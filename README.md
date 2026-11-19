# Puntos Vuela Toolkit

**Puntos Vuela Toolkit — Francisco Javier Gallego Orellana**  
Aplicación de escritorio para Linux que reúne un catálogo comunitario de AppImages, herramientas de Punto Vuela y una biblioteca local de aplicaciones.

## Guía interactiva y capturas

Consulta la [guía interactiva de Puntos Vuela Toolkit](https://montejaque.github.io/punto-vuela-linux-toolkit/) para recorrer las secciones de la aplicación con capturas de pantalla, instrucciones paso a paso y consejos de uso.

> Las capturas de pantalla se generarán automáticamente desde una ejecución real de la interfaz Electron en un entorno Linux de CI, con datos de demostración para evitar exponer información personal o depender de servicios externos.

## Funciones

- Catálogo AppImage Community con búsqueda, categorías y fichas.
- Descarga desde fuentes oficiales del proyecto cuando el catálogo identifica una Release compatible.
- Biblioteca de aplicaciones locales: abrir, permisos, actualización compatible y eliminación.
- Herramientas Punto Vuela de repositorios públicos.
- Banco de recursos y FAQs de software.
- Tema claro, oscuro o automático.
- Contacto y propuesta de aplicaciones con selección de centro, revisión de mensaje, correo y WhatsApp.
- Verificación Turnstile para proteger el envío de propuestas.

## Capturas

Las imágenes actuales de la interfaz se publican en `docs/screenshots/` y se reutilizan en la guía web. El proceso de capturas automatizado documenta la versión y commit de la interfaz capturada.

## Tecnología

Electron · React · TypeScript · Vite · Lucide React · Cloudflare Workers para el endpoint de correo · Gmail API para la entrega.

## Compatibilidad y uso

Objetivo: Linux x86_64, con atención a Ubuntu 20.04 y posteriores. La gestión de AppImages se realiza en el perfil del usuario y no requiere privilegios de administrador. La compatibilidad de cada aplicación depende también de sus bibliotecas, drivers y requisitos publicados por el autor.

## Desarrollo

Requisitos: Node.js compatible con Electron 43 y npm.

```bash
cd desktop-electron
npm ci
npm run dev
```

Comprobaciones y build:

```bash
npm run typecheck
npm run build
npm run dist:appimage
```

## Contacto y soporte

**Responsable del proyecto:** Francisco Javier Gallego Orellana  
**Proyecto:** Puntos Vuela Montejaque

- Correo: [montejaque@puntosvuela.es](mailto:montejaque@puntosvuela.es)
- WhatsApp: [+34 633 402 959](https://wa.me/34633402959)

## Identidad visual y licencia

Acento amarillo `#F3D54E`, antracita y blanco. MIT para el código del proyecto. Los logos y recursos de marca pertenecen a sus titulares y no quedan relicenciados por la licencia del código.
