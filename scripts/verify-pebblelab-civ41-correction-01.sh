#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
BUILD_CONFIGURATION=${PEBBLELAB_CIV41_BUILD_CONFIGURATION:-release}

case "$BUILD_CONFIGURATION" in
    debug|release) ;;
    *)
        printf 'ERROR: unsupported CIV-41 build configuration: %s\n' \
            "$BUILD_CONFIGURATION" >&2
        exit 1
        ;;
esac

git -C "$ROOT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1
[ "$(git -C "$ROOT_DIR" rev-parse --show-toplevel)" = "$ROOT_DIR" ]

cd "$ROOT_DIR"
swift build -c "$BUILD_CONFIGURATION" --product pebsmoke
TEMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/pebblelab-civ41-correction.XXXXXX")
CHECKPOINT_PATH="$TEMP_ROOT/civ41-correction-schema36.json"
trap 'rm -rf "$TEMP_ROOT"' EXIT

PEBBLELAB_CIV41_CORRECTION_CHECKPOINT_PATH="$CHECKPOINT_PATH" \
PEBBLELAB_SMOKE_ONLY=civ-41-correction-01-restart-write \
    ".build/$BUILD_CONFIGURATION/pebsmoke"
PEBBLELAB_CIV41_CORRECTION_CHECKPOINT_PATH="$CHECKPOINT_PATH" \
PEBBLELAB_SMOKE_ONLY=civ-41-correction-01-restart-read \
    ".build/$BUILD_CONFIGURATION/pebsmoke"
PEBBLELAB_SMOKE_ONLY=civ-41-correction-01 \
    ".build/$BUILD_CONFIGURATION/pebsmoke"
