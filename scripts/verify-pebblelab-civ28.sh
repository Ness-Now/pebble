#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
WORLD_NAME="PebbleLab-Disposable-CIV28-46"
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
    printf 'CIV-28 rendered Observer proof (dry run)\n'
    printf '  World: %s seed=%s\n' "$WORLD_NAME" "$WORLD_SEED"
    printf '  Process 1: create World, rights/activity/refusal, open read-only Observer, save v20, capture.\n'
    printf '  Process 2: restore World/checkpoint, reconcile, continue, inspect Observer, capture, exact cleanup.\n'
    printf '  Product tests are not run by this script.\n'
    exit 0
fi
[ "$#" -eq 0 ] || fail "usage: scripts/verify-pebblelab-civ28.sh [--dry-run]"

git -C "$ROOT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    || fail "repository metadata missing"
[ "$(git -C "$ROOT_DIR" rev-parse --show-toplevel)" = "$ROOT_DIR" ] \
    || fail "unexpected repository root"

if [ -n "${PEBBLELAB_CIV28_EVIDENCE_DIR:-}" ]; then
    EVIDENCE_ROOT=$PEBBLELAB_CIV28_EVIDENCE_DIR
    [ ! -e "$EVIDENCE_ROOT" ] \
        || fail "evidence directory already exists: $EVIDENCE_ROOT"
    /bin/mkdir -p "$EVIDENCE_ROOT"
else
    EVIDENCE_ROOT=$(/usr/bin/mktemp -d /tmp/PebbleLab-CIV28.XXXXXX)
fi
SESSION_HOME="$EVIDENCE_ROOT/home"
/bin/mkdir -p "$SESSION_HOME"
PHASE1_TRACE="$EVIDENCE_ROOT/civ28-before-restart.log"
PHASE2_TRACE="$EVIDENCE_ROOT/civ28-after-restart.log"
BEFORE_CAPTURE="$EVIDENCE_ROOT/civ28-observer-before-restart.png"
AFTER_CAPTURE="$EVIDENCE_ROOT/civ28-observer-after-restart.png"

cd "$ROOT_DIR"
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

PHASE1_COMMANDS='/gamerule randomTickSpeed 0;/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/tp 14 68 -18|/lab start;/lab pause;/lab movement off;/lab follow off;/lab overlay off;/lab persistence-reconciliation setup;/lab observer-proof setup;/lab checkpoint save civ28-restart|/lab observer open;/lab observer select agent_2;/lab observer status;/lab observer-proof status;/tp 18 71 -14 135 24|/lab observer reason;/lab observer status;/lab observer global;/lab observer filter agent agent_2;/lab observer page 1;/lab observer status;/lab observer individual;/tp 14 68 -18'
PHASE2_COMMANDS='/lab start;/lab pause;/lab movement off;/lab follow off;/lab overlay off;/lab checkpoint load civ28-restart;/lab persistence-reconciliation status;/lab observer open;/lab observer select agent_1;/lab observer status;/lab observer-proof status|/lab observer reason;/lab observer status;/lab observer individual|/lab resume|/lab pause;/lab observer status;/tp 18 71 -14 135 24|/lab observer global;/lab observer filter asset asset:civ27:live-pickaxe;/lab observer status;/lab observer individual;/lab observer close;/lab persistence-reconciliation cleanup;/lab checkpoint delete civ28-restart;/lab status'

printf '\nCIV-28 phase 1: rendered refusal, rights divergence, and read-only Observer.\n'
run_app "$PHASE1_TRACE" "$PHASE1_COMMANDS" "-|-|$BEFORE_CAPTURE|-" 1

require_trace "$PHASE1_TRACE" \
    'observer proof setup actor=agent_2 asset=asset:civ27:live-pickaxe verdict=denied reason=requesterNotPhysicalHolder physicalAttempt=none .*event=[0-9]+' \
    'authoritative refused-use event with no invented physical attempt'
