import { contextBridge, ipcRenderer } from "electron";

const api = Object.freeze({
  platform: process.platform,
  version: "0.4.2",
  invoke: (method: string, args?: unknown) => ipcRenderer.invoke("pv:invoke", method, args)
});
contextBridge.exposeInMainWorld("puntoVuela", api);
