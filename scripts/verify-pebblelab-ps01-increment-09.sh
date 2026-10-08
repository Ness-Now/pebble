#!/usr/bin/env bash
set -euo pipefail
[ "${PEBBLE_REGOLD+x}" != x ] || { printf 'PEBBLE_REGOLD must be absent.\n' >&2; exit 1; }
ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
EVIDENCE_ROOT=${1:?Explicit new /tmp evidence directory required}
case "$EVIDENCE_ROOT" in /tmp/*) ;; *) exit 2;; esac
[ ! -e "$EVIDENCE_ROOT/focused-home" ] || {
    printf 'Refusing reused focused test home; provide a new evidence directory.\n' >&2
    exit 1
}
mkdir -p "$EVIDENCE_ROOT"
cd "$ROOT_DIR"
if [ "${PEBBLELAB_I09_SKIP_BUILD:-0}" != 1 ]; then
    swift build -c release --product Pebble 2>&1 | tee "$EVIDENCE_ROOT/build-pebble.log"
    swift build -c release --product pebsmoke 2>&1 | tee "$EVIDENCE_ROOT/build-smoke.log"
fi
BIN_DIR=$(swift build -c release --show-bin-path)
mkdir -p "$EVIDENCE_ROOT/executable"
cp "$BIN_DIR/Pebble" "$BIN_DIR/pebsmoke" "$EVIDENCE_ROOT/executable/"
shasum -a 256 "$EVIDENCE_ROOT/executable/"* > "$EVIDENCE_ROOT/executable.sha256"
mkdir -p "$EVIDENCE_ROOT/focused-home"
CFFIXED_USER_HOME="$EVIDENCE_ROOT/focused-home" PEBBLELAB_SMOKE_ONLY=ps01-increment-09 \
    "$EVIDENCE_ROOT/executable/pebsmoke" 2>&1 | tee "$EVIDENCE_ROOT/focused.log"
run_phase() {
    label=$1 phase=$2 seed=$3
    if [ "$phase" != read ] && [ -e "$EVIDENCE_ROOT/home-$label" ]; then
        printf 'Refusing existing writer home %s\n' "$label" >&2; exit 1
    fi
    mkdir -p "$EVIDENCE_ROOT/home-$label"
    env CFFIXED_USER_HOME="$EVIDENCE_ROOT/home-$label" \
        PEBBLELAB_APP_AGENTS=1 PEBBLELAB_APP_PROBES=1 PEBBLELAB_APP_AGENTS_OBSERVER=1 \
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
        PEBBLELAB_PS01_INCREMENT09_PHASE="$phase" \
        PEBBLELAB_PS01_INCREMENT09_SEED="$seed" \
        PEBBLELAB_PS01_INCREMENT09_OUTPUT="$EVIDENCE_ROOT/$label" \
        "$EVIDENCE_ROOT/executable/Pebble" 2>&1 | tee "$EVIDENCE_ROOT/$label-$phase.log"
}
run_phase positive-a write 14
run_phase positive-a read 14
run_phase positive-b write 14
run_phase positive-b read 14
run_phase pending-plan plan 14
run_phase pending-plan read 14
run_phase scarcity scarcity 46
run_phase scarcity read 46
python3 - "$EVIDENCE_ROOT" <<'PY'
import json, pathlib, sys
r = pathlib.Path(sys.argv[1])
for suffix in ('session.json', 'read.session.json'):
    assert (r/f'positive-a.{suffix}').read_bytes() == (r/f'positive-b.{suffix}').read_bytes(), suffix
for name in ('positive-a', 'positive-b', 'pending-plan.read'):
    d=json.loads((r/f'{name}.json').read_text())
    assert d['births'] >= 1 and d['checkpointSchema'] == 46, name
    assert d['acquired'] == d['consumed'] + d['carried'], name
s=json.loads((r/'scarcity.json').read_text())
assert s['births'] == s['acquired'] == s['consumed'] == s['carried'] == 0
pending=json.loads((r/'pending-plan.session.json').read_text())['lifecycleState']
continued=json.loads((r/'pending-plan.read.session.json').read_text())['lifecycleState']
accepted=next(p for p in pending['plans'] if p['status'] == 'planned')
birth=continued['births'][0]
resolved=next(p for p in continued['plans'] if p['planID'] == accepted['planID'])
assert birth['planID'] == accepted['planID'], 'pending transition identity'
assert birth['progenitorIDs'] == accepted['progenitorIDs'], 'pending canonical parents'
assert resolved['physicalSubsistenceEvidence'] == accepted['physicalSubsistenceEvidence'], 'pinned meals'
assert resolved['createdEventID'] == accepted['createdEventID'], 'accepted event identity'
print('PASS: byte-exact normal deterministic repeats, native births, pending-plan restart and scarcity')
PY
