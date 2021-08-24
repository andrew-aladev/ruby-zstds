#!/usr/bin/env bash
set -e

DIR=$(dirname "${BASH_SOURCE[0]}")
cd "$DIR"

git fetch --all || :
git fetch --tags || :
git remote | xargs -I {} git rebase "{}/$(git branch --show-current)" || :

./clang/complete.sh
./clang/format.sh

cd ".."

ROOT_DIR=$(pwd)

rm -f "Gemfile.lock"

/usr/bin/env bash -cl "\
  cd \"$ROOT_DIR\" && \
  gem install bundler --force && \
  bundle update && \
  bundle exec rubocop \
"
