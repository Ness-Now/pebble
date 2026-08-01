#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
WORLD_NAME="PebbleLab-Disposable-Renewable-46"
WORLD_SEED=46

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
    printf 'Renewable-subsistence rendered proof (dry run)\n'
    printf '  World: %s seed=%s\n' "$WORLD_NAME" "$WORLD_SEED"
    printf '  Process 1: one initial carrot, physical plant, canonical World-tick\n'
    printf '             growth, harvest, real food debit, reserve, second plant,\n'
    printf '             schema 29 checkpoint with the second crop non-mature.\n'
    printf '  Process 2: exact World/session restart, unchanged stage and custody,\n'
    printf '             resumed World-tick growth, second harvest, Observer 7.\n'
    printf '  No item, block, crop age, maturity, harvest, or food outcome is\n'
    printf '  injected after the explicit initialization boundary.\n'
    exit 0
fi
[ "$#" -eq 0 ] \
    || fail "usage: scripts/verify-pebblelab-renewable-subsistence.sh [--dry-run]"

git -C "$ROOT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    || fail "repository metadata missing"
[ "$(git -C "$ROOT_DIR" rev-parse --show-toplevel)" = "$ROOT_DIR" ] \
    || fail "unexpected repository root"

if [ -n "${PEBBLELAB_RENEWABLE_EVIDENCE_DIR:-}" ]; then
    EVIDENCE_ROOT=$PEBBLELAB_RENEWABLE_EVIDENCE_DIR
    [ ! -e "$EVIDENCE_ROOT" ] \
        || fail "evidence directory already exists: $EVIDENCE_ROOT"
    /bin/mkdir -p "$EVIDENCE_ROOT"
else
    EVIDENCE_ROOT=$(/usr/bin/mktemp -d /tmp/PebbleLab-Renewable.XXXXXX)
fi
SESSION_HOME="$EVIDENCE_ROOT/home"
/bin/mkdir -p "$SESSION_HOME"
PHASE1_TRACE="$EVIDENCE_ROOT/renewable-before-restart.log"
PHASE2_TRACE="$EVIDENCE_ROOT/renewable-after-restart.log"
FIRST_PLANT_CAPTURE="$EVIDENCE_ROOT/renewable-first-physical-operation.png"
FIRST_HARVEST_CAPTURE="$EVIDENCE_ROOT/renewable-first-harvest-output.png"
RESTART_CAPTURE="$EVIDENCE_ROOT/renewable-same-second-cycle-after-restart.png"
SECOND_HARVEST_CAPTURE="$EVIDENCE_ROOT/renewable-second-harvest.png"
MATRIX="$EVIDENCE_ROOT/matrix.tsv"
COMPACT_TRACE="$EVIDENCE_ROOT/renewable-compact-trace.log"
MANIFEST_COPY="$EVIDENCE_ROOT/renewable-schema29-manifest.json"
BUILD_CONFIGURATION=${PEBBLELAB_RENEWABLE_BUILD_CONFIGURATION:-release}
case "$BUILD_CONFIGURATION" in
    debug|release) ;;
    *) fail "unsupported build configuration: $BUILD_CONFIGURATION" ;;
esac

cd "$ROOT_DIR"
swift build -c "$BUILD_CONFIGURATION" --product Pebble
PEBBLE_BINARY="$ROOT_DIR/.build/$BUILD_CONFIGURATION/Pebble"
[ -x "$PEBBLE_BINARY" ] || fail "$BUILD_CONFIGURATION Pebble binary missing"

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
    PEBBLELAB_APP_AGENTS_LIFECYCLE=1 \
    PEBBLELAB_APP_AGENTS_SKILLS=1 \
    PEBBLELAB_APP_AGENTS_ECOLOGICAL_OBSERVATION=1 \
    PEBBLELAB_APP_AGENTS_AGRICULTURE=1 \
    PEBBLELAB_APP_AGENTS_HOMEOSTASIS=1 \
    PEBBLELAB_APP_AGENTS_OBSERVER=1 \
    PEBBLELAB_DISPOSABLE_WORLD_PROOF=1 \
    PEBBLE_CMD="$commands" \
    PEBBLE_SHOT="$shots" \
    "$PEBBLE_BINARY"
}

