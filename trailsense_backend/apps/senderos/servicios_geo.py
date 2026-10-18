import json
import math
import time
import urllib.parse
import urllib.request
from collections import Counter

from defusedxml import ElementTree as ET
from django.conf import settings
from django.core.cache import cache

MAX_BYTES = 10 * 1024 * 1024
MAX_PUNTOS_FINALES = 500
TOLERANCIA_INICIAL_M = 5.0

_ultima_peticion = 0.0


class ArchivoTrazaError(ValueError):
    pass


# --------------------------------------------------------------- lectura GPX / TCX
def _local(tag):
    return tag.rsplit('}', 1)[-1]          # ignora el namespace XML


def _agregar(puntos, lat, lon):
    try:
        lat, lon = float(lat), float(lon)
    except (TypeError, ValueError):
        return
    if -90 <= lat <= 90 and -180 <= lon <= 180:
        if not puntos or puntos[-1] != (lat, lon):      # descarta duplicados consecutivos
            puntos.append((lat, lon))


def extraer_puntos(contenido, nombre):
    extension = nombre.lower().rsplit('.', 1)[-1] if '.' in nombre else ''
    if extension not in ('gpx', 'tcx'):
        raise ArchivoTrazaError('Formato no soportado. Sube un archivo .gpx o .tcx.')
    try:
        raiz = ET.fromstring(contenido)
    except Exception:
        raise ArchivoTrazaError('El archivo está dañado o no es un XML válido.')

    puntos = []
    if extension == 'gpx':
        for etiqueta in ('trkpt', 'rtept'):             # primero tracks; si no hay, rutas
            for el in raiz.iter():
                if _local(el.tag) == etiqueta:
                    _agregar(puntos, el.get('lat'), el.get('lon'))
            if puntos:
                break
    else:
        for el in raiz.iter():
            if _local(el.tag) == 'Trackpoint':
                lat = lon = None
                for hijo in el.iter():
                    t = _local(hijo.tag)
                    if t == 'LatitudeDegrees':
                        lat = hijo.text
                    elif t == 'LongitudeDegrees':
                        lon = hijo.text
                if lat is not None and lon is not None:
                    _agregar(puntos, lat, lon)
    return puntos


# ----------------------------------------------------------------- geometría
def haversine_m(a, b):
    R = 6371008.8
    la1, lo1, la2, lo2 = map(math.radians, (a[0], a[1], b[0], b[1]))
    h = math.sin((la2 - la1) / 2) ** 2 + math.cos(la1) * math.cos(la2) * math.sin((lo2 - lo1) / 2) ** 2
    return 2 * R * math.asin(math.sqrt(h))


def longitud_km(puntos):
    return sum(haversine_m(puntos[i], puntos[i + 1]) for i in range(len(puntos) - 1)) / 1000


def _distancia_punto_segmento(p, a, b):
    dx, dy = b[0] - a[0], b[1] - a[1]
    if dx == 0 and dy == 0:
        return math.hypot(p[0] - a[0], p[1] - a[1])
    t = max(0, min(1, ((p[0] - a[0]) * dx + (p[1] - a[1]) * dy) / (dx * dx + dy * dy)))
    return math.hypot(p[0] - (a[0] + t * dx), p[1] - (a[1] + t * dy))


def simplificar_rdp(puntos, tolerancia_m):
    """Ramer–Douglas–Peucker iterativo (sin recursión, soporta trazas de decenas de miles de puntos)."""
    n = len(puntos)
    if n < 3:
        return list(puntos)
    lat0 = sum(p[0] for p in puntos) / n
    kx, ky = 111320 * math.cos(math.radians(lat0)), 110540      # grados -> metros (proyección local)
    xy = [(p[1] * kx, p[0] * ky) for p in puntos]

    conservar = [False] * n
    conservar[0] = conservar[-1] = True
    pila = [(0, n - 1)]
    while pila:
        i, j = pila.pop()
        max_d, idx = 0.0, None
        for k in range(i + 1, j):
            d = _distancia_punto_segmento(xy[k], xy[i], xy[j])
            if d > max_d:
                max_d, idx = d, k
        if idx is not None and max_d > tolerancia_m:
            conservar[idx] = True
            pila.append((i, idx))
            pila.append((idx, j))
    return [p for p, c in zip(puntos, conservar) if c]


