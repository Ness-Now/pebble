#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
BASELINE=24c679581f7dfd93d26bffa2e9486a5340af0d9c
CANONICAL_REF=origin/lab/pebblelab-v1
WORLD_NAME=PebbleLab-Disposable-GateD-Evaluation11
WORLD_SEED=46
BUILD_CONFIGURATION=${PEBBLELAB_GATE_D_EVALUATION_11_BUILD_CONFIGURATION:-release}

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

case "${1:-}" in
    "") ;;
    --dry-run)
        printf '%s\n' \
            'Independent V4-GATE-D-v1 Evaluation 11.' \
            'A: new G0/G1 history, renewable late rollback/retry, two holders, checkpoint A.' \
            'B: fresh restore, childhood consequence, G2, causal G0 death, obligation and succession.' \
            'C: load rollback adversarials, mixed collective restore, first inherited use, checkpoint B.' \
            'D: fresh restore, damage 1>2, inherited support attack/rollback, immediate checkpoint, safe 2>3, till/place audit, checkpoint C.' \
            'E: fresh C restore, safe 3>4, second support attack/rollback, safe 4>5, current wild-gathering path, normal continuation.'
        exit 0
        ;;
    *) fail 'usage: scripts/evaluate-pebblelab-gate-d-11.sh [--dry-run]' ;;
esac

cd "$ROOT_DIR"
[ "$(git rev-parse "$CANONICAL_REF")" = "$BASELINE" ] \
    || fail "$CANONICAL_REF is not the mandatory published baseline"
[ "$(git merge-base HEAD "$BASELINE")" = "$BASELINE" ] \
    || fail 'evaluation branch is not based on the mandatory baseline'
[ "$(git branch --show-current)" = 'codex/gate-d-evaluation-11' ] \
    || fail 'Evaluation 11 must run from codex/gate-d-evaluation-11'
if git merge-base --is-ancestor \
    a39cca48d4bbb33873ed9ba63fbcd7146f772976 HEAD; then
    fail 'Evaluation 10 runner commit is an ancestor'
fi
if git merge-base --is-ancestor \
    154a79a6c34247fe5ad0ca4de33badaab3086f09 HEAD; then
    fail 'Evaluation 10 evidence commit is an ancestor'
fi
case "$BUILD_CONFIGURATION" in
    debug|release) ;;
    *) fail "unsupported build configuration: $BUILD_CONFIGURATION" ;;
esac

if [ -n "${PEBBLELAB_GATE_D_EVALUATION_11_EVIDENCE_DIR:-}" ]; then
    EVIDENCE_ROOT=$PEBBLELAB_GATE_D_EVALUATION_11_EVIDENCE_DIR
    [ ! -e "$EVIDENCE_ROOT" ] \
        || fail "evidence directory already exists: $EVIDENCE_ROOT"
    /bin/mkdir -p "$EVIDENCE_ROOT"
else
    EVIDENCE_ROOT=$(/usr/bin/mktemp -d \
        /tmp/PebbleLab-GateD-Evaluation11.XXXXXX)
fi

SESSION_HOME="$EVIDENCE_ROOT/session-home"
PROCESS_A_TRACE="$EVIDENCE_ROOT/process-a-generations-renewable.log"
PROCESS_B_TRACE="$EVIDENCE_ROOT/process-b-mortality-succession.log"
PROCESS_C_TRACE="$EVIDENCE_ROOT/process-c-collective-first-use.log"
PROCESS_D_TRACE="$EVIDENCE_ROOT/process-d-b10-checkpoint-c.log"
PROCESS_E_TRACE="$EVIDENCE_ROOT/process-e-post-c-continuation.log"
WILD_TRACE="$EVIDENCE_ROOT/current-wild-physical-path.log"
/bin/mkdir -p "$SESSION_HOME"

