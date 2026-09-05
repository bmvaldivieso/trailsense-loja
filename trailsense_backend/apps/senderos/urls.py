from django.urls import path
from rest_framework.routers import DefaultRouter
from .views import SenderoViewSet, SenderoEstadisticasView

router = DefaultRouter()
router.register('senderos', SenderoViewSet, basename='sendero')

urlpatterns = router.urls + [
    path('senderos/<int:pk>/estadisticas/', SenderoEstadisticasView.as_view(), name='sendero-estadisticas'),
]