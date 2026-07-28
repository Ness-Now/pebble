#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
EXPECTED_HEAD="57ece4c911d83afd49877fad9191cef7e31f791e"
DRY_RUN=0

usage() {
    printf '%s\n' \
        "Usage: scripts/verify-pebblelab-safe-bootstrap.sh [--dry-run]" \
        "" \
        "Runs a retained, disposable live campaign for post-Gate-B safe bootstrap:" \
        "  - three naturally generated World scenarios;" \
        "  - one start/reset/restart/clear lifecycle cycle;" \
        "  - one unavailable-area refusal;" \
        "  - one injected late-publication rollback." \
        "" \
        "No terrain preparation or terrain mutation command is used."
}

fail() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

require_trace() {
    local trace=$1
    local pattern=$2
    local description=$3
    /usr/bin/grep -Eq "$pattern" "$trace" \
        || fail "$trace missing: $description"
}

reject_trace() {
    local trace=$1
    local pattern=$2
    local description=$3
    if /usr/bin/grep -Eq "$pattern" "$trace"; then
        fail "$trace unexpectedly contains: $description"
    fi
}

if [ "$#" -gt 1 ]; then
    usage >&2
    exit 2
fi
if [ "$#" -eq 1 ]; then
    case "$1" in
        --dry-run) DRY_RUN=1 ;;
        --help|-h) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
fi

if [ "${PEBBLE_REGOLD+x}" = x ]; then
    fail "PEBBLE_REGOLD must be absent, including an empty value"
fi

TOP_LEVEL=$(git -C "$ROOT_DIR" rev-parse --show-toplevel 2>/dev/null) \
    || fail "repository metadata not found"
[ "$TOP_LEVEL" = "$ROOT_DIR" ] \
    || fail "unexpected repository root: $TOP_LEVEL"
BASELINE=$(git -C "$ROOT_DIR" merge-base HEAD "$EXPECTED_HEAD")
[ "$BASELINE" = "$EXPECTED_HEAD" ] \
    || fail "current branch is not based on expected canonical HEAD $EXPECTED_HEAD"

if [ "$DRY_RUN" -eq 1 ]; then
    printf '%s\n' \
        "PebbleLab safe-bootstrap live campaign (dry run)" \
        "Repository: $ROOT_DIR" \
        "Expected baseline ancestor: $EXPECTED_HEAD" \
        "Natural terrain matrix:" \
        "  spawn-46: seed=46, player=natural spawn" \
        "  lake-71: seed=71, expected honest refusal from natural water at x=48 z=48" \
        "  remote-887: seed=887, player placed on the natural surface at x=-64 z=32" \
        "Lifecycle contract:" \
        "  lifecycle-rebuild: seed=46, start/reset/start-existing/clear, exact cleanup" \
        "Negative contracts:" \
        "  unavailable-refusal: seed=12345, unloaded remote area, no session/probes" \
        "  late-rollback: seed=46, two staged probes, injected failure, exact rollback" \
        "Every run uses a fresh isolated home and PebbleLab-Disposable-* World." \
        "Natural scenarios observe movement for two 240-frame intervals." \
        "DRY RUN: Pebble was not built or launched."
    exit 0
fi

if /usr/bin/pgrep -x Pebble >/dev/null 2>&1; then
    fail "a Pebble process is already running"
fi

TMP_BASE=${TMPDIR:-/tmp}
TMP_BASE=${TMP_BASE%/}
ARTIFACT_ROOT=$(mktemp -d "$TMP_BASE/PebbleLab-safe-bootstrap.XXXXXX")
case "$ARTIFACT_ROOT" in
    "$TMP_BASE"/PebbleLab-safe-bootstrap.*) ;;
    *) fail "unsafe artifact directory: $ARTIFACT_ROOT" ;;
esac
MANIFEST="$ARTIFACT_ROOT/matrix.tsv"
printf 'scenario\tseed\tanchor\tpositions\tcandidates\tplayer_facts\tfinal_status\ttrace\tstart_capture\tobserved_capture\n' \
    > "$MANIFEST"

