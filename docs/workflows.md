# Workflows

GitHub Actions automation lives in `.github/workflows/`. Image builds are split
by product family so a run stays focused and its artifacts are easy to find.

| Workflow | File | Output |
| --- | --- | --- |
| Build ISOs | `.github/workflows/build-iso.yaml` | Generic amd64 and arm64 ISOs |
| Build PINE64 Images | `.github/workflows/build-pine64.yaml` | Phone and tablet images |
| Build Raspberry Pi Images | `.github/workflows/build-rpi.yaml` | Desktop and server images |

All three workflows use `workflow_dispatch`. Pushing a commit does not start an
image build. To run one, open the repository's **Actions** page, select the
workflow, choose **Run workflow**, and pick the branch to build.

## Generic ISOs

One **Build ISOs** run expands into four independent jobs:

| Architecture | Desktop | Runner |
| --- | --- | --- |
| `amd64` | `unicorn` | `ubuntu-latest` |
| `amd64` | `lomiri` | `ubuntu-latest` |
| `arm64` | `unicorn` | `ubuntu-24.04-arm` |
| `arm64` | `lomiri` | `ubuntu-24.04-arm` |

Each job calls `build.sh` with its matrix values and uploads the resulting ISO.
There is no separate deploy stage because live-build produces the final ISO
directly.

```bash
sudo ./build.sh \
  "<architecture>" \
  "<environment>" \
  "build_<architecture>_<environment>"
```

The final artifacts are named
`rhino-linux-<architecture>-<environment>`. Matrix jobs use unique build
directories and artifact names, so they do not share state.

## Device Images

PINE64 and Raspberry Pi builds have two stages because their final images need
two different hosts:

1. An ARM64 runner uses `build.sh` and live-build to create a root filesystem
   tarball.
2. The tarball is uploaded as an intermediate workflow artifact.
3. An amd64 runner downloads it into the original build directory's `binary/`
   folder.
4. `deploy.sh` reconstructs the rest of that build directory and runs Debos to
   create the partitioned device image.

Only `binary/` crosses between jobs.

GitHub documents [workflow artifacts](https://docs.github.com/en/actions/using-workflows/storing-workflow-data-as-artifacts)
as a way to pass data between jobs, while [dependency caches](https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/caching-dependencies-to-speed-up-workflows)
reuse dependencies across jobs or runs. The tarball is a required output of one
job and an input to another, so an artifact fits this handoff. Documenting as changing to using artifacts from builder v2 onwards.

### deploy.sh

`deploy.sh` begins the second stage:

```text
deploy.sh <platform> <environment> <build-directory>
```

It must run as root from the repository root. The build directory must already
contain exactly one rootfs tarball under `binary/`.

Supported calls are:

| Platform | Environment | Images produced |
| --- | --- | --- |
| `pinephone` | `unicorn`, `lomiri` | PinePhone and PinePhone Pro |
| `pinetab` | `unicorn`, `lomiri` | PineTab and PineTab 2 |
| `rpi` | `unicorn` | Raspberry Pi desktop |
| `rpi` | `server` | Raspberry Pi server |

The script uses `overlayer.sh` to rebuild the missing files around `binary/`,
then sources the assembled `terraform.conf` for version information. A platform
case selects the recipes associated with that family. For example, `pinephone`
runs both the PinePhone and PinePhone Pro recipes.

Each Debos recipe removes the tarball after unpacking it. `deploy.sh` creates a
temporary hard link before running Debos and restores the expected name between
recipes. A hard link avoids copying the large tarball. The exit trap restores
the original path and removes the temporary link even when deployment fails.

Raw images and their `.bmap` files are placed under:

```text
<build-directory>/builds/<platform>/
```

The raw `.img` is compressed with `xz`; workflows upload the resulting `.img.xz`
and `.bmap` files as the final artifacts.

## PINE64

The **Build PINE64 Images** workflow uses this matrix:

| Family | Desktop |
| --- | --- |
| `pinephone` | `unicorn` |
| `pinephone` | `lomiri` |
| `pinetab` | `unicorn` |
| `pinetab` | `lomiri` |

Each family/desktop combination gets its own rootfs. The matching deploy job
turns that rootfs into both models in the family, so one PinePhone deploy creates
PinePhone and PinePhone Pro images, while one PineTab deploy creates PineTab and
PineTab 2 images.

Final artifacts are named `rhino-linux-<family>-<environment>`.

## Raspberry Pi

The **Build Raspberry Pi Images** workflow builds two variants:

| Environment | Image |
| --- | --- |
| `unicorn` | Raspberry Pi desktop |
| `server` | Raspberry Pi server |

Each variant has its own rootfs and deploy job. Final artifacts are named
`rhino-linux-rpi-<environment>`.

## Failure Behavior

Matrices use `fail-fast: false`, so one failed combination does not cancel the
others. Device deploy jobs use `if: !cancelled()` after the build matrix. This
lets deploy jobs for successful rootfs artifacts continue even if another matrix
combination failed; the deploy corresponding to a missing rootfs fails at its
download step.