#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
WORLD_NAME="PebbleLab-Disposable-CIV29-46"
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
    printf 'CIV-29 rendered homeostasis proof (dry run)\n'
    printf '  World: %s seed=%s\n' "$WORLD_NAME" "$WORLD_SEED"
    printf '  Process 1: real food for two agents, deprivation/incapacity for one, v21 save, Observer capture.\n'
    printf '  Process 2: restore/reconcile, causal death, no resurrection, Observer capture, exact cleanup.\n'
    printf '  Product tests are not run by this script.\n'
    exit 0
fi
[ "$#" -eq 0 ] || fail "usage: scripts/verify-pebblelab-civ29.sh [--dry-run]"

git -C "$ROOT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    || fail "repository metadata missing"
[ "$(git -C "$ROOT_DIR" rev-parse --show-toplevel)" = "$ROOT_DIR" ] \
    || fail "unexpected repository root"

if [ -n "${PEBBLELAB_CIV29_EVIDENCE_DIR:-}" ]; then
    EVIDENCE_ROOT=$PEBBLELAB_CIV29_EVIDENCE_DIR
    [ ! -e "$EVIDENCE_ROOT" ] \
        || fail "evidence directory already exists: $EVIDENCE_ROOT"
    /bin/mkdir -p "$EVIDENCE_ROOT"
else
    EVIDENCE_ROOT=$(/usr/bin/mktemp -d /tmp/PebbleLab-CIV29.XXXXXX)
fi
SESSION_HOME="$EVIDENCE_ROOT/home"
/bin/mkdir -p "$SESSION_HOME"
PHASE1_TRACE="$EVIDENCE_ROOT/civ29-before-restart.log"
PHASE2_TRACE="$EVIDENCE_ROOT/civ29-after-restart.log"
BEFORE_CAPTURE="$EVIDENCE_ROOT/civ29-incapacitated-before-restart.png"
RESTORED_CAPTURE="$EVIDENCE_ROOT/civ29-restored-progression-after-restart.png"
FINAL_CAPTURE="$EVIDENCE_ROOT/civ29-mortality-final.png"

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
        PEBBLELAB_APP_AGENTS_POPULATION=1 \
        PEBBLELAB_APP_AGENTS_MORTALITY=1 \
        PEBBLELAB_APP_AGENTS_LIFECYCLE=1 \
        PEBBLELAB_APP_AGENTS_HOMEOSTASIS=1 \
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
        PEBBLELAB_APP_AGENTS_POPULATION=1 \
        PEBBLELAB_APP_AGENTS_MORTALITY=1 \
        PEBBLELAB_APP_AGENTS_LIFECYCLE=1 \
        PEBBLELAB_APP_AGENTS_HOMEOSTASIS=1 \
        PEBBLELAB_DISPOSABLE_WORLD_PROOF=1 \
        PEBBLE_CMD="$commands" \
        PEBBLE_SHOT="$shots" \
        "$PEBBLE_BINARY" 2>&1 | /usr/bin/tee "$run_trace"
    fi
    if /usr/bin/pgrep -x Pebble >/dev/null 2>&1; then
        fail "Pebble process remained after phase: $run_trace"
    fi
}

PHASE1_COMMANDS='/gamerule randomTickSpeed 0;/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/tp 14 68 -18|/lab start;/lab pause;/lab movement off;/lab follow off;/lab overlay off;/lab persistence-reconciliation setup;/lab survival on;/lab population on;/lab mortality on;/lab lifecycle on;/lab physical-food-survival on;/lab homeostasis on;/lab homeostasis proof setup;/lab homeostasis proof advance 22;/lab homeostasis status;/lab checkpoint save civ29-restart|/lab observer open;/lab observer select agent_2;/lab observer status;/tp 18 71 -14 135 24|/lab homeostasis status;/lab observer status;/tp 14 68 -18'
PHASE2_COMMANDS='/lab start;/lab pause;/lab movement off;/lab follow off;/lab overlay off;/lab checkpoint load civ29-restart;/lab persistence-reconciliation status;/lab homeostasis status;/lab observer open;/lab observer select agent_2;/lab observer status|/lab homeostasis proof advance 1;/lab homeostasis status;/lab observer global;/lab observer status;/tp 18 71 -14 135 24|/lab homeostasis proof advance 2;/lab homeostasis status;/lab homeostasis proof cleanup;/lab observer close;/lab persistence-reconciliation cleanup;/lab checkpoint delete civ29-restart;/lab status'