cd "$ROOT_DIR"
swift build -c release --product Pebble
PEBBLE_BINARY="$ROOT_DIR/.build/release/Pebble"
[ -x "$PEBBLE_BINARY" ] || fail "release Pebble binary missing"

run_pebble() {
    local scenario=$1
    local seed=$2
    local commands=$3
    local shots=$4
    local late_failure=$5
    local run_root="$ARTIFACT_ROOT/$scenario"
    local run_home="$run_root/home"
    local capture_dir="$run_root/captures"
    local trace="$run_root/pebble-live.log"
    local world_name="PebbleLab-Disposable-SafeBootstrap-$scenario-$seed"

    /bin/mkdir -p "$run_home" "$capture_dir"
    set +e
    CFFIXED_USER_HOME="$run_home" \
    PEBBLE_AUTOLOAD=1 \
    PEBBLE_NEWWORLD="$seed" \
    PEBBLE_NEWWORLD_NAME="$world_name" \
    PEBBLELAB_APP_AGENTS=1 \
    PEBBLELAB_APP_AGENTS_MOVE=1 \
    PEBBLELAB_APP_PROBES=1 \
    PEBBLELAB_DEBUG_ENTITIES=1 \
    PEBBLELAB_APP_AGENTS_OVERLAY=1 \
    PEBBLELAB_APP_AGENTS_TRACE=1 \
    PEBBLELAB_APP_AGENTS_TRACE_EVERY=1 \
    PEBBLELAB_APP_AGENTS_INTERACT=0 \
    PEBBLELAB_APP_AGENTS_NATURAL=0 \
    PEBBLELAB_APP_AGENTS_BUILD=0 \
    PEBBLELAB_APP_AGENTS_SOCIAL=0 \
    PEBBLELAB_APP_AGENTS_PHYSICAL=0 \
    PEBBLELAB_APP_AGENTS_MATERIAL=0 \
    PEBBLELAB_APP_AGENTS_COOPERATION=0 \
    PEBBLELAB_APP_AGENTS_PERSISTENCE=0 \
    PEBBLELAB_APP_AGENTS_POPULATION=0 \
    PEBBLELAB_APP_AGENTS_MULTISCALE=0 \
    PEBBLELAB_APP_AGENTS_ECOLOGY=0 \
    PEBBLELAB_APP_AGENTS_MORTALITY=0 \
    PEBBLELAB_APP_AGENTS_LIFECYCLE=0 \
    PEBBLELAB_APP_AGENTS_KINSHIP=0 \
    PEBBLELAB_APP_AGENTS_HOUSEHOLDS=0 \
    PEBBLELAB_APP_AGENTS_CARE=0 \
    PEBBLELAB_APP_AGENTS_SKILLS=0 \
    PEBBLELAB_APP_AGENTS_TEACHING=0 \
    PEBBLELAB_APP_AGENTS_ECOLOGICAL_OBSERVATION=0 \
    PEBBLELAB_APP_AGENTS_AGRICULTURE=0 \
    PEBBLELAB_APP_AGENTS_WILD_SUBSISTENCE=0 \
    PEBBLELAB_APP_AGENTS_LIVESTOCK=0 \
    PEBBLELAB_APP_AGENTS_WORK_PROFESSIONS=0 \
    PEBBLELAB_APP_AGENTS_AUTONOMOUS_CIVILIZATION=0 \
    PEBBLELAB_DISPOSABLE_WORLD_PROOF=1 \
    PEBBLELAB_DISPOSABLE_SAFE_BOOTSTRAP_LATE_FAILURE_PROOF="$late_failure" \
    PEBBLE_CMD="$commands" \
    PEBBLE_SHOT="$shots" \
    "$PEBBLE_BINARY" 2>&1 | /usr/bin/tee "$trace"
    local app_status=${PIPESTATUS[0]}
    set -e
    [ "$app_status" -eq 0 ] \
        || fail "$scenario Pebble process exited $app_status"
    if /usr/bin/pgrep -x Pebble >/dev/null 2>&1; then
        fail "$scenario left a Pebble process running"
    fi

    local db="$run_home/Library/Application Support/Pebble/pebble.db"
    [ -f "$db" ] || fail "$scenario did not create its disposable database"
    local world_facts
    world_facts=$(/usr/bin/sqlite3 "$db" \
        "SELECT count(*), json_extract(json, '$.seed'), json_extract(json, '$.name') FROM worlds;")
    [ "$world_facts" = "1|$seed|$world_name" ] \
        || fail "$scenario unexpected World facts: $world_facts"
}

