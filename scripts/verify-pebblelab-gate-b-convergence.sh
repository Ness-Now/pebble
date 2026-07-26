#!/usr/bin/env bash

set -u
set -o pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
BASELINE=eaed4ce1d0a8c151316ddd84e8076813b3079c94
FIXED_SEEDS='46 71 113 197 337 509 887 1597 2593 4099'
MEDIUM_SEEDS='509 887 1597'
STRESS_SEEDS='2593 4099'
MODE=all

usage() {
    printf '%s\n' \
        'Usage: scripts/verify-pebblelab-gate-b-convergence.sh [mode]' \
        '' \
        'Modes: --all (default), --wave0, --wave1, --wave2, --wave3,' \
        '       --determinism, --checkpoint, --stress, --live,' \
        '       --canonical, --summary' \
        '' \
        'This is a progressive convergence probe, never Gate B acceptance.'
}

fail() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

assert_final_state() {
    [ "$(git branch --show-current)" = "$BRANCH" ] \
        || fail "branch changed during convergence campaign"
    [ "$(git rev-parse HEAD)" = "$HEAD_SHA" ] \
        || fail "HEAD changed during convergence campaign"
    [ -z "$(git status --short)" ] \
        || fail "working tree changed during convergence campaign"
    [ -z "$(git diff "$BASELINE"..HEAD --name-only -- Sources/PebbleCore)" ] \
        || fail "PebbleCore changed during convergence campaign"
}

if [ "$#" -gt 1 ]; then usage >&2; exit 2; fi
if [ "$#" -eq 1 ]; then
    case "$1" in
        --all) MODE=all ;;
        --wave0) MODE=wave0 ;;
        --wave1) MODE=wave1 ;;
        --wave2) MODE=wave2 ;;
        --wave3) MODE=wave3 ;;
        --determinism) MODE=determinism ;;
        --checkpoint) MODE=checkpoint ;;
        --stress) MODE=stress ;;
        --live) MODE=live ;;
        --canonical) MODE=canonical ;;
        --summary) MODE=summary ;;
        --help|-h) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
fi

if [ "${PEBBLE_REGOLD+x}" = x ]; then
    fail "PEBBLE_REGOLD must be absent (an empty value is also refused)."
fi
[ -d "$ROOT_DIR/.git" ] || fail "repository metadata not found at $ROOT_DIR"
cd "$ROOT_DIR"

BRANCH=$(git branch --show-current)
HEAD_SHA=$(git rev-parse HEAD)
REMOTE_SHA=$(git ls-remote origin refs/heads/lab/pebblelab-v1 | awk '{print $1}')
[ "$BRANCH" = lab/pebblelab-v1 ] || fail "expected lab/pebblelab-v1, got $BRANCH"
[ "$REMOTE_SHA" = "$BASELINE" ] \
    || fail "canonical remote changed unexpectedly: $REMOTE_SHA"
git merge-base --is-ancestor "$BASELINE" HEAD \
    || fail "canonical Gate B re-evaluation #4 baseline is not an ancestor"
assert_final_state

EVIDENCE_ROOT=${PEBBLELAB_GATE_B_CONVERGENCE_ROOT:-"/tmp/PebbleLab-GateB-Convergence01-${HEAD_SHA}"}
case "$EVIDENCE_ROOT" in
    /tmp/PebbleLab-GateB-Convergence01-"$HEAD_SHA"|\
    /private/tmp/PebbleLab-GateB-Convergence01-"$HEAD_SHA") ;;
    *) fail "evidence root must be /tmp/PebbleLab-GateB-Convergence01-<HEAD>" ;;
esac
mkdir -p \
    "$EVIDENCE_ROOT/focused" "$EVIDENCE_ROOT/wave1-128" \
    "$EVIDENCE_ROOT/wave2-800" "$EVIDENCE_ROOT/wave3-2400" \
    "$EVIDENCE_ROOT/determinism" "$EVIDENCE_ROOT/checkpoint" \
    "$EVIDENCE_ROOT/stress" "$EVIDENCE_ROOT/live" "$EVIDENCE_ROOT/summary"

CONFIG_DIGEST=$(
    printf '%s\n' \
        "head=$HEAD_SHA" "fixed=$FIXED_SEEDS" \
        "wave1=128" "wave2=800" "wave3=$MEDIUM_SEEDS:2400" \
        "determinism=509:1600x2" "checkpoint=887:1200>2400" \
        "stress=$STRESS_SEEDS:3200>3600" "live=120" \
        "randomTickSpeed=3" "cognitiveHz=80" \
        "roleNeutral=1" "productiveCommands=0" "rerolls=0" \
        | shasum -a 256 | awk '{print $1}'
)

python3 - "$EVIDENCE_ROOT/configuration.json" "$HEAD_SHA" "$BRANCH" \
    "$REMOTE_SHA" "$CONFIG_DIGEST" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
value = {
    "schemaVersion": 1,
    "mission": "GATE-B-CONVERGENCE-01",
    "head": sys.argv[2],
    "branch": sys.argv[3],
    "remoteAtLaunch": sys.argv[4],
    "configurationDigest": sys.argv[5],
    "fixedSeeds": [46, 71, 113, 197, 337, 509, 887, 1597, 2593, 4099],
    "waves": {
        "wave1": {"ticks": 128},
        "wave2": {"ticks": 800},
        "wave3": {"seeds": [509, 887, 1597], "ticks": 2400},
        "determinism": {"seed": 509, "ticks": 1600, "runs": 2},
        "checkpoint": {"seed": 887, "saveTick": 1200, "ticks": 2400},
        "stress": {"seeds": [2593, 4099], "shockTick": 3200, "ticks": 3600},
        "live": {"seconds": 120},
    },
    "randomTickSpeed": 3,
    "campaignCognitiveHz": 80,
    "rerolls": 0,
    "postBootstrapProductiveCommands": 0,
    "gateBCanonicallyAcquired": False,
    "civ26Started": False,
}
if path.exists():
    prior = json.loads(path.read_text())
    if (
        prior.get("head") != value["head"]
        or prior.get("configurationDigest") != value["configurationDigest"]
    ):
        raise SystemExit("existing evidence root has another HEAD/configuration")
