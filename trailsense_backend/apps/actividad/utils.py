from .models import RegistroActividad

def registrar_actividad(usuario, tipo, descripcion=''):
    RegistroActividad.objects.create(usuario=usuario, tipo=tipo, descripcion=descripcion)