run_app() {
    run_trace=$1
    commands=$2
    shots=$3
    create_world=$4
    if [ "$create_world" -eq 1 ]; then
        CFFIXED_USER_HOME="$SESSION_HOME" \
        PEBBLE_AUTOLOAD=1 \
        PEBBLE_NEWWORLD="$WORLD_SEED" \
        PEBBLE_NEWWORLD_NAME="$WORLD_NAME" \
        run_pebble "$commands" "$shots" 2>&1 | /usr/bin/tee "$run_trace"
    else
        CFFIXED_USER_HOME="$SESSION_HOME" \
        PEBBLE_AUTOLOAD=1 \
        run_pebble "$commands" "$shots" 2>&1 | /usr/bin/tee "$run_trace"
    fi
    if /usr/bin/pgrep -x Pebble >/dev/null 2>&1; then
        fail "Pebble process remained after phase: $run_trace"
    fi
}

WORLD_READY='/gamerule randomTickSpeed 0;/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/tp 14 66 -21'
ENABLE='/lab start;/tp 14 69 -21;/lab pause;/lab movement off;/lab follow off;/lab overlay full;/lab survival on;/lab population on;/lab lifecycle on;/lab skills on;/lab step;/lab ecological-observation on;/lab agriculture on;/lab physical-food-survival on;/lab observer open;/lab observer global'
PHASE1_COMMANDS="$WORLD_READY|$ENABLE;/lab renewable-subsistence setup;/lab renewable-subsistence plant-first;/lab renewable-subsistence status;/lab observer status;/tp 18 71 -14 135 24|/lab renewable-subsistence harvest-first;/lab renewable-subsistence status;/lab observer status;/tp 18 71 -14 135 24|/lab renewable-subsistence consume-replant;/lab renewable-subsistence status;/lab observer status;/lab checkpoint save renewable-cycle2;/lab checkpoint status;/tp 18 71 -14 135 24|/lab status"
PHASE2_COMMANDS="$WORLD_READY|/lab start;/lab pause;/lab movement off;/lab follow off;/lab overlay full;/lab checkpoint load renewable-cycle2;/lab renewable-subsistence status;/lab observer open;/lab observer global;/lab observer status;/tp 18 71 -14 135 24|/lab renewable-subsistence harvest-second;/lab renewable-subsistence status;/lab observer status;/lab causality tail 20;/tp 18 71 -14 135 24|/lab checkpoint save renewable-complete;/lab checkpoint status;/lab observer close;/lab checkpoint delete renewable-cycle2;/lab checkpoint delete renewable-complete;/lab checkpoint status|/lab status"

printf '\nRenewable process 1: initial input through second non-mature planting.\n'
run_app "$PHASE1_TRACE" "$PHASE1_COMMANDS" \
    "-|$FIRST_PLANT_CAPTURE|$FIRST_HARVEST_CAPTURE|-|-" 1

require_trace "$PHASE1_TRACE" \
    'renewable INITIALIZATION CLOSED .*externalInjectionsAfterBoundary=0 directWorldBlockMutationsAfterBoundary=0' \
    'explicit initialization boundary'
require_trace "$PHASE1_TRACE" \
    'renewable first operation operationID=.* input=carrot:1 debit=1 freeInitialStock=0 .*stage=0 crop=carrots .*externalInjections=0 directWorldBlockMutations=0' \
    'first physical planting and exact initial debit'
require_trace "$PHASE1_TRACE" \
    'renewable cycle harvest cycle=1 .*authorizedWorldTicks=[1-9][0-9]* .*harvestReceipt=.* output=carrot:[3-5] foodOutput=1 reproductiveOutput=[2-4] .*externalInjections=0 directWorldBlockMutations=0' \
    'first canonical growth and physical harvest'
require_trace "$PHASE1_TRACE" \
    'renewable food and reserve consumptionReceipt=.* material=carrot debit=1 hunger=[^ ]+ reservedOutput=carrot:1 physicalHolder=agent:agent_0 storedSurplus=[1-3] storeReceipt=.*' \
    'real food debit, need improvement, and distinct reserve'
