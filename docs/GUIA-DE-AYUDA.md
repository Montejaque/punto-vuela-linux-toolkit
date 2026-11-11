# Guía de ayuda — Punto Vuela Linux Toolkit

> **Identidad visual Punto Vuela:** amarillo principal #F3D54E, antracita y blanco; tipografía Inter en la interfaz. Los colores secundarios se reservan para estados y categorías. Esta guía está maquetada con alto contraste para que los titulares y subtítulos se lean tanto en pantalla como al imprimir.

## 1. Qué es el centro de software

Punto Vuela Linux Toolkit reúne un catálogo comunitario de aplicaciones AppImage, los proyectos Linux de Punto Vuela y una biblioteca local para descargar, ejecutar, actualizar y eliminar AppImages sin permisos de administrador.

El catálogo principal utiliza el feed público de AppImage Community (https://appimage.github.io/feed.json). AppImageHub/Pling es otra fuente y se abre por separado; no se presenta como si fuera el mismo catálogo.

## 2. Catálogo de aplicaciones

1. Entra en **Catálogo AppImage**.
2. Escribe el nombre, categoría, descripción o autor y pulsa **Buscar**.
3. Revisa la categoría, licencia, autor y requisito de glibc que muestra cada ficha.
4. Pulsa **Instalar** para descargar el archivo AppImage de la última versión de GitHub Releases cuando el catálogo identifica un repositorio y encuentra un archivo compatible.
5. Si no existe un archivo AppImage en la última versión, abre el proyecto del autor y sigue sus instrucciones oficiales.

El catálogo no aloja los programas: los descarga directamente desde la fuente del desarrollador. La disponibilidad y el nombre de los archivos dependen de cada proyecto.

## 3. Compatibilidad con Ubuntu 20.04 o posterior

Ubuntu 20.04 utiliza glibc 2.31. El catálogo muestra el requisito declarado por el proyecto:

- **Requisito hasta 2.31:** compatible según el requisito glibc publicado; pueden existir otras dependencias.
- **Requisito superior a 2.31:** el botón de instalación queda bloqueado en el objetivo Ubuntu 20.04.
- **Requisito no declarado:** no es posible garantizar compatibilidad. Revisa la documentación del autor antes de ejecutar.

La compatibilidad no depende únicamente de glibc: una AppImage puede requerir FUSE, controladores gráficos, bibliotecas del sistema u otros componentes. La aplicación se compila dentro de un entorno Ubuntu 20.04 para reducir el riesgo de introducir dependencias de una versión posterior. Cada paquete debe superar las pruebas automatizadas y las pruebas reales en Ubuntu 20.04 antes de publicarse como estable.

## 4. Dónde se guardan las aplicaciones

Las descargas se guardan en el perfil del usuario:

    ~/.local/share/punto-vuela-linux-toolkit/AppImages/

Si existe la variable XDG_DATA_HOME, se utiliza esa ubicación en lugar de ~/.local/share. No se necesita root para crear esta carpeta, descargar aplicaciones o administrar los archivos.

## 5. Descargar, ejecutar y administrar

- **Descargar:** pega un enlace HTTPS directo a un archivo .AppImage o utiliza el botón Instalar del catálogo.
- **Permisos:** el Toolkit aplica automáticamente permisos de ejecución a las descargas válidas. También permite corregir permisos de archivos añadidos manualmente a la carpeta.
- **Abrir:** ejecuta la aplicación seleccionada desde la biblioteca.
- **Eliminar:** solicita confirmación antes de borrar el archivo AppImage de la carpeta administrada. No elimina documentos personales ni paquetes del sistema.
- **Abrir carpeta:** muestra el directorio local de aplicaciones en el gestor de archivos.

Una descarga se valida como archivo ELF, pero eso no es un análisis antivirus ni una verificación criptográfica del editor. Ejecuta únicamente software de fuentes fiables.

## 6. Actualizaciones

1. El Toolkit comprueba si la AppImage incorpora información de actualización compatible.
2. Si el editor ha publicado metadatos zsync/Pling compatibles, AppImageUpdate consulta el origen.
3. Si hay una versión nueva, pulsa **Actualizar** para confirmar la operación.
4. Se conserva la copia de respaldo que proporciona el actualizador cuando el formato lo permite.

No existe un mecanismo universal para detectar versiones nuevas de todas las AppImages. Si el autor no ha incluido metadatos compatibles, la aplicación informa de que no puede comprobarla; no debe mostrar un falso estado de “actualizada”. En ese caso abre la web del proyecto y descarga manualmente la nueva versión.

## 7. Catálogo AppImageHub / Pling

AppImageHub (Pling) es una fuente independiente del feed comunitario de AppImage. Desde **Mis aplicaciones** puedes abrir su web, consultar la ficha de una aplicación y pegar el enlace HTTPS directo de descarga cuando el editor lo proporcione. No todas las fichas ofrecen un enlace directo, ni todas las aplicaciones tienen actualizaciones automáticas.

## 8. Seguridad y privacidad

- Las descargas y actualizaciones se realizan desde conexiones HTTPS.
- No se ejecutan instalaciones privilegiadas de paquetes del sistema.
- La instalación desde el catálogo utiliza las fuentes originales del editor.
- Las actualizaciones reemplazan archivos solo después de que el usuario las solicite.
- La eliminación requiere confirmación.
- El catálogo comunitario es una fuente de descubrimiento, no una garantía de seguridad o compatibilidad.

## 9. Problemas habituales

| Problema | Solución |
|---|---|
| No carga el catálogo | Comprueba la conexión y pulsa Actualizar catálogo. Se utiliza una copia en caché para búsquedas recientes. |
| La aplicación no tiene botón Instalar | El catálogo no proporciona un repositorio GitHub o no hay un archivo AppImage en la última versión publicada. Abre la web del autor. |
| Requiere glibc superior a 2.31 | No es apta para Ubuntu 20.04. Busca una versión anterior compatible o una alternativa. |
| No arranca | Comprueba FUSE y las dependencias indicadas por el autor. |
| No se puede comprobar una actualización | El autor puede no haber incluido metadatos compatibles con AppImageUpdate. |
| No se puede descargar | Comprueba que el enlace sea HTTPS y directo al archivo, y que el servidor permita la descarga. |

## 10. Proyectos Punto Vuela

La sección **Punto Vuela** ofrece acceso a los repositorios de las herramientas propias. Consulta el README de cada proyecto para conocer requisitos, versiones y procedimiento de instalación.

---

**Punto Vuela Linux Toolkit** · Guía de ayuda  
Colores de marca: #F3D54E · Antracita · Blanco · Tipografía de interfaz: Inter
