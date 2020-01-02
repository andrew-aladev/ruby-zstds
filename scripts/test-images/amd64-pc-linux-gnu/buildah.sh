#!/bin/bash
set -e

DIR=$(dirname "${BASH_SOURCE[0]}")
cd "$DIR"

source "../../utils.sh"
source "./env.sh"

CONTAINER=$(buildah from "$FROM_IMAGE_NAME")
buildah config --label maintainer="$MAINTAINER" "$CONTAINER"

run mkdir -p /home
copy ../entrypoint.sh /home/

copy root/ /
build emerge -v dev-vcs/git dev-lang/ruby:2.7 virtual/rubygems

run update
build upgrade
run cleanup

run find /etc -maxdepth 1 -name ._cfg* -delete
run eselect news read

commit
