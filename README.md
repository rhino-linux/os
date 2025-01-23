### Issues Tracker

To report issues or propose new features for this repository, visit [our tracker](https://github.com/rhino-linux/tracker).

## Rhino Linux ISO Builder
---
Originally forked from [Vanilla-OS's ISO builder](https://github.com/Vanilla-OS/live-iso), which forked from [Cinnamon's ISO builder](https://github.com/ubuntucinnamon/iso-builder-devel), which forked from [Elementary's ISO builder](https://github.com/elementary/os) :) 

---

This is the new Rhino Linux (RL) ISO builder (replaces the formerly known [RRR-builder](https://github.com/rollingrhinoremix/RRR-builder)) which creates images from scratch and gives us (even) more control over the final image. To set up the builder:

- `sudo apt-get update && sudo apt-get install --reinstall debootstrap -y`
- `sudo mv /usr/share/debootstrap/functions functions`
- `sudo patch -i 0002-remove-WRONGSUITE-error.patch`
- `sudo mv functions /usr/share/debootstrap/functions`
- `sudo ln -sfn /usr/share/debootstrap/scripts/gutsy /usr/share/debootstrap/scripts/lunar`
- `sudo dpkg -i debs/live-build_*_all.deb`
- `sudo cp binary_grub-efi /usr/lib/live/build/binary_grub-efi`
- `sudo chmod -R +x build.sh etc/auto/config etc/terraform.conf etc/`

Then, to build: 

`sudo ./build.sh etc/terraform.conf`

The resulting ISO, if successful, will be located in builds/`$ARCH`. The builder should automatically detect whether to build on ARM64 or AMD64, depending on the machine you run it on. **32-bit images are unsupported.**

This build system creates the images using `lb`/live-build with debootstrap to create images with configuration in `etc` folder.
