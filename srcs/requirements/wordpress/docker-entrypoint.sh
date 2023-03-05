#!/bin/sh
set -euxo pipefail
#cat /etc/php8/php-fpm.d/www.conf

## NOTE : wordpress 압축 - 주석해제!
#tar -xzf /wordpress-6.1.1.tar.gz;

touch /var/log/php8/access.log && chmod 777 /var/log/php8/access.log

if [ $1 = "php-fpm8" ]; then
    echo "Starting php-fpm8 ..."
    set -- $@ '-F' '-e'
fi

exec "$@"
