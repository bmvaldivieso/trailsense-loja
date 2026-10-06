from django.conf import settings
from django.db import models


class Notificacion(models.Model):
    ORIGEN_CHOICES = (('manual', 'Manual'), ('automatica', 'Automática'))

    TIPO_CHOICES = (
        # Manuales (las crea un administrador)
        ('mantenimiento', 'Mantenimiento de la aplicación'),
        ('sendero', 'Aviso sobre un sendero'),
        ('seguridad', 'Aviso de seguridad'),
        ('comunicado', 'Comunicado a la comunidad'),
        # Automáticas (las genera el sistema)
        ('proximidad', 'Incidencia cercana'),
        ('acumulacion', 'Reportes acumulados en un sendero'),
        ('estado_sendero', 'Cambio de estado de un sendero'),
    )
    TIPOS_MANUALES = ('mantenimiento', 'sendero', 'seguridad', 'comunicado')

    titulo = models.CharField(max_length=120)
    mensaje = models.TextField()
    tipo = models.CharField(max_length=20, choices=TIPO_CHOICES)
    origen = models.CharField(max_length=12, choices=ORIGEN_CHOICES, default='manual')
    imagen = models.ImageField(upload_to='notificaciones/', null=True, blank=True)

    # null = para todos los senderistas
    destinatario = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE,
        null=True, blank=True, related_name='notificaciones_recibidas',
    )
    sendero = models.ForeignKey('senderos.Sendero', on_delete=models.SET_NULL, null=True, blank=True, related_name='notificaciones')
    reporte = models.ForeignKey('reportes.Reporte', on_delete=models.SET_NULL, null=True, blank=True, related_name='notificaciones')
    creado_por = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
        null=True, blank=True, related_name='notificaciones_creadas',
    )
    fecha_creacion = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-fecha_creacion']

    def __str__(self):
        return f"{self.titulo} ({self.get_origen_display()})"


class NotificacionLeida(models.Model):
    usuario = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='notificaciones_leidas')
    notificacion = models.ForeignKey(Notificacion, on_delete=models.CASCADE, related_name='lecturas')
    fecha = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('usuario', 'notificacion')