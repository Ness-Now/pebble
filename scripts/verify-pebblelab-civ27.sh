#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
WORLD_NAME="PebbleLab-Disposable-CIV27-46"
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
    printf 'CIV-27 live proof (dry run)\n'
    printf '  World: %s seed=%s\n' "$WORLD_NAME" "$WORLD_SEED"
    printf '  Process 1: create World, real container/item, rights, activity, v20 checkpoint, capture.\n'
    printf '  Process 2: load World, create fresh probes, restore/reconcile, continue, capture, exact cleanup.\n'
    printf '  Product tests are not run by this script.\n'
    exit 0
fi
[ "$#" -eq 0 ] || fail "usage: scripts/verify-pebblelab-civ27.sh [--dry-run]"

git -C "$ROOT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    || fail "repository metadata missing"
[ "$(git -C "$ROOT_DIR" rev-parse --show-toplevel)" = "$ROOT_DIR" ] \
    || fail "unexpected repository root"

if [ -n "${PEBBLELAB_CIV27_EVIDENCE_DIR:-}" ]; then
    EVIDENCE_ROOT=$PEBBLELAB_CIV27_EVIDENCE_DIR
    [ ! -e "$EVIDENCE_ROOT" ] || fail "evidence directory already exists: $EVIDENCE_ROOT"
    /bin/mkdir -p "$EVIDENCE_ROOT"
else
    EVIDENCE_ROOT=$(/usr/bin/mktemp -d /tmp/PebbleLab-CIV27.XXXXXX)
fi
SESSION_HOME="$EVIDENCE_ROOT/home"
/bin/mkdir -p "$SESSION_HOME"
PHASE1_TRACE="$EVIDENCE_ROOT/civ27-before-restart.log"
PHASE2_TRACE="$EVIDENCE_ROOT/civ27-after-restart.log"
BEFORE_CAPTURE="$EVIDENCE_ROOT/civ27-before-restart.png"
AFTER_CAPTURE="$EVIDENCE_ROOT/civ27-after-restart.png"

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
        PEBBLELAB_APP_AGENTS_OVERLAY=1 \
        PEBBLELAB_APP_AGENTS_TRACE=1 \
        PEBBLELAB_APP_AGENTS_TRACE_EVERY=1 \
        PEBBLELAB_APP_AGENTS_MATERIAL=1 \
        PEBBLELAB_APP_AGENTS_PERSISTENCE=1 \
        PEBBLELAB_APP_AGENTS_RECONCILIATION=1 \
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
        PEBBLELAB_APP_AGENTS_OVERLAY=1 \
        PEBBLELAB_APP_AGENTS_TRACE=1 \
        PEBBLELAB_APP_AGENTS_TRACE_EVERY=1 \
        PEBBLELAB_APP_AGENTS_MATERIAL=1 \
        PEBBLELAB_APP_AGENTS_PERSISTENCE=1 \
        PEBBLELAB_APP_AGENTS_RECONCILIATION=1 \
        PEBBLELAB_DISPOSABLE_WORLD_PROOF=1 \
        PEBBLE_CMD="$commands" \
        PEBBLE_SHOT="$shots" \
        "$PEBBLE_BINARY" 2>&1 | /usr/bin/tee "$run_trace"
    fi
    if /usr/bin/pgrep -x Pebble >/dev/null 2>&1; then
        fail "Pebble process remained after phase: $run_trace"
    fi
}

PHASE1_COMMANDS='/gamerule randomTickSpeed 0;/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/tp 14 68 -18|/lab start;/lab pause;/lab movement off;/lab follow off;/lab persistence-reconciliation setup;/lab checkpoint save civ27-restart;/lab persistence-reconciliation status;/tp 18 71 -14 135 24;/lab overlay full|/lab persistence-reconciliation status|/tp 14 68 -18'
PHASE2_COMMANDS='/lab start;/lab pause;/lab movement off;/lab follow off;/lab checkpoint load civ27-restart;/lab persistence-reconciliation status;/lab resume|/lab pause;/lab persistence-reconciliation status;/tp 18 71 -14 135 24;/lab overlay full|/lab persistence-reconciliation cleanup;/lab checkpoint delete civ27-restart;/lab status'

printf '\nCIV-27 phase 1: real World/save boundary and pre-restart capture.\n'
run_app "$PHASE1_TRACE" "$PHASE1_COMMANDS" "-|-|$BEFORE_CAPTURE|-" 1

require_trace "$PHASE1_TRACE" \
    'persistence reconciliation setup .*asset=asset:civ27:live-pickaxe .*holder=container:.*custodian=agent_1 owner=agent_0 .*authorized=agent_1 .*activity=active agents=3 physicalItems=1 .*schema=20' \
    'real container, item, rights, activity, and three identities before restart'
require_trace "$PHASE1_TRACE" \
    'checkpoint saved name=civ27-restart .*restartSafe=1 .*physicalReferences=1 .*mutation=none' \
    'restart-safe v20 checkpoint with one physical reference'
require_trace "$PHASE1_TRACE" \
    'persistence reconciliation status enabled=1 runs=0 outcome=pending .*holder=container:.*custodian=agent_1 owner=agent_0 claims=1 permissions=1 activity=1 agents=3 duplicates=0 tick=0' \
    'pre-restart civilization projection'
require_trace "$PHASE1_TRACE" \
    'summary .*agents=3 .*runtimeErrors=0 .*probesRemoved=3 ' \
    'first process stopped and removed transient probes'
