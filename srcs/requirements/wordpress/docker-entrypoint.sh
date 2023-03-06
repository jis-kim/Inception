#!/bin/sh
set -euxo pipefail

## NOTE : wordpress 압축 - 주석해제!
#tar -xzf /wordpress-6.1.1.tar.gz;

mkdir /.wp-cli && chown nobody /wordpress /.wp-cli;
ls -al /wordpress;
cd /wordpress;
su-exec nobody wp core download --locale=ko_KR
su-exec nobody wp config create --dbname="${WP_DB_NAME}"  --dbuser="${WP_DB_USER}" --dbpass="${WP_DB_PASSWORD}" --dbhost="${WP_DB_HOST}" --locale="${LOCALE}"
su-exec nobody wp core install --url="jiskim.42.fr" --title=wpwp --admin_user=wpwp --admin_password=wpwp --admin_email=jiskim@student.42seoul.kr --skip-email
su-exec nobody wp core version

if [ $1 = "php-fpm8" ]; then
    echo "Starting php-fpm8 ..."
    set -- $@ '-F' '-e'
fi

exec "$@"
