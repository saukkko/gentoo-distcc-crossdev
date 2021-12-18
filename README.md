# Gentoo with distccd and crossdev

## Building

When building with docker it's recommended to leave `FEATURES` as is, because portage complains about "unable to unshare" otherwise.

### Build arguments, default values and syntax

Default ARGs for make.conf:

- `MARCH="-march=skylake"`
- `FEATURES="-ipc-sandbox -network-sandbox -pid-sandbox"`
- `MAKEOPTS="-j4"`
- `USE="-filecaps bindist"`

Default ARGs for crossdev:

- `BINUTILS_VER="2.37_p1"`
- `GCC_VER="~11.2.0"`
- `KERNEL_VER="5.10-r1"`
- `LIBC_VER="2.33-r7"`
- `TARGET_CHOST="armv6j-unknown-linux-gnueabihf"`

### Build example

Override arguments by passing `--build-arg VAR=val` to `docker build` command.

```
docker build --pull -t gentoo-cross-distcc:armv6j \
--build-arg MARCH="-march=x86-64" \
--build-arg MAKEOPTS="-j16" .
```

## Running

Default environment variables are:

- `PORT="3632"`
- `STATS_PORT="3633"`
- `LOGLEVEL="warning"`
- `ALLOW="172.17.0.0/16"`
- `NICE="15"`

Substitute defaults by passing `--env VAR=val` or `-e VAR=val` to `docker run`. If you change the default ports, don't forget to expose them with `--expose`.

For example:

```
docker run -d -p 1234:1234 --name distccd-armv6j \
--expose 1234 --env PORT="1234" --env ALLOW="10.100.1.0/24" \
gentoo-cross-distcc:armv6j
```

The above command starts the container as detached `-d`, publishes port 1234 from host to container `-p host:cont`, sets its name to distccd-armv6j `--name name`, exposes port 1234 from the container to the host `--expose port`, sets environment values PORT and ALLOW `--env var=val` from image named `gentoo-cross-distcc:armv6j`.

## Known issues

- Building is slow and the image is quite big, around 1.8 GB

## TODO

- Nothing major.
