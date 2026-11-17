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
function turnstilePage() {
  const html = `<!doctype html><html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Verificación de seguridad</title><style>html,body{margin:0;padding:0;background:transparent;font-family:Arial,sans-serif;color:#202833}.wrap{min-height:78px;display:flex;align-items:center;justify-content:flex-start}.cf-turnstile{min-height:65px}</style></head><body><div class="wrap"><div class="cf-turnstile" data-sitekey="0x4AAAAAAGE00xD9YbrCMdVS" data-callback="onTurnstileSuccess" data-expired-callback="onTurnstileExpired" data-error-callback="onTurnstileError" data-theme="auto"></div></div><script>function onTurnstileSuccess(token){parent.postMessage({type:"turnstile-token",token:token},"*")}function onTurnstileExpired(){parent.postMessage({type:"turnstile-expired"},"*")}function onTurnstileError(){parent.postMessage({type:"turnstile-error"},"*")}</script><script src="https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit" async defer></script></body></html>`;
  return new Response(html, {status:200,headers:{"content-type":"text/html; charset=utf-8","cache-control":"no-store","content-security-policy":"frame-ancestors *; default-src 'self' https://challenges.cloudflare.com; script-src 'self' 'unsafe-inline' https://challenges.cloudflare.com; frame-src https://challenges.cloudflare.com; connect-src https://challenges.cloudflare.com"}});
}
async function verifyTurnstile(token, request, env) {
  if (!env.TURNSTILE_SECRET_KEY) return {ok:false, reason:"missing-secret"};
  if (typeof token !== "string" || !token.trim()) return {ok:false, reason:"missing-token"};
  const body = new URLSearchParams({secret:env.TURNSTILE_SECRET_KEY,response:token});
  const ip = request.headers.get("CF-Connecting-IP");
  if (ip) body.set("remoteip", ip);
  const response = await fetch("https://challenges.cloudflare.com/turnstile/v0/siteverify", {method:"POST",headers:{"content-type":"application/x-www-form-urlencoded"},body});
  if (!response.ok) return {ok:false, reason:"verification-unavailable"};
  const result = await response.json();
  return {ok:result.success === true, reason:result.success ? "" : "invalid-token"};
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
    ["Enlace", data.url || "No indicado"],
    ["Necesidad y utilidad", data.purpose], ["Observaciones", data.notes || "Ninguna"], ["Vista previa revisada", data.preview_text || "Sin cambios en la vista previa."],
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
    '<tr><td style="background:#303740;border-top:6px solid #F3D54E;padding:22px 30px"><table role="presentation" cellspacing="0" cellpadding="0"><tr>' +
    '<td style="vertical-align:middle;padding-right:16px"><img src="cid:pv-toolkit-logo" width="66" height="66" alt="Puntos Vuela Toolkit" style="display:block;width:66px;height:66px;border-radius:12px;background:#F3D54E"></td>' +
    '<td style="vertical-align:middle"><div style="font-size:11px;letter-spacing:2px;color:#d9dee5;font-weight:bold">PUNTOS VUELA</div>' +
    '<div style="font-size:23px;line-height:1.3;color:#ffffff!important;font-weight:bold;margin-top:5px">Solicitud de incorporación de aplicación</div></td></tr></table></td></tr>' +
    '<tr><td style="padding:25px 30px 12px;font-size:14px;line-height:1.6">Se ha recibido una propuesta desde Punto Vuela Linux Toolkit.</td></tr>' +
    '<tr><td style="padding:8px 22px 26px"><table role="presentation" width="100%" cellspacing="0" cellpadding="0">' + table + "</table></td></tr>" +
    '<tr><td style="padding:18px 30px;background:#f7f8fa;color:#788392;font-size:11px;line-height:1.5">Mensaje generado automáticamente por Puntos Vuela Toolkit.</td></tr>' +
    "</table></td></tr></table></body></html>";
  const text = rows.map(([label, value]) => label + ": " + String(value ?? "")).join("\n");
  const alternative = "pv-alt-" + crypto.randomUUID().replace(/-/g, "");
  const related = "pv-related-" + crypto.randomUUID().replace(/-/g, "");
  const logoBase64 = "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";
  return [
    "From: Punto Vuela Linux Toolkit <" + SENDER + ">",
    "To: " + RECIPIENT,
    "Cc: " + data.reply_email,
    "Reply-To: " + data.reply_email,
    "Subject: =?UTF-8?B?" + btoa(unescape(encodeURIComponent("Solicitud de aplicación"))) + "?=",
    "MIME-Version: 1.0",
    'Content-Type: multipart/related; boundary="' + related + '"',
    "",
    "--" + related,
    'Content-Type: multipart/alternative; boundary="' + alternative + '"',
    "",
    "--" + alternative,
    "Content-Type: text/plain; charset=UTF-8",
    "Content-Transfer-Encoding: base64",
    "",
    btoa(unescape(encodeURIComponent(text))),
    "--" + alternative,
    "Content-Type: text/html; charset=UTF-8",
    "Content-Transfer-Encoding: base64",
    "",
    btoa(unescape(encodeURIComponent(html))),
    "--" + alternative + "--",
    "--" + related,
    'Content-Type: image/png; name="logo_toolkit.png"',
    "Content-Transfer-Encoding: base64",
    "Content-ID: <pv-toolkit-logo>",
    'Content-Disposition: inline; filename="logo_toolkit.png"',
    "",
    logoBase64,
    "--" + related + "--",
    "",
  ].join("\r\n");
}
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (request.method === "GET" && url.pathname === "/turnstile") return turnstilePage();
    if (request.method === "OPTIONS") return json({ok: true});
    if (request.method !== "POST" || url.pathname !== "/") return json({ok: false, message: "Método no permitido."}, 405);
    if (!env.GOOGLE_CLIENT_ID || !env.GOOGLE_CLIENT_SECRET || !env.GOOGLE_REFRESH_TOKEN) {
      return json({ok: false, message: "El servicio de correo aún no está configurado."}, 503);
    }
    try {
      if (!env.RATE_LIMIT) return json({ok: false, message: "La protección antispam no está configurada."}, 503);
      const ip = request.headers.get("CF-Connecting-IP") || "unknown";
      {
        const key = "mail:" + ip;
        const current = Number(await env.RATE_LIMIT.get(key) || "0");
        if (current >= 5) return json({ok: false, message: "Se ha alcanzado el límite temporal de solicitudes. Inténtalo más tarde."}, 429);
        await env.RATE_LIMIT.put(key, String(current + 1), {expirationTtl: 3600});
      }
      const data = await request.json();
      const verification = await verifyTurnstile(data.turnstileToken, request, env);
      if (!verification.ok) return json({ok:false,message:verification.reason==="missing-secret"?"La protección Turnstile no está configurada en el servidor.":"Completa de nuevo la verificación antispam."}, verification.reason==="missing-secret"?503:403);
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
