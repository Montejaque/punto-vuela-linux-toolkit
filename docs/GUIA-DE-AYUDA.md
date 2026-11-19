# Guía de uso — Puntos Vuela Toolkit

**Desarrollo y mantenimiento:** Francisco Javier Gallego Orellana · Puntos Vuela Montejaque

Esta guía describe la edición Electron de Puntos Vuela Toolkit. Las pantallas y botones pueden variar ligeramente entre versiones.

## 1. Inicio

Desde Inicio encontrarás una introducción y accesos directos al Catálogo AppImage, Mis aplicaciones y Herramientas Punto Vuela.

![Inicio](screenshots/01-inicio.png)

## 2. Catálogo AppImage

Explora el feed de AppImage Community. Puedes buscar por nombre, descripción, categoría o autor y revisar la información que la fuente publica.

![Catálogo](screenshots/02-catalogo.png)

**Instalar:** utiliza el botón de instalación cuando la ficha tenga una descarga compatible. El Toolkit descarga desde la fuente del proyecto, no aloja el software.

## 3. Ficha de aplicación

Abre los detalles para consultar descripción, icono, autor, licencia, compatibilidad y versión cuando esos metadatos estén disponibles.

![Ficha de aplicación](screenshots/03-ficha-app.png)

La información ausente en la fuente no se debe interpretar como garantía. Consulta el sitio del desarrollador si falta algún dato.

## 4. Mis aplicaciones

La biblioteca muestra las AppImages gestionadas por el usuario. Desde aquí puedes abrir una aplicación, reparar permisos, comprobar si dispone de actualización compatible, actualizar o eliminar el archivo.

![Mis aplicaciones](screenshots/04-mis-aplicaciones.png)

Las aplicaciones se guardan dentro del perfil personal, habitualmente en `~/.local/share/punto-vuela-linux-toolkit/AppImages` (o bajo `$XDG_DATA_HOME` si se configura).

## 5. Herramientas Punto Vuela

Sección para descubrir aplicaciones publicadas en los repositorios propios. Revisa la versión y ficha antes de instalar.

![Herramientas Punto Vuela](screenshots/05-herramientas.png)

## 6. Banco de recursos

Acceso agrupado a recursos de creatividad, formación, oficina, tecnología, ciudadanía y emprendimiento. Los enlaces llevan a los portales originales.

![Banco de recursos](screenshots/06-recursos.png)

## 7. FAQs de software

Accede a preguntas frecuentes, guías y videotutoriales de referencia para tareas habituales de la red.

![FAQs](screenshots/07-faqs.png)

## 8. Contacto y propuestas

Puedes seleccionar tu centro Punto Vuela, revisar y completar los datos de contacto y enviar una propuesta de aplicación. El formulario requiere la lectura y aceptación de los apartados legales y la comprobación antispam.

![Contacto](screenshots/08-contacto.png)

Antes del envío, el mensaje se muestra en una vista previa editable. Puedes elegir correo electrónico o WhatsApp. El correo se envía si el servicio remoto está disponible; WhatsApp abre una conversación para que confirmes el envío.

## 9. Ayuda y documentación

Incluye explicaciones de uso, compatibilidad, gestión de aplicaciones, actualizaciones y privacidad.

![Ayuda](screenshots/09-ayuda.png)

## 10. Compatibilidad y seguridad

- Ubuntu 20.04 utiliza glibc 2.31. Una AppImage que requiere una glibc posterior puede no ejecutarse.
- Los requisitos glibc no garantizan compatibilidad completa: pueden existir dependencias de FUSE, drivers, bibliotecas y otros componentes.
- Descarga software desde fuentes fiables. La validación ELF no es un antivirus.
- AppImageUpdate solo puede comprobar/actualizar aplicaciones que incorporen metadatos compatibles.
- La aplicación no ejecuta instalaciones privilegiadas del sistema. No necesita root para las funciones de gestión de AppImages en el espacio del usuario.

## 11. Contacto

**Francisco Javier Gallego Orellana** · Puntos Vuela Montejaque

- [montejaque@puntosvuela.es](mailto:montejaque@puntosvuela.es)
- [WhatsApp +34 633 402 959](https://wa.me/34633402959)

---

*Puntos Vuela Toolkit · Guía de uso*
