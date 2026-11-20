import { app, BrowserWindow, shell, ipcMain, dialog } from "electron";
import { join, dirname } from "node:path";
import { promises as fs } from "node:fs";
import { createHash } from "node:crypto";
import { spawn } from "node:child_process";
import { api } from "./services";

const isDevelopment = !app.isPackaged;
const allowed = new Set(["catalog.search","tools.list","apps.list","apps.folder","apps.install","tools.install","apps.launch","apps.permissions","apps.remove","apps.checkUpdate","apps.update","tools.openExternal","mail.send","mail.health","centres.list","centres.details","app.info"]);
const REPO = "Montejaque/punto-vuela-linux-toolkit";
const UPDATE_BASE = "https://api.github.com/repos/" + REPO;
const markerPath = () => join(app.getPath("userData"), "update-pending.json");

function createWindow(): BrowserWindow {
  const window = new BrowserWindow({
    width: 1440, height: 920, minWidth: 760, minHeight: 600, show: false,
    backgroundColor: "#171d25", title: "Puntos Vuela Toolkit", icon: join(__dirname, "../dist/assets/logo_toolkit.png"),
    webPreferences: {
      preload: join(__dirname, "preload.js"),
      contextIsolation: true, nodeIntegration: false, sandbox: true,
      webSecurity: true
    }
  });
  window.once("ready-to-show", () => window.show());
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
        const choice = await dialog.showMessageBox(window, {
          type: "info", buttons: ["Ver release de pruebas", "Cerrar"], defaultId: 0, cancelId: 1,
          title: "ACTUALIZADOR · MODO DE PRUEBAS",
          message: "Canal de pruebas detectado: " + legacyTestRelease.tag_name,
          detail: "Las releases antiguas de pruebas no usan etiquetas SemVer. Este modal valida la detección y presentación; no instala estas releases legacy."
        });
        if (choice.response === 0 && legacyTestRelease.html_url) void shell.openExternal(legacyTestRelease.html_url);
        return;
      }
    }
    if (!candidate) return;

    const latest = candidate.version;
    const appImageAsset = candidate.appImage;
    const checksumAsset = candidate.checksums;
    const choice = await dialog.showMessageBox(window, {
      type: "info", buttons: ["Actualizar ahora", "Más tarde"], defaultId: 0, cancelId: 1,
      title: testMode ? "ACTUALIZADOR · MODO DE PRUEBAS" : "Nueva versión disponible", message: "Puntos Vuela Toolkit " + latest,
      detail: (testMode ? "CANAL DE PRUEBAS (release prerelease). " : "") + "Tienes instalada la versión " + current + ". La versión " + latest + " está disponible. La descarga se verificará antes de sustituir la aplicación. Se conservará una copia para recuperación."
    });
    if (choice.response !== 0) return;
    await performUpdate(window, appImageAsset, checksumAsset, latest);
  } catch (error: any) {
    console.warn("Updater:", error?.message || error);
  }
}

async function performUpdate(window:BrowserWindow,asset:any,checksumAsset:any,version:string):Promise<void>{
  const image=process.env.APPIMAGE;
  if(!image){await dialog.showMessageBox(window,{type:"warning",title:"Actualización no disponible",message:"Esta instalación no es una AppImage ejecutada directamente. Descarga la nueva versión desde GitHub Releases."});return;}
  const folder=dirname(image),tmp=image+".update-part",backup=image+".backup";
  let replaced = false;
  try{
    const checksumResponse=await fetch(checksumAsset.browser_download_url,{headers:{"User-Agent":"Puntos-Vuela-Toolkit-Updater"},signal:AbortSignal.timeout(30000)});
    if(!checksumResponse.ok)throw new Error("No se pudo obtener el archivo de sumas de verificación.");
    const checksums=await checksumResponse.text();
    const expected=checksums.split(/\r?\n/).find(line=>line.endsWith("  "+asset.name))?.split(/\s+/)[0];
    if(!expected||!/^[a-f0-9]{64}$/i.test(expected))throw new Error("No se encontró una suma SHA-256 válida para la descarga.");
    const downloadResponse=await fetch(asset.browser_download_url,{headers:{"User-Agent":"Puntos-Vuela-Toolkit-Updater"},signal:AbortSignal.timeout(20*60*1000)});
    if(!downloadResponse.ok||!downloadResponse.body)throw new Error("No se pudo descargar la actualización.");
    const data=Buffer.from(await downloadResponse.arrayBuffer());
    const actual=createHash("sha256").update(data).digest("hex");
    if(actual.toLowerCase()!==expected.toLowerCase())throw new Error("La verificación SHA-256 ha fallado. No se instalará el archivo.");
    await fs.writeFile(tmp,data,{mode:0o755});
    await fs.chmod(tmp,0o755);
    await fs.copyFile(image,backup);
    await fs.chmod(backup,0o755);
    await fs.writeFile(markerPath(),JSON.stringify({version,backup,installedAt:new Date().toISOString()}));
    await fs.rename(tmp,image);
    replaced = true;
    const result=await dialog.showMessageBox(window,{type:"info",buttons:["Reiniciar ahora","Reiniciar más tarde"],defaultId:0,title:"Actualización descargada y verificada",message:"La versión "+version+" está lista. Se ha guardado una copia de seguridad para permitir la recuperación si la nueva versión no inicia correctamente."});
    if(result.response===0){app.relaunch();app.exit(0);}
  }catch(error:any){
    await fs.rm(tmp,{force:true}).catch(()=>{});
    await fs.rm(markerPath(),{force:true}).catch(()=>{});
    if (replaced && await fs.access(backup).then(()=>true).catch(()=>false)) { await fs.rename(backup,image).catch(()=>{}); }
    else await fs.rm(backup,{force:true}).catch(()=>{});
    await dialog.showMessageBox(window,{type:"error",title:"No se pudo actualizar",message:"La actualización no se ha aplicado.",detail:error?.message||"Error desconocido. La versión actual permanece intacta."});
  }
}

ipcMain.handle("pv:invoke", async (_event, method: string, args: unknown) => {
  if (!allowed.has(method)) throw new Error("Operación no autorizada.");
  return api(method, args && typeof args === "object" ? args : {});
});

app.whenReady().then(async () => {
  await recoverPreviousVersion();
  createWindow();
  app.on("activate", () => { if (BrowserWindow.getAllWindows().length === 0) createWindow(); });
});
app.on("window-all-closed", () => { if (process.platform !== "darwin") app.quit(); });
