from .base import *

EMAIL_BACKEND = "django.core.mail.backends.smtp.EmailBackend"

INSTALLED_APPS += ["django_extensions"]