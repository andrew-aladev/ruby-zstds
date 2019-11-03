#!/bin/bash
set -e

cd "$(dirname $0)"

source "../env.sh"
source "../utils.sh"

DOCKER_IMAGE="${DOCKER_IMAGE_PREFIX}_amd64-pc-linux-gnu"

CONTAINER=$(buildah from "docker.io/$DOCKER_USERNAME/test_amd64-pc-linux-gnu:latest")
buildah config --label maintainer="$MAINTAINER" --entrypoint "/home/entrypoint.sh" "$CONTAINER"

run mkdir -p /home
copy ../entrypoint.sh /home/

copy root/ /
build emerge -v \
  dev-vcs/git \
  dev-lang/ruby:2.6 virtual/rubygems

build "update && upgrade && cleanup"

run rm -rf /etc/._cfg*
run eselect news read

commit
