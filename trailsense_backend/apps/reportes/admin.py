from django.contrib import admin
from django.contrib.gis.admin import GISModelAdmin
from .models import Reporte, FotoReporte


class FotoReporteInline(admin.TabularInline):
    model = FotoReporte
    extra = 0


@admin.register(Reporte)
class ReporteAdmin(GISModelAdmin):
    list_display = ('id', 'usuario', 'sendero', 'categoria', 'estado', 'votos_confirmacion', 'fecha_creacion')
    list_filter = ('categoria', 'estado', 'sendero')
    search_fields = ('usuario__email', 'descripcion')
    inlines = [FotoReporteInline]
    default_lon = -79.2005
    default_lat = -3.9973
    default_zoom = 13