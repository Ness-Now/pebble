#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
WORLD_SEED=46
WORLD_NAME=PebbleLab-Disposable-Gate-E-Blocker-02-46
DAMAGE1_CHECKPOINT=gate-e-blocker-02-damage1-v34
DAMAGE2_CHECKPOINT=gate-e-blocker-02-damage2-v34

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

PROCESS1_COMMANDS='/gamerule randomTickSpeed 0;/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/tp 14 68 -18|/lab start;/tp 14 73 -22;/lab pause;/lab movement off;/lab population on;/lab lifecycle on;/lab skills on;/lab barter setup;/lab barter status;/lab overlay compact|/lab step;/lab barter status;/lab overlay compact|/lab step;/lab barter status;/lab barter proof;/lab barter use-produced-tool;/lab barter blocker-02-status;/lab checkpoint save gate-e-blocker-02-damage1-v34;/lab checkpoint status;/lab causality tail 20;/lab overlay compact;/lab status'
PROCESS2_COMMANDS='/tp 14 68 -18;/lab start;/tp 14 73 -22;/lab pause;/lab movement off;/lab population on;/lab lifecycle on;/lab skills on;/lab checkpoint load gate-e-blocker-02-damage1-v34;/lab barter blocker-02-status;/lab overlay compact|/lab barter use-produced-tool;/lab barter blocker-02-status;/lab overlay compact|/lab step;/lab barter status;/lab barter blocker-02-status;/lab overlay compact|/lab step;/lab barter status;/lab barter blocker-02-status;/lab overlay compact|/lab checkpoint save gate-e-blocker-02-damage2-v34;/lab checkpoint status;/lab observer status;/lab barter cleanup;/lab causality tail 20;/lab status'

if [ "${1:-}" = "--dry-run" ]; then
    printf 'Gate E Blocker 02 live proof dry run\n'
    printf 'Repository: %s\n' "$ROOT_DIR"
    printf 'World: %s seed=%s\n' "$WORLD_NAME" "$WORLD_SEED"
    printf 'Fresh processes: 2\n'
    printf 'PEBBLELAB_GATE_E_BLOCKER_02=1\n'
    printf 'Process 1 PEBBLE_CMD=%s\n' "$PROCESS1_COMMANDS"
    printf 'Process 2 PEBBLE_CMD=%s\n' "$PROCESS2_COMMANDS"
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

SESSION_ROOT=$(/usr/bin/mktemp -d "/tmp/pebblelab-gate-e-blocker-02.XXXXXX")
case "$SESSION_ROOT" in
    /tmp/pebblelab-gate-e-blocker-02.*) ;;
    *) fail "unsafe session root: $SESSION_ROOT" ;;
esac
SESSION_HOME="$SESSION_ROOT/home"
CAPTURE_DIR="$SESSION_ROOT/captures"
PROCESS1_TRACE="$SESSION_ROOT/blocker-02-process-1.log"
PROCESS2_TRACE="$SESSION_ROOT/blocker-02-process-2.log"
DB_PATH="$SESSION_HOME/Library/Application Support/Pebble/pebble.db"
/bin/mkdir -p "$SESSION_HOME" "$CAPTURE_DIR"

