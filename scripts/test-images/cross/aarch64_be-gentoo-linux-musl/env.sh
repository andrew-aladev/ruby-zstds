#!/bin/bash
set -e

DIR=$(dirname "${BASH_SOURCE[0]}")
source "${DIR}/../../env.sh"

FROM_IMAGE="docker.io/${DOCKER_USERNAME}/test_aarch64_be-gentoo-linux-musl"
IMAGE_NAME="${IMAGE_PREFIX}_aarch64_be-gentoo-linux-musl"
IMAGE_PLATFORM="linux/arm64"
