from datetime import timedelta

from django.contrib.gis.db.models.functions import Distance
from django.contrib.gis.geos import Point
from django.contrib.gis.measure import D
from django.db.models import Exists, OuterRef, Q
from django.utils import timezone

from apps.reportes.models import Reporte
from .models import Notificacion, NotificacionLeida

# --- Parámetros de las notificaciones automáticas ---
RADIO_ALERTA_M = 200            # distancia a la que se avisa de una incidencia
VENTANA_REPORTES_DIAS = 7       # solo reportes creados en la última semana
COOLDOWN_MINUTOS = 30           # tiempo mínimo entre avisos de proximidad
UMBRAL_ACUMULACION = 3          # reportes de la misma categoría en un sendero
SEVERIDAD = {'seguridad': 5, 'obstaculo': 4, 'deterioro': 3, 'senalizacion': 2, 'residuos': 1}


# ------------------------------------------------------------- consulta para el senderista
def visibles_para(usuario):
    """Notificaciones para todos o dirigidas a este usuario, posteriores a su registro."""
    return Notificacion.objects.filter(
        Q(destinatario__isnull=True) | Q(destinatario=usuario),
        fecha_creacion__gte=usuario.date_joined,
    )


def con_estado_lectura(queryset, usuario):
    return queryset.annotate(
        leida=Exists(NotificacionLeida.objects.filter(notificacion=OuterRef('pk'), usuario=usuario))
    )


def contar_no_leidas(usuario):
    return visibles_para(usuario).exclude(lecturas__usuario=usuario).count()


# ----------------------------------------------------------------------- automáticas
def _hace(fecha):
    horas = int((timezone.now() - fecha).total_seconds() // 3600)
    if horas < 1:
        return "hace menos de una hora"
    if horas < 24:
        return f"hace {horas} h"
    dias = horas // 24
    return f"hace {dias} día{'s' if dias != 1 else ''}"


def evaluar_proximidad(usuario, lat, lon):
    """Crea (y devuelve) un aviso si hay incidencias recientes cerca; None si no corresponde."""
    ahora = timezone.now()

    # Control de tiempo: un solo aviso de proximidad cada COOLDOWN_MINUTOS
    if Notificacion.objects.filter(
        destinatario=usuario, tipo='proximidad',
        fecha_creacion__gte=ahora - timedelta(minutes=COOLDOWN_MINUTOS),
    ).exists():
        return None

    punto = Point(lon, lat, srid=4326)
    cercanos = list(
        Reporte.objects
        .filter(fecha_creacion__gte=ahora - timedelta(days=VENTANA_REPORTES_DIAS))
        .exclude(estado='rechazado')
        .exclude(usuario=usuario)
        .annotate(dist=Distance('ubicacion', punto))
        .filter(dist__lte=D(m=RADIO_ALERTA_M))
        .select_related('sendero')
    )
    if not cercanos:
        return None

    # Solo se avisa de la incidencia más grave (a igual gravedad, la más reciente)
    peor = max(cercanos, key=lambda r: (SEVERIDAD.get(r.categoria, 0), r.fecha_creacion))
    categoria = peor.get_categoria_display()
    mensaje = (
        f"A unos {int(peor.dist.m)} metros se reportó «{categoria}» en el sendero "
        f"{peor.sendero.nombre} ({_hace(peor.fecha_creacion)})."
    )
    if len(cercanos) > 1:
        mensaje += f" Hay {len(cercanos) - 1} reporte(s) más en esta zona."

    return Notificacion.objects.create(
        titulo=f"Cerca de ti: {categoria}", mensaje=mensaje,
        tipo='proximidad', origen='automatica',
        destinatario=usuario, sendero=peor.sendero, reporte=peor,
    )


def evaluar_acumulacion(reporte):
    """Avisa a todos cuando un sendero acumula UMBRAL reportes de la misma categoría en la semana."""
    desde = timezone.now() - timedelta(days=VENTANA_REPORTES_DIAS)
    total = (Reporte.objects
             .filter(sendero=reporte.sendero, categoria=reporte.categoria, fecha_creacion__gte=desde)
             .exclude(estado='rechazado').count())
    if total < UMBRAL_ACUMULACION:
        return None

    categoria = reporte.get_categoria_display()
    titulo = f"{categoria} en {reporte.sendero.nombre}"
    # No repetir el mismo aviso dentro de la misma ventana
    if Notificacion.objects.filter(tipo='acumulacion', sendero=reporte.sendero, titulo=titulo, fecha_creacion__gte=desde).exists():
        return None

    return Notificacion.objects.create(
        titulo=titulo,
        mensaje=f"En los últimos {VENTANA_REPORTES_DIAS} días se han reportado {total} incidencias de «{categoria}» en este sendero.",
        tipo='acumulacion', origen='automatica', sendero=reporte.sendero,
    )


def notificar_cambio_estado(sendero, estado_anterior):
    etiquetas = dict(sendero.ESTADO_CHOICES)
    return Notificacion.objects.create(
        titulo=f"Sendero {sendero.nombre}: nuevo estado",
        mensaje=(f"El estado del sendero «{sendero.nombre}» cambió de "
                 f"«{etiquetas.get(estado_anterior, estado_anterior)}» a «{etiquetas.get(sendero.estado, sendero.estado)}»."),
        tipo='estado_sendero', origen='automatica', sendero=sendero,
    )