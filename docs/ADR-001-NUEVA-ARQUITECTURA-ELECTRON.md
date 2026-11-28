# ADR-001: Nueva interfaz de escritorio con Electron

- Estado: implementación Electron activa; validación de publicación y pruebas manuales pendientes
- Fecha de actualización: 2026-11-26
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

## Estado de implementación (26-11-2026)

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
- CI de AppImage: los pushes a `rewrite/electron-desktop` que cambien `desktop-electron/**` o el workflow de AppImage ejecutan typecheck, build, empaquetado y smoke test, y publican pre-releases `prueba-N`; los tags `v*` publican releases estables. Se añade filtro de paths para que los pushes solo documentales no generen releases de prueba. `npm test` ejecuta typecheck, no una suite de pruebas unitarias completa.
- Capturas de la guía: 01–09 se generan con Chromium/Playwright sobre el renderer Vite y una API simulada con datos demo. 10–11 se capturan de ventanas reales Electron con estado sintético del updater en modo `--capture-updater-docs` (sin descargar ni instalar). No se versionan. El workflow de Pages valida las 11 PNG y los enlaces antes de desplegar; el fallback es manual y exige las mismas capturas, sin placeholders.
- Ajustes recientes de interfaz amplían el ancho máximo del formulario de propuestas, panel de desarrollador y sección de ayuda a 88rem para alinearlos.

Pendiente de validación:
- Prueba manual de la AppImage en Ubuntu 20.04 GNOME: arranque, integración de escritorio, navegación y cierre.
- Comprobar compatibilidad de glibc 2.31 y dependencias del artefacto final.
- Prueba real del formulario y del servicio remoto de correo, incluyendo Turnstile y confirmación de entrega.
- Revisión de accesibilidad: teclado, foco, contraste y lector de pantalla.
- Revisión de dependencias y avisos de seguridad relevantes.
- Verificar caché de imágenes, registros de fallos y reintentos inmediatos, persistencia entre reinicios, migración de archivos `.img`, escrituras concurrentes, fallos de permisos y fallback visual; comprobar además los botones de diagnóstico y limpieza de errores.
- Resolver la discrepancia de configuración: `IMAGE_CACHE` está fijada a `~/.local/share/...` y no sigue `XDG_DATA_HOME`, a diferencia del directorio principal de datos.

CI comprobada (runs históricos del 24-11-2026, ejecutados sobre el commit `45271b1a23d9d43d94aea89a14e34ae7a811c375`, anterior a este baseline): [AppImage run 420](https://github.com/Montejaque/punto-vuela-linux-toolkit/actions/runs/45353295806) terminó `success` en typecheck, build, empaquetado, smoke test y publicación de `prueba-420`; el job de release estable quedó omitido. [Pages run 98](https://github.com/Montejaque/punto-vuela-linux-toolkit/actions/runs/45353295819) también terminó `success`, pero los logs demuestran que usó el workflow fallback antiguo de capturas best-effort: el artefacto contiene solo las nueve PNG 01–09 y no incluye las imágenes 10–11. Por tanto, run 98 **no** valida el workflow Pages actual ni la captura real Electron; la publicación histórica pudo dejar esas dos referencias de guía sin archivo. En el baseline actual, `publish-guide-pages.yml` captura 01–09 con Chromium/Playwright y 10–11 desde Electron real, valida que existan las 11 PNG y falla si faltan; el fallback es manual y aplica la misma validación, sin placeholders. La publicación principal de Pages se activa por sus paths configurados y mantiene `cancel-in-progress: true`, por lo que conviene agrupar los cambios documentales en un solo commit. El workflow AppImage filtra los pushes de rama por `desktop-electron/**` o su propio archivo: los commits exclusivamente documentales no generan builds ni pre-releases `prueba-N`; los tags `v*` siguen publicando releases estables. No se han comprobado HTTP/DNS del dominio desde el entorno. La implementación no debe considerarse Release estable hasta completar las pruebas manuales anteriores.
