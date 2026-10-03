#!/usr/bin/env bash
set -euo pipefail
[ "${PEBBLE_REGOLD+x}" != x ] || { printf 'PEBBLE_REGOLD must be absent.\n' >&2; exit 1; }
ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
EVIDENCE_ROOT=${PEBBLELAB_I08_EVIDENCE_ROOT:-/tmp/pebblelab-ps01-increment-08-live}
BIN_DIR=$(cd "$ROOT_DIR" && swift build -c release --show-bin-path)
RUN_HOME="$EVIDENCE_ROOT/live-home"
if [ "${1:-}" = --dry-run ]; then
    printf 'PS01 Increment 08 live dry-run\nExecutable: %s/Pebble\nSeed: 14, founders: 24\nWriter: ordinary founder startup, naturally acquired food, Save/Continue then Save/Exit\nReader: ordinary World autoload, no founder-start or checkpoint-load command\nTime: normal authoritative 1x, only capture settling pauses World delivery\nCamera: render-only, Player unchanged\nRuntime: %s\nCaptures: before-save, after-restore, continued\n' "$BIN_DIR" "$RUN_HOME"
    exit 0
fi
[ "$#" -eq 0 ] || exit 2
case "$EVIDENCE_ROOT" in /tmp/*|/private/tmp/*) ;; *) exit 2;; esac
[ ! -e "$RUN_HOME" ] || { printf 'Refusing existing live runtime.\n' >&2; exit 1; }
mkdir -p "$RUN_HOME" "$EVIDENCE_ROOT/captures"
mkdir -p "$EVIDENCE_ROOT/executable"
cp "$BIN_DIR/Pebble" "$EVIDENCE_ROOT/executable/Pebble"
LIVE_BINARY="$EVIDENCE_ROOT/executable/Pebble"
shasum -a 256 "$LIVE_BINARY" > "$EVIDENCE_ROOT/executable.sha256"
run_phase() {
    phase=$1
    shift
    env CFFIXED_USER_HOME="$RUN_HOME" PEBBLE_AUTOLOAD=1 \
        PEBBLELAB_PS01_INCREMENT08_LIVE_PHASE="$phase" \
        PEBBLELAB_PS01_INCREMENT08_LIVE_CAPTURE_DIR="$EVIDENCE_ROOT/captures" \
        PEBBLELAB_APP_AGENTS=1 PEBBLELAB_APP_AGENTS_OBSERVER=1 PEBBLELAB_APP_AGENTS_TRACE=1 \
        PEBBLELAB_APP_AGENTS_TRACE_EVERY=200 PEBBLELAB_APP_PROBES=1 \
        PEBBLELAB_DEBUG_ENTITIES=1 PEBBLELAB_APP_AGENTS_MOVE=1 \
        PEBBLELAB_APP_AGENTS_INTERACT=1 PEBBLELAB_APP_AGENTS_MATERIAL=1 \
        PEBBLELAB_APP_AGENTS_PERSISTENCE=1 PEBBLELAB_APP_AGENTS_POPULATION=1 \
        PEBBLELAB_APP_AGENTS_LIFECYCLE=1 PEBBLELAB_APP_AGENTS_KINSHIP=1 \
        PEBBLELAB_APP_AGENTS_HOUSEHOLDS=1 PEBBLELAB_APP_AGENTS_CARE=1 \
        PEBBLELAB_APP_AGENTS_CHILDHOOD=1 PEBBLELAB_APP_AGENTS_FAMILY=1 \
        PEBBLELAB_APP_AGENTS_MORTALITY=1 PEBBLELAB_APP_AGENTS_HOMEOSTASIS=1 \
        PEBBLELAB_APP_AGENTS_GENETICS=1 PEBBLELAB_APP_AGENTS_SKILLS=1 \
        PEBBLELAB_APP_AGENTS_ECOLOGICAL_OBSERVATION=1 \
        PEBBLELAB_APP_AGENTS_WILD_SUBSISTENCE=1 \
        PEBBLELAB_APP_AGENTS_AUTONOMOUS_CIVILIZATION=1 \
        "$@" "$LIVE_BINARY" > "$EVIDENCE_ROOT/live-$phase.log" 2>&1 &
    pebble_pid=$!
    deadline=$((SECONDS + ${PEBBLELAB_I08_LIVE_TIMEOUT_SECONDS:-14400}))
    while kill -0 "$pebble_pid" 2>/dev/null; do
        if [ "$SECONDS" -ge "$deadline" ]; then
            kill "$pebble_pid" 2>/dev/null || true
            wait "$pebble_pid" 2>/dev/null || true
            printf 'FAIL: live timeout; retained %s\n' "$RUN_HOME" >&2
            exit 1
        fi
        sleep 1
    done
    wait "$pebble_pid"
    rg -q "PS01_INCREMENT_08_LIVE_PASS phase=$phase" "$EVIDENCE_ROOT/live-$phase.log"
}
run_phase write PEBBLE_NEWWORLD=14 \
    PEBBLE_CMD='/lab start founders 24;/lab overlay compact;/lab observer close'
run_phase read PEBBLE_CMD='/lab overlay compact;/lab observer close'
rg -q 'normal continuation restored .*foundersCreated=0 agents=24' "$EVIDENCE_ROOT/live-read.log"
! rg -q 'bootstrap publication' "$EVIDENCE_ROOT/live-read.log"
for name in before-save after-restore continued; do
    [ -s "$EVIDENCE_ROOT/captures/$name.png" ]
done
python3 - "$EVIDENCE_ROOT" <<'PY_VALIDATE'
import pathlib, sys
root = pathlib.Path(sys.argv[1])
records = {}
for phase in ('write', 'read'):
    for line in (root / f'live-{phase}.log').read_text().splitlines():
        if 'PS01_INCREMENT_08_RENDER_READY ' in line or 'PS01_INCREMENT_08_CAPTURE_REQUEST ' in line:
            fields = dict(part.split('=', 1) for part in line.split() if '=' in part)
            records.setdefault(fields['phase'], {}).update(fields)
for name in ('before-save', 'after-restore', 'continued'):
    r = records[name]
    assert r['loadingScreen'] == '0' and r['surfaceNeighborhood'] == '9' and int(r['targetOpaque']) > 0, name
before, restored, continued = (records[name] for name in ('before-save', 'after-restore', 'continued'))
assert before['world'] == restored['world'] == continued['world'], 'World identity'
assert before['simulation'] == restored['simulation'] == continued['simulation'], 'civilization identity'
assert int(restored['tick']) >= int(before['tick']), 'restore boundary'
assert int(continued['tick']) > int(restored['tick']), 'continued civilization progression'
assert int(continued['consumed']) > int(restored['consumed']), 'ordinary post-restore food use'
print('PASS: 8 visual-readiness, identity and post-restore continuity assertions')
PY_VALIDATE
printf 'PASS: two-process ordinary rendered continuation, probesFinal=0; disposable durable runtime retained for evidence inspection: %s\n' "$RUN_HOME"
