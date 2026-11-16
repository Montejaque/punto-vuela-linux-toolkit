import { contextBridge } from "electron";

contextBridge.exposeInMainWorld("puntoVuela", Object.freeze({
  platform: process.platform,
  version: "0.2.0-preview"
}));