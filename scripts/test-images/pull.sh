#!/bin/bash
set -e

cd "$(dirname $0)"

./amd64-pc-linux-gnu/pull.sh
./i686-pc-linux-gnu/pull.sh
