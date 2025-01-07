
FROM ghcr.io/jjl772/centos7-vault:latest

ARG RTEMS_VER=4.10.2
ADD tarballs/rtems-${RTEMS_VER}.tar.gz /

ENV PATH="/sdf/sw/epics/package/rtems/${RTEMS_VER}/host/amd64_linux26/bin:$PATH"
