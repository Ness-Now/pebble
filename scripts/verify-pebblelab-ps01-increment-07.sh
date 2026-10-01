#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
EVIDENCE_ROOT=${1:-/tmp/pebblelab-ps01-increment-07-evidence}

fail() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

mkdir -p "$EVIDENCE_ROOT"
cd "$ROOT_DIR"

if [ "${PEBBLELAB_I07_SKIP_BUILD:-0}" != "1" ]; then
    swift build -c release --product Pebble \
        2>&1 | tee "$EVIDENCE_ROOT/release-pebble-build.log"
    swift build -c release --product pebsmoke \
        2>&1 | tee "$EVIDENCE_ROOT/release-pebsmoke-build.log"
fi

BIN_DIR=$(swift build -c release --show-bin-path)
PEBBLE_BIN="$BIN_DIR/Pebble"
SMOKE_BIN="$BIN_DIR/pebsmoke"
[ -x "$PEBBLE_BIN" ] || fail "release Pebble binary missing"
[ -x "$SMOKE_BIN" ] || fail "release pebsmoke binary missing"

run_normal() {
    run_home=$1
    shift
    mkdir -p "$run_home"
    env \
        CFFIXED_USER_HOME="$run_home" \
        PEBBLELAB_APP_AGENTS=1 \
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
        "$@"
}

printf 'Increment 07 focused deterministic suite.\n'
PEBBLELAB_SMOKE_ONLY=ps01-increment-07-focused \
    "$SMOKE_BIN" 2>&1 | tee "$EVIDENCE_ROOT/focused.log"

printf 'Increment 07 Core-backed navigation adapter and product-chain fixture.\n'
run_normal "$EVIDENCE_ROOT/home-invalid-start" \
    PEBBLELAB_PS01_INCREMENT07_INVALIDSTART=focused \
    "$PEBBLE_BIN" 2>&1 | tee "$EVIDENCE_ROOT/invalid-start-focused.log"

printf 'Increment 07 disposable fault/rollback matrix.\n'
run_normal "$EVIDENCE_ROOT/home-fault" \
    PEBBLELAB_DISPOSABLE_WORLD_PROOF=1 \
    PEBBLELAB_PS01_INCREMENT07_FAULT_MATRIX=1 \
    "$PEBBLE_BIN" 2>&1 | tee "$EVIDENCE_ROOT/fault-matrix.log"

run_primary() {
    run_name=$1
    output="$EVIDENCE_ROOT/primary-$run_name.json"
    run_normal "$EVIDENCE_ROOT/home-primary-$run_name" \
        PEBBLELAB_PS01_INCREMENT07_HEADLESS_CHARACTERIZATION=1 \
        PEBBLELAB_PS01_INCREMENT07_HEADLESS_MODE=characterization \
        PEBBLELAB_PS01_INCREMENT07_HEADLESS_SEED=14 \
        PEBBLELAB_PS01_INCREMENT07_HEADLESS_FOUNDERS=24 \
        PEBBLELAB_PS01_INCREMENT07_HEADLESS_WORLD_TICKS=30000 \
        PEBBLELAB_PS01_INCREMENT07_HEADLESS_OUTPUT="$output" \
        "$PEBBLE_BIN" 2>&1 | tee "$EVIDENCE_ROOT/primary-$run_name.log"
}

printf 'Increment 07 normal 24-founder positive repeat A.\n'
run_primary a
printf 'Increment 07 normal 24-founder positive repeat B.\n'
run_primary b

for scarcity_seed in 46 887; do
    printf 'Increment 07 scarcity control seed %s.\n' "$scarcity_seed"
    run_normal "$EVIDENCE_ROOT/home-scarcity-$scarcity_seed" \
        PEBBLELAB_PS01_INCREMENT07_HEADLESS_CHARACTERIZATION=1 \
        PEBBLELAB_PS01_INCREMENT07_HEADLESS_MODE=scarcity \
        PEBBLELAB_PS01_INCREMENT07_HEADLESS_SEED="$scarcity_seed" \
        PEBBLELAB_PS01_INCREMENT07_HEADLESS_FOUNDERS=24 \
        PEBBLELAB_PS01_INCREMENT07_HEADLESS_WORLD_TICKS=12000 \
        PEBBLELAB_PS01_INCREMENT07_HEADLESS_OUTPUT="$EVIDENCE_ROOT/scarcity-$scarcity_seed.json" \
        "$PEBBLE_BIN" 2>&1 | tee "$EVIDENCE_ROOT/scarcity-$scarcity_seed.log"
done

