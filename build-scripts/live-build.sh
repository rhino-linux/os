#!/usr/bin/env bash

function lb_run() {
  { ignore_stack=false; set -o pipefail; trap stacktrace ERR RETURN; }
  local BUILD_ARCH="${1}" \
    BASE_DIR="${2}" \
    CONFIG_FILE="${3}" \
    OUTPUT_DIR INPUT_FILE OUTPUT_FILE

  mkdir -p "${BASE_DIR}/tmp/${BUILD_ARCH}"
  cd "${BASE_DIR}/tmp/${BUILD_ARCH}" || return 1

  # remove old configs and copy over new
  rm -rf config auto
  cp -r "${BASE_DIR}/etc/"* .
  # Make sure conffile specified as arg has correct name
  cp -f "${BASE_DIR}/${CONFIG_FILE}" terraform.conf

  # Symlink chosen package lists to where live-build will find them
  ln -s "package-lists.${PACKAGE_LISTS_SUFFIX}" "config/package-lists"

  fancy_message info "Running live-build clean"
  lb clean

  fancy_message info "Running live-build config"
  lb config

  fancy_message info "Running live-build build"
  lb --force build

  fancy_message info "Moving build to output directory"
  case "${BUILD_TYPE}" in
    iso)
      OUTPUT_DIR="${BASE_DIR}/builds"
      INPUT_FILE="${BASE_DIR}/tmp/${BUILD_ARCH}/${FNAME}-${BUILD_ARCH}.hybrid.iso"
      OUTPUT_FILE="${FNAME}.iso"
    ;;
    img)
      OUTPUT_DIR="${BASE_DIR}/binary"
      INPUT_FILE="${BASE_DIR}/tmp/${BUILD_ARCH}/${FNAME}-${BUILD_ARCH}.tar.tar"
      OUTPUT_FILE="${FNAME}.tar"
    ;;
    *)
      fancy_message error "Invalid build type"
      return 1
    ;;
  esac

  mkdir -p "${OUTPUT_DIR}"
  mv "${INPUT_FILE}" "${OUTPUT_DIR}/${OUTPUT_FILE}"

  # cd into output so {FNAME}.sha256.txt only
  # includes the filename and not the path to
  # our file.
  fancy_message info "Generating hashes"
  cd "${OUTPUT_DIR}"
  sha512sum "${OUTPUT_FILE}" > "${FNAME}.sha512"
  sha256sum "${OUTPUT_FILE}" > "${FNAME}.sha256"
  cd "${BASE_DIR}"
}

function lb_build() {
  { ignore_stack=false; set -o pipefail; trap stacktrace ERR RETURN; }
  local lb_platform="${1:?Platform required}" \
    lb_envir="${2:?Environment required}" \
    lb_builddir="${3:?Build directory required}" \
    lb_terra="${4}" SBASE_DIR SCONFIG_FILE

  # get config
  terra_envir="${lb_envir}"
  case "${lb_platform}" in
    amd64|arm64)
      terra_platform="${lb_platform}"
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
      fancy_message error "Unknown platform"
      return 1
    ;;
  esac
  export terra_platform terra_envir

  if [[ -n ${lb_terra} ]]; then
    SCONFIG_FILE="${lb_terra}"
  else
    SCONFIG_FILE="etc/terraform.conf"
  fi
  SBASE_DIR="${lb_builddir}"
  source "${SBASE_DIR}/${SCONFIG_FILE}"

  #VanillaOS patch to yeet ia32
  #sudo sed -i '/Check_package chroot \/usr\/lib\/grub\/i386-efi\/configfile.mod grub-efi-ia32-bin/d' /usr/lib/live/build/binary_grub-efi
  if [[ -z ${ARCH} ]]; then
    fancy_message error "ARCH not found"
    return 1
  elif [[ ${ARCH} == "all" ]]; then
    lb_run amd64 "${SBASE_DIR}" "${SCONFIG_FILE}"
  else
    lb_run "${ARCH}" "${SBASE_DIR}" "${SCONFIG_FILE}"
  fi
}
