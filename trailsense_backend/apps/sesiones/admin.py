from django.contrib import admin
from django.contrib.gis.admin import GISModelAdmin
from .models import SesionCaminata, PuntoGPS


@admin.register(SesionCaminata)
class SesionCaminataAdmin(GISModelAdmin):
    list_display = ('id', 'usuario', 'estado', 'distancia_km', 'duracion_segundos', 'pasos', 'iniciado_en')
    list_filter = ('estado',)
    search_fields = ('usuario__email',)
    default_lon = -79.2005
    default_lat = -3.9973
    default_zoom = 13


@admin.register(PuntoGPS)
class PuntoGPSAdmin(GISModelAdmin):
    list_display = ('id', 'sesion', 'capturado_en')
    default_lon = -79.2005
    default_lat = -3.9973
    default_zoom = 13