#  : wordpress Dockerfile
ARG VERSION=3.15
FROM alpine:$VERSION

ENV TZ=Asia/Seoul

RUN set -eux; \
    apk update; \
    apk add --no-cache su-exec vim tzdata && \
    cp /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    apk del tzdata

RUN set -eux; \
    apk add --no-cache mariadb-client \
    php8 php8-phar php8-fpm php8-common php8-session php8-iconv php8-json \
    php8-gd php8-curl php8-xml php8-mysqli && \
    ln -s /usr/bin/php8 /usr/bin/php && \
    wget "https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar" && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp && \
    rm -rf /var/cache/apk/* /var/lib/apk/lists/*

RUN adduser -D -s /sbin/nologin -H -u 4242 -G www-data www-data

COPY docker-entrypoint.sh /usr/local/bin/
COPY www.conf /etc/php8/php-fpm.d/www.conf

VOLUME /wordpress
EXPOSE 9000

ENTRYPOINT [ "docker-entrypoint.sh" ]
CMD [ "php-fpm8", "-F" ]
