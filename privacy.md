# Política de privacidad de Punto Vuela Mail

**Última actualización: 12 de noviembre de 2026**

## 1. Identidad y ámbito de la herramienta

Punto Vuela Mail es una herramienta de escritorio de uso interno, destinada exclusivamente a los **Agentes de Innovación Local (AIL) de los centros de la red Puntos Vuela**. No es un formulario público dirigido a la ciudadanía ni a empresas.

El mantenimiento técnico de la herramienta lo realiza **Francisco Javier Gallego Orellana, AIL del Punto Vuela de Montejaque**. Asimismo, gestiona el buzón central **montejaque@puntosvuela.es**, que recibe las propuestas remitidas por los AIL.

La función de mantenimiento técnico y gestión del buzón no determina por sí sola quién es el responsable jurídico del tratamiento. La entidad que determine los fines y medios del tratamiento debe confirmar su identidad y los datos de contacto antes de que esta política se considere definitiva.

## 2. Datos tratados

Según los campos cumplimentados, una propuesta puede incluir:
- Nombre del centro Puntos Vuela y municipio.
- Nombre o identificación profesional de la persona de contacto.
- Teléfono y correo electrónico profesional.
- Nombre de la aplicación propuesta y, cuando proceda, dirección web y distribución.
- Descripción de la necesidad, utilidad y observaciones.

La herramienta está destinada a comunicaciones profesionales. No deben introducirse contraseñas, documentos de identidad, datos especialmente protegidos ni datos personales de terceras personas que no sean necesarios para valorar la propuesta.

## 3. Finalidad

Los datos se utilizan para recibir, revisar, valorar y responder a las propuestas de aplicaciones y necesidades remitidas por los AIL de los centros Puntos Vuela, y para mantener la comunicación profesional relacionada con ellas.

## 4. Destinatarios y funcionamiento técnico

Al enviar una propuesta, la aplicación transmite el contenido mediante HTTPS a un servicio alojado en **Cloudflare Workers**. Este servicio remite el mensaje mediante **Gmail API** al buzón central **montejaque@puntosvuela.es**, gestionado por Francisco Javier Gallego Orellana. La dirección de correo indicada por el AIL se incorpora como dirección de respuesta y recibe una copia.

Intervienen, por tanto, proveedores tecnológicos:
- **Cloudflare**, que proporciona la infraestructura para ejecutar el servicio de envío.
- **Google**, que proporciona Gmail y Gmail API para la entrega y gestión del correo.

Estos proveedores pueden tratar datos técnicos y de comunicación necesarios para prestar sus servicios, conforme a sus condiciones y acuerdos aplicables.

La herramienta no dispone de una base de datos propia ni de un sistema de expedientes para almacenar el contenido de las propuestas. El contenido se entrega al buzón central y puede permanecer en los buzones de correo correspondientes. El servicio puede conservar datos técnicos limitados para controles operativos y de uso, como contadores temporales de solicitudes; estos datos no constituyen un archivo de propuestas.

Las credenciales técnicas de Google utilizadas para el envío se guardan como secretos del entorno de Cloudflare y no se incluyen en la aplicación de escritorio ni se solicitan a los AIL.

## 5. Conservación

Las propuestas se conservan en el buzón central y en las copias que puedan existir en el buzón del remitente, de acuerdo con los criterios y plazos que establezca el responsable del tratamiento y con las obligaciones aplicables. Los proveedores tecnológicos pueden mantener registros técnicos o copias de seguridad durante los plazos previstos en sus servicios.

El plazo concreto de conservación debe ser fijado y documentado por el responsable del tratamiento. La herramienta no establece por sí misma un plazo de archivo ni un procedimiento de eliminación del correo.

## 6. Seguridad

La transmisión entre la aplicación y el servicio se realiza mediante HTTPS. Las credenciales OAuth de envío permanecen en el entorno de servidor de Cloudflare y no se distribuyen con la aplicación. El servicio incorpora validaciones y controles de limitación de solicitudes, que pueden evolucionar.

Ningún sistema conectado a Internet puede garantizar seguridad absoluta. Los AIL deben utilizar la herramienta para su finalidad profesional y evitar remitir información excesiva o innecesaria.

## 7. Derechos de las personas

Las personas cuyos datos personales se incluyan en una propuesta podrán ejercer los derechos que reconozca la normativa de protección de datos —como acceso, rectificación, supresión, oposición, limitación y, cuando proceda, portabilidad— ante el responsable del tratamiento.

**Pendiente de completar antes de la publicación definitiva:** la entidad responsable debe facilitar su denominación oficial, dirección o canal de contacto para el ejercicio de derechos, y confirmar el procedimiento aplicable. El contacto técnico de la herramienta no sustituye al responsable jurídico del tratamiento.

También puede presentarse una reclamación ante la Agencia Española de Protección de Datos: https://www.aepd.es/

## 8. Contacto técnico

**Mantenimiento técnico y gestión del buzón receptor:** Francisco Javier Gallego Orellana, AIL del Punto Vuela de Montejaque.

**Buzón central de propuestas:** montejaque@puntosvuela.es

## 9. Actualizaciones

Esta política podrá actualizarse cuando cambien las funciones, los proveedores o los tratamientos asociados a Punto Vuela Mail. La fecha de actualización aparecerá al principio del documento.

---

**Estado del documento:** borrador pendiente de validación por la entidad que sea responsable del tratamiento. Antes de utilizarlo como política definitiva para la publicación OAuth, deben completarse y verificarse la identidad del responsable, la base jurídica, los plazos de conservación y el canal para ejercer derechos.
