import { _electron as electron } from "playwright";
import { mkdir } from "node:fs/promises";
import path from "node:path";

const out = path.resolve("../docs-site/screenshots");
await mkdir(out,{recursive:true});
const app = await electron.launch({args:["--capture-updater-docs","--no-sandbox","--disable-gpu","--disable-dev-shm-usage"]});
try {
  const main = app.windows()[0];
  if (!main) throw new Error("La ventana principal de Electron no se creó.");
  await main.waitForLoadState("domcontentloaded");
  const modal = await app.waitForEvent("window", {timeout:20000});
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
