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
await browser.close();
console.log("Capturas de UI generadas: 9");
