# 📊 Proyecto 01 — Inteligencia de Negocios (TI-6900)

## Cadena de Supermercados Minoristas — Grupo 1

**Curso:** TI-6900 Inteligencia de Negocios  
**Institución:** Instituto Tecnológico de Costa Rica (TEC)  
**Semestre:** I Semestre 2026  
**Profesor:** Lic. Michael Lizandro Sánchez Soto  
**Profesor alterno:** Dr. Federico Torres Carballo  
**Fecha de entrega:** 21 de abril de 2026  

---

## 👥 Integrantes del Grupo

| Nombre                          | Carné       | Rol principal                              |
|---------------------------------|-------------|--------------------------------------------|
| Danny Cordero Arrieta           | 2023042387  | Fuente de datos transaccional + ETL        |
| Raquel Gómez Vargas             | 20220502    | Modelo dimensional                         |
| Mariana Herrera Bermúdez        | 2023800120  | Comprensión del caso + documentación       |
| Randall Marcelo Sánchez Ortiz   | —           | Solución analítica (dashboard) + ETL       |

---

## 📝 Descripción del Proyecto

Este proyecto implementa una solución completa de **Business Intelligence (BI)** para una cadena de supermercados minoristas en Costa Rica. Cubre todo el flujo de datos desde la fuente transaccional hasta la visualización analítica:

1. **Fuente de datos transaccional (OLTP):** Base de datos PostgreSQL con 16 tablas normalizadas y +140,000 filas de datos sintéticos generados con Python/Faker.
2. **Modelo dimensional (DW):** Esquema estrella en Google BigQuery con 7 tablas de dimensiones y 2 tablas de hechos.
3. **Proceso ETL:** 9 pipelines implementados en Google Cloud Data Fusion que extraen datos del OLTP, los transforman y los cargan al Data Warehouse.
4. **Solución analítica:** Dashboard interactivo en Looker Studio conectado a BigQuery.

### Preguntas de negocio que responde el proyecto

- ¿Cuáles son los productos y categorías más vendidos por sucursal y periodo?
- ¿Cómo varía el comportamiento de compra por canal de venta y método de pago?
- ¿Cuál es el impacto de las promociones en el volumen de ventas e ingresos?
- ¿Cuáles son las tendencias temporales de ventas y su estacionalidad?

---

## 🏗️ Arquitectura del Proyecto

```
┌──────────────┐      ┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│  PostgreSQL  │ CSV  │  Google Cloud │ GCS  │  Cloud Data  │  BQ  │   BigQuery   │
│  (OLTP)      │ ───► │  Storage     │ ───► │  Fusion      │ ───► │   (DW)       │
│  16 tablas   │      │  (Buckets)   │      │  9 pipelines │      │  Estrella    │
└──────────────┘      └──────────────┘      └──────────────┘      └──────┬───────┘
                                                                         │
                                                                         ▼
                                                                  ┌──────────────┐
                                                                  │ Looker Studio│
                                                                  │ (Dashboard)  │
                                                                  └──────────────┘
```

---

## 📁 Estructura del Repositorio

