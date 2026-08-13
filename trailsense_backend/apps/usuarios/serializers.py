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

    El usuario se crea inicialmente:
    - is_active=False
    - is_verified=False

    La cuenta se activa únicamente después de verificar
    correctamente el código enviado al correo.
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
        """
        Comprueba que el correo no esté registrado.
        """
        value = value.lower().strip()

        if Usuario.objects.filter(email__iexact=value).exists():
            raise serializers.ValidationError(
                "El correo electrónico ya está registrado."
            )

        return value

    def validate(self, attrs):
        """
        Validaciones generales del registro.
        """
        password = attrs.get("password")
        password2 = attrs.get("password2")

        if password != password2:
            raise serializers.ValidationError({
                "password2": "Las contraseñas no coinciden."
            })

        return attrs

    def create(self, validated_data):
        """
        Crea el usuario utilizando set_password mediante create_user.
        """
        validated_data.pop("password2")

        password = validated_data.pop("password")
        email = validated_data["email"]

        # Tu modelo actual tiene username como REQUIRED_FIELD.
        # Usamos el correo como username para no pedir otro dato
        # innecesario al usuario.
        username = email

        usuario = Usuario.objects.create_user(
            username=username,
            email=email,
            password=password,
            nombre=validated_data.get("nombre", ""),
            apellido=validated_data.get("apellido", ""),
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
        """
        Devuelve la URL absoluta de la foto de perfil.
        """

        if not obj.foto_perfil:
            return None

        request = self.context.get("request")

        if request:
            return request.build_absolute_uri(
                obj.foto_perfil.url
            )

        return obj.foto_perfil.url    