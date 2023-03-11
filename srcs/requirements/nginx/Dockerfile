ARG VERSION=3.15
FROM alpine:$VERSION

ENV TZ=Asia/Seoul

RUN set -e; \
    apk update; \
    apk add --no-cache su-exec vim tzdata && \
    cp /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN set -e; \
    apk add --no-cache openssl nginx && \
    mkdir -p /var/lib/nginx/keys && \
    rm -rf /var/cache/apk/* /var/lib/apk/lists/*

RUN adduser -D -s /sbin/nologin -H -u 4242 -G www-data www-data

COPY default.conf /etc/nginx/http.d/default.conf
COPY nginx.conf /etc/nginx/nginx.conf
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

VOLUME /var/www/html
EXPOSE 80 443

ENTRYPOINT [ "docker-entrypoint.sh" ]
CMD [ "nginx", "-g", "daemon off;" ]
