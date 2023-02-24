## Rhino Linux ISO Builder

This is the new Rhino Linux (RL) ISO builder (replaces the formerly known [RRR-builder](https://github.com/rollingrhinoremix/RRR-builder)) which creates images from scratch and gives us (even) more control over the final image. To run/build image run:

1. `sudo apt-get update && sudo apt-get install debootstrap -y`
2. `sudo dpkg -i debs/live-build_*_all.deb`
3. `sudo cp binary_grub-efi /usr/lib/live/build/binary_grub-efi`
4. `sudo chmod -R +x build.sh etc/auto/config etc/terraform.conf etc/`
5. `sudo ./build.sh etc/terraform.conf`

The resulting ISO, if successful, will be located in builds/`$ARCH`. The builder should automatically detect whether to build on ARM64 or AMD64, depending on the machine you run it on. **32-bit images are unsupported.**

This build system creates the images using `lb`/live-build with debootstrap to create images with configuration in `etc` folder.
