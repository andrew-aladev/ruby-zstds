#!/bin/bash
set -e

DIR=$(dirname "${BASH_SOURCE[0]}")
cd "$DIR"

./x86_64-unknown-linux-gnu/run.sh
./i686-unknown-linux-gnu/run.sh

./x86_64-gentoo-linux-musl/run.sh
./i686-gentoo-linux-musl/run.sh