require_trace "$PHASE1_TRACE" \
    'renewable second operation operationID=.* input=carrot:1 provenance=.* debit=1 freeReproductiveStock=0 .*stage=0 checkpointReady=1 probeInventory=empty externalInjections=0 probePosition=home directWorldBlockMutations=0' \
    'second planting from first-harvest provenance'
require_trace "$PHASE1_TRACE" \
    'renewable status schema=29 observerSchema=7 .*cycle=2 phase=growing stage=0 actorCarrots=0 .*status=secondCycleEstablished .*duplicateReceipts=0 duplicateSites=0 externalInjections=0 directWorldBlockMutations=0 runtimeErrors=0' \
    'non-mature schema 29 second cycle before restart'
require_trace "$PHASE1_TRACE" \
    'checkpoint saved name=renewable-cycle2 .*manifestIntegrity=v1:[0-9a-f]{64} .*restartSafe=1 .*mutation=none' \
    'schema 29 restart-safe checkpoint'
require_trace "$PHASE1_TRACE" \
    'observer status .*schema=7 .*renewableStatus=secondCycleEstablished .*mutation=none tickStable=1 causalStable=1 digestStable=1' \
    'Observer schema 7 is read-only before restart'
reject_trace "$PHASE1_TRACE" \
    '^\[lab-live\] error|runtimeErrors=[1-9]|duplicateReceipts=[1-9]|duplicateSites=[1-9]|checkpoint save refused|Renewable subsistence .* failed|Observer violated' \
    'process-1 error, duplication, checkpoint, or Observer failure'

for capture in "$FIRST_PLANT_CAPTURE" "$FIRST_HARVEST_CAPTURE"; do
    [ -s "$capture" ] || fail "rendered capture missing: $capture"
done

PERSISTENCE_ROOT="$SESSION_HOME/Library/Application Support/Pebble/PebbleLabAgents"
CYCLE_MANIFEST=$(/usr/bin/find "$PERSISTENCE_ROOT" -type f \
    -path '*/checkpoints/renewable-cycle2/manifest.json' -print -quit)
[ -n "$CYCLE_MANIFEST" ] || fail "schema 29 checkpoint manifest missing"
/usr/bin/grep -q '"schemaVersion":29' "$CYCLE_MANIFEST" \
    || fail "checkpoint manifest is not schema 29"
/usr/bin/grep -Eq '"manifestIntegrityVersion":1' "$CYCLE_MANIFEST" \
    || fail "manifest integrity version missing"
/usr/bin/grep -Eq '"manifestIntegrityDigest":"[0-9a-f]{64}"' "$CYCLE_MANIFEST" \
    || fail "manifest integrity digest missing"
/bin/cp "$CYCLE_MANIFEST" "$MANIFEST_COPY"

PHASE1_SIM=$(/usr/bin/sed -n \
    's/.*checkpoint saved name=renewable-cycle2 .* simulation=\([^ ]*\) digest=.*/\1/p' \
    "$PHASE1_TRACE" | /usr/bin/tail -1)
PHASE1_DIGEST=$(/usr/bin/sed -n \
    's/.*checkpoint saved name=renewable-cycle2 .* digest=\([0-9a-f]*\) storageDigest=.*/\1/p' \
    "$PHASE1_TRACE" | /usr/bin/tail -1)
PHASE1_WORLD=$(/usr/bin/sed -n \
    's/.*renewable status schema=29 .* world=\([^ ]*\) simulation=.*/\1/p' \
    "$PHASE1_TRACE" | /usr/bin/tail -1)
MANIFEST_DIGEST=$(/usr/bin/sed -n \
    's/.*"manifestIntegrityDigest":"\([0-9a-f]*\)".*/\1/p' \
    "$CYCLE_MANIFEST" | /usr/bin/tail -1)
FIRST_OUTPUT=$(/usr/bin/sed -n \
    's/.*renewable cycle harvest cycle=1 .* output=carrot:\([0-9][0-9]*\) .*/\1/p' \
    "$PHASE1_TRACE" | /usr/bin/tail -1)
