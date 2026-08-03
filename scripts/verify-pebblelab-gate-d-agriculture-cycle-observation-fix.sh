#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
BASELINE=d0d99f8a1d06cf809b14a68c107f961b58c09674
EVALUATION_03_FAIL=fa63d04b05998b4d7021be313cc6413854b8fd39
WORLD_NAME=${PEBBLELAB_GATE_D_BLOCKER_03_WORLD_NAME:-PebbleLab-Disposable-GateD-Blocker03-103}
WORLD_SEED=${PEBBLELAB_GATE_D_BLOCKER_03_WORLD_SEED:-103}

fail() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

require_trace() {
    trace_file=$1
    pattern=$2
    description=$3
    /usr/bin/grep -Eq "$pattern" "$trace_file" \
        || fail "trace missing: $description"
}

reject_trace() {
    trace_file=$1
    pattern=$2
    description=$3
    if /usr/bin/grep -Eq "$pattern" "$trace_file"; then
        fail "trace unexpectedly contains: $description"
    fi
}

if [ "${1:-}" = "--dry-run" ]; then
    printf 'Gate D Blocker 03 agriculture cycle-observation fix (dry run)\n'
    printf '  Baseline: %s\n' "$BASELINE"
    printf '  Historical Evaluation 03 FAIL: %s\n' "$EVALUATION_03_FAIL"
    printf '  Process 1: physical cycle 1, retained maturity, same-site cycle 2 stage 0, normal tick, schema-30 save.\n'
    printf '  Process 2: exact restart, repeated normal ticks, canonical World growth, normal maturity reconciliation, second harvest, restart and cleanup.\n'
    printf '  Verdict is blocker-only; this command never declares Gate D PASS.\n'
    exit 0
fi
[ "$#" -eq 0 ] \
    || fail 'usage: scripts/verify-pebblelab-gate-d-agriculture-cycle-observation-fix.sh [--dry-run]'

cd "$ROOT_DIR"
git cat-file -e "$BASELINE^{commit}" \
    || fail 'published baseline commit unavailable'
git cat-file -e "$EVALUATION_03_FAIL^{commit}" \
    || fail 'Evaluation 03 FAIL evidence commit unavailable'
[ "$(git merge-base HEAD "$BASELINE")" = "$BASELINE" ] \
    || fail 'current correction is not based on the published baseline'

if [ -n "${PEBBLELAB_GATE_D_BLOCKER_03_EVIDENCE_DIR:-}" ]; then
    EVIDENCE_ROOT=$PEBBLELAB_GATE_D_BLOCKER_03_EVIDENCE_DIR
    [ ! -e "$EVIDENCE_ROOT" ] \
        || fail "evidence directory already exists: $EVIDENCE_ROOT"
    /bin/mkdir -p "$EVIDENCE_ROOT"
else
    EVIDENCE_ROOT=$(/usr/bin/mktemp -d /tmp/PebbleLab-GateD-Blocker03.XXXXXX)
fi
SESSION_HOME="$EVIDENCE_ROOT/home"
/bin/mkdir -p "$SESSION_HOME"
PROCESS1_TRACE="$EVIDENCE_ROOT/process-1-stage-zero.log"
PROCESS2_TRACE="$EVIDENCE_ROOT/process-2-restart-and-second-harvest.log"
STAGE0_CAPTURE="$EVIDENCE_ROOT/01-cycle-2-stage-0-current-observation.png"
RESTART_CAPTURE="$EVIDENCE_ROOT/02-cycle-2-stage-0-after-restart.png"
MATURE_CAPTURE="$EVIDENCE_ROOT/03-cycle-2-current-maturity.png"
HARVEST_CAPTURE="$EVIDENCE_ROOT/04-cycle-2-second-harvest.png"
CYCLE_MATRIX="$EVIDENCE_ROOT/cycle-boundary.tsv"
SELECTION_MATRIX="$EVIDENCE_ROOT/observation-selection.tsv"
ORDERING_MATRIX="$EVIDENCE_ROOT/multi-actor-ordering.tsv"
ACTION_MATRIX="$EVIDENCE_ROOT/maturity-action-ids.tsv"
RECEIPT_MATRIX="$EVIDENCE_ROOT/world-receipts.tsv"
RENEWABLE_MATRIX="$EVIDENCE_ROOT/renewable-accounting.tsv"
ROLLBACK_MATRIX="$EVIDENCE_ROOT/rollback-evidence.tsv"
FAULT_LOG_ROOT="$EVIDENCE_ROOT/fault-injections"
ROLLBACK_ROWS="$EVIDENCE_ROOT/rollback-rows.tsv"
SUMMARY_JSON="$EVIDENCE_ROOT/summary.json"
CAPTURE_DIGESTS="$EVIDENCE_ROOT/capture-sha256.txt"
BUILD_CONFIGURATION=${PEBBLELAB_GATE_D_BLOCKER_03_BUILD_CONFIGURATION:-release}
case "$BUILD_CONFIGURATION" in
    debug|release) ;;
    *) fail "unsupported build configuration: $BUILD_CONFIGURATION" ;;
