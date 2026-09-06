from django.urls import path
from rest_framework.routers import DefaultRouter
from .views import ReporteViewSet, CrearReporteView

router = DefaultRouter()
router.register('reportes', ReporteViewSet, basename='reporte')

urlpatterns = [
    path('reportes/crear/', CrearReporteView.as_view(), name='reporte-crear'),
] + router.urls