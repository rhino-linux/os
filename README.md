# Rhino Linux Image Builder

Originally forked from [Vanilla-OS's ISO builder](https://github.com/Vanilla-OS/live-iso).

This is an overlay-based build system for producing Rhino Linux images.
A single checkout can build images for all supported platforms by composing
overlays from `base/` and `platform/` directories.

## Platforms

| Platform arg | Output | Arch | Environment |
|---|---|---|---|
| `amd64` | `.iso` | amd64 | `unicorn`, `lomiri` |
| `arm64` | `.iso` | arm64 | `unicorn`, `lomiri` |
| `pinephone` / `pp` | `.img.xz` | arm64 | `unicorn`, `lomiri` |
| `pinephonepro` / `ppp` | `.img.xz` | arm64 | `unicorn`, `lomiri` |
| `pinetab` / `pt` | `.img.xz` | arm64 | `unicorn`, `lomiri` |
| `pinetab2` / `pt2` | `.img.xz` | arm64 | `unicorn`, `lomiri` |
| `rpi` / `raspi` / `raspberrypi` | `.img.xz` | arm64 | `desktop`, `server` |

## Building Locally

You need:
- Root access (for live-build / debootstrap)
- Docker (for the debos stage on ARM platforms only)

### Stage 1: Root filesystem (all platforms)

`build.sh` handles dependency installation, submodule init, overlay assembly
(via `build-scripts/overlayer.sh`), and the live-build cycle (via
`build-scripts/live-build.sh`).

```sh
# ISO — for x86_64 or ARM64 PCs
sudo ./build.sh amd64 unicorn /tmp/rl-build
sudo ./build.sh arm64 lomiri /tmp/rl-build

# Tarball — for PinePhone, PineTab, or Raspberry Pi
sudo ./build.sh pinephone unicorn /tmp/rl-build
sudo ./build.sh rpi desktop /tmp/rl-build
```

Outputs:
- ISO: `builds/<arch>/Rhino-Linux-<version>-<platform>.iso`
- Tarball: `binary/Rhino-Linux-<version>-<platform>.tar`

### Stage 2: Disk image from tarball (Pine64, RPi only)

The overlay system copies everything needed (YAML recipes, scripts, Dockerfile,
polish.yaml) into the build directory. Run from there:

```sh
cd /tmp/rl-build

# Verify the tarball is ready
ls -lh binary/*.tar

# Build the disk image (requires Docker, kvm group membership)
./debos-docker --privileged \
  -t image:"Rhino-Linux-2025.1-pinephone.img" \
  -m 10G \
  pinephone.yaml

# Compress
xz -v Rhino-Linux-*-pinephone.img
```

The `.img` lands in the current directory. Move + compress as needed.

**YAML recipe files** (already in the build directory after stage 1):

| Platform | Recipe |
|---|---|
| PinePhone | `pinephone.yaml` |
| PinePhone Pro | `pinephonepro.yaml` |
| PineTab | `pinetab.yaml` |
| PineTab2 | `pinetab2.yaml` |
| RPi desktop | `raspberrypi-desktop.yaml` |
| RPi server | `raspberrypi-server.yaml` |

## Issues

Report issues at [github.com/rhino-linux/tracker](https://github.com/rhino-linux/tracker).