P1_SETUP="$CAPTURE_DIR/blocker-02-setup.png"
P1_DISCOVERY="$CAPTURE_DIR/blocker-02-first-discovery.png"
P1_DAMAGE1="$CAPTURE_DIR/blocker-02-damage-1.png"
P2_RESTORED="$CAPTURE_DIR/blocker-02-restored-damage-1.png"
P2_DAMAGE2="$CAPTURE_DIR/blocker-02-damage-2.png"
P2_DISCOVERY="$CAPTURE_DIR/blocker-02-evolved-discovery.png"
P2_SETTLED="$CAPTURE_DIR/blocker-02-evolved-settled.png"
P2_FINAL="$CAPTURE_DIR/blocker-02-final.png"
PROCESS1_SHOTS="-|$P1_SETUP|$P1_DISCOVERY|$P1_DAMAGE1"
PROCESS2_SHOTS="$P2_RESTORED|$P2_DAMAGE2|$P2_DISCOVERY|$P2_SETTLED|$P2_FINAL"

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
        PEBBLELAB_APP_AGENTS_OBSERVER=1 \
        PEBBLELAB_APP_AGENTS_INTERACT=1 \
        PEBBLELAB_APP_AGENTS_MATERIAL=1 \
        PEBBLELAB_APP_AGENTS_PERSISTENCE=1 \
        PEBBLELAB_APP_AGENTS_POPULATION=1 \
        PEBBLELAB_APP_AGENTS_LIFECYCLE=1 \
        PEBBLELAB_APP_AGENTS_SKILLS=1 \
        PEBBLELAB_APP_AGENTS_PRODUCTION=1 \
        PEBBLELAB_APP_AGENTS_BARTER=1 \
        PEBBLELAB_APP_AGENTS_MARKETS=1 \
        PEBBLELAB_APP_AGENTS_AUTONOMOUS_CIVILIZATION=1 \
        PEBBLELAB_GATE_E_BLOCKER_02=1 \
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
        PEBBLELAB_APP_AGENTS_OBSERVER=1 \
        PEBBLELAB_APP_AGENTS_INTERACT=1 \
        PEBBLELAB_APP_AGENTS_MATERIAL=1 \
        PEBBLELAB_APP_AGENTS_PERSISTENCE=1 \
        PEBBLELAB_APP_AGENTS_POPULATION=1 \
        PEBBLELAB_APP_AGENTS_LIFECYCLE=1 \
        PEBBLELAB_APP_AGENTS_SKILLS=1 \
        PEBBLELAB_APP_AGENTS_PRODUCTION=1 \
        PEBBLELAB_APP_AGENTS_BARTER=1 \
        PEBBLELAB_APP_AGENTS_MARKETS=1 \
        PEBBLELAB_APP_AGENTS_AUTONOMOUS_CIVILIZATION=1 \
        PEBBLELAB_GATE_E_BLOCKER_02=1 \
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

printf 'Gate E Blocker 02 process 1: production, barter transfer, physical use, damage-1 checkpoint.\n'
run_blocker_process \
    "$PROCESS1_TRACE" "$PROCESS1_COMMANDS" 100 "$PROCESS1_SHOTS" 1

[ -f "$DB_PATH" ] || fail "disposable database missing"
world_facts=$(/usr/bin/sqlite3 "$DB_PATH" "SELECT count(*), json_extract(json, '$.seed'), json_extract(json, '$.name') FROM worlds;")
[ "$world_facts" = "1|$WORLD_SEED|$WORLD_NAME" ] \
    || fail "unexpected disposable world facts: $world_facts"
for capture in "$P1_SETUP" "$P1_DISCOVERY" "$P1_DAMAGE1"; do
    [ -s "$capture" ] || fail "missing process-1 capture: $capture"
done
require_trace "$PROCESS1_TRACE" 'barter setup .*produced=stone_pickaxe:1,bread:2 physical=verified .*barterProofFixtureDecisionAuthority=0 .*manualProductiveBarterCommandsAfterBootstrap=0 blocker02Bootstrap=1 blocker02FutureNeeds=2 checkpointSchema=34' 'fresh normal product bootstrap without decision authority'
require_trace_count "$PROCESS1_TRACE" 'barter completed offer=barter-[0-9a-f]+ ' 1 'one initial physical barter'
require_trace "$PROCESS1_TRACE" 'bartered produced tool used .*productionReceipt=barter-production:.*produce-pickaxe sameItem=stone_pickaxe damage=0>1 world=stone>air dropsAcquired=1 downstreamUse=PASS' 'same transferred tool physically evolves to damage one'
require_trace "$PROCESS1_TRACE" 'blocker02 evolved production identity result=PASS asset=.* productionOperation=.* originIdentity=stone_pickaxe:damage0 currentIdentity=stone_pickaxe:damage1 originCurrentExactEquality=0 permitsCurrentIdentity=1 originRewritten=0 .*productionProvenanceOperations=1 .*currentFingerprintAuthority=1 currentExactAuthority=1 historicalOriginAsCurrentAuthority=refused .*normalEconomicDiscovery=0 .*barterCount=1 producedToolUses=1 .*duplicateProductionReceipts=0 duplicateBarterReceipts=0 duplicateReservations=0 observerMutationCount=0 currencyAuthority=0 checkpointSchema=34 replaySchema=34 observerSchema=11 .*manualProductiveEconomicCommandsAfterBootstrap=0' 'damage-one immutable origin and exact current authority diagnostics'
require_trace "$PROCESS1_TRACE" 'checkpoint saved name=gate-e-blocker-02-damage1-v34 .*restartSafe=1 ' 'schema-34 evolved identity checkpoint'
require_trace "$PROCESS1_TRACE" 'summary .*runtimeErrors=0 .*probesRemoved=3 ' 'clean process-1 termination'
reject_trace "$PROCESS1_TRACE" 'CANDIDATE_PHYSICAL_HARD_FAILURE|^\[lab-live\] error ' 'unexpected process-1 runtime error'

