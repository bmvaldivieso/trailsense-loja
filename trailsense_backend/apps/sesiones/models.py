from django.contrib.gis.db import models
from django.conf import settings
from apps.senderos.models import Sendero

class SesionCaminata(models.Model):
    usuario = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    sendero = models.ForeignKey(Sendero, on_delete=models.SET_NULL, null=True, blank=True)
    traza = models.LineStringField(srid=4326)
    distancia_km = models.FloatField(default=0)
    duracion_segundos = models.PositiveIntegerField(default=0)
    velocidad_promedio = models.FloatField(default=0)
    numero_pasos = models.PositiveIntegerField(default=0)
    fecha_inicio = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Sesión {self.id} - {self.usuario}"