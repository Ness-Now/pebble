#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
WORLD_SEED=46
WORLD_NAME=PebbleLab-Disposable-Gate-E-Blocker-01-46
OPEN_CHECKPOINT=gate-e-blocker-01-open-v33

fail() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

require_trace() {
    trace=$1
    pattern=$2
    description=$3
    /usr/bin/grep -Eq "$pattern" "$trace" \
        || fail "live trace missing: $description"
}

reject_trace() {
    trace=$1
    pattern=$2
    description=$3
    if /usr/bin/grep -Eq "$pattern" "$trace"; then
        fail "live trace unexpectedly contains: $description"
    fi
}

require_trace_count() {
    trace=$1
    pattern=$2
    expected=$3
    description=$4
    actual=$(/usr/bin/grep -Ec "$pattern" "$trace" || true)
    [ "$actual" -eq "$expected" ] \
        || fail "live trace count $actual != $expected: $description"
}

PHASE1_COMMANDS='/gamerule randomTickSpeed 0;/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/tp 14 68 -18|/lab start;/tp 14 73 -22;/lab pause;/lab movement off;/lab contract setup;/lab contract provenance;/lab contract status;/lab overlay compact|/lab step;/lab contract status;/lab contract provenance;/lab overlay compact|/lab step;/lab contract status;/lab contract provenance;/lab checkpoint save gate-e-blocker-01-open-v33;/lab checkpoint status;/lab causality tail 20;/lab status'
PHASE2_COMMANDS='/tp 14 68 -18;/lab start;/tp 14 73 -22;/lab pause;/lab movement off;/lab checkpoint load gate-e-blocker-01-open-v33;/lab contract status;/lab contract provenance;/lab overlay compact|/lab contract displace fulfillment;/lab contract status;/lab contract provenance;/lab overlay compact|/lab step;/lab step;/lab contract status;/lab contract provenance;/lab overlay compact|/lab contract return fulfillment;/lab contract status;/lab contract provenance;/lab overlay compact|/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab contract status;/lab contract provenance;/lab contract proof;/lab checkpoint save gate-e-blocker-01-fulfilled-v33;/lab checkpoint status;/lab causality tail 20;/lab overlay compact|/lab step;/lab contract status;/lab contract provenance;/lab contract proof;/lab contract cleanup;/lab status'

if [ "${1:-}" = "--dry-run" ]; then
    printf 'Gate E Blocker 01 live proof dry run\n'
    printf 'Repository: %s\n' "$ROOT_DIR"
    printf 'World: %s seed=%s\n' "$WORLD_NAME" "$WORLD_SEED"
    printf 'Fresh processes: 2\n'
    printf 'PEBBLELAB_GATE_E_BLOCKER_01=1\n'
    printf 'Process 1 PEBBLE_CMD=%s\n' "$PHASE1_COMMANDS"
    printf 'Process 2 PEBBLE_CMD=%s\n' "$PHASE2_COMMANDS"
    printf 'No process was launched and no directory was created.\n'
    exit 0
fi
[ "$#" -eq 0 ] || fail "usage: $0 [--dry-run]"

if [ "${PEBBLE_REGOLD+x}" = x ]; then
    fail "PEBBLE_REGOLD must be absent, including an empty value"
fi
[ "$(git -C "$ROOT_DIR" rev-parse --show-toplevel)" = "$ROOT_DIR" ] \
    || fail "unexpected repository root"
if /usr/bin/pgrep -x Pebble >/dev/null 2>&1; then
    fail "a Pebble process is already running"
fi

SESSION_ROOT=$(/usr/bin/mktemp -d "/tmp/pebblelab-gate-e-blocker-01.XXXXXX")
case "$SESSION_ROOT" in
    /tmp/pebblelab-gate-e-blocker-01.*) ;;
    *) fail "unsafe session root: $SESSION_ROOT" ;;
