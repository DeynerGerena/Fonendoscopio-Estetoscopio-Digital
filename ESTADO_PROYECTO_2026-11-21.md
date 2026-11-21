# Estado del proyecto — 2026-11-21

**Proyecto:** Fonendoscopio digital multimodal para la diferenciación de sonidos cardíacos y pulmonares  
**Propósito:** consolidar avances reales, organizar el repositorio y dejar una base coherente para la revisión del anteproyecto.

---

## 1. Avance consolidado

### Documentación

- Existe un DOCX completo del grupo con título, cuatro autores, introducción, planteamiento, justificación, alcances, objetivos, marco teórico, metodología, cronograma y presupuesto.
- El Overleaf local fue diagnosticado y migrado:
  - Capítulos 03–07 pasaron de plantilla de radiación solar a contenido del fonendoscopio.
  - Capítulos 01–02 fueron ajustados al alcance real.
  - Se agregaron 18 referencias del DOCX a la bibliografía.
  - Se eliminaron bloques de figuras inexistentes.
- Informes disponibles:
  - `Informe_Tecnico_Unificado_Estado_al_2026-11-21.pdf`
  - `Informe_Ampliado_DWT_ESP32_Estado_al_2026-11-21.pdf`
  - `Resumen_Proyecto_Estado_al_2026-11-19.pdf`
- Referencias locales en `01_Documentacion/03_Referencias/`.

### Hardware y firmware

- Componentes seleccionados: INMP441, MAX30102, MPU6050 y ESP32-C3 Super Mini.
- Firmware activo en `02_Codigo/Firmware_ESP32/`:
  - I2S a 16 kHz con anti-alias y decimación a 8 kHz.
  - PCM16 en tramas de 128 muestras (16 ms).
  - WebSocket puerto 81 en AP `Fonendo-ESP32` / `fonendo1234`.
  - Telemetría JSON con BPM, dedo, movimiento y RSSI.
  - Comando `MT=` para ajustar umbral de movimiento.
- El README del firmware reporta compilación verificada con core ESP32 3.0.4 (75 % flash, 11 % RAM). No se repitió la compilación en esta sesión.
- Binarios generados disponibles en `04_Binarios_y_Releases/Firmware_ESP32/`.

### Aplicación Flutter

- Proyecto activo en `02_Codigo/App_Flutter/cardiopulmo_ia/`.
- Pantallas: inicio, ajustes, auscultación libre, registro de pacientes, historial, detalle y análisis de grabación.
- Procesamiento en `lib/dsp.dart`: filtros Butterworth orden 4 a 8 kHz, ganancias y exportación WAV.
- Datos guardados: PCM crudo y máscara de movimiento, lo que permite reprocesamiento.
- APK presente: `04_Binarios_y_Releases/CardioPulmoIA_v0.1.0_2026-11-17.apk`.
- Límites declarados: sin escucha en vivo, sin número de secuencia de tramas y sin compilación verificada en el entorno de preparación (aunque existe un APK entregado).

### Análisis de señal

- Evidencias gráficas en `03_Imagenes/Analisis_senal/`:
  - señal sintética de 75 lpm;
  - archivo WAV real del equipo.
- El análisis exploratorio incluye FFT, espectrograma, envolvente, bandas, centroide, autocorrelación y marcas S1/S2.
- Resultados informados: el WAV real mostró baja confianza de ritmo, energía alta sobre 250 Hz y posible zumbido de 120 Hz; no constituye validación clínica ni de separación de fuentes.
- **`analisis_fono.py` no aparece en los archivos entregados.** Debe aportarse para hacer reproducible la gráfica.

### Organización del repositorio

- Código activo separado en `02_Codigo`.
- Imágenes separadas en `03_Imagenes`.
- Binarios en `04_Binarios_y_Releases`.
- SDK en `05_Herramientas/Flutter_SDK`.
- ZIPs originales, duplicados y artefactos generados conservados en `99_Archivo`.
- No se eliminó información; solo se movió a ubicaciones claras.

---

## 2. Estado de la coherencia

| Tema | Documento / anteproyecto | Código / evidencia | Estado |
|---|---|---|---|
| Microcontrolador | ESP32-S3 | ESP32-C3 Super Mini | **Discrepancia** |
| Pines I2C | 8/9 en firmware activo; 0/1 en resumen previo | 8/9 en `.ino` | **Discrepancia histórica** |
| Frecuencia | 16 kHz en informe previo | 16 kHz I2S → 8 kHz enviado | **Aclarar versión vigente** |
| Bandas | 60–150 / 150–1000 Hz, DWT | ≤250 / 200–1500 / ≤3000 Hz, Butterworth | **Discrepancia** |
| PPG | Referencia y, en el objetivo, cancelación | Solo telemetría/BPM | **Discrepancia** |
| Movimiento | Cancelación activa | Compuerta/fundido | **Discrepancia** |
| Interfaz | Botones capacitivos | Modos en app Flutter | **Discrepancia** |
| IA | Proyección futura | Sin modelo entrenado | **Coherente si se aclara** |
| Validación clínica | No realizada | No realizada | **Coherente** |

---

## 3. Pendientes priorizados

### Prioridad 1 — antes de entregar el anteproyecto

1. Decidir ESP32-S3 o ESP32-C3 y actualizar DOCX/Overleaf/firmware.
2. Definir los cuatro autores y cómo se reflejarán en la plantilla UFPS (máximo dos).
3. Reformular el objetivo de cancelación con PPG o implementarlo.
4. Unificar pines, credenciales Wi-Fi, frecuencia y tamaño de trama.
5. Confirmar bandas y justificar el paso de DWT a Butterworth.

### Prioridad 2 — antes de reportar resultados

6. Aportar `analisis_fono.py`, audio original y anotaciones S1/S2.
7. Definir matemáticamente la “confianza 0,95” de la gráfica.
8. Comparar BPM acústico/SCG contra PPG con métricas explícitas.
9. Medir respuesta real de los filtros y latencia/pérdida de tramas.
10. Calibrar movimiento con el dispositivo colocado en el pecho.

### Prioridad 3 — consolidación futura

11. Compilar y ejecutar integralmente firmware + app en hardware real.
12. Añadir número de secuencia y recuperación de paquetes.
13. Portar caracterización de sensores y modo desarrollador a Flutter.
14. Definir privacidad, consentimiento y límites de uso.
15. Si se mantiene IA, construir dataset etiquetado con separación por paciente.

---

## 4. Archivos de control creados en esta sesión

- `README.md`
- `ESTADO_PROYECTO_2026-11-21.md`
- `01_Documentacion/01_Anteproyecto/Revision_Overleaf_Anteproyecto_2026-11-21.md`
- Capítulos `01`–`07` de `01_Documentacion/01_Anteproyecto/Overleaf/Capitulos/`
- `01_Documentacion/01_Anteproyecto/Overleaf/metadata.tex`
- `01_Documentacion/01_Anteproyecto/Overleaf/referencias.bib`

---

## 5. Nota metodológica

Este estado distingue entre:

- **lo que dice el DOCX**, migrado al Overleaf;
- **lo que implementa el código activo**, verificado leyendo archivos;
- **lo que solo aparece en informes/gráficas**, tratado como evidencia exploratoria;
- **lo que aún no existe**, como `analisis_fono.py` o validación clínica.

No se afirmó compilación de Flutter, ejecución en hardware, IA entrenada ni resultado diagnóstico sin evidencia en los archivos revisados.
