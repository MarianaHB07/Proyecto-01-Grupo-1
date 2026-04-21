-- =============================================================================
-- Proyecto 01 BI — TI-6900 — Grupo 1
-- Archivo: 01_create_dw_schema.sql — VERSION FINAL CORREGIDA
-- =============================================================================

-- =============================================================================
-- 1. DATASETS
-- =============================================================================
CREATE SCHEMA IF NOT EXISTS `proyectobi-493618.stg_supermercado`
OPTIONS (
  location = "US",
  description = "Area de staging: datos ya extraidos y tipados, previo a reglas dimensionales."
);

CREATE SCHEMA IF NOT EXISTS `proyectobi-493618.dw_supermercado`
OPTIONS (
  location = "US",
  description = "Data Warehouse dimensional: 7 dimensiones + 2 tablas de hechos."
);

-- =============================================================================
-- 2. DIMENSIONES
-- =============================================================================

CREATE OR REPLACE TABLE `proyectobi-493618.dw_supermercado.dim_tiempo` (
  id_tiempo        INT64   NOT NULL,
  fecha            DATE    NOT NULL,
  dia              INT64   NOT NULL,
  mes              INT64   NOT NULL,
  nombre_mes       STRING  NOT NULL,
  trimestre        STRING  NOT NULL,
  anio             INT64   NOT NULL,
  dia_semana       STRING  NOT NULL,
  franja_horaria   STRING
)
OPTIONS (description = "Dimension de tiempo con granularidad diaria");

CREATE OR REPLACE TABLE `proyectobi-493618.dw_supermercado.dim_producto` (
  id_producto_sk    INT64          NOT NULL,
  id_producto_nk    INT64          NOT NULL,
  codigo_barras     STRING,
  nombre_producto   STRING         NOT NULL,
  categoria         STRING         NOT NULL,
  subcategoria      STRING         NOT NULL,
  marca             STRING         NOT NULL,
  tipo_marca        STRING         NOT NULL,
  precio_unitario   NUMERIC(12,2)  NOT NULL,
  unidad_medida     STRING         NOT NULL
)
OPTIONS (description = "Dimension de producto con jerarquia categoria -> subcategoria -> marca desnormalizada");

CREATE OR REPLACE TABLE `proyectobi-493618.dw_supermercado.dim_cliente` (
  id_cliente_sk     INT64    NOT NULL,
  id_cliente_nk     INT64,
  nombre_completo   STRING   NOT NULL,
  genero            STRING   NOT NULL,
  edad              INT64,
  rango_edad        STRING   NOT NULL,
  tipo_cliente      STRING   NOT NULL,
  fecha_afiliacion  DATE,
  nivel_lealtad     STRING   NOT NULL
)
OPTIONS (description = "Dimension de cliente; incluye fila subrogada (-1) para ventas anonimas");

CREATE OR REPLACE TABLE `proyectobi-493618.dw_supermercado.dim_sucursal` (
  id_sucursal_sk    INT64   NOT NULL,
  id_sucursal_nk    INT64   NOT NULL,
  nombre_sucursal   STRING  NOT NULL,
  direccion         STRING,
  provincia         STRING  NOT NULL,
  region            STRING  NOT NULL
)
OPTIONS (description = "Dimension de sucursal con jerarquia geografica");

CREATE OR REPLACE TABLE `proyectobi-493618.dw_supermercado.dim_metodoPago` (
  id_metodoPago_sk  INT64   NOT NULL,
  id_metodoPago_nk  INT64   NOT NULL,
  tipo_pago         STRING  NOT NULL
)
OPTIONS (description = "Dimension de metodos de pago");

CREATE OR REPLACE TABLE `proyectobi-493618.dw_supermercado.dim_promocion` (
  id_promocion_sk       INT64         NOT NULL,
  id_promocion_nk       INT64,
  tipo_promocion        STRING        NOT NULL,
  descripcion           STRING        NOT NULL,
  fecha_inicio          DATE,
  fecha_fin             DATE,
  porcentaje_descuento  NUMERIC(5,2)
)
OPTIONS (description = "Dimension de promociones; incluye fila subrogada (-1) para ventas sin promocion");

CREATE OR REPLACE TABLE `proyectobi-493618.dw_supermercado.dim_canal` (
  id_canal_sk       INT64   NOT NULL,
  id_canal_nk       INT64   NOT NULL,
  tipo_canal        STRING  NOT NULL
)
OPTIONS (description = "Dimension de canal de venta");

-- =============================================================================
-- 3. TABLAS DE HECHOS
-- =============================================================================

CREATE OR REPLACE TABLE `proyectobi-493618.dw_supermercado.hechos_ventas` (
  id_venta           INT64          NOT NULL,
  id_tiempo          INT64          NOT NULL,
  fecha_venta        DATE           NOT NULL,
  id_producto        INT64          NOT NULL,
  id_cliente         INT64          NOT NULL,
  id_sucursal        INT64          NOT NULL,
  id_promocion       INT64          NOT NULL,
  id_metodoPago      INT64          NOT NULL,
  id_canal           INT64          NOT NULL,
  franja_horaria     STRING         NOT NULL,
  cantidad_vendida   INT64          NOT NULL,
  precio_unitario    NUMERIC(12,2)  NOT NULL,
  descuento          NUMERIC(12,2)  NOT NULL,
  monto_total        NUMERIC(12,2)  NOT NULL,
  costo              NUMERIC(12,2)  NOT NULL,
  margen             NUMERIC(12,2)  NOT NULL
)
PARTITION BY DATE_TRUNC(fecha_venta, MONTH)
CLUSTER BY id_sucursal, id_producto
OPTIONS (description = "Tabla de hechos de ventas particionada por mes");

CREATE OR REPLACE TABLE `proyectobi-493618.dw_supermercado.hechos_inventario` (
  id_inventario      INT64   NOT NULL,
  id_tiempo          INT64   NOT NULL,
  fecha_snapshot     DATE    NOT NULL,
  id_producto        INT64   NOT NULL,
  id_sucursal        INT64   NOT NULL,
  stock_actual       INT64   NOT NULL,
  stock_minimo       INT64   NOT NULL,
  entradas           INT64   NOT NULL,
  salidas            INT64   NOT NULL,
  indicador_quiebre  INT64   NOT NULL
)
PARTITION BY fecha_snapshot
CLUSTER BY id_sucursal, id_producto
OPTIONS (description = "Snapshot diario de inventario por producto y sucursal");

-- =============================================================================
-- 4. FILAS SUBROGADAS POR DEFECTO
-- =============================================================================

INSERT INTO `proyectobi-493618.dw_supermercado.dim_cliente`
  (id_cliente_sk, id_cliente_nk, nombre_completo, genero, edad,
   rango_edad, tipo_cliente, fecha_afiliacion, nivel_lealtad)
VALUES
  (-1, NULL, 'Cliente sin registro', 'N', NULL,
   'No aplica', 'Ocasional', NULL, 'Sin programa');

INSERT INTO `proyectobi-493618.dw_supermercado.dim_promocion`
  (id_promocion_sk, id_promocion_nk, tipo_promocion, descripcion,
   fecha_inicio, fecha_fin, porcentaje_descuento)
VALUES
  (-1, NULL, 'No aplica', 'Sin promocion',
   NULL, NULL, 0.00);

-- =============================================================================
-- 5. VERIFICACION
-- =============================================================================
SELECT 'Tablas creadas en dw_supermercado' AS info, COUNT(*) AS total
FROM `proyectobi-493618.dw_supermercado.INFORMATION_SCHEMA.TABLES`;