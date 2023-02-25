#!/bin/sh
set -exuo pipefail
#shopt -s nullglob

#_verboseHelpArgs=(
#  --verbose --help
#)


print_configs() {
  local conf="$1"; shift
  "$@" "--verbose" "--help" 2>/dev/null | grep "^$conf"
  whoami;
}

print_configs 'datadir' "$@"
print_configs 'socket' "$@"

if [ "$(id -u)" = '0' ]; then
  exec su-exec mysql "$0" "$@"
  echo "왜 실행 두 번 됨? 돌았나"
  # 아 그냥 같은 스크립트 다시 실행하는 거임 ㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋ 이걸 왤케 나중에 하지?
  # 뭔가 환경변수 같은 것도 설정 가능하도록 하는 듯?
fi

echo ${BASH_SOURCE:-} # sh 에는 없을듯..

/bin/sh