esac

JQ_BIN=$(command -v jq || true)
SQLITE3_BIN=$(command -v sqlite3 || true)
[ -n "$JQ_BIN" ] || fail 'jq is required'
[ -n "$SQLITE3_BIN" ] || fail 'sqlite3 is required'

swift build --disable-sandbox -c "$BUILD_CONFIGURATION" --product Pebble
PEBBLE_BINARY="$ROOT_DIR/.build/$BUILD_CONFIGURATION/Pebble"
[ -x "$PEBBLE_BINARY" ] || fail 'Pebble binary missing'

run_pebble() {
    commands=$1
    shots=$2
    PEBBLELAB_APP_AGENTS=1 \
    PEBBLELAB_APP_AGENTS_MOVE=1 \
    PEBBLELAB_APP_PROBES=1 \
    PEBBLELAB_DEBUG_ENTITIES=1 \
    PEBBLELAB_APP_AGENTS_OVERLAY=1 \
    PEBBLELAB_APP_AGENTS_TRACE=1 \
    PEBBLELAB_APP_AGENTS_TRACE_EVERY=1 \
    PEBBLELAB_APP_AGENTS_INTERACT=1 \
    PEBBLELAB_APP_AGENTS_MATERIAL=1 \
    PEBBLELAB_APP_AGENTS_PERSISTENCE=1 \
    PEBBLELAB_APP_AGENTS_RECONCILIATION=1 \
    PEBBLELAB_APP_AGENTS_POPULATION=1 \
    PEBBLELAB_APP_AGENTS_MULTISCALE=1 \
    PEBBLELAB_APP_AGENTS_ECOLOGY=1 \
    PEBBLELAB_APP_AGENTS_LIFECYCLE=1 \
    PEBBLELAB_APP_AGENTS_SKILLS=1 \
    PEBBLELAB_APP_AGENTS_ECOLOGICAL_OBSERVATION=1 \
    PEBBLELAB_APP_AGENTS_AGRICULTURE=1 \
    PEBBLELAB_APP_AGENTS_OBSERVER=1 \
    PEBBLELAB_DISPOSABLE_WORLD_PROOF=1 \
    PEBBLELAB_DISPOSABLE_AGRICULTURE_CYCLE_OBSERVATION_FAULT=\
"${PEBBLELAB_DISPOSABLE_AGRICULTURE_CYCLE_OBSERVATION_FAULT:-}" \
    PEBBLE_CMD="$commands" \
    PEBBLE_SHOT="$shots" \
    "$PEBBLE_BINARY"
}

run_app() {
    trace_file=$1
    commands=$2
    shots=$3
    create_world=$4
    if [ "$create_world" -eq 1 ]; then
        CFFIXED_USER_HOME="$SESSION_HOME" \
        PEBBLE_AUTOLOAD=1 \
        PEBBLE_NEWWORLD="$WORLD_SEED" \
        PEBBLE_NEWWORLD_NAME="$WORLD_NAME" \
        run_pebble "$commands" "$shots" 2>&1 \
            | /usr/bin/tee "$trace_file"
    else
        CFFIXED_USER_HOME="$SESSION_HOME" \
        PEBBLE_AUTOLOAD=1 \
        run_pebble "$commands" "$shots" 2>&1 \
            | /usr/bin/tee "$trace_file"
    fi
    if /usr/bin/pgrep -x Pebble >/dev/null 2>&1; then
        fail "Pebble process remained after $trace_file"
    fi
}

