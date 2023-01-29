#!/usr/bin/env bash
set -e

DIR="/mnt/data"

if [ ! -d "$DIR" ]; then
  mkdir -p "$DIR"

  git clone "https://github.com/andrew-aladev/ruby-zstds.git" \
    --single-branch \
    --branch "master" \
    --depth 1 \
    "$DIR"
fi

cd "$DIR"
./scripts/ci_test.sh
