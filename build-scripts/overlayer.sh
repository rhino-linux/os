#!/usr/bin/env bash

function overlayer() {
  { ignore_stack=false; set -o pipefail; trap stacktrace ERR RETURN; }
  local o_platform="${1:?Platform required}" \
    o_envir="${2:?Environment required}" \
    o_builddir="${3:?Build directory required}" \
    overlay overlay_arr

  case "${o_platform}" in
    amd64|arm64)
      overlay_arr=({base,platform/iso-generic}/{base,environment/${o_envir}})
    ;;
    raspberrypi|raspi|rpi)
      if [[ ${o_envir} == "server" ]]; then
        overlay_arr=({base,platform/{img-preinst,rpi}}/base)
      else
        overlay_arr=({base,platform/{img-preinst,rpi}}/{base,environment/${o_envir}})
      fi
    ;;
    pinephone|pp|ppog|pinephonepro|ppp)
      overlay_arr=({base,platform/{img-preinst,pine64{,/phone}}}/{base,environment/${o_envir}})
    ;;
    pinetab|pt|ptog|pt1|pinetab2|pt2)
      overlay_arr=({base,platform/{img-preinst,pine64{,/tab}}}/{base,environment/${o_envir}})
    ;;
    *)
      fancy_message error "Unknown platform"
      return 1
    ;;
  esac

  mkdir -p "${o_builddir}"
  fancy_message info "Overlaying to build directory"
  fancy_message sub "Source: ${overlay_arr[*]}"
  fancy_message sub "Output: ${o_builddir}"
  for overlay in "${overlay_arr[@]}"; do
    if [[ -d ${overlay} ]]; then
      cp -r "${overlay}"/* -t "${o_builddir}"
    fi
  done
}
