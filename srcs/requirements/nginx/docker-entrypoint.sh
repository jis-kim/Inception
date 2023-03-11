#!/bin/sh
set -eo pipefail

logger_info() {
  printf "\033[32m"
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] [INFO] $@"
  printf "\033[0m"
}

if [ "$1" = 'nginx' ]; then
  find /var/lib/nginx \! -user www-data -exec chown www-data '{}' +
  if [ -f /var/lib/nginx/keys/server.crt ] && [ -f /var/lib/nginx/keys/private.key ]; then
    logger_info "SSL certificate already exists."
  else
    logger_info "Generating SSL certificate ..."
    openssl genrsa -out /var/lib/nginx/keys/private.key;
    openssl req -new -key /var/lib/nginx/keys/private.key \
    -out /var/lib/nginx/keys/server.csr -subj "/" >/dev/null 2>&1;
    openssl x509 -req -days 365 -in /var/lib/nginx/keys/server.csr \
    -signkey /var/lib/nginx/keys/private.key -out /var/lib/nginx/keys/server.crt >/dev/null 2>&1;
    rm -rf server.csr;
  fi
fi

logger_info "Starting $@ ..."
exec "$@"
