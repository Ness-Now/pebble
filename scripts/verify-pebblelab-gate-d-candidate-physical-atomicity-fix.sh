#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
BASELINE=4b11c93abd36a1a1c61d491df1e5efa6607f6206
EVALUATION_04_FAIL=d1115ae50318b15ffe064209b40a46dd44bb356f
BUILD_CONFIGURATION=${PEBBLELAB_GATE_D_BLOCKER_04_BUILD_CONFIGURATION:-debug}

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
    printf 'Gate D Blocker 04 candidate physical atomicity fix (dry run)\n'
    printf '  Baseline: %s\n' "$BASELINE"
    printf '  Historical Evaluation 04 FAIL: %s\n' "$EVALUATION_04_FAIL"
    printf '  Test 0: unavailable shearing and injected parent-registration failure leave sheep, tool, RNG, custody, receipts, and publication exact.\n'
    printf '  Test 1: external renewable World progress, failed candidate, fresh retry, checkpoint and process restart.\n'
    printf '  Test 2: verified movement, late failure, exact full-state rollback, nominal retry, checkpoint and process restart.\n'
    printf '  Test 3: injected non-verifiable movement compensation, hard failure, and step/checkpoint/restart refusal.\n'
    printf '  Verdict is blocker-only; this command never declares Gate D PASS.\n'
    exit 0
fi
[ "$#" -eq 0 ] \
    || fail 'usage: scripts/verify-pebblelab-gate-d-candidate-physical-atomicity-fix.sh [--dry-run]'

cd "$ROOT_DIR"
git cat-file -e "$BASELINE^{commit}" \
    || fail 'published baseline commit unavailable'
git cat-file -e "$EVALUATION_04_FAIL^{commit}" \
    || fail 'historical Evaluation 04 FAIL commit unavailable'
[ "$(git merge-base HEAD "$BASELINE")" = "$BASELINE" ] \
    || fail 'current correction is not based on the required baseline'
case "$BUILD_CONFIGURATION" in
    debug|release) ;;
    *) fail "unsupported build configuration: $BUILD_CONFIGURATION" ;;
esac

if [ -n "${PEBBLELAB_GATE_D_BLOCKER_04_EVIDENCE_DIR:-}" ]; then
    EVIDENCE_ROOT=$PEBBLELAB_GATE_D_BLOCKER_04_EVIDENCE_DIR
    [ ! -e "$EVIDENCE_ROOT" ] \
        || fail "evidence directory already exists: $EVIDENCE_ROOT"
    /bin/mkdir -p "$EVIDENCE_ROOT"
else
    EVIDENCE_ROOT=$(/usr/bin/mktemp -d /tmp/PebbleLab-GateD-Blocker04.XXXXXX)
fi

HEADLESS_TRACE="$EVIDENCE_ROOT/00-priority-tests.log"
SHEARING_HOME="$EVIDENCE_ROOT/shearing-home"
SHEARING_TRACE="$EVIDENCE_ROOT/00-shearing-atomicity.log"
SHEARING_CAPTURE="$EVIDENCE_ROOT/00-shearing-atomicity.png"
RENEWABLE_HOME="$EVIDENCE_ROOT/renewable-home"
RENEWABLE_TRACE="$EVIDENCE_ROOT/01-renewable-failure-retry.log"
RENEWABLE_RESTART_TRACE="$EVIDENCE_ROOT/02-renewable-restart.log"
RENEWABLE_CAPTURE="$EVIDENCE_ROOT/01-renewable-retry.png"
RENEWABLE_RESTART_CAPTURE="$EVIDENCE_ROOT/02-renewable-restart.png"
MOVEMENT_HOME="$EVIDENCE_ROOT/movement-home"
MOVEMENT_TRACE="$EVIDENCE_ROOT/03-movement-failure-retry.log"
MOVEMENT_RESTART_TRACE="$EVIDENCE_ROOT/04-movement-restart.log"
MOVEMENT_CAPTURE="$EVIDENCE_ROOT/03-movement-retry.png"
MOVEMENT_RESTART_CAPTURE="$EVIDENCE_ROOT/04-movement-restart.png"
HARD_HOME="$EVIDENCE_ROOT/hard-failure-home"
HARD_TRACE="$EVIDENCE_ROOT/05-compensation-hard-failure.log"
HARD_CAPTURE="$EVIDENCE_ROOT/05-compensation-hard-failure.png"
SUMMARY_JSON="$EVIDENCE_ROOT/summary.json"
CAPTURE_DIGESTS="$EVIDENCE_ROOT/capture-sha256.txt"

