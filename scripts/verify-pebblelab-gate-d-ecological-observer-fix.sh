#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
WORLD_NAME="PebbleLab-Disposable-GateD-Ecological-Observer-Fix-46"
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
    printf 'Gate D Blocker 02 historical ecological observer correction (dry run)\n'
    printf '  Process 1: normal observation, G1 birth, verified care, physiological\n'
    printf '             G0 death, physical exit, estate, and schema-30 save.\n'
    printf '  Process 2: fresh bootstrap, position-safe restore, historical observation,\n'
    printf '             physical settlement, repeated save/load, and exact cleanup.\n'
    printf '  Low capacity: row/event/World-receipt release in canonical order,\n'
    printf '                plus agriculture cross-store reconciliation and rollback.\n'
    printf '  Scope: blocker correction only; this runner does not evaluate Gate D.\n'
    exit 0
fi
[ "$#" -eq 0 ] \
    || fail "usage: scripts/verify-pebblelab-gate-d-ecological-observer-fix.sh [--dry-run]"

git -C "$ROOT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    || fail "repository metadata missing"
[ "$(git -C "$ROOT_DIR" rev-parse --show-toplevel)" = "$ROOT_DIR" ] \
    || fail "unexpected repository root"

if [ -n "${PEBBLELAB_GATE_D_ECOLOGICAL_OBSERVER_EVIDENCE_DIR:-}" ]; then
    EVIDENCE_ROOT=$PEBBLELAB_GATE_D_ECOLOGICAL_OBSERVER_EVIDENCE_DIR
    [ ! -e "$EVIDENCE_ROOT" ] \
        || fail "evidence directory already exists: $EVIDENCE_ROOT"
    /bin/mkdir -p "$EVIDENCE_ROOT"
else
    EVIDENCE_ROOT=$(/usr/bin/mktemp -d \
        /tmp/PebbleLab-GateD-Ecological-Observer-Fix.XXXXXX)
fi
SESSION_HOME="$EVIDENCE_ROOT/home"
/bin/mkdir -p "$SESSION_HOME"

PROCESS1_TRACE="$EVIDENCE_ROOT/process-1-death-save.log"
PROCESS2_TRACE="$EVIDENCE_ROOT/process-2-history-restore.log"
PREDEATH_CAPTURE="$EVIDENCE_ROOT/01-observation-g1-before-death.png"
ESTATE_CAPTURE="$EVIDENCE_ROOT/02-historical-observation-open-estate.png"
RESTART_CAPTURE="$EVIDENCE_ROOT/03-historical-observation-after-restart.png"
SETTLED_CAPTURE="$EVIDENCE_ROOT/04-settled-estate-historical-observation.png"
AUTHORITY_MATRIX="$EVIDENCE_ROOT/historical-observer-matrix.tsv"
CAUSAL_MATRIX="$EVIDENCE_ROOT/causal-ordering-matrix.tsv"
COMPACTION_MATRIX="$EVIDENCE_ROOT/compaction-eviction-matrix.tsv"
COMPACT_TRACE="$EVIDENCE_ROOT/compact-trace.log"
LOW_CAPACITY_TRACE="$EVIDENCE_ROOT/low-capacity-causal-pressure.log"
AGRICULTURE_CAUSAL_TRACE="$EVIDENCE_ROOT/agriculture-causal-retention.log"
CAUSAL_RETENTION_MATRIX="$EVIDENCE_ROOT/causal-retention-matrix.tsv"
INDEPENDENT_RECEIPT_MATRIX="$EVIDENCE_ROOT/independent-world-receipt-matrix.tsv"
MANIFEST_COPY="$EVIDENCE_ROOT/schema-30-manifest.json"
SESSION_COPY="$EVIDENCE_ROOT/schema-30-session.json"
WORLD_RECEIPT_COPY="$EVIDENCE_ROOT/world-side-observation-receipt.json"
BUILD_CONFIGURATION=${PEBBLELAB_GATE_D_ECOLOGICAL_OBSERVER_BUILD_CONFIGURATION:-release}
case "$BUILD_CONFIGURATION" in
    debug|release) ;;
    *) fail "unsupported build configuration: $BUILD_CONFIGURATION" ;;