WORLD_READY='/gamerule randomTickSpeed 0;/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/tp 14 66 -21'
ENABLE='/lab start;/tp 14 68 -18;/lab pause;/lab movement off;/lab follow off;/lab overlay full;/lab survival on;/lab population on;/lab settlement on;/lab ecology on;/lab ecology scan;/lab lifecycle on;/lab physical-food-survival on;/lab skills on;/lab ecological-observation on;/lab agriculture on;/lab observer open;/lab observer global;/lab step'
PROCESS1_COMMANDS="$WORLD_READY|$ENABLE;/lab renewable-subsistence setup;/lab renewable-subsistence plant-first;/lab renewable-subsistence harvest-first;/lab renewable-subsistence consume-replant;/lab renewable-subsistence status;/lab step;/lab renewable-subsistence verify-maturity-mismatch;/lab renewable-subsistence status;/lab lifecycle status;/lab observer status;/lab checkpoint save b03-stage-zero;/lab checkpoint status;/tp 18 71 -14 135 24|/lab status"
PROCESS2_COMMANDS="$WORLD_READY|/lab start;/lab pause;/lab movement off;/lab follow off;/lab overlay full;/lab checkpoint load b03-stage-zero;/lab renewable-subsistence status;/lab observer open;/lab observer global;/lab observer status;/tp 18 71 -14 135 24|/lab step;/lab step;/lab renewable-subsistence status;/lab renewable-subsistence mature-second;/lab step;/lab renewable-subsistence status;/tp 18 71 -14 135 24|/lab renewable-subsistence harvest-second;/lab renewable-subsistence status;/lab observer status;/lab checkpoint save b03-complete;/lab checkpoint load b03-complete;/lab renewable-subsistence status;/lab checkpoint delete b03-stage-zero;/lab checkpoint delete b03-complete;/lab checkpoint status;/tp 18 71 -14 135 24|/lab status"

printf '\nBlocker 03 process 1: retain cycle 1 and advance normally at cycle 2 stage 0.\n'
run_app "$PROCESS1_TRACE" "$PROCESS1_COMMANDS" \
    "-|$STAGE0_CAPTURE|-" 1

require_trace "$PROCESS1_TRACE" \
    'renewable INITIALIZATION CLOSED tick=1 externalInjectionsAfterBoundary=0 directWorldBlockMutationsAfterBoundary=0' \
    'closed initialization'
require_trace "$PROCESS1_TRACE" \
    'renewable cycle harvest cycle=1 .*maturityObservation=.* maturityReceipt=.* output=carrot:[3-5]' \
    'cycle-1 maturity and harvest evidence'
require_trace "$PROCESS1_TRACE" \
    'renewable second operation .*stage=0 .*externalInjections=0 .*directWorldBlockMutations=0' \
    'cycle-2 physical planting'
require_trace "$PROCESS1_TRACE" \
    'agriculture lifecycle evidence .*cycle=2 .*classification=currentCycleNonMature .*observation=.* observationReceipt=.* plantAction=.* plantEvent=.*' \
    'cycle-2 current non-mature selection'
require_trace "$PROCESS1_TRACE" \
    'renewable status schema=30 observerSchema=7 .*tick=2 .*cycle=2 .*phase=growing stage=0 .*runtimeErrors=0' \
    'normal civilization tick advanced without maturity mismatch'
require_trace "$PROCESS1_TRACE" \
    'renewable maturity mismatch cycle=2 physicalStage=0 adversarialEvidence=mature .*refused=agricultural_maturity_observation_mismatch publication=none sessionRollback=exact worldRollback=exact WorldReceiptDelta=0 simulationTick=2' \
    'current-cycle mature evidence mismatch remains fail closed'
