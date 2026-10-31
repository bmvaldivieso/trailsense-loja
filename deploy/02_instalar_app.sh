#!/usr/bin/env bash
# =============================================================================
# TrailSense Loja - 02: instalar la aplicación Django
#
# Qué hace:
#   1. Crea el entorno virtual de Python en ~/venv (fuera del repositorio).
#   2. Instala las dependencias de requirements.txt y Gunicorn.
#   3. Crea la carpeta donde Nginx servirá el CSS/JS del panel.
#
# Uso (como usuario ubuntu, SIN sudo):   bash deploy/02_instalar_app.sh
# Requisito: el repositorio ya clonado en ~/trailsense-loja
# =============================================================================
set -euo pipefail

REPO="$HOME/trailsense-loja"
BACKEND="$REPO/trailsense_backend"
VENV="$HOME/venv"
STATIC_DIR="/var/www/trailsense/static"

if [ "$EUID" -eq 0 ]; then
  echo "No uses sudo con este script. Ejecútalo como el usuario ubuntu: bash $0"
  exit 1
fi

if [ ! -f "$BACKEND/requirements.txt" ]; then
  echo "No encuentro $BACKEND/requirements.txt. ¿Clonaste el repositorio en $REPO?"
  exit 1
fi

echo "==> 1/3 Entorno virtual de Python en $VENV"
[ -d "$VENV" ] || python3 -m venv "$VENV"
"$VENV/bin/pip" install --upgrade pip wheel

echo "==> 2/3 Dependencias del backend (puede tardar varios minutos)"
"$VENV/bin/pip" install -r "$BACKEND/requirements.txt"
"$VENV/bin/pip" install gunicorn

echo "==> 3/3 Carpeta de archivos estáticos: $STATIC_DIR"
sudo mkdir -p "$STATIC_DIR"
sudo chown -R "$USER":www-data /var/www/trailsense
sudo chmod -R 755 /var/www/trailsense

echo
echo "Listo. Comprobación rápida:"
"$VENV/bin/python" -c "import django, gunicorn; print('Django', django.get_version(), '| Gunicorn', gunicorn.__version__)"
