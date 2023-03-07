#!/bin/sh
set -euxo pipefail

check_minimum_env() {
    if [ -z $WP_DB_HOST ] || [ -z $WP_DB_NAME  ] || [ -z $WP_DB_USER ] || [ -z $WP_DB_PASSWORD ]; then
        echo >&2 "error: missing required WP_DB_HOST, WP_DB_NAME, WP_DB_USER, WP_DB_PASSWORD environment variables"
        echo >&2 "  Please check your .env file and make sure you have set all required variables."
        exit 1
    fi
}

if [ "$(id -u)" = '0' ]; then
    mkdir -p /.wp-cli /var/log/php8 && chown nobody /wordpress /.wp-cli /var/log/php8;
    cd /wordpress && exec su-exec nobody "$0" "$@"
fi;
check_minimum_env

# user : nobody
if ! $(wp core is-installed) ; then
    echo "installing wordpress..."
    wp core download --locale=ko_KR
    wp config create --dbname="${WP_DB_NAME}" --dbuser="${WP_DB_USER}" --dbpass="${WP_DB_PASSWORD}" --dbhost="${WP_DB_HOST}" --locale="ko_KR"
    wp core install --url="${DOMAIN_NAME}" --title="blog_title" --admin_user=wpwp --admin_password=wpwp --admin_email=jiskim@student.42seoul.kr --skip-email
else
    echo "wordpress is already installed!"
fi;
echo -n "wordpress version :"
wp core version

echo "Starting $@ ..."
exec "$@"
