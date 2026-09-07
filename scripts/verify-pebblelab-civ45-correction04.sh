#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
cd "$ROOT_DIR"

BUILD_CONFIGURATION=${PEBBLELAB_CIV45_BUILD_CONFIGURATION:-debug}
case "$BUILD_CONFIGURATION" in debug|release) ;; *) exit 2 ;; esac
swift build -c "$BUILD_CONFIGURATION" --product Pebble

PROOF_ROOT=$(mktemp -d /tmp/pebblelab-civ45-correction04.XXXXXX)
HOME_ROOT="$PROOF_ROOT/home"
mkdir -p "$HOME_ROOT"
export PEBBLELAB_CIV45_C04_ROOT="$PROOF_ROOT"
export PEBBLELAB_CIV45_C04_BINARY="$ROOT_DIR/.build/$BUILD_CONFIGURATION/Pebble"
export PEBBLELAB_CIV45_C04_HOME="$HOME_ROOT"

run_phase() {
    phase=$1
    trace=$2
    new_world=$3
    if [ "$new_world" = 1 ]; then
        PEBBLE_NEWWORLD=46 PEBBLE_NEWWORLD_NAME=PebbleLab-Disposable-Writing-46 \
            run_process "$phase" "$trace"
    else
        run_process "$phase" "$trace"
    fi
}

run_process() {
    phase=$1
    trace=$2
    CFFIXED_USER_HOME="$PEBBLELAB_CIV45_C04_HOME" \
    PEBBLE_AUTOLOAD=1 \
    PEBBLELAB_APP_AGENTS=1 \
    PEBBLELAB_APP_AGENTS_MOVE=1 \
    PEBBLELAB_APP_PROBES=1 \
    PEBBLELAB_DEBUG_ENTITIES=1 \
    PEBBLELAB_APP_AGENTS_TRACE=1 \
    PEBBLELAB_APP_AGENTS_WRITING=1 \
    PEBBLELAB_DISPOSABLE_WORLD_PROOF=1 \
    PEBBLELAB_CIV45_PROOF_DIR="$PEBBLELAB_CIV45_C04_ROOT" \
    PEBBLE_CMD="/gamerule randomTickSpeed 0;/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/tp 14 68 -18|/lab start;/lab pause;/lab movement off;/lab overlay off;/lab writing proof $phase|/lab stop" \
    PEBBLE_SHOT='-|-|-' \
        "$PEBBLELAB_CIV45_C04_BINARY" > "$trace" 2>&1
}

run_phase correction04 "$PROOF_ROOT/write-failure.log" 1
run_phase correction04-restart "$PROOF_ROOT/restart.log" 0

grep -q 'CIV45_C04 .*status=PASS' "$PROOF_ROOT/write-failure.log"
grep -q 'CIV45_C04_DIRTY .*result=PASS' "$PROOF_ROOT/write-failure.log"
grep -q 'CIV45_C04_RESTART .*status=PASS' "$PROOF_ROOT/restart.log"
! grep -q 'status=FAIL\|\[lab-live\] error' "$PROOF_ROOT/write-failure.log"
! grep -q 'status=FAIL\|\[lab-live\] error' "$PROOF_ROOT/restart.log"

printf 'PASS: CIV-45 Correction 04 deterministic capture/rollback, abort, dirty retry, external mutation and separate-process restart; evidence=%s\n' "$PROOF_ROOT"
