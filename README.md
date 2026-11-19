# Puntos Vuela Toolkit

**Centro de aplicaciones Linux de Punto Vuela.** Una aplicación de escritorio para descubrir aplicaciones AppImage, administrar la biblioteca local y acceder a las herramientas de Punto Vuela desde una interfaz unificada.

> Rama de desarrollo activa: `rewrite/electron-desktop` · Versión Electron: **0.4.0**.  
> La interfaz Electron está implementada con React, TypeScript y Electron. La edición PySide6 anterior se conserva como referencia de migración y para las Releases históricas.

## Capturas de pantalla

Las capturas de la interfaz Electron se incorporarán aquí cuando se genere y ejecute una compilación del commit actual en un escritorio Linux. No se incluyen mockups como si fueran capturas reales.

Capturas previstas:
- **Inicio:** resumen de la aplicación y accesos principales.
- **Catálogo AppImage:** búsqueda, categorías y tarjetas de aplicaciones.
- **Ficha de aplicación:** detalles, compatibilidad y opciones disponibles.
- **Mis aplicaciones:** biblioteca local y acciones de administración.
- **Herramientas Punto Vuela:** catálogo de herramientas propias.
- **Contacto y propuestas:** formulario, revisión de la propuesta y protección antispam.
- **Ayuda y documentación:** guía integrada.

## Funciones principales

- Catálogo AppImage Community a través de su feed JSON público.
- Búsqueda por nombre, descripción, categoría y autor.
- Fichas con información publicada por el proyecto, como licencia, autor y requisito glibc, cuando está disponible.
- Instalación desde GitHub Releases cuando el catálogo identifica un repositorio y una Release con un AppImage x86_64 compatible.
- Biblioteca local para consultar, abrir y eliminar aplicaciones gestionadas.
- Descarga HTTPS, validación del tipo de archivo ELF y permisos de ejecución.
- Comprobación y actualización mediante AppImageUpdate solo cuando la AppImage contiene metadatos compatibles.
- Acceso independiente a AppImageHub/Pling; no se presenta como parte del feed comunitario ni se presupone que proporcione una API de versiones.
- Secciones de proyectos y herramientas propias de Punto Vuela.
- Apariencia clara, oscura o adaptada al sistema.
- Formulario de propuestas con selección de centro, revisión previa y envío por correo o WhatsApp.
- Verificación antispam Turnstile en el flujo de envío por correo.

## Tecnología

- Electron 43
- React 18
- TypeScript
- Vite
- Lucide React
- Cloudflare Workers para el servicio de correo
- Gmail API para la entrega de mensajes

## Estado de la versión Electron

La interfaz Electron y el flujo de propuestas están en desarrollo en `rewrite/electron-desktop`. El servicio Cloudflare Worker `punto-vuela-mail` ha superado el despliegue automatizado de GitHub Actions en la ejecución [44058080605](https://github.com/Montejaque/punto-vuela-linux-toolkit/actions/runs/44058080605).

Este resultado confirma el despliegue del Worker, pero no equivale por sí solo a una prueba funcional completa del envío de correo desde la aplicación. Antes de publicar una versión estable deben completarse las pruebas de extremo a extremo, incluida la verificación Turnstile y el envío real de un mensaje de prueba autorizado.

Los avisos de GitHub Actions sobre Node.js 20 y la futura migración de `ubuntu-latest` son advertencias informativas de mantenimiento; no fueron la causa del fallo anterior ni impidieron el despliegue que terminó correctamente.

## Compatibilidad y distribución

El objetivo de la distribución es Linux x86_64, con especial atención a Ubuntu 20.04 (glibc 2.31) y posteriores.

La estrategia histórica del proyecto contempla AppImage, DEB y RPM. La edición Electron actual debe considerarse distribuible únicamente en los formatos que hayan sido compilados y probados en la ejecución correspondiente. No se debe dar por publicada una AppImage porque exista un workflow o porque se haya compilado una versión anterior.

La compilación no requiere que el usuario final tenga privilegios de administrador para las funciones propias de gestión de AppImages. La aplicación no debe ejecutar instalaciones privilegiadas del sistema de forma silenciosa.

## Capturas reproducibles

Para obtener capturas verificables de la versión actual:

1. Compilar la rama `rewrite/electron-desktop` con las dependencias definidas en `desktop-electron/package.json`.
2. Ejecutar la aplicación en un escritorio Linux real.
3. Capturar las pantallas principales a resolución de escritorio y guardar los PNG en `docs/screenshots/`.
4. Sustituir la lista de pantallas previstas de este README por imágenes de esa ejecución, indicando el commit o versión capturada.

No utilizar imágenes conceptuales, pantallas reconstruidas ni capturas de una versión antigua etiquetándolas como la versión actual.

## Desarrollo de Electron

Requisitos: Node.js compatible con Electron 43 y npm.

```bash
cd desktop-electron
npm ci
npm run dev
```

Compilación de la interfaz y del proceso principal:

```bash
npm run build
```

Comprobaciones de tipos:

```bash
npm run typecheck
```

Generación local de AppImage x86_64:

```bash
npm run dist:appimage
```

El artefacto generado se guarda en `desktop-electron/release/`. Debe comprobarse el resultado real y probarse en Ubuntu 20.04 antes de publicarlo.

## Envío de solicitudes por correo

El formulario utiliza un Cloudflare Worker desplegado en:

`https://punto-vuela-mail.montejaque.workers.dev`

El Worker:
- entrega la página de verificación Turnstile en `/turnstile`;
- valida el token con Cloudflare Turnstile antes de aceptar el envío;
- aplica limitación de frecuencia mediante el binding KV `RATE_LIMIT`;
- envía el mensaje mediante Gmail API;
- mantiene las credenciales OAuth en secretos de Cloudflare, fuera del código de la aplicación.

Los secretos de GitHub Actions utilizados para el despliegue son `CLOUDFLARE_API_TOKEN` y `CLOUDFLARE_ACCOUNT_ID`. No introducir sus valores en el repositorio, README, código de cliente o capturas.

La configuración del servicio y de sus secretos debe mantenerse documentada en [docs/CORREO-CLOUDFLARE-WORKERS.md](docs/CORREO-CLOUDFLARE-WORKERS.md).

## Identidad visual

- Amarillo corporativo de Toolkit: `#F3D54E`.
- Antracita, blanco y grises neutros.
- Logotipo oficial local: `desktop-electron/public/assets/logo_toolkit.svg`.

El logotipo y los recursos de marca pertenecen a sus titulares. La licencia MIT del código no relicencia la identidad corporativa.

## Ayuda

La guía de uso está en [docs/GUIA-DE-AYUDA.md](docs/GUIA-DE-AYUDA.md). Debe mantenerse alineada con la versión Electron activa y evitar instrucciones exclusivas de la edición PySide6 cuando no correspondan.

## Licencia

MIT para el código del proyecto. El logotipo y los demás recursos de marca permanecen sujetos a los derechos de sus respectivos titulares.
