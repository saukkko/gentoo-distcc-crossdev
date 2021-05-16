# syntax=docker/dockerfile:1
FROM gentoo/stage3:amd64

# Copy the config files
COPY src/etc/portage/make.conf /etc/portage/make.conf
COPY src/etc/conf.d/distccd.conf /etc/conf.d/distccd.conf
COPY src/root/crossdev.sh /root/crossdev.sh
COPY src/root/distcc.sh /root/distcc.sh

# Get recent version of portage snapshot
RUN emerge-webrsync

# Compile and install the kernel.
RUN emerge sys-kernel/installkernel-gentoo
RUN emerge sys-kernel/gentoo-kernel-bin

# Build the tools we need
RUN emerge sys-devel/crossdev sys-devel/distcc app-portage/gentoolkit

# Run the scripts inside to container that we copied earlier.
RUN sh /root/crossdev.sh
RUN sh /root/distcc.sh

# Try to clean packages and distfiles nicely
RUN eclean-dist --deep
RUN eclean-pkg --deep
RUN emerge --depclean --with-bdeps=y

# Dramatic measure to reduce around 1GB of unpacked image size, handle with care and use only if you know what you are removing and how to fix it.
#RUN rm -fr /var/cache/distfiles/*
#RUN rm -fr /var/db/repos/gentoo/

EXPOSE 3632
# Just run the init to start everything that is needed.
CMD [ "/sbin/init" ]