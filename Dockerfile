
FROM ghcr.io/jjl772/centos7-vault:latest

RUN ulimit -n 1024 && yum install -y wget

ARG RTEMS_VER=4.10.2
RUN wget https://github.com/JJL772/slac-rtems-docker/releases/download/base/rtems-${RTEMS_VER}.tar.gz && tar -xf rtems-${RTEMS_VER}.tar.gz && rm rtems-${RTEMS_VER}.tar.gz

ENV PATH="/sdf/sw/epics/package/rtems/${RTEMS_VER}/host/amd64_linux26/bin:$PATH"
