#!/bin/bash
set -e

DIR=$(dirname "${BASH_SOURCE[0]}")
cd "$DIR"

./aarch64-unknown-linux-gnu/reset_rebuild_date.sh
./aarch64_be-unknown-linux-gnu/reset_rebuild_date.sh

./arm-unknown-linux-gnueabi/reset_rebuild_date.sh
./armeb-unknown-linux-gnueabi/reset_rebuild_date.sh

./mips-unknown-linux-gnu/reset_rebuild_date.sh
./mipsel-unknown-linux-gnu/reset_rebuild_date.sh
