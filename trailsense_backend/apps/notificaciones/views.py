from django.shortcuts import get_object_or_404
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import NotificacionLeida
from .servicios import contar_no_leidas, con_estado_lectura, evaluar_proximidad, visibles_para


def _imagen_url(n, request):
    if n.imagen:
        return request.build_absolute_uri(n.imagen.url)
    if n.reporte_id:   # las automáticas de proximidad usan la foto del reporte
        fotos = list(n.reporte.fotos.all())
        if fotos:
            return request.build_absolute_uri(fotos[0].imagen.url)
    return None

def _sendero_imagen_url(n, request):
    if n.sendero_id and n.sendero.imagen_portada:
        return request.build_absolute_uri(n.sendero.imagen_portada.url)
    return None

def _a_dict(n, request, leida=None):
    return {
        "id": n.id, "titulo": n.titulo, "mensaje": n.mensaje,
        "tipo": n.tipo, "tipo_display": n.get_tipo_display(), "origen": n.origen,
        "imagen": _imagen_url(n, request),
        "fecha": n.fecha_creacion.isoformat(),
        "leida": leida if leida is not None else getattr(n, 'leida', False),
        "sendero_id": n.sendero_id, "sendero_nombre": n.sendero.nombre if n.sendero else None,
        "sendero_imagen": _sendero_imagen_url(n, request),
        "reporte_id": n.reporte_id,
    }


class NotificacionesListView(APIView):
    """GET /api/notificaciones/ — mis notificaciones (las 100 más recientes) + contador sin leer."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        qs = (con_estado_lectura(visibles_para(request.user), request.user)
              .select_related('sendero', 'reporte').prefetch_related('reporte__fotos')[:100])
        return Response({
            "no_leidas": contar_no_leidas(request.user),
            "notificaciones": [_a_dict(n, request) for n in qs],
        })


class NotificacionDetalleView(APIView):
    """GET /api/notificaciones/<id>/ — detalle; al abrirla se marca como leída."""
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        n = get_object_or_404(visibles_para(request.user).select_related('sendero', 'reporte'), pk=pk)
        NotificacionLeida.objects.get_or_create(usuario=request.user, notificacion=n)
        return Response(_a_dict(n, request, leida=True))


class ProximidadView(APIView):
    """POST /api/notificaciones/proximidad/ {lat, lon} — evalúa si corresponde un aviso por incidencia cercana."""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        try:
            lat, lon = float(request.data.get('lat')), float(request.data.get('lon'))
        except (TypeError, ValueError):
            return Response({"error": "coordenadas_invalidas", "message": "lat y lon son obligatorios."}, status=400)
        if not (-90 <= lat <= 90 and -180 <= lon <= 180):
            return Response({"error": "coordenadas_invalidas", "message": "Coordenadas fuera de rango."}, status=400)

        n = evaluar_proximidad(request.user, lat, lon)
        return Response({"notificacion": _a_dict(n, request, leida=False) if n else None})