/bin/mkdir -p "$SHEARING_HOME" "$RENEWABLE_HOME" "$MOVEMENT_HOME" "$HARD_HOME"

swift build --disable-sandbox -c "$BUILD_CONFIGURATION" --product Pebble
swift build --disable-sandbox -c "$BUILD_CONFIGURATION" --product pebsmoke
PEBBLE_BINARY="$ROOT_DIR/.build/$BUILD_CONFIGURATION/Pebble"
SMOKE_BINARY="$ROOT_DIR/.build/$BUILD_CONFIGURATION/pebsmoke"
[ -x "$PEBBLE_BINARY" ] || fail 'Pebble binary missing'
[ -x "$SMOKE_BINARY" ] || fail 'pebsmoke binary missing'

printf '\nBlocker 04 priority headless tests.\n'
PEBBLELAB_SMOKE_ONLY=candidate-physical-atomicity \
    "$SMOKE_BINARY" 2>&1 | /usr/bin/tee "$HEADLESS_TRACE"
require_trace "$HEADLESS_TRACE" \
    'candidateTickFailureAfterVerifiedMovementRestoresAllPhysicalState restores' \
    'full movement physical state restores'
require_trace "$HEADLESS_TRACE" \
    'renewableWorldAdvanceRemainsExternalAfterCandidateFailure' \
    'external World progress survives candidate rollback'
require_trace "$HEADLESS_TRACE" '3 passed, 0 failed' \
    'priority headless tests passed'

run_pebble() {
    home=$1
    trace_file=$2
    proof_commands=$3
    proof_shots=$4
    seed=$5
    world_name=$6
    create_world=$7
    candidate_fault=$8
    compensation_fault=$9
    agriculture_navigation_fault=${10}
    if [ "$create_world" -eq 1 ]; then
        CFFIXED_USER_HOME="$home" \
        PEBBLE_AUTOLOAD=1 \
        PEBBLE_NEWWORLD="$seed" \
        PEBBLE_NEWWORLD_NAME="$world_name" \
        PEBBLELAB_DISPOSABLE_CANDIDATE_PHYSICAL_FAULT="$candidate_fault" \
        PEBBLELAB_DISPOSABLE_CANDIDATE_COMPENSATION_FAULT="$compensation_fault" \
        PEBBLELAB_DISPOSABLE_CANDIDATE_AGRICULTURE_NAVIGATION_FAULT="$agriculture_navigation_fault" \
        run_pebble_environment "$proof_commands" "$proof_shots" \
            2>&1 | /usr/bin/tee "$trace_file"
    else
        CFFIXED_USER_HOME="$home" \
        PEBBLE_AUTOLOAD=1 \
        PEBBLELAB_DISPOSABLE_CANDIDATE_PHYSICAL_FAULT="$candidate_fault" \
        PEBBLELAB_DISPOSABLE_CANDIDATE_COMPENSATION_FAULT="$compensation_fault" \
        PEBBLELAB_DISPOSABLE_CANDIDATE_AGRICULTURE_NAVIGATION_FAULT="$agriculture_navigation_fault" \
        run_pebble_environment "$proof_commands" "$proof_shots" \
            2>&1 | /usr/bin/tee "$trace_file"
    fi
    if /usr/bin/pgrep -x Pebble >/dev/null 2>&1; then
        fail "Pebble process remained after $trace_file"
    fi
}

run_pebble_environment() {
    proof_commands=$1
    proof_shots=$2
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
    PEBBLELAB_APP_AGENTS_LIFECYCLE=1 \
    PEBBLELAB_APP_AGENTS_SKILLS=1 \
    PEBBLELAB_APP_AGENTS_ECOLOGICAL_OBSERVATION=1 \
    PEBBLELAB_APP_AGENTS_AGRICULTURE=1 \
    PEBBLELAB_APP_AGENTS_LIVESTOCK=1 \
    PEBBLELAB_APP_AGENTS_OBSERVER=1 \
    PEBBLELAB_DISPOSABLE_WORLD_PROOF=1 \
    PEBBLE_CMD="$proof_commands" \
    PEBBLE_SHOT="$proof_shots" \
    "$PEBBLE_BINARY"
}

