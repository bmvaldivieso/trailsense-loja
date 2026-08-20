from django.contrib import admin
from django.contrib.auth.admin import UserAdmin

from .models import Usuario


@admin.register(Usuario)
class UsuarioAdmin(UserAdmin):

    fieldsets = (
        ('Credenciales', {
            'fields': ('email', 'username', 'password')
        }),
        ('Información personal', {
            'fields': ('first_name', 'last_name', 'foto_perfil')
        }),
        ('Información de TrailSense', {
            'fields': (
                'rol',
                'total_reportes',
                'kilometros_recorridos',
                'reputacion_score',
                'is_verified',
            )
        }),
        ('Permisos', {
            'fields': (
                'is_active',
                'is_staff',
                'is_superuser',
                'groups',
                'user_permissions',
            )
        }),
        ('Fechas', {
            'fields': ('last_login', 'date_joined')
        }),
    )

    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': (
                'email',
                'username',
                'password1',
                'password2',
                'first_name',
                'last_name',
                'rol',
                'foto_perfil',
                'is_active',
                'is_verified',
            ),
        }),
    )