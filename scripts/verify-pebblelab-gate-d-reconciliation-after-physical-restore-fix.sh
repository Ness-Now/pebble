#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
WORLD_NAME="PebbleLab-Disposable-GateD-Blocker07-46"
WORLD_SEED=46
MODE=${1:-green}

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

require_count() {
    trace_file=$1
    pattern=$2
    expected=$3
    description=$4
    actual=$(/usr/bin/grep -Ec "$pattern" "$trace_file" || true)
    [ "$actual" -eq "$expected" ] \
        || fail "$description: expected $expected, got $actual"
}

case "$MODE" in
    --dry-run)
        printf 'Gate D Blocker 07 post-restore reconciliation proof (dry run)\n'
        printf '  Main: estate settlement -> protected checkpoint -> fresh load\n'
        printf '        -> custody exact -> one matched reconciliation -> inherited use\n'
        printf '  Fault: inject after reconciliation candidate -> exact load rollback\n'
        printf '         -> immediate same-process load retry -> inherited use\n'
        exit 0
        ;;
    green) ;;
    *)
        fail "usage: scripts/verify-pebblelab-gate-d-reconciliation-after-physical-restore-fix.sh [--dry-run]"
        ;;
esac

git -C "$ROOT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    || fail "repository metadata missing"
[ "$(git -C "$ROOT_DIR" rev-parse --show-toplevel)" = "$ROOT_DIR" ] \
    || fail "unexpected repository root"

if [ -n "${PEBBLELAB_GATE_D_BLOCKER_07_EVIDENCE_DIR:-}" ]; then
    EVIDENCE_ROOT=$PEBBLELAB_GATE_D_BLOCKER_07_EVIDENCE_DIR
    [ ! -e "$EVIDENCE_ROOT" ] \
        || fail "evidence directory already exists: $EVIDENCE_ROOT"
    /bin/mkdir -p "$EVIDENCE_ROOT"
else
    EVIDENCE_ROOT=$(/usr/bin/mktemp -d /tmp/PebbleLab-GateD-Blocker07.XXXXXX)
fi
MAIN_HOME="$EVIDENCE_ROOT/main-home"
FAULT_HOME="$EVIDENCE_ROOT/fault-home"
/bin/mkdir -p "$MAIN_HOME" "$FAULT_HOME"
MAIN_A_TRACE="$EVIDENCE_ROOT/main-process-a.log"
MAIN_B_TRACE="$EVIDENCE_ROOT/main-process-b.log"
FAULT_A_TRACE="$EVIDENCE_ROOT/fault-process-a.log"
FAULT_B_TRACE="$EVIDENCE_ROOT/fault-process-b.log"
MAIN_BEFORE_CAPTURE="$EVIDENCE_ROOT/main-before-restart.png"
MAIN_AFTER_CAPTURE="$EVIDENCE_ROOT/main-after-inherited-use.png"
FAULT_BEFORE_CAPTURE="$EVIDENCE_ROOT/fault-before-restart.png"
FAULT_AFTER_CAPTURE="$EVIDENCE_ROOT/fault-after-retry.png"
BUILD_CONFIGURATION=${PEBBLELAB_GATE_D_BLOCKER_07_BUILD_CONFIGURATION:-release}
case "$BUILD_CONFIGURATION" in
    debug|release) ;;
    *) fail "unsupported Blocker 07 build configuration: $BUILD_CONFIGURATION" ;;
esac

cd "$ROOT_DIR"
if [ "${PEBBLELAB_GATE_D_BLOCKER_07_SKIP_BUILD:-0}" != "1" ]; then
    swift build -c "$BUILD_CONFIGURATION" --product Pebble
fi
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
    PEBBLELAB_APP_AGENTS_MULTISCALE=1 \
    PEBBLELAB_APP_AGENTS_ECOLOGY=1 \
    PEBBLELAB_APP_AGENTS_MORTALITY=1 \
    PEBBLELAB_APP_AGENTS_LIFECYCLE=1 \
    PEBBLELAB_APP_AGENTS_KINSHIP=1 \
    PEBBLELAB_APP_AGENTS_HOUSEHOLDS=1 \
    PEBBLELAB_APP_AGENTS_HOMEOSTASIS=1 \
    PEBBLELAB_APP_AGENTS_GENETICS=1 \
    PEBBLELAB_APP_AGENTS_CARE=1 \
    PEBBLELAB_APP_AGENTS_CHILDHOOD=1 \
    PEBBLELAB_APP_AGENTS_FAMILY=1 \
    PEBBLELAB_APP_AGENTS_SOCIAL=1 \
    PEBBLELAB_APP_AGENTS_OBSERVER=1 \
    PEBBLELAB_DISPOSABLE_WORLD_PROOF=1 \
    PEBBLELAB_GATE_D_BLOCKER_06=1 \
    PEBBLELAB_GATE_D_BLOCKER_07=1 \
    PEBBLE_CMD="$commands" \
    PEBBLE_SHOT="$shots" \
    "$PEBBLE_BINARY"
}

