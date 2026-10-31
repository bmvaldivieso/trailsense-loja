#!/usr/bin/env bash
# =============================================================================
# TrailSense Loja - 03: configurar los servicios del servidor
#
# Qué hace:
#   1. Instala el comando 'tsmanage' (manage.py con los ajustes de producción).
#   2. Instala el servicio de Gunicorn (Django) para que arranque solo con la máquina.
#   3. Instala el servicio que actualiza la IP en Cloudflare al encender el servidor.
#   4. Configura Nginx (HTTPS con el certificado de origen de Cloudflare).
#   5. Activa y arranca todo.
#
# Requisitos ANTES de ejecutarlo (ver la guía):
#   - /etc/ssl/cloudflare/trailsense-loja.pem   (certificado de origen)
#   - /etc/ssl/cloudflare/trailsense-loja.key   (llave privada del certificado)
#   - /etc/trailsense/cloudflare.env            (CF_API_TOKEN y CF_ZONE_ID)
#   - trailsense_backend/.env                    (variables de producción)
#
# Uso:   sudo bash deploy/03_configurar_servicios.sh
# Volver a ejecutarlo es seguro (por ejemplo, si cambias la config de Nginx).
# =============================================================================
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  echo "Ejecútalo con: sudo bash $0"
  exit 1
fi

DIR="$(cd "$(dirname "$0")" && pwd)"
BACKEND="/home/ubuntu/trailsense-loja/trailsense_backend"

echo "==> Verificando requisitos"
faltan=0
for f in /etc/ssl/cloudflare/trailsense-loja.pem \
         /etc/ssl/cloudflare/trailsense-loja.key \
         /etc/trailsense/cloudflare.env \
         "$BACKEND/.env"; do
  if [ ! -f "$f" ]; then
    echo "    FALTA: $f"
    faltan=1
  fi
done
[ "$faltan" -eq 0 ] || { echo "Completa los archivos que faltan y vuelve a ejecutar."; exit 1; }

chmod 600 /etc/ssl/cloudflare/trailsense-loja.key /etc/trailsense/cloudflare.env
chmod 600 "$BACKEND/.env" && chown ubuntu:ubuntu "$BACKEND/.env"

echo "==> 1/5 Comando tsmanage"
install -m 755 "$DIR/tsmanage" /usr/local/bin/tsmanage

echo "==> 2/5 Servicio de Gunicorn"
install -m 644 "$DIR/gunicorn-trailsense.service" /etc/systemd/system/gunicorn-trailsense.service

echo "==> 3/5 Servicio de actualización de IP en Cloudflare"
install -m 755 "$DIR/cloudflare-ddns.sh" /usr/local/bin/cloudflare-ddns.sh
install -m 644 "$DIR/cloudflare-ddns.service" /etc/systemd/system/cloudflare-ddns.service

echo "==> 4/5 Nginx"
install -m 644 "$DIR/nginx-trailsense.conf" /etc/nginx/sites-available/trailsense
ln -sf /etc/nginx/sites-available/trailsense /etc/nginx/sites-enabled/trailsense
rm -f /etc/nginx/sites-enabled/default
nginx -t

echo "==> 5/5 Activando servicios"
systemctl daemon-reload
systemctl enable --now cloudflare-ddns.service
systemctl enable --now gunicorn-trailsense.service
systemctl enable nginx
systemctl reload nginx || systemctl restart nginx

echo
echo "================ Estado ================"
systemctl --no-pager --lines=3 status cloudflare-ddns.service || true
systemctl --no-pager --lines=3 status gunicorn-trailsense.service || true
systemctl --no-pager --lines=0 status nginx || true
