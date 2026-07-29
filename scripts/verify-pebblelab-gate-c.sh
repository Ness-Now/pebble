#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
WORLD_NAME="PebbleLab-Disposable-GateC-46"
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
    printf 'V4-GATE-C-v1 independent evaluation (dry run)\n'
    printf '  Focused: CIV-26 rights, CIV-27 reconciliation, CIV-28 Observer, checkpoint/replay.\n'
    printf '  World: %s seed=%s\n' "$WORLD_NAME" "$WORLD_SEED"
    printf '  Process 1: create real container/item and rights, save schema 20, inspect Observer, capture, then remove the container through /setblock and stop.\n'
    printf '  Process 2: restore the same World/checkpoint, reconcile the missing physical asset, inspect history, continue eight ticks, capture, and clean exactly.\n'
    printf '  Product behavior is not modified by this harness.\n'
    exit 0
fi
[ "$#" -eq 0 ] || fail "usage: scripts/verify-pebblelab-gate-c.sh [--dry-run]"

git -C "$ROOT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    || fail "repository metadata missing"
[ "$(git -C "$ROOT_DIR" rev-parse --show-toplevel)" = "$ROOT_DIR" ] \
    || fail "unexpected repository root"

if [ -n "${PEBBLELAB_GATE_C_EVIDENCE_DIR:-}" ]; then
    EVIDENCE_ROOT=$PEBBLELAB_GATE_C_EVIDENCE_DIR
    [ ! -e "$EVIDENCE_ROOT" ] \
        || fail "evidence directory already exists: $EVIDENCE_ROOT"
    /bin/mkdir -p "$EVIDENCE_ROOT"
else
    EVIDENCE_ROOT=$(/usr/bin/mktemp -d /tmp/PebbleLab-GateC.XXXXXX)
fi
SESSION_HOME="$EVIDENCE_ROOT/home"
/bin/mkdir -p "$SESSION_HOME"

MATERIAL_TRACE="$EVIDENCE_ROOT/focused-material-rights.log"
RECONCILIATION_TRACE="$EVIDENCE_ROOT/focused-persistence-reconciliation.log"
OBSERVER_TRACE="$EVIDENCE_ROOT/focused-observer.log"
CHECKPOINT_TRACE="$EVIDENCE_ROOT/focused-checkpoint-replay.log"
PHASE1_TRACE="$EVIDENCE_ROOT/gate-c-before-restart.log"
PHASE2_TRACE="$EVIDENCE_ROOT/gate-c-after-restart.log"
BEFORE_CAPTURE="$EVIDENCE_ROOT/gate-c-observer-before-restart.png"
AFTER_CAPTURE="$EVIDENCE_ROOT/gate-c-observer-after-restart.png"

cd "$ROOT_DIR"

printf '\nGate C focused adversarial matrix.\n'
swift build -c debug --product pebsmoke
SMOKE_BINARY="$ROOT_DIR/.build/debug/pebsmoke"
[ -x "$SMOKE_BINARY" ] || fail "debug pebsmoke binary missing"

PEBBLELAB_SMOKE_ONLY=material-rights \
    "$SMOKE_BINARY" 2>&1 | /usr/bin/tee "$MATERIAL_TRACE"
require_trace "$MATERIAL_TRACE" '^21 passed, 0 failed$' \
    'complete CIV-26 focused suite'
require_trace "$MATERIAL_TRACE" \
    'rolled-back transfer publishes no false roles' \
    'failed transfer cannot publish false social state'
require_trace "$MATERIAL_TRACE" \
    'prior and competing claims coexist as conflict' \
    'physical/social divergence and competing claims'
require_trace "$MATERIAL_TRACE" \
    'active claim bound refuses overflow' \
    'bounded claims'

PEBBLELAB_SMOKE_ONLY=persistence-reconciliation \
    "$SMOKE_BINARY" 2>&1 | /usr/bin/tee "$RECONCILIATION_TRACE"
require_trace "$RECONCILIATION_TRACE" '^18 passed, 0 failed$' \
    'complete CIV-27 focused suite'
require_trace "$RECONCILIATION_TRACE" \
    'changed physical holder replaces only the physical projection' \
    'changed-holder reconciliation'
require_trace "$RECONCILIATION_TRACE" \
    'missing asset is not administratively recreated' \
    'missing asset refusal'
require_trace "$RECONCILIATION_TRACE" \
    'multiple physical holders are refused atomically' \
    'duplicated/conflicting holder refusal'
