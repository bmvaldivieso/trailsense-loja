from django.core.management.base import BaseCommand
from apps.senderos.models import Sendero
from apps.senderos.servicios_geo import direccion_desde_puntos


class Command(BaseCommand):
    help = 'Calcula la dirección de los senderos que no la tienen (usa Nominatim, ~6 s por sendero).'

    def add_arguments(self, parser):
        parser.add_argument('--forzar', action='store_true', help='Recalcula también los que ya tienen dirección.')

    def handle(self, *args, **opts):
        qs = Sendero.objects.all() if opts['forzar'] else Sendero.objects.filter(direccion='')
        for s in qs:
            puntos = [(lat, lon) for lon, lat in s.geometria.coords]
            texto = direccion_desde_puntos(puntos)['texto']
            if texto:
                s.direccion = texto
                s.save(update_fields=['direccion', 'actualizado_en'])
            self.stdout.write(f'{s.nombre}: {texto or "(sin resultado)"}')