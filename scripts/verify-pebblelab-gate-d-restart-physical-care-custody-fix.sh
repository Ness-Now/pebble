#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
WORLD_NAME="PebbleLab-Disposable-GateD-Care-Custody-Fix-46"
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
    printf 'Gate D Blocker 05 restart physical-care custody correction (dry run)\n'
    printf '  Process A: legitimate G1, durable care, real bread custody, protected checkpoint.\n'
    printf '  Process B: fresh bootstrap, exact custody restore, care debit and continuation.\n'
    printf '  Adversarial: post-custody rollback, corruption, conflict and multi-slot exactness.\n'
    printf '  Scope: targeted blocker proof only; this runner does not evaluate Gate D.\n'
    exit 0
fi
[ "$#" -eq 0 ] \
    || fail "usage: scripts/verify-pebblelab-gate-d-restart-physical-care-custody-fix.sh [--dry-run]"

git -C "$ROOT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    || fail "repository metadata missing"
[ "$(git -C "$ROOT_DIR" rev-parse --show-toplevel)" = "$ROOT_DIR" ] \
    || fail "unexpected repository root"

if [ -n "${PEBBLELAB_GATE_D_CARE_CUSTODY_EVIDENCE_DIR:-}" ]; then
    EVIDENCE_ROOT=$PEBBLELAB_GATE_D_CARE_CUSTODY_EVIDENCE_DIR
    [ ! -e "$EVIDENCE_ROOT" ] \
        || fail "evidence directory already exists: $EVIDENCE_ROOT"
    /bin/mkdir -p "$EVIDENCE_ROOT"
else
    EVIDENCE_ROOT=$(/usr/bin/mktemp -d /tmp/PebbleLab-GateD-Care-Custody-Fix.XXXXXX)
fi
SESSION_HOME="$EVIDENCE_ROOT/home"
/bin/mkdir -p "$SESSION_HOME"

PROCESS_A_TRACE="$EVIDENCE_ROOT/process-a-save.log"
PROCESS_B_TRACE="$EVIDENCE_ROOT/process-b-restore.log"
SAVE_CAPTURE="$EVIDENCE_ROOT/caregiver-custody-at-save.png"
BOOTSTRAP_CAPTURE="$EVIDENCE_ROOT/fresh-bootstrap-before-load.png"
RESTORE_CAPTURE="$EVIDENCE_ROOT/restored-custody-after-load.png"
CARE_CAPTURE="$EVIDENCE_ROOT/care-continued-after-restart.png"
MANIFEST_COPY="$EVIDENCE_ROOT/protected-custody-manifest.json"
PROCESS_A_HOME="$EVIDENCE_ROOT/process-a-home"
CORRUPTION_TRACE="$EVIDENCE_ROOT/adversarial-corrupted-evidence.log"
CONFLICT_TRACE="$EVIDENCE_ROOT/adversarial-conflicting-bootstrap.log"
BUILD_CONFIGURATION=${PEBBLELAB_GATE_D_CARE_CUSTODY_BUILD_CONFIGURATION:-release}
case "$BUILD_CONFIGURATION" in
    debug|release) ;;
    *) fail "unsupported build configuration: $BUILD_CONFIGURATION" ;;
esac