PERSISTENCE_ROOT="$SESSION_HOME/Library/Application Support/Pebble/PebbleLabAgents"
DAMAGE1_SESSION=$(/usr/bin/find "$PERSISTENCE_ROOT" -type f -path "*/checkpoints/$DAMAGE1_CHECKPOINT/session.json" -print -quit)
[ -n "$DAMAGE1_SESSION" ] || fail "damage-1 checkpoint session.json missing"
/usr/bin/grep -q '"schemaVersion":34' "$DAMAGE1_SESSION" \
    || fail "damage-1 checkpoint is not schema 34"
DAMAGE1_DIGEST=$(/usr/bin/sed -n 's/.*checkpoint saved name=gate-e-blocker-02-damage1-v34 .* digest=\([0-9a-f]*\) storageDigest=.*/\1/p' "$PROCESS1_TRACE" | /usr/bin/tail -1)
[ -n "$DAMAGE1_DIGEST" ] || fail "damage-1 checkpoint digest unavailable"
persisted_world_tick=$(/usr/bin/sqlite3 "$DB_PATH" "SELECT json_extract(json, '$.dims.\"0\".time') FROM worlds;")
case "$persisted_world_tick" in
    ''|*[!0-9]*) fail "invalid persisted World tick: $persisted_world_tick" ;;
esac
continuation_tick=$((persisted_world_tick + 100))

printf 'Gate E Blocker 02 process 2: exact restore, second physical use, evolved discovery and settlement.\n'
run_blocker_process \
    "$PROCESS2_TRACE" "$PROCESS2_COMMANDS" "$continuation_tick" \
    "$PROCESS2_SHOTS" 0

for capture in "$P2_RESTORED" "$P2_DAMAGE2" "$P2_DISCOVERY" \
    "$P2_SETTLED" "$P2_FINAL"; do
    [ -s "$capture" ] || fail "missing process-2 capture: $capture"
