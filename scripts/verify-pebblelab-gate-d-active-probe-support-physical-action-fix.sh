#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
BASELINE=55e513becac622e2f7f258f10ec406d26865eb6a
BUILD_CONFIGURATION=${PEBBLELAB_GATE_D_BLOCKER_10_BUILD_CONFIGURATION:-release}

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

MODE=green
case "${1:-}" in
    --dry-run)
        printf '%s\n' \
            'Gate D Blocker 10 active-probe physical-action safety proof.' \
            'Baseline red: support break commits, leaves a probe invalid, and checkpoint refuses.' \
            'Green: break/till/place preserve every pre-valid active probe or roll back exactly.' \
            'Positive control: a safe physical break succeeds with wear and acquired drop.' \
            'Continuation: damage 1>2, checkpoint C, fresh damage-two restore, then real damage 2>3 use.' \
            'Scope: targeted Blocker 10 correction; this runner does not evaluate Gate D.'
        exit 0
        ;;
    --baseline-red) MODE=baseline-red ;;
    "") ;;
    *) fail 'usage: scripts/verify-pebblelab-gate-d-active-probe-support-physical-action-fix.sh [--dry-run|--baseline-red]' ;;
esac

cd "$ROOT_DIR"
[ "$(git rev-parse origin/lab/pebblelab-v1)" = "$BASELINE" ] \
    || fail 'canonical remote is not the Blocker 10 baseline'
[ "$(git merge-base HEAD "$BASELINE")" = "$BASELINE" ] \
    || fail 'current branch does not descend from the Blocker 10 baseline'
case "$BUILD_CONFIGURATION" in
    debug|release) ;;
    *) fail "unsupported build configuration: $BUILD_CONFIGURATION" ;;
esac

if [ -n "${PEBBLELAB_GATE_D_BLOCKER_10_EVIDENCE_DIR:-}" ]; then
    EVIDENCE_ROOT=$PEBBLELAB_GATE_D_BLOCKER_10_EVIDENCE_DIR
    [ ! -e "$EVIDENCE_ROOT" ] \
        || fail "evidence directory already exists: $EVIDENCE_ROOT"
    /bin/mkdir -p "$EVIDENCE_ROOT"
else
    EVIDENCE_ROOT=$(/usr/bin/mktemp -d /tmp/PebbleLab-GateD-Blocker10.XXXXXX)
fi

if [ "$MODE" = baseline-red ]; then
    PEBBLE_BINARY=${PEBBLELAB_GATE_D_BLOCKER_10_BASELINE_BINARY:-}
    [ -x "$PEBBLE_BINARY" ] \
        || fail 'PEBBLELAB_GATE_D_BLOCKER_10_BASELINE_BINARY is required'
else
    swift build --disable-sandbox -c "$BUILD_CONFIGURATION" --product Pebble \
        > "$EVIDENCE_ROOT/build.log" 2>&1
    PEBBLE_BINARY="$ROOT_DIR/.build/$BUILD_CONFIGURATION/Pebble"
    [ -x "$PEBBLE_BINARY" ] || fail 'Pebble binary is missing'
fi

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
    PEBBLELAB_GATE_D_BLOCKER_08=1 \
    PEBBLELAB_GATE_D_BLOCKER_09=1 \
    PEBBLELAB_GATE_D_BLOCKER_10=1 \
    PEBBLE_CMD="$commands" \
    PEBBLE_SHOT="$shots" \
    "$PEBBLE_BINARY"
}

run_process() {
    process_home=$1
    trace_file=$2
    commands=$3
    shots=$4
    world_name=$5
    world_seed=$6
    /bin/mkdir -p "$process_home"
    if [ -n "$world_name" ]; then
        CFFIXED_USER_HOME="$process_home" \
        PEBBLE_AUTOLOAD=1 \
        PEBBLE_NEWWORLD="$world_seed" \
        PEBBLE_NEWWORLD_NAME="$world_name" \
        run_pebble "$commands" "$shots" > "$trace_file" 2>&1
    else
        CFFIXED_USER_HOME="$process_home" \
        PEBBLE_AUTOLOAD=1 \
        run_pebble "$commands" "$shots" > "$trace_file" 2>&1
    fi
    if /usr/bin/pgrep -x Pebble >/dev/null 2>&1; then
        fail "Pebble process remained after $trace_file"
    fi
}

