from django.contrib.gis.geos import GEOSGeometry, GEOSException
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.views import LoginView as DjangoLoginView
from django.shortcuts import render, redirect, get_object_or_404
from django.contrib import messages
from django.views import View
from django.views.generic import TemplateView

from core.mixins.panel_mixins import PanelAccesoMixin, SuperusuarioAccesoMixin, PermisoSenderosMixin
from apps.senderos.models import Sendero

from django.conf import settings

from apps.actividad.utils import registrar_actividad 


class PanelLoginView(View):
    """
    Login del panel administrativo (basado en sesión, no JWT).
    Solo permite ingresar a usuarios con rol administrador/superusuario.
    """
    template_name = "panel/login.html"

    def get(self, request):
        if request.user.is_authenticated:
            if request.user.rol == "superusuario":
                return redirect("panel:superusuario-dashboard")
            if request.user.rol == "administrador":
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

        if usuario.rol == "superusuario":
            return redirect("panel:superusuario-dashboard")
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

    # El superusuario nunca debe ver el dashboard del administrador
    def get(self, request, *args, **kwargs):
        if request.user.rol == "superusuario":
            return redirect("panel:superusuario-dashboard")
        return super().get(request, *args, **kwargs)

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context["active_page"] = "dashboard"
        context["page_title"] = "Descripción General"
        context["carto_api_key"] = settings.CARTO_BASEMAPS_API_KEY
        context["es_superusuario"] = False
        return context


class SenderosPanelView(PermisoSenderosMixin, View):
    template_name = "panel/senderos.html"

    def get(self, request):
        senderos = Sendero.objects.all()
        return render(request, self.template_name, {
            "active_page": "senderos",
            "page_title": "Senderos",
            "senderos": senderos,
        })


class DetalleSenderoPanelView(PermisoSenderosMixin, View):
    template_name = "panel/detalle_sendero.html"

    def get(self, request, pk=None):
        sendero = get_object_or_404(Sendero, pk=pk) if pk else None
        return render(request, self.template_name, {
            "active_page": "senderos",
            "page_title": f"Editar {sendero.nombre}" if sendero else "Nuevo Sendero",
            "sendero": sendero,
            "carto_api_key": settings.CARTO_BASEMAPS_API_KEY,
        })

    def post(self, request, pk=None):
        es_creacion = pk is None
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
                "carto_api_key": settings.CARTO_BASEMAPS_API_KEY,
            })

        if "imagen_portada" in request.FILES:
            sendero.imagen_portada = request.FILES["imagen_portada"]

        if es_creacion:
            sendero.creado_por = request.user    

        sendero.save()

        registrar_actividad(
            request.user,
            'sendero_creado' if es_creacion else 'sendero_actualizado',
            f"Sendero: {sendero.nombre}"
        )

        messages.success(request, "Sendero guardado correctamente.")
        return redirect("panel:senderos")


class EliminarSenderoPanelView(PermisoSenderosMixin, View):
    def post(self, request, pk):
        sendero = get_object_or_404(Sendero, pk=pk)
        nombre = sendero.nombre
        sendero.delete()
        registrar_actividad(request.user, 'sendero_eliminado', f"Sendero: {nombre}")
        messages.success(request, "Sendero eliminado correctamente.")
        return redirect("panel:senderos")






class RecorridosPanelView(PanelAccesoMixin, View):
    template_name = "panel/recorridos.html"

    def get(self, request):
        return render(request, self.template_name, {
            "active_page": "recorridos",
            "page_title": "Recorridos",
            "carto_api_key": settings.CARTO_BASEMAPS_API_KEY,
        })        






class IncidenciasPanelView(PanelAccesoMixin, View):
    template_name = "panel/incidencias.html"

    def get(self, request):
        return render(request, self.template_name, {"active_page": "incidencias", "page_title": "Incidencias"})


class DetalleIncidenciaPanelView(PanelAccesoMixin, View):
    template_name = "panel/detalle_incidencia.html"

    def get(self, request, pk):
        return render(request, self.template_name, {
            "active_page": "incidencias",
            "page_title": "Detalle de Incidencia",
            "reporte_id": pk,
            "carto_api_key": settings.CARTO_BASEMAPS_API_KEY,
        })






class DashboardSuperusuarioPanelView(SuperusuarioAccesoMixin, TemplateView):
    template_name = "panel/dashboard_superusuario.html"

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context["active_page"] = "superusuario-dashboard"
        context["page_title"] = "Descripción General"
        context["carto_api_key"] = settings.CARTO_BASEMAPS_API_KEY
        context["es_superusuario"] = True
        return context


class AdminsPanelView(SuperusuarioAccesoMixin, View):
    def get(self, request):
        return render(request, "panel/usuarios.html", {"active_page": "superusuario-usuarios", "page_title": "Usuarios"})


class SenderistasPanelView(PanelAccesoMixin, View):
    def get(self, request):
        return render(request, "panel/senderistas.html", {"active_page": "senderistas", "page_title": "Senderistas"})


class HistorialSenderistasPanelView(PanelAccesoMixin, View):
    def get(self, request):
        return render(request, "panel/historial_senderistas.html", {"active_page": "historial", "page_title": "Historial de actividad"})


class HistorialAdminsPanelView(SuperusuarioAccesoMixin, View):
    def get(self, request):
        return render(request, "panel/historial_admins.html", {"active_page": "superusuario-historial", "page_title": "Historial de actividad"})