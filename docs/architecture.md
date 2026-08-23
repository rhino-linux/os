# Architecture

Rhino Linux images are assembled from source overlays. Each layer preserves the path that the file will have in the assembled build directory.

For example:

```text
base/base/etc/config/hooks/live/example.chroot
```

is assembled as:

```text
<build-directory>/etc/config/hooks/live/example.chroot
```

## Source Layout

```text
base/
  base/
  environment/<environment>/

platform/
  iso-generic/
    base/
    environment/<environment>/

  img-preinst/
    base/
    environment/<environment>/

  pine64/
    base/
    environment/<environment>/
    phone/
      base/
      environment/<environment>/
    tab/
      base/
      environment/<environment>/

  rpi/
    base/
    environment/<environment>/
```

## Overlay Precedence

`build-scripts/overlayer.sh` applies layers from shared to specific. If multiple layers contain the same relative path, the later layer replaces the earlier one.

### Generic ISO

For `amd64` and `arm64`:

```text
base/base/
base/environment/<environment>/
platform/iso-generic/base/
platform/iso-generic/environment/<environment>/
```

### PINE64

#### PinePhone

```text
base/base/
base/environment/<environment>/
platform/img-preinst/base/
platform/img-preinst/environment/<environment>/
platform/pine64/base/
platform/pine64/environment/<environment>/
platform/pine64/phone/base/
platform/pine64/phone/environment/<environment>/
```

#### PineTab

```text
base/base/
base/environment/<environment>/
platform/img-preinst/base/
platform/img-preinst/environment/<environment>/
platform/pine64/base/
platform/pine64/environment/<environment>/
platform/pine64/tab/base/
platform/pine64/tab/environment/<environment>/
```

### Raspberry Pi

#### Server

The server build does not include an environment layer:

```text
base/base/
platform/img-preinst/base/
platform/rpi/base/
```

#### Desktop

```text
base/base/
base/environment/<environment>/
platform/img-preinst/base/
platform/img-preinst/environment/<environment>/
platform/rpi/base/
platform/rpi/environment/<environment>/
```

## File Placement

Keep each file at the highest layer where it is valid:

- Use `base/base/` for files shared by every image.
- Use `base/environment/` for files shared by every image using a specific environment.
- Use `platform/<platform>/base/` for files shared by every image using a specific platform. (Note: `img-preinst/` is a higher level than `pine64/` and `rpi/`)
- Use `platform/<platform>/environment/` for files using a specific environment on a specific platform.
- Use `platform/pine64/phone/base/` or `platform/pine64/tab/base/` for files shared by every image on a specific PINE64 target family.
- Use target environment directories for files using a specific environment on a specific target family.

Do not duplicate a shared file in several more-specific layers.

**Do not flatten paths within a layer. Every source file must retain its path relative to the assembled build directory.**

## Image Types

Generic targets produce bootable ISO images through live-build.

Raspberry Pi and Pine64 targets first produce a root filesystem tarball through live-build. Debos recipes then partition and customize device images from that tarball.

Shared preinstalled-image resources, including the Debos wrapper and common polishing recipe, live under:

```text
platform/img-preinst/base/
```

Device recipes live in the narrowest applicable target or environment layer.

## Build-Host Files

The generic ISOLINUX directory contains absolute symlinks provided by Linux packages. They may appear broken on hosts without Syslinux but are expected to resolve on the build host.

The generic GRUB theme is a Git submodule at:

```text
platform/iso-generic/base/etc/config/includes.binary/grub
```

Initialize submodules before building an ISO; `rhino-os.sh build` does this automatically. These are not used by the preinstalled images.

The build command also patches the build host before running live-build. It copies the assembled `binary_grub-efi` and, for PINE64 targets, `binary_rootfs` over the live-build scripts in `/usr/lib/live/build/`, symlinks the `gutsy` debootstrap script as `devel`, and applies `0002-remove-WRONGSUITE-error.patch` to debootstrap's `functions`. The replaced files are backed up inside the build directory and restored when the build exits.

`base/base/rebuild-list` is historical metadata and is not required by the current build scripts.