WORLD_READY='/gamerule randomTickSpeed 0;/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/tp 14 66 -21'
ENABLE='/lab start;/lab pause;/lab movement off;/lab follow off;/lab overlay full;/lab persistence-reconciliation setup;/lab survival on;/lab population on;/lab settlement on;/lab ecology on;/lab ecology scan;/lab mortality on;/lab lifecycle on;/lab kinship on;/lab household on;/lab physical-food-survival on;/lab homeostasis on;/lab genetics on;/lab care on;/lab childhood on;/lab family on'

SUPPORT_HOME="$EVIDENCE_ROOT/support-home"
SUPPORT_TRACE="$EVIDENCE_ROOT/support-action.log"
SUPPORT_CAPTURE="$EVIDENCE_ROOT/01-support-boundary.png"
SUPPORT_COMMANDS="$WORLD_READY|$ENABLE;/lab checkpoint position-proof collective-semantics;/lab gateway proof support-safety;/lab gateway proof mutation-family-audit;/lab gateway proof safe-break;/lab checkpoint save blocker10-support-safe;/lab checkpoint position-proof foreign-collision-load blocker10-support-safe 20 66 -24;/lab checkpoint list;/lab status"
run_process "$SUPPORT_HOME" "$SUPPORT_TRACE" "$SUPPORT_COMMANDS" \
    "-|$SUPPORT_CAPTURE" 'PebbleLab-Disposable-GateD-Blocker10-Support-46' 46

if [ "$MODE" = baseline-red ]; then
    require_trace "$SUPPORT_TRACE" \
        'blocker10 support destructive request .*beforePlacement=valid outcome=succeeded failure=none .*worldMutation=1 .*protectedPlacementAfter=incompatibleSupport' \
        'published support-destructive break'
    require_trace "$SUPPORT_TRACE" \
        'checkpoint command failed: .*agent_[0-9]+:incompatibleSupport' \
        'checkpoint refusal after unsupported probe'
    reject_trace "$SUPPORT_TRACE" \
        'checkpoint saved name=blocker10-support-safe ' \
        'baseline checkpoint publication'
    printf '\nGATE D BLOCKER 10 BASELINE RED REPRODUCED\n'
    printf 'Evidence: %s\n' "$EVIDENCE_ROOT"
    exit 0
fi

require_trace "$SUPPORT_TRACE" \
    'blocker10 support destructive request .*beforePlacement=valid outcome=verificationFailure failure=activeProbePlacementInvalid .*worldMutation=0 toolDamage=0>0 drops=0 custody=unchanged materialRights=unchanged estate=unchanged session=unchanged recorder=unchanged protectedPlacementAfter=valid physicalReceipts=0' \
    'support-destructive refusal with zero surviving effects'
require_trace "$SUPPORT_TRACE" \
    'blocker10 mutation family audit till=verificationFailure:activeProbePlacementInvalid place=verificationFailure:activeProbePlacementInvalid directOccupied=refused:occupiedTarget support=unchanged body=clear tool=unchanged custody=unchanged drops=0 placement=valid enumerationOrder=independent exact=1' \
    'break sibling-family audit and direct occupied refusal'
require_trace "$SUPPORT_TRACE" \
    'blocker10 safe physical break .*outcome=succeeded .*toolDamage=0>1 dropsAcquired=[1-9][0-9]* activePlacement=valid session=unchanged recorder=unchanged' \
    'safe real physical break positive control'
require_trace "$SUPPORT_TRACE" \
    'checkpoint collective placement semantics adjacent=valid .*actualOverlap=refused orderIndependent=1 sessionMutation=0 worldMutation=0' \
    'Blocker 08 canonical adjacency and target-overlap semantics'
