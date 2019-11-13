#!/bin/bash
set -e

cd "$(dirname $0)"

git remote | xargs -n1 git push --all
git remote | xargs -n1 git push --tags