done
require_trace "$PROCESS2_TRACE" "checkpoint loaded name=gate-e-blocker-02-damage1-v34 .*digest=$DAMAGE1_DIGEST .*restartSafe=1 .*custodyDuplicates=0 physicalBoundary=acquired" 'fresh-process exact damage-one restore'
require_trace "$PROCESS2_TRACE" 'blocker02 evolved production identity result=PASS .*originIdentity=stone_pickaxe:damage0 currentIdentity=stone_pickaxe:damage1 .*originRewritten=0 .*barterCount=1 producedToolUses=1 .*checkpointSchema=34 replaySchema=34 observerSchema=11' 'origin and evolved current identity survive restart'
require_trace "$PROCESS2_TRACE" 'bartered produced tool used .*sameItem=stone_pickaxe damage=1>2 world=stone>air dropsAcquired=1 downstreamUse=PASS' 'second legitimate real tool evolution'
require_trace "$PROCESS2_TRACE" 'blocker02 evolved production identity result=PASS .*originIdentity=stone_pickaxe:damage0 currentIdentity=stone_pickaxe:damage2 .*originRewritten=0 .*normalEconomicDiscovery=0 .*barterCount=1 producedToolUses=2 ' 'origin unchanged immediately after second use'
require_trace "$PROCESS2_TRACE" 'barter normal opportunity discovery .*normalOpportunityDiscovery=1 .*barterProofFixtureDecisionAuthority=0 ' 'ordinary evolved-asset barter discovery after restart'
require_trace "$PROCESS2_TRACE" 'barter normal offer decision .*normalOfferDecision=1 barterProofFixtureDecisionAuthority=0 physicalMutation=0' 'ordinary evolved-asset offer'
require_trace "$PROCESS2_TRACE" 'barter normal counterparty decision .*decision=accepted normalCounterpartyDecision=1 barterProofFixtureDecisionAuthority=0 .*physicalMutation=0' 'independent evolved-asset acceptance'
require_trace_count "$PROCESS2_TRACE" 'barter completed offer=barter-[0-9a-f]+ ' 1 'one later evolved-asset physical barter'
require_trace "$PROCESS2_TRACE" 'blocker02 evolved production identity result=PASS .*originIdentity=stone_pickaxe:damage0 currentIdentity=stone_pickaxe:damage2 originCurrentExactEquality=0 permitsCurrentIdentity=1 originRewritten=0 .*normalEconomicDiscovery=1 .*normalBarterSettlementAfterEvolution=1 .*barterCount=2 producedToolUses=2 .*physicalLoss=0 physicalDuplication=0 syntheticMaterial=0 duplicateProductionReceipts=0 duplicateBarterReceipts=0 duplicateReservations=0 observerMutationCount=0 currencyAuthority=0 .*observerSchema=11' 'normal evolved-asset discovery and settlement with conservation'
require_trace "$PROCESS2_TRACE" 'checkpoint saved name=gate-e-blocker-02-damage2-v34 .*restartSafe=1 ' 'final schema-34 checkpoint'
require_trace "$PROCESS2_TRACE" 'Barter disposable fixture cleanup cells=exact exchangedCustody=retained' 'exact disposable-cell cleanup'
require_trace "$PROCESS2_TRACE" 'summary .*runtimeErrors=0 .*probesRemoved=3 ' 'clean process-2 termination'
reject_trace "$PROCESS2_TRACE" 'CANDIDATE_PHYSICAL_HARD_FAILURE|^\[lab-live\] error ' 'unexpected process-2 runtime error'

DAMAGE2_SESSION=$(/usr/bin/find "$PERSISTENCE_ROOT" -type f -path "*/checkpoints/$DAMAGE2_CHECKPOINT/session.json" -print -quit)
[ -n "$DAMAGE2_SESSION" ] || fail "damage-2 checkpoint session.json missing"
/usr/bin/grep -q '"schemaVersion":34' "$DAMAGE2_SESSION" \
    || fail "damage-2 checkpoint is not schema 34"
capture_count=$(/usr/bin/find "$CAPTURE_DIR" -type f -name '*.png' | /usr/bin/wc -l | /usr/bin/tr -d ' ')
[ "$capture_count" -eq 8 ] || fail "capture count $capture_count != 8"

printf '\nPASS: Gate E Blocker 02 evolved current identity live proof.\n'
printf 'Fresh processes: 2\n'
printf 'Captures: %s (8)\n' "$CAPTURE_DIR"
printf 'Process 1 trace: %s\n' "$PROCESS1_TRACE"
printf 'Process 2 trace: %s\n' "$PROCESS2_TRACE"
printf 'Damage-1 checkpoint: %s\n' "$DAMAGE1_SESSION"
printf 'Damage-2 checkpoint: %s\n' "$DAMAGE2_SESSION"
printf 'Checkpoint schema: 34\n'
printf 'Replay schema: 34\n'
printf 'Observer schema: 11\n'
printf 'Expected runtime errors: 0\n'
printf 'Unexpected runtime errors: 0\n'
printf 'Cleanup: exact disposable cells and three probes per process\n'
printf 'Retained isolated session: %s\n' "$SESSION_ROOT"