run_process() {
    process_home=$1
    trace_file=$2
    commands=$3
    shots=$4
    create_world=$5
    if [ "$create_world" -eq 1 ]; then
        CFFIXED_USER_HOME="$process_home" \
        PEBBLE_AUTOLOAD=1 \
        PEBBLE_NEWWORLD="$WORLD_SEED" \
        PEBBLE_NEWWORLD_NAME="$WORLD_NAME" \
        run_pebble "$commands" "$shots" 2>&1 \
            | /usr/bin/tee "$trace_file"
    else
        CFFIXED_USER_HOME="$process_home" \
        PEBBLE_AUTOLOAD=1 \
        run_pebble "$commands" "$shots" 2>&1 \
            | /usr/bin/tee "$trace_file"
    fi
    if /usr/bin/pgrep -x Pebble >/dev/null 2>&1; then
        fail "Pebble process remained after Blocker 07 process: $trace_file"
    fi
}

WORLD_READY='/gamerule randomTickSpeed 0;/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/tp 14 66 -21'
ESTATE_SETUP="$WORLD_READY|/lab start;/tp 14 68 -18;/lab pause;/lab movement off;/lab follow off;/lab overlay full;/lab persistence-reconciliation setup;/lab survival on;/lab population on;/lab settlement on;/lab ecology on;/lab ecology scan;/lab mortality on;/lab lifecycle on;/lab kinship on;/lab household on;/lab physical-food-survival on;/lab homeostasis on;/lab genetics on;/lab care on;/lab childhood on;/lab family on;/lab family propose agent_0 agent_1 blocker07-proposal;/lab family accept blocker07-proposal agent_1 agent_0 blocker07-accept;/lab reproduction on;/lab step;/lab step;/lab step;/lab step;/lab care proof proximity-setup;/lab estates on;/lab homeostasis proof estate-co-mingled-setup;/lab homeostasis proof estate-advance 18;/lab homeostasis proof estate-advance 1;/lab estates accept latest agent_1;/lab estates settle latest next;/lab estates proof physical latest tracked"

prepare_checkpoint() {
    home=$1
    trace_file=$2
    checkpoint=$3
    capture=$4
    commands="$ESTATE_SETUP;/lab checkpoint save $checkpoint;/lab checkpoint status;/lab status"
    run_process "$home" "$trace_file" "$commands" "-|$capture" 1
    require_trace "$trace_file" \
        'estate asset settled .*status=transferred beneficiary=agent_1 custodian=agent_1' \
        'tracked estate asset settles before checkpoint'
    require_trace "$trace_file" \
        'estate physical authority .*trackedDestination=1 .*hoeSource=1 .*trackedTotal=1 hoeTotal=1 physicalLoss=0 physicalDuplication=0 syntheticMaterial=0 .*rightsHolder=agent:agent_1' \
        'co-mingled settlement conserves tracked and unrelated material'
    require_trace "$trace_file" \
        "checkpoint saved name=$checkpoint .*restartSafe=1 .*protectedCustodyStacks=1 protectedCustodyQuantity=1" \
        'checkpoint protects one non-empty inherited custody stack'
    require_trace "$trace_file" \
        'stop .*custodyHandoff=protected handoffFreshness=exact taggedCustodySpills=1' \
        'graceful shutdown publishes exact checkpoint-bound escrow'
    reject_trace "$trace_file" \
        'Estate boundary refused|checkpoint .*failed|runtimeErrors=[1-9]' \
        'Process A runtime or estate failure'
    [ -s "$capture" ] || fail "Process A native capture missing: $capture"
}

