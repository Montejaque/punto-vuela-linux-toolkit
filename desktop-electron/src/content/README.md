# Puntos Vuela Toolkit

Aplicación de escritorio Linux para descubrir aplicaciones AppImage, administrar tu biblioteca personal, explorar herramientas Punto Vuela y consultar recursos.

## Secciones de la aplicación

- **Inicio:** accesos a las áreas principales.
- **Catálogo AppImage:** búsqueda, categorías, fichas y descargas disponibles desde fuentes del proyecto.
- **Mis aplicaciones:** abrir, reparar permisos, comprobar actualizaciones compatibles, actualizar y eliminar AppImages locales.
- **Herramientas Punto Vuela:** descubrir paquetes publicados en Releases públicas del ecosistema.
- **Banco de recursos:** enlaces a recursos por áreas temáticas.
- **FAQs de software:** preguntas frecuentes y guías de referencia.
- **Contacto y propuestas:** selector de centro, formulario, vista previa, aceptación de privacidad y condiciones, Turnstile y opciones de correo/WhatsApp.
- **Ayuda y documentación:** documentación integrada.
- **Tema:** claro, oscuro o automático; navegación lateral expandible/compacta.

## Guías

- Guía integrada: archivo `GUIA-DE-AYUDA.md`.
- Guía web interactiva y capturas: https://toolkit.javigallego.es/guia.html
- Web del proyecto: https://toolkit.javigallego.es/

## Compatibilidad

Objetivo Linux x86_64, con atención a Ubuntu 20.04 y posteriores. Las AppImages se gestionan en el perfil del usuario y no requieren privilegios de administrador. La compatibilidad de cada AppImage depende de sus bibliotecas, glibc, FUSE, controladores y requisitos publicados por su desarrollador.

## Desarrollo

Requisitos: Node.js/npm compatibles con Electron 43.

```bash
npm ci
npm run dev
```

Comprobaciones y empaquetado:

```bash
npm run typecheck
npm run build
npm run dist:appimage
```

## Seguridad y límites

- Renderer sin acceso Node directo; operaciones locales mediadas por IPC.
- Las verificaciones de descarga no constituyen análisis antivirus.
- AppImageUpdate depende de metadatos compatibles de la aplicación.
- El envío de propuestas depende de la disponibilidad del servicio remoto de correo.

## Contacto

Francisco Javier Gallego Orellana · Puntos Vuela Montejaque  
Correo: montejaque@puntosvuela.es  
WhatsApp: https://wa.me/34633402959

Código MIT. Logos, marcas y recursos de terceros conservan sus derechos respectivos.
