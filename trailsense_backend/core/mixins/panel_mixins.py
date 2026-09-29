from django.contrib.auth.mixins import LoginRequiredMixin, UserPassesTestMixin


class PanelAccesoMixin(LoginRequiredMixin, UserPassesTestMixin):
    """
    Restringe el acceso al panel administrativo únicamente a
    usuarios con rol 'administrador' o 'superusuario'.
    """
    login_url = "panel:login"

    def test_func(self):
        return self.request.user.rol in ("administrador", "superusuario")

    def handle_no_permission(self):
        from django.contrib.auth import logout
        from django.shortcuts import redirect
        from django.contrib import messages

        if self.request.user.is_authenticated:
            # Usuario autenticado pero sin rol suficiente: fuera del panel
            messages.error(
                self.request,
                "Tu cuenta no tiene permisos para acceder al panel administrativo."
            )
            logout(self.request)

        return redirect("panel:login")


class SuperusuarioAccesoMixin(LoginRequiredMixin, UserPassesTestMixin):
    login_url = "panel:login"

    def test_func(self):
        return self.request.user.rol == "superusuario"

    def handle_no_permission(self):
        from django.contrib.auth import logout
        from django.shortcuts import redirect
        from django.contrib import messages

        if self.request.user.is_authenticated:
            messages.error(self.request, "Solo el superusuario puede acceder a esta sección.")
            logout(self.request)
        return redirect("panel:login")


class PermisoSenderosMixin(PanelAccesoMixin):
    """Exige, además del acceso general al panel, el permiso explícito de senderos (is_staff)."""
    def test_func(self):
        if not super().test_func():
            return False
        return self.request.user.rol == "superusuario" or self.request.user.is_staff        