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
    if (request.method === "GET" && url.pathname === "/health") return json({ok:true,service:"punto-vuela-mail",brevoConfigured:!!env.BREVO_API_KEY,senderConfigured:!!env.MAIL_FROM_EMAIL,turnstileConfigured:!!env.TURNSTILE_SECRET_KEY,rateLimitConfigured:!!env.RATE_LIMIT,recipient:env.MAIL_TO_EMAIL||RECIPIENT});
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
      const logoBase64 = "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";
      const htmlContent = '<!doctype html><html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width"></head><body style="margin:0;background:#f2f4f7;font-family:Arial,Helvetica,sans-serif;color:#172033"><table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#f2f4f7;padding:28px 12px"><tr><td align="center"><table role="presentation" width="600" cellpadding="0" cellspacing="0" style="max-width:600px;width:100%;background:#ffffff;border-radius:14px;overflow:hidden;border:1px solid #e3e7ed"><tr><td style="background:#172033;padding:24px 28px;border-bottom:6px solid #F3D54E"><table role="presentation" cellpadding="0" cellspacing="0"><tr><td valign="middle"><img src="cid:puntos-vuela-toolkit-icon" width="64" height="64" alt="Icono Puntos Vuela Toolkit" style="display:block;border:0;border-radius:12px"></td><td style="padding-left:16px"><div style="color:#F3D54E;font-size:12px;font-weight:bold;letter-spacing:1.5px;text-transform:uppercase">Puntos Vuela Toolkit</div><h1 style="margin:6px 0 0;color:#ffffff;font-size:23px;line-height:1.25">Nueva propuesta de aplicación</h1></td></tr></table></td></tr><tr><td style="padding:26px 28px 12px"><p style="margin:0;color:#4b5563;font-size:15px;line-height:1.6">Se ha recibido una nueva propuesta de aplicación desde el formulario de Puntos Vuela Toolkit.</p></td></tr><tr><td style="padding:12px 28px 24px"><table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="border:1px solid #e6eaf0;border-radius:10px;overflow:hidden">' +
        rows.map(([label,value],i) => '<tr><td style="width:34%;padding:11px 12px;background:'+(i%2?'#ffffff':'#f7f8fa')+';border-bottom:1px solid #e6eaf0;color:#596579;font-size:12px;font-weight:bold;vertical-align:top">'+esc(label)+'</td><td style="padding:11px 12px;background:'+(i%2?'#ffffff':'#f7f8fa')+';border-bottom:1px solid #e6eaf0;color:#172033;font-size:13px;line-height:1.5;vertical-align:top">'+esc(value)+'</td></tr>').join("") +
        '</table></td></tr><tr><td style="padding:0 28px 28px"><div style="border-left:4px solid #F3D54E;padding:12px 16px;background:#fffbea;color:#394152;font-size:12px;line-height:1.5">Este mensaje ha sido generado automáticamente por Puntos Vuela Toolkit. La propuesta incluye los datos de contacto y la vista previa revisada por la persona solicitante.</div></td></tr><tr><td style="background:#172033;padding:18px 28px;text-align:center;color:#aab4c3;font-size:11px;line-height:1.5">Puntos Vuela Toolkit · Propuesta recibida<br><span style="color:#F3D54E">Herramientas digitales para los Puntos Vuela</span></td></tr></table></td></tr></table></body></html>';
      const textContent = rows.map(([label,value]) => label + ": " + String(value ?? "")).join("\\n");
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
          attachment: [{name:"puntos-vuela-toolkit-icon.png",content:logoBase64,contentId:"puntos-vuela-toolkit-icon"}],
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
