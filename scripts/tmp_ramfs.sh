#!/bin/bash
set -e

cd "$(dirname $0)"

cd ".."

SIZE=10 # MB
DIRECTORY="tmp"

kernel_name=$(uname -s)
if [ $kernel_name = "Darwin" ]; then
  umount -f "$DIRECTORY" || true
  hdiutil detach "$DIRECTORY" || true

  sectors=$((2048 * $SIZE))
  disk_id=$(hdiutil attach -nomount ram://$sectors)
  diskutil erasevolume HFS+ "$DIRECTORY" $disk_id

else
  umount -f "$DIRECTORY" || true
  mount -t ramfs -o size=${SIZE}M,mode=777 ramfs "$DIRECTORY"
fi
