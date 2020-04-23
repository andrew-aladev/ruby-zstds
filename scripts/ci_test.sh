#!/bin/bash
set -e

DIR=$(dirname "${BASH_SOURCE[0]}")
cd "$DIR"

CPU_COUNT=$(grep -c "^processor" "/proc/cpuinfo" || sysctl -n "hw.ncpu")

# This script is for CI machines only, it provides junk and changes some config files.
# Please do not use it on your machine.

./mount_tmp.sh "16"

cd ".."

# CI may not want to provide target ruby version.
# We can just use the latest available ruby based on target major version.
if command -v rvm > /dev/null 2>&1; then
  ruby_version=$(< ".ruby-version")
  ruby_major_version=$(echo "${ruby_version%.*}" | sed "s/\./\\\./g") # escaping for regex
  ruby_version=$(rvm list | grep -o -e "${ruby_major_version}\.[0-9]\+" | sort | tail -n 1)
  echo "${ruby_version}" > ".ruby-version"
fi

bash -cl "\
  rvm use '.'; \
  gem install bundler && \
  bundle install \
"

# Fix path environment params.
export PATH="${PATH}:/usr/local/bin"
export C_INCLUDE_PATH="${C_INCLUDE_PATH}:/usr/local/include"
export LIBRARY_PATH="${C_INCLUDE_PATH}:/usr/local/lib"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/usr/local/lib"

# Compiling library from source.
ZSTD_BRANCH="v1.4.4"

build="build"
mkdir -p "$build"
cd "$build"

# Remove orphaned directory.
rm -rf "zstd"
git clone "https://github.com/facebook/zstd.git" --single-branch --branch "$ZSTD_BRANCH" --depth 1 "zstd"
cd "zstd"

export CFLAGS="-DZSTD_MULTITHREAD=1"
export CXXFLAGS="-DZSTD_MULTITHREAD=1"

make clean
make -j${CPU_COUNT}

# "sudo" may be required for "/usr/local".
if command -v sudo > /dev/null 2>&1; then
  sudo make install
else
  make install
fi

bash -cl "\
  cd ../.. && \
  rvm use '.'; \
  bundle exec rake clean && \
  bundle exec rake \
"