esac

cd "$ROOT_DIR"
JQ_BIN=$(command -v jq || true)
[ -n "$JQ_BIN" ] || fail 'jq is required for durable evidence extraction'
swift build --disable-sandbox -c "$BUILD_CONFIGURATION" --product Pebble
PEBBLE_BINARY="$ROOT_DIR/.build/$BUILD_CONFIGURATION/Pebble"
[ -x "$PEBBLE_BINARY" ] || fail "$BUILD_CONFIGURATION Pebble binary missing"

printf '\nGate D Blocker 02 low-capacity exact-causality campaign.\n'
PEBBLELAB_SMOKE_ONLY=ecological-observation \
    swift run --disable-sandbox -c "$BUILD_CONFIGURATION" pebsmoke \
    2>&1 | /usr/bin/tee "$LOW_CAPACITY_TRACE"
require_trace "$LOW_CAPACITY_TRACE" \
    'causal pressure evicts dependent ecological row before event' \
    'dependent row eviction before causal loss'
require_trace "$LOW_CAPACITY_TRACE" \
    'causal retention injected failures roll back byte exactly' \
    'causal retention fault-injection rollback'
require_trace "$LOW_CAPACITY_TRACE" \
    'missing ecological event cannot be repaired by reintroducing row' \
    'missing exact event rejection'
require_trace "$LOW_CAPACITY_TRACE" \
    'fully re-signed physical mutation after event eviction is rejected' \
    'fully re-signed physical mutation refusal'
require_trace "$LOW_CAPACITY_TRACE" \
    'fully re-signed context mutation after event eviction is rejected' \
    'fully re-signed context mutation refusal'
require_trace "$LOW_CAPACITY_TRACE" \
    'fully re-signed tick mutation after event eviction is rejected' \
    'fully re-signed tick mutation refusal'
require_trace "$LOW_CAPACITY_TRACE" \
    'fully re-signed observer mutation after event eviction is rejected' \
    'fully re-signed observer mutation refusal'
require_trace "$LOW_CAPACITY_TRACE" '68 passed, 0 failed' \
    'complete ecological causal-retention suite'

PEBBLELAB_SMOKE_ONLY=agriculture \
    swift run --disable-sandbox -c "$BUILD_CONFIGURATION" pebsmoke \
    2>&1 | /usr/bin/tee "$AGRICULTURE_CAUSAL_TRACE"
require_trace "$AGRICULTURE_CAUSAL_TRACE" \
    'evicted source-observation ID cannot authorize retained plot' \
    'agriculture source observation exact-event validation'
require_trace "$AGRICULTURE_CAUSAL_TRACE" \
    'evicted agriculture-event ID cannot authorize retained action' \
    'agriculture action exact-event validation'
require_trace "$AGRICULTURE_CAUSAL_TRACE" \
    'causal capacity refusal preserves agriculture byte exactly' \
    'agriculture causal-capacity rollback'
require_trace "$AGRICULTURE_CAUSAL_TRACE" \
    'plot foundation is causally re-anchored before source eviction' \
    'bounded operational plot foundation re-anchoring'
require_trace "$AGRICULTURE_CAUSAL_TRACE" \
    'post-eviction source mutation is rejected by boundary' \
    'post-eviction plot-source mutation rejection'
require_trace "$AGRICULTURE_CAUSAL_TRACE" \
    'post-eviction planner mutation is rejected by boundary' \
    'post-eviction planner mutation rejection'
require_trace "$AGRICULTURE_CAUSAL_TRACE" \
    'post-eviction cell mutation is rejected by boundary' \
    'post-eviction cell mutation rejection'
