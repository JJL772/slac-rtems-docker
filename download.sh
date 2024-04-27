#!/usr/bin/env bash

# Download and extract required host applications

set -e

TOP="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"
mkdir -p "${TOP}/rtems"
cd "${TOP}/rtems"

. "$TOP/versions.sh"

function error {
    echo "$1"
    exit 1
}

FORCE=0
while test $# -gt 0; do
    case $1 in
    -f|--force)
        FORCE=1
        ;;
    *)
        error "Unknown arg $1"
        ;;
    esac
done

function get_gnu {
    [ ! -z $3 ] && _EXT=$3 || _EXT="tar.gz"
    if [ ! -f "$2.$_EXT" ]; then
        wget "$1/$2.$_EXT"
    fi
    if [ ! -d "$2" ] || [ $FORCE -gt 0 ]; then
        rm -rf "$2" || true
        tar -xf "$2.$_EXT"
    fi
}

get_gnu "https://ftp.gnu.org/gnu/autoconf" "$AUTOCONF"
get_gnu "https://ftp.gnu.org/gnu/automake" "$AUTOMAKE"
get_gnu "https://ftp.gnu.org/gnu/binutils" "$BINUTILS" "tar.bz2"
get_gnu "https://ftp.gnu.org/gnu/gcc/gcc-4.8.5" "$GCC" "tar.bz2"
get_gnu "https://ftp.gnu.org/gnu/gmp" "$GMP"
get_gnu "https://ftp.gnu.org/gnu/gdb" "$GDB"
get_gnu "https://ftp.gnu.org/gnu/mpc" "$MPC"
get_gnu "https://ftp.gnu.org/gnu/mpfr" "$MPFR"
get_gnu "http://sourceware.org/pub/newlib" "$NEWLIB"
get_gnu "https://ftp.gnu.org/gnu/texinfo" "$TEXINFO"

if [ ! -d ldep ] || [ $FORCE -gt 0 ]; then
    rm -rf ldep
    git clone https://github.com/till-s/ldep
fi

if [ ! -d $RTEMS ] || [ $FORCE -gt 0 ]; then
    rm -rf $RTEMS
    git clone --recursive -b "$RTEMS_BRANCH" git@github.com:slaclab/rtems.git $RTEMS
fi

if [ ! -d $SSRLAPPS ] || [ $FORCE -gt 0 ]; then
    rm -rf $SSRLAPPS
    git clone --recursive -b "$SSRLAPPS_BRANCH" https://github.com/till-s/rtems-ssrlApps.git $SSRLAPPS
fi

echo "All packages downloaded successfully"
