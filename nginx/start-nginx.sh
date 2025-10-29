#!/bin/sh
set -e

: "${ACTIVE_POOL:=blue}"
: "${PORT:=3000}"

if [ "$ACTIVE_POOL" = "green" ]; then
  PRIMARY_HOST="app_green"
  BACKUP_HOST="app_blue"
else
  PRIMARY_HOST="app_blue"
  BACKUP_HOST="app_green"
fi

if ! command -v envsubst >/dev/null 2>&1; then
  echo "Installing gettext (for envsubst)..."
  apk add --no-cache gettext
fi

export PRIMARY_HOST BACKUP_HOST PORT
envsubst '${PRIMARY_HOST} ${BACKUP_HOST} ${PORT}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

nginx -g 'daemon off;'
