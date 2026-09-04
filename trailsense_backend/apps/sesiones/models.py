from django.contrib.gis.db import models
from django.conf import settings


class SesionCaminata(models.Model):
    ESTADO_CHOICES = (
        ('en_curso', 'En curso'),
        ('pausada', 'Pausada'),
        ('finalizada', 'Finalizada'),
    )

    usuario = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='sesiones_caminata',
    )
    sendero = models.ForeignKey(
        'senderos.Sendero',
        on_delete=models.SET_NULL,
        null=True, blank=True,
        related_name='sesiones',
    )

    estado = models.CharField(max_length=15, choices=ESTADO_CHOICES, default='en_curso')

    iniciado_en = models.DateTimeField(auto_now_add=True)
    finalizado_en = models.DateTimeField(null=True, blank=True)
    tiempo_pausado_segundos = models.PositiveIntegerField(default=0)

    # Traza real como LineString (se construye al finalizar — base del Sprint 9)
    traza = models.LineStringField(srid=4326, geography=True, null=True, blank=True)

    # Métricas calculadas al finalizar (Sprint 9)
    distancia_km = models.FloatField(default=0)
    duracion_segundos = models.PositiveIntegerField(default=0)
    velocidad_promedio_kmh = models.FloatField(default=0)

    # Sensado oportunista adicional (Tabla 2 tesis, categoría Movimiento)
    pasos = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ['-iniciado_en']

    def __str__(self):
        return f"Sesión {self.id} - {self.usuario.email}"


class PuntoGPS(models.Model):
    """
    Puntos individuales capturados de forma oportunista mientras
    la sesión está en curso. Se envían en lotes desde la app.
    """
    sesion = models.ForeignKey(SesionCaminata, on_delete=models.CASCADE, related_name='puntos')
    ubicacion = models.PointField(srid=4326)
    capturado_en = models.DateTimeField()
    precision_m = models.FloatField(null=True, blank=True)
    altitud_m = models.FloatField(null=True, blank=True)
    velocidad_mps = models.FloatField(null=True, blank=True)

    class Meta:
        ordering = ['capturado_en']

    def __str__(self):
        return f"Punto de sesión {self.sesion_id} @ {self.capturado_en}"