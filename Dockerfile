FROM rockylinux:9

RUN sudo dnf install -y gcc gcc-c++ libtirpc-devel make automake autoconf

RUN build.sh