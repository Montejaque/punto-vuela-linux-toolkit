from __future__ import annotations

import json
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

# Worker de envío de solicitudes de Punto Vuela, desplegado en Cloudflare.
WORKER_URL = "https://punto-vuela-mail.montejaque.workers.dev"


def send_application_request(data: dict[str, str]) -> str:
    required = ("center", "municipality", "contact", "phone", "reply_email", "application", "purpose")
    missing = [field for field in required if not str(data.get(field, "")).strip()]
    if missing:
        raise ValueError("Faltan datos obligatorios en la solicitud.")
    payload = json.dumps(data, ensure_ascii=False).encode("utf-8")
    request = Request(
        WORKER_URL,
        data=payload,
        headers={"Content-Type": "application/json", "Accept": "application/json"},
        method="POST",
    )
    try:
        with urlopen(request, timeout=25) as response:
            result = json.loads(response.read().decode("utf-8"))
    except HTTPError as exc:
        try:
            result = json.loads(exc.read().decode("utf-8"))
            raise RuntimeError(result.get("message", "No se pudo enviar la solicitud.")) from exc
        except json.JSONDecodeError:
            raise RuntimeError("El servicio de correo no está disponible.") from exc
    except (URLError, TimeoutError) as exc:
        raise RuntimeError("No se puede conectar con el servicio seguro de correo.") from exc
    if not result.get("ok"):
        raise RuntimeError(result.get("message", "No se pudo enviar la solicitud."))
    return result.get("message", "Solicitud enviada correctamente.")