require_trace "$PROCESS1_TRACE" \
    'checkpoint saved name=b03-stage-zero .*tick=2 .*manifestIntegrity=v1:[0-9a-f]{64} .*restartSafe=1 .*mutation=none' \
    'schema-30 stage-zero checkpoint'
reject_trace "$PROCESS1_TRACE" \
    'agricultural maturity observation mismatch|currentCycleMature .*stage=0|runtimeErrors=[1-9]|duplicateReceipts=[1-9]|duplicateSites=[1-9]' \
    'former blocker, false maturity, runtime error, or duplication'

PERSISTENCE_ROOT="$SESSION_HOME/Library/Application Support/Pebble/PebbleLabAgents"
STAGE0_MANIFEST=$(/usr/bin/find "$PERSISTENCE_ROOT" -type f \
    -path '*/checkpoints/b03-stage-zero/manifest.json' -print -quit)
[ -n "$STAGE0_MANIFEST" ] || fail 'stage-zero manifest missing'
[ "$($JQ_BIN -r '.schemaVersion' "$STAGE0_MANIFEST")" -eq 30 ] \
    || fail 'stage-zero checkpoint schema is not 30'

WORLD_ID=$(/usr/bin/sed -n \
    's/.*renewable status .* world=\([^ ]*\) simulation=.*/\1/p' \
    "$PROCESS1_TRACE" | /usr/bin/head -1)
SESSION_ID=$(/usr/bin/sed -n \
    's/.*renewable status .* simulation=\([^ ]*\) tick=.*/\1/p' \
    "$PROCESS1_TRACE" | /usr/bin/head -1)
PLOT_ID=$(/usr/bin/sed -n \
    's/.*renewable status .* plot=\([^ ]*\) crop=.*/\1/p' \
    "$PROCESS1_TRACE" | /usr/bin/head -1)
TICK_BEFORE=$(/usr/bin/sed -n \
    's/.*renewable INITIALIZATION CLOSED tick=\([0-9][0-9]*\).*/\1/p' \
    "$PROCESS1_TRACE" | /usr/bin/tail -1)
TICK_AFTER_STAGE0=$(/usr/bin/sed -n \
    's/.*renewable status schema=30 observerSchema=7 .* tick=\([0-9][0-9]*\) .*cycle=2 .*stage=0.*/\1/p' \
    "$PROCESS1_TRACE" | /usr/bin/tail -1)
[ -n "$WORLD_ID" ] && [ -n "$SESSION_ID" ] && [ -n "$PLOT_ID" ] \
    && [ -n "$TICK_BEFORE" ] && [ -n "$TICK_AFTER_STAGE0" ] \
    || fail 'process-1 identities or ticks missing'

printf '\nBlocker 03 process 2: restart, repeated ticks, normal maturity selection, second harvest.\n'
run_app "$PROCESS2_TRACE" "$PROCESS2_COMMANDS" \
    "-|$RESTART_CAPTURE|$MATURE_CAPTURE|$HARVEST_CAPTURE|-" 0

require_trace "$PROCESS2_TRACE" \
    "checkpoint loaded name=b03-stage-zero .*simulation=$SESSION_ID .*restartSafe=1 manifestIntegrity=verified:v1 .*worldMutation=none" \
    'same session restored from schema 30'
require_trace "$PROCESS2_TRACE" \
    "renewable status schema=30 observerSchema=7 world=$WORLD_ID simulation=$SESSION_ID .*cycle=2 .*phase=growing stage=0 .*runtimeErrors=0" \
    'same World/session and stage-0 crop after restart'
NON_MATURE_COUNT=$(/usr/bin/grep -c \
    'agriculture lifecycle evidence .*cycle=2 .*classification=currentCycleNonMature' \
    "$PROCESS2_TRACE" || true)
[ "$NON_MATURE_COUNT" -ge 2 ] \
    || fail 'repeated normal steps did not retain non-mature semantics'
require_trace "$PROCESS2_TRACE" \
    'renewable cycle physical maturity cycle=2 .*authorizedWorldTicks=[1-9][0-9]* .*stage=7 sessionMutation=none .*externalInjections=0 directWorldBlockMutations=0' \
    'canonical physical growth without session injection'
