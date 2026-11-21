/*
 * ============================================================================
 *  FONENDOSCOPIO DIGITAL WiFi — ESP32-C3 Super Mini
 *  Firmware compatible con la app Flutter "CardioPulmo IA"
 * ----------------------------------------------------------------------------
 *  Protocolo (WebSocket, puerto 81):
 *
 *   ESP32 -> app
 *     - Binario: [0xA2, flags, int16 LE ...]
 *         PCM crudo a 8 kHz. flags bit0 = 1 si hay movimiento.
 *         (NO se silencia el audio en la ESP32: la app aplica el silencio
 *          usando la bandera y su propio filtro/ganancia).
 *     - Texto: telemetría JSON
 *         {"t":1,"bpm":..,"bv":..,"fing":..,"mot":..,"acc":..,
 *          "ir":..,"red":..,"rssi":..}
 *
 *   app -> ESP32
 *     - Texto: "MT=0.60"  -> ajusta el umbral de movimiento (m/s^2)
 *
 *  Cadena de audio:
 *     INMP441 16 kHz -> quita DC (HP 15 Hz) -> anti-alias (LP 3.4 kHz)
 *     -> decimación x2 -> PCM int16 8 kHz -> WebSocket
 *     La app hace los filtros cardíaco (<=250 Hz), pulmonar (200-1500 Hz)
 *     y general (<=3000 Hz), además de la amplificación fina.
 *
 *  Placa: "ESP32C3 Dev Module"  (USB CDC On Boot: Enabled)
 * ============================================================================
 */

#include <Arduino.h>
#include <WiFi.h>
#include <WebSocketsServer.h>
#include <Wire.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <MAX30105.h>
#include <driver/i2s.h>
#include <math.h>

// ============================== RED ========================================
#define WS_PORT 81

// Si STA_SSID está vacío, la ESP32 crea su propio punto de acceso (recomendado).
// Si lo llenas, intenta conectarse a esa red y, si falla, cae al modo AP.
static const char *STA_SSID = "";
static const char *STA_PASS = "";

static const char *AP_SSID = "Fonendo-ESP32";
static const char *AP_PASS = "fonendo1234";  // >= 8 caracteres; "" = red abierta

// ============================== PINES ======================================
#define I2S_WS   5
#define I2S_SD   6
#define I2S_SCK  4
#define I2S_PORT I2S_NUM_0

#define I2C_SDA  8
#define I2C_SCL  9

// ============================== AUDIO ======================================
#define FS_IN          16000
#define DECIM          2
#define FS_OUT         (FS_IN / DECIM)   // 8000 Hz
#define FRAME_SAMPLES  128               // 16 ms a 8 kHz
#define MIC_GAIN       6.0f              // ajusta si la señal queda muy baja/fuerte
#define HP_HZ          15.0f             // quita continua / deriva
#define LP_HZ          3400.0f           // anti-alias antes de decimar

// ============================== SENSORES ===================================
#define DEFAULT_MT     0.60f             // umbral de movimiento por defecto (m/s^2)
#define FINGER_IR_MIN  50000UL           // IR mínimo para considerar dedo presente

// ============================== GLOBALES ===================================
Adafruit_MPU6050 mpu;
MAX30105 particleSensor;
WebSocketsServer webSocket(WS_PORT);

bool mpu_ok = false;
bool max_ok = false;

// ---- filtros (solo los usa la tarea de audio) ----
struct Biquad {
  float b0 = 1, b1 = 0, b2 = 0, a1 = 0, a2 = 0;
  float z1 = 0, z2 = 0;

  void designLP(float fs, float fc, float q) { design(true, fs, fc, q); }
  void designHP(float fs, float fc, float q) { design(false, fs, fc, q); }

  void design(bool lowpass, float fs, float fc, float q) {
    const float w  = 2.0f * (float)PI * fc / fs;
    const float c  = cosf(w);
    const float al = sinf(w) / (2.0f * q);
    const float a0 = 1.0f + al;
    b0 = (lowpass ? (1.0f - c) : (1.0f + c)) / 2.0f / a0;
    b1 = (lowpass ? (1.0f - c) : -(1.0f + c)) / a0;
    b2 = b0;
    a1 = -2.0f * c / a0;
    a2 = (1.0f - al) / a0;
  }

  inline float process(float x) {
    const float y = b0 * x + z1;
    z1 = b1 * x - a1 * y + z2;
    z2 = b2 * x - a2 * y;
    return y;
  }
};

Biquad hpF, lpF1, lpF2;

// ---- audio ----
struct AudioFrame {
  uint16_t len;
  uint8_t flags;
  int16_t pcm[FRAME_SAMPLES];
};

QueueHandle_t audioQ = nullptr;
volatile uint32_t audioDrops = 0;

