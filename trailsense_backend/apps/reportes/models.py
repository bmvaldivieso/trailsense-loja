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

    usuario = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='reportes')
    sendero = models.ForeignKey(Sendero, on_delete=models.CASCADE, related_name='reportes')

    ubicacion = models.PointField(srid=4326, geography=True)
    altitud = models.FloatField(null=True, blank=True)

    categoria = models.CharField(max_length=20, choices=CATEGORIA_CHOICES)
    descripcion = models.TextField()

    validado = models.BooleanField(default=False)
    votos_confirmacion = models.PositiveIntegerField(default=0)

    # Preparación Sprint 11 — se calcula al crear, no bloquea nada aún
    distancia_sendero_m = models.FloatField(null=True, blank=True)

    fecha_creacion = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-fecha_creacion']

    def __str__(self):
        return f"Reporte {self.id} - {self.categoria} ({self.sendero.nombre})"


class FotoReporte(models.Model):
    """Entre 1 y 5 fotos por reporte."""
    reporte = models.ForeignKey(Reporte, on_delete=models.CASCADE, related_name='fotos')
    imagen = models.ImageField(upload_to='reportes/')
    orden = models.PositiveSmallIntegerField(default=0)

    class Meta:
        ordering = ['orden']

    def __str__(self):
        return f"Foto {self.orden} de reporte {self.reporte_id}"