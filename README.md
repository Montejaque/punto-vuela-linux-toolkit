# Puntos Vuela Toolkit

**Puntos Vuela Toolkit** es una aplicación de escritorio para Linux que reúne un catálogo comunitario de AppImages, una biblioteca local para gestionar aplicaciones, herramientas del ecosistema Punto Vuela y recursos de consulta.

**Responsable del proyecto:** Francisco Javier Gallego Orellana · Puntos Vuela Montejaque.

## Descarga y documentación

- 🌐 **Web del proyecto:** https://toolkit.javigallego.es/
- 📘 **Guía interactiva con capturas:** https://toolkit.javigallego.es/guia.html
- 🔐 **Privacidad:** https://toolkit.javigallego.es/privacy.html
- 📄 **Términos y condiciones:** https://toolkit.javigallego.es/terms.html
- 💻 **Código fuente y Releases:** https://github.com/Montejaque/punto-vuela-linux-toolkit
- 📦 **Releases:** https://github.com/Montejaque/punto-vuela-linux-toolkit/releases

## Funcionalidades

### Catálogo AppImage
- Catálogo Community con búsqueda por nombre, descripción y autor.
- Filtrado por categorías y consulta de fichas de aplicaciones.
- Metadatos como versión, autor, licencia, icono y requisitos de compatibilidad cuando están disponibles.
- Descarga desde las fuentes del proyecto, cuando existe un recurso compatible identificado.

### Biblioteca local — Mis aplicaciones
- Listado de AppImages gestionadas desde el perfil del usuario.
- Abrir aplicaciones y reparar permisos de ejecución.
- Comprobación de actualizaciones cuando la AppImage ofrece metadatos compatibles.
- Actualización delegada a AppImageUpdate cuando está disponible.
- Eliminación de archivos y gestión de lanzadores de escritorio.

### Herramientas Punto Vuela
Descubrimiento e instalación de AppImages publicadas en Releases de repositorios públicos del ecosistema Punto Vuela/Montejaque, cuando se encuentra un paquete compatible.

### Recursos y ayuda
- Banco de recursos enlazado con portales originales.
- FAQs de software y documentación de referencia.
- Guía integrada en la aplicación y guía web con capturas de pantalla.

### Contacto y propuestas
Formulario para seleccionar centro, revisar los datos y preparar propuestas de aplicaciones. Incluye información legal, verificación anti-spam de Cloudflare Turnstile y envío mediante el servicio remoto de correo. También permite abrir una conversación de WhatsApp con el texto de la propuesta preparado.

### Personalización
- Tema claro, oscuro o automático.
- Interfaz responsive con navegación lateral.
- Gestión de aplicaciones en el espacio de usuario, sin operaciones privilegiadas.

## Compatibilidad

- Linux x86_64.
- Objetivo de compatibilidad: Ubuntu 20.04 y posteriores.
- La compatibilidad real de cada AppImage depende de sus requisitos: glibc, FUSE, bibliotecas, controladores y otras dependencias del sistema.
- No todas las AppImages del catálogo tienen instalador o actualización compatible.

## Instalación y uso

Descarga la AppImage desde la sección **Releases** del repositorio, guarda el archivo, dale permiso de ejecución y ábrelo. No requiere instalación de paquetes del sistema ni permisos de administrador para las operaciones de gestión local.

Consulta la [guía de uso](https://toolkit.javigallego.es/guia.html) para recorrer las secciones de la aplicación.

## Desarrollo

Requisitos: Node.js/npm compatibles con Electron 43.

```bash
cd desktop-electron
npm ci
npm run dev
```

Comprobaciones y empaquetado:

```bash
npm run typecheck
npm run build
npm run dist:appimage
```

La aplicación de escritorio usa Electron, React, TypeScript y Vite. Las funciones locales se gestionan en el proceso principal de Electron y se exponen al renderer mediante una API IPC limitada.

## Seguridad y limitaciones

- El renderer no tiene acceso directo a Node.js; la comunicación con operaciones locales se realiza mediante IPC controlado.
- Las descargas usan HTTPS y se realizan comprobaciones del tipo de archivo; estas comprobaciones **no sustituyen a un antivirus ni garantizan que el software sea seguro**.
- Las actualizaciones AppImage dependen de metadatos compatibles del editor.
- La aplicación no ejecuta instalaciones privilegiadas silenciosas.
- La disponibilidad del envío de propuestas depende del servicio remoto y su configuración.

## Tecnología

Electron 43 · React 18 · TypeScript · Vite · Lucide React · electron-builder · Cloudflare Workers para el servicio de correo.

## Contacto

- Correo: [montejaque@puntosvuela.es](mailto:montejaque@puntosvuela.es)
- WhatsApp: [633 402 959](https://wa.me/34633402959)

## Licencia

Código bajo licencia MIT. Los logos, marcas y recursos de terceros mantienen sus derechos y licencias respectivas.
