#!/usr/bin/env bash
set -e

DIR=$(dirname "${BASH_SOURCE[0]}")
cd "$DIR"

git fetch --all || true
git fetch --tags || true
git remote | xargs -n1 -I {} git rebase "{}/$(git branch --show-current)" || true

cd ".."
ROOT_DIR=$(pwd)

rm -f "Gemfile.lock"

/usr/bin/env bash -cl "\
  cd \"$ROOT_DIR\" && \
  gem install bundler --force && \
  bundle update \
"
