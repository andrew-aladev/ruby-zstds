#!/bin/bash

CPU_COUNT=$(grep -c "^processor" "/proc/cpuinfo")
MAKEOPTS="-j${CPU_COUNT}"

# https://github.com/containers/buildah/issues/2165
XDG_RUNTIME_DIR="/tmp/buildah-user"
mkdir -p "$XDG_RUNTIME_DIR"

quote_args () {
  for arg in "$@"; do
    printf " %q" "$arg"
  done
}

tool () {
  command=$(quote_args "$@")
  XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" eval buildah "$command"
}

# -----

unshare () {
  tool unshare "$1"
}

from () {
  tool from "$1"
}

mount () {
  tool mount "$1"
}

unmount () {
  tool unmount "$1"
}

config () {
  command=$(quote_args "$@")
  command="--label maintainer=\"${MAINTAINER}\" ${command} ${CONTAINER}"
  eval tool config "$command"
}

copy () {
  tool copy "$CONTAINER" "$1" "$2"
}

run () {
  command=$(quote_args "$@")
  tool run "$CONTAINER" -- sh -c "$command"
}

build () {
  command=$(quote_args "$@")
  command="MAKEOPTS=\"${MAKEOPTS}\" ${command}"

  tool run \
    --cap-add=CAP_SYS_PTRACE \
    --cap-add=CAP_SETFCAP \
    "$CONTAINER" -- sh -c "$command"
}

# -----

commit () {
  image_name="${1:-${IMAGE_NAME}}"
  docker_username="${2:-${DOCKER_USERNAME}}"
  container="${3:-${CONTAINER}}"
  docker_image_name="docker://docker.io/${docker_username}/${image_name}"

  tool commit --format docker "$container" "$image_name"
  tool tag "$image_name" "$docker_image_name"
}

push () {
  image_name="${1:-${IMAGE_NAME}}"
  docker_username="${2:-${DOCKER_USERNAME}}"
  docker_image_name="docker://docker.io/${docker_username}/${image_name}"

  logged_docker_username=$(tool login --get-login "docker.io" || :)
  if [ "$logged_docker_username" != "$docker_username" ]; then
    tool login --username "$docker_username" "docker.io"
  fi

  tool push "$image_name" "$docker_image_name"
}

pull () {
  image_name="${1:-${IMAGE_NAME}}"
  docker_username="${2:-${DOCKER_USERNAME}}"
  docker_image_name="docker://docker.io/${docker_username}/${image_name}"

  tool pull "$docker_image_name"
  tool tag "$docker_image_name" "$image_name"
}

# -----

get_image_created_date () {
  tool inspect --format "{{.Docker.Created.UTC.Format \"2006-01-02 15:04:05\"}}" "$1"
}

get_today_date () {
  date -u +"%Y-%m-%d %H:%M:%S"
}

check_up_to_date () {
  from_image_name="${1:-${FROM_IMAGE_NAME}}"
  image_name="${2:-${IMAGE_NAME}}"

  from_image=$(tool images -q "$from_image_name" || :)
  image=$(tool images -q "$image_name" || :)

  if [ -z "$from_image" ]; then
    >&2 echo "from image is required"
    exit 1
  fi

  if [ -z "$image" ]; then
    echo "image: ${IMAGE_NAME} has not yet been built"
    return
  fi

  from_image_created_date=$(get_image_created_date "$from_image")
  image_created_date=$(get_image_created_date "$image")

  if [[ ! "$from_image_created_date" < "$image_created_date" ]]; then
    echo "from image: ${FROM_IMAGE_NAME} is more recent than image: ${IMAGE_NAME}, it will be rebuilt"
    return
  fi

  if ([ ! -z "$REBUILD_DATE" ] && [[ ! "$REBUILD_DATE" < "$image_created_date" ]]); then
    echo "image: ${IMAGE_NAME} will be rebuilt"
    return
  fi

  echo "image: ${IMAGE_NAME} is already up to date"
  exit 0
}

# -----

run_image () {
  echo "running image: ${IMAGE_NAME}"
  run $(from "$IMAGE_NAME") "/home/entrypoint.sh"
}
