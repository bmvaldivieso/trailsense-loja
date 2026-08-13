from django.contrib.auth.models import AbstractUser
from django.db import models
from django.utils import timezone

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

    nombre = models.CharField(
        max_length=100,
        blank=True,
        default=''
    )

    apellido = models.CharField(
        max_length=100,
        blank=True,
        default=''
    )

    foto_perfil = models.ImageField(
        upload_to='perfiles/',
        null=True,
        blank=True
    )

    reputacion_score = models.FloatField(
        default=0
    )

    is_verified = models.BooleanField(
        default=False
    )

    def __str__(self):
        return self.email



class CodigoVerificacion(models.Model):
    usuario = models.ForeignKey(
        Usuario,
        on_delete=models.CASCADE,
        related_name='codigos_verificacion'
    )

    codigo = models.CharField(
        max_length=4
    )

    creado_en = models.DateTimeField(
        auto_now_add=True
    )

    expira_en = models.DateTimeField()

    usado = models.BooleanField(
        default=False
    )

    def esta_vigente(self):
        return (
            not self.usado
            and timezone.now() < self.expira_en
        )

    def __str__(self):
        return f"{self.usuario.email} - {self.codigo}"