// ---- movimiento ----
volatile bool motionFlag = false;
volatile float motionThreshold = DEFAULT_MT;
float accDev = 0.0f;

// ---- PPG ----
uint32_t ppgIr = 0, ppgRed = 0;
bool finger = false;
bool ppgPrimed = false;
float ppgDc = 0.0f;
float acMax = 100.0f;
bool ppgAbove = false;
uint32_t lastBeatMs = 0;
float beatIntervals[5] = {0, 0, 0, 0, 0};
int beatIdx = 0, beatCount = 0;
int bpm = 0;

// ---- tiempos ----
uint32_t lastMotionMs = 0, lastPpgMs = 0, lastTelemetryMs = 0, lastDebugMs = 0;

// ---- buffer de envío (solo lo usa loop()) ----
uint8_t txBuf[2 + FRAME_SAMPLES * 2];

// ============================== PROTOTIPOS =================================
void setupWiFi();
void setupI2S();
void setupSensors();
void audioTask(void *arg);
void updateMotion();
void updatePpg();
void sendTelemetry();
void onWsEvent(uint8_t num, WStype_t type, uint8_t *payload, size_t length);

// ============================== SETUP ======================================
void setup() {
  Serial.begin(115200);
  delay(800);

  Serial.println();
  Serial.println("==============================================");
  Serial.println(" Fonendoscopio digital WiFi - ESP32-C3");
  Serial.println("==============================================");

  Wire.begin(I2C_SDA, I2C_SCL);
  Wire.setClock(100000);  // 100 kHz: estable para MPU6050 + MAX30102
  Wire.setTimeOut(50);

  setupSensors();

  // Filtros de la cadena de audio (fs = 16 kHz)
  hpF.designHP((float)FS_IN, HP_HZ, 0.70710678f);   // 2do orden
  lpF1.designLP((float)FS_IN, LP_HZ, 0.54119610f);  // 4to orden
  lpF2.designLP((float)FS_IN, LP_HZ, 1.30656296f);

  setupWiFi();

  webSocket.begin();
  webSocket.onEvent(onWsEvent);

  setupI2S();

  audioQ = xQueueCreate(24, sizeof(AudioFrame));  // ~380 ms de respaldo
  if (audioQ == nullptr) {
    Serial.println("ERROR: no se pudo crear la cola de audio");
  } else {
    xTaskCreate(audioTask, "audio", 6144, nullptr, 12, nullptr);
  }

  Serial.printf("WebSocket listo en el puerto %d\n", WS_PORT);
  Serial.println("Esperando conexión de la app...");
}

// ============================== LOOP =======================================
void loop() {
  webSocket.loop();

  // Envía a la app los bloques de audio ya decimados
  AudioFrame f;
  while (audioQ != nullptr && xQueueReceive(audioQ, &f, 0) == pdTRUE) {
    if (webSocket.connectedClients() > 0) {
      txBuf[0] = 0xA2;
      txBuf[1] = f.flags;
      memcpy(txBuf + 2, f.pcm, (size_t)f.len * 2);
      webSocket.broadcastBIN(txBuf, 2 + (size_t)f.len * 2);
    }
  }

  const uint32_t now = millis();

  if (now - lastMotionMs >= 20) {  // 50 Hz
    lastMotionMs = now;
    updateMotion();
  }

  if (now - lastPpgMs >= 20) {     // 50 Hz
    lastPpgMs = now;
    updatePpg();
  }

  if (now - lastTelemetryMs >= 500) {
    lastTelemetryMs = now;
    sendTelemetry();
  }

  if (now - lastDebugMs >= 2000) {
    lastDebugMs = now;
    Serial.printf("WS:%u | bpm:%d | mot:%d (%.2f) | IR:%lu | drops:%lu\n",
                  (unsigned)webSocket.connectedClients(), bpm,
                  motionFlag ? 1 : 0, accDev,
                  (unsigned long)ppgIr, (unsigned long)audioDrops);
  }

  delay(1);
}

// ============================== WIFI =======================================
void setupWiFi() {
  WiFi.persistent(false);
  WiFi.setSleep(false);

  if (strlen(STA_SSID) > 0) {
    Serial.printf("Conectando a WiFi \"%s\"...\n", STA_SSID);
    WiFi.mode(WIFI_STA);
    WiFi.begin(STA_SSID, STA_PASS);

    const uint32_t t0 = millis();
    while (WiFi.status() != WL_CONNECTED && (millis() - t0) < 12000) {
      delay(250);
      Serial.print('.');
    }
    Serial.println();

    if (WiFi.status() == WL_CONNECTED) {
      Serial.print("WiFi OK. IP: ");
      Serial.println(WiFi.localIP());
      Serial.println("Usa esa IP en Ajustes de la app (ws://IP:81)");
      return;
    }
    Serial.println("No se pudo conectar. Se usará modo AP.");
  }

  WiFi.mode(WIFI_AP);
  const bool ok = (strlen(AP_PASS) >= 8)
                      ? WiFi.softAP(AP_SSID, AP_PASS)
                      : WiFi.softAP(AP_SSID);
  if (ok) {
    Serial.printf("AP creado: %s  (clave: %s)\n", AP_SSID,
                  strlen(AP_PASS) >= 8 ? AP_PASS : "(abierta)");
    Serial.print("IP del AP: ");
    Serial.println(WiFi.softAPIP());
    Serial.println("Conecta el celular a esta red y abre la app.");
  } else {
    Serial.println("ERROR: no se pudo crear el punto de acceso");
  }
}

