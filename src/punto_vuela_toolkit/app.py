from __future__ import annotations

import os
import sys
from pathlib import Path

from PySide6.QtCore import QUrl
from PySide6.QtGui import QFont, QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

APP_NAME = "Punto Vuela Linux Toolkit"
QML_FILE = Path(__file__).parent / "qml" / "Main.qml"


def create_application() -> QGuiApplication:
    os.environ.setdefault("QT_QUICK_CONTROLS_STYLE", "Basic")
    app = QGuiApplication.instance() or QGuiApplication(sys.argv[:1])
    app.setApplicationName(APP_NAME)
    app.setOrganizationName("Punto Vuela")
    app.setFont(QFont("Inter", 10))
    return app


def load_interface() -> QQmlApplicationEngine:
    engine = QQmlApplicationEngine()
    engine.load(QUrl.fromLocalFile(str(QML_FILE.resolve())))
    if not engine.rootObjects():
        raise RuntimeError(f"No se pudo cargar la interfaz QML: {QML_FILE}")
    return engine


def main() -> None:
    smoke_test = "--smoke-test" in sys.argv[1:]
    create_application()
    engine = load_interface()
    if smoke_test:
        # Loading the QML engine and obtaining a root object validates imports,
        # component construction and resource paths without entering the event loop.
        engine.deleteLater()
        return
    sys.exit(QGuiApplication.instance().exec())


if __name__ == "__main__":
    main()