else:
    temporary = path.with_suffix(".tmp")
    temporary.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n")
    temporary.replace(path)
PY
[ "$?" -eq 0 ] || fail "evidence configuration refused"

printf 'GATE-B-CONVERGENCE-01 — progressive integration stabilization\n'
printf 'Repository: %s\nBranch: %s\nHEAD: %s\nRemote: %s\n' \
    "$ROOT_DIR" "$BRANCH" "$HEAD_SHA" "$REMOTE_SHA"
printf 'Evidence root: %s\nConfiguration digest: %s\n' \
    "$EVIDENCE_ROOT" "$CONFIG_DIGEST"
printf 'Gate B credit: NONE; CIV-26: NOT STARTED; rerolls: 0\n'

if [ "$MODE" != summary ]; then
    assert_final_state
    printf '\n[build] Release Pebble and pebsmoke\n'
    swift build -c release --product Pebble \
        >"$EVIDENCE_ROOT/summary/build-pebble.log" 2>&1 \
        || fail "release Pebble build failed"
    swift build -c release --product pebsmoke \
        >"$EVIDENCE_ROOT/summary/build-pebsmoke.log" 2>&1 \
        || fail "release pebsmoke build failed"
    assert_final_state
fi
PEBBLE_BINARY="$ROOT_DIR/.build/release/Pebble"
[ "$MODE" = summary ] || [ -x "$PEBBLE_BINARY" ] \
    || fail "release Pebble binary missing"

BASE_COMMANDS='/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/lab start;/lab pause;/lab movement off;/lab population on;/lab lifecycle on;/lab survival on;/lab mortality on;/lab kinship on;/lab household on;/lab care on;/lab skills on;/lab teaching on;/lab settlement on;/lab ecology on;/lab ecological-observation on;/lab work-professions on;/lab physical-food-survival on;/lab autonomous-civilization passive;/lab resume'

next_attempt() {
    destination=$1
    mkdir -p "$destination"
    count=$(find "$destination" -maxdepth 1 -type d -name 'attempt-*' | wc -l | tr -d ' ')
    [ "$count" -eq 0 ] || return 1
    printf 'attempt-0001'
}

run_seed() {
    wave=$1
    seed=$2
    horizon=$3
    label=$4
    checkpoint=${5:-0}
    shock=${6:-}
    destination="$EVIDENCE_ROOT/$wave/$label"
    assert_final_state
    attempt=$(next_attempt "$destination") \
        || fail "reroll refused for $wave/$label on this HEAD"
    destination="$destination/$attempt"
    mkdir -p "$destination/home"
    trace="$destination/pebble-live.log"
    base_result="$destination/base-result.json"
    result="$destination/result.json"
    world_label=$label
    if [ "$wave" = determinism ]; then
        world_label=seed-509-identical
    fi
    world_name="PebbleLab-Disposable-Convergence01-${wave}-${world_label}-${attempt}"
    timeout_seconds=$((horizon / 8 + 180))
    [ "$timeout_seconds" -ge 240 ] || timeout_seconds=240
    started=$(date +%s)
    printf '  %-16s seed=%-4s horizon=%-4s %s ... ' \
        "$wave" "$seed" "$horizon" "$attempt"
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
        PEBBLELAB_GATE_B_CONVERGENCE=1 \
        PEBBLELAB_GATE_B3_COGNITIVE_HZ=80 \
        PEBBLELAB_GATE_B3_HORIZON="$horizon" \
        PEBBLELAB_GATE_B3_RANDOM_TICK_SPEED=3 \
        PEBBLELAB_GATE_B3_SHOCK="$shock" \
        PEBBLELAB_GATE_B3_INTERVENTION_TICK=3200 \
        PEBBLELAB_GATE_B3_SKIP_CHECKPOINT="$([ "$checkpoint" = 1 ] && printf 0 || printf 1)" \
        PEBBLE_CMD="$BASE_COMMANDS" \
        /usr/bin/perl -e '
            $seconds = shift;
            $SIG{ALRM} = sub { die "GATE_B_CONVERGENCE_TIMEOUT\n" };
            alarm $seconds;
            exec @ARGV or die "exec failed: $!";
        ' "$timeout_seconds" "$PEBBLE_BINARY"
    ) >"$trace" 2>&1
    app_exit=$?
    elapsed=$(( $(date +%s) - started ))
    python3 "$SCRIPT_DIR/gate_b4_evidence.py" run \
        --head "$HEAD_SHA" --seed "$seed" --tier "$wave" \
        --horizon "$horizon" --label "$label" \
        --configuration-digest "$CONFIG_DIGEST" \
        --elapsed-seconds "$elapsed" --app-exit "$app_exit" \
        --log "$trace" --output "$base_result"
    python3 "$SCRIPT_DIR/gate_b_convergence_evidence.py" run \
        --base-result "$base_result" --log "$trace" --output "$result" \
        --wave "$wave" --head "$HEAD_SHA" --seed "$seed" \
        --horizon "$horizon" --configuration-digest "$CONFIG_DIGEST"
    disposition=$(python3 -c \
        'import json,sys; print(json.load(open(sys.argv[1]))["convergenceResult"])' \
        "$result")
    reached=$(python3 -c \
        'import json,sys; print(json.load(open(sys.argv[1]))["ticksReached"])' \
        "$result")
    reason=$(python3 -c \
        'import json,sys; value=json.load(open(sys.argv[1])); print(value.get("primaryFailure","none"))' \
        "$result")
    printf '%s tick=%s elapsed=%ss reason=%s\n' \
        "$disposition" "$reached" "$elapsed" "$reason"
    assert_final_state
}

