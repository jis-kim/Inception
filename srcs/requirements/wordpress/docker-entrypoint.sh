#!/bin/sh
set -euxo pipefail

logger_info() {
  echo -e "\033[32m"
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] [INFO] $@"
  echo -e "\033[0m"
}

logger_error() {
  echo -e "\033[31m"
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR] $@" >&2
  echo -e "\033[0m"
  exit 1
}

check_minimum_env() {
    if [ -z "$WP_DB_HOST" ] || [ -z "$WP_DB_NAME " ] || [ -z "$WP_DB_USER" ] || [ -z "$WP_DB_PASSWORD" ] \
     || [ -z "$WP_ADMIN_USER" ] || [ -z "$WP_ADMIN_PASSWORD" ] || [ -z $WP_ADMIN_EMAIL" ] ; then
        logger_error "error: missing required environment variable.\n" \
        "Please check your .env file and make sure you have set all required variables."
    fi
}

if [ "$1" = 'php-fpm8' ]; then
    if [ "$(id -u)" = '0' ]; then
        find /wordpress \! -user nobody -exec chown nobody '{}' +
        cd /wordpress && exec su-exec nobody "$0" "$@"
    fi;
    check_minimum_env

    # user : nobody
    if ! [ -f /wordpress/.wp_downloaded ] ; then
        rm -rf /wordpress/*
        wp core download --locale="ko_KR"
        wp config create --dbname="${WP_DB_NAME}" --dbuser="${WP_DB_USER}" \
        --dbpass="${WP_DB_PASSWORD}" --dbhost="${WP_DB_HOST}" --locale="ko_KR"
        touch /wordpress/.wp_downloaded
    fi
    if ! wp core is-installed ; then
        logger_info "installing wordpress..."
        wp core install --url="${DOMAIN_NAME}" --title="blog_title" \
        --admin_user=${WP_ADMIN_USER} --admin_password=${WP_ADMIN_PASSWORD} \
        --admin_email=${WP_ADMIN_EMAIL} --skip-email
        wp user create ${WP_USER} ${WP_USER}@${DOMAIN_NAME} --user_pass=${WP_PASSWORD}
    else
        logger_info "wordpress is already installed!"
    fi;
    logger_info -n "wordpress version :"
    wp core version
fi

echo "Starting $@ ..."
exec "$@"