require_trace "$PHASE1_TRACE" \
    'observer status open=1 view=individual selected=agent_2 schema=1 world=.* simulation=.* tick=0 sequence=[0-9]+ .*reason=refused:useRefused reasonEvent=[0-9]+ holder=container:.*custodian=agent_1 owner=agent_0 claims=agent_0 users=agent_1 .*mutation=none tickStable=1 causalStable=1 digestStable=1' \
    'rendered individual projection with reason, custody, claim, permission, and exact read-only proof'
require_trace "$PHASE1_TRACE" \
    'observer proof status .*boundedAgents=2 agentsOmitted=1 eventsOmitted=[1-9][0-9]* truncationVisible=1 mutation=none digestStable=1' \
    'explicit bounded projection and visible truncation'
require_trace "$PHASE1_TRACE" \
    'observer status open=1 view=event:[0-9]+ selected=agent_2 .*mutation=none tickStable=1 causalStable=1 digestStable=1' \
    'reason-to-causal-event navigation'
require_trace "$PHASE1_TRACE" \
    'observer status open=1 view=global selected=agent_2 .*mutation=none tickStable=1 causalStable=1 digestStable=1' \
    'filtered/paginated global Chronicle navigation'
require_trace "$PHASE1_TRACE" \
    'checkpoint saved name=civ28-restart .*restartSafe=1 .*physicalReferences=1 .*mutation=none' \
    'schema 20 restart-safe checkpoint'
require_trace "$PHASE1_TRACE" \
    'summary .*agents=3 .*runtimeErrors=0 .*probesRemoved=3 ' \
    'first process stopped and removed transient probes'
[ -s "$BEFORE_CAPTURE" ] || fail "pre-restart Observer capture missing"

DB_PATH="$SESSION_HOME/Library/Application Support/Pebble/pebble.db"
[ -s "$DB_PATH" ] || fail "real World database missing after first process"
PERSISTENCE_ROOT="$SESSION_HOME/Library/Application Support/Pebble/PebbleLabAgents"
MANIFEST=$(/usr/bin/find "$PERSISTENCE_ROOT" -type f \
    -path '*/checkpoints/civ28-restart/manifest.json' -print -quit)
[ -n "$MANIFEST" ] || fail "v20 checkpoint manifest missing"
/usr/bin/grep -q '"schemaVersion":20' "$MANIFEST" \
    || fail "checkpoint manifest is not schema v20"

PHASE1_SIM=$(/usr/bin/sed -n \
    's/.*checkpoint saved name=civ28-restart .* simulation=\([^ ]*\) digest=.*/\1/p' \
    "$PHASE1_TRACE" | /usr/bin/tail -1)
PHASE1_DIGEST=$(/usr/bin/sed -n \
    's/.*checkpoint saved name=civ28-restart .* digest=\([0-9a-f]*\) storageDigest=.*/\1/p' \
    "$PHASE1_TRACE" | /usr/bin/tail -1)
PHASE1_WORLD=$(/usr/bin/sed -n \
    's/.*observer status open=1 view=individual selected=agent_2 schema=1 world=\([^ ]*\) storage=.*/\1/p' \
    "$PHASE1_TRACE" | /usr/bin/tail -1)
[ -n "$PHASE1_SIM" ] && [ -n "$PHASE1_DIGEST" ] && [ -n "$PHASE1_WORLD" ] \
    || fail "pre-restart identity extraction failed"

printf '\nCIV-28 phase 2: new process, reconciliation explanation, continuation, cleanup.\n'
run_app "$PHASE2_TRACE" "$PHASE2_COMMANDS" "$AFTER_CAPTURE|-|-|-|-" 0

require_trace "$PHASE2_TRACE" \
    "checkpoint loaded name=civ28-restart .*simulation=$PHASE1_SIM digest=$PHASE1_DIGEST .*restartSafe=1 probes=3 paused=1 .*physicalReconciliation=applied:matched worldMutation=none" \
    'same checkpoint restored and matched in a new process'
