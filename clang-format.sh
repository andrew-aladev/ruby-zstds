#!/bin/sh
set -e

cd "$(dirname $0)"

find "ext" \( -name "*.h" -o -name "*.c" \) -exec clang-format -i {} \;