esac
SESSION_HOME="$SESSION_ROOT/home"
CAPTURE_DIR="$SESSION_ROOT/captures"
PHASE1_TRACE="$SESSION_ROOT/blocker-01-process-1.log"
PHASE2_TRACE="$SESSION_ROOT/blocker-01-process-2.log"
DB_PATH="$SESSION_HOME/Library/Application Support/Pebble/pebble.db"
/bin/mkdir -p "$SESSION_HOME" "$CAPTURE_DIR"

P1_SETUP="$CAPTURE_DIR/blocker-01-three-productions.png"
P1_PROPOSAL="$CAPTURE_DIR/blocker-01-normal-proposal.png"
P1_OPEN="$CAPTURE_DIR/blocker-01-open-debt.png"
P2_RESTORED="$CAPTURE_DIR/blocker-01-restored-open.png"
P2_DISPLACED="$CAPTURE_DIR/blocker-01-displaced.png"
P2_REFUSED="$CAPTURE_DIR/blocker-01-refused-open.png"
P2_RETURNED="$CAPTURE_DIR/blocker-01-returned.png"
P2_FULFILLED="$CAPTURE_DIR/blocker-01-fulfilled.png"
P2_FINAL="$CAPTURE_DIR/blocker-01-final.png"
PHASE1_SHOTS="-|$P1_SETUP|$P1_PROPOSAL|$P1_OPEN"
PHASE2_SHOTS="$P2_RESTORED|$P2_DISPLACED|$P2_REFUSED|$P2_RETURNED|$P2_FULFILLED|$P2_FINAL"

cd "$ROOT_DIR"
swift build -c release --product Pebble
PEBBLE_BINARY="$ROOT_DIR/.build/release/Pebble"
[ -x "$PEBBLE_BINARY" ] || fail "release Pebble binary missing"

run_blocker_process() {
    trace=$1
    commands=$2
    command_world_tick=$3
    shots=$4
    create_world=$5
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
        PEBBLELAB_APP_AGENTS_INTERACT=1 \
        PEBBLELAB_APP_AGENTS_MATERIAL=1 \
        PEBBLELAB_APP_AGENTS_PERSISTENCE=1 \
        PEBBLELAB_APP_AGENTS_PRODUCTION=1 \
        PEBBLELAB_APP_AGENTS_CONTRACTS=1 \
        PEBBLELAB_APP_AGENTS_AUTONOMOUS_CIVILIZATION=1 \
        PEBBLELAB_GATE_E_BLOCKER_01=1 \
        PEBBLELAB_DISPOSABLE_WORLD_PROOF=1 \
        PEBBLE_CMD_WORLD_TICK="$command_world_tick" \
        PEBBLE_CMD="$commands" \
        PEBBLE_SHOT="$shots" \
        "$PEBBLE_BINARY" 2>&1 | /usr/bin/tee "$trace"
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
        PEBBLELAB_APP_AGENTS_INTERACT=1 \
        PEBBLELAB_APP_AGENTS_MATERIAL=1 \
        PEBBLELAB_APP_AGENTS_PERSISTENCE=1 \
        PEBBLELAB_APP_AGENTS_PRODUCTION=1 \
        PEBBLELAB_APP_AGENTS_CONTRACTS=1 \
        PEBBLELAB_APP_AGENTS_AUTONOMOUS_CIVILIZATION=1 \
        PEBBLELAB_GATE_E_BLOCKER_01=1 \
        PEBBLELAB_DISPOSABLE_WORLD_PROOF=1 \
        PEBBLE_CMD_WORLD_TICK="$command_world_tick" \
        PEBBLE_CMD="$commands" \
        PEBBLE_SHOT="$shots" \
        "$PEBBLE_BINARY" 2>&1 | /usr/bin/tee "$trace"
    fi
    if /usr/bin/pgrep -x Pebble >/dev/null 2>&1; then
        fail "Pebble process remained after $trace"
    fi
}

printf 'Gate E Blocker 01 process 1: three exact productions, normal contract, open debt.\n'
run_blocker_process "$PHASE1_TRACE" "$PHASE1_COMMANDS" 100 "$PHASE1_SHOTS" 1

