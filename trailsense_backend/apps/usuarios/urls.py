from django.urls import path
from .views import LoginView, RegisterView, VerifyCodeView, ResendCodeView, RequestPasswordResetView, ResetPasswordView, PerfilView, CambiarPasswordView, PanelAdminTestView
from .views import (
    AdminsPanelListView, AdminDetalleAPIView,
    SenderistasPanelListView, SenderistaDetalleAPIView,
)

urlpatterns = [
    path('login/', LoginView.as_view(), name='login'),
    
    path('register/', RegisterView.as_view(), name='register'),
    path('verify-code/', VerifyCodeView.as_view(), name='verify-code'),
    path('resend-code/', ResendCodeView.as_view(), name='resend-code'),
    
    path('password-reset/request/', RequestPasswordResetView.as_view(), name='password-reset-request'),
    path('password-reset/confirm/', ResetPasswordView.as_view(), name='password-reset-confirm'),

    path('perfil/', PerfilView.as_view(), name='perfil'),
    path('perfil/cambiar-password/', CambiarPasswordView.as_view(), name='cambiar-password'),

    #Test
    path('panel-admin-test/', PanelAdminTestView.as_view(), name='panel-admin-test'),

    path('panel/admins/listado/', AdminsPanelListView.as_view(), name='panel-admins-list'),
    path('panel/admins/', AdminDetalleAPIView.as_view(), name='panel-admin-crear'),
    path('panel/admins/<int:pk>/', AdminDetalleAPIView.as_view(), name='panel-admin-detalle'),
    path('panel/senderistas/', SenderistasPanelListView.as_view(), name='panel-senderistas-list'),
    path('panel/senderistas/<int:pk>/', SenderistaDetalleAPIView.as_view(), name='panel-senderista-detalle'),
]