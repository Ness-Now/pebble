#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
BASELINE=02c7778769c8a6d971f4eb8bd73e5a3f7afc8c1e
SOURCE_HOME=${PEBBLELAB_GATE_D_BLOCKER_08_SESSION_HOME:-}
BUILD_CONFIGURATION=${PEBBLELAB_GATE_D_BLOCKER_08_BUILD_CONFIGURATION:-release}

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
            'Gate D Blocker 08 collective probe-restore correction (dry run).' \
            'Input: immutable Evaluation 08 e08-succession session-home.' \
            'Baseline-red: isolated createProbe rejects agent_3 against its checkpoint escrow.' \
            'Green: foreign collision refusal, mixed-plan load, partial creation rollback, post-reconciliation rollback, immediate retry, inherited first use.' \
            'Order proof: independent fresh load creates agent_4 then agent_3 with the same collective authority.' \
            'Scope: targeted Blocker 08 correction; this runner does not evaluate Gate D.'
        exit 0
        ;;
    --baseline-red) MODE=baseline-red ;;
    "") ;;
    *) fail 'usage: scripts/verify-pebblelab-gate-d-collective-probe-restore-fix.sh [--dry-run|--baseline-red]' ;;
esac

cd "$ROOT_DIR"
[ "$(git rev-parse origin/lab/pebblelab-v1)" = "$BASELINE" ] \
    || fail 'canonical remote is not the Blocker 08 baseline'
[ "$(git merge-base HEAD "$BASELINE")" = "$BASELINE" ] \
    || fail 'current branch does not descend from the Blocker 08 baseline'
[ -n "$SOURCE_HOME" ] && [ -d "$SOURCE_HOME" ] \
    || fail 'PEBBLELAB_GATE_D_BLOCKER_08_SESSION_HOME is required'

SOURCE_MANIFEST=$(/usr/bin/find "$SOURCE_HOME" -type f \
    -path '*/checkpoints/e08-succession/manifest.json' -print -quit)
[ -n "$SOURCE_MANIFEST" ] && [ -s "$SOURCE_MANIFEST" ] \
    || fail 'e08-succession manifest is missing'
SOURCE_SESSION=$(dirname "$SOURCE_MANIFEST")/session.json
[ -s "$SOURCE_SESSION" ] || fail 'e08-succession session is missing'
jq -e '
    .schemaVersion == 30
    and .restartSafe == true
    and (.orchestration.protectedProbeCustodyEvidenceAtSave
        | map(select(.items | length > 0)) | length) == 2
' "$SOURCE_MANIFEST" >/dev/null \
    || fail 'source checkpoint is not the protected schema-30 E08 boundary'
jq -e '
    [.durableState.agents[] | {
        id: .agentID,
        position: [.position.x, .position.y, .position.z]
    }] == [
        {"id":"agent_1","position":[21,66,-24]},
        {"id":"agent_2","position":[22,66,-24]},
        {"id":"agent_3","position":[20,66,-24]},
        {"id":"agent_4","position":[19,67,-23]}
    ]
' "$SOURCE_SESSION" >/dev/null \
    || fail 'source checkpoint target set is not the E08 decisive layout'

case "$BUILD_CONFIGURATION" in
    debug|release) ;;
    *) fail "unsupported build configuration: $BUILD_CONFIGURATION" ;;
esac

if [ -n "${PEBBLELAB_GATE_D_BLOCKER_08_EVIDENCE_DIR:-}" ]; then
    EVIDENCE_ROOT=$PEBBLELAB_GATE_D_BLOCKER_08_EVIDENCE_DIR
    [ ! -e "$EVIDENCE_ROOT" ] \
        || fail "evidence directory already exists: $EVIDENCE_ROOT"
    /bin/mkdir -p "$EVIDENCE_ROOT"
else
    EVIDENCE_ROOT=$(/usr/bin/mktemp -d /tmp/PebbleLab-GateD-Blocker08-Fix.XXXXXX)
fi
/bin/cp "$SOURCE_MANIFEST" "$EVIDENCE_ROOT/e08-succession-manifest.json"
/bin/cp "$SOURCE_SESSION" "$EVIDENCE_ROOT/e08-succession-session.json"

if [ "$MODE" = baseline-red ]; then
    PEBBLE_BINARY=${PEBBLELAB_GATE_D_BLOCKER_08_BASELINE_BINARY:-}
    [ -x "$PEBBLE_BINARY" ] \
        || fail 'PEBBLELAB_GATE_D_BLOCKER_08_BASELINE_BINARY is required'
