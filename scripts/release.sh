#!/usr/bin/env bash
set -e

DIR=$(dirname "${BASH_SOURCE[0]}")
cd "$DIR"

cd ".."

# Packing binaries.

rake gem

# Packing source.

VERSION=$(grep "VERSION" "lib/zstds/version.rb" | sed "s/.*VERSION\s*=\s*['\"]\([0-9.]*\).*/\1/g")
NAME="ruby-zstds-${VERSION}"

COMPRESSION_LEVEL="-9"
TAR_COMMANDS=(
  "gzip $COMPRESSION_LEVEL"
  "zip $COMPRESSION_LEVEL"
)
TAR_EXTENSIONS=(
  "tar.gz"
  "zip"
)
CURRENT_BRANCH="$(git branch --show-current)"

for index in ${!TAR_COMMANDS[@]}; do
  git archive --format="tar" "$CURRENT_BRANCH" | \
    ${TAR_COMMANDS[$index]} > "build/${NAME}.${TAR_EXTENSIONS[$index]}"
done

git archive --format="zip" "$CURRENT_BRANCH" $COMPRESSION_LEVEL -o "build/${NAME}.zip"
