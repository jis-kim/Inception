_verboseHelpArgs=( --help --verbose )


print_configs() {
  local conf="$1" shift
  "$@" "${_verboseHelpArgs[@]}" 2>&1 | grep -E "^$conf"
}

print_configs socket "$@"