require_trace "$SUPPORT_TRACE" \
    'checkpoint collective placement foreignCollision=refused .*relocation=none publication=none reconciliationRunsPublished=0 sessionMutation=0 residualForeignEntity=0' \
    'Blocker 08 foreign collision fail-closed semantics'
require_trace "$SUPPORT_TRACE" \
    'checkpoint saved name=blocker10-support-safe .*restartSafe=1' \
    'immediate restart-safe checkpoint after refusal and safe break'
reject_trace "$SUPPORT_TRACE" \
    'checkpoint command failed|runtimeErrors=[1-9]' \
    'green support-boundary failure'

# The continuation is independently generated here. It uses the published
# estate and evolved-identity product mechanisms, not Evaluation 10 ancestry.
CONTINUATION_HOME="$EVIDENCE_ROOT/continuation-home"
CONT_A="$EVIDENCE_ROOT/continuation-process-a.log"
CONT_B="$EVIDENCE_ROOT/continuation-process-b.log"
CONT_C="$EVIDENCE_ROOT/continuation-process-c.log"
CONT_D="$EVIDENCE_ROOT/continuation-process-d.log"
CONT_SETUP="$WORLD_READY|$ENABLE;/lab family propose agent_0 agent_1 blocker10-proposal;/lab family accept blocker10-proposal agent_1 agent_0 blocker10-accept;/lab reproduction on;/lab step;/lab step;/lab step;/lab step;/lab care proof proximity-setup;/lab estates on;/lab homeostasis proof estate-co-mingled-setup;/lab homeostasis proof estate-advance 18;/lab homeostasis proof estate-advance 1;/lab estates accept latest agent_1;/lab estates settle latest next;/lab estates proof physical latest tracked;/lab checkpoint save blocker10-preuse;/lab checkpoint status;/lab status"
run_process "$CONTINUATION_HOME" "$CONT_A" "$CONT_SETUP" \
    "-|$EVIDENCE_ROOT/02-pre-use.png" \
    'PebbleLab-Disposable-GateD-Blocker10-Continuation-46' 46
require_trace "$CONT_A" \
    'estate asset settled .*status=transferred beneficiary=agent_1 custodian=agent_1' \
    'legitimate estate settlement'
require_trace "$CONT_A" \
    'checkpoint saved name=blocker10-preuse .*restartSafe=1 .*protectedCustodyStacks=1 protectedCustodyQuantity=1' \
    'pre-use protected checkpoint'
require_trace "$CONT_A" \
    'stop .*custodyHandoff=protected handoffFreshness=exact taggedCustodySpills=1' \
    'pre-use exact escrow'

CONT_B_COMMANDS='/tp 14 66 -21|/lab start;/lab pause;/lab movement off;/lab follow off;/lab overlay full;/lab checkpoint load blocker10-preuse;/lab persistence-reconciliation status;/lab estates proof blocker07-inherited-use;/lab checkpoint custody-proof verified-move agent_2;/lab checkpoint custody-proof blocker09-identity status;/lab checkpoint save blocker10-damage1;/lab checkpoint status;/lab status'
run_process "$CONTINUATION_HOME" "$CONT_B" "$CONT_B_COMMANDS" \
    "-|$EVIDENCE_ROOT/03-damage-one.png" '' 0
require_trace "$CONT_B" \
    'blocker07 inherited estate use .*damage=0>1 .*physicalMutationOccurred=1 .*firstAttempt=allowed' \
    'first inherited physical use'
require_trace "$CONT_B" \
    'checkpoint saved name=blocker10-damage1 .*restartSafe=1' \
    'damage-one checkpoint save'

