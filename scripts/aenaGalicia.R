# ============================================================
# ANÁLISIS DE AEROPUERTOS GALLEGOS - DATOS AENA
# ============================================================
# Autor: Enrique Manuel Pardo Aldao
# Objetivo:
#   Preparar y transformar los datos de AENA para construir una
#   visualización interactiva sobre los aeropuertos gallegos:
#   Santiago de Compostela (SCQ), A Coruña (LCG) y Vigo (VGO).
#
# Fuente:
#   Estadísticas oficiales de AENA (2023-2025)
#
# Salida:
#   ../resultados/Analisis_Aeropuertos_Galicia.xlsx
# ============================================================


# ============================================================
# 1. CARGA DE LIBRERÍAS
# ============================================================

library(readxl)
library(dplyr)
library(janitor)
library(stringr)
library(tidyr)
library(writexl)


# ============================================================
# 2. PARÁMETROS DEL ANÁLISIS
# ============================================================
# Estos umbrales permiten eliminar rutas residuales o testimoniales
# que podrían distorsionar las visualizaciones y las métricas.

umbral_pasajeros_eficiencia <- 1000
umbral_operaciones_eficiencia <- 10

umbral_pasajeros_visualizacion <- 1000
umbral_operaciones_visualizacion <- 10

# ============================================================
# 3. CARGA DE DATOS
# ============================================================
# Se importan los dos datasets maestros generados a partir de los
# ficheros originales descargados desde AENA.

rutas_originales <- read_excel(
  "../datos/Dataset_Maestro_Aeropuertos_Galicia.xlsx",
  sheet = "Rutas"
)

companias_originales <- read_excel(
  "../datos/Dataset_Maestro_Companias.xlsx",
  sheet = "Companias"
)


# ============================================================
# 4. LIMPIEZA BÁSICA DE RUTAS
# ============================================================
# Acciones realizadas:
#   - Estandarización de nombres de columnas.
#   - Eliminación de duplicados.
#   - Limpieza de espacios en variables de texto.
#   - Conversión de tipos numéricos.
#   - Cálculo de la métrica pasajeros por operación.
#
# Nota metodológica:
#   Si operaciones = 0, la eficiencia se deja como NA para evitar
#   divisiones no válidas.

rutas_limpias <- rutas_originales %>%
  clean_names() %>%
  distinct() %>%
  mutate(
    origen = str_trim(origen),
    destino = str_trim(destino),
    pais = str_trim(pais),
    pasajeros = as.numeric(pasajeros),
    operaciones = as.numeric(operaciones),
    ano = as.integer(ano),
    pasajeros_por_operacion = if_else(
      operaciones > 0,
      pasajeros / operaciones,
      NA_real_
    )
  ) %>%
  filter(
    !is.na(origen),
    !is.na(destino),
    !is.na(pais),
    !is.na(ano)
  )


# ============================================================
# 5. DATASET PARA EFICIENCIA
# ============================================================
# Para calcular eficiencia se excluyen rutas con tráfico testimonial.
# Esto evita que rutas con muy pocos pasajeros u operaciones afecten
# de forma desproporcionada a los indicadores.

rutas_eficiencia <- rutas_limpias %>%
  filter(
    pasajeros >= umbral_pasajeros_eficiencia,
    operaciones >= umbral_operaciones_eficiencia
  )


# ============================================================
# 6. DATASET PARA VISUALIZACIÓN
# ============================================================
# Dataset principal que se usa para construir las visualizaciones.
# Mantiene rutas con actividad relevante y elimina ruido.

rutas_visualizacion <- rutas_limpias %>%
  filter(
    pasajeros >= umbral_pasajeros_visualizacion,
    operaciones >= umbral_operaciones_visualizacion
  )


# ============================================================
# 7. LIMPIEZA DE COMPAÑÍAS
# ============================================================
# Acciones realizadas:
#   - Estandarización de nombres de columnas.
#   - Eliminación de duplicados.
#   - Conversión de tipos.
#   - Eliminación de registros sin pasajeros.

companias_limpias <- companias_originales %>%
  clean_names() %>%
  distinct() %>%
  mutate(
    aeropuerto = str_trim(aeropuerto),
    compania = str_trim(compania),
    pasajeros = as.numeric(pasajeros),
    ano = as.integer(ano)
  ) %>%
  filter(
    !is.na(aeropuerto),
    !is.na(compania),
    !is.na(ano),
    pasajeros > 0
  )


# ============================================================
# 8. RESUMEN DE CALIDAD DE DATOS
# ============================================================
# Esta tabla permite documentar el impacto de la limpieza.

resumen_calidad <- tibble(
  dataset = c(
    "Rutas originales",
    "Rutas limpias",
    "Rutas eficiencia",
    "Rutas visualizacion",
    "Companias originales",
    "Companias limpias"
  ),
  registros = c(
    nrow(rutas_originales),
    nrow(rutas_limpias),
    nrow(rutas_eficiencia),
    nrow(rutas_visualizacion),
    nrow(companias_originales),
    nrow(companias_limpias)
  )
)


