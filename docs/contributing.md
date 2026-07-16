# Contributing

## Add a target

1. Create `platforms/<family>/<target>/`.
2. Add hardware files at their assembled relative paths.
3. Add `etc/terraform.d/20-target.conf` when target values differ.
4. Add target-only packages in a `20-target` package file.
5. Move anything shared by the family into its `base/` layer.

## Add an environment

1. Create `platforms/<family>/<target>/<environment>/`.
2. Add `etc/terraform.d/30-environment.conf` when needed.
3. Select customization through `profile.d/30-environment.conf`.
4. Put environment-only packages in `30-environment` package files.
5. Reuse an existing customization script unless behavior actually differs.

## Check changes

- Ensure the target resolves `ARCH`, `IMAGE_NAME`, `NAME`, and
  `MIRROR_PROFILE`.
- Run the appropriate shell syntax checks.
- Confirm new scripts are executable.
- Run `git diff --check`.

Full image validation requires a composed tree on a Linux build host.
