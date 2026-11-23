# Puntos Vuela Toolkit

**Puntos Vuela Toolkit** es una aplicación de escritorio para Linux que reúne herramientas y recursos para descubrir, descargar, organizar, actualizar y utilizar aplicaciones AppImage desde un único lugar.

## Información de la aplicación

- **Web oficial:** https://toolkit.javigallego.es/
- **Guía de uso:** https://toolkit.javigallego.es/guia.html
- **Privacidad:** https://toolkit.javigallego.es/privacy.html
- **Términos y condiciones:** https://toolkit.javigallego.es/terms.html
- **Descargas:** https://github.com/Montejaque/punto-vuela-linux-toolkit/releases

## Capturas de la aplicación

Las capturas de interfaz no están disponibles en esta rama. Se retiraron los enlaces a archivos no verificados para evitar imágenes rotas; se reincorporarán cuando se publiquen y validen.

## Funcionalidades

### Catálogo de aplicaciones
- Explora aplicaciones AppImage disponibles en el catálogo comunitario.
- Busca por nombre, descripción o autor.
- Filtra por categorías y consulta fichas de cada aplicación.
- Consulta información como versión, autor, licencia, icono y compatibilidad, cuando esos datos están disponibles.
- Accede a las descargas de las aplicaciones desde sus fuentes originales.

### Mis aplicaciones
- Consulta las aplicaciones AppImage que tienes en tu equipo y que gestiona Toolkit.
- Abre aplicaciones y corrige permisos de ejecución.
- Comprueba si existen actualizaciones compatibles.
- Actualiza aplicaciones cuando se dispone de los mecanismos necesarios.
- Elimina aplicaciones y administra sus accesos directos.

### Herramientas Punto Vuela
Encuentra aplicaciones y herramientas publicadas en repositorios públicos del ecosistema Punto Vuela y Montejaque, cuando hay paquetes compatibles disponibles.

### Recursos y ayuda
- Accede a recursos y contenidos de consulta desde sus portales originales.
- Consulta preguntas frecuentes y documentación de apoyo.
- Utiliza la guía integrada y la guía web.
- En Ayuda, diagnostica la caché de imágenes (ruta, conteos y entradas) o elimina solo los registros de fallos; no se borran las imágenes almacenadas.

### Contacto y propuestas
Envía propuestas de aplicaciones, selecciona el centro y revisa la información antes de enviarla. También puedes contactar por WhatsApp con un mensaje preparado.

### Personalización
- Tema claro, oscuro o automático.
- Navegación lateral y diseño adaptable.
- Gestión de aplicaciones desde tu espacio de usuario.

### Caché persistente de imágenes
- El catálogo y las fichas pueden descargar iconos y capturas desde sus orígenes HTTPS.
- Se aceptan PNG, JPEG, WebP, GIF y SVG; cada imagen está limitada a 8 MB.
- La caché de imágenes se conserva entre ejecuciones y utiliza nombres derivados de SHA-256 de la URL, extensiones reconocibles y metadatos locales.
- Los fallos quedan registrados localmente solo para diagnóstico; cada nueva solicitud vuelve a intentar descargar la imagen (sin espera de 12 horas). Las imágenes guardadas no caducan automáticamente.
- Ruta actual: `~/.local/share/punto-vuela-linux-toolkit/cache/images`. Por ahora no respeta `XDG_DATA_HOME`.
- Para vaciar la caché, cierra Toolkit y elimina esa carpeta; la aplicación la vuelve a crear al arrancar.

## Changelog

Consulta [CHANGELOG.md](CHANGELOG.md) para conocer las novedades y cambios de cada versión.
## Actualizador automático

La aplicación comprueba si hay releases disponibles. El modal permite **Actualizar ahora** o **Más tarde**. Al posponer o cerrar el modal, queda un banner en la interfaz para retomar la actualización. La descarga se verifica mediante SHA-256, se conserva una copia de la AppImage actual y el mecanismo de recuperación puede restaurarla si el nuevo inicio no se confirma.


## Compatibilidad

- Sistemas Linux de 64 bits (x86_64).
- Compatibilidad objetivo: Ubuntu 20.04 y versiones posteriores.
- La compatibilidad de cada AppImage depende de los requisitos de la propia aplicación y del sistema.
- Algunas aplicaciones pueden no disponer de opciones compatibles de instalación, actualización o gestión.

## Descargas

Descarga la versión más reciente desde [GitHub Releases](https://github.com/Montejaque/punto-vuela-linux-toolkit/releases).

## Instalación

1. Descarga la AppImage desde la sección [Releases](https://github.com/Montejaque/punto-vuela-linux-toolkit/releases).
2. Guarda el archivo en tu equipo y habilita el permiso de ejecución.
3. Abre la aplicación.

No necesitas instalar paquetes del sistema ni disponer de permisos de administrador para las funciones de gestión local.

Consulta la [guía de uso](https://toolkit.javigallego.es/guia.html) para conocer las secciones de la aplicación.

## Contacto

- **Correo:** montejaque@puntosvuela.es
- **WhatsApp:** [633 402 959](https://wa.me/34633402959)

## Licencia

Puntos Vuela Toolkit se distribuye bajo licencia MIT. Los logotipos, marcas y recursos de terceros mantienen sus derechos y licencias correspondientes.
