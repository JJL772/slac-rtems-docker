#!/usr/bin/env bash
set -e

TOP="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"
cd "$TOP/rtems"

. "$TOP/versions.sh"

function error {
    echo "$1"
    exit 1
}

# Adjust to your heart's desire, but this is all that SLAC uses (as of March '24)
PPC_BSPS='beatnik mvme3100'
M68K_BSPS='uC5282'
ARCHES='m68k powerpc i386'

ONLY="autoconf automake binutils gcc gdb gmp ldep mpc mpfr texinfo rtems ssrlApps"
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
    --arches|-a)
        ARCHES=$2
        shift 2
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
    pushd $AUTOCONF > /dev/null
    ./configure --prefix="$PREFIX/host/$HARCH"
    make && make install

    # Symlink exact version of autoconf
    cd "$PREFIX/host/$HARCH/bin"
    rm -fv $AUTOCONF
    ln -s autoconf $AUTOCONF
    
    popd > /dev/null
fi

if [[ "$ONLY" =~ 'automake' ]]; then
    pushd $AUTOMAKE > /dev/null
    ./configure --prefix="$PREFIX/host/$HARCH"
    make $JOBS && make install

    # Yet another symlink
    cd "$PREFIX/host/$HARCH/bin"
    rm -fv automake-1.11.1
    ln -s automake automake-1.11.1
    
    popd > /dev/null
fi

# Required for GDB. Can also be installed on the host via package manager.
if [[ "$ONLY" =~ 'texinfo' ]]; then
    pushd $TEXINFO > /dev/null
    ./configure --prefix="$PREFIX/host/$HARCH"
    make $JOBS && make install
    popd > /dev/null
fi

if [[ "$ONLY" =~ 'ldep' ]]; then
    pushd ldep
    ./bootstrap --prefix="$PREFIX/host/$HARCH"
    make $JOBS && make install
    popd
fi

if [[ "$ONLY" =~ 'binutils' ]]; then
    pushd $BINUTILS

    if [[ "$ARCHES" =~ 'powerpc' ]]; then
        mkdir -p build-powerpc-rtems && pushd build-powerpc-rtems
        ../../../configs/config-cross.ssrl -t powerpc-rtems -p "$PREFIX" -h $HARCH -o --enable-werror=no
        make $JOBS
        make install
        popd
    fi

    if [[ "$ARCHES" =~ 'm68k' ]]; then
        mkdir -p build-m68k-rtems && pushd build-m68k-rtems
        ../../../configs/config-cross.ssrl -t m68k-rtems -p "$PREFIX" -h $HARCH -o --enable-werror=no
        make $JOBS
        make install
        popd
    fi

    if [[ "$ARCHES" =~ 'i386' ]]; then
        mkdir -p build-i386-rtems && pushd build-i386-rtems
        ../../../configs/config-cross.ssrl -t i386-rtems -p "$PREFIX" -h $HARCH -o --enable-werror=no
           make $JOBS
        make install
        popd
    fi
    
    popd
fi

if [[ "$ONLY" =~ 'gcc' ]]; then
    pushd $GCC > /dev/null

    # Newer GCC defaults to C++14 or higher. We need gnu++11 specifically, else GCC will not build.
    export CXXFLAGS=-std=gnu++11

    # Apply patches
    if [ ! -f .gcc-patch-marker ] || [ ! -z $FORCEPATCH ]; then
        pushd .. > /dev/null
        for p in $TOP/patches/tools/gcc*.diff; do
            echo "Applying `basename $p`"
            if ! patch -p0 -N --posix --verbose < "$p"; then
                [ $PIPESTATUS -gt 1 ] && exit 1
            fi
        done
        echo "Done applying patches"
        popd > /dev/null
        touch .gcc-patch-marker
    fi

    # Apply patches to newlib
    pushd $TOP/rtems/$NEWLIB > /dev/null
    if [ ! -f .newlib-patch-marker ] || [ ! -z $FORCEPATCH ]; then
        # HACK: For some reason I'm getting 'too many open files' when applying newlib patches :(
        # Doesn't happenin GHA because the default limit is 64k in there
        _OLDLIMIT=`ulimit -n`
        if [ $_OLDLIMIT -lt 8192 ]; then
            ulimit -n 8192
        fi
        
        for p in $TOP/patches/tools/newlib*.diff; do
            echo "Applying `basename $p`"
            if ! patch -p1 -N --verbose < "$p"; then
                [ $PIPESTATUS -gt 1 ] && exit 1
            fi
        done
        echo "Applied all patches to $NEWLIB"
        touch .newlib-patch-marker
        
        if [ $_OLDLIMIT -lt 8192 ]; then
            ulimit -n $_OLDLIMIT
        fi
    fi
    popd > /dev/null

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

    # Specify a package version to identify our GCC build
    COMMON_GCC_ARGS="-o --with-pkgversion=SLAC-RTEMS-$GCC-$(date "+%Y.%m.%d")"

    if [[ "$ARCHES" =~ 'powerpc' ]]; then
        mkdir -p build-powerpc-rtems && pushd build-powerpc-rtems
        ../../../configs/config-gcc.ssrl -t powerpc-rtems -p "$PREFIX" -h $HARCH -o --enable-werror=no "$COMMON_GCC_ARGS"
        make $JOBS
        make install
        popd > /dev/null
    fi

    if [[ "$ARCHES" =~ 'm68k' ]]; then
        mkdir -p build-m68k-rtems && pushd build-m68k-rtems
        ../../../configs/config-gcc.ssrl -t m68k-rtems -p "$PREFIX" -h $HARCH -o --enable-werror=no "$COMMON_GCC_ARGS"
        make $JOBS
        make install
        popd > /dev/null
    fi

    if [[ "$ARCHES" =~ 'i386' ]]; then
        mkdir -p build-i386-rtems && pushd build-i386-rtems > /dev/null
        ../../../configs/config-gcc.ssrl -t i386-rtems -p "$PREFIX" -h $HARCH -o --enable-werror=no
        make $JOBS
        make install
        popd > /dev/null
    fi

    popd > /dev/null

    export CXXFLAGS=
