# Plantilla de Anteproyecto de Grado

Esta plantilla en LaTeX ha sido diseñada para la elaboración de anteproyectos de grado del programa de Ingeniería Electrónica de la Universidad Francisco de Paula Santander. Su propósito es separar el contenido académico del formato institucional, de modo que el estudiante concentre su trabajo en la escritura del documento y en la organización de la información.

## Autoría y licencia

Plantilla elaborada por:

- Prof. Sergio Sepúlveda, Ph.D.
- Programa de Ingeniería Electrónica
- Universidad Francisco de Paula Santander

Esta plantilla se distribuye bajo la licencia `CC BY-NC 4.0`. Consulte el archivo `LICENSE` para más información.

## Estructura general

La plantilla se organiza en los siguientes archivos y carpetas principales:

- `main.tex`: archivo principal del documento.
- `ufps-anteproyecto.cls`: clase institucional que define formato, portada, estilo de capítulos, tablas, figuras y configuración general.
- `metadata.tex`: archivo de metadatos editables del trabajo.
- `referencias.bib`: base de datos bibliográfica en formato BibTeX.
- `Capitulos/`: carpeta que contiene el contenido de cada capítulo.
- `Capitulos/Figuras/`: carpeta destinada a las imágenes y figuras del documento.
- `README.md`: guía breve de uso de la plantilla.

## Archivos que el estudiante debe editar

En condiciones normales, el estudiante solo debe trabajar en los siguientes archivos:

- `metadata.tex`
- `referencias.bib`
- los archivos ubicados en `Capitulos/`

No se recomienda modificar el archivo `ufps-anteproyecto.cls`, salvo que exista una actualización institucional del formato o una instrucción expresa del director del programa o del docente responsable.

## Registro de datos del trabajo

El archivo `metadata.tex` contiene la información básica del anteproyecto. Allí se deben diligenciar:

- título del trabajo
- modalidad
- año de presentación
- nombre y código del estudiante
- nombre del director
- nombre del codirector, si aplica

La plantilla admite:

- un estudiante
- dos estudiantes
- director obligatorio
- codirector opcional

Si el trabajo tiene dos autores, deben descomentarse las líneas correspondientes al segundo estudiante. Si no existe codirector, la línea respectiva puede dejarse comentada.

## Organización del contenido

Cada capítulo se encuentra en un archivo independiente dentro de la carpeta `Capitulos/`. La versión actual incluye:

- `01-introduccion.tex`
- `02-planteamiento.tex`
- `03-objetivos.tex`
- `04-marco_referencial.tex`
- `05-metodologia.tex`
- `06-cronograma.tex`
- `07-presupuesto.tex`

Esta separación facilita la revisión del documento, mejora la organización del trabajo y reduce el riesgo de alterar accidentalmente la estructura general de la plantilla.

Cada archivo de capítulo incluye una línea del tipo:

```tex
% !TeX root = ../main.tex
```

Esta línea ayuda a algunos editores a reconocer que el archivo principal del proyecto es `main.tex`.

## Gestión de referencias bibliográficas

La bibliografía se administra mediante el archivo `referencias.bib`, usando BibTeX y el estilo `apacite`. Se recomienda:

- registrar todas las referencias en `referencias.bib`
- citar dentro del texto mediante las claves bibliográficas correspondientes
- evitar escribir referencias manualmente en el cuerpo del documento

Esta práctica permite mantener uniformidad en el formato de citación y simplifica la actualización de las fuentes.

La versión actual de la plantilla está configurada para citas y bibliografía en formato APA. Por ello, es válido usar comandos como:

- `\cite{clave}` para cita parentética
- `\citeA{clave}` para cita narrativa
- `\citeA[p.~4]{clave}` para cita narrativa con número de página

Si en el futuro se requiere una variante en formato IEEE, conviene crear una configuración específica para ese estilo, ya que la bibliografía numérica (`[1]`, `[2]`, `[3]`) cambia también la forma de citar dentro del texto.

## Inclusión de figuras

Las figuras deben almacenarse en la carpeta `Capitulos/Figuras/`. Se recomienda utilizar nombres de archivo claros y evitar espacios en blanco. Ejemplos recomendables:

- `arquitectura_sistema.png`
- `cronograma_general.pdf`
- `diagrama_bloques.jpg`

## Compilación del documento

El documento puede compilarse desde un editor LaTeX compatible o desde la terminal. Un método recomendado es:

```bash
latexmk -pdf main.tex
```

