#!/usr/bin/env bash
# =============================================================================
# TrailSense Loja - publicar en el servidor la última versión de GitHub
#
# Qué hace:
#   1. Descarga los cambios del repositorio (git pull).
#   2. Instala dependencias nuevas, si las hay.
#   3. Aplica migraciones de la base de datos.
#   4. Recopila el CSS/JS del panel.
#   5. Reinicia Gunicorn para que Django cargue el código nuevo.
#
# Uso (como usuario ubuntu, SIN sudo):   bash ~/trailsense-loja/deploy/actualizar.sh
# Si cambiaste algún archivo de deploy/ (Nginx, servicios), ejecuta además:
#   sudo bash ~/trailsense-loja/deploy/03_configurar_servicios.sh
# =============================================================================
set -euo pipefail

REPO="$HOME/trailsense-loja"
cd "$REPO"

echo "==> 1/5 Descargando cambios de GitHub"
git pull --ff-only

echo "==> 2/5 Dependencias"
"$HOME/venv/bin/pip" install -q -r trailsense_backend/requirements.txt gunicorn

echo "==> 3/5 Migraciones"
tsmanage migrate --noinput

echo "==> 4/5 Archivos estáticos"
tsmanage collectstatic --noinput

echo "==> 5/5 Reiniciando la aplicación"
sudo systemctl restart gunicorn-trailsense
sleep 2
sudo systemctl --no-pager --lines=5 status gunicorn-trailsense

echo
echo "Listo. Versión publicada:"
git log -1 --pretty='%h  %s  (%cr)'
