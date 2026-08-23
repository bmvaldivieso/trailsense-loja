from rest_framework.routers import DefaultRouter
from .views import SenderoViewSet

router = DefaultRouter()
router.register('senderos', SenderoViewSet, basename='sendero')

urlpatterns = router.urls