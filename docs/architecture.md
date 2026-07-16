# Architecture

Build inputs are overlays, applied from shared to specific:

```text
base/
platforms/<family>/base/
platforms/<family>/<target>/
platforms/<family>/<target>/<environment>/
```

Later layers add files or replace the same relative path from an earlier layer.
Generic builds use `amd64` or `arm64` as the target. Raspberry Pi does not require a hardware sub-target.

Keep a file at the highest layer where it is valid:

- `base/` for all images
- family `base/` for all targets in that family
- target directories for hardware or architecture differences
- environment directories for Unicorn or Lomiri differences

Do not flatten paths inside a layer. A file intended for the assembled
`etc/config/` directory must retain that path in its source layer.

## Build-host files

The generic ISOLINUX directory contains absolute symlinks supplied by Linux
packages. They appear broken on macOS or hosts without Syslinux, but resolve on
the build host.

The generic GRUB theme is a submodule. `rebuild-list` is unused historical
metadata and is not required for builds.
