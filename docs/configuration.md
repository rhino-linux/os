# Configuration

## Shared Configuration

All images use one configuration file:

```text
base/base/etc/terraform.conf
```

After overlay assembly, the file is available as:

```text
<build-directory>/etc/terraform.conf
```

There are no platform, target, or environment `terraform.conf` fragments in the current design.

## Build Inputs

The shared configuration requires two external inputs:

```text
terra_platform
terra_envir
```

`terra_platform` identifies the output platform. Canonical values are:

```text
amd64
arm64
rpi
pinephone
pinetab
```

`terra_envir` identifies the selected environment, such as:

```text
unicorn
lomiri
server
```

These inputs are supplied by the build entry point, which passes its arguments to the overlay and live-build stages. `build-scripts/live-build.sh` normalizes the platform and environment arguments and exports `terra_platform` and `terra_envir` so the assembled `terraform.conf` can read them.

`build.sh` passes the platform and environment arguments through, and the live-build stage accepts additional platform aliases and normalizes them before exporting these variables.

CI/CD should select the platform and environment and pass them to the build entry point. It should not modify or generate separate copies of `terraform.conf`.

The generic ISO workflow passes its architecture and environment matrix values to this entry point. See [Workflows](workflows.md).

## Derived Values

`terraform.conf` derives the following values from the supplied inputs:

- `ARCH`: build architecture.
- `BUILD_TYPE`: `iso` or `img`.
- `BUILD_PLATFORM`: live-build configuration family.
- `MIRROR_URL`: Ubuntu package mirror.
- `SECURITY_URL`: Ubuntu security mirror.
- `BOOTLOADERS`: bootloaders used by generic ISOs.
- `PACKAGE_LISTS_SUFFIX`: package-list selection for generic ISOs.
- `FNAME`: output filename prefix.
- `QEMU_ARCH` and `QEMU_STATIC`: cross-architecture bootstrap settings.

Generic amd64 and arm64 targets produce ISOs.

Raspberry Pi, PinePhone, and PineTab targets produce arm64 root filesystem archives for a later Debos stage.

Lomiri builds add `-lomiri` to the generated filename.

## live-build Configuration

The shared live-build configuration is:

```text
base/base/etc/auto/config
```

After assembly, live-build copies the contents of `etc/` into its temporary working directory. `auto/config` then sources the assembled `terraform.conf` and converts its values into `lb config` arguments.

Live-build source data uses its normal directory structure:

```text
etc/config/archives/
etc/config/bootloaders/
etc/config/hooks/live/
etc/config/includes.binary/
etc/config/includes.chroot/
etc/config/package-lists/
etc/config/package-lists.calamares/
```

Package selection and image customization are currently implemented through live-build package lists, hooks, and chroot includes. The repository does not currently use the former `terraform.d` or `/etc/rhino-build/` fragment layouts.

## Build Stages

### Build Entry Point

`build.sh` is the supported entry point. It must be run as root from the repository root:

```text
build.sh <platform> <environment> <build-directory>
```

It initializes submodules, installs the build dependencies (including the vendored live-build package under `base/base/debs/`), sources both build scripts, assembles the overlays, patches the host's live-build and debootstrap files, and starts live-build.

### Overlay Assembly

`build-scripts/overlayer.sh` defines the `overlayer` function. It is sourced by `build.sh`, not executed directly:

```text
source build-scripts/overlayer.sh
overlayer <platform> <environment> <build-directory>
```

It must be invoked from the repository root because its source paths are relative to the current working directory. Missing optional overlay directories are skipped.

### live-build

`build-scripts/live-build.sh` defines the `lb_build` and `lb_run` functions. It is sourced by `build.sh`, not executed directly:

```text
source build-scripts/live-build.sh
lb_build <platform> <environment> <build-directory> <terraform>
```

`lb_build` normalizes the platform and exports `terra_platform` and `terra_envir`, which the assembled `terraform.conf` reads. The `<terraform>` input is optional, and will auto-resolve to `etc/terraform.conf` if nothing is provided.

Its intended configuration path inside an assembled build directory is:

```text
etc/terraform.conf
```

### Device Image Generation

Preinstalled targets produce a root filesystem archive under:

```text
binary/
```

A device-specific Debos recipe consumes that archive and creates an image. Common image finishing steps are defined in:

```text
platform/img-preinst/base/polish.yaml
```

## Outputs

Generic ISO output:

```text
builds/<architecture>/<filename>.iso
```

Preinstalled root filesystem output:

```text
binary/<filename>.tar
```

The live-build wrapper also generates SHA-256 and SHA-512 checksum files beside its output.

Debos recipes produce `.img` files and the common polishing recipe produces a corresponding `.bmap`.

## CI/CD Status

The generic ISO workflow uses the consolidated interface and builds its architecture and environment combinations through a GitHub Actions matrix.

- TODO: Update artifact deployment to use recipes from the assembled build directory.
- TODO: Update publishing workflows to obtain version information from the shared configuration without requiring unrelated build selectors.
