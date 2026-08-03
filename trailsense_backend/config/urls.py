from django.contrib import admin
from django.urls import path, include
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/auth/', include('apps.usuarios.urls')),
    path('api/auth/login/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('api/auth/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('api/usuarios/', include('apps.usuarios.urls')),
    path('api/senderos/', include('apps.senderos.urls')),
    path('api/reportes/', include('apps.reportes.urls')),
    path('api/sesiones/', include('apps.sesiones.urls')),
    path('api/notificaciones/', include('apps.notificaciones.urls')),
]
