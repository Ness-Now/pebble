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
SETTLEMENT_OUT_A="$TMP_ROOT/settlement-metrics-a"
SETTLEMENT_OUT_B="$TMP_ROOT/settlement-metrics-b"
ECOLOGY_OUT_A="$TMP_ROOT/local-ecology-a"
ECOLOGY_OUT_B="$TMP_ROOT/local-ecology-b"
MORTALITY_OUT_A="$TMP_ROOT/mortality-a"
MORTALITY_OUT_B="$TMP_ROOT/mortality-b"
LIFECYCLE_OUT_A="$TMP_ROOT/lifecycle-a"
LIFECYCLE_OUT_B="$TMP_ROOT/lifecycle-b"
KINSHIP_OUT_A="$TMP_ROOT/kinship-a"
KINSHIP_OUT_B="$TMP_ROOT/kinship-b"

STEP=0
TOTAL_STEPS=26

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

verify_settlement_metrics_outputs() {
    out=$1
    for file in \
        settlement_metrics_state.json \
        settlement_metric_frames.json \
        settlement_agent_classifications.json \
        settlement_macro_causal_chain.json \
        settlement_behavior_ab.json \
        settlement_metrics_summary.json \
        settlement_metrics_digest.json \
        settlement_metrics_invariant_report.json \
        settlement_checkpoint_v3/manifest.json \
        settlement_checkpoint_v3/session.json \
        settlement_replay_v3/manifest.json \
        settlement_replay_v3/operations.ndjson
    do
        [ -s "$out/$file" ] || fail "settlement metrics did not produce $out/$file"
    done
    expect_json_value "$out/settlement_metrics_summary.json" schemaVersion 3
    expect_json_value "$out/settlement_metrics_summary.json" scenario \
        settlement_metrics_multiscale_smoke
    expect_json_value "$out/settlement_metrics_summary.json" seed 46
    expect_json_value "$out/settlement_metrics_summary.json" macroInterval 4
    expect_json_value "$out/settlement_metrics_summary.json" macroSequence 3
    expect_json_value "$out/settlement_metrics_summary.json" population 4
    expect_json_value "$out/settlement_metrics_summary.json" residents 4
    expect_json_value "$out/settlement_metrics_summary.json" checkpointSchema 3
    expect_json_value "$out/settlement_metrics_summary.json" replaySchema 3
    expect_json_value "$out/settlement_behavior_ab.json" equal true
    expect_json_value "$out/settlement_metrics_invariant_report.json" success true
}

verify_local_ecology_outputs() {
    out=$1
    for file in \
        local_ecology_patches.json \
        local_ecology_observations.json \
        forage_outcomes.json \
        ecology_conservation.json \
        subsistence_pressure_frames.json \
        ecology_causal_chain.json \
        ecology_summary.json \
        ecology_digest.json \
        ecology_invariant_report.json \
        ecology_checkpoint_v4/manifest.json \
        ecology_checkpoint_v4/session.json \
        ecology_replay_v4/manifest.json \
        ecology_replay_v4/operations.ndjson
    do
        [ -s "$out/$file" ] || fail "local ecology did not produce $out/$file"
    done
    expect_json_value "$out/ecology_summary.json" schemaVersion 4
    expect_json_value "$out/ecology_summary.json" scenario local_ecology_subsistence_smoke
    expect_json_value "$out/ecology_summary.json" seed 46
    expect_json_value "$out/ecology_summary.json" population 4
    expect_json_value "$out/ecology_summary.json" residents 4
    expect_json_value "$out/ecology_summary.json" checkpointSchema 4
    expect_json_value "$out/ecology_summary.json" replaySchema 4
    expect_json_value "$out/ecology_summary.json" ecologyBalanced true
    expect_json_value "$out/ecology_summary.json" materialBalanced true
    expect_json_value "$out/ecology_summary.json" worldMutationCount 0
    expect_json_value "$out/ecology_invariant_report.json" success true
}

