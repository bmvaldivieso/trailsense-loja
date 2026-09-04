from rest_framework import serializers
from apps.senderos.models import Sendero
from .models import SesionCaminata, PuntoGPS


class IniciarSesionSerializer(serializers.Serializer):
    sendero = serializers.PrimaryKeyRelatedField(
        queryset=Sendero.objects.all(), required=False, allow_null=True
    )


class PuntoGPSInputSerializer(serializers.Serializer):
    lat = serializers.FloatField()
    lon = serializers.FloatField()
    capturado_en = serializers.DateTimeField()
    precision_m = serializers.FloatField(required=False, allow_null=True)
    altitud_m = serializers.FloatField(required=False, allow_null=True)
    velocidad_mps = serializers.FloatField(required=False, allow_null=True)


class SesionListSerializer(serializers.ModelSerializer):
    """Liviano: para el listado en sesiones_screen.dart."""
    sendero_nombre = serializers.SerializerMethodField()
    punto_inicio = serializers.SerializerMethodField()

    class Meta:
        model = SesionCaminata
        fields = [
            'id', 'sendero', 'sendero_nombre', 'estado',
            'iniciado_en', 'finalizado_en',
            'distancia_km', 'duracion_segundos', 'velocidad_promedio_kmh', 'pasos',
            'punto_inicio',
        ]
        read_only_fields = fields

    def get_sendero_nombre(self, obj):
        return obj.sendero.nombre if obj.sendero else None

    def get_punto_inicio(self, obj):
        if obj.traza:
            lon, lat = obj.traza[0]
            return {"lat": lat, "lon": lon}
        return None


class SesionDetailSerializer(SesionListSerializer):
    """Incluye la traza completa: para detalle_recorrido_screen.dart."""
    traza = serializers.SerializerMethodField()

    class Meta(SesionListSerializer.Meta):
        fields = SesionListSerializer.Meta.fields + ['traza']
        read_only_fields = fields

    def get_traza(self, obj):
        if not obj.traza:
            return []
        return [[coord[1], coord[0]] for coord in obj.traza.coords]   # [lat, lon]