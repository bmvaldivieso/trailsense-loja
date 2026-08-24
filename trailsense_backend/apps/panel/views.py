from django.contrib.gis.geos import GEOSGeometry, GEOSException
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.views import LoginView as DjangoLoginView
from django.shortcuts import render, redirect, get_object_or_404
from django.contrib import messages
from django.views import View
from django.views.generic import TemplateView

from core.mixins.panel_mixins import PanelAccesoMixin
from apps.senderos.models import Sendero


class PanelLoginView(View):
    """
    Login del panel administrativo (basado en sesión, no JWT).
    Solo permite ingresar a usuarios con rol administrador/superusuario.
    """
    template_name = "panel/login.html"

    def get(self, request):
        if request.user.is_authenticated and request.user.rol in ("administrador", "superusuario"):
            return redirect("panel:dashboard")
        return render(request, self.template_name)

    def post(self, request):
        email = request.POST.get("email", "").strip().lower()
        password = request.POST.get("password", "")

        if not email or not password:
            messages.error(request, "Ingresa tu correo y contraseña.")
            return render(request, self.template_name)

        usuario = authenticate(request, username=email, password=password)

        if usuario is None:
            messages.error(request, "Credenciales incorrectas.")
            return render(request, self.template_name)

        if usuario.rol not in ("administrador", "superusuario"):
            messages.error(request, "Tu cuenta no tiene permisos para acceder al panel.")
            return render(request, self.template_name)

        login(request, usuario)
        return redirect("panel:dashboard")


class PanelLogoutView(View):
    def get(self, request):
        logout(request)
        return redirect("panel:login")

    def post(self, request):
        logout(request)
        return redirect("panel:login")


class DashboardView(PanelAccesoMixin, TemplateView):
    template_name = "panel/dashboard.html"

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context["active_page"] = "dashboard"
        context["page_title"] = "Descripción General"
        return context


class SenderosPanelView(PanelAccesoMixin, View):
    template_name = "panel/senderos.html"

    def get(self, request):
        senderos = Sendero.objects.all()
        return render(request, self.template_name, {
            "active_page": "senderos",
            "page_title": "Senderos",
            "senderos": senderos,
        })


class DetalleSenderoPanelView(PanelAccesoMixin, View):
    template_name = "panel/detalle_sendero.html"

    def get(self, request, pk=None):
        sendero = get_object_or_404(Sendero, pk=pk) if pk else None
        return render(request, self.template_name, {
            "active_page": "senderos",
            "page_title": f"Editar {sendero.nombre}" if sendero else "Nuevo Sendero",
            "sendero": sendero,
        })

    def post(self, request, pk=None):
        sendero = get_object_or_404(Sendero, pk=pk) if pk else Sendero()

        sendero.nombre = request.POST.get("nombre", "").strip()
        sendero.descripcion = request.POST.get("descripcion", "").strip()
        sendero.canton = request.POST.get("canton", "Loja").strip()
        sendero.dificultad = request.POST.get("dificultad", "media")
        sendero.estado = request.POST.get("estado", "bueno")
        sendero.longitud_km = request.POST.get("longitud_km") or 0
        sendero.horario_apertura = request.POST.get("horario_apertura") or None
        sendero.horario_cierre = request.POST.get("horario_cierre") or None

        wkt = request.POST.get("geometria_wkt", "").strip()
        try:
            # Esta línea limpia automáticamente cualquier salto de línea o espacio oculto
            wkt_limpio = " ".join(wkt.split())

            geom = GEOSGeometry(wkt_limpio, srid=4326)
            if geom.geom_type != "LineString":
                raise GEOSException("La geometría debe ser un LINESTRING.")
            sendero.geometria = geom
        except (GEOSException, ValueError, Exception):
            messages.error(
                request,
                "La geometría no es válida. Usa el formato: LINESTRING(lon lat, lon lat, ...)"
            )
            return render(request, self.template_name, {
                "active_page": "senderos",
                "page_title": "Nuevo Sendero" if pk is None else f"Editar {sendero.nombre}",
                "sendero": sendero if pk else None,
            })

        if "imagen_portada" in request.FILES:
            sendero.imagen_portada = request.FILES["imagen_portada"]

        sendero.save()
        messages.success(request, "Sendero guardado correctamente.")
        return redirect("panel:senderos")


class EliminarSenderoPanelView(PanelAccesoMixin, View):
    def post(self, request, pk):
        sendero = get_object_or_404(Sendero, pk=pk)
        sendero.delete()
        messages.success(request, "Sendero eliminado correctamente.")
        return redirect("panel:senderos")