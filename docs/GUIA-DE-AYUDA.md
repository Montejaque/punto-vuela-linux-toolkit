# Guía de ayuda — Punto Vuela Linux Toolkit

> **Identidad visual:** fondo antracita, amarillo corporativo `#F3D54E`, tipografía Inter, tarjetas limpias y componentes de alto contraste. Esta guía utiliza la misma identidad que las herramientas Punto Vuela para Linux.

## 1. ¿Qué es Punto Vuela Linux Toolkit?

Es el centro de software de Punto Vuela para Linux. Reúne los proyectos propios, permite organizar aplicaciones AppImage y ofrece acceso a fuentes de software.

## 2. Dónde se guardan las AppImages

Las aplicaciones descargadas desde el catálogo se guardan en una carpeta propia del usuario:

```text
~/.local/share/punto-vuela-linux-toolkit/AppImages/
```


Puedes abrirla desde el gestor de archivos. Cada AppImage descargada se conserva como un archivo independiente; eliminar una AppImage de esta carpeta no desinstala paquetes del sistema ni borra documentos personales.

## 3. Descargar una AppImage

1. Abre el catálogo AppImage y localiza la aplicación.
2. Comprueba que el enlace procede de la web oficial del proyecto o de una ficha fiable de AppImageHub.
3. Descarga el archivo con extensión `.AppImage`.
4. El Toolkit comprueba que la dirección de descarga sea HTTPS y que el archivo recibido tenga cabecera ELF.
5. El archivo se guarda en la carpeta AppImages y recibe automáticamente permisos de ejecución.

**Seguridad:** una AppImage es un programa ejecutable. Descarga solo software de autores y fuentes en los que confíes. La cabecera ELF y los permisos de ejecución no certifican que el programa sea seguro. Cuando el editor publique hashes o firmas verificables, deben comprobarse antes de ejecutar el archivo.

## 4. Comprobar y actualizar aplicaciones

AppImage no dispone de un repositorio universal de versiones. Para que una AppImage pueda actualizarse mediante AppImageUpdate, el autor debe incluir información de actualización compatible dentro del propio archivo.

El procedimiento recomendado es:

1. Al terminar una descarga, el Toolkit intenta comprobar automáticamente si hay una actualización.
2. También puedes seleccionar una AppImage descargada y solicitar **Comprobar actualizaciones**.
3. Si el archivo incorpora información compatible, AppImageUpdate consulta su origen de actualización.
4. Si existe una versión nueva, revisar el resultado y confirmar **Actualizar**.
5. La herramienta realiza la actualización y conserva una copia de respaldo cuando el mecanismo lo permite.

Si el archivo no incluye información de actualización, el Toolkit debe indicarlo como **No compatible con actualización automática**. En ese caso habrá que consultar la ficha de AppImageHub o la web del desarrollador y descargar la versión nueva manualmente. No se debe afirmar que está actualizada si no se ha podido comprobar.

### AppImageHub y las versiones

AppImageHub es un catálogo, no un repositorio universal que garantice metadatos de versión para todos los programas. Algunas AppImages publicadas allí incorporan información Pling/zsync y otras pueden no hacerlo. La comprobación automática depende de esa información o de una fuente de versiones explícita y verificable del proyecto.

## 5. Permisos de ejecución

El Toolkit asigna automáticamente permisos de ejecución al terminar una descarga válida. Si copias manualmente una AppImage a la carpeta y no arranca, puedes habilitar el permiso desde las propiedades del archivo o con:

```bash
chmod u+x "Nombre-de-la-aplicacion.AppImage"
```

## 6. Problemas habituales

| Situación | Qué hacer |
|---|---|
| No se puede descargar | Comprueba la conexión y que el enlace sea HTTPS y directo al archivo. |
| El archivo no es una AppImage | Vuelve a la ficha y utiliza el enlace correcto del archivo `.AppImage`. |
| No tiene permisos de ejecución | Vuelve a descargarla desde el Toolkit o aplica `chmod u+x`. |
| No se puede comprobar una actualización | Comprueba que la AppImage incorpore información de actualización. Si falta el CLI, el Toolkit intentará descargar el actualizador oficial y verificar su SHA-256. |
| La aplicación no arranca | Consulta los requisitos del desarrollador; algunas AppImages necesitan FUSE u otras bibliotecas del sistema. |
| La descarga no procede de una fuente fiable | No ejecutes el archivo; busca la web oficial y las verificaciones publicadas por el autor. |

## 7. Privacidad y control

- Las comprobaciones de actualización deben iniciarse desde la aplicación o configurarse expresamente por el usuario.
- No se debe reemplazar una AppImage sin autorización del usuario.
- No se necesita root para descargar, dar permisos o gestionar archivos en la carpeta personal.
- Los archivos originales o copias de respaldo no deben eliminarse sin una confirmación clara.

## 8. Proyectos de Punto Vuela

Desde la sección Punto Vuela puedes acceder a los repositorios de las herramientas propias. Revisa siempre sus instrucciones y requisitos antes de instalar.

## 9. Limitaciones conocidas

- No todas las AppImages publicadas en AppImageHub ofrecen actualización automática.
- Un resultado de comprobación desconocido no equivale a “sin actualizaciones”.
- La compatibilidad con Ubuntu y otras distribuciones depende de los requisitos de cada AppImage, del entorno gráfico y de bibliotecas como FUSE.
- La gestión de AppImages no sustituye al gestor de paquetes del sistema.

---

**Punto Vuela Linux Toolkit** · Guía de ayuda  
Colores corporativos: antracita y amarillo `#F3D54E` · Tipografía: Inter
