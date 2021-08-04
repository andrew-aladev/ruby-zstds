#!/usr/bin/env bash
set -e

DIR=$(dirname "${BASH_SOURCE[0]}")
source "${DIR}/../env.sh"

TARGET="i686-unknown-linux-gnu"
FROM_IMAGE="${DOCKER_HOST}/${DOCKER_USERNAME}/test_${TARGET}"

IMAGE_BUILD_ARGS="FROM_IMAGE"
IMAGE_NAME="${IMAGE_PREFIX}_${TARGET}"
IMAGE_PLATFORM="linux/amd64"
IMAGE_LAYERS="false"
