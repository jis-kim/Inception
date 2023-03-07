# NOTE : nginx Dockerfile
ARG VERSION=3.15
FROM alpine:$VERSION

RUN set -eux; \
    apk update; \
    apk add --no-cache vim nginx; \
    rm -rf /var/cache/apk/*; \
    rm -rf /var/lib/apk/lists/*; \
    cat /etc/nginx/nginx.conf;

VOLUME /var/www/html

COPY default.conf /etc/nginx/http.d/default.conf
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80

ENTRYPOINT [ "nginx", "-g", "daemon off;" ]
