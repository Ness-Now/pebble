#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
BUILD_CONFIGURATION=${PEBBLELAB_CIV46_BUILD_CONFIGURATION:-release}
case "$BUILD_CONFIGURATION" in
    debug|release) ;;
    *)
        printf 'ERROR: unsupported CIV-46 build configuration: %s\n' \
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
PEBBLELAB_CIV41_BUILD_CONFIGURATION="$BUILD_CONFIGURATION" \
    "$SCRIPT_DIR/verify-pebblelab-civ41.sh"
PEBBLELAB_CIV42_BUILD_CONFIGURATION="$BUILD_CONFIGURATION" \
    "$SCRIPT_DIR/verify-pebblelab-civ42.sh"
PEBBLELAB_CIV43_BUILD_CONFIGURATION="$BUILD_CONFIGURATION" \
    "$SCRIPT_DIR/verify-pebblelab-civ43.sh"
PEBBLELAB_CIV44_BUILD_CONFIGURATION="$BUILD_CONFIGURATION" \
    "$SCRIPT_DIR/verify-pebblelab-civ44.sh"
PEBBLELAB_CIV45_BUILD_CONFIGURATION="$BUILD_CONFIGURATION" \
    "$SCRIPT_DIR/verify-pebblelab-civ45.sh"
PEBBLELAB_SMOKE_ONLY=civ-46 \
    ".build/$BUILD_CONFIGURATION/pebsmoke"