if [ "${PEBBLELAB_GATE_D_EVALUATION_11_SKIP_BUILD:-0}" != "1" ]; then
    swift build --disable-sandbox -c "$BUILD_CONFIGURATION" --product Pebble \
        > "$EVIDENCE_ROOT/build.log" 2>&1
fi
PEBBLE_BINARY="$ROOT_DIR/.build/$BUILD_CONFIGURATION/Pebble"
[ -x "$PEBBLE_BINARY" ] || fail 'Pebble binary missing'

run_environment() {
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
    PEBBLELAB_APP_AGENTS_SKILLS=1 \
    PEBBLELAB_APP_AGENTS_TEACHING=1 \
    PEBBLELAB_APP_AGENTS_SOCIAL=1 \
    PEBBLELAB_APP_AGENTS_OBSERVER=1 \
    PEBBLELAB_APP_AGENTS_FAMILY=1 \
    PEBBLELAB_APP_AGENTS_ECOLOGICAL_OBSERVATION=1 \
    PEBBLELAB_APP_AGENTS_AGRICULTURE=1 \
    PEBBLELAB_APP_AGENTS_WILD_SUBSISTENCE=1 \
    PEBBLELAB_DISPOSABLE_WORLD_PROOF=1 \
    PEBBLELAB_GATE_D_BLOCKER_06=1 \
    PEBBLELAB_GATE_D_BLOCKER_07=1 \
    PEBBLELAB_GATE_D_BLOCKER_08=1 \
    PEBBLELAB_GATE_D_BLOCKER_09=1 \
    PEBBLELAB_GATE_D_BLOCKER_10=1 \
    PEBBLELAB_GATE_D_EVALUATION_11=1 \
    PEBBLE_CMD="$commands" \
    PEBBLE_SHOT="$shots" \
    "$PEBBLE_BINARY"
}

run_process() {
    trace_file=$1
    commands=$2
    shots=$3
    create_world=$4
    candidate_fault=${5:-}
    printf 'Running %s\n' "$(basename "$trace_file")"
    if [ "$create_world" -eq 1 ]; then
        CFFIXED_USER_HOME="$SESSION_HOME" \
        PEBBLE_AUTOLOAD=1 \
        PEBBLE_NEWWORLD="$WORLD_SEED" \
        PEBBLE_NEWWORLD_NAME="$WORLD_NAME" \
        PEBBLELAB_DISPOSABLE_CANDIDATE_PHYSICAL_FAULT="$candidate_fault" \
        run_environment "$commands" "$shots" > "$trace_file" 2>&1
    else
        CFFIXED_USER_HOME="$SESSION_HOME" \
        PEBBLE_AUTOLOAD=1 \
        PEBBLELAB_DISPOSABLE_CANDIDATE_PHYSICAL_FAULT="$candidate_fault" \
        run_environment "$commands" "$shots" > "$trace_file" 2>&1
    fi
    if /usr/bin/pgrep -x Pebble >/dev/null 2>&1; then
        fail "Pebble process remained after $trace_file"
    fi
}

run_wild_process() {
    commands=$1
    shots=$2
    wild_home="$EVIDENCE_ROOT/wild-session-home"
    /bin/mkdir -p "$wild_home"
    printf 'Running %s\n' "$(basename "$WILD_TRACE")"
    CFFIXED_USER_HOME="$wild_home" \
    PEBBLE_AUTOLOAD=1 \
    PEBBLE_NEWWORLD="$WORLD_SEED" \
    PEBBLE_NEWWORLD_NAME=PebbleLab-Disposable-GateD-Evaluation11-Wild \
    PEBBLELAB_DISPOSABLE_CANDIDATE_PHYSICAL_FAULT= \
    run_environment "$commands" "$shots" > "$WILD_TRACE" 2>&1
    if /usr/bin/pgrep -x Pebble >/dev/null 2>&1; then
        fail "Pebble process remained after $WILD_TRACE"
    fi
}

