#!/usr/bin/env bash

set -u
set -o pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
BASELINE=a673b28b14e9d6c97c8d59cca0fbe47b097410a8
SHORT_SEEDS='46 71 113 197 337'
MEDIUM_SEEDS='509 887 1597'
STRESS_SEEDS='2593 4099'
SHORT_HORIZON=800
MEDIUM_HORIZON=4800
STRESS_HORIZON=6400
MODE=all
REPORT_ONLY=0

usage() {
    cat <<'EOF'
Usage: scripts/verify-pebblelab-gate-b.sh [--short|--medium|--stress|--passive|--report-only]

Runs the fixed Gate B re-evaluation #3 acceptance campaign. Normal mode runs
all ten fixed seeds, seed-509 repeat, seed-887 checkpoint attempt, the rendered
five-minute passive slice, focused regressions, and the canonical full gate.
The command exits zero only for a hard B1-B12 candidate PASS. --report-only
prints the durable repository summary without executing or crediting new runs.
EOF
}

fail() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

if [ "$#" -gt 1 ]; then
    usage >&2
    exit 2
fi
if [ "$#" -eq 1 ]; then
    case "$1" in
        --short) MODE=short ;;
        --medium) MODE=medium ;;
        --stress) MODE=stress ;;
        --passive) MODE=passive ;;
        --report-only) MODE=report; REPORT_ONLY=1 ;;
        --help|-h) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
fi

if [ "${PEBBLE_REGOLD+x}" = x ]; then
    fail "PEBBLE_REGOLD must be absent (an empty value is also refused)."
fi
[ -d "$ROOT_DIR/.git" ] || fail "repository metadata not found at $ROOT_DIR"
cd "$ROOT_DIR"
git merge-base --is-ancestor "$BASELINE" HEAD \
    || fail "published CORR-03 baseline is not an ancestor of HEAD"

HEAD_SHA=$(git rev-parse HEAD)
BRANCH=$(git branch --show-current)
if [ "$REPORT_ONLY" -eq 1 ]; then
    SUMMARY="$ROOT_DIR/docs/pebblelab/GATE_B_REEVALUATION_3_SUMMARY.json"
    [ -f "$SUMMARY" ] || fail "durable Gate B re-evaluation #3 summary is missing"
    python3 -m json.tool "$SUMMARY"
    printf '\nGate B canonically acquired: NO\nCIV-26 started: NO\n'
    exit 0
fi

if [ -n "${PEBBLELAB_GATE_B_EVIDENCE_ROOT:-}" ]; then
    EVIDENCE_ROOT=${PEBBLELAB_GATE_B_EVIDENCE_ROOT%/}
else
    EVIDENCE_ROOT=$(
        mktemp -d "/tmp/PebbleLab-GateB-Reevaluation3-${HEAD_SHA}.XXXXXX"
    )
fi
case "$EVIDENCE_ROOT" in
    /tmp/PebbleLab-GateB-Reevaluation3-*|/private/tmp/PebbleLab-GateB-Reevaluation3-*) ;;
    *) fail "evidence root must be a dedicated Gate B re-evaluation #3 temp path" ;;
esac
mkdir -p \
    "$EVIDENCE_ROOT/short" "$EVIDENCE_ROOT/medium" \
    "$EVIDENCE_ROOT/stress" "$EVIDENCE_ROOT/determinism" \
    "$EVIDENCE_ROOT/checkpoint" "$EVIDENCE_ROOT/passive" \
    "$EVIDENCE_ROOT/focused" "$EVIDENCE_ROOT/summary"

CONFIG_DIGEST=$(
    printf '%s\n' \
        "head=$HEAD_SHA" "short=$SHORT_SEEDS:$SHORT_HORIZON" \
        "medium=$MEDIUM_SEEDS:$MEDIUM_HORIZON" \
        "stress=$STRESS_SEEDS:$STRESS_HORIZON" \
        "randomTickSpeed=3" "cognitiveHz=80" \
        "gates=population,lifecycle,mortality,survival,physical-food,skills,teaching,ecological-observation,agriculture,wild,livestock,care,work,autonomy,movement,material" \
        | shasum -a 256 | awk '{print $1}'
)