require_trace "$RECONCILIATION_TRACE" \
    'ambiguous same-holder stacks are refused atomically' \
    'ambiguous candidate refusal'
require_trace "$RECONCILIATION_TRACE" \
    'reapplying one restoration is idempotent' \
    'repeated restore idempotence'
require_trace "$RECONCILIATION_TRACE" \
    'wrong World is refused before session publication' \
    'wrong-World refusal'
require_trace "$RECONCILIATION_TRACE" \
    'incompatible checkpoint schema is rejected cleanly' \
    'schema corruption refusal'

PEBBLELAB_SMOKE_ONLY=observer \
    "$SMOKE_BINARY" 2>&1 | /usr/bin/tee "$OBSERVER_TRACE"
require_trace "$OBSERVER_TRACE" '^20 passed, 0 failed$' \
    'complete CIV-28 focused suite'
require_trace "$OBSERVER_TRACE" \
    'observation cannot tick, append causality, or change durable state' \
    'read-only projection'
require_trace "$OBSERVER_TRACE" \
    'permission on asset A cannot authorize activity on asset B' \
    'exact asset permission'
require_trace "$OBSERVER_TRACE" \
    'a newer action replaces an older refused-use reason' \
    'current reason freshness'
require_trace "$OBSERVER_TRACE" \
    'direct causal references obey their bound with explicit truncation' \
    'bounded causal references'
require_trace "$OBSERVER_TRACE" \
    'repeated post-restart observation creates no duplicate event' \
    'repeated observation idempotence'

PEBBLELAB_SMOKE_ONLY=checkpoint-replay \
    "$SMOKE_BINARY" 2>&1 | /usr/bin/tee "$CHECKPOINT_TRACE"
require_trace "$CHECKPOINT_TRACE" '^49 passed, 0 failed$' \
    'complete checkpoint/replay focused suite'
require_trace "$CHECKPOINT_TRACE" \
    'checkpoint repeated restore digest exact' \
    'repeated restore identity'
require_trace "$CHECKPOINT_TRACE" \
    'checkpoint restore causal sequence exact' \
    'causal sequence restore'
require_trace "$CHECKPOINT_TRACE" \
    'replay rejects cross-simulation record' \
    'cross-simulation corruption refusal'
require_trace "$CHECKPOINT_TRACE" \
    'replay rejects truncated NDJSON' \
    'truncated replay refusal'

printf '\nGate C integrated live campaign build.\n'
swift build -c release --product Pebble
PEBBLE_BINARY="$ROOT_DIR/.build/release/Pebble"
[ -x "$PEBBLE_BINARY" ] || fail "release Pebble binary missing"

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
        PEBBLELAB_APP_AGENTS=1 \
        PEBBLELAB_APP_AGENTS_MOVE=1 \
        PEBBLELAB_APP_PROBES=1 \
        PEBBLELAB_DEBUG_ENTITIES=1 \
        PEBBLELAB_APP_AGENTS_TRACE=1 \
        PEBBLELAB_APP_AGENTS_TRACE_EVERY=1 \
        PEBBLELAB_APP_AGENTS_MATERIAL=1 \
        PEBBLELAB_APP_AGENTS_PERSISTENCE=1 \
        PEBBLELAB_APP_AGENTS_RECONCILIATION=1 \
        PEBBLELAB_APP_AGENTS_OBSERVER=1 \
        PEBBLELAB_DISPOSABLE_WORLD_PROOF=1 \
        PEBBLE_CMD="$commands" \
        PEBBLE_SHOT="$shots" \
        "$PEBBLE_BINARY" 2>&1 | /usr/bin/tee "$run_trace"
    else
        CFFIXED_USER_HOME="$SESSION_HOME" \
        PEBBLE_AUTOLOAD=1 \
        PEBBLELAB_APP_AGENTS=1 \
        PEBBLELAB_APP_AGENTS_MOVE=1 \
        PEBBLELAB_APP_PROBES=1 \
        PEBBLELAB_DEBUG_ENTITIES=1 \
        PEBBLELAB_APP_AGENTS_TRACE=1 \
        PEBBLELAB_APP_AGENTS_TRACE_EVERY=1 \
        PEBBLELAB_APP_AGENTS_MATERIAL=1 \
        PEBBLELAB_APP_AGENTS_PERSISTENCE=1 \
        PEBBLELAB_APP_AGENTS_RECONCILIATION=1 \
        PEBBLELAB_APP_AGENTS_OBSERVER=1 \
        PEBBLELAB_DISPOSABLE_WORLD_PROOF=1 \
        PEBBLE_CMD="$commands" \
        PEBBLE_SHOT="$shots" \
        "$PEBBLE_BINARY" 2>&1 | /usr/bin/tee "$run_trace"
    fi
    if /usr/bin/pgrep -x Pebble >/dev/null 2>&1; then
        fail "Pebble process remained after phase: $run_trace"
    fi
}

