"""
============================================================================
Proyecto 01 BI — TI-6900 — Grupo 1: Cadena de supermercados minoristas
Archivo: generate_oltp_data.py
Propósito: Generar e insertar datos sintéticos en el OLTP PostgreSQL.
Autor: Danny Cordero Arrieta (2023042387)
============================================================================

Volúmenes objetivo (> 100 000 filas totales):
    tb_provincia              7
    tb_sucursal              15
    tb_categoria             12
    tb_subcategoria          45
    tb_marca                 40
    tb_proveedor             25
    tb_producto             800
    tb_programa_lealtad       4
    tb_cliente            5 000
    tb_canal_venta            3
    tb_metodo_pago            5
    tb_promocion             60
    tb_promocion_producto   500
    tb_venta_cabecera    25 000
    tb_venta_detalle     75 000
    tb_inventario        12 000
    ------------------- -------
    Total              118 516

Uso:
    python -m venv venv
    source venv/bin/activate     (en Windows: venv\\Scripts\\activate)
    pip install -r requirements.txt
    # Configure la conexión en la variable DB_CONFIG de abajo o via env vars
    python generate_oltp_data.py

El script es idempotente para la estructura pero NO para los datos:
si corre dos veces, los datos se duplicarán. Para reinsertar, ejecute primero
02_drop_all.sql y luego 01_create_schema.sql antes de correr este script.
"""

import os
import random
import string
from datetime import date, datetime, time, timedelta
from decimal import Decimal, ROUND_HALF_UP

import psycopg2
from psycopg2.extras import execute_values
from faker import Faker

# ---------------------------------------------------------------------------
# Configuración
# ---------------------------------------------------------------------------
SEED = 42
random.seed(SEED)
fake = Faker("es_MX")
Faker.seed(SEED)

DB_CONFIG = {
    "host":     os.getenv("PGHOST",     "localhost"),
    "port":     int(os.getenv("PGPORT", 5432)),
    "database": os.getenv("PGDATABASE", "supermercado_oltp"),
    "user":     os.getenv("PGUSER",     "postgres"),
    "password": os.getenv("PGPASSWORD", "postgres"),
}

SCHEMA       = "sm"
FECHA_INICIO = date(2023, 1, 1)
FECHA_FIN    = date(2025, 12, 31)

# Volúmenes
N_SUCURSALES       = 15
N_CATEGORIAS       = 12
N_SUBCATEGORIAS    = 45
N_MARCAS           = 40
N_PROVEEDORES      = 25
N_PRODUCTOS        = 800
N_CLIENTES         = 5_000
N_PROMOCIONES      = 60
N_PROMO_PRODUCTOS  = 500
N_VENTAS           = 25_000
DIAS_INVENTARIO    = 30
PRODUCTOS_INV      = 400   # subset de productos con snapshot diario

# ---------------------------------------------------------------------------
# Utilidades
# ---------------------------------------------------------------------------
def money(v):
    return Decimal(str(v)).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)


def fecha_random(inicio, fin):
    delta = (fin - inicio).days
    return inicio + timedelta(days=random.randint(0, delta))


def datetime_random(inicio, fin):
    d = fecha_random(inicio, fin)
    hora = random.choices(
        range(0, 24),
        weights=[1, 1, 1, 1, 1, 2, 4, 6, 7, 8, 9, 10,
                 11, 10, 9, 9, 10, 11, 10, 8, 6, 4, 3, 2],
    )[0]
    minuto  = random.randint(0, 59)
    segundo = random.randint(0, 59)
    return datetime.combine(d, time(hora, minuto, segundo))


def factura_aleatoria(n):
    return f"F-{n:08d}"


# ---------------------------------------------------------------------------
# Datos maestros fijos (dominios controlados)
# ---------------------------------------------------------------------------
PROVINCIAS_CR = [
    ("San Jose",     "Central"),
    ("Alajuela",     "Central"),
    ("Cartago",      "Central"),
    ("Heredia",      "Central"),
    ("Guanacaste",   "Chorotega"),
    ("Puntarenas",   "Pacifico Central"),
    ("Limon",        "Huetar Atlantica"),
]

