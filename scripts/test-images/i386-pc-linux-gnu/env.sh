#!/usr/bin/env bash
set -e

DIR=$(dirname "${BASH_SOURCE[0]}")
source "${DIR}/../env.sh"

TARGET="i386-pc-linux-gnu"
IMAGE_NAME="${IMAGE_PREFIX}_${TARGET}"