else
    swift build --disable-sandbox -c "$BUILD_CONFIGURATION" --product Pebble \
        > "$EVIDENCE_ROOT/build.log" 2>&1
    PEBBLE_BINARY="$ROOT_DIR/.build/$BUILD_CONFIGURATION/Pebble"
    [ -x "$PEBBLE_BINARY" ] || fail 'Pebble binary is missing'
fi

run_pebble() {
    run_home=$1
    commands=$2
    shots=$3
    trace_file=$4
    reverse_order=$5
    CFFIXED_USER_HOME="$run_home" \
    PEBBLE_AUTOLOAD=1 \
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
    PEBBLELAB_DISPOSABLE_WORLD_PROOF=1 \
    PEBBLELAB_GATE_D_BLOCKER_06=1 \
    PEBBLELAB_GATE_D_BLOCKER_07=1 \
    PEBBLELAB_GATE_D_BLOCKER_08=1 \
    PEBBLELAB_GATE_D_BLOCKER_08_REVERSE_CREATION_ORDER="$reverse_order" \
    PEBBLE_CMD="$commands" \
    PEBBLE_SHOT="$shots" \
    "$PEBBLE_BINARY" > "$trace_file" 2>&1
    if /usr/bin/pgrep -x Pebble >/dev/null 2>&1; then
        fail "Pebble process remained after $trace_file"
    fi
}

WORLD_READY='/gamerule randomTickSpeed 0;/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/tp 14 66 -21'

if [ "$MODE" = baseline-red ]; then
    RED_HOME="$EVIDENCE_ROOT/baseline-home"
    /bin/mkdir -p "$RED_HOME"
    /bin/cp -R "$SOURCE_HOME/." "$RED_HOME/"
    RED_TRACE="$EVIDENCE_ROOT/baseline-red.log"
    RED_CAPTURE="$EVIDENCE_ROOT/baseline-red.png"
    RED_COMMANDS="$WORLD_READY|/lab start;/lab pause;/lab movement off;/lab follow off;/lab checkpoint load e08-succession;/lab persistence-reconciliation status;/lab status"
    run_pebble "$RED_HOME" "$RED_COMMANDS" "-|$RED_CAPTURE" \
        "$RED_TRACE" 0
    require_trace "$RED_TRACE" \
        'checkpoint probe classification agent=agent_3 checkpoint=20,66,-24 current=none .*reconciliation=restored_missing' \
        'agent_3 restore plan'
    require_trace "$RED_TRACE" \
        'checkpoint probe rollback verified name=e08-succession .*restoredMissing=0 .*candidateReconciliation=discarded session=unchanged recorder=unchanged' \
        'baseline exact rollback'
    require_trace "$RED_TRACE" \
        'checkpoint command failed: bootstrapPlacementBoundary\("invalid physical creation position for agent_3:entityCollision"\)' \
        'baseline false isolated collision'
    reject_trace "$RED_TRACE" \
        'checkpoint physical boundary acquired|persistence reconciliation candidate|checkpoint loaded name=e08-succession' \
        'baseline false publication'
    [ -s "$RED_CAPTURE" ] || fail 'baseline capture is missing'
    printf '\nGATE D BLOCKER 08 BASELINE RED REPRODUCED\n'
    printf 'Evidence: %s\n' "$EVIDENCE_ROOT"
    exit 0
fi

NORMAL_HOME="$EVIDENCE_ROOT/normal-home"
REVERSE_HOME="$EVIDENCE_ROOT/reverse-home"
/bin/mkdir -p "$NORMAL_HOME" "$REVERSE_HOME"
/bin/cp -R "$SOURCE_HOME/." "$NORMAL_HOME/"
/bin/cp -R "$SOURCE_HOME/." "$REVERSE_HOME/"

NORMAL_TRACE="$EVIDENCE_ROOT/normal-order.log"
NORMAL_RESTORE_CAPTURE="$EVIDENCE_ROOT/normal-restored-layout.png"
INHERITED_USE_CAPTURE="$EVIDENCE_ROOT/inherited-first-use.png"
NORMAL_COMMANDS="$WORLD_READY|/lab start;/lab pause;/lab movement off;/lab follow off;/lab checkpoint position-proof collective-semantics;/lab checkpoint position-proof foreign-collision-load e08-succession 20 66 -24;/lab checkpoint position-proof failure after-first-missing;/lab checkpoint load e08-succession;/lab checkpoint position-proof failure none;/lab checkpoint custody-proof failure after-reconciliation-candidate;/lab checkpoint load e08-succession;/lab checkpoint custody-proof failure none;/lab checkpoint load e08-succession;/lab checkpoint custody-proof status agent_1;/lab checkpoint custody-proof status agent_3;/lab persistence-reconciliation status;/lab status|/lab estates proof blocker07-inherited-use;/lab estates proof physical latest tracked;/lab persistence-reconciliation status;/lab status"
run_pebble "$NORMAL_HOME" "$NORMAL_COMMANDS" \
    "-|$NORMAL_RESTORE_CAPTURE|$INHERITED_USE_CAPTURE" \
    "$NORMAL_TRACE" 0

