from django.db import models
from django.conf import settings


class RegistroActividad(models.Model):
    TIPO_CHOICES = (
        # Senderistas
        ('reporte_creado', 'Reporte creado'),
        ('perfil_actualizado', 'Perfil actualizado'),
        ('recorrido_finalizado', 'Recorrido finalizado'),
        ('descarga_pdf_estadisticas', 'Descarga de estadísticas (PDF)'),   # sprint futuro, sin wiring aún
        # Administradores
        ('sendero_creado', 'Sendero creado'),
        ('sendero_actualizado', 'Sendero actualizado'),
        ('sendero_eliminado', 'Sendero eliminado'),
        ('descarga_pdf_historial', 'Descarga de historial (PDF)'),
        ('notificacion_creada', 'Notificación creada'),   # sprint futuro, sin wiring aún
    )

    usuario = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='actividades')
    tipo = models.CharField(max_length=30, choices=TIPO_CHOICES)
    descripcion = models.CharField(max_length=255, blank=True, default='')
    fecha = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-fecha']

    def __str__(self):
        return f"{self.usuario.email} - {self.get_tipo_display()} - {self.fecha}"