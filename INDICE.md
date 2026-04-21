# Proyecto BI Completo — Índice de archivos

**Curso:** TI-6900 Inteligencia de Negocios — TEC, I Semestre 2026
**Grupo:** 1 — Cadena de supermercados minoristas
**Autor:** Danny Cordero Arrieta (2023042387)

---

Esta carpeta consolida todos los archivos funcionales del proyecto, en orden
de ejecución. Todos los archivos han sido verificados y corregidos.

## Estructura

```
proyecto_bi_completo/
│
├── 01_oltp/schema/
│   ├── 01_create_schema.sql     ← DDL de las 16 tablas + índices (PostgreSQL)
│   └── 02_drop_all.sql          ← Script de limpieza (solo dev)
│
├── 02_data_generation/
│   ├── generate_oltp_data.py    ← Generador Python con Faker (140,266 filas)
│   └── requirements.txt         ← Faker + psycopg2-binary
│
├── 03_dw/
│   ├── 01_create_dw_schema.sql  ← DDL BigQuery (7 dims + 2 hechos)
│   └── 02_validation_queries.sql← 6 bloques de validación
│
├── 04_etl/
│   ├── DATA_FUSION_GUIDE.md     ← Guía paso a paso de Data Fusion
│   └── wrangler_recipes.txt     ← Recetas listas para copy-paste
│
├── 05_diagramas/
│   ├── er_oltp.mmd / .png / .svg
│   ├── estrella_dw.mmd / .png / .svg
│   ├── arquitectura_etl.mmd / .png / .svg
│   └── pipelines_orquestacion.mmd / .png / .svg
│
├── 06_diccionario/
│   ├── Diccionario_Datos.docx   ← 17 páginas, editable
│   └── Diccionario_Datos.pdf    ← Versión lectura/impresión
│
├── 07_avances/
│   ├── avance_01_oltp.txt       ← Verificación tras OLTP
│   ├── avance_02_datos.txt      ← Verificación tras datos
│   ├── avance_03_gcp_setup.txt  ← Verificación DW en BigQuery
│   ├── avance_04_pipelines.txt  ← Verificación 9 pipelines
│   ├── avance_05_validacion.txt ← Validación funcional final
│   └── checklist_entrega.txt    ← Checklist maestro
│
├── INDICE.md                    ← este archivo
└── README.md                    ← README original del proyecto
```

## Correcciones aplicadas

1. `02_validation_queries.sql` — Typo `COIUNT` → `COUNT`
2. `generate_oltp_data.py` — Locale `es_CR` → `es_MX` (Faker)
3. `generate_oltp_data.py` — `bulk_insert` return value fix

## Orden de ejecución

| Paso | Archivo | Dónde se ejecuta |
|------|---------|-------------------|
| 1 | `01_oltp/schema/01_create_schema.sql` | PostgreSQL local |
| 2 | `02_data_generation/generate_oltp_data.py` | Python local |
| 3 | `03_dw/01_create_dw_schema.sql` | BigQuery (GCP) |
| 4 | `04_etl/DATA_FUSION_GUIDE.md` (seguir guía) | Data Fusion (GCP) |
| 5 | `03_dw/02_validation_queries.sql` | BigQuery (GCP) |
