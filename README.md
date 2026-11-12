# Puntos Vuela Toolkit

Centro de software para Linux con identidad Punto Vuela. Reúne las herramientas propias de Punto Vuela y facilita descubrir, instalar y mantener aplicaciones AppImage.

## Objetivos

- Interfaz de escritorio moderna con PySide6 y QML.
- Distribución x86_64 en AppImage, DEB y RPM.
- Instalación y gestión en el espacio del usuario, sin requerir privilegios root para las funciones propias.
- Catálogo Punto Vuela con enlaces a los proyectos oficiales.
- Catálogo integrado AppImage Community mediante su feed JSON: búsqueda por nombre, descripción, categoría y autor; fichas con licencia y requisito glibc; instalación desde la última GitHub Release cuando existe un AppImage x86_64.
- Acceso independiente a AppImageHub/Pling; no se confunde con el feed comunitario ni se presupone que ofrezca una API de versiones.
- Diseño claro, oscuro o automático según el tema del sistema; selector visible en la barra superior y preferencia guardada entre sesiones.
- Carpeta de AppImages por usuario en `~/.local/share/punto-vuela-linux-toolkit/AppImages` (o `$XDG_DATA_HOME`), descargas HTTPS, validación ELF, permisos automáticos, lanzamiento, reparación de permisos y eliminación con confirmación.
- Comprobación y actualización mediante AppImageUpdate cuando la AppImage incluye información de actualización compatible. La actualización se confirma expresamente y se conserva el respaldo del actualizador. El actualizador oficial x86_64 puede descargarse al perfil de usuario y se verifica con el SHA-256 publicado por GitHub.
- Guía de ayuda en la aplicación y en `docs/GUIA-DE-AYUDA.md`.
- Acento amarillo `#F3D54E`, tipografía Inter y símbolo V oficial de Puntos Vuela integrado en el icono de Toolkit.

## Estado

Versión de desarrollo: catálogo comunitario consultable, instalación desde GitHub Releases cuando hay un archivo AppImage, biblioteca local, lanzamiento, permisos, eliminación, comprobación y actualización condicionada a metadatos del editor. No instala paquetes DEB/RPM/APT ni puede garantizar actualizaciones de AppImages que no publiquen metadatos compatibles. AppImageHub/Pling se ofrece como fuente web independiente.

## Desarrollo

Requiere Python 3.10+ y PySide6 6.4.3:

```bash
python -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
bash packaging/fetch-brand-assets.sh
python -m punto_vuela_toolkit
```

## Paquetes

La estrategia prevista es generar AppImage, DEB y RPM x86_64 desde GitHub Actions. La compilación de paquetes se realiza dentro de un contenedor Ubuntu 20.04 y usa PySide6 6.6.3 como base conservadora. El objetivo es Ubuntu 20.04 x86_64 y posteriores; la compatibilidad debe confirmarse con los artefactos y pruebas reales de cada ejecución de GitHub Actions antes de publicar una versión estable. Los paquetes DEB/RPM serán instalables mediante el gestor de paquetes de cada distribución; las operaciones de administración del sistema pueden solicitar autorización al sistema operativo. La aplicación no ejecutará instalaciones privilegiadas silenciosamente.

## Logotipo

El recurso oficial se obtiene desde:
https://puntosvuela.es/storage/images/logotipovuela.svg

El icono de la aplicación utiliza `src/punto_vuela_toolkit/assets/logo_toolkit.svg`, basado en el SVG facilitado: fondo amarillo corporativo y símbolo V negro. Se utiliza en la interfaz, el icono de ventana y los paquetes de escritorio. Su uso debe respetar las condiciones de identidad corporativa de Punto Vuela.

## Licencia

MIT para el código de este proyecto. El logotipo y otros recursos de marca pertenecen a sus respectivos titulares y no quedan relicenciados por esta licencia.

## Envío de solicitudes por correo

El formulario de contacto utiliza un servicio HTTPS desplegado en Cloudflare Workers. El Worker envía las solicitudes mediante Gmail API desde la cuenta corporativa y mantiene las credenciales OAuth exclusivamente en los secretos de Cloudflare. La AppImage no contiene contraseñas ni tokens.

La configuración y el despliegue se documentan en [docs/CORREO-CLOUDFLARE-WORKERS.md](docs/CORREO-CLOUDFLARE-WORKERS.md). Antes de publicar una versión funcional, hay que desplegar el Worker, configurar los secretos de Google y sustituir la URL provisional en `src/punto_vuela_toolkit/email_sender.py`. Hasta entonces, el envío mostrará que el servicio está pendiente de activación.