require_trace "$NORMAL_TRACE" \
    'checkpoint collective placement semantics adjacent=valid .*actualOverlap=refused orderIndependent=1 sessionMutation=0 worldMutation=0' \
    'adjacency, overlap, and collective order semantics'
require_trace "$NORMAL_TRACE" \
    'checkpoint collective placement foreignCollision=refused .*publication=none reconciliationRunsPublished=0 .*residualForeignEntity=0' \
    'foreign collision fail-closed proof'
require_trace "$NORMAL_TRACE" \
    'checkpoint collective placement authority name=e08-succession .*retired=1 repositioned=2 missing=2 checkpointEscrow=2 .*targetOverlap=0 foreignCollision=0 terrain=valid' \
    'mixed collective authority acquisition'
require_trace "$NORMAL_TRACE" \
    'checkpoint missing probe application order name=e08-succession agents=agent_3,agent_4 authority=collective' \
    'normal missing-probe order'
require_trace "$NORMAL_TRACE" \
    'checkpoint probe rollback verified name=e08-succession repositioned=2 restoredMissing=1 retired=1 custodyRestored=0 custodySpillsRestored=0 candidateReconciliation=discarded session=unchanged recorder=unchanged' \
    'partial creation rollback'
require_trace "$NORMAL_TRACE" \
    'checkpoint probe rollback verified name=e08-succession repositioned=2 restoredMissing=2 retired=1 custodyRestored=2 custodySpillsRestored=2 candidateReconciliation=discarded session=unchanged recorder=unchanged' \
    'post-reconciliation rollback'
require_trace "$NORMAL_TRACE" \
    'checkpoint physical boundary acquired name=e08-succession probes=4 positions=exact custody=exact retired=1 restoredMissing=2 custodyRestored=2' \
    'complete physical boundary'
require_trace "$NORMAL_TRACE" \
    'checkpoint loaded name=e08-succession .*probeRestoredMissing=2 probeRepositionedVerified=2 probeRetiredVerified=1 .*custodyRestoredStacks=2 custodyRestoredQuantity=2 .*physicalReconciliation=applied:matched reconciliationRunsBefore=1 committedCurrentReconciliationThisLoad=1' \
    'one current reconciliation and exact load publication'
require_trace "$NORMAL_TRACE" \
    'blocker07 inherited estate use .*damage=0>1 .*dropsAcquired=1 physicalMutationOccurred=1 postMutationVerified=1 .*firstAttempt=allowed physicalLoss=0 physicalDuplication=0 syntheticMaterial=0' \
    'first inherited physical use'
require_trace "$NORMAL_TRACE" \
    'summary reason=termination .*agents=4 .*runtimeErrors=0 .*probesRemoved=4 ' \
    'normal process cleanup'
[ -s "$NORMAL_RESTORE_CAPTURE" ] \
    || fail 'normal restored-layout capture is missing'
[ -s "$INHERITED_USE_CAPTURE" ] \
    || fail 'inherited-use capture is missing'

MIXED_HOME="$EVIDENCE_ROOT/mixed-home"
/bin/mkdir -p "$MIXED_HOME"
/bin/cp -R "$SOURCE_HOME/." "$MIXED_HOME/"
MIXED_TRACE="$EVIDENCE_ROOT/mixed-plan.log"
MIXED_CAPTURE="$EVIDENCE_ROOT/mixed-restored-layout.png"
MIXED_COMMANDS="$WORLD_READY|/lab start;/lab pause;/lab movement off;/lab follow off;/lab checkpoint position-proof mixed-load e08-succession agent_2 agent_1;/lab checkpoint custody-proof status agent_1;/lab checkpoint custody-proof status agent_3;/lab persistence-reconciliation status;/lab status"
run_pebble "$MIXED_HOME" "$MIXED_COMMANDS" \
    "-|$MIXED_CAPTURE" "$MIXED_TRACE" 0
