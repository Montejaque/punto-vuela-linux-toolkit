from __future__ import annotations

import json
import os
import sys
from pathlib import Path

from PySide6.QtCore import QObject, QUrl, Slot
from PySide6.QtGui import QDesktopServices, QFont, QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

from .appimages import AppImageManager

APP_NAME = "Punto Vuela Linux Toolkit"
QML_FILE = Path(__file__).parent / "qml" / "Main.qml"


class AppImageBridge(QObject):
    """Small QML-facing API for managing AppImages in the current user profile."""

    def __init__(self) -> None:
        super().__init__()
        self.manager = AppImageManager()

    @Slot(result=str)
    def listAppImages(self) -> str:
        return json.dumps([
            {"path": str(item.path), "name": item.path.name,
             "size": item.size, "executable": item.executable}
            for item in self.manager.list_appimages()
        ], ensure_ascii=False)

    @Slot(str, result=str)
    def downloadAppImage(self, url: str) -> str:
        try:
            path = self.manager.download(url)
            return json.dumps({"ok": True, "path": str(path), "message": f"Descargada y preparada para ejecutar: {path.name}"}, ensure_ascii=False)
        except Exception as exc:
            return json.dumps({"ok": False, "message": str(exc)}, ensure_ascii=False)

    @Slot(str, result=str)
    def checkAppImageUpdate(self, path: str) -> str:
        try:
            result = self.manager.check_update(path)
            return json.dumps(result, ensure_ascii=False)
        except Exception as exc:
            return json.dumps({"supported": False, "available": False, "message": str(exc)}, ensure_ascii=False)

    @Slot(str, result=str)
    def updateAppImage(self, path: str) -> str:
        try:
            result = self.manager.update(path)
            return json.dumps(result, ensure_ascii=False)
        except Exception as exc:
            return json.dumps({"updated": False, "message": str(exc)}, ensure_ascii=False)

    @Slot()
    def openAppImageFolder(self) -> None:
        self.manager.directory.mkdir(parents=True, exist_ok=True)
        QDesktopServices.openUrl(QUrl.fromLocalFile(str(self.manager.directory)))


def create_application() -> QGuiApplication:
    os.environ.setdefault("QT_QUICK_CONTROLS_STYLE", "Basic")
    app = QGuiApplication.instance() or QGuiApplication(sys.argv[:1])
    app.setApplicationName(APP_NAME)
    app.setOrganizationName("Punto Vuela")
    app.setFont(QFont("Inter", 10))
    return app


def load_interface() -> QQmlApplicationEngine:
    engine = QQmlApplicationEngine()
    engine.rootContext().setContextProperty("appImageManager", AppImageBridge())
    engine.load(QUrl.fromLocalFile(str(QML_FILE.resolve())))
    if not engine.rootObjects():
        raise RuntimeError(f"No se pudo cargar la interfaz QML: {QML_FILE}")
    return engine


def main() -> None:
    smoke_test = "--smoke-test" in sys.argv[1:]
    create_application()
    engine = load_interface()
    if smoke_test:
        engine.deleteLater()
        return
    sys.exit(QGuiApplication.instance().exec())


if __name__ == "__main__":
    main()