# ============================================================
# 9. INDICADORES GENERALES POR AEROPUERTO
# ============================================================
# Resume el peso global de cada aeropuerto en el periodo completo.

indicadores_aeropuerto <- rutas_eficiencia %>%
  group_by(origen) %>%
  summarise(
    pasajeros_totales = sum(pasajeros, na.rm = TRUE),
    operaciones_totales = sum(operaciones, na.rm = TRUE),
    eficiencia = pasajeros_totales / operaciones_totales,
    destinos = n_distinct(destino),
    paises = n_distinct(pais),
    .groups = "drop"
  ) %>%
  arrange(desc(pasajeros_totales))


# ============================================================
# 10. INDICADORES POR AEROPUERTO Y AÑO
# ============================================================
# Tabla utilizada para comparar la evolución anual de cada aeropuerto
# y alimentar visualizaciones con filtros por año e indicador.

indicadores_aeropuerto_ano <- rutas_eficiencia %>%
  group_by(ano, origen) %>%
  summarise(
    pasajeros_totales = sum(pasajeros, na.rm = TRUE),
    operaciones_totales = sum(operaciones, na.rm = TRUE),
    eficiencia = pasajeros_totales / operaciones_totales,
    destinos = n_distinct(destino),
    paises = n_distinct(pais),
    .groups = "drop"
  ) %>%
  arrange(ano, origen)


# ============================================================
# 11. TABLA LARGA DE INDICADORES PARA FLOURISH
# ============================================================
# Permite usar un filtro de indicador en Flourish.

indicadores_flourish <- indicadores_aeropuerto_ano %>%
  pivot_longer(
    cols = c(
      pasajeros_totales,
      operaciones_totales,
      eficiencia,
      destinos,
      paises
    ),
    names_to = "indicador",
    values_to = "valor"
  ) %>%
  mutate(
    indicador = recode(
      indicador,
      pasajeros_totales = "Pasajeros totales",
      operaciones_totales = "Operaciones totales",
      eficiencia = "Eficiencia",
      destinos = "Destinos",
      paises = "Países"
    )
  )


# ============================================================
# 12. EVOLUCIÓN TEMPORAL
# ============================================================
# Evolución anual de pasajeros y operaciones por aeropuerto.

evolucion_metricas <- indicadores_aeropuerto_ano %>%
  select(
    ano,
    origen,
    pasajeros_totales,
    operaciones_totales
  ) %>%
  pivot_longer(
    cols = c(pasajeros_totales, operaciones_totales),
    names_to = "indicador",
    values_to = "valor"
  ) %>%
  mutate(
    indicador = recode(
      indicador,
      pasajeros_totales = "Pasajeros",
      operaciones_totales = "Operaciones"
    )
  )

# Formato ancho para que Flourish dibuje una línea por aeropuerto.
evolucion_flourish <- evolucion_metricas %>%
  pivot_wider(
    names_from = origen,
    values_from = valor
  ) %>%
  arrange(indicador, ano)


# ============================================================
# 13. TOP 10 DESTINOS POR AEROPUERTO
# ============================================================
# Identifica los mercados más relevantes de cada aeropuerto.

top10_destinos <- rutas_visualizacion %>%
  group_by(origen, destino, pais) %>%
  summarise(
    pasajeros = sum(pasajeros, na.rm = TRUE),
    operaciones = sum(operaciones, na.rm = TRUE),
    eficiencia = pasajeros / operaciones,
    .groups = "drop"
  ) %>%
  group_by(origen) %>%
  slice_max(
    order_by = pasajeros,
    n = 10,
    with_ties = FALSE
  ) %>%
  ungroup() %>%
  arrange(origen, desc(pasajeros))


# ============================================================
# 14. DESTINOS COMPARTIDOS Y EXCLUSIVOS
# ============================================================
# Tabla de detalle por destino:
#   - número de aeropuertos gallegos que lo ofrecen
#   - lista de aeropuertos que operan ese destino
#   - clasificación narrativa: exclusivo, compartido por 2 o compartido por 3.

