#!/bin/bash

# Crossdev toolchain versions should match as closely as possible with the target.
# Crossdev understands depend atom syntaxes:
# e.g. ">=2.20" "~4.6.1" "=2.13.1-r3"
BINUTILS_VER="~2.34"    # binutils
GCC_VER="~9.3.0"        # gcc
KERNEL_VER="~5.4"       # kernel headers
LIBC_VER="~2.32"        # (g)libc

# Target CHOST must have following syntax: "<arch>-<vendor>-<os>-<libc>"
TARGET_CHOST="armv6j-unknown-linux-gnueabihf"

mkdir -pv /var/db/repos/localrepo-crossdev/{profiles,metadata}
echo 'crossdev' > /var/db/repos/localrepo-crossdev/profiles/repo_name
echo 'masters = gentoo' > /var/db/repos/localrepo-crossdev/metadata/layout.conf
chown -R portage:portage /var/db/repos/localrepo-crossdev

mkdir -pv /etc/portage/repos.conf

echo "[crossdev]
location = /var/db/repos/localrepo-crossdev
priority = 10
masters = gentoo
auto-sync = no" > /etc/portage/repos.conf/crossdev.conf

crossdev --b ${BINUTILS_VER} --g ${GCC_VER} --k ${KERNEL_VER} --l ${LIBC_VER} -t ${TARGET_CHOST}
# for example:
# crossdev --b '~2.34' --g '~9.3.0' --k '~5.4' --l '~2.32' -t armv6j-unknown-linux-gnueabihf