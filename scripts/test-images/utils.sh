#!/usr/bin/env bash
set -e

XDG_RUNTIME_DIR="/tmp/buildah-runtime"
mkdir -p "$XDG_RUNTIME_DIR"

tool () {
  XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" buildah unshare -- buildah "$@"
}

# -- wrappers --

bud () {
  tool bud \
    --cap-add=CAP_SETFCAP \
    --cap-add=CAP_SYS_PTRACE \
    --security-opt="seccomp=unconfined" \
    --isolation="rootless" \
    "$@"
}

from () {
  tool from \
    --cap-add=CAP_SETFCAP \
    --cap-add=CAP_SYS_PTRACE \
    --security-opt="seccomp=unconfined" \
    --isolation="rootless" \
    "$1"
}

run () {
  tool run \
    --cap-add=CAP_SETFCAP \
    --cap-add=CAP_SYS_PTRACE \
    --isolation="rootless" \
    "$@"
}

mount () {
  tool mount "$1"
}

unmount () {
  tool unmount "$1"
}

copy () {
  tool copy "$1" "$2" "$3"
}

remove () {
  tool rm "$1"
}

# -- utils --

build () {
  args=()

  for arg_name in $IMAGE_BUILD_ARGS; do
    args+=(--build-arg ${arg_name}="${!arg_name}")
  done

  # Layers are enabled by default.
  layers=${IMAGE_LAYERS:-"true"}

  bud \
    "${args[@]}" \
    --tag "$IMAGE_NAME" \
    --platform="$IMAGE_PLATFORM" \
    --label maintainer="$MAINTAINER" \
    --layers="$layers" \
    "$@" \
    "."
}

build_with_portage () {
  portage=$(from "${DOCKER_HOST}/${DOCKER_USERNAME}/test_portage")
  portage_root=$(mount "$portage") || error=$?

  build --volume "${portage_root}/var/db/repos/gentoo:/var/db/repos/gentoo" "$@" \
    || error=$?

  unmount "$portage" || :
  remove "$portage" || :

  if [ ! -z "$error" ]; then
    exit "$error"
  fi
}

push () {
  docker_image_name="docker://${DOCKER_HOST}/${DOCKER_USERNAME}/${IMAGE_NAME}"

  logged_docker_username=$(tool login --get-login "$DOCKER_HOST" || :)
  if [ "$logged_docker_username" != "$DOCKER_USERNAME" ]; then
    tool login --username "$DOCKER_USERNAME" "$DOCKER_HOST"
  fi

  tool push "$IMAGE_NAME" "$docker_image_name"
}

pull () {
  docker_image_name="docker://${DOCKER_HOST}/${DOCKER_USERNAME}/${IMAGE_NAME}"

  tool pull "$docker_image_name"
  tool tag "$docker_image_name" "$IMAGE_NAME"
}

run_image () {
  container=$(from "$IMAGE_NAME")

  run $CONTAINER_OPTIONS "$container" "$@" || error=$?

  remove "$container" || :

  if [ ! -z "$error" ]; then
    exit "$error"
  fi
}