wave_passes() {
    directory=$1
    shift
    python3 - "$EVIDENCE_ROOT/$directory" "$@" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
labels = sys.argv[2:]
for label in labels:
    values = sorted((root / label).glob("attempt-*/result.json"))
    if len(values) != 1:
        raise SystemExit(1)
    result = json.loads(values[0].read_text())
    if result.get("convergenceResult") != "PASS":
        raise SystemExit(1)
PY
}

determinism_passes() {
    python3 - "$EVIDENCE_ROOT/determinism" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
results = []
for label in ("seed-509-a", "seed-509-b"):
    paths = sorted((root / label).glob("attempt-*/result.json"))
    if len(paths) != 1:
        raise SystemExit(1)
    value = json.loads(paths[0].read_text())
    if value.get("convergenceResult") != "PASS":
        raise SystemExit(1)
    results.append(value)
required = {
    "tick", "durable", "population", "agentCount", "alive",
    "positionsHome", "activities", "materialCustody", "food",
    "agriculture", "livestock", "care", "teaching", "work", "skills",
    "causal", "causalSequence", "worldEntities", "semanticDigest",
    "worldEntityDigest",
}
left = results[0].get("semanticState", {})
right = results[1].get("semanticState", {})
raise SystemExit(0 if required <= left.keys() and left == right else 1)
PY
}

run_focused() {
    selectors='bounded-autonomous-navigation role-neutral-society-bootstrap autonomous-civilization embodiment work-demand-refresh work-professions agriculture wild-subsistence livestock dependent-care integrated-teaching-initiation teaching physical-food-survival checkpoint-replay skills materials ecological-observation'
    assert_final_state
    [ ! -e "$EVIDENCE_ROOT/focused/results.tsv" ] \
        || fail "reroll refused for Wave 0 on this HEAD"
    : >"$EVIDENCE_ROOT/focused/results.tsv"
    for selector in $selectors; do
        output="$EVIDENCE_ROOT/focused/$selector.log"
        if PEBBLELAB_SMOKE_ONLY="$selector" \
            swift run -c release --skip-build pebsmoke >"$output" 2>&1; then
            count=$(sed -n \
                's/^\([0-9][0-9]*\) passed, 0 failed$/\1/p' \
                "$output" | tail -n 1)
            if [ -n "$count" ]; then
                printf '%s\t%s\t0\t0\n' "$selector" "$count" \
                    >>"$EVIDENCE_ROOT/focused/results.tsv"
                printf '  %-38s %s passed, 0 failed\n' "$selector" "$count"
            else
                printf '%s\t0\t1\t1\n' "$selector" \
                    >>"$EVIDENCE_ROOT/focused/results.tsv"
                printf '  %-38s malformed result\n' "$selector"
            fi
        else
            code=$?
            printf '%s\t0\t1\t%s\n' "$selector" "$code" \
                >>"$EVIDENCE_ROOT/focused/results.tsv"
            printf '  %-38s FAIL exit=%s\n' "$selector" "$code"
        fi
    done
    python3 - "$EVIDENCE_ROOT/focused/results.tsv" <<'PY'
import sys
from pathlib import Path

lines = Path(sys.argv[1]).read_text().splitlines()
raise SystemExit(0 if len(lines) == 17 and all(
    line.split("\t")[2:] == ["0", "0"] for line in lines
) else 1)
PY
    result=$?
    assert_final_state
    return "$result"
}

run_live() {
    live_root="$EVIDENCE_ROOT/live/client"
    assert_final_state
    [ ! -e "$EVIDENCE_ROOT/live/dry-run.log" ] \
        || fail "reroll refused for live dry-run on this HEAD"
    scripts/verify-pebblelab-live.sh --dry-run --gate-b-passive \
        >"$EVIDENCE_ROOT/live/dry-run.log" 2>&1 \
        || fail "mandatory live dry-run failed"
    attempt=$(next_attempt "$live_root") \
        || fail "reroll refused for Wave 7 on this HEAD"
    destination="$live_root/$attempt"
    mkdir -p "$destination/home" "$destination/captures"
    trace="$destination/pebble-live.log"
    commands='/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/tp 14 68 -18;/lab start;/lab pause;/lab movement off;/lab population on;/lab lifecycle on;/lab survival on;/lab mortality on;/lab kinship on;/lab household on;/lab care on;/lab skills on;/lab teaching on;/lab settlement on;/lab ecology on;/lab ecological-observation on;/lab work-professions on;/lab physical-food-survival on;/tp 24.5 68 -11.5 150 12;/lab focus agent_0;/lab follow off;/lab overlay off;/lab autonomous-civilization passive;/lab resume'
    started=$(date +%s)
    printf '  live seed=46 wallTarget=120s %s ... ' "$attempt"
    (
        CFFIXED_USER_HOME="$destination/home" \
        PEBBLE_AUTOLOAD=1 \
        PEBBLE_NEWWORLD=46 \
        PEBBLE_NEWWORLD_NAME=PebbleLab-Disposable-Convergence01-Live-46 \
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
        PEBBLELAB_GATE_B_CONVERGENCE=1 \
        PEBBLELAB_GATE_B3_COGNITIVE_HZ=4 \
        PEBBLELAB_GATE_B3_RANDOM_TICK_SPEED=3 \
        PEBBLELAB_GATE_B3_PASSIVE=1 \
        PEBBLELAB_GATE_B3_PASSIVE_SECONDS=120 \
        PEBBLELAB_GATE_B3_PASSIVE_CAPTURE_DIR="$destination/captures" \
        PEBBLE_CMD="$commands" \
        PEBBLE_SHOT="$destination/captures/fallback.png@999999" \
        /usr/bin/perl -e '
            $SIG{ALRM} = sub { die "GATE_B_CONVERGENCE_LIVE_TIMEOUT\n" };
            alarm 300;
            exec @ARGV or die "exec failed: $!";
        ' "$PEBBLE_BINARY"
    ) >"$trace" 2>&1
    app_exit=$?
    elapsed=$(( $(date +%s) - started ))
    python3 "$SCRIPT_DIR/gate_b_convergence_evidence.py" live \
        --head "$HEAD_SHA" --elapsed-seconds "$elapsed" \
        --app-exit "$app_exit" --log "$trace" \
        --capture-directory "$destination/captures" \
        --output "$destination/result.json"
    disposition=$(python3 -c \
        'import json,sys; print(json.load(open(sys.argv[1]))["result"])' \
        "$destination/result.json")
    printf '%s elapsed=%ss\n' "$disposition" "$elapsed"
    assert_final_state
    [ "$disposition" = PASS ]
}

