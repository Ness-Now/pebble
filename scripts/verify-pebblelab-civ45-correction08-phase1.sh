#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
cd "$ROOT_DIR"

BUILD_CONFIGURATION=debug
swift build -c "$BUILD_CONFIGURATION" --product pebsmoke
swift build -c "$BUILD_CONFIGURATION" --product Pebble

PROOF_ROOT=$(mktemp -d /tmp/pebblelab-civ45-correction08-phase1.XXXXXX)
mkdir -p "$PROOF_ROOT/core-home" "$PROOF_ROOT/appkit-home"

CFFIXED_USER_HOME="$PROOF_ROOT/core-home" \
PEBBLELAB_SMOKE_ONLY=civ-45-correction08 \
    ".build/$BUILD_CONFIGURATION/pebsmoke" | tee "$PROOF_ROOT/core.log"

grep -q '6 passed, 0 failed' "$PROOF_ROOT/core.log"
grep -q 'CIV45_C08_EXIT .*status=PASS' "$PROOF_ROOT/core.log"
grep -q 'CIV45_C08_EXIT_RETRY .*status=PASS' "$PROOF_ROOT/core.log"
grep -q 'CIV45_C08_REPLACEMENT .*status=PASS' "$PROOF_ROOT/core.log"
grep -q 'CIV45_C08_MULTI .*status=PASS' "$PROOF_ROOT/core.log"
grep -q 'CIV45_C08_CYCLES .*status=PASS' "$PROOF_ROOT/core.log"
! grep -q 'status=FAIL\|✗' "$PROOF_ROOT/core.log"

CFFIXED_USER_HOME="$PROOF_ROOT/appkit-home" \
PEBBLE_AUTOLOAD=1 \
PEBBLE_NEWWORLD=73 \
PEBBLE_NEWWORLD_NAME=PebbleLab-Disposable-C08-AppKit-73 \
PEBBLELAB_APP_AGENTS=1 \
PEBBLELAB_APP_AGENTS_PERSISTENCE=1 \
PEBBLELAB_APP_PROBES=1 \
PEBBLELAB_DEBUG_ENTITIES=1 \
PEBBLELAB_CIV45_C08_TERMINATION_PROOF=1 \
    ".build/$BUILD_CONFIGURATION/Pebble" > "$PROOF_ROOT/appkit.log" 2>&1

grep -q 'CIV45_C08_APPKIT_CANCEL .*detachedRefusal=PASS .*status=PASS' \
    "$PROOF_ROOT/appkit.log"
grep -q 'CIV45_C08_APPKIT_SUCCESS .*status=PASS' "$PROOF_ROOT/appkit.log"
! grep -q 'status=FAIL\|precondition failed\|Fatal error' "$PROOF_ROOT/appkit.log"

CFFIXED_USER_HOME="$PROOF_ROOT/appkit-home" \
PEBBLELAB_SMOKE_ONLY=civ-45-correction08-appkit-reader \
    ".build/$BUILD_CONFIGURATION/pebsmoke" | tee "$PROOF_ROOT/restart.log"

grep -q '1 passed, 0 failed' "$PROOF_ROOT/restart.log"
grep -q 'CIV45_C08_APPKIT_RESTART .*status=PASS' "$PROOF_ROOT/restart.log"
! grep -q 'status=FAIL\|✗' "$PROOF_ROOT/restart.log"

printf 'PASS: CIV-45 Correction 08 Phase 1 streaming custody; evidence=%s\n' \
    "$PROOF_ROOT"