[ -s "$BEFORE_CAPTURE" ] || fail "pre-restart capture missing"

DB_PATH="$SESSION_HOME/Library/Application Support/Pebble/pebble.db"
[ -s "$DB_PATH" ] || fail "real World database missing after first process"
PERSISTENCE_ROOT="$SESSION_HOME/Library/Application Support/Pebble/PebbleLabAgents"
MANIFEST=$(/usr/bin/find "$PERSISTENCE_ROOT" -type f \
    -path '*/checkpoints/civ27-restart/manifest.json' -print -quit)
[ -n "$MANIFEST" ] || fail "v20 checkpoint manifest missing"
/usr/bin/grep -q '"schemaVersion":20' "$MANIFEST" \
    || fail "checkpoint manifest is not schema v20"
/usr/bin/grep -q '"reconciliationBinding"' "$MANIFEST" \
    || fail "checkpoint manifest has no physical reconciliation binding"

PHASE1_SIM=$(/usr/bin/sed -n \
    's/.*checkpoint saved name=civ27-restart .* simulation=\([^ ]*\) digest=.*/\1/p' \
    "$PHASE1_TRACE" | /usr/bin/tail -1)
PHASE1_DIGEST=$(/usr/bin/sed -n \
    's/.*checkpoint saved name=civ27-restart .* digest=\([0-9a-f]*\) storageDigest=.*/\1/p' \
    "$PHASE1_TRACE" | /usr/bin/tail -1)
[ -n "$PHASE1_SIM" ] && [ -n "$PHASE1_DIGEST" ] \
    || fail "checkpoint identity extraction failed"

printf '\nCIV-27 phase 2: new process, restored World, reconciliation, continuation, cleanup.\n'
run_app "$PHASE2_TRACE" "$PHASE2_COMMANDS" "-|$AFTER_CAPTURE|-" 0

require_trace "$PHASE2_TRACE" \
    "checkpoint loaded name=civ27-restart .*simulation=$PHASE1_SIM digest=$PHASE1_DIGEST .*restartSafe=1 probes=3 paused=1 .*physicalReconciliation=applied:matched worldMutation=none" \
    'same checkpoint restored and matched against the newly loaded World'
require_trace "$PHASE2_TRACE" \
    'persistence reconciliation run=.*assets=1 activities=1 outcomes=matched duplicates=0 causal=[0-9]+>[0-9]+' \
    'bounded asset and interrupted-activity reconciliation'
require_trace "$PHASE2_TRACE" \
    'persistence reconciliation status enabled=1 runs=1 outcome=matched .*asset=asset:civ27:live-pickaxe .*holder=container:.*custodian=agent_1 owner=agent_0 claims=1 permissions=1 activity=1 agents=3 duplicates=0' \
    'same rights and identities after restart'
require_trace "$PHASE2_TRACE" \
    'persistence reconciliation cleanup world=exact assetRemoved=1 state=cleared probes=3 duplicates=0' \
    'exact World and civilization cleanup'
require_trace "$PHASE2_TRACE" \
    'checkpoint deleted name=civ27-restart' \
    'checkpoint proof artifact cleanup'
require_trace "$PHASE2_TRACE" \
    'summary .*agents=3 .*runtimeErrors=0 .*probesRemoved=3 ' \
    'second process stopped with no runtime error or probe orphan'
reject_trace "$PHASE2_TRACE" \
    'runtimeErrors=[1-9]|duplicates=[1-9]|rollback failed|cleanup .*failed' \
    'runtime error, duplication, rollback failure, or cleanup failure'
[ -s "$AFTER_CAPTURE" ] || fail "post-restart capture missing"

WORLD_COUNT=$(/usr/bin/sqlite3 "$DB_PATH" 'SELECT count(*) FROM worlds;')
[ "$WORLD_COUNT" = "1" ] || fail "unexpected persisted World count: $WORLD_COUNT"
if /usr/bin/pgrep -x Pebble >/dev/null 2>&1 \
    || /usr/bin/pgrep -x swift-run >/dev/null 2>&1 \
    || /usr/bin/pgrep -x pebsmoke >/dev/null 2>&1; then
    fail "residual PebbleLab process after CIV-27 proof"
fi

{
    printf 'world=%s\n' "$WORLD_NAME"
    printf 'seed=%s\n' "$WORLD_SEED"
    printf 'checkpointSimulation=%s\n' "$PHASE1_SIM"
    printf 'checkpointDigest=%s\n' "$PHASE1_DIGEST"
    /usr/bin/grep -E \
        '^\[lab-live\] (persistence reconciliation setup|checkpoint saved name=civ27-restart|persistence reconciliation run=|checkpoint loaded name=civ27-restart|persistence reconciliation status|persistence reconciliation cleanup)' \
        "$PHASE1_TRACE" "$PHASE2_TRACE"
    printf 'duplicationCount=0\n'
    printf 'cleanup=exact\n'
} > "$EVIDENCE_ROOT/civ27-reconciliation-trace.txt"

printf '\nPASS: real World save, process stop, World restore, civilization restore, bounded reconciliation, continuation, visual captures, and exact cleanup verified.\n'
printf 'Evidence: %s\n' "$EVIDENCE_ROOT"
printf 'Before capture: %s\n' "$BEFORE_CAPTURE"
printf 'After capture: %s\n' "$AFTER_CAPTURE"
printf 'Phase 1 trace: %s\n' "$PHASE1_TRACE"
printf 'Phase 2 trace: %s\n' "$PHASE2_TRACE"
