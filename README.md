# Punto Vuela Linux Toolkit

Centro de software para Linux con identidad Punto Vuela. Reúne las herramientas propias de Punto Vuela y facilita descubrir, instalar y mantener aplicaciones AppImage.

## Objetivos

- Interfaz de escritorio moderna con PySide6 y QML.
- Distribución x86_64 en AppImage, DEB y RPM.
- Instalación y gestión en el espacio del usuario, sin requerir privilegios root para las funciones propias.
- Catálogo Punto Vuela con enlaces a los proyectos oficiales.
- Catálogos AppImageHub y AppImage Community, respetando sus fuentes y condiciones.
- Diseño oscuro, acento amarillo `#F3D54E`, tipografía Inter y logotipo oficial de Punto Vuela.

## Estado

Primera base de desarrollo: interfaz inicial, navegación y estructura de empaquetado. La gestión real de instalaciones, actualizaciones y catálogos se incorporará por fases. No se debe considerar todavía un gestor de paquetes completo.

## Desarrollo

Requiere Python 3.10+ y PySide6:

```bash
python -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
bash packaging/fetch-brand-assets.sh
python -m punto_vuela_toolkit
```

## Paquetes

La estrategia prevista es generar AppImage, DEB y RPM x86_64 desde GitHub Actions. La compilación inicial usa Ubuntu 22.04 como entorno de construcción; la compatibilidad binaria con Ubuntu 20.04 y otras distribuciones deberá validarse en pruebas específicas antes de anunciarla como garantizada. Los paquetes DEB/RPM serán instalables mediante el gestor de paquetes de cada distribución; las operaciones de administración del sistema pueden solicitar autorización al sistema operativo. La aplicación no ejecutará instalaciones privilegiadas silenciosamente.

## Logotipo

El recurso oficial se obtiene desde:
https://puntosvuela.es/storage/images/logotipovuela.svg

Se conserva como recurso de marca y se generan variantes PNG para los lanzadores de escritorio durante el empaquetado. Su uso debe respetar las condiciones de identidad corporativa de Punto Vuela.

## Licencia

MIT para el código de este proyecto. El logotipo y otros recursos de marca pertenecen a sus respectivos titulares y no quedan relicenciados por esta licencia.