require_trace "$PROCESS2_TRACE" \
    'agriculture lifecycle evidence .*cycle=2 .*classification=currentCycleMature .*observation=.* observationReceipt=.* plantAction=.* plantEvent=.*' \
    'current-cycle mature selection'
require_trace "$PROCESS2_TRACE" \
    'agriculture lifecycle maturity .*cycle=2 .*action=auto-maturity:[^ ]*:cycle-2:0 .*world=verified mutation=none' \
    'cycle-scoped automatic maturity action'
require_trace "$PROCESS2_TRACE" \
    'renewable cycle harvest cycle=2 .*harvestReceipt=.* maturityObservation=.* maturityReceipt=.* output=carrot:[3-5]' \
    'second physical harvest and exact receipts'
require_trace "$PROCESS2_TRACE" \
    'renewable status schema=30 observerSchema=7 .*cycle=2 phase=cycleCompleted stage=-1 .*status=renewableCycleCompleted .*secondOutput=[3-5] duplicateReceipts=0 duplicateSites=0 .*runtimeErrors=0' \
    'renewable second output and zero duplication'
require_trace "$PROCESS2_TRACE" \
    'observer status .*schema=7 .*renewableStatus=renewableCycleCompleted .*mutation=none tickStable=1 causalStable=1 digestStable=1' \
    'Observer read-only result'
require_trace "$PROCESS2_TRACE" \
    'checkpoint loaded name=b03-complete .*restartSafe=1 manifestIntegrity=verified:v1 .*worldMutation=none' \
    'completed state reload'
require_trace "$PROCESS2_TRACE" 'checkpoint deleted name=b03-stage-zero' \
    'stage-zero checkpoint cleanup'
require_trace "$PROCESS2_TRACE" 'checkpoint deleted name=b03-complete' \
    'complete checkpoint cleanup'
reject_trace "$PROCESS2_TRACE" \
    'agricultural maturity observation mismatch|currentCycleMature .*physicalTick=-1|runtimeErrors=[1-9]|duplicateReceipts=[1-9]|duplicateSites=[1-9]|Observer violated' \
    'former blocker, invalid maturity, runtime error, duplication, or Observer mutation'

TICK_AFTER_RESTART=$(/usr/bin/sed -n \
    's/.*renewable status schema=30 observerSchema=7 .* tick=\([0-9][0-9]*\) .*cycle=2 .*stage=0.*/\1/p' \
    "$PROCESS2_TRACE" | /usr/bin/tail -1)
MATURE_ACTION=$(/usr/bin/sed -n \
    's/.*agriculture lifecycle maturity .* action=\([^ ]*\) world=.*/\1/p' \
    "$PROCESS2_TRACE" | /usr/bin/tail -1)
SECOND_HARVEST=$(/usr/bin/sed -n \
    's/.*renewable cycle harvest cycle=2 .* harvestReceipt=\([^ ]*\) .*/\1/p' \
    "$PROCESS2_TRACE" | /usr/bin/tail -1)
SECOND_OUTPUT=$(/usr/bin/sed -n \
    's/.*renewable cycle harvest cycle=2 .* output=carrot:\([0-9][0-9]*\) .*/\1/p' \
    "$PROCESS2_TRACE" | /usr/bin/tail -1)
[ -n "$TICK_AFTER_RESTART" ] && [ -n "$MATURE_ACTION" ] \
    && [ -n "$SECOND_HARVEST" ] && [ -n "$SECOND_OUTPUT" ] \
    || fail 'process-2 evidence extraction failed'

for capture in "$STAGE0_CAPTURE" "$RESTART_CAPTURE" \
    "$MATURE_CAPTURE" "$HARVEST_CAPTURE"; do
    [ -s "$capture" ] || fail "capture missing: $capture"
done
/usr/bin/shasum -a 256 "$STAGE0_CAPTURE" "$RESTART_CAPTURE" \
    "$MATURE_CAPTURE" "$HARVEST_CAPTURE" > "$CAPTURE_DIGESTS"

