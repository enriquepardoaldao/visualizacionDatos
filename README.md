# ¿Necesita Galicia tres aeropuertos?

Práctica de visualización de datos desarrollada en el marco del Máster en Ingeniería de la UOC. El proyecto analiza el tráfico aéreo de los tres aeropuertos gallegos —Santiago de Compostela, A Coruña y Vigo— para explorar si su coexistencia está justificada o supone un solapamiento ineficiente de recursos públicos.

La web del proyecto está disponible en: **[https://enriquepardoaldao.github.io/visualizacionDatos/](https://enriquepardoaldao.github.io/visualizacionDatos/)**

---

## Estructura del repositorio

```
├── index.html          # Web principal con la visualización y el vídeo
├── LICENSE
├── README.md
├── datos/              # Datasets originales utilizados en el análisis
├── resultados/         # Outputs y gráficos generados
├── scripts/            # Código R para el procesamiento y visualización
└── VisualizacionDatosAeropuertos.Rproj
```

---

## Datos utilizados

Los datos provienen de fuentes públicas oficiales:

- **AENA** — Estadísticas de tráfico de pasajeros, operaciones y carga por aeropuerto
- https://www.aena.es/es/estadisticas/inicio.html

---

## Cómo ejecutar el código R

1. Abre el archivo `VisualizacionDatosAeropuertos.Rproj` con **RStudio**
2. Instala las dependencias necesarias:

```r
install.packages(c("tidyverse", "ggplot2", "readxl", "knitr", "rmarkdown"))
```

3. Ejecuta los scripts en la carpeta `scripts/`
4. Los resultados se generan en la carpeta `resultados/`

---

## Cómo ver la web en local

La web está publicada en GitHub Pages y puede verse directamente en el enlace de arriba. Si prefieres ejecutarla en local, necesitas un servidor local (no basta con hacer doble clic en el `index.html`).

### Opción A — Python (recomendada)

**Mac / Linux:** Python viene instalado por defecto.

**Windows:** Comprueba si lo tienes abriendo el símbolo del sistema (`cmd`) y escribiendo `python --version`. Si no está instalado, descárgalo desde [python.org](https://www.python.org/downloads/) y marca la opción **"Add Python to PATH"** durante la instalación.

Una vez instalado, abre una terminal en la carpeta donde está el `index.html` y ejecuta:

```bash
python -m http.server 8000
```

En Mac/Linux puede ser necesario usar `python3` en lugar de `python`.

### Opción B — Node.js

Descarga e instala Node.js desde [nodejs.org](https://nodejs.org/) (versión LTS recomendada). Luego ejecuta:

```bash
npx serve .
```

### Acceder a la web

Con cualquiera de las dos opciones, abre el navegador en **http://localhost:8000**

---

## Visualización

La historia de datos está construida con **Flourish** y accesible de forma interactiva desde la web del proyecto. Incluye gráficos de evolución de pasajeros, comparativas entre aeropuertos y análisis de rutas.

---

## Autoría

**Enrique Manuel Pardo Aldao**  
Máster en Ingeniería Informática — Visualización de datos  
Universitat Oberta de Catalunya (UOC) · 2025–2026
