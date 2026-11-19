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
La sección Ayuda incluye guía, información de compatibilidad, gestión de AppImages, actualizaciones, privacidad y condiciones. También puedes consultar la [guía web ilustrada](https://toolkit.javigallego.es/guia.html).

## 10. Tema y navegación
Puedes seleccionar tema claro, oscuro o automático. La navegación lateral se puede expandir o contraer.

## 11. Compatibilidad y seguridad
- El objetivo es Linux x86_64, con especial atención a Ubuntu 20.04 y posteriores.
- Ubuntu 20.04 utiliza glibc 2.31; una AppImage que requiera una glibc más reciente puede no ejecutarse.
- También pueden existir requisitos de FUSE, controladores, bibliotecas y otros componentes.
- La comprobación del tipo de archivo o del ejecutable no es un antivirus.
- AppImageUpdate solo funciona con metadatos compatibles incorporados por el editor.
- El Toolkit gestiona aplicaciones en el espacio de usuario y no necesita root para estas operaciones.

## 12. Descarga, soporte y documentación
- Web: https://toolkit.javigallego.es/
- Releases: https://github.com/Montejaque/punto-vuela-linux-toolkit/releases
- Guía interactiva: https://toolkit.javigallego.es/guia.html
- Privacidad: https://toolkit.javigallego.es/privacy.html
- Condiciones: https://toolkit.javigallego.es/terms.html

**Contacto:** montejaque@puntosvuela.es · [WhatsApp 633 402 959](https://wa.me/34633402959)