run_natural_scenario() {
    local scenario=$1
    local seed=$2
    local teleport=$3
    local run_root="$ARTIFACT_ROOT/$scenario"
    local start_capture="$run_root/captures/bootstrap.png"
    local observed_capture="$run_root/captures/observed.png"
    local trace="$run_root/pebble-live.log"
    local commands
    local shots

    if [ "$teleport" = "spawn" ]; then
        commands='/lab start;/lab pause;/lab movement on;/lab focus agent_0;/lab follow agent_0;/lab overlay full|/lab resume|/lab status|/lab stop;/lab status'
        shots="$start_capture|-|$observed_capture|-"
    else
        commands="/tp $teleport;/surface|/lab start;/lab pause;/lab movement on;/lab focus agent_0;/lab follow agent_0;/lab overlay full|/lab resume|/lab status|/lab stop;/lab status"
        shots="-|$start_capture|-|$observed_capture|-"
    fi

    printf '\n=== %s seed=%s player=%s ===\n' "$scenario" "$seed" "$teleport"
    run_pebble "$scenario" "$seed" "$commands" "$shots" 0

    require_trace "$trace" \
        '^\[lab-live\] bootstrap placement status=accepted anchor=.* positions=agent_0:.*;agent_1:.*;agent_2:.* candidates=[1-9][0-9]*/12000 rejections=.*' \
        "accepted bounded placement with three identities"
    require_trace "$trace" \
        '^\[lab-live\] bootstrap publication status=verified cognitionPhysical=exact sessionAgents=3 worldProbes=3 rollbackRequired=0$' \
        "verified atomic cognitive/physical publication"
    require_trace "$trace" \
        "^\[lab-live\] start seed=$seed agents=3 tick=0 hz=4 movement=on " \
        "normal product start"
    require_trace "$trace" \
        '^\[lab-live\] status PebbleAgents running tick=[1-9][0-9]* .*probes=3 .*agent_0=.*o[1-9][0-9]* agent_1=.*o[1-9][0-9]* agent_2=.*o[1-9][0-9]*$' \
        "continuous temporal observation of all three agents"
    require_trace "$trace" \
        '^\[lab-live\] summary .*ticks=[1-9][0-9]* .*runtimeErrors=0 .*probesRemoved=3 ' \
        "clean lifecycle after prolonged observation"
    require_trace "$trace" \
        '^\[lab-live\] status inactive gate=enabled$' \
        "inactive session after explicit stop"
    reject_trace "$trace" \
        'bootstrap placement status=refused|bootstrap rollback|unsafe movement|runtimeErrors=[1-9]|start failed|cleanup failed|hardFailure=1' \
        "placement, movement, runtime, or cleanup failure"
    if /usr/bin/grep -Eq \
        '^\[lab-live\] summary .*movementCount=0 blocked=0 ' "$trace"; then
        reject_trace "$trace" \
            '^\[lab-live\] embodiment movement .*:(blocked|moved):' \
            "physical outcome when cognition requested no movement"
    else
        require_trace "$trace" \
            '^\[lab-live\] embodiment movement .*:moved:.* noNormalSetPos=1$' \
            "Core-verified movement without bootstrap repositioning"
    fi
    [ -s "$start_capture" ] || fail "$scenario missing bootstrap capture"
    [ -s "$observed_capture" ] || fail "$scenario missing observed capture"

    local placement
    local anchor
    local positions
    local candidates
    local player_facts
    local status
    placement=$(/usr/bin/grep -E '^\[lab-live\] bootstrap placement status=accepted ' \
        "$trace" | /usr/bin/head -1)
    anchor=$(printf '%s\n' "$placement" \
        | /usr/bin/sed -E 's/.* anchor=([^ ]+) .*/\1/')
    positions=$(printf '%s\n' "$placement" \
        | /usr/bin/sed -E 's/.* positions=([^ ]+) candidates=.*/\1/')
    candidates=$(printf '%s\n' "$placement" \
        | /usr/bin/sed -E 's/.* candidates=([^ ]+) rejections=.*/\1/')
    local db="$run_root/home/Library/Application Support/Pebble/pebble.db"
    player_facts=$(/usr/bin/sqlite3 "$db" \
        "SELECT json_extract(json, '$.data.health'), coalesce(json_extract(json, '$.data.data.deathCause'), 'none'), printf('%d,%d,%d', floor(json_extract(json, '$.data.x')), floor(json_extract(json, '$.data.y')), floor(json_extract(json, '$.data.z'))) FROM player;")
    [ "$player_facts" = "20|none|$anchor" ] \
        || fail "$scenario player was not healthy and stationary at bootstrap anchor: $player_facts vs $anchor"
    status=$(/usr/bin/grep -E '^\[lab-live\] status PebbleAgents running ' \
        "$trace" | /usr/bin/tail -1)
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$scenario" "$seed" "$anchor" "$positions" "$candidates" \
        "$player_facts" "$status" "$trace" "$start_capture" "$observed_capture" \
        >> "$MANIFEST"
}

