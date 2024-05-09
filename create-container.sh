#!/usr/bin/env bash

function do_build {
	CNAME="slac-rtems"
	DF="Dockerfile.rtems"
	if [[ "${2}" = "toolchain" ]]; then
		CNAME="slac-rtems-toolchain"
		DF="Dockerfile"
	fi
	docker build . -f "$DF" -t "${CNAME}:${1}" --build-arg="RTEMS_VER=${1}" --build-arg="USER=$(id -u)" --build-arg="GROUP=$(id -g)" --build-arg="TYPE=${2}"
}

if [ -z $1 ]; then
	echo "USAGE: $0 toolchain|rtems"
	echo "  Either build container for toolchain or rtems"
	exit 1
fi

do_build 4.10.2 "${1}"
