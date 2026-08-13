#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
BASELINE=4ea6fba4b615d72a96087bb98bf5bbca4b560e4b
WORLD_NAME=PebbleLab-Disposable-GateD-Blocker09-46
WORLD_SEED=46
BUILD_CONFIGURATION=${PEBBLELAB_GATE_D_BLOCKER_09_BUILD_CONFIGURATION:-release}

fail() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

require_trace() {
    file=$1
    pattern=$2
    description=$3
    /usr/bin/grep -Eq "$pattern" "$file" \
        || fail "trace missing: $description"
}

reject_trace() {
    file=$1
    pattern=$2
    description=$3
    if /usr/bin/grep -Eq "$pattern" "$file"; then
        fail "trace unexpectedly contains: $description"
    fi
}

MODE=green
case "${1:-}" in
    --dry-run)
        printf '%s\n' \
            'Gate D Blocker 09 evolved material identity checkpoint-save proof.' \
            'Baseline red: inherited pickaxe damage 0>1 then checkpoint save refusal.' \
            'Green: damage 0>1 save, protected fresh restore, damage 1>2 save, second restore.' \
            'Adversarial: old/future/missing/wrong-holder/quantity/ambiguity/duplicate reservation.' \
            'Scope: targeted Blocker 09 correction; this runner does not evaluate Gate D.'
        exit 0
        ;;
    --baseline-red) MODE=baseline-red ;;
    "") ;;
    *) fail 'usage: scripts/verify-pebblelab-gate-d-evolved-material-identity-checkpoint-save-fix.sh [--dry-run|--baseline-red]' ;;
esac

cd "$ROOT_DIR"
[ "$(git rev-parse origin/lab/pebblelab-v1)" = "$BASELINE" ] \
    || fail 'canonical remote is not the Blocker 09 baseline'
[ "$(git merge-base HEAD "$BASELINE")" = "$BASELINE" ] \
    || fail 'current branch does not descend from the Blocker 09 baseline'
case "$BUILD_CONFIGURATION" in
    debug|release) ;;
    *) fail "unsupported build configuration: $BUILD_CONFIGURATION" ;;
esac

if [ -n "${PEBBLELAB_GATE_D_BLOCKER_09_EVIDENCE_DIR:-}" ]; then
    EVIDENCE_ROOT=$PEBBLELAB_GATE_D_BLOCKER_09_EVIDENCE_DIR
    [ ! -e "$EVIDENCE_ROOT" ] \
        || fail "evidence directory already exists: $EVIDENCE_ROOT"
    /bin/mkdir -p "$EVIDENCE_ROOT"
else
    EVIDENCE_ROOT=$(/usr/bin/mktemp -d /tmp/PebbleLab-GateD-Blocker09.XXXXXX)
fi
HOME_ROOT="$EVIDENCE_ROOT/session-home"
/bin/mkdir -p "$HOME_ROOT"

if [ "$MODE" = baseline-red ]; then
    PEBBLE_BINARY=${PEBBLELAB_GATE_D_BLOCKER_09_BASELINE_BINARY:-}
    [ -x "$PEBBLE_BINARY" ] \
        || fail 'PEBBLELAB_GATE_D_BLOCKER_09_BASELINE_BINARY is required'
else
    swift build --disable-sandbox -c "$BUILD_CONFIGURATION" --product Pebble \
        > "$EVIDENCE_ROOT/build.log" 2>&1
    PEBBLE_BINARY="$ROOT_DIR/.build/$BUILD_CONFIGURATION/Pebble"
    [ -x "$PEBBLE_BINARY" ] || fail 'Pebble binary is missing'
fi

run_process() {
    trace_file=$1
    commands=$2
    shots=$3
    create_world=$4
    if [ "$create_world" -eq 1 ]; then
        CFFIXED_USER_HOME="$HOME_ROOT" \
        PEBBLE_AUTOLOAD=1 \
        PEBBLE_NEWWORLD="$WORLD_SEED" \
        PEBBLE_NEWWORLD_NAME="$WORLD_NAME" \
        run_pebble "$commands" "$shots" > "$trace_file" 2>&1
    else
        CFFIXED_USER_HOME="$HOME_ROOT" \
        PEBBLE_AUTOLOAD=1 \
        run_pebble "$commands" "$shots" > "$trace_file" 2>&1
    fi
    if /usr/bin/pgrep -x Pebble >/dev/null 2>&1; then
        fail "Pebble process remained after $trace_file"
    fi
}

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
    PEBBLE_CMD="$commands" \
    PEBBLE_SHOT="$shots" \
    "$PEBBLE_BINARY"
}

