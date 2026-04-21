-- =============================================================================
-- Proyecto 01 BI — TI-6900 — Grupo 1: Cadena de supermercados minoristas
-- Archivo: 01_create_schema.sql
-- Propósito: Crear el esquema transaccional (OLTP) con 16 tablas en PostgreSQL
-- Motor recomendado: PostgreSQL 16 en Cloud SQL
-- Autor: Danny Cordero Arrieta (2023042387)
-- =============================================================================

-- Ejecutar como superusuario conectado a la BD destino.
-- Recomendado: crear una BD dedicada antes de correr este script:
--   CREATE DATABASE supermercado_oltp;
--   \c supermercado_oltp

-- Opcional: schema dedicado para aislar del esquema público
CREATE SCHEMA IF NOT EXISTS sm;
SET search_path TO sm, public;

-- =============================================================================
-- DOMINIO: GEOGRAFÍA
-- =============================================================================

CREATE TABLE tb_provincia (
    id_provincia      SERIAL PRIMARY KEY,
    nombre_provincia  VARCHAR(50)  NOT NULL UNIQUE,
    region            VARCHAR(30)  NOT NULL,
    CONSTRAINT chk_region CHECK (region IN ('Central','Chorotega','Pacifico Central','Brunca','Huetar Atlantica','Huetar Norte'))
);

CREATE TABLE tb_sucursal (
    id_sucursal       SERIAL PRIMARY KEY,
    nombre_sucursal   VARCHAR(80)  NOT NULL,
    direccion         VARCHAR(200) NOT NULL,
    id_provincia      INTEGER      NOT NULL REFERENCES tb_provincia(id_provincia) ON DELETE RESTRICT,
    fecha_apertura    DATE         NOT NULL,
    gerente           VARCHAR(100),
    telefono          VARCHAR(20)
);

-- =============================================================================
-- DOMINIO: CATÁLOGO DE PRODUCTOS
-- =============================================================================

CREATE TABLE tb_categoria (
    id_categoria      SERIAL PRIMARY KEY,
    nombre_categoria  VARCHAR(60)  NOT NULL UNIQUE
);

CREATE TABLE tb_subcategoria (
    id_subcategoria       SERIAL PRIMARY KEY,
    nombre_subcategoria   VARCHAR(80)  NOT NULL,
    id_categoria          INTEGER      NOT NULL REFERENCES tb_categoria(id_categoria) ON DELETE RESTRICT,
    UNIQUE (id_categoria, nombre_subcategoria)
);

CREATE TABLE tb_marca (
    id_marca          SERIAL PRIMARY KEY,
    nombre_marca      VARCHAR(80)  NOT NULL UNIQUE,
    tipo_marca        VARCHAR(20)  NOT NULL,
    CONSTRAINT chk_tipo_marca CHECK (tipo_marca IN ('Comercial','Privada'))
);

CREATE TABLE tb_proveedor (
    id_proveedor      SERIAL PRIMARY KEY,
    nombre_proveedor  VARCHAR(120) NOT NULL UNIQUE,
    telefono          VARCHAR(20),
    correo            VARCHAR(120)
);

CREATE TABLE tb_producto (
    id_producto       SERIAL PRIMARY KEY,
    codigo_barras     VARCHAR(13)   NOT NULL UNIQUE,
    nombre_producto   VARCHAR(150)  NOT NULL,
    id_subcategoria   INTEGER       NOT NULL REFERENCES tb_subcategoria(id_subcategoria) ON DELETE RESTRICT,
    id_marca          INTEGER       NOT NULL REFERENCES tb_marca(id_marca) ON DELETE RESTRICT,
    id_proveedor      INTEGER       NOT NULL REFERENCES tb_proveedor(id_proveedor) ON DELETE RESTRICT,
    precio_unitario   DECIMAL(12,2) NOT NULL CHECK (precio_unitario >= 0),
    costo_unitario    DECIMAL(12,2) NOT NULL CHECK (costo_unitario  >= 0),
    unidad_medida     VARCHAR(10)   NOT NULL DEFAULT 'UN',
    peso_gramos       DECIMAL(10,2),
    activo            BOOLEAN       NOT NULL DEFAULT TRUE,
    CONSTRAINT chk_unidad_medida CHECK (unidad_medida IN ('UN','KG','LT','ML','GR'))
);

-- =============================================================================
-- DOMINIO: CLIENTES
-- =============================================================================

CREATE TABLE tb_programa_lealtad (
    id_programa       SERIAL PRIMARY KEY,
    nombre_programa   VARCHAR(40)  NOT NULL UNIQUE,
    nivel             VARCHAR(20)  NOT NULL,
    fecha_creacion    DATE         NOT NULL,
    CONSTRAINT chk_nivel CHECK (nivel IN ('Basico','Plata','Oro','VIP'))
);

