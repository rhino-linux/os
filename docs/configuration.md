# Configuration

## Image configuration

`base/etc/terraform.conf` contains global defaults and loads shell fragments
from `etc/terraform.d/` in lexical order:

```text
10-platform.conf
20-target.conf
30-environment.conf
```

Fragments should set inputs such as `ARCH`, `IMAGE_NAME`, `IMAGE_SUFFIX`, and
`MIRROR_PROFILE`. Global code derives mirrors, bootloaders, `VERSION`, and
`FNAME` after loading them.

`TERRAFORM_CONFIG_DIRS` may contain a space-separated list of fragment
directories when inspecting unassembled source layers.

## Chroot configuration

Shared hooks in `base/etc/config/hooks/live/` call the package helper installed
at `/usr/local/lib/rhino-build/install-packages`.

Chroot settings are split by purpose:

```text
/etc/rhino-build/profile.d/*.conf
/etc/rhino-build/packages/apt.d/*
/etc/rhino-build/packages/pacstall.d/*
/usr/local/lib/rhino-build/customize/*
```

Profiles select the image user and customization script. Package files contain
one package per line; blank lines and comments are ignored. Customization
scripts are for actions that cannot be represented as package data.

Use the same scope prefixes as Terraform: `00-common`, `10-platform`,
`20-target`, and `30-environment`.
