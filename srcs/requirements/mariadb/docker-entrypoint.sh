#!/bin/sh
set -euo pipefail # -x for debugging

logger_info() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] [INFO] $@"
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
  if [ -d "${DATADIR}mysql" ]; then
    DATABASE_ALREADY_EXISTS='true'
  fi
}

check_minimum_env() {
  if [ -z $MYSQL_ROOT_PASSWORD ] || [ -z $MYSQL_USER ] || [ -z $MYSQL_PASSWORD ]; then
    logger_error 'database is uninitialized and password option is not specified '
  fi
}

# run command as mysql user
exec_client() {
  mariadb --protocol=socket -umysql -hlocalhost --socket="${SOCKET}" "$@"
}

kill_server_for_init() {
  kill "$MARIADB_PID"
  wait "$MARIADB_PID"
}

run_server_for_init() {
  # run as background process
  "$@" --skip-networking --socket="$SOCKET" \
  --loose-innodb_buffer_pool_load_at_startup=0 &
  MARIADB_PID=$!

  logger_info "Waiting for server startup ..."
  # only use the root password if the database has already been initialized
	# so that it won't try to fill in a password file when it hasn't been set yet
  local i
  # waiting server until timeout (30 seconds)
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

#sql_escape_string_literal() {
#  local newline=$'\n' # real newline
#	local escaped=${1//\\/\\\\}
#  echo $escaped
#	escaped="${escaped//$newline/\\n}"
#	echo "${escaped//\'/\\\'}"
#}

setup_db() {
  run_server_for_init "$@"

  local createUsers=
  # true 로 종료 방지
  # heredoc 은 envriotment variable 을 인식하지 못하므로 read(stdin 에서 한 줄 읽음) 로 한 번 변환.
  read -r -d '' createUsers <<-EOSQL || true
    CREATE USER 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' ;
    GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION ;
    CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}' ;
    GRANT ALL ON *.* TO '${MYSQL_USER}'@'%' WITH GRANT OPTION ;
	EOSQL

  exec_client --database=mysql --binary-mode <<-EOSQL
    ${createUsers}
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
  # TODO : datadir, socket extract logic
  DATADIR="/var/lib/mysql/"
  SOCKET="/var/run/mysqld/mysqld.sock"
  check_db_exists

  # root
  if [ "$(id -u)" = '0' ]; then
    # 이미 존재..하지 않으면 삭제.
    if [ -z $DATABASE_ALREADY_EXISTS ]; then
      rm -rf "${DATADIR}*"
    fi
    mkdir -p "$DATADIR" "${SOCKET%/*}"
    # 무조건 바꾸는 게 아니라 소유자가 mysql 이 아닌 파일들만 찾아서 권한을 바꾼다.
    find "${DATADIR}" \! -user mysql -exec chown mysql: '{}' +
    # /var/run/mysqld 의 권한만 바꾼다.
    find "${SOCKET%/*}" -maxdepth 0 \! -user mysql -exec chown mysql: '{}' \;
    # chown -R mysql:mysql ${DATADIR} /var/run/mysqld
    # 얘는 안에 있는 모든 file 을 재귀적으로 권한바꿈.
    # user를 mysql 로 변경하여 현재 스크립트를 재실행한다.
    exec su-exec mysql "$0" "$@"
  fi

  check_minimum_env

  if [ -z $DATABASE_ALREADY_EXISTS ]; then
    # mysql user 를 auth-root-socket-user 로 생성해서 바로 접속가능. (아마도 ^^)
    mysql_install_db --datadir="${DATADIR}"\
     '--skip-test-db' '--auth-root-socket-user=mysql'
    setup_db "$@"

    kill_server_for_init
  fi
fi

# TODO : edit configures
# 1. skip-networking=false

if [ "$1" = "mariadbd" ] ; then
  set -- $@  '--skip-networking=false'
fi

exec "$@"
