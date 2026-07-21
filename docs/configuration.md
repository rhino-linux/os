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

The build wrapper accepts additional platform aliases and normalizes them before exporting these variables.

CI/CD should select the platform and environment and pass them to the build entry point. It should not modify or generate separate copies of `terraform.conf`.

The existing workflows have not yet been migrated to this model.

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

### Overlay Assembly

The overlay script accepts:

```text
build-scripts/overlayer.sh <platform> <environment> <build-directory>
```

It must be run from the repository root because its source paths are relative to the current working directory.

### live-build

The live-build wrapper accepts a platform and environment, normalizes them, and exports `terra_platform` and `terra_envir`.

Its intended configuration path inside an assembled build directory is:

```text
etc/terraform.conf
```

The wrapper currently has a bug that assigns its first argument to both the platform and configuration path.

- TODO: Make `etc/terraform.conf` the fixed default configuration path.
- TODO: Add a distinct optional configuration-path argument only if one is required.
- TODO: Connect overlay assembly and live-build through one supported command.

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

The checked-in workflows still expect the previous flat layout, including root-level `build.sh`, `etc/`, `debs/`, and image recipes.

- TODO: Assemble the selected overlays in CI.
- TODO: Pass platform and environment selections to the consolidated build wrapper.
- TODO: Replace old `build.sh` invocations.
- TODO: Update artifact deployment to use recipes from the assembled build directory.
- TODO: Update publishing workflows to obtain version information from the shared configuration without requiring unrelated build selectors.
