# TODO : write mariadb Docker file
# - word press 의 db가 되어야 한다.

# 얘네는 compose 인 것 같은데?
# - port 3306 (default) 연결
# - volume 연결
# FROM 에만 적용되는 ARG
ARG VERSION=latest
FROM alpine:$VERSION

RUN set -eux; \
    apk update; \
    apk add --no-cache su-exec vim mariadb mariadb-client; \
    rm -rf /var/cache/apk/*; \
    rm -rf /var/lib/apk/lists/*;

# comment out a few problematic configuration values
#RUN  set -ex; find /etc/mysql/ -name '*.cnf' -print0 ; \
		  #| xargs -0 grep -lZE '^(bind-address|log|user\s)' \
		  #| xargs -rt -0 sed -Ei 's/^(bind-address|log|user\s)/#&/'; \
    # don't reverse lookup hostnames, they are usually another container
	#printf "[mariadb]\nhost-cache-size=0\nskip-name-resolve\n" | tee /etc/mysql/mariadb.conf.d/05-skipcache.cnf; \
    #if [ -L /etc/mysql/my.cnf ]; then \
	#	sed -i -e '/includedir/ {N;s/\(.*\)\n\(.*\)/\n\2\n\1/}' /etc/mysql/mariadb.cnf; \
	#fi

# NOTE : run 할 때 volume 이름을 지정하지 않으면 unname volume 이 생성된다.
VOLUME /var/lib/mysql

COPY docker-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["mariadbd"]
# CMD 는 run 할 때 적으면 바뀌는!

EXPOSE 3306