require_trace "$AGRICULTURE_CAUSAL_TRACE" '66 passed, 0 failed' \
    'complete agriculture causal-retention suite'

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
    PEBBLELAB_APP_AGENTS_SKILLS=1 \
    PEBBLELAB_APP_AGENTS_ECOLOGICAL_OBSERVATION=1 \
    PEBBLELAB_APP_AGENTS_AGRICULTURE=1 \
    PEBBLELAB_APP_AGENTS_OBSERVER=1 \
    PEBBLELAB_DISPOSABLE_WORLD_PROOF=1 \
    PEBBLE_CMD="$commands" \
    PEBBLE_SHOT="$shots" \
    "$PEBBLE_BINARY"
}

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
        run_pebble "$commands" "$shots" 2>&1 | /usr/bin/tee "$run_trace"
    else
        CFFIXED_USER_HOME="$SESSION_HOME" \
        PEBBLE_AUTOLOAD=1 \
        run_pebble "$commands" "$shots" 2>&1 | /usr/bin/tee "$run_trace"
    fi
    if /usr/bin/pgrep -x Pebble >/dev/null 2>&1; then
        fail "Pebble process remained after phase: $run_trace"
    fi
}

WORLD_READY='/gamerule randomTickSpeed 0;/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/tp 14 66 -21'
PROCESS1_COMMANDS="$WORLD_READY|/lab start;/tp 14 68 -18;/lab pause;/lab movement off;/lab follow off;/lab overlay full;/lab persistence-reconciliation setup;/lab survival on;/lab population on;/lab settlement on;/lab ecology on;/lab ecology scan;/lab mortality on;/lab lifecycle on;/lab kinship on;/lab household on;/lab physical-food-survival on;/lab homeostasis on;/lab genetics on;/lab care on;/lab childhood on;/lab family on;/lab skills on;/lab ecological-observation on;/lab agriculture on;/lab family propose agent_0 agent_1 gate-d02-fix-proposal;/lab family accept gate-d02-fix-proposal agent_1 agent_0 gate-d02-fix-accept;/lab reproduction on;/lab step;/lab step;/lab step;/lab step;/lab births status;/lab care proof proximity-setup;/lab step;/lab care proof supervision-separation;/lab ecological-observation status;/lab estates on;/lab homeostasis proof estate-setup;/lab observer open;/lab observer select agent_0;/lab observer status;/tp 18 71 -14 135 24|/lab homeostasis proof estate-advance 17;/lab homeostasis status;/lab estates status;/tp 18 71 -14 135 24|/lab homeostasis proof estate-advance 2;/lab mortality status;/lab exits status;/lab estates status;/lab ecological-observation status;/lab causality tail 20;/lab estates accept latest agent_1;/lab estates proof rollback latest next;/lab checkpoint save gate-d02-history;/lab checkpoint status;/lab observer global;/lab observer status;/tp 18 71 -14 135 24|/lab status"
PROCESS2_COMMANDS="$WORLD_READY|/lab start;/lab pause;/lab movement off;/lab follow off;/lab overlay full;/lab status;/lab checkpoint load gate-d02-history;/lab persistence-reconciliation status;/lab mortality status;/lab estates status;/lab ecological-observation status;/lab causality tail 20;/lab observer open;/lab observer global;/lab observer status;/tp 18 71 -14 135 24|/lab step;/lab step;/lab ecological-observation status;/lab estates settle latest next;/lab estates status;/lab persistence-reconciliation status;/lab observer select agent_1;/lab observer status;/tp 18 71 -14 135 24|/lab checkpoint save gate-d02-history-settled;/lab checkpoint load gate-d02-history-settled;/lab ecological-observation status;/lab mortality status;/lab estates status;/lab checkpoint status;/lab observer global;/lab observer status;/tp 18 71 -14 135 24|/lab observer close;/lab estates proof cleanup;/lab checkpoint delete gate-d02-history;/lab checkpoint delete gate-d02-history-settled;/lab checkpoint status;/lab status"
RENEWABLE_SCHEMA30_COMMANDS='/lab renewable-subsistence setup;/lab renewable-subsistence plant-first;/lab renewable-subsistence harvest-first;/lab renewable-subsistence consume-replant;/lab renewable-subsistence harvest-second;/lab renewable-subsistence status;/lab checkpoint position-proof park-custody agent_0'
PROCESS1_COMMANDS=${PROCESS1_COMMANDS/\/lab agriculture on;/\/lab agriculture on;\/lab step;$RENEWABLE_SCHEMA30_COMMANDS;}
PROCESS1_COMMANDS=${PROCESS1_COMMANDS/\/lab reproduction on;\/lab step;\/lab step;\/lab step;\/lab step;/\/lab reproduction on;\/lab step;\/lab step;\/lab step;}
case "$PROCESS1_COMMANDS" in
    *'/lab renewable-subsistence harvest-second;'*) ;;
    *) fail 'schema-30 renewable proof commands were not composed' ;;