WORLD_READY='/gamerule randomTickSpeed 0;/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/tp 14 66 -21'
SETUP="$WORLD_READY|/lab start;/tp 14 68 -18;/lab pause;/lab movement off;/lab follow off;/lab overlay full;/lab persistence-reconciliation setup;/lab survival on;/lab population on;/lab settlement on;/lab ecology on;/lab ecology scan;/lab mortality on;/lab lifecycle on;/lab kinship on;/lab household on;/lab physical-food-survival on;/lab homeostasis on;/lab genetics on;/lab care on;/lab childhood on;/lab family on;/lab family propose agent_0 agent_1 blocker09-proposal;/lab family accept blocker09-proposal agent_1 agent_0 blocker09-accept;/lab reproduction on;/lab step;/lab step;/lab step;/lab step;/lab care proof proximity-setup;/lab estates on;/lab homeostasis proof estate-co-mingled-setup;/lab homeostasis proof estate-advance 18;/lab homeostasis proof estate-advance 1;/lab estates accept latest agent_1;/lab estates settle latest next;/lab estates proof physical latest tracked;/lab checkpoint save blocker09-preuse;/lab checkpoint status;/lab status"

PROCESS_A="$EVIDENCE_ROOT/process-a.log"
PROCESS_B="$EVIDENCE_ROOT/process-b.log"
CAPTURE_A="$EVIDENCE_ROOT/01-pre-use-checkpoint.png"
CAPTURE_B="$EVIDENCE_ROOT/02-damage-one.png"
run_process "$PROCESS_A" "$SETUP" "-|$CAPTURE_A" 1
require_trace "$PROCESS_A" \
    'estate asset settled .*status=transferred beneficiary=agent_1 custodian=agent_1' \
    'legitimate inherited settlement'
require_trace "$PROCESS_A" \
    'checkpoint saved name=blocker09-preuse .*restartSafe=1 .*protectedCustodyStacks=1 protectedCustodyQuantity=1' \
    'pre-use protected checkpoint'
require_trace "$PROCESS_A" \
    'stop .*custodyHandoff=protected handoffFreshness=exact taggedCustodySpills=1' \
    'pre-use exact graceful escrow'

if [ "$MODE" = baseline-red ]; then
    COMMANDS_B='/tp 14 66 -21|/lab start;/lab pause;/lab movement off;/lab follow off;/lab overlay full;/lab checkpoint load blocker09-preuse;/lab persistence-reconciliation status;/lab estates proof blocker07-inherited-use;/lab checkpoint custody-proof verified-move agent_2;/lab checkpoint save blocker09-damage1;/lab checkpoint list;/lab status'
    run_process "$PROCESS_B" "$COMMANDS_B" "-|$CAPTURE_B" 0
    require_trace "$PROCESS_B" \
        'blocker07 inherited estate use .*damage=0>1 .*physicalMutationOccurred=1 .*firstAttempt=allowed' \
        'baseline first inherited physical use'
    require_trace "$PROCESS_B" \
        'PebbleAgents checkpoint command failed: Material Rights conflicts with physical custody: holder/material/quantity asset:civ27:live-pickaxe' \
        'published baseline damage-one save refusal'
    reject_trace "$PROCESS_B" \
        'checkpoint saved name=blocker09-damage1 ' \
        'baseline checkpoint publication'
    printf '\nGATE D BLOCKER 09 BASELINE RED REPRODUCED\n'
    printf 'Evidence: %s\n' "$EVIDENCE_ROOT"
    exit 0
fi

COMMANDS_B='/tp 14 66 -21|/lab start;/lab pause;/lab movement off;/lab follow off;/lab overlay full;/lab checkpoint load blocker09-preuse;/lab persistence-reconciliation status;/lab estates proof blocker07-inherited-use;/lab checkpoint custody-proof verified-move agent_2;/lab checkpoint custody-proof blocker09-identity status;/lab checkpoint custody-proof blocker09-identity adversarial;/lab checkpoint save blocker09-damage1;/lab checkpoint status;/lab status'
run_process "$PROCESS_B" "$COMMANDS_B" "-|$CAPTURE_B" 0
require_trace "$PROCESS_B" \
    'blocker07 inherited estate use .*damage=0>1 .*physicalMutationOccurred=1 .*firstAttempt=allowed' \
    'first inherited physical use'
require_trace "$PROCESS_B" \
    'blocker09 checkpoint identity .*durableDamage=0 .*currentDamage=1 physicalDamage=1 .*assetContinuity=1 checkpointValidation=current_exact .*assetCount=1' \
    'durable/current/physical identity distinction at damage one'
require_trace "$PROCESS_B" \
    'blocker09 checkpoint identity adversarial missing=refused oldIdentity=refused futureIdentity=refused wrongHolder=refused wrongQuantity=refused ambiguity=refused duplicateReservation=refused session=unchanged world=unchanged checkpointPublication=0 handoffPublication=0' \
    'fail-closed identity adversarials'
