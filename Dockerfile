# syntax=docker/dockerfile:1
# Portage is updated roughly once a day, which means latest has a different
# checksum roughly once a day, meaning we need to start build from the start
# roughly once a day.
# Use `gentoo/portage:timestamp` while developing and switch to latest aftter.

# FROM gentoo/portage:latest as portage
FROM gentoo/portage:20211217 as portage
FROM gentoo/stage3:amd64 as gentoo-stage3
# FROM scratch as gentoo-stage2
#
# If you don't have stage2 tarball available, you can use stage3 tarball.
# Alternatively you can use Gentoo official stage3 container for example:
# FROM gentoo/stage3:amd64 It will work the same but will create bigger image.
#
# ADD stage2.tar.xz /
COPY --from=portage /var/db/repos/gentoo /var/db/repos/gentoo

FROM gentoo-stage3 as configure
####
# Modify make.conf
ARG MARCH="-march=skylake"
ARG FEATURES="-ipc-sandbox -network-sandbox -pid-sandbox"
ARG MAKEOPTS="-j4"
ARG USE="-filecaps bindist"
RUN sed -i.bak "s/\(^COMMON_FLAGS\=\)\"\(.*\)\"$/\1\"${MARCH} \2\"/" /etc/portage/make.conf && \
    echo "FEATURES=\"${FEATURES}\"" >> /etc/portage/make.conf && \
    echo "MAKEOPTS=\"${MAKEOPTS}\"" >> /etc/portage/make.conf && \
    echo "USE=\"${USE}\"" >> /etc/portage/make.conf

# ADD make.conf /etc/portage/make.conf
# RUN sed -i.bak.use "s/\(^USE\=\)\"\(.*\)\"$/\1\"-filecaps bindist\"/" /etc/portage/make.conf
RUN mkdir -pv /etc/portage/{repos.conf,package.mask,package.accept_keywords}


# Create crossdev repository
RUN mkdir -pv /var/db/repos/localrepo-crossdev/{profiles,metadata} && \
    chown -R portage:portage /var/db/repos/localrepo-crossdev && \
    \
    echo 'crossdev' > /var/db/repos/localrepo-crossdev/profiles/repo_name && \
    echo 'masters = gentoo' > /var/db/repos/localrepo-crossdev/metadata/layout.conf
ADD ./include/crossdev.conf /etc/portage/repos.conf/crossdev.conf

FROM configure as optimize
####
# this fails if using stage3 image
#RUN emerge -eqv @installed --jobs=2

# workaround for libxcrypt-migration issues and conflicts
# https://bugs.gentoo.org/699422
# https://bugs.gentoo.org/802210

RUN echo "<virtual/libcrypt-2" >> /etc/portage/package.mask/libcrypt
RUN emerge -1qvDNU virtual/libcrypt sys-libs/libxcrypt --ignore-built-slot-operator-deps=y --jobs=2
RUN emerge -1qv sys-devel/gcc sys-devel/binutils sys-libs/glibc sys-kernel/linux-headers --jobs=2 --exclude dev-libs/libxml2
RUN emerge -1uvq dev-libs/libxml2

RUN gcc-config x86_64-pc-linux-gnu-11.2.0
FROM optimize as builder-1
####
RUN emerge -1q sys-devel/crossdev sys-devel/distcc

FROM builder-1 as builder-2
####
# latest stable package atoms as of 2021-12-16 are:
# sys-devel/gcc-11.2.0
# sys-devel/binutils-2.37_p1
# sys-libs/glibc-2.33-r7
# sys-kernel/linux-headers-5.10-r1
ARG BINUTILS_VER="2.37_p1"
ARG GCC_VER="~11.2.0"
ARG KERNEL_VER="5.10-r1"
ARG LIBC_VER="2.33-r7"
ARG TARGET_CHOST="armv6j-unknown-linux-gnueabihf"



# uncomment and edit to your needs to unmask packages. if, for some reason we need old or unstable toolchains. good luck.
# RUN for atom in \
#     "~sys-devel/binutils-${BINUTILS_VER}" \
#     "~sys-devel/gcc-${GCC_VER}" \
#     "~sys-libs/glibc-${LIBC_VER}" \
#     "~sys-kernel/linux-headers-${KERNEL_VER}" \
#     \
#     "cross-${TARGET_CHOST}/binutils-${BINUTILS_VER}" \
#     "cross-${TARGET_CHOST}/gcc-${GCC_VER}" \
#     "cross-${TARGET_CHOST}/glibc-${LIBC_VER}" \
#     "cross-${TARGET_CHOST}/linux-headers-${KERNEL_VER}" \
#     do \
#         echo $atom >> /etc/portage/package.unmask; \
#     done && sleep 1
# if you need more than one versions of toolchain just type them manually below
FROM builder-2 as crossdev-1
RUN crossdev --show-fail-log --b ${BINUTILS_VER} --g ${GCC_VER} --k ${KERNEL_VER} --l ${LIBC_VER} -t ${TARGET_CHOST}

FROM crossdev-1 as crossdev-last
# RUN crossdev --show-fail-log --b '2.35.2' -t armv6j-unknown-linux-gnueabihf

FROM crossdev-last as tidy-1
####
RUN emerge -1qv app-portage/gentoolkit

RUN eclean --deep distfiles && eclean --deep packages
RUN rm -fr /var/db/repos/gentoo
RUN du -shc $(portageq envvar DISTDIR PKGDIR)

FROM scratch as tidy-2
####
COPY --from=tidy-1 / /

FROM tidy-2 as run
####

ENV PORT="3632"
ENV STATS_PORT="3633"
ENV LOGLEVEL="warning"
ENV ALLOW="172.17.0.0/16"
ENV NICE="15"

# TODO:
ADD ./include/run.sh /
RUN chmod 755 /run.sh

EXPOSE ${PORT}
EXPOSE ${STATS_PORT}

RUN touch /run/distccd.pid && chown distcc:distcc /run/distccd.pid
USER distcc:distcc
ENTRYPOINT /run.sh --port=$PORT --log-level=$LOGLEVEL --allow=$ALLOW --nice=$NICE
