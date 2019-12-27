#!/bin/bash
set -e

DIR=$(dirname "${BASH_SOURCE[0]}")
cd "$DIR"

env-update
source "/etc/profile"

git clone "https://github.com/andrew-aladev/ruby-zstds.git" --single-branch --branch "master" --depth 1 "ruby-zstds"
cd "ruby-zstds"

./scripts/ci_test.sh
