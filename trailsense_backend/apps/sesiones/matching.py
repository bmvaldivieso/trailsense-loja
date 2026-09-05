from django.contrib.gis.db.models.functions import Distance
from django.contrib.gis.measure import D

from apps.senderos.models import Sendero

# Margen de proximidad: 30m cubre el error típico de GPS de smartphone
# (5-15m) más el margen de trazado de las geometrías de los senderos.
UMBRAL_METROS = 30

# Porcentaje mínimo de puntos de la sesión que deben caer dentro del
# umbral de un sendero para considerar que SÍ corresponde a ese sendero.
RATIO_MINIMO = 0.6


def detectar_sendero_cercano(punto, umbral_metros=UMBRAL_METROS):
    """
    Vinculación rápida al INICIAR una sesión: busca el sendero más
    cercano a un único punto (la ubicación del usuario en ese momento).
    """
    return (
        Sendero.objects.annotate(dist=Distance('geometria', punto))
        .filter(dist__lte=D(m=umbral_metros))
        .order_by('dist')
        .first()
    )


def detectar_sendero_para_sesion(sesion, umbral_metros=UMBRAL_METROS, ratio_minimo=RATIO_MINIMO):
    """
    Vinculación autoritativa al FINALIZAR una sesión: calcula, para cada
    sendero existente, qué porcentaje de los puntos GPS de la sesión
    cayeron dentro de `umbral_metros` de su geometría. Si el mejor
    candidato supera `ratio_minimo`, se vincula; si no, queda libre.
    """
    total_puntos = sesion.puntos.count()
    if total_puntos == 0:
        return None

    mejor_sendero = None
    mejor_ratio = 0.0

    for sendero in Sendero.objects.all():
        coincidencias = sesion.puntos.annotate(
            dist=Distance('ubicacion', sendero.geometria)
        ).filter(dist__lte=D(m=umbral_metros)).count()

        ratio = coincidencias / total_puntos
        if ratio > mejor_ratio:
            mejor_ratio = ratio
            mejor_sendero = sendero

    return mejor_sendero if mejor_ratio >= ratio_minimo else None