verify_mortality_outputs() {
    out=$1
    for file in \
        mortality_records.json \
        population_exit_frames.json \
        mortality_cleanup.json \
        mortality_terminal_activity.json \
        mortality_resource_conservation.json \
        mortality_causal_chain.json \
        mortality_summary.json \
        mortality_digest.json \
        mortality_invariant_report.json \
        mortality_checkpoint_v5/manifest.json \
        mortality_checkpoint_v5/session.json \
        mortality_replay_v5/manifest.json \
        mortality_replay_v5/operations.ndjson
    do
        [ -s "$out/$file" ] || fail "mortality did not produce $out/$file"
    done
    expect_json_value "$out/mortality_summary.json" schemaVersion 5
    expect_json_value "$out/mortality_summary.json" scenario mortality_population_exit_smoke
    expect_json_value "$out/mortality_summary.json" seed 46
    expect_json_value "$out/mortality_summary.json" deadAgentID agent_3
    expect_json_value "$out/mortality_summary.json" deathTick 27
    expect_json_value "$out/mortality_summary.json" populationBefore 4
    expect_json_value "$out/mortality_summary.json" populationAfter 3
    expect_json_value "$out/mortality_summary.json" replacementAgentID agent_4
    expect_json_value "$out/mortality_summary.json" nextPopulationOrdinal 5
    expect_json_value "$out/mortality_summary.json" checkpointSchema 5
    expect_json_value "$out/mortality_summary.json" replaySchema 5
    expect_json_value "$out/mortality_summary.json" unrecoveredAtDeath 2
    expect_json_value "$out/mortality_summary.json" worldMutationCount 0
    expect_json_value "$out/mortality_invariant_report.json" success true
}

verify_lifecycle_outputs() {
    out=$1
    for file in \
        lifecycle_members.json \
        life_stage_transitions.json \
        reproduction_plans.json \
        birth_records.json \
        lineage_index.json \
        birth_site_observations.json \
        lifecycle_causal_chain.json \
        lifecycle_checkpoint_v6/manifest.json \
        lifecycle_checkpoint_v6/session.json \
        lifecycle_replay_v6/manifest.json \
        lifecycle_replay_v6/operations.ndjson \
        lifecycle_summary.json \
        lifecycle_digest.json \
        lifecycle_invariant_report.json
    do
        [ -s "$out/$file" ] || fail "lifecycle did not produce $out/$file"
    done
    expect_json_value "$out/lifecycle_invariant_report.json" schemaVersion 6
    expect_json_value "$out/lifecycle_invariant_report.json" scenario \
        age_maturity_reproduction_smoke
    expect_json_value "$out/lifecycle_invariant_report.json" seed 46
    expect_json_value "$out/lifecycle_invariant_report.json" success true
    expect_json_value "$out/lifecycle_summary.json" totalBirthCount 1
    expect_json_value "$out/lifecycle_summary.json" matureCount 5
    expect_json_value "$out/lifecycle_checkpoint_v6/session.json" schemaVersion 6
    expect_json_value "$out/lifecycle_replay_v6/manifest.json" schemaVersion 6
}

