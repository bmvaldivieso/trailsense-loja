from django.contrib.gis.db import models
from django.conf import settings
from apps.senderos.models import Sendero

class Reporte(models.Model):
    CATEGORIA_CHOICES = (
        ('deterioro', 'Deterioro del camino'),
        ('senalizacion', 'Señalización deficiente'),
        ('residuos', 'Acumulación de residuos'),
        ('obstaculo', 'Obstáculo'),
        ('seguridad', 'Riesgo de seguridad'),
    )
    usuario = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    sendero = models.ForeignKey(Sendero, on_delete=models.CASCADE, related_name='reportes')
    ubicacion = models.PointField(srid=4326)
    altitud = models.FloatField(null=True, blank=True)
    categoria = models.CharField(max_length=20, choices=CATEGORIA_CHOICES)
    descripcion = models.TextField()
    foto_url = models.URLField(blank=True, null=True)
    validado = models.BooleanField(default=False)
    votos_confirmacion = models.PositiveIntegerField(default=0)
    fecha_creacion = models.DateTimeField(auto_now_add=True)