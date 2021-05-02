#!/usr/bin/env bash
set -e

DIR=$(dirname "${BASH_SOURCE[0]}")
cd "$DIR"

./aarch64-unknown-linux-gnu/run.sh
./aarch64_be-unknown-linux-gnu/run.sh

./aarch64-gentoo-linux-musl/run.sh
./aarch64_be-gentoo-linux-musl/run.sh
