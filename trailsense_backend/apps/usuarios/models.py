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

    GENERO_CHOICES = (
        ('M', 'Masculino'),
        ('F', 'Femenino'),
    )

    rol = models.CharField(max_length=20, choices=ROL_CHOICES, default='ciudadano')
    total_reportes = models.PositiveIntegerField(default=0)
    kilometros_recorridos = models.FloatField(default=0)

    foto_perfil = models.ImageField(upload_to='perfiles/', null=True, blank=True)

    reputacion_score = models.FloatField(default=0)
    is_verified = models.BooleanField(default=False)

    # --- NUEVOS CAMPOS (Sprint 5 - administración de perfil) ---
    cedula = models.CharField(max_length=10, blank=True, default='')
    telefono = models.CharField(max_length=15, blank=True, default='')
    genero = models.CharField(max_length=1, choices=GENERO_CHOICES, blank=True, default='')
    fecha_nacimiento = models.DateField(null=True, blank=True)

    def __str__(self):
        return self.email


class CodigoVerificacion(models.Model):
    TIPO_CHOICES = (
        ('verificacion', 'Verificación de cuenta'),
        ('recuperacion', 'Recuperación de contraseña'),
    )

    usuario = models.ForeignKey(
        Usuario,
        on_delete=models.CASCADE,
        related_name='codigos_verificacion'
    )

    codigo = models.CharField(max_length=4)

    tipo = models.CharField(
        max_length=20,
        choices=TIPO_CHOICES,
        default='verificacion'
    )

    creado_en = models.DateTimeField(auto_now_add=True)
    expira_en = models.DateTimeField()
    usado = models.BooleanField(default=False)

    def esta_vigente(self):
        return not self.usado and timezone.now() < self.expira_en

    def __str__(self):
        return f"{self.usuario.email} - {self.codigo} ({self.tipo})"