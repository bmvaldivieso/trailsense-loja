from django.contrib import admin
from django.contrib.auth.admin import UserAdmin

from .models import Usuario, CodigoVerificacion


@admin.register(Usuario)
class UsuarioAdmin(UserAdmin):

    fieldsets = (
        ('Credenciales', {
            'fields': ('email', 'username', 'password')
        }),
        ('Información personal', {
            'fields': ('first_name', 'last_name', 'cedula', 'telefono', 'genero', 'fecha_nacimiento', 'foto_perfil')
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
                'cedula',
                'telefono',
                'genero',
                'fecha_nacimiento',
                'rol',
                'foto_perfil',
                'is_active',
                'is_verified',
            ),
        }),
    )


@admin.register(CodigoVerificacion)
class CodigoVerificacionAdmin(admin.ModelAdmin):

    list_display = (
        'usuario',
        'codigo',
        'tipo',
        'creado_en',
        'expira_en',
        'usado',
    )

    list_filter = (
        'tipo',
        'usado',
        'creado_en',
    )

    search_fields = (
        'usuario__email',
        'codigo',
    )

    ordering = ('-creado_en',)