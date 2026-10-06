from django.urls import path
from .views import NotificacionesListView, NotificacionDetalleView, ProximidadView
from .views_panel import NotificacionesPanelView, NotificacionPanelDetalleView, NotificacionesOpcionesView

urlpatterns = [
    path('notificaciones/', NotificacionesListView.as_view(), name='notificaciones-list'),
    path('notificaciones/proximidad/', ProximidadView.as_view(), name='notificaciones-proximidad'),
    path('notificaciones/panel/', NotificacionesPanelView.as_view(), name='notificaciones-panel'),
    path('notificaciones/panel/opciones/', NotificacionesOpcionesView.as_view(), name='notificaciones-panel-opciones'),
    path('notificaciones/panel/<int:pk>/', NotificacionPanelDetalleView.as_view(), name='notificaciones-panel-detalle'),
    path('notificaciones/<int:pk>/', NotificacionDetalleView.as_view(), name='notificaciones-detalle'),
]