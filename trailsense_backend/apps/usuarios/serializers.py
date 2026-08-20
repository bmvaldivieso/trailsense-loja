from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import CodigoVerificacion

Usuario = get_user_model()

class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)

class RegisterSerializer(serializers.ModelSerializer):
    """
    Serializer utilizado para registrar nuevos usuarios.
    ...
    """

    password = serializers.CharField(
        write_only=True,
        min_length=8,
        style={"input_type": "password"}
    )

    password2 = serializers.CharField(
        write_only=True,
        style={"input_type": "password"}
    )

    foto_perfil = serializers.ImageField(
        required=False,
        allow_null=True
    )

    nombre = serializers.CharField(source="first_name", required=False, allow_blank=True)
    apellido = serializers.CharField(source="last_name", required=False, allow_blank=True)

    class Meta:
        model = Usuario
        fields = [
            "nombre",
            "apellido",
            "email",
            "password",
            "password2",
            "foto_perfil",
        ]

    def validate_email(self, value):
        value = value.lower().strip()

        if Usuario.objects.filter(email__iexact=value).exists():
            raise serializers.ValidationError(
                "Este correo ya está registrado.",
                code="email_already_registered",
            )

        return value

    def validate(self, attrs):
        password = attrs.get("password")
        password2 = attrs.get("password2")
        if password != password2:
            raise serializers.ValidationError({
                "password2": "Las contraseñas no coinciden."
            })
        return attrs

    def create(self, validated_data):
        validated_data.pop("password2")
        password = validated_data.pop("password")
        email = validated_data["email"]
        username = email

        usuario = Usuario.objects.create_user(
            username=username,
            email=email,
            password=password,
            # CAMBIO: ahora validated_data trae "first_name"/"last_name"
            # porque el `source=` en los campos declarados los renombra automáticamente
            first_name=validated_data.get("first_name", ""),
            last_name=validated_data.get("last_name", ""),
            foto_perfil=validated_data.get("foto_perfil"),
            is_active=False,
            is_verified=False,
        )

        return usuario


class VerifyCodeSerializer(serializers.Serializer):
    """
    Serializer para verificar el código enviado al correo.
    """

    email = serializers.EmailField()

    codigo = serializers.CharField(
        min_length=4,
        max_length=4
    )

    def validate_email(self, value):
        return value.lower().strip()

    def validate_codigo(self, value):
        if not value.isdigit():
            raise serializers.ValidationError(
                "El código debe contener únicamente números."
            )

        return value

class UsuarioSerializer(serializers.ModelSerializer):
    """
    Serializer para exponer información pública del usuario.
    """

    foto_perfil_url = serializers.SerializerMethodField()
    fecha_registro = serializers.DateTimeField(
        source="date_joined",
        read_only=True
    )

    # NUEVO: exponer first_name/last_name bajo las llaves "nombre"/"apellido"
    nombre = serializers.CharField(source="first_name", read_only=True)
    apellido = serializers.CharField(source="last_name", read_only=True)

    class Meta:
        model = Usuario
        fields = [
            "id",
            "email",
            "nombre",
            "apellido",
            "rol",
            "foto_perfil_url",
            "fecha_registro",
            "total_reportes",
            "kilometros_recorridos",
            "reputacion_score",
            "is_verified",
        ]
        read_only_fields = fields

    def get_foto_perfil_url(self, obj):
        if not obj.foto_perfil:
            return None
        request = self.context.get("request")
        if request:
            return request.build_absolute_uri(obj.foto_perfil.url)
        return obj.foto_perfil.url  