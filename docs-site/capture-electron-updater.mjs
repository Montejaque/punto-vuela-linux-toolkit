import { createRequire } from "node:module";
import { mkdir } from "node:fs/promises";
import path from "node:path";

const require = createRequire(path.resolve("package.json"));
const { _electron: electron } = require("playwright");
const out = path.resolve("../docs-site/screenshots");
await mkdir(out, { recursive: true });

const app = await electron.launch({
  args: [".", "--capture-updater-docs", "--no-sandbox", "--disable-gpu", "--disable-dev-shm-usage"],
  timeout: 60000
});
try {
  let main;
  const mainDeadline = Date.now() + 30000;
  while (Date.now() < mainDeadline) {
    main = app.windows().find((win) => win.url().includes(":5173"));
    if (main) break;
    await new Promise((resolve) => setTimeout(resolve, 250));
  }
  if (!main) throw new Error("Electron no creó la ventana principal cargada en Vite (localhost:5173) en 30 segundos.");
  await main.waitForLoadState("domcontentloaded");

  // Identify the modal by its actual rendered content, not document.title.
  // data: documents can expose an empty title to Playwright.
  let modal;
  const deadline = Date.now() + 20000;
  while (Date.now() < deadline && !modal) {
    for (const candidate of app.windows()) {
      if (candidate === main) continue;
      const later = candidate.locator('a[href="pvu-updater://later"]');
      const captureText = candidate.getByText("Modo de captura para documentación. No descarga ni instala nada.", { exact: true });
      if (await later.isVisible().catch(() => false) && await captureText.isVisible().catch(() => false)) {
        modal = candidate;
        break;
      }
    }
    if (!modal) await new Promise((resolve) => setTimeout(resolve, 200));
  }
  if (!modal) {
    const diagnostics = await Promise.all(app.windows().map(async (win, index) => ({
      index, url: win.url(), title: await win.title().catch(() => ""),
      body: await win.locator("body").innerText().catch(() => "")
    })));
    throw new Error("No se detectó el modal real del actualizador. Ventanas: " + JSON.stringify(diagnostics));
  }

  await modal.screenshot({ path: path.join(out, "10-updater-modal.png") });
  await modal.locator('a[href="pvu-updater://later"]').click();
  await main.locator(".updater-available-banner").waitFor({ state: "visible", timeout: 10000 });
  await main.screenshot({ path: path.join(out, "11-updater-banner.png") });
  console.log("Capturas reales de Electron generadas: modal y banner.");
} finally {
  await app.close();
}
