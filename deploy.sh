#!/usr/bin/env bash

set -e
# declare verbose debug output
declare -gx PS4=$'\E[0;10m\E[1m\033[1;31m\033[1;37m[\033[1;35m${BASH_SOURCE[0]##*/}:\033[1;34m${FUNCNAME[0]:-NOFUNC}():\033[1;33m${LINENO}\033[1;37m] - \033[1;33mDEBUG: \E[0;10m'

platform="${1}"
envir="${2}"
builddir="$(realpath ${3})"
REPO_ROOT="${PWD}"

# fail out if platform, envir, and builddir are not all provided
if ! [[ -n ${platform} && -n ${envir} && -n ${builddir} ]]; then
  echo "Usage: ${0} <platform> <environment> <build-directory>"
  exit 1
fi

#init sequences
source "build-scripts/stacktrace.sh"
set_colors

# cleanup function to trap EXIT & INT
export cleaned=false
function cleanup() {
  cd "${REPO_ROOT}"
  if ! ${cleaned}; then
    # put any cleanup steps here if/as needed
    export cleaned=true
  fi
}
trap cleanup EXIT INT

{ export ignore_stack=false; set -o pipefail; trap stacktrace ERR RETURN; }

function verify() {
  { ignore_stack=false; set -o pipefail; trap stacktrace ERR RETURN; }
  # check for root permissions
  if ((EUID != 0)); then
    fancy_message error "Requires root permissions"
    return 1
  fi

  # normalize platforms
  terra_envir="${envir}"
  case "${platform}" in
    raspberrypi|raspi|rpi)
      platform="rpi"
    ;;
    pinephone|pp|ppog)
      platform="pinephone"
    ;;
    pinephonepro|ppp)
      platform="pinephonepro"
    ;;
    pinetab|pt|ptog|pt1)
      platform="pinetab"
    ;;
    pinetab2|pt2)
      platform="pinetab2"  
    ;;
    *)
      fancy_message error "Unknown platform"
      return 1
    ;;
  esac
  terra_platform="${platform}"
  export terra_platform terra_envir

  # check validity of input
  valid_images=(
    {pinephone{,pro},pinetab{,2}}:{unicorn,lomiri}
    rpi:{unicorn,server}
  )

  if ! [[ "${valid_images[@]}" =~ "${platform}:${envir}" ]]; then
    fancy_message error "Invalid platform+environment combination"
    return 1
  fi

  # select environment-specific recipe and image names
  case "${platform}:${envir}" in
    pinephone:unicorn|pinephonepro:unicorn|pinetab:unicorn|pinetab2:unicorn)
      target="${platform}"
    ;;
    pinephone:lomiri|pinephonepro:lomiri|pinetab:lomiri|pinetab2:lomiri)
      target="${platform}-lomiri"
    ;;
    rpi:unicorn)
      target="rpi-desktop"
    ;;
    rpi:server)
      target="rpi-server"
    ;;
  esac
}

function source_scripts() {
  { ignore_stack=false; set -o pipefail; trap stacktrace ERR RETURN; }
  fancy_message info "Sourcing build scripts"
  source "build-scripts/overlayer.sh"
}

function create_builddir() {
  { ignore_stack=false; set -o pipefail; trap stacktrace ERR RETURN; }
  fancy_message info "Creating build directory"
  overlayer "${platform}" "${envir}" "${builddir}"
}

function init_config() {
  { ignore_stack=false; set -o pipefail; trap stacktrace ERR RETURN; }
  source "${builddir}/etc/terraform.conf"

  # check for root filesystem tarball
  tarball="${builddir}/binary/${FNAME}.tar"
  if ! [[ -f ${tarball} ]]; then
    fancy_message error "Root tarball not found, please run build.sh first and ensure output is placed in ${builddir}/binary"
    return 1
  fi
}

function start_deploy() {
  { ignore_stack=false; set -o pipefail; trap stacktrace ERR RETURN; }
  case "${target}" in
    rpi-desktop)
      recipe="raspberrypi-desktop.yaml"
    ;;
    rpi-server)
      recipe="raspberrypi-server.yaml"
    ;;
    *)
      recipe="${target}.yaml"
    ;;
  esac
  image="${FNAME}.img"

  cd "${builddir}"

  # begin deploy
  fancy_message info "Building ${image} from ${recipe}"
  bash "${builddir}/debos-docker" -t "image:${image}" -m 10G "${recipe}"

  fancy_message info "Moving build to output directory"
  output_dir="${builddir}/builds"
  mkdir -p "${output_dir}"
  mv "${image}" "${output_dir}"
  mv "${image}.bmap" "${output_dir}"

  cd "${REPO_ROOT}"
}

function deploy_steps() {
  { ignore_stack=false; set -o pipefail; trap stacktrace ERR RETURN; }
  verify || return 1
  source_scripts || return 1
  create_builddir || return 1
  init_config || return 1
  start_deploy || return 1
}

deploy_steps
exit 0
