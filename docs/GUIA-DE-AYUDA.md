# Guía de uso — Puntos Vuela Toolkit

**Desarrollo y mantenimiento:** Francisco Javier Gallego Orellana · Puntos Vuela Montejaque

Esta guía describe la aplicación de escritorio Electron. Las pantallas pueden variar ligeramente según la versión publicada.

## 1. Inicio
La pantalla Inicio ofrece accesos a las principales secciones: Catálogo AppImage, Mis aplicaciones, Herramientas Punto Vuela y recursos de consulta.

## 2. Catálogo AppImage
Busca aplicaciones por nombre, descripción o autor y utiliza las categorías para filtrar el catálogo. Abre la ficha para revisar los metadatos disponibles.

La información de la ficha depende de los datos que publique la fuente; puede incluir descripción, autor, licencia, versión, icono y requisitos.

## 3. Instalar desde el catálogo
Utiliza el botón de instalación cuando la ficha disponga de un recurso descargable compatible. El Toolkit descarga desde la fuente del proyecto y no aloja ni mantiene el software de terceros.

## 4. Mis aplicaciones
Esta sección reúne los AppImages gestionados en tu perfil de usuario. Permite:
- Abrir una aplicación.
- Corregir o habilitar permisos de ejecución.
- Consultar si hay una actualización compatible.
- Actualizar mediante AppImageUpdate cuando el archivo disponga de metadatos apropiados.
- Eliminar el AppImage y gestionar lanzadores locales.

Los archivos se guardan en el directorio de datos de usuario de la aplicación, normalmente bajo `~/.local/share/punto-vuela-linux-toolkit/AppImages` (o la ruta de `$XDG_DATA_HOME` si está definida).

## 5. Herramientas Punto Vuela
Explora herramientas publicadas en repositorios públicos del proyecto. Comprueba los detalles y el recurso descargable antes de instalar.

## 6. Banco de recursos
Accede a recursos agrupados por áreas. Los enlaces abren los portales de origen, donde se mantiene el contenido.

## 7. FAQs de software
Consulta preguntas frecuentes, guías y videotutoriales enlazados desde el portal de recursos.

## 8. Contacto y propuestas
Selecciona el centro Punto Vuela y revisa los datos de contacto que se cargan cuando están disponibles. Completa la aplicación propuesta, enlace, motivo y observaciones.

Antes de continuar, el formulario requiere consultar y aceptar los apartados legales y completar la comprobación antispam de Cloudflare Turnstile. El texto de la propuesta se muestra en una vista previa.

- **Correo:** el envío se realiza mediante el servicio remoto; la aplicación muestra el resultado recibido del servicio.
- **WhatsApp:** se abre una conversación con el texto preparado para que confirmes el envío en WhatsApp.