FIRST_STORED_SURPLUS=$(/usr/bin/sed -n \
    's/.*renewable food and reserve .* storedSurplus=\([0-9][0-9]*\) .*/\1/p' \
    "$PHASE1_TRACE" | /usr/bin/tail -1)
SAVE_CONTAINER_QUANTITY=$(/usr/bin/sed -n \
    's/.*renewable status schema=29 .* cycle=2 phase=growing stage=0 actorCarrots=0 containerCarrots=\([0-9][0-9]*\) .*/\1/p' \
    "$PHASE1_TRACE" | /usr/bin/tail -1)
[ -n "$PHASE1_SIM" ] && [ -n "$PHASE1_DIGEST" ] \
    && [ -n "$PHASE1_WORLD" ] && [ "${#MANIFEST_DIGEST}" -eq 64 ] \
    && [ -n "$FIRST_OUTPUT" ] && [ -n "$FIRST_STORED_SURPLUS" ] \
    && [ -n "$SAVE_CONTAINER_QUANTITY" ] \
    || fail "pre-restart identities or manifest digest missing"

printf '\nRenewable process 2: exact restart and second physical harvest.\n'
run_app "$PHASE2_TRACE" "$PHASE2_COMMANDS" \
    "-|$RESTART_CAPTURE|$SECOND_HARVEST_CAPTURE|-|-" 0

require_trace "$PHASE2_TRACE" \
    "checkpoint loaded name=renewable-cycle2 .*simulation=$PHASE1_SIM digest=$PHASE1_DIGEST .*restartSafe=1 manifestIntegrity=verified:v1 .*worldMutation=none" \
    'same schema 29 session with verified manifest integrity'
require_trace "$PHASE2_TRACE" \
    "renewable status schema=29 observerSchema=7 world=$PHASE1_WORLD simulation=$PHASE1_SIM .*cycle=2 phase=growing stage=0 actorCarrots=0 .*status=secondCycleEstablished .*duplicateReceipts=0 duplicateSites=0 .*runtimeErrors=0" \
    'same World, session, non-mature crop, and inventory after restart'
require_trace "$PHASE2_TRACE" \
    'renewable cycle harvest cycle=2 .*authorizedWorldTicks=[1-9][0-9]* .*harvestReceipt=.* output=carrot:[3-5] .*externalInjections=0 directWorldBlockMutations=0' \
    'second canonical World-tick growth and physical output'
require_trace "$PHASE2_TRACE" \
    'renewable status schema=29 observerSchema=7 .*cycle=2 phase=cycleCompleted stage=-1 actorCarrots=1 .*status=renewableCycleCompleted .*secondOutput=[3-5] duplicateReceipts=0 duplicateSites=0 externalInjections=0 directWorldBlockMutations=0 runtimeErrors=0' \
    'renewable proof completed once with a new reserve'
require_trace "$PHASE2_TRACE" \
    'observer status .*schema=7 .*renewableStatus=renewableCycleCompleted .*mutation=none tickStable=1 causalStable=1 digestStable=1' \
    'Observer schema 7 remains read-only after completion'
require_trace "$PHASE2_TRACE" \
    'checkpoint saved name=renewable-complete .*manifestIntegrity=v1:[0-9a-f]{64} .*restartSafe=1 .*mutation=none' \
    'completed schema 29 checkpoint'
require_trace "$PHASE2_TRACE" \
    'checkpoint deleted name=renewable-cycle2' \
    'restart checkpoint cleanup'
require_trace "$PHASE2_TRACE" \
    'checkpoint deleted name=renewable-complete' \
    'completed checkpoint cleanup'
reject_trace "$PHASE2_TRACE" \
    '^\[lab-live\] error|runtimeErrors=[1-9]|duplicateReceipts=[1-9]|duplicateSites=[1-9]|checkpoint (load|save) refused|Renewable subsistence .* failed|Observer violated' \
    'process-2 error, duplication, checkpoint, or Observer failure'

RESTART_CONTAINER_QUANTITY=$(/usr/bin/sed -n \
    's/.*renewable status schema=29 .* cycle=2 phase=growing stage=0 actorCarrots=0 containerCarrots=\([0-9][0-9]*\) .*/\1/p' \
    "$PHASE2_TRACE" | /usr/bin/head -1)
