#!/usr/bin/env bash

set -e

platform="${1}"
envir="${2}"
builddir="${3}"
REPO_ROOT="${PWD}"

# fail out if platform, envir, and builddir are not all provided
if ! [[ -n ${platform} && -n ${envir} && -n ${builddir} ]]; then
  echo "Usage: ${0} <platform> <environment> <build-directory>"
  exit 1
fi

# check for root permissions
if [[ "$(id -u)" != 0 ]]; then
  echo "E: Requires root permissions" > /dev/stderr
  exit 1
fi

# cleanup function to trap EXIT & INT
function cleanup() {
  local catch=$?
  echo "
#-----------------#
# RESTORE BACKUPS #
#-----------------#
"
  # restore any patched files to their original state
  for i in "binary_grub-efi" "binary_rootfs"; do
    if [[ -f "${builddir}/${i}.bak" ]]; then
      cp "${builddir}/${i}.bak" "/usr/lib/live/build/${i}"
    fi
  done
  if [[ -f "${builddir}/functions.bak" ]]; then
    cp "${builddir}/functions.bak" /usr/share/debootstrap/functions
  fi
  # exit with caught code
  return "${catch}"
}

echo "
#-----------------#
# INIT SUBMODULES #
#-----------------#
"
git submodule update --init --recursive

echo "
#----------------------#
# INSTALL DEPENDENCIES #
#----------------------#
"
apt-get update
apt-get install -y \
  patch gnupg2 binutils zstd ubuntu-keyring \
  libglib2.0-dev libmysqlclient-dev apt-utils \
  debootstrap mtools dosfstools qemu-user-binfmt binfmt-support dpkg-dev
dpkg -i "base/base/debs/live-build_20220505_all.deb"

echo "
#----------------------#
# SOURCE BUILD SCRIPTS #
#----------------------#
"
# imports `overlayer` function
source "build-scripts/overlayer.sh"
# imports `lb_build` and `lb_run` functions; `lb_build` calls `lb_run`
source "build-scripts/live-build.sh"

echo "
#------------------------#
# CREATE BUILD DIRECTORY #
#------------------------#
"
overlayer "${platform}" "${envir}" "${builddir}"

# init trap after builddir created
trap "cleanup" EXIT INT

echo "
#-------------------#
# PATCH BUILD TOOLS #
#-------------------#
"
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
cp "${builddir}/functions.bak" functions
patch -i "${builddir}/0002-remove-WRONGSUITE-error.patch"
cp functions /usr/share/debootstrap/functions

echo "
#------------------#
# START LIVE-BUILD #
#------------------#
"
lb_build "${platform}" "${envir}" "${builddir}" "etc/terraform.conf"
cd "${REPO_ROOT}"
exit 0
