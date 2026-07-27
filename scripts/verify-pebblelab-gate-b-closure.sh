#!/usr/bin/env bash

set -u
set -o pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
BRANCH=lab/gate-b-economic-renewal-v1
FOUNDATION=780d59d04b0e2b943cde2a9a4b39c9f93496ebe5
MODE=${1:---pre-soak}

fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

[ "${PEBBLE_REGOLD+x}" != x ] || fail "PEBBLE_REGOLD must be absent"
[ "$(git -C "$ROOT_DIR" rev-parse --show-toplevel)" = "$ROOT_DIR" ] \
    || fail "unexpected repository root"
[ "$(git -C "$ROOT_DIR" branch --show-current)" = "$BRANCH" ] \
    || fail "unexpected branch"
[ "$(git -C "$ROOT_DIR" rev-parse origin/lab/pebblelab-v1)" = "$FOUNDATION" ] \
    || fail "published foundation changed"
[ -z "$(git -C "$ROOT_DIR" status --short)" ] || fail "working tree is not clean"

HEAD_SHA=$(git -C "$ROOT_DIR" rev-parse HEAD)
ROOT=${PEBBLELAB_GATE_B_CLOSURE_ROOT:-"/tmp/PebbleLab-GateB-Closure01-$HEAD_SHA"}
case "$ROOT" in
    /tmp/PebbleLab-GateB-Closure01-"$HEAD_SHA"|\
    /private/tmp/PebbleLab-GateB-Closure01-"$HEAD_SHA") ;;
    *) fail "evidence root must be bound to evaluated HEAD" ;;
esac
mkdir -p "$ROOT/summary"

if [ "$MODE" = --self-test ]; then
    python3 "$SCRIPT_DIR/gate_b_closure_evidence.py" self-test
    exit
fi

BASE_COMMANDS='/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/lab start;/lab pause;/lab movement off;/lab population on;/lab lifecycle on;/lab survival on;/lab mortality on;/lab kinship on;/lab household on;/lab care on;/lab skills on;/lab teaching on;/lab settlement on;/lab ecology on;/lab ecological-observation on;/lab work-professions on;/lab physical-food-survival on;/lab autonomous-civilization passive;/lab resume'
PEBBLE_BINARY="$ROOT_DIR/.build/release/Pebble"