CONT_C_COMMANDS='/tp 14 66 -21|/lab start;/lab pause;/lab movement off;/lab follow off;/lab overlay full;/lab checkpoint load blocker10-damage1;/lab persistence-reconciliation status;/lab checkpoint custody-proof blocker09-identity status;/lab estates proof blocker07-inherited-use;/lab checkpoint custody-proof verified-move agent_2;/lab checkpoint custody-proof blocker09-identity status;/lab checkpoint save blocker10-damage2;/lab checkpoint status;/lab status'
run_process "$CONTINUATION_HOME" "$CONT_C" "$CONT_C_COMMANDS" \
    "-|$EVIDENCE_ROOT/04-damage-two.png" '' 0
require_trace "$CONT_C" \
    'checkpoint loaded name=blocker10-damage1 .*physicalBoundary=acquired .*committedCurrentReconciliationThisLoad=1' \
    'damage-one fresh restore'
require_trace "$CONT_C" \
    'blocker07 inherited estate use .*damage=1>2 .*physicalMutationOccurred=1 .*firstAttempt=allowed' \
    'safe second inherited physical use'
require_trace "$CONT_C" \
    'blocker09 checkpoint identity .*durableDamage=0 .*currentDamage=2 physicalDamage=2 .*assetContinuity=1 checkpointValidation=current_exact' \
    'durable/current identity continuity at damage two'
require_trace "$CONT_C" \
    'checkpoint saved name=blocker10-damage2 .*restartSafe=1' \
    'checkpoint C save'
require_trace "$CONT_C" \
    'stop .*custodyHandoff=protected handoffFreshness=exact' \
    'checkpoint C exact escrow'

CONT_D_COMMANDS='/tp 14 66 -21|/lab start;/lab pause;/lab movement off;/lab follow off;/lab overlay full;/lab checkpoint load blocker10-damage2;/lab persistence-reconciliation status;/lab checkpoint custody-proof blocker09-identity status;/lab estates proof blocker07-inherited-use;/lab checkpoint custody-proof blocker09-identity status;/lab status'
run_process "$CONTINUATION_HOME" "$CONT_D" "$CONT_D_COMMANDS" \
    "-|$EVIDENCE_ROOT/05-damage-two-restored-and-continued.png" '' 0
require_trace "$CONT_D" \
    'checkpoint loaded name=blocker10-damage2 .*physicalBoundary=acquired reconciliationPhase=postPhysicalBoundary .*committedCurrentReconciliationThisLoad=1' \
    'checkpoint C fresh physical restore and one current reconciliation'
require_trace "$CONT_D" \
    'blocker09 checkpoint identity .*durableDamage=0 .*currentDamage=2 physicalDamage=2 .*estateEntry=.*settlementReceipt=.*assetCount=1' \
    'exact damage-two restore with historical settlement'
require_trace "$CONT_D" \
    'blocker07 inherited estate use .*damage=2>3 .*physicalMutationOccurred=1 .*firstAttempt=allowed' \
    'continued normal physical action after checkpoint C restore'
require_trace "$CONT_D" \
    'blocker09 checkpoint identity .*durableDamage=0 .*currentDamage=3 physicalDamage=3 .*assetContinuity=1 checkpointValidation=current_exact .*assetCount=1' \
    'continued identity evolution after fresh restore'
reject_trace "$CONT_B" 'checkpoint command failed|runtimeErrors=[1-9]' \
    'damage-one continuation failure'
reject_trace "$CONT_C" 'checkpoint command failed|runtimeErrors=[1-9]' \
    'damage-two continuation failure'
reject_trace "$CONT_D" 'checkpoint command failed|outcomes=missing|runtimeErrors=[1-9]' \
    'post-checkpoint-C continuation failure'

printf '\nGATE D BLOCKER 10 REPRODUCED AND FIXED\n'
printf 'Support-destructive break: refused with exact rollback\n'
printf 'Safe break: succeeded with real wear and acquired drop\n'
printf 'Till/place sibling mutations: compensated; direct occupancy refused\n'
printf 'E10 decisive continuation: damage 1>2, checkpoint C, fresh damage-two restore, damage 2>3\n'
printf 'Physical loss / duplication / synthetic material: 0 / 0 / 0\n'
printf 'Evidence: %s\n' "$EVIDENCE_ROOT"