[ -f "$DB_PATH" ] || fail "disposable database missing"
world_facts=$(/usr/bin/sqlite3 "$DB_PATH" "SELECT count(*), json_extract(json, '$.seed'), json_extract(json, '$.name') FROM worlds;")
[ "$world_facts" = "1|$WORLD_SEED|$WORLD_NAME" ] \
    || fail "unexpected disposable world facts: $world_facts"
for capture in "$P1_SETUP" "$P1_PROPOSAL" "$P1_OPEN"; do
    [ -s "$capture" ] || fail "missing process-1 capture: $capture"
done
require_trace "$PHASE1_TRACE" 'gate-e blocker-01 bootstrap producer=agent_[0-9]+ matchingHistorical=3 promisedAsset=contract-blocker-01-bread-p3:agent_[0-9]+ quantity=1 productionOperations=[^ ]+ proofFixtureDecisionAuthority=0' 'three distinct real productions'
require_trace "$PHASE1_TRACE" 'gate-e blocker-01 provenance matchingHistorical=3 .*promisedQuantity=1 .*attributedQuantity=1 otherMatchingRecords=2 falseMatchingAttributed=0 .*exactBinding=PASS observerMutationCount=0' 'exact P3 binding before the promise'
require_trace "$PHASE1_TRACE" 'contract normal promise proposal .*normalProposalDecision=1 proofFixtureDecisionAuthority=0 physicalMutation=0' 'normal product contract discovery'
require_trace_count "$PHASE1_TRACE" 'contract physical publication obligation=.* action=consideration ' 1 'one real consideration transfer'
require_trace "$PHASE1_TRACE" 'contracts enabled=1 .*active=1 debts=1 fulfilled=0 .*physicalLoss=0 physicalDuplication=0 syntheticMaterial=0 .*observerMutationCount=0' 'open debt conservation status'
require_trace "$PHASE1_TRACE" 'checkpoint saved name=gate-e-blocker-01-open-v33 .*restartSafe=1 ' 'restart-safe open debt checkpoint'
require_trace "$PHASE1_TRACE" 'summary .*runtimeErrors=0 .*probesRemoved=3 ' 'clean process-1 termination'
reject_trace "$PHASE1_TRACE" 'CANDIDATE_PHYSICAL_HARD_FAILURE|^\[lab-live\] error ' 'unexpected process-1 runtime error'

OPEN_SESSION=$(/usr/bin/find "$SESSION_HOME/Library/Application Support/Pebble/PebbleLabAgents" -type f -path "*/checkpoints/$OPEN_CHECKPOINT/session.json" -print -quit)
[ -n "$OPEN_SESSION" ] || fail "open checkpoint session.json missing"
/usr/bin/grep -q '"schemaVersion":33' "$OPEN_SESSION" \
    || fail "open checkpoint is not schema 33"
OPEN_DIGEST=$(/usr/bin/sed -n 's/.*checkpoint saved name=gate-e-blocker-01-open-v33 .* digest=\([0-9a-f]*\) storageDigest=.*/\1/p' "$PHASE1_TRACE" | /usr/bin/tail -1)
[ -n "$OPEN_DIGEST" ] || fail "open checkpoint digest unavailable"
persisted_world_tick=$(/usr/bin/sqlite3 "$DB_PATH" "SELECT json_extract(json, '$.dims.\"0\".time') FROM worlds;")
case "$persisted_world_tick" in
    ''|*[!0-9]*) fail "invalid persisted World tick: $persisted_world_tick" ;;
esac
continuation_tick=$((persisted_world_tick + 100))

printf 'Gate E Blocker 01 process 2: restore, displace, refuse, return, fulfill once.\n'
run_blocker_process "$PHASE2_TRACE" "$PHASE2_COMMANDS" "$continuation_tick" "$PHASE2_SHOTS" 0

for capture in "$P2_RESTORED" "$P2_DISPLACED" "$P2_REFUSED" \
    "$P2_RETURNED" "$P2_FULFILLED" "$P2_FINAL"; do
    [ -s "$capture" ] || fail "missing process-2 capture: $capture"
