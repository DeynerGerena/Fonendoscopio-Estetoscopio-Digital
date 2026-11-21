# CardioPulmo IA — app Flutter (ESP32-C3 Super Mini, WiFi)

App Flutter para auscultación digital conectada por **WiFi** a una ESP32-C3 con sensores (acústico/IMU/PPG según firmware). Usa WebSocket para recibir audio PCM y telemetría en tiempo real.

## 1. Requisitos
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (canal estable) y Dart >= 3.3
- Android SDK / Android Studio (para compilar APK en Android) o Xcode (iOS)
- Un celular y la ESP32 en la misma red WiFi, **o** el celular conectado al punto de acceso (AP) de la ESP32

## 2. Preparar el proyecto (plataformas Android/iOS)
Este directorio incluye `lib/`, `pubspec.yaml` y este README (código de la app). Para generar las carpetas de plataforma y compilar:

```bash
cd cardiopulmo_app
flutter create --org com.tuuni --project-name cardiopulmo_ia .
# Si flutter create pregunta por sobrescribir, conserva lib/ y pubspec.yaml de este proyecto
flutter pub get
```

> Si ya tienes un proyecto Flutter creado, puedes reemplazar su `lib/` y `pubspec.yaml` por los de esta carpeta y ejecutar `flutter pub get`.

## 3. Permisos y red WiFi (necesario para ws://)
La ESP32 usa WebSocket sin cifrar (`ws://`), así que hay que permitir tráfico en claro hacia la red local.

**Android** — `android/app/src/main/AndroidManifest.xml`:
- antes de `<application>`: `<uses-permission android:name="android.permission.INTERNET"/>`
- en `<application ...>` agrega: `android:usesCleartextTraffic="true"`

**iOS** — `ios/Runner/Info.plist`, dentro de `<dict>`:
```xml
<key>NSAppTransportSecurity</key><dict><key>NSAllowsLocalNetworking</key><true/></dict>
<key>NSLocalNetworkUsageDescription</key><string>Conexión con el fonendoscopio</string>
```

Notas de conexión:
- URL por defecto en la app: `ws://192.168.4.1:81` (modo AP de la ESP32). Cámbiala en **Ajustes** si la ESP32 está en tu WiFi (STA) con otra IP.
- Si te conectas al AP de la ESP32 (sin internet), Android puede cambiar a datos móviles: acepta “mantener conexión” o desactiva datos móviles.
- Verifica que el firewall no bloquee el puerto 81 en la red local.

## 4. Protocolo WiFi esperado (firmware ESP32-C3)
- **WebSocket** en el puerto configurado (ej. `81`).
- **Binario (audio)**: `[0xA2, flags, int16 LE ...]` — PCM crudo a **8 kHz**; `flags` bit0 = movimiento detectado.
- **Texto (telemetría JSON)**, ej.: `{"t":1,"bpm":..,"bv":..,"fing":..,"mot":..,"acc":..,"rssi":..}`.
- **Comandos app → ESP32** (texto), ej.: `MT=0.60` para ajustar umbral de movimiento.

La ESP32 debe decimar 16 kHz → 8 kHz y enviar PCM crudo (filtros finos en la app). Ejemplo de cambios en `fonendoscopio.ino`:
```cpp
#define DECIM     2                 // 16 kHz -> 8 kHz
#define FS_AUDIO  (FS_IN / DECIM)
// en setup():   decim.lowpass(FS_IN, 3500.0f);

struct AudioFrame { int16_t raw[FRAME]; uint8_t flags; };   // quita heart[] y lung[]

// en audioTask(), después de "if (++dcnt < DECIM) continue; dcnt = 0;" deja solo:
fr.raw[idx] = clip16(d * gGainR * 32767.f);          // sin silenciar: la app decide con la bandera
if (++idx == FRAME) { fr.flags = mot ? 1 : 0; if (xQueueSend(frameQ, &fr, 0) != pdTRUE) gDrops++; idx = 0; }

// en loop(), al enviar:
static uint8_t sendBuf[2 + FRAME * 2];
sendBuf[0] = 0xA2; sendBuf[1] = f.flags;
memcpy(sendBuf + 2, f.raw, FRAME * 2);
ws.broadcastBIN(sendBuf, sizeof sendBuf);
```
Ajusta `gGainR` (ganancia previa, ~8) para evitar saturación; la amplificación fina se hace en la app.

## 5. Ejecutar y desplegar (build)

```bash
# Verificar entorno
flutter doctor

# Ejecutar en un dispositivo Android conectado por USB (depuración USB activada)
flutter run

# Generar APK de lanzamiento (Android)
flutter build apk --release
# Salida: build/app/outputs/flutter-apk/app-release.apk

# (Opcional) App Bundle para Play Store
flutter build appbundle --release
```

Para instalar el APK generado: copia `app-release.apk` al celular y ábrelo (permitir instalación desde orígenes desconocidos si aplica), o usa `adb install build/app/outputs/flutter-apk/app-release.apk`.

## 6. Qué hace la app
- **Conexión WiFi/WS**: estado en vivo, reconexión manual, URL configurable.
- **Filtros en la app** (`lib/dsp.dart`, Butterworth orden 4, fs = 8 kHz): cardíacos pasa-bajas ≤ 250 Hz; pulmonares pasa-banda 200–1500 Hz; general pasa-bajas ≤ 3000 Hz. Amplificación por canal (0.5×–30×) y silencio por movimiento (fundido).
- **Grabación**: audio crudo + máscara de movimiento para reprocesar con distintos filtros/ganancias; vista de separación en tiempo real.
- **Pacientes**: registro (nombre/edad/notas), historial con las 2 grabaciones más recientes por paciente.
- **Análisis**: reproducción, forma de onda por canal, ajuste de ganancia, indicador de calidad/saturación, “Descargar todo” (3 canales + crudo, WAV 8 kHz) y “Compartir”.
- **Telemetría**: muestra datos enviados por la ESP32 (p. ej. PPG/bpm, RSSI, movimiento) cuando están disponibles.

## 7. Límites conocidos
- Sin escucha en vivo (solo visualización en tiempo real); la reproducción es sobre grabaciones.
- Sin número de secuencia para pérdida de paquetes (revisar `drop` en telemetría si el firmware lo envía).
- Prototipo experimental, **no es un dispositivo médico** ni sustituye diagnóstico clínico.