WORLD_RULES='/gamerule randomTickSpeed 0;/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear'
SHEARING_COMMANDS="$WORLD_RULES;/tp 14 68 -18|/tp 14 68 -18;/lab start;/lab pause;/lab movement off;/lab follow off;/lab overlay full;/lab population on;/lab lifecycle on;/lab skills on;/lab ecological-observation on;/lab livestock on;/lab livestock proof setup;/lab livestock proof atomicity;/lab livestock status;/lab status;/tp 18 80 -14 135 24"

printf '\nTest 0: candidate shearing refusal and registration failure atomicity.\n'
run_pebble "$SHEARING_HOME" "$SHEARING_TRACE" \
    "$SHEARING_COMMANDS" "-|$SHEARING_CAPTURE|-" 46 \
    PebbleLab-Disposable-GateD-B04-Shearing 1 '' '' ''
require_trace "$SHEARING_TRACE" \
    'candidatePhysicalRegisterClosedTransactionRefused: PASS committed=refused rolledBack=refused tokens=0' \
    'closed candidate transactions refuse compensation registration'
require_trace "$SHEARING_TRACE" \
    'candidateShearingUnavailableLeavesPhysicalStateExact: PASS .*sheep=exact .*durability=exact .*rng=exact .*itemEntities=0 .*tokens=0 .*session=unchanged .*recorder=unchanged .*receipts=unchanged' \
    'unavailable candidate shearing leaves all physical and publication state exact'
require_trace "$SHEARING_TRACE" \
    'candidateShearingRegistrationFailureCannotLeakParentMutation: PASS .*parent=restored childCustody=restored .*durability=exact .*rng=exact .*itemEntities=0 .*tokens=0 .*session=unchanged .*recorder=unchanged .*receipts=unchanged' \
    'parent registration failure restores parent and child custody exactly'
reject_trace "$SHEARING_TRACE" \
    'candidateShearing.*: FAIL|CANDIDATE_PHYSICAL_HARD_FAILURE|runtimeErrors=[1-9]' \
    'shearing atomicity failure, hard failure, or runtime error'
RENEWABLE_START='/tp 14 68 -18;/lab start;/lab pause;/lab movement off;/lab follow off;/lab overlay full;/lab survival on;/lab population on;/lab settlement on;/lab ecology on;/lab ecology scan;/lab lifecycle on;/lab physical-food-survival on;/lab skills on;/lab ecological-observation on;/lab agriculture on;/lab observer open;/lab observer global;/lab step'
RENEWABLE_COMMANDS="$WORLD_RULES;/tp 14 68 -18|$RENEWABLE_START;/lab renewable-subsistence setup;/lab renewable-subsistence status;/lab renewable-subsistence setup;/lab renewable-subsistence plant-first;/lab renewable-subsistence harvest-first;/lab renewable-subsistence status;/lab renewable-subsistence harvest-first;/lab renewable-subsistence status;/lab renewable-subsistence consume-replant;/lab renewable-subsistence status;/lab checkpoint save b04-renewable;/lab checkpoint load b04-renewable;/lab checkpoint status;/lab status;/tp 18 80 -14 135 24"
RENEWABLE_RESTART_COMMANDS="$WORLD_RULES;/tp 14 68 -18|/tp 14 68 -18;/lab start;/lab pause;/lab movement off;/lab follow off;/lab overlay full;/lab checkpoint load b04-renewable;/lab renewable-subsistence status;/lab checkpoint status;/lab status;/tp 18 80 -14 135 24"

printf '\nTest 1: external renewable World progression and failed candidate retry.\n'
run_pebble "$RENEWABLE_HOME" "$RENEWABLE_TRACE" \
    "$RENEWABLE_COMMANDS" "-|$RENEWABLE_CAPTURE|-" 103 \
    PebbleLab-Disposable-GateD-B04-Renewable 1 \
    renewable-after-final-validation '' after-first-verified-movement

require_trace "$RENEWABLE_TRACE" \
    'candidate agriculture navigation fault seam operation=navigateAgricultureActor point=after-first-verified-movement .*globalTokenRegistered=0' \
    'partial agricultural navigation fault after one verified Core movement'
