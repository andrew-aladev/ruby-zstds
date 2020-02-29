#!/bin/bash
set -e

DIR=$(dirname "${BASH_SOURCE[0]}")
cd "$DIR"

./aarch64-unknown-linux-gnu/run.sh
./aarch64_be-unknown-linux-gnu/run.sh

./arm-unknown-linux-gnueabi/run.sh
./armeb-unknown-linux-gnueabi/run.sh
