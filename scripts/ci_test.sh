#!/bin/bash
set -e

DIR=$(dirname "${BASH_SOURCE[0]}")
cd "$DIR"

TMP_PATH="$(pwd)/../tmp"
TMP_SIZE="16"

./temp/mount.sh "$TMP_PATH" "$TMP_SIZE"

cd ".."

bash -cl "\
  gem install bundler && \
  bundle install && \
  bundle exec rake clean && \
  bundle exec rake \
"