require_trace "$RENEWABLE_TRACE" \
    'CANDIDATE_PHYSICAL_LOCAL_ROLLBACK operation=navigateAgricultureActor .*restored=\{.*position=.*prev=.*velocity=.*orientation=.*onGround=.*horizontalCollision=.*fallDistance=.*\} globalTokenRegistered=0' \
    'partial agricultural navigation restored its complete physical state locally'
require_trace "$RENEWABLE_TRACE" \
    'CANDIDATE_PHYSICAL_ROLLBACK operation=renewable-subsistence command=setup .*registered=renewable-proof-fixture.*completed=renewable-proof-fixture.*publishedSession=unchanged .*publishedRecorder=unchanged' \
    'outer setup candidate reversed earlier fixture work after local navigation rollback'

require_trace "$RENEWABLE_TRACE" \
    'candidate physical fault seam operation=renewable-subsistence .*point=after-final-validation' \
    'late renewable fault after verified candidate mutation'
require_trace "$RENEWABLE_TRACE" \
    'CANDIDATE_PHYSICAL_ROLLBACK operation=renewable-subsistence .*receiptsRetained=0 publishedSession=unchanged .*publishedRecorder=unchanged' \
    'candidate physical, receipt, session, and recorder rollback'
require_trace "$RENEWABLE_TRACE" \
    'renewable cycle harvest cycle=1 growthStart=[0-9]+ authorizedWorldTicks=[1-9][0-9]* .*output=carrot:[3-5]' \
    'external World growth and failed harvest candidate'
require_trace "$RENEWABLE_TRACE" \
    'renewable cycle harvest cycle=1 growthStart=[0-9]+ authorizedWorldTicks=0 .*output=carrot:[3-5]' \
    'fresh retry without a second World advance'
require_trace "$RENEWABLE_TRACE" \
    'checkpoint loaded name=b04-renewable .*restartSafe=1 .*probeReconciliation=reused_exact .*worldMutation=none' \
    'in-process exact checkpoint reconciliation'
reject_trace "$RENEWABLE_TRACE" \
    'CANDIDATE_PHYSICAL_HARD_FAILURE|runtimeErrors=[1-9]|duplicateReceipts=[1-9]|duplicateSites=[1-9]' \
    'hard failure, runtime error, or duplication in successful compensation case'

FAILED_RECEIPT=$(/usr/bin/sed -n \
    's/.*renewable cycle harvest cycle=1 .* maturityReceipt=\([^ ]*\) output=.*/\1/p' \
    "$RENEWABLE_TRACE" | /usr/bin/head -1)
RETRY_RECEIPT=$(/usr/bin/sed -n \
    's/.*renewable cycle harvest cycle=1 .* maturityReceipt=\([^ ]*\) output=.*/\1/p' \
    "$RENEWABLE_TRACE" | /usr/bin/tail -1)
FAILED_OUTPUT=$(/usr/bin/sed -n \
    's/.*renewable cycle harvest cycle=1 .* output=carrot:\([0-9][0-9]*\) .*/\1/p' \
    "$RENEWABLE_TRACE" | /usr/bin/head -1)
RETRY_OUTPUT=$(/usr/bin/sed -n \
    's/.*renewable cycle harvest cycle=1 .* output=carrot:\([0-9][0-9]*\) .*/\1/p' \
    "$RENEWABLE_TRACE" | /usr/bin/tail -1)
ACQUIRED_WORLD_TICK=$(/usr/bin/sed -n \
    's/.*renewable cycle harvest cycle=1 .* maturityTick=\([0-9][0-9]*\) .*/\1/p' \
    "$RENEWABLE_TRACE" | /usr/bin/head -1)
RETRY_WORLD_TICK=$(/usr/bin/sed -n \
    's/.*renewable cycle harvest cycle=1 .* maturityTick=\([0-9][0-9]*\) .*/\1/p' \
    "$RENEWABLE_TRACE" | /usr/bin/tail -1)
[ -n "$FAILED_RECEIPT" ] && [ -n "$RETRY_RECEIPT" ] \
    && [ "$FAILED_RECEIPT" != "$RETRY_RECEIPT" ] \
    || fail 'renewable retry reused the abandoned observation receipt'
[ "$FAILED_OUTPUT" = "$RETRY_OUTPUT" ] \
    || fail 'candidate rollback did not restore gameplay RNG exactly'