PHASE1_COMMANDS='/gamerule randomTickSpeed 0;/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/tp 14 68 -18|/lab start;/lab pause;/lab movement off;/lab follow off;/lab overlay off;/lab persistence-reconciliation setup;/lab observer-proof setup;/lab checkpoint save gate-c-restart|/lab observer open;/lab observer select agent_2;/lab observer status;/lab observer-proof status;/tp 18 71 -14 135 24|/lab observer reason;/lab observer status;/lab observer global;/lab observer filter agent agent_2;/lab observer page 1;/lab observer status;/lab observer individual|/setblock 9 69 -18 air;/tp 14 68 -18'
PHASE2_COMMANDS='/lab start;/lab pause;/lab movement off;/lab follow off;/lab overlay off;/lab checkpoint load gate-c-restart;/lab persistence-reconciliation status;/lab observer open;/lab observer select agent_1;/lab observer status;/lab observer-proof status;/tp 18 71 -14 135 24|/lab observer event 11;/lab observer status;/lab observer individual|/lab resume|/lab pause;/lab observer status;/lab observer global;/lab observer filter asset asset:civ27:live-pickaxe;/lab observer status;/lab observer individual;/lab observer close|/lab checkpoint delete gate-c-restart;/lab clear'

printf '\nGate C phase 1: real rights, rendered Observer, checkpoint, then honest physical loss.\n'
run_app "$PHASE1_TRACE" "$PHASE1_COMMANDS" \
    "-|-|$BEFORE_CAPTURE|-|-" 1

require_trace "$PHASE1_TRACE" \
    'persistence reconciliation setup .*container=9,69,-18 asset=asset:civ27:live-pickaxe holder=container:9,69,-18 custodian=agent_1 owner=agent_0 claimants=agent_0 authorized=agent_1 activity=active agents=3 physicalItems=1 .*schema=20 worldMutation=realContainer' \
    'real container, physical item, rights, activity, and three identities'
require_trace "$PHASE1_TRACE" \
    'observer proof setup actor=agent_2 asset=asset:civ27:live-pickaxe verdict=denied reason=requesterNotPhysicalHolder physicalAttempt=none .*event=10 mutation=causalFixtureOnly' \
    'authoritative denied use with no invented physical result'
require_trace "$PHASE1_TRACE" \
    'observer status open=1 view=individual selected=agent_2 schema=1 world=.* tick=0 sequence=10 .*reason=refused:useRefused reasonEvent=10 holder=container:9,69,-18 custodian=agent_1 owner=agent_0 claims=agent_0 users=agent_1 .*mutation=none tickStable=1 causalStable=1 digestStable=1' \
    'read-only pre-restart Observer with physical/social divergence and cause'
require_trace "$PHASE1_TRACE" \
    'observer proof status .*boundedAgents=2 agentsOmitted=1 eventsOmitted=[1-9][0-9]* truncationVisible=1 mutation=none digestStable=1' \
    'bounded pre-restart Observer'
require_trace "$PHASE1_TRACE" \
    'observer status open=1 view=event:10 selected=agent_2 .*mutation=none tickStable=1 causalStable=1 digestStable=1' \
    'pre-restart reason-to-event navigation'
require_trace "$PHASE1_TRACE" \
    'checkpoint saved name=gate-c-restart .*tick=0 .*causalSequence=10 restartSafe=1 .*physicalReferences=1 .*world=.* mutation=none' \
    'schema 20 checkpoint at the observed causal boundary'
require_trace "$PHASE1_TRACE" \
    'summary .*agents=3 .*runtimeErrors=0 .*probesRemoved=3 ' \
    'first process terminated with transient probes removed'
reject_trace "$PHASE1_TRACE" \
    'runtimeErrors=[1-9]|rollback failed|cleanup .*failed|Observer violated' \
    'first-process runtime, rollback, cleanup, or read-only error'
[ -s "$BEFORE_CAPTURE" ] || fail "pre-restart Gate C capture missing"

