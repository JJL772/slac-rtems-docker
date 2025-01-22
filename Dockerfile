
FROM rockylinux:9

RUN ulimit -n 1024 && yum install -y wget

ARG RTEMS_VER=4.10.2
RUN cd / && wget https://github.com/JJL772/slac-rtems-docker/releases/download/base/rtems-${RTEMS_VER}.tar.gz && mkdir -p /sdf/sw/epics/package/rtems && cd /sdf/sw/epics/package/rtems && \
	tar -xf /rtems-${RTEMS_VER}.tar.gz && rm /rtems-${RTEMS_VER}.tar.gz

ENV PATH="/sdf/sw/epics/package/rtems/${RTEMS_VER}/host/amd64_linux26/bin:$PATH"
