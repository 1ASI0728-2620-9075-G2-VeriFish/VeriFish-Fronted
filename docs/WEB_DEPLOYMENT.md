# Flutter Web — TB2

Validado con Flutter 3.47.9 / Dart 3.13.7. No se actualizaron dependencias directas; el lockfile refleja las dependencias fijadas por este SDK. Backend y contrato JWT permanecen sin cambios.

## Validación local

```sh
flutter pub get
flutter test
flutter analyze
flutter build web --debug --no-wasm-dry-run --dart-define=API_BASE_URL=https://yaku-backend-hjbmb2btfzece4c0.brazilsouth-01.azurewebsites.net/api
python3 -m http.server 3000 --directory build/web
```

La URL base debe terminar en `/api`, porque las rutas del cliente comienzan en `/v1`. Usar `http://localhost:3000` para coincidir con el CORS del backend. La aplicación usa rutas con hash. Firebase también configura una reescritura SPA para rutas directas.

Las pruebas `test/web/admin_flows_test.dart` simulan respuestas para comprobar validación, 403, 409, recuperación tras fallos y cierre de sesión ante 401. Estos resultados verifican el frontend, no el aislamiento del backend.

Para el smoke test real de navegador, instalar Playwright Python y Chromium. Proporcionar un archivo privado mediante `VERIFISH_TEST_ACCOUNTS` (lista JSON de cuentas ADMIN de prueba con `username` y `password`). No incluirlo en Git. Ejecutar `python3 test/web/e2e_admin.py`; opcionalmente configurar `VERIFISH_EVIDENCE_DIR` y `PLAYWRIGHT_CHROMIUM_EXECUTABLE`. El test crea recursos TB2 y no ejecuta aireadores.

## Publicar en Firebase Hosting

```sh
firebase login:add bendezuni@gmail.com
firebase use yakucontrol-v2
flutter build web --release --no-wasm-dry-run --dart-define=API_BASE_URL=https://yaku-backend-hjbmb2btfzece4c0.brazilsouth-01.azurewebsites.net/api
firebase deploy --only hosting --project yakucontrol-v2
```

La compilación release está autorizada solo para publicar la Web. `firebase.json` conserva FlutterFire y publica `build/web`; `.firebaserc` apunta a `yakucontrol-v2`. No desplegar otros servicios ni proyectos. Revisar https://yakucontrol-v2.web.app después de publicar.

Cerrar sesión y volver a ingresar al desplegar el cambio de aislamiento. Tras crear una granja se cierra la sesión para obtener un JWT con `farmId` en el siguiente login. Un 403 conserva la sesión y explica el problema de permisos; un 401 limpia únicamente las preferencias de sesión y devuelve al login. Usuarios sin granja y usuarios de otras granjas requieren pruebas contra Azure con cuentas dedicadas.

## Estado al 30/10/2026

Web publicada en https://yakucontrol-v2.web.app, versión Hosting `b27c1e8c2210d609`. Azure todavía rechaza CORS desde los dominios Firebase; el login publicado depende de corregir esos orígenes.