focused_passes() {
    python3 - "$EVIDENCE_ROOT/focused/results.tsv" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
if not path.is_file():
    raise SystemExit(1)
lines = path.read_text().splitlines()
raise SystemExit(0 if len(lines) == 17 and all(
    len(line.split("\t")) == 4
    and line.split("\t")[2:] == ["0", "0"]
    for line in lines
) else 1)
PY
}

live_passes() {
    python3 - "$EVIDENCE_ROOT/live/client" <<'PY'
import json
import sys
from pathlib import Path

paths = sorted(Path(sys.argv[1]).glob("attempt-*/result.json"))
raise SystemExit(0 if len(paths) == 1
    and json.loads(paths[0].read_text()).get("result") == "PASS" else 1)
PY
}

write_static_audits() {
    python3 - "$ROOT_DIR" "$BASELINE" "$HEAD_SHA" "$EVIDENCE_ROOT" <<'PY'
from __future__ import annotations

import json
import shlex
import subprocess
import sys
from pathlib import Path

root = Path(sys.argv[1])
baseline = sys.argv[2]
head = sys.argv[3]
evidence_root = Path(sys.argv[4])
summary_root = evidence_root / "summary"
source_range = f"{baseline}..{head}"


def shell_join(values: list[str]) -> str:
    return " ".join(shlex.quote(value) for value in values)


def execute(check: str, command: str) -> tuple[dict[str, object], bool]:
    completed = subprocess.run(
        ["/bin/bash", "-o", "pipefail", "-c", command],
        cwd=root,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    return ({
        "check": check,
        "command": command,
        "exit": completed.returncode,
    }, completed.returncode == 0)


def absence_in_added_lines(paths: list[str], pattern: str) -> str:
    path_arguments = shell_join(paths)
    quoted_pattern = shlex.quote(pattern)
    return (
        f"added=$(git diff --unified=0 {source_range} -- {path_arguments}) "
        '|| exit $?; '
        'if printf \'%s\\n\' "$added" '
        "| awk '/^\\+/ && !/^\\+\\+\\+/' "
        f"| rg -i -- {quoted_pattern} >/dev/null; "
        'then exit 1; else status=$?; test "$status" -eq 1; fi'
    )


def run_audit(
    checks_to_commands: dict[str, list[str]],
) -> tuple[dict[str, bool], list[dict[str, object]]]:
    checks: dict[str, bool] = {}
    commands: list[dict[str, object]] = []
    for check, check_commands in checks_to_commands.items():
        results = []
        for command in check_commands:
            record, passed = execute(check, command)
            commands.append(record)
            results.append(passed)
        checks[check] = bool(results) and all(results)
    return checks, commands


source_paths = ["Sources/Pebble", "Sources/PebbleAgents"]
authority_declaration = (
    r"(class|struct|actor|enum|protocol)[[:space:]]+"
    r"[A-Za-z_][A-Za-z0-9_]*{domain}"
    r"[A-Za-z0-9_]*(engine|runtime|kernel|scheduler|manager|system|"
    r"authority|executor|store|gateway|coordinator|service|controller|owner)"
)
gate_r_commands = {
    "baselineInherited": [
        f"git merge-base --is-ancestor {baseline} {head}",
    ],
    "coreUnchanged": [
        f"git diff --quiet {source_range} -- Sources/PebbleCore",
    ],
    "singleAgentKernel": [
        (
            "test \"$(rg -l "
            + shlex.quote(
                r"^(public[[:space:]]+)?(final[[:space:]]+)?"
                r"(struct|class|actor)[[:space:]]+"
                r"AgentSimulationSession\b"
            )
            + " Sources --glob '*.swift')\" = "
            + shlex.quote(
                "Sources/PebbleAgents/AgentSimulationSession.swift"
            )
        ),
    ],
    "noSecondPathfinder": [
        absence_in_added_lines(
            source_paths,
            (
                r"(class|struct|actor|enum|protocol)[[:space:]]+"
                r"[A-Za-z_][A-Za-z0-9_]*"
                r"(pathfinder|pathfinding|pathplanner|routeplanner)"
                r"[A-Za-z0-9_]*"
            ),
        ),
    ],
    "noSecondInventory": [
        absence_in_added_lines(
            source_paths,
            (
                r"(class|struct|actor|enum|protocol)[[:space:]]+"
                r"[A-Za-z_][A-Za-z0-9_]*"
                r"(inventory|materialcustody|custodygateway)"
                r"[A-Za-z0-9_]*"
            ),
        ),
    ],
    "noSecondFarming": [
        absence_in_added_lines(
            source_paths,
            authority_declaration.format(
                domain=r"(farming|agriculture)"
            ),
        ),
    ],
    "noSecondLivestock": [
        absence_in_added_lines(
            source_paths,
            authority_declaration.format(domain=r"(livestock|animalhusbandry)"),
        ),
    ],
    "noTeachingScheduler": [
        absence_in_added_lines(
            source_paths,
            authority_declaration.format(
                domain=r"(teaching|apprentice|pedagogy)"
            ),
        ),
    ],
    "noWorkScheduler": [
        absence_in_added_lines(
            source_paths,
            authority_declaration.format(
                domain=r"(work|profession|labor)"
            ),
        ),
    ],
    "noGlobalResourceOracle": [
        absence_in_added_lines(
            source_paths,
            (
                r"(global|worldwide|wholeworld|omniscient)"
                r"[A-Za-z0-9_]*(resource|material)"
                r"[A-Za-z0-9_]*(oracle|index|catalog|map)"
                r"|resourceoracle|globalresourceoracle"
            ),
        ),
    ],
    "noGateBRuntimeAuthority": [
        (
            "matches=$(rg -l "
            + shlex.quote(r"([Gg]ateBConvergence|GATE_B_CONVERGENCE)")
            + " Sources --glob '*.swift') || exit $?; "
            + 'while IFS= read -r file; do case "$file" in '
            + "Sources/Pebble/main.swift|"
            + "Sources/Pebble/PebbleAgentController+GateBConvergence.swift|"
            + "Sources/Pebble/PebbleAgentController+GateB3Acceptance.swift|"
            + "Sources/Pebble/PebbleAgentController+PassiveSocietySlice.swift"
            + ') ;; *) exit 1 ;; esac; done <<< "$matches"; '
            + 'printf \'%s\\n\' "$matches" | rg -Fxq '
            + shlex.quote(
                "Sources/Pebble/PebbleAgentController+GateBConvergence.swift"
            )
            + " && "
            + 'printf \'%s\\n\' "$matches" | rg -Fxq '
            + shlex.quote("Sources/Pebble/main.swift")
        ),
    ],
}
gate_r_checks, gate_r_command_results = run_audit(gate_r_commands)

movement_paths = [
    "Sources/Pebble/PebbleAgentMovementExecutor.swift",
    "Sources/Pebble/PebbleAgentController+Tick.swift",
    "Sources/PebbleAgents/AgentFeedbackLoop.swift",
    "Sources/PebbleAgents/AgentNavigation.swift",
    "Sources/PebbleAgents/AgentSimulationSession+AutonomousActivity.swift",
    "Sources/PebbleAgents/AgentSimulationSession+MovementNavigation.swift",
]
movement_evidence_code = r'''
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
specification = {
    "wave1-128": 10,
    "wave2-800": 10,
    "wave3-2400": 3,
    "determinism": 2,
    "checkpoint": 1,
    "stress": 2,
}
results = []
valid = True
for directory, expected_count in specification.items():
    paths = sorted(root.glob(
        f"{directory}/*/attempt-0001/result.json"
    ))
    valid = valid and len(paths) == expected_count
    for path in paths:
        try:
            value = json.loads(path.read_text())
        except (OSError, ValueError, json.JSONDecodeError):
            valid = False
            continue
        results.append(value)
valid = valid and len(results) == sum(specification.values())
valid = valid and all(
    value.get("convergenceChecks", {}).get("movementEnabled") is True
    for value in results
)
live_paths = sorted(
    (root / "live" / "client").glob("attempt-0001/result.json")
)
valid = valid and len(live_paths) == 1
if len(live_paths) == 1:
    try:
        live = json.loads(live_paths[0].read_text())
        valid = valid and (
            live.get("checks", {}).get("movementStayedEnabled") is True
        )
    except (OSError, ValueError, json.JSONDecodeError):
        valid = False
raise SystemExit(0 if valid else 1)
'''.strip()
no_bypass_evidence_code = r'''
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
paths = []
for directory in (
    "wave1-128", "wave2-800", "wave3-2400",
    "determinism", "checkpoint", "stress",
):
    paths.extend(sorted(root.glob(
        f"{directory}/*/attempt-0001/result.json"
    )))
valid = len(paths) == 28
for path in paths:
    try:
        value = json.loads(path.read_text())
        valid = valid and (
            value.get("convergenceChecks", {}).get(
                "distanceHomeBypassAbsent"
            ) is True
        )
    except (OSError, ValueError, json.JSONDecodeError):
        valid = False
live_paths = sorted(
    (root / "live" / "client").glob("attempt-0001/result.json")
)
valid = valid and len(live_paths) == 1
if len(live_paths) == 1:
    try:
        live = json.loads(live_paths[0].read_text())
        valid = valid and (
            live.get("checks", {}).get("distanceHomeBypassAbsent") is True
        )
    except (OSError, ValueError, json.JSONDecodeError):
        valid = False
raise SystemExit(0 if valid else 1)
'''.strip()
movement_commands = {
    "coreEntityMoveAuthority": [
        (
            "rg -q "
            + shlex.quote(r"public final class LabCoreAgentEntity: Entity")
            + " Sources/PebbleCore/Entity/LabCoreAgentEntity.swift"
            + " && rg -q "
            + shlex.quote(r"guard let path = findPath")
            + " Sources/Pebble/PebbleAgentMovementExecutor.swift"
            + " && rg -q "
            + shlex.quote(r"embodiment\.probe\.move\(")
            + " Sources/Pebble/PebbleAgentMovementExecutor.swift"
        ),
    ],
    "noAgentSetPosOrTeleport": [
        absence_in_added_lines(
            movement_paths,
            r"\b(setPos|teleport)[[:space:]]*\(",
        ),
    ],
    "noAcceptanceBypass": [
        absence_in_added_lines(
            movement_paths,
            (
                r"bypass[[:space:]]*=[[:space:]]*(1|true)"
                r"|acceptancebypass"
                r"|skip[A-Za-z0-9_]*(home|movement)[A-Za-z0-9_]*boundary"
                r"|ignore[A-Za-z0-9_]*home[A-Za-z0-9_]*boundary"
            ),
        ),
        (
            "git diff --unified=0 "
            + source_range
            + " -- "
            + shell_join(movement_paths)
            + " | awk '/^\\+/ && !/^\\+\\+\\+/' "
            + "| rg -q "
            + shlex.quote(r"bypass=0")
        ),
        (
            "python3 -c "
            + shlex.quote(no_bypass_evidence_code)
            + " "
            + shlex.quote(str(evidence_root))
        ),
    ],
    "movementEnabledEvidence": [
        (
            "python3 -c "
            + shlex.quote(movement_evidence_code)
            + " "
            + shlex.quote(str(evidence_root))
        ),
    ],
    "trueExplorationBoundary": [
        (
            "rg -q "
            + shlex.quote(r"public static func respectsExplorationHomeBoundary")
            + " Sources/PebbleAgents/AgentFeedbackLoop.swift"
            + " && rg -q "
            + shlex.quote(r"distanceBefore < maximumDistance")
            + " Sources/PebbleAgents/AgentFeedbackLoop.swift"
            + " && rg -q "
            + shlex.quote(r"distanceAfter <= maximumDistance")
            + " Sources/PebbleAgents/AgentFeedbackLoop.swift"
            + " && rg -q "
            + shlex.quote(r"distanceAfter < distanceBefore")
            + " Sources/PebbleAgents/AgentFeedbackLoop.swift"
            + " && rg -q "
            + shlex.quote(r"AgentFeedbackLoop.respectsExplorationHomeBoundary")
            + " Sources/Pebble/PebbleAgentController+Tick.swift"
            + " && rg -q "
            + shlex.quote(r"AgentFeedbackLoop.respectsExplorationHomeBoundary")
            + " Sources/Pebble/PebbleAgentMovementExecutor.swift"
            + " && rg -q "
            + shlex.quote(r"Core step exceeds exploration home boundary")
            + " Sources/Pebble/PebbleAgentMovementExecutor.swift"
            + " && rg -q "
            + shlex.quote(r"maxExploreDistanceFromHome")
            + " Sources/Pebble/PebbleAgentController+Tick.swift"
            + " && rg -q "
            + shlex.quote(r"physicalMutationCount:[[:space:]]*0")
            + " Sources/Pebble/PebbleAgentController+EmbodimentConvergence.swift"
            + " && rg -q "
            + shlex.quote(r"physicalMutationCount == 0")
            + " Sources/pebsmoke/PebbleAgentsBoundedAutonomousNavigationSmoke.swift"
        ),
    ],
    "localWaypointContract": [
        (
            "rg -q "
            + shlex.quote(r"public enum AgentBoundedTravel")
            + " Sources/PebbleAgents/AgentNavigation.swift"
            + " && rg -q "
            + shlex.quote(r"public static func isLocallyBoundedSegment")
            + " Sources/PebbleAgents/AgentNavigation.swift"
            + " && rg -q "
            + shlex.quote(r"public static func desiredWaypoint")
            + " Sources/PebbleAgents/AgentNavigation.swift"
            + " && rg -q "
            + shlex.quote(r"public static func permitsNormalizedWaypoint")
            + " Sources/PebbleAgents/AgentNavigation.swift"
            + " && rg -q "
            + shlex.quote(r"AgentBoundedTravel.desiredWaypoint")
            + " Sources/PebbleAgents/AgentSimulationSession+MovementNavigation.swift"
            + " && rg -q "
            + shlex.quote(r"AgentBoundedTravel.permitsNormalizedWaypoint")
            + " Sources/PebbleAgents/AgentSimulationSession+MovementNavigation.swift"
            + " && rg -q "
            + shlex.quote(r"AgentBoundedTravel.isLocallyBoundedSegment")
            + " Sources/Pebble/PebbleAgentController+Tick.swift"
        ),
    ],
    "rollbackPreserved": [
        (
            "rg -q "
            + shlex.quote(r"private func rollback\(")
            + " Sources/Pebble/PebbleAgentMovementExecutor.swift"
            + " && rg -q "
            + shlex.quote(r"probe\.move\(")
            + " Sources/Pebble/PebbleAgentMovementExecutor.swift"
            + " && rg -q "
            + shlex.quote(r"throw ExecutionError.rollbackVerificationFailed")
            + " Sources/Pebble/PebbleAgentMovementExecutor.swift"
            + " && rg -q "
            + shlex.quote(r"abs\(probe\.x - original\.x\) <= epsilon")
            + " Sources/Pebble/PebbleAgentMovementExecutor.swift"
        ),
    ],
}
movement_checks, movement_command_results = run_audit(movement_commands)


def write_reproducible(path: Path, value: dict[str, object]) -> None:
    encoded = json.dumps(value, indent=2, sort_keys=True) + "\n"
    if path.exists():
        if path.read_text() != encoded:
            raise SystemExit(
                f"existing static audit differs from recomputation: {path}"
            )
        return
    temporary = path.with_name(path.name + ".tmp")
    temporary.write_text(encoded)
    temporary.replace(path)


write_reproducible(summary_root / "gate-r.json", {
    "schemaVersion": 1,
    "head": head,
    "baseline": baseline,
    "result": "PASS" if all(gate_r_checks.values()) else "FAIL",
    "checks": gate_r_checks,
    "commands": gate_r_command_results,
})
write_reproducible(summary_root / "movement-audit.json", {
    "schemaVersion": 1,
    "head": head,
    "baseline": baseline,
    "result": "PASS" if all(movement_checks.values()) else "FAIL",
    "checks": movement_checks,
    "commands": movement_command_results,
})
PY
    [ "$?" -eq 0 ] || fail "static Gate R/movement audit generation failed"
}

require_prior_waves() {
    case "$MODE" in
        all|wave0|canonical) return 0 ;;
    esac
    focused_passes || fail "Wave 0 must already PASS on this exact HEAD"
    [ "$MODE" = wave1 ] && return 0
    wave_passes wave1-128 \
        seed-46 seed-71 seed-113 seed-197 seed-337 \
        seed-509 seed-887 seed-1597 seed-2593 seed-4099 \
        || fail "Wave 1 must already PASS on this exact HEAD"
    [ "$MODE" = wave2 ] && return 0
    wave_passes wave2-800 \
        seed-46 seed-71 seed-113 seed-197 seed-337 \
        seed-509 seed-887 seed-1597 seed-2593 seed-4099 \
        || fail "Wave 2 must already PASS on this exact HEAD"
    [ "$MODE" = wave3 ] && return 0
    wave_passes wave3-2400 seed-509 seed-887 seed-1597 \
        || fail "Wave 3 must already PASS on this exact HEAD"
    [ "$MODE" = determinism ] && return 0
    determinism_passes \
        || fail "Wave 4 must already PASS semantically on this exact HEAD"
    [ "$MODE" = checkpoint ] && return 0
    wave_passes checkpoint seed-887 \
        || fail "Wave 5 must already PASS on this exact HEAD"
    [ "$MODE" = stress ] && return 0
    wave_passes stress seed-2593 seed-4099 \
        || fail "Wave 6 must already PASS on this exact HEAD"
    [ "$MODE" = live ] && return 0
    live_passes || fail "Wave 7 must already PASS on this exact HEAD"
    [ -f "$EVIDENCE_ROOT/summary/full-gate.json" ] \
        || fail "canonical full gate evidence is missing"
}

