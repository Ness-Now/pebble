#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
EVIDENCE_ROOT=${PEBBLELAB_I07_EVIDENCE_ROOT:-/tmp/pebblelab-ps01-increment-07-evidence}
DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1
[ "$#" -le 1 ] || { printf 'Usage: %s [--dry-run]\n' "$0" >&2; exit 2; }

fail() {
    printf 'ERROR: %s\n' "$*" >&2
    if [ -n "${RUN_HOME:-}" ] && [ -d "$RUN_HOME" ]; then
        printf 'PRESERVED_RUNTIME: %s\n' "$RUN_HOME" >&2
    fi
    exit 1
}

PRIMARY="$EVIDENCE_ROOT/primary-a.json"
[ -s "$PRIMARY" ] || fail "normal primary evidence missing: $PRIMARY"
TARGET=$(/usr/bin/python3 - "$PRIMARY" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))["renewableFoodContinuity"]
print(f'{d["targetX"]},{d["targetY"]},{d["targetZ"]}')
PY
)

CAPTURE_DIR="$EVIDENCE_ROOT/live-captures"
TRACE_PATH="$EVIDENCE_ROOT/live-trace.log"
RUN_HOME="$EVIDENCE_ROOT/live-home"
LIVE_TIMEOUT_SECONDS=${PEBBLELAB_I07_LIVE_TIMEOUT_SECONDS:-1800}
case "$LIVE_TIMEOUT_SECONDS" in
    ''|*[!0-9]*) fail "invalid live safety timeout: $LIVE_TIMEOUT_SECONDS" ;;
esac
[ "$LIVE_TIMEOUT_SECONDS" -gt 0 ] \
    || fail "live safety timeout must be positive"
BIN_DIR=$(cd "$ROOT_DIR" && swift build -c release --show-bin-path)
PEBBLE_BIN="$BIN_DIR/Pebble"

if [ "$DRY_RUN" -eq 1 ]; then
    printf 'PS01 Increment 07 live dry-run\n'
    printf '  executable: %s\n' "$PEBBLE_BIN"
    printf '  seed: 14\n'
    printf '  founders: 24\n'
    printf '  observed source (camera/trace only): %s\n' "$TARGET"
    printf '  World tick delivery: authoritative real-client 1x\n'
    printf '  success boundary: first normal preserving acquisition; living source stage 1\n'
    printf '  render camera: render-only observer; Player transform unchanged\n'
    printf '  external safety timeout: %s seconds (PEBBLELAB_I07_LIVE_TIMEOUT_SECONDS)\n' \
        "$LIVE_TIMEOUT_SECONDS"
    printf '  capture directory: %s\n' "$CAPTURE_DIR"
    printf '  expected captures: pre-harvest source, post-first acquisition\n'
    exit 0
fi

[ -x "$PEBBLE_BIN" ] || fail "release Pebble binary missing"
[ ! -e "$CAPTURE_DIR" ] || fail "capture directory already exists: $CAPTURE_DIR"
[ ! -e "$RUN_HOME" ] || fail "disposable runtime already exists: $RUN_HOME"
mkdir -p "$EVIDENCE_ROOT" "$CAPTURE_DIR" "$RUN_HOME"
: > "$TRACE_PATH"

env \
    CFFIXED_USER_HOME="$RUN_HOME" \
    PEBBLE_AUTOLOAD=1 \
    PEBBLE_NEWWORLD=14 \
    PEBBLE_CMD='/lab start founders 24' \
    PEBBLELAB_PS01_INCREMENT07_LIVE_CAPTURE=1 \
    PEBBLELAB_PS01_INCREMENT07_LIVE_CAPTURE_DIR="$CAPTURE_DIR" \
    PEBBLELAB_PS01_INCREMENT07_LIVE_OBSERVED_SOURCE="$TARGET" \
    PEBBLELAB_APP_AGENTS=1 \
    PEBBLELAB_APP_AGENTS_TRACE=1 \
    PEBBLELAB_APP_AGENTS_TRACE_EVERY=200 \
    PEBBLELAB_APP_PROBES=1 \
    PEBBLELAB_DEBUG_ENTITIES=1 \
    PEBBLELAB_APP_AGENTS_MOVE=1 \
    PEBBLELAB_APP_AGENTS_INTERACT=1 \
    PEBBLELAB_APP_AGENTS_MATERIAL=1 \
    PEBBLELAB_APP_AGENTS_PERSISTENCE=1 \
    PEBBLELAB_APP_AGENTS_POPULATION=1 \
    PEBBLELAB_APP_AGENTS_LIFECYCLE=1 \
    PEBBLELAB_APP_AGENTS_KINSHIP=1 \
    PEBBLELAB_APP_AGENTS_HOUSEHOLDS=1 \
    PEBBLELAB_APP_AGENTS_CARE=1 \
    PEBBLELAB_APP_AGENTS_CHILDHOOD=1 \
    PEBBLELAB_APP_AGENTS_FAMILY=1 \
    PEBBLELAB_APP_AGENTS_MORTALITY=1 \
    PEBBLELAB_APP_AGENTS_HOMEOSTASIS=1 \
    PEBBLELAB_APP_AGENTS_GENETICS=1 \
    PEBBLELAB_APP_AGENTS_SKILLS=1 \
    PEBBLELAB_APP_AGENTS_ECOLOGICAL_OBSERVATION=1 \
    PEBBLELAB_APP_AGENTS_WILD_SUBSISTENCE=1 \
    PEBBLELAB_APP_AGENTS_AUTONOMOUS_CIVILIZATION=1 \
    "$PEBBLE_BIN" > "$TRACE_PATH" 2>&1 &