[ "$ACQUIRED_WORLD_TICK" = "$RETRY_WORLD_TICK" ] \
    || fail 'renewable retry advanced the physical World a second time'

WORLD_DB="$RENEWABLE_HOME/Library/Application Support/Pebble/pebble.db"
SQLITE3_BIN=$(command -v sqlite3 || true)
[ -n "$SQLITE3_BIN" ] && [ -s "$WORLD_DB" ] \
    || fail 'sqlite3 or renewable World database unavailable'
FAILED_RECEIPT_COUNT=$($SQLITE3_BIN "$WORLD_DB" \
    "SELECT COUNT(*) FROM world_receipts WHERE receiptID='$FAILED_RECEIPT';")
RETRY_RECEIPT_COUNT=$($SQLITE3_BIN "$WORLD_DB" \
    "SELECT COUNT(*) FROM world_receipts WHERE receiptID='$RETRY_RECEIPT';")
[ "$FAILED_RECEIPT_COUNT" -eq 0 ] && [ "$RETRY_RECEIPT_COUNT" -eq 1 ] \
    || fail 'abandoned or committed renewable receipt count is incorrect'

printf '\nTest 1 restart: exact checkpoint and reconciliation in a new process.\n'
run_pebble "$RENEWABLE_HOME" "$RENEWABLE_RESTART_TRACE" \
    "$RENEWABLE_RESTART_COMMANDS" "-|$RENEWABLE_RESTART_CAPTURE|-" 103 unused 0 '' '' ''
require_trace "$RENEWABLE_RESTART_TRACE" \
    'checkpoint loaded name=b04-renewable .*restartSafe=1 .*probeReconciliation=reused_exact .*worldMutation=none' \
    'separate-process renewable checkpoint reconciliation'
require_trace "$RENEWABLE_RESTART_TRACE" \
    'renewable status schema=30 observerSchema=7 .*cycle=2 phase=growing stage=0 .*runtimeErrors=0' \
    'renewable state and acquired external maturity provenance retained across restart'

MOVEMENT_START='/tp 14 68 -18;/lab start;/lab pause;/lab movement off;/lab follow off;/lab overlay full;/lab population on;/lab settlement on;/lab ecology on;/lab ecology scan;/lab lifecycle on;/lab skills on;/lab ecological-observation on;/lab agriculture on;/lab migration admit;/lab focus agent_3;/lab movement on'
MOVEMENT_COMMANDS="$WORLD_RULES;/tp 14 68 -18|$MOVEMENT_START;/lab step;/lab status;/lab step;/lab step;/lab movement off;/lab checkpoint save b04-movement;/lab checkpoint load b04-movement;/lab checkpoint status;/lab status;/tp 18 80 -14 135 24"
MOVEMENT_RESTART_COMMANDS="$WORLD_RULES;/tp 14 68 -18|/tp 14 68 -18;/lab start;/lab pause;/lab movement off;/lab follow off;/lab overlay full;/lab checkpoint load b04-movement;/lab status;/lab movement on;/lab step;/lab movement off;/lab checkpoint save b04-movement-restart;/lab checkpoint load b04-movement-restart;/lab checkpoint status;/tp 18 80 -14 135 24"

printf '\nTest 2: verified movement and late candidate failure.\n'
run_pebble "$MOVEMENT_HOME" "$MOVEMENT_TRACE" \
    "$MOVEMENT_COMMANDS" "-|$MOVEMENT_CAPTURE|-" 46 \
    PebbleLab-Disposable-GateD-B04-Movement 1 after-verified-movement '' ''
require_trace "$MOVEMENT_TRACE" \
    'candidate physical fault seam operation=advanceOneTick point=after-verified-movement mutations=movement-batch' \
    'late fault after verified physical movement'
require_trace "$MOVEMENT_TRACE" \
    'boundaries=movement-batch.*position=.*prev=.*velocity=.*orientation=.*onGround=.*horizontalCollision=.*fallDistance=' \
    'full movement state boundary trace'
require_trace "$MOVEMENT_TRACE" \
    'CANDIDATE_PHYSICAL_ROLLBACK operation=advanceOneTick .*completed=movement-batch.*publishedSession=unchanged publishedSessionTick=0 publishedRecorder=unchanged' \
    'movement compensation and publication rollback'
