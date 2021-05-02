#!/usr/bin/env bash
set -e

DIR=$(dirname "${BASH_SOURCE[0]}")
cd "$DIR"

git remote | xargs -n1 git push --all
git remote | xargs -n1 git push --tags
