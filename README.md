# Gentoo with distccd and crossdev

It is recommended to build this image directly on the helper box. You should also configure the files according to your personal needs and environment.

## Building

The build itself should be fairly simple, for example:

`docker build --pull --rm -f "Dockerfile" -t gentoo-distcc-crossdev-armv6j:latest "."`

## Usage

Run the image and forward the distcc port from container to host as needed, for example:

`docker run -d -p 3632:3632 --name gentoo-distcc gentoo-distcc-crossdev-armv6j:latest`

## TODO

- put all the emerge scripts into one shell script
- add some tests
- make the shell scripts to be actual scripts instead of just commands after another...

## Known issues

- Image and cross-toolchain is unoptimized, but all the binaries should run nicely on any x86-64 processor. Change the contents of `src/etc/portage/make.conf` if you must optimize it.
- Building is very slow, since the crossdev toolchain is built along with the docker image.
- Fully built and uncompressed image size is fairly big (around 2,5 GB). It could be made couple gigabytes smaller since we dont need everything that stage3 offers and this is not intended to be a fully featured VM.
