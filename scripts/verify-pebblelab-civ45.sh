#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
cd "$ROOT_DIR"
BUILD_CONFIGURATION=${PEBBLELAB_CIV45_BUILD_CONFIGURATION:-release}
case "$BUILD_CONFIGURATION" in debug|release) ;; *) exit 2 ;; esac
swift build -c "$BUILD_CONFIGURATION" --product pebsmoke
PEBBLELAB_CIV45_BUILD_CONFIGURATION="$BUILD_CONFIGURATION" \
    PEBBLELAB_CIV45_C02_SKIP_BUILD=1 \
    scripts/verify-pebblelab-civ45-correction02.sh
TMP_BASE=${TMPDIR:-/tmp}
TMP_BASE=${TMP_BASE%/}
PERSISTENCE_HOME=$(mktemp -d "$TMP_BASE/pebblelab-civ45-persistent-identity.XXXXXX")
cleanup() {
    rm -rf -- "$PERSISTENCE_HOME"
}
trap cleanup EXIT
CFFIXED_USER_HOME="$PERSISTENCE_HOME" \
    PEBBLELAB_SMOKE_ONLY=civ-45-persistent-identity \
    ".build/$BUILD_CONFIGURATION/pebsmoke"
PEBBLELAB_SMOKE_ONLY=civ-45 ".build/$BUILD_CONFIGURATION/pebsmoke"
