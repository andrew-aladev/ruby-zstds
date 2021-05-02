#!/usr/bin/env bash
set -e

DIR=$(dirname "${BASH_SOURCE[0]}")
cd "$DIR"

TMP_PATH=$1
TMP_SIZE=$2

mkdir -p "$TMP_PATH"
TMP_FULL_PATH=$(cd "$TMP_PATH" && pwd -P)

if mount | grep "$TMP_FULL_PATH" > /dev/null 2>&1; then
  echo "tmp is already mounted"
  exit 0
fi

echo "need to mount tmp"

# "sudo" may be required for ramfs.
if command -v "sudo" > /dev/null 2>&1; then
  sudo_prefix="sudo"
else
  sudo_prefix=""
fi

$sudo_prefix ./ramfs.sh "$TMP_PATH" "$TMP_SIZE" || true
