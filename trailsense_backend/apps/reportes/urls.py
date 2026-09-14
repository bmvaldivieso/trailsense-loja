from django.urls import path
from rest_framework.routers import DefaultRouter
from .views import ReporteViewSet, CrearReporteView, ReportesPanelListView, SenderosCercanosPanelView, ReporteDetalleAdminView

router = DefaultRouter()
router.register('reportes', ReporteViewSet, basename='reporte')

urlpatterns = [
    path('reportes/crear/', CrearReporteView.as_view(), name='reporte-crear'),
    path('reportes/panel/', ReportesPanelListView.as_view(), name='reportes-panel-list'),
    path('reportes/panel/senderos-geojson/', SenderosCercanosPanelView.as_view(), name='reportes-panel-senderos'),
    path('reportes/panel/<int:pk>/', ReporteDetalleAdminView.as_view(), name='reportes-panel-detail'),
] + router.urls