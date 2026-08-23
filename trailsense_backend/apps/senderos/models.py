from django.contrib.gis.db import models


class Sendero(models.Model):

    DIFICULTAD_CHOICES = (
        ('baja', 'Baja'),
        ('media', 'Media'),
        ('alta', 'Alta'),
    )

    ESTADO_CHOICES = (
        ('bueno', 'Bueno'),
        ('alerta', 'Con alertas menores'),
        ('critico', 'Crítico'),
    )

    nombre = models.CharField(
        max_length=150
    )

    descripcion = models.TextField(
        blank=True,
        default=''
    )

    canton = models.CharField(
        max_length=100,
        blank=True,
        default='Loja'
    )

    dificultad = models.CharField(
        max_length=10,
        choices=DIFICULTAD_CHOICES,
        default='media'
    )

    estado = models.CharField(
        max_length=10,
        choices=ESTADO_CHOICES,
        default='bueno'
    )

    longitud_km = models.FloatField(
        default=0
    )

    tiene_iluminacion = models.BooleanField(
        default=False
    )

    horario_apertura = models.TimeField(
        null=True,
        blank=True
    )

    horario_cierre = models.TimeField(
        null=True,
        blank=True
    )

    imagen_portada = models.ImageField(
        upload_to='senderos/portadas/',
        null=True,
        blank=True
    )

    # Núcleo geoespacial: WGS84
    geometria = models.LineStringField(
        srid=4326
    )

    creado_en = models.DateTimeField(
        auto_now_add=True
    )

    actualizado_en = models.DateTimeField(
        auto_now=True
    )

    class Meta:
        ordering = ['-creado_en']

    def __str__(self):
        return self.nombre