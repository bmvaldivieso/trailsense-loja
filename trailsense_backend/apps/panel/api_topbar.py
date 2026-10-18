from datetime import timedelta

from django.db.models import Q
from django.urls import NoReverseMatch, reverse
from django.utils import timezone
from django.utils.timesince import timesince
from rest_framework.authentication import SessionAuthentication
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.estadisticas.dashboard import sin_actividad
from apps.reportes.models import Reporte
from apps.senderos.models import Sendero
from apps.usuarios.models import Usuario
from core.permissions.roles import EsAdminOSuperusuario

from apps.actividad.models import RegistroActividad

LIMITE = 5


def _url(nombre, *args, alterno='panel:dashboard'):
    try:
        return reverse(nombre, args=args)
    except NoReverseMatch:
        return reverse(alterno)


def _filtro_persona(q, prefijo=''):
    return (Q(**{f'{prefijo}first_name__icontains': q}) | Q(**{f'{prefijo}last_name__icontains': q})
            | Q(**{f'{prefijo}email__icontains': q}))


def _persona(u, url):
    return {'titulo': f'{u.first_name} {u.last_name}'.strip() or u.email, 'detalle': u.email, 'url': url}


class BuscadorGlobalAPIView(APIView):
    authentication_classes = [SessionAuthentication]
    permission_classes = [IsAuthenticated, EsAdminOSuperusuario]

    def get(self, request):
        q = (request.query_params.get('q') or '').strip()
        if len(q) < 2:
            return Response({'grupos': []})

        es_super = request.user.rol == 'superusuario'

        if es_super:                                           # solo administradores
            url_admins = _url('panel:superusuario-usuarios')
            admins = Usuario.objects.filter(rol='administrador').filter(
                _filtro_persona(q) | Q(cedula__icontains=q))[:LIMITE]
            grupos = [{'nombre': 'Administradores', 'icono': 'bi-shield-check',
                       'items': [_persona(u, url_admins) for u in admins]}]
            return Response({'grupos': [g for g in grupos if g['items']]})

        grupos = []
        if request.user.is_staff:
            senderos = Sendero.objects.filter(
                Q(nombre__icontains=q) | Q(canton__icontains=q) | Q(direccion__icontains=q))[:LIMITE]
            grupos.append({'nombre': 'Senderos', 'icono': 'bi-signpost-split', 'items': [
                {'titulo': s.nombre, 'detalle': ' · '.join(t for t in (s.canton, s.direccion) if t),
                 'url': _url('panel:detalle-sendero', s.pk, alterno='panel:senderos')} for s in senderos]})

            filtro = (Q(descripcion__icontains=q) | Q(sendero__nombre__icontains=q) | _filtro_persona(q, 'usuario__'))
            if q.isdigit():
                filtro |= Q(pk=int(q))
            incidencias = (Reporte.objects.select_related('usuario', 'sendero')
                        .filter(filtro).order_by('-fecha_creacion')[:LIMITE])
            grupos.append({'nombre': 'Incidencias', 'icono': 'bi-megaphone', 'items': [
                {'titulo': f'Incidencia {r.pk} · {r.get_categoria_display()}',
                'detalle': f'{r.sendero.nombre} · {r.get_estado_display()}',
                'url': _url('panel:detalle-incidencia', r.pk, alterno='panel:incidencias')} for r in incidencias]})

        url_senderistas = _url('panel:senderistas')
        senderistas = Usuario.objects.filter(rol='ciudadano').filter(_filtro_persona(q) | Q(cedula__icontains=q))[:LIMITE]
        grupos.append({'nombre': 'Senderistas', 'icono': 'bi-person', 'items': [
            _persona(u, url_senderistas) for u in senderistas]})

        return Response({'grupos': [g for g in grupos if g['items']]})


class AlertasPanelAPIView(APIView):
    authentication_classes = [SessionAuthentication]
    permission_classes = [IsAuthenticated, EsAdminOSuperusuario]

    def get(self, request):
        es_super = request.user.rol == 'superusuario'
        items, total = [], 0

        n_sin_senal = len(sin_actividad())
        if n_sin_senal:
            total += n_sin_senal
            items.append({'icono': 'bi-wifi-off', 'color': '#ef4444',
                          'titulo': f'{n_sin_senal} recorrido(s) sin señal GPS',
                          'detalle': 'Revisa su última posición conocida',
                          'url': _url('panel:superusuario-dashboard' if es_super else 'panel:dashboard')})

        if es_super:
            semana = timezone.now() - timedelta(days=7)
            n = Usuario.objects.filter(rol='administrador', date_joined__gte=semana).count()
            if n:
                total += n
                items.append({'icono': 'bi-person-plus', 'color': '#3b82f6',
                              'titulo': f'{n} administrador(es) nuevo(s)', 'detalle': 'En los últimos 7 días',
                              'url': _url('panel:superusuario-usuarios')})

            hace_24h = timezone.now() - timedelta(hours=24)
            n_act = RegistroActividad.objects.filter(usuario__rol='administrador', fecha__gte=hace_24h).count()
            if n_act:                    # informativo: NO suma al número rojo
                items.append({'icono': 'bi-clock-history', 'color': '#64748b',
                              'titulo': f'{n_act} acción(es) de administradores', 'detalle': 'En las últimas 24 horas',
                              'url': _url('panel:superusuario-historial')})
        else:
            n_criticos = Sendero.objects.filter(estado='critico').count() if request.user.is_staff else 0
            if n_criticos:
                total += n_criticos
                items.append({'icono': 'bi-exclamation-triangle', 'color': '#f97316',
                              'titulo': f'{n_criticos} sendero(s) en estado crítico',
                              'detalle': 'Requieren atención', 'url': _url('panel:senderos')})

            pendientes = Reporte.objects.filter(estado='pendiente')
            n_pend = pendientes.count()
            if n_pend:
                total += n_pend
                items.append({'icono': 'bi-hourglass-split', 'color': '#eab308',
                              'titulo': f'{n_pend} incidencia(s) pendiente(s) de revisión',
                              'detalle': 'Aprobar o rechazar', 'url': _url('panel:incidencias')})
                for r in pendientes.select_related('sendero').order_by('-fecha_creacion')[:5]:
                    items.append({'icono': 'bi-megaphone', 'color': '#64748b',
                                  'titulo': f'Incidencia {r.pk} · {r.get_categoria_display()}',
                                  'detalle': f'{r.sendero.nombre} · hace {timesince(r.fecha_creacion).split(",")[0]}',
                                  'url': _url('panel:detalle-incidencia', r.pk, alterno='panel:incidencias')})

        return Response({'total': total, 'items': items})