done
require_trace "$PHASE2_TRACE" "checkpoint loaded name=gate-e-blocker-01-open-v33 .*digest=$OPEN_DIGEST .*restartSafe=1 .*custodyDuplicates=0 physicalBoundary=acquired" 'fresh-process open-debt restore'
require_trace "$PHASE2_TRACE" 'gate-e blocker-01 provenance matchingHistorical=3 .*attributedQuantity=1 otherMatchingRecords=2 falseMatchingAttributed=0 .*exactBinding=PASS observerMutationCount=0' 'exact provenance after restart'
require_trace "$PHASE2_TRACE" 'contract blocker-01 displaced asset=.* currentPhysicalHolder=agent:agent_[0-9]+ quantity=1 rightsObservationUnchanged=1 productionOriginUnchanged=1 syntheticReplacement=0' 'exact promised asset displaced'
require_trace "$PHASE2_TRACE" 'autonomous activity blocked actor=agent_[0-9]+ domain=contract reason=.*current_rights_or_exact_physical_authority_refused' 'fulfillment refusal while displaced'
require_trace "$PHASE2_TRACE" 'contracts enabled=1 .*active=1 debts=1 fulfilled=0 .*syntheticMaterial=0 ' 'debt remains open after refusal'
require_trace "$PHASE2_TRACE" 'contract blocker-01 returned asset=.* currentPhysicalHolder=agent:agent_[0-9]+ quantity=1 rightsObservationUnchanged=1 productionOriginUnchanged=1 syntheticReplacement=0' 'same asset legitimately returned'
require_trace_count "$PHASE2_TRACE" 'contract physical publication obligation=.* action=fulfillment ' 1 'one exact physical fulfillment'
require_trace "$PHASE2_TRACE" 'contract proof result=PASS .*exactOnce=1 duplicateFulfillmentCount=0 observerMutationCount=0 .*physicalLoss=0 physicalDuplication=0 syntheticMaterial=0 ' 'exact-once fulfillment proof'
require_trace "$PHASE2_TRACE" 'contracts enabled=1 .*active=0 debts=0 fulfilled=1 .*physicalLoss=0 physicalDuplication=0 syntheticMaterial=0 .*observerMutationCount=0' 'final conservation status'
require_trace "$PHASE2_TRACE" 'summary .*runtimeErrors=0 .*probesRemoved=3 ' 'clean process-2 termination'
reject_trace "$PHASE2_TRACE" 'CANDIDATE_PHYSICAL_HARD_FAILURE|^\[lab-live\] error ' 'unexpected process-2 runtime error'

FULFILLED_SESSION=$(/usr/bin/find "$SESSION_HOME/Library/Application Support/Pebble/PebbleLabAgents" -type f -path '*/checkpoints/gate-e-blocker-01-fulfilled-v33/session.json' -print -quit)
[ -n "$FULFILLED_SESSION" ] || fail "fulfilled checkpoint session.json missing"
/usr/bin/grep -q '"schemaVersion":33' "$FULFILLED_SESSION" \
    || fail "fulfilled checkpoint is not schema 33"
capture_count=$(/usr/bin/find "$CAPTURE_DIR" -type f -name '*.png' | /usr/bin/wc -l | /usr/bin/tr -d ' ')
[ "$capture_count" -eq 9 ] || fail "capture count $capture_count != 9"

printf '\nPASS: Gate E Blocker 01 exact produced-asset provenance live proof.\n'
printf 'Fresh processes: 2\n'
printf 'Captures: %s (9)\n' "$CAPTURE_DIR"
printf 'Process 1 trace: %s\n' "$PHASE1_TRACE"
printf 'Process 2 trace: %s\n' "$PHASE2_TRACE"
printf 'Open checkpoint: %s\n' "$OPEN_SESSION"
printf 'Fulfilled checkpoint: %s\n' "$FULFILLED_SESSION"
printf 'Checkpoint schema: 33\n'
printf 'Observer schema: 10\n'
printf 'Unexpected runtime errors: 0\n'
printf 'Retained isolated session: %s\n' "$SESSION_ROOT"