CATEGORIAS = [
    "Abarrotes", "Lacteos", "Carnes y embutidos", "Panaderia",
    "Frutas y verduras", "Bebidas", "Snacks y confiteria",
    "Cuidado personal", "Limpieza del hogar", "Mascotas",
    "Bebe", "Congelados",
]

SUBCATEGORIAS_POR_CATEGORIA = {
    "Abarrotes":              ["Arroz y granos", "Aceites", "Azucar y endulzantes", "Pastas", "Salsas"],
    "Lacteos":                ["Leche liquida", "Leche en polvo", "Quesos", "Yogurt"],
    "Carnes y embutidos":     ["Res", "Cerdo", "Pollo", "Embutidos"],
    "Panaderia":              ["Pan fresco", "Galletas", "Reposteria"],
    "Frutas y verduras":      ["Frutas", "Verduras", "Hierbas"],
    "Bebidas":                ["Gaseosas", "Jugos", "Agua", "Cervezas", "Vinos"],
    "Snacks y confiteria":    ["Chips", "Chocolates", "Caramelos"],
    "Cuidado personal":       ["Higiene bucal", "Cabello", "Corporal"],
    "Limpieza del hogar":     ["Detergentes", "Desinfectantes", "Papel higienico"],
    "Mascotas":               ["Alimento perro", "Alimento gato", "Accesorios"],
    "Bebe":                   ["Panales", "Formulas"],
    "Congelados":             ["Helados", "Comidas preparadas"],
}

CANALES_VENTA = ["Tienda fisica", "Aplicacion movil", "Sitio web"]
METODOS_PAGO  = ["Efectivo", "Tarjeta debito", "Tarjeta credito", "SINPE Movil", "Billetera digital"]

PROGRAMAS_LEALTAD = [
    ("Basico", "Basico"),
    ("Plata",  "Plata"),
    ("Oro",    "Oro"),
    ("VIP",    "VIP"),
]

TIPOS_PROMOCION = ["Descuento", "2x1", "Combo", "Temporada", "Liquidacion"]
UNIDADES_MEDIDA = ["UN", "KG", "LT", "ML", "GR"]
GENEROS         = ["M", "F", "N"]
TIPOS_CLIENTE   = ["Ocasional", "Frecuente", "VIP"]


# ---------------------------------------------------------------------------
# Generadores por tabla
# ---------------------------------------------------------------------------
def gen_provincias():
    return [(nombre, region) for nombre, region in PROVINCIAS_CR]


def gen_sucursales(provincia_ids):
    rows = []
    for i in range(1, N_SUCURSALES + 1):
        nombre   = f"Sucursal {i:02d} - {fake.street_name()[:30]}"
        direccion = fake.address().replace("\n", ", ")[:200]
        id_prov  = random.choice(provincia_ids)
        apertura = fecha_random(date(2010, 1, 1), date(2022, 12, 31))
        gerente  = fake.name()[:100]
        telefono = fake.phone_number()[:20]
        rows.append((nombre, direccion, id_prov, apertura, gerente, telefono))
    return rows


def gen_categorias():
    return [(c,) for c in CATEGORIAS]


def gen_subcategorias(categoria_id_by_name):
    rows = []
    for cat, subs in SUBCATEGORIAS_POR_CATEGORIA.items():
        for sub in subs:
            rows.append((sub, categoria_id_by_name[cat]))
    while len(rows) < N_SUBCATEGORIAS:
        cat = random.choice(list(categoria_id_by_name.keys()))
        rows.append((f"{random.choice(['Premium','Extra','Nueva'])} {cat} {len(rows)}", categoria_id_by_name[cat]))
    return rows[:N_SUBCATEGORIAS]


def gen_marcas():
    nombres = set()
    while len(nombres) < N_MARCAS - 5:
        nombres.add(fake.company()[:60])
    marcas = [(n, "Comercial") for n in nombres]
    for i in range(1, 6):
        marcas.append((f"MP SuperFresh {i}", "Privada"))
    random.shuffle(marcas)
    return marcas[:N_MARCAS]


