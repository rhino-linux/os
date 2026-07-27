#!/bin/bash

set -e

platform=${1:?Platform required}
envir=${2:?Environment required}
terra=${3}

# check for root permissions
if [[ "$(id -u)" != 0 ]]; then
  echo "E: Requires root permissions" > /dev/stderr
  exit 1
fi

# get config
terra_envir="${envir}"
case ${platform} in
  amd64|arm64)
    terra_platform="${platform}"
  ;;
  raspberrypi|raspi|rpi)
    terra_platform="rpi"
  ;;
  pinephone|pp|ppog|pinephonepro|ppp)
    terra_platform="pinephone"
  ;;
  pinetab|pt|ptog|pt1|pinetab2|pt2)
    terra_platform="pinetab"
  ;;
  *)
    echo "Unknown platform, exiting"
    exit 1
  ;;
esac
export terra_platform terra_envir

if [[ -n "${terra}" ]]; then
  CONFIG_FILE="${terra}"
else
  CONFIG_FILE="etc/terraform.conf"
fi
BASE_DIR="${PWD}"
source "${BASE_DIR}/${CONFIG_FILE}"

#VanillaOS patch to yeet ia32
#sudo sed -i '/Check_package chroot \/usr\/lib\/grub\/i386-efi\/configfile.mod grub-efi-ia32-bin/d' /usr/lib/live/build/binary_grub-efi

echo -e "
#----------------------#
# INSTALL DEPENDENCIES #
#----------------------#
"

apt-get update
apt-get install -y patch gnupg2 binutils zstd ubuntu-keyring libglib2.0-dev libmysqlclient-dev apt-utils
ln -sfn /usr/share/debootstrap/scripts/gutsy /usr/share/debootstrap/scripts/devel

build() {
  BUILD_ARCH="${1}"

  mkdir -p "${BASE_DIR}/tmp/${BUILD_ARCH}"
  cd "${BASE_DIR}/tmp/${BUILD_ARCH}" || exit

  # remove old configs and copy over new
  rm -rf config auto
  cp -r "${BASE_DIR}"/etc/* .
  # Make sure conffile specified as arg has correct name
  cp -f "${BASE_DIR}/${CONFIG_FILE}" terraform.conf

  # Symlink chosen package lists to where live-build will find them
  ln -s "package-lists.${PACKAGE_LISTS_SUFFIX}" "config/package-lists"

  echo -e "
#------------------#
# LIVE-BUILD CLEAN #
#------------------#
"
  lb clean

  echo -e "
#-------------------#
# LIVE-BUILD CONFIG #
#-------------------#
"
  lb config

  echo -e "
#------------------#
# LIVE-BUILD BUILD #
#------------------#
"
  lb --force build

  echo -e "
#---------------------------#
# MOVE OUTPUT TO BUILDS DIR #
#---------------------------#
"

  case "${BUILD_TYPE}" in
    iso)
      OUTPUT_DIR="${BASE_DIR}/builds/${BUILD_ARCH}"
      INPUT_FILE="${BASE_DIR}/tmp/${BUILD_ARCH}/${FNAME}-${BUILD_ARCH}.hybrid.iso"
      OUTPUT_FILE="${FNAME}.iso"
    ;;
    img)
      OUTPUT_DIR="${BASE_DIR}/binary"
      INPUT_FILE="${BASE_DIR}/tmp/${BUILD_ARCH}/${FNAME}-${BUILD_ARCH}.tar.tar"
      OUTPUT_FILE="${FNAME}.tar"
    ;;
    *)
      echo "Invalid build type. Exiting..."
      exit 1
    ;;
  esac

  mkdir -p "${OUTPUT_DIR}"
  mv "${INPUT_FILE}" "${OUTPUT_DIR}/${OUTPUT_FILE}"

  # cd into output so {FNAME}.sha256.txt only
  # includes the filename and not the path to
  # our file.
  cd "${OUTPUT_DIR}"
  sha512sum "${OUTPUT_FILE}" > "${FNAME}.sha512"
  sha256sum "${OUTPUT_FILE}" > "${FNAME}.sha256"
  cd "${BASE_DIR}"
}

if [[ ${ARCH} == "all" ]]; then
  build amd64
else
  build "${ARCH}"
fi
