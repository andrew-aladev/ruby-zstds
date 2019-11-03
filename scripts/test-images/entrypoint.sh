#!/bin/bash
set -e

cd "$(dirname $0)"

env-update
source /etc/profile

git clone "https://github.com/andrew-aladev/ruby-zstds.git" --single-branch --branch "master" --depth 1 "ruby-zstds"
cd "ruby-zstds"

./scripts/ci_test.sh
