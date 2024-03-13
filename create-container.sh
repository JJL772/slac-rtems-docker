#!/usr/bin/env bash

function do_build {
	docker build . -t "slac-rtems:${1}" --build-arg="RTEMS_VER=${1}" --build-arg="USER=$(id -u)" --build-arg="GROUP=$(id -g)"
}

do_build 4.10.2
