from django.contrib import admin
from django.urls import path, include
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/auth/', include('apps.usuarios.urls')),
    
    path('api/auth/login/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('api/auth/refresh/', TokenRefreshView.as_view(), name='token_refresh'),

    path("panel/", include("apps.panel.urls")),

    path('api/', include('apps.senderos.urls')),

    path('api/', include('apps.sesiones.urls')),

    path('api/', include('apps.reportes.urls')),

    path('api/', include('apps.actividad.urls')),

    path('api/', include('apps.estadisticas.urls')),

    path('api/', include('apps.notificaciones.urls')),

    # path('api/usuarios/', include('apps.usuarios.urls')),
    # path('api/senderos/', include('apps.senderos.urls')),
    # path('api/reportes/', include('apps.reportes.urls')),
    # path('api/sesiones/', include('apps.sesiones.urls')),
    # path('api/notificaciones/', include('apps.notificaciones.urls')),
]

if settings.DEBUG:
    urlpatterns += static(
        settings.MEDIA_URL,
        document_root=settings.MEDIA_ROOT
    )