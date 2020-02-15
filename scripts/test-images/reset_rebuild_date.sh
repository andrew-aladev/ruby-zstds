#!/bin/bash
set -e

DIR=$(dirname "${BASH_SOURCE[0]}")
cd "$DIR"

./native/reset_rebuild_date.sh
./cross/reset_rebuild_date.sh
