from django.urls import path
from .views import MetricasPersonalesView, MetricasPersonalesPDFView
from .views_dashboard import DashboardAPIView

urlpatterns = [
    path('metricas/personales/', MetricasPersonalesView.as_view(), name='metricas-personales'),
    path('metricas/personales/pdf/', MetricasPersonalesPDFView.as_view(), name='metricas-personales-pdf'),
    path('metricas/dashboard/', DashboardAPIView.as_view(), name='metricas-dashboard'),
]