```
Proyecto-01-Grupo-1/
│
├── README.md                          ← Este archivo (bitácora + documentación)
├── INDICE.md                          ← Índice rápido de todos los archivos
├── .gitignore                         ← Archivos excluidos del versionamiento
│
├── 01_oltp/schema/                    ← Esquema de la base transaccional
│   ├── 01_create_schema.sql           DDL: 16 tablas + índices + constraints
│   └── 02_drop_all.sql                Script de limpieza (solo desarrollo)
│
├── 02_data_generation/                ← Generación de datos sintéticos
│   ├── generate_oltp_data.py          Generador Python con Faker (140,266 filas)
│   ├── requirements.txt               Dependencias: faker, psycopg2-binary
│   └── last_run_output.txt            Log de la última ejecución exitosa
│
├── 03_dw/                             ← Data Warehouse (BigQuery)
│   ├── 01_create_dw_schema.sql        DDL: 7 dimensiones + 2 hechos + filas -1
│   └── 02_validation_queries.sql      6 bloques de validación post-carga
│
├── 04_etl/                            ← Documentación del proceso ETL
│   └── pipelines_bigquery_simples_supermercado.docx
│
├── 05_diagramas/                      ← Diagramas del proyecto
│   ├── arquitectura_etl.png           Arquitectura GCP completa
│   ├── estrella_dw.png                Modelo dimensional (esquema estrella)
│   ├── oltp transaccional 2.png       Diagrama ER del OLTP
│   └── pipelines_orquestacion.png     Orquestación de los 9 pipelines
│
├── 06_diccionario/                    ← Diccionario de datos
│   ├── Diccionario_Datos.docx         Versión editable (17 páginas)
│   └── Diccionario_Datos.pdf          Versión lectura/impresión
│
├── avances danny/                     ← Bitácora de avances verificados
│   ├── avance_01_oltp.txt             Verificación tras crear OLTP
│   ├── avance_02_datos.txt            Verificación tras poblar datos
│   ├── avance_03_gcp_setup.txt        Verificación del DW en BigQuery
│   ├── avance_04_pipelines.txt        Verificación de los 9 pipelines
│   ├── avance_05_validacion.txt       Validación funcional final
│   └── checklist_entrega.txt          Checklist maestro de entrega
│
├── csv_exports/                       ← Datos exportados (16 tablas CSV)
│   ├── tb_canal_venta.csv
│   ├── tb_categoria.csv
│   ├── tb_cliente.csv
│   ├── tb_inventario.csv
│   ├── tb_marca.csv
│   ├── tb_metodo_pago.csv
│   ├── tb_producto.csv
│   ├── tb_programa_lealtad.csv
│   ├── tb_promocion.csv
│   ├── tb_promocion_producto.csv
│   ├── tb_proveedor.csv
│   ├── tb_provincia.csv
│   ├── tb_subcategoria.csv
│   ├── tb_sucursal.csv
│   ├── tb_venta_cabecera.csv
│   └── tb_venta_detalle.csv
│
├── json pipelines/                    ← Exportaciones JSON de Data Fusion
│   ├── dim_cliente-cdap-data-pipeline.json
│   ├── dim_producto-cdap-data-pipeline.json
│   ├── fact_inventario-cdap-data-pipeline.json
│   ├── fact_ventas-cdap-data-pipeline.json
│   ├── pipe_dim_canal-cdap-data-pipeline.json
│   ├── pipe_dim_metodoPago-cdap-data-pipeline.json
│   ├── pipe_dim_promocion-cdap-data-pipeline.json
│   ├── pipe_dim_sucursal-cdap-data-pipeline.json
│   └── pipe_dim_tiempo-cdap-data-pipeline.json
│
└── export_tables_to_csv.py            Script para exportar tablas a CSV
```

---

## ⚙️ Instrucciones de Reproducción

### Prerrequisitos

- **PostgreSQL 16+** instalado localmente
- **Python 3.10+** con pip
- **Cuenta de Google Cloud Platform** con proyecto activo
- APIs habilitadas: BigQuery, Cloud Storage, Cloud Data Fusion, Compute Engine, Dataproc

### Paso 1 — Crear la base de datos OLTP

```bash
# Crear la base de datos
psql -U postgres -c "CREATE DATABASE supermercado_oltp;"

# Ejecutar el DDL (16 tablas + índices + constraints)
psql -U postgres -d supermercado_oltp -f 01_oltp/schema/01_create_schema.sql
```

### Paso 2 — Generar datos sintéticos

```bash
cd 02_data_generation
python -m venv venv
# Windows:
venv\Scripts\activate
# Linux/Mac:
# source venv/bin/activate

pip install -r requirements.txt

# Configurar conexión
set PGHOST=localhost
set PGUSER=postgres
set PGPASSWORD=<tu_password>
set PGDATABASE=supermercado_oltp

python generate_oltp_data.py
# Resultado esperado: ~140,266 filas insertadas en 16 tablas
```

