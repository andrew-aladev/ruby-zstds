#!/bin/bash
set -e

DIR=$(dirname "${BASH_SOURCE[0]}")
cd "$DIR"

SIZE=$1

mkdir -p "../tmp"
tmp_path=$(cd "../tmp" && pwd -P)

if mount | grep "$tmp_path" > /dev/null 2>&1; then
  echo "tmp is already mounted"
  exit 0
fi

echo "need to mount tmp"

# "sudo" may be required for ramfs.
if command -v sudo > /dev/null 2>&1; then
  sudo ./tmp_ramfs.sh $SIZE || true
else
  ./tmp_ramfs.sh $SIZE || true
fi