fi

if [[ "$ONLY" =~ 'gdb' ]]; then
    pushd $GDB > /dev/null

    # HORRIBLE: -fcommon is bad, but required for this version of GDB. -fno-common became default in modern versions of GCC (such as your host machine's compiler)
    #  This just forces all symbols into the same data/bss section, which apparently avoids multiply-defined symbols, even if you define `int cool;` in 10 different translation units.
    export CFLAGS="-fcommon"
    export CXXFLAGS="-fcommon -fpermissive"

    if [[ "$ARCHES" =~ 'powerpc' ]]; then
        mkdir -p build-powerpc-rtems && pushd build-powerpc-rtems
        ../../../configs/config-cross.ssrl -t powerpc-rtems  -p "$PREFIX" -h $HARCH -o --enable-werror=no -o --with-python=no
        make $JOBS
        make install
        popd > /dev/null
    fi

    if [[ "$ARCHES" =~ 'm68k' ]]; then
        mkdir -p build-m68k-rtems && pushd build-m68k-rtems
        ../../../configs/config-cross.ssrl -t m68k-rtems  -p "$PREFIX" -h $HARCH -o --enable-werror=no -o --with-python=no
        make $JOBS
        make install
        popd > /dev/null
    fi

    if [[ "$ARCHES" =~ 'i386' ]]; then
        mkdir -p build-i386-rtems && pushd build-i386-rtems
        ../../../configs/config-cross.ssrl -t i386-rtems  -p "$PREFIX" -h $HARCH -o --enable-werror=no -o --with-python=no
        make $JOBS
        make install
        popd > /dev/null
    fi

    export CFLAGS=
    export CXXFLAGS=

    popd > /dev/null
fi

if [[ "$ONLY" =~ 'rtems' ]]; then
    echo "Building RTEMS"
    pushd $RTEMS > /dev/null

    ./bootstrap

    if [[ "$ARCHES" =~ 'powerpc' ]]; then
        mkdir -p build-powerpc && pushd build-powerpc > /dev/null
        echo "-- config-rtems.ssrl"
        ../../../configs/config-rtems.ssrl -t powerpc-rtems -p "$PREFIX" -v $RTEMS -b "$PPC_BSPS"
        echo "-- make && make install"
        make #$JOBS
        make install
        popd > /dev/null
    fi

    if [[ "$ARCHES" =~ 'm68k' ]]; then
        mkdir -p build-m68k && pushd build-m68k > /dev/null
        echo "-- config-rtems.ssrl"
        ../../../configs/config-rtems.ssrl -s .. -t m68k-rtems -p "$PREFIX" -v $RTEMS -b "$M68K_BSPS"
        echo "-- make && make install"
        make #$JOBS
        make install
        popd > /dev/null
    fi

    popd > /dev/null
fi

if [[ "$ONLY" =~ 'ssrlApps' ]]; then
    echo "Building ssrlApps"
    pushd $SSRLAPPS > /dev/null

    ./bootstrap

    if [[ "$ARCHES" =~ 'powerpc' ]]; then
        mkdir -p build-powerpc && pushd build-powerpc > /dev/null
        ../configure --prefix="$PREFIX" --enable-rtemsbsp="$PPC_BSPS" --with-rtems-top="$PREFIX/target/$RTEMS" --with-package-subdir="target/$RTEMS/$SSRLAPPS"
        make #$JOBS
        make install
        popd > /dev/null
    fi

    if [[ "$ARCHES" =~ 'm68k' ]]; then
        mkdir -p build-m68k && pushd build-m68k > /dev/null
        ../configure --prefix="$PREFIX" --enable-rtemsbsp="$M68K_BSPS" --with-rtems-top="$PREFIX/target/$RTEMS" --with-package-subdir="target/$RTEMS/$SSRLAPPS"
        make $JOBS
        make install
        popd > /dev/null
    fi

    # layout should be target/rtems_p3   target/ssrlApps
    ln -s "$PREFIX/target/$RTEMS/$SSRLAPPS" "$PREFIX/target/ssrlApps"

    popd > /dev/null
fi