### Paso 3 — Exportar datos a CSV

```bash
# Desde la raíz del proyecto
python export_tables_to_csv.py
# Se generan 16 archivos CSV en csv_exports/
```

### Paso 4 — Crear el Data Warehouse en BigQuery

1. Abrir `03_dw/01_create_dw_schema.sql` en BigQuery SQL Workspace
2. Reemplazar `{PROJECT_ID}` por tu Project ID real
3. Ejecutar el script completo

### Paso 5 — Configurar y ejecutar los pipelines ETL

1. Crear instancia de Cloud Data Fusion (Basic Edition)
2. Subir los CSVs a un bucket de Google Cloud Storage
3. Importar los 9 pipelines JSON desde `json pipelines/`
4. Ejecutar en orden: `dim_tiempo` → dimensiones restantes → hechos

### Paso 6 — Validar la carga

```sql
-- Ejecutar en BigQuery los 6 bloques de validación
-- Archivo: 03_dw/02_validation_queries.sql
```

---

## 📊 Volúmenes de Datos

| Tabla                 | Filas    | Descripción                          |
|-----------------------|----------|--------------------------------------|
| tb_provincia          | 7        | Provincias de Costa Rica             |
| tb_canal_venta        | 3        | Online, Físico, App                  |
| tb_metodo_pago        | 4        | Efectivo, Tarjeta, Sinpe, Mixto      |
| tb_programa_lealtad   | 4        | Niveles de programa de lealtad       |
| tb_categoria          | 8        | Categorías de productos              |
| tb_subcategoria       | 25       | Subcategorías de productos           |
| tb_marca              | 50       | Marcas comerciales                   |
| tb_proveedor          | 20       | Proveedores registrados              |
| tb_sucursal           | 15       | Sucursales a nivel nacional          |
| tb_producto           | 500      | Catálogo de productos                |
| tb_cliente            | 5,000    | Base de clientes                     |
| tb_promocion          | 50       | Promociones activas e históricas     |
| tb_promocion_producto | 200      | Relación promoción ↔ producto        |
| tb_inventario         | 7,500    | Inventario por sucursal/producto     |
| tb_venta_cabecera     | 25,000   | Transacciones de venta               |
| tb_venta_detalle      | 102,880  | Detalle línea por línea              |
| **Total**             | **140,266** | —                                 |

---

## 📅 Bitácora de Desarrollo

### Lunes 14 de abril, 2026 — Planificación y configuración inicial

| Hora  | Actividad | Responsable | Detalle |
|-------|-----------|-------------|---------|
| 09:00 | Reunión de kick-off del grupo | Todos | Se revisó la rúbrica del proyecto, se asignaron roles y responsabilidades. Danny: OLTP + ETL. Raquel: modelo dimensional. Mariana: caso de negocio + documentación. Randall: dashboard + apoyo ETL. |
| 10:30 | Definición de preguntas de negocio | Todos | Se definieron las 4 preguntas obligatorias y 1 adicional. Se identificaron los KPIs e indicadores clave. |
| 14:00 | Creación del proyecto en GCP | Danny | Se creó el proyecto `proyectobi-493618` en Google Cloud Platform, región `us-central1`. Se habilitaron las APIs necesarias: BigQuery, Cloud Storage, Data Fusion, Compute Engine, Dataproc. |
| 15:00 | Instalación de PostgreSQL local | Danny | Se instaló PostgreSQL 16 en Windows con pgAdmin 4. Se decidió usar PostgreSQL local en lugar de Cloud SQL para reducir costos operativos. |
| 16:00 | Creación del repositorio GitHub | Mariana | Se creó el repositorio `Proyecto-01-Grupo-1` y se agregaron los 4 integrantes como colaboradores. |
| 17:00 | Diseño inicial del esquema OLTP | Danny | Primer borrador del modelo ER con 16 tablas. Se establecieron las entidades principales: productos, clientes, sucursales, ventas, inventario. |

