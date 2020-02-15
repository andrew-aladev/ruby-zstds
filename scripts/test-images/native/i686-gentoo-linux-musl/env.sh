#!/bin/bash
set -e

DIR=$(dirname "${BASH_SOURCE[0]}")
source "${DIR}/../../env.sh"

FROM_IMAGE_NAME="test_i686-gentoo-linux-musl"
IMAGE_NAME="${IMAGE_PREFIX}_i686-gentoo-linux-musl"

REBUILD_DATE=$(< "${DIR}/.rebuild_date") || :
