#!/bin/bash
set -e

DIR=$(dirname "${BASH_SOURCE[0]}")
cd "$DIR"

./aarch64-unknown-linux-gnu/pull.sh
./aarch64_be-unknown-linux-gnu/pull.sh

./arm-unknown-linux-gnueabi/pull.sh
./armeb-unknown-linux-gnueabi/pull.sh

./mips-unknown-linux-gnu/pull.sh
./mipsel-unknown-linux-gnu/pull.sh
