\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{ufps-anteproyecto}[2026/03/23 v3.0 UFPS anteproyecto class]

\DeclareOption*{\PassOptionsToClass{\CurrentOption}{report}}
\ProcessOptions\relax
\LoadClass[letterpaper]{report}

\RequirePackage[T1]{fontenc}
\RequirePackage[utf8]{inputenc}
\RequirePackage[english,spanish,es-tabla]{babel}
\RequirePackage{mathptmx}
\RequirePackage{graphicx}
\RequirePackage[hidelinks]{hyperref}
\RequirePackage{amssymb}
\RequirePackage{amsmath}
\RequirePackage{amsfonts}
\RequirePackage{caption}
\RequirePackage{enumitem}
\RequirePackage{cleveref}
\RequirePackage{setspace}
\RequirePackage{array}
\RequirePackage{multirow}
\RequirePackage{xcolor,colortbl}
\RequirePackage{longtable}
\RequirePackage{booktabs}
\RequirePackage{chngcntr}
\RequirePackage{float}
\RequirePackage{apacite}
\RequirePackage[titletoc,title]{appendix}
\RequirePackage{pdflscape}
\RequirePackage{fancyhdr}
\RequirePackage{ragged2e}
\RequirePackage{titletoc}
\RequirePackage{titlesec}

\makeatletter

\newlength{\ufpsparindent}
\setlength{\ufpsparindent}{0.5in}

\raggedbottom

\counterwithout{figure}{chapter}
\counterwithout{table}{chapter}
\setcounter{secnumdepth}{4}
\setcounter{tocdepth}{4}

\definecolor{greencheese}{rgb}{0.56,0.66,0.5}
\definecolor{codegreen}{rgb}{0,0.6,0}
\definecolor{codegray}{rgb}{0.5,0.5,0.5}
\definecolor{codepurple}{rgb}{0.58,0,0.82}
\definecolor{backcolor}{rgb}{0.98,0.98,0.98}
\definecolor{url_links_color}{RGB}{0,76,153}
\definecolor{linkcolor}{RGB}{0,0,0}
\definecolor{citations_color}{RGB}{135,35,35}
\definecolor{sombreado-cronograma}{RGB}{204,229,255}

\hypersetup{
  colorlinks = true,
  urlcolor = url_links_color,
  linkcolor = linkcolor,
  citecolor = citations_color
}

\AtBeginDocument{
  \RaggedRight
  \setlength{\parindent}{\ufpsparindent}
  \renewcommand{\BBAA}{\&}
  \renewcommand{\BRetrievedFrom}{}
  \renewcommand{\BOthers}[1]{et al.\hbox{}}
}

\def\@institucion{UNIVERSIDAD FRANCISCO DE PAULA SANTANDER}
\def\@facultad{INGENIERÍA}
\def\@programa{INGENIERÍA ELECTRÓNICA}
\def\@ciudad{SAN JOSÉ DE CÚCUTA}
\def\@fecha{10 de noviembre}
\def\@yeardef{2026}
\def\@grado{INGENIERO ELECTRÓNICO}
\def\@mode{Investigación}
\def\@estudianteA{Deyner Osslander Gerena Torres}
\def\@codigoA{1161891}
\def\@estudianteB{}
\def\@codigoB{}
\def\@director{Sepulveda Mora Sergio Basilio}
\def\@codirector{}
\def\@asesortec{}

