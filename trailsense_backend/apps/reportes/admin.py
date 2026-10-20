from django.contrib import admin
from django.contrib.gis.admin import GISModelAdmin
from core.gis_widgets import CartoOSMWidget
from .models import Reporte, FotoReporte, VotoReporte


class FotoReporteInline(admin.TabularInline):
    model = FotoReporte
    extra = 0


class VotoReporteInline(admin.TabularInline):
    model = VotoReporte
    extra = 0
    can_delete = False
    readonly_fields = ('usuario', 'fecha')

    def has_add_permission(self, request, obj=None):
        return False    


@admin.register(Reporte)
class ReporteAdmin(GISModelAdmin):
    list_display = ('id', 'usuario', 'sendero', 'categoria', 'estado', 'votos_confirmacion', 'fecha_creacion')
    list_filter = ('categoria', 'estado', 'sendero')
    search_fields = ('usuario__email', 'descripcion')
    inlines = [FotoReporteInline, VotoReporteInline]
    gis_widget = CartoOSMWidget
    # default_lon = -79.2005
    # default_lat = -3.9973
    # default_zoom = 13