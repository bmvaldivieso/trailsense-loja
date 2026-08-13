from django.urls import path
from .views import LoginView, RegisterView, VerifyCodeView, ResendCodeView

urlpatterns = [
    path('login/', LoginView.as_view(), name='login'),
    
    path('register/', RegisterView.as_view(), name='register'),
    path('verify-code/', VerifyCodeView.as_view(), name='verify-code'),
    path('resend-code/', ResendCodeView.as_view(), name='resend-code'),
]