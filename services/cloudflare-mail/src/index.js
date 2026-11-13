/**
 * Punto Vuela Linux Toolkit - mail gateway
 * Deploy with Cloudflare Workers. Gmail OAuth credentials belong in Worker secrets.
 */
const RECIPIENT = "montejaque@puntosvuela.es";
const SENDER = "puntovuelamontejaque@gmail.com";
const ALLOWED_ORIGIN = "*"; // Native desktop client; no browser credentials are exposed.

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "access-control-allow-origin": ALLOWED_ORIGIN,
      "access-control-allow-methods": "POST, OPTIONS",
      "access-control-allow-headers": "content-type",
      "cache-control": "no-store",
    },
  });
}
function esc(value) {
  return String(value ?? "").trim().replace(/[&<>"']/g, c =>
    ({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c])
  ).replace(/\n/g, "<br>");
}
function b64url(value) {
  const bytes = new TextEncoder().encode(value);
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}
async function gmailToken(env) {
  const body = new URLSearchParams({
    client_id: env.GOOGLE_CLIENT_ID,
    client_secret: env.GOOGLE_CLIENT_SECRET,
    refresh_token: env.GOOGLE_REFRESH_TOKEN,
    grant_type: "refresh_token",
  });
  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: {"content-type": "application/x-www-form-urlencoded"},
    body,
  });
  const data = await response.json();
  if (!response.ok || !data.access_token) throw new Error("No se pudo autorizar Gmail.");
  return data.access_token;
}
function buildMime(data) {
  const rows = [
    ["Punto Vuela", data.center], ["Municipio", data.municipality], ["Provincia", data.province],
    ["Persona de contacto", data.contact], ["Teléfono", data.phone],
    ["Correo para la copia", data.reply_email], ["Aplicación", data.application],
    ["Enlace", data.url || "No indicado"], ["Distribución", data.distribution || "No indicada"],
    ["Necesidad y utilidad", data.purpose], ["Observaciones", data.notes || "Ninguna"],
    ["Información de protección de datos leída", data.data_protection_read ? "Sí" : "No"],
    ["Política de privacidad leída", data.privacy_policy_read ? "Sí" : "No"],
    ["Términos y condiciones aceptados", data.terms_accepted ? "Sí" : "No"],
  ];
  const table = rows.map(([label, value]) =>
    '<tr><td style="padding:11px 14px;border-bottom:1px solid #e9edf2;color:#657080;width:34%;font-size:13px">' +
    esc(label) + '</td><td style="padding:11px 14px;border-bottom:1px solid #e9edf2;color:#202833;font-size:13px">' +
    esc(value) + "</td></tr>"
  ).join("");
  const html = '<!doctype html><html lang="es"><meta charset="utf-8"><body style="margin:0;padding:28px 12px;background:#f2f4f7;font-family:Arial,Helvetica,sans-serif;color:#202833">' +
    '<table role="presentation" width="100%" cellspacing="0" cellpadding="0"><tr><td align="center">' +
    '<table role="presentation" width="640" cellspacing="0" cellpadding="0" style="max-width:640px;background:#fff;border-radius:16px;overflow:hidden">' +
    '<tr><td style="background:#303740;border-top:6px solid #FAD100;padding:25px 30px"><div style="font-size:11px;letter-spacing:2px;color:#d9dee5;font-weight:bold">PUNTO VUELA</div>' +
    '<div style="font-size:23px;line-height:1.3;color:#fff;font-weight:bold;margin-top:5px">Solicitud de incorporación de aplicación</div></td></tr>' +
    '<tr><td style="padding:25px 30px 12px;font-size:14px;line-height:1.6">Se ha recibido una propuesta desde Punto Vuela Linux Toolkit.</td></tr>' +
    '<tr><td style="padding:8px 22px 26px"><table role="presentation" width="100%" cellspacing="0" cellpadding="0">' + table + "</table></td></tr>" +
    '<tr><td style="padding:18px 30px;background:#f7f8fa;color:#788392;font-size:11px;line-height:1.5">Mensaje generado automáticamente por Punto Vuela Linux Toolkit.</td></tr>' +
    "</table></td></tr></table></body></html>";
  const text = rows.map(([label, value]) => label + ": " + String(value ?? "")).join("\n");
  const boundary = "pvtoolkit_" + crypto.randomUUID().replace(/-/g, "");
  return [
    "From: Punto Vuela Linux Toolkit <" + SENDER + ">",
    "To: " + RECIPIENT,
    "Cc: " + data.reply_email,
    "Reply-To: " + data.reply_email,
    "Subject: =?UTF-8?B?" + btoa(unescape(encodeURIComponent("Solicitud de aplicación"))) + "?=",
    "MIME-Version: 1.0",
    'Content-Type: multipart/alternative; boundary="' + boundary + '"',
    "",
    "--" + boundary,
    "Content-Type: text/plain; charset=UTF-8",
    "Content-Transfer-Encoding: base64",
    "",
    btoa(unescape(encodeURIComponent(text))),
    "--" + boundary,
    "Content-Type: text/html; charset=UTF-8",
    "Content-Transfer-Encoding: base64",
    "",
    btoa(unescape(encodeURIComponent(html))),
    "--" + boundary + "--",
    "",
  ].join("\r\n");
}
export default {
  async fetch(request, env) {
    if (request.method === "OPTIONS") return json({ok: true});
    if (request.method !== "POST") return json({ok: false, message: "Método no permitido."}, 405);
    if (!env.GOOGLE_CLIENT_ID || !env.GOOGLE_CLIENT_SECRET || !env.GOOGLE_REFRESH_TOKEN) {
      return json({ok: false, message: "El servicio de correo aún no está configurado."}, 503);
    }
    try {
      const ip = request.headers.get("CF-Connecting-IP") || "unknown";
      if (env.RATE_LIMIT) {
        const key = "mail:" + ip;
        const current = Number(await env.RATE_LIMIT.get(key) || "0");
        if (current >= 5) return json({ok: false, message: "Se ha alcanzado el límite temporal de solicitudes. Inténtalo más tarde."}, 429);
        await env.RATE_LIMIT.put(key, String(current + 1), {expirationTtl: 3600});
      }
      const data = await request.json();
      // Honeypot: silently accept bot submissions without forwarding email.
      if (String(data.website || "").trim()) return json({ok: true, message: "Solicitud recibida."});
      const required = ["center", "municipality", "province", "contact", "phone", "reply_email", "application", "purpose"];
      if (required.some(key => !String(data[key] || "").trim())) return json({ok: false, message: "Faltan campos obligatorios."}, 400);
      if (data.data_protection_read !== true || data.privacy_policy_read !== true || data.terms_accepted !== true) return json({ok: false, message: "Debes consultar y aceptar la información legal y los términos antes de enviar."}, 400);
      if (JSON.stringify(data).length > 16000) return json({ok: false, message: "La solicitud supera el tamaño permitido."}, 413);
      if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(data.reply_email)) return json({ok: false, message: "El correo de contacto no es válido."}, 400);
      const token = await gmailToken(env);
      const raw = b64url(buildMime(data));
      const sent = await fetch("https://gmail.googleapis.com/gmail/v1/users/me/messages/send", {
        method: "POST",
        headers: {authorization: "Bearer " + token, "content-type": "application/json"},
        body: JSON.stringify({raw}),
      });
      if (!sent.ok) {
        const detail = await sent.text();
        console.error("Gmail API error", sent.status, detail.slice(0, 500));
        return json({ok: false, message: "Gmail no ha podido enviar la solicitud. Contacta con soporte."}, 502);
      }
      return json({ok: true, message: "Solicitud enviada a " + RECIPIENT + ". Se ha enviado una copia a " + data.reply_email + "."});
    } catch (error) {
      console.error("Mail worker error", String(error));
      return json({ok: false, message: "No se ha podido enviar la solicitud. Inténtalo de nuevo más tarde."}, 500);
    }
  },
};
