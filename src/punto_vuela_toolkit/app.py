from __future__ import annotations

import os
import platform
import sys
from pathlib import Path

from PySide6.QtCore import QUrl
from PySide6.QtGui import QFont, QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

APP_NAME = "Punto Vuela Linux Toolkit"


def main() -> None:
    os.environ.setdefault("QT_QUICK_CONTROLS_STYLE", "Basic")
    app = QGuiApplication(sys.argv)
    app.setApplicationName(APP_NAME)
    app.setOrganizationName("Punto Vuela")
    app.setFont(QFont("Inter", 10))

    engine = QQmlApplicationEngine()
    qml_file = Path(__file__).parent / "qml" / "Main.qml"
    engine.load(QUrl.fromLocalFile(str(qml_file)))
    if not engine.rootObjects():
        raise RuntimeError(f"No se pudo cargar la interfaz: {qml_file}")
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