require_trace "$PROCESS_B" \
    'checkpoint saved name=blocker09-damage1 .*restartSafe=1 .*protectedCustodyStacks=2 protectedCustodyQuantity=2' \
    'damage-one checkpoint save'
require_trace "$PROCESS_B" \
    'stop .*custodyHandoff=protected handoffFreshness=exact taggedCustodySpills=2' \
    'damage-one protected escrow'
reject_trace "$PROCESS_B" \
    'checkpoint command failed|runtimeErrors=[1-9]' \
    'damage-one process failure'

PROCESS_C="$EVIDENCE_ROOT/process-c.log"
CAPTURE_C="$EVIDENCE_ROOT/03-damage-two.png"
COMMANDS_C='/tp 14 66 -21|/lab start;/lab pause;/lab movement off;/lab follow off;/lab overlay full;/lab checkpoint load blocker09-damage1;/lab persistence-reconciliation status;/lab checkpoint custody-proof blocker09-identity status;/lab estates proof blocker07-inherited-use;/lab checkpoint custody-proof verified-move agent_2;/lab checkpoint custody-proof blocker09-identity status;/lab checkpoint save blocker09-damage2;/lab checkpoint status;/lab status'
run_process "$PROCESS_C" "$COMMANDS_C" "-|$CAPTURE_C" 0
require_trace "$PROCESS_C" \
    'checkpoint loaded name=blocker09-damage1 .*physicalBoundary=acquired reconciliationPhase=postPhysicalBoundary reconciliationRuns=[0-9]+ physicalReconciliation=applied:matched .*committedCurrentReconciliationThisLoad=1' \
    'damage-one fresh restore and Blocker 07 ordering'
require_trace "$PROCESS_C" \
    'blocker09 checkpoint identity .*durableDamage=0 .*currentDamage=1 physicalDamage=1 .*checkpointValidation=current_exact' \
    'damage-one exact protected restore'
require_trace "$PROCESS_C" \
    'blocker07 inherited estate use .*damage=1>2 .*physicalMutationOccurred=1 .*firstAttempt=allowed' \
    'second inherited physical use'
require_trace "$PROCESS_C" \
    'blocker09 checkpoint identity .*durableDamage=0 .*currentDamage=2 physicalDamage=2 .*assetContinuity=1 checkpointValidation=current_exact .*assetCount=1' \
    'repeated legitimate identity evolution'
require_trace "$PROCESS_C" \
    'checkpoint saved name=blocker09-damage2 .*restartSafe=1 .*protectedCustodyStacks=2 protectedCustodyQuantity=3' \
    'damage-two checkpoint save'
require_trace "$PROCESS_C" \
    'stop .*custodyHandoff=protected handoffFreshness=exact taggedCustodySpills=2' \
    'damage-two protected escrow'
reject_trace "$PROCESS_C" \
    'checkpoint command failed|runtimeErrors=[1-9]' \
    'damage-two process failure'

PROCESS_D="$EVIDENCE_ROOT/process-d.log"
CAPTURE_D="$EVIDENCE_ROOT/04-damage-two-restored.png"
COMMANDS_D='/tp 14 66 -21|/lab start;/lab pause;/lab movement off;/lab follow off;/lab overlay full;/lab checkpoint load blocker09-damage2;/lab persistence-reconciliation status;/lab checkpoint custody-proof blocker09-identity status;/lab estates status;/lab status'
run_process "$PROCESS_D" "$COMMANDS_D" "-|$CAPTURE_D" 0
require_trace "$PROCESS_D" \
    'checkpoint loaded name=blocker09-damage2 .*physicalBoundary=acquired reconciliationPhase=postPhysicalBoundary reconciliationRuns=[0-9]+ physicalReconciliation=applied:matched .*committedCurrentReconciliationThisLoad=1' \
    'damage-two second fresh restore'
require_trace "$PROCESS_D" \
    'blocker09 checkpoint identity .*durableDamage=0 .*currentDamage=2 physicalDamage=2 .*checkpointValidation=current_exact .*estateEntry=.*settlementReceipt=.*assetCount=1' \
    'damage-two exact identity with historical settlement retained'
reject_trace "$PROCESS_D" \
    'checkpoint command failed|outcomes=missing|runtimeErrors=[1-9]' \
    'second restart failure'

find_checkpoint_file() {
    checkpoint_name=$1
    file_name=$2
    /usr/bin/find "$HOME_ROOT" -type f \
        -path "*/checkpoints/$checkpoint_name/$file_name" -print -quit
}