require_trace "$MIXED_TRACE" \
    'checkpoint collective mixed plan name=e08-succession reusedExact=1 repositioned=1 restoredMissing=2 retired=1 positions=exact custody=exact physicalBoundary=acquired reconciliationCommitted=1' \
    'mixed reuse, reposition, restore, and retire plan'
require_trace "$MIXED_TRACE" \
    'checkpoint loaded name=e08-succession .*probeReusedExact=1 probeRestoredMissing=2 probeRepositionedVerified=1 probeRetiredVerified=1 .*custodyRestoredStacks=2 custodyRestoredQuantity=2 .*physicalReconciliation=applied:matched .*committedCurrentReconciliationThisLoad=1' \
    'mixed plan exact publication'
reject_trace "$MIXED_TRACE" \
    '^\[lab-live\] error|runtimeErrors=[1-9]|rollback failed|duplicates=[1-9]' \
    'mixed-plan runtime, rollback, or duplication failure'
[ -s "$MIXED_CAPTURE" ] || fail 'mixed-plan capture is missing'

REVERSE_TRACE="$EVIDENCE_ROOT/reverse-order.log"
REVERSE_CAPTURE="$EVIDENCE_ROOT/reverse-restored-layout.png"
REVERSE_COMMANDS="$WORLD_READY|/lab start;/lab pause;/lab movement off;/lab follow off;/lab checkpoint load e08-succession;/lab checkpoint custody-proof status agent_1;/lab checkpoint custody-proof status agent_3;/lab persistence-reconciliation status;/lab status"
run_pebble "$REVERSE_HOME" "$REVERSE_COMMANDS" \
    "-|$REVERSE_CAPTURE" "$REVERSE_TRACE" 1
require_trace "$REVERSE_TRACE" \
    'checkpoint missing probe application order name=e08-succession agents=agent_4,agent_3 authority=collective' \
    'reversed missing-probe order'
require_trace "$REVERSE_TRACE" \
    'checkpoint missing probe created agent=agent_4 position=19,67,-23 authority=collective' \
    'agent_4 created first'
require_trace "$REVERSE_TRACE" \
    'checkpoint missing probe created agent=agent_3 position=20,66,-24 authority=collective' \
    'agent_3 created second'
require_trace "$REVERSE_TRACE" \
    'checkpoint loaded name=e08-succession .*probeRestoredMissing=2 probeRepositionedVerified=2 probeRetiredVerified=1 .*custodyRestoredStacks=2 custodyRestoredQuantity=2 .*physicalReconciliation=applied:matched .*committedCurrentReconciliationThisLoad=1' \
    'reverse order exact publication'
reject_trace "$REVERSE_TRACE" \
    '^\[lab-live\] error|runtimeErrors=[1-9]|rollback failed|duplicates=[1-9]' \
    'reverse-order runtime, rollback, or duplication failure'
[ -s "$REVERSE_CAPTURE" ] || fail 'reverse-order capture is missing'

jq -n \
    --arg baseline "$BASELINE" \
    --arg checkpoint "$(jq -r .checkpointID "$SOURCE_MANIFEST")" \
    '{
        baseline: $baseline,
        checkpointID: $checkpoint,
        targetSet: {
            agent_1: [21,66,-24], agent_2: [22,66,-24],
            agent_3: [20,66,-24], agent_4: [19,67,-23]
        },
        normalCreationOrder: ["agent_3","agent_4"],
        reverseCreationOrder: ["agent_4","agent_3"],
        mixedPlan: {
            reusedExact: 1, repositioned: 1,
            restoredMissing: 2, retired: 1
        },
        physicalBoundary: "acquired",
        committedCurrentReconciliationThisLoad: 1,
        firstInheritedUse: "allowed",
        physicalLoss: 0,
        physicalDuplication: 0,
        syntheticMaterial: 0,
        duplicateProbes: 0
    }' > "$EVIDENCE_ROOT/result.json"

printf '\nGATE D BLOCKER 08 REPRODUCED AND FIXED\n'
printf 'Evidence: %s\n' "$EVIDENCE_ROOT"
printf 'Normal creation order: agent_3,agent_4\n'
printf 'Reverse creation order: agent_4,agent_3\n'
printf 'Physical loss / duplication / synthetic material / duplicate probes: 0 / 0 / 0 / 0\n'
printf 'Current reconciliation committed by successful load: 1\n'
printf 'Inherited first use: allowed with real physical mutation\n'
