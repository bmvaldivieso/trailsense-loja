from django.contrib.gis.geos import Point
from django.contrib.gis.db.models.functions import Distance

from rest_framework import viewsets, status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated

from .models import Reporte, FotoReporte
from .serializers import ReporteListSerializer, ReporteDetailSerializer, ReporteCreateSerializer


class ReporteViewSet(viewsets.ReadOnlyModelViewSet):
    """
    GET /api/reportes/            -> todos los reportes (con filtros)
    GET /api/reportes/?mios=true  -> solo los del usuario autenticado
    GET /api/reportes/<id>/       -> detalle con todas las fotos
    """
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        qs = Reporte.objects.select_related('sendero', 'usuario').prefetch_related('fotos')
        params = self.request.query_params

        if params.get('mios') == 'true':
            qs = qs.filter(usuario=self.request.user)

        categoria = params.get('categoria')
        if categoria:
            qs = qs.filter(categoria=categoria)

        sendero_id = params.get('sendero')
        if sendero_id:
            qs = qs.filter(sendero_id=sendero_id)

        return qs

    def get_serializer_class(self):
        return ReporteDetailSerializer if self.action == 'retrieve' else ReporteListSerializer

    def get_serializer_context(self):
        return {'request': self.request}


class CrearReporteView(APIView):
    """
    POST /api/reportes/crear/

    Recibe multipart/form-data con los campos de texto + 1 a 5 fotos
    bajo la clave repetida 'fotos'.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = ReporteCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        fotos = request.FILES.getlist('fotos')
        if len(fotos) < 1:
            return Response(
                {"error": "fotos_requeridas", "message": "Debes adjuntar al menos una foto."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if len(fotos) > 5:
            return Response(
                {"error": "maximo_fotos", "message": "Puedes adjuntar máximo 5 fotos."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        punto = Point(data['lon'], data['lat'], srid=4326)

        reporte = Reporte.objects.create(
            usuario=request.user,
            sendero=data['sendero'],
            ubicacion=punto,
            altitud=data.get('altitud'),
            categoria=data['categoria'],
            descripcion=data['descripcion'],
        )

        # NUEVO (preparación Sprint 11): distancia real al sendero, sin bloquear la creación
        resultado = Reporte.objects.filter(pk=reporte.pk).annotate(
            dist=Distance('ubicacion', data['sendero'].geometria)
        ).first()
        reporte.distancia_sendero_m = resultado.dist.m if resultado.dist else None
        reporte.save(update_fields=['distancia_sendero_m'])

        for i, foto in enumerate(fotos):
            FotoReporte.objects.create(reporte=reporte, imagen=foto, orden=i)

        return Response(
            ReporteDetailSerializer(reporte, context={'request': request}).data,
            status=status.HTTP_201_CREATED,
        )