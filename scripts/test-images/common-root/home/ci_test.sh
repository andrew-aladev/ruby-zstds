#!/bin/bash
set -e

DIR="/mnt/data"
mkdir -p "$DIR"
cd "$DIR"

env-update
source "/etc/profile"

git clone "https://github.com/andrew-aladev/ruby-zstds.git" \
  --single-branch \
  --branch "master" \
  --depth 1 \
  "."

./scripts/ci_test.sh