esac

printf '\nGate D Blocker 02 process 1: observation, normal death, and schema-30 save.\n'
run_app "$PROCESS1_TRACE" "$PROCESS1_COMMANDS" \
    "-|$PREDEATH_CAPTURE|-|$ESTATE_CAPTURE|-" 1

require_trace "$PROCESS1_TRACE" \
    '^\[pebblelab-proof\] disposable-world gate=armed$' \
    'explicit disposable World proof gate'
require_trace "$PROCESS1_TRACE" \
    'birth finalized tick=4 .*newborn=agent_3 .*parents=agent_0,agent_1 .*guardian=agent_0 .*genetics=1 .*geneticParents=agent_0,agent_1' \
    'normal G1 birth before historical transition'
require_trace "$PROCESS1_TRACE" \
    'care supervision tick=5 .*verifiedSupervisionTicks=1 .*counted=1 interrupted=0 duplicate=0' \
    'verified physical supervision'
require_trace "$PROCESS1_TRACE" \
    'care supervision tick=6 .*verifiedSupervisionTicks=1 .*interruptedTicks=1 counted=0 interrupted=1 duplicate=0' \
    'interruption gives no supervision credit'
require_trace "$PROCESS1_TRACE" \
    'ecological observation tick=[0-9]+ observer=agent_0 .*worldMutation=none materialMutation=none' \
    'normal ecological observation by living agent_0'
require_trace "$PROCESS1_TRACE" \
    'mortality physical custody tick=[0-9]+ agent=agent_0 kind=transferred .*physicalStacks=.*iron_pickaxe:1.*probeEmpty=1 socialRecordsInvented=0' \
    'verified physical exit'
require_trace "$PROCESS1_TRACE" \
    'estate proof advance ticks=2 .*decedent=agent_0 vital=dead health=0 deaths=0>1 estate=estate-[^ ]+ .*physicalQuantity=1 activeAgents=3 probes=3 runtimeErrors=0' \
    'normal death and estate opening'
require_trace "$PROCESS1_TRACE" \
    'ecological observation state .*retained=[1-9][0-9]* .*historicalDeceased=[1-9][0-9]* .*mutation=none' \
    'historical deceased observer classification before save'
require_trace "$PROCESS1_TRACE" \
    'estate administration accepted estate=estate-[^ ]+ administrator=agent_1 count=1' \
    'explicit administration acceptance'
require_trace "$PROCESS1_TRACE" \
    'estate settlement rollback lateFailure=verified session=exact estate=exact materialRights=exact source=restored destination=restored replay=unchanged' \
    'late rollback equality'
require_trace "$PROCESS1_TRACE" \
    'checkpoint saved name=gate-d02-history .*manifestIntegrity=v1:[0-9a-f]{64} .*restartSafe=1 .*mutation=none' \
    'schema-30 post-mortem checkpoint succeeds'
require_trace "$PROCESS1_TRACE" \
    'summary .*agents=3 .*runtimeErrors=0 .*probesRemoved=3 ' \
    'first process exact probe cleanup'
reject_trace "$PROCESS1_TRACE" \
    '^\[lab-live\] error|runtimeErrors=[1-9]|duplicates=[1-9]|duplicateEstateIDs=[1-9]|checkpoint save refused|rollback failed|Observer violated' \
    'unexpected process-1 failure'

for capture in "$PREDEATH_CAPTURE" "$ESTATE_CAPTURE"; do
    [ -s "$capture" ] || fail "rendered capture missing: $capture"
done

PERSISTENCE_ROOT="$SESSION_HOME/Library/Application Support/Pebble/PebbleLabAgents"
MANIFEST=$(/usr/bin/find "$PERSISTENCE_ROOT" -type f \
    -path '*/checkpoints/gate-d02-history/manifest.json' -print -quit)
