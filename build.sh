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
    fancy_message info "Restoring backups"
    # restore any patched files to their original state
    for i in "binary_grub-efi" "binary_rootfs"; do
      if [[ -f "${builddir}/${i}.bak" ]]; then
        cp "${builddir}/${i}.bak" "/usr/lib/live/build/${i}"
      fi
    done
    if [[ -f "${builddir}/functions.bak" ]]; then
      cp "${builddir}/functions.bak" /usr/share/debootstrap/functions
    fi
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
  case "${platform}" in
    amd64|arm64)
      # already normalized
    ;;
    raspberrypi|raspi|rpi)
      platform="rpi"
    ;;
    pinephone|pp|ppog|pinephonepro|ppp)
      platform="pinephone"
    ;;
    pinetab|pt|ptog|pt1|pinetab2|pt2)
      platform="pinetab"
    ;;
    *)
      fancy_message error "Unknown platform"
      return 1
    ;;
  esac

  # check validity of input
  valid_images=(
    {amd64,arm64,pinephone,pinetab}:{unicorn,lomiri}
    rpi:{unicorn,server}
  )

  if ! [[ "${valid_images[@]}" =~ "${platform}:${envir}" ]]; then
    fancy_message error "Invalid platform+environment combination"
    return 1
  fi
}

function init_submodules() {
  { ignore_stack=false; set -o pipefail; trap stacktrace ERR RETURN; }
  fancy_message info "Initializing submodules"
  git submodule update --init --recursive
}

function install_deps() {
  { ignore_stack=false; set -o pipefail; trap stacktrace ERR RETURN; }
  fancy_message info "Installing dependencies"
  apt-get update || return 1
  apt-get install -y \
    patch gnupg2 binutils zstd ubuntu-keyring \
    libglib2.0-dev libmysqlclient-dev apt-utils \
    debootstrap mtools dosfstools qemu-user-binfmt binfmt-support dpkg-dev || return 1
  dpkg -i "base/base/debs/live-build_20220505_all.deb" || return 1
}

function source_scripts() {
  { ignore_stack=false; set -o pipefail; trap stacktrace ERR RETURN; }
  fancy_message info "Sourcing build scripts"
  # imports `overlayer` function
  source "build-scripts/overlayer.sh"
  # imports `lb_build` and `lb_run` functions; `lb_build` calls `lb_run`
  source "build-scripts/live-build.sh"
}

function create_builddir() {
  { ignore_stack=false; set -o pipefail; trap stacktrace ERR RETURN; }
  fancy_message info "Creating build directory"
  overlayer "${platform}" "${envir}" "${builddir}"
}

function patch_tools() {
  { ignore_stack=false; set -o pipefail; trap stacktrace ERR RETURN; }
  fancy_message info "Patching build tools"
  # patch live-build functions
  for i in "binary_grub-efi" "binary_rootfs"; do
    if [[ -f "${builddir}/${i}" ]]; then
      if [[ -f "/usr/lib/live/build/${i}" ]]; then
        # copy backups if files present
        cp "/usr/lib/live/build/${i}" "${builddir}/${i}.bak"
      fi
      cp "${builddir}/${i}" "/usr/lib/live/build/${i}"
    fi
  done

  # allow devel debootstrapping
  ln -sfn /usr/share/debootstrap/scripts/gutsy /usr/share/debootstrap/scripts/devel

  # patch out debootstrap error
  cp /usr/share/debootstrap/functions "${builddir}/functions.bak"
  cp "${builddir}/functions.bak" "${builddir}/functions"
  cd "${builddir}"
  patch -i "0002-remove-WRONGSUITE-error.patch"
  cp "${builddir}/functions" /usr/share/debootstrap/functions
  cd "${REPO_ROOT}"
}

function start_livebuild() {
  { ignore_stack=false; set -o pipefail; trap stacktrace ERR RETURN; }
  fancy_message info "Starting live-build"
  lb_build "${platform}" "${envir}" "${builddir}" "etc/terraform.conf"
  cd "${REPO_ROOT}"
}

function build_steps() {
  { ignore_stack=false; set -o pipefail; trap stacktrace ERR RETURN; }
  verify || return 1
  init_submodules || return 1
  install_deps || return 1
  source_scripts || return 1
  create_builddir || return 1
  patch_tools || return 1
  start_livebuild || return 1
}

build_steps
exit 0