for founders in 20 24 30; do
    printf 'Increment 07 release performance founders %s.\n' "$founders"
    run_normal "$EVIDENCE_ROOT/home-performance-$founders" \
        PEBBLELAB_PS01_INCREMENT07_HEADLESS_CHARACTERIZATION=1 \
        PEBBLELAB_PS01_INCREMENT07_HEADLESS_MODE=performance \
        PEBBLELAB_PS01_INCREMENT07_HEADLESS_SEED=14 \
        PEBBLELAB_PS01_INCREMENT07_HEADLESS_FOUNDERS="$founders" \
        PEBBLELAB_PS01_INCREMENT07_HEADLESS_WORLD_TICKS=1200 \
        PEBBLELAB_PS01_INCREMENT07_HEADLESS_OUTPUT="$EVIDENCE_ROOT/performance-$founders.json" \
        "$PEBBLE_BIN" 2>&1 | tee "$EVIDENCE_ROOT/performance-$founders.log"
done

printf 'Increment 07 fresh-process restart writer.\n'
RESTART_HOME="$EVIDENCE_ROOT/home-restart"
RESTART_BOUNDARY="$EVIDENCE_ROOT/restart-boundary.json"
run_normal "$RESTART_HOME" \
    PEBBLELAB_PS01_INCREMENT07_RESTART_PHASE=write \
    PEBBLELAB_PS01_INCREMENT07_RESTART_SEED=14 \
    PEBBLELAB_PS01_INCREMENT07_RESTART_BOUNDARY="$RESTART_BOUNDARY" \
    PEBBLELAB_PS01_INCREMENT07_RESTART_OUTPUT="$EVIDENCE_ROOT/restart-write.json" \
    "$PEBBLE_BIN" 2>&1 | tee "$EVIDENCE_ROOT/restart-write.log"

printf 'Increment 07 fresh-process restart reader.\n'
run_normal "$RESTART_HOME" \
    PEBBLELAB_PS01_INCREMENT07_RESTART_PHASE=read \
    PEBBLELAB_PS01_INCREMENT07_RESTART_SEED=14 \
    PEBBLELAB_PS01_INCREMENT07_RESTART_BOUNDARY="$RESTART_BOUNDARY" \
    PEBBLELAB_PS01_INCREMENT07_RESTART_OUTPUT="$EVIDENCE_ROOT/restart-read.json" \
    "$PEBBLE_BIN" 2>&1 | tee "$EVIDENCE_ROOT/restart-read.log"

/usr/bin/python3 - "$EVIDENCE_ROOT" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
a = json.loads((root / "primary-a.json").read_text())
b = json.loads((root / "primary-b.json").read_text())
ra = a["renewableFoodContinuity"]
rb = b["renewableFoodContinuity"]
assert ra["normalProductEntry"] and rb["normalProductEntry"]
assert ra["sameSourceRenewalExact"] and rb["sameSourceRenewalExact"]
assert ra["materialConservationExact"] and rb["materialConservationExact"]
assert a["semanticDigest"] == b["semanticDigest"]
assert a["causalDigest"] == b["causalDigest"]
for key in (
    "targetKey", "firstAcquisitionWorldTick", "firstAcquisitionQuantity",
    "renewedWorldTick", "renewedSourceStage", "secondAcquisitionWorldTick",
    "secondAcquisitionQuantity", "totalSweetBerriesAcquired",
    "totalSweetBerriesConsumed", "totalSweetBerriesCarried",
):
    assert ra[key] == rb[key], key
for seed in (46, 887):
    scarcity = json.loads((root / f"scarcity-{seed}.json").read_text())[
        "scarcityControl"
    ]
    assert not scarcity["fabricatedFood"]
    assert scarcity["observedEdibleBerryEvents"] == 0
    assert scarcity["totalSweetBerriesAcquired"] == 0
    assert scarcity["totalSweetBerriesConsumed"] == 0
    assert scarcity["totalSweetBerriesCarried"] == 0
restart = json.loads((root / "restart-read.json").read_text())
assert not restart["restartCreatedGrowth"]
assert not restart["restartCreatedMaterial"]
assert restart["materialConservationExact"]
assert restart["sameSourceRenewalExact"]
assert restart["worldCleanupSucceeded"]
assert restart["checkpointSchema"] == 45
summary = {
    "determinism": "exact",
    "primaryWorldTicks": a["eligibleWorldTicks"],
    "primarySemanticDigest": a["semanticDigest"],
    "primaryCausalDigest": a["causalDigest"],
    "renewal": ra,
    "restart": restart,
    "performance": {
        str(n): json.loads((root / f"performance-{n}.json").read_text())
        for n in (20, 24, 30)
    },
}
(root / "acceptance-summary.json").write_text(
    json.dumps(summary, indent=2, sort_keys=True) + "\n"
)
PY

printf 'PASS: PS01 Increment 07 deterministic, normal-product, scarcity, performance and restart evidence; root=%s\n' "$EVIDENCE_ROOT"
