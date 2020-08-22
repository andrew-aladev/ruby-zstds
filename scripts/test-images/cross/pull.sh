#!/bin/bash
set -e

DIR=$(dirname "${BASH_SOURCE[0]}")
cd "$DIR"

./aarch64-unknown-linux-gnu/pull.sh
./aarch64_be-unknown-linux-gnu/pull.sh
./aarch64-gentoo-linux-musl/pull.sh
./aarch64_be-gentoo-linux-musl/pull.sh