\def\fecha#1{\gdef\@fecha{#1}}
\def\yeardef#1{\gdef\@yeardef{#1}}
\def\aniodepresentacion#1{\gdef\@yeardef{#1}}
\def\institucion#1{\gdef\@institucion{#1}}
\def\facultad#1{\gdef\@facultad{#1}}
\def\programa#1{\gdef\@programa{#1}}
\def\ciudad#1{\gdef\@ciudad{#1}}
\def\grado#1{\gdef\@grado{#1}}
\def\mode#1{\gdef\@mode{#1}}
\def\modalidad#1{\gdef\@mode{#1}}
\def\estudianteA#1{\gdef\@estudianteA{#1}}
\def\codigoA#1{\gdef\@codigoA{#1}}
\def\estudianteB#1{\gdef\@estudianteB{#1}}
\def\codigoB#1{\gdef\@codigoB{#1}}
\def\director#1{\gdef\@director{#1}}
\def\codirector#1{\gdef\@codirector{#1}}
\def\titulo#1{\title{#1}}
\def\autor#1{\estudianteA{#1}}
\def\codigoestudiante#1{\codigoA{#1}}

% Compatibilidad con la versión anterior.
\renewcommand{\author}[1]{\gdef\@author{#1}\gdef\@estudianteA{#1}}
\def\code#1{\gdef\@codigoA{#1}}
\def\authorA#1{\gdef\@estudianteB{#1}}
\def\asesortec#1{\gdef\@asesortec{#1}}

\setlength{\topmargin}{-6mm}
\setlength{\headheight}{17pt}
\setlength{\headsep}{2mm}
\setlength{\marginparsep}{0mm}
\setlength{\marginparwidth}{0cm}
\setlength{\oddsidemargin}{0cm}
\setlength{\evensidemargin}{-5.4mm}
\setlength{\textheight}{22.86cm}
\setlength{\textwidth}{16.51cm}
\setlength{\parskip}{0em}
\setlength{\parindent}{\ufpsparindent}
\setlength{\bibleftmargin}{\ufpsparindent}
\setlength{\bibindent}{-\bibleftmargin}
\setstretch{1.8}
\renewcommand{\arraystretch}{1.2}

\renewcommand*{\ps@plain}{%
  \let\@mkboth\@gobbletwo
  \let\@oddfoot\@empty
  \def\@oddhead{%
    \reset@font
    \hfil
    \thepage
  }%
  \let\@evenhead\@oddhead
  \let\@evenfoot\@empty
}
\let\ufps@plain@orig\ps@plain
\pagestyle{plain}

\fancypagestyle{mylandscape}{
  \fancyhf{}
  \fancyhead[L]{\rotatebox{90}{\thepage}}
  \renewcommand{\headrulewidth}{0pt}
  \renewcommand{\footrulewidth}{0pt}
}

\addto\captionsspanish{\renewcommand{\contentsname}{Tabla de Contenido}}
\addto\captionsspanish{\renewcommand{\listfigurename}{Lista de figuras}}
\addto\captionsspanish{\renewcommand{\listtablename}{Lista de tablas}}
\addto\captionsspanish{\renewcommand{\bibname}{Bibliografía y Cibergrafía}}
\addto\captionsspanish{\renewcommand{\tablename}{Tabla}}

\titleformat{\chapter}[block]
  {\normalfont\normalsize\bfseries}{\thechapter.}{1ex}{\centering}
\titlespacing*{\chapter}{0pt}{-20pt}{10pt}

\titleformat{\section}[block]
  {\normalfont\normalsize\bfseries}{\thesection.}{1ex}{}

\titleformat{\subsection}[block]
  {\it\normalsize\bfseries}{\thesubsection.}{1em}{}

\titleformat{\subsubsection}[runin]
  {\normalfont\normalsize\bfseries}
  {\hspace{\ufpsparindent}\thesubsubsection.}
  {1ex}{}[.\quad]

\titleformat{\paragraph}[runin]
  {\it\normalsize\bfseries}
  {\hspace{\ufpsparindent}\theparagraph.}
  {1ex}{}[.\quad]
\titlespacing*{\paragraph}{0pt}{0.8\baselineskip}{1em}

\titlecontents{section}
  [1.5em]
  {}
  {\contentslabel{2.3em}}
  {}
  {\titlerule*[0.8pc]{.}\contentspage}

\titlecontents{subsection}
  [3.8em]
  {}
  {\contentslabel{3.1em}}
  {}
  {\titlerule*[0.8pc]{.}\contentspage}

\titlecontents{subsubsection}
  [7.2em]
  {}
  {\contentslabel{4.2em}}
  {}
  {\titlerule*[0.8pc]{.}\contentspage}

\titlecontents{paragraph}
  [11.8em]
  {}
  {\contentslabel{4.8em}}
  {}
  {\titlerule*[0.8pc]{.}\contentspage}

\captionsetup[table]{labelformat=simple,labelsep=newline,singlelinecheck=off,justification=raggedright}
\captionsetup[table]{labelfont=bf,textfont={it},font=doublespacing}
\captionsetup[longtable]{labelformat=simple,labelsep=newline,singlelinecheck=off,justification=raggedright}
\captionsetup[longtable]{labelfont=bf,textfont={it},font=doublespacing}
\captionsetup[figure]{labelformat=simple,labelsep=newline,singlelinecheck=off,justification=raggedright}
\captionsetup[figure]{labelfont=bf,textfont={it},font=doublespacing}

\renewcommand{\labelitemi}{\textbullet}
\setlist[itemize]{leftmargin=\ufpsparindent,itemindent=0pt,labelsep=0.5em,labelwidth=0.8em,align=left}

\titlecontents{figure}
  [0em]
  {\addvspace{0.4em}}
  {Figura \thecontentslabel.\hspace{0.5em}}
  {}
  {\titlerule*[0.8pc]{.}\contentspage}

\titlecontents{table}
  [0em]
  {}
  {Tabla \thecontentslabel.\hspace{0.5em}}
  {}
  {\titlerule*[0.8pc]{.}\contentspage}

% Evita el espacio extra automático entre tablas de capítulos distintos
% para que la Lista de tablas mantenga un espaciado uniforme.
\def\@chapter[#1]#2{%
  \ifnum \c@secnumdepth >\m@ne
    \refstepcounter{chapter}%
    \typeout{\@chapapp\space\thechapter.}%
    \addcontentsline{toc}{chapter}{\protect\numberline{\thechapter}#1}%
  \else
    \addcontentsline{toc}{chapter}{#1}%
  \fi
  \chaptermark{#1}%
  \addtocontents{lof}{\protect\addvspace{10\p@}}%
  \if@twocolumn
    \@topnewpage[\@makechapterhead{#2}]%
  \else
    \@makechapterhead{#2}%
    \@afterheading
  \fi
}

\newenvironment{alwayssingle}{%
  \@restonecolfalse
  \if@twocolumn\@restonecoltrue\onecolumn
  \else\if@openright\cleardoublepage\else\clearpage\fi
  \fi
}{%
  \if@restonecol\twocolumn
  \else\newpage\thispagestyle{empty}\fi\onecolumn
}

\newcommand{\@printstudents}{%
  {\@estudianteA \par}
  \ifx\@estudianteB\@empty\else
    \vspace{1ex}
    {\@estudianteB \par}
  \fi
}

\newcommand{\@printcodes}{%
  \ifx\@codigoA\@empty\else
    {Código: \@codigoA \par}
  \fi
  \ifx\@codigoB\@empty\else
    {Código: \@codigoB \par}
  \fi
}

\newcommand{\@printadvisors}{%
  \ifx\@asesortec\@empty
    Director:\\ \@director \par
    \ifx\@codirector\@empty\else
      \vspace{1ex}
      Codirector:\\ \@codirector \par
    \fi
  \else
    \@asesortec \par
  \fi
}

\newcommand{\portada}{%
  \begin{alwayssingle}
    \renewcommand{\footnotesize}{\small}
    \renewcommand{\footnoterule}{\relax}
    \thispagestyle{empty}
    \begin{center}
      {\@title \par}
      \vfill
      \@printstudents
      {\vspace*{\fill}
      {\@institucion \par}
      {FACULTAD DE \@facultad \par}
      {\@programa \par}
      {\@ciudad \par}
      {\@yeardef}}
    \end{center}
  \end{alwayssingle}
}

\newcommand{\subportada}{%
  \begin{alwayssingle}
    \renewcommand{\footnotesize}{\small}
    \renewcommand{\footnoterule}{\relax}
    \thispagestyle{plain}
    \begin{center}
      {\@title \par}
      \vfill
      {Anteproyecto de grado para optar por el título de:\\ \@grado \par}
      \vfill
      {Modalidad: \@mode \par}
      \@printstudents
      \@printcodes
      \vfill
      \@printadvisors
      {\vspace*{\fill}
      {\@institucion \par}
      {FACULTAD DE \@facultad \par}
      {\@programa \par}
      {\@ciudad \par}
      {\@yeardef}}
    \end{center}
  \end{alwayssingle}
}

\newcommand{\aceptacion}{%
  \renewcommand{\footnotesize}{\small}
  \renewcommand{\footnoterule}{\relax}
  \thispagestyle{plain}
  \twocolumn
  \mbox{}
  \newpage
  \begin{center}
    {Nota de Aceptación\par}
    \vspace*{5mm}
    \hrule
    \vspace*{5mm}
    \hrule
    \vspace*{5mm}
    \hrule
    \vspace*{5mm}
    \hrule
    \vspace*{5mm}
    \hrule
    \vspace*{5mm}
    \hrule
    \vfill
    \vspace*{30mm}
    \hrule
    {Firma del presidente de jurado}
    \vspace*{20mm}
    \hrule
    {Firma del jurado}
    \vspace*{20mm}
    \hrule
    {Firma del jurado}
    \vfill
  \end{center}
  \onecolumn
}

\newenvironment{dedicatoria}
{
  \begin{alwayssingle}
    \thispagestyle{plain}
    \vspace{0.5cm}
    \begin{center}
      \textbf{Dedicatoria}\par
      \vspace{0.5cm}
}
{
    \end{center}
  \end{alwayssingle}
}

\newenvironment{agradecimientos}
{
  \begin{alwayssingle}
    \thispagestyle{plain}
    \begin{center}
      \textbf{Agradecimientos}
    \end{center}
    \begin{quote}
}
{
    \end{quote}
  \end{alwayssingle}
}

\newenvironment{RAE}
{
  \begin{alwayssingle}
    \setlength{\parindent}{0.5cm}
    \thispagestyle{plain}
    \begin{center}
      {\textbf{RESUMEN ANALÍTICO DE ESTUDIO}}

      {\textbf{R.A.E}}

      {\textbf{UNIVERSIDAD FRANCISCO DE PAULA SANTANDER}}
    \end{center}
}
{
  \end{alwayssingle}
}

\newenvironment{Resume}
{
  \begin{alwayssingle}
    \thispagestyle{plain}
    \begin{center}
      \vspace*{1.5cm}
      {\Large \bfseries R\'{e}sum\'{e}}
    \end{center}
    \vspace{0.5cm}
    \begin{quote}
}
{
    \end{quote}
  \end{alwayssingle}
}

\newenvironment{ListPubli}
{
  \begin{alwayssingle}
    \thispagestyle{plain}
    \vspace*{3cm}
    {\Huge \bfseries \hspace*{-0.8cm} List of Publications}
    \vspace{0.5cm}
}
{
  \end{alwayssingle}
}

\newenvironment{romanpages}
{\cleardoublepage\hypersetup{pageanchor=false}\pagenumbering{roman}}
{\cleardoublepage\pagenumbering{arabic}\hypersetup{pageanchor=true}}

\newcommand{\maketitlepages}{\portada}
\renewcommand{\maketitlepages}{%
  \hypersetup{pageanchor=false}%
  \portada
}

\newcommand{\makefrontmatter}{%
  \begin{romanpages}
    \subportada
    \tableofcontents
    \listoffigures
    \listoftables
  \end{romanpages}
}

\makeatother