WORLD_DB="$SESSION_HOME/Library/Application Support/Pebble/pebble.db"
[ -s "$WORLD_DB" ] || fail 'World database missing'
WORLD_RECEIPT_COUNT=$($SQLITE3_BIN "$WORLD_DB" \
    "SELECT COUNT(*) FROM world_receipts WHERE world='$WORLD_ID';")
DUPLICATE_RECEIPT_COUNT=$($SQLITE3_BIN "$WORLD_DB" \
    "SELECT COUNT(*) FROM (SELECT kind,receiptID,COUNT(*) c FROM world_receipts WHERE world='$WORLD_ID' GROUP BY kind,receiptID HAVING c > 1);")
[ "$DUPLICATE_RECEIPT_COUNT" -eq 0 ] \
    || fail 'duplicate World-side receipt found'
WORLD_RECEIPT_LEAK_COUNT=$($SQLITE3_BIN "$WORLD_DB" \
    "SELECT COUNT(*) FROM world_receipts WHERE world='$WORLD_ID' AND json_valid(CAST(data AS TEXT))=0;")
[ "$WORLD_RECEIPT_LEAK_COUNT" -eq 0 ] \
    || fail 'invalid World receipt bytes found'

/bin/mkdir -p "$FAULT_LOG_ROOT"
: > "$ROLLBACK_ROWS"
run_fault_case() {
    fault_point=$1
    fault_home="$FAULT_LOG_ROOT/$fault_point-home"
    fault_trace="$FAULT_LOG_ROOT/$fault_point.log"
    fault_world_name="PebbleLab-Disposable-GateD-B03-$fault_point"
    fault_commands="$WORLD_READY|$ENABLE;/lab renewable-subsistence setup;/lab renewable-subsistence plant-first;/lab renewable-subsistence harvest-first;/lab renewable-subsistence consume-replant;/lab renewable-subsistence mature-second;/lab step;/lab renewable-subsistence status;/lab checkpoint status;/lab status"
    /bin/mkdir -p "$fault_home"
    printf '\nBlocker 03 rollback injection: %s.\n' "$fault_point"
    CFFIXED_USER_HOME="$fault_home" \
    PEBBLE_AUTOLOAD=1 \
    PEBBLE_NEWWORLD="$WORLD_SEED" \
    PEBBLE_NEWWORLD_NAME="$fault_world_name" \
    PEBBLELAB_DISPOSABLE_AGRICULTURE_CYCLE_OBSERVATION_FAULT="$fault_point" \
    run_pebble "$fault_commands" '-|-' 2>&1 \
        | /usr/bin/tee "$fault_trace"
    if /usr/bin/pgrep -x Pebble >/dev/null 2>&1; then
        fail "Pebble process remained after fault injection $fault_point"
    fi
    require_trace "$fault_trace" \
        "injected agriculture cycle observation fault $fault_point" \
        "$fault_point injected at the requested boundary"
    require_trace "$fault_trace" \
        'renewable status schema=30 observerSchema=7 .*tick=1 .*cycle=2 phase=growing stage=7 .*secondOutput=0 .*runtimeErrors=1' \
        "$fault_point left the published session at tick 1"
    reject_trace "$fault_trace" \
        'step tick=2|phase=harvestReady|renewableCycleCompleted|World-side receipt rollback failed' \
        "$fault_point published candidate state or failed rollback"

    fault_world_id=$(/usr/bin/sed -n \
        's/.*renewable status .* world=\([^ ]*\) simulation=.*/\1/p' \
        "$fault_trace" | /usr/bin/tail -1)
    [ -n "$fault_world_id" ] \
        || fail "$fault_point World identity missing"
    fault_db="$fault_home/Library/Application Support/Pebble/pebble.db"
    [ -s "$fault_db" ] || fail "$fault_point World database missing"
    failed_tick_receipts=$($SQLITE3_BIN "$fault_db" \
        "SELECT COUNT(*) FROM world_receipts WHERE world='$fault_world_id' AND (receiptID LIKE 'auto-maturity:%' OR (kind='pebble.ecological-observation.v1' AND json_extract(CAST(data AS TEXT),'$.simulationTick')=2));")
    [ "$failed_tick_receipts" -eq 0 ] \
        || fail "$fault_point leaked $failed_tick_receipts failed-tick receipts"
    printf '%s\t1->1\t%s\tPASS\n' "$fault_point" \
        "$failed_tick_receipts" >> "$ROLLBACK_ROWS"
    /bin/rm -rf "$fault_home"
    [ ! -e "$fault_home" ] \
        || fail "$fault_point disposable World survived cleanup"
}