run_natural_refusal_scenario() {
    local scenario=$1
    local seed=$2
    local teleport=$3
    local run_root="$ARTIFACT_ROOT/$scenario"
    local trace="$run_root/pebble-live.log"
    local commands="/tp $teleport;/surface|/lab start|/lab status|/lab stop;/lab status"

    printf '\n=== %s seed=%s player=%s expected-refusal ===\n' \
        "$scenario" "$seed" "$teleport"
    run_pebble "$scenario" "$seed" "$commands" '-|-|-|-' 0

    require_trace "$trace" \
        '^\[lab-live\] bootstrap placement status=refused anchor=.* reason=insufficient_safe_positions found=[0-2] required=3 candidates=[1-9][0-9]*/12000 rejections=.* session=none probes=0$' \
        "honest normal-world refusal with diagnostics"
    require_trace "$trace" \
        '^\[lab-live\] status inactive gate=enabled$' \
        "inactive state after normal-world refusal"
    reject_trace "$trace" \
        'bootstrap publication status=verified|^\[lab-live\] start seed=|probesRemoved=[1-9]|hardFailure=1' \
        "partial publication after normal-world refusal"

    local refusal
    local anchor
    local candidates
    local player_facts
    refusal=$(/usr/bin/grep -E \
        '^\[lab-live\] bootstrap placement status=refused ' "$trace" \
        | /usr/bin/head -1)
    anchor=$(printf '%s\n' "$refusal" \
        | /usr/bin/sed -E 's/.* anchor=([^ ]+) .*/\1/')
    candidates=$(printf '%s\n' "$refusal" \
        | /usr/bin/sed -E 's/.* candidates=([^ ]+) rejections=.*/\1/')
    local db="$run_root/home/Library/Application Support/Pebble/pebble.db"
    player_facts=$(/usr/bin/sqlite3 "$db" \
        "SELECT json_extract(json, '$.data.health'), coalesce(json_extract(json, '$.data.data.deathCause'), 'none'), printf('%d,%d,%d', floor(json_extract(json, '$.data.x')), floor(json_extract(json, '$.data.y')), floor(json_extract(json, '$.data.z'))) FROM player;")
    [ "$player_facts" = "20|none|$anchor" ] \
        || fail "$scenario player was not healthy and stationary at refusal anchor: $player_facts vs $anchor"
    printf '%s\t%s\t%s\tREFUSED\t%s\t%s\tnone\t%s\tnone\tnone\n' \
        "$scenario" "$seed" "$anchor" "$candidates" "$player_facts" "$trace" \
        >> "$MANIFEST"
}

