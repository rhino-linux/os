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

  rpi/
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

### Raspberry Pi Server

The server build does not include an environment layer:

```text
base/base/
platform/img-preinst/base/
platform/rpi/base/
```

### Raspberry Pi Desktop

```text
base/base/
base/environment/<environment>/
platform/img-preinst/base/
platform/img-preinst/environment/<environment>/
platform/rpi/base/
platform/rpi/environment/<environment>/
```

### PinePhone

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

### PineTab

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

## File Placement

Keep each file at the highest layer where it is valid:

- Use `base/base/` for files shared by every image.
- Use `base/environment/` for environment files shared by multiple platforms.
- Use a platform `base/` for files shared by that platform family.
- Use a platform `environment/` for environment-specific platform files.
- Use `phone/base/` or `tab/base/` for target-family files.
- Use target environment directories for files specific to both a target family and an environment.

Do not duplicate a shared file in several more-specific layers.

**Do not flatten paths within a layer. Every source file must retain its path relative to the assembled build directory.**

## Image Types

Generic targets produce bootable ISO images through live-build.

Raspberry Pi and Pine64 targets first produce an ext4 root filesystem archive through live-build. Debos recipes then partition and customize device images from that archive.

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

Initialize submodules before building an ISO.

`base/base/rebuild-list` is historical metadata and is not required by the current build scripts.
