from django.contrib.gis.geos import Point
from django.contrib.gis.db.models.functions import Distance as GDistance

from rest_framework import viewsets, status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated

from apps.senderos.models import Sendero


from django.db import transaction, IntegrityError
from django.db.models import F
from django.contrib.gis.measure import D
from django.utils import timezone
from datetime import timedelta
from rest_framework.decorators import action

from .models import Reporte, FotoReporte, VotoReporte


from .serializers import ReporteListSerializer, ReporteDetailSerializer, ReporteCreateSerializer
from .validaciones import (
    validar_proximidad_sendero,
    validar_no_duplicado,
    validar_limite_diario,
    buscar_reportes_similares,
    RADIO_SIMILAR_M,
    VENTANA_SIMILAR_DIAS,
    ValidacionReporteError,
)
from .reputacion import actualizar_reputacion, PUNTOS_POR_REPORTE_CREADO

from django.shortcuts import get_object_or_404
from rest_framework.authentication import SessionAuthentication

from core.permissions.roles import EsAdminOSuperusuario
from apps.senderos.serializers import SenderoSerializer
from .reputacion import actualizar_reputacion, PUNTOS_POR_REPORTE_VALIDADO, PUNTOS_POR_REPORTE_RECHAZADO

from apps.actividad.utils import registrar_actividad

import logging
from apps.notificaciones.servicios import evaluar_acumulacion
logger = logging.getLogger(__name__)


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

    @action(detail=False, methods=['get'], url_path='similares')
    def similares(self, request):
        """GET /api/reportes/similares/?sendero=&categoria=&lat=&lon="""
        try:
            sendero_id = int(request.query_params['sendero'])
            lat = float(request.query_params['lat'])
            lon = float(request.query_params['lon'])
        except (KeyError, ValueError):
            return Response({"error": "parametros_invalidos", "message": "Faltan sendero, lat o lon."}, status=400)

        categoria = request.query_params.get('categoria')
        if categoria not in dict(Reporte.CATEGORIA_CHOICES):
            return Response({"error": "categoria_invalida", "message": "Categoría no válida."}, status=400)

        punto = Point(lon, lat, srid=4326)
        similares = buscar_reportes_similares(request.user, sendero_id, categoria, punto)
        return Response(ReporteDetailSerializer(similares, many=True, context={'request': request}).data)

    @action(detail=True, methods=['post'], url_path='votar')
    def votar(self, request, pk=None):
        """POST /api/reportes/<id>/votar/  body: {lat, lon}. El voto no se puede revertir."""
        reporte = get_object_or_404(Reporte, pk=pk)

        if reporte.usuario_id == request.user.id:
            return Response({"error": "voto_propio", "message": "No puedes votar tu propio reporte."}, status=400)
        if reporte.estado == 'rechazado':
            return Response({"error": "reporte_rechazado", "message": "Este reporte ya fue rechazado."}, status=400)
        if reporte.fecha_creacion < timezone.now() - timedelta(days=VENTANA_SIMILAR_DIAS):
            return Response({"error": "reporte_antiguo", "message": "Este reporte ya no admite votos."}, status=400)

        try:
            punto = Point(float(request.data['lon']), float(request.data['lat']), srid=4326)
        except (KeyError, TypeError, ValueError):
            return Response({"error": "parametros_invalidos", "message": "Faltan lat y lon."}, status=400)

        # El voto solo es válido estando en el lugar del reporte
        cerca = (Reporte.objects.filter(pk=reporte.pk)
                 .annotate(dist=GDistance('ubicacion', punto))
                 .filter(dist__lte=D(m=RADIO_SIMILAR_M)).exists())
        if not cerca:
            return Response({"error": "fuera_de_rango", "message": "Debes estar en el lugar del reporte para confirmarlo."}, status=400)

        try:
            with transaction.atomic():
                VotoReporte.objects.create(reporte=reporte, usuario=request.user)
                Reporte.objects.filter(pk=reporte.pk).update(votos_confirmacion=F('votos_confirmacion') + 1)
        except IntegrityError:
            return Response({"error": "ya_votaste", "message": "Ya votaste por este reporte."}, status=400)

        reporte.refresh_from_db(fields=['votos_confirmacion'])
        return Response({"votos_confirmacion": reporte.votos_confirmacion})    


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
            return Response({"error": "fotos_requeridas", "message": "Debes adjuntar al menos una foto."}, status=status.HTTP_400_BAD_REQUEST)
        if len(fotos) > 5:
            return Response({"error": "maximo_fotos", "message": "Puedes adjuntar máximo 5 fotos."}, status=status.HTTP_400_BAD_REQUEST)

        punto = Point(data['lon'], data['lat'], srid=4326)
        sendero = data['sendero']

        # Distancia real al sendero, calculada ANTES de crear el reporte
        resultado_dist = Sendero.objects.filter(pk=sendero.pk).annotate(
            dist=GDistance('geometria', punto)
        ).first()
        distancia_m = resultado_dist.dist.m if resultado_dist and resultado_dist.dist else None

        # Validaciones anti-spam y de proximidad
        try:
            validar_proximidad_sendero(sendero, distancia_m)
            validar_no_duplicado(request.user, punto)
            validar_limite_diario(request.user)
        except ValidacionReporteError as err:
            return Response({"error": err.codigo, "message": err.mensaje}, status=status.HTTP_400_BAD_REQUEST)

        reporte = Reporte.objects.create(
            usuario=request.user,
            sendero=sendero,
            ubicacion=punto,
            altitud=data.get('altitud'),
            categoria=data['categoria'],
            descripcion=data['descripcion'],
            distancia_sendero_m=distancia_m,   # Ya no se recalcula después de crear
        )

        for i, foto in enumerate(fotos):
            FotoReporte.objects.create(reporte=reporte, imagen=foto, orden=i)

        # Recompensa de reputación por participar
        actualizar_reputacion(request.user, PUNTOS_POR_REPORTE_CREADO)

        # Alimenta el contador de reportes del perfil, igual que
        # kilometros_recorridos se actualiza al finalizar una sesión
        request.user.total_reportes = (request.user.total_reportes or 0) + 1
        request.user.save(update_fields=['total_reportes'])

        registrar_actividad(request.user, 'reporte_creado', f"Categoría: {reporte.get_categoria_display()}")

        try:
            evaluar_acumulacion(reporte)
        except Exception:
            logger.exception("No se pudo evaluar la acumulación de reportes") 

        return Response(
            ReporteDetailSerializer(reporte, context={'request': request}).data,
            status=status.HTTP_201_CREATED,
        )



