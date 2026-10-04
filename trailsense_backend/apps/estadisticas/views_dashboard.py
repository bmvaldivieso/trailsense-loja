from rest_framework.authentication import SessionAuthentication
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from core.permissions.roles import EsAdminOSuperusuario
from .dashboard import construir_dashboard


class DashboardAPIView(APIView):
    """GET /api/metricas/dashboard/ — datos del dashboard según el rol (admin o superusuario)."""
    authentication_classes = [SessionAuthentication]
    permission_classes = [IsAuthenticated, EsAdminOSuperusuario]

    def get(self, request):
        return Response(construir_dashboard(request))