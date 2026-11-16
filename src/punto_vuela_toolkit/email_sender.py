from __future__ import annotations

import json
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

# Worker de envío de solicitudes de Punto Vuela, desplegado en Cloudflare.
WORKER_URL = "https://punto-vuela-mail.montejaque.workers.dev"


def send_application_request(data: dict[str, str]) -> str:
    required = ("center", "municipality", "province", "contact", "phone", "reply_email", "application", "purpose")
    missing = [field for field in required if not str(data.get(field, "")).strip()]
    if missing:
        raise ValueError("Faltan datos obligatorios en la solicitud.")
    if data.get("data_protection_read") is not True or data.get("privacy_policy_read") is not True or data.get("terms_accepted") is not True:
        raise ValueError("Debes aceptar la información legal y los términos antes de enviar.")
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
            body = exc.read().decode("utf-8", errors="replace")
            result = json.loads(body) if body else {}
            message = result.get("message") or "El servicio ha rechazado la solicitud."
        except (json.JSONDecodeError, UnicodeDecodeError):
            message = "El servicio de correo no ha devuelto una respuesta válida."
        raise RuntimeError(f"{message} (HTTP {exc.code}).") from exc
    except (URLError, TimeoutError) as exc:
        reason = getattr(exc, "reason", exc)
        raise RuntimeError(f"No se puede conectar con el servicio seguro de correo: {reason}") from exc
    except (json.JSONDecodeError, UnicodeDecodeError) as exc:
        raise RuntimeError("El servicio de correo ha devuelto una respuesta ilegible.") from exc
    if not isinstance(result, dict) or not result.get("ok"):
        message = result.get("message", "No se pudo enviar la solicitud.") if isinstance(result, dict) else "Respuesta inesperada del servicio de correo."
        raise RuntimeError(message)
    return result.get("message", "Solicitud enviada correctamente.")

def check_mail_service() -> dict[str, object]:
    """Return a safe configuration status from the Worker health endpoint."""
    request = Request(
        WORKER_URL.rstrip("/") + "/health",
        headers={"Accept": "application/json"},
        method="GET",
    )
    try:
        with urlopen(request, timeout=10) as response:
            payload = json.loads(response.read().decode("utf-8"))
            payload["http_status"] = response.status
            return payload
    except HTTPError as exc:
        try:
            payload = json.loads(exc.read().decode("utf-8", errors="replace"))
        except (json.JSONDecodeError, UnicodeDecodeError):
            payload = {"ok": False, "message": "El servicio de correo no ha devuelto un diagnóstico válido."}
        payload["http_status"] = exc.code
        return payload
    except (URLError, TimeoutError) as exc:
        reason = getattr(exc, "reason", exc)
        return {
            "ok": False,
            "message": f"No se puede conectar con el servicio de correo: {reason}",
            "http_status": None,
        }
    except (json.JSONDecodeError, UnicodeDecodeError):
        return {"ok": False, "message": "El servicio de correo ha devuelto una respuesta ilegible.", "http_status": None}
