#!/usr/bin/env bash

function help_pull() {
  echo -e "Usage: $0 REPO BRANCH OUTDIR [IMAGES]

Download images produced by GitHub Actions workflows for publishing.

IMAGES:
    Images to download (default: all):
    - all
    - amd64, amd64-lomiri
    - arm64, arm64-lomiri
    - rpi-desktop, rpi-servers
    - pinephone, pinephone-lomiri
    - pinephonepro, pinephonepro-lomiri
    - pinetab, pinetab-lomiri
    - pinetab2, pinetab2-lomiri"
}

function verify() {
  { ignore_stack=false; set -o pipefail; trap stacktrace ERR RETURN; }
  local valid_images invalid_images

  iso_images=({amd64,arm64}{,-lomiri})
  pine64_images=({pinephone{,pro},pinetab{,2}}{,-lomiri})
  rpi_images=(rpi-{desktop,server})
  export iso_images pine64_images rpi_images

  valid_images=("${iso_images[@]}" "${pine64_images[@]}" "${rpi_images[@]}" "all")

  for i in "${selected[@]}"; do
    if ! contains valid_images "${i}"; then
      invalid_images+=("${i}")
    fi
  done
  if [[ -n ${invalid_images[@]} ]]; then
    fancy_message error "Invalid image(s) supplied: ${invalid_images[*]}"
    return 1
  fi
}

function find_run() {
  { ignore_stack=false; set -o pipefail; trap stacktrace ERR RETURN; }
  local f_workflow="${1}" f_run
  f_run="$(
    gh run list \
      -r "${repo}" -b "${branch}" -w "${f_workflow}" \
      -s success --json databaseId -q '.[].databaseId' -L 1
    )"
  if [[ -z ${f_run} || ${f_run} == "null" ]]; then
    fancy_message error "No successful ${f_workflow} run found for ${repo}:${branch}"
    return 1
  fi
  echo "${f_run}"
}

function download() {
  { ignore_stack=false; set -o pipefail; trap stacktrace ERR RETURN; }
  local download_ext workflow_ext download_key workflow run
  mkdir -p "${outdir}"
  for i in "${selected[@]}"; do
    if contains iso_images "${i}"; then
      download_ext="iso"
      workflow_ext="iso"
    else
      download_ext="img.xz"
      if contains pine64_images "${i}"; then
        workflow_ext="pine64"
      else
        workflow_ext="rpi"
      fi
    fi
    download_key="Rhino-Linux-*-${i}.${download_ext}"
    workflow="build-${workflow_ext}.yaml"
    run="$(find_run "${workflow}" || return 1)"
    fancy_message info "Downloading ${download_key} from ${workflow}"
    gh run download -r "${repo}" -p "${download_key}" -d "${outdir}" "${run}" || return 1
  done
}

function pull_steps() {
  { ignore_stack=false; set -o pipefail; trap stacktrace ERR RETURN; }
  verify || return 1
  download || return 1
  fancy_message info "Images ready for upload under ${outdir}"
}
