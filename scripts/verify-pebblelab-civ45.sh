#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
cd "$ROOT_DIR"
BUILD_CONFIGURATION=${PEBBLELAB_CIV45_BUILD_CONFIGURATION:-release}
case "$BUILD_CONFIGURATION" in debug|release) ;; *) exit 2 ;; esac
swift build -c "$BUILD_CONFIGURATION" --product pebsmoke
PEBBLELAB_SMOKE_ONLY=civ-45 ".build/$BUILD_CONFIGURATION/pebsmoke"
