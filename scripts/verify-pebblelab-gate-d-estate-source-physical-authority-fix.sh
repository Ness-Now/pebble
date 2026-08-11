#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
WORLD_NAME="PebbleLab-Disposable-GateD-Blocker06-46"
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

case "$MODE" in
    --dry-run)
        printf 'Gate D Blocker 06 estate-source physical-authority proof (dry run)\n'
        printf '  Baseline mode: --expect-baseline-failure\n'
        printf '  Green mode:    no argument\n'
        printf '  Fixture: tracked iron_pickaxe remains in a durable container;\n'
        printf '           normal mortality adds one unregistered iron_hoe.\n'
        exit 0
        ;;
    --expect-baseline-failure)
        EXPECT_BASELINE_FAILURE=1
        ;;
    green)
        EXPECT_BASELINE_FAILURE=0
        ;;
    *)
        fail "usage: scripts/verify-pebblelab-gate-d-estate-source-physical-authority-fix.sh [--dry-run|--expect-baseline-failure]"
        ;;
esac

git -C "$ROOT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    || fail "repository metadata missing"
[ "$(git -C "$ROOT_DIR" rev-parse --show-toplevel)" = "$ROOT_DIR" ] \
    || fail "unexpected repository root"

if [ -n "${PEBBLELAB_GATE_D_BLOCKER_06_EVIDENCE_DIR:-}" ]; then
    EVIDENCE_ROOT=$PEBBLELAB_GATE_D_BLOCKER_06_EVIDENCE_DIR
    [ ! -e "$EVIDENCE_ROOT" ] \
        || fail "evidence directory already exists: $EVIDENCE_ROOT"
    /bin/mkdir -p "$EVIDENCE_ROOT"
else
    EVIDENCE_ROOT=$(/usr/bin/mktemp -d /tmp/PebbleLab-GateD-Blocker06.XXXXXX)
fi
NO_FAULT_HOME="$EVIDENCE_ROOT/no-fault-home"
LATE_FAULT_HOME="$EVIDENCE_ROOT/late-fault-home"
/bin/mkdir -p "$NO_FAULT_HOME" "$LATE_FAULT_HOME"
NO_FAULT_A_TRACE="$EVIDENCE_ROOT/co-mingled-no-fault-process-a.log"
NO_FAULT_B_TRACE="$EVIDENCE_ROOT/co-mingled-no-fault-process-b.log"
LATE_FAULT_A_TRACE="$EVIDENCE_ROOT/co-mingled-late-fault-process-a.log"
LATE_FAULT_B_TRACE="$EVIDENCE_ROOT/co-mingled-late-fault-process-b.log"
NO_FAULT_BEFORE_CAPTURE="$EVIDENCE_ROOT/co-mingled-no-fault-before.png"
NO_FAULT_AFTER_CAPTURE="$EVIDENCE_ROOT/co-mingled-no-fault-after.png"
NO_FAULT_RESTART_CAPTURE="$EVIDENCE_ROOT/co-mingled-no-fault-restart.png"
LATE_FAULT_BEFORE_CAPTURE="$EVIDENCE_ROOT/co-mingled-late-fault-before.png"
LATE_FAULT_AFTER_CAPTURE="$EVIDENCE_ROOT/co-mingled-late-fault-after.png"
LATE_FAULT_RESTART_CAPTURE="$EVIDENCE_ROOT/co-mingled-late-fault-restart.png"
BUILD_CONFIGURATION=${PEBBLELAB_GATE_D_BLOCKER_06_BUILD_CONFIGURATION:-release}
case "$BUILD_CONFIGURATION" in
    debug|release) ;;
    *) fail "unsupported Blocker 06 build configuration: $BUILD_CONFIGURATION" ;;
esac

cd "$ROOT_DIR"
if [ "${PEBBLELAB_GATE_D_BLOCKER_06_SKIP_BUILD:-0}" != "1" ]; then
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
        fail "Pebble process remained after Blocker 06 process: $trace_file"
    fi
}