require_prior_waves

ALL_GREEN=1

if [ "$MODE" = all ] || [ "$MODE" = wave0 ]; then
    printf '\n[Wave 0] Focused contracts\n'
    run_focused || ALL_GREEN=0
    [ "$MODE" != wave0 ] || exit $((1 - ALL_GREEN))
fi

if [ "$MODE" = all ] && [ "$ALL_GREEN" -ne 1 ]; then
    printf 'Wave 0 failed; later waves are not attempted.\n'
elif [ "$MODE" = all ] || [ "$MODE" = wave1 ]; then
    printf '\n[Wave 1] All ten seeds × 128\n'
    for seed in $FIXED_SEEDS; do
        run_seed wave1-128 "$seed" 128 "seed-$seed"
    done
    wave_passes wave1-128 \
        seed-46 seed-71 seed-113 seed-197 seed-337 \
        seed-509 seed-887 seed-1597 seed-2593 seed-4099 || ALL_GREEN=0
    [ "$MODE" != wave1 ] || exit $((1 - ALL_GREEN))
fi

if [ "$MODE" = all ] && [ "$ALL_GREEN" -ne 1 ]; then
    printf 'Wave 1 failed; later waves are not attempted.\n'
elif [ "$MODE" = all ] || [ "$MODE" = wave2 ]; then
    printf '\n[Wave 2] All ten seeds × 800\n'
    for seed in $FIXED_SEEDS; do
        run_seed wave2-800 "$seed" 800 "seed-$seed"
    done
    wave_passes wave2-800 \
        seed-46 seed-71 seed-113 seed-197 seed-337 \
        seed-509 seed-887 seed-1597 seed-2593 seed-4099 || ALL_GREEN=0
    [ "$MODE" != wave2 ] || exit $((1 - ALL_GREEN))