CREATE TABLE tb_cliente (
    id_cliente        SERIAL PRIMARY KEY,
    identificacion    VARCHAR(20)  NOT NULL UNIQUE,
    nombre            VARCHAR(60)  NOT NULL,
    apellido          VARCHAR(80)  NOT NULL,
    genero            CHAR(1)      NOT NULL,
    fecha_nacimiento  DATE         NOT NULL,
    correo            VARCHAR(120),
    telefono          VARCHAR(20),
    id_programa       INTEGER      REFERENCES tb_programa_lealtad(id_programa) ON DELETE SET NULL,
    fecha_afiliacion  DATE,
    tipo_cliente      VARCHAR(15)  NOT NULL DEFAULT 'Ocasional',
    CONSTRAINT chk_genero       CHECK (genero IN ('M','F','N')),
    CONSTRAINT chk_tipo_cliente CHECK (tipo_cliente IN ('Ocasional','Frecuente','VIP'))
);

-- =============================================================================
-- DOMINIO: CANALES Y PAGOS
-- =============================================================================

CREATE TABLE tb_canal_venta (
    id_canal          SERIAL PRIMARY KEY,
    tipo_canal        VARCHAR(30)  NOT NULL UNIQUE,
    CONSTRAINT chk_canal CHECK (tipo_canal IN ('Tienda fisica','Aplicacion movil','Sitio web'))
);

CREATE TABLE tb_metodo_pago (
    id_metodo_pago    SERIAL PRIMARY KEY,
    tipo_pago         VARCHAR(30)  NOT NULL UNIQUE,
    CONSTRAINT chk_tipo_pago CHECK (tipo_pago IN ('Efectivo','Tarjeta debito','Tarjeta credito','SINPE Movil','Billetera digital'))
);

-- =============================================================================
-- DOMINIO: PROMOCIONES
-- =============================================================================

CREATE TABLE tb_promocion (
    id_promocion          SERIAL PRIMARY KEY,
    descripcion           VARCHAR(200) NOT NULL,
    tipo_promocion        VARCHAR(30)  NOT NULL,
    porcentaje_descuento  DECIMAL(5,2) NOT NULL CHECK (porcentaje_descuento BETWEEN 0 AND 100),
    fecha_inicio          DATE         NOT NULL,
    fecha_fin             DATE         NOT NULL,
    CONSTRAINT chk_tipo_promo CHECK (tipo_promocion IN ('Descuento','2x1','Combo','Temporada','Liquidacion')),
    CONSTRAINT chk_fechas_promo CHECK (fecha_fin >= fecha_inicio)
);

CREATE TABLE tb_promocion_producto (
    id_promocion      INTEGER NOT NULL REFERENCES tb_promocion(id_promocion) ON DELETE CASCADE,
    id_producto       INTEGER NOT NULL REFERENCES tb_producto(id_producto)   ON DELETE CASCADE,
    PRIMARY KEY (id_promocion, id_producto)
);

-- =============================================================================
-- DOMINIO: TRANSACCIONAL DE VENTAS
-- =============================================================================

CREATE TABLE tb_venta_cabecera (
    id_venta           SERIAL PRIMARY KEY,
    fecha_hora         TIMESTAMP       NOT NULL,
    id_cliente         INTEGER         REFERENCES tb_cliente(id_cliente) ON DELETE RESTRICT,
    id_sucursal        INTEGER         NOT NULL REFERENCES tb_sucursal(id_sucursal) ON DELETE RESTRICT,
    id_canal           INTEGER         NOT NULL REFERENCES tb_canal_venta(id_canal) ON DELETE RESTRICT,
    id_metodo_pago     INTEGER         NOT NULL REFERENCES tb_metodo_pago(id_metodo_pago) ON DELETE RESTRICT,
    monto_subtotal     DECIMAL(12,2)   NOT NULL CHECK (monto_subtotal  >= 0),
    monto_descuento    DECIMAL(12,2)   NOT NULL DEFAULT 0 CHECK (monto_descuento >= 0),
    monto_total        DECIMAL(12,2)   NOT NULL CHECK (monto_total     >= 0),
    numero_factura     VARCHAR(20)     NOT NULL UNIQUE
);

CREATE TABLE tb_venta_detalle (
    id_detalle              SERIAL PRIMARY KEY,
    id_venta                INTEGER        NOT NULL REFERENCES tb_venta_cabecera(id_venta) ON DELETE CASCADE,
    id_producto             INTEGER        NOT NULL REFERENCES tb_producto(id_producto)    ON DELETE RESTRICT,
    id_promocion            INTEGER        REFERENCES tb_promocion(id_promocion) ON DELETE SET NULL,
    cantidad                INTEGER        NOT NULL CHECK (cantidad > 0),
    precio_unitario_venta   DECIMAL(12,2)  NOT NULL CHECK (precio_unitario_venta >= 0),
    descuento_aplicado      DECIMAL(12,2)  NOT NULL DEFAULT 0 CHECK (descuento_aplicado >= 0),
    subtotal_linea          DECIMAL(12,2)  NOT NULL CHECK (subtotal_linea >= 0)
);