cat >"$EVIDENCE_ROOT/configuration.json" <<EOF
{
  "schemaVersion": 3,
  "evaluation": "Gate B Re-evaluation #3",
  "head": "$HEAD_SHA",
  "branch": "$BRANCH",
  "configurationDigest": "$CONFIG_DIGEST",
  "short": {"seeds": [46, 71, 113, 197, 337], "ticks": 800},
  "medium": {"seeds": [509, 887, 1597], "ticks": 4800},
  "stress": {"seeds": [2593, 4099], "ticks": 6400},
  "rerolls": 0,
  "randomTickSpeed": 3,
  "campaignCognitiveHz": 80,
  "postBootstrapProductiveInjection": 0
}
EOF

printf 'Gate B Re-evaluation #3 — Final Self-Sustaining Local Society Candidate Acceptance\n'
printf 'Repository: %s\nBranch: %s\nHEAD: %s\n' "$ROOT_DIR" "$BRANCH" "$HEAD_SHA"
printf 'Evidence root: %s\nConfiguration digest: %s\n' "$EVIDENCE_ROOT" "$CONFIG_DIGEST"
printf 'Goldens: read-only; PEBBLE_REGOLD refused.\n'
printf 'Fixed matrix: short=%s@%s medium=%s@%s stress=%s@%s rerolls=0\n' \
    "$SHORT_SEEDS" "$SHORT_HORIZON" "$MEDIUM_SEEDS" "$MEDIUM_HORIZON" \
    "$STRESS_SEEDS" "$STRESS_HORIZON"

printf '\n[1/5] Building the existing Pebble client and pebsmoke\n'
if ! swift build -c release --product Pebble >"$EVIDENCE_ROOT/build-pebble.log" 2>&1; then
    fail "release Pebble build failed; see $EVIDENCE_ROOT/build-pebble.log"
fi
if ! swift build -c release --product pebsmoke >"$EVIDENCE_ROOT/build-pebsmoke.log" 2>&1; then
    fail "release pebsmoke build failed; see $EVIDENCE_ROOT/build-pebsmoke.log"
fi
PEBBLE_BINARY="$ROOT_DIR/.build/release/Pebble"
[ -x "$PEBBLE_BINARY" ] || fail "release Pebble binary missing"

BASE_COMMANDS='/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/lab start;/lab pause;/lab movement off;/lab population on;/lab lifecycle on;/lab survival on;/lab mortality on;/lab kinship on;/lab household on;/lab care on;/lab skills on;/lab teaching on;/lab settlement on;/lab ecology on;/lab ecological-observation on;/lab work-professions on;/lab physical-food-survival on;/lab autonomous-civilization passive;/lab resume'

