# Política de privacidad de Puntos Vuela Toolkit

**Última actualización: 12 de noviembre de 2026**

## 1. Responsable del tratamiento

El responsable del tratamiento de los datos personales recogidos mediante la función de envío de propuestas de esta aplicación es:

**CONSORCIO PUNTOS VUELA DE ANDALUCÍA (CPV)**  
Avda. del Conocimiento nº 33, Edif. Sede Fundación PTS, Parque Tecnológico de la Salud, 18016 Granada.  
Teléfono: 958 897 289  
Correo electrónico: info.cfr@puntosvuela.es

**Delegado de Protección de Datos (DPD):**  
delegadoprotecciondatos.cfr@puntosvuela.es

La denominación y los datos de contacto se corresponden con la información publicada por el propio Consorcio en su política oficial de protección de datos.

## 2. Aplicación y personas usuarias

Punto Vuela Linux Toolkit es una aplicación de escritorio destinada al uso profesional interno por parte de los **Agentes de Innovación Local (AIL) de los centros de la red Puntos Vuela**. La función de envío permite remitir propuestas de aplicaciones y necesidades de los centros. No es un formulario público dirigido a la ciudadanía ni a empresas.

El mantenimiento técnico de la aplicación y la gestión del buzón receptor **montejaque@puntosvuela.es** los realiza **Francisco Javier Gallego Orellana, AIL del Punto Vuela de Montejaque**. Esta función técnica y operativa se realiza en el marco del uso interno de la herramienta y no altera la identificación del Consorcio como responsable del tratamiento indicada en esta política.

## 3. Datos tratados

Según los campos cumplimentados, una propuesta puede incluir:
- Nombre del centro Puntos Vuela y municipio.
- Nombre y apellidos o identificación profesional de la persona de contacto.
- Teléfono y correo electrónico profesional.
- Nombre de la aplicación propuesta y, en su caso, dirección web y distribución.
- Descripción de la necesidad, utilidad y observaciones.

La herramienta está destinada a comunicaciones profesionales. No deben introducirse contraseñas, documentos de identidad, categorías especiales de datos ni datos personales de terceras personas que no sean necesarios para valorar la propuesta.

## 4. Finalidad y base jurídica

Los datos se utilizan para recibir, revisar, valorar y responder a las propuestas de aplicaciones y necesidades remitidas por los AIL de los centros Puntos Vuela, y para mantener la comunicación profesional relacionada con dichas propuestas.

La base jurídica concreta debe ser la que corresponda al tratamiento incluido en el Registro de Actividades de Tratamiento del Consorcio y a las funciones que tenga atribuidas. La información pública del CPV contempla, según el tratamiento, el cumplimiento de obligaciones legales, el cumplimiento de una misión realizada en interés público y otras bases previstas en el RGPD. El CPV debe confirmar la base aplicable específicamente a este flujo de propuestas.

La casilla de la aplicación acredita que el AIL ha leído la información de privacidad; **no se utiliza como consentimiento para el tratamiento ni sustituye la base jurídica que corresponda al Consorcio**.

## 5. Destinatarios y funcionamiento técnico

Cuando el AIL envía una propuesta, la aplicación transmite su contenido mediante HTTPS a un servicio alojado en **Cloudflare Workers**. Este servicio remite el mensaje mediante **Gmail API** al buzón central **montejaque@puntosvuela.es**, gestionado operativamente por el AIL de Montejaque. La dirección de correo indicada por el AIL se incluye como dirección de respuesta y recibe una copia.

En el funcionamiento técnico intervienen:
- **Cloudflare**, como proveedor de infraestructura para ejecutar el servicio de envío.
- **Google**, mediante Gmail y Gmail API, para el envío y la recepción del correo.

Estos proveedores pueden tratar datos técnicos y de comunicación necesarios para prestar sus servicios, conforme a sus condiciones y a los acuerdos aplicables con el responsable del tratamiento.

La aplicación y el servicio de envío no mantienen una base de datos propia de propuestas ni un sistema de expedientes. El contenido se entrega al buzón central y puede permanecer en los buzones de correo del destinatario y del remitente. El servicio puede utilizar contadores temporales y registros técnicos limitados para seguridad, prevención de abusos y funcionamiento; estos datos no constituyen un archivo de propuestas.

Las credenciales técnicas de Google utilizadas para el envío se guardan como secretos en el entorno de Cloudflare. No se incluyen en la aplicación de escritorio ni se solicitan a los AIL.

## 6. Conservación

La información oficial del CPV indica que los datos se conservan mientras puedan derivarse responsabilidades del tratamiento y durante los plazos establecidos por la normativa de archivo y documentación aplicable. Las propuestas remitidas pueden permanecer en el buzón central y en la copia recibida por el AIL conforme a esos criterios y a las instrucciones de conservación del Consorcio.

Los proveedores tecnológicos pueden conservar registros técnicos o copias de seguridad conforme a sus propios plazos y condiciones. La aplicación no establece un plazo de archivo propio ni elimina automáticamente los correos enviados.

## 7. Derechos de las personas

Las personas cuyos datos personales se incluyan en una propuesta podrán ejercer los derechos que les reconozca la normativa —incluidos acceso, rectificación, supresión, oposición y limitación y, cuando proceda, portabilidad— ante el Consorcio Puntos Vuela de Andalucía.

Para ejercerlos, pueden contactar con el Delegado de Protección de Datos en **delegadoprotecciondatos.cfr@puntosvuela.es** o utilizar los canales indicados en la política oficial del Consorcio: [Privacidad y Protección de Datos del CPV](https://consorciopuntosvuela.es/politica-de-proteccion-de-datos/).

También se puede presentar una reclamación ante la Agencia Española de Protección de Datos: https://www.aepd.es/

## 8. Seguridad

La transmisión entre la aplicación y el servicio se realiza mediante HTTPS. Las credenciales OAuth utilizadas para enviar correo permanecen en el entorno de servidor de Cloudflare y no se distribuyen con la aplicación. El servicio aplica validaciones y controles técnicos de limitación de solicitudes.

Los AIL deben utilizar la herramienta para su finalidad profesional y evitar remitir información excesiva o innecesaria. Ningún sistema conectado a Internet puede garantizar seguridad absoluta.

## 9. Contacto técnico

**Mantenimiento técnico de Punto Vuela Linux Toolkit y gestión operativa del buzón receptor:** Francisco Javier Gallego Orellana, AIL del Punto Vuela de Montejaque.

**Buzón central de propuestas:** montejaque@puntosvuela.es

## 10. Actualizaciones

Esta política podrá actualizarse cuando cambien las funciones de la aplicación, los proveedores o los tratamientos asociados. La fecha de actualización aparecerá al principio del documento.

---

**Nota:** esta política específica debe ser revisada y validada por el Delegado de Protección de Datos del Consorcio Puntos Vuela de Andalucía, especialmente en lo relativo a la base jurídica, la inclusión de este flujo en su Registro de Actividades de Tratamiento y los proveedores que intervienen.
