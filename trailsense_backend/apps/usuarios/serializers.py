from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import CodigoVerificacion

Usuario = get_user_model()

class LoginSerializer(serializers.Serializer):
    """
    Serializer utilizado para iniciar sesión.
    ...
    """
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


class RequestPasswordResetSerializer(serializers.Serializer):
    """
    Solicita un código de recuperación de contraseña.
    """
    email = serializers.EmailField()

    def validate_email(self, value):
        return value.lower().strip()


class ResetPasswordSerializer(serializers.Serializer):
    """
    Confirma el código de recuperación y establece la nueva contraseña.
    """
    email = serializers.EmailField()

    codigo = serializers.CharField(min_length=4, max_length=4)

    password = serializers.CharField(
        write_only=True,
        min_length=8,
        style={"input_type": "password"}
    )

    password2 = serializers.CharField(
        write_only=True,
        style={"input_type": "password"}
    )

    def validate_email(self, value):
        return value.lower().strip()

    def validate_codigo(self, value):
        if not value.isdigit():
            raise serializers.ValidationError(
                "El código debe contener únicamente números."
            )
        return value

    def validate(self, attrs):
        if attrs.get("password") != attrs.get("password2"):
            raise serializers.ValidationError({
                "password2": "Las contraseñas no coinciden."
            })
        return attrs


class EditarPerfilSerializer(serializers.ModelSerializer):
    """
    Serializer para editar el perfil del usuario.
    """
    nombre = serializers.CharField(source="first_name", required=False, allow_blank=True)
    apellido = serializers.CharField(source="last_name", required=False, allow_blank=True)
    foto_perfil = serializers.ImageField(required=False, allow_null=True)

    class Meta:
        model = Usuario
        fields = [
            "nombre", "apellido", "foto_perfil",
            "cedula", "telefono", "genero", "fecha_nacimiento",   # NUEVOS
        ]

    def validate_cedula(self, value):
        if value and (not value.isdigit() or len(value) != 10):
            raise serializers.ValidationError("La cédula debe tener 10 dígitos numéricos.")
        return value

    def update(self, instance, validated_data):
        for field in ["first_name", "last_name", "cedula", "telefono", "genero", "fecha_nacimiento"]:
            if field in validated_data:
                setattr(instance, field, validated_data[field])
        if "foto_perfil" in validated_data:
            instance.foto_perfil = validated_data["foto_perfil"]
        instance.save()
        return instance


class CambiarPasswordSerializer(serializers.Serializer):
    """
    Cambio de contraseña estando autenticado (distinto del flujo de recuperación).
    """
    password_actual = serializers.CharField(write_only=True)
    password_nueva = serializers.CharField(write_only=True, min_length=8)
    password_nueva2 = serializers.CharField(write_only=True)

    def validate(self, attrs):
        if attrs["password_nueva"] != attrs["password_nueva2"]:
            raise serializers.ValidationError({"password_nueva2": "Las contraseñas no coinciden."})
        return attrs
        

class UsuarioSerializer(serializers.ModelSerializer):
    """
    Serializer para obtener información del usuario.
    """

    foto_perfil_url = serializers.SerializerMethodField()

    fecha_registro = serializers.DateTimeField(
        source="date_joined",
        read_only=True
    )

    nombre = serializers.CharField(
        source="first_name",
        read_only=True
    )

    apellido = serializers.CharField(
        source="last_name",
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
            "cedula",
            "telefono",
            "genero",
            "fecha_nacimiento",
        ]

        read_only_fields = fields

    def get_foto_perfil_url(self, obj):
        if not obj.foto_perfil:
            return None

        request = self.context.get("request")

        if request:
            return request.build_absolute_uri(obj.foto_perfil.url)

        return obj.foto_perfil.url