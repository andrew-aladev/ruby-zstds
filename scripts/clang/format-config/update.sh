#!/bin/bash
set -e

DIR=$(dirname "${BASH_SOURCE[0]}")
cd "$DIR"

SOURCE="config-source.yml"
UPDATES="config-updates.yml"
DESTINATION="../../../.clang-format"

echo "# This file has been auto generated, please don't edit directly." \
  > "$DESTINATION"

SOURCE_STYLE=$(yq -cs ".[0]" < "$SOURCE")

clang-format -style="$SOURCE_STYLE" --dump-config | \
  yq -sy ".[0] * .[1]" - "$UPDATES" >> "$DESTINATION"
