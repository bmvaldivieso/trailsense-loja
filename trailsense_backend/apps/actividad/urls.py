from django.urls import path
from .views import HistorialSenderistasListView, HistorialSenderistasPDFView, HistorialAdminsListView, HistorialAdminsPDFView

urlpatterns = [
    path('actividad/senderistas/', HistorialSenderistasListView.as_view(), name='actividad-senderistas'),
    path('actividad/senderistas/pdf/', HistorialSenderistasPDFView.as_view(), name='actividad-senderistas-pdf'),
    path('actividad/admins/', HistorialAdminsListView.as_view(), name='actividad-admins'),
    path('actividad/admins/pdf/', HistorialAdminsPDFView.as_view(), name='actividad-admins-pdf'),
]