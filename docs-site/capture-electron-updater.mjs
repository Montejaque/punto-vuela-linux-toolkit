import { createRequire } from "node:module";
const require = createRequire(path.resolve("package.json"));
const { _electron: electron } = require("playwright");
import { mkdir } from "node:fs/promises";
import path from "node:path";

const out = path.resolve("../docs-site/screenshots");
await mkdir(out,{recursive:true});
const app = await electron.launch({args:["--capture-updater-docs","--no-sandbox","--disable-gpu","--disable-dev-shm-usage"]});
try {
  let main;
  const mainDeadline = Date.now() + 30000;
  while (Date.now() < mainDeadline) {
    main = app.windows()[0];
    if (main) break;
    await new Promise((resolve) => setTimeout(resolve, 250));
  }
  if (!main) throw new Error("La ventana principal de Electron no se creó tras esperar 30 segundos. Revisa el arranque de Electron y su carga de renderer.");
  await main.waitForLoadState("domcontentloaded");
  let modal;
  const deadline = Date.now() + 20000;
  while (Date.now() < deadline) {
    for (const candidate of app.windows()) {
      if (candidate === main) continue;
      const title = await candidate.title();
      if (title.includes("capturas de documentación")) {
        modal = candidate;
        break;
      }
    }
    if (modal) break;
    await new Promise((resolve) => setTimeout(resolve, 200));
  }
  if (!modal) throw new Error("No se abrió el modal real de actualización.");
  await modal.waitForLoadState("domcontentloaded");
  await modal.screenshot({path:path.join(out,"10-updater-modal.png")});
  const later = modal.locator('a[href="pvu-updater://later"]');
  await later.waitFor({state:"visible",timeout:10000});
  await later.click();
  await main.locator(".updater-available-banner").waitFor({state:"visible",timeout:10000});
  await main.screenshot({path:path.join(out,"11-updater-banner.png")});
  console.log("Capturas reales de Electron generadas: modal y banner.");
} finally {
  await app.close();
}
