#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
BUILD_CONFIGURATION=${PEBBLELAB_CIV43_BUILD_CONFIGURATION:-release}

case "$BUILD_CONFIGURATION" in
    debug|release) ;;
    *)
        printf 'ERROR: unsupported CIV-43 build configuration: %s\n' \
            "$BUILD_CONFIGURATION" >&2
        exit 1
        ;;
esac

git -C "$ROOT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1
[ "$(git -C "$ROOT_DIR" rev-parse --show-toplevel)" = "$ROOT_DIR" ]

cd "$ROOT_DIR"
swift build -c "$BUILD_CONFIGURATION" --product pebsmoke
TEMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/pebblelab-civ43.XXXXXX")
CHECKPOINT_PATH="$TEMP_ROOT/civ43-schema38.json"
trap 'rm -rf "$TEMP_ROOT"' EXIT

PEBBLELAB_CIV43_CHECKPOINT_PATH="$CHECKPOINT_PATH" \
PEBBLELAB_SMOKE_ONLY=civ-43-restart-write \
    ".build/$BUILD_CONFIGURATION/pebsmoke"
PEBBLELAB_CIV43_CHECKPOINT_PATH="$CHECKPOINT_PATH" \
PEBBLELAB_SMOKE_ONLY=civ-43-restart-read \
    ".build/$BUILD_CONFIGURATION/pebsmoke"
PEBBLELAB_SMOKE_ONLY=civ-43 \
    ".build/$BUILD_CONFIGURATION/pebsmoke"