class ReportesPanelListView(APIView):
    """GET /api/reportes/panel/ — listado completo + indicadores, para el panel (DataTables)."""
    authentication_classes = [SessionAuthentication]
    permission_classes = [IsAuthenticated, EsAdminOSuperusuario]

    def get(self, request):
        reportes = Reporte.objects.select_related('usuario', 'sendero').order_by('-votos_confirmacion', '-fecha_creacion')

        data = [{
            "id": r.id,
            "usuario_nombre": f"{r.usuario.first_name} {r.usuario.last_name}".strip() or r.usuario.email,
            "sendero_nombre": r.sendero.nombre if r.sendero else '',
            "categoria": r.get_categoria_display(),
            "votos": r.votos_confirmacion,
            "estado": r.estado,
            "fecha_creacion": r.fecha_creacion.strftime("%d-%m-%Y"),
        } for r in reportes]

        contadores = {
            "total": reportes.count(),
            "pendientes": reportes.filter(estado='pendiente').count(),
            "aprobados": reportes.filter(estado='aprobado').count(),
            "rechazados": reportes.filter(estado='rechazado').count(),
        }
        return Response({"reportes": data, "contadores": contadores})


class SenderosCercanosPanelView(APIView):
    """GET /api/reportes/panel/senderos-geojson/ — senderos en GeoJSON, para dibujarlos de referencia en el mapa de detalle."""
    authentication_classes = [SessionAuthentication]
    permission_classes = [IsAuthenticated, EsAdminOSuperusuario]

    def get(self, request):
        senderos = Sendero.objects.all()
        return Response(SenderoSerializer(senderos, many=True, context={'request': request}).data)


class ReporteDetalleAdminView(APIView):
    """GET/POST /api/reportes/panel/<id>/ — detalle y revisión (aprobar/rechazar) de un reporte."""
    authentication_classes = [SessionAuthentication]
    permission_classes = [IsAuthenticated, EsAdminOSuperusuario]

    def get(self, request, pk):
        reporte = get_object_or_404(
            Reporte.objects.select_related('usuario', 'sendero').prefetch_related('fotos'), pk=pk
        )
        return Response(ReporteDetailSerializer(reporte, context={'request': request}).data)

    def post(self, request, pk):
        reporte = get_object_or_404(Reporte, pk=pk)
        nuevo_estado = request.data.get('estado')
        comentario = request.data.get('comentario_admin', '').strip()

        if nuevo_estado not in ('pendiente', 'aprobado', 'rechazado'):
            return Response({"error": "estado_invalido", "message": "Estado no válido."}, status=400)

        if nuevo_estado == 'rechazado' and not comentario:
            return Response({"error": "comentario_requerido", "message": "El comentario es obligatorio al rechazar un reporte."}, status=400)

        estado_anterior = reporte.estado
        reporte.estado = nuevo_estado
        reporte.comentario_admin = comentario
        reporte.save(update_fields=['estado', 'comentario_admin'])

        # Aplica la reputación preparada desde el Sprint 11
        if estado_anterior != nuevo_estado:
            if nuevo_estado == 'aprobado':
                actualizar_reputacion(reporte.usuario, PUNTOS_POR_REPORTE_VALIDADO)
            elif nuevo_estado == 'rechazado':
                actualizar_reputacion(reporte.usuario, -PUNTOS_POR_REPORTE_RECHAZADO)

        return Response(ReporteDetailSerializer(reporte, context={'request': request}).data)
