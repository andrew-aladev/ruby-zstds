#!/bin/bash

CPU_COUNT=$(grep -c "^processor" "/proc/cpuinfo")
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

  buildah run --cap-add=CAP_SYS_PTRACE --cap-add=CAP_SETFCAP "$CONTAINER" -- sh -c "$command"
}

commit () {
  image_name="${1:-${IMAGE_NAME}}"
  docker_username="${2:-${DOCKER_USERNAME}}"
  container="${3:-${CONTAINER}}"
  docker_image_name="docker://docker.io/${docker_username}/${image_name}"

  buildah commit --format docker "$container" "$image_name"
  buildah tag "$image_name" "$docker_image_name"
}

get_image_created_date () {
  buildah inspect --format "{{.Docker.Created.UTC.Format \"2006-01-02 15:04:05\"}}" "$1"
}

get_today_date () {
  date -u +"%Y-%m-%d %H:%M:%S"
}

check_up_to_date () {
  from_image_name="${1:-${FROM_IMAGE_NAME}}"
  image_name="${2:-${IMAGE_NAME}}"

  from_image=$(buildah images -q "$from_image_name" || :)
  image=$(buildah images -q "$image_name" || :)

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

docker_push () {
  image_name="${1:-${IMAGE_NAME}}"
  docker_username="${2:-${DOCKER_USERNAME}}"
  docker_image_name="docker://docker.io/${docker_username}/${image_name}"

  logged_docker_username=$(buildah login --get-login "docker.io" || :)
  if [ "$logged_docker_username" != "$docker_username" ]; then
    buildah login --username "$docker_username" "docker.io"
  fi

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
  echo "running image ${IMAGE_NAME}"
  buildah run $(buildah from "$IMAGE_NAME") "/home/entrypoint.sh"
}