def procesar_traza(contenido, nombre):
    crudos = extraer_puntos(contenido, nombre)
    if len(crudos) < 2:
        raise ArchivoTrazaError('El archivo no contiene una traza con al menos 2 puntos.')

    tolerancia = TOLERANCIA_INICIAL_M
    simplificados = simplificar_rdp(crudos, tolerancia)
    while len(simplificados) > MAX_PUNTOS_FINALES and tolerancia < 500:
        tolerancia *= 1.5
        simplificados = simplificar_rdp(crudos, tolerancia)

    wkt = 'LINESTRING (' + ', '.join(f'{lon:.6f} {lat:.6f}' for lat, lon in simplificados) + ')'
    return {
        'wkt': wkt,
        'puntos_originales': len(crudos),
        'puntos_resultantes': len(simplificados),
        'longitud_km': round(longitud_km(crudos), 3),
        'tolerancia_m': round(tolerancia, 1),
    }


# --------------------------------------------------------- geocodificación inversa
CLAVES_CALLE = ('road', 'pedestrian', 'footway', 'cycleway', 'path', 'track')
CLAVES_ZONA = ('neighbourhood', 'suburb', 'quarter', 'hamlet', 'village', 'city_district')


def _reverse(lat, lon):
    """Devuelve el dict 'address' de Nominatim o None. Cachea 30 días y respeta 1 petición/s."""
    global _ultima_peticion
    clave = f'geo:{round(lat, 4)}:{round(lon, 4)}'
    en_cache = cache.get(clave)
    if en_cache is not None:
        return en_cache

    espera = 1.1 - (time.monotonic() - _ultima_peticion)
    if espera > 0:
        time.sleep(espera)

    params = urllib.parse.urlencode({
        'format': 'jsonv2', 'lat': lat, 'lon': lon, 'zoom': 17,
        'addressdetails': 1, 'accept-language': 'es',
    })
    req = urllib.request.Request(
        f'{settings.NOMINATIM_URL}?{params}',
        headers={'User-Agent': settings.GEOCODER_USER_AGENT},
    )
    try:
        with urllib.request.urlopen(req, timeout=6) as resp:
            direccion = (json.loads(resp.read().decode('utf-8')).get('address') or {})
    except Exception:
        return None
    finally:
        _ultima_peticion = time.monotonic()

    cache.set(clave, direccion, 60 * 60 * 24 * 30)
    return direccion


def _muestrear(puntos, n=5):
    """n puntos repartidos por distancia a lo largo del trazado."""
    if len(puntos) <= n:
        return list(puntos)
    acumulada = [0.0]
    for i in range(1, len(puntos)):
        acumulada.append(acumulada[-1] + haversine_m(puntos[i - 1], puntos[i]))
    total = acumulada[-1] or 1
    elegidos, j = [], 0
    for k in range(n):
        objetivo = total * k / (n - 1)
        while j < len(puntos) - 1 and acumulada[j] < objetivo:
            j += 1
        elegidos.append(puntos[j])
    return elegidos


def direccion_desde_puntos(puntos):
    """puntos: lista de (lat, lon). Devuelve {'texto','calles','zona','canton'}."""
    calles, zonas, cantones = [], [], []
    for lat, lon in _muestrear(puntos):
        addr = _reverse(lat, lon)
        if not addr:
            continue
        calle = next((addr[k] for k in CLAVES_CALLE if addr.get(k)), None)
        if calle and calle not in calles:
            calles.append(calle)
        zona = next((addr[k] for k in CLAVES_ZONA if addr.get(k)), None)
        if zona:
            zonas.append(zona)
        if addr.get('county'):
            cantones.append(addr['county'].replace('Cantón ', '').strip())

    zona = Counter(zonas).most_common(1)[0][0] if zonas else ''
    canton = Counter(cantones).most_common(1)[0][0] if cantones else ''

    if calles:
        texto = ', '.join(calles[:4])
        if zona:
            texto += f' (sector {zona})'
    elif zona:
        texto = f'Sector {zona}'
    else:
        texto = ''
    return {'texto': texto[:255], 'calles': calles[:4], 'zona': zona, 'canton': canton}


def completar_direccion(sendero):
    """Si el sendero no tiene dirección, la calcula con su trazado. Devuelve True si la completó."""
    if (sendero.direccion or '').strip() or not sendero.geometria:
        return False
    try:
        puntos = [(lat, lon) for lon, lat in sendero.geometria.coords]
        texto = direccion_desde_puntos(puntos)['texto']
    except Exception:
        return False                      # sin internet o error: se guarda sin dirección
    if texto:
        sendero.direccion = texto
        return True
    return False    