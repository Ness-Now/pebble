#!/usr/bin/env bash
set -euo pipefail
[ "${PEBBLE_REGOLD+x}" != x ] || { printf 'PEBBLE_REGOLD must be absent.\n' >&2; exit 1; }
ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
EVIDENCE_ROOT=${1:-/tmp/pebblelab-ps01-increment-08-evidence}
case "$EVIDENCE_ROOT" in /tmp/*|/private/tmp/*) ;; *) printf 'Evidence root must be under /tmp.\n' >&2; exit 2;; esac
mkdir -p "$EVIDENCE_ROOT"
cd "$ROOT_DIR"
if [ "${PEBBLELAB_I08_SKIP_BUILD:-0}" != "1" ]; then
    swift build -c release --product Pebble 2>&1 | tee "$EVIDENCE_ROOT/build-pebble.log"
    swift build -c release --product pebsmoke 2>&1 | tee "$EVIDENCE_ROOT/build-smoke.log"
fi
BIN_DIR=$(swift build -c release --show-bin-path)
mkdir -p "$EVIDENCE_ROOT/executable"
cp "$BIN_DIR/Pebble" "$EVIDENCE_ROOT/executable/Pebble"
cp "$BIN_DIR/pebsmoke" "$EVIDENCE_ROOT/executable/pebsmoke"
BIN_DIR="$EVIDENCE_ROOT/executable"
shasum -a 256 "$BIN_DIR/Pebble" "$BIN_DIR/pebsmoke" > "$EVIDENCE_ROOT/executable.sha256"
run_normal() {
    run_home=$1
    shift
    mkdir -p "$run_home"
    env CFFIXED_USER_HOME="$run_home" \
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
        PEBBLELAB_APP_AGENTS_AUTONOMOUS_CIVILIZATION=1 "$@"
}
mkdir -p "$EVIDENCE_ROOT/core-home"
CFFIXED_USER_HOME="$EVIDENCE_ROOT/core-home" PEBBLELAB_SMOKE_ONLY=ps01-increment-08 "$BIN_DIR/pebsmoke" 2>&1 | tee "$EVIDENCE_ROOT/core-focused.log"
run_phase() {
    label=$1 phase=$2 seed=$3 founders=$4
    if [ "$phase" != read ] && [ -e "$EVIDENCE_ROOT/home-$label" ]; then
        printf 'Refusing existing writer runtime: %s\n' "$EVIDENCE_ROOT/home-$label" >&2
        exit 1
    fi
    run_normal "$EVIDENCE_ROOT/home-$label" \
        PEBBLELAB_PS01_INCREMENT08_PHASE="$phase" \
        PEBBLELAB_PS01_INCREMENT08_SEED="$seed" \
        PEBBLELAB_PS01_INCREMENT08_FOUNDERS="$founders" \
        PEBBLELAB_PS01_INCREMENT08_OUTPUT="$EVIDENCE_ROOT/$label.json" \
        "$BIN_DIR/Pebble" 2>&1 | tee "$EVIDENCE_ROOT/$label-$phase.log"
}
run_phase faults faults 46 24
for count in 20 30; do
    run_phase "envelope-$count" envelope 46 "$count"
    run_phase "envelope-$count" read 46 "$count"
done
for label in deterministic-a deterministic-b; do
    run_phase "$label" envelope 46 24
    run_phase "$label" read 46 24
done
for label in retention retention-manual; do
    run_phase "$label" "$label" 46 24
    run_phase "$label" read 46 24
done
for label in positive scarcity; do
    seed=14
    [ "$label" != scarcity ] || seed=46
    run_phase "$label" write "$seed" 24
    run_phase "$label" read "$seed" 24
done
run_phase zero zero 46 24
run_phase zero read 46 24
python3 - "$EVIDENCE_ROOT" <<'PY_COMPARE'
import json, pathlib, sys
root=pathlib.Path(sys.argv[1])
a=json.loads((root/'deterministic-a.json').read_text())
b=json.loads((root/'deterministic-b.json').read_text())
assert a == b, 'normal physical/civilization boundary differs across deterministic repeats'
ra=json.loads((root/'deterministic-a.json.read.json').read_text())
rb=json.loads((root/'deterministic-b.json.read.json').read_text())
assert ra == rb, 'continued state differs across repeats'
print('PASS: exact paired boundary and post-restart deterministic repeat')
PY_COMPARE
printf 'PASS: PS01 Increment 08 bounded headless/product continuation campaign.\n'