run_case() {
    label=$1
    seed=$2
    horizon=$3
    shock=${4:-}
    destination="$ROOT/$label"
    [ ! -e "$destination" ] || fail "reroll refused: $label"
    mkdir -p "$destination/home"
    trace="$destination/pebble-live.log"
    (
        CFFIXED_USER_HOME="$destination/home" \
        PEBBLE_AUTOLOAD=1 \
        PEBBLE_NEWWORLD="$seed" \
        PEBBLE_NEWWORLD_NAME="PebbleLab-Disposable-GateBClosure-$label" \
        PEBBLELAB_APP_AGENTS=1 \
        PEBBLELAB_APP_AGENTS_TRACE=1 \
        PEBBLELAB_APP_AGENTS_TRACE_EVERY=400 \
        PEBBLELAB_APP_AGENTS_OVERLAY=0 \
        PEBBLELAB_APP_AGENTS_MOVE=1 \
        PEBBLELAB_APP_PROBES=1 \
        PEBBLELAB_DEBUG_ENTITIES=1 \
        PEBBLELAB_APP_AGENTS_INTERACT=1 \
        PEBBLELAB_APP_AGENTS_MATERIAL=1 \
        PEBBLELAB_APP_AGENTS_PERSISTENCE=1 \
        PEBBLELAB_APP_AGENTS_POPULATION=1 \
        PEBBLELAB_APP_AGENTS_MULTISCALE=1 \
        PEBBLELAB_APP_AGENTS_ECOLOGY=1 \
        PEBBLELAB_APP_AGENTS_MORTALITY=1 \
        PEBBLELAB_APP_AGENTS_LIFECYCLE=1 \
        PEBBLELAB_APP_AGENTS_KINSHIP=1 \
        PEBBLELAB_APP_AGENTS_HOUSEHOLDS=1 \
        PEBBLELAB_APP_AGENTS_CARE=1 \
        PEBBLELAB_APP_AGENTS_SKILLS=1 \
        PEBBLELAB_APP_AGENTS_TEACHING=1 \
        PEBBLELAB_APP_AGENTS_ECOLOGICAL_OBSERVATION=1 \
        PEBBLELAB_APP_AGENTS_AGRICULTURE=1 \
        PEBBLELAB_APP_AGENTS_WILD_SUBSISTENCE=1 \
        PEBBLELAB_APP_AGENTS_LIVESTOCK=1 \
        PEBBLELAB_APP_AGENTS_WORK_PROFESSIONS=1 \
        PEBBLELAB_APP_AGENTS_AUTONOMOUS_CIVILIZATION=1 \
        PEBBLELAB_INTEGRATED_TEACHING_PROOF=1 \
        PEBBLELAB_DISPOSABLE_WORLD_PROOF=1 \
        PEBBLELAB_GATE_B3_ACCEPTANCE=1 \
        PEBBLELAB_GATE_B_CONVERGENCE=1 \
        PEBBLELAB_GATE_B3_COGNITIVE_HZ=80 \
        PEBBLELAB_GATE_B3_HORIZON="$horizon" \
        PEBBLELAB_GATE_B3_RANDOM_TICK_SPEED=3 \
        PEBBLELAB_GATE_B3_SHOCK="$shock" \
        PEBBLELAB_GATE_B3_INTERVENTION_TICK=400 \
        PEBBLELAB_GATE_B3_SKIP_CHECKPOINT=1 \
        PEBBLE_CMD="$BASE_COMMANDS" \
        /usr/bin/perl -e '
            $SIG{ALRM}=sub{die "GATE_B_CLOSURE_TIMEOUT\n"};
            alarm shift; exec @ARGV or die "exec failed: $!";
        ' 360 "$PEBBLE_BINARY"
    ) >"$trace" 2>&1
    app_exit=$?
    extra=
    [ -z "$shock" ] || extra=--reactivation
    python3 "$SCRIPT_DIR/gate_b_closure_evidence.py" run \
        --log "$trace" --seed "$seed" --horizon "$horizon" \
        --app-exit "$app_exit" --output "$destination/result.json" $extra
}

if [ "$MODE" = --summary ]; then
    python3 - "$ROOT" <<'PY'
import json, sys
from pathlib import Path
root = Path(sys.argv[1])
labels = ("seed-46", "seed-71", "seed-887", "material-reactivation")
results = {}
for label in labels:
    path = root / label / "result.json"
    results[label] = json.loads(path.read_text()) if path.exists() else {
        "classification": "NOT_RUN", "gateBResult": "FAIL"
    }
passes = all(value["gateBResult"] == "PASS" for value in results.values())
domains = set()
for value in results.values():
    for part in value.get("exercisedDomains", "").split(","):
        if ":" in part and int(part.rsplit(":", 1)[1]) > 0:
            domains.add(part.rsplit(":", 1)[0])
summary = {
    "schemaVersion": 1,
    "campaignResult": "PASS" if passes and len(domains) >= 2 else "FAIL",
    "readinessVerdict": (
        "GATE B CLOSURE CANDIDATE"
        if passes and len(domains) >= 2 else "CORRECTIONS REQUIRED"
    ),
    "exercisedDomains": sorted(domains),
    "results": results,
}
(root / "summary" / "result.json").write_text(
    json.dumps(summary, indent=2, sort_keys=True) + "\n"
)
print(summary["readinessVerdict"])
PY
    exit
fi

swift build -c release --product Pebble \
    >"$ROOT/summary/build.log" 2>&1 || fail "Pebble build failed"
if [ "$MODE" = --reactivation ]; then
    run_case material-reactivation 46 600 material-reactivation-berry
    exit
fi
[ "$MODE" = --pre-soak ] || fail "unknown mode: $MODE"
for seed in 46 71 887; do
    run_case "seed-$seed" "$seed" 800
    result=$(python3 -c \
        'import json,sys; print(json.load(open(sys.argv[1]))["gateBResult"])' \
        "$ROOT/seed-$seed/result.json")
    [ "$result" = PASS ] || break
done
