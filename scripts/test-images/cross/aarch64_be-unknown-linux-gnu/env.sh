#!/bin/bash
set -e

DIR=$(dirname "${BASH_SOURCE[0]}")
source "${DIR}/../../env.sh"

FROM_IMAGE_NAME="test_aarch64_be-unknown-linux-gnu"
IMAGE_NAME="${IMAGE_PREFIX}_aarch64_be-unknown-linux-gnu"
