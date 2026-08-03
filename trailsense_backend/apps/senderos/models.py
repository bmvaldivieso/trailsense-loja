from django.contrib.gis.db import models

class Sendero(models.Model):
    ESTADO_CHOICES = (
        ('activo', 'Activo'),
        ('mantenimiento', 'En mantenimiento'),
        ('cerrado', 'Cerrado'),
    )
    nombre = models.CharField(max_length=150)
    descripcion = models.TextField(blank=True)
    geometria = models.LineStringField(srid=4326)
    dificultad = models.CharField(max_length=20)
    longitud_km = models.FloatField()
    tiene_iluminacion = models.BooleanField(default=False)
    horario_apertura = models.TimeField(null=True, blank=True)
    horario_cierre = models.TimeField(null=True, blank=True)
    estado = models.CharField(max_length=20, choices=ESTADO_CHOICES, default='activo')
    fecha_creacion = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.nombre