def gen_proveedores():
    nombres = set()
    while len(nombres) < N_PROVEEDORES:
        nombres.add(fake.company()[:120])
    return [(n, fake.phone_number()[:20], fake.company_email()[:120]) for n in nombres]


def gen_productos(subcategoria_ids, marca_ids, proveedor_ids):
    rows = []
    barcodes = set()
    while len(rows) < N_PRODUCTOS:
        bc = "".join(random.choices(string.digits, k=13))
        if bc in barcodes:
            continue
        barcodes.add(bc)
        nombre         = fake.catch_phrase()[:150]
        id_sub         = random.choice(subcategoria_ids)
        id_marca       = random.choice(marca_ids)
        id_proveedor   = random.choice(proveedor_ids)
        costo          = money(random.uniform(200, 15000))
        precio         = money(float(costo) * random.uniform(1.20, 1.80))
        unidad         = random.choice(UNIDADES_MEDIDA)
        peso           = money(random.uniform(50, 2500))
        activo         = random.random() > 0.02
        rows.append((bc, nombre, id_sub, id_marca, id_proveedor,
                     precio, costo, unidad, peso, activo))
    return rows


def gen_programas_lealtad():
    hoy = date(2022, 1, 1)
    return [(nom, niv, hoy) for nom, niv in PROGRAMAS_LEALTAD]


def gen_clientes(programa_ids):
    rows = []
    identificaciones = set()
    while len(rows) < N_CLIENTES:
        ident = "".join(random.choices(string.digits, k=9))
        if ident in identificaciones:
            continue
        identificaciones.add(ident)
        genero   = random.choice(GENEROS)
        nombre   = fake.first_name_male() if genero == "M" else fake.first_name_female() if genero == "F" else fake.first_name()
        apellido = f"{fake.last_name()} {fake.last_name()}"
        nacimiento = fecha_random(date(1950, 1, 1), date(2006, 12, 31))
        correo   = fake.email()[:120]
        telefono = fake.phone_number()[:20]
        # Segmentacion: 20% VIP, 35% Frecuente, 45% Ocasional
        r = random.random()
        if   r < 0.20: tipo_cli = "VIP"
        elif r < 0.55: tipo_cli = "Frecuente"
        else:          tipo_cli = "Ocasional"
        # 70% tienen programa de lealtad
        if random.random() < 0.70:
            id_prog = random.choice(programa_ids)
            fecha_afi = fecha_random(date(2022, 1, 1), FECHA_FIN)
        else:
            id_prog   = None
            fecha_afi = None
        rows.append((ident, nombre[:60], apellido[:80], genero, nacimiento,
                     correo, telefono, id_prog, fecha_afi, tipo_cli))
    return rows


def gen_canales():
    return [(c,) for c in CANALES_VENTA]


def gen_metodos_pago():
    return [(m,) for m in METODOS_PAGO]


def gen_promociones():
    rows = []
    for _ in range(N_PROMOCIONES):
        tipo    = random.choice(TIPOS_PROMOCION)
        desc    = f"{tipo} {fake.word()} {random.randint(5, 50)}"[:200]
        pct     = money(random.choice([5, 10, 15, 20, 25, 30, 40, 50]))
        inicio  = fecha_random(FECHA_INICIO, FECHA_FIN - timedelta(days=30))
        fin     = inicio + timedelta(days=random.randint(7, 60))
        rows.append((desc, tipo, pct, inicio, fin))
    return rows


def gen_promocion_producto(promocion_ids, producto_ids):
    parejas = set()
    while len(parejas) < N_PROMO_PRODUCTOS:
        parejas.add((random.choice(promocion_ids), random.choice(producto_ids)))
    return list(parejas)


