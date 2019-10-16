#!/bin/sh
set -e

cd "$(dirname $0)"

git remote add github    "git@github.com:andrew-aladev/ruby-zstds.git"    || true
git remote add bitbucket "git@bitbucket.org:andrew-aladev/ruby-zstds.git" || true
git remote add gitlab    "git@gitlab.com:andrew-aladev/ruby-zstds.git"    || true
