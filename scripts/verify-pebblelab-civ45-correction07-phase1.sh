#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
cd "$ROOT_DIR"

BUILD_CONFIGURATION=debug
swift build -c "$BUILD_CONFIGURATION" --product pebsmoke
swift build -c "$BUILD_CONFIGURATION" --product Pebble

PROOF_ROOT=$(mktemp -d /tmp/pebblelab-civ45-correction07-phase1.XXXXXX)
mkdir -p "$PROOF_ROOT/core-home" "$PROOF_ROOT/appkit-home"

CFFIXED_USER_HOME="$PROOF_ROOT/core-home" \
PEBBLELAB_SMOKE_ONLY=civ-45-correction07 \
    ".build/$BUILD_CONFIGURATION/pebsmoke" | tee "$PROOF_ROOT/core.log"

grep -q '8 passed, 0 failed' "$PROOF_ROOT/core.log"
grep -q 'CIV45_C07_EXIT .*status=PASS' "$PROOF_ROOT/core.log"
grep -q 'CIV45_C07_EXIT_RETRY .*status=PASS' "$PROOF_ROOT/core.log"
grep -q 'CIV45_C07_REPLACEMENT .*status=PASS' "$PROOF_ROOT/core.log"
grep -q 'CIV45_C07_REQUIRED write=world .*status=PASS' "$PROOF_ROOT/core.log"
grep -q 'CIV45_C07_REQUIRED write=player .*status=PASS' "$PROOF_ROOT/core.log"
grep -q 'CIV45_C07_REQUIRED write=advancements .*status=PASS' "$PROOF_ROOT/core.log"
grep -q 'CIV45_C07_MIXED .*status=PASS' "$PROOF_ROOT/core.log"
! grep -q 'status=FAIL\|✗' "$PROOF_ROOT/core.log"

CFFIXED_USER_HOME="$PROOF_ROOT/appkit-home" \
PEBBLE_AUTOLOAD=1 \
PEBBLE_NEWWORLD=73 \
PEBBLE_NEWWORLD_NAME=PebbleLab-Disposable-C07-AppKit-73 \
PEBBLELAB_APP_AGENTS=1 \
PEBBLELAB_APP_AGENTS_PERSISTENCE=1 \
PEBBLELAB_APP_PROBES=1 \
PEBBLELAB_DEBUG_ENTITIES=1 \
PEBBLELAB_CIV45_C07_TERMINATION_PROOF=1 \
    ".build/$BUILD_CONFIGURATION/Pebble" > "$PROOF_ROOT/appkit.log" 2>&1

grep -q 'CIV45_C07_APPKIT_CANCEL .*status=PASS' "$PROOF_ROOT/appkit.log"
grep -q 'CIV45_C07_APPKIT_SUCCESS .*status=PASS' "$PROOF_ROOT/appkit.log"
! grep -q 'status=FAIL\|precondition failed\|Fatal error' "$PROOF_ROOT/appkit.log"

printf 'PASS: CIV-45 Correction 07 Phase 1 lifecycle boundaries; evidence=%s\n' "$PROOF_ROOT"