// ============================== SENSORES ===================================
void setupSensors() {
  if (mpu.begin(0x68, &Wire)) {
    mpu_ok = true;
  } else if (mpu.begin(0x69, &Wire)) {
    mpu_ok = true;
  }

  if (mpu_ok) {
    mpu.setAccelerometerRange(MPU6050_RANGE_4_G);
    mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);
    Serial.println("MPU6050 OK");
  } else {
    Serial.println("AVISO: MPU6050 no detectado (sin bandera de movimiento)");
  }

  if (particleSensor.begin(Wire, I2C_SPEED_STANDARD)) {
    max_ok = true;
    particleSensor.setup();  // 100 Hz, 18 bits, promedio 4
    Serial.println("MAX30102 OK");
  } else {
    Serial.println("AVISO: MAX30102 no detectado (sin telemetría PPG)");
  }
}

// ============================== I2S ========================================
void setupI2S() {
  i2s_config_t cfg;
  memset(&cfg, 0, sizeof(cfg));
  cfg.mode = (i2s_mode_t)(I2S_MODE_MASTER | I2S_MODE_RX);
  cfg.sample_rate = FS_IN;
  cfg.bits_per_sample = I2S_BITS_PER_SAMPLE_32BIT;
  cfg.channel_format = I2S_CHANNEL_FMT_ONLY_LEFT;
  cfg.communication_format = I2S_COMM_FORMAT_STAND_I2S;
  cfg.intr_alloc_flags = ESP_INTR_FLAG_LEVEL1;
  cfg.dma_desc_num = 6;
  cfg.dma_frame_num = 256;
  cfg.use_apll = false;
  cfg.tx_desc_auto_clear = false;
  cfg.fixed_mclk = 0;
  cfg.mclk_multiple = I2S_MCLK_MULTIPLE_256;

  i2s_pin_config_t pins;
  memset(&pins, 0, sizeof(pins));
  pins.mck_io_num = I2S_PIN_NO_CHANGE;
  pins.bck_io_num = I2S_SCK;
  pins.ws_io_num = I2S_WS;
  pins.data_out_num = I2S_PIN_NO_CHANGE;
  pins.data_in_num = I2S_SD;

  const esp_err_t e1 = i2s_driver_install(I2S_PORT, &cfg, 0, nullptr);
  const esp_err_t e2 = i2s_set_pin(I2S_PORT, &pins);
  if (e1 != ESP_OK || e2 != ESP_OK) {
    Serial.printf("ERROR I2S: install=%d pin=%d\n", (int)e1, (int)e2);
  } else {
    Serial.println("I2S del INMP441 OK");
  }
}

// ============================== TAREA DE AUDIO =============================
// Lee 256 muestras a 16 kHz (16 ms), filtra, decima x2 y deja 128 muestras
// a 8 kHz en la cola. NO silencia por movimiento: solo pone la bandera.
void audioTask(void *arg) {
  (void)arg;
  static int32_t raw[256];

  while (true) {
    size_t bytes = 0;
    const esp_err_t err = i2s_read(I2S_PORT, raw, sizeof(raw), &bytes,
                                   pdMS_TO_TICKS(120));
    if (err != ESP_OK || bytes < sizeof(int32_t) * 2) {
      vTaskDelay(pdMS_TO_TICKS(5));
      continue;
    }

    const int n = (int)(bytes / sizeof(int32_t));
    int k = 0;
    AudioFrame frame;

    for (int i = 0; i < n; ++i) {
      // El INMP441 entrega 24 bits alineados a la izquierda en 32 bits.
      float x = (float)(raw[i] >> 14);

      x = hpF.process(x);   // quita DC
      x = lpF1.process(x);  // anti-alias
      x = lpF2.process(x);

      if ((i & 1) == 0) {   // decimación 16 kHz -> 8 kHz
        float y = x * MIC_GAIN;
        if (y > 32767.0f) y = 32767.0f;
        else if (y < -32768.0f) y = -32768.0f;

        if (k < FRAME_SAMPLES) {
          frame.pcm[k++] = (int16_t)lrintf(y);
        }
      }
    }

    if (k <= 0) continue;

    frame.len = (uint16_t)k;
    frame.flags = motionFlag ? 0x01 : 0x00;

    // Si la app/red va lenta, se descarta el bloque para no bloquear la tarea
    if (audioQ == nullptr || xQueueSend(audioQ, &frame, 0) != pdTRUE) {
      ++audioDrops;
    }
  }
}

