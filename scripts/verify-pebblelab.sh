#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)

fail() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

if [ "${PEBBLE_REGOLD+x}" = x ]; then
    fail "PEBBLE_REGOLD must be absent (an empty value is also refused)."
fi

[ -d "$ROOT_DIR/.git" ] || fail "repository metadata not found at $ROOT_DIR"
[ -f "$ROOT_DIR/Package.swift" ] || fail "Package.swift not found at $ROOT_DIR"

cd "$ROOT_DIR"

TMP_BASE=${TMPDIR:-/tmp}
TMP_BASE=${TMP_BASE%/}
TMP_ROOT=$(mktemp -d "$TMP_BASE/PebbleLab-verify.XXXXXX")
AGENTS_OUT_A="$TMP_ROOT/agents-basic-a"
AGENTS_OUT_B="$TMP_ROOT/agents-basic-b"
REGRESSION_OUT="$TMP_ROOT/regression-smoke"

STEP=0
TOTAL_STEPS=11

run_step() {
    STEP=$((STEP + 1))
    printf '\n[%d/%d] %s\n' "$STEP" "$TOTAL_STEPS" "$1"
    shift
    "$@"
}

json_value() {
    /usr/bin/plutil -extract "$2" raw -o - "$1"
}

expect_json_value() {
    file=$1
    key=$2
    expected=$3
    [ -f "$file" ] || fail "missing canonical output: $file"
    actual=$(json_value "$file" "$key") || fail "cannot read $key from $file"
    [ "$actual" = "$expected" ] || fail "$file: expected $key=$expected, got $actual"
}

verify_agents_basic_outputs() {
    out=$1
    for file in config.json world_snapshot.json agent_snapshot.json metrics.json events.ndjson; do
        [ -s "$out/$file" ] || fail "agents_basic did not produce $out/$file"
    done
    expect_json_value "$out/config.json" scenario agents_basic
    expect_json_value "$out/config.json" seed 42
    expect_json_value "$out/config.json" ticks 3
    expect_json_value "$out/agent_snapshot.json" scenario agents_basic
    expect_json_value "$out/agent_snapshot.json" ticksCompleted 3
    expect_json_value "$out/metrics.json" scenario agents_basic
    expect_json_value "$out/metrics.json" success true
    expect_json_value "$out/metrics.json" agentCount 3
    /usr/bin/grep -Fq '"type":"run_finished"' "$out/events.ndjson" \
        || fail "agents_basic events are missing run_finished"
    /usr/bin/grep -Fq '"success":true' "$out/events.ndjson" \
        || fail "agents_basic events do not report success"
}

verify_regression_outputs() {
    report="$REGRESSION_OUT/regression_report.json"
    expect_json_value "$REGRESSION_OUT/metrics.json" scenario regression_smoke
    expect_json_value "$REGRESSION_OUT/metrics.json" success true
    expect_json_value "$report" scenario regression_smoke
    expect_json_value "$report" success true
    expect_json_value "$report" summary.checksFailed 0
}

verify_no_tracked_run_outputs() {
    tracked=$(
        git ls-files | /usr/bin/awk '
            /(^|\/)(runs?|outputs?|traces?|captures?)\// ||
            /(^|\/)(config|metrics|agent_snapshot|world_snapshot|regression_report)\.json$/ ||
            /(^|\/)events\.ndjson$/ ||
            /(^|\/)(\.DS_Store|.*\.swp|.*~)$/ { print }
        '
    )
    [ -z "$tracked" ] || {
        printf 'Tracked run outputs or parasite files detected:\n%s\n' "$tracked" >&2
        return 1
    }
}

printf 'PebbleLab verification\n'
printf 'Repository: %s\n' "$ROOT_DIR"
printf 'Temporary outputs: %s\n' "$TMP_ROOT"
printf 'Network: not used; this package has no external dependencies.\n'
printf 'Goldens: read-only; PEBBLE_REGOLD is refused.\n'

run_step "Debug build" swift build
run_step "Release Pebble build" swift build -c release --product Pebble
run_step "Release PebbleLab build" swift build -c release --product PebbleLab
run_step "Release pebsmoke build" swift build -c release --product pebsmoke
run_step "Golden and shared-runtime smoke suite" swift run -c release pebsmoke
run_step "agents_basic deterministic run A" \
    swift run -c release PebbleLab -- --scenario agents_basic --seed 42 --agents 3 --ticks 3 --out "$AGENTS_OUT_A"
run_step "agents_basic deterministic run B" \
    swift run -c release PebbleLab -- --scenario agents_basic --seed 42 --agents 3 --ticks 3 --out "$AGENTS_OUT_B"
run_step "agents_basic canonical outputs" verify_agents_basic_outputs "$AGENTS_OUT_A"

run_step "agents_basic deterministic replay comparison" \
    /usr/bin/cmp "$AGENTS_OUT_A/agent_snapshot.json" "$AGENTS_OUT_B/agent_snapshot.json"
/usr/bin/cmp "$AGENTS_OUT_A/world_snapshot.json" "$AGENTS_OUT_B/world_snapshot.json"
/usr/bin/cmp "$AGENTS_OUT_A/metrics.json" "$AGENTS_OUT_B/metrics.json"
/usr/bin/cmp "$AGENTS_OUT_A/events.ndjson" "$AGENTS_OUT_B/events.ndjson"

run_step "Canonical regression_smoke business checks" \
    swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out "$REGRESSION_OUT"
verify_regression_outputs

run_step "Repository hygiene" git diff --check
verify_no_tracked_run_outputs

printf '\nPASS: all %d PebbleLab verification steps succeeded.\n' "$TOTAL_STEPS"
printf 'Temporary evidence retained at: %s\n' "$TMP_ROOT"
