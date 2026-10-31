#!/usr/bin/env bash
# =============================================================================
# TrailSense Loja - 01: preparar el servidor (Ubuntu Server 24.04 LTS, ARM o x86)
#
# Qué hace:
#   1. Pone la zona horaria de Ecuador.
#   2. Crea 2 GB de memoria de intercambio (swap) para que 1 GB de RAM alcance.
#   3. Actualiza el sistema.
#   4. Instala Python, las librerías geográficas (GDAL/GEOS/PROJ), Nginx y utilidades.
#   5. Instala el cliente de PostgreSQL 18 (necesario para restaurar tu respaldo).
#   6. Instala AWS CLI (para copiar las fotos entre buckets).
#
# Uso:   sudo bash deploy/01_preparar_servidor.sh
# Se puede ejecutar más de una vez sin problema.
# =============================================================================
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  echo "Este script necesita permisos de administrador. Ejecútalo con: sudo bash $0"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a   # reinicia servicios sin hacer preguntas

echo "==> 1/6 Zona horaria America/Guayaquil"
timedatectl set-timezone America/Guayaquil

echo "==> 2/6 Memoria de intercambio (swap) de 2 GB"
if ! swapon --show | grep -q '/swapfile'; then
  fallocate -l 2G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  grep -q '^/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
else
  echo "    El swap ya existe, se omite."
fi

echo "==> 3/6 Actualizando el sistema (puede tardar unos minutos)"
apt-get update
apt-get -y upgrade

echo "==> 4/6 Python, GDAL/GEOS/PROJ, Nginx y utilidades"
apt-get install -y \
  python3-venv python3-dev build-essential \
  gdal-bin libgdal-dev libgeos-dev libproj-dev \
  nginx git jq curl unzip ca-certificates

echo "==> 5/6 Cliente de PostgreSQL 18 (repositorio oficial de PostgreSQL)"
apt-get install -y postgresql-common
if ! apt-cache policy postgresql-client-18 | grep -q 'apt.postgresql.org'; then
  /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y
fi
apt-get install -y postgresql-client-18

echo "==> 6/6 AWS CLI"
if ! command -v aws >/dev/null 2>&1; then
  snap install aws-cli --classic
fi

echo
echo "================ Listo. Versiones instaladas ================"
python3 --version
gdalinfo --version
psql --version
nginx -v 2>&1
aws --version
free -h | grep -i swap
