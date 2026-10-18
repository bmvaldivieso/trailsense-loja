from django.urls import path
from .views import MetricasPersonalesView, MetricasPersonalesPDFView, MesesDisponiblesView 
from .views_dashboard import DashboardAPIView

urlpatterns = [
    path('metricas/personales/', MetricasPersonalesView.as_view(), name='metricas-personales'),
    path('metricas/personales/pdf/', MetricasPersonalesPDFView.as_view(), name='metricas-personales-pdf'),
    path('metricas/dashboard/', DashboardAPIView.as_view(), name='metricas-dashboard'),
    path('metricas/personales/meses/', MesesDisponiblesView.as_view(), name='metricas-meses'),
]