from django.urls import path
from .views import MetricasPersonalesView, MetricasPersonalesPDFView

urlpatterns = [
    path('metricas/personales/', MetricasPersonalesView.as_view(), name='metricas-personales'),
    path('metricas/personales/pdf/', MetricasPersonalesPDFView.as_view(), name='metricas-personales-pdf'),
]