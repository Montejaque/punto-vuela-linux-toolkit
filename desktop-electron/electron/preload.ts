import { contextBridge, ipcRenderer } from "electron";

const api = Object.freeze({
  platform: process.platform,
  version: "0.4.2",
  invoke: (method: string, args?: unknown) => ipcRenderer.invoke("pv:invoke", method, args),
  updaterAction: () => ipcRenderer.invoke("pv:updater-action"),
  onUpdaterBanner: (callback: (data: {version:string;kind:string;releaseUrl?:string}) => void) => { const listener=(_event: Electron.IpcRendererEvent,data:any)=>callback(data); ipcRenderer.on("pv:updater-banner",listener); return () => ipcRenderer.removeListener("pv:updater-banner",listener); }
});
contextBridge.exposeInMainWorld("puntoVuela", api);
