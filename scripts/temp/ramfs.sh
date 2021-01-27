#!/bin/bash
set -e

DIR=$(dirname "${BASH_SOURCE[0]}")
cd "$DIR"

TMP_PATH=$1
TMP_SIZE=$2 # MB

umount -f "$TMP_PATH" || true

kernel_name=$(uname -s)

if [ $kernel_name = "Darwin" ]; then
  hdiutil detach "$TMP_PATH" || true

  sectors=$((2048 * $TMP_SIZE))
  disk_id=$(hdiutil attach -nomount "ram://${sectors}")
  diskutil erasevolume HFS+ "$TMP_PATH" "$disk_id"
else
  mount -t ramfs -o size=${TMP_SIZE}M,mode=777 ramfs "$TMP_PATH"
fi

# Keeping temp directory after mount.
touch "$TMP_PATH/.gitkeep"