WORLD_RULES='/gamerule randomTickSpeed 0;/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/tp 14 66 -21'
ENABLE='/lab start;/tp 14 69 -21;/lab pause;/lab movement off;/lab follow off;/lab overlay full;/lab persistence-reconciliation setup;/lab survival on;/lab population on;/lab settlement on;/lab ecology on;/lab ecology scan;/lab mortality on;/lab lifecycle on;/lab kinship on;/lab household on;/lab physical-food-survival on;/lab homeostasis on;/lab genetics on;/lab care on;/lab childhood on;/lab family on;/lab skills on;/lab ecological-observation on;/lab agriculture on;/lab estates on;/lab observer open'

PROCESS_A_COMMANDS="$WORLD_RULES|$ENABLE;/lab family lineage agent_2 e11-lineage-2;/lab family house-found agent_2 e11-house-2;/lab family propose agent_0 agent_1 e11-g0-proposal;/lab family lineage agent_0 e11-lineage-0;/lab family accept e11-g0-proposal agent_1 agent_0 e11-g0-accept;/lab family lineage agent_1 e11-lineage-1;/lab family house-cofound agent_0 agent_1 e11-house-0 e11-house-1;/lab reproduction on;/lab step;/lab step;/lab step;/lab step;/lab care proof proximity-setup;/lab step;/lab renewable-subsistence setup;/lab renewable-subsistence plant-first;/lab renewable-subsistence harvest-first;/lab renewable-subsistence harvest-first;/lab renewable-subsistence consume-replant;/lab focus agent_0;/lab ecological-observation scan;/lab renewable-subsistence verify-maturity-mismatch;/lab renewable-subsistence mature-second;/lab renewable-subsistence harvest-second;/lab renewable-subsistence evaluation11-reserve-to-agent1;/lab checkpoint custody-proof status agent_0;/lab checkpoint custody-proof status agent_1;/lab childhood status;/lab renewable-subsistence status;/lab observer select agent_3;/lab observer status|/lab checkpoint save e11-checkpoint-a;/lab checkpoint status;/lab status"

run_process "$PROCESS_A_TRACE" "$PROCESS_A_COMMANDS" \
    "-|$EVIDENCE_ROOT/01-g1-renewable.png|$EVIDENCE_ROOT/02-checkpoint-a.png" \
    1 renewable-after-final-validation

require_trace "$PROCESS_A_TRACE" 'birth finalized .*newborn=agent_3 .*parents=agent_0,agent_1 .*genetics=1' 'G1 birth'
require_trace "$PROCESS_A_TRACE" 'candidate physical fault seam operation=renewable-subsistence .*point=after-final-validation' 'renewable late fault seam'
require_trace "$PROCESS_A_TRACE" 'CANDIDATE_PHYSICAL_ROLLBACK operation=renewable-subsistence .*receiptsRetained=0 publishedSession=unchanged .*publishedRecorder=unchanged' 'renewable exact rollback'
require_trace "$PROCESS_A_TRACE" 'renewable status .*cycle=2 phase=cycleCompleted .*duplicateReceipts=0 duplicateSites=0 .*runtimeErrors=0' 'renewable completion'
require_trace "$PROCESS_A_TRACE" 'evaluation11 renewable reserve .*target=agent_1 .*quantity=1 .*syntheticMaterial=0 physicalLoss=0 physicalDuplication=0 sessionMutation=none' 'second protected holder'
require_trace "$PROCESS_A_TRACE" 'checkpoint custody proof status agent=agent_0 .*stacks=1 quantity=1 .*duplicates=0' 'holder A custody'
require_trace "$PROCESS_A_TRACE" 'checkpoint custody proof status agent=agent_1 .*stacks=1 quantity=1 .*duplicates=0' 'holder B custody'
require_trace "$PROCESS_A_TRACE" 'checkpoint saved name=e11-checkpoint-a .*restartSafe=1 .*protectedCustodyStacks=2 protectedCustodyQuantity=2' 'checkpoint A'
require_trace "$PROCESS_A_TRACE" 'stop probesRemoved=4 reason=termination custodyHandoff=protected handoffFreshness=exact taggedCustodySpills=2' 'checkpoint A escrow'
reject_trace "$PROCESS_A_TRACE" 'CANDIDATE_PHYSICAL_HARD_FAILURE|runtimeErrors=[1-9]|duplicateSites=[1-9]|duplicateReceipts=[1-9]|Observer violated' 'process A failure'

