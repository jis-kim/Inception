# NOTE : nginx Dockerfile
ARG VERSION=3.15
FROM alpine:$VERSION

RUN set -eux; \
    apk update; \
    apk add --no-cache vim openssl nginx; \
    rm -rf /var/cache/apk/*; \
    rm -rf /var/lib/apk/lists/*; \
    openssl genrsa -out /private.key; \
    openssl req -new -key /private.key -out server.csr -subj "/"; \
    openssl x509 -req -days 365 -in server.csr -signkey private.key -out server.crt;


VOLUME /var/www/html

COPY default.conf /etc/nginx/http.d/default.conf
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 443

ENTRYPOINT [ "nginx", "-g", "daemon off;" ]