run_natural_scenario "spawn-46" "46" "spawn"
run_natural_refusal_scenario "lake-71" "71" "48 120 48"
run_natural_scenario "remote-887" "887" "-64 120 32"

printf '\n=== start/reset/restart/clear lifecycle ===\n'
LIFECYCLE_SCENARIO="lifecycle-rebuild"
LIFECYCLE_TRACE="$ARTIFACT_ROOT/$LIFECYCLE_SCENARIO/pebble-live.log"
run_pebble "$LIFECYCLE_SCENARIO" "46" \
    '/lab start;/lab pause;/lab status|/lab reset;/lab pause;/lab status|/lab start;/lab pause;/lab status|/lab clear;/lab status' \
    '-|-|-|-' 0
LIFECYCLE_PLACEMENTS=$(/usr/bin/grep -Ec \
    '^\[lab-live\] bootstrap placement status=accepted ' "$LIFECYCLE_TRACE")
[ "$LIFECYCLE_PLACEMENTS" -eq 3 ] \
    || fail "lifecycle expected three accepted placement plans, found $LIFECYCLE_PLACEMENTS"
LIFECYCLE_PUBLICATIONS=$(/usr/bin/grep -Ec \
    '^\[lab-live\] bootstrap publication status=verified cognitionPhysical=exact sessionAgents=3 worldProbes=3 rollbackRequired=0$' \
    "$LIFECYCLE_TRACE")
[ "$LIFECYCLE_PUBLICATIONS" -eq 3 ] \
    || fail "lifecycle expected three atomic publications, found $LIFECYCLE_PUBLICATIONS"
require_trace "$LIFECYCLE_TRACE" \
    '^\[lab-live\] summary reason=reset .*runtimeErrors=0 .*probesRemoved=3 ' \
    "exact cleanup before reset"
require_trace "$LIFECYCLE_TRACE" \
    '^\[lab-live\] reset seed=46 agents=3 tick=0 hz=4 movement=on ' \
    "successful reset publication"
require_trace "$LIFECYCLE_TRACE" \
    '^\[lab-live\] summary reason=restart .*runtimeErrors=0 .*probesRemoved=3 ' \
    "exact cleanup before start on an existing session"
require_trace "$LIFECYCLE_TRACE" \
    '^\[lab-live\] summary reason=clear .*runtimeErrors=0 .*probesRemoved=3 ' \
    "exact cleanup on clear"
require_trace "$LIFECYCLE_TRACE" \
    '^\[lab-live\] status inactive gate=enabled$' \
    "inactive state after clear"
reject_trace "$LIFECYCLE_TRACE" \
    'bootstrap placement status=refused|bootstrap rollback|start failed|cleanup failed|hardFailure=1|^\[lab-live\] summary .*probesRemoved=[0124-9] ' \
    "refusal, rollback, cleanup failure, or inexact probe removal"
LIFECYCLE_PLACEMENT=$(/usr/bin/grep -E \
    '^\[lab-live\] bootstrap placement status=accepted ' "$LIFECYCLE_TRACE" \
    | /usr/bin/head -1)
LIFECYCLE_ANCHOR=$(printf '%s\n' "$LIFECYCLE_PLACEMENT" \
    | /usr/bin/sed -E 's/.* anchor=([^ ]+) .*/\1/')
LIFECYCLE_CANDIDATES=$(printf '%s\n' "$LIFECYCLE_PLACEMENT" \
    | /usr/bin/sed -E 's/.* candidates=([^ ]+) rejections=.*/\1/')