cd "$ROOT_DIR"
swift build --disable-sandbox -c "$BUILD_CONFIGURATION" --product Pebble
PEBBLE_BINARY="$ROOT_DIR/.build/$BUILD_CONFIGURATION/Pebble"
[ -x "$PEBBLE_BINARY" ] || fail "$BUILD_CONFIGURATION Pebble binary missing"

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
ENABLE='/lab start;/tp 14 69 -21;/lab pause;/lab movement off;/lab follow off;/lab overlay full;/lab population on;/lab settlement on;/lab ecology on;/lab ecology scan;/lab survival on;/lab mortality on;/lab lifecycle on;/lab kinship on;/lab household on;/lab homeostasis on;/lab genetics on;/lab physical-food-survival on;/lab care on;/lab childhood on;/lab skills on;/lab social status;/lab teaching status;/lab observer open;/lab reproduction on'
PROCESS_A_COMMANDS="$WORLD_READY|$ENABLE;/lab step;/lab step;/lab step;/lab step;/lab care proof proximity-setup;/lab step;/lab care proof supervision-separation;/lab step;/lab movement on;/lab step;/lab step;/lab movement off;/lab care proof supervision-resume;/lab checkpoint custody-proof multi-slot-setup agent_0;/lab care proof physical-food-setup;/lab births status;/lab kinship status;/lab household status;/lab care status;/lab childhood status;/lab checkpoint custody-proof status agent_0;/lab checkpoint save gate-d-b05-care;/lab checkpoint status;/lab observer select agent_3;/lab observer status;/lab status;/tp 18 71 -14 135 24|/tp 18 71 -14 135 24"
PROCESS_B_COMMANDS="$WORLD_READY|/lab start;/lab pause;/lab movement off;/lab follow off;/lab overlay full;/lab status;/lab checkpoint custody-proof failure after-first-custody;/lab checkpoint load gate-d-b05-care;/lab checkpoint custody-proof status agent_0;/lab checkpoint custody-proof failure none;/tp 18 71 -14 135 24|/tp 18 71 -14 135 24|/lab checkpoint load gate-d-b05-care;/lab checkpoint custody-proof status agent_0;/lab births status;/lab kinship status;/lab household status;/lab care status;/lab childhood status;/lab observer open;/lab observer select agent_3;/lab observer status;/tp 18 71 -14 135 24|/tp 18 71 -14 135 24|/lab step;/lab checkpoint custody-proof status agent_0;/lab care status;/lab childhood status;/lab causality tail 20;/tp 18 71 -14 135 24|/tp 18 71 -14 135 24|/lab checkpoint delete gate-d-b05-care;/lab checkpoint status;/lab observer close;/lab status"

printf '\nGate D Blocker 05 process A: real caregiver custody and protected save.\n'
run_app "$PROCESS_A_TRACE" "$PROCESS_A_COMMANDS" "-|-|$SAVE_CAPTURE" 1

require_trace "$PROCESS_A_TRACE" \
    'birth finalized tick=4 .*newborn=agent_3 .*parents=agent_0,agent_1' \
    'legitimate G1 birth'
require_trace "$PROCESS_A_TRACE" \
    'checkpoint custody proof multiSlotSetup agent=agent_0 toolSlot=0 item=iron_hoe count=1 damage=7 enchantments=efficiency:2 label=present priorWork=2 repairUnits=1 fingerprint=[0-9a-f]{64}' \
    'non-trivial exact physical tool state in slot 0'
require_trace "$PROCESS_A_TRACE" \
    'care physical food setup tick=[0-9]+ caregiver=agent_0 dependent=agent_3 material=bread slot=1 count=1 custody=real' \
    'real bread in caregiver slot 1'
require_trace "$PROCESS_A_TRACE" \
    'checkpoint saved name=gate-d-b05-care .*manifestIntegrity=v2:[0-9a-f]{64} .*restartSafe=1 protectedCustodyAgents=4 protectedCustodyStacks=2 protectedCustodyQuantity=2 ' \
    'restart-safe checkpoint with real custody'
require_trace "$PROCESS_A_TRACE" \
    'stop probesRemoved=4 reason=termination custodyHandoff=protected taggedCustodySpills=2' \
    'graceful shutdown persists two uniquely tagged physical spills'
require_trace "$PROCESS_A_TRACE" \
    'summary .*agents=4 .*runtimeErrors=0 .*probesRemoved=4 ' \
    'process A exact shutdown'
reject_trace "$PROCESS_A_TRACE" \
    'runtimeErrors=[1-9]|duplicates=[1-9]|rollback failed' \
    'process A runtime, duplicate, or rollback failure'

