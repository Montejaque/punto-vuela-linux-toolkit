# Política de privacidad de Punto Vuela Mail

**Última actualización: 12 de noviembre de 2026**

## 1. Qué es Punto Vuela Mail

Punto Vuela Mail es una herramienta de escritorio destinada a los centros de la red Puntos Vuela para remitir propuestas de aplicaciones y solicitudes relacionadas con su actividad. La herramienta está mantenida técnicamente por **Francisco Javier Gallego Orellana, AIL (Agente de Innovación Local) del Punto Vuela de Montejaque**.

La persona que mantiene técnicamente la herramienta no debe confundirse necesariamente con el responsable jurídico del tratamiento de los datos. La identidad y los datos de contacto del responsable del tratamiento deberán ser confirmados por la entidad que determine los fines y medios del tratamiento antes de considerar esta política como versión definitiva.

## 2. Datos que puede incluir una solicitud

El formulario puede transmitir:
- Centro Puntos Vuela y municipio.
- Nombre o identificación de la persona de contacto.
- Teléfono y correo electrónico de contacto.
- Nombre de la aplicación propuesta y, en su caso, dirección web y distribución.
- Descripción de la necesidad, utilidad y observaciones.

Se recomienda incluir únicamente información profesional necesaria. No deben introducirse datos especialmente protegidos, contraseñas, documentos de identidad ni datos personales de terceras personas que no sean necesarios para tramitar la propuesta.

## 3. Finalidad

Los datos se utilizan para recibir, revisar, responder y, cuando corresponda, valorar las propuestas remitidas por los centros Puntos Vuela, así como para mantener la comunicación relacionada con dichas solicitudes.

## 4. Destinatarios y proveedores tecnológicos

La solicitud se transmite a través de un servicio alojado en **Cloudflare Workers** y se envía mediante **Gmail API**, desde la cuenta operativa del servicio, al buzón de recepción configurado: **montejaque@puntosvuela.es**. El correo de contacto indicado en el formulario se incluye como dirección de respuesta y recibe copia del mensaje.

Cloudflare presta infraestructura de ejecución del servicio y Google proporciona el servicio de correo y la API correspondiente. Estos proveedores pueden tratar datos técnicos y de comunicación necesarios para prestar sus servicios, conforme a sus propias condiciones y acuerdos aplicables.

La aplicación no solicita al usuario las credenciales OAuth de Gmail. Las credenciales técnicas de envío se mantienen en los secretos del entorno de Cloudflare y no se distribuyen dentro de la aplicación de escritorio.

## 5. Conservación

Los datos enviados pueden permanecer en los buzones de correo de origen y destino y en los sistemas de respaldo o seguridad de los proveedores durante los plazos aplicables. El plazo concreto de conservación de las solicitudes debe ser establecido por el responsable del tratamiento según su finalidad y obligaciones. No se debe entender que la herramienta ofrece por sí misma un archivo o expediente con un plazo de conservación propio.

## 6. Seguridad

La comunicación con el servicio se realiza mediante HTTPS. El envío se efectúa en el servidor y las credenciales OAuth no se incluyen en el programa de escritorio. Se aplican controles técnicos de validación y limitación de solicitudes, que pueden evolucionar con las versiones del servicio.

Ningún sistema conectado a Internet puede garantizar seguridad absoluta. No se deben enviar datos que no sean necesarios para tramitar la solicitud.

## 7. Derechos de las personas

Las personas interesadas podrán ejercer los derechos que les reconozca la normativa de protección de datos —incluidos, cuando proceda, acceso, rectificación, supresión, oposición, limitación y portabilidad— ante el responsable del tratamiento.

**El canal y la identidad del responsable para el ejercicio de derechos deben completarse antes de la publicación definitiva de esta política.** Como contacto técnico de la herramienta puede utilizarse el canal profesional del Punto Vuela de Montejaque, indicando en el asunto «Privacidad – Punto Vuela Mail»; este contacto técnico no sustituye al responsable jurídico del tratamiento.

También podrá presentarse una reclamación ante la Agencia Española de Protección de Datos (AEPD): https://www.aepd.es/

## 8. Cambios en esta política

Esta política podrá actualizarse cuando cambien las funciones, los proveedores o los tratamientos asociados a Punto Vuela Mail. La fecha de última actualización aparecerá al principio del documento.

## 9. Contacto técnico

**Mantenimiento técnico:** Francisco Javier Gallego Orellana, AIL del Punto Vuela de Montejaque.

**Buzón receptor de solicitudes:** montejaque@puntosvuela.es

---

**Aviso importante:** este texto es un borrador informativo basado en el funcionamiento técnico conocido de la herramienta. No constituye asesoramiento jurídico ni identifica todavía de forma definitiva al responsable del tratamiento. Antes de utilizarlo como URL de verificación OAuth en producción, la entidad responsable debe revisar y completar esos datos, los plazos de conservación y el canal para ejercer derechos.