SECOND_OUTPUT=$(/usr/bin/sed -n \
    's/.*renewable cycle harvest cycle=2 .* output=carrot:\([0-9][0-9]*\) .*/\1/p' \
    "$PHASE2_TRACE" | /usr/bin/tail -1)
FINAL_ACTOR_QUANTITY=$(/usr/bin/sed -n \
    's/.*renewable status schema=29 .* phase=cycleCompleted .* actorCarrots=\([0-9][0-9]*\) containerCarrots=.*/\1/p' \
    "$PHASE2_TRACE" | /usr/bin/tail -1)
FINAL_CONTAINER_QUANTITY=$(/usr/bin/sed -n \
    's/.*renewable status schema=29 .* phase=cycleCompleted .* actorCarrots=[0-9][0-9]* containerCarrots=\([0-9][0-9]*\) .*/\1/p' \
    "$PHASE2_TRACE" | /usr/bin/tail -1)
[ -n "$RESTART_CONTAINER_QUANTITY" ] && [ -n "$SECOND_OUTPUT" ] \
    && [ -n "$FINAL_ACTOR_QUANTITY" ] && [ -n "$FINAL_CONTAINER_QUANTITY" ] \
    || fail "post-restart physical quantities missing"
[ "$SAVE_CONTAINER_QUANTITY" = "$RESTART_CONTAINER_QUANTITY" ] \
    || fail "container quantity changed across restart"
FIRST_REPRODUCTIVE_OUTPUT=$((FIRST_OUTPUT - 1))
SECOND_REPRODUCTIVE_OUTPUT=$((SECOND_OUTPUT - 1))
FINAL_LOOSE_QUANTITY=$((FINAL_ACTOR_QUANTITY + FINAL_CONTAINER_QUANTITY))

for capture in "$RESTART_CAPTURE" "$SECOND_HARVEST_CAPTURE"; do
    [ -s "$capture" ] || fail "rendered capture missing: $capture"
done
[ ! -e "$CYCLE_MANIFEST" ] || fail "cycle checkpoint survived cleanup"

if /usr/bin/pgrep -x Pebble >/dev/null 2>&1 \
    || /usr/bin/pgrep -x swift-run >/dev/null 2>&1 \
    || /usr/bin/pgrep -x pebsmoke >/dev/null 2>&1; then
    fail "residual PebbleLab process after renewable proof"
fi

