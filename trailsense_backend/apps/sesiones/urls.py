from django.urls import path
from .views import (
    SesionesListView, SesionDetailView, IniciarSesionView,
    EnviarPuntosView, PausarSesionView, ReanudarSesionView, FinalizarSesionView,
)

urlpatterns = [
    path('sesiones/', SesionesListView.as_view(), name='sesiones-list'),
    path('sesiones/iniciar/', IniciarSesionView.as_view(), name='sesion-iniciar'),
    path('sesiones/<int:pk>/', SesionDetailView.as_view(), name='sesion-detalle'),
    path('sesiones/<int:pk>/puntos/', EnviarPuntosView.as_view(), name='sesion-puntos'),
    path('sesiones/<int:pk>/pausar/', PausarSesionView.as_view(), name='sesion-pausar'),
    path('sesiones/<int:pk>/reanudar/', ReanudarSesionView.as_view(), name='sesion-reanudar'),
    path('sesiones/<int:pk>/finalizar/', FinalizarSesionView.as_view(), name='sesion-finalizar'),
]