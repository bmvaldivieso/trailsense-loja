from django.contrib.gis.geos import GEOSGeometry
from rest_framework.authentication import SessionAuthentication
from rest_framework.parsers import JSONParser, MultiPartParser
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from core.permissions.roles import EsAdminOSuperusuario
from .servicios_geo import (
    MAX_BYTES, ArchivoTrazaError, direccion_desde_puntos, procesar_traza,
)


class ProcesarTrazaAPIView(APIView):
    authentication_classes = [SessionAuthentication]
    permission_classes = [IsAuthenticated, EsAdminOSuperusuario]
    parser_classes = [MultiPartParser]

    def post(self, request):
        archivo = request.FILES.get('archivo')
        if not archivo:
            return Response({'message': 'No se recibió ningún archivo.'}, status=400)
        if archivo.size > MAX_BYTES:
            return Response({'message': 'El archivo supera los 10 MB permitidos.'}, status=400)
        try:
            return Response(procesar_traza(archivo.read(), archivo.name))
        except ArchivoTrazaError as e:
            return Response({'message': str(e)}, status=400)


class DireccionSugeridaAPIView(APIView):
    authentication_classes = [SessionAuthentication]
    permission_classes = [IsAuthenticated, EsAdminOSuperusuario]
    parser_classes = [JSONParser]

    def post(self, request):
        try:
            geom = GEOSGeometry(request.data.get('wkt', ''), srid=4326)
            if geom.geom_type != 'LineString':
                raise ValueError
        except Exception:
            return Response({'message': 'Dibuja o carga primero el trazado del sendero.'}, status=400)

        puntos = [(lat, lon) for lon, lat in geom.coords]
        resultado = direccion_desde_puntos(puntos)
        if not resultado['texto']:
            resultado['aviso'] = 'No se encontraron calles para este trazado. Puedes escribirlas manualmente.'
        return Response(resultado)