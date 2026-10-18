from django.urls import path
from rest_framework.routers import DefaultRouter
from .views import SenderoViewSet, SenderoEstadisticasView
from .api_geo import ProcesarTrazaAPIView, DireccionSugeridaAPIView

router = DefaultRouter()
router.register('senderos', SenderoViewSet, basename='sendero')

urlpatterns = router.urls + [
    path('senderos/<int:pk>/estadisticas/', SenderoEstadisticasView.as_view(), name='sendero-estadisticas'),
    path('senderos/panel/procesar-traza/', ProcesarTrazaAPIView.as_view(), name='senderos-procesar-traza'),
    path('senderos/panel/direccion-sugerida/', DireccionSugeridaAPIView.as_view(), name='senderos-direccion-sugerida'),
]