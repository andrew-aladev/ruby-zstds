#!/bin/bash
set -e

DIR=$(dirname "${BASH_SOURCE[0]}")
cd "$DIR"

cd ".."

# Packing binaries.

rake gem

# Packing source.

NAME="ruby-zstds"

COMPRESSION_LEVEL="-9"
TAR_COMMANDS=(
  "bzip2 $COMPRESSION_LEVEL"
  "gzip $COMPRESSION_LEVEL"
  "xz $COMPRESSION_LEVEL"
  "zip $COMPRESSION_LEVEL"
)
TAR_EXTENSIONS=(
  "tar.bz2"
  "tar.gz"
  "tar.xz"
  "zip"
)
CURRENT_BRANCH="$(git branch --show-current)"

for index in ${!TAR_COMMANDS[@]}; do
  git archive --format="tar" "$CURRENT_BRANCH" | \
    ${TAR_COMMANDS[$index]} > "build/${NAME}.${TAR_EXTENSIONS[$index]}"
done

git archive --format="zip" "$CURRENT_BRANCH" $COMPRESSION_LEVEL -o "build/${NAME}.zip"
