#!/usr/bin/env bash
set -e

DIR=$(dirname "${BASH_SOURCE[0]}")
cd "$DIR"

source "../../utils.sh"
source "./env.sh"

SOURCE_PATH=$(realpath "../../../..")
VOLUME_OPTIONS="--volume ${SOURCE_PATH}:/mnt/data"

CONTAINER_OPTIONS="$VOLUME_OPTIONS" run_image "/home/ci_test.sh"
