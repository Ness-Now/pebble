#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
cd "$ROOT_DIR"

BUILD_CONFIGURATION=${PEBBLELAB_CIV45_BUILD_CONFIGURATION:-debug}
case "$BUILD_CONFIGURATION" in debug|release) ;; *) exit 2 ;; esac
swift build -c "$BUILD_CONFIGURATION" --product pebsmoke
swift build -c "$BUILD_CONFIGURATION" --product Pebble

PROOF_ROOT=$(mktemp -d /tmp/pebblelab-civ45-correction06.XXXXXX)
mkdir -p "$PROOF_ROOT/core-home" "$PROOF_ROOT/live-home" "$PROOF_ROOT/termination-home"
CFFIXED_USER_HOME="$PROOF_ROOT/core-home" \
PEBBLELAB_SMOKE_ONLY=civ-45-correction06 \
    ".build/$BUILD_CONFIGURATION/pebsmoke" | tee "$PROOF_ROOT/correction06.log"

grep -q 'CIV45_C06_RETURN .*status=PASS' "$PROOF_ROOT/correction06.log"
grep -q 'CIV45_C06_SUCCESS .*status=PASS' "$PROOF_ROOT/correction06.log"
grep -q 'CIV45_C06_DELETE .*status=PASS' "$PROOF_ROOT/correction06.log"
grep -q 'CIV45_C06_EDIT .*status=PASS' "$PROOF_ROOT/correction06.log"
grep -q 'CIV45_C06_GENERATIONS .*status=PASS' "$PROOF_ROOT/correction06.log"
grep -q 'CIV45_C06_EXIT .*status=PASS' "$PROOF_ROOT/correction06.log"
grep -q 'CIV45_C06_TERMINATION .*status=PASS' "$PROOF_ROOT/correction06.log"
grep -q 'CIV45_C06_WORLD_ISOLATION .*status=PASS' "$PROOF_ROOT/correction06.log"
! grep -q '✗' "$PROOF_ROOT/correction06.log"

run_live_process() {
    phase=$1
    trace=$2
    new_world=$3
    if [ "$new_world" = 1 ]; then
        world_env="PEBBLE_NEWWORLD=46 PEBBLE_NEWWORLD_NAME=PebbleLab-Disposable-Writing-46"
    else
        world_env=""
    fi
    env $world_env \
    CFFIXED_USER_HOME="$PROOF_ROOT/live-home" \
    PEBBLE_AUTOLOAD=1 \
    PEBBLELAB_APP_AGENTS=1 \
    PEBBLELAB_APP_AGENTS_MOVE=1 \
    PEBBLELAB_APP_PROBES=1 \
    PEBBLELAB_DEBUG_ENTITIES=1 \
    PEBBLELAB_APP_AGENTS_TRACE=1 \
    PEBBLELAB_APP_AGENTS_WRITING=1 \
    PEBBLELAB_DISPOSABLE_WORLD_PROOF=1 \
    PEBBLELAB_CIV45_PROOF_DIR="$PROOF_ROOT" \
    PEBBLE_CMD="/gamerule randomTickSpeed 0;/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/tp 14 68 -18|/lab start;/lab pause;/lab movement off;/lab overlay off;/lab writing proof $phase|/lab stop" \
    PEBBLE_SHOT='-|-|-' \
        ".build/$BUILD_CONFIGURATION/Pebble" > "$trace" 2>&1
}

run_live_process correction06 "$PROOF_ROOT/live-write.log" 1
run_live_process correction06-restart "$PROOF_ROOT/live-restart.log" 0
CFFIXED_USER_HOME="$PROOF_ROOT/termination-home" \
PEBBLE_AUTOLOAD=1 \
PEBBLE_NEWWORLD=46 \
PEBBLE_NEWWORLD_NAME=PebbleLab-Disposable-C06-Termination-46 \
PEBBLELAB_CIV45_C06_TERMINATION_PROOF=1 \
    ".build/$BUILD_CONFIGURATION/Pebble" > "$PROOF_ROOT/live-termination.log" 2>&1
grep -q 'CIV45_C06_LIVE .*status=PASS' "$PROOF_ROOT/live-write.log"
grep -q 'CIV45_C06_RESTART .*status=PASS' "$PROOF_ROOT/live-restart.log"
grep -q 'CIV45_C06_APP_TERMINATION .*status=PASS' "$PROOF_ROOT/live-termination.log"
! grep -q 'status=FAIL\|\[lab-live\] error' "$PROOF_ROOT/live-write.log"
! grep -q 'status=FAIL\|\[lab-live\] error' "$PROOF_ROOT/live-restart.log"
! grep -q 'status=FAIL\|\[lab-live\] error' "$PROOF_ROOT/live-termination.log"

printf 'PASS: CIV-45 Correction 06 unresolved streaming and lifecycle recovery; evidence=%s\n' "$PROOF_ROOT"
