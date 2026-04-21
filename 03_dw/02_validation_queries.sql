-- =============================================================================
-- Proyecto 01 BI — Archivo: 02_validation_queries.sql
-- Propósito: Validar la correctitud de las cargas tras la ejecucion de los
--            pipelines de Data Fusion sobre BigQuery.
-- =============================================================================
-- Reemplace {PROJECT_ID} por el identificador real del proyecto GCP.

-- =============================================================================
-- V1. Conteo de filas por tabla
-- =============================================================================
SELECT 'dim_tiempo'        AS tabla, COUNT(*) AS filas FROM `{PROJECT_ID}.dw_supermercado.dim_tiempo`
UNION ALL SELECT 'dim_producto',      COUNT(*) FROM `{PROJECT_ID}.dw_supermercado.dim_producto`
UNION ALL SELECT 'dim_cliente',       COUNT(*) FROM `{PROJECT_ID}.dw_supermercado.dim_cliente`
UNION ALL SELECT 'dim_sucursal',      COUNT(*) FROM `{PROJECT_ID}.dw_supermercado.dim_sucursal`
UNION ALL SELECT 'dim_metodoPago',    COUNT(*) FROM `{PROJECT_ID}.dw_supermercado.dim_metodoPago`
UNION ALL SELECT 'dim_promocion',     COUNT(*) FROM `{PROJECT_ID}.dw_supermercado.dim_promocion`
UNION ALL SELECT 'dim_canal',         COUNT(*) FROM `{PROJECT_ID}.dw_supermercado.dim_canal`
UNION ALL SELECT 'hechos_ventas',     COUNT(*) FROM `{PROJECT_ID}.dw_supermercado.hechos_ventas`
UNION ALL SELECT 'hechos_inventario', COUNT(*) FROM `{PROJECT_ID}.dw_supermercado.hechos_inventario`
ORDER BY tabla;

-- Valores esperados (aproximados):
-- dim_tiempo         ~1 461   (365 dias * 4 anios)
-- dim_producto         800
-- dim_cliente        5 001    (5 000 reales + 1 subrogado)
-- dim_sucursal          15
-- dim_metodoPago         5
-- dim_promocion        61     (60 reales + 1 subrogado)
-- dim_canal              3
-- hechos_ventas    ~75 000
-- hechos_inventario ~12 000

-- =============================================================================
-- V2. Integridad referencial — cero huerfanos
-- =============================================================================
-- Todas estas queries deben retornar 0

SELECT COUNT(*) AS huerfanos_producto_en_ventas
FROM `{PROJECT_ID}.dw_supermercado.hechos_ventas` h
LEFT JOIN `{PROJECT_ID}.dw_supermercado.dim_producto` p
  ON h.id_producto = p.id_producto_sk
WHERE p.id_producto_sk IS NULL;

SELECT COUNT(*) AS huerfanos_cliente_en_ventas
FROM `{PROJECT_ID}.dw_supermercado.hechos_ventas` h
LEFT JOIN `{PROJECT_ID}.dw_supermercado.dim_cliente` c
  ON h.id_cliente = c.id_cliente_sk
WHERE c.id_cliente_sk IS NULL;

SELECT COUNT(*) AS huerfanos_sucursal_en_ventas
FROM `{PROJECT_ID}.dw_supermercado.hechos_ventas` h
LEFT JOIN `{PROJECT_ID}.dw_supermercado.dim_sucursal` s
  ON h.id_sucursal = s.id_sucursal_sk
WHERE s.id_sucursal_sk IS NULL;

SELECT COUNT(*) AS huerfanos_tiempo_en_ventas
FROM `{PROJECT_ID}.dw_supermercado.hechos_ventas` h
LEFT JOIN `{PROJECT_ID}.dw_supermercado.dim_tiempo` t
  ON h.id_tiempo = t.id_tiempo
WHERE t.id_tiempo IS NULL;

SELECT COUNT(*) AS huerfanos_producto_en_inventario
FROM `{PROJECT_ID}.dw_supermercado.hechos_inventario` h
LEFT JOIN `{PROJECT_ID}.dw_supermercado.dim_producto` p
  ON h.id_producto = p.id_producto_sk
WHERE p.id_producto_sk IS NULL;

-- =============================================================================
-- V3. Consistencia monetaria
-- =============================================================================
-- Debe retornar 0: lineas donde monto_total no coincide con el calculo esperado
SELECT COUNT(*) AS lineas_inconsistentes
FROM `{PROJECT_ID}.dw_supermercado.hechos_ventas`
WHERE ABS(monto_total - ((cantidad_vendida * precio_unitario) - descuento)) > 0.02;

-- Debe retornar 0: margenes mal calculados
SELECT COUNT(*) AS margenes_incorrectos
FROM `{PROJECT_ID}.dw_supermercado.hechos_ventas`
WHERE ABS(margen - (monto_total - costo)) > 0.02;

