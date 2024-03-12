# slac-rtems-toolchains

Build scripts for SLAC's RTEMS toolchains. As of right now, only GCC 4.8.5 for RTEMS 4.10.2 is here.

## Required Packages

TODO full list.

- gcc
- g++
- texinfo
- autoconf
- automake
- make

## Usage

First download the packages via `download.sh`

```sh
./download.sh
```

They will be downloaded and extracted into rtems/

Now, build.

```
./build.sh --prefix "/afs/slac/package/rtems/4.10.2"
```

