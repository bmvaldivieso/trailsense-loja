from rest_framework import serializers
from apps.senderos.models import Sendero
from .models import Reporte, FotoReporte


class ReporteCreateSerializer(serializers.Serializer):
    """Valida los campos de texto; las fotos se manejan aparte (multipart)."""
    sendero = serializers.PrimaryKeyRelatedField(queryset=Sendero.objects.all())
    lat = serializers.FloatField()
    lon = serializers.FloatField()
    altitud = serializers.FloatField(required=False, allow_null=True)
    categoria = serializers.ChoiceField(choices=Reporte.CATEGORIA_CHOICES)
    descripcion = serializers.CharField(max_length=500)


class FotoReporteSerializer(serializers.ModelSerializer):
    class Meta:
        model = FotoReporte
        fields = ['id', 'imagen', 'orden']


class ReporteListSerializer(serializers.ModelSerializer):
    sendero_nombre = serializers.CharField(source='sendero.nombre', read_only=True)
    usuario_email = serializers.CharField(source='usuario.email', read_only=True)
    foto_portada = serializers.SerializerMethodField()
    lat = serializers.SerializerMethodField()
    lon = serializers.SerializerMethodField()

    class Meta:
        model = Reporte
        fields = [
            'id', 'sendero', 'sendero_nombre', 'usuario_email', 'categoria',
            'descripcion', 'validado', 'votos_confirmacion', 'fecha_creacion',
            'foto_portada', 'lat', 'lon',
        ]
        read_only_fields = fields

    def get_foto_portada(self, obj):
        primera = obj.fotos.order_by('orden').first()
        if not primera:
            return None
        request = self.context.get('request')
        return request.build_absolute_uri(primera.imagen.url) if request else primera.imagen.url

    def get_lat(self, obj):
        return obj.ubicacion.y

    def get_lon(self, obj):
        return obj.ubicacion.x


class ReporteDetailSerializer(ReporteListSerializer):
    fotos = FotoReporteSerializer(many=True, read_only=True)

    class Meta(ReporteListSerializer.Meta):
        fields = ReporteListSerializer.Meta.fields + ['fotos', 'altitud']
        read_only_fields = fields