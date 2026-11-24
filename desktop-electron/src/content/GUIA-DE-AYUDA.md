# Guía de ayuda — Puntos Vuela Toolkit

Puntos Vuela Toolkit permite descubrir aplicaciones AppImage, administrar aplicaciones locales, consultar herramientas Punto Vuela y acceder a recursos formativos y de software.

## Actualizador de Toolkit

En las versiones empaquetadas, la aplicación consulta GitHub Releases unos 5 segundos después del inicio y vuelve a comprobar cada 6 horas. No descarga ni instala sin confirmación.

- El canal estable ofrece releases estables compatibles.
- Las compilaciones de prueba usan etiquetas `prueba-N` y no proponen números inferiores a la versión de prueba instalada.
- El modal muestra el release detectado y las novedades; en ventanas pequeñas el contenido se puede desplazar y los botones permanecen accesibles.
- Si pospones el aviso, queda un banner en la parte superior con la acción **Actualizar ahora**.
- Al iniciar la descarga, verifica SHA-256, realiza copia de seguridad y reemplaza la AppImage. Si falla la comprobación de arranque, intenta recuperar la copia anterior.

Las capturas reales del modal y banner del actualizador están pendientes de obtener desde una ejecución real de Electron. No se utilizarán maquetas ni recreaciones.


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
Los iconos y capturas del catálogo pueden descargarse de sus orígenes mediante HTTPS y guardarse en la caché local persistente. Se aceptan PNG, JPEG, WebP, GIF y SVG, hasta 8 MB por imagen. Los nombres se derivan de la URL y se guardan metadatos técnicos. Las imágenes guardadas no caducan automáticamente. Los errores se registran localmente para diagnóstico, pero cada nueva solicitud reintenta la descarga inmediatamente (sin espera de 12 horas).

En Ayuda, **Diagnosticar caché de imágenes** muestra la ruta, contadores y entradas, incluidos los detalles técnicos de errores. **Limpiar errores de caché** elimina solo los registros `.failed.json`; no borra las imágenes. La caché está en `~/.local/share/punto-vuela-linux-toolkit/cache/images`, incluso si `XDG_DATA_HOME` está configurado. Se crea al arrancar; si falla la creación, se muestra un aviso. Para vaciar las imágenes, cierra la aplicación y elimina la carpeta `cache/images`; se recreará al siguiente inicio. Su contenido no se transmite al servicio de propuestas, aunque los servidores de imagen reciben solicitudes HTTPS y datos técnicos de conexión.

## Mis aplicaciones
La biblioteca muestra las AppImages que gestiona el usuario. Desde sus acciones puedes abrirlas, corregir permisos, comprobar actualizaciones compatibles, actualizar cuando exista soporte y eliminar archivos. El almacenamiento se encuentra en tu perfil de usuario.

## Actualizaciones de aplicaciones
AppImageUpdate solo puede actualizar archivos con metadatos compatibles. Si no hay soporte, revisa la web o Releases oficiales del proyecto.

## Actualizador de Toolkit
En builds empaquetadas, Toolkit consulta GitHub Releases unos 5 segundos después del inicio y cada 6 horas mientras permanece abierto. La consulta no instala automáticamente. Las releases estables se buscan en el canal estable; las builds de prueba identificadas como `prueba-N` solo reciben avisos para un número superior al incorporado en la build y se etiquetan como **PRUEBA**.

El modal permite **Actualizar ahora** o **Más tarde**. Al posponerlo, queda un banner para retomar. En ventanas de menor altura, el contenido se desplaza y las acciones quedan accesibles al pie. La descarga verifica SHA-256, conserva una copia de la AppImage actual y puede recuperarla si no se confirma el inicio de la versión nueva.

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
- Guía web de uso (sin capturas de interfaz en esta revisión): https://toolkit.javigallego.es/guia.html
- Releases: https://github.com/Montejaque/punto-vuela-linux-toolkit/releases
- Privacidad: https://toolkit.javigallego.es/privacy.html
- Condiciones: https://toolkit.javigallego.es/terms.html

## Contacto
Correo: montejaque@puntosvuela.es  
WhatsApp: https://wa.me/34633402959
