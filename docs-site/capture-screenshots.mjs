import { chromium } from "../desktop-electron/node_modules/playwright/index.mjs";
import { mkdir } from "node:fs/promises";
const base="http://127.0.0.1:5173";
await mkdir("../docs-site/screenshots",{recursive:true});
const browser=await chromium.launch({headless:true});
const page=await browser.newPage({viewport:{width:1440,height:950},deviceScaleFactor:1});
await page.addInitScript(()=>{
 const catalog=[
  {name:"LibreOffice",description:"Suite de oficina para documentos, hojas de cálculo y presentaciones.",category:"Oficina",categories:["Oficina"],author:"The Document Foundation",license:"MPL-2.0",glibc:"2.31",compatibleUbuntu20:true,compatibility:"Ubuntu 20.04 o posterior (referencia declarada)",iconUrl:"",version:"24.2",repository:"https://github.com/LibreOffice"},
  {name:"GIMP",description:"Editor de imágenes libre para retoque, composición y creación.",category:"Diseño",categories:["Diseño"],author:"GIMP Team",license:"GPL-3.0",glibc:"2.31",compatibleUbuntu20:true,compatibility:"Compatibilidad declarada por el catálogo",iconUrl:"",version:"3.0",repository:"https://www.gimp.org"},
  {name:"Inkscape",description:"Editor vectorial de código abierto.",category:"Diseño",categories:["Diseño"],author:"Inkscape Project",license:"GPL-3.0",glibc:"2.31",compatibleUbuntu20:true,compatibility:"Compatibilidad declarada por el catálogo",iconUrl:"",version:"1.4",repository:"https://inkscape.org"}
 ];
 const tool=[{name:"Puntos Vuela Toolkit",description:"Centro de aplicaciones y recursos Linux de Punto Vuela.",category:"Punto Vuela",author:"Francisco Javier Gallego Orellana",license:"MIT",compatibility:"Linux x86_64",version:"0.4.1",iconUrl:"",repository:"https://github.com/Montejaque/punto-vuela-linux-toolkit",repositoryUrl:"https://github.com/Montejaque/punto-vuela-linux-toolkit"}];
 const centres=[{name:"Centro Punto Vuela de Montejaque",slug:"montejaque",municipality:"Montejaque",province:"Málaga",details:"Centro demo para capturas",url:"https://puntosvuela.es"}];
 window.puntoVuela={version:"0.4.1",invoke:async(method,args={})=>{
  if(method==="catalog.search") return catalog;
  if(method==="tools.list") return tool;
  if(method==="apps.list") return [{name:"Krita",path:"/home/demo/AppImages/Krita.AppImage",size:157286400,executable:true,modified:"2026-11-18"}];
  if(method==="apps.folder") return {message:"Carpeta de demostración"};
  if(method==="mail.health") return {brevoConfigured:true,senderConfigured:true,turnstileConfigured:true,rateLimitConfigured:true};
  if(method==="centres.list") return centres;
  if(method==="centres.details") return {ail:"Equipo de dinamización",phone:"+34 600 000 000",email:"montejaque@example.test"};
  if(method==="apps.checkUpdate") return {supported:false,available:false,message:"Demo: no se comprueba actualización real."};
  if(method==="app.info") return {version:"0.4.1"};
  return {message:"Operación de demostración"};
 }};
});
await page.goto(base,{waitUntil:"domcontentloaded"});
await page.waitForTimeout(1500);
async function shot(file){await page.waitForTimeout(500);await page.screenshot({path:"../docs-site/screenshots/"+file,fullPage:true});}
async function go(label){const btn=page.getByRole("button",{name:label,exact:true}).first();await btn.waitFor({state:"visible",timeout:15000});await btn.evaluate(el=>el.click());await page.waitForTimeout(800);}
async function closeModal(){const close=page.getByRole("button",{name:"Cerrar",exact:true});if(await close.count()) await close.first().evaluate(el=>el.click());await page.waitForTimeout(250);}
await shot("01-inicio.png");
await go("Catálogo AppImage");await shot("02-catalogo.png");
const details=page.getByRole("button",{name:/Ver detalles/});if(await details.count()){await details.first().evaluate(el=>el.click());await page.waitForTimeout(350);await shot("03-ficha-app.png");await closeModal();}else await shot("03-ficha-app.png");
await go("Mis aplicaciones");await shot("04-mis-aplicaciones.png");
await go("Herramientas Punto Vuela");await shot("05-herramientas.png");
await go("Banco de recursos");await shot("06-recursos.png");
await go("FAQs de software");await shot("07-faqs.png");
await go("Contacto y propuestas");await shot("08-contacto.png");
await go("Ayuda y documentación");await shot("09-ayuda.png");
// Illustrative updater UI screenshots for the web guide (not a live update run).
const updaterPage=await browser.newPage({viewport:{width:900,height:680},deviceScaleFactor:1});
const modalHtml=`<!doctype html><html><body style="margin:0;background:#111923;font-family:Inter,Arial,sans-serif;color:#1b2632"><div style="display:grid;place-items:center;height:100vh;background:linear-gradient(135deg,#111923,#283646);"><div style="width:560px;background:#f7f8fa;border-radius:22px;box-shadow:0 25px 80px #0008;overflow:hidden"><div style="background:#202b38;color:white;padding:22px 26px"><small style="color:#f3d54e;font-weight:800;letter-spacing:.1em">ACTUALIZADOR · MODO DE PRUEBAS</small><h1 style="margin:10px 0 0;font-size:25px">Nueva versión disponible</h1></div><div style="padding:24px 26px"><div style="display:flex;justify-content:space-between;gap:20px"><div><small style="color:#66717d">VERSIÓN INSTALADA</small><h2 style="margin:5px 0">prueba-375</h2></div><div><small style="color:#66717d">NUEVA VERSIÓN</small><h2 style="margin:5px 0;color:#876d00">prueba-376</h2></div></div><p style="line-height:1.6;color:#566273">Hay una nueva versión de Puntos Vuela Toolkit. Se descargará desde GitHub Releases y se verificará su integridad antes de reemplazar la AppImage actual.</p><div style="border:1px solid #dce1e7;border-radius:12px;padding:14px;background:white"><strong>Verificación de seguridad</strong><p style="margin:6px 0;color:#647080">La descarga se validará mediante SHA-256 antes de instalar.</p></div><div style="margin-top:18px;border-radius:10px;background:#fff4c4;padding:12px;color:#6a5600;font-size:13px">Canal de pruebas: solo se proponen releases prueba-N superiores.</div></div><div style="display:flex;justify-content:flex-end;gap:10px;padding:14px 24px;background:#eef1f4"><button style="padding:12px 18px;border:1px solid #cbd3db;border-radius:9px;background:white">Más tarde</button><button style="padding:12px 18px;border:0;border-radius:9px;background:#202b38;color:white;font-weight:800">Actualizar ahora</button></div></div></div></body></html>`;
await updaterPage.setContent(modalHtml);await updaterPage.screenshot({path:"../docs-site/screenshots/10-updater-modal.png",fullPage:true});
const bannerHtml=`<!doctype html><html><body style="margin:0;padding:40px;background:#182330;font-family:Inter,Arial,sans-serif;color:#fff"><div style="border:1px solid #d9b900;border-radius:16px;padding:18px;display:flex;align-items:center;gap:14px;background:linear-gradient(115deg,#3a3420,#222c38);max-width:1000px"><div style="background:#f3d54e;color:#171d25;border-radius:12px;width:48px;height:48px;display:grid;place-items:center;font-size:22px;font-weight:900">↻</div><div style="flex:1"><strong style="font-size:17px">Actualización disponible · prueba-376</strong><div style="margin-top:5px;color:#b9c2cd;font-size:13px">La nueva versión está lista. Puedes actualizar cuando quieras.</div></div><button style="border:0;border-radius:10px;padding:13px 16px;background:#f3d54e;color:#171d25;font-weight:800">Actualizar ahora</button><button style="border:0;background:transparent;color:#9ca8b5;font-size:18px">×</button></div></body></html>`;
await updaterPage.setContent(bannerHtml);await updaterPage.screenshot({path:"../docs-site/screenshots/11-updater-banner.png",fullPage:true});await updaterPage.close();
await browser.close();
console.log("Capturas de UI generadas: 9");
