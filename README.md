# Fonendoscopio Digital Multimodal

Proyecto académico de Ingeniería Electrónica — Universidad Francisco de Paula Santander  
**Estado del repositorio:** 2026-11-21

Este directorio está organizado para separar documentación, código, imágenes, binarios, herramientas y archivos históricos. La copia activa del código está en `02_Codigo`; las descargas originales, duplicados y artefactos generados se conservan en `99_Archivo`.

---

## Estructura

| Carpeta | Contenido |
|---|---|
| `01_Documentacion/` | Anteproyecto (DOCX, PDF y Overleaf), informes de avance y referencias. |
| `02_Codigo/` | Única copia activa del firmware ESP32 y de la app Flutter. |
| `03_Imagenes/` | Gráficas de análisis de señal y fotos/esquemas de diseño y montaje. |
| `04_Binarios_y_Releases/` | APK y binarios del firmware ya generados. |
| `05_Herramientas/` | SDK de Flutter conservado como herramienta local. |
| `99_Archivo/` | ZIPs originales, duplicados y artefactos generados. **No borrar.** |

---

## Puntos de entrada

### Documentación

- Anteproyecto LaTeX: `01_Documentacion/01_Anteproyecto/Overleaf/main.tex`
- Documento fuente del grupo: `01_Documentacion/01_Anteproyecto/Anteproyecto_Fonendoscopio_Digital_Estado_2026-11-16.docx`
- Revisión del Overleaf: `01_Documentacion/01_Anteproyecto/Revision_Overleaf_Anteproyecto_2026-11-21.md`
- Informe técnico unificado: `01_Documentacion/02_Informes_Avance/Informe_Tecnico_Unificado_Estado_al_2026-11-21.pdf`
- Informe ampliado DWT/ESP32: `01_Documentacion/02_Informes_Avance/Informe_Ampliado_DWT_ESP32_Estado_al_2026-11-21.pdf`
- Resumen al 19/11: `01_Documentacion/02_Informes_Avance/Resumen_Proyecto_Estado_al_2026-11-19.pdf`
- Estado consolidado: `ESTADO_PROYECTO_2026-11-21.md`

### Código

- App Flutter: `02_Codigo/App_Flutter/cardiopulmo_ia/`
  - `lib/dsp.dart`: filtros Butterworth y exportación WAV.
  - `lib/services.dart`: WebSocket, ajustes y almacenamiento.
  - `README.md`: protocolo, permisos y límites conocidos.
- Firmware: `02_Codigo/Firmware_ESP32/fonendoscopio_wifi/fonendoscopio_wifi.ino`
  - `README.md`: pines, red, librerías y compilación.

### Imágenes y binarios

- `03_Imagenes/Analisis_senal/`: análisis con señal sintética y con WAV real.
- `03_Imagenes/Diseno_y_montaje/`: evidencias de montaje.
- `04_Binarios_y_Releases/CardioPulmoIA_v0.1.0_2026-11-17.apk`
- `04_Binarios_y_Releases/Firmware_ESP32/`: binarios merged, app, bootloader y particiones.

---

## Configuración vigente según el código

- Microcontrolador: **ESP32-C3 Super Mini**.
- Audio: INMP441 por I2S a 16 kHz, anti-alias, decimación a 8 kHz y envío PCM16.
- Red: AP `Fonendo-ESP32`, clave `fonendo1234`, WebSocket en `ws://192.168.4.1:81`.
- Telemetría: JSON con BPM, validez, dedo, movimiento, aceleración y RSSI.
- Filtros en la app: cardíaco ≤250 Hz, pulmonar 200–1500 Hz, general ≤3000 Hz.
- Movimiento: el firmware marca el evento; la app aplica silencio con fundido.

> El DOCX del anteproyecto menciona ESP32-S3, pines y bandas diferentes. Esa discrepancia está documentada en el informe de revisión y debe resolverse antes de la entrega final.

---

## Pendientes críticos

1. Unificar ESP32-S3 (documento) frente a ESP32-C3 (código).
2. Unificar pines I2C, credenciales Wi-Fi, frecuencia y tamaño de trama.
3. Definir si el PPG solo entrega BPM o si debe restarse del audio.
4. Distinguir compuerta por movimiento de cancelación adaptativa.
5. Confirmar la autoría en la portada: el DOCX tiene 4 autores y la clase UFPS admite 2.
6. Aportar `analisis_fono.py` y los datos que respaldan la gráfica de análisis.
7. Compilar/probar integralmente la app y verificar el montaje real.

---

## Convenciones

- No ejecutar `reorganizar2.ps1`: la reorganización ya fue aplicada.
- No duplicar código fuera de `02_Codigo`.
- Los ZIPs originales en `99_Archivo/Descargas_originales/` son la fuente histórica.
- Los cambios recientes se resumen en `ESTADO_PROYECTO_2026-11-21.md`.
