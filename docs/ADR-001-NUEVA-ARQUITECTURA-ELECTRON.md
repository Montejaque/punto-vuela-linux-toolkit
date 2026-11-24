# ADR-001: Nueva interfaz de escritorio con Electron

- Estado: implementación Electron activa; validación de publicación y pruebas manuales pendientes
- Fecha de actualización: 2026-11-24
- Fecha de decisión original: 2026-11-16
- Rama: `rewrite/electron-desktop`
- Versiones anteriores: se conservan sin modificar (`pruebas-80` y anteriores)

## Contexto

La interfaz actual usa PySide6 + Qt Quick/QML. Las capturas de uso muestran problemas repetidos de distribución, estados de controles, filtros densos y accesibilidad. La capa visual está concentrada en un único archivo QML de gran tamaño, lo que hace más difícil revisar y mantener los componentes.

La aplicación debe seguir funcionando en Ubuntu 20.04, en equipos x86_64, sin privilegios de administrador y distribuirse como AppImage. También debe conservar las funciones existentes: gestión de AppImages, catálogo oficial, herramientas Punto Vuela, directorio de centros, formulario de propuestas y envío mediante el Worker de Cloudflare.

## Decisión para el prototipo

Evaluar **Electron + React + TypeScript + Vite** como nueva interfaz, con estas condiciones:

- HTML semántico y CSS moderno, usando `rem` para tipografía, espaciado, dimensiones y puntos de ruptura.
- Componentes accesibles por teclado, etiquetas asociadas, foco visible, contraste WCAG 2.2 AA y pruebas automatizadas con axe.
- React para separar navegación, formularios, catálogo, filtros y tarjetas en componentes mantenibles.
- Electron main process para operaciones locales; renderer aislado y sin acceso Node directo.
- `contextIsolation: true`, `nodeIntegration: false`, sandbox habilitado y una API limitada mediante preload/contextBridge.
- IPC con lista permitida de operaciones y validación de argumentos en el proceso principal.
- Mantener Cloudflare Worker como servicio de correo; el cliente solo informa de envío correcto cuando el servidor confirma que Gmail API aceptó el mensaje.
- Construir AppImage x86_64 en CI sobre una base Linux compatible con Ubuntu 20.04; probar el artefacto en Ubuntu 20.04 antes de publicarlo.

## Compatibilidad y alternativas

- **Tauri 2 se descarta para el objetivo Ubuntu 20.04**: requiere WebKitGTK 4.1; la documentación oficial de Tauri indica ese conjunto de dependencias para Linux. Ubuntu 20.04 suele proporcionar WebKitGTK 4.0, por lo que no es una base segura para este requisito.
- **Tauri 1** puede usar WebKitGTK 4.0, pero depende del WebKit del sistema y requiere una ruta de compilación Rust/GTK. No se elige para el primer prototipo.
- **Electron** incluye Chromium y electron-builder permite generar AppImage sin instalación ni root. Su principal coste es el tamaño del paquete y el consumo de memoria; se medirán antes de decidir la publicación.

## Estrategia de migración

1. Crear una aplicación Electron mínima que abra y cierre de forma fiable en Ubuntu 20.04.
2. Crear el sistema visual y navegación responsive antes de migrar funcionalidades.
3. Migrar por módulos: catálogo, biblioteca local, utilidades Punto Vuela, formulario y centros.
4. Mantener la lógica de negocio y contratos del Worker separados de la interfaz; portar a Node solo las operaciones locales que realmente lo necesiten.
5. Añadir pruebas unitarias, pruebas de interfaz, auditoría de accesibilidad y smoke test de AppImage.
6. Publicar como una **nueva Release** con tag nuevo (siguiente identificador de pruebas), sin editar ni reemplazar Releases anteriores.

## Criterios de aceptación

- Arranque con doble clic tras habilitar el permiso ejecutable.
- No requiere sudo ni instalación de paquetes en el equipo de destino.
- Funciona en Ubuntu 20.04 x86_64.
- El menú lateral se expande y contrae sin truncar nombres ni perder contexto.
- Filtros del catálogo en un panel compacto, con búsqueda, categorías y contador de resultados.
- Formulario con controles legales alineados, legibles y accesibles; motivo obligatorio y observaciones opcionales.
- Envío de correo verificado de extremo a extremo; errores de configuración y de Gmail claramente diferenciados.
- Ninguna Release publicada anteriormente se modifica o elimina.