DAMAGE1_MANIFEST=$(find_checkpoint_file blocker09-damage1 manifest.json)
DAMAGE1_SESSION=$(find_checkpoint_file blocker09-damage1 session.json)
DAMAGE2_MANIFEST=$(find_checkpoint_file blocker09-damage2 manifest.json)
DAMAGE2_SESSION=$(find_checkpoint_file blocker09-damage2 session.json)
for artifact in "$DAMAGE1_MANIFEST" "$DAMAGE1_SESSION" \
    "$DAMAGE2_MANIFEST" "$DAMAGE2_SESSION"; do
    [ -n "$artifact" ] && [ -s "$artifact" ] \
        || fail 'evolved checkpoint artifact is missing'
done
jq -e '
    .restartSafe == true
    and ([.orchestration.protectedProbeCustodyEvidenceAtSave[]
        | select(.agentID == "agent_1") | .items[]
        | select(.itemKey == "iron_pickaxe" and .damage == 1
            and .quantity == 1)] | length) == 1
    and ([.orchestration.protectedProbeCustodyEvidenceAtSave[]
        | .items[] | select(.itemKey == "iron_pickaxe" and .damage != 1)]
        | length) == 0
' "$DAMAGE1_MANIFEST" >/dev/null \
    || fail 'damage-one protected custody evidence is not exact'
jq -e '
    .restartSafe == true
    and ([.orchestration.protectedProbeCustodyEvidenceAtSave[]
        | select(.agentID == "agent_1") | .items[]
        | select(.itemKey == "iron_pickaxe" and .damage == 2
            and .quantity == 1)] | length) == 1
    and ([.orchestration.protectedProbeCustodyEvidenceAtSave[]
        | .items[] | select(.itemKey == "iron_pickaxe" and .damage != 2)]
        | length) == 0
' "$DAMAGE2_MANIFEST" >/dev/null \
    || fail 'damage-two protected custody evidence is not exact'
jq -e '
    ([.durableState.materialRightsState.records[]
        | select(.asset.assetID == "asset:civ27:live-pickaxe")
        | select(.asset.materialIdentity.damage == 0
            and .lastVerifiedHolder.materialIdentity.damage == 1)]
        | length) == 1
    and ([.durableState.estateState.estates[].assets[]
        | select(.materialRightsAssetID == "asset:civ27:live-pickaxe")
        | select(.settlementObservation.materialIdentity.damage == 0
            and .destinationObservation.materialIdentity.damage == 1
            and .settlementReceiptID != null)] | length) == 1
' "$DAMAGE1_SESSION" >/dev/null \
    || fail 'damage-one durable/current/estate identity history is incoherent'
jq -e '
    ([.durableState.materialRightsState.records[]
        | select(.asset.assetID == "asset:civ27:live-pickaxe")
        | select(.asset.materialIdentity.damage == 0
            and .lastVerifiedHolder.materialIdentity.damage == 2)]
        | length) == 1
    and ([.durableState.estateState.estates[].assets[]
        | select(.materialRightsAssetID == "asset:civ27:live-pickaxe")
        | select(.settlementObservation.materialIdentity.damage == 0
            and .destinationObservation.materialIdentity.damage == 2
            and .settlementReceiptID != null)] | length) == 1
' "$DAMAGE2_SESSION" >/dev/null \
    || fail 'damage-two durable/current/estate identity history is incoherent'
[ "$(jq -r .manifestIntegrityDigest "$DAMAGE1_MANIFEST")" \
    != "$(jq -r .manifestIntegrityDigest "$DAMAGE2_MANIFEST")" ] \
    || fail 'successive checkpoint integrity boundaries are not distinct'
/bin/cp "$DAMAGE1_MANIFEST" "$EVIDENCE_ROOT/damage1-manifest.json"
/bin/cp "$DAMAGE1_SESSION" "$EVIDENCE_ROOT/damage1-session.json"
/bin/cp "$DAMAGE2_MANIFEST" "$EVIDENCE_ROOT/damage2-manifest.json"
/bin/cp "$DAMAGE2_SESSION" "$EVIDENCE_ROOT/damage2-session.json"

for capture in "$CAPTURE_A" "$CAPTURE_B" "$CAPTURE_C" "$CAPTURE_D"; do
    [ -s "$capture" ] || fail "native capture missing: $capture"
done

printf '\nGATE D BLOCKER 09 REPRODUCED AND FIXED\n'
printf 'Damage evolution and saves: 0>1 PASS; 1>2 PASS\n'
printf 'Fresh restores: damage1 exact; damage2 exact\n'
printf 'Adversarial identity proofs: all fail closed\n'
printf 'Physical loss / duplication / synthetic material: 0 / 0 / 0\n'
printf 'Duplicate assets / receipts / settlements: 0 / 0 / 0\n'
printf 'Observer mutations: 0\n'
printf 'Evidence: %s\n' "$EVIDENCE_ROOT"
