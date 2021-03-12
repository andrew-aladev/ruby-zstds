#!/bin/bash
set -e

DIR=$(dirname "${BASH_SOURCE[0]}")
cd "$DIR"

BASE_DIR="../.."
RUBY_VERSION=$(< "${BASE_DIR}/.ruby-version")
RUBY_MAJOR_VERSION="${RUBY_VERSION%.*}"
DESTINATION="${BASE_DIR}/.clang_complete"

echo "\
-I$(pwd)/${BASE_DIR}/ext
-I${HOME}/.rvm/rubies/${RUBY_VERSION}/include/${RUBY_MAJOR_VERSION}.0\
" > "$DESTINATION"
