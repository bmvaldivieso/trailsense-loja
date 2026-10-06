from django.contrib import admin
from .models import Notificacion, NotificacionLeida


@admin.register(Notificacion)
class NotificacionAdmin(admin.ModelAdmin):
    list_display = ('titulo', 'tipo', 'origen', 'destinatario', 'sendero', 'fecha_creacion')
    list_filter = ('origen', 'tipo')
    search_fields = ('titulo', 'mensaje')


admin.site.register(NotificacionLeida)