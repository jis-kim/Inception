ARG VERSION=3.15
FROM alpine:$VERSION

ENV TZ=Asia/Seoul

RUN set -e; \
    apk update; \
    apk add --no-cache su-exec vim tzdata && \
    cp /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN set -e; \
    apk add --no-cache mariadb mariadb-client && \
    rm -rf /etc/my.cnf.d/* /etc/mysql/* /var/cache/apk/* /var/lib/apk/lists/*

COPY my.cnf /etc/my.cnf
COPY docker-entrypoint.sh /usr/local/bin/

VOLUME /var/lib/mysql
EXPOSE 3306

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["mariadbd"]
