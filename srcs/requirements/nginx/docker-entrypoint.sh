#!/bin/sh
set -euo pipefail

logger_info() {
  printf "\033[32m"
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] [INFO] $@"
  printf "\033[0m"
}

logger_error() {
  printf "\033[31m"
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR] $@" >&2
  printf "\033[0m"
  exit 1
}

if [ "$1" = 'nginx' ]; then
  if [ "$(id -u)" = '0' ]; then
    find /var/lib/nginx \! -user www-data -exec chown www-data '{}' +
    cd /var/lib/nginx && exec su-exec www-data "$0" "$@"
  fi;

  if [ -f /var/lib/nginx/keys/server.crt ] && [ -f /var/lib/nginx/keys/private.key ]; then
    logger_info "SSL certificate already exists."
  else
    logger_info "Generating SSL certificate ..."
    openssl genrsa -out /var/lib/nginx/keys/private.key;
    openssl req -new -key /var/lib/nginx/keys/private.key -out /var/lib/nginx/keys/server.csr -subj "/";
    openssl x509 -req -days 365 -in /var/lib/nginx/keys/server.csr -signkey /var/lib/nginx/keys/private.key -out /var/lib/nginx/keys/server.crt;
    rm -rf server.csr;
  fi
fi

logger_info "Starting $@ ..."
exec "$@"