printf '\nCIV-29 phase 1: real food/recovery versus deprivation and rendered incapacity.\n'
run_app "$PHASE1_TRACE" "$PHASE1_COMMANDS" "-|-|$BEFORE_CAPTURE|-" 1

require_trace "$PHASE1_TRACE" \
    'homeostasis proof setup .*physicalItem=iron_pickaxe:1 .*owner=agent_0 terminalClaim=agent_2 claims=agent_0,agent_2 .*foodAuthority=physicalItems worldMutation=none' \
    'real asset and terminal social claim before physiological progression'
require_trace "$PHASE1_TRACE" \
    'homeostasis proof advance ticks=22 tick=0>22 foodProvisioned=[1-9][0-9]* foodConsumed=[1-9][0-9]* fedAgents=agent_0,agent_1 deprivedAgent=agent_2 vital=incapacitated condition=incapacitated health=[1-9][0-9]* age=[0-9]+ stage=mature deaths=0>0 claimPreserved=1 activeAgents=3 probes=3 runtimeErrors=0' \
    'real food/recovery and causal deprivation through incapacity'
require_trace "$PHASE1_TRACE" \
    'observer status open=1 view=individual selected=agent_2 schema=2 .*reason=blocked:physiologicalIncapacity .*vital=incapacitated .*healthCondition=incapacitated .*deaths=0 .*mutation=none tickStable=1 causalStable=1 digestStable=1' \
    'rendered authoritative incapacity and read-only Observer'
require_trace "$PHASE1_TRACE" \
    'checkpoint saved name=civ29-restart .*tick=22 .*restartSafe=1 .*physicalReferences=1 .*mutation=none' \
    'restart-safe schema 21 checkpoint boundary'
require_trace "$PHASE1_TRACE" \
    'summary .*agents=3 .*runtimeErrors=0 .*probesRemoved=3 ' \
    'first process terminated and removed transient probes'
[ -s "$BEFORE_CAPTURE" ] || fail "pre-restart incapacity capture missing"

DB_PATH="$SESSION_HOME/Library/Application Support/Pebble/pebble.db"
[ -s "$DB_PATH" ] || fail "real World database missing after first process"
PERSISTENCE_ROOT="$SESSION_HOME/Library/Application Support/Pebble/PebbleLabAgents"
MANIFEST=$(/usr/bin/find "$PERSISTENCE_ROOT" -type f \
    -path '*/checkpoints/civ29-restart/manifest.json' -print -quit)
[ -n "$MANIFEST" ] || fail "schema 21 checkpoint manifest missing"
/usr/bin/grep -q '"schemaVersion":21' "$MANIFEST" \
    || fail "checkpoint manifest is not schema 21"

PHASE1_SIM=$(/usr/bin/sed -n \
    's/.*checkpoint saved name=civ29-restart .* simulation=\([^ ]*\) digest=.*/\1/p' \
    "$PHASE1_TRACE" | /usr/bin/tail -1)
PHASE1_DIGEST=$(/usr/bin/sed -n \
    's/.*checkpoint saved name=civ29-restart .* digest=\([0-9a-f]*\) storageDigest=.*/\1/p' \
    "$PHASE1_TRACE" | /usr/bin/tail -1)
[ -n "$PHASE1_SIM" ] && [ -n "$PHASE1_DIGEST" ] \
    || fail "checkpoint identity extraction failed"

printf '\nCIV-29 phase 2: new process, exact physiological restore, causal death, cleanup.\n'
run_app "$PHASE2_TRACE" "$PHASE2_COMMANDS" \
    "$RESTORED_CAPTURE|$FINAL_CAPTURE|-" 0

require_trace "$PHASE2_TRACE" \
    "checkpoint loaded name=civ29-restart .*tick=22 simulation=$PHASE1_SIM digest=$PHASE1_DIGEST .*restartSafe=1 probes=3 paused=1 .*physicalReconciliation=applied:matched worldMutation=none" \
    'same schema 21 state restored and physically reconciled in a new process'
require_trace "$PHASE2_TRACE" \
    'homeostasis status enabled=1 schema=21 tick=22 .*agent_2:incapacitated:incapacitated:.*terminalClaim=1 probes=3 .*runtimeErrors=0 worldMutation=none' \
    'age, stage, health trajectory, and claim preserved exactly after restart'
