from rest_framework import viewsets, permissions
from .models import Sendero
from .serializers import SenderoSerializer
from core.permissions.roles import EsAdminOSuperusuario


class SenderoViewSet(viewsets.ModelViewSet):
    queryset = Sendero.objects.all()
    serializer_class = SenderoSerializer

    def get_permissions(self):
        if self.action in ('create', 'update', 'partial_update', 'destroy'):
            return [permissions.IsAuthenticated(), EsAdminOSuperusuario()]
        return [permissions.IsAuthenticated()]