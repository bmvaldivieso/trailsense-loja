from django.db import models
from apps.senderos.models import Sendero

class Notificacion(models.Model):
    sendero = models.ForeignKey(Sendero, on_delete=models.CASCADE, related_name='notificaciones')
    mensaje = models.CharField(max_length=255)
    enviada = models.BooleanField(default=False)
    fecha_creacion = models.DateTimeField(auto_now_add=True)