# Prueba controlada del actualizador de Puntos Vuela Toolkit

Este modo permite probar el actualizador real sin interferir con el canal estable.

## Canal normal y canal de prueba

- Canal normal: solo releases estables con tags `vMAJOR.MINOR.PATCH`.
- Canal de prueba: solo releases marcadas como prerelease, con tags semver como `v0.4.3-test.1`.
- El canal de prueba se activa pasando `--updater-test` a la AppImage.
- Ambos canales requieren la AppImage de arquitectura adecuada y el fichero `SHA256SUMS`.
- El modo de prueba realiza una actualización real del fichero AppImage; úsalo en una copia de prueba, no sobre tu instalación principal.

## Preparar una release de prueba en GitHub

1. Compila una AppImage de prueba cuyo `package.json` tenga una versión mayor que la instalada (por ejemplo, 0.4.3).
2. En GitHub Releases, crea una release con tag `v0.4.3-test.1` y marca **Pre-release**.
3. Adjunta la AppImage con nombre `Puntos_Vuela_Toolkit-Electron-x86_64.AppImage` y un `SHA256SUMS` que incluya la suma del archivo, usando el formato habitual de sha256sum: `HASH  NOMBRE`.
4. No publiques ni edites releases estables para esta prueba.

## Ejecutar el canal de prueba

En una AppImage de prueba, abre una terminal en la carpeta del archivo y ejecuta:

```bash
./Puntos_Vuela_Toolkit-Electron-x86_64.AppImage --updater-test
```

Si hay una prerelease superior compatible con la versión instalada y tiene AppImage + SHA256SUMS, debe mostrar el modal **ACTUALIZADOR · MODO DE PRUEBAS**. Puedes cancelar con «Más tarde» o iniciar la actualización real.

## Casos de prueba

- Cancelar desde el modal: no debe cambiar el AppImage instalado.
- Descarga y SHA-256 correctos: debe preparar la sustitución y ofrecer reinicio.
- SHA256 incorrecto o ausente: debe abortar y conservar la versión instalada.
- Descarga fallida: debe abortar y conservar la versión instalada.
- Reiniciar tras actualizar: comprobar que la nueva versión abre.
- Recuperación: si el siguiente arranque no llega al punto de inicio confirmado, el watchdog intenta restaurar la copia de respaldo.

## Seguridad

El modo de pruebas no es un simulador: permite ejecutar la ruta real de actualización, incluida la sustitución del fichero AppImage. Haz la prueba con una copia separada. No uses una prerelease que no hayas preparado y revisado.