-- =============================================================================
-- V4. Distribucion de datos (sanidad de negocio)
-- =============================================================================
-- Ventas por anio y trimestre
SELECT t.anio, t.trimestre,
       COUNT(*) AS lineas_venta,
       ROUND(SUM(h.monto_total), 2) AS total_vendido
FROM `{PROJECT_ID}.dw_supermercado.hechos_ventas` h
JOIN `{PROJECT_ID}.dw_supermercado.dim_tiempo` t
  ON h.id_tiempo = t.id_tiempo
GROUP BY t.anio, t.trimestre
ORDER BY t.anio, t.trimestre;

-- Top 10 categorias por ventas (responde pregunta 1 del negocio)
SELECT p.categoria,
       COUNT(*) AS lineas,
       ROUND(SUM(h.monto_total), 2) AS total_vendido,
       ROUND(SUM(h.margen), 2)      AS margen_total,
       ROUND(AVG(h.monto_total), 2) AS ticket_promedio
FROM `{PROJECT_ID}.dw_supermercado.hechos_ventas` h
JOIN `{PROJECT_ID}.dw_supermercado.dim_producto` p ON h.id_producto = p.id_producto_sk
GROUP BY p.categoria
ORDER BY total_vendido DESC
LIMIT 10;

-- Distribucion por canal (responde pregunta adicional)
SELECT c.tipo_canal,
       COUNT(DISTINCT h.id_venta) AS transacciones,
       ROUND(AVG(h.monto_total), 2) AS ticket_promedio_linea
FROM `{PROJECT_ID}.dw_supermercado.hechos_ventas` h
JOIN `{PROJECT_ID}.dw_supermercado.dim_canal` c ON h.id_canal = c.id_canal_sk
GROUP BY c.tipo_canal
ORDER BY ticket_promedio_linea DESC;

-- Metodos de pago por franja horaria (responde pregunta 3)
SELECT h.franja_horaria, mp.tipo_pago,
       COUNT(*) AS transacciones
FROM `{PROJECT_ID}.dw_supermercado.hechos_ventas` h
JOIN `{PROJECT_ID}.dw_supermercado.dim_metodoPago` mp ON h.id_metodoPago = mp.id_metodoPago_sk
GROUP BY h.franja_horaria, mp.tipo_pago
ORDER BY h.franja_horaria, transacciones DESC;

-- Productos con riesgo de quiebre (responde pregunta 4)
SELECT p.nombre_producto, s.nombre_sucursal,
       COUNT(*) AS dias_en_quiebre,
       AVG(h.stock_actual) AS stock_promedio,
       AVG(h.stock_minimo) AS stock_minimo_promedio
FROM `{PROJECT_ID}.dw_supermercado.hechos_inventario` h
JOIN `{PROJECT_ID}.dw_supermercado.dim_producto` p ON h.id_producto = p.id_producto_sk
JOIN `{PROJECT_ID}.dw_supermercado.dim_sucursal` s ON h.id_sucursal = s.id_sucursal_sk
WHERE h.indicador_quiebre = 1
GROUP BY p.nombre_producto, s.nombre_sucursal
ORDER BY dias_en_quiebre DESC
LIMIT 20;

-- Promociones mas efectivas (responde pregunta 2)
SELECT pr.descripcion, pr.tipo_promocion, pr.porcentaje_descuento,
       COUNT(*) AS lineas_con_promo,
       ROUND(SUM(h.cantidad_vendida), 0) AS unidades_vendidas,
       ROUND(AVG(h.monto_total), 2)      AS ticket_promedio
FROM `{PROJECT_ID}.dw_supermercado.hechos_ventas` h
JOIN `{PROJECT_ID}.dw_supermercado.dim_promocion` pr ON h.id_promocion = pr.id_promocion_sk
WHERE pr.id_promocion_sk <> -1
GROUP BY pr.descripcion, pr.tipo_promocion, pr.porcentaje_descuento
ORDER BY unidades_vendidas DESC
LIMIT 15;

-- =============================================================================
-- V5. Verificacion de filas subrogadas
-- =============================================================================
SELECT 'cliente_subrogado' AS verificacion,
       IF(COUNT(*) = 1, 'OK', 'ERROR') AS resultado
FROM `{PROJECT_ID}.dw_supermercado.dim_cliente`
WHERE id_cliente_sk = -1
UNION ALL
SELECT 'promocion_subrogada',
       IF(COUNT(*) = 1, 'OK', 'ERROR')
FROM `{PROJECT_ID}.dw_supermercado.dim_promocion`
WHERE id_promocion_sk = -1;

-- =============================================================================
-- V6. Cobertura del rango de fechas
-- =============================================================================
SELECT MIN(t.fecha) AS fecha_min,
       MAX(t.fecha) AS fecha_max,
       COUNT(*)     AS dias_totales
FROM `{PROJECT_ID}.dw_supermercado.dim_tiempo` t;
-- Esperado: fecha_min = 2023-01-01, fecha_max >= 2026-12-31, dias >= 1 461

-- Fin de 02_validation_queries.sql