fi

if [ "$MODE" = all ] && [ "$ALL_GREEN" -ne 1 ]; then
    printf 'Wave 2 failed; later waves are not attempted.\n'
elif [ "$MODE" = all ] || [ "$MODE" = wave3 ]; then
    printf '\n[Wave 3] Medium seeds × 2400\n'
    for seed in $MEDIUM_SEEDS; do
        run_seed wave3-2400 "$seed" 2400 "seed-$seed"
    done
    wave_passes wave3-2400 seed-509 seed-887 seed-1597 || ALL_GREEN=0
    [ "$MODE" != wave3 ] || exit $((1 - ALL_GREEN))
fi

if [ "$MODE" = all ] && [ "$ALL_GREEN" -ne 1 ]; then
    printf 'Wave 3 failed; later waves are not attempted.\n'
elif [ "$MODE" = all ] || [ "$MODE" = determinism ]; then
    printf '\n[Wave 4] Seed 509 deterministic repeat × 1600\n'
    run_seed determinism 509 1600 seed-509-a
    run_seed determinism 509 1600 seed-509-b
    wave_passes determinism seed-509-a seed-509-b || ALL_GREEN=0
    determinism_passes || ALL_GREEN=0
    [ "$MODE" != determinism ] || exit $((1 - ALL_GREEN))