def gen_ventas(cliente_ids, sucursal_ids, canal_ids, metodo_pago_ids,
               producto_info, promocion_info):
    """
    producto_info: dict id_producto -> (precio, costo)
    promocion_info: dict id_producto -> list of (id_promocion, pct, fecha_inicio, fecha_fin)
    """
    cabeceras   = []
    detalles    = []
    factura_n   = 1
    product_ids = list(producto_info.keys())

    # Pesos por canal: 75% fisica, 15% app, 10% web
    canal_pesos = [0.75, 0.15, 0.10]
    # Pesos por método de pago
    metodo_pesos = [0.30, 0.30, 0.25, 0.10, 0.05]

    for v in range(1, N_VENTAS + 1):
        fecha_hora = datetime_random(FECHA_INICIO, FECHA_FIN)
        # Clientes anónimos ~15%
        id_cliente = random.choice(cliente_ids) if random.random() > 0.15 else None
        id_sucursal = random.choice(sucursal_ids)
        id_canal   = random.choices(canal_ids, weights=canal_pesos)[0]
        id_metodo  = random.choices(metodo_pago_ids, weights=metodo_pesos)[0]

        n_lineas = random.choices([1, 2, 3, 4, 5, 6, 7, 8],
                                  weights=[10, 20, 20, 15, 12, 10, 8, 5])[0]
        subtotal    = Decimal("0")
        descuento_t = Decimal("0")
        lineas_tmp  = []
        productos_en_venta = random.sample(product_ids, n_lineas)

        for id_prod in productos_en_venta:
            precio, costo = producto_info[id_prod]
            cantidad = random.choices([1, 2, 3, 4, 5], weights=[40, 25, 15, 12, 8])[0]
            base     = Decimal(cantidad) * precio
            # Revisar si hay promo vigente para este producto en esta fecha
            id_promo = None
            descuento_linea = Decimal("0")
            promos = promocion_info.get(id_prod, [])
            for p_id, pct, p_ini, p_fin in promos:
                if p_ini <= fecha_hora.date() <= p_fin:
                    id_promo = p_id
                    descuento_linea = money(base * pct / Decimal("100"))
                    break
            subtotal_linea = money(base - descuento_linea)
            lineas_tmp.append((id_prod, id_promo, cantidad, precio,
                               descuento_linea, subtotal_linea))
            subtotal    += base
            descuento_t += descuento_linea

        monto_total = money(subtotal - descuento_t)
        subtotal    = money(subtotal)
        descuento_t = money(descuento_t)

        cabeceras.append((fecha_hora, id_cliente, id_sucursal, id_canal,
                          id_metodo, subtotal, descuento_t, monto_total,
                          factura_aleatoria(factura_n)))
        # Los detalles se enlazarán al id_venta tras insertar la cabecera
        detalles.append(lineas_tmp)
        factura_n += 1

    return cabeceras, detalles


def gen_inventario(producto_ids, sucursal_ids):
    rows = []
    # Últimos DIAS_INVENTARIO
    fecha_base = FECHA_FIN
    productos_seleccionados = random.sample(producto_ids, min(PRODUCTOS_INV, len(producto_ids)))
    combinaciones = random.sample(
        [(p, s) for p in productos_seleccionados for s in sucursal_ids],
        min(N_PRODUCTOS_INV := 400, len(producto_ids) * len(sucursal_ids))
    )
    for d in range(DIAS_INVENTARIO):
        fecha = fecha_base - timedelta(days=d)
        for (p, s) in combinaciones:
            stock_min = random.randint(5, 30)
            # 5% de los registros con quiebre
            if random.random() < 0.05:
                stock_actual = random.randint(0, stock_min - 1)
            else:
                stock_actual = random.randint(stock_min, stock_min + 200)
            entradas = random.randint(0, 50)
            salidas  = random.randint(0, 60)
            rows.append((p, s, fecha, stock_actual, stock_min, entradas, salidas))
    return rows