PROCESS_B_COMMANDS="$WORLD_RULES|/lab start;/lab pause;/lab movement off;/lab follow off;/lab overlay full;/lab checkpoint load e11-checkpoint-a;/lab checkpoint custody-proof status agent_0;/lab checkpoint custody-proof status agent_1;/lab renewable-subsistence evaluation11-return-agent1-reserve;/lab persistence-reconciliation status;/lab observer open;/lab observer select agent_3;/lab observer status|/lab care proof supervision-separation;/lab step;/lab care proof supervision-resume;/lab step;/lab care proof proximity-setup;/lab step;/lab childhood status;/lab homeostasis proof estate-advance 3;/lab homeostasis proof estate-advance 2;/lab renewable-subsistence evaluation11-feed-g0;/lab renewable-subsistence evaluation11-transfer-to-g1;/lab family propose agent_3 agent_2 e11-g1-proposal;/lab family accept e11-g1-proposal agent_2 agent_3 e11-g1-accept;/lab homeostasis proof estate-advance 8;/lab renewable-subsistence evaluation11-feed-g0;/lab homeostasis proof estate-advance 3;/lab renewable-subsistence evaluation11-feed-g0;/lab checkpoint custody-proof multi-slot-setup agent_0;/lab homeostasis proof estate-advance 2;/lab childhood evaluation11-cohabit agent_3 agent_4;/lab childhood delegate agent_4 agent_3;/lab care proof proximity-setup;/lab step;/lab births status;/lab lifecycle status;/lab kinship status;/lab household status;/lab family status;/lab care status;/lab childhood status;/lab genetics status;/lab mortality status;/lab exits status;/lab estates status|/lab estates accept latest agent_1;/lab estates proof physical latest tracked;/lab estates proof authority latest tracked;/lab estates proof pre-mutation-refusal latest tracked;/lab estates proof rollback latest next;/lab estates proof physical latest tracked;/lab estates settle latest next;/lab estates proof physical latest tracked;/lab renewable-subsistence evaluation11-final-reserve-to-g1;/lab checkpoint custody-proof status agent_1;/lab checkpoint custody-proof status agent_3;/lab persistence-reconciliation status;/lab observer select agent_4;/lab observer status|/lab checkpoint save e11-succession;/lab checkpoint status;/lab status"

run_process "$PROCESS_B_TRACE" "$PROCESS_B_COMMANDS" \
    "-|$EVIDENCE_ROOT/03-first-restore.png|$EVIDENCE_ROOT/04-g2-mortality.png|$EVIDENCE_ROOT/05-succession.png" 0