require_trace "$MOVEMENT_TRACE" \
    'tick=1 movement=on moved=[1-9]' \
    'nominal movement succeeds after compensation'
require_trace "$MOVEMENT_TRACE" \
    'checkpoint loaded name=b04-movement .*restartSafe=1 .*probeReconciliation=reused_exact .*worldMutation=none' \
    'movement checkpoint exact after rollback and nominal retry'
reject_trace "$MOVEMENT_TRACE" \
    'CANDIDATE_PHYSICAL_HARD_FAILURE|movement boundary mismatch|runtimeErrors=[2-9]' \
    'unexpected hard failure, next-tick mismatch, or repeated runtime error'

/usr/bin/python3 - "$MOVEMENT_TRACE" <<'PY'
import re
import sys

text = open(sys.argv[1], encoding="utf-8").read()
fault = next(line for line in text.splitlines() if "candidate physical fault seam" in line)
rollback = next(line for line in text.splitlines() if "CANDIDATE_PHYSICAL_ROLLBACK operation=advanceOneTick" in line)
match = re.search(r"before=\{(agent_[^=]+=\{.*?\})\}:after=", fault)
if match is None or match.group(1) not in rollback:
    raise SystemExit("full pre-movement physical state was not restored in rollback trace")
PY

printf '\nTest 2 restart: exact checkpoint, reconciliation, and nominal movement.\n'
run_pebble "$MOVEMENT_HOME" "$MOVEMENT_RESTART_TRACE" \
    "$MOVEMENT_RESTART_COMMANDS" "-|$MOVEMENT_RESTART_CAPTURE|-" 46 unused 0 '' '' ''
require_trace "$MOVEMENT_RESTART_TRACE" \
    'checkpoint loaded name=b04-movement .*restartSafe=1 .*probeReconciliation=(reused_exact|restored_verified:agent_3) .*worldMutation=none' \
    'separate-process movement checkpoint reconciliation'
require_trace "$MOVEMENT_RESTART_TRACE" \
    'tick=[1-9][0-9]* movement=on moved=[1-9]' \
    'nominal movement after process restart'
require_trace "$MOVEMENT_RESTART_TRACE" \
    'checkpoint loaded name=b04-movement-restart .*restartSafe=1 .*probeReconciliation=reused_exact .*worldMutation=none' \
    'post-restart nominal movement checkpoint exact'
reject_trace "$MOVEMENT_RESTART_TRACE" \
    'movement boundary mismatch|CANDIDATE_PHYSICAL_HARD_FAILURE|runtimeErrors=[1-9]' \
    'movement mismatch or runtime failure after restart'

HARD_COMMANDS="$WORLD_RULES;/tp 14 68 -18|$MOVEMENT_START;/lab step;/lab step;/lab migration admit;/lab checkpoint save forbidden;/lab reset;/lab start;/lab resume;/lab status;/tp 18 80 -14 135 24"
printf '\nTest 3: non-verifiable compensation hard-fails without publication.\n'
run_pebble "$HARD_HOME" "$HARD_TRACE" \
    "$HARD_COMMANDS" "-|$HARD_CAPTURE|-" 46 \
    PebbleLab-Disposable-GateD-B04-Hard-Failure 1 \
    after-verified-movement movement-collision ''
require_trace "$HARD_TRACE" \
    'CANDIDATE_PHYSICAL_HARD_FAILURE operation=advanceOneTick .*mutation=.*movement batch .*expected=\{.*\} observed=\{.*\} attempt=movement-batch.*error=physical=injected compensation collision/non-verifiable restore .*completed=.*remaining=.*publishedSession=unchanged worldTick=[0-9]+ candidateReceipts=.*world=.*session=.*checkpoint=none agent=.*probe=' \
    'complete observable hard-failure diagnostic'
require_trace "$HARD_TRACE" \
    'Step refused after candidate physical hard failure' \
    'normal tick refused after hard failure'
require_trace "$HARD_TRACE" \
    'Command refused after candidate physical hard failure' \
    'other productive commands refused after hard failure'
require_trace "$HARD_TRACE" \
    'Checkpoint operation refused after candidate physical hard failure' \
    'normal checkpoint refused after hard failure'
require_trace "$HARD_TRACE" \
    'Restart refused after candidate physical hard failure' \
    'normal reset refused after hard failure'
