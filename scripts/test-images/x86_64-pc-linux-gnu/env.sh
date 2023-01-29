#!/usr/bin/env bash
set -e

DIR=$(dirname "${BASH_SOURCE[0]}")
source "${DIR}/../env.sh"

TARGET="x86_64-pc-linux-gnu"
IMAGE_NAME="${IMAGE_PREFIX}_${TARGET}"
