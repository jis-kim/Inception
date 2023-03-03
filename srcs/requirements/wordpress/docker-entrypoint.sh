#!/bin/sh
set -euxo pipefail
#cat /etc/php8/php-fpm.d/www.conf

# NOTE : wordpress 압축 - 주석해제!
tar -xzvf /wordpress-6.1.1.tar.gz;

php8 --version
php-fpm8 --version

if [ $1 = "php-fpm8" ]; then
    set -- $@ '-F'
fi

echo "$@"
exec "$@"