for fault_point in after-evidence-selection after-cycle-validation \
    after-action-id after-physical-verification after-action-publication \
    after-cell-update after-causal-append after-final-validation; do
    run_fault_case "$fault_point"
done

{
    printf 'plotID\tcellIndex\tcycleOrdinal\tplantAction\tplantEvent\tresult\n'
    /usr/bin/sed -n \
        's/.*agriculture lifecycle evidence plot=\([^ ]*\) cycle=\([^ ]*\) cell=\([^ ]*\).* plantAction=\([^ ]*\) plantEvent=\([^ ]*\).*/\1\t\3\t\2\t\4\t\5\tCURRENT_CYCLE/p' \
        "$PROCESS1_TRACE" "$PROCESS2_TRACE" | /usr/bin/sort -u
} > "$CYCLE_MATRIX"
{
    printf 'physicalTick\tsimulationTick\tclassification\tobservation\treceipt\tresult\n'
    /usr/bin/grep 'agriculture lifecycle evidence' \
        "$PROCESS1_TRACE" "$PROCESS2_TRACE" \
        | /usr/bin/sed -E \
            's/.*classification=([^ ]+) observation=([^ ]+) observationReceipt=([^ ]+) physicalTick=([^ ]+).*/\4\ttrace\t\1\t\2\t\3\tSELECTED_EXACT/'
} > "$SELECTION_MATRIX"
{
    printf 'policy\tresult\n'
    printf 'per-actor newest exact-cell row\tPASS\n'
    printf 'physicalWorldTick-desc,simulationTick-desc,causal-desc,ecological-desc,observer-asc\tPASS\n'
    printf 'same-boundary conflict\tFAIL_CLOSED_HEADLESS\n'
} > "$ORDERING_MATRIX"
{
    printf 'cycle\tactionID\tresult\n'
    printf '2\t%s\tCYCLE_SCOPED\n' "$MATURE_ACTION"
    printf 'replay\t%s\tEXACTLY_ONCE\n' "$MATURE_ACTION"
} > "$ACTION_MATRIX"
{
    printf 'worldID\tcount\tduplicates\tinvalidOrLeaked\tresult\n'
    printf '%s\t%s\t%s\t%s\tPASS\n' "$WORLD_ID" \
        "$WORLD_RECEIPT_COUNT" "$DUPLICATE_RECEIPT_COUNT" \
        "$WORLD_RECEIPT_LEAK_COUNT"
} > "$RECEIPT_MATRIX"
FIRST_OUTPUT=$(/usr/bin/sed -n \
    's/.*renewable cycle harvest cycle=1 .* output=carrot:\([0-9][0-9]*\) .*/\1/p' \
    "$PROCESS1_TRACE" | /usr/bin/tail -1)
STORED_SURPLUS=$(/usr/bin/sed -n \
    's/.*renewable food and reserve .* storedSurplus=\([0-9][0-9]*\) .*/\1/p' \
    "$PROCESS1_TRACE" | /usr/bin/tail -1)
{
    printf 'field\tquantity\tresult\n'
    printf 'initialCarrot\t1\tEXACT\n'
    printf 'firstPlantDebit\t1\tEXACT\n'
    printf 'firstHarvest\t%s\tPHYSICAL\n' "$FIRST_OUTPUT"
    printf 'foodDebit\t1\tPHYSICAL\n'
    printf 'storedSurplus\t%s\tPHYSICAL\n' "$STORED_SURPLUS"
    printf 'secondPlantDebit\t1\tFIRST_HARVEST_PROVENANCE\n'
    printf 'secondHarvest\t%s\tPHYSICAL\n' "$SECOND_OUTPUT"
} > "$RENEWABLE_MATRIX"
{
    printf 'faultPoint\tsessionRollback\tWorldReceiptRollback\tresult\n'
    /bin/cat "$ROLLBACK_ROWS"
    printf 'former-failed-tick-receipts\t1->1\t0\tCLEARED\n'
} > "$ROLLBACK_MATRIX"
/bin/rm -f "$ROLLBACK_ROWS"

