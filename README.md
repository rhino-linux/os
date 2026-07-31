# Rhino Linux Image Builder

This repository contains the shared source layers used to build Rhino Linux ISO and device images.

Originally forked from the Vanilla OS, Ubuntu Cinnamon, and elementary OS image builders.

## Issue Tracker

Report bugs and propose features through the [Rhino Linux tracker](https://github.com/rhino-linux/tracker).

## Repository Layout

```text
build.sh                 build entry point

base/
  base/                 Files shared by every image
  environment/          Files shared by an environment

platform/
  iso-generic/          Generic amd64 and arm64 ISO files
  img-preinst/          Shared preinstalled-image files (PINE64 + RPi)
  pine64/               PinePhone and PineTab files
  rpi/                  Raspberry Pi files

build-scripts/
  overlayer.sh          assembles source layers
  live-build.sh         runs live-build

docs/                   Architecture and configuration documentation
```

Source directories are overlays. Files are copied from the broadest layer to the most specific layer, with later files replacing earlier files at the same relative path.

See [the architecture documentation](docs/architecture.md) for the complete layer order.

## Configuration

The shared image configuration is:

```text
base/base/etc/terraform.conf
```

This is the highest overlay level used by every image. Once the layers have been assembled, it appears at:

```text
<build-directory>/etc/terraform.conf
```

Platform and environment selection are inputs rather than separate configuration files. The configuration expects:

```text
terra_platform
terra_envir
```

The build entry point derives these values from its platform and environment arguments.

See [the configuration documentation](docs/configuration.md) for the supported values and derived settings.

## Build Process

The end-to-end build entry point is `build.sh`, run as root from the repository root:

```text
build.sh <platform> <environment> <build-directory>
```

It initializes the submodules, installs the build dependencies (including the vendored live-build package under `base/base/debs/`), sources the build scripts, assembles the overlays into the build directory, patches the host's live-build and debootstrap files, and starts the live-build stage.

The build scripts are sourced libraries rather than standalone executables:

1. `build-scripts/overlayer.sh` defines the `overlayer` function, which assembles the required source layers.
2. `build-scripts/live-build.sh` defines the `lb_build` and `lb_run` functions, which produce an ISO or root filesystem archive.
3. Preinstalled images use a Debos recipe to turn the root filesystem archive into a device image.

Generic ISO output is written under:

```text
builds/<architecture>/
```

Preinstalled root filesystem archives are written under:

```text
binary/
```

### Migration Status

Remaining work:

- TODO: Update CI/CD to use `build.sh`, assemble overlays, and pass the platform and environment inputs.
- TODO: Update publishing workflows to read configuration from the consolidated layout.

The existing GitHub Actions workflows still use the previous flat repository layout and should not be treated as examples for the consolidated build system.

## Supported Images

The source tree currently contains layers for:

- Generic amd64 ISO
- Generic arm64 ISO
- Raspberry Pi desktop and server images
- PinePhone and PinePhone Pro images
- PineTab and PineTab 2 images
- Unicorn and Lomiri environments where corresponding overlays exist

Full image builds require a Linux build host with root privileges and the live-build, debootstrap, QEMU, Docker, and Debos dependencies required by the selected target.