require_trace "$PROCESS_B_TRACE" 'checkpoint loaded name=e11-checkpoint-a .*custodyRestoredStacks=2 custodyRestoredQuantity=2 .*physicalBoundary=acquired reconciliationPhase=postPhysicalBoundary reconciliationRuns=1' 'checkpoint A restore ordering'
require_trace "$PROCESS_B_TRACE" 'care supervision .*interruptedTicks=[1-9][0-9]* counted=0 interrupted=1 duplicate=0' 'childhood interruption'
require_trace "$PROCESS_B_TRACE" 'birth finalized .*newborn=agent_4 .*parents=agent_2,agent_3 .*genetics=1' 'G2 birth'
require_trace "$PROCESS_B_TRACE" 'childhood status .*guardians=agent_4->agent_2:canonicalParent@.*caregivers=agent_4->agent_3' 'guardian/caregiver distinction'
require_trace "$PROCESS_B_TRACE" 'mortality exit .*agent=agent_0 cause=compoundedHomeostaticFailure .*probes=5>4' 'causal G0 death'
require_trace "$PROCESS_B_TRACE" 'estate source authority adversarial .*failClosed=1' 'estate authority matrix'
require_trace "$PROCESS_B_TRACE" 'estate settlement rollback lateFailure=verified .*physicalMutationOccurred=1 postMutationVerified=1 faultInjectionReached=1 rollbackClaim=exact' 'true estate late fault'
require_trace "$PROCESS_B_TRACE" 'estate asset settled .*status=transferred beneficiary=agent_1 custodian=agent_1 receipt=estate-settle:' 'immediate retry settlement'
require_trace "$PROCESS_B_TRACE" 'estate physical authority .*physicalLoss=0 physicalDuplication=0 syntheticMaterial=0 estateReceiptCount=1 duplicateReceipt=0 rightsHolder=agent:agent_1' 'estate conservation'
require_trace "$PROCESS_B_TRACE" 'checkpoint saved name=e11-succession .*restartSafe=1 .*protectedCustodyStacks=[2-9]' 'succession checkpoint'
reject_trace "$PROCESS_B_TRACE" 'Estate boundary refused|CANDIDATE_PHYSICAL_HARD_FAILURE|runtimeErrors=[1-9]|duplicateEstateIDs=[1-9]|Observer violated|rollback failed' 'process B failure'

PERSISTENCE_ROOT="$SESSION_HOME/Library/Application Support/Pebble/PebbleLabAgents"
SUCCESSION_MANIFEST=$(/usr/bin/find "$PERSISTENCE_ROOT" -type f \
    -path '*/checkpoints/e11-succession/manifest.json' -print -quit)
[ -n "$SUCCESSION_MANIFEST" ] && [ -s "$SUCCESSION_MANIFEST" ] \
    || fail 'succession manifest missing'
SUCCESSION_SESSION=$(dirname "$SUCCESSION_MANIFEST")/session.json
read -r G1_X G1_Y G1_Z <<EOF
$(jq -r '.durableState.agents[] | select(.agentID == "agent_3") | [.position.x,.position.y,.position.z] | @tsv' "$SUCCESSION_SESSION")
EOF

PROCESS_C_COMMANDS="$WORLD_RULES|/lab start;/lab pause;/lab movement off;/lab follow off;/lab overlay full;/lab checkpoint position-proof collective-semantics;/lab checkpoint position-proof foreign-collision-load e11-succession $G1_X $G1_Y $G1_Z;/lab checkpoint position-proof failure after-first-missing;/lab checkpoint load e11-succession;/lab checkpoint position-proof failure none;/lab checkpoint custody-proof failure after-reconciliation-candidate;/lab checkpoint load e11-succession;/lab checkpoint custody-proof failure none;/lab checkpoint position-proof mixed-load e11-succession agent_2 agent_1;/lab checkpoint custody-proof status agent_1;/lab checkpoint custody-proof status agent_3;/lab persistence-reconciliation status;/lab checkpoint custody-proof verified-move agent_2;/lab estates proof blocker07-inherited-use;/lab checkpoint custody-proof blocker09-identity status;/lab checkpoint custody-proof blocker09-identity adversarial;/lab checkpoint save e11-checkpoint-b;/lab checkpoint status;/lab estates status;/lab observer open;/lab observer select agent_1;/lab observer status|/lab status"

run_process "$PROCESS_C_TRACE" "$PROCESS_C_COMMANDS" \
    "-|$EVIDENCE_ROOT/06-load-adversarials.png|$EVIDENCE_ROOT/07-damage1.png|$EVIDENCE_ROOT/08-checkpoint-b.png" 0

