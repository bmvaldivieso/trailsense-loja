from rest_framework_gis.serializers import GeoFeatureModelSerializer
from .models import Sendero


class SenderoSerializer(GeoFeatureModelSerializer):
    class Meta:
        model = Sendero
        geo_field = "geometria"
        fields = [
            "id", "nombre", "descripcion", "canton",
            "dificultad", "estado", "longitud_km",
            "horario_apertura", "horario_cierre",
            "imagen_portada", "creado_en", "actualizado_en",
        ]