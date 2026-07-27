# Rhino Linux Image Builder

This repository contains the shared source layers used to build Rhino Linux ISO and device images.

Originally forked from the Vanilla OS, Ubuntu Cinnamon, and elementary OS image builders.

## Issue Tracker

Report bugs and propose features through the [Rhino Linux tracker](https://github.com/rhino-linux/tracker).

## Repository Layout

```text
base/
  base/                 Files shared by every image
  environment/          Files shared by an environment

platform/
  iso-generic/          Generic amd64 and arm64 ISO files
  img-preinst/          Shared preinstalled-image files (PINE64 + RPi)
  pine64/               PinePhone and PineTab files
  rpi/                  Raspberry Pi files

build-scripts/
  overlayer.sh          Assembles source layers
  live-build.sh         Runs live-build

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

`build-scripts/live-build.sh` derives these values from its platform and environment arguments.

See [the configuration documentation](docs/configuration.md) for the supported values and derived settings.

## Build Process

The implemented build process has three stages:

1. `build-scripts/overlayer.sh` assembles the required source layers.
2. `build-scripts/live-build.sh` produces an ISO or root filesystem archive.
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

The consolidated build system is not yet complete.

- TODO: Add an end-to-end build entry point that assembles the overlays and invokes the correct build stages.
- TODO: Fix `live-build.sh` so its platform argument is not also interpreted as the configuration path.
- TODO: Update CI/CD to use `build-scripts/`, assemble overlays, and pass the platform and environment inputs.
- TODO: Update publishing workflows to read configuration from the consolidated layout.
- TODO: Make missing optional overlay directories safe to skip.

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