---

### Martes 15 de abril, 2026 — Implementación del OLTP

| Hora  | Actividad | Responsable | Detalle |
|-------|-----------|-------------|---------|
| 08:00 | Desarrollo del DDL completo | Danny | Se escribió `01_create_schema.sql` con las 16 tablas bajo el schema `sm`. Se definieron 17 foreign keys, 18 check constraints y 12 índices secundarios. Tablas principales: `tb_producto`, `tb_cliente`, `tb_venta_cabecera`, `tb_venta_detalle`. |
| 10:00 | Script de limpieza | Danny | Se creó `02_drop_all.sql` para facilitar el desarrollo iterativo — permite borrar todas las tablas y recrear desde cero. |
| 11:00 | Ejecución y verificación del schema | Danny | Se ejecutó el DDL contra PostgreSQL local. Verificación exitosa: 16 tablas creadas, 17 FKs, 18 checks, 12 índices. Se documentó todo en `avance_01_oltp.txt`. |
| 14:00 | Desarrollo del generador de datos | Danny | Se inició el desarrollo de `generate_oltp_data.py` usando la librería Faker con seed 42 para reproducibilidad. Se configuró el locale `es_MX` (Faker no soporta `es_CR` directamente). |
| 16:00 | Generación de datos sintéticos | Danny | Ejecución exitosa del generador. Total de filas generadas: 140,266 distribuidas en 16 tablas. Las tablas más pesadas: `tb_venta_detalle` (102,880 filas) y `tb_venta_cabecera` (25,000 filas). |
| 17:30 | Verificación de integridad de datos | Danny | Se corrieron queries de validación sobre las 16 tablas. Todas las foreign keys se respetan, los checks pasan, no hay NULLs en campos NOT NULL. Se documentó en `avance_02_datos.txt`. |

---

### Miércoles 16 de abril, 2026 — Exportación de datos y modelo dimensional

| Hora  | Actividad | Responsable | Detalle |
|-------|-----------|-------------|---------|
| 09:00 | Desarrollo del script de exportación | Danny | Se creó `export_tables_to_csv.py` para exportar las 16 tablas de PostgreSQL a archivos CSV. Los CSV se guardan en `csv_exports/` con headers incluidos. |
| 10:00 | Exportación exitosa | Danny | Se generaron los 16 archivos CSV. Archivo más grande: `tb_venta_detalle.csv` (~4 MB). Total de datos exportados: ~6.9 MB. |
| 11:00 | Subida de CSVs a Google Cloud Storage | Danny | Se subieron los 16 CSVs al bucket del proyecto en GCS. Estos sirven como fuente para los pipelines ETL de Data Fusion. |
| 14:00 | Diseño del modelo dimensional | Raquel + Danny | Se diseñó el esquema estrella con 7 dimensiones (`dim_tiempo`, `dim_producto`, `dim_cliente`, `dim_sucursal`, `dim_canal`, `dim_metodo_pago`, `dim_promocion`) y 2 hechos (`fact_ventas`, `fact_inventario`). |
| 16:00 | Creación del DW en BigQuery | Danny | Se escribió y ejecutó `01_create_dw_schema.sql` en BigQuery. Se insertaron las filas subrogadas `-1` en todas las dimensiones para manejar claves faltantes. |
| 17:00 | Verificación del DW | Danny | Se verificó que las 9 tablas del DW existieran en BigQuery con la estructura correcta. Se documentó en `avance_03_gcp_setup.txt`. |

---

### Jueves 17 de abril, 2026 — Pipelines ETL (Parte 1)

