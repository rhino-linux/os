#!/usr/bin/env bash

function set_colors() {
  # Colors
  export BOLD='\033[1m'
  export NC="\033[0m"

  export BLACK='\033[0;30m'
  export RED='\033[0;31m'
  export GREEN='\033[0;32m'
  export YELLOW='\033[0;33m'
  export BLUE='\033[0;34m'
  export PURPLE='\033[0;35m'
  export CYAN='\033[0;36m'
  export WHITE='\033[0;37m'

  export BBlack='\033[1;30m'
  export BRed='\033[1;31m'
  export BGreen='\033[1;32m'
  export BYellow='\033[1;33m'
  export BBlue='\033[1;34m'
  export BPurple='\033[1;35m'
  export BCyan='\033[1;36m'
  export BWhite='\033[1;37m'
}

function fancy_message() {
  local MESSAGE_TYPE="${1}" MESSAGE="${2}" FANCYTEXT
  shift 2
  local PRINTARGS=("${@}")
  case ${MESSAGE_TYPE} in
    info) FANCYTEXT="[${BGreen}+${NC}] ${BOLD}INFO${NC}:" ;;
    warn) FANCYTEXT="[${BYellow}*${NC}] ${BOLD}WARNING${NC}:" ;;
    error) FANCYTEXT="[${BRed}!${NC}] ${BOLD}ERROR${NC}:" ;;
    sub) FANCYTEXT="\t[${BBlue}>${NC}]" ;;
    *) FANCYTEXT="[${BOLD}?${NC}] ${BOLD}UNKNOWN${NC}:" ;;
  esac
  case ${MESSAGE_TYPE} in
    info | sub) printf "${FANCYTEXT} ${MESSAGE}\n" "${PRINTARGS[@]}" ;;
    *) printf "${FANCYTEXT} ${MESSAGE}\n" "${PRINTARGS[@]}" >&2 ;;
  esac
}

function stacktrace() {
  local catch=$?
  if ((catch != 0)) && ! ${ignore_stack}; then
    local i stack_size=${#FUNCNAME[@]} func linen src trace stack_color color_idx \
      colors=(196 197 198 199 200 201 165 129 93 57 21 27 33 39 45 51 50 49 48 47 46 82 118 154 190 226 220 214 208 202)
    echo -e "[${BRed}!${NC}] ${BOLD}ERROR${NC}: Stacktrace (most recent call last)" >&2
    for ((i = stack_size - 1; i >= 1; i--)); do
      color_idx=$(((stack_size - 1 - i) % ${#colors[@]}))
      stack_color="\033[38;5;${colors[color_idx]}m"
      ((i != stack_size - 1)) && func="${FUNCNAME[i - 1]}"
      [[ -z ${func} ]] && func='MAIN'
      [[ ${func} == "stacktrace" ]] && { unset func; trace="${RED}TRACEBACK${NC}"; }
      linen="${BASH_LINENO[i - 1]}"
      src="${BASH_SOURCE[i]}"
      if [[ -z ${src} ]]; then
        src=non_file_source
      elif [[ ${src} == "./rhino-os.sh" ]]; then
        src="${REPO_ROOT}/rhino-os.sh"
      fi
      echo -e " ${stack_color}${func:+├}${trace:+╰}─➤${GREEN}${func}${NC}${trace}${NC}${func:+()}${trace:+:} ${src%/*}/${PURPLE}${src##*/}${NC}:${YELLOW}${linen}${NC}" >&2
      # shellcheck disable=SC2027
      echo -e " ${stack_color}${func:+│}${trace:+ }${NC}  ${CYAN}╰───➤${NC} \033[38;5;242m"$(tail -n +"${linen}" "${src}" | head -n1)"${NC}" >&2
    done
    cleanup
    exit 1
  else
    export ignore_stack=false
    return "${catch}"
  fi
}

function contains() {
  { ignore_stack=false; set -o pipefail; trap stacktrace ERR RETURN; }
  local check
  local -n arra="${1:?No array passed to array.contains}"
  local input="${2:?No input given to array.contains}"
  for check in "${arra[@]}"; do
    if [[ ${check} == "${input}" ]]; then
      return 0
    fi
  done
  { ignore_stack=true; return 1; }
}
