# Gentoo with distccd and crossdev

## Building

The build itself should be fairly simple, for example:

`docker build --pull --rm -f "Dockerfile" -t gentoo-distcc-crossdev-armv6j:latest "."`

## Usage

Run the image and forward the distcc port from container to host as needed, for example:

`docker run -d -p 3632:3632 --name gentoo-distcc gentoo-distcc-crossdev-armv6j:latest`

## TODO

- add some tests
- list all build-time args and default values in this readme

## Known issues

- Building is very slow, since the crossdev toolchain is built along with the docker image.
- Image is still quite big, around 1.15 GB
