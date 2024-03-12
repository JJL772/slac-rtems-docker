#!/usr/bin/env bash

# Download and extract required host applications

set -e

TOP="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"
mkdir -p "${TOP}/rtems"
cd "${TOP}/rtems"

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

get_gnu "https://ftp.gnu.org/gnu/autoconf" "autoconf-2.68"
get_gnu "https://ftp.gnu.org/gnu/automake" "automake-1.11"
get_gnu "https://ftp.gnu.org/gnu/binutils" "binutils-2.21.1" "tar.bz2"
get_gnu "https://ftp.gnu.org/gnu/gcc/gcc-4.8.5" "gcc-4.8.5" "tar.bz2"
get_gnu "https://ftp.gnu.org/gnu/gmp" "gmp-4.3.2"
get_gnu "https://ftp.gnu.org/gnu/gdb" "gdb-8.0"
get_gnu "https://ftp.gnu.org/gnu/mpc" "mpc-1.0.3"
get_gnu "https://ftp.gnu.org/gnu/mpfr" "mpfr-3.0.1"
get_gnu "http://sourceware.org/pub/newlib" "newlib-1.18.0"
get_gnu "https://ftp.gnu.org/gnu/texinfo" "texinfo-5.0"

if [ ! -d ldep ] || [ $FORCE -gt 0 ]; then
    rm -rf ldep
    git clone git@github.com:till-s/ldep
fi

echo "All packages downloaded successfully"
