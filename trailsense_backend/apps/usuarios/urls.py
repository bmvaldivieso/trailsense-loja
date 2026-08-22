from django.urls import path
from .views import LoginView, RegisterView, VerifyCodeView, ResendCodeView, RequestPasswordResetView, ResetPasswordView, PerfilView, CambiarPasswordView, PanelAdminTestView

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
]