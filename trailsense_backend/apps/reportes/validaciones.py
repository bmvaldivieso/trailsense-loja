from datetime import timedelta
from django.utils import timezone
from django.contrib.gis.db.models.functions import Distance
from django.contrib.gis.measure import D

from .models import Reporte

# --- Proximidad al sendero ---
UMBRAL_PROXIMIDAD_SENDERO_M = 50

# --- Anti-duplicado (mismo usuario, mismo lugar, poco tiempo) ---
VENTANA_DUPLICADO_MINUTOS = 10
RADIO_DUPLICADO_M = 0.005

# --- Límite general de reportes por usuario (resguardo anti-flood) ---
LIMITE_REPORTES_POR_DIA = 10


class ValidacionReporteError(Exception):
    """Se lanza cuando un reporte no pasa alguna validación anti-spam/proximidad."""
    def __init__(self, codigo, mensaje):
        self.codigo = codigo
        self.mensaje = mensaje
        super().__init__(mensaje)


def validar_proximidad_sendero(sendero, distancia_m):
    if distancia_m is None or distancia_m > UMBRAL_PROXIMIDAD_SENDERO_M:
        raise ValidacionReporteError(
            "fuera_de_rango",
            f"La ubicación reportada está a más de {UMBRAL_PROXIMIDAD_SENDERO_M}m del sendero '{sendero.nombre}'.",
        )


def validar_no_duplicado(usuario, punto):
    limite_tiempo = timezone.now() - timedelta(minutes=VENTANA_DUPLICADO_MINUTOS)

    duplicado = Reporte.objects.filter(
        usuario=usuario,
        fecha_creacion__gte=limite_tiempo,
    ).annotate(
        dist=Distance('ubicacion', punto)
    ).filter(dist__lte=D(m=RADIO_DUPLICADO_M)).exists()

    if duplicado:
        raise ValidacionReporteError(
            "posible_duplicado",
            f"Ya registraste un reporte cerca de esta ubicación en los últimos {VENTANA_DUPLICADO_MINUTOS} minutos.",
        )


def validar_limite_diario(usuario):
    limite_tiempo = timezone.now() - timedelta(hours=24)
    total = Reporte.objects.filter(usuario=usuario, fecha_creacion__gte=limite_tiempo).count()

    if total >= LIMITE_REPORTES_POR_DIA:
        raise ValidacionReporteError(
            "limite_diario_alcanzado",
            f"Has alcanzado el límite de {LIMITE_REPORTES_POR_DIA} reportes en las últimas 24 horas.",
        )