# Django
from django.contrib.auth import authenticate, get_user_model
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
    RequestPasswordResetSerializer,
    ResetPasswordSerializer,
)

import logging

from django.conf import settings

from .emails import enviar_correo_verificacion, enviar_correo_recuperacion

from rest_framework.permissions import IsAuthenticated
from .serializers import EditarPerfilSerializer, CambiarPasswordSerializer

from core.permissions.roles import EsAdminOSuperusuario

logger = logging.getLogger(__name__)

Usuario = get_user_model()

class LoginView(APIView):
    permission_classes = [AllowAny]
    
    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        email = serializer.validated_data['email']
        password = serializer.validated_data['password']

        user = authenticate(request, username=email, password=password)
        if user is None:
            return Response(
                {"detail": "Credenciales incorrectas."},
                status=status.HTTP_401_UNAUTHORIZED
            )

        refresh = RefreshToken.for_user(user)
        refresh["rol"] = user.rol          
        access = refresh.access_token
        access["rol"] = user.rol 

        return Response({
            "access": str(access),
            "refresh": str(refresh),
            "usuario": {
                "id": user.id,
                "email": user.email,
                "nombre": user.first_name,  
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
            errors = serializer.errors

            email_errors = errors.get("email")
            if email_errors:
                for err in email_errors:
                    err_code = getattr(err, "code", None)
                    if err_code in ["email_already_registered", "unique"]:
                        return Response(
                            {
                                "error": "email_already_registered",
                                "message": "Este correo ya está registrado.",
                            },
                            status=status.HTTP_400_BAD_REQUEST,
                        )

            return Response(
                {
                    "error": "validation_error",
                    "message": "No se pudo completar el registro.",
                    "errors": errors,
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
            tipo='verificacion',
        )

        # logger.info(f"[DEV] Código de verificación para {usuario.email}: {codigo}")
        if settings.DEBUG:
            print(f"[DEV] Código de verificación para {usuario.email}: {codigo}")

        # Enviar correo.
        enviar_correo_verificacion(usuario, codigo)

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

        # Ya no filtra usado=False, busca el código exacto ingresado
        codigo_verificacion = (
            CodigoVerificacion.objects
            .filter(usuario=usuario, codigo=codigo, tipo='verificacion')
            .order_by("-creado_en")
            .first()
        )

        if codigo_verificacion is None:
            return Response(
                {
                    "error": "invalid_code",
                    "message": "El código ingresado no es correcto.",
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        if codigo_verificacion.usado:
            return Response(
                {
                    "error": "code_already_used",
                    "message": "Este código ya no es válido. Solicita uno nuevo.",
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        if timezone.now() >= codigo_verificacion.expira_en:
            return Response(
                {
                    "error": "code_expired",
                    "message": "El código expiró. Solicita uno nuevo.",
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Código correcto
        codigo_verificacion.usado = True
        codigo_verificacion.save(update_fields=["usado"])

        usuario.is_active = True
        usuario.is_verified = True
        usuario.save(update_fields=["is_active", "is_verified"])

        return Response(
            {
                "detail": "Cuenta verificada correctamente.",
                "verified": True,
                "user": UsuarioSerializer(usuario, context={"request": request}).data,
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
            usado=False,
            tipo='verificacion',
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
            tipo='verificacion',
        )

        # logger.info(f"[DEV] Código de verificación para {usuario.email}: {codigo}")
        if settings.DEBUG:
            print(f"[DEV] Código de verificación para {usuario.email}: {codigo}")

        # Enviar nuevo correo.
        enviar_correo_verificacion(
            usuario,
            codigo,
            asunto="Nuevo código de verificación - TrailSense Loja",
        )

        return Response(
            {
                "detail": "Se ha enviado un nuevo código de verificación.",
                "email": usuario.email,
                "expires_in": 900,
            },
            status=status.HTTP_200_OK,
        )


# Reseteo de contraseña
class RequestPasswordResetView(APIView):
    """
    POST /api/auth/password-reset/request/

    Genera un código de recuperación de contraseña de 4 dígitos
    con una vigencia de 15 minutos.
    """

    permission_classes = [AllowAny]

    @transaction.atomic
    def post(self, request):
        serializer = RequestPasswordResetSerializer(data=request.data)

        if not serializer.is_valid():
            return Response(
                {
                    "error": "validation_error",
                    "message": "Datos inválidos.",
                    "errors": serializer.errors,
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        email = serializer.validated_data["email"]

        try:
            usuario = Usuario.objects.get(email__iexact=email)
        except Usuario.DoesNotExist:
            return Response(
                {
                    "error": "user_not_found",
                    "message": "No existe un usuario registrado con ese correo.",
                },
                status=status.HTTP_404_NOT_FOUND,
            )

        # Invalidar códigos de recuperación anteriores.
        CodigoVerificacion.objects.filter(
            usuario=usuario,
            usado=False,
            tipo='recuperacion',
        ).update(usado=True)

        codigo = str(secrets.randbelow(9000) + 1000)
        ahora = timezone.now()
        expira_en = ahora + timedelta(minutes=15)

        CodigoVerificacion.objects.create(
            usuario=usuario,
            codigo=codigo,
            expira_en=expira_en,
            usado=False,
            tipo='recuperacion',
        )

        if settings.DEBUG:
            print(f"[DEV] Código de recuperación para {usuario.email}: {codigo}")

        enviar_correo_recuperacion(usuario, codigo)

        return Response(
            {
                "detail": "Se ha enviado un código de recuperación a tu correo.",
                "email": usuario.email,
                "expires_in": 900,
            },
            status=status.HTTP_200_OK,
        )


class ResetPasswordView(APIView):
    """
    POST /api/auth/password-reset/confirm/

    Verifica el código de recuperación y establece la nueva contraseña.
    """

    permission_classes = [AllowAny]

    @transaction.atomic
    def post(self, request):
        serializer = ResetPasswordSerializer(data=request.data)

        if not serializer.is_valid():
            return Response(
                {
                    "error": "validation_error",
                    "message": "Datos inválidos.",
                    "errors": serializer.errors,
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        email = serializer.validated_data["email"]
        codigo = serializer.validated_data["codigo"]
        password = serializer.validated_data["password"]

        try:
            usuario = Usuario.objects.get(email__iexact=email)
        except Usuario.DoesNotExist:
            return Response(
                {
                    "error": "user_not_found",
                    "message": "No existe un usuario registrado con ese correo.",
                },
                status=status.HTTP_404_NOT_FOUND,
            )

        codigo_verificacion = (
            CodigoVerificacion.objects
            .filter(usuario=usuario, codigo=codigo, tipo='recuperacion')
            .order_by("-creado_en")
            .first()
        )

        if codigo_verificacion is None:
            return Response(
                {
                    "error": "invalid_code",
                    "message": "El código ingresado no es correcto.",
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        if codigo_verificacion.usado:
            return Response(
                {
                    "error": "code_already_used",
                    "message": "Este código ya no es válido. Solicita uno nuevo.",
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        if timezone.now() >= codigo_verificacion.expira_en:
            return Response(
                {
                    "error": "code_expired",
                    "message": "El código expiró. Solicita uno nuevo.",
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Código correcto: establecer nueva contraseña.
        usuario.set_password(password)
        usuario.save(update_fields=["password"])

        codigo_verificacion.usado = True
        codigo_verificacion.save(update_fields=["usado"])

        return Response(
            {
                "detail": "Contraseña restablecida correctamente.",
                "reset": True,
            },
            status=status.HTTP_200_OK,
        ) 


class PerfilView(APIView):
    """
    GET  /api/auth/perfil/   -> ver mi perfil
    PATCH /api/auth/perfil/  -> editar mi perfil (nombre, apellido, foto)
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response(UsuarioSerializer(request.user, context={"request": request}).data)

    def patch(self, request):
        serializer = EditarPerfilSerializer(request.user, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        usuario = serializer.save()
        return Response(UsuarioSerializer(usuario, context={"request": request}).data)


class CambiarPasswordView(APIView):
    """
    POST /api/auth/perfil/cambiar-password/
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = CambiarPasswordSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        if not request.user.check_password(serializer.validated_data["password_actual"]):
            return Response({"detail": "La contraseña actual es incorrecta."}, status=400)

        request.user.set_password(serializer.validated_data["password_nueva"])
        request.user.save(update_fields=["password"])
        return Response({"detail": "Contraseña actualizada correctamente."})        



class PanelAdminTestView(APIView):
    """
    Endpoint de verificación del sistema de roles (Sprint 5).
    """
    permission_classes = [IsAuthenticated, EsAdminOSuperusuario]

    def get(self, request):
        return Response({"detail": f"Acceso concedido para rol: {request.user.rol}"})