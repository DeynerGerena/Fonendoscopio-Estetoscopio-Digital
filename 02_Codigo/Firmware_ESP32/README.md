# Firmware ESP32-C3 para la app CardioPulmo IA

Sketch: `fonendoscopio_wifi/fonendoscopio_wifi.ino`

Este firmware deja la ESP32-C3 Super Mini lista para que la app **CardioPulmo IA** reciba audio y telemetría por WiFi, con el mismo protocolo que ya espera la app.

## 1. Qué hace

- Crea un **punto de acceso WiFi** propio (por defecto):
  - Red: `Fonendo-ESP32`
  - Clave: `fonendo1234`
  - IP: `192.168.4.1` (la URL por defecto de la app: `ws://192.168.4.1:81`)
- Levanta un **servidor WebSocket en el puerto 81**.
- Lee el **INMP441** por I2S a 16 kHz, quita continua, aplica anti-alias a 3.4 kHz, **decima a 8 kHz** y envía PCM int16 al app.
- Lee el **MPU6050** y marca en cada bloque de audio si hay movimiento (bit 0 de `flags`). La app decide silenciar o no.
- Lee el **MAX30102** y envía telemetría JSON (IR, RED, BPM estimado, RSSI).
- Acepta el comando `MT=0.60` que envía la app desde **Ajustes → Umbral de movimiento**.

Formato binario (idéntico al que espera la app):

```
[0xA2, flags, int16 LE, int16 LE, ...]
```

- `flags` bit0 = 1 → movimiento detectado en ese bloque
- 128 muestras por bloque a 8 kHz (16 ms)

Telemetría (texto):

```json
{"t":1,"bpm":72,"bv":1,"fing":1,"mot":0,"acc":0.12,"ir":123456,"red":98765,"rssi":0}
```

## 2. Librerías necesarias (Arduino IDE)

Instala desde **Library Manager**:

1. **WebSockets** — Markus Sattler (Links2004)
2. **Adafruit MPU6050**
3. **Adafruit Unified Sensor**
4. **SparkFun MAX3010x Pulse and Proximity Sensor Library** (busca “MAX30105”)

Para la placa, en **Boards Manager** instala el core **esp32 by Espressif Systems** usando esta URL adicional:

```
https://espressif.github.io/arduino-esp32/package_esp32_index.json
```

## 3. Configuración de la placa

- Placa: **ESP32C3 Dev Module**
- **USB CDC On Boot: Enabled** (para ver el monitor serie por el USB del Super Mini)
- Flash Size: 4 MB
- Partition Scheme: Default

## 4. Conexiones (las mismas que ya usas)

| Señal | ESP32-C3 |
|---|---|
| INMP441 SCK | GPIO 4 |
| INMP441 WS | GPIO 5 |
| INMP441 SD | GPIO 6 |
| INMP441 L/R | GND |
| INMP441 VDD | 3.3 V |
| MPU6050 SDA | GPIO 8 |
| MPU6050 SCL | GPIO 9 |
| MPU6050 VCC | 3.3 V |
| MAX30102 SDA | GPIO 8 |
| MAX30102 SCL | GPIO 9 |
| MAX30102 VIN | 3.3 V |

> MPU6050 (0x68) y MAX30102 (0x57) comparten el mismo bus I2C.

## 5. Uso con la app

1. Sube el sketch a la ESP32.
2. Abre el **Monitor Serie** a 115200 baudios. Debe aparecer la IP (`192.168.4.1` en modo AP).
3. En el celular, conéctate a la red **Fonendo-ESP32** (clave `fonendo1234`).
   - Si Android avisa que “esta red no tiene Internet”, elige **Mantener conexión**.
4. Abre la app **CardioPulmo IA**. Debe pasar a **“En vivo”**.
5. En **Ajustes** puedes cambiar la URL si usas modo STA (`ws://IP:81`) y ajustar el **umbral de movimiento** (la app envía `MT=...` a la ESP32).

## 6. Modo STA (opcional)

Si prefieres que la ESP32 se conecte a tu WiFi en lugar de crear su propia red, edita al inicio del sketch:

```cpp
static const char *STA_SSID = "TU_WIFI";
static const char *STA_PASS = "TU_CLAVE";
```

Si no logra conectarse en 12 segundos, cae automáticamente al modo AP. En modo STA, mira la IP en el Monitor Serie y escríbela en **Ajustes** de la app.

## 7. Ajustes útiles del sketch

- `MIC_GAIN` (por defecto `6.0f`): súbelo si la señal se ve muy baja en la app, bájalo si aparece saturada.
- `DEFAULT_MT` (`0.60f`): umbral inicial de movimiento en m/s².
- `AP_SSID` / `AP_PASS`: nombre y clave del punto de acceso.

## 8. Compilación ya verificada

El sketch **compila sin errores ni advertencias** con:

- Core ESP32 **3.0.4** (`esp32 by Espressif`)
- Placa `esp32:esp32:esp32c3` (ESP32C3 Dev Module)
- Ocupa 995 250 bytes (75 %) de flash y 38 348 bytes (11 %) de RAM

Los binarios ya generados están en `firmware_esp32/build/`:

| Archivo | Uso |
|---|---|
| `fonendoscopio_wifi.ino.merged.bin` | Flasheo en un solo paso desde la dirección `0x0` |
| `fonendoscopio_wifi.ino.bin` | Solo la app (junto con bootloader y partitions) |
| `fonendoscopio_wifi.ino.bootloader.bin` | Bootloader (`0x0`) |
| `fonendoscopio_wifi.ino.partitions.bin` | Tabla de particiones (`0x8000`) |

Si prefieres no usar el IDE, con `esptool` (ya viene con el core ESP32 en
`%LOCALAPPDATA%\Arduino15\packages\esp32\tools\esptool_py\4.6\esptool.exe`):

```powershell
& "$env:LOCALAPPDATA\Arduino15\packages\esp32\tools\esptool_py\4.6\esptool.exe" `
  --chip esp32c3 -p COM5 -b 460800 write_flash 0x0 fonendoscopio_wifi.ino.merged.bin
```

(cambia `COM5` por el puerto real de la placa). También puedes simplemente abrir
el sketch en Arduino IDE y pulsar **Subir**; es lo recomendado si ya lo tienes abierto.

## 9. Notas

- La ESP32 **no silencia** el audio cuando hay movimiento: solo lo marca, porque así lo espera la app (ella aplica el fundido usando la bandera).
- La app hace los filtros cardíaco/pulmonar/general y la amplificación fina; la ESP32 solo entrega PCM crudo a 8 kHz.
- El BPM del MAX30102 es una estimación por picos; si no hay dedo o la señal es débil, se envía `bv:0` y la app muestra `--`.
- Prototipo experimental: **no es un dispositivo médico**.
