from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.authentication import SessionAuthentication

from core.permissions.roles import EsAdminOSuperusuario, EsSuperusuario
from .models import RegistroActividad
from .utils import registrar_actividad
from .pdf import generar_pdf_actividades

from django.utils import timezone


class HistorialSenderistasListView(APIView):
    authentication_classes = [SessionAuthentication]
    permission_classes = [IsAuthenticated, EsAdminOSuperusuario]

    def get(self, request):
        actividades = self._queryset(request)
        data = [{
            "id": a.id, "tipo": a.tipo, "tipo_display": a.get_tipo_display(),
            "fecha": timezone.localtime(a.fecha).strftime('%d/%m/%Y %H:%M'),
            "usuario_nombre": f"{a.usuario.first_name} {a.usuario.last_name}".strip() or a.usuario.email,
            "descripcion": a.descripcion,
        } for a in actividades]
        return Response(data)

    def _queryset(self, request):
        qs = RegistroActividad.objects.filter(usuario__rol='ciudadano').select_related('usuario')
        desde, hasta = request.query_params.get('desde'), request.query_params.get('hasta')
        if desde: qs = qs.filter(fecha__date__gte=desde)
        if hasta: qs = qs.filter(fecha__date__lte=hasta)
        return qs


class HistorialSenderistasPDFView(APIView):
    authentication_classes = [SessionAuthentication]
    permission_classes = [IsAuthenticated, EsAdminOSuperusuario]

    def get(self, request):
        actividades = HistorialSenderistasListView()._queryset(request)
        registrar_actividad(request.user, 'descarga_pdf_historial', 'Historial de senderistas')
        return generar_pdf_actividades('Historial de Actividad — Senderistas', actividades, 'historial_senderistas.pdf')


class HistorialAdminsListView(APIView):
    authentication_classes = [SessionAuthentication]
    permission_classes = [IsAuthenticated, EsSuperusuario]

    def get(self, request):
        actividades = self._queryset(request)
        data = [{
            "id": a.id, "tipo": a.tipo, "tipo_display": a.get_tipo_display(),
            "fecha": timezone.localtime(a.fecha).strftime('%d/%m/%Y %H:%M'),
            "usuario_nombre": f"{a.usuario.first_name} {a.usuario.last_name}".strip() or a.usuario.email,
            "descripcion": a.descripcion,
        } for a in actividades]
        return Response(data)

    def _queryset(self, request):
        qs = RegistroActividad.objects.filter(usuario__rol__in=('administrador', 'superusuario')).select_related('usuario')
        desde, hasta = request.query_params.get('desde'), request.query_params.get('hasta')
        if desde: qs = qs.filter(fecha__date__gte=desde)
        if hasta: qs = qs.filter(fecha__date__lte=hasta)
        return qs


class HistorialAdminsPDFView(APIView):
    authentication_classes = [SessionAuthentication]
    permission_classes = [IsAuthenticated, EsSuperusuario]

    def get(self, request):
        actividades = HistorialAdminsListView()._queryset(request)
        registrar_actividad(request.user, 'descarga_pdf_historial', 'Historial de administradores')
        return generar_pdf_actividades('Historial de Actividad — Administradores', actividades, 'historial_admins.pdf')