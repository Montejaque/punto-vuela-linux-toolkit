# Changelog — Puntos Vuela Toolkit

Todos los cambios relevantes de cada versión se documentan aquí.

## Próxima versión — en desarrollo

### Actualizador automático
- Modal de actualización con opción **Actualizar ahora** y **Más tarde**.
- Banner persistente mientras exista una actualización pendiente; al abrir el modal desde el banner, el banner se oculta.
- Si se cierra el modal o se elige **Más tarde**, vuelve a mostrarse el banner para no perder la actualización pendiente.
- El banner no descarta la actualización: su control de cierre vuelve a abrir el modal.
- Descarga de AppImage con verificación de SHA-256.
- Copia de seguridad de la AppImage instalada antes de reemplazarla.
- Ventana propia que confirma descarga y verificación, con acciones para reiniciar ahora o más tarde.
- Inicio de la AppImage actualizada y mecanismo de recuperación si el inicio no se confirma.

### Interfaz y documentación
- Modal de actualización compacto y sin scroll, con botones visibles.
- Guía visual y guía de ayuda documentan el actualizador y su proceso de recuperación.
- El modal muestra las notas de la release cuando GitHub proporciona el cuerpo de la publicación.
