import { app, BrowserWindow, shell, ipcMain, dialog, Menu } from "electron";
import { join, dirname } from "node:path";
import { promises as fs } from "node:fs";
import { createHash } from "node:crypto";
import { spawn } from "node:child_process";
import { api } from "./services";

const isDevelopment = !app.isPackaged;
const allowed = new Set(["catalog.search","tools.list","apps.list","apps.folder","apps.install","tools.install","apps.launch","apps.permissions","apps.remove","apps.checkUpdate","apps.update","tools.openExternal","mail.send","mail.health","centres.list","centres.details","app.info","images.cache"]);
const REPO = "Montejaque/punto-vuela-linux-toolkit";
const UPDATE_BASE = "https://api.github.com/repos/" + REPO;
const markerPath = () => join(app.getPath("userData"), "update-pending.json");
let pendingUpdaterAction: {window: BrowserWindow; version: string; asset: any; checksums: any; legacy?: boolean; releaseUrl?: string; testMode?: boolean; current?: string} | null = null;



function showUpdaterModal(parent: BrowserWindow, options: { title: string; version: string; current?: string; testMode?: boolean; legacy?: boolean; description?: string; changelog?: string }): Promise<"update"|"later"|"release"> {
  return new Promise(resolve => {
    const modal = new BrowserWindow({ width: 560, height: 470, minWidth: 560, minHeight: 470, maxWidth: 560, maxHeight: 470, resizable: false, modal: true, parent, show: false, frame: false, title: options.title, backgroundColor: "#f7f8fa", webPreferences: { contextIsolation: true, nodeIntegration: false, sandbox: true } });
    let settled = false;
    const finish = (action: "update"|"later"|"release") => { if (settled) return; settled=true; resolve(action); if (!modal.isDestroyed()) modal.close(); };
    modal.once("ready-to-show", () => modal.show());
    modal.webContents.on("will-navigate", (event, url) => { if (url.startsWith("pvu-updater://")) { event.preventDefault(); const action=url.replace("pvu-updater://",""); if(action==="update"||action==="later"||action==="release") finish(action); } else event.preventDefault(); });
    modal.on("closed",()=>{if(!settled){settled=true;resolve("later");}});
    const testBadge=options.testMode?'<span class="badge">CANAL DE PRUEBAS</span>':'';
    const current=options.current?'<div class="version-row"><span>Versión instalada</span><b>'+options.current+'</b></div>':'';
    const changelogHtml=options.changelog?'<div class="changes"><strong>Novedades de esta versión</strong><ul>'+options.changelog.split(/\\r?\\n/).map(line=>line.trim()).filter(line=>line.startsWith("- ")||line.startsWith("* ")).slice(0,3).map(line=>'<li>'+line.slice(2).replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;")+'</li>').join("")+'</ul></div>':'';
    const updateButton='<a class="primary" href="pvu-updater://update"><span class="arrow">↻</span> Actualizar ahora</a>';
    const html='<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width"><style>*{box-sizing:border-box}body{margin:0;overflow:hidden;background:#f6f7f9;color:#17212b;font-family:Inter,system-ui,-apple-system,Segoe UI,sans-serif}.wrap{padding:20px 26px 18px}.modal-head{display:flex;align-items:center;justify-content:space-between;margin:-20px -26px 18px;padding:11px 16px;background:#17212b;color:#fff;font-size:12px;font-weight:750;letter-spacing:.02em;-webkit-app-region:drag}.modal-close{border:0;background:transparent;color:#fff;font-size:20px;text-decoration:none;cursor:pointer;-webkit-app-region:no-drag}.top{display:flex;align-items:center;gap:14px}.icon{width:52px;height:52px;border-radius:16px;background:#f0cf00;display:grid;place-items:center;font-size:32px;font-weight:900;color:#121820;box-shadow:0 5px 18px #0001}.badge{font-size:10px;font-weight:800;letter-spacing:.12em;color:#806600;background:#fff1b4;padding:7px 10px;border-radius:999px}.eyebrow{font-size:11px;color:#71808e;font-weight:750;letter-spacing:.13em;text-transform:uppercase;margin-top:15px}.h{font-size:23px;font-weight:850;letter-spacing:-.04em;margin:8px 0 6px}.desc{font-size:14px;line-height:1.4;color:#52616d;margin:0 0 14px}.version-row{display:flex;justify-content:space-between;align-items:center;background:white;border:1px solid #e3e7eb;border-radius:12px;padding:11px 13px;margin-bottom:14px;color:#65717b;font-size:13px}.version-row b{color:#18212b;font-size:14px}.safe{display:flex;gap:9px;align-items:flex-start;font-size:12px;line-height:1.4;color:#677581;margin-bottom:14px}.safe .check{color:#17834b;font-size:16px;font-weight:900}.actions{display:flex;justify-content:flex-end;gap:10px}.actions a{border-radius:11px;padding:11px 16px;font-size:13px;font-weight:750;text-decoration:none;cursor:pointer}.primary{background:#171e26;color:white}.primary:hover{background:#2a3542}.secondary{background:#e9edf0;color:#26323d}.changes{background:#fff;border:1px solid #e3e7eb;border-radius:12px;padding:10px 12px;margin:0 0 12px;font-size:12px;color:#465663}.changes strong{font-size:12px;color:#17212b}.changes ul{margin:7px 0 0;padding-left:18px}.changes li{margin:3px 0;line-height:1.35}.footer{margin-top:14px;padding-top:11px;border-top:1px solid #e4e8eb;color:#89939c;font-size:11px}</style></head><body><div class="wrap"><div class="modal-head"><span>PUNTOS VUELA TOOLKIT · ACTUALIZADOR</span><a class="modal-close" href="pvu-updater://later" aria-label="Cerrar">×</a></div><div class="top"><div class="icon">V</div>'+testBadge+'</div><div class="eyebrow">'+(options.legacy?"Actualización de pruebas disponible":"Actualización disponible")+'</div><div class="h">'+("Puntos Vuela Toolkit · "+options.version)+'</div><p class="desc">'+(options.description||("Hay una nueva versión disponible. Descarga y verificación se realizarán antes de reemplazar la AppImage."))+'</p>'+current+changelogHtml+'<div class="safe"><span class="check">✓</span><span>La descarga se verifica con SHA-256 y se conserva una copia de la versión actual para poder recuperarla si el inicio de la nueva falla.</span></div><div class="actions">'+updateButton+'<a class="secondary" href="pvu-updater://later">'+("Más tarde")+'</a></div><div class="footer">Actualizador oficial · Puntos Vuela Toolkit</div></div></body></html>';
    void modal.loadURL("data:text/html;charset=utf-8,"+encodeURIComponent(html));
  });
}

function createWindow(): BrowserWindow {
  const window = new BrowserWindow({
    width: 1440, height: 920, minWidth: 760, minHeight: 600, show: false, autoHideMenuBar: true,
    backgroundColor: "#171d25", title: "Puntos Vuela Toolkit", icon: join(__dirname, "../dist/assets/logo_toolkit.svg"),
    webPreferences: {
      preload: join(__dirname, "preload.js"),
      contextIsolation: true, nodeIntegration: false, sandbox: true,
      webSecurity: true
    }
  });
  window.once("ready-to-show", () => { window.maximize(); window.show(); });
  window.webContents.once("did-finish-load", async () => {
    if (process.argv.includes("--smoke-test")) setTimeout(() => app.exit(0), 750);
    await confirmSuccessfulStartup();
    if (!isDevelopment && !process.argv.includes("--smoke-test")) setTimeout(() => void checkUpdates(window), 5000);
  });
  window.webContents.setWindowOpenHandler(({ url }) => {
    if (url.startsWith("https://punto-vuela-mail.montejaque.workers.dev/turnstile")) {
      return { action: "allow", overrideBrowserWindowOptions: { width: 430, height: 270, resizable: false, minimizable: false, maximizable: false, autoHideMenuBar: true, backgroundColor: "#ffffff" } };
    }
    if (url.startsWith("https://")) void shell.openExternal(url);
    return { action: "deny" };
  });
  window.webContents.on("will-navigate", (event, url) => {
    const allowedUrl = isDevelopment ? url.startsWith("http://127.0.0.1:5173") : url.startsWith("file://");
    if (!allowedUrl) event.preventDefault();
  });
  if (isDevelopment) void window.loadURL("http://127.0.0.1:5173");
  else void window.loadFile(join(__dirname, "../dist/index.html"));
  return window;
}

async function confirmSuccessfulStartup(): Promise<void> {
  try {
    const marker = JSON.parse(await fs.readFile(markerPath(), "utf8"));
    if (marker?.backup && await fs.access(marker.backup).then(()=>true).catch(()=>false)) {
      await fs.rm(markerPath(), {force:true});
      await fs.rm(marker.backup, {force:true});
    }
  } catch {}
}

async function recoverPreviousVersion(): Promise<void> {
  if (!process.env.APPIMAGE) return;
  try {
    const marker = JSON.parse(await fs.readFile(markerPath(), "utf8"));
    if (!marker?.backup || !await fs.access(marker.backup).then(()=>true).catch(()=>false)) return;
    // First launch after replacement: arm the rollback watchdog and allow startup.
    if (!marker.started) {
      marker.started = true;
      await fs.writeFile(markerPath(), JSON.stringify(marker));
      return;
    }
    // If a launch was armed but never reached the renderer-ready checkpoint,
    // restore the previous image on the next invocation.
    const current = process.env.APPIMAGE;
    const failed = current + ".failed";
    await fs.rename(current, failed);
    await fs.rename(marker.backup, current);
    await fs.rm(failed, {force:true});
    await fs.rm(markerPath(), {force:true});
    spawn(current, [], {detached:true, stdio:"ignore"}).unref();
    app.exit(0);
  } catch {}
}

function releaseVersion(tag: string, testMode = false): string | null {
  const match = tag.match(/^v?(\d+\.\d+\.\d+)(?:-([0-9A-Za-z.-]+))?$/);
  if (!match || (match[2] && !testMode)) return null;
  return match[1] + (match[2] ? "-" + match[2] : "");
}

function compareVersions(a: string, b: string): number {
  const [aBase, aPre] = a.split("-", 2), [bBase, bPre] = b.split("-", 2);
  const pa = aBase.split(".").map(Number), pb = bBase.split(".").map(Number);
  for (let i = 0; i < 3; i++) {
    const x = pa[i] || 0, y = pb[i] || 0;
    if (x !== y) return x > y ? 1 : -1;
  }
  if (!aPre && bPre) return 1;
  if (aPre && !bPre) return -1;
  if (aPre === bPre) return 0;
  return aPre! > bPre! ? 1 : -1;
}

function appImageAssetForArch(assets: any[]): any | undefined {
  const arch = process.arch === "arm64" ? "arm64" : process.arch === "x64" ? "x86_64" : process.arch;
  const suffix = "-" + arch + ".AppImage";
  return assets.find((asset: any) =>
    typeof asset.name === "string" &&
    asset.name.includes("Puntos_Vuela_Toolkit-Electron") &&
    asset.name.endsWith(suffix)
  );
}

async function checkUpdates(window: BrowserWindow): Promise<void> {
  const testMode = process.argv.includes("--updater-test");
  try {
    const response = await fetch(UPDATE_BASE + "/releases?per_page=20", {
      headers: { "Accept": "application/vnd.github+json", "User-Agent": "Puntos-Vuela-Toolkit-Updater" },
      signal: AbortSignal.timeout(15000)
    });
    if (!response.ok) return;

    const releases: any[] = await response.json();
    const current = app.getVersion();
    const candidates = releases
      .filter((candidate: any) => !candidate.draft && (testMode ? candidate.prerelease : !candidate.prerelease))
      .map((candidate: any) => ({
        release: candidate,
        version: releaseVersion(String(candidate.tag_name || ""), testMode),
        assets: candidate.assets || []
      }))
      .filter((candidate: any) => candidate.version && compareVersions(candidate.version, current) > 0)
      .map((candidate: any) => ({
        ...candidate,
        appImage: appImageAssetForArch(candidate.assets),
        checksums: candidate.assets.find((asset: any) => asset.name === "SHA256SUMS")
      }))
      .filter((candidate: any) => candidate.appImage && candidate.checksums)
      .sort((a: any, b: any) => compareVersions(b.version, a.version));

    const candidate = candidates[0];
    if (!candidate && testMode) {
      const legacyTestRelease = releases
        .filter((release: any) => !release.draft && release.prerelease && /^pruebas-\d+$/i.test(String(release.tag_name || "")))
        .filter((release: any) => appImageAssetForArch(release.assets || []) && (release.assets || []).some((asset: any) => asset.name === "SHA256SUMS"))
        .sort((a: any, b: any) => Date.parse(b.published_at || b.created_at || 0) - Date.parse(a.published_at || a.created_at || 0))[0];
      if (legacyTestRelease) {
        const testAsset = appImageAssetForArch(legacyTestRelease.assets || []);
        const testChecksums = (legacyTestRelease.assets || []).find((asset: any) => asset.name === "SHA256SUMS");
        const testVersion = String(legacyTestRelease.tag_name);
        pendingUpdaterAction = { window, version: testVersion, asset: testAsset, checksums: testChecksums, releaseUrl: legacyTestRelease.html_url, testMode: true };
        const action = await showUpdaterModal(window, { title: "Actualizador · canal de pruebas", version: testVersion, current, testMode: true, legacy: true, description: "Hay una versión de pruebas descargable. Pulsa Actualizar ahora para descargarla, verificar SHA-256 y sustituir la AppImage con copia de recuperación.", changelog: String(legacyTestRelease.body || "") });
        if (action === "update") await performUpdate(window, testAsset, testChecksums, testVersion);
        else { pendingUpdaterAction = { window, version: testVersion, asset: testAsset, checksums: testChecksums, releaseUrl: legacyTestRelease.html_url, testMode: true }; window.webContents.send("pv:updater-banner", { version: testVersion, kind: "test", releaseUrl: legacyTestRelease.html_url }); }
        return;
      }
    }
    if (!candidate) return;

    const latest = candidate.version;
    const appImageAsset = candidate.appImage;
    const checksumAsset = candidate.checksums;
    pendingUpdaterAction = { window, version: latest, asset: appImageAsset, checksums: checksumAsset, testMode };
    const action = await showUpdaterModal(window, { title: testMode ? "Actualizador · pruebas" : "Nueva versión disponible", version: latest, current, testMode, description: "Está disponible la versión " + latest + ". Pulsa Actualizar ahora para descargarla, comprobar su integridad y sustituir la AppImage de forma segura.", changelog: String(candidate.release.body || "") });
    if (action === "update") await performUpdate(window, appImageAsset, checksumAsset, latest);
    else { pendingUpdaterAction = { window, version: latest, asset: appImageAsset, checksums: checksumAsset, testMode }; window.webContents.send("pv:updater-banner", { version: latest, kind: testMode ? "test" : "stable" }); }
  } catch (error: any) {
    console.warn("Updater:", error?.message || error);
  }
}

function showUpdateReadyModal(parent:BrowserWindow,version:string):Promise<"restart"|"later">{
  return new Promise(resolve=>{
    const modal=new BrowserWindow({width:500,height:360,minWidth:500,minHeight:360,maxWidth:500,maxHeight:360,resizable:false,modal:true,parent,show:false,frame:false,title:"Actualización preparada",backgroundColor:"#f7f8fa",webPreferences:{contextIsolation:true,nodeIntegration:false,sandbox:true}});
    let settled=false;
    const finish=(choice:"restart"|"later")=>{if(settled)return;settled=true;resolve(choice);if(!modal.isDestroyed())modal.close();};
    modal.once("ready-to-show",()=>modal.show());
    modal.webContents.on("will-navigate",(event,url)=>{event.preventDefault();if(url.startsWith("pvu-ready://")){const choice=url.replace("pvu-ready://","");if(choice==="restart"||choice==="later")finish(choice);}});
    modal.on("closed",()=>{if(!settled){settled=true;resolve("later");}});
    const html='<!doctype html><html><head><meta charset="utf-8"><style>*{box-sizing:border-box}body{margin:0;overflow:hidden;background:#f6f7f9;color:#17212b;font-family:Inter,system-ui,sans-serif}.wrap{height:360px;padding:22px;display:flex;flex-direction:column;justify-content:center;overflow:hidden}.top{display:flex;align-items:center;gap:14px}.icon{width:54px;height:54px;background:#f0cf00;border-radius:16px;display:grid;place-items:center;font-size:32px;font-weight:900}.title{font-weight:850;font-size:21px;margin-top:18px}.text{font-size:14px;line-height:1.5;color:#586775;margin-top:8px}.status{display:flex;align-items:center;gap:9px;background:#fff;border:1px solid #e1e6eb;padding:12px;border-radius:12px;margin-top:16px;font-size:13px}.check{color:#158348;font-weight:900}.buttons{display:flex;gap:10px;margin-top:20px}.buttons a{flex:1;text-align:center;padding:12px;border-radius:10px;text-decoration:none;font-size:13px;font-weight:800}.primary{background:#17212b;color:white}.secondary{background:#e9edf0;color:#26323d}</style></head><body><div class="wrap"><div class="top"><div class="icon">V</div><div><b>PUNTOS VUELA TOOLKIT</b><br><small>ACTUALIZADOR</small></div></div><div class="title">Actualización lista para instalar</div><p class="text">La versión '+version+' se ha descargado y verificado correctamente. Se ha guardado una copia de seguridad para poder recuperar la versión anterior si el inicio falla.</p><div class="status"><span class="check">✓</span> Descarga completa · SHA-256 verificado · Copia de seguridad creada</div><div class="buttons"><a class="primary" href="pvu-ready://restart">Reiniciar ahora</a><a class="secondary" href="pvu-ready://later">Reiniciar más tarde</a></div></div></body></html>';
    void modal.loadURL("data:text/html;charset=utf-8,"+encodeURIComponent(html));
  });
}

function showDownloadProgress(parent:BrowserWindow):{window:BrowserWindow;update:(percent:number,message:string)=>void;close:()=>void}{
  const win=new BrowserWindow({width:430,height:330,minWidth:430,minHeight:330,maxWidth:430,maxHeight:330,resizable:false,modal:true,parent,show:false,frame:false,title:"Actualizando Puntos Vuela Toolkit",backgroundColor:"#e9edf1",webPreferences:{contextIsolation:true,nodeIntegration:false,sandbox:true}});
  const html='<!doctype html><html><head><meta charset="utf-8"><style>*{box-sizing:border-box}body{margin:0;background:#e9edf1;color:#17212b;font-family:Inter,system-ui,sans-serif}.wrap{height:330px;display:flex;flex-direction:column;align-items:center;justify-content:center;padding:22px}.ring{width:156px;height:156px;position:relative;display:grid;place-items:center}.ring svg{position:absolute;inset:0;transform:rotate(-90deg)}.logo{width:78px;height:78px;border-radius:22px;background:#f0cf00;display:grid;place-items:center;font-size:48px;font-weight:950;color:#101820;box-shadow:0 6px 20px #0002}.pct{font-size:14px;font-weight:800;margin-top:14px}.msg{font-size:13px;color:#596775;text-align:center;margin-top:8px;min-height:20px}.track{stroke:#d1d8de}.progress{stroke:#f0cf00;stroke-linecap:round;transition:stroke-dashoffset .15s}</style></head><body><div class="wrap"><div class="ring"><svg viewBox="0 0 156 156"><circle class="track" cx="78" cy="78" r="69" fill="none" stroke-width="9"/><circle id="progress" class="progress" cx="78" cy="78" r="69" fill="none" stroke-width="9" stroke-dasharray="433.54" stroke-dashoffset="433.54"/></svg><div class="logo">V</div></div><div id="pct" class="pct">0%</div><div id="msg" class="msg">Preparando la descarga…</div></div><script>window.setProgress=(p,m)=>{const v=Math.max(0,Math.min(100,Number(p)||0));document.getElementById("pct").textContent=Math.round(v)+"%";document.getElementById("progress").style.strokeDashoffset=433.54*(1-v/100);document.getElementById("msg").textContent=m||"Actualizando…";}</script></body></html>';
  void win.loadURL("data:text/html;charset=utf-8,"+encodeURIComponent(html));
  win.once("ready-to-show",()=>win.show());
  return {window:win,update:(percent,message)=>{if(!win.isDestroyed())win.webContents.executeJavaScript("window.setProgress("+Math.round(percent)+","+JSON.stringify(message)+")").catch(()=>{});},close:()=>{if(!win.isDestroyed())win.close();}};
}

async function performUpdate(window:BrowserWindow,asset:any,checksumAsset:any,version:string):Promise<void>{
  const image=process.env.APPIMAGE;
  if(!image){await dialog.showMessageBox(window,{type:"warning",title:"Actualización no disponible",message:"Esta instalación no es una AppImage ejecutada directamente. Descarga la nueva versión desde GitHub Releases."});return;}
  const folder=dirname(image),tmp=image+".update-part",backup=image+".backup";
  let replaced = false;
  let progressUI:{window:BrowserWindow;update:(percent:number,message:string)=>void;close:()=>void}|null=null;
  try{
    const checksumResponse=await fetch(checksumAsset.browser_download_url,{headers:{"User-Agent":"Puntos-Vuela-Toolkit-Updater"},signal:AbortSignal.timeout(30000)});
    if(!checksumResponse.ok)throw new Error("No se pudo obtener el archivo de sumas de verificación.");
    const checksums=await checksumResponse.text();
    const expected=checksums.split(/\r?\n/).map(line=>line.trim()).filter(Boolean).map(line=>{const match=line.match(/^([a-f0-9]{64})\s+\*?(.+)$/i);return match?{hash:match[1],name:match[2].trim().replace(/^\.\//,"")}:null;}).find(entry=>entry&&entry.name===asset.name)?.hash;
    if(!expected||!/^[a-f0-9]{64}$/i.test(expected))throw new Error("No se encontró una suma SHA-256 válida para la descarga.");
    progressUI=showDownloadProgress(window);
    progressUI.update(0,"Conectando con GitHub Releases…");
    const downloadResponse=await fetch(asset.browser_download_url,{headers:{"User-Agent":"Puntos-Vuela-Toolkit-Updater"},signal:AbortSignal.timeout(20*60*1000)});
    if(!downloadResponse.ok||!downloadResponse.body)throw new Error("No se pudo descargar la actualización.");
    const reader=downloadResponse.body.getReader(),chunks:Uint8Array[]=[];let received=0;const total=Number(downloadResponse.headers.get("content-length"))||Number(asset.size)||0;
    while(true){const chunk=await reader.read();if(chunk.done)break;chunks.push(chunk.value);received+=chunk.value.length;progressUI.update(total>0?Math.min(92,received/total*92):0,total>0?"Descargando AppImage…":"Descargando AppImage… ("+Math.round(received/1024/1024)+" MB)");}
    const data=Buffer.concat(chunks.map(chunk=>Buffer.from(chunk)));progressUI.update(94,"Verificando SHA-256…");
    const actual=createHash("sha256").update(data).digest("hex");
    if(actual.toLowerCase()!==expected.toLowerCase())throw new Error("La verificación SHA-256 ha fallado. No se instalará el archivo.");
    progressUI.update(96,"Checksum válido. Preparando instalación…");
    await fs.writeFile(tmp,data,{mode:0o755});
    await fs.chmod(tmp,0o755);
    await fs.copyFile(image,backup);
    await fs.chmod(backup,0o755);
    await fs.writeFile(markerPath(),JSON.stringify({version,backup,installedAt:new Date().toISOString()}));
    await fs.rename(tmp,image);
    replaced = true;
    progressUI.update(100,"Actualización instalada. Preparando reinicio…");
    progressUI.close();progressUI=null;
    const result=await showUpdateReadyModal(window,version);
    if(result==="restart"){spawn(image,[],{detached:true,stdio:"ignore",env:process.env}).unref();app.exit(0);}
  }catch(error:any){
    progressUI?.close();progressUI=null;
    await fs.rm(tmp,{force:true}).catch(()=>{});
    await fs.rm(markerPath(),{force:true}).catch(()=>{});
    if (replaced && await fs.access(backup).then(()=>true).catch(()=>false)) { await fs.rename(backup,image).catch(()=>{}); }
    else await fs.rm(backup,{force:true}).catch(()=>{});
    await dialog.showMessageBox(window,{type:"error",title:"No se pudo actualizar",message:"La actualización no se ha aplicado.",detail:error?.message||"Error desconocido. La versión actual permanece intacta."});
  }
}

ipcMain.handle("pv:updater-action", async () => {
  const pending=pendingUpdaterAction; if(!pending) return false; pendingUpdaterAction=null;
  const action=await showUpdaterModal(pending.window,{title:"Actualización disponible",version:pending.version,current:pending.current,testMode:pending.testMode,legacy:pending.legacy,description:"Pulsa Actualizar ahora para descargar, verificar e instalar la versión disponible."});
  if(action==="update") await performUpdate(pending.window,pending.asset,pending.checksums,pending.version); else {pendingUpdaterAction=pending; pending.window.webContents.send("pv:updater-banner",{version:pending.version,kind:pending.testMode?"test":"stable",releaseUrl:pending.releaseUrl});} return true;
});
ipcMain.handle("pv:invoke", async (_event, method: string, args: unknown) => {
  if (!allowed.has(method)) throw new Error("Operación no autorizada.");
  return api(method, args && typeof args === "object" ? args : {});
});

app.whenReady().then(async () => {
  Menu.setApplicationMenu(null);
  await recoverPreviousVersion();
  createWindow();
  app.on("activate", () => { if (BrowserWindow.getAllWindows().length === 0) createWindow(); });
});
app.on("window-all-closed", () => { if (process.platform !== "darwin") app.quit(); });
