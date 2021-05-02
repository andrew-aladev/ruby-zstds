#!/usr/bin/env bash
set -e

DIR=$(dirname "${BASH_SOURCE[0]}")
cd "$DIR"

git fetch --all || true
git fetch --tags || true
git remote | xargs -n1 -I {} git rebase "{}/$(git branch --show-current)" || true

cd ".."
rm -f "Gemfile.lock"

bash -cl "\
  gem install bundler && \
  bundle update \
"