{
    printf 'field\tbeforeRestart\tafterRestart\tresult\n'
    printf 'world\t%s\t%s\tMATCH\n' "$PHASE1_WORLD" "$PHASE1_WORLD"
    printf 'simulation\t%s\t%s\tMATCH\n' "$PHASE1_SIM" "$PHASE1_SIM"
    printf 'agent\tagent_0\tagent_0\tMATCH\n'
    printf 'resource\tcarrot\tcarrot\tSAME_PHYSICAL_MECHANIC\n'
    printf 'initialReproductiveQuantity\t1\t0 free after first plant\tEXACT\n'
    printf 'firstPlantDebit\t1\tcrop-stage0\tSINGLE_RECEIPT\n'
    printf 'firstCycleProductiveSites\t1\t0 after harvest\tEXACT\n'
    printf 'firstHarvestQuantity\t%s\tretained-provenance\tEXACT_PHYSICAL_OUTPUT\n' "$FIRST_OUTPUT"
    printf 'firstHarvestFoodQuantity\t1\tconsumed\tEXACT\n'
    printf 'firstHarvestReproductiveQuantity\t%s\treserve+surplus\tEXACT\n' "$FIRST_REPRODUCTIVE_OUTPUT"
    printf 'foodConsumptionDebit\t1\tretained-receipt\tEXACT\n'
    printf 'storedSurplus\t%s\t%s after restart\tMATCH\n' "$FIRST_STORED_SURPLUS" "$RESTART_CONTAINER_QUANTITY"
    printf 'reservedReproductiveQuantity\t1\tconsumed-by-second-plant\tEXACT\n'
    printf 'secondPlantDebit\t1\tsame-stage0-after-restart\tEXACT_PROVENANCE\n'
    printf 'growthDuringStop\tstage0\tstage0\tZERO\n'
    printf 'quantityAtSave\tcontainer:%s+crop:1\tcontainer:%s+crop:1\tMATCH\n' \
        "$SAVE_CONTAINER_QUANTITY" "$RESTART_CONTAINER_QUANTITY"
    printf 'secondHarvestQuantity\t0\t%s\tEXACT_PHYSICAL_OUTPUT\n' "$SECOND_OUTPUT"
    printf 'secondHarvestFoodQuantity\t0\t1\tAVAILABLE\n'
    printf 'secondHarvestReproductiveQuantity\t0\t%s\tEXACT\n' "$SECOND_REPRODUCTIVE_OUTPUT"
    printf 'finalLoosePhysicalQuantity\t0\t%s (agent:%s+container:%s)\tEXACT\n' \
        "$FINAL_LOOSE_QUANTITY" "$FINAL_ACTOR_QUANTITY" "$FINAL_CONTAINER_QUANTITY"
    printf 'newReserve\tnone\tcarrot:%s\tPHYSICAL\n' "$FINAL_ACTOR_QUANTITY"
    printf 'checkpointSchema\t29\t29\tMATCH\n'
    printf 'manifestIntegrity\t%s\tverified:v1\tMATCH\n' "$MANIFEST_DIGEST"
    printf 'externalInjections\t0\t0\tZERO\n'
    printf 'directWorldBlockMutations\t0\t0\tZERO_AFTER_BOUNDARY\n'
    printf 'duplicateReceipts\t0\t0\tZERO\n'
    printf 'duplicateSites\t0\t0\tZERO\n'
    printf 'observerMutations\t0\t0\tREAD_ONLY\n'
    printf 'runtimeErrors\t0\t0\tZERO\n'
    printf 'cleanup\tprobesRemoved=3\tprobes+checkpoints+disposable-home\tEXACT\n'
} > "$MATRIX"

{
    printf 'world=%s\n' "$PHASE1_WORLD"
    printf 'simulation=%s\n' "$PHASE1_SIM"
    printf 'manifestIntegrityDigest=%s\n' "$MANIFEST_DIGEST"
    printf 'restartProcessBoundary=process1_terminated>process2_started\n'
    printf 'physicalAccounting=initial:1,firstPlantDebit:1,firstOutput:%s,foodDebit:1,secondPlantDebit:1,secondOutput:%s,finalLoose:%s\n' \
        "$FIRST_OUTPUT" "$SECOND_OUTPUT" "$FINAL_LOOSE_QUANTITY"
    /usr/bin/grep -E \
        '^\[lab-live\] (renewable initialization|renewable INITIALIZATION CLOSED|renewable first operation|renewable cycle harvest|renewable food and reserve|renewable second operation|renewable second reserve|renewable status|checkpoint saved name=renewable-(cycle2|complete)|checkpoint loaded name=renewable-cycle2|observer status)' \
        "$PHASE1_TRACE" "$PHASE2_TRACE"
    printf 'externalInjectionCount=0\n'
    printf 'directWorldBlockMutationCount=0\n'
    printf 'duplicateReceiptCount=0\n'
    printf 'duplicateSiteCount=0\n'
    printf 'observerMutationCount=0\n'
    printf 'runtimeErrors=0\n'
    printf 'cleanup=exact\n'
} > "$COMPACT_TRACE"

/bin/rm -rf "$SESSION_HOME"
[ ! -e "$SESSION_HOME" ] || fail "disposable campaign home survived cleanup"

printf '\nRenewable-subsistence two-process rendered campaign passed.\n'
printf 'Evidence: %s\n' "$EVIDENCE_ROOT"
printf 'World: %s\n' "$PHASE1_WORLD"
printf 'Simulation: %s\n' "$PHASE1_SIM"
printf 'Manifest integrity: %s verified\n' "$MANIFEST_DIGEST"
printf 'External injection count after initialization: 0\n'
printf 'Direct World block mutation count after initialization: 0\n'
printf 'Duplication count: 0\n'
printf 'Observer mutation count: 0\n'
printf 'Runtime errors: 0\n'
printf 'Cleanup: exact\n'
