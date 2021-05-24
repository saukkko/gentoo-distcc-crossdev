# syntax=docker/dockerfile:1
FROM gentoo/portage:latest as portage
FROM scratch as gentoo-stage2
# If you don't have stage2 tarball available, you can use stage3 tarball.
# Alternatively you can use Gentoo official stage3 container for example:
# FROM gentoo/stage3:amd64 It will work the same but will create bigger image.

ADD stage2.tar.xz /
COPY --from=portage /var/db/repos/gentoo /var/db/repos/gentoo

FROM gentoo-stage2 as configure
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

#RUN sed -i.bak.use "s/\(^USE\=\)\"\(.*\)\"$/\1\"-filecaps bindist\"/" /etc/portage/make.conf

# Create crossdev repository
ENV CROSSDEV_CONF="/etc/portage/repos.conf/crossdev.conf"
RUN mkdir -pv /var/db/repos/localrepo-crossdev/{profiles,metadata} && \
    chown -R portage:portage /var/db/repos/localrepo-crossdev && \
    mkdir -pv /etc/portage/repos.conf && \
    \
    echo 'crossdev' > /var/db/repos/localrepo-crossdev/profiles/repo_name && \
    echo 'masters = gentoo' > /var/db/repos/localrepo-crossdev/metadata/layout.conf && \
    \
    echo "[crossdev]" > ${CROSSDEV_CONF} && \
    echo "location = /var/db/repos/localrepo-crossdev" >> ${CROSSDEV_CONF} && \
    echo "priority = 10" >> ${CROSSDEV_CONF} && \
    echo "masters = gentoo" >> ${CROSSDEV_CONF} && \
    echo "auto-sync = no" >> ${CROSSDEV_CONF}

FROM configure as optimize
####
RUN emerge -eqv @installed --jobs=2

FROM optimize as builder-1
####
RUN emerge -1q sys-devel/crossdev sys-devel/distcc

FROM builder-1 as builder-2
####
# BINUTILS: ~2.34
# GCC: ~9.3.0
# KERNEL: ~5.10
# LIBC ~2.32
ARG BINUTILS_VER="~2.34"
ARG GCC_VER="~9.3.0"
ARG KERNEL_VER="~5.10"
ARG LIBC_VER="~2.32"
ARG TARGET_CHOST="armv6j-unknown-linux-gnueabihf"

RUN crossdev --show-fail-log --b ${BINUTILS_VER} --g ${GCC_VER} --k ${KERNEL_VER} --l ${LIBC_VER} -t ${TARGET_CHOST}

FROM builder-2 as tidy-1
####
RUN echo "cleaning portage repo..." && sleep 3 && rm -fr /var/db/repos/gentoo && sleep 3

FROM scratch as tidy-2
####
COPY --from=tidy-1 / /

FROM tidy-2 as run
####

ENV PORT="3632"
ENV LOGLEVEL="warning"
ENV ALLOW="172.17.0.0/16"
ENV NICE="15"

RUN echo "#!/bin/bash" > /run.sh && \
    \
    echo "if [ -z \$PORT ]" >> /run.sh && \
    echo "then" >> /run.sh && \
    echo "  export PORT=${PORT}" >> /run.sh && \
    echo "fi" >> /run.sh && \
    \
    echo "if [ -z \$LOGLEVEL ]" >> /run.sh && \
    echo "then" >> /run.sh && \
    echo "  export LOGLEVEL=${LOGLEVEL}" >> /run.sh && \
    echo "fi" >> /run.sh && \
    \
    echo "if [ -z \$ALLOW ]" >> /run.sh && \
    echo "then" >> /run.sh && \
    echo "  export ALLOW=${ALLOW}" >> /run.sh && \
    echo "fi" >> /run.sh && \
    \
    echo "if [ -z \$NICE ]" >> /run.sh && \
    echo "then" >> /run.sh && \
    echo "  export NICE=${NICE}" >> /run.sh && \
    echo "fi" >> /run.sh && \
    \
    echo "DISTCCD_ARGS=\"--daemon --no-detach --port \$PORT --log-level \$LOGLEVEL --allow \$ALLOW -N \$NICE\"" >> /run.sh && \
    echo "echo [\$(date \"+%Y-%m-%d %H:%M:%S\")]: Starting distccd with arguments: \$DISTCCD_ARGS" >> /run.sh && \
    echo "/usr/bin/distccd \$DISTCCD_ARGS" >> /run.sh && \
    chmod a+x /run.sh


EXPOSE ${PORT}
USER distcc:distcc
#CMD [ "/bin/bash" ]
ENTRYPOINT [ "/run.sh" ]