# Revisión del Overleaf del anteproyecto

**Fecha:** 2026-11-21  
**Proyecto:** Diseño de un prototipo de fonendoscopio digital multimodal para la diferenciación de sonidos cardíacos y pulmonares  
**Alcance:** diagnóstico del proyecto LaTeX local (extraído de `Overleaf Projects (1 items).zip`) y migración del contenido real del DOCX del grupo. No se modificó el Overleaf remoto directamente: los cambios quedaron en la copia local de `01_Documentacion/01_Anteproyecto/Overleaf/`.

---

## 1. Resumen ejecutivo

El proyecto de Overleaf estaba parcialmente personalizado: el título y parte de la introducción correspondían al fonendoscopio, pero los capítulos 03 a 07 seguían siendo plantilla sobre radiación solar y redes neuronales. Además, la portada mostraba un solo autor cuando el DOCX registra cuatro.

Se migraron los capítulos 01 a 07 desde `Anteproyecto_Fonendoscopio_Digital_Estado_2026-11-16.docx`, se ajustó la metadata, se eliminaron referencias a imágenes inexistentes y se agregaron las 18 referencias del DOCX a `referencias.bib`. El resultado es un anteproyecto coherentemente enfocado en el fonendoscopio, con banderas explícitas para las decisiones que el grupo aún debe confirmar.

No se realizó compilación PDF porque `pdflatex` no está disponible en este entorno. La verificación fue estática (llaves, citas, columnas y restos de plantilla).

---

## 2. Hallazgos críticos

| # | Severidad | Hallazgo | Evidencia | Acción realizada / pendiente |
|---|---|---|---|---|
| 1 | Crítica | Capítulos 03–07 eran plantilla de radiación solar / RNA. | `03-objetivos.tex`, `04-marco_referencial.tex`, `05-metodologia.tex`, `06-cronograma.tex`, `07-presupuesto.tex` contenían piranómetro, IDEAM, radiación solar, RNAs y presupuesto de equipos de energía. | **Corregido.** Reescritos con objetivos, marco, metodología, cronograma y presupuesto del DOCX. |
| 2 | Alta | Introducción y planteamiento incompletos e incoherentes con el alcance real. | `01-introduccion.tex` introducía IA como etapa casi alcanzada; `02-planteamiento.tex` tenía texto de ejemplo sin desarrollar en “Beneficios”, “Alcances” y “Limitaciones”. | **Corregido.** Ajustados al texto del DOCX; IA y telemedicina quedan como proyecciones futuras. |
| 3 | Alta | Autoría discrepante. | Overleaf: 1 estudiante (`Deyner Osslander Gerena Torres`, código `1161891`). DOCX: 4 autores. La clase `ufps-anteproyecto.cls` solo admite 2. | **Parcialmente corregido.** Título completo actualizado; se documentaron los 4 autores en comentarios de `metadata.tex`. **Pendiente:** decidir cómo se registrarán los otros 3 en la portada. |
| 4 | Alta | Microcontrolador inconsistente. | DOCX y capítulo 05 indican `ESP32-S3`. El firmware y la app activos usan `ESP32-C3 Super Mini`. | **Señalado, no resuelto.** Se conservó `ESP32-S3` en el texto migrado por fidelidad al DOCX. El grupo debe unificar la plataforma antes de la entrega. |
| 5 | Alta | Pines I2C inconsistentes entre documentos. | Código activo: `SDA=GPIO8`, `SCL=GPIO9`. El resumen PDF del 19/11 reporta `GPIO0/GPIO1`. | **Pendiente.** Verificar cableado real y fijar una sola tabla en firmware, README y anteproyecto. |
| 6 | Alta | Frecuencia de muestreo y lugar de procesamiento inconsistentes. | Informe previo: 16 kHz y filtros primarios en ESP32. Código activo: I2S a 16 kHz, anti-alias, decimación a 8 kHz y filtros Butterworth en Flutter. | **Pendiente.** Decir explícitamente cuál es la versión vigente y en qué etapa ocurre cada filtro. |
| 7 | Alta | Bandas de filtrado diferentes. | DOCX: enfoque DWT y bandas 60–150 Hz / 150–1000 Hz. App: cardíaco ≤250 Hz, pulmonar 200–1500 Hz, general ≤3000 Hz. | **Pendiente.** Confirmar bandas definitivas y justificar el cambio de DWT a Butterworth por bandas. |
| 8 | Alta | “Resta de PPG” no implementada. | El objetivo específico 2 del DOCX habla de cancelación en dos etapas. El código activo envía BPM/IR/RED como telemetría; no resta PPG del audio. | **Pendiente.** Reformular el objetivo o implementar la resta. No debe afirmarse como logro. |
| 9 | Alta | Compuerta por movimiento ≠ cancelación adaptativa. | El firmware marca movimiento y la app aplica fundido/silencio. No hay filtro adaptativo que estime y reste ruido. | **Pendiente.** Ajustar la redacción técnica o implementar cancelación adaptativa. |
| 10 | Media | Modos por botones capacitivos no evidenciados. | El DOCX indica selección por botones capacitivos; en el código revisado la selección de modos ocurre en la app Flutter. | **Pendiente.** Confirmar si existe hardware de botones o si la interfaz es exclusivamente móvil. |
| 11 | Media | Credenciales y tamaño de trama discrepantes. | Firmware activo: AP `Fonendo-ESP32`, clave `fonendo1234`, 128 muestras/trama (16 ms). Resumen PDF/App README menciona clave `12345678` y ejemplo de 256 muestras (32 ms). | **Pendiente.** Unificar protocolo y documentación. |
| 12 | Media | Referencias del DOCX no estaban en BibTeX. | `referencias.bib` tenía 38 entradas; 17 citadas y 21 sin citar, todas de la plantilla de energía/PNT. | **Corregido.** Agregadas 18 entradas del DOCX; ahora hay 56 entradas, 35 citadas y 21 sin citar (20 de plantilla solar + `ADXL355`). |
| 13 | Media | Figuras referenciadas no existían. | El marco teórico viejo referenciaba `ComponentesRadiacionSolarGlobal.png`, `EspectroDeRadiacionSolar.png`, `rna_multicapa.PNG` y `funcionamiento_neurona.PNG`. | **Corregido.** Bloques `figure` eliminados. Las imágenes reales disponibles están en `03_Imagenes/`. |
| 14 | Media | Presupuesto con redacción ambigua. | El DOCX decía “precios en dólares estadounidenses (COP)” y usaba punto como separador de miles. La suma coincide con 136.548 COP. | **Corregido en el capítulo.** Se rotula como COP y se conserva el separador. Queda pendiente confirmar si los precios son vigentes. |
| 15 | Media | Cronograma migrado desde texto lineal. | El DOCX muestra marcas ● pero la extracción no conservó su posición exacta en todas las filas. | **Corregido con cautela.** Se reconstruyó una tabla de 16 semanas; conviene compararla con el DOCX original. |
| 16 | Media | `analisis_fono.py` se menciona pero no está en los archivos entregados. | Aparece en informes y en la hoja de ruta; no aparece en ningún ZIP ni carpeta del proyecto. | **Pendiente.** Aportar el script y los datos/audio que soportan la gráfica de análisis. |
| 17 | Media | IA y validación clínica podían interpretarse como resultados alcanzados. | Nombre de la app “CardioPulmo IA”, menciones a clasificación y confianza 0,95 sin modelo entrenado ni anotación experta. | **Corregido en el texto.** Se declara IA como línea futura y no se afirma validación clínica. **Pendiente:** revisar informes/PDFs antiguos con el mismo criterio. |

