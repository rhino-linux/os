#!/usr/bin/env bash

shopt -s nullglob

platform=${1:?Platform required}
envir=${2:?Environment required}
builddir=${3:?Build directory required}

case ${platform} in
  amd64|arm64)
    overlays=({base,platform/iso-generic}/{base,environment/${envir}})
  ;;
  raspberrypi|raspi|rpi)
    if [[ ${envir} == "server" ]]; then
      overlays=({base,platform/{img-preinst,rpi}}/base)
    else
      overlays=({base,platform/{img-preinst,rpi}}/{base,environment/${envir}})
    fi
  ;;
  pinephone|pp|ppog|pinephonepro|ppp)
    overlays=({base,platform/{img-preinst,pine64{,/phone}}}/{base,environment/${envir}})
  ;;
  pinetab|pt|ptog|pt1|pinetab2|pt2)
    overlays=({base,platform/{img-preinst,pine64{,/tab}}}/{base,environment/${envir}})
  ;;
  *)
    echo "Unknown platform, exiting"
    exit 1
  ;;
esac

mkdir -p "${builddir}"
echo -e "Overlaying:\n  Source: ${overlays[*]}\n  Output: ${builddir}"
for i in "${overlays[@]}"; do
  if [[ -d ${i} ]]; then
    cp -r "${i}"/* -t "${builddir}"
  fi
done
