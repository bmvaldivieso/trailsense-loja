"""Cierre de sesiones de caminata: normal (senderista) o automático (app cerrada o sin conexión)."""
from datetime import timedelta

from django.contrib.gis.geos import LineString, MultiLineString
from django.db import connection, transaction
from django.db.models import Max
from django.utils import timezone

from apps.actividad.utils import registrar_actividad
from .matching import detectar_sendero_para_sesion
from .models import SesionCaminata

ESTADOS_ABIERTOS = ('en_curso', 'pausada')
ESTADOS_CERRADOS = ('finalizada', 'interrumpida')

# Mínimos para considerar que un cierre automático conserva un recorrido real
MIN_PUNTOS = 2
MIN_DISTANCIA_KM = 0.05
MIN_DURACION_S = 60
# Sin puntos durante este tiempo = la app dejó de enviar (huérfana)
UMBRAL_HUERFANA = timedelta(minutes=30)


def distancia_km(puntos):
    """Longitud geodésica sumando por tramos: no une el fin de una pausa con su reanudación."""
    tramos, actual = [], []
    for p in puntos:
        if p.inicia_tramo and actual:
            tramos.append(actual)
            actual = []
        actual.append((p.ubicacion.x, p.ubicacion.y))
    if actual:
        tramos.append(actual)

    lineas = [LineString(t, srid=4326) for t in tramos if len(t) >= 2]
    if not lineas:
        return 0.0
    with connection.cursor() as cursor:   # mismo cálculo que Length() sobre geography
        cursor.execute("SELECT ST_Length(ST_GeomFromEWKT(%s)::geography)", [MultiLineString(lineas, srid=4326).ewkt])
        metros = cursor.fetchone()[0] or 0
    return round(metros / 1000, 3)


def _ultima_actividad(sesion, puntos):
    return puntos[-1].capturado_en if puntos else sesion.iniciado_en


def _es_recorrido_real(n_puntos, km, duracion_s):
    return n_puntos >= MIN_PUNTOS and km >= MIN_DISTANCIA_KM and duracion_s >= MIN_DURACION_S


def cerrar_sesion(sesion, *, pasos=0, tiempo_pausado=0, automatico=False):
    puntos = list(sesion.puntos.order_by('capturado_en'))
    fin = _ultima_actividad(sesion, puntos) if automatico else timezone.now()

    if len(puntos) >= MIN_PUNTOS:
        sesion.traza = LineString([(p.ubicacion.x, p.ubicacion.y) for p in puntos], srid=4326)
    sesion.sendero = detectar_sendero_para_sesion(sesion)

    sesion.finalizado_en = fin
    sesion.tiempo_pausado_segundos = tiempo_pausado
    sesion.pasos = pasos
    sesion.duracion_segundos = max(int((fin - sesion.iniciado_en).total_seconds()) - tiempo_pausado, 0)
    sesion.distancia_km = distancia_km(puntos)
    sesion.velocidad_promedio_kmh = (
        round(sesion.distancia_km / (sesion.duracion_segundos / 3600), 2) if sesion.duracion_segundos > 0 else 0
    )
    sesion.cierre_automatico = automatico

    valida = not automatico or _es_recorrido_real(len(puntos), sesion.distancia_km, sesion.duracion_segundos)
    sesion.estado = 'finalizada' if valida else 'interrumpida'

    if valida and sesion.numero_usuario is None:
        ultimo = SesionCaminata.objects.filter(usuario=sesion.usuario).aggregate(m=Max('numero_usuario'))['m'] or 0
        sesion.numero_usuario = ultimo + 1
    sesion.save()

    if valida:
        usuario = sesion.usuario
        usuario.kilometros_recorridos = (usuario.kilometros_recorridos or 0) + sesion.distancia_km
        usuario.save(update_fields=['kilometros_recorridos'])
        detalle = ' (cierre automático)' if automatico else ''
        registrar_actividad(usuario, 'recorrido_finalizado', f"Distancia: {sesion.distancia_km} km{detalle}")
    return sesion


def cerrar_huerfanas(*, usuario=None, sin_actividad_desde=None):
    """Cierra automáticamente sesiones abiertas. Con fecha: solo las inactivas desde entonces."""
    qs = SesionCaminata.objects.filter(estado__in=ESTADOS_ABIERTOS).select_related('usuario')
    if usuario is not None:
        qs = qs.filter(usuario=usuario)
    cerradas = []
    for s in qs:
        if sin_actividad_desde is not None:
            ultimo = s.puntos.aggregate(m=Max('capturado_en'))['m'] or s.iniciado_en
            if ultimo > sin_actividad_desde:
                continue
        with transaction.atomic():
            cerradas.append(cerrar_sesion(s, automatico=True))
    return cerradas


def parece_cierre_de_huerfana(sesion, pasos, tiempo_pausado):
    """Firma de versiones anteriores de la app al cerrar huérfanas: 0 pasos, 0 pausa y sin puntos recientes."""
    if pasos or tiempo_pausado:
        return False
    ultimo = sesion.puntos.aggregate(m=Max('capturado_en'))['m'] or sesion.iniciado_en
    return timezone.now() - ultimo > UMBRAL_HUERFANA


def reparar_historica(sesion, *, aplicar=False):
    """Sesión ya finalizada con la firma de una huérfana mal cerrada. Devuelve los cambios o None."""
    if sesion.pasos or sesion.tiempo_pausado_segundos or sesion.cierre_automatico or not sesion.finalizado_en:
        return None
    puntos = list(sesion.puntos.order_by('capturado_en'))
    ultimo = _ultima_actividad(sesion, puntos)
    if sesion.finalizado_en - ultimo <= UMBRAL_HUERFANA:
        return None

    duracion = max(int((ultimo - sesion.iniciado_en).total_seconds()), 0)
    km = distancia_km(puntos)
    valida = _es_recorrido_real(len(puntos), km, duracion)
    cambios = {
        'id': sesion.pk, 'usuario': sesion.usuario.email,
        'duracion_antes_s': sesion.duracion_segundos, 'duracion_despues_s': duracion,
        'km': km, 'estado_nuevo': 'finalizada' if valida else 'interrumpida',
    }
    if not aplicar:
        return cambios

    with transaction.atomic():
        km_antes = sesion.distancia_km
        sesion.finalizado_en = ultimo
        sesion.duracion_segundos = duracion
        sesion.distancia_km = km
        sesion.velocidad_promedio_kmh = round(km / (duracion / 3600), 2) if duracion > 0 else 0
        sesion.cierre_automatico = True
        sesion.estado = cambios['estado_nuevo']
        sesion.save(update_fields=['finalizado_en', 'duracion_segundos', 'distancia_km',
                                   'velocidad_promedio_kmh', 'cierre_automatico', 'estado'])
        usuario = sesion.usuario
        ajuste = (km - km_antes) if valida else -km_antes
        usuario.kilometros_recorridos = max((usuario.kilometros_recorridos or 0) + ajuste, 0)
        usuario.save(update_fields=['kilometros_recorridos'])
    return cambios