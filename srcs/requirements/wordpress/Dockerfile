#  : wordpress Dockerfile
ARG VERSION=3.15
FROM alpine:$VERSION

RUN set -eux; \
    cat /etc/resolv.conf; \
    #echo "http://pkg.adfinis.com/alpine/v3.11/community" >> /etc/apk/repositories; \
    cat /etc/apk/repositories; \
    apk update; \
    apk add --no-cache vim \
    php8 \
    php8-fpm \
    php8-common \
    php8-session \
    php8-iconv \
    php8-json \
    php8-gd \
    php8-curl \
    php8-xml \
    php8-mysqli \
    php8-imap \
    php8-pdo \
    php8-pdo_mysql \
    php8-soap \
    #php8-xmlrpc \ - php8 에서 안되는 패키지 2개
    #php8-mcrypt \
    php8-posix \
    php8-gettext \
    php8-ldap \
    php8-ctype \
    php8-dom \
    php8-simplexml; \
    rm -rf /var/cache/apk/*; \
    rm -rf /var/lib/apk/lists/*;

RUN set -eux; \
    wget https://wordpress.org/wordpress-6.1.1.tar.gz; \
    wget "https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar"; \
    php8 -v; \
    which php8; \
    #php8 wp-cli.phar --info; \
    chmod +x wp-cli.phar; \
    mv wp-cli.phar /usr/local/bin/wp;

COPY docker-entrypoint.sh /usr/local/bin/
VOLUME /wordpress
EXPOSE 9000

ENTRYPOINT [ "docker-entrypoint.sh" ]
CMD [ "php-fpm8" ]
