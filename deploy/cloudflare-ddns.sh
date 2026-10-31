#!/usr/bin/env bash
# =============================================================================
# Actualiza en Cloudflare la IP pública del servidor.
# AWS asigna una IP nueva cada vez que el servidor se enciende; este script
# corre al arrancar y apunta los registros DNS a la IP actual.
#
#   trailsense-loja.com      -> IP actual, con proxy de Cloudflare (nube naranja)
#   ssh.trailsense-loja.com  -> IP actual, solo DNS (nube gris), para conectarte por SSH
#
# Lee CF_API_TOKEN y CF_ZONE_ID de /etc/trailsense/cloudflare.env
# =============================================================================
set -euo pipefail

# shellcheck disable=SC1091
source /etc/trailsense/cloudflare.env
: "${CF_API_TOKEN:?Falta CF_API_TOKEN en /etc/trailsense/cloudflare.env}"
: "${CF_ZONE_ID:?Falta CF_ZONE_ID en /etc/trailsense/cloudflare.env}"

API="https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records"

# IP pública desde el servicio de metadatos de EC2 (IMDSv2).
TOKEN_IMDS=$(curl -sS -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 60")
IP=$(curl -sS -H "X-aws-ec2-metadata-token: $TOKEN_IMDS" \
  "http://169.254.169.254/latest/meta-data/public-ipv4")

if ! [[ "$IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "No se obtuvo una IP pública válida: '$IP'"
  exit 1
fi

actualizar() {
  local nombre="$1" proxied="$2" id respuesta
  id=$(curl -sS -H "Authorization: Bearer $CF_API_TOKEN" \
        "$API?type=A&name=$nombre" | jq -r '.result[0].id // empty')
  if [ -z "$id" ]; then
    echo "No existe un registro A para $nombre en Cloudflare. Créalo primero (ver guía)."
    exit 1
  fi
  respuesta=$(curl -sS -X PATCH "$API/$id" \
    -H "Authorization: Bearer $CF_API_TOKEN" \
    -H "Content-Type: application/json" \
    --data "{\"content\":\"$IP\",\"proxied\":$proxied}")
  if [ "$(echo "$respuesta" | jq -r '.success')" != "true" ]; then
    echo "Error actualizando $nombre: $respuesta"
    exit 1
  fi
  echo "$nombre -> $IP (proxy: $proxied)"
}

actualizar "trailsense-loja.com" true
actualizar "ssh.trailsense-loja.com" false