require_successful_load_and_use() {
    trace_file=$1
    checkpoint=$2
    require_trace "$trace_file" \
        "checkpoint physical boundary acquired name=$checkpoint .*positions=exact custody=exact .*custodyRestored=[1-9]" \
        'complete physical checkpoint boundary is acquired first'
    require_trace "$trace_file" \
        "persistence reconciliation candidate run=restore:.* phase=postPhysicalBoundary published=0 .*outcomes=matched .*duplicates=0" \
        'one matched reconciliation is staged after physical restoration'
    require_trace "$trace_file" \
        "checkpoint loaded name=$checkpoint .*custodyRestoredStacks=1 custodyRestoredQuantity=1 .*physicalBoundary=acquired reconciliationPhase=postPhysicalBoundary reconciliationRuns=1 physicalReconciliation=applied:matched" \
        'checkpoint publishes only the coherent post-physical candidate'
    require_trace "$trace_file" \
        'persistence reconciliation status enabled=1 runs=1 outcome=matched asset=asset:civ27:live-pickaxe holder=agent:agent_1 .*duplicates=0' \
        'one current matched run is visible after load'
    require_trace "$trace_file" \
        'blocker07 inherited estate use .*asset=asset:civ27:live-pickaxe actor=agent_1 holder=agent:agent_1 right=recognizedOwner tool=iron_pickaxe .*physicalMutationOccurred=1 postMutationVerified=1 rightsPublication=1 .*reconciliationRuns=1 firstAttempt=allowed physicalLoss=0 physicalDuplication=0 syntheticMaterial=0' \
        'first inherited use performs and publishes one real physical action'
    reject_trace "$trace_file" \
        'outcomes=missing|physicalAssetUnresolved|runtimeErrors=[1-9]' \
        'stale bootstrap reconciliation or inherited-use refusal'
}

prepare_checkpoint "$MAIN_HOME" "$MAIN_A_TRACE" \
    blocker07-main "$MAIN_BEFORE_CAPTURE"
MAIN_B_COMMANDS='/tp 14 66 -21|/lab start;/lab pause;/lab movement off;/lab follow off;/lab overlay full;/lab checkpoint load blocker07-main;/lab persistence-reconciliation status;/lab estates proof blocker07-inherited-use;/lab estates status;/lab status'
run_process "$MAIN_HOME" "$MAIN_B_TRACE" "$MAIN_B_COMMANDS" \
    "-|$MAIN_AFTER_CAPTURE" 0
require_successful_load_and_use "$MAIN_B_TRACE" blocker07-main
require_count "$MAIN_B_TRACE" \
    'persistence reconciliation candidate run=restore:.*checkpoint=.*phase=postPhysicalBoundary published=0' \
    1 'successful load must stage exactly one reconciliation run'
require_count "$MAIN_B_TRACE" 'checkpoint loaded name=blocker07-main ' \
    1 'successful load must publish once'
[ -s "$MAIN_AFTER_CAPTURE" ] || fail 'main post-use native capture missing'

prepare_checkpoint "$FAULT_HOME" "$FAULT_A_TRACE" \
    blocker07-fault "$FAULT_BEFORE_CAPTURE"
FAULT_B_COMMANDS='/tp 14 66 -21|/lab start;/lab pause;/lab movement off;/lab follow off;/lab overlay full;/lab checkpoint custody-proof status agent_1;/lab checkpoint custody-proof failure after-reconciliation-candidate;/lab checkpoint load blocker07-fault;/lab checkpoint custody-proof status agent_1;/lab checkpoint custody-proof failure none;/lab checkpoint load blocker07-fault;/lab persistence-reconciliation status;/lab estates proof blocker07-inherited-use;/lab status'
run_process "$FAULT_HOME" "$FAULT_B_TRACE" "$FAULT_B_COMMANDS" \
    "-|$FAULT_AFTER_CAPTURE" 0
require_trace "$FAULT_B_TRACE" \
    'PebbleAgents checkpoint command failed: .*injected checkpoint failure after Material Rights reconciliation candidate' \
    'fault is injected after the staged current reconciliation'
require_trace "$FAULT_B_TRACE" \
    'checkpoint probe rollback verified name=blocker07-fault .*custodyRestored=[1-9] .*custodySpillsRestored=1 candidateReconciliation=discarded session=unchanged recorder=unchanged' \
    'failed load restores bootstrap probes custody escrow and publication state'
require_count "$FAULT_B_TRACE" \
    'checkpoint custody proof status agent=agent_1 .*stacks=0 quantity=0' \
    2 'bootstrap custody must be empty before and after failed load'
require_successful_load_and_use "$FAULT_B_TRACE" blocker07-fault
require_count "$FAULT_B_TRACE" 'checkpoint loaded name=blocker07-fault ' \
    1 'only immediate retry may publish the checkpoint'
require_count "$FAULT_B_TRACE" \
    'persistence reconciliation candidate run=restore:.*checkpoint=.*phase=postPhysicalBoundary published=0' \
    2 'failed candidate and retry each stage exactly one unobservable run'
[ -s "$FAULT_AFTER_CAPTURE" ] || fail 'fault retry native capture missing'

printf '\nGATE D BLOCKER 07 TARGETED PROOF PASSED\n'
printf 'Evidence: %s\n' "$EVIDENCE_ROOT"
