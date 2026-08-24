from django.contrib.gis.geos import Point
from django.contrib.gis.db.models.functions import Distance
from django.contrib.gis.measure import D
from rest_framework_gis.pagination import GeoJsonPagination

from rest_framework import viewsets, permissions
from .models import Sendero
from .serializers import SenderoSerializer
from core.permissions.roles import EsAdminOSuperusuario


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