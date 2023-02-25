FROM alpine:latest
RUN set -eux; \
    apk update; \
    apk add --no-cache vim mariadb mariadb-client; \
    rm -rf /var/cache/apk/*; \
    ls -la /var/lib/mysql; \
    ls -la /var/lib;

RUN set -eux; \
    rm -rf /var/lib/apk/lists/*; \
    rm -rf /var/lib/mysql; \
    mkdir -p /var/lib/mysql /var/run/mysqld;

RUN  set -eux; ls -al /var/lib; \
    chown -R mysql:mysql /var/lib/mysql /var/run/mysqld; \
    ls -la /var/lib; \
    ls -la /var/run; \
    chmod 777 /var/run/mysqld;

# comment out a few problematic configuration values
#RUN  set -ex; find /etc/mysql/ -name '*.cnf' -print0 ; \
		  #| xargs -0 grep -lZE '^(bind-address|log|user\s)' \
		  #| xargs -rt -0 sed -Ei 's/^(bind-address|log|user\s)/#&/'; \
    # don't reverse lookup hostnames, they are usually another container
	#printf "[mariadb]\nhost-cache-size=0\nskip-name-resolve\n" | tee /etc/mysql/mariadb.conf.d/05-skipcache.cnf; \
    #if [ -L /etc/mysql/my.cnf ]; then \
	#	sed -i -e '/includedir/ {N;s/\(.*\)\n\(.*\)/\n\2\n\1/}' /etc/mysql/mariadb.cnf; \
	#fi

VOLUME /var/lib/mysql

COPY docker-entrypoint.sh /usr/local/bin/
#USER mysql
#RUN whoami
ENTRYPOINT ["docker-entrypoint.sh"]
CMD [mariadbd]

EXPOSE 3306