destinos_detalle <- rutas_visualizacion %>%
  group_by(destino, pais) %>%
  summarise(
    aeropuertos = n_distinct(origen),
    lista_aeropuertos = paste(sort(unique(origen)), collapse = " + "),
    pasajeros_totales = sum(pasajeros, na.rm = TRUE),
    operaciones_totales = sum(operaciones, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    tipo = case_when(
      aeropuertos == 3 ~ "Compartido por los 3",
      aeropuertos == 2 ~ "Compartido por 2",
      TRUE ~ "Exclusivo"
    )
  ) %>%
  arrange(desc(pasajeros_totales))


# Resumen por tipo de compartición.
destinos_compartidos_resumen <- destinos_detalle %>%
  group_by(tipo) %>%
  summarise(
    destinos = n(),
    pasajeros = sum(pasajeros_totales, na.rm = TRUE),
    operaciones = sum(operaciones_totales, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(pasajeros))


# Compartición detallada por combinación concreta de aeropuertos.
# Ejemplos: LCG + SCQ + VGO, LCG + SCQ, SCQ + VGO, Solo SCQ, etc.
comparticion_detallada <- rutas_visualizacion %>%
  group_by(destino, pais) %>%
  summarise(
    grupo = paste(sort(unique(origen)), collapse = " + "),
    pasajeros = sum(pasajeros, na.rm = TRUE),
    operaciones = sum(operaciones, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    grupo = if_else(
      str_detect(grupo, "\\+"),
      grupo,
      paste("Solo", grupo)
    )
  ) %>%
  group_by(grupo) %>%
  summarise(
    destinos = n(),
    pasajeros = sum(pasajeros, na.rm = TRUE),
    operaciones = sum(operaciones, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(pasajeros))


# Destinos exclusivos por aeropuerto.
destinos_exclusivos <- destinos_detalle %>%
  filter(aeropuertos == 1) %>%
  transmute(
    aeropuerto = lista_aeropuertos,
    destino,
    pais,
    pasajeros_totales,
    operaciones_totales
  ) %>%
  arrange(aeropuerto, desc(pasajeros_totales))


# Resumen de destinos exclusivos por aeropuerto.
destinos_exclusivos_resumen <- destinos_exclusivos %>%
  group_by(aeropuerto) %>%
  summarise(
    destinos_exclusivos = n(),
    pasajeros = sum(pasajeros_totales, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(destinos_exclusivos))


# ============================================================
# 15. COMPAÑÍAS AÉREAS Y DEPENDENCIA COMERCIAL
# ============================================================
# Se calcula la cuota de pasajeros de cada compañía dentro de cada aeropuerto.

dependencia_companias <- companias_limpias %>%
  group_by(aeropuerto, compania) %>%
  summarise(
    pasajeros = sum(pasajeros, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  group_by(aeropuerto) %>%
  mutate(
    total_aeropuerto = sum(pasajeros, na.rm = TRUE),
    cuota = round(100 * pasajeros / total_aeropuerto, 2)
  ) %>%
  ungroup() %>%
  arrange(aeropuerto, desc(pasajeros))


# Top 5 compañías por aeropuerto.
top5_companias <- dependencia_companias %>%
  group_by(aeropuerto) %>%
  slice_max(
    order_by = pasajeros,
    n = 5,
    with_ties = FALSE
  ) %>%
  ungroup() %>%
  arrange(aeropuerto, desc(pasajeros))


# Versión simplificada para barras apiladas:
# se agrupan las compañías pequeñas como "OTRAS".
companias_visualizacion <- dependencia_companias %>%
  group_by(aeropuerto) %>%
  mutate(
    ranking = rank(-pasajeros, ties.method = "first"),
    compania_agrupada = if_else(ranking <= 4, compania, "OTRAS")
  ) %>%
  group_by(aeropuerto, compania_agrupada) %>%
  summarise(
    pasajeros = sum(pasajeros, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  group_by(aeropuerto) %>%
  mutate(
    total_aeropuerto = sum(pasajeros, na.rm = TRUE),
    cuota = round(100 * pasajeros / total_aeropuerto, 2)
  ) %>%
  ungroup() %>%
  arrange(aeropuerto, desc(pasajeros))


# ============================================================
# 16. EXPORTACIÓN DE RESULTADOS
# ============================================================
# Se crea una carpeta de resultados si no existe y se exportan todas
# las tablas necesarias para Flourish y para justificar el análisis.

if (!dir.exists("resultados")) {
  dir.create("resultados")
}

write_xlsx(
  list(
    resumen_calidad = resumen_calidad,
    rutas_limpias = rutas_limpias,
    rutas_eficiencia = rutas_eficiencia,
    rutas_visualizacion = rutas_visualizacion,
    companias_limpias = companias_limpias,
    indicadores_aeropuerto = indicadores_aeropuerto,
    indicadores_aeropuerto_ano = indicadores_aeropuerto_ano,
    indicadores_flourish = indicadores_flourish,
    evolucion_metricas = evolucion_metricas,
    evolucion_flourish = evolucion_flourish,
    top10_destinos = top10_destinos,
    destinos_detalle = destinos_detalle,
    destinos_compartidos_resumen = destinos_compartidos_resumen,
    comparticion_detallada = comparticion_detallada,
    destinos_exclusivos = destinos_exclusivos,
    destinos_exclusivos_resumen = destinos_exclusivos_resumen,
    dependencia_companias = dependencia_companias,
    top5_companias = top5_companias,
    companias_visualizacion = companias_visualizacion
  ),
  "../resultados/Analisis_Aeropuertos_Galicia.xlsx"
)


# ============================================================
# 17. RESULTADOS CLAVE EN CONSOLA
# ============================================================
# Estas salidas permiten revisar rápidamente si el análisis se ha
# generado correctamente.

cat("\n===== RESUMEN DE CALIDAD =====\n")
print(resumen_calidad)

cat("\n===== INDICADORES POR AEROPUERTO =====\n")
print(indicadores_aeropuerto)

cat("\n===== COMPARTICIÓN DE DESTINOS =====\n")
print(comparticion_detallada)

cat("\n===== TOP 5 COMPAÑÍAS =====\n")
print(top5_companias)

cat("\nArchivo generado correctamente en: ../resultados/Analisis_Aeropuertos_Galicia.xlsx\n")