# ---------------------------------------------------------------------------
# Helpers de inserción
# ---------------------------------------------------------------------------
def bulk_insert(cur, tabla, columnas, valores, returning=None, page_size=1000):
    cols = ", ".join(columnas)
    if returning:
        sql = f"INSERT INTO {SCHEMA}.{tabla} ({cols}) VALUES %s RETURNING {returning}"
        results = execute_values(cur, sql, valores, page_size=page_size, fetch=True)
        return [r[0] for r in results]
    else:
        sql = f"INSERT INTO {SCHEMA}.{tabla} ({cols}) VALUES %s"
        execute_values(cur, sql, valores, page_size=page_size)
        return None


# ---------------------------------------------------------------------------
# Ejecución principal
# ---------------------------------------------------------------------------
def main():
    print(f"Conectando a {DB_CONFIG['host']}:{DB_CONFIG['port']}/{DB_CONFIG['database']} ...")
    conn = psycopg2.connect(**DB_CONFIG)
    conn.autocommit = False
    cur  = conn.cursor()
    cur.execute(f"SET search_path TO {SCHEMA}, public;")

    try:
        # 1. Provincias
        print("Insertando tb_provincia ...")
        prov_ids = bulk_insert(cur, "tb_provincia",
                               ["nombre_provincia", "region"],
                               gen_provincias(), returning="id_provincia")

        # 2. Sucursales
        print("Insertando tb_sucursal ...")
        suc_ids = bulk_insert(cur, "tb_sucursal",
                              ["nombre_sucursal", "direccion", "id_provincia",
                               "fecha_apertura", "gerente", "telefono"],
                              gen_sucursales(prov_ids), returning="id_sucursal")

        # 3. Categorias
        print("Insertando tb_categoria ...")
        cat_rows = gen_categorias()
        cat_ids  = bulk_insert(cur, "tb_categoria",
                               ["nombre_categoria"], cat_rows, returning="id_categoria")
        cat_name_to_id = {cat_rows[i][0]: cat_ids[i] for i in range(len(cat_rows))}

        # 4. Subcategorias
        print("Insertando tb_subcategoria ...")
        sub_ids = bulk_insert(cur, "tb_subcategoria",
                              ["nombre_subcategoria", "id_categoria"],
                              gen_subcategorias(cat_name_to_id), returning="id_subcategoria")

        # 5. Marcas
        print("Insertando tb_marca ...")
        marca_ids = bulk_insert(cur, "tb_marca",
                                ["nombre_marca", "tipo_marca"],
                                gen_marcas(), returning="id_marca")

        # 6. Proveedores
        print("Insertando tb_proveedor ...")
        prov_p_ids = bulk_insert(cur, "tb_proveedor",
                                 ["nombre_proveedor", "telefono", "correo"],
                                 gen_proveedores(), returning="id_proveedor")

        # 7. Productos
        print("Insertando tb_producto ...")
        prod_rows = gen_productos(sub_ids, marca_ids, prov_p_ids)
        prod_ids  = bulk_insert(cur, "tb_producto",
                                ["codigo_barras", "nombre_producto", "id_subcategoria",
                                 "id_marca", "id_proveedor", "precio_unitario",
                                 "costo_unitario", "unidad_medida", "peso_gramos", "activo"],
                                prod_rows, returning="id_producto")
        # Diccionario id_producto -> (precio, costo)
        producto_info = {
            prod_ids[i]: (prod_rows[i][5], prod_rows[i][6]) for i in range(len(prod_ids))
        }

        # 8. Programas de lealtad
        print("Insertando tb_programa_lealtad ...")
        programa_ids = bulk_insert(cur, "tb_programa_lealtad",
                                   ["nombre_programa", "nivel", "fecha_creacion"],
                                   gen_programas_lealtad(), returning="id_programa")

        # 9. Clientes
        print("Insertando tb_cliente ...")
        cli_ids = bulk_insert(cur, "tb_cliente",
                              ["identificacion", "nombre", "apellido", "genero",
                               "fecha_nacimiento", "correo", "telefono", "id_programa",
                               "fecha_afiliacion", "tipo_cliente"],
                              gen_clientes(programa_ids), returning="id_cliente")

        # 10. Canales
        print("Insertando tb_canal_venta ...")
        canal_ids = bulk_insert(cur, "tb_canal_venta",
                                ["tipo_canal"], gen_canales(), returning="id_canal")

        # 11. Metodos de pago
        print("Insertando tb_metodo_pago ...")
        metodo_ids = bulk_insert(cur, "tb_metodo_pago",
                                 ["tipo_pago"], gen_metodos_pago(), returning="id_metodo_pago")

        # 12. Promociones
        print("Insertando tb_promocion ...")
        promo_rows = gen_promociones()
        promo_ids  = bulk_insert(cur, "tb_promocion",
                                 ["descripcion", "tipo_promocion", "porcentaje_descuento",
                                  "fecha_inicio", "fecha_fin"],
                                 promo_rows, returning="id_promocion")

        # 13. Promocion-producto (bridge)
        print("Insertando tb_promocion_producto ...")
        pp_rows = gen_promocion_producto(promo_ids, prod_ids)
        bulk_insert(cur, "tb_promocion_producto",
                    ["id_promocion", "id_producto"], pp_rows)

        # Dict de promos por producto para las ventas
        promocion_info = {}
        for i, p_id in enumerate(promo_ids):
            _, _, pct, f_ini, f_fin = promo_rows[i]
            for (pp_promo, pp_prod) in pp_rows:
                if pp_promo == p_id:
                    promocion_info.setdefault(pp_prod, []).append(
                        (p_id, pct, f_ini, f_fin)
                    )

        # 14 y 15. Ventas (cabecera y detalle)
        print("Generando ventas (puede tardar) ...")
        cabeceras, detalles = gen_ventas(cli_ids, suc_ids, canal_ids, metodo_ids,
                                         producto_info, promocion_info)
        print("Insertando tb_venta_cabecera ...")
        venta_ids = bulk_insert(cur, "tb_venta_cabecera",
                                ["fecha_hora", "id_cliente", "id_sucursal", "id_canal",
                                 "id_metodo_pago", "monto_subtotal", "monto_descuento",
                                 "monto_total", "numero_factura"],
                                cabeceras, returning="id_venta", page_size=5000)

        # Armar los detalles con el id_venta correcto
        print("Insertando tb_venta_detalle ...")
        detalle_rows = []
        for v_idx, lineas in enumerate(detalles):
            for (id_prod, id_promo, cantidad, precio, desc_l, sub_l) in lineas:
                detalle_rows.append((venta_ids[v_idx], id_prod, id_promo,
                                     cantidad, precio, desc_l, sub_l))
        bulk_insert(cur, "tb_venta_detalle",
                    ["id_venta", "id_producto", "id_promocion", "cantidad",
                     "precio_unitario_venta", "descuento_aplicado", "subtotal_linea"],
                    detalle_rows, page_size=5000)

        # 16. Inventario
        print("Insertando tb_inventario ...")
        inv_rows = gen_inventario(prod_ids, suc_ids)
        bulk_insert(cur, "tb_inventario",
                    ["id_producto", "id_sucursal", "fecha", "stock_actual",
                     "stock_minimo", "entradas_dia", "salidas_dia"],
                    inv_rows, page_size=5000)

        conn.commit()
        print("\n=== CARGA COMPLETA ===")

        # Reporte final
        cur.execute(f"""
            SELECT table_name,
                   (xpath('/row/c/text()', query_to_xml('SELECT COUNT(*) AS c FROM '||
                    quote_ident(table_schema)||'.'||quote_ident(table_name), true, true, '')))[1]::text::int AS n
            FROM information_schema.tables
            WHERE table_schema = '{SCHEMA}' AND table_type = 'BASE TABLE'
            ORDER BY table_name;
        """)
        total = 0
        print(f"{'Tabla':<25}  Filas")
        print("-" * 40)
        for tbl, n in cur.fetchall():
            print(f"{tbl:<25}  {n:>8,}")
            total += n
        print("-" * 40)
        print(f"{'TOTAL':<25}  {total:>8,}")

    except Exception as e:
        conn.rollback()
        print(f"ERROR: {e}")
        raise
    finally:
        cur.close()
        conn.close()


if __name__ == "__main__":
    main()
