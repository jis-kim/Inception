#!/bin/sh
set -exuo pipefail

#_verboseHelpArgs=(
#  --verbose --help
#)
print_configs() {
  local conf="$1"; shift
  "$@" "--verbose" "--help" 2>/dev/null | grep "^$conf"
  whoami;
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
    # 아 그냥 같은 스크립트 다시 실행하는 거임 ㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋ 이걸 왤케 나중에 하지?
    # 뭔가 환경변수 같은 것도 설정 가능하도록 하는 듯?
  fi
  mysql_install_db --datadir="/var/lib/mysql/" --auth-root-socket-user=mysql

fi

exec "${@}" # 확장성 - COMMAND
#/bin/sh
