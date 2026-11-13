from __future__ import annotations

import json
import os
import sys
from pathlib import Path
from threading import Thread

from PySide6.QtCore import QObject, QUrl, Signal, Slot
from PySide6.QtGui import QDesktopServices, QFont, QGuiApplication, QIcon
from PySide6.QtQml import QQmlApplicationEngine

from .appimages import AppImageManager
from .catalog import AppImageCatalog
from .email_sender import send_application_request

APP_NAME = "Puntos Vuela Toolkit"
QML_FILE = Path(__file__).parent / "qml" / "Main.qml"


class AppImageBridge(QObject):
    """QML-facing API for local AppImages and the community catalogue."""

    catalogLoaded = Signal(str)
    puntoVuelaToolsLoaded = Signal(str)
    toolkitReleaseLoaded = Signal(str)
    catalogInstallFinished = Signal(str)
    appImageDownloadFinished = Signal(str)
    appImageUpdateCheckFinished = Signal(str)
    appImageUpdated = Signal(str)
    emailSent = Signal(str)

    def __init__(self) -> None:
        super().__init__()
        self.manager = AppImageManager()
        self.catalog = AppImageCatalog(self.manager)
        self._workers: list[Thread] = []

    def _spawn(self, target) -> None:
        self._workers = [worker for worker in self._workers if worker.is_alive()]
        worker = Thread(target=target, daemon=True)
        self._workers.append(worker)
        worker.start()

    @Slot(result=str)
    def listAppImages(self) -> str:
        return json.dumps([
            {"path": str(item.path), "name": item.path.name,
             "size": item.size, "executable": item.executable,
             "customUpdater": any(token in item.path.name.casefold() for token in
                                  ("vscode-installer", "chatgpt-installer", "claude-desktop", "antigravity-installer"))}
            for item in self.manager.list_appimages()
        ], ensure_ascii=False)


    @Slot(str)
    def sendApplicationRequest(self, payload: str) -> None:
        def work() -> None:
            try:
                data = json.loads(payload)
                message = send_application_request(data)
                result = {"ok": True, "message": message}
            except Exception as exc:
                result = {"ok": False, "message": str(exc)}
            self.emailSent.emit(json.dumps(result, ensure_ascii=False))
        self._spawn(work)

    @Slot()
    def loadPuntoVuelaTools(self) -> None:
        def work() -> None:
            try:
                items = self.catalog.discover_public_github_tools()
                payload = {"ok": True, "items": items, "message": f"{len(items)} herramientas públicas encontradas en GitHub."}
            except Exception as exc:
                payload = {"ok": False, "items": [], "message": f"No se pudo consultar GitHub: {exc}"}
            self.puntoVuelaToolsLoaded.emit(json.dumps(payload, ensure_ascii=False))
        self._spawn(work)

    @Slot()
    def refreshPuntoVuelaTools(self) -> None:
        def work() -> None:
            try:
                items = self.catalog.discover_public_github_tools(force=True)
                payload = {"ok": True, "items": items, "message": f"Catálogo actualizado: {len(items)} herramientas públicas."}
            except Exception as exc:
                payload = {"ok": False, "items": [], "message": f"No se pudo actualizar GitHub: {exc}"}
            self.puntoVuelaToolsLoaded.emit(json.dumps(payload, ensure_ascii=False))
        self._spawn(work)

    @Slot()
    def loadToolkitRelease(self) -> None:
        def work() -> None:
            result = self.catalog.latest_toolkit_release()
            self.toolkitReleaseLoaded.emit(json.dumps(result, ensure_ascii=False))
        self._spawn(work)
    @Slot(str)
    def loadCatalog(self, query: str) -> None:
        def work() -> None:
            try:
                entries = self.catalog.search(query, force=False, limit=5000)
                payload = {"ok": True, "items": entries, "message": f"{len(entries)} aplicaciones encontradas en el catálogo comunitario."}
            except Exception as exc:
                payload = {"ok": False, "items": [], "message": f"No se pudo cargar el catálogo: {exc}"}
            self.catalogLoaded.emit(json.dumps(payload, ensure_ascii=False))

        worker = Thread(target=work, daemon=True)
        self._workers.append(worker)
        worker.start()

    @Slot()
    def refreshCatalog(self) -> None:
        def work() -> None:
            try:
                entries = self.catalog.search("", force=True, limit=5000)
                payload = {"ok": True, "items": entries, "message": f"Catálogo actualizado: {len(entries)} aplicaciones."}
            except Exception as exc:
                payload = {"ok": False, "items": [], "message": f"No se pudo actualizar el catálogo: {exc}"}
            self.catalogLoaded.emit(json.dumps(payload, ensure_ascii=False))

        worker = Thread(target=work, daemon=True)
        self._workers.append(worker)
        worker.start()

    @Slot(str)
    def installPuntoVuelaTool(self, repository: str) -> None:
        def work() -> None:
            try:
                item = next((x for x in self.catalog.discover_public_github_tools() if x.get("repository") == repository), None)
                if not item:
                    raise RuntimeError("La herramienta ya no está disponible en los repositorios públicos.")
                result = self.catalog._download_result(item["name"], item["downloadUrl"], item.get("assetName"))
                desktop = self.manager.integrate(result["path"], item["name"])
                result["desktopEntry"] = str(desktop)
                result["message"] = item["name"] + " descargada e integrada en el menú de aplicaciones."
                result["ok"] = True
            except Exception as exc:
                result = {"ok": False, "message": str(exc)}
            self.catalogInstallFinished.emit(json.dumps(result, ensure_ascii=False))
        self._spawn(work)

    @Slot(str)
    def installCatalogApp(self, app_name: str) -> None:
        def work() -> None:
            try:
                payload = self.catalog.install(app_name)
                payload["name"] = app_name
            except Exception as exc:
                payload = {"ok": False, "name": app_name, "message": str(exc)}
            self.catalogInstallFinished.emit(json.dumps(payload, ensure_ascii=False))

        worker = Thread(target=work, daemon=True)
        self._workers.append(worker)
        worker.start()


    @Slot(str, result=str)
    def launchAppImage(self, path: str) -> str:
        try:
            self.manager.launch(path)
            return json.dumps({"ok": True, "message": "Aplicación iniciada."}, ensure_ascii=False)
        except Exception as exc:
            return json.dumps({"ok": False, "message": str(exc)}, ensure_ascii=False)

    @Slot(str, result=str)
    def makeAppImageExecutable(self, path: str) -> str:
        try:
            self.manager.ensure_executable(path)
            return json.dumps({"ok": True, "message": "Permisos de ejecución aplicados."}, ensure_ascii=False)
        except Exception as exc:
            return json.dumps({"ok": False, "message": str(exc)}, ensure_ascii=False)

    @Slot(str, result=str)
    def removeAppImage(self, path: str) -> str:
        try:
            self.manager.remove(path)
            return json.dumps({"ok": True, "message": "AppImage eliminada de la carpeta administrada."}, ensure_ascii=False)
        except Exception as exc:
            return json.dumps({"ok": False, "message": str(exc)}, ensure_ascii=False)

    @Slot(str)
    def downloadAppImage(self, url: str) -> None:
        def work() -> None:
            try:
                path = self.manager.download(url)
                try:
                    update = self.manager.check_update(path)
                except Exception as update_error:
                    update = {"supported": False, "available": False, "message": str(update_error)}
                if update.get("supported") and update.get("available"):
                    message = f"Descargada: {path.name}. Hay una actualización disponible; pulsa Actualizar para instalarla."
                elif update.get("supported"):
                    message = f"Descargada y preparada para ejecutar: {path.name}. No se detectan actualizaciones."
                else:
                    message = f"Descargada y preparada para ejecutar: {path.name}. No se pudo comprobar la versión: {update.get('message', 'origen no compatible')}."
                payload = {"ok": True, "path": str(path), "updateAvailable": bool(update.get("available")), "message": message}
            except Exception as exc:
                payload = {"ok": False, "message": str(exc)}
            self.appImageDownloadFinished.emit(json.dumps(payload, ensure_ascii=False))
        self._spawn(work)

    @Slot(str)
    def checkAppImageUpdate(self, path: str) -> None:
        def work() -> None:
            try:
                result = self.manager.check_update(path)
            except Exception as exc:
                result = {"supported": False, "available": False, "message": str(exc)}
            self.appImageUpdateCheckFinished.emit(json.dumps({"path": path, **result}, ensure_ascii=False))
        self._spawn(work)

    @Slot(str)
    def updateAppImage(self, path: str) -> None:
        def work() -> None:
            try:
                result = self.manager.update(path)
                result["path"] = path
            except Exception as exc:
                result = {"updated": False, "path": path, "message": str(exc)}
            self.appImageUpdated.emit(json.dumps(result, ensure_ascii=False))
        self._spawn(work)

    @Slot()
    def openAppImageFolder(self) -> None:
        self.manager.directory.mkdir(parents=True, exist_ok=True)
        QDesktopServices.openUrl(QUrl.fromLocalFile(str(self.manager.directory)))


