## The ISO Builder

This is the new RRR ISO builder (replaces [RRR-builder](https://github.com/rollingrhinoremix/RRR-builder)) which creates images from scratch and gives us (even) more control over the final image. To run/build image run:
`./build.sh etc/terraform.conf`

This build system creates the images using `lb`/live-build with debootstrap to create images with configuration in `etc` folder.