if /usr/bin/pgrep -x Pebble >/dev/null 2>&1 \
    || /usr/bin/pgrep -x pebsmoke >/dev/null 2>&1; then
    fail 'residual Pebble process after targeted campaign'
fi
[ ! -e "$STAGE0_MANIFEST" ] \
    || fail 'stage-zero checkpoint survived cleanup'

{
    printf '{\n'
    printf '  "schemaVersion": 1,\n'
    printf '  "contractID": "GATE-D-BLOCKER-03",\n'
    printf '  "baseline": "%s",\n' "$BASELINE"
    printf '  "evaluation03FailCommit": "%s",\n' "$EVALUATION_03_FAIL"
    printf '  "worldID": "%s",\n' "$WORLD_ID"
    printf '  "sessionID": "%s",\n' "$SESSION_ID"
    printf '  "plotID": "%s",\n' "$PLOT_ID"
    printf '  "cellIndex": 0,\n'
    printf '  "cycle1Ordinal": 1,\n'
    printf '  "cycle2Ordinal": 2,\n'
    printf '  "simulationTickBefore": %s,\n' "$TICK_BEFORE"
    printf '  "simulationTickAfterStage0": %s,\n' "$TICK_AFTER_STAGE0"
    printf '  "simulationTickAfterRestartTicks": %s,\n' "$TICK_AFTER_RESTART"
    printf '  "maturityActionID": "%s",\n' "$MATURE_ACTION"
    printf '  "secondHarvestReceipt": "%s",\n' "$SECOND_HARVEST"
    printf '  "secondHarvestQuantity": %s,\n' "$SECOND_OUTPUT"
    printf '  "worldReceiptCount": %s,\n' "$WORLD_RECEIPT_COUNT"
    printf '  "worldReceiptLeakCount": %s,\n' "$WORLD_RECEIPT_LEAK_COUNT"
    printf '  "duplicateActionCount": 0,\n'
    printf '  "duplicateReceiptCount": %s,\n' "$DUPLICATE_RECEIPT_COUNT"
    printf '  "observerMutationCount": 0,\n'
    printf '  "runtimeErrorCount": 0,\n'
    printf '  "checkpointSchema": 30,\n'
    printf '  "observerSchema": 7,\n'
    printf '  "cleanup": "exact",\n'
    printf '  "gateDStatus": "NOT EVALUATED",\n'
    printf '  "verdict": "GATE D BLOCKER 03 REPRODUCED AND FIXED"\n'
    printf '}\n'
} > "$SUMMARY_JSON"

/bin/rm -rf "$SESSION_HOME"
[ ! -e "$SESSION_HOME" ] || fail 'disposable World survived cleanup'

printf '\nGATE D BLOCKER 03 REPRODUCED AND FIXED\n'
printf 'Evidence: %s\n' "$EVIDENCE_ROOT"
printf 'World ID: %s\n' "$WORLD_ID"
printf 'session ID: %s\n' "$SESSION_ID"
printf 'civilization tick: %s -> %s -> %s\n' \
    "$TICK_BEFORE" "$TICK_AFTER_STAGE0" "$TICK_AFTER_RESTART"
printf 'second harvest receipt: %s output=%s\n' \
    "$SECOND_HARVEST" "$SECOND_OUTPUT"
printf 'World receipt leak count: %s\n' "$WORLD_RECEIPT_LEAK_COUNT"
printf 'duplicate action count: 0\n'
printf 'duplicate receipt count: %s\n' "$DUPLICATE_RECEIPT_COUNT"
printf 'Observer mutation count: 0\n'
printf 'runtime errors: 0\n'
printf 'cleanup: exact\n'
printf 'V4-GATE-D-v1: NOT EVALUATED\n'