require_trace "$HARD_TRACE" \
    'PebbleAgents start refused after candidate physical hard failure' \
    'normal start refused after hard failure'
require_trace "$HARD_TRACE" \
    'Resume refused after candidate physical hard failure' \
    'normal resume refused after hard failure'
reject_trace "$HARD_TRACE" \
    'checkpoint saved name=forbidden|step tick=1|publishedSession=changed' \
    'candidate publication, forbidden checkpoint, or permissive continuation'

for capture in "$SHEARING_CAPTURE" "$RENEWABLE_CAPTURE" "$RENEWABLE_RESTART_CAPTURE" \
    "$MOVEMENT_CAPTURE" "$MOVEMENT_RESTART_CAPTURE" "$HARD_CAPTURE"; do
    [ -s "$capture" ] || fail "capture missing: $capture"
done
/usr/bin/shasum -a 256 "$SHEARING_CAPTURE" "$RENEWABLE_CAPTURE" "$RENEWABLE_RESTART_CAPTURE" \
    "$MOVEMENT_CAPTURE" "$MOVEMENT_RESTART_CAPTURE" "$HARD_CAPTURE" \
    > "$CAPTURE_DIGESTS"

if /usr/bin/pgrep -x Pebble >/dev/null 2>&1 \
    || /usr/bin/pgrep -x pebsmoke >/dev/null 2>&1; then
    fail 'residual Pebble or pebsmoke process after targeted campaign'
fi

{
    printf '{\n'
    printf '  "schemaVersion": 1,\n'
    printf '  "contractID": "GATE-D-BLOCKER-04",\n'
    printf '  "baseline": "%s",\n' "$BASELINE"
    printf '  "evaluation04FailCommit": "%s",\n' "$EVALUATION_04_FAIL"
    printf '  "renewableAcquiredWorldTick": %s,\n' "$ACQUIRED_WORLD_TICK"
    printf '  "failedReceipt": "%s",\n' "$FAILED_RECEIPT"
    printf '  "retryReceipt": "%s",\n' "$RETRY_RECEIPT"
    printf '  "failedReceiptRetained": false,\n'
    printf '  "retryReceiptCount": %s,\n' "$RETRY_RECEIPT_COUNT"
    printf '  "candidateShearingUnavailableLeavesPhysicalStateExact": "PASS",\n'
    printf '  "candidateShearingRegistrationFailureCannotLeakParentMutation": "PASS",\n'
    printf '  "candidateTickFailureAfterVerifiedMovementRestoresAllPhysicalState": "PASS",\n'
    printf '  "renewableWorldAdvanceRemainsExternalAfterCandidateFailure": "PASS",\n'
    printf '  "candidateCompensationCollisionHardFailsWithoutPublication": "PASS",\n'
    printf '  "gateDStatus": "EVALUATED_FAIL_NOT_ACQUIRED",\n'
    printf '  "civ34Status": "NOT_STARTED",\n'
    printf '  "verdict": "BLOCKER_FIX_LOCAL_CANDIDATE"\n'
    printf '}\n'
} > "$SUMMARY_JSON"

/bin/rm -rf "$SHEARING_HOME" "$RENEWABLE_HOME" "$MOVEMENT_HOME" "$HARD_HOME"

printf '\nGATE D BLOCKER 04 REPRODUCED AND FIXED — LOCAL CANDIDATE\n'
printf 'Evidence: %s\n' "$EVIDENCE_ROOT"
printf 'candidateShearingUnavailableLeavesPhysicalStateExact: PASS\n'
printf 'candidateShearingRegistrationFailureCannotLeakParentMutation: PASS\n'
printf 'renewableWorldAdvanceRemainsExternalAfterCandidateFailure: PASS\n'
printf 'candidateTickFailureAfterVerifiedMovementRestoresAllPhysicalState: PASS\n'
printf 'candidateCompensationCollisionHardFailsWithoutPublication: PASS\n'
printf 'abandoned receipt retained: NO\n'
printf 'retry World advance: 0\n'
printf 'movement full-state rollback: exact\n'
printf 'checkpoint/restart/reconciliation: exact\n'
printf 'hard failure continuation: refused\n'
printf 'V4-GATE-D-v1: EVALUATED_FAIL_NOT_ACQUIRED\n'
printf 'CIV-34: NOT_STARTED\n'