require_co_mingled_history() {
    trace_file=$1
    require_trace "$trace_file" \
        'estate co-mingled proof setup .*tracked=iron_pickaxe:1 .*unregistered=iron_hoe:1 .*session=unchanged worldMutation=physicalCustodyOnly' \
        'real tracked and unrelated materials are separated before mortality'
    require_trace "$trace_file" \
        'mortality physical custody .*agent=agent_0 kind=transferred trackedAssets= *physicalStacks=.*iron_hoe:1.*destination=container:.*probeEmpty=1 socialRecordsInvented=0' \
        'normal mortality adds the unrelated hoe to durable custody'
    require_trace "$trace_file" \
        'estates schema=28 enabled=1 .*decedent=agent_0 .*assets=.*unregistered~iron_hoe:1~.*blocked~sociallyUnregistered' \
        'unregistered physical hoe remains explicitly blocked'
    require_trace "$trace_file" \
        'estates schema=28 enabled=1 .*decedent=agent_0 .*assets=.*asset:civ27:live-pickaxe~iron_pickaxe:1~container:.*pendingSettlement' \
        'one tracked estate asset and one unrelated blocked physical asset coexist'
    require_trace "$trace_file" \
        'estate administration accepted .*administrator=agent_1 count=1' \
        'administrator accepted before settlement'
}

WORLD_READY='/gamerule randomTickSpeed 0;/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/tp 14 66 -21'
SETUP="$WORLD_READY|/lab start;/tp 14 68 -18;/lab pause;/lab movement off;/lab follow off;/lab overlay full;/lab persistence-reconciliation setup;/lab survival on;/lab population on;/lab settlement on;/lab ecology on;/lab ecology scan;/lab mortality on;/lab lifecycle on;/lab kinship on;/lab household on;/lab physical-food-survival on;/lab homeostasis on;/lab genetics on;/lab care on;/lab childhood on;/lab family on;/lab family propose agent_0 agent_1 gate-d06-proposal;/lab family accept gate-d06-proposal agent_1 agent_0 gate-d06-accept;/lab reproduction on;/lab step;/lab step;/lab step;/lab step;/lab care proof proximity-setup;/lab estates on;/lab homeostasis proof estate-co-mingled-setup;/lab homeostasis proof estate-advance 18;/lab homeostasis proof estate-advance 1;/lab mortality status;/lab estates status;/lab estates accept latest agent_1"

if [ "$EXPECT_BASELINE_FAILURE" -eq 1 ]; then
    BASELINE_COMMANDS="$SETUP|/lab estates settle latest next;/lab estates status;/lab status"
    run_process "$NO_FAULT_HOME" "$NO_FAULT_A_TRACE" \
        "$BASELINE_COMMANDS" "-|$NO_FAULT_BEFORE_CAPTURE" 1
    require_co_mingled_history "$NO_FAULT_A_TRACE"
    [ -s "$NO_FAULT_BEFORE_CAPTURE" ] \
        || fail "native co-mingled baseline capture missing"
    require_trace "$NO_FAULT_A_TRACE" \
        'Estate boundary refused: invalid\("stale estate source"\)' \
        'published baseline stale full-container fingerprint failure'
    reject_trace "$NO_FAULT_A_TRACE" \
        'estate asset settled ' \
        'baseline must not settle the tracked asset'
    printf '\nGATE D BLOCKER 06 BASELINE FAILURE REPRODUCED\n'
    printf 'Evidence: %s\n' "$EVIDENCE_ROOT"
    exit 0
fi

NO_FAULT_A_COMMANDS="$SETUP|/lab estates proof physical latest tracked;/lab estates proof authority latest tracked|/lab estates settle latest next;/lab estates proof physical latest tracked;/lab estates status;/lab checkpoint save blocker06-no-fault;/lab checkpoint status;/lab status"
NO_FAULT_B_COMMANDS='/tp 14 66 -21|/lab start;/lab pause;/lab movement off;/lab follow off;/lab overlay full;/lab checkpoint load blocker06-no-fault;/lab estates proof physical latest tracked;/lab estates status|/lab step;/lab estates proof physical latest tracked;/lab checkpoint delete blocker06-no-fault;/lab estates proof blocker06-cleanup;/lab status'

run_process "$NO_FAULT_HOME" "$NO_FAULT_A_TRACE" \
    "$NO_FAULT_A_COMMANDS" \
    "-|$NO_FAULT_BEFORE_CAPTURE|-|$NO_FAULT_AFTER_CAPTURE" 1
