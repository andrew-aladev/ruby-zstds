#!/bin/bash
set -e

DIR=$(dirname "${BASH_SOURCE[0]}")
source "${DIR}/../../env.sh"

FROM_IMAGE_NAME="test_mipsel-unknown-linux-gnu"
IMAGE_NAME="${IMAGE_PREFIX}_mipsel-unknown-linux-gnu"

REBUILD_DATE=$(< "${DIR}/.rebuild_date") || :
