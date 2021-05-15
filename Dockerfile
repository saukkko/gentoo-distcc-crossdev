# syntax=docker/dockerfile:1
# the build is very intense and takes at least an hour to complete.
# if you want to speed things up you can comment out the two shell scripts, crossdev.sh and distcc.sh, and run them manually later.
FROM gentoo/stage3:amd64
COPY src/etc/portage/make.conf /etc/portage/make.conf
COPY src/etc/conf.d/distccd.template /etc/conf.d/distccd.template
COPY src/root/crossdev.sh /root/crossdev.sh
COPY src/root/distcc.sh /root/distcc.sh

RUN emerge-webrsync

# RUN echo "sys-kernel/linux-firmware linux-fw-redistributable no-source-code" > /etc/portage/package.license
# RUN emerge sys-kernel/linux-firmware

RUN emerge sys-kernel/installkernel-gentoo
RUN emerge sys-kernel/gentoo-kernel-bin
RUN emerge --prune sys-kernel/gentoo-kernel sys-kernel/gentoo-kernel-bin

RUN emerge sys-devel/crossdev
RUN emerge sys-devel/distcc

# comment these to dramatically speed the build process.
RUN sh /root/crossdev.sh
RUN sh /root/distcc.sh

RUN emerge --prune sys-devel/distcc sys-devel/crossdev

CMD [ "/sbin/init" ]