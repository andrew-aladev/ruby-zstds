#!/usr/bin/env bash
set -e

DIR=$(dirname "${BASH_SOURCE[0]}")
cd "$DIR"

./x86_64-pc-linux-gnu/run.sh
./i386-pc-linux-gnu/run.sh

./x86_64-alpine-linux-musl/run.sh
./i386-alpine-linux-musl/run.sh
