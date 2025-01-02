
CYAN="\033[0;36m" 
PURPLE="\033[0;35m"
RESET="\033[0m"

function is_true {
    local val=${1,,} # convert to lower case
    case "$val" in
        "true" | "t" | "yes" | "1") return 0 ;;
        *) return 1 ;;
    esac
}

function notify() {
  script="$1"

  if [ -n "$script" ]; then
    export MESSAGE="$2"
    bash -c "$script"
  fi
}