## Riesgos y mitigaciones

- **Tamaño Electron**: medir AppImage y memoria; evitar dependencias innecesarias.
- **Seguridad IPC**: API pequeña, validación en main y renderer sin Node.
- **Compatibilidad glibc**: compilar en entorno con glibc 2.31 o más antiguo y ejecutar prueba real en Ubuntu 20.04.
- **Correo**: no simular éxito; requiere despliegue del Worker y prueba real con cuenta autorizada.

## Estado de implementación (24-11-2026)

La rama Electron ya incorpora:
- Proceso principal con IPC de lista permitida; el renderer no tiene acceso Node directo.
- Feed AppImage Community con caché, búsqueda, categorías, ficha, licencia y evaluación del requisito glibc frente a Ubuntu 20.04.
- Descarga HTTPS, comprobación ELF, almacenamiento por usuario, permisos, lanzamiento, lanzadores .desktop, eliminación y actualización delegada a AppImageUpdate con verificación SHA-256 del actualizador.
- Descubrimiento de Releases públicas de repositorios Montejaque y descarga de AppImages x86_64.
- Directorio de centros desde puntosvuela.es y precarga de datos públicos de contacto en el formulario.
- Formulario de propuestas con campos obligatorios, motivo, observaciones y aceptaciones legales; envío a Cloudflare Worker y confirmación basada en respuesta HTTP/Gmail del servicio.
- Pantallas de biblioteca, herramientas, directorio, contacto y ayuda.
- Caché persistente de iconos y capturas: solo HTTPS y MIME permitidos, límite de 8 MB, claves SHA-256, extensiones reconocibles, metadatos, escritura atómica con temporales únicos, migración de archivos `.img` antiguos y registro local de fallos para diagnóstico; las solicitudes posteriores reintentan inmediatamente (sin espera de 12 horas). La carpeta se inicializa al arrancar y muestra un aviso si falla. La interfaz de Ayuda permite diagnosticar la ruta, conteos y entradas, y limpiar únicamente los registros de fallos.
- Actualizador de Toolkit: consulta GitHub Releases aproximadamente 5 segundos tras abrir la ventana y cada 6 horas en segundo plano mientras la app empaquetada permanece abierta. El canal estable selecciona releases estables con AppImage x86_64 y `SHA256SUMS`; el canal de pruebas usa tags monotónicos `prueba-N` y no ofrece downgrades de número de prueba. Modal y banner identifican las builds de prueba como **PRUEBA**. La instalación requiere acción del usuario, valida SHA-256 y mantiene una copia de recuperación. El modal tiene scroll interno y mantiene las acciones visibles en ventanas bajas.
- CI configurada: los pushes a `rewrite/electron-desktop` publican releases preliminares de prueba con tag `prueba-N`; los tags `v*` publican releases estables. El workflow declara `npm test`, build AppImage y smoke test, pero su ejecución/resultado no se ha verificado en esta revisión.
- Ajustes recientes de interfaz amplían el ancho máximo del formulario de propuestas, panel de desarrollador y sección de ayuda a 88rem para alinearlos.

Pendiente de validación:
- Prueba manual de la AppImage en Ubuntu 20.04 GNOME: arranque, integración de escritorio, navegación y cierre.
- Comprobar compatibilidad de glibc 2.31 y dependencias del artefacto final.
- Prueba real del formulario y del servicio remoto de correo, incluyendo Turnstile y confirmación de entrega.
- Revisión de accesibilidad: teclado, foco, contraste y lector de pantalla.
- Revisión de dependencias y avisos de seguridad relevantes.
- Verificar caché de imágenes, registros de fallos y reintentos inmediatos, persistencia entre reinicios, migración de archivos `.img`, escrituras concurrentes, fallos de permisos y fallback visual; comprobar además los botones de diagnóstico y limpieza de errores.
- Resolver la discrepancia de configuración: `IMAGE_CACHE` está fijada a `~/.local/share/...` y no sigue `XDG_DATA_HOME`, a diferencia del directorio principal de datos.

La guía, README y documentación integrada, además de privacidad y condiciones, se han actualizado para describir el comportamiento de la edición Electron. El estado de los workflows y de la publicación debe verificarse en Actions antes de dar por cerrada la validación. La implementación no debe considerarse Release estable hasta completar las pruebas anteriores.
