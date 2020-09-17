#!/bin/bash
set -e

DIR=$(dirname "${BASH_SOURCE[0]}")
cd "$DIR"

TMP_PATH="$(pwd)/../tmp"
TMP_SIZE="16"

./temp/mount.sh "$TMP_PATH" "$TMP_SIZE"

cd ".."

ruby_version=$(< ".ruby-version")
ruby_gemset=$(< ".ruby-gemset")

if command -v rvm > /dev/null 2>&1; then
  # Using latest available ruby version (search is based on required major version).
  ruby_major_version=$(echo "${ruby_version%.*}" | sed "s/\./\\\./g") # escaping for regex
  ruby_version=$(rvm list | grep -o -e "${ruby_major_version}\.[0-9]\+" | sort | tail -n 1)
fi

bash -cl "\
  rvm use \"${ruby_version}@${ruby_gemset}\"; \
  gem install bundler && \
  bundle install && \
  bundle exec rake clean && \
  bundle exec rake \
"
