#!/usr/bin/env bash

function help_publish() {
  echo -e "Usage: $0 publish TYPE DESTINATION INDIR [IMAGES]

Publish downloaded images to a mirror location.

TYPE:
  Upload location type for setting rclone config:
    - sourceforge

IMAGES:
  Images to download (default: all):
    - all
    - amd64, amd64-lomiri
    - arm64, arm64-lomiri
    - rpi-desktop, rpi-server
    - pinephone, pinephone-lomiri
    - pinephonepro, pinephonepro-lomiri
    - pinetab, pinetab-lomiri
    - pinetab2, pinetab2-lomiri"
}

function verify() {
  { ignore_stack=false; set -o pipefail; trap stacktrace ERR RETURN; }
  local valid_images invalid_images download_list

  iso_images=({amd64,arm64}{,-lomiri})
  pine64_images=({pinephone{,pro},pinetab{,2}}{,-lomiri})
  rpi_images=(rpi-{desktop,server})
  export iso_images pine64_images rpi_images

  valid_images=("${iso_images[@]}" "${pine64_images[@]}" "${rpi_images[@]}")
  
  if contains selected "all"; then
    selected=("${valid_images[@]}")
    export selected
  fi

  for i in "${selected[@]}"; do
    if ! contains valid_images "${i}"; then
      invalid_images+=("${i}")
    fi
  done
  if [[ -n ${invalid_images[@]} ]]; then
    fancy_message error "Invalid image(s) supplied: ${invalid_images[*]}"
    return 1
  fi

  for i in "${selected[@]}"; do
    if contains iso_images "${i}"; then
      download_list+=("${i}.iso")
    else
      download_list+=("${i}.img.xz")
    fi
  done

  cd "${indir}" || return 1
  shopt -s nullglob
  artifacts=()
  for i in "${download_list[@]}"; do
    artifacts+=("Rhino-Linux-"*"-${i}")
  done
  shopt -u nullglob

  if [[ -z "${artifacts[@]}" ]]; then
    fancy_message error "No images downloaded"
    return 1
  fi
  export artifacts
}

function set_type() {
  { ignore_stack=false; set -o pipefail; trap stacktrace ERR RETURN; }
  case "${type}" in
    sourceforge)
      if [[ -z "${SOURCEFORGE_USER}" || -z "${SOURCEFORGE_PASS}" ]]; then
        fancy_message error "Variables 'SOURCEFORGE_USER' and 'SOURCEFORGE_PASS' must be set in environment"
        return 1
      fi
      rclone config create sourceforge sftp \
        host frs.sourceforge.net user "${SOURCEFORGE_USER}" \
        shell_type unix use_insecure_cipher true pass "${SOURCEFORGE_PASS}" --obscure
      ;;
    *)
      fancy_message error "Unknown destination type: ${type}"
      return 1
      ;;
  esac
}

function upload() {
  { ignore_stack=false; set -o pipefail; trap stacktrace ERR RETURN; }
  local target version

  cd "${indir}" || return 1
  for i in "${artifacts[@]}"; do
    version="${i#Rhino-Linux-}"
    version="${version%%-*}"
    case "${i}" in
      *.iso)
        target="${version}"
      ;;
      *pinephone*)
        target="${version}-pinephone"
      ;;
      *pinetab*)
        target="${version}-pinetab"
      ;;
      *rpi*)
        target="${version}-rpi"
      ;;
      *)
        fancy_message error "Unknown image: ${i}"
        return 1
      ;;
    esac
    sha256sum "${i}" > "${i}.sha256"
    rclone copyto --progress --sftp-ask-password "${i}.sha256" "${destination}/${target}/${i}.sha256"
    rclone copyto --progress --sftp-ask-password "${i}" "${destination}/${target}/${i}"
  done
}

function publish_steps() {
  { ignore_stack=false; set -o pipefail; trap stacktrace ERR RETURN; }
  verify || return 1
  set_type || return 1
  upload || return 1
  fancy_message info "Images published to ${destination}: ${artifacts[@]}"
}