## 9. Ayuda y documentación
La sección Ayuda incluye guía, información de compatibilidad, gestión de AppImages, actualizaciones, privacidad y condiciones. También puedes consultar la [guía web](https://toolkit.javigallego.es/guia.html).

## 10. Tema y navegación
Puedes seleccionar tema claro, oscuro o automático. La navegación lateral se puede expandir o contraer.

## 11. Compatibilidad y seguridad
- El objetivo es Linux x86_64, con especial atención a Ubuntu 20.04 y posteriores.
- Ubuntu 20.04 utiliza glibc 2.31; una AppImage que requiera una glibc más reciente puede no ejecutarse.
- También pueden existir requisitos de FUSE, controladores, bibliotecas y otros componentes.
- La comprobación del tipo de archivo o del ejecutable no es un antivirus.
- AppImageUpdate solo funciona con metadatos compatibles incorporados por el editor.
- El Toolkit gestiona aplicaciones en el espacio de usuario y no necesita root para estas operaciones.

## 12. Caché local de imágenes

El catálogo y las fichas pueden mostrar iconos y capturas obtenidos de sus servidores de origen mediante HTTPS. Toolkit mantiene una caché local para reutilizar las imágenes entre sesiones y reducir descargas repetidas.

- Formatos admitidos: PNG, JPEG, WebP, GIF y SVG.
- Tamaño máximo por imagen: 8 MB.
- Las imágenes guardadas se conservan sin caducidad automática; pueden quedar desactualizadas si el origen cambia.
- Los errores de descarga se registran localmente para diagnóstico. Cada nueva solicitud vuelve a intentar descargar la imagen; no existe una espera de 12 horas.
- Los nombres de archivo se derivan de SHA-256 de la URL; se guardan metadatos JSON y se usan extensiones de imagen reconocibles.
- Ruta: `~/.local/share/punto-vuela-linux-toolkit/cache/images`. Actualmente esta ruta fija no sigue `XDG_DATA_HOME`.
- La carpeta se prepara al iniciar la aplicación. Si no puede crearse, se muestra un aviso. Para vaciarla, cierra Toolkit y elimina `cache/images`; se volverá a crear en el siguiente arranque.

En Ayuda, **Diagnosticar caché de imágenes** muestra la ruta, los contadores y las entradas (incluida la URL y el motivo de los fallos). **Limpiar errores de caché** elimina solo los registros `.failed.json`, no las imágenes guardadas.

El contenido de esta caché permanece en el equipo y no se sincroniza ni se envía al servicio de propuestas. Los servidores de origen sí reciben las solicitudes HTTPS de imágenes y pueden registrar datos técnicos de conexión.

## 13. Actualizador automático de la aplicación

En una versión empaquetada, Toolkit consulta GitHub Releases aproximadamente 5 segundos después del inicio y repite la comprobación cada 6 horas mientras está abierto. La consulta no instala la actualización automáticamente.

- **Estable:** busca releases estables con AppImage para la arquitectura del equipo y `SHA256SUMS`.
- **Pruebas:** las builds de desarrollo identificadas como `prueba-N` buscan solo números mayores que el identificador incluido en la build. El modal y el banner muestran **PRUEBA**; no se propone volver a un número inferior.

El modal permite **Actualizar ahora** o **Más tarde**. Si lo pospones, aparece un banner para retomar. En ventanas de menor altura, el contenido puede desplazarse y los botones de acción permanecen accesibles al pie. Al iniciar la actualización, se descarga el AppImage, se comprueba SHA-256 y se conserva una copia previa para recuperación si el arranque de la nueva versión no se confirma.

### Modal de actualización

Cuando se detecta una versión, aparece un diálogo con la versión disponible y la versión instalada. El botón **Actualizar ahora** inicia la descarga y el proceso de actualización; **Más tarde** cierra el diálogo sin descartar la actualización.



### Banner persistente

Si se pulsa **Más tarde** o se cierra el modal, la aplicación muestra un banner en la parte superior del área de trabajo. El banner informa de la versión detectada y permite pulsar **Actualizar ahora** para retomar el proceso. También se puede cerrar el aviso; el comprobador puede volver a mostrarlo si la actualización sigue pendiente.



### Proceso de actualización y recuperación

1. Descarga el AppImage de la release compatible.
2. Verifica la suma SHA-256 usando el archivo de checksums publicado.
3. Conserva una copia de la AppImage actual antes de sustituirla.
4. Sustituye el archivo y solicita reiniciar para usar la nueva versión.
5. Si el inicio de la nueva versión falla antes de confirmarse, el mecanismo de recuperación puede restaurar la copia previa.

**Recomendación:** mantén conexión a Internet durante la comprobación y descarga. No interrumpas el proceso de reemplazo del archivo.


## 14. Actualizador de la propia aplicación

Toolkit comprueba GitHub Releases aproximadamente 5 segundos después de iniciar y repite la comprobación cada 6 horas. Solo avisa: la instalación comienza cuando pulsas **Actualizar ahora**.

- **Estable:** busca releases estables con AppImage x86_64 y `SHA256SUMS`.
- **Pruebas:** las builds de desarrollo usan el canal `prueba-N` y solo ofrecen un número superior al instalado.
- **Modal:** muestra versión instalada, versión disponible, novedades y estado de verificación; el contenido puede desplazarse y los botones se mantienen accesibles en ventanas pequeñas.
- **Banner:** si pospones o cierras el modal, el aviso queda en la parte superior del Toolkit y permite reanudar con **Actualizar ahora**.

### Proceso de actualización

1. Pulsa **Actualizar ahora** para iniciar la descarga.
2. Se valida la suma SHA-256 contra `SHA256SUMS`.
3. Se guarda una copia de seguridad de la AppImage actual.
4. Se reemplaza el archivo y se ofrece reiniciar.
5. Si el inicio de la versión nueva falla durante la comprobación, se intenta restaurar la copia anterior.

No interrumpas el reemplazo y mantén conexión a Internet. Las capturas del modal y del banner se publican en la [guía interactiva](https://toolkit.javigallego.es/guia.html), sección **Actualizador automático**.


## 15. Descarga, soporte y documentación

**Capturas de interfaz:** consulta la guía interactiva publicada, que se genera con capturas durante el flujo de publicación.
- Web: https://toolkit.javigallego.es/
- Releases: https://github.com/Montejaque/punto-vuela-linux-toolkit/releases
- Guía interactiva: https://toolkit.javigallego.es/guia.html
- Privacidad: https://toolkit.javigallego.es/privacy.html
- Condiciones: https://toolkit.javigallego.es/terms.html

**Contacto:** montejaque@puntosvuela.es · [WhatsApp 633 402 959](https://wa.me/34633402959)