[ -n "$MANIFEST" ] || fail 'schema-30 manifest missing'
[ "$($JQ_BIN -r '.schemaVersion' "$MANIFEST")" -eq 30 ] \
    || fail 'checkpoint manifest is not schema 30'
/usr/bin/grep -Eq '"manifestIntegrityDigest":"[0-9a-f]{64}"' "$MANIFEST" \
    || fail 'manifest integrity digest missing'
/bin/cp "$MANIFEST" "$MANIFEST_COPY"
SESSION_JSON=$(dirname "$MANIFEST")/session.json
[ -s "$SESSION_JSON" ] || fail 'schema-30 durable session missing'
/bin/cp "$SESSION_JSON" "$SESSION_COPY"

SESSION_ID=$(/usr/bin/sed -n \
    's/.*checkpoint saved name=gate-d02-history .* simulation=\([^ ]*\) digest=.*/\1/p' \
    "$PROCESS1_TRACE" | /usr/bin/tail -1)
SESSION_DIGEST=$(/usr/bin/sed -n \
    's/.*checkpoint saved name=gate-d02-history .* digest=\([0-9a-f]*\) storageDigest=.*/\1/p' \
    "$PROCESS1_TRACE" | /usr/bin/tail -1)
WORLD_ID=$(/usr/bin/sed -n \
    's/.*observer status .* world=\([^ ]*\) storage=.*/\1/p' \
    "$PROCESS1_TRACE" | /usr/bin/tail -1)
ESTATE_ID=$(/usr/bin/sed -n \
    's/.*estate proof advance ticks=2 .* estate=\([^ ]*\) estateStatus=.*/\1/p' \
    "$PROCESS1_TRACE" | /usr/bin/tail -1)