run_seed() {
    tier=$1
    seed=$2
    horizon=$3
    label=${4:-$seed}
    destination="$EVIDENCE_ROOT/$tier/$label"
    mkdir -p "$destination/home"
    trace="$destination/pebble-live.log"
    result="$destination/result.json"
    world_name="PebbleLab-Disposable-GateB3-${tier}-${label}"
    shock=
    if [ "$seed" = "2593" ]; then shock=worker-care; fi
    if [ "$seed" = "4099" ]; then shock=tool-feed; fi
    started=$(date +%s)
    printf '  %-12s seed=%-4s horizon=%-4s ... ' "$tier" "$seed" "$horizon"
    (
        CFFIXED_USER_HOME="$destination/home" \
        PEBBLE_AUTOLOAD=1 \
        PEBBLE_NEWWORLD="$seed" \
        PEBBLE_NEWWORLD_NAME="$world_name" \
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
        PEBBLELAB_GATE_B3_COGNITIVE_HZ=80 \
        PEBBLELAB_GATE_B3_HORIZON="$horizon" \
        PEBBLELAB_GATE_B3_RANDOM_TICK_SPEED=3 \
        PEBBLELAB_GATE_B3_SHOCK="$shock" \
        PEBBLE_CMD="$BASE_COMMANDS" \
        "$PEBBLE_BINARY"
    ) >"$trace" 2>&1
    app_exit=$?
    elapsed=$(( $(date +%s) - started ))
    python3 "$SCRIPT_DIR/gate_b3_evidence.py" run \
        --head "$HEAD_SHA" --seed "$seed" --tier "$tier" \
        --horizon "$horizon" --label "$label" \
        --configuration-digest "$CONFIG_DIGEST" \
        --elapsed-seconds "$elapsed" --app-exit "$app_exit" \
        --log "$trace" --output "$result"
    disposition=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["result"])' "$result")
    reached=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["ticksReached"])' "$result")
    reason=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["primaryFailure"])' "$result")
    printf '%s tick=%s reason=%s\n' "$disposition" "$reached" "$reason"
}

printf '\n[2/5] Fixed integrated campaign (ordinary failures do not stop later seeds)\n'
if [ "$MODE" = all ] || [ "$MODE" = short ]; then
    for seed in $SHORT_SEEDS; do run_seed short "$seed" "$SHORT_HORIZON"; done
fi
if [ "$MODE" = all ] || [ "$MODE" = medium ]; then
    for seed in $MEDIUM_SEEDS; do run_seed medium "$seed" "$MEDIUM_HORIZON"; done
    run_seed determinism 509 "$MEDIUM_HORIZON" 509-repeat
fi
if [ "$MODE" = all ] || [ "$MODE" = stress ]; then
    for seed in $STRESS_SEEDS; do run_seed stress "$seed" "$STRESS_HORIZON"; done
fi

run_passive() {
    destination="$EVIDENCE_ROOT/passive"
    mkdir -p "$destination/home" "$destination/captures"
    trace="$destination/pebble-live.log"
    commands='/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/tp 14 68 -18;/lab start;/lab pause;/lab movement off;/lab population on;/lab lifecycle on;/lab survival on;/lab mortality on;/lab kinship on;/lab household on;/lab care on;/lab skills on;/lab teaching on;/lab settlement on;/lab ecology on;/lab ecological-observation on;/lab work-professions on;/lab physical-food-survival on;/tp 24.5 68 -11.5 150 12;/lab focus agent_0;/lab follow off;/lab overlay off;/lab autonomous-civilization passive;/lab resume'
    started=$(date +%s)
    printf '  passive     seed=46 wallTarget=300s ... '
    (
        CFFIXED_USER_HOME="$destination/home" \
        PEBBLE_AUTOLOAD=1 \
        PEBBLE_NEWWORLD=46 \
        PEBBLE_NEWWORLD_NAME=PebbleLab-Disposable-GateB-Reevaluation3-46 \
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
        PEBBLELAB_PASSIVE_OBSERVER_INPUT_PROOF=1 \
        PEBBLELAB_PASSIVE_OBSERVER_BATCH_FRAMES=7200 \
        PEBBLELAB_DISPOSABLE_WORLD_PROOF=1 \
        PEBBLELAB_GATE_B3_ACCEPTANCE=1 \
        PEBBLELAB_GATE_B3_COGNITIVE_HZ=4 \
        PEBBLELAB_GATE_B3_RANDOM_TICK_SPEED=3 \
        PEBBLELAB_GATE_B3_PASSIVE=1 \
        PEBBLELAB_GATE_B3_PASSIVE_SECONDS=300 \
        PEBBLELAB_GATE_B3_PASSIVE_CAPTURE_DIR="$destination/captures" \
        PEBBLE_CMD="$commands" \
        PEBBLE_SHOT="$destination/captures/fallback.png@999999" \
        "$PEBBLE_BINARY"
    ) >"$trace" 2>&1
    app_exit=$?
    elapsed=$(( $(date +%s) - started ))
    python3 "$SCRIPT_DIR/gate_b3_evidence.py" passive \
        --head "$HEAD_SHA" --elapsed-seconds "$elapsed" \
        --app-exit "$app_exit" --log "$trace" \
        --capture-directory "$destination/captures" \
        --output "$destination/result.json"
    disposition=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["result"])' "$destination/result.json")
    reason=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["primaryFailure"])' "$destination/result.json")
    printf '%s elapsed=%ss reason=%s\n' "$disposition" "$elapsed" "$reason"
}