require_trace "$PROCESS_C_TRACE" 'checkpoint collective placement semantics adjacent=valid .*actualOverlap=refused orderIndependent=1 sessionMutation=0 worldMutation=0' 'B08 adjacency and overlap'
require_trace "$PROCESS_C_TRACE" 'checkpoint collective placement foreignCollision=refused .*relocation=none publication=none reconciliationRunsPublished=0' 'B08 foreign collision'
require_trace "$PROCESS_C_TRACE" 'checkpoint probe rollback verified name=e11-succession .*restoredMissing=1 .*candidateReconciliation=discarded session=unchanged recorder=unchanged' 'partial load rollback'
require_trace "$PROCESS_C_TRACE" 'checkpoint probe rollback verified name=e11-succession .*restoredMissing=2 .*candidateReconciliation=discarded session=unchanged recorder=unchanged' 'post-boundary rollback'
require_trace "$PROCESS_C_TRACE" 'checkpoint collective mixed plan name=e11-succession reusedExact=1 repositioned=1 restoredMissing=2 retired=1 positions=exact custody=exact physicalBoundary=acquired reconciliationCommitted=1' 'mixed restore'
require_trace "$PROCESS_C_TRACE" 'blocker07 inherited estate use .*damage=0>1 .*dropsAcquired=1 physicalMutationOccurred=1 postMutationVerified=1 .*firstAttempt=allowed' 'first inherited use'
require_trace "$PROCESS_C_TRACE" 'blocker09 checkpoint identity adversarial missing=refused oldIdentity=refused futureIdentity=refused wrongHolder=refused wrongQuantity=refused ambiguity=refused duplicateReservation=refused .*checkpointPublication=0' 'identity adversarials'
require_trace "$PROCESS_C_TRACE" 'checkpoint saved name=e11-checkpoint-b .*restartSafe=1' 'checkpoint B'
load_fault_count=$(/usr/bin/grep -Ec 'checkpoint command failed: invalid persistence bundle: injected checkpoint failure' "$PROCESS_C_TRACE")
[ "$load_fault_count" -eq 2 ] || fail 'expected two controlled checkpoint-load failures'
reject_trace "$PROCESS_C_TRACE" 'runtimeErrors=[1-9]|rollback failed|Observer violated' 'process C failure'

PROCESS_D_COMMANDS="$WORLD_RULES|/lab start;/lab pause;/lab movement off;/lab follow off;/lab overlay full;/lab checkpoint load e11-checkpoint-b;/lab persistence-reconciliation status;/lab checkpoint custody-proof blocker09-identity status;/lab estates proof blocker07-inherited-use;/lab checkpoint custody-proof blocker09-identity status;/lab estates proof evaluation11-inherited-support;/lab checkpoint save e11-post-b10-refusal;/lab estates proof evaluation11-inherited-safe-use;/lab checkpoint custody-proof blocker09-identity status;/lab gateway proof evaluation11-mutation-family-audit;/lab checkpoint save e11-checkpoint-c;/lab checkpoint status;/lab estates status;/lab observer open;/lab observer select agent_1;/lab observer status|/lab status"

run_process "$PROCESS_D_TRACE" "$PROCESS_D_COMMANDS" \
    "-|$EVIDENCE_ROOT/09-damage2.png|$EVIDENCE_ROOT/10-b10-refusal.png|$EVIDENCE_ROOT/11-safe-after-refusal.png|$EVIDENCE_ROOT/12-checkpoint-c.png" 0

