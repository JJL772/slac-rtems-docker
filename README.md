# slac-rtems-toolchains

Containers and build scripts for SLAC's RTEMS 4.10.2 toolchains. RTEMS 4.9.4 is partially supported.

## Building Container

This repository provides two different containers: centos7 and rocky9.

The rocky 9 container is a complete build environment for the toolchains and takes quite a while to build.
Currently there is also a problem with the resulting toolchain that needs to get fixed.

The centos7 container simply adds a tarball at /sdf/sw/epics/package for the RTEMS toolchain.

Both containers configure the path so that e.g. powerpc-rtems-gcc will point to the expected version of GCC.

## Building Locally

### Required Packages

TODO full list.

- gcc
- g++
- texinfo
- autoconf
- automake
- make

### Usage

First download the packages via `download.sh`

```sh
./download.sh
```

They will be downloaded and extracted into rtems/

Now, build.

```
./build.sh --prefix "/afs/slac/package/rtems/4.10.2"
```