def create_application() -> QGuiApplication:
    os.environ.setdefault("QT_QUICK_CONTROLS_STYLE", "Basic")
    app = QGuiApplication.instance() or QGuiApplication(sys.argv[:1])
    app.setApplicationName(APP_NAME)
    icon_file = Path(__file__).parent / "assets" / "logo_toolkit.svg"
    if icon_file.is_file():
        app.setWindowIcon(QIcon(str(icon_file)))
    app.setOrganizationName("Punto Vuela")
    app.setFont(QFont("Inter", 10))
    return app


def load_interface() -> QQmlApplicationEngine:
    engine = QQmlApplicationEngine()
    bridge = AppImageBridge()
    engine.rootContext().setContextProperty("appImageManager", bridge)
    engine._app_image_bridge = bridge
    engine.load(QUrl.fromLocalFile(str(QML_FILE.resolve())))
    if not engine.rootObjects():
        raise RuntimeError(f"No se pudo cargar la interfaz QML: {QML_FILE}")
    return engine


def register_desktop_entry() -> None:
    """Register the Toolkit in the current user's GNOME applications menu.

    This is deliberately user-local: it works without root and does not modify
    /usr/share/applications. When running as an AppImage, APPIMAGE points to
    the persistent AppImage file rather than the temporary mount directory.
    """
    if os.environ.get("PUNTO_VUELA_DISABLE_MENU_INTEGRATION") == "1":
        return
    data_home = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share")).expanduser()
    applications_dir = data_home / "applications"
    icons_dir = data_home / "icons" / "hicolor" / "scalable" / "apps"
    try:
        applications_dir.mkdir(parents=True, exist_ok=True)
        icons_dir.mkdir(parents=True, exist_ok=True)
        icon_source = Path(__file__).parent / "assets" / "logo_toolkit.svg"
        icon_target = icons_dir / "punto-vuela-linux-toolkit.svg"
        if icon_source.is_file():
            import shutil
            if not icon_target.exists() or icon_source.read_bytes() != icon_target.read_bytes():
                shutil.copy2(icon_source, icon_target)

        executable = os.environ.get("APPIMAGE") or sys.executable
        executable = str(Path(executable).expanduser().resolve())
        # Desktop Entry Exec quoting: escape backslashes, quotes and percent signs.
        quoted_exec = executable.replace("\\", "\\\\").replace('"', '\\\\"').replace("%", "%%")
        desktop = applications_dir / "punto-vuela-linux-toolkit.desktop"
        entry = (
            "[Desktop Entry]\n"
            "Type=Application\n"
            "Name=Puntos Vuela Toolkit\n"
            "GenericName=Centro de software\n"
            "Comment=Herramientas y centro de software para Linux de Puntos Vuela\n"
            f'Exec="{quoted_exec}"\n'
            "TryExec=" + quoted_exec + "\n"
            "Icon=punto-vuela-linux-toolkit\n"
            "Terminal=false\n"
            "Categories=System;Utility;\n"
            "StartupNotify=true\n"
            "StartupWMClass=punto-vuela-linux-toolkit\n"
        )
        temporary = desktop.with_suffix(".desktop.part")
        temporary.write_text(entry, encoding="utf-8")
        temporary.chmod(0o644)
        os.replace(temporary, desktop)
        import shutil
        updater = shutil.which("update-desktop-database")
        if updater:
            subprocess.run([updater, str(applications_dir)], capture_output=True, timeout=10, check=False)
    except (OSError, subprocess.SubprocessError):
        # Menu integration must never prevent the application from opening.
        return


def main() -> None:
    smoke_test = "--smoke-test" in sys.argv[1:]
    if not smoke_test:
        register_desktop_entry()
    create_application()
    engine = load_interface()
    if smoke_test:
        engine.deleteLater()
        return
    sys.exit(QGuiApplication.instance().exec())


if __name__ == "__main__":
    main()