-- =============================================================================
-- DOMINIO: INVENTARIO
-- =============================================================================

CREATE TABLE tb_inventario (
    id_inventario     SERIAL PRIMARY KEY,
    id_producto       INTEGER  NOT NULL REFERENCES tb_producto(id_producto)  ON DELETE RESTRICT,
    id_sucursal       INTEGER  NOT NULL REFERENCES tb_sucursal(id_sucursal)  ON DELETE RESTRICT,
    fecha             DATE     NOT NULL,
    stock_actual      INTEGER  NOT NULL CHECK (stock_actual >= 0),
    stock_minimo      INTEGER  NOT NULL CHECK (stock_minimo >= 0),
    entradas_dia      INTEGER  NOT NULL DEFAULT 0 CHECK (entradas_dia >= 0),
    salidas_dia       INTEGER  NOT NULL DEFAULT 0 CHECK (salidas_dia  >= 0),
    UNIQUE (id_producto, id_sucursal, fecha)
);

-- =============================================================================
-- ÍNDICES SECUNDARIOS
-- =============================================================================
-- Estos índices aceleran las extracciones del ETL sobre columnas filtradas
-- frecuentemente (fechas y llaves foráneas muy selectivas).

CREATE INDEX idx_venta_cab_fecha          ON tb_venta_cabecera (fecha_hora);
CREATE INDEX idx_venta_cab_sucursal       ON tb_venta_cabecera (id_sucursal);
CREATE INDEX idx_venta_cab_cliente        ON tb_venta_cabecera (id_cliente);
CREATE INDEX idx_venta_det_venta          ON tb_venta_detalle  (id_venta);
CREATE INDEX idx_venta_det_producto       ON tb_venta_detalle  (id_producto);
CREATE INDEX idx_venta_det_promocion      ON tb_venta_detalle  (id_promocion);
CREATE INDEX idx_inv_fecha_sucursal       ON tb_inventario     (fecha, id_sucursal);
CREATE INDEX idx_inv_producto             ON tb_inventario     (id_producto);
CREATE INDEX idx_producto_marca           ON tb_producto       (id_marca);
CREATE INDEX idx_producto_subcategoria    ON tb_producto       (id_subcategoria);
CREATE INDEX idx_cliente_programa         ON tb_cliente        (id_programa);
CREATE INDEX idx_sucursal_provincia       ON tb_sucursal       (id_provincia);

-- =============================================================================
-- COMENTARIOS SOBRE LAS TABLAS (autodocumentación)
-- =============================================================================

COMMENT ON TABLE tb_provincia            IS 'Catalogo de provincias con la region geografica a la que pertenecen';
COMMENT ON TABLE tb_sucursal             IS 'Sucursales fisicas de la cadena';
COMMENT ON TABLE tb_categoria            IS 'Nivel 1 de la jerarquia de productos';
COMMENT ON TABLE tb_subcategoria         IS 'Nivel 2 de la jerarquia de productos';
COMMENT ON TABLE tb_marca                IS 'Marcas comerciales y de marca privada';
COMMENT ON TABLE tb_proveedor            IS 'Proveedores que suministran productos a la cadena';
COMMENT ON TABLE tb_producto             IS 'Catalogo maestro de SKUs';
COMMENT ON TABLE tb_programa_lealtad     IS 'Niveles del programa de fidelizacion';
COMMENT ON TABLE tb_cliente              IS 'Clientes registrados con datos demograficos';
COMMENT ON TABLE tb_canal_venta          IS 'Canales habilitados de venta';
COMMENT ON TABLE tb_metodo_pago          IS 'Medios de pago aceptados';
COMMENT ON TABLE tb_promocion            IS 'Campanas promocionales con fechas de vigencia';
COMMENT ON TABLE tb_promocion_producto   IS 'Tabla puente N:M entre promociones y productos';
COMMENT ON TABLE tb_venta_cabecera       IS 'Encabezado de cada transaccion con montos totales';
COMMENT ON TABLE tb_venta_detalle        IS 'Detalle linea por linea de cada venta';
COMMENT ON TABLE tb_inventario           IS 'Snapshot diario por producto y sucursal';

-- =============================================================================
-- VERIFICACION FINAL
-- =============================================================================
-- Confirmar que las 16 tablas existen
DO $$
DECLARE
    total_tablas INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_tablas
    FROM information_schema.tables
    WHERE table_schema = 'sm'
      AND table_type = 'BASE TABLE';

    RAISE NOTICE 'Total de tablas creadas en schema sm: %', total_tablas;

    IF total_tablas <> 16 THEN
        RAISE EXCEPTION 'Se esperaban 16 tablas y se encontraron %', total_tablas;
    END IF;
END $$;

-- Fin de 01_create_schema.sql
