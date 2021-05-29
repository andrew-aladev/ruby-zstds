#!/usr/bin/env bash
set -e

DIR=$(dirname "${BASH_SOURCE[0]}")
cd "$DIR"

source "../utils.sh"
source "./env.sh"

CONTAINER_OPTIONS="--volume $(pwd)/../../..:/mnt/data" \
  run_image "/home/ci_test.sh"
