#!/bin/sh
set -eo pipefail # -x for debugging

logger_info() {
  printf "\033[32m"
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] [INFO] $@"
  printf "\033[0m"
}

logger_error() {
  printf "\033[31m"
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR] $@" >&2
  printf "\033[0m"
  exit 1
}

check_db_exists() {
  DATABASE_ALREADY_EXISTS=
  if [ -d "${DATADIR}mysql" ]; then
    DATABASE_ALREADY_EXISTS='true'
  fi
}

check_minimum_env() {
  if [ -z "$MYSQL_ROOT_PASSWORD" ] || [ -z "$MYSQL_USER" ] || [ -z "$MYSQL_PASSWORD" ]; then
    logger_error 'database is uninitialized and password option is not specified'
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
    echo $i th try ...
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

setup_db() {
  run_server_for_init "$@"
  logger_info "Initializing database ..."
  #mysql_tzinfo_to_sql '/usr/share/zoneinfo/Asia/Seoul' 'Asia/Seoul' | mysql --database=mysql
  local createUsers=
  # true 로 종료 방지
  # heredoc 은 envriotment variable 을 인식하지 못하므로 read(stdin 에서 한 줄 읽음) 로 한 번 변환.
  read -r -d '' createUsers <<-EOSQL || true
    CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE} ;
    CREATE USER 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' ;
    GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION ;
    CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}' ;
    GRANT ALL ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%' WITH GRANT OPTION ;
	EOSQL

  exec_client --binary-mode <<-EOSQL
    ${createUsers}
	EOSQL
}

if [ "$1" = 'mariadbd' ] || [ "$1" = 'mysqld' ]; then
  echo "Entrypoint script for MariaDB Server started."

  DATADIR="/var/lib/mysql/"
  SOCKET="/var/run/mysqld/mysqld.sock"
  check_db_exists

  # root
  if [ "$(id -u)" = '0' ]; then
    if [ -z "$DATABASE_ALREADY_EXISTS" ]; then
      rm -rf "${DATADIR}*"
    fi
    mkdir -p "$DATADIR" "${SOCKET%/*}"
    # 소유자가 mysql 이 아닌 파일들만 찾아서 권한을 바꾼다.
    find "${DATADIR}" \! -user mysql -exec chown mysql: '{}' +
    # /var/run/mysqld 의 권한만 바꾼다.
    find "${SOCKET%/*}" -maxdepth 0 \! -user mysql -exec chown mysql: '{}' \;
    exec su-exec mysql "$0" "$@"
  fi

  check_minimum_env
  if [ -z "$DATABASE_ALREADY_EXISTS" ]; then
    mysql_install_db --datadir="${DATADIR}"\
     '--skip-test-db' '--auth-root-socket-user=mysql'
    setup_db "$@"
    kill_server_for_init
  fi
fi

exec "$@"