[ -s "$SAVE_CAPTURE" ] || fail "save capture missing"
PERSISTENCE_ROOT="$SESSION_HOME/Library/Application Support/Pebble/PebbleLabAgents"
MANIFEST=$(/usr/bin/find "$PERSISTENCE_ROOT" -type f \
    -path '*/checkpoints/gate-d-b05-care/manifest.json' -print -quit)
[ -n "$MANIFEST" ] || fail "checkpoint manifest missing"
/bin/cp "$MANIFEST" "$MANIFEST_COPY"
/bin/cp -R "$SESSION_HOME" "$PROCESS_A_HOME"

printf '\nGate D Blocker 05 process B: fresh restore and normal care continuation.\n'
run_app "$PROCESS_B_TRACE" "$PROCESS_B_COMMANDS" \
    "-|-|$BOOTSTRAP_CAPTURE|-|$RESTORE_CAPTURE|-|$CARE_CAPTURE" 0

require_trace "$PROCESS_B_TRACE" \
    'checkpoint probe rollback verified name=gate-d-b05-care .*custodyRestored=1 custodySpillsRestored=2' \
    'fault after custody restore rolls back probes and persisted spills exactly'
require_trace "$PROCESS_B_TRACE" \
    'checkpoint loaded name=gate-d-b05-care .*restartSafe=1 .*custodyReconciliation=(restored|adopted_physical).*custodyRestoredStacks=2 .*custodyDuplicates=0 ' \
    'fresh-process exact physical custody restoration'
require_trace "$PROCESS_B_TRACE" \
    'checkpoint custody proof status agent=agent_0 .*breadSlot=1 breadCount=1 .*exact=1 duplicates=0' \
    'bread and non-trivial slot state restored exactly'
require_trace "$PROCESS_B_TRACE" \
    'care physical nourishment tick=[0-9]+ caregiver=agent_0 dependent=agent_3 material=bread slot=1 physicalCount=1>0 physicalDebit=1 .*foodRawGhostDelta=0 receipt=physical-care:' \
    'normal post-restart care consumes the real bread once'
require_trace "$PROCESS_B_TRACE" \
    'checkpoint custody proof status agent=agent_0 .*breadSlot=none breadCount=0 .*exact=1 duplicates=0' \
    'post-care custody has one normal debit and no refill'
require_trace "$PROCESS_B_TRACE" \
    'checkpoint status gate=enabled .*count=0 latest=none' \
    'checkpoint cleanup'
require_trace "$PROCESS_B_TRACE" \
    'summary .*agents=4 .*runtimeErrors=0 .*probesRemoved=4 ' \
    'process B exact shutdown'
reject_trace "$PROCESS_B_TRACE" \
    'protected_empty-custody_attestation|runtimeErrors=[1-9]|duplicates=[1-9]|rollback failed|physicalDebit=2' \
    'legacy refusal, runtime failure, duplication, rollback failure, or double debit'

for capture in "$BOOTSTRAP_CAPTURE" "$RESTORE_CAPTURE" "$CARE_CAPTURE"; do
    [ -s "$capture" ] || fail "rendered capture missing: $capture"
done

printf '\nGate D Blocker 05 adversarial C: conflicting bootstrap custody.\n'
CONFLICT_HOME="$EVIDENCE_ROOT/conflicting-bootstrap-home"
/bin/cp -R "$PROCESS_A_HOME" "$CONFLICT_HOME"
SESSION_HOME="$CONFLICT_HOME"
CONFLICT_COMMANDS="$WORLD_READY|/lab start;/lab pause;/lab movement off;/lab checkpoint custody-proof conflicting-bootstrap agent_0;/lab checkpoint custody-proof status agent_0;/lab checkpoint load gate-d-b05-care;/lab checkpoint custody-proof status agent_0;/lab status"
run_app "$CONFLICT_TRACE" "$CONFLICT_COMMANDS" "" 0
require_trace "$CONFLICT_TRACE" \
    'checkpoint custody proof conflictingBootstrap agent=agent_0 slot=3 item=cobblestone count=2 custody=real' \
    'contradictory bootstrap custody fixture'