// ============================== MOVIMIENTO =================================
void updateMotion() {
  if (!mpu_ok) {
    motionFlag = false;
    return;
  }

  sensors_event_t a, g, temp;
  if (!mpu.getEvent(&a, &g, &temp)) return;

  const float ax = a.acceleration.x;
  const float ay = a.acceleration.y;
  const float az = a.acceleration.z;
  const float mag = sqrtf(ax * ax + ay * ay + az * az);

  accDev = fabsf(mag - 9.80665f);
  motionFlag = accDev > motionThreshold;
}

// ============================== PPG / BPM ==================================
void updatePpg() {
  if (!max_ok) return;

  // Lectura NO bloqueante: drena el FIFO y se queda con la muestra más reciente.
  // (getIR()/getRed() esperan hasta 250 ms y frenarían el envío de audio.)
  uint32_t ir = ppgIr, red = ppgRed;
  bool got = false;
  if (particleSensor.check()) {
    while (particleSensor.available()) {
      ir = particleSensor.getFIFOIR();
      red = particleSensor.getFIFORed();
      particleSensor.nextSample();
      got = true;
    }
  }
  if (!got) return;

  ppgIr = ir;
  ppgRed = red;

  finger = ir > FINGER_IR_MIN;

  if (!finger) {
    ppgPrimed = false;
    ppgAbove = false;
    beatCount = 0;
    beatIdx = 0;
    lastBeatMs = 0;
    bpm = 0;
    return;
  }

  if (!ppgPrimed) {
    ppgDc = (float)ir;
    acMax = 100.0f;
    ppgPrimed = true;
    return;
  }

  // DC lento + componente AC
  ppgDc = 0.95f * ppgDc + 0.05f * (float)ir;
  const float ac = (float)ir - ppgDc;
  acMax = fmaxf(acMax * 0.999f, fabsf(ac));

  const float thr = fmaxf(acMax * 0.45f, 60.0f);
  const uint32_t now = millis();

  if (!ppgAbove && ac > thr) {
    ppgAbove = true;

    if (lastBeatMs != 0) {
      const uint32_t dt = now - lastBeatMs;
      if (dt >= 300 && dt <= 2000) {  // 30-200 lpm
        beatIntervals[beatIdx] = (float)dt;
        beatIdx = (beatIdx + 1) % 5;
        if (beatCount < 5) ++beatCount;

        float sum = 0;
        for (int i = 0; i < beatCount; ++i) sum += beatIntervals[i];
        const int b = (int)(60000.0f / (sum / (float)beatCount) + 0.5f);
        bpm = (b >= 30 && b <= 220) ? b : 0;
      }
    }
    lastBeatMs = now;
  } else if (ppgAbove && ac < thr * 0.5f) {
    ppgAbove = false;
  }
}

// ============================== TELEMETRÍA =================================
void sendTelemetry() {
  char buf[240];
  const int rssi = (WiFi.getMode() == WIFI_STA) ? (int)WiFi.RSSI() : 0;

  snprintf(buf, sizeof(buf),
           "{\"t\":1,\"bpm\":%d,\"bv\":%d,\"fing\":%d,\"mot\":%d,"
           "\"acc\":%.2f,\"ir\":%lu,\"red\":%lu,\"rssi\":%d}",
           bpm, (finger && bpm > 0) ? 1 : 0, finger ? 1 : 0,
           motionFlag ? 1 : 0, accDev,
           (unsigned long)ppgIr, (unsigned long)ppgRed, rssi);

  webSocket.broadcastTXT(buf);
}

// ============================== WEBSOCKET ==================================
void onWsEvent(uint8_t num, WStype_t type, uint8_t *payload, size_t length) {
  (void)num;

  switch (type) {
    case WStype_CONNECTED:
      Serial.println("App conectada por WebSocket");
      sendTelemetry();
      break;

    case WStype_DISCONNECTED:
      Serial.println("App desconectada");
      break;

    case WStype_TEXT: {
      if (length >= 3 && payload != nullptr) {
        char cmd[24];
        const size_t n = (length < sizeof(cmd) - 1) ? length : sizeof(cmd) - 1;
        memcpy(cmd, payload, n);
        cmd[n] = '\0';

        if (strncmp(cmd, "MT=", 3) == 0) {
          const float v = atof(cmd + 3);
          if (v >= 0.05f && v <= 20.0f) {
            motionThreshold = v;
            Serial.printf("Umbral de movimiento: %.2f m/s^2\n", v);
          }
        }
      }
      break;
    }

    default:
      break;
  }
}
