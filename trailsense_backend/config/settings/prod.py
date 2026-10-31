"""
Ajustes de PRODUCCIÓN (AWS: EC2 + Nginx + Gunicorn, RDS, S3, Cloudflare).

Se activan con la variable de entorno DJANGO_SETTINGS_MODULE=config.settings.prod
(el servicio de Gunicorn y el comando 'tsmanage' ya la definen).
Todo lo demás se hereda de base.py y se lee del .env del servidor.
"""
from decouple import Csv, config

from .base import *  # noqa: F401,F403

DEBUG = False

ALLOWED_HOSTS = config("ALLOWED_HOSTS", cast=Csv())
CSRF_TRUSTED_ORIGINS = config("CSRF_TRUSTED_ORIGINS", cast=Csv())

# La app móvil no usa CORS (no es un navegador) y el panel se sirve desde el mismo dominio.
CORS_ALLOW_ALL_ORIGINS = False
CORS_ALLOWED_ORIGINS = []

# ------------------------------------------------------------------ HTTPS
# Cloudflare y Nginx terminan HTTPS; Nginx avisa a Django con X-Forwarded-Proto.
SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
SECURE_SSL_REDIRECT = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True

# HSTS: el navegador recordará usar solo HTTPS durante 30 días.
# Sin subdominios: 'ssh.trailsense-loja.com' no sirve páginas web.
SECURE_HSTS_SECONDS = 60 * 60 * 24 * 30
SECURE_HSTS_INCLUDE_SUBDOMAINS = False
SECURE_HSTS_PRELOAD = False

SECURE_CONTENT_TYPE_NOSNIFF = True
SECURE_REFERRER_POLICY = "same-origin"

# ------------------------------------------------------------------ Correo
EMAIL_BACKEND = "django.core.mail.backends.smtp.EmailBackend"

# ------------------------------------------------------------------ Registros
# Los errores salen por consola -> Gunicorn -> journalctl -u gunicorn-trailsense
LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "handlers": {
        "console": {"class": "logging.StreamHandler"},
    },
    "root": {"handlers": ["console"], "level": "WARNING"},
    "loggers": {
        "django": {"handlers": ["console"], "level": "WARNING", "propagate": False},
    },
}
