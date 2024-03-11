#!/usr/bin/env bash
set -e

TOP="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"
cd "$TOP/rtems"

############################
# Package versions
MPFR=mpfr-3.0.1
MPC=mpc-1.0.3
GCC=gcc-4.8.5
AUTOMAKE=automake-1.11
AUTOCONF=autoconf-2.68
BINUTILS=binutils-2.21.1
NEWLIB=newlib-1.18.0
GMP=gmp-4.3.2
############################

function error {
    echo "$1"
    exit 1
}

ONLY="autoconf automake binutils gcc gdb gmp ldep mpc mpfr"
JOBS=-j$(nproc)
while test $# -gt 0; do
    case $1 in
    --prefix|-p)
        PREFIX="$2"
        shift 2
        ;;
    --only|-o)
        ONLY="$2"
        shift 2
        ;;
    -f|--force-patch)
        FORCEPATCH=1
        shift
        ;;
    -j*)
        JOBS=$1
        shift
        ;;
    --jobs)
        JOBS=-j$2
        shift
        ;;
    *)
        error "Unknown arg"
        ;;
    esac
done

if [ -z "$PREFIX" ]; then
    error "No prefix path specified. Please run with --prefix <pfx> or -p <pfx>"
fi
mkdir -p "$PREFIX"

export HARCH="linux-$(uname -m)"
export PATH="$PREFIX/host/$HARCH/bin:$PATH"

if [[ "$ONLY" =~ 'autoconf' ]]; then
    pushd $AUTOCONF
    ./configure --prefix="$PREFIX/host/$HARCH"
    make && make install
    popd
fi

if [[ "$ONLY" =~ 'automake' ]]; then
    pushd $AUTOMAKE
    ./configure --prefix="$PREFIX/host/$HARCH"
    make $JOBS && make install
    popd
fi

if [[ "$ONLY" =~ 'ldep' ]]; then
    pushd ldep
    ./bootstrap --prefix="$PREFIX/host/$HARCH"
    make $JOBS && make install
    popd
fi

if [[ "$ONLY" =~ 'binutils' ]]; then
    pushd $BINUTILS

    mkdir -p build-powerpc-rtems && pushd build-powerpc-rtems
    ../../../configs/config-cross.ssrl -t powerpc-rtems -p "$PREFIX" -h $HARCH -o --enable-werror=no
    make $JOBS && make install
    popd

    mkdir -p build-m68k-rtems && pushd build-m68k-rtems
    ../../../configs/config-cross.ssrl -t m68k-rtems -p "$PREFIX" -h $HARCH -o --enable-werror=no
    make $JOBS && make install
    popd

    mkdir -p build-i386-rtems && pushd build-i386-rtems
    ../../../configs/config-cross.ssrl -t i386-rtems -p "$PREFIX" -h $HARCH -o --enable-werror=no
    make $JOBS && make install
    popd
    
    popd
fi

if [[ "$ONLY" =~ 'gcc' ]]; then
    pushd $GCC > /dev/null

    # Newer GCC defaults to C++14 or higher.
    export CXXFLAGS=-std=gnu++11

    # Apply patches
    if [ ! -f .gcc-patch-marker ] || [ ! -z $FORCEPATCH ]; then
        pushd .. > /dev/null
        for p in $TOP/patches/tools/gcc*.diff; do
            echo "Applying `basename $p`"
            patch -p0 --posix --verbose < "$p"
        done
        echo "Done applying patches"
        popd > /dev/null
        touch .gcc-patch-marker
    fi

    # Setup symlinks to our MPC, MPFR and newlib. GCC will build these for us
    if [ ! -d mpc ]; then
        ln -s ../$MPC mpc
    fi
    if [ ! -d gmp ]; then
        ln -s ../$GMP gmp
    fi
    if [ ! -d mpfr ]; then
        ln -s ../$MPFR mpfr
    fi
    if [ ! -d newlib ]; then
        ln -s ../$NEWLIB/newlib newlib
    fi

    mkdir -p build-powerpc-rtems && pushd build-powerpc-rtems
    ../../../configs/config-gcc.ssrl -t powerpc-rtems -p "$PREFIX" -h $HARCH -o --enable-werror=no
    make $JOBS && make install
    popd > /dev/null

    mkdir -p build-m68k-rtems && pushd build-m68k-rtems
    ../../../configs/config-gcc.ssrl -t m68k-rtems -p "$PREFIX" -h $HARCH -o --enable-werror=no
    make $JOBS && make install
    popd > /dev/null

    mkdir -p build-i386-rtems && pushd build-i386-rtems > /dev/null
    ../../../configs/config-gcc.ssrl -t i386-rtems -p "$PREFIX" -h $HARCH -o --enable-werror=no
    make $JOBS && make install
    popd > /dev/null

    popd > /dev/null

    export CXXFLAGS=
fi
