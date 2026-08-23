from django.urls import path
from . import views

app_name = "panel"

urlpatterns = [
    path("login/", views.PanelLoginView.as_view(), name="login"),
    path("logout/", views.PanelLogoutView.as_view(), name="logout"),
    path("dashboard/", views.DashboardView.as_view(), name="dashboard"),
    path("senderos/", views.SenderosPanelView.as_view(), name="senderos"),
    path("senderos/nuevo/", views.DetalleSenderoPanelView.as_view(), name="sendero-nuevo"),  
    path("senderos/<int:pk>/", views.DetalleSenderoPanelView.as_view(), name="detalle-sendero"),
    path("senderos/<int:pk>/eliminar/", views.EliminarSenderoPanelView.as_view(), name="sendero-eliminar"),
]