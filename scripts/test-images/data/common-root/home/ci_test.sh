#!/bin/bash
set -e

env-update
source "/etc/profile"

DIR="/mnt/data"
mkdir -p "$DIR"
cd "$DIR"

git clone "https://github.com/andrew-aladev/ruby-zstds.git" \
  --single-branch \
  --branch "master" \
  --depth 1 \
  "."

./scripts/ci_test.sh
