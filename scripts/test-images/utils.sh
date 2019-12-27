#!/bin/bash

CPU_COUNT=$(grep -c "^processor" "/proc/cpuinfo")
MAKEOPTS="-j$CPU_COUNT"

quote_args () {
  for arg in "$@"; do
    printf " %q" "$arg"
  done
}

copy () {
  command=$(quote_args "$@")
  eval buildah copy "$CONTAINER" "$command"
}

run () {
  command=$(quote_args "$@")
  buildah run "$CONTAINER" -- sh -c "$command"
}

build () {
  command=$(quote_args "$@")
  command="MAKEOPTS=\"$MAKEOPTS\" $command"
  buildah run --cap-add=CAP_SYS_PTRACE "$CONTAINER" -- sh -c "$command"
}

commit () {
  buildah commit --format docker "$CONTAINER" "$IMAGE_NAME"

  DOCKER_IMAGE_NAME="docker://docker.io/$DOCKER_USERNAME/$IMAGE_NAME"
  buildah tag "$IMAGE_NAME" "$DOCKER_IMAGE_NAME"
}

docker_push () {
  docker login --username "$DOCKER_USERNAME"

  DOCKER_IMAGE_NAME="docker://docker.io/$DOCKER_USERNAME/$IMAGE_NAME"
  buildah push "$IMAGE_NAME" "$DOCKER_IMAGE_NAME"
}

docker_pull () {
  DOCKER_IMAGE_NAME="docker://docker.io/$DOCKER_USERNAME/$IMAGE_NAME"
  buildah pull "$DOCKER_IMAGE_NAME"
  buildah tag "$DOCKER_IMAGE_NAME" "$IMAGE_NAME"
}