fi

if [ "$MODE" = all ] && [ "$ALL_GREEN" -ne 1 ]; then
    printf 'Wave 4 failed; later waves are not attempted.\n'
elif [ "$MODE" = all ] || [ "$MODE" = checkpoint ]; then
    printf '\n[Wave 5] Seed 887 checkpoint 1200 → 2400\n'
    run_seed checkpoint 887 2400 seed-887 1
    wave_passes checkpoint seed-887 || ALL_GREEN=0
    [ "$MODE" != checkpoint ] || exit $((1 - ALL_GREEN))
fi

if [ "$MODE" = all ] && [ "$ALL_GREEN" -ne 1 ]; then
    printf 'Wave 5 failed; later waves are not attempted.\n'
elif [ "$MODE" = all ] || [ "$MODE" = stress ]; then
    printf '\n[Wave 6] Stress seeds, shock at 3200, stop at 3600\n'
    run_seed stress 2593 3600 seed-2593 0 worker-care
    run_seed stress 4099 3600 seed-4099 0 tool-feed
    wave_passes stress seed-2593 seed-4099 || ALL_GREEN=0
    [ "$MODE" != stress ] || exit $((1 - ALL_GREEN))
fi

if [ "$MODE" = all ] && [ "$ALL_GREEN" -ne 1 ]; then
    printf 'Wave 6 failed; live preflight is not attempted.\n'
