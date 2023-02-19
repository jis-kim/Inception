# TODO : write mariadb Docker file
# - word press 의 db가 되어야 한다.
# .env 를 이용한 환경변수 설정
# db 사용자가 두 명.
# 1. administrator (사용자 명이 admin, Admin 등이면 안된다.)
# 2. 일반 유저.
# 볼륨 설정 위치 : /home/login/data 폴더.


# 얘네는 compose 인 것 같은데?
# - port 3306 (default) 연결
# - volume 연결
# FROM 에만 적용되는 ARG
ARG VERSION=latest
FROM alpine:$VERSION

# 어디에 출력되는 거임...?
RUN set -ex; /bin/sh; ls; apk update; echo hihi;

#RUN whoami; apk add mariadb mariadb-client; ps;

ENV LANG C.UTF-8

COPY *.txt /home/login/data/

ENTRYPOINT [ "/bin/sh" ]

RUN whoami; ps;
#RUN which mariadb

EXPOSE 3306/TCP

#CMD ["mariadbd"]
