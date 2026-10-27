#!/bin/bash
#
# Copies the files listed in overlay.txt from a patched dCache tarball into
# the container build context, and checks that each of them exists in the
# official image.
#
# Usage: prepare-overlay.sh <version> <dcache-tarball> <context-dir> [<engine>]
#
set -euo pipefail

version=$1
tarball=$2
context=$3
engine=${4:-docker}

here=$(cd "$(dirname "$0")" && pwd)
base="docker.io/dcache/dcache:${version}"

unpacked=$(mktemp -d)
trap 'rm -rf "$unpacked"' EXIT
tar -C "$unpacked" --strip-components=1 -xzf "$tarball"

mkdir -p "$context/opt/dcache"
cp "$here/Dockerfile" "$context/"

"$engine" pull -q "$base" > /dev/null
# Inspect the image without running it, as it may need a newer CPU than the
# build host has.
container=$("$engine" create "$base")
trap 'rm -rf "$unpacked"; "$engine" rm "$container" > /dev/null' EXIT

grep -v -e '^#' -e '^[[:space:]]*$' "$here/overlay.txt" | while read -r entry; do
    file=${entry//\$\{VERSION\}/$version}

    if [[ ! -f "$unpacked/$file" ]]; then
        echo "ERROR: $file not found in $tarball" >&2
        exit 1
    fi
    if ! "$engine" cp "$container:/opt/dcache/$file" - > /dev/null 2>&1; then
        echo "ERROR: $file not found in $base" >&2
        exit 1
    fi

    mkdir -p "$context/opt/dcache/$(dirname "$file")"
    cp "$unpacked/$file" "$context/opt/dcache/$file"
    echo "overlay: /opt/dcache/$file"
done
