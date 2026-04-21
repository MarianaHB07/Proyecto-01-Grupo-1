-- =============================================================================
-- Proyecto 01 BI — Archivo: 02_drop_all.sql
-- Propósito: Eliminar todas las tablas del OLTP en orden inverso de dependencias.
-- ATENCIÓN: este script destruye datos. Úselo solo en entornos de desarrollo.
-- =============================================================================

SET search_path TO sm, public;

DROP TABLE IF EXISTS tb_inventario           CASCADE;
DROP TABLE IF EXISTS tb_venta_detalle        CASCADE;
DROP TABLE IF EXISTS tb_venta_cabecera       CASCADE;
DROP TABLE IF EXISTS tb_promocion_producto   CASCADE;
DROP TABLE IF EXISTS tb_promocion            CASCADE;
DROP TABLE IF EXISTS tb_metodo_pago          CASCADE;
DROP TABLE IF EXISTS tb_canal_venta          CASCADE;
DROP TABLE IF EXISTS tb_cliente              CASCADE;
DROP TABLE IF EXISTS tb_programa_lealtad     CASCADE;
DROP TABLE IF EXISTS tb_producto             CASCADE;
DROP TABLE IF EXISTS tb_proveedor            CASCADE;
DROP TABLE IF EXISTS tb_marca                CASCADE;
DROP TABLE IF EXISTS tb_subcategoria         CASCADE;
DROP TABLE IF EXISTS tb_categoria            CASCADE;
DROP TABLE IF EXISTS tb_sucursal             CASCADE;
DROP TABLE IF EXISTS tb_provincia            CASCADE;

-- Opcional: eliminar el schema completo
-- DROP SCHEMA IF EXISTS sm CASCADE;