LIFECYCLE_DB="$ARTIFACT_ROOT/$LIFECYCLE_SCENARIO/home/Library/Application Support/Pebble/pebble.db"
LIFECYCLE_PLAYER_FACTS=$(/usr/bin/sqlite3 "$LIFECYCLE_DB" \
    "SELECT json_extract(json, '$.data.health'), coalesce(json_extract(json, '$.data.data.deathCause'), 'none'), printf('%d,%d,%d', floor(json_extract(json, '$.data.x')), floor(json_extract(json, '$.data.y')), floor(json_extract(json, '$.data.z'))) FROM player;")
[ "$LIFECYCLE_PLAYER_FACTS" = "20|none|$LIFECYCLE_ANCHOR" ] \
    || fail "lifecycle player facts changed: $LIFECYCLE_PLAYER_FACTS"
printf '%s\t%s\t%s\tREBUILTx3\t%s\t%s\tinactive\t%s\tnone\tnone\n' \
    "$LIFECYCLE_SCENARIO" "46" "$LIFECYCLE_ANCHOR" "$LIFECYCLE_CANDIDATES" \
    "$LIFECYCLE_PLAYER_FACTS" "$LIFECYCLE_TRACE" >> "$MANIFEST"

printf '\n=== unavailable-area refusal ===\n'
REFUSAL_SCENARIO="unavailable-refusal"
REFUSAL_TRACE="$ARTIFACT_ROOT/$REFUSAL_SCENARIO/pebble-live.log"
run_pebble "$REFUSAL_SCENARIO" "12345" \
    '/tp 4096 200 4096;/lab start|/lab status|/lab stop;/lab status' \
    '-|-|-' 0
require_trace "$REFUSAL_TRACE" \
    '^\[lab-live\] bootstrap placement status=refused anchor=4096,200,4096 reason=insufficient_safe_positions found=0 required=3 candidates=[1-9][0-9]*/12000 rejections=.*chunkUnavailable=.* session=none probes=0$' \
    "bounded diagnosed refusal"
require_trace "$REFUSAL_TRACE" \
    '^\[lab-live\] status inactive gate=enabled$' \
    "inactive state after refusal"
reject_trace "$REFUSAL_TRACE" \
    'bootstrap publication status=verified|^\[lab-live\] start seed=|probesRemoved=[1-9]' \
    "partial publication after refusal"

printf '\n=== injected late bootstrap rollback ===\n'
ROLLBACK_SCENARIO="late-rollback"
ROLLBACK_TRACE="$ARTIFACT_ROOT/$ROLLBACK_SCENARIO/pebble-live.log"
run_pebble "$ROLLBACK_SCENARIO" "46" \
    '/lab start|/lab status|/lab stop;/lab status' \
    '-|-|-' 1
require_trace "$ROLLBACK_TRACE" \
    '^\[lab-live\] bootstrap placement status=accepted ' \
    "safe plan before staged publication"
require_trace "$ROLLBACK_TRACE" \
    '^\[lab-live\] bootstrap rollback status=verified cause=.*injected_late_bootstrap_failure.* probesRemoved=2 session=none residual=0$' \
    "exact rollback of staged probes"
require_trace "$ROLLBACK_TRACE" \
    '^\[lab-live\] status inactive gate=enabled$' \
    "inactive state after injected failure"
reject_trace "$ROLLBACK_TRACE" \
    'bootstrap publication status=verified|^\[lab-live\] start seed=|hardFailure=1' \
    "partial or successful publication after injected failure"

if /usr/bin/pgrep -x Pebble >/dev/null 2>&1 \
    || /usr/bin/pgrep -x pebsmoke >/dev/null 2>&1; then
    fail "residual PebbleLab process after safe-bootstrap campaign"
fi

printf '\nPASS: safe bootstrap natural-world matrix, lifecycle rebuilds, bounded refusal, temporal observation, and exact late rollback verified.\n'
printf 'Matrix: %s\n' "$MANIFEST"
printf 'Retained artifacts: %s\n' "$ARTIFACT_ROOT"
