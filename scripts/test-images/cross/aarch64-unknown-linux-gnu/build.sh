#!/bin/bash
set -e

DIR=$(dirname "${BASH_SOURCE[0]}")
cd "$DIR"

source "../../utils.sh"
source "./env.sh"

fusermount -zu attached-common-root || true
bindfs -r -o nonempty "../../common-root" attached-common-root
build "FROM_IMAGE" || error=$?
fusermount -zu attached-common-root || true

if [ ! -z "$error" ]; then
  exit "$error"
fi
