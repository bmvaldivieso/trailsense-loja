from django.contrib.gis.geos import Point
from django.contrib.gis.db.models.functions import Distance
from django.contrib.gis.measure import D
from rest_framework_gis.pagination import GeoJsonPagination

from rest_framework import viewsets, permissions
from .models import Sendero
from .serializers import SenderoSerializer
from core.permissions.roles import EsAdminOSuperusuario

from django.shortcuts import get_object_or_404
from django.db.models import Count, Sum
from apps.sesiones.models import SesionCaminata

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status


class SenderoViewSet(viewsets.ModelViewSet):
    serializer_class = SenderoSerializer
    pagination_class = GeoJsonPagination

    def get_permissions(self):
        if self.action in ('create', 'update', 'partial_update', 'destroy'):
            return [permissions.IsAuthenticated(), EsAdminOSuperusuario()]
        return [permissions.IsAuthenticated()]

    def get_queryset(self):
        qs = Sendero.objects.all()
        params = self.request.query_params

        dificultad = params.get('dificultad')
        if dificultad:
            qs = qs.filter(dificultad=dificultad)

        estado = params.get('estado')
        if estado:
            qs = qs.filter(estado=estado)

        longitud_min = params.get('longitud_min')
        if longitud_min:
            qs = qs.filter(longitud_km__gte=float(longitud_min))

        longitud_max = params.get('longitud_max')
        if longitud_max:
            qs = qs.filter(longitud_km__lte=float(longitud_max))

        lat = params.get('lat')
        lon = params.get('lon')
        radio_km = params.get('radio_km')

        if lat and lon:
            punto = Point(float(lon), float(lat), srid=4326)
            qs = qs.annotate(distancia=Distance('geometria', punto))
            if radio_km:
                qs = qs.filter(geometria__distance_lte=(punto, D(km=float(radio_km))))
            qs = qs.order_by('distancia')

        return qs


class SenderoEstadisticasView(APIView):
    """
    GET /api/senderos/<id>/estadisticas/

    Indicadores de uso de un sendero (Sprint 9): cuántos recorridos
    finalizados tuvo, distancia total caminada en él y cuántos
    senderistas distintos lo han recorrido.
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, pk):
        sendero = get_object_or_404(Sendero, pk=pk)
        stats = SesionCaminata.objects.filter(sendero=sendero, estado='finalizada').aggregate(
            total_recorridos=Count('id'),
            distancia_total_km=Sum('distancia_km'),
            senderistas_unicos=Count('usuario', distinct=True),
        )
        return Response({
            "sendero_id": sendero.id,
            "sendero_nombre": sendero.nombre,
            "total_recorridos": stats['total_recorridos'] or 0,
            "distancia_total_km": round(stats['distancia_total_km'] or 0, 2),
            "senderistas_unicos": stats['senderistas_unicos'] or 0,
        })        