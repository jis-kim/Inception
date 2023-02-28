#!/bin/sh
set -exuo pipefail

logger_info() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] [INFO] $@"
}

logger_warn() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] [WARN] $@" >&2
}

logger_error() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR] $@" >&2
  exit 1
}

print_configs() {
  local conf="$1"; shift
  "$@" "--verbose" "--help" 2>/dev/null | grep "^$conf"
}

check_db_exists() {
  DATABASE_ALREADY_EXISTS=
  if [ -d "/var/lib/mysql/mysql" ]; then
    DATABASE_ALREADY_EXISTS='true'
  fi
}

check_minimum_env() {
  if [ -z $MYSQL_ROOT_PASSWORD ] || [ -z $MYSQL_USER ] || [ -z $MYSQL_PASSWORD ]; then
    logger_error 'error: database is uninitialized and password option is not specified '
  fi
}

# run command as root@localhost
exec_client() {
  mariadb -umysql "$@"
}

kill_server() {
  kill "$MARIADB_PID"
  wait "$MARIADB_PID"
}

run_server_for_init() {
  # run as background process
  "$@" --skip-networking --socket="/var/run/mysqld/mysqld.sock" \
  --loose-innodb_buffer_pool_load_at_startup=0 &
  MARIADB_PID=$!

  logger_info "Waiting for server startup ..."

  # only use the root password if the database has already been initialized
	# so that it won't try to fill in a password file when it hasn't been set yet
  local i
  # decreasing 30 to 0 until timeout (30 seconds)
	for i in `seq 0 30` ; do
    echo $i th try
		if echo "SELECT 1" | exec_client --database=mysql; then
			break
		fi
		sleep 1
	done
  if [ "$i" = 30 ]; then
    logger_error "Unable to start server."
  fi
  logger_info "Connected to server successfully!"
}

#stop_server_for_init() {
#}


#sql_escape_string_literal() {
#  local newline=$'\n' # real newline
#	local escaped=${1//\\/\\\\}
#  echo $escaped
#	escaped="${escaped//$newline/\\n}"
#	echo "${escaped//\'/\\\'}"
#}

setup_db() {
  run_server_for_init "$@"

  local rootCreate=
  # true 로 종료 방지
  read -r -d '' rootCreate <<-EOSQL || true
    CREATE USER 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' ;
    GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION ;
    CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}' ;
    GRANT ALL ON *.* TO '${MYSQL_USER}'@'%' WITH GRANT OPTION ;
	EOSQL

  exec_client --database=mysql --binary-mode <<-EOSQL
    ${rootCreate}
	EOSQL
}

#if [ "${1:0:1}" = '-' ]; then
#  set -- mariadbd "$@"
#fi
#if [ "$1" = 'mariadbd' ] || [ "$1" = 'mysqld' ] && ! _mysql_want_help "$@"; then
if [ "$1" = 'mariadbd' ] || [ "$1" = 'mysqld' ]; then
  echo "Entrypoint script for MariaDB Server started."

  print_configs 'datadir' "$@"
  print_configs 'socket' "$@"
  check_db_exists

  # root
  if [ "$(id -u)" = '0' ]; then
    # 이미 존재..하지 않으면 삭제.
    if [ -z $DATABASE_ALREADY_EXISTS ]; then
      rm -rf /var/lib/mysql/*
    fi
    mkdir -p /var/lib/mysql /var/run/mysqld
    # 무조건 바꾸는 게 아니라 소유자가 mysql 이 아닌 파일들만 찾아서 권한을 바꾼다. 진짜 또라이아님?
    find "/var/lib/mysql/" \! -user mysql -exec chown mysql: '{}' +
    # /var/run/mysqld 의 권한만 바꾼다.
    find "/var/run/mysqld/" -maxdepth 0 \! -user mysql -exec chown mysql: '{}' \;
    # chown -R mysql:mysql /var/lib/mysql /var/run/mysqld
    # 얘는 안에 있는 모든 file 을 재귀적으로 권한바꿈.
    exec su-exec mysql "$0" "$@"
  fi

  check_minimum_env

  if [ -z $DATABASE_ALREADY_EXISTS ]; then
    # mysql user 를 auth-root-socket-user 로 생성해서 바로 접속가능. (아마도 ^^)
    mysql_install_db --datadir="/var/lib/mysql/" --auth-root-socket-user=mysql
    setup_db "$@"

    kill_server
  fi

fi

exec "$@" # 확장성 - COMMAND

#/bin/sh
