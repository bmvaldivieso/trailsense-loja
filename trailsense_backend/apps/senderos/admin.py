from django.contrib import admin
from django.contrib.gis.admin import GISModelAdmin
from .models import Sendero


@admin.register(Sendero)
class SenderoAdmin(GISModelAdmin):
    list_display = ('nombre', 'canton', 'dificultad', 'estado', 'longitud_km', 'creado_en')
    list_filter = ('estado', 'dificultad', 'canton')
    search_fields = ('nombre',)
    default_lon = -79.2005
    default_lat = -3.9973
    default_zoom = 12