elif [ "$MODE" = all ] || [ "$MODE" = live ]; then
    printf '\n[Wave 7] Real client, two-minute passive preflight\n'
    run_live || ALL_GREEN=0
    [ "$MODE" != live ] || exit $((1 - ALL_GREEN))
fi

if [ "$MODE" = all ] || [ "$MODE" = canonical ]; then
    printf '\n[canonical] Full PebbleLab gate\n'
    full_log="$EVIDENCE_ROOT/summary/full-gate.log"
    assert_final_state
    [ ! -e "$full_log" ] \
        || fail "reroll refused for canonical full gate on this HEAD"
    if scripts/verify-pebblelab.sh >"$full_log" 2>&1; then
        full_exit=0
    else
        full_exit=$?
        ALL_GREEN=0
    fi
    counts=$(sed -n 's/^\([0-9][0-9]*\) passed, \([0-9][0-9]*\) failed$/\1 \2/p' \
        "$full_log" | tail -n 1)
    passed=$(printf '%s\n' "$counts" | awk '{print $1 + 0}')
    failed=$(printf '%s\n' "$counts" | awk '{print $2 + 0}')
    steps=$(grep -F 'PASS: all 35 PebbleLab verification steps succeeded.' \
        "$full_log" >/dev/null && printf '35/35' || printf 'FAIL')
    python3 - "$EVIDENCE_ROOT/summary/full-gate.json" \
        "$full_exit" "$steps" "$passed" "$failed" <<'PY'
import json
import sys
from pathlib import Path

Path(sys.argv[1]).write_text(json.dumps({
    "baseline": 3187,
    "newChecks": 38,
    "removedOrReplacedChecks": 0,
    "expected": 3225,
    "exit": int(sys.argv[2]),
    "steps": sys.argv[3],
    "passed": int(sys.argv[4]),
    "failed": int(sys.argv[5]),
}, indent=2, sort_keys=True) + "\n")
PY
    printf '  exit=%s steps=%s pebsmoke=%s/%s\n' \
        "$full_exit" "$steps" "$passed" "$failed"
    assert_final_state
    [ "$MODE" != canonical ] || exit $((1 - ALL_GREEN))
fi

if [ "$MODE" = all ] || [ "$MODE" = summary ]; then
    assert_final_state
    write_static_audits
    EXPECTED_CHECKS=3225
    summary="$EVIDENCE_ROOT/summary/GATE_B_CONVERGENCE_01_SUMMARY.json"
    python3 "$SCRIPT_DIR/gate_b_convergence_evidence.py" aggregate \
        --head "$HEAD_SHA" --root "$EVIDENCE_ROOT" \
        --configuration-digest "$CONFIG_DIGEST" \
        --expected-checks "$EXPECTED_CHECKS" \
        --product-corrections 3 \
        --discovered-blocker B-BLOCKER-ACCEPTANCE-BOOTSTRAP-ROLE-ASSIGNMENT \
        --discovered-blocker B-BLOCKER-MOVEMENT-HOME-BOUNDARY \
        --discovered-blocker B-BLOCKER-AUTONOMOUS-LIVESTOCK-INITIATION \
        --discovered-blocker B-BLOCKER-CHECKPOINT-PHYSICAL-CUSTODY \
        --corrected-blocker B-BLOCKER-ACCEPTANCE-BOOTSTRAP-ROLE-ASSIGNMENT \
        --corrected-blocker B-BLOCKER-MOVEMENT-HOME-BOUNDARY \
        --corrected-blocker B-BLOCKER-AUTONOMOUS-LIVESTOCK-INITIATION \
        --corrected-blocker B-BLOCKER-CHECKPOINT-PHYSICAL-CUSTODY \
        --output "$summary"
    verdict=$(python3 -c \
        'import json,sys; print(json.load(open(sys.argv[1]))["readinessVerdict"])' \
        "$summary")
    printf '\n%s\n' "$verdict"
    printf 'Gate B canonically acquired: NO\nCIV-26 started: NO\n'
    printf 'Evidence root: %s\n' "$EVIDENCE_ROOT"
    [ "$verdict" = 'READY FOR GATE B RE-EVALUATION #5' ] || exit 2
fi

exit $((1 - ALL_GREEN))
