#!/bin/bash
set -e

cd "$(dirname $0)"

buildah unshare ./buildah.sh
