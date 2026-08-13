# Django
from django.contrib.auth import authenticate, get_user_model
from django.core.mail import send_mail
from django.db import transaction
from django.utils import timezone

# Django Rest Framework (DRF)
from rest_framework import status
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

# Simple JWT (Tokens)
from rest_framework_simplejwt.tokens import RefreshToken

# Librerías estándar de Python
from datetime import timedelta
import secrets

# Módulos locales de la aplicación
from .models import CodigoVerificacion
from .serializers import (
    LoginSerializer,
    RegisterSerializer,
    UsuarioSerializer,
    VerifyCodeSerializer,
)

Usuario = get_user_model()

class LoginView(APIView):
    permission_classes = [AllowAny]
    
    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        email = serializer.validated_data['email']
        password = serializer.validated_data['password']

        user = authenticate(request, username=email, password=password)
        # Si tu USERNAME_FIELD del modelo Usuario es 'email', usa username=email
        if user is None:
            return Response(
                {"detail": "Credenciales incorrectas."},
                status=status.HTTP_401_UNAUTHORIZED
            )

        refresh = RefreshToken.for_user(user)
        return Response({
            "access": str(refresh.access_token),
            "refresh": str(refresh),
            "usuario": {
                "id": user.id,
                "email": user.email,
                "nombre": getattr(user, "nombre", ""),
                "rol": getattr(user, "rol", ""),
            }
        }, status=status.HTTP_200_OK)


class RegisterView(APIView):
    """
    POST /api/auth/register/

    Registra un usuario y genera un código de verificación
    de 4 dígitos con una duración de 15 minutos.
    """

    permission_classes = [AllowAny]

    @transaction.atomic
    def post(self, request):
        serializer = RegisterSerializer(data=request.data)

        if not serializer.is_valid():
            return Response(
                {
                    "detail": "No se pudo completar el registro.",
                    "errors": serializer.errors,
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        usuario = serializer.save()

        # Invalidar códigos anteriores del usuario.
        CodigoVerificacion.objects.filter(
            usuario=usuario,
            usado=False
        ).update(usado=True)

        # Generar código seguro de 4 dígitos.
        codigo = str(secrets.randbelow(9000) + 1000)

        ahora = timezone.now()
        expira_en = ahora + timedelta(minutes=15)

        codigo_verificacion = CodigoVerificacion.objects.create(
            usuario=usuario,
            codigo=codigo,
            expira_en=expira_en,
            usado=False,
        )

        # Enviar correo.
        send_mail(
            subject="Código de verificación - TrailSense Loja",
            message=(
                f"Hola {usuario.nombre},\n\n"
                f"Tu código de verificación para TrailSense es:\n\n"
                f"{codigo}\n\n"
                f"Este código tiene una vigencia de 15 minutos.\n\n"
                f"Si no realizaste este registro, puedes ignorar este mensaje.\n\n"
                f"TrailSense Loja"
            ),
            from_email=None,
            recipient_list=[usuario.email],
            fail_silently=False,
        )

        return Response(
            {
                "detail": (
                    "Registro exitoso. "
                    "Se ha enviado un código de verificación a tu correo."
                ),
                "email": usuario.email,
                "expires_in": 900,
            },
            status=status.HTTP_201_CREATED,
        )

class VerifyCodeView(APIView):
    """
    POST /api/auth/verify-code/

    Verifica el código enviado al correo y activa la cuenta.
    """

    permission_classes = [AllowAny]

    @transaction.atomic
    def post(self, request):
        serializer = VerifyCodeSerializer(data=request.data)

        if not serializer.is_valid():
            return Response(
                {
                    "detail": "Datos de verificación inválidos.",
                    "errors": serializer.errors,
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        email = serializer.validated_data["email"]
        codigo = serializer.validated_data["codigo"]

        # Buscar usuario por correo.
        try:
            usuario = Usuario.objects.get(email__iexact=email)
        except Usuario.DoesNotExist:
            return Response(
                {
                    "detail": "No existe un usuario registrado con ese correo."
                },
                status=status.HTTP_404_NOT_FOUND,
            )

        # Buscar el código no utilizado más reciente.
        codigo_verificacion = (
            CodigoVerificacion.objects
            .filter(
                usuario=usuario,
                usado=False
            )
            .order_by("-creado_en")
            .first()
        )

        if codigo_verificacion is None:
            return Response(
                {
                    "detail": (
                        "No existe un código de verificación activo. "
                        "Solicita un nuevo código."
                    ),
                    "error": "code_not_found",
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Comprobar expiración.
        if not codigo_verificacion.esta_vigente():
            return Response(
                {
                    "detail": (
                        "El código de verificación ha expirado. "
                        "Solicita un nuevo código."
                    ),
                    "error": "code_expired",
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Comprobar código.
        if codigo_verificacion.codigo != codigo:
            return Response(
                {
                    "detail": "El código de verificación es incorrecto.",
                    "error": "invalid_code",
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Código correcto.
        codigo_verificacion.usado = True
        codigo_verificacion.save(update_fields=["usado"])

        # Activar cuenta.
        usuario.is_active = True
        usuario.is_verified = True
        usuario.save(update_fields=["is_active", "is_verified"])

        return Response(
            {
                "detail": "Cuenta verificada correctamente.",
                "verified": True,
                "user": UsuarioSerializer(
                    usuario,
                    context={"request": request}
                ).data,
            },
            status=status.HTTP_200_OK,
        )


class ResendCodeView(APIView):
    """
    POST /api/auth/resend-code/

    Invalida códigos anteriores y genera un nuevo código
    con una vigencia de 15 minutos.
    """

    permission_classes = [AllowAny]

    @transaction.atomic
    def post(self, request):
        email = request.data.get("email", "").lower().strip()

        if not email:
            return Response(
                {
                    "detail": "El correo electrónico es obligatorio."
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            usuario = Usuario.objects.get(email__iexact=email)
        except Usuario.DoesNotExist:
            return Response(
                {
                    "detail": "No existe un usuario registrado con ese correo."
                },
                status=status.HTTP_404_NOT_FOUND,
            )

        # Si ya está verificado no tiene sentido reenviar.
        if usuario.is_verified:
            return Response(
                {
                    "detail": "Esta cuenta ya se encuentra verificada."
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Invalidar códigos anteriores.
        CodigoVerificacion.objects.filter(
            usuario=usuario,
            usado=False
        ).update(usado=True)

        # Generar nuevo código.
        codigo = str(secrets.randbelow(9000) + 1000)

        ahora = timezone.now()
        expira_en = ahora + timedelta(minutes=15)

        CodigoVerificacion.objects.create(
            usuario=usuario,
            codigo=codigo,
            expira_en=expira_en,
            usado=False,
        )

        # Enviar nuevo correo.
        send_mail(
            subject="Nuevo código de verificación - TrailSense Loja",
            message=(
                f"Hola {usuario.nombre},\n\n"
                f"Tu nuevo código de verificación es:\n\n"
                f"{codigo}\n\n"
                f"Este código tiene una vigencia de 15 minutos.\n\n"
                f"TrailSense Loja"
            ),
            from_email=None,
            recipient_list=[usuario.email],
            fail_silently=False,
        )

        return Response(
            {
                "detail": "Se ha enviado un nuevo código de verificación.",
                "email": usuario.email,
                "expires_in": 900,
            },
            status=status.HTTP_200_OK,
        )