#!/usr/bin/env bash
set -e

DIR=$(dirname "${BASH_SOURCE[0]}")
cd "$DIR"

TMP_PATH="$(pwd)/../tmp"
TMP_SIZE="16"

./temp/mount.sh "$TMP_PATH" "$TMP_SIZE"

cd ".."
ROOT_DIR=$(pwd)

# We need to send coverage for extension.
curl -s "https://codecov.io/bash" > "codecov.sh"
chmod +x "codecov.sh"

/usr/bin/env bash -cl "\
  cd \"$ROOT_DIR\" && \
  gem install bundler --force && \
  bundle install && \
  bundle exec rake clean && \
  bundle exec rake && \
  ./codecov.sh \
"
