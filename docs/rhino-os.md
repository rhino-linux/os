# rhino-os.sh

`rhino-os.sh` is the entry point for building, deploying, and downloading Rhino
Linux images. Run it from the repository root.

The scripts under `build-scripts/` only define the functions used by this entry
point and should not be run directly.

## Build

```text
sudo ./rhino-os.sh build <platform> <environment> <build-directory>
```

The build command assembles the source overlays and runs live-build. Supported
platform and environment combinations are:

| Platform | Environment |
| --- | --- |
| `amd64`, `arm64` | `unicorn`, `lomiri` |
| `pinephone`, `pinetab` | `unicorn`, `lomiri` |
| `rpi` | `unicorn`, `server` |

PinePhone Pro and PineTab 2 aliases use the corresponding PinePhone or PineTab
root filesystem.

## Deploy

```text
sudo ./rhino-os.sh deploy <platform> <environment> <build-directory>
```

The deploy command turns a preinstalled root filesystem into a device image
with Debos. The build directory must contain the matching rootfs tarball under
`binary/`.

Supported targets are `rpi`, `pinephone`, `pinephonepro`, `pinetab`, and
`pinetab2`. PINE64 targets support `unicorn` and `lomiri`; Raspberry Pi supports
`unicorn` and `server`.

## Pull

```text
./rhino-os.sh pull <repository> <branch> <output-directory> [image...]
```

The pull command downloads images from the latest successful GitHub Actions run
for the selected branch. It requires an authenticated GitHub CLI. If no images
are listed, all images are downloaded.

```bash
./rhino-os.sh pull rhino-linux/os main "$PWD" pinephone rpi-desktop
```

Use `./rhino-os.sh <command> --help` to view the accepted aliases and image
selectors for a command.