require_trace "$PHASE2_TRACE" \
    'homeostasis proof advance ticks=1 tick=22>23 .*deprivedAgent=agent_2 vital=dead condition=dead health=0 .*stage=mature deaths=0>1 claimPreserved=1 activeAgents=2 probes=2 runtimeErrors=0' \
    'single causal death and exact physical embodiment removal'
require_trace "$PHASE2_TRACE" \
    'mortality exit tick=23 .*agent=agent_2 cause=compoundedHomeostaticFailure .*population=3>2 .*probes=3>2 .*corpse=none worldMutation=none' \
    'Pebble mortality boundary removed only the terminal embodiment'
require_trace "$PHASE2_TRACE" \
    'observer status open=1 view=global .*schema=2 .*deaths=1 .*mutation=none tickStable=1 causalStable=1 digestStable=1' \
    'rendered causal mortality Chronicle after restart'
require_trace "$PHASE2_TRACE" \
    'homeostasis proof advance ticks=2 tick=23>25 .*deaths=1>1 claimPreserved=1 activeAgents=2 probes=2 runtimeErrors=0' \
    'no resurrection, duplicate death, post-death aging, or action'
require_trace "$PHASE2_TRACE" \
    'homeostasis proof cleanup claimRemoved=1 foodCustody=empty physicalAsset=preserved worldMutation=none' \
    'proof-only claim and real food custody cleanup'
require_trace "$PHASE2_TRACE" \
    'persistence reconciliation cleanup world=exact assetRemoved=1 state=cleared probes=2 duplicates=0' \
    'exact physical asset and reconciliation cleanup'
require_trace "$PHASE2_TRACE" \
    'checkpoint deleted name=civ29-restart' \
    'checkpoint proof artifact cleanup'
require_trace "$PHASE2_TRACE" \
    'summary .*agents=2 .*runtimeErrors=0 .*probesRemoved=2 ' \
    'second process stopped with no runtime error or orphan probe'
reject_trace "$PHASE1_TRACE" \
    'runtimeErrors=[1-9]|rollback failed|cleanup .*failed|Observer violated' \
    'first-process runtime, rollback, cleanup, or read-only error'
reject_trace "$PHASE2_TRACE" \
    'runtimeErrors=[1-9]|duplicates=[1-9]|rollback failed|cleanup .*failed|Observer violated' \
    'second-process runtime, duplication, rollback, cleanup, or read-only error'
[ -s "$RESTORED_CAPTURE" ] \
    || fail "post-restart progression capture missing"
[ -s "$FINAL_CAPTURE" ] || fail "final mortality capture missing"

if /usr/bin/pgrep -x Pebble >/dev/null 2>&1 \
    || /usr/bin/pgrep -x swift-run >/dev/null 2>&1 \
    || /usr/bin/pgrep -x pebsmoke >/dev/null 2>&1; then
    fail "residual PebbleLab process after CIV-29 proof"
fi

{
    printf 'world=%s\n' "$WORLD_NAME"
    printf 'seed=%s\n' "$WORLD_SEED"
    printf 'checkpointSimulation=%s\n' "$PHASE1_SIM"
    printf 'checkpointDigest=%s\n' "$PHASE1_DIGEST"
    /usr/bin/grep -E \
        '^\[lab-live\] (homeostasis proof setup|homeostasis proof advance|homeostasis status|observer status|checkpoint saved name=civ29-restart|checkpoint loaded name=civ29-restart|mortality exit|homeostasis proof cleanup|persistence reconciliation cleanup)' \
        "$PHASE1_TRACE" "$PHASE2_TRACE"
    printf 'deathCount=1\n'
    printf 'resurrectionCount=0\n'
    printf 'runtimeErrors=0\n'
    printf 'cleanup=exact\n'
} > "$EVIDENCE_ROOT/civ29-homeostasis-trace.txt"

printf '\nPASS: real food/recovery, deprivation, incapacity, schema 21 process restart, causal mortality, read-only Observer, no resurrection, and exact cleanup verified.\n'
printf 'Evidence: %s\n' "$EVIDENCE_ROOT"
printf 'Before capture: %s\n' "$BEFORE_CAPTURE"
printf 'Restored progression capture: %s\n' "$RESTORED_CAPTURE"
printf 'Final mortality capture: %s\n' "$FINAL_CAPTURE"
printf 'Phase 1 trace: %s\n' "$PHASE1_TRACE"
printf 'Phase 2 trace: %s\n' "$PHASE2_TRACE"
