#!/bin/sh
# Usage: ./kdev              -- mounts $PWD into /work
#        ./kdev /some/path   -- mounts that path instead
set -e
IMG=kernel-dev
HERE="$(cd "$(dirname "$0")" && pwd)"
HOST_DIR="${1:-$PWD}"

docker build -t "$IMG" "$HERE"

exec docker run --rm -it \
  -v "$HOST_DIR:/work" \
  -w /work \
  "$IMG"
