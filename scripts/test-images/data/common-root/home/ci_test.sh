#!/bin/bash
set -e

env-update
source "/etc/profile"

DIR="/mnt/data"
RUBY_VERSIONS=(
  "ruby25"
  "ruby26"
  "ruby27"
  "ruby30"
)

if [ ! -d "$DIR" ]; then
  mkdir -p "$DIR"

  git clone "https://github.com/andrew-aladev/ruby-zstds.git" \
    --single-branch \
    --branch "master" \
    --depth 1 \
    "$DIR"
fi

cd "$DIR"

for RUBY_VERSION in "${RUBY_VERSIONS[@]}"; do
  eselect ruby set "$RUBY_VERSION"

  ./scripts/ci_test.sh
done
