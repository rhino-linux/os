# Workflows

GitHub Actions automation lives in `.github/workflows/`. This page describes what
each workflow does, how to run it, and where to find its output.

## Build ISOs

The workflow in `.github/workflows/build-iso.yaml` builds the generic Rhino Linux
ISOs. It is manually triggered, so pushing a commit does not start a build.

### Starting a Build

Open the repository's **Actions** page, choose **Build ISOs**, and select
**Run workflow**. Choose the branch you want to build before starting the run.

The same thing can be done with the GitHub CLI:

```bash
gh workflow run build-iso.yaml --ref <branch>
```

One run covers every supported desktop and architecture combination. The matrix
expands into these four jobs:

| Architecture | Desktop | Runner |
| --- | --- | --- |
| `amd64` | `unicorn` | `ubuntu-latest` |
| `amd64` | `lomiri` | `ubuntu-latest` |
| `arm64` | `unicorn` | `ubuntu-24.04-arm` |
| `arm64` | `lomiri` | `ubuntu-24.04-arm` |

GitHub starts the jobs independently when runners are available. Because
`fail-fast` is disabled, a failure in one job does not cancel the other three.

### What a Job Does

Each job checks out the repository and its submodules, refreshes APT's package
lists, and calls the main build script with values from the matrix:

```bash
sudo ./build.sh \
  "<architecture>" \
  "<environment>" \
  "build_<architecture>_<environment>"
```

`build.sh` passes those values to `build-scripts/overlayer.sh`. For a generic ISO,
the overlayer assembles the shared files and the selected desktop in this order:

```text
base/base/
base/environment/<environment>/
platform/iso-generic/base/
platform/iso-generic/environment/<environment>/
```

The assembled `terraform.conf` selects an ISO build for `amd64` or `arm64`, and
the live-build wrapper places the result here:

```text
build_<architecture>_<environment>/builds/<architecture>/
```

See [Architecture](architecture.md) for the full overlay order and
[Configuration](configuration.md) for the values derived by `terraform.conf`.

### Runners and Permissions

The workflow only requests read access to repository contents. The build command
uses `sudo` because it installs packages and temporarily patches live-build and
debootstrap files on the runner.

### Artifacts

Every successful job uploads its ISO with a name in this form:

```text
rhino-linux-<architecture>-<environment>
```

Uploads use `actions/upload-artifact@v7`. A missing ISO fails the job, and
compression is disabled because compressing an ISO again usually adds time
without saving meaningful space.

To find a run and download its artifacts with the GitHub CLI:

```bash
gh run list --workflow build-iso.yaml
gh run download <run-id>
```

### Changing the Matrix

Architectures and desktops are defined as separate matrix axes in
`.github/workflows/build-iso.yaml`. Runner mappings live under `matrix.include`.
Artifact names and build directories include both matrix values, which keeps the
four jobs from writing to the same place.

Before adding a value, make sure `overlayer.sh`, `terraform.conf`, and the matching
overlay directories all support it. When another workflow is added to the
repository, document it as a new section on this page.