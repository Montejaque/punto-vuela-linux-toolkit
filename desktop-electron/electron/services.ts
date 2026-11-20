import { app, shell } from "electron";
import { promises as fs } from "node:fs";
import path from "node:path";
import os from "node:os";
import { spawn } from "node:child_process";
import { createHash, randomUUID } from "node:crypto";

const DATA = path.join(process.env.XDG_DATA_HOME || path.join(os.homedir(), ".local", "share"), "punto-vuela-linux-toolkit");
const APP_DIR = path.join(DATA, "AppImages");
const CACHE = path.join(DATA, "cache");
const IMAGE_CACHE = path.join(os.homedir(), ".local", "share", "punto-vuela-linux-toolkit", "cache", "images");
const FEED = "https://appimage.github.io/feed.json";
const MAIL = "https://punto-vuela-mail.montejaque.workers.dev";
const UA = "PuntoVuelaLinuxToolkit-Electron/0.3";
const GLIBC_MAX = [2,31,0];

async function remoteFetch(input: string | URL, init: RequestInit = {}): Promise<Response> {
  try { return await fetch(input, init); }
  catch (error: any) {
    const host = new URL(String(input)).hostname;
    const detail = error?.cause?.code || error?.cause?.message || error?.message || "error de red";
    throw new Error(`No se pudo conectar con ${host}. Comprueba tu conexión a Internet o inténtalo más tarde. (${detail})`);
  }
}
async function getJson(url: string): Promise<any> {
  const response = await remoteFetch(url, { headers: { "user-agent": UA, accept: "application/json" }, signal: AbortSignal.timeout(60000) });
  if (!response.ok) throw new Error(`Error HTTP ${response.status} al consultar ${new URL(url).hostname}`);
  if (!new URL(response.url).protocol.startsWith("https")) throw new Error("La conexión ha dejado de ser HTTPS.");
  return response.json();
}
async function cachedJson(file: string, ttl: number, loader: () => Promise<any>, force = false): Promise<any> {
  let stale: any = null;
  try { const stat = await fs.stat(file); stale = JSON.parse(await fs.readFile(file,"utf8")); if (!force && Date.now()-stat.mtimeMs < ttl) return stale; } catch {}
  try {
    const value = await loader(); await fs.mkdir(path.dirname(file),{recursive:true});
    const tmp=file+".part"; await fs.writeFile(tmp,JSON.stringify(value)); await fs.rename(tmp,file); return value;
  } catch (error: any) {
    if (stale !== null) return stale;
    throw error;
  }
}
function ver(value: string): number[] | null { const m=value.match(/(\d+(?:\.\d+)*)/); return m?m[1].split(".").map(Number):null; }
function glibcCompatible(value: string): boolean { const v=ver(value); if(!v)return true; for(let i=0;i<3;i++){if((v[i]||0)!==(GLIBC_MAX[i]||0))return (v[i]||0)<(GLIBC_MAX[i]||0);} return true; }
function appimageAssetUrl(value:any):string {
  if(typeof value!=="string"||!value.trim()) return "";
  const raw=value.trim();
  try {
    const absolute=new URL(raw);
    if(absolute.protocol==="https:") return absolute.href;
    if(absolute.protocol==="http:") { absolute.protocol="https:"; return absolute.href; }
    return "";
  } catch {}
  // The feed can contain paths with or without the database/ prefix.
  const clean=raw.replace(/^\/+/,"").replace(/^database\//i,"").split("/").filter(part=>part&&part!=="."&&part!=="..").map(encodeURIComponent).join("/");
  return clean ? "https://appimage.github.io/database/"+clean : "";
}
function githubRepo(links:any[]): string { const l=(links||[]).find(x=>String(x.type).toLowerCase()==="github"); const value=String(l?.url||"").replace("https://github.com/","").replace(/\/$/,""); return /^[\w.-]+\/[\w.-]+$/.test(value)?value:""; }
function safeName(value:string):string { const name=path.basename(value).replace(/[^A-Za-z0-9._+-]/g,"-").replace(/^[-.]+|[-.]+$/g,""); if(!name)throw new Error("Nombre de archivo no válido."); return name.toLowerCase().endsWith(".appimage")?name.replace(/\.appimage$/i,"")+".AppImage":name+".AppImage"; }
function managedPath(file:string):string { const full=path.resolve(file); if(path.dirname(full)!==path.resolve(APP_DIR)||!full.toLowerCase().endsWith(".appimage"))throw new Error("La operación solo está permitida sobre AppImages de la carpeta administrada."); return full; }
async function download(url:string, filename?:string):Promise<string> {
  const u=new URL(url); if(u.protocol!=="https:")throw new Error("Solo se permiten descargas HTTPS.");
  await fs.mkdir(APP_DIR,{recursive:true}); const name=safeName(filename||path.basename(u.pathname)); const dest=managedPath(path.join(APP_DIR,name));
  try { await fs.access(dest); throw new Error("Ya existe una AppImage con ese nombre."); } catch(e:any) { if(e.message==="Ya existe una AppImage con ese nombre.")throw e; }
  const response=await remoteFetch(url,{headers:{"user-agent":UA},redirect:"follow",signal:AbortSignal.timeout(15*60*1000)});
  if(!response.ok||!response.url.startsWith("https://")||!response.body)throw new Error("No se pudo descargar el archivo desde un origen HTTPS.");
  const tmp=dest+".part"; const file=await fs.open(tmp,"wx"); let first=Buffer.alloc(0); let size=0;
  try { const reader=response.body.getReader(); while(true){const {done,value}=await reader.read();if(done)break;const chunk=Buffer.from(value);if(first.length<4)first=Buffer.concat([first,chunk]).subarray(0,4);size+=chunk.length;await file.write(chunk);} if(first.length!==4||first[0]!==0x7f||first.toString("ascii",1,4)!=="ELF"||size<1024*1024)throw new Error("El archivo descargado no es una AppImage ELF válida."); await file.close(); await fs.chmod(tmp,0o755); await fs.rename(tmp,dest); return dest; }
  catch(e){await file.close().catch(()=>{});await fs.rm(tmp,{force:true});throw e;}
}
async function desktopIntegrate(file:string,name?:string):Promise<string> {
  const full=managedPath(file); const safe=full.replace(/\\/g,"\\\\").replace(/"/g,'\\"'); const base=path.basename(full,".AppImage").replace(/[^A-Za-z0-9._-]/g,"-").toLowerCase();
  const dir=path.join(process.env.XDG_DATA_HOME||path.join(os.homedir(),".local","share"),"applications"); await fs.mkdir(dir,{recursive:true});
  const target=path.join(dir,`punto-vuela-${base}.desktop`); const label=(name||path.basename(full,".AppImage")).replace(/[\r\n]/g," ").trim();
  await fs.writeFile(target,`[Desktop Entry]\nType=Application\nName=${label}\nComment=Aplicación gestionada por Punto Vuela Toolkit\nExec="${safe}" %U\nIcon=application-x-executable\nTerminal=false\nCategories=Utility;\nStartupNotify=true\n`,{mode:0o644});
  return target;
}
async function cachedImage(url:string):Promise<string>{
  const target=new URL(url);
  if(target.protocol!=="https:")throw new Error("Solo se permiten imágenes HTTPS.");
  const cacheKey=createHash("sha256").update(target.href).digest("hex");
  await fs.mkdir(IMAGE_CACHE,{recursive:true});
  const file=path.join(IMAGE_CACHE,cacheKey+".img"), metaFile=file+".json", failureFile=file+".failed.json";
  const atomicWrite=async(targetFile:string,data:string|Buffer)=>{const tmp=targetFile+".tmp-"+randomUUID();await fs.writeFile(tmp,data);await fs.rename(tmp,targetFile);};
  // Persistent positive cache: valid icons survive app restarts and offline use.
  try{
    const bytes=await fs.readFile(file),meta=await fs.readFile(metaFile,"utf8").then(JSON.parse).catch(()=>null);
    if(meta&&meta.source===target.href&&/^image\/(png|jpeg|webp|gif|svg\+xml)$/.test(meta.mime)&&bytes.length>0&&bytes.length<=8*1024*1024)
      return "data:"+meta.mime+";base64,"+bytes.toString("base64");
  }catch{}
  // Persistent negative cache avoids repeatedly hitting known-broken URLs. Retry after 12h.
  try{
    const failed=JSON.parse(await fs.readFile(failureFile,"utf8"));
    if(failed.source===target.href&&Number(failed.failedAt)>0&&Date.now()-Number(failed.failedAt)<12*3600*1000)return "";
  }catch{}
  try{
    const response=await remoteFetch(target.href,{headers:{"user-agent":UA,"accept":"image/avif,image/webp,image/png,image/jpeg,image/svg+xml,*/*"},redirect:"follow",signal:AbortSignal.timeout(30000)});
    if(!response.ok||!response.url.startsWith("https://")||!response.body)throw new Error("No se pudo recuperar la imagen.");
    const mime=(response.headers.get("content-type")||"").split(";")[0].trim().toLowerCase();
    if(!/^image\/(png|jpeg|webp|gif|svg\+xml)$/.test(mime))throw new Error("El servidor no devolvió un formato de imagen admitido.");
    const reader=response.body.getReader(),chunks:Buffer[]=[];let size=0;
    while(true){const {done,value}=await reader.read();if(done)break;const chunk=Buffer.from(value);size+=chunk.length;if(size>8*1024*1024){await reader.cancel();throw new Error("La imagen supera el límite de caché de 8 MB.");}chunks.push(chunk);}
    const bytes=Buffer.concat(chunks);
    await atomicWrite(file,bytes);
    await atomicWrite(metaFile,JSON.stringify({mime,source:target.href,cachedAt:Date.now(),size:bytes.length}));
    await fs.rm(failureFile,{force:true}).catch(()=>{});
    return "data:"+mime+";base64,"+bytes.toString("base64");
  }catch(error:any){
    // Keep the initial-letter fallback visible, and store failure state across launches.
    await atomicWrite(failureFile,JSON.stringify({source:target.href,failedAt:Date.now(),reason:String(error?.message||"fetch failed").slice(0,240)})).catch(()=>{});
    return "";
  }
}
async function catalogSearch(query="",force=false):Promise<any[]> {
  const feed=await cachedJson(path.join(CACHE,"feed.json"),12*3600*1000,()=>getJson(FEED),force);
  if(!Array.isArray(feed.items))throw new Error("El feed oficial no tiene el formato esperado.");
  const needle=query.trim().toLocaleLowerCase("es");
  return feed.items.filter((x:any)=>String(x.name||"").trim()).map((x:any)=>{
    const links=x.links||[], categories=(x.categories||[]).filter(Boolean), author=x.authors?.[0]?.name||"", glibc=String(x.glibc_required||"");
    const desc=String(x.description||"").replace(/<[^>]*>/g," ").replace(/\s+/g," ").trim();
    return {name:String(x.name),description:desc.slice(0,500),category:categories[0]||"Sin categoría",categories,author,license:x.license||"No indicada",glibc:glibc||"No declarada",compatibleUbuntu20:glibcCompatible(glibc),compatibility:glibc&&!glibcCompatible(glibc)?"No compatible con Ubuntu 20.04":glibc?"Requisito glibc declarado compatible":"glibc no declarada; compatibilidad no garantizada",downloadUrl:links.find((l:any)=>String(l.type).toLowerCase()==="download")?.url||"",repository:githubRepo(links),catalogUrl:"https://appimage.github.io/"+encodeURIComponent(String(x.name))+"/",iconUrl:appimageAssetUrl(x.icons?.[0]),screenshotUrl:appimageAssetUrl(x.screenshots?.[0])};
  }).filter((x:any)=>!needle||[x.name,x.description,x.category,x.categories.join(" "),x.author].join(" ").toLocaleLowerCase("es").includes(needle)).slice(0,5000);
}
async function publicTools(force=false):Promise<any[]> {
  return cachedJson(path.join(CACHE,"tools.json"),6*3600*1000,async()=>{
    const repos=await getJson("https://api.github.com/users/Montejaque/repos?type=public&sort=updated&per_page=100"); const out=[];
    for(const repo of repos){if(repo.private||repo.archived||repo.disabled||!String(repo.full_name).startsWith("Montejaque/")||repo.name==="punto-vuela-linux-toolkit")continue;
      try{const [rel,details,readme]=await Promise.all([getJson(`https://api.github.com/repos/${repo.full_name}/releases/latest`),getJson(`https://api.github.com/repos/${repo.full_name}`),getJson(`https://api.github.com/repos/${repo.full_name}/readme`).catch(()=>null)]);const assets=(rel.assets||[]).filter((a:any)=>/\.appimage$/i.test(a.name));const a=assets.find((x:any)=>/(x86_64|amd64|x64)/i.test(x.name))||assets.find((x:any)=>!/(aarch64|arm64|armv7|armhf|i386|i686)/i.test(x.name));if(a){let readmeText="";if(readme?.content){try{readmeText=Buffer.from(readme.content,"base64").toString("utf8");}catch{}}const lic=details.license?.spdx_id&&details.license.spdx_id!=="NOASSERTION"?details.license.spdx_id:details.license?.name||"Consultar repositorio";const about=readmeText.match(/(?:ubuntu\s*20\.04|ubuntu\s*20|glibc\s*2\.31|glibc\s*2\.3[01]|ubuntu\s*20\.04\s*y\s*superiores)/i);const incompat=/(?:not\s+compatible\s+with\s+ubuntu\s*20|ubuntu\s*20.{0,30}(?:not\s+supported|unsupported)|glibc\s*2\.(?:32|3\d|[4-9]\d))/i.test(readmeText);const compat=incompat?"La documentación indica incompatibilidad con Ubuntu 20.04":about?`Compatibilidad declarada en README: ${about[0]}`:"No especificada en README (consultar repositorio)";out.push({name:String(repo.name).replace(/[-_]/g," "),repository:repo.full_name,repositoryUrl:repo.html_url,description:repo.description||"Herramienta publicada por Montejaque.",iconUrl:repo.owner?.avatar_url||"",author:details.owner?.login||repo.owner?.login||"Montejaque",license:lic,compatibility:compat,glibc:"",compatibleUbuntu20:incompat?false:undefined,category:"Herramientas Punto Vuela",version:rel.tag_name||"",releaseUrl:rel.html_url,downloadUrl:a.browser_download_url,assetName:a.name});}}catch{}
    } return out;
  },force);
}
async function installed():Promise<any[]> {
  await fs.mkdir(APP_DIR,{recursive:true}); const files=await fs.readdir(APP_DIR,{withFileTypes:true}); const rows=[];
  for(const f of files){if(!f.isFile()||!f.name.toLowerCase().endsWith(".appimage"))continue;const p=path.join(APP_DIR,f.name);const s=await fs.stat(p);rows.push({name:f.name.replace(/\.appimage$/i,""),path:p,size:s.size,executable:!!(s.mode&0o111),modified:s.mtime.toISOString()});}return rows;
}
async function updateCheck(file:string):Promise<any>{
  const p=managedPath(file); const tool=path.join(DATA,"tools","appimageupdatetool-x86_64.AppImage");
  try{await fs.access(tool);}catch{throw new Error("AppImageUpdate no está instalado. La actualización solo funciona para AppImages con metadatos compatibles.");}
  return new Promise((resolve,reject)=>{const child=spawn(tool,["--appimage-extract-and-run","-j",p],{stdio:["ignore","pipe","pipe"]});let out="";child.stdout.on("data",d=>out+=d);child.stderr.on("data",d=>out+=d);child.on("error",reject);child.on("close",code=>resolve({supported:code===0||code===1,available:code===1,message:out.trim()|| (code===0?"No hay actualizaciones.":code===1?"Hay una actualización disponible.":"No se pudo comprobar esta AppImage.")}));});
}
async function updaterInstall():Promise<string>{
  const dir=path.join(DATA,"tools"),file=path.join(dir,"appimageupdatetool-x86_64.AppImage");await fs.mkdir(dir,{recursive:true});
  try{await fs.access(file);return file;}catch{}
  const rel=await getJson("https://api.github.com/repos/AppImageCommunity/AppImageUpdate/releases/tags/continuous");const asset=rel.assets?.find((a:any)=>a.name==="appimageupdatetool-x86_64.AppImage");if(!asset?.digest?.startsWith("sha256:"))throw new Error("GitHub no proporciona SHA-256 verificable para AppImageUpdate.");
  const response=await remoteFetch(asset.browser_download_url,{headers:{"user-agent":UA}});if(!response.ok||!response.url.startsWith("https://"))throw new Error("No se pudo descargar AppImageUpdate de forma segura.");
  const bytes=Buffer.from(await response.arrayBuffer());const digest=createHash("sha256").update(bytes).digest("hex");if(digest!==asset.digest.slice(7))throw new Error("La verificación SHA-256 de AppImageUpdate ha fallado.");if(bytes.subarray(0,4).toString("hex")!=="7f454c46")throw new Error("El actualizador no es un ejecutable ELF.");
  await fs.writeFile(file,bytes,{mode:0o755});return file;
}
export async function api(method:string,args:any={}):Promise<any>{
  switch(method){
    case "cache.init": await fs.mkdir(IMAGE_CACHE,{recursive:true}); return {path:IMAGE_CACHE,created:true};
    case "images.cache": return cachedImage(String(args.url||""));
    case "catalog.search": return catalogSearch(args.query||"",!!args.force);
    case "tools.list": return publicTools(!!args.force);
    case "apps.list": return installed();
    case "apps.folder": await fs.mkdir(APP_DIR,{recursive:true}); return shell.openPath(APP_DIR);
    case "apps.install": {const all=await catalogSearch(args.name);const item=all.find(x=>x.name.toLocaleLowerCase()===String(args.name).toLocaleLowerCase());if(!item)throw new Error("Aplicación no encontrada en el catálogo.");if(!item.compatibleUbuntu20)throw new Error("La aplicación declara una glibc superior a 2.31 y se bloquea su instalación en Ubuntu 20.04.");let url=item.downloadUrl,name=item.name;if(item.repository){const rel=await getJson(`https://api.github.com/repos/${item.repository}/releases/latest`);const assets=(rel.assets||[]).filter((a:any)=>/\.appimage$/i.test(a.name));const a=assets.find((x:any)=>/(x86_64|amd64|x64)/i.test(x.name))||assets.find((x:any)=>!/(aarch64|arm64|armv7|armhf|i386|i686)/i.test(x.name));if(!a)throw new Error("La última Release no contiene AppImage x86_64.");url=a.browser_download_url;name=a.name;}if(!url)throw new Error("No hay enlace directo de descarga para esta aplicación.");const p=await download(url,name);await desktopIntegrate(p,item.name);return {ok:true,path:p,message:item.name+" descargada e integrada en el menú de aplicaciones."};}
    case "tools.install": {const items=await publicTools();const item=items.find(x=>x.repository===args.repository);if(!item)throw new Error("La herramienta ya no está disponible.");const p=await download(item.downloadUrl,item.assetName);await desktopIntegrate(p,item.name);return {ok:true,path:p,message:item.name+" descargada e integrada en el menú."};}
    case "apps.launch": {const p=managedPath(args.path);await fs.access(p);await fs.chmod(p,0o755);const child=spawn(p,[],{detached:true,stdio:"ignore"});child.unref();return {ok:true,message:"Aplicación iniciada."};}
    case "apps.permissions": {const p=managedPath(args.path);await fs.chmod(p,0o755);return {ok:true,message:"Permisos de ejecución aplicados."};}
    case "apps.remove": {const p=managedPath(args.path);await fs.rm(p);const base=path.basename(p,".AppImage").replace(/[^A-Za-z0-9._-]/g,"-").toLowerCase();const desk=path.join(process.env.XDG_DATA_HOME||path.join(os.homedir(),".local","share"),"applications",`punto-vuela-${base}.desktop`);await fs.rm(desk,{force:true});return {ok:true,message:"AppImage eliminada."};}
    case "apps.checkUpdate": await updaterInstall(); return updateCheck(args.path);
    case "apps.update": {const p=managedPath(args.path);await updaterInstall();const check=await updateCheck(p);if(!check.supported)throw new Error(check.message);if(!check.available)return {updated:false,message:check.message};const result=await new Promise<any>((resolve,reject)=>{const child=spawn(path.join(DATA,"tools","appimageupdatetool-x86_64.AppImage"),["--appimage-extract-and-run","--overwrite",p]);let out="";child.stdout.on("data",d=>out+=d);child.stderr.on("data",d=>out+=d);child.on("error",reject);child.on("close",code=>code===0?resolve({updated:true,message:out||"AppImage actualizada."}):reject(new Error(out||"Error al actualizar.")));});await fs.access(p);return result;}
    case "tools.openExternal": {const u=new URL(args.url);if(u.protocol!=="https:")throw new Error("Solo se pueden abrir enlaces HTTPS.");await shell.openExternal(u.href);return {ok:true};}
    case "mail.health": {const response=await remoteFetch(MAIL+"/health",{headers:{"accept":"application/json"},signal:AbortSignal.timeout(15000)});if(!response.ok)throw new Error("El servicio de correo responde HTTP "+response.status);return response.json();}
    case "mail.send": {const response=await remoteFetch(MAIL,{method:"POST",headers:{"content-type":"application/json","accept":"application/json"},body:JSON.stringify(args.data),signal:AbortSignal.timeout(30000)});const result=await response.json().catch(()=>({ok:false,message:"Respuesta no válida del servicio de correo."}));if(!response.ok||!result.ok)throw new Error(result.message||"No se pudo enviar la solicitud.");return result;}
    case "centres.list": {
      const cacheFile=path.join(CACHE,"centres.json");
      const rows=await cachedJson(cacheFile,7*24*3600*1000,async()=>{
        const load=async(page:number)=>{const url=page===1?"https://puntosvuela.es/centros":`https://puntosvuela.es/centros?page=${page}`;const response=await remoteFetch(url,{headers:{"user-agent":UA},signal:AbortSignal.timeout(30000)});if(!response.ok)throw new Error("Error consultando el directorio de centros.");return response.text();};
        const first=await load(1);const last=Math.max(1,...[...first.matchAll(/[?&]page=(\d+)/g)].map(m=>Number(m[1])));
        const pages=[first,...await Promise.all(Array.from({length:Math.max(0,last-1)},(_,i)=>load(i+2)))];
        const result=new Map<string,any>();
        for(const html of pages){const matches=[...html.matchAll(/<h[2-6][^>]*>\s*<a[^>]*href=["']([^"']*\/centros\/([^"'/?#]+))["'][^>]*>(.*?)<\/a>\s*<\/h[2-6]>([\s\S]*?)(?=<h[2-6]|$)/gi)];
          for(const m of matches){const clean=(s:string)=>s.replace(/<[^>]*>/g," ").replace(/&nbsp;/g," ").replace(/&amp;/g,"&").replace(/\s+/g," ").trim();const name=clean(m[3]),slug=m[2],details=clean(m[4]);const paragraphs=[...m[4].matchAll(/<p[^>]*>([\s\S]*?)<\/p>/gi)].map(p=>clean(p[1]));const postal=paragraphs.find(p=>/\(\d{5}\)/.test(p))||"";const municipality=postal?postal.replace(/\s*\(\d{5}\)\s*/,"").trim():"";const province=paragraphs.find(p=>["almería","cádiz","córdoba","granada","huelva","jaén","málaga","sevilla"].includes(p.toLocaleLowerCase("es")))||"";if(name)result.set(slug,{name,slug,details,municipality,province:province?province[0].toLocaleUpperCase("es")+province.slice(1):"",url:"https://puntosvuela.es/centros/"+slug});}
        }return [...result.values()];
      });return rows;
    }
    case "centres.details": {
      const slug=String(args.slug||"").replace(/^\/+|\/+$/g,"");if(!/^[\w-]+$/u.test(slug))throw new Error("Ficha de centro no válida.");
      const response=await remoteFetch("https://puntosvuela.es/centros/"+encodeURIComponent(slug),{headers:{"user-agent":UA},signal:AbortSignal.timeout(30000)});if(!response.ok)throw new Error("No se pudo abrir la ficha del centro.");const html=await response.text();
      const text=html.replace(/<(script|style|noscript)[\s\S]*?<\/\1>/gi," ").replace(/<[^>]*>/g," ").replace(/&nbsp;/g," ").replace(/&amp;/g,"&").replace(/\s+/g," ");
      const contact=text.match(/Información de contacto\s+(.*?)\s+Agentes de innovación local/i);const ail=text.match(/Agentes de innovación local\s+(.+?)(?:\s+Horario de apertura|\s+Verificar disponibilidad|\s+Te estamos esperando)/i);
      if(!contact||!ail)throw new Error("La ficha no contiene datos de contacto reconocibles.");
      const emails=[...contact[1].matchAll(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/gi)].map(m=>m[0]);const phones=[...contact[1].matchAll(/(?<!\d)(?:\+34[\s.-]?)?[6789](?:[\s()./-]*\d){8}(?!\d)/g)].map(m=>m[0].replace(/\s+/g," ").trim());
      return {slug,ail:ail[1].trim(),phone:[...new Set(phones)].join(" / "),email:emails[0]||"",sourceUrl:"https://puntosvuela.es/centros/"+encodeURIComponent(slug)};
    }
    case "app.info": return {version:app.getVersion(),platform:process.platform,appImagesDirectory:APP_DIR};
    default: throw new Error("Operación no reconocida.");
  }
}