require_co_mingled_history "$NO_FAULT_A_TRACE"
require_trace "$NO_FAULT_A_TRACE" \
    'estate source authority adversarial unrelatedAdded=allowed unrelatedRemoved=allowed trackedRemoved=refused:missing trackedChanged=refused:identityMismatch trackedDuplicated=refused:ambiguous wrongHolder=refused:missing physical=restored session=unchanged gatewayReceipts=unchanged failClosed=1' \
    'asset-scoped authority allows unrelated drift and refuses tracked drift'
require_trace "$NO_FAULT_A_TRACE" \
    'estate asset settled .*status=transferred beneficiary=agent_1 custodian=agent_1 receipt=estate-settle:' \
    'tracked asset settles immediately without restart'
require_trace "$NO_FAULT_A_TRACE" \
    'estate physical authority .*status=transferred trackedSource=0 trackedDestination=1 hoeSource=1 hoeDestination=0 trackedTotal=1 hoeTotal=1 physicalLoss=0 physicalDuplication=0 syntheticMaterial=0 estateReceiptCount=1 duplicateReceipt=0 rightsHolder=agent:agent_1' \
    'no-fault transfer moves only the tracked pickaxe once'
require_trace "$NO_FAULT_A_TRACE" \
    'checkpoint saved name=blocker06-no-fault .*restartSafe=1 .*protectedCustodyStacks=1 protectedCustodyQuantity=1' \
    'settled tracked custody is checkpoint-bound before fresh restart'
reject_trace "$NO_FAULT_A_TRACE" \
    'Estate boundary refused|runtimeErrors=[1-9]|rollback failed' \
    'no-fault runtime or settlement boundary failure'

run_process "$NO_FAULT_HOME" "$NO_FAULT_B_TRACE" \
    "$NO_FAULT_B_COMMANDS" "-|$NO_FAULT_RESTART_CAPTURE|-" 0
require_trace "$NO_FAULT_B_TRACE" \
    'checkpoint loaded name=blocker06-no-fault .*restartSafe=1 .*custodyRestoredStacks=1 custodyRestoredQuantity=1 .*custodyDuplicates=0' \
    'fresh process restores the settled tracked custody exactly'
require_trace "$NO_FAULT_B_TRACE" \
    'estate physical authority .*status=transferred trackedSource=0 trackedDestination=1 hoeSource=1 hoeDestination=0 trackedTotal=1 hoeTotal=1 physicalLoss=0 physicalDuplication=0 syntheticMaterial=0 estateReceiptCount=1 duplicateReceipt=0 rightsHolder=agent:agent_1' \
    'fresh process retains the same estate and material truth'
require_trace "$NO_FAULT_B_TRACE" \
    'estate blocker06 cleanup world=exact trackedPickaxeRemoved=1 unregisteredHoeRemoved=1 fixtureContainerRemoved=1 session=unchanged probes=3 duplicates=0' \
    'no-fault fixture cleanup is exact'
reject_trace "$NO_FAULT_B_TRACE" \
    'Estate boundary refused|checkpoint load refused|runtimeErrors=[1-9]|cleanup .*failed' \
    'no-fault restart or cleanup failure'

LATE_FAULT_A_COMMANDS="$SETUP|/lab estates proof physical latest tracked;/lab estates proof authority latest tracked;/lab estates proof pre-mutation-refusal latest tracked;/lab estates proof rollback latest next;/lab estates proof physical latest tracked|/lab estates settle latest next;/lab estates proof physical latest tracked;/lab estates status;/lab checkpoint save blocker06-late-fault;/lab checkpoint status;/lab status"
LATE_FAULT_B_COMMANDS='/tp 14 66 -21|/lab start;/lab pause;/lab movement off;/lab follow off;/lab overlay full;/lab checkpoint load blocker06-late-fault;/lab estates proof physical latest tracked;/lab estates status|/lab step;/lab estates proof physical latest tracked;/lab checkpoint delete blocker06-late-fault;/lab estates proof blocker06-cleanup;/lab status'

run_process "$LATE_FAULT_HOME" "$LATE_FAULT_A_TRACE" \
    "$LATE_FAULT_A_COMMANDS" \
    "-|$LATE_FAULT_BEFORE_CAPTURE|-|$LATE_FAULT_AFTER_CAPTURE" 1
