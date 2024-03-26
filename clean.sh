#!/usr/bin/env bash

TOP="$(dirname "${BASH_SOURCE[0]}")"

. "$TOP/versions.sh"

function git_clean {
    pushd "$TOP/rtems/$1" > /dev/null
    git clean -ffdx .
    popd > /dev/null
}

git_clean $RTEMS
git_clean $SSRLAPPS
