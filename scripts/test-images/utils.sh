#!/bin/bash

CPU_COUNT=$(grep -c "^processor" "/proc/cpuinfo" || sysctl -n "hw.ncpu")
MAKEOPTS="-j${CPU_COUNT}"

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
  image_name="${1:-${IMAGE_NAME}}"
  docker_username="${2:-${DOCKER_USERNAME}}"
  container="${3:-${CONTAINER}}"
  docker_image_name="docker://docker.io/${docker_username}/${image_name}"

  buildah commit --format docker "$container" "$image_name"
  buildah tag "$image_name" "$docker_image_name"
}

docker_push () {
  image_name="${1:-${IMAGE_NAME}}"
  docker_username="${2:-${DOCKER_USERNAME}}"
  docker_image_name="docker://docker.io/${docker_username}/${image_name}"

  docker login --username "$docker_username"
  buildah push "$image_name" "$docker_image_name"
}

docker_pull () {
  image_name="${1:-${IMAGE_NAME}}"
  docker_username="${2:-${DOCKER_USERNAME}}"
  docker_image_name="docker://docker.io/${docker_username}/${image_name}"

  buildah pull "$docker_image_name"
  buildah tag "$docker_image_name" "$image_name"
}

run_image () {
  echo "-- running image $IMAGE_NAME --"
  buildah run $(buildah from "$IMAGE_NAME") "/home/entrypoint.sh"
}