verify_kinship_outputs() {
    out=$1
    for file in \
        kinship_people.json \
        parentage_records.json \
        children_by_parent.json \
        sibling_relations.json \
        kinship_external_status.json \
        kinship_causal_chain.json \
        kinship_digest.json \
        kinship_invariant_report.json \
        kinship_checkpoint_v7/manifest.json \
        kinship_checkpoint_v7/session.json \
        kinship_replay_v7/manifest.json \
        kinship_replay_v7/operations.ndjson
    do
        [ -s "$out/$file" ] || fail "kinship did not produce $out/$file"
    done
    expect_json_value "$out/kinship_invariant_report.json" schemaVersion 7
    expect_json_value "$out/kinship_invariant_report.json" scenario \
        durable_kinship_graph_smoke
    expect_json_value "$out/kinship_invariant_report.json" seed 47
    expect_json_value "$out/kinship_invariant_report.json" success true
    expect_json_value "$out/kinship_digest.json" schemaVersion 7
    expect_json_value "$out/kinship_digest.json" seed 47
    expect_json_value "$out/kinship_digest.json" worldBoundaryEvidence \
        "pure PebbleAgents APIs; no World access or mutation event"
    expect_json_value "$out/kinship_checkpoint_v7/session.json" schemaVersion 7
    expect_json_value "$out/kinship_replay_v7/manifest.json" schemaVersion 7
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

run_step "settlement metrics deterministic run A" \
    swift run -c release PebbleLab -- --scenario settlement_metrics_multiscale_smoke \
        --seed 46 --ticks 12 --out "$SETTLEMENT_OUT_A"
run_step "settlement metrics deterministic run B" \
    swift run -c release PebbleLab -- --scenario settlement_metrics_multiscale_smoke \
        --seed 46 --ticks 12 --out "$SETTLEMENT_OUT_B"
run_step "settlement metrics canonical outputs and replay comparison" \
    verify_settlement_metrics_outputs "$SETTLEMENT_OUT_A"
verify_settlement_metrics_outputs "$SETTLEMENT_OUT_B"
/usr/bin/diff -r "$SETTLEMENT_OUT_A" "$SETTLEMENT_OUT_B"

run_step "local ecology deterministic run A" \
    swift run -c release PebbleLab -- --scenario local_ecology_subsistence_smoke \
        --seed 46 --ticks 14 --out "$ECOLOGY_OUT_A"
run_step "local ecology deterministic run B" \
    swift run -c release PebbleLab -- --scenario local_ecology_subsistence_smoke \
        --seed 46 --ticks 14 --out "$ECOLOGY_OUT_B"
run_step "local ecology canonical outputs and replay comparison" \
    verify_local_ecology_outputs "$ECOLOGY_OUT_A"
verify_local_ecology_outputs "$ECOLOGY_OUT_B"
/usr/bin/diff -r "$ECOLOGY_OUT_A" "$ECOLOGY_OUT_B"

run_step "mortality deterministic run A" \
    swift run -c release PebbleLab -- --scenario mortality_population_exit_smoke \
        --seed 46 --ticks 27 --out "$MORTALITY_OUT_A"
run_step "mortality deterministic run B" \
    swift run -c release PebbleLab -- --scenario mortality_population_exit_smoke \
        --seed 46 --ticks 27 --out "$MORTALITY_OUT_B"
run_step "mortality canonical outputs and replay comparison" \
    verify_mortality_outputs "$MORTALITY_OUT_A"
verify_mortality_outputs "$MORTALITY_OUT_B"
/usr/bin/diff -r "$MORTALITY_OUT_A" "$MORTALITY_OUT_B"

run_step "lifecycle deterministic run A" \
    swift run -c release PebbleLab -- --scenario age_maturity_reproduction_smoke \
        --seed 46 --ticks 12 --out "$LIFECYCLE_OUT_A"
run_step "lifecycle deterministic run B" \
    swift run -c release PebbleLab -- --scenario age_maturity_reproduction_smoke \
        --seed 46 --ticks 12 --out "$LIFECYCLE_OUT_B"
run_step "lifecycle canonical outputs and replay comparison" \
    verify_lifecycle_outputs "$LIFECYCLE_OUT_A"
verify_lifecycle_outputs "$LIFECYCLE_OUT_B"
/usr/bin/diff -r "$LIFECYCLE_OUT_A" "$LIFECYCLE_OUT_B"

run_step "kinship deterministic run A" \
    swift run -c release PebbleLab -- --scenario durable_kinship_graph_smoke \
        --seed 47 --out "$KINSHIP_OUT_A"
run_step "kinship deterministic run B" \
    swift run -c release PebbleLab -- --scenario durable_kinship_graph_smoke \
        --seed 47 --out "$KINSHIP_OUT_B"
run_step "kinship canonical outputs and replay comparison" \
    verify_kinship_outputs "$KINSHIP_OUT_A"
verify_kinship_outputs "$KINSHIP_OUT_B"
/usr/bin/diff -r "$KINSHIP_OUT_A" "$KINSHIP_OUT_B"

run_step "Repository hygiene" git diff --check
verify_no_tracked_run_outputs

printf '\nPASS: all %d PebbleLab verification steps succeeded.\n' "$TOTAL_STEPS"
printf 'Temporary evidence retained at: %s\n' "$TMP_ROOT"
