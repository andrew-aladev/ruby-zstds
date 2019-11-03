#!/bin/bash
set -e

cd "$(dirname $0)"

./amd64-pc-linux-gnu/build.sh
./i686-pc-linux-gnu/build.sh