| Hora  | Actividad | Responsable | Detalle |
|-------|-----------|-------------|---------|
| 08:00 | Creación de instancia Data Fusion | Danny + Randall | Se creó la instancia de Cloud Data Fusion (Basic Edition). Tiempo de provisión: ~20 minutos. |
| 08:30 | Configuración de conexiones | Danny | Se configuró la conexión a GCS (fuente de CSVs) y a BigQuery (destino del DW). Se subió el driver JDBC de PostgreSQL como respaldo. |
| 09:00 | Pipeline `pipe_dim_tiempo` | Danny | Primer pipeline: genera la dimensión de tiempo a partir de las fechas encontradas en las ventas. Se aplicaron transformaciones Wrangler para extraer año, mes, día, trimestre, día de la semana. |
| 10:30 | Pipeline `pipe_dim_canal` | Danny | Pipeline simple: mapea los 3 canales de venta del OLTP a la dimensión. |
| 11:00 | Pipeline `pipe_dim_metodoPago` | Danny | Pipeline simple: mapea los 4 métodos de pago. |
| 14:00 | Pipeline `dim_cliente` | Danny + Randall | Pipeline complejo: join de `tb_cliente` con `tb_provincia` y `tb_programa_lealtad`. Transformaciones Wrangler para concatenar nombre completo y calcular antigüedad del cliente. |
| 16:00 | Pipeline `dim_producto` | Randall | Pipeline complejo: join de `tb_producto` con `tb_marca`, `tb_subcategoria` y `tb_categoria`. Desnormalización completa de la jerarquía de productos. |
| 17:30 | Pipeline `pipe_dim_sucursal` | Danny | Pipeline con join de `tb_sucursal` y `tb_provincia`. Incluye transformación de coordenadas y formato de dirección. |

---

### Viernes 18 de abril, 2026 — Pipelines ETL (Parte 2) + Validación

| Hora  | Actividad | Responsable | Detalle |
|-------|-----------|-------------|---------|
| 08:00 | Pipeline `pipe_dim_promocion` | Danny | Pipeline con transformaciones de fechas y cálculo de duración de promociones. Join con `tb_promocion_producto` para enriquecer la dimensión. |
| 09:30 | Pipeline `fact_ventas` | Danny + Randall | Pipeline más complejo del proyecto: join de `tb_venta_cabecera` y `tb_venta_detalle` con lookups a todas las dimensiones para obtener claves subrogadas. Cálculo de métricas: `monto_bruto`, `monto_descuento`, `monto_neto`. |
| 12:00 | Pipeline `fact_inventario` | Danny | Pipeline de la tabla de hechos de inventario. Join con dimensiones de producto y sucursal. Cálculo de `valor_inventario` y `dias_stock`. |
| 14:00 | Ejecución secuencial de todos los pipelines | Danny + Randall | Orden de ejecución: `dim_tiempo` → 6 dimensiones restantes (en paralelo) → `fact_ventas` → `fact_inventario`. Todos los pipelines ejecutaron exitosamente. |
| 15:30 | Exportación de pipelines a JSON | Danny | Se exportaron los 9 pipelines desde Data Fusion Studio en formato JSON. Guardados en `json pipelines/` para reproducibilidad. |
| 16:00 | Validación funcional | Danny + Randall | Se ejecutaron los 6 bloques de validación de `02_validation_queries.sql` contra BigQuery. Conciliación de volúmenes: 140,266 filas OLTP → DW verificadas. Se documentó en `avance_04_pipelines.txt`. |
| 17:00 | Corrección de bugs encontrados | Danny | Se corrigió typo `COIUNT` → `COUNT` en `02_validation_queries.sql`. Se arregló el locale de Faker (`es_CR` → `es_MX`) y el valor de retorno de `bulk_insert` en el generador. |

---

### Sábado 19 de abril, 2026 — Documentación y diagramas

