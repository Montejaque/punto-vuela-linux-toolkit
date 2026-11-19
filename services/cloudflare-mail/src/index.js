/**
 * Punto Vuela Linux Toolkit - mail gateway
 * Deploy with Cloudflare Workers. Brevo and Turnstile credentials belong in Worker secrets.
 */
const RECIPIENT = "montejaque@puntosvuela.es";
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
  const html = `<!doctype html><html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Verificación de seguridad</title><style>html,body{margin:0;padding:0;background:transparent;font-family:Arial,sans-serif;color:#202833}.wrap{min-height:78px;display:flex;align-items:center;justify-content:flex-start;flex-direction:column}.status{width:100%;font-size:12px;color:#64748b;padding:4px 0}.widget{min-height:65px;width:100%}</style></head><body><div class="wrap"><div id="turnstile-status" class="status" role="status">Conectando con Cloudflare…</div><div id="turnstile-widget" class="widget"></div></div><script>
function report(type,extra){var payload=Object.assign({type:type},extra||{});if(window.parent!==window){window.parent.postMessage(payload,"*");}else if(window.opener&&!window.opener.closed){window.opener.postMessage(payload,"*");if(type==="turnstile-token"){setTimeout(function(){window.close();},500);}}}
function onTurnstileSuccess(token){document.getElementById("turnstile-status").textContent="Verificación completada.";report("turnstile-token",{token:token});}
function onTurnstileExpired(){document.getElementById("turnstile-status").textContent="La verificación ha caducado.";report("turnstile-expired");}
function onTurnstileError(code){var detail=String(code||"sin código");document.getElementById("turnstile-status").textContent="Cloudflare ha devuelto el error "+detail+".";report("turnstile-error",{code:detail});}
function onTurnstileUnsupported(){document.getElementById("turnstile-status").textContent="Este entorno no es compatible con Turnstile.";report("turnstile-error",{code:"unsupported"});}
var api=document.createElement("script");api.src="https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit";api.async=true;api.defer=true;
api.onload=function(){if(!window.turnstile){onTurnstileError("api-no-disponible");return;}try{window.turnstile.render("#turnstile-widget",{sitekey:"0x4AAAAAAGE00xD9YbrCMdVS",theme:"light",language:"es",callback:onTurnstileSuccess,"expired-callback":onTurnstileExpired,"error-callback":onTurnstileError,"unsupported-callback":onTurnstileUnsupported,"timeout-callback":function(){onTurnstileError("timeout");}});document.getElementById("turnstile-status").textContent="Verificación de seguridad lista.";report("turnstile-ready"); }catch(error){onTurnstileError(error&&error.message?error.message:"fallo-de-inicialización");}};
api.onerror=function(){document.getElementById("turnstile-status").textContent="No se ha podido cargar challenges.cloudflare.com. Comprueba la conexión o el cortafuegos.";report("turnstile-error",{code:"script-load-failed"});};
document.head.appendChild(api);
</script></body></html>`;
  return new Response(html, {status:200,headers:{"content-type":"text/html; charset=utf-8","cache-control":"no-store","content-security-policy":"frame-ancestors *; default-src 'self' https: data:; script-src 'self' 'unsafe-inline' https://challenges.cloudflare.com; style-src 'self' 'unsafe-inline' https://challenges.cloudflare.com; img-src 'self' data: https:; font-src 'self' data: https:; frame-src https://challenges.cloudflare.com https://*.cloudflare.com; connect-src 'self' https://challenges.cloudflare.com https://*.cloudflare.com; worker-src 'self' blob:; child-src 'self' blob: https://challenges.cloudflare.com"}});
}
async function verifyTurnstile(token, request, env) {
  if (!env.TURNSTILE_SECRET_KEY) return {ok:false, reason:"missing-secret"};
  if (typeof token !== "string" || !token.trim()) return {ok:false, reason:"missing-token"};
  const body = new URLSearchParams({secret:env.TURNSTILE_SECRET_KEY,response:token});
  const ip = request.headers.get("CF-Connecting-IP");
  if (ip) body.set("remoteip", ip);
  console.log("turnstile_siteverify_request", JSON.stringify({event:"siteverify_request",timestamp:new Date().toISOString()}));
  let response;
  try {
    response = await fetch("https://challenges.cloudflare.com/turnstile/v0/siteverify", {method:"POST",headers:{"content-type":"application/x-www-form-urlencoded"},body});
  } catch (error) {
    console.error("turnstile_siteverify_network_error", String(error?.message||error).slice(0,180));
    return {ok:false, reason:"verification-unavailable"};
  }
  if (!response.ok) {
    console.error("turnstile_siteverify_http_error", response.status);
    return {ok:false, reason:"verification-unavailable"};
  }
  const result = await response.json();
  console.log("turnstile_siteverify_result", JSON.stringify({success:result.success===true,hostname:result.hostname||null,action:result.action||null,errorCodes:result["error-codes"]||[]}));
  return {ok:result.success === true, reason:result.success ? "" : "invalid-token"};
}
function esc(value) {
  return String(value ?? "").trim().replace(/[&<>"']/g, c =>
    ({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c])
  ).replace(/\n/g, "<br>");
}
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (request.method === "GET" && url.pathname === "/health") return json({ok:true,service:"punto-vuela-mail",brevoConfigured:!!env.BREVO_API_KEY,senderConfigured:!!env.MAIL_FROM_EMAIL,turnstileConfigured:!!env.TURNSTILE_SECRET_KEY,rateLimitConfigured:!!env.RATE_LIMIT,recipient:env.MAIL_TO_EMAIL||RECIPIENT,workerVersion:"brevo-turnstile-health-v1"});
    if (request.method === "GET" && url.pathname === "/turnstile") return turnstilePage();
    if (request.method === "OPTIONS") return json({ok: true});
    if (request.method !== "POST" || url.pathname !== "/") return json({ok: false, message: "Método no permitido."}, 405);
    if (!env.BREVO_API_KEY || !env.MAIL_FROM_EMAIL) {
      return json({ok: false, message: "El servicio de correo aún no está configurado en Brevo."}, 503);
    }
    try {
      if (!env.RATE_LIMIT) return json({ok: false, message: "La protección antispam no está configurada."}, 503);
      const data = await request.json();
      const verification = await verifyTurnstile(data.turnstileToken, request, env);
      if (!verification.ok) return json({ok:false,message:verification.reason==="missing-secret"?"La protección Turnstile no está configurada en el servidor.":"Completa de nuevo la verificación antispam."}, verification.reason==="missing-secret"?503:403);
      const ip = request.headers.get("CF-Connecting-IP") || "unknown";
      {
        const key = "mail:" + ip;
        const current = Number(await env.RATE_LIMIT.get(key) || "0");
        if (current >= 5) return json({ok: false, message: "Se ha alcanzado el límite temporal de solicitudes. Inténtalo más tarde."}, 429);
        await env.RATE_LIMIT.put(key, String(current + 1), {expirationTtl: 3600});
      }
      // Honeypot: silently accept bot submissions without forwarding email.
      if (String(data.website || "").trim()) return json({ok: true, message: "Solicitud recibida."});
      const required = ["center", "municipality", "province", "contact", "phone", "reply_email", "application", "purpose"];
      if (required.some(key => !String(data[key] || "").trim())) return json({ok: false, message: "Faltan campos obligatorios."}, 400);
      if (data.data_protection_read !== true || data.privacy_policy_read !== true || data.terms_accepted !== true) return json({ok: false, message: "Debes consultar y aceptar la información legal y los términos antes de enviar."}, 400);
      if (JSON.stringify(data).length > 16000) return json({ok: false, message: "La solicitud supera el tamaño permitido."}, 413);
      if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(data.reply_email)) return json({ok: false, message: "El correo de contacto no es válido."}, 400);
      const recipient = env.MAIL_TO_EMAIL || RECIPIENT;
      const rows = [
        ["Punto Vuela", data.center], ["Municipio", data.municipality], ["Provincia", data.province],
        ["Persona de contacto", data.contact], ["Teléfono", data.phone], ["Correo de contacto", data.reply_email],
        ["Aplicación", data.application], ["Enlace", data.url || "No indicado"],
        ["Necesidad y utilidad", data.purpose], ["Observaciones", data.notes || "Ninguna"],
        ["Vista previa revisada", data.preview_text || "Sin cambios en la vista previa."],
      ];
      const htmlContent = '<!doctype html><html lang="es"><meta charset="utf-8"><body style="font-family:Arial,sans-serif;color:#202833"><h2 style="border-bottom:5px solid #F3D54E;padding-bottom:12px">Nueva propuesta · Puntos Vuela Toolkit</h2><table cellpadding="9" cellspacing="0" style="border-collapse:collapse;width:100%">' +
        rows.map(([label,value]) => '<tr><th align="left" style="border-bottom:1px solid #e9edf2;color:#657080">' + esc(label) + '</th><td style="border-bottom:1px solid #e9edf2">' + esc(value) + '</td></tr>').join("") +
        '</table><p style="color:#788392;font-size:12px">Mensaje generado automáticamente por Puntos Vuela Toolkit.</p></body></html>';
      const textContent = rows.map(([label,value]) => label + ": " + String(value ?? "")).join("\n");
      const sent = await fetch("https://api.brevo.com/v3/smtp/email", {
        method: "POST",
        headers: {"api-key": env.BREVO_API_KEY, "content-type": "application/json", accept: "application/json"},
        body: JSON.stringify({
          sender: {email: env.MAIL_FROM_EMAIL, name: env.MAIL_FROM_NAME || "Puntos Vuela Toolkit"},
          to: [{email: recipient}],
          replyTo: {email: data.reply_email},
          subject: "Nueva propuesta de aplicación · Puntos Vuela Toolkit",
          htmlContent,
          textContent,
        }),
      });
      if (!sent.ok) {
        const detail = await sent.text();
        console.error("Brevo API error", sent.status, detail.slice(0, 500));
        const safeDetail=detail.replace(/[\r\n]+/g," ").slice(0,220);
        return json({ok:false,message:"Brevo ha rechazado el envío (HTTP "+sent.status+"). "+safeDetail},502);
      }
      return json({ok: true, message: "Solicitud enviada correctamente a " + recipient + "."});
    } catch (error) {
      console.error("Mail worker error", String(error));
      return json({ok: false, message: "No se ha podido enviar la solicitud. Inténtalo de nuevo más tarde."}, 500);
    }
  },
};
