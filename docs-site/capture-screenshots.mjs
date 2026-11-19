import { chromium } from "playwright";
import { mkdir } from "node:fs/promises";
const base="http://127.0.0.1:5173";
await mkdir("docs-site/screenshots",{recursive:true});
const browser=await chromium.launch({headless:true});
const page=await browser.newPage({viewport:{width:1440,height:1024},deviceScaleFactor:1});
await page.addInitScript(()=>{
 const catalog=[
  {name:"LibreOffice",description:"Suite of office tools for documents, spreadsheets and presentations.",category:"Oficina",categories:["Oficina"],author:"The Document Foundation",license:"MPL-2.0",glibc:"2.31",compatibleUbuntu20:true,compatibility:"Ubuntu 20.04 o posterior (referencia declarada)",iconUrl:"",version:"24.2",repository:"https://github.com/LibreOffice"},
  {name:"GIMP",description:"Editor de imágenes libre para retoque, composición y creación.",category:"Diseño",categories:["Diseño"],author:"GIMP Team",license:"GPL-3.0",glibc:"2.31",compatibleUbuntu20:true,compatibility:"Compatibilidad declarada por el catálogo",iconUrl:"",version:"3.0",repository:"https://www.gimp.org"},
  {name:"Inkscape",description:"Editor vectorial de código abierto.",category:"Diseño",categories:["Diseño"],author:"Inkscape Project",license:"GPL-3.0",glibc:"2.31",compatibleUbuntu20:true,compatibility:"Compatibilidad declarada por el catálogo",iconUrl:"",version:"1.4",repository:"https://inkscape.org"}
 ];
 const tool=[{name:"Punto Vuela Toolkit",description:"Centro de aplicaciones y recursos Linux de Punto Vuela.",category:"Punto Vuela",author:"Francisco Javier Gallego Orellana",license:"MIT",compatibility:"Linux x86_64",version:"0.4.1",iconUrl:"",repository:"https://github.com/Montejaque/punto-vuela-linux-toolkit",repositoryUrl:"https://github.com/Montejaque/punto-vuela-linux-toolkit"}];
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
await page.goto(base,{waitUntil:"networkidle"});
await page.screenshot({path:"docs-site/screenshots/01-inicio.png",fullPage:true});
async function clickNav(label){await page.getByRole("button",{name:label,exact:true}).first().click();await page.waitForTimeout(400);}
await clickNav("Catálogo AppImage");
await page.screenshot({path:"docs-site/screenshots/02-catalogo.png",fullPage:true});
await page.getByRole("button",{name:/Ver detalles/}).first().click();
await page.waitForTimeout(200);
await page.screenshot({path:"docs-site/screenshots/03-ficha-app.png",fullPage:true});
await page.getByRole("button",{name:"Cerrar"}).first().click();
await clickNav("Mis aplicaciones");
await page.screenshot({path:"docs-site/screenshots/04-mis-aplicaciones.png",fullPage:true});
await clickNav("Herramientas Punto Vuela");
await page.screenshot({path:"docs-site/screenshots/05-herramientas.png",fullPage:true});
await clickNav("Banco de recursos");
await page.screenshot({path:"docs-site/screenshots/06-recursos.png",fullPage:true});
await clickNav("FAQs de software");
await page.screenshot({path:"docs-site/screenshots/07-faqs.png",fullPage:true});
await clickNav("Contacto y propuestas");
await page.getByLabel("Centro Punto Vuela *").selectOption("montejaque").catch(()=>{});
await page.waitForTimeout(500);
await page.screenshot({path:"docs-site/screenshots/08-contacto.png",fullPage:true});
await clickNav("Ayuda y documentación");
await page.screenshot({path:"docs-site/screenshots/09-ayuda.png",fullPage:true});
await browser.close();
console.log("Captured 9 UI screenshots with demo data.");
