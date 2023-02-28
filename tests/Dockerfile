FROM alpine:latest
RUN set -eux; \
    apk update; \
    apk add --no-cache su-exec vim mariadb mariadb-client; \
    rm -rf /var/cache/apk/*; \
    ls -la /var/lib/mysql; \
    ls -la /var/lib;

RUN set -eux; \
    rm -rf /var/lib/apk/lists/*; \
    rm -rf /var/lib/mysql; \
    mkdir -p /var/lib/mysql /var/run/mysqld; \
    ls -al /var/lib; \
    chown -R mysql:mysql /var/lib/mysql /var/run/mysqld; \
    ls -la /var/lib; \
    ls -la /var/run/mysqld; \
    chmod 777 /var/run/mysqld;

VOLUME /var/lib/mysql

COPY docker-entrypoint.sh /usr/local/bin/
#RUN chmod 777 /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["mariadbd"]
# CMD 는 run 할 때 적으면 바뀌는;;

EXPOSE 3306