DB_PATH="$SESSION_HOME/Library/Application Support/Pebble/pebble.db"
[ -s "$DB_PATH" ] || fail "real World database missing after first process"
PERSISTENCE_ROOT="$SESSION_HOME/Library/Application Support/Pebble/PebbleLabAgents"
MANIFEST=$(/usr/bin/find "$PERSISTENCE_ROOT" -type f \
    -path '*/checkpoints/gate-c-restart/manifest.json' -print -quit)
[ -n "$MANIFEST" ] || fail "Gate C checkpoint manifest missing"
/usr/bin/grep -q '"schemaVersion":20' "$MANIFEST" \
    || fail "Gate C checkpoint is not schema 20"
/usr/bin/grep -q '"reconciliationBinding"' "$MANIFEST" \
    || fail "Gate C checkpoint has no reconciliation binding"

PHASE1_SIM=$(/usr/bin/sed -n \
    's/.*checkpoint saved name=gate-c-restart .* simulation=\([^ ]*\) digest=.*/\1/p' \
    "$PHASE1_TRACE" | /usr/bin/tail -1)
PHASE1_DIGEST=$(/usr/bin/sed -n \
    's/.*checkpoint saved name=gate-c-restart .* digest=\([0-9a-f]*\) storageDigest=.*/\1/p' \
    "$PHASE1_TRACE" | /usr/bin/tail -1)
PHASE1_WORLD=$(/usr/bin/sed -n \
    's/.*observer status open=1 view=individual selected=agent_2 schema=1 world=\([^ ]*\) storage=.*/\1/p' \
    "$PHASE1_TRACE" | /usr/bin/tail -1)
[ -n "$PHASE1_SIM" ] && [ -n "$PHASE1_DIGEST" ] \
    && [ -n "$PHASE1_WORLD" ] \
    || fail "pre-restart Gate C identities could not be extracted"

printf '\nGate C phase 2: new process, real World restore, missing-asset reconciliation, continuation, cleanup.\n'
run_app "$PHASE2_TRACE" "$PHASE2_COMMANDS" \
    "$AFTER_CAPTURE|-|-|-|-" 0

require_trace "$PHASE2_TRACE" \
    "persistence reconciliation run=restore:.* world=$PHASE1_WORLD assets=1 activities=1 outcomes=missing duplicates=0 causal=10>13" \
    'real reconciliation performed work on the physically missing asset'
require_trace "$PHASE2_TRACE" \
    "checkpoint loaded name=gate-c-restart .*simulation=$PHASE1_SIM digest=$PHASE1_DIGEST .*causalSequence=13 .*restartSafe=1 probes=3 paused=1 .*physicalReconciliation=applied:missing worldMutation=none" \
    'same checkpoint restored only after missing-asset reconciliation'
require_trace "$PHASE2_TRACE" \
    'persistence reconciliation status enabled=1 runs=1 outcome=missing asset=asset:civ27:live-pickaxe holder=container:9,69,-18 custodian=agent_1 owner=agent_0 claims=1 permissions=1 activity=0 agents=3 duplicates=0 tick=0 causalSequence=13' \
    'social rights retained without recreating the physical asset'
require_trace "$PHASE2_TRACE" \
    "observer status open=1 view=individual selected=agent_1 schema=1 world=$PHASE1_WORLD .*simulation=$PHASE1_SIM tick=0 sequence=13 .*activity=none reason=replanning:boundedReplan reasonEvent=none holder=container:9,69,-18 custodian=agent_1 owner=agent_0 claims=agent_0 users=agent_1 .*mutation=none tickStable=1 causalStable=1 digestStable=1" \
    'post-restart Observer explains replanning and preserves rights'
require_trace "$PHASE2_TRACE" \
    'observer status open=1 view=event:11 selected=agent_1 .*mutation=none tickStable=1 causalStable=1 digestStable=1' \
    'missing-asset reconciliation event is inspectable'
require_trace "$PHASE2_TRACE" \
    'resume tick=0' \
    'simulation resumed after reconciliation'
require_trace "$PHASE2_TRACE" \
    'observer status open=1 view=individual selected=agent_1 .*tick=8 sequence=[8-9][0-9] .*reason=(acting:goalAction|waiting:waitingForCondition) reasonEvent=[1-9][0-9]* .*mutation=none tickStable=1 causalStable=1 digestStable=1' \
    'newer ordinary action replaces the restart replan after continuation'
require_trace "$PHASE2_TRACE" \
    'observer closed mutation=none tickStable=1 causalStable=1 digestStable=1' \
    'post-restart Observer navigation remained read-only'