require_trace "$PROCESS_D_TRACE" 'checkpoint loaded name=e11-checkpoint-b .*physicalBoundary=acquired reconciliationPhase=postPhysicalBoundary .*committedCurrentReconciliationThisLoad=1' 'checkpoint B fresh restore'
require_trace "$PROCESS_D_TRACE" 'blocker07 inherited estate use .*damage=1>2 .*physicalMutationOccurred=1 .*firstAttempt=allowed' 'second legitimate identity evolution'
require_trace "$PROCESS_D_TRACE" 'evaluation11 blocker10 inherited support destructive .*currentDamage=2 .*outcome=verificationFailure failure=activeProbePlacementInvalid .*physicalMutationOccurred=1 .*committedEffects=0 .*world=exact tool=unchanged drops=0 custody=unchanged materialRights=unchanged estate=unchanged session=unchanged recorder=unchanged .*protectedPlacement=valid exactRollback=1' 'integrated B10 damage-two refusal'
require_trace "$PROCESS_D_TRACE" 'checkpoint saved name=e11-post-b10-refusal .*restartSafe=1' 'immediate checkpoint after B10 refusal'
require_trace "$PROCESS_D_TRACE" 'evaluation11 safe-after-refusal blocker07 inherited estate use .*damage=2>3 .*physicalMutationOccurred=1 .*firstAttempt=allowed' 'safe physical use after B10 refusal'
require_trace "$PROCESS_D_TRACE" 'evaluation11 blocker10 mutation family composition .*safeTill=succeeded safePlace=succeeded .*syntheticMaterial=0 exact=1' 'till/place adversarial and safe controls'
require_trace "$PROCESS_D_TRACE" 'checkpoint saved name=e11-checkpoint-c .*restartSafe=1' 'checkpoint C'
reject_trace "$PROCESS_D_TRACE" 'checkpoint command failed|runtimeErrors=[1-9]|Observer violated' 'process D failure'

PROCESS_E_COMMANDS="$WORLD_RULES|/lab start;/lab pause;/lab movement off;/lab follow off;/lab overlay full;/lab checkpoint load e11-checkpoint-c;/lab persistence-reconciliation status;/lab checkpoint custody-proof blocker09-identity status;/lab estates proof evaluation11-inherited-support;/lab care status;/lab childhood status;/lab family status;/lab mortality status;/lab estates status;/lab observer open;/lab observer select agent_4;/lab observer status|/lab step;/lab care status;/lab observer status;/lab status"

run_process "$PROCESS_E_TRACE" "$PROCESS_E_COMMANDS" \
    "-|$EVIDENCE_ROOT/13-checkpoint-c-restore.png|$EVIDENCE_ROOT/14-b10-after-c.png|$EVIDENCE_ROOT/15-wild-gathering-current.png" 0

require_trace "$PROCESS_E_TRACE" 'checkpoint loaded name=e11-checkpoint-c .*physicalBoundary=acquired reconciliationPhase=postPhysicalBoundary .*committedCurrentReconciliationThisLoad=1' 'checkpoint C fresh restore'
require_trace "$PROCESS_E_TRACE" 'blocker09 checkpoint identity .*durableDamage=0 .*currentDamage=3 physicalDamage=3 .*checkpointValidation=current_exact' 'damage-three exact restore'
require_trace "$PROCESS_E_TRACE" 'evaluation11 blocker10 inherited support destructive .*currentDamage=3 .*outcome=verificationFailure failure=activeProbePlacementInvalid .*tool=unchanged drops=0 .*exactRollback=1' 'B10 after checkpoint C restart'
require_trace "$PROCESS_E_TRACE" 'step tick=28' 'normal civilization continuation after C restore'
require_trace "$PROCESS_E_TRACE" 'care tick=28 enabled=1 assignments=1' 'obligation continuity after third restart'
reject_trace "$PROCESS_E_TRACE" 'checkpoint command failed|runtimeErrors=[1-9]|Observer violated|rollbackFailure' 'process E failure'

WILD_COMMANDS="$WORLD_RULES|/lab start;/lab pause;/lab movement off;/lab follow off;/lab overlay full;/lab population on;/lab lifecycle on;/lab skills on;/lab ecological-observation on;/lab wild-subsistence on;/lab focus agent_0;/lab wild-subsistence proof setup;/lab wild-subsistence proof fish;/lab wild-subsistence proof hunt;/lab wild-subsistence proof gather;/lab wild-subsistence status|/lab status"
run_wild_process "$WILD_COMMANDS" \
    "-|$EVIDENCE_ROOT/15-wild-gathering-current.png"