require_trace "$CONFLICT_TRACE" \
    'PebbleAgents checkpoint command failed: current probe custody conflicts with protected evidence for agent_0' \
    'conflicting bootstrap custody is refused before mutation'
require_trace "$CONFLICT_TRACE" \
    'checkpoint custody proof status agent=agent_0 .*breadCount=0 stacks=1 quantity=2 .*taggedSpills=2 .*duplicates=0' \
    'existing bootstrap matter and protected escrow remain exact'
require_trace "$CONFLICT_TRACE" \
    'status PebbleAgents paused tick=0 .*probes=3 ' \
    'conflict leaves the fresh session unpublished'
reject_trace "$CONFLICT_TRACE" \
    'checkpoint loaded name=gate-d-b05-care|duplicates=[1-9]|rollback failed' \
    'conflict must not publish, duplicate, or damage rollback'

printf '\nGate D Blocker 05 adversarial B: corrupted protected evidence.\n'
CORRUPTION_HOME="$EVIDENCE_ROOT/corrupted-evidence-home"
/bin/cp -R "$PROCESS_A_HOME" "$CORRUPTION_HOME"
CORRUPT_MANIFEST=$(/usr/bin/find "$CORRUPTION_HOME" -type f \
    -path '*/checkpoints/gate-d-b05-care/manifest.json' -print -quit)
[ -n "$CORRUPT_MANIFEST" ] || fail "corruption manifest missing"
/usr/bin/python3 - "$CORRUPT_MANIFEST" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as stream:
    manifest = json.load(stream)
items = manifest["orchestration"]["protectedProbeCustodyEvidenceAtSave"][0]["items"]
if not items:
    raise SystemExit("protected evidence unexpectedly empty")
items[0]["quantity"] += 1
with open(path, "w", encoding="utf-8") as stream:
    json.dump(manifest, stream, sort_keys=True, separators=(",", ":"))
PY
SESSION_HOME="$CORRUPTION_HOME"
CORRUPTION_COMMANDS="$WORLD_READY|/lab start;/lab pause;/lab movement off;/lab checkpoint load gate-d-b05-care;/lab checkpoint custody-proof status agent_0;/lab status"
run_app "$CORRUPTION_TRACE" "$CORRUPTION_COMMANDS" "" 0
require_trace "$CORRUPTION_TRACE" \
    'PebbleAgents checkpoint command failed: (persistence storage digest mismatch|checkpoint manifest integrity mismatch)' \
    'tampered protected custody evidence is rejected by the manifest digest'
require_trace "$CORRUPTION_TRACE" \
    'checkpoint custody proof status agent=agent_0 .*breadCount=0 stacks=0 quantity=0 .*taggedSpills=2 .*duplicates=0' \
    'corruption refusal preserves empty bootstrap probes and physical escrow'
require_trace "$CORRUPTION_TRACE" \
    'status PebbleAgents paused tick=0 .*probes=3 ' \
    'corruption leaves the fresh session unpublished'
reject_trace "$CORRUPTION_TRACE" \
    'checkpoint loaded name=gate-d-b05-care|duplicates=[1-9]|rollback failed' \
    'corruption must not publish, duplicate, or mutate'

SESSION_HOME="$EVIDENCE_ROOT/home"

printf '\nGATE D BLOCKER 05 TARGETED PROOF PASSED\n'
printf 'Evidence: %s\n' "$EVIDENCE_ROOT"
printf 'Physical item loss count: 0\n'
printf 'Physical item duplication count: 0\n'
printf 'Care debit count after restart: 1\n'
printf 'Runtime errors: 0\n'
printf 'Cleanup: exact\n'
