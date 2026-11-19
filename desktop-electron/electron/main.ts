import { app, BrowserWindow, shell, ipcMain } from "electron";
import { join } from "node:path";
import { api } from "./services";

const isDevelopment = !app.isPackaged;
const allowed = new Set(["catalog.search","tools.list","apps.list","apps.folder","apps.install","tools.install","apps.launch","apps.permissions","apps.remove","apps.checkUpdate","apps.update","tools.openExternal","mail.send","mail.health","centres.list,"centres.details","app.info"]);

function createWindow(): void {
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
  window.webContents.once("did-finish-load", () => {
    if (process.argv.includes("--smoke-test")) setTimeout(() => app.exit(0), 750);
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
}

ipcMain.handle("pv:invoke", async (_event, method: string, args: unknown) => {
  if (!allowed.has(method)) throw new Error("Operación no autorizada.");
  return api(method, args && typeof args === "object" ? args : {});
});

app.whenReady().then(() => {
  createWindow();
  app.on("activate", () => { if (BrowserWindow.getAllWindows().length === 0) createWindow(); });
});
app.on("window-all-closed", () => { if (process.platform !== "darwin") app.quit(); });