---

## 3. Cambios aplicados

### En `Overleaf/`

- `metadata.tex`: título completo del DOCX; comentario con los cuatro autores y advertencia sobre el límite de dos estudiantes de la clase UFPS.
- `Capitulos/01-introduccion.tex`: Introducción migrada, conceptos clave completados y IA reclasificada como proyección futura.
- `Capitulos/02-planteamiento.tex`: problema, pregunta de investigación, justificación teórica/práctica/académica/social, alcances y limitaciones.
- `Capitulos/03-objetivos.tex`: objetivo general y cinco objetivos específicos del DOCX.
- `Capitulos/04-marco_referencial.tex`: antecedentes, bases teóricas, modelo de señal y consideraciones regulatorias; sin figuras inexistentes.
- `Capitulos/05-metodologia.tex`: población, muestra, técnicas, instrumentos, fases y validación preliminar.
- `Capitulos/06-cronograma.tex`: tabla de 11 actividades en 8 periodos de dos semanas.
- `Capitulos/07-presupuesto.tex`: tabla de componentes del prototipo, total COP 136.548.
- `referencias.bib`: 18 entradas nuevas migradas del DOCX.

### Fuera de `Overleaf/`

- `README.md`: índice general del proyecto reorganizado.
- `ESTADO_PROYECTO_2026-11-21.md`: avance consolidado, pendientes y próximos pasos.

No se eliminaron ZIPs originales ni copias de respaldo; todo quedó bajo `99_Archivo/`.

---

## 4. Decisiones que requieren el grupo

1. **Plataforma:** ESP32-S3 (DOCX) o ESP32-C3 Super Mini (código real).
2. **Autoría:** cómo reflejar cuatro autores en una clase que admite dos.
3. **Procesamiento:** DWT/cancelación adaptativa (DOCX) frente a filtros Butterworth y compuerta por movimiento (código).
4. **PPG:** referencia de BPM, como está implementado, o señal a restar del audio, como dice el objetivo.
5. **Interfaz:** botones capacitivos físicos o selección de modos en la app Flutter.
6. **Configuración de red:** SSID, clave, pines, frecuencia y tamaño de trama definitivos.
7. **Evidencia:** incorporar `analisis_fono.py`, audio de origen y anotaciones que respalden la gráfica de análisis.

---

## 5. Verificación estática realizada

- Llaves balanceadas en `main.tex`, `metadata.tex`, los siete capítulos y `referencias.bib`.
- Todas las claves citadas existen en BibTeX; 35 de 56 entradas están citadas.
- Tabla del cronograma: 9 columnas por fila (actividad + 8 periodos).
- Sin restos de plantilla solar: no aparecen “radiación solar”, “piranómetro”, “neurona”, `Figuras/`, `includegraphics` ni claves `Capizzi`/`Markvart`.
- Entornos `landscape` correctamente abiertos y cerrados en capítulos 06 y 07.
- Sin caracteres fuera de alphanumería latina esperada en los archivos LaTeX.

**Limitación:** no hay compilación PDF; la revisión es de contenido y sintaxis básica, no de maquetación final.

---

## 6. Recomendación final

El Overleaf local ya sirve como base para revisar el anteproyecto con el director: ya no contiene plantilla de energía solar y refleja el trabajo del grupo. Antes de subirlo/entregarlo, el grupo debe resolver las siete decisiones anteriores y actualizar el texto y el código para que digan exactamente lo mismo. Priorice la coherencia ESP32-C3 vs ESP32-S3, PPG, bandas y autoría.