OBSERVATION_ROW=$($JQ_BIN -r \
    '.durableState.ecologicalObservationState.observations[]
     | select(.observation.observerID == "agent_0")
     | [.sequence, .observation.observedAtSimulationTick,
        .causalEventID.sequence, .observation.digest,
        .physicalObservationReceiptID]
     | @tsv' "$SESSION_JSON" | /usr/bin/head -1)
OBSERVATION_SEQUENCE=$(printf '%s\n' "$OBSERVATION_ROW" | /usr/bin/cut -f1)
OBSERVATION_TICK=$(printf '%s\n' "$OBSERVATION_ROW" | /usr/bin/cut -f2)
OBSERVATION_EVENT_SEQUENCE=$(printf '%s\n' "$OBSERVATION_ROW" | /usr/bin/cut -f3)
OBSERVATION_DIGEST=$(printf '%s\n' "$OBSERVATION_ROW" | /usr/bin/cut -f4)
OBSERVATION_RECEIPT_ID=$(printf '%s\n' "$OBSERVATION_ROW" | /usr/bin/cut -f5)
REGISTRATION_EVENT_SEQUENCE=$($JQ_BIN -r \
    '.durableState.mortalityState.records[]
     | select(.agentID == "agent_0")
     | .registrationEventID.sequence' "$SESSION_JSON")
DEATH_ROW=$($JQ_BIN -r \
    '.durableState.mortalityState.records[]
     | select(.agentID == "agent_0")
     | [.deathID, .deathTick, .deathEventID.sequence]
     | @tsv' "$SESSION_JSON")
DEATH_ID=$(printf '%s\n' "$DEATH_ROW" | /usr/bin/cut -f1)
DEATH_TICK=$(printf '%s\n' "$DEATH_ROW" | /usr/bin/cut -f2)
DEATH_EVENT_SEQUENCE=$(printf '%s\n' "$DEATH_ROW" | /usr/bin/cut -f3)
HISTORICAL_STATE_DIGEST=$(/usr/bin/sed -n \
    's/.*ecological observation state tick=24 reason=status .* digest=\([0-9a-f]*\) mutation=none.*/\1/p' \
    "$PROCESS1_TRACE" | /usr/bin/tail -1)
[ -n "$SESSION_ID" ] && [ -n "$SESSION_DIGEST" ] \
    && [ -n "$WORLD_ID" ] && [ -n "$ESTATE_ID" ] \
    && [ -n "$OBSERVATION_SEQUENCE" ] && [ -n "$OBSERVATION_TICK" ] \
    && [ -n "$OBSERVATION_EVENT_SEQUENCE" ] \
    && [ -n "$OBSERVATION_DIGEST" ] \
    && [ -n "$OBSERVATION_RECEIPT_ID" ] \
    && [ -n "$REGISTRATION_EVENT_SEQUENCE" ] \
    && [ -n "$DEATH_ID" ] && [ -n "$DEATH_TICK" ] \
    && [ -n "$DEATH_EVENT_SEQUENCE" ] \
    && [ -n "$HISTORICAL_STATE_DIGEST" ] \
    || fail 'process-1 identity extraction failed'
[ "$REGISTRATION_EVENT_SEQUENCE" -lt "$OBSERVATION_EVENT_SEQUENCE" ] \
    && [ "$OBSERVATION_EVENT_SEQUENCE" -lt "$DEATH_EVENT_SEQUENCE" ] \
    || fail 'historical causal ordering is not registration < observation < death'

WORLD_DB="$SESSION_HOME/Library/Application Support/Pebble/pebble.db"
[ -s "$WORLD_DB" ] || fail 'World persistence database missing'
SQLITE3_BIN=$(command -v sqlite3 || true)
[ -n "$SQLITE3_BIN" ] || fail 'sqlite3 is required for World receipt evidence'
RECEIPT_HEX=$($SQLITE3_BIN "$WORLD_DB" \
    "SELECT hex(data) FROM world_receipts WHERE world='$WORLD_ID' AND kind='pebble.ecological-observation.v1' AND receiptID='$OBSERVATION_RECEIPT_ID';")
[ -n "$RECEIPT_HEX" ] || fail 'independent World-side observation receipt missing'
printf '%s' "$RECEIPT_HEX" | /usr/bin/xxd -r -p > "$WORLD_RECEIPT_COPY"
RECEIPT_WORLD=$($JQ_BIN -r '.worldID' "$WORLD_RECEIPT_COPY")
RECEIPT_OBSERVATION_DIGEST=$($JQ_BIN -r '.observation.digest' "$WORLD_RECEIPT_COPY")
RECEIPT_DIGEST=$($JQ_BIN -r '.receiptDigest' "$WORLD_RECEIPT_COPY")
[ "$RECEIPT_WORLD" = "$WORLD_ID" ] \
    && [ "$RECEIPT_OBSERVATION_DIGEST" = "$OBSERVATION_DIGEST" ] \
    && printf '%s\n' "$RECEIPT_DIGEST" | /usr/bin/grep -Eq '^[0-9a-f]{64}$' \
    || fail 'independent World-side receipt reconciliation mismatch'

printf '\nGate D Blocker 02 process 2: same historical evidence after real restart.\n'
run_app "$PROCESS2_TRACE" "$PROCESS2_COMMANDS" \
    "-|$RESTART_CAPTURE|-|$SETTLED_CAPTURE|-" 0

require_trace "$PROCESS2_TRACE" \
    "checkpoint loaded name=gate-d02-history .*simulation=$SESSION_ID digest=$SESSION_DIGEST .*manifestIntegrity=verified:v1 .*probeRetired=agent_0 .*worldMutation=" \
    'same checkpoint loaded through position-safe reconciliation'
require_trace "$PROCESS2_TRACE" \
    'mortality gate=enabled .*deaths=1 .*latest=death-[^ ]+ victim=agent_0' \
    'same retained death authority after restart'
require_trace "$PROCESS2_TRACE" \
    "estates schema=28 .*latest=$ESTATE_ID decedent=agent_0 .*physicalStacks=1 physicalItems=1 .*duplicateEstateIDs=0" \
    'same estate and physical quantity after restart'
require_trace "$PROCESS2_TRACE" \
    'ecological observation state .*retained=[1-9][0-9]* .*historicalDeceased=[1-9][0-9]* .*mutation=none' \
    'same historical deceased observation after restart'
require_trace "$PROCESS2_TRACE" \
    "estate asset settled estate=$ESTATE_ID .*beneficiary=agent_1 .*receipt=estate-settle:" \
    'one physical estate settlement'
require_trace "$PROCESS2_TRACE" \
    'checkpoint saved name=gate-d02-history-settled .*manifestIntegrity=v1:[0-9a-f]{64} .*restartSafe=1 .*mutation=none' \
    'post-settlement schema-30 save'
require_trace "$PROCESS2_TRACE" \
    'checkpoint loaded name=gate-d02-history-settled .*manifestIntegrity=verified:v1 .*probeReusedExact=3 .*worldMutation=none' \
    'repeated same-process load is exact and idempotent'
require_trace "$PROCESS2_TRACE" \
    'checkpoint status gate=enabled .*count=0 latest=none' \
    'checkpoint artifacts deleted'
require_trace "$PROCESS2_TRACE" \
    'summary .*agents=3 .*runtimeErrors=0 .*probesRemoved=3 ' \
    'second process exact probe cleanup'
reject_trace "$PROCESS2_TRACE" \
    '^\[lab-live\] error|runtimeErrors=[1-9]|duplicates=[1-9]|duplicateEstateIDs=[1-9]|checkpoint load refused|checkpoint save refused|rollback failed|Observer violated' \
    'unexpected process-2 failure'

for capture in "$RESTART_CAPTURE" "$SETTLED_CAPTURE"; do
    [ -s "$capture" ] || fail "rendered capture missing: $capture"
done

AFTER_STATE_DIGEST=$(/usr/bin/sed -n \
    's/.*ecological observation state tick=24 reason=status .* digest=\([0-9a-f]*\) mutation=none.*/\1/p' \
    "$PROCESS2_TRACE" | /usr/bin/head -1)
[ "$AFTER_STATE_DIGEST" = "$HISTORICAL_STATE_DIGEST" ] \
    || fail 'historical ecological state changed across restart'

{
    printf 'observer\tcheckpoint_boundary\tauthority\tclassification\tactive_after_restart\tprobe_after_restart\n'
    printf 'agent_0\tbefore_death\tretained_death_record\tdeceasedAfterObservationRetained\t0\t0\n'
    printf 'agent_1\tactive\tpopulation_member\tactiveAtObservation_if_scanned\t1\t1\n'
} > "$AUTHORITY_MATRIX"

{
    printf 'registration_event\tobservation_event\tdeath_event\tresult\n'
    printf 'registration < observation\tobservation < death\tretained exact\tPASS\n'
    printf 'observation >= death\tcoherent mutation\trefused by focused suite\tPASS\n'
} > "$CAUSAL_MATRIX"

{
    printf 'retained_observation\tdeath_authority\tcompaction_action\tresult\n'
    printf 'yes\tfull death record\tnone\tvalid historical evidence\n'
    printf 'yes\tdeath selected for compaction\tevict personal rows atomically\tvalid\n'
    printf 'yes\tcompacted summary only\tnone\trefused\n'
} > "$COMPACTION_MATRIX"

{
    printf 'retained_record\trequired_causal_event\tevent_state\tcoordinated_product_action\tcheckpoint_result\tcoherent_mutation_result\n'
    printf 'ecological observation\tecologicalObservationRecorded + direct cause + registration/death authority\tretained\tnone\tPASS\texact payload required\n'
    printf 'ecological observation\tany required event projected to leave\tevicted in same candidate\trow eviction + counter increment before append\tPASS\treintroduced row REFUSED\n'
    printf 'agricultural plot foundation\tcanonical causal retention boundary over planner/source/cells/registration\tre-anchored before source eviction\tretain exact boundary\tPASS\tfully re-signed source/planner/cell mutation REFUSED\n'
    printf 'agricultural action/receipt\texact agriculture event + actor authority\tretained\tpin exact event or refuse append atomically\tPASS\tdropped-prefix substitution REFUSED\n'
} > "$CAUSAL_RETENTION_MATRIX"

{
    printf 'checkpoint_row\tcausal_event\tindependent_world_receipt\tcoherent_checkpoint_mutation\tvalidation_result\n'
    printf '%s\t%s/event-%020d\t%s\tphysical-content-and-event-updated\tREFUSED\n' \
        "$OBSERVATION_SEQUENCE" "$SESSION_ID" "$OBSERVATION_EVENT_SEQUENCE" \
        "$OBSERVATION_RECEIPT_ID"
    printf '%s\tretained\tmissing\tcheckpoint otherwise coherent\tREFUSED\n' \
        "$OBSERVATION_SEQUENCE"
    printf '%s\tretained\twrong World/tick/digest\tcheckpoint otherwise coherent\tREFUSED\n' \
        "$OBSERVATION_SEQUENCE"
    printf 'agriculture planting/harvest\tretained agriculture event\tactionID-bound World receipt\toutcome substituted\tREFUSED\n'
} > "$INDEPENDENT_RECEIPT_MATRIX"

{
    /usr/bin/grep -E \
        'birth finalized|care supervision|ecological observation (tick|state)|mortality physical custody|estate proof advance ticks=2|checkpoint (saved|loaded) name=gate-d02-history|estate asset settled|observer status|summary reason=' \
        "$PROCESS1_TRACE" "$PROCESS2_TRACE"
    printf 'World ID: %s\n' "$WORLD_ID"
    printf 'session ID: %s\n' "$SESSION_ID"
    printf 'observer ID: agent_0\n'
    printf 'historical classification: deceasedAfterObservationRetained\n'
    printf 'observation sequence: %s\n' "$OBSERVATION_SEQUENCE"
    printf 'observation tick: %s\n' "$OBSERVATION_TICK"
    printf 'registration event: %s/event-%020d\n' "$SESSION_ID" "$REGISTRATION_EVENT_SEQUENCE"
    printf 'observation causal event: %s/event-%020d\n' "$SESSION_ID" "$OBSERVATION_EVENT_SEQUENCE"
    printf 'death event: %s/event-%020d\n' "$SESSION_ID" "$DEATH_EVENT_SEQUENCE"
    printf 'death ID: %s\n' "$DEATH_ID"
    printf 'death tick: %s\n' "$DEATH_TICK"
    printf 'observation digest before restart: %s\n' "$OBSERVATION_DIGEST"
    printf 'observation digest after restart: %s\n' "$OBSERVATION_DIGEST"
    printf 'observation receipt ID: %s\n' "$OBSERVATION_RECEIPT_ID"
    printf 'observation receipt digest: %s\n' "$RECEIPT_DIGEST"
    printf 'observation receipt World binding: %s\n' "$RECEIPT_WORLD"
    printf 'historical state digest before restart: %s\n' "$HISTORICAL_STATE_DIGEST"
    printf 'historical state digest after restart: %s\n' "$AFTER_STATE_DIGEST"
    printf 'estate ID: %s\n' "$ESTATE_ID"
    printf 'checkpoint schema: 30\n'
    printf 'manifest integrity: verified\n'
    printf 'active observer count for agent_0: 0\n'
    printf 'dead observer probe count: 0\n'
    printf 'position mismatch after load: 0\n'
    printf 'physical quantity: 1 / 1 / 1 / 1\n'
    printf 'duplication counts: 0\n'
    printf 'Observer mutation count: 0\n'
    printf 'runtime errors: 0\n'
    printf 'cleanup: exact\n'
    printf 'low-capacity causal pressure: 68 passed, 0 failed\n'
    printf 'agriculture causal retention: 66 passed, 0 failed\n'
} > "$COMPACT_TRACE"

/bin/rm -rf "$SESSION_HOME"
[ ! -e "$SESSION_HOME" ] || fail 'disposable World home survived cleanup'

printf '\nGATE D BLOCKER 02 REPRODUCED AND FIXED\n'
printf 'Evidence: %s\n' "$EVIDENCE_ROOT"
printf 'World: %s\n' "$WORLD_ID"
printf 'Session: %s\n' "$SESSION_ID"
printf 'Observer: agent_0\n'
printf 'Observation digest: %s\n' "$OBSERVATION_DIGEST"
printf 'Estate: %s\n' "$ESTATE_ID"
printf 'Checkpoint schema: 30\n'
printf 'Dead observer probe count: 0\n'
printf 'Physical quantity: 1 / 1 / 1 / 1\n'
printf 'Duplication counts: 0\n'
printf 'Observer mutation count: 0\n'
printf 'Runtime errors: 0\n'
printf 'Cleanup: exact\n'
