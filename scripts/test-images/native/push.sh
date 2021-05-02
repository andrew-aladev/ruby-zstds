#!/usr/bin/env bash
set -e

DIR=$(dirname "${BASH_SOURCE[0]}")
cd "$DIR"

./x86_64-unknown-linux-gnu/push.sh
./i686-unknown-linux-gnu/push.sh

./x86_64-gentoo-linux-musl/push.sh
./i686-gentoo-linux-musl/push.sh
