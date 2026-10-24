from datetime import timedelta

from django.core.management.base import BaseCommand
from django.utils import timezone

from apps.sesiones.cierre import cerrar_huerfanas, reparar_historica
from apps.sesiones.models import SesionCaminata


class Command(BaseCommand):
    help = ("Revisa recorridos mal cerrados. Sin --aplicar solo muestra lo que cambiaría. "
            "Con --aplicar repara los históricos y cierra las sesiones abiertas e inactivas.")

    def add_arguments(self, parser):
        parser.add_argument('--aplicar', action='store_true', help='Guarda los cambios (por defecto solo muestra).')
        parser.add_argument('--horas', type=int, default=24, help='Horas sin puntos para cerrar una sesión abierta.')

    def handle(self, *args, aplicar, horas, **opciones):
        modo = 'APLICANDO' if aplicar else 'SIMULACIÓN (no se guarda nada)'
        self.stdout.write(self.style.WARNING(f'== {modo} =='))

        reparadas = 0
        for s in SesionCaminata.objects.filter(estado='finalizada').select_related('usuario'):
            cambios = reparar_historica(s, aplicar=aplicar)
            if cambios:
                reparadas += 1
                self.stdout.write(
                    f"#{cambios['id']} {cambios['usuario']}: {cambios['duracion_antes_s']}s -> "
                    f"{cambios['duracion_despues_s']}s, {cambios['km']} km -> {cambios['estado_nuevo']}"
                )

        limite = timezone.now() - timedelta(hours=horas)
        abiertas = SesionCaminata.objects.filter(estado__in=('en_curso', 'pausada')).count()
        cerradas = len(cerrar_huerfanas(sin_actividad_desde=limite)) if aplicar else 0

        self.stdout.write(self.style.SUCCESS(
            f'Históricas a reparar: {reparadas}. Abiertas actualmente: {abiertas}. '
            f'Cerradas por inactividad (> {horas} h): {cerradas}.'
        ))