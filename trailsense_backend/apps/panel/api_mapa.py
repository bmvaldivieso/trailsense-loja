from django.db.models import Count, Q
from django.utils import timezone
from rest_framework.authentication import SessionAuthentication
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.reportes.models import Reporte
from apps.senderos.models import Sendero
from apps.sesiones.models import SesionCaminata
from core.permissions.roles import EsAdministrador 

LIMITE_INCIDENCIAS = 500
LIMITE_RECORRIDOS = 200
TOLERANCIA_GRADOS = 0.00003   # ~3 m: reduce puntos de la traza sin alterar su forma visible


def _nombre(u):
    return f"{u.first_name} {u.last_name}".strip() or u.email


def _url(request, archivo):
    return request.build_absolute_uri(archivo.url) if archivo else None


def _latlon(geometria):
    # GeoDjango entrega (lon, lat); Leaflet espera [lat, lon]
    return [[c[1], c[0]] for c in geometria.coords]


def _local(fecha, formato='%d/%m/%Y %H:%M'):
    return timezone.localtime(fecha).strftime(formato)


def _senderos(request):
    qs = Sendero.objects.annotate(
        n_recorridos=Count('sesiones', filter=Q(sesiones__estado='finalizada'), distinct=True),
        n_reportes=Count('reportes', distinct=True),
    ).order_by('nombre')

    return [{
        "id": s.id, "nombre": s.nombre, "descripcion": s.descripcion, "canton": s.canton,
        "dificultad": s.dificultad, "dificultad_display": s.get_dificultad_display(),
        "estado": s.estado, "estado_display": s.get_estado_display(),
        "longitud_km": s.longitud_km,
        "horario": f"{s.horario_apertura:%H:%M} - {s.horario_cierre:%H:%M}" if (s.horario_apertura and s.horario_cierre) else None,
        "imagen": _url(request, s.imagen_portada),
        "recorridos": s.n_recorridos, "reportes": s.n_reportes,
        "coords": _latlon(s.geometria),
    } for s in qs]


def _incidencias(request):
    qs = (Reporte.objects.select_related('sendero', 'usuario').prefetch_related('fotos')
          .order_by('-fecha_creacion')[:LIMITE_INCIDENCIAS])

    return [{
        "id": r.id,
        "categoria": r.categoria, "categoria_display": r.get_categoria_display(),
        "estado": r.estado, "estado_display": r.get_estado_display(),
        "descripcion": r.descripcion,
        "sendero_id": r.sendero_id, "sendero_nombre": r.sendero.nombre,
        "usuario_nombre": _nombre(r.usuario),
        "fecha": _local(r.fecha_creacion),
        "distancia_sendero_m": round(r.distancia_sendero_m, 1) if r.distancia_sendero_m is not None else None,
        "lat": r.ubicacion.y, "lon": r.ubicacion.x,
        "fotos": [_url(request, f.imagen) for f in r.fotos.all()],
    } for r in qs]


def _recorridos(request):
    qs = (SesionCaminata.objects.filter(estado='finalizada', traza__isnull=False)
          .select_related('usuario', 'sendero').order_by('-iniciado_en')[:LIMITE_RECORRIDOS])

    resultado = []
    for s in qs:
        coords = _latlon(s.traza.simplify(TOLERANCIA_GRADOS, preserve_topology=True))
        if len(coords) < 2:
            continue
        resultado.append({
            "id": s.id, "numero_usuario": s.numero_usuario,
            "usuario_nombre": _nombre(s.usuario),
            "fecha": _local(s.iniciado_en),
            "distancia_km": s.distancia_km, "duracion_segundos": s.duracion_segundos,
            "velocidad_promedio_kmh": s.velocidad_promedio_kmh, "pasos": s.pasos,
            "sendero_id": s.sendero_id, "sendero_nombre": s.sendero.nombre if s.sendero else None,
            "coords": coords,
        })
    return resultado


class MapaDatosAPIView(APIView):
    """GET /panel/mapa/datos/: datos de solo lectura para el mapa interactivo."""
    authentication_classes = [SessionAuthentication]
    permission_classes = [IsAuthenticated, EsAdministrador]

    def get(self, request):
        return Response({
            "senderos": _senderos(request),
            "incidencias": _incidencias(request),
            "recorridos": _recorridos(request),
            "generado": _local(timezone.now(), '%H:%M:%S'),
        })