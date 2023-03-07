#  : wordpress Dockerfile
ARG VERSION=3.15
FROM alpine:$VERSION

RUN set -eux; \
    apk update; \
    apk add --no-cache vim su-exec mariadb-client \
    php8 php8-phar php8-fpm php8-common php8-session php8-iconv php8-json \
    php8-gd php8-curl php8-xml php8-mysqli; \
    ln -s /usr/bin/php8 /usr/bin/php; \
    rm -rf /var/cache/apk/*; \
    rm -rf /var/lib/apk/lists/*; \
    wget "https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar"; \
    chmod +x wp-cli.phar; \
    mv wp-cli.phar /usr/local/bin/wp; \
    wp --info; \
    mkdir -p /.wp-cli /var/log/php8; \
    chown nobody /.wp-cli /var/log/php8;

COPY docker-entrypoint.sh /usr/local/bin/
COPY www.conf /etc/php8/php-fpm.d/www.conf

VOLUME /wordpress
EXPOSE 9000

ENTRYPOINT [ "docker-entrypoint.sh" ]
CMD [ "php-fpm8", "-F" ]
