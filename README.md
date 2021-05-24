# Gentoo with distccd and crossdev

## Building

When building with docker it's recommended to leave `FEATURES` as is, because portage complains about "unable to unshare" otherwise.

### Build arguments, default values and syntax

ARG list for make.conf:

- `MARCH="-march=skylake"`
- `FEATURES="-ipc-sandbox -network-sandbox -pid-sandbox"`
- `MAKEOPTS="-j4"`
- `USE="-filecaps bindist"`

ARG list for building the crossdev toolchain:

- `BINUTILS_VER="=2.35.2"`
- `GCC_VER="~10.2.0"`
- `KERNEL_VER="~5.10"`
- `LIBC_VER="~2.32"`
- `TARGET_CHOST="armv6j-unknown-linux-gnueabihf"`

### Build example

```
docker build --pull -t gentoo-cross-distcc:armv6j \
--build-arg MARCH="-march=x86-64" \
--build-arg MAKEOPTS="-j16" .
```

## Usage

### Runtime ENV variables

- `PORT="3632"`
- `LOGLEVEL="warning"`
- `ALLOW="172.17.0.0/16"`
- `NICE="15"`

Run the image and forward the distcc port from container to host as needed, for example:

```
docker run -d -p 3632:3632 --name distccd-armv6j \
-e LOGLEVEL="debug" \
-e ALLOW="10.100.1.0/24" \
gentoo-cross-distcc:armv6j`
```

## TODO

- finish this readme
- tidy up the Dockerfile

## Known issues

- only one ALLOW is currently supported.
- Dockerfile exposes only the default port 3632. If using other than default port, you need to take this into account when running the container.
- Building is very slow, since the crossdev toolchain is built along with the docker image.
- Image is still quite big, around 1.15 GB