En Overleaf, basta con establecer `main.tex` como archivo principal del proyecto y usar la compilación normal del editor.

Cuando se agregan nuevas referencias bibliográficas, pueden requerirse varias pasadas de compilación para que se actualicen correctamente las citas, la tabla de contenido, la lista de tablas y las referencias cruzadas.

Si se desea limpiar archivos auxiliares generados durante la compilación, puede usarse:

```bash
latexmk -c main.tex
```

También es normal que, después de compilar, aparezcan archivos auxiliares como `.aux`, `.bbl`, `.blg`, `.fdb_latexmk`, `.fls`, `.log`, `.lof`, `.lot`, `.out` y `.toc`. Estos archivos no forman parte del contenido académico y pueden eliminarse antes de compartir la plantilla.

## Formas de usar la plantilla

La plantilla puede utilizarse de tres maneras principales:

- desde GitHub, descargando o clonando el repositorio
- desde Overleaf, importando una copia del proyecto
- de forma local, usando VS Code con una distribución LaTeX

### Opción 1: usar la plantilla desde GitHub

Si solo desea descargar la plantilla, puede usar la opción `Code > Download ZIP` en GitHub.

Si desea clonar el repositorio con Git, puede usar:

```bash
git clone <URL-del-repositorio>
cd <nombre-del-repositorio>
```

Después de descargar o clonar el proyecto, el archivo principal para compilar es:

```tex
main.tex
```

### Opción 2: usar la plantilla en Overleaf

Para trabajar en Overleaf, se recomienda:

1. descargar el proyecto como archivo `.zip` desde GitHub o desde la copia oficial compartida
2. crear un proyecto nuevo en Overleaf
3. importar el archivo `.zip`
4. verificar que el archivo principal del proyecto sea `main.tex`

Esta opción es útil para estudiantes que no desean instalar LaTeX de forma local.

### Opción 3: usar la plantilla localmente en Mac

Configuración recomendada:

- Visual Studio Code
- MacTeX
- extensión `LaTeX Workshop`

Pasos básicos:

1. instalar `MacTeX`
2. instalar `Visual Studio Code`
3. instalar la extensión `LaTeX Workshop`
4. abrir la carpeta del proyecto en VS Code
5. compilar `main.tex`

Si la instalación quedó correcta, también puede compilar desde la terminal con:

```bash
latexmk -pdf main.tex
```

### Opción 4: usar la plantilla localmente en Windows

Configuración recomendada:

- Visual Studio Code
- MiKTeX
- extensión `LaTeX Workshop`

Pasos básicos:

1. instalar `MiKTeX`
2. instalar `Visual Studio Code`
3. instalar la extensión `LaTeX Workshop`
4. abrir la carpeta del proyecto en VS Code
5. compilar `main.tex`

Si es necesario, MiKTeX puede solicitar la instalación automática de paquetes faltantes durante la primera compilación.

## Recomendaciones para estudiantes

Para comenzar a editar la plantilla, se recomienda este orden:

1. diligenciar `metadata.tex`
2. revisar y actualizar `referencias.bib`
3. editar los archivos dentro de `Capitulos/`
4. compilar siempre desde `main.tex`

No se recomienda modificar `ufps-anteproyecto.cls`, salvo que exista una actualización oficial del formato o una instrucción expresa del docente o del programa.

## Buenas prácticas de uso

Para un uso adecuado de la plantilla, se recomienda:

- no modificar el archivo de clase institucional
- conservar la separación entre contenido y formato
- escribir cada sección en el archivo de capítulo correspondiente
- mantener actualizada la base bibliográfica
- usar etiquetas (`\label`) y referencias cruzadas (`\ref`, `\cref`) de forma consistente
- evitar cambios locales de formato dentro del contenido, salvo cuando sean estrictamente necesarios
- almacenar las imágenes dentro de `Capitulos/Figuras/`
- compilar siempre desde `main.tex`

## Observaciones finales

Esta plantilla busca ofrecer una base estable, profesional y mantenible para la presentación de anteproyectos de grado. Cualquier ajuste institucional futuro en tipografía, márgenes, portada, estructura o estilo puede realizarse centralizadamente en la clase `ufps-anteproyecto.cls`, sin exigir a los estudiantes reescribir su contenido.

En caso de requerirse mejoras adicionales, se recomienda documentarlas y aplicarlas preservando el principio fundamental de esta plantilla: que el estudiante se ocupe del contenido y la institución del formato.
