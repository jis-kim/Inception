#!/bin/sh
set -xuo pipefail



print_configs() {
  local conf="$1"; shift
  "$@" "--verbose" "--help" 2>/dev/null | grep "^$conf"
  whoami;
}

check_minimum_env() {
  if [ -z $MARIADB_ROOT_PASSWORD ] && [ -z $MARIADB)]
}

#if [ "${1:0:1}" = '-' ]; then
#  set -- mariadbd "$@"
#fi
#if [ "$1" = 'mariadbd' ] || [ "$1" = 'mysqld' ] && ! _mysql_want_help "$@"; then
if [ "$1" = 'mariadbd' ] || [ "$1" = 'mysqld' ]; then
  echo "Entrypoint script for MariaDB Server started."

  print_configs 'datadir' "$@"
  print_configs 'socket' "$@"

  if [ "$(id -u)" = '0' ]; then
    exec su-exec mysql "$0" "$@"
  fi

  check_minimum_env

  mysql_install_db --datadir="/var/lib/mysql/" --auth-root-socket-user=mysql

fi

exec "$@" # 확장성 - COMMAND

#/bin/sh