require_trace "$PHASE2_TRACE" \
    "observer status open=1 view=individual selected=agent_1 schema=1 world=$PHASE1_WORLD storage=.* simulation=$PHASE1_SIM .*reason=interruptedReconciled:persistenceReconciled reasonEvent=[0-9]+ holder=container:.*custodian=agent_1 owner=agent_0 claims=agent_0 users=agent_1 .*mutation=none tickStable=1 causalStable=1 digestStable=1" \
    'same identities, World binding, social rights, and reconciliation reason after restart'
require_trace "$PHASE2_TRACE" \
    'resume tick=[0-9]+' \
    'simulation resumed after restart'
require_trace "$PHASE2_TRACE" \
    'observer status open=1 view=event:[0-9]+ selected=agent_1 .*mutation=none tickStable=1 causalStable=1 digestStable=1' \
    'post-restart causal reconciliation event navigation'
require_trace "$PHASE2_TRACE" \
    'observer proof status .*truncationVisible=1 mutation=none digestStable=1' \
    'post-restart bounded Observer remains read-only'
require_trace "$PHASE2_TRACE" \
    'observer closed mutation=none tickStable=1 causalStable=1 digestStable=1' \
    'Observer closure remains read-only'
require_trace "$PHASE2_TRACE" \
    'persistence reconciliation cleanup world=exact assetRemoved=1 state=cleared probes=3 duplicates=0' \
    'exact World and civilization cleanup'
require_trace "$PHASE2_TRACE" \
    'checkpoint deleted name=civ28-restart' \
    'checkpoint proof artifact cleanup'
require_trace "$PHASE2_TRACE" \
    'summary .*agents=3 .*runtimeErrors=0 .*probesRemoved=3 ' \
    'second process stopped with no runtime error or probe orphan'
reject_trace "$PHASE1_TRACE" \
    'runtimeErrors=[1-9]|rollback failed|cleanup .*failed|Observer violated' \
    'first-process runtime, rollback, cleanup, or read-only error'
reject_trace "$PHASE2_TRACE" \
    'runtimeErrors=[1-9]|duplicates=[1-9]|rollback failed|cleanup .*failed|Observer violated' \
    'second-process runtime, duplication, rollback, cleanup, or read-only error'
[ -s "$AFTER_CAPTURE" ] || fail "post-restart Observer capture missing"

if /usr/bin/pgrep -x Pebble >/dev/null 2>&1 \
    || /usr/bin/pgrep -x swift-run >/dev/null 2>&1 \
    || /usr/bin/pgrep -x pebsmoke >/dev/null 2>&1; then
    fail "residual PebbleLab process after CIV-28 proof"
fi

{
    printf 'world=%s\n' "$WORLD_NAME"
    printf 'seed=%s\n' "$WORLD_SEED"
    printf 'worldBinding=%s\n' "$PHASE1_WORLD"
    printf 'checkpointSimulation=%s\n' "$PHASE1_SIM"
    printf 'checkpointDigest=%s\n' "$PHASE1_DIGEST"
    /usr/bin/grep -E \
        '^\[lab-live\] (observer proof setup|observer proof status|observer status|checkpoint saved name=civ28-restart|persistence reconciliation run=|checkpoint loaded name=civ28-restart|persistence reconciliation cleanup)' \
        "$PHASE1_TRACE" "$PHASE2_TRACE"
    printf 'observerMutationCount=0\n'
    printf 'runtimeErrors=0\n'
    printf 'duplicationCount=0\n'
    printf 'cleanup=exact\n'
} > "$EVIDENCE_ROOT/civ28-observer-trace.txt"

printf '\nPASS: rendered read-only Observer, structured reason, Chronicle, true restart continuity, continuation, and exact cleanup verified.\n'
printf 'Evidence: %s\n' "$EVIDENCE_ROOT"
printf 'Before capture: %s\n' "$BEFORE_CAPTURE"
printf 'After capture: %s\n' "$AFTER_CAPTURE"
printf 'Phase 1 trace: %s\n' "$PHASE1_TRACE"
printf 'Phase 2 trace: %s\n' "$PHASE2_TRACE"
