# Servicio de correo con Cloudflare Workers

Este servicio recibe solicitudes del Punto Vuela Linux Toolkit y las envía mediante Gmail API. No se incluye ninguna contraseña, token OAuth ni secreto en la AppImage o en el repositorio.

## Componentes

- Cloudflare Worker con HTTPS.
- Gmail API con OAuth 2.0 (refresh token almacenado como secreto del Worker).
- Cloudflare KV para limitar a cinco solicitudes por IP y hora.
- Destinatario fijo: `montejaque@puntosvuela.es`.
- Remitente fijo: `puntovuelamontejaque@gmail.com`.
- Copia (Cc) y Reply-To a la dirección facilitada en el formulario.

## Despliegue inicial

Requiere una cuenta Cloudflare y Node.js en un equipo administrador.

1. En Cloudflare, crea un namespace KV llamado `PV_MAIL_RATE_LIMIT`.
2. Copia su ID y sustituye `REPLACE_WITH_KV_NAMESPACE_ID` en `wrangler.toml`.
3. En Google Cloud Console crea un proyecto, habilita **Gmail API** y configura la pantalla de consentimiento OAuth.
4. Crea un cliente OAuth de tipo aplicación de escritorio y autoriza la cuenta remitente con el alcance `https://www.googleapis.com/auth/gmail.send`. Obtén un refresh token mediante el flujo OAuth de usuario. No publiques ni compartas ese token.
5. Abre una terminal en la carpeta `services/cloudflare-mail` del repositorio. Ejecuta `npm install` para instalar Wrangler y después `npx wrangler login` para autorizar el acceso a tu cuenta Cloudflare. Si ya habías iniciado sesión, no hace falta repetir el login.
6. Guarda los tres secretos directamente en Cloudflare:
   - `npx wrangler secret put GOOGLE_CLIENT_ID`
   - `npx wrangler secret put GOOGLE_CLIENT_SECRET`
   - `npx wrangler secret put GOOGLE_REFRESH_TOKEN`
7. Comprueba que `wrangler.toml` contiene el ID real del namespace KV en `[[kv_namespaces]]` y que los tres secretos están configurados. Puedes comprobar los nombres de secretos con `npx wrangler secret list` (no muestra sus valores). Ejecuta `npx wrangler deploy` desde `services/cloudflare-mail`. Este comando publica el código del Worker en Cloudflare; no muestra ni modifica el contenido de los secretos. Cloudflare asignará o mantendrá la URL HTTPS `https://punto-vuela-mail.<subdominio>.workers.dev`.
8. Configura esa URL en `src/punto_vuela_toolkit/email_sender.py` (constante `WORKER_URL`) y publica una nueva AppImage.

## Actualizar el Worker después de modificar el código

En Linux, con Node.js instalado y acceso al repositorio:

```bash
cd /ruta/donde/clonaste/punto-vuela-linux-toolkit/services/cloudflare-mail
npm install
npx wrangler login
npx wrangler secret list
npx wrangler deploy
```

- Sustituye la ruta del primer comando por la ubicación real de tu copia local del repositorio.
- `npm install` instala Wrangler según `package.json` y `package-lock.json`.
- `npx wrangler login` abre el navegador para autorizar Wrangler en Cloudflare; normalmente solo se hace una vez.
- `npx wrangler secret list` comprueba que existen los nombres de secretos OAuth. No revela sus valores.
- `npx wrangler deploy` publica el Worker definido en `wrangler.toml`, incluido el enlace KV `RATE_LIMIT`.
- Si los secretos ya están configurados en ese Worker, se conservan al desplegar una nueva versión. No vuelvas a introducirlos salvo que falten o haya que rotarlos.

Al terminar, Wrangler debe mostrar el nombre del Worker y su URL. Haz una prueba real de envío y otra de límite: tras cinco solicitudes desde la misma IP dentro de una hora, las siguientes deben recibir HTTP 429. No hagas estas pruebas con datos personales reales.

## Evitar la caducidad de 7 días del refresh token

La caducidad de siete días no se corrige renovando el token desde el Worker: la impone Google cuando el proyecto OAuth es de tipo **External** y su estado de publicación es **Testing** y solicita permisos Gmail.

Para el servicio de correo de producción:

1. Abre Google Cloud Console y selecciona el proyecto OAuth que contiene el cliente usado por el Worker.
2. En **Google Auth Platform → Audience** (o **OAuth consent screen**, según la interfaz), comprueba que el tipo de usuario es **External**.
3. Cambia **Publishing status** de **Testing** a **In production** mediante **Publish app**.
4. Comprueba que la aplicación, su página de inicio, política de privacidad, datos de contacto y los dominios autorizados están correctamente declarados.
5. En **Data Access**, declara únicamente el alcance necesario: `https://www.googleapis.com/auth/gmail.send`.
6. Revisa el **Verification Center**. Google puede exigir verificación para el alcance sensible antes de retirar las advertencias y permitir un uso público sin límites de usuarios.
7. Una vez publicado, vuelve a autorizar la cuenta remitente con acceso sin conexión (`access_type=offline`) y genera un refresh token nuevo si el actual se emitió mientras el proyecto estaba en Testing. Actualiza `GOOGLE_REFRESH_TOKEN` como secreto del Worker; nunca lo incluyas en el repositorio.

**Importante:** publicar la aplicación en producción elimina la caducidad automática de siete días asociada al modo Testing, pero no convierte el token en permanente. Google puede revocarlo por seguridad, inactividad prolongada, cambios de contraseña en ciertos casos o límites de tokens. El Worker debe tratar los errores de autorización y requerir una nueva autorización cuando corresponda.

No se debe sustituir Gmail OAuth por una cuenta de servicio para una cuenta Gmail personal: las cuentas de servicio no pueden enviar como un buzón Gmail personal sin un entorno Google Workspace compatible con delegación de dominio.

## Seguridad y límites

- Nunca introducir credenciales OAuth en la aplicación de escritorio ni en GitHub.
- No usar una contraseña de aplicación Gmail compartida.
- El Worker valida campos, tamaño y correo; exige las tres confirmaciones legales; incluye honeypot (campo trampa invisible) y límite de cinco solicitudes por IP y hora mediante el namespace KV `RATE_LIMIT` configurado en `wrangler.toml`. El límite es una barrera básica, no una autenticación fuerte.
- El endpoint es público porque una AppImage distribuida no puede ocultar un secreto compartido. El límite KV reduce abuso, pero no equivale a autenticación fuerte. Si el servicio recibe abuso, añadir Turnstile u otro mecanismo de verificación antes de mantener el envío público.
- Revisa las cuotas y políticas de Gmail/Google Cloud antes de ponerlo en producción.
- Los logs no deben registrar contenido de solicitudes ni tokens.
