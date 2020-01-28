#!/bin/bash
set -e

DIR=$(dirname "${BASH_SOURCE[0]}")
cd "$DIR"

./x86_64-pc-linux-gnu/run.sh
./i686-pc-linux-gnu/run.sh

./x86_64-gentoo-linux-musl/run.sh
./i686-gentoo-linux-musl/run.sh
