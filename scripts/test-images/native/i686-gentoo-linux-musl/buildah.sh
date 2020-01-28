#!/bin/bash
set -e

DIR=$(dirname "${BASH_SOURCE[0]}")
cd "$DIR"

source "../../utils.sh"
source "./env.sh"

docker_pull "$FROM_IMAGE_NAME"

CONTAINER=$(buildah from "$FROM_IMAGE_NAME")
buildah config --label maintainer="$MAINTAINER" --entrypoint "/home/entrypoint.sh" "$CONTAINER"

run mkdir -p /home
copy ../../entrypoint.sh /home/

copy root/ /
build emerge -v dev-vcs/git dev-lang/ruby:2.7 virtual/rubygems

commit
