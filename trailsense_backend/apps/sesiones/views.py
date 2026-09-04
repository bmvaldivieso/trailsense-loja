from django.utils import timezone
from django.contrib.gis.geos import LineString, Point
from django.contrib.gis.db.models.functions import Length

from rest_framework import status, generics
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated

from .models import SesionCaminata, PuntoGPS
from .serializers import (
    SesionListSerializer,
    SesionDetailSerializer,
    IniciarSesionSerializer,
    PuntoGPSInputSerializer,
)


class SesionesListView(generics.ListAPIView):
    """GET /api/sesiones/ -> mis sesiones."""
    serializer_class = SesionListSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return SesionCaminata.objects.filter(usuario=self.request.user)


class SesionDetailView(generics.RetrieveAPIView):
    """GET /api/sesiones/<id>/ -> detalle con traza completa."""
    serializer_class = SesionDetailSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return SesionCaminata.objects.filter(usuario=self.request.user)


class IniciarSesionView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = IniciarSesionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        sesion = SesionCaminata.objects.create(
            usuario=request.user,
            sendero=serializer.validated_data.get('sendero'),
            estado='en_curso',
        )
        return Response(SesionDetailSerializer(sesion).data, status=status.HTTP_201_CREATED)


class EnviarPuntosView(APIView):
    """
    POST /api/sesiones/<id>/puntos/

    Recibe un LOTE de puntos GPS capturados de forma oportunista
    mientras la sesión está en curso (Sprint 8).
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        try:
            sesion = SesionCaminata.objects.get(pk=pk, usuario=request.user)
        except SesionCaminata.DoesNotExist:
            return Response({"detail": "Sesión no encontrada."}, status=status.HTTP_404_NOT_FOUND)

        if sesion.estado == 'finalizada':
            return Response({"detail": "La sesión ya fue finalizada."}, status=status.HTTP_400_BAD_REQUEST)

        puntos_data = request.data if isinstance(request.data, list) else request.data.get('puntos', [])
        serializer = PuntoGPSInputSerializer(data=puntos_data, many=True)
        serializer.is_valid(raise_exception=True)

        objetos = [
            PuntoGPS(
                sesion=sesion,
                ubicacion=Point(item['lon'], item['lat'], srid=4326),
                capturado_en=item['capturado_en'],
                precision_m=item.get('precision_m'),
                altitud_m=item.get('altitud_m'),
                velocidad_mps=item.get('velocidad_mps'),
            )
            for item in serializer.validated_data
        ]
        PuntoGPS.objects.bulk_create(objetos)

        return Response(
            {"detail": f"{len(objetos)} puntos recibidos.", "total_puntos": sesion.puntos.count()},
            status=status.HTTP_201_CREATED,
        )


class PausarSesionView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        try:
            sesion = SesionCaminata.objects.get(pk=pk, usuario=request.user, estado='en_curso')
        except SesionCaminata.DoesNotExist:
            return Response({"detail": "Sesión no encontrada o no está en curso."}, status=status.HTTP_404_NOT_FOUND)

        sesion.estado = 'pausada'
        sesion.save(update_fields=['estado'])
        return Response(SesionDetailSerializer(sesion).data)


class ReanudarSesionView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        try:
            sesion = SesionCaminata.objects.get(pk=pk, usuario=request.user, estado='pausada')
        except SesionCaminata.DoesNotExist:
            return Response({"detail": "Sesión no encontrada o no está pausada."}, status=status.HTTP_404_NOT_FOUND)

        sesion.estado = 'en_curso'
        sesion.save(update_fields=['estado'])
        return Response(SesionDetailSerializer(sesion).data)


class FinalizarSesionView(APIView):
    """
    POST /api/sesiones/<id>/finalizar/

    Base del Sprint 9: construye el LineString real desde los puntos
    GPS acumulados y calcula distancia/duración/velocidad promedio
    usando funciones nativas de PostGIS (ST_Length vía Length()).
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        try:
            sesion = SesionCaminata.objects.get(pk=pk, usuario=request.user)
        except SesionCaminata.DoesNotExist:
            return Response({"detail": "Sesión no encontrada."}, status=status.HTTP_404_NOT_FOUND)

        if sesion.estado == 'finalizada':
            return Response(SesionDetailSerializer(sesion).data)

        tiempo_pausado = int(request.data.get('tiempo_pausado_segundos', 0))
        pasos = int(request.data.get('pasos', 0))

        puntos = list(sesion.puntos.order_by('capturado_en'))

        if len(puntos) >= 2:
            coords = [(p.ubicacion.x, p.ubicacion.y) for p in puntos]
            sesion.traza = LineString(coords, srid=4326)

        sesion.finalizado_en = timezone.now()
        sesion.tiempo_pausado_segundos = tiempo_pausado
        sesion.pasos = pasos
        sesion.estado = 'finalizada'

        duracion_total = (sesion.finalizado_en - sesion.iniciado_en).total_seconds() - tiempo_pausado
        sesion.duracion_segundos = max(int(duracion_total), 0)
        sesion.save()

        if sesion.traza:
            resultado = SesionCaminata.objects.filter(pk=sesion.pk).annotate(
                longitud=Length('traza')
            ).first()
            distancia_m = resultado.longitud.m if resultado.longitud else 0
            sesion.distancia_km = round(distancia_m / 1000, 3)

            if sesion.duracion_segundos > 0:
                sesion.velocidad_promedio_kmh = round(
                    sesion.distancia_km / (sesion.duracion_segundos / 3600), 2
                )
            sesion.save(update_fields=['distancia_km', 'velocidad_promedio_kmh'])

        return Response(SesionDetailSerializer(sesion).data)