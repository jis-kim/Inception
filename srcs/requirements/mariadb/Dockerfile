ARG VERSION=3.15
FROM alpine:$VERSION

RUN set -eux; \
    apk update; \
    apk add --no-cache su-exec vim mariadb mariadb-client; \
    rm -rf /var/cache/apk/*; \
    rm -rf /var/lib/apk/lists/*; \
    rm -rf /etc/my.cnf.d/* /etc/mysql/* \

COPY my.cnf /etc/my.cnf
COPY docker-entrypoint.sh /usr/local/bin/

VOLUME /var/lib/mysql
EXPOSE 3306

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["mariadbd"]

