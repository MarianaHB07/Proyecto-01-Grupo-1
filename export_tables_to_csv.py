"""
============================================================================
Proyecto 01 BI — TI-6900 — Grupo 1
Archivo: export_tables_to_csv.py
Propósito: Exportar las 16 tablas del OLTP a archivos CSV individuales,
           listos para subir a Google Cloud Storage.
Autor: Danny Cordero Arrieta (2023042387)
============================================================================

Uso:
    python export_tables_to_csv.py

Los CSVs se guardan en la carpeta csv_exports/ junto a este script.
Cada archivo se nombra igual que la tabla: tb_provincia.csv, tb_producto.csv, etc.

Formato de salida:
    - Separador: coma (,)
    - Encabezados: sí (primera fila son los nombres de columna)
    - Encoding: UTF-8
    - Valores NULL: cadena vacía
"""

import os
import csv
import psycopg2
from pathlib import Path

# ---------------------------------------------------------------------------
# Configuración de conexión (misma que generate_oltp_data.py)
# ---------------------------------------------------------------------------
DB_CONFIG = {
    "host":     os.getenv("PGHOST",     "localhost"),
    "port":     int(os.getenv("PGPORT", 5432)),
    "database": os.getenv("PGDATABASE", "supermercado_oltp"),
    "user":     os.getenv("PGUSER",     "postgres"),
    "password": os.getenv("PGPASSWORD", "1234"),
}

SCHEMA = "sm"

# Las 16 tablas en orden lógico (dimensiones primero, hechos después)
TABLAS = [
    "tb_provincia",
    "tb_sucursal",
    "tb_categoria",
    "tb_subcategoria",
    "tb_marca",
    "tb_proveedor",
    "tb_producto",
    "tb_programa_lealtad",
    "tb_cliente",
    "tb_canal_venta",
    "tb_metodo_pago",
    "tb_promocion",
    "tb_promocion_producto",
    "tb_venta_cabecera",
    "tb_venta_detalle",
    "tb_inventario",
]

# ---------------------------------------------------------------------------
# Exportación
# ---------------------------------------------------------------------------
def export_table(cur, tabla, output_dir):
    """Exporta una tabla completa a CSV con encabezados."""
    filepath = output_dir / f"{tabla}.csv"

    # Obtener nombres de columnas
    cur.execute(f"""
        SELECT column_name
        FROM information_schema.columns
        WHERE table_schema = '{SCHEMA}' AND table_name = '{tabla}'
        ORDER BY ordinal_position;
    """)
    columnas = [row[0] for row in cur.fetchall()]

    # Obtener todos los datos
    cur.execute(f"SELECT * FROM {SCHEMA}.{tabla} ORDER BY 1;")
    filas = cur.fetchall()

    # Escribir CSV
    with open(filepath, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(columnas)  # encabezados
        for fila in filas:
            # Convertir None a cadena vacía para compatibilidad con BigQuery
            writer.writerow(["" if v is None else v for v in fila])

    return len(filas)


def main():
    # Crear carpeta de salida
    script_dir = Path(__file__).parent
    output_dir = script_dir / "csv_exports"
    output_dir.mkdir(exist_ok=True)

    print(f"Conectando a {DB_CONFIG['host']}:{DB_CONFIG['port']}/{DB_CONFIG['database']} ...")
    conn = psycopg2.connect(**DB_CONFIG)
    cur = conn.cursor()
    cur.execute(f"SET search_path TO {SCHEMA}, public;")

    print(f"Exportando 16 tablas a: {output_dir}\n")

    total_filas = 0
    print(f"{'Tabla':<25}  {'Filas':>8}  Archivo")
    print("-" * 60)

    for tabla in TABLAS:
        n = export_table(cur, tabla, output_dir)
        total_filas += n
        print(f"{tabla:<25}  {n:>8,}  {tabla}.csv")

    print("-" * 60)
    print(f"{'TOTAL':<25}  {total_filas:>8,}  ({len(TABLAS)} archivos CSV)")

    cur.close()
    conn.close()

    print(f"\n=== EXPORTACIÓN COMPLETA ===")
    print(f"Carpeta: {output_dir}")
    print(f"\nPróximo paso: sube la carpeta csv_exports/ a Cloud Storage:")
    print(f"  gsutil -m cp csv_exports/*.csv gs://TU_BUCKET/oltp_exports/")


if __name__ == "__main__":
    main()
