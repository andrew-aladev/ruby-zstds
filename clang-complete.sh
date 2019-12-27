#!/bin/bash
set -e

DIR=$(dirname "${BASH_SOURCE[0]}")
cd "$DIR"

ruby_version=$(< ".ruby-version")
ruby_major_version="${ruby_version%.*}"

echo "\
-I$(pwd)/ext
-I$HOME/.rvm/rubies/$ruby_version/include/$ruby_major_version.0\
" > ".clang_complete"