if [ "$MODE" = all ] || [ "$MODE" = passive ]; then
    printf '\n[3/5] Five-minute rendered passive observer slice\n'
    run_passive
fi

if [ "$MODE" = all ]; then
    printf '\n[4/5] Focused and canonical regression evidence\n'
    FOCUSED_SELECTORS='physical-food-survival autonomous-civilization integrated-teaching-initiation teaching agriculture wild-subsistence livestock dependent-care work-professions skills checkpoint-replay embodiment'
    : >"$EVIDENCE_ROOT/focused/results.tsv"
    for selector in $FOCUSED_SELECTORS; do
        output="$EVIDENCE_ROOT/focused/$selector.log"
        if PEBBLELAB_SMOKE_ONLY="$selector" \
            swift run -c release --skip-build pebsmoke >"$output" 2>&1; then
            count=$(sed -n 's/^\([0-9][0-9]*\) passed, 0 failed$/\1/p' "$output" | tail -n 1)
            if [ -n "$count" ]; then
                printf '%s\t%s\t0\t0\n' "$selector" "$count" >>"$EVIDENCE_ROOT/focused/results.tsv"
                printf '  %-34s %s passed, 0 failed\n' "$selector" "$count"
            else
                printf '%s\t0\t1\t1\n' "$selector" >>"$EVIDENCE_ROOT/focused/results.tsv"
                printf '  %-34s malformed result\n' "$selector"
            fi
        else
            code=$?
            printf '%s\t0\t1\t%s\n' "$selector" "$code" >>"$EVIDENCE_ROOT/focused/results.tsv"
            printf '  %-34s FAIL exit=%s\n' "$selector" "$code"
        fi
    done
    if scripts/verify-pebblelab.sh >"$EVIDENCE_ROOT/full-gate.log" 2>&1; then
        FULL_GATE_EXIT=0
    else
        FULL_GATE_EXIT=$?
    fi
    full_gate_summary=$(grep -E '35/35|[0-9]+ passed, 0 failed' "$EVIDENCE_ROOT/full-gate.log" | tail -n 2 | tr '\n' ';')
    printf '  full gate exit=%s %s\n' "$FULL_GATE_EXIT" "$full_gate_summary"
fi

printf '\n[5/5] Hard aggregation (no averaging)\n'
python3 "$SCRIPT_DIR/gate_b3_evidence.py" aggregate \
    --head "$HEAD_SHA" --root "$EVIDENCE_ROOT" \
    --configuration-digest "$CONFIG_DIGEST" \
    --output "$EVIDENCE_ROOT/summary/gate-b3-summary.json"
python3 -m json.tool "$EVIDENCE_ROOT/summary/gate-b3-summary.json"

CANDIDATE=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["candidateResult"])' \
    "$EVIDENCE_ROOT/summary/gate-b3-summary.json")
printf '\nGATE B CANDIDATE RESULT: %s\n' "$CANDIDATE"
printf 'Gate R: ACQUIRED\nGate B canonically acquired: NO\nCIV-26 started: NO\n'
printf 'Evidence root: %s\n' "$EVIDENCE_ROOT"
if [ "$CANDIDATE" = PASS ]; then exit 0; fi
exit 2
