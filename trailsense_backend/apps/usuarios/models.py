from django.contrib.auth.models import AbstractUser
from django.db import models

class Usuario(AbstractUser):
    email = models.EmailField(unique=True)

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = ["username"]

    ROL_CHOICES = (
        ('ciudadano', 'Ciudadano'),
        ('administrador', 'Administrador'),
        ('superusuario', 'Superusuario'),
    )

    rol = models.CharField(max_length=20, choices=ROL_CHOICES, default='ciudadano')
    total_reportes = models.PositiveIntegerField(default=0)
    kilometros_recorridos = models.FloatField(default=0)

    def __str__(self):
        return self.email