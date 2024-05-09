FROM rockylinux:9

RUN dnf install -y make gcc gcc-c++ automake m4 autoconf git wget bzip2 which unzip file diffutils \
	binutils patch gzip perl cpio rsync bc findutils python zlib-devel

ARG USER=0
ARG GROUP=0
COPY --chown=$USER:$GROUP . /build/

# Using the same location as SDF here.
ARG RTEMS_VER=4.10.2
RUN mkdir -p /sdf/sw/epics/package/rtems/${RTEMS_VER}

RUN cd /build && ./download.sh

ARG RTEMS_VER=4.10.2
RUN cd /build && ./build.sh --prefix /sdf/sw/epics/package/rtems/${RTEMS_VER} --arches "powerpc m68k" --type toolchain && rm -rf /build

