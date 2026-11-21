# Guía de ayuda — Puntos Vuela Toolkit

Puntos Vuela Toolkit permite descubrir aplicaciones AppImage, administrar aplicaciones locales, consultar herramientas Punto Vuela y acceder a recursos formativos y de software.

## Navegación
- **Inicio:** resumen y accesos directos.
- **Catálogo AppImage:** búsqueda, categorías y fichas de aplicaciones.
- **Mis aplicaciones:** abrir, reparar permisos, revisar actualizaciones compatibles, actualizar y eliminar AppImages de tu perfil.
- **Herramientas Punto Vuela:** explorar aplicaciones publicadas en repositorios públicos.
- **Banco de recursos:** abrir recursos temáticos en sus portales de origen.
- **FAQs de software:** consultar preguntas frecuentes, guías y vídeos.
- **Contacto y propuestas:** seleccionar centro, completar propuesta y revisar el mensaje antes de compartirlo.
- **Ayuda y documentación:** documentación, compatibilidad, seguridad, privacidad y condiciones.

## Catálogo e instalación
Busca y filtra el catálogo. Revisa la ficha y utiliza Instalar cuando exista un recurso compatible. El Toolkit descarga desde el origen de la aplicación; no aloja las AppImages de terceros.

## Caché local de imágenes
Los iconos y capturas del catálogo pueden descargarse de sus orígenes mediante HTTPS y guardarse en la caché local persistente. Se aceptan PNG, JPEG, WebP, GIF y SVG, hasta 8 MB por imagen. Los nombres se derivan de la URL y se guardan metadatos técnicos. Las imágenes positivas no caducan automáticamente; las URL que fallan quedan en caché de error durante 12 horas antes de volver a intentarse.

La caché está en `~/.local/share/punto-vuela-linux-toolkit/cache/images`, incluso si `XDG_DATA_HOME` está configurado. Se crea al arrancar; si falla la creación, se muestra un aviso. Para limpiarla, cierra la aplicación y elimina la carpeta `cache/images`; se recreará al siguiente inicio. Su contenido no se transmite al servicio de propuestas, aunque los servidores de imagen reciben solicitudes HTTPS y datos técnicos de conexión.

## Mis aplicaciones
La biblioteca muestra las AppImages que gestiona el usuario. Desde sus acciones puedes abrirlas, corregir permisos, comprobar actualizaciones compatibles, actualizar cuando exista soporte y eliminar archivos. El almacenamiento se encuentra en tu perfil de usuario.

## Actualizaciones
AppImageUpdate solo puede actualizar archivos con metadatos compatibles. Si no hay soporte, revisa la web o Releases oficiales del proyecto.

## Contacto y propuestas
Selecciona un centro Punto Vuela, revisa los datos cargados si están disponibles y completa los campos de propuesta. Consulta y acepta privacidad, protección de datos y condiciones. La comprobación antispam Cloudflare Turnstile es necesaria antes de abrir la vista previa.

En la vista previa:
- **Correo:** la propuesta se envía a través del servicio remoto. El Toolkit muestra el resultado devuelto.
- **WhatsApp:** se abre WhatsApp con el mensaje preparado; el envío final lo confirmas desde WhatsApp.

## Tema
Puedes elegir tema claro, oscuro o automático. La barra de navegación lateral puede contraerse o expandirse.

## Compatibilidad
Objetivo Linux x86_64, con especial atención a Ubuntu 20.04 y posteriores. Ubuntu 20.04 usa glibc 2.31; aplicaciones que exijan una versión superior pueden no funcionar. Revisa también FUSE, controladores y bibliotecas requeridas.

## Seguridad
Descarga desde fuentes fiables. Las comprobaciones de tipo de archivo y ejecutable no sustituyen a un antivirus. El Toolkit no instala paquetes del sistema ni ejecuta operaciones privilegiadas silenciosas.

## Documentación web
- Web: https://toolkit.javigallego.es/
- Guía ilustrada: https://toolkit.javigallego.es/guia.html
- Releases: https://github.com/Montejaque/punto-vuela-linux-toolkit/releases
- Privacidad: https://toolkit.javigallego.es/privacy.html
- Condiciones: https://toolkit.javigallego.es/terms.html

## Contacto
Correo: montejaque@puntosvuela.es  
WhatsApp: https://wa.me/34633402959