require_co_mingled_history "$LATE_FAULT_A_TRACE"
require_trace "$LATE_FAULT_A_TRACE" \
    'estate rollback proof refused seamReached=0 physicalMutationOccurred=0 lateFailureVerified=0 rollbackClaim=none staleTrackedAsset=wrongHolder proofState=unchanged fixture=restored session=unchanged estate=unchanged materialRights=unchanged replay=unchanged' \
    'pre-mutation failure cannot masquerade as late rollback'
require_trace "$LATE_FAULT_A_TRACE" \
    'estate settlement rollback lateFailure=verified session=exact estate=exact materialRights=exact source=restored destination=restored replay=unchanged physicalMutationOccurred=1 postMutationVerified=1 faultInjectionReached=1 rollbackClaim=exact' \
    'fault injection occurs only after verified physical mutation'
require_trace "$LATE_FAULT_A_TRACE" \
    'estate asset settled .*status=transferred beneficiary=agent_1 custodian=agent_1 receipt=estate-settle:' \
    'immediate same-process retry succeeds without reconciliation'
require_trace "$LATE_FAULT_A_TRACE" \
    'estate physical authority .*status=transferred trackedSource=0 trackedDestination=1 hoeSource=1 hoeDestination=0 trackedTotal=1 hoeTotal=1 physicalLoss=0 physicalDuplication=0 syntheticMaterial=0 estateReceiptCount=1 duplicateReceipt=0 rightsHolder=agent:agent_1' \
    'late rollback and retry conserve both co-mingled materials'
require_trace "$LATE_FAULT_A_TRACE" \
    'checkpoint saved name=blocker06-late-fault .*restartSafe=1 .*protectedCustodyStacks=1 protectedCustodyQuantity=1' \
    'late-fault retry result is checkpoint-bound'
reject_trace "$LATE_FAULT_A_TRACE" \
    'Estate boundary refused|runtimeErrors=[1-9]|rollback failed' \
    'late-fault runtime, rollback, or retry failure'

run_process "$LATE_FAULT_HOME" "$LATE_FAULT_B_TRACE" \
    "$LATE_FAULT_B_COMMANDS" "-|$LATE_FAULT_RESTART_CAPTURE|-" 0
require_trace "$LATE_FAULT_B_TRACE" \
    'checkpoint loaded name=blocker06-late-fault .*restartSafe=1 .*custodyRestoredStacks=1 custodyRestoredQuantity=1 .*custodyDuplicates=0' \
    'fresh process restores the retry result exactly'
require_trace "$LATE_FAULT_B_TRACE" \
    'estate physical authority .*status=transferred trackedSource=0 trackedDestination=1 hoeSource=1 hoeDestination=0 trackedTotal=1 hoeTotal=1 physicalLoss=0 physicalDuplication=0 syntheticMaterial=0 estateReceiptCount=1 duplicateReceipt=0 rightsHolder=agent:agent_1' \
    'fresh process retains one pickaxe and one unrelated hoe'
require_trace "$LATE_FAULT_B_TRACE" \
    'estate blocker06 cleanup world=exact trackedPickaxeRemoved=1 unregisteredHoeRemoved=1 fixtureContainerRemoved=1 session=unchanged probes=3 duplicates=0' \
    'late-fault fixture cleanup is exact'
reject_trace "$LATE_FAULT_B_TRACE" \
    'Estate boundary refused|checkpoint load refused|runtimeErrors=[1-9]|cleanup .*failed' \
    'late-fault restart or cleanup failure'

for capture in \
    "$NO_FAULT_BEFORE_CAPTURE" "$NO_FAULT_AFTER_CAPTURE" \
    "$NO_FAULT_RESTART_CAPTURE" "$LATE_FAULT_BEFORE_CAPTURE" \
    "$LATE_FAULT_AFTER_CAPTURE" "$LATE_FAULT_RESTART_CAPTURE"
do
    [ -s "$capture" ] || fail "native Blocker 06 capture missing: $capture"
done

if /usr/bin/pgrep -x Pebble >/dev/null 2>&1 \
    || /usr/bin/pgrep -x swift-run >/dev/null 2>&1; then
    fail "residual process after Gate D Blocker 06 proof"
fi

printf '\nGATE D BLOCKER 06 TARGETED PROOF PASSED\n'
printf 'Evidence: %s\n' "$EVIDENCE_ROOT"
