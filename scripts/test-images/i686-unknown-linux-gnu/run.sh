#!/usr/bin/env bash
set -e

DIR=$(dirname "${BASH_SOURCE[0]}")
cd "$DIR"

source "../../../test-images/utils.sh"
source "./env.sh"

CONTAINER_OPTIONS="--volume $(pwd)/../../..:/mnt/data" \
  run_image "/mnt/data/scripts/test-images/ci_test.sh"