require_trace "$WILD_TRACE" 'wild subsistence gathering .*interaction=canonicalBreak drops=exact loot=sweet_berries custody=real depleted=1 .*abstractCredit=0' 'current canonical wild gathering path'
require_trace "$WILD_TRACE" 'wild subsistence cleanup entities=exact cells=exact custody=exact probes=restored' 'wild fixture cleanup'
reject_trace "$WILD_TRACE" 'runtimeErrors=[1-9]|rollbackFailure|abstractCredit=[^0]|campStockDelta=[^0]|resourceInventoryDelta=[^0]' 'current wild-path failure'

find_checkpoint_file() {
    checkpoint_name=$1
    file_name=$2
    /usr/bin/find "$SESSION_HOME" -type f \
        -path "*/checkpoints/$checkpoint_name/$file_name" -print -quit
}

for checkpoint in e11-checkpoint-a e11-succession e11-checkpoint-b \
        e11-post-b10-refusal e11-checkpoint-c; do
    manifest=$(find_checkpoint_file "$checkpoint" manifest.json)
    session_file=$(find_checkpoint_file "$checkpoint" session.json)
    [ -n "$manifest" ] && [ -s "$manifest" ] \
        || fail "manifest missing: $checkpoint"
    [ -n "$session_file" ] && [ -s "$session_file" ] \
        || fail "session missing: $checkpoint"
    jq -e '.schemaVersion == 30 and .restartSafe == true' "$manifest" \
        >/dev/null || fail "invalid manifest: $checkpoint"
    /bin/cp "$manifest" "$EVIDENCE_ROOT/$checkpoint-manifest.json"
    /bin/cp "$session_file" "$EVIDENCE_ROOT/$checkpoint-session.json"
done

jq -e '([.orchestration.protectedProbeCustodyEvidenceAtSave[] | .items[] | select(.itemKey == "iron_pickaxe" and .damage == 1 and .quantity == 1)] | length) == 1' \
    "$EVIDENCE_ROOT/e11-checkpoint-b-manifest.json" >/dev/null \
    || fail 'checkpoint B does not protect exact damage-one tool'
jq -e '([.orchestration.protectedProbeCustodyEvidenceAtSave[] | .items[] | select(.itemKey == "iron_pickaxe" and .damage == 3 and .quantity == 1)] | length) == 1' \
    "$EVIDENCE_ROOT/e11-checkpoint-c-manifest.json" >/dev/null \
    || fail 'checkpoint C does not protect exact damage-three tool'
[ "$(jq -r .manifestIntegrityDigest "$EVIDENCE_ROOT/e11-checkpoint-a-manifest.json")" \
    != "$(jq -r .manifestIntegrityDigest "$EVIDENCE_ROOT/e11-checkpoint-b-manifest.json")" ] \
    || fail 'checkpoint A/B boundaries are not distinct'
[ "$(jq -r .manifestIntegrityDigest "$EVIDENCE_ROOT/e11-checkpoint-b-manifest.json")" \
    != "$(jq -r .manifestIntegrityDigest "$EVIDENCE_ROOT/e11-checkpoint-c-manifest.json")" ] \
    || fail 'checkpoint B/C boundaries are not distinct'

for capture in "$EVIDENCE_ROOT"/*.png; do
    [ -s "$capture" ] || fail "native capture missing: $capture"
done

printf '\nV4-GATE-D-v1 EVALUATION 11 integrated campaign: PASS — LOCAL EVIDENCE CANDIDATE FOR SENIOR REVIEW\n'
printf 'Evidence: %s\n' "$EVIDENCE_ROOT"
printf 'Checkpoints A/B/C: exact and distinct\n'
printf 'Physical loss / duplication / synthetic material / duplicate probes: 0 / 0 / 0 / 0\n'
printf 'Observer mutation count: 0\n'
