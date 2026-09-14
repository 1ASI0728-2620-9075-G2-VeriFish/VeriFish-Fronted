# Yaku Frontend — Stack Técnico y Guía de Ejecución

## 1. Información General del Proyecto
- **Tipo de Aplicación**: Aplicación Multiplataforma (Web & Android / iOS) para la gestión y monitoreo acuícola en tiempo real.
- **Lenguaje**: Dart 3.x (SDK `^3.10.4`).
- **Framework Core**: Flutter (soporte Web, Android, iOS, Windows, macOS, Linux).

---

## 2. Dependencias y Decisiones Arquitectónicas Clave

| Componente | Librería / Tecnología | Versión | Propósito / Decisión |
|---|---|---|---|
| **Gestión de Estado** | `provider` | ^6.1.2 | Inyección de dependencias y reactividad en la capa de presentación. |
| **Enrutamiento** | `go_router` | ^14.6.2 | Enrutamiento declarativo con guards de autenticación y navegación web/deep-linking. |
| **Cliente HTTP & REST** | `dio` | ^5.7.0 | Cliente HTTP para llamadas a la API con interceptores de autorización JWT y manejo de errores. |
| **Almacenamiento Seguro** | `flutter_secure_storage` | ^9.2.2 | Almacenamiento seguro y cifrado de tokens JWT de sesión (Keystore en Android, Keychain en iOS). |
| **Preferencia Local** | `shared_preferences` | ^2.3.3 | Persistencia liviana de preferencias de usuario y caché de interfaz. |
| **Gráficos y Telemetría** | `fl_chart` | ^0.69.0 | Visualización gráfica e interactiva de series temporales de telemetría (pH, temperatura, turbidez, ICA). |
| **Notificaciones Push** | `firebase_core` & `firebase_messaging` | ^4.10.0 / ^16.3.0 | Notificaciones de alertas críticas acuícolas en segundo plano vía FCM. |
| **Enlaces Externos / Pagos**| `url_launcher` | ^6.3.1 | Apertura de URLs externas y pasarela de suscripción Stripe Checkout en navegador. |
| **Formateo e i18n** | `intl` | ^0.19.0 | Formateo de fechas, números y soporte de internacionalización. |

---

## 3. Servicios Externos Consumidos

1. **Yaku Backend API**: Endpoints RESTful para autenticación, gestión de granjas, estanques, equipos, suscripciones y telemetría.
2. **Firebase Cloud Messaging (FCM)**: Recepción de notificaciones push de incidencias y cambios de estado de estanques.
3. **Stripe Checkout Web**: Redirección para pago seguro de membresías y planes.

---

## 4. Cómo Levantar el Proyecto Localmente

### Prerrequisitos
- Flutter SDK instalado (`flutter --version` >= 3.x).
- Chrome instalado (para target Web) o Android Studio con Emulador (para target Android).

### Comandos de Ejecución

1. **Obtener dependencias:**
   ```bash
   flutter pub get
   ```

2. **Ejecutar en Web (Google Chrome):**
   ```bash
   # Por defecto se conecta a http://localhost:8080/api
   flutter run -d chrome

   # Con backend remoto o staging:
   flutter run -d chrome --dart-define=API_BASE_URL=https://api.tu-dominio.com/api
   ```

3. **Ejecutar en Emulador Android:**
   ```bash
   # Por defecto se conecta a http://10.0.2.2:8080/api (alias localhost de emulador)
   flutter run
   ```

4. **Compilar para Producción:**
   ```bash
   # Build Web:
   flutter build web --release --dart-define=API_BASE_URL=https://api.tu-dominio.com/api

   # Build Android APK:
   flutter build apk --release --dart-define=API_BASE_URL=https://api.tu-dominio.com/api
   ```
