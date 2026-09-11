#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
BUILD_CONFIGURATION=${PEBBLELAB_CIV47_BUILD_CONFIGURATION:-release}
case "$BUILD_CONFIGURATION" in
    debug|release) ;;
    *)
        printf 'ERROR: unsupported CIV-47 build configuration: %s\n' \
            "$BUILD_CONFIGURATION" >&2
        exit 1
        ;;
esac
if [ "${PEBBLE_REGOLD+x}" = x ]; then
    printf 'ERROR: PEBBLE_REGOLD must be absent.\n' >&2
    exit 1
fi
git -C "$ROOT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1
[ "$(git -C "$ROOT_DIR" rev-parse --show-toplevel)" = "$ROOT_DIR" ]
cd "$ROOT_DIR"
swift build -c "$BUILD_CONFIGURATION" --product pebsmoke
PEBBLELAB_CIV46_BUILD_CONFIGURATION="$BUILD_CONFIGURATION" \
    "$SCRIPT_DIR/verify-pebblelab-civ46.sh"
PEBBLELAB_SMOKE_ONLY=civ-47 \
    ".build/$BUILD_CONFIGURATION/pebsmoke"
