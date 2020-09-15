#!/bin/bash
set -e

XDG_RUNTIME_DIR="/tmp/buildah-runtime"
mkdir -p "$XDG_RUNTIME_DIR"

tool () {
  XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" buildah "$@"
}

# -----

bud () {
  tool bud \
    --cap-add=CAP_SYS_PTRACE \
    --cap-add=CAP_SETFCAP \
    --security-opt="seccomp=unconfined" \
    --isolation="rootless" \
    "$@"
}

from () {
  tool from \
    --cap-add=CAP_SYS_PTRACE \
    --cap-add=CAP_SETFCAP \
    --security-opt="seccomp=unconfined" \
    --isolation="rootless" \
    "$1"
}

run () {
  tool run \
    --cap-add=CAP_SYS_PTRACE \
    --cap-add=CAP_SETFCAP \
    --security-opt="seccomp=unconfined" \
    --isolation="rootless" \
    "$@"
}

mount () {
  tool unshare -- sh -c "buildah mount $1"
}

unmount () {
  tool unshare -- sh -c "buildah unmount $1"
}

copy () {
  tool copy "$1" "$2" "$3"
}

remove () {
  tool rm "$1"
}

attach () {
  container=$(from "$FROM_IMAGE")

  (
    container_root=$(mount "$container")
    fusermount -zu attached-root || true
    bindfs -r -o nonempty "${container_root}$1" attached-root
  ) || error=$?

  if [ ! -z "$error" ]; then
    detach "$container"
    exit "$error"
  fi

  echo "$container"
}

detach () {
  fusermount -zu attached-root || true

  unmount "$1" || true
  remove "$1" || true
}

build () {
  args=()

  for arg_name in $1; do
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
    "."
}

push () {
  docker_image_name="docker://docker.io/${DOCKER_USERNAME}/${IMAGE_NAME}"

  logged_docker_username=$(tool login --get-login "docker.io" || :)
  if [ "$logged_docker_username" != "$DOCKER_USERNAME" ]; then
    tool login --username "$DOCKER_USERNAME" "docker.io"
  fi

  tool push "$IMAGE_NAME" "$docker_image_name"
}

pull () {
  docker_image_name="docker://docker.io/${DOCKER_USERNAME}/${IMAGE_NAME}"

  tool pull "$docker_image_name"
  tool tag "$docker_image_name" "$IMAGE_NAME"
}

run_image () {
  container=$(from "$IMAGE_NAME")
  run $CONTAINER_OPTIONS "$container" "$@" || error=$?

  remove "$container" || true

  if [ ! -z "$error" ]; then
    exit "$error"
  fi
}
