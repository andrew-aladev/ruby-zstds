#!/bin/bash
set -e

DIR=$(dirname "${BASH_SOURCE[0]}")
cd "$DIR"

cd ".."

SIZE=10 # MB
TMP_DIR="tmp"

kernel_name=$(uname -s)
if [ $kernel_name = "Darwin" ]; then
  umount -f "$TMP_DIR" || true
  hdiutil detach "$TMP_DIR" || true

  sectors=$((2048 * $SIZE))
  disk_id=$(hdiutil attach -nomount "ram://${sectors}")
  diskutil erasevolume HFS+ "$TMP_DIR" "$disk_id"

else
  umount -f "$TMP_DIR" || true
  mount -t ramfs -o size=${SIZE}M,mode=777 ramfs "$TMP_DIR"
fi
