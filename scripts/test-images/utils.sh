#!/bin/bash

CPU_COUNT=$(grep -c "^processor" "/proc/cpuinfo")
MAKEOPTS="-j$CPU_COUNT"

copy () {
  buildah copy "$CONTAINER" $@
}

run () {
  command="$@"
  buildah run "$CONTAINER" -- sh -c "$command"
}

build () {
  command="MAKEOPTS=\"$MAKEOPTS\" $@"
  buildah run --cap-add=CAP_SYS_PTRACE "$CONTAINER" -- sh -c "$command"
}

commit () {
  buildah commit --format docker "$CONTAINER" "$DOCKER_IMAGE"
}

docker_push () {
  DOCKER_IMAGE="$1"

  docker login --username "$DOCKER_USERNAME"

  LOCAL_IMAGE="$DOCKER_IMAGE:latest"
  REMOTE_IMAGE="docker://docker.io/$DOCKER_USERNAME/$DOCKER_IMAGE:latest"

  buildah push "$LOCAL_IMAGE" "$REMOTE_IMAGE"
}

docker_pull () {
  DOCKER_IMAGE="$1"

  LOCAL_IMAGE="$DOCKER_IMAGE:latest"
  REMOTE_IMAGE="docker://docker.io/$DOCKER_USERNAME/$DOCKER_IMAGE:latest"

  buildah pull "$REMOTE_IMAGE"
  buildah tag "$REMOTE_IMAGE" "$LOCAL_IMAGE"
}