| Hora  | Actividad | Responsable | Detalle |
|-------|-----------|-------------|---------|
| 09:00 | Generación de diagramas | Danny | Se generaron 4 diagramas PNG: diagrama ER del OLTP, esquema estrella del DW, arquitectura ETL completa, y orquestación de pipelines. Guardados en `05_diagramas/`. |
| 11:00 | Diccionario de datos | Danny | Se finalizó el diccionario de datos del DW (17 páginas) documentando cada tabla, columna, tipo de dato, descripción y reglas de negocio. Versiones `.docx` y `.pdf` en `06_diccionario/`. |
| 14:00 | Documentación de pipelines ETL | Danny | Se documentó el proceso de cada pipeline en `04_etl/pipelines_bigquery_simples_supermercado.docx` con capturas, configuraciones y transformaciones aplicadas. |
| 16:00 | Avance de validación final | Danny + Randall | Se completó `avance_05_validacion.txt` con los resultados finales de las 6 validaciones. Todas pasaron correctamente. |
| 17:00 | Checklist de entrega | Danny | Se actualizó `checklist_entrega.txt` con el estado de todos los rubros. Estado global: ~65% completo (pendiente informe final del grupo, presentación y dashboard). |

---

### Domingo 20 de abril, 2026 — Revisión y preparación final

| Hora  | Actividad | Responsable | Detalle |
|-------|-----------|-------------|---------|
| 10:00 | Revisión cruzada de documentación | Danny + Raquel | Se revisaron todos los archivos de avances para consistencia. Se verificó que los volúmenes reportados coinciden con los datos reales. |
| 12:00 | Prueba de reproducibilidad | Danny | Se ejecutó todo el flujo desde cero en un ambiente limpio: DDL → generación de datos → exportación CSV. Todo funciona correctamente con las instrucciones del README. |
| 15:00 | Reunión grupal de revisión | Todos | Se revisó el estado del proyecto completo. Dashboard en Looker Studio en proceso (Randall). Informe y presentación pendientes de consolidar (Mariana + Raquel). |
| 17:00 | Preparación para subida a GitHub | Danny | Se organizó la estructura final de archivos, se verificó que no haya credenciales expuestas, y se preparó el `.gitignore`. |

---

### Lunes 21 de abril, 2026 — Entrega final

| Hora  | Actividad | Responsable | Detalle |
|-------|-----------|-------------|---------|
| 09:00 | Push final al repositorio GitHub | Danny | Se subieron todos los archivos del proyecto al repositorio del grupo. Se actualizó el README con la bitácora completa. |
| 10:00 | Verificación del repositorio | Danny | Se confirmó que todos los archivos están correctamente versionados y accesibles en GitHub. |

---

## 🔧 Tecnologías Utilizadas

| Tecnología | Uso |
|------------|-----|
| **PostgreSQL 16** | Base de datos transaccional (OLTP) |
| **Python 3.10 + Faker** | Generación de datos sintéticos |
| **Google Cloud Platform** | Infraestructura cloud |
| **Google Cloud Storage** | Almacenamiento de archivos CSV |
| **Google Cloud Data Fusion** | Herramienta ETL (9 pipelines) |
| **Google BigQuery** | Data Warehouse (esquema estrella) |
| **Looker Studio** | Dashboard analítico |
| **Git + GitHub** | Control de versiones |

---

## ⚠️ Notas Importantes

1. **PostgreSQL local vs Cloud SQL:** Se usó PostgreSQL local para reducir costos. Los datos se exportan a CSV y se suben a GCS como fuente para Data Fusion.
2. **Orden de ejecución de pipelines:** `dim_tiempo` primero, las otras 6 dimensiones en paralelo, y los 2 hechos al final. Los hechos fallan si las dimensiones no están cargadas.
3. **Filas subrogadas `-1`:** Se insertan en el DDL del DW antes de los pipelines. NO usar truncate-reload en dimensiones que las contengan.
4. **Costos de Data Fusion:** Basic Edition cobra por hora de instancia encendida. Borrar la instancia al terminar.
5. **Placeholder `{PROJECT_ID}`:** Los scripts SQL de BigQuery usan este placeholder. Hacer Find & Replace antes de ejecutar.

---

## 📄 Licencia

Material académico para uso interno del curso TI-6900 del TEC, I Semestre 2026.  
No distribuir fuera del grupo sin autorización del profesor.