require_trace "$PHASE2_TRACE" \
    'checkpoint deleted name=gate-c-restart' \
    'Gate C checkpoint removed'
require_trace "$PHASE2_TRACE" \
    'summary reason=clear .*agents=3 .*runtimeErrors=0 .*probesRemoved=3 ' \
    'second process cleared the session and removed probes'
reject_trace "$PHASE2_TRACE" \
    'runtimeErrors=[1-9]|duplicates=[1-9]|rollback failed|cleanup .*failed|Observer violated' \
    'second-process runtime, duplication, rollback, cleanup, or read-only error'
[ -s "$AFTER_CAPTURE" ] || fail "post-restart Gate C capture missing"

WORLD_COUNT=$(/usr/bin/sqlite3 "$DB_PATH" 'SELECT count(*) FROM worlds;')
[ "$WORLD_COUNT" = "1" ] || fail "unexpected persisted World count: $WORLD_COUNT"
if /usr/bin/find "$PERSISTENCE_ROOT" -type f \
    -path '*/checkpoints/gate-c-restart/*' -print -quit \
    | /usr/bin/grep -q .; then
    fail "Gate C checkpoint files remained after deletion"
fi
if /usr/bin/pgrep -x Pebble >/dev/null 2>&1 \
    || /usr/bin/pgrep -x swift-run >/dev/null 2>&1 \
    || /usr/bin/pgrep -x pebsmoke >/dev/null 2>&1; then
    fail "residual PebbleLab process after Gate C proof"
fi

{
    printf 'contract=V4-GATE-C-v1\n'
    printf 'world=%s\n' "$WORLD_NAME"
    printf 'seed=%s\n' "$WORLD_SEED"
    printf 'worldBinding=%s\n' "$PHASE1_WORLD"
    printf 'simulation=%s\n' "$PHASE1_SIM"
    printf 'checkpointDigest=%s\n' "$PHASE1_DIGEST"
    printf 'agents=agent_0,agent_1,agent_2\n'
    printf 'asset=asset:civ27:live-pickaxe\n'
    printf 'savedHolder=container:9,69,-18\n'
    printf 'restoredPhysicalAsset=missing\n'
    printf 'custodian=agent_1\n'
    printf 'recognizedOwner=agent_0\n'
    printf 'claimants=agent_0\n'
    printf 'authorizedUsers=agent_1\n'
    printf 'beforeActivity=none\n'
    printf 'beforeReason=refused:useRefused\n'
    printf 'beforeReasonEvent=10\n'
    printf 'beforeTick=0\n'
    printf 'beforeSequence=10\n'
    printf 'reconciliationOutcome=missing\n'
    printf 'reconciliationEvent=11\n'
    printf 'interruptedActivityPolicy=replan\n'
    printf 'afterRestartTick=0\n'
    printf 'afterRestartSequence=13\n'
    printf 'afterContinuationTick=8\n'
    /usr/bin/sed -n \
        's/.*observer status open=1 view=individual selected=agent_1 .*tick=8 sequence=\([0-9]*\) .*activity=\([^ ]*\) reason=\([^ ]*\) reasonEvent=\([^ ]*\).*/afterContinuationSequence=\1\
afterContinuationActivity=\2\
afterContinuationReason=\3\
afterContinuationReasonEvent=\4/p' \
        "$PHASE2_TRACE" | /usr/bin/tail -4
    printf 'observerMutationCount=0\n'
    printf 'duplicationCount=0\n'
    printf 'runtimeErrors=0\n'
    printf 'firstProcessTerminated=1\n'
    printf 'secondProcessTerminated=1\n'
    printf 'checkpointRemoved=1\n'
    printf 'probesRemoved=3\n'
    printf 'worldFixtureRemoval=physicalCommand\n'
    printf 'sessionHomeRemoved=1\n'
    printf 'cleanup=exact\n'
} > "$EVIDENCE_ROOT/gate-c-trace.txt"

/bin/rm -rf "$SESSION_HOME"
[ ! -e "$SESSION_HOME" ] || fail "disposable Gate C World was not removed"

printf '\nPASS: Gate C focused adversarial matrix and integrated rendered two-process missing-asset reconciliation succeeded.\n'
printf 'Evidence: %s\n' "$EVIDENCE_ROOT"
printf 'Before capture: %s\n' "$BEFORE_CAPTURE"
printf 'After capture: %s\n' "$AFTER_CAPTURE"
printf 'Compact trace: %s\n' "$EVIDENCE_ROOT/gate-c-trace.txt"
