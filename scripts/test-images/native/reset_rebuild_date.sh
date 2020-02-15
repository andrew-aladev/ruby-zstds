#!/bin/bash
set -e

DIR=$(dirname "${BASH_SOURCE[0]}")
cd "$DIR"

./x86_64-pc-linux-gnu/reset_rebuild_date.sh
./i686-pc-linux-gnu/reset_rebuild_date.sh

./x86_64-gentoo-linux-musl/reset_rebuild_date.sh
./i686-gentoo-linux-musl/reset_rebuild_date.sh
