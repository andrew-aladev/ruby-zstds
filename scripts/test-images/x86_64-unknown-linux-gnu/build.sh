#!/usr/bin/env bash
set -e

DIR=$(dirname "${BASH_SOURCE[0]}")
cd "$DIR"

source "../utils.sh"
source "./env.sh"

build_with_portage --volume "$(pwd)/../common-root:/mnt/common-root"