PEBBLE_PID=$!

deadline=$((SECONDS + LIVE_TIMEOUT_SECONDS))
while kill -0 "$PEBBLE_PID" 2>/dev/null; do
    if [ "$SECONDS" -ge "$deadline" ]; then
        kill "$PEBBLE_PID" 2>/dev/null || true
        wait "$PEBBLE_PID" 2>/dev/null || true
        fail "live client exceeded ${LIVE_TIMEOUT_SECONDS}-second external safety timeout"
    fi
    sleep 1
done
set +e
wait "$PEBBLE_PID"
status=$?
set -e
[ "$status" -eq 0 ] || fail "live client exited $status"

for milestone in \
    PS01_INCREMENT_07_INITIAL_SOURCE \
    PS01_INCREMENT_07_FIRST_ACQUISITION; do
    /usr/bin/grep -q "$milestone" "$TRACE_PATH" \
        || fail "missing live milestone: $milestone"
done
/usr/bin/grep -Eq \
    'PS01_INCREMENT_07_FIRST_ACQUISITION .*sourceStage=1 .*custody=verified .*conservation=exact .*founders=24 movementObserved=1 .*runtimeErrors=0 catchUpDrops=0 fatalIntegrity=0 .*playerUnchanged=1 harnessPlayerMutation=none cameraAuthority=renderOnlyObserver' \
    "$TRACE_PATH" || fail "first-cycle live conservation/integrity line missing"
/usr/bin/grep -Eq \
    'PS01_INCREMENT_07_CAPTURE phase=preHarvest .*sourceStage=[2-3] .*cameraAuthority=renderOnlyObserver .*alignment=1\.0+ .*playerUnchanged=1 harnessPlayerMutation=none settledRenderFrames=1' \
    "$TRACE_PATH" || fail "pre-harvest render-only capture metadata missing"
/usr/bin/grep -Eq \
    'PS01_INCREMENT_07_CAPTURE phase=postFirstAcquisition .*sourceStage=1 .*custody=verified .*cameraAuthority=renderOnlyObserver .*alignment=1\.0+ .*playerUnchanged=1 harnessPlayerMutation=none settledRenderFrames=1' \
    "$TRACE_PATH" || fail "post-acquisition render-only capture metadata missing"
if /usr/bin/grep -Eq 'PS01_INCREMENT_07_CAPTURE_FAIL|fatal-integrity|conservation=diverged' "$TRACE_PATH"; then
    fail "live trace contains a capture, integrity, or conservation failure"
fi

for capture in \
    01-initial-source.png \
    02-after-first-acquisition.png; do
    [ -s "$CAPTURE_DIR/$capture" ] || fail "missing rendered capture: $capture"
done

if kill -0 "$PEBBLE_PID" 2>/dev/null; then
    fail "Pebble process survived completed live proof"
fi
case "$RUN_HOME" in
    "$EVIDENCE_ROOT"/live-home) /bin/rm -rf "$RUN_HOME" ;;
    *) fail "refusing unexpected live-home cleanup target: $RUN_HOME" ;;
esac
[ ! -e "$RUN_HOME" ] || fail "disposable live runtime cleanup failed"

printf 'PASS: Increment 07 real-client first-preserving-acquisition visual campaign; target=%s captures=%s cleanup=verified watchdog=%ss\n' \
    "$TARGET" "$CAPTURE_DIR" "$LIVE_TIMEOUT_SECONDS"
