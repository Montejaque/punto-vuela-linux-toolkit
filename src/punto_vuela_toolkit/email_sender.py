from __future__ import annotations

import html
import smtplib
import ssl
from email.message import EmailMessage
from email.utils import formataddr, parseaddr

import keyring

SERVICE_NAME = "punto-vuela-linux-toolkit.smtp"
RECIPIENT = "montejaque@puntosvuela.es"


def save_credentials(sender: str, app_password: str) -> None:
    address = parseaddr(sender.strip())[1]
    if not address or "@" not in address:
        raise ValueError("Introduce una dirección de Gmail válida.")
    if not app_password.strip():
        raise ValueError("Introduce la contraseña de aplicación de Google.")
    keyring.set_password(SERVICE_NAME, address, app_password.strip().replace(" ", ""))
    keyring.set_password(SERVICE_NAME, "configured_sender", address)


def configured_sender() -> str:
    return keyring.get_password(SERVICE_NAME, "configured_sender") or ""


def send_application_request(data: dict[str, str]) -> None:
    sender = configured_sender()
    password = keyring.get_password(SERVICE_NAME, sender) if sender else None
    if not sender or not password:
        raise RuntimeError("Configura primero la cuenta de Gmail y su contraseña de aplicación.")
    required = ("center", "municipality", "contact", "phone", "reply_email", "application", "purpose")
    missing = [field for field in required if not str(data.get(field, "")).strip()]
    if missing:
        raise ValueError("Faltan datos obligatorios en la solicitud.")
    esc = lambda value: html.escape(str(value or "").strip()).replace("\n", "<br>")
    rows = [
        ("Punto Vuela", data.get("center")),
        ("Municipio", data.get("municipality")),
        ("Persona de contacto", data.get("contact")),
        ("Teléfono", data.get("phone")),
        ("Correo para la copia", data.get("reply_email")),
        ("Aplicación", data.get("application")),
        ("Enlace", data.get("url") or "No indicado"),
        ("Distribución", data.get("distribution") or "No indicada"),
        ("Necesidad y utilidad", data.get("purpose")),
        ("Observaciones", data.get("notes") or "Ninguna"),
    ]
    table_rows = "".join(
        "<tr><td style='padding:11px 14px;border-bottom:1px solid #e9edf2;color:#657080;width:34%;font-size:13px'>"
        + esc(label) + "</td><td style='padding:11px 14px;border-bottom:1px solid #e9edf2;color:#202833;font-size:13px'>"
        + esc(value) + "</td></tr>" for label, value in rows
    )
    body = f"""<!doctype html><html lang="es"><head><meta charset="utf-8"></head>
<body style="margin:0;padding:28px 12px;background:#f2f4f7;font-family:Arial,Helvetica,sans-serif;color:#202833">
<table role="presentation" width="100%" cellspacing="0" cellpadding="0"><tr><td align="center">
<table role="presentation" width="640" cellspacing="0" cellpadding="0" style="max-width:640px;background:#fff;border-radius:16px;overflow:hidden">
<tr><td style="background:#303740;padding:25px 30px">
<div style="font-size:11px;letter-spacing:2px;color:#d9dee5;font-weight:bold">PUNTO VUELA</div>
<div style="font-size:23px;line-height:1.3;color:#fff;font-weight:bold;margin-top:5px">Solicitud de incorporación de aplicación</div>
</td></tr>
<tr><td style="padding:25px 30px 12px;font-size:14px;line-height:1.6">Se ha recibido una propuesta desde Punto Vuela Linux Toolkit.</td></tr>
<tr><td style="padding:8px 22px 26px"><table role="presentation" width="100%" cellspacing="0" cellpadding="0">{table_rows}</table></td></tr>
<tr><td style="padding:18px 30px;background:#f7f8fa;color:#788392;font-size:11px;line-height:1.5">Mensaje generado automáticamente por Punto Vuela Linux Toolkit. La copia se envía a la dirección indicada por la persona solicitante.</td></tr>
</table></td></tr></table></body></html>"""
    msg = EmailMessage()
    msg["Subject"] = "Solicitud de aplicación"
    msg["From"] = formataddr(("Punto Vuela Linux Toolkit", sender))
    msg["To"] = RECIPIENT
    msg["Cc"] = data["reply_email"].strip()
    msg["Reply-To"] = data["reply_email"].strip()
    msg.set_content("\n".join(f"{label}: {value}" for label, value in rows))
    msg.add_alternative(body, subtype="html")
    context = ssl.create_default_context()
    with smtplib.SMTP("smtp.gmail.com", 587, timeout=30) as server:
        server.ehlo()
        server.starttls(context=context)
        server.ehlo()
        server.login(sender, password)
        server.send_message(msg)
