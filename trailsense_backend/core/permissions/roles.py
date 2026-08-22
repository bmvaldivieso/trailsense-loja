from rest_framework.permissions import BasePermission

class EsCiudadano(BasePermission):
    message = "Solo los ciudadanos pueden acceder a este recurso."
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.rol == "ciudadano")


class EsAdministrador(BasePermission):
    message = "Solo los administradores pueden acceder a este recurso."
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.rol == "administrador")


class EsSuperusuario(BasePermission):
    message = "Solo el superusuario puede acceder a este recurso."
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.rol == "superusuario")


class EsAdminOSuperusuario(BasePermission):
    message = "Se requieren privilegios administrativos."
    def has_permission(self, request, view):
        return bool(
            request.user and request.user.is_authenticated
            and request.user.rol in ("administrador", "superusuario")
        )