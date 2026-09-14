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

from django.db.models import Count, Sum 
from .matching import detectar_sendero_cercano, detectar_sendero_para_sesion

from rest_framework.authentication import SessionAuthentication
from core.permissions.roles import EsAdminOSuperusuario


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

        sendero = serializer.validated_data.get('sendero')
        lat = serializer.validated_data.get('lat')
        lon = serializer.validated_data.get('lon')

        # Si no se especificó sendero pero sí ubicación, detecta el más cercano
        if sendero is None and lat is not None and lon is not None:
            sendero = detectar_sendero_cercano(Point(lon, lat, srid=4326))

        sesion = SesionCaminata.objects.create(
            usuario=request.user,
            sendero=sendero,
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

        # Vinculación autoritativa sendero-recorrido (Sprint 9)
        sesion.sendero = detectar_sendero_para_sesion(sesion)

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

        # Alimenta el perfil del senderista (Sprint 9)
        usuario = sesion.usuario
        usuario.kilometros_recorridos = (usuario.kilometros_recorridos or 0) + sesion.distancia_km
        usuario.save(update_fields=['kilometros_recorridos'])

        return Response(SesionDetailSerializer(sesion).data)




class RecorridosPorUsuarioView(APIView):
    """
    GET /api/sesiones/panel/  (solo administrador/superusuario)

    Devuelve todos los recorridos finalizados, agrupados por senderista,
    para el listado de recorridos del panel web (Sprint 14).
    """
    authentication_classes = [SessionAuthentication]
    permission_classes = [IsAuthenticated, EsAdminOSuperusuario]

    def get(self, request):
        usuarios_con_sesiones = {}
        # Se traen todos los recorridosy cada recorrido lleva su propio campo "estado" para que el panel decida qué mostrar
        sesiones = SesionCaminata.objects.select_related('usuario', 'sendero').order_by('-iniciado_en')

        for s in sesiones:
            uid = s.usuario_id
            if uid not in usuarios_con_sesiones:
                usuarios_con_sesiones[uid] = {
                    "usuario_id": uid,
                    "usuario_nombre": f"{s.usuario.first_name} {s.usuario.last_name}".strip() or s.usuario.email,
                    "usuario_foto": request.build_absolute_uri(s.usuario.foto_perfil.url) if s.usuario.foto_perfil else None,
                    "recorridos": [],
                }
            usuarios_con_sesiones[uid]["recorridos"].append({
                "id": s.id,
                "fecha": s.iniciado_en.strftime("%d.%m.%Y %I:%M %p"),
                "distancia_km": s.distancia_km,
                "sendero_nombre": s.sendero.nombre if s.sendero else None,
                "estado": s.estado,
            })

        return Response(list(usuarios_con_sesiones.values()))


class RecorridoDetalleAdminView(APIView):
    """
    GET /api/sesiones/panel/<id>/  (solo administrador/superusuario)

    Detalle completo de un recorrido, reutilizando SesionDetailSerializer
    (ya incluye traza, distancia, duración, velocidad promedio y pasos).
    """
    authentication_classes = [SessionAuthentication]
    permission_classes = [IsAuthenticated, EsAdminOSuperusuario]

    def get(self, request, pk):
        try:
            sesion = SesionCaminata.objects.select_related('usuario', 'sendero').get(pk=pk)
        except SesionCaminata.DoesNotExist:
            return Response({"detail": "Recorrido no encontrado."}, status=404)

        data = SesionDetailSerializer(sesion, context={'request': request}).data
        data['usuario_nombre'] = f"{sesion.usuario.first_name} {sesion.usuario.last_name}".strip() or sesion.usuario.email
        data['usuario_foto'] = request.build_absolute_uri(sesion.usuario.foto_perfil.url) if sesion.usuario.foto_perfil else None
        return Response(data)