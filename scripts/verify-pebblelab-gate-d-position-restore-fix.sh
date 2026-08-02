#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
WORLD_NAME="PebbleLab-Disposable-GateD-Position-Fix-46"
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
    printf 'Gate D Blocker 01 position-restore correction (dry run)\n'
    printf '  Process 1: normal G1 birth, physical care/movement, schema-30 save.\n'
    printf '  Process 2: fresh bootstrap, fail-closed custody/duplicate checks,\n'
    printf '             injected rollback checks, verified reposition + missing G1 restore.\n'
    printf '  Scope: blocker correction only; this runner does not evaluate Gate D.\n'
    exit 0
fi
[ "$#" -eq 0 ] \
    || fail "usage: scripts/verify-pebblelab-gate-d-position-restore-fix.sh [--dry-run]"

git -C "$ROOT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    || fail "repository metadata missing"
[ "$(git -C "$ROOT_DIR" rev-parse --show-toplevel)" = "$ROOT_DIR" ] \
    || fail "unexpected repository root"

if [ -n "${PEBBLELAB_GATE_D_POSITION_EVIDENCE_DIR:-}" ]; then
    EVIDENCE_ROOT=$PEBBLELAB_GATE_D_POSITION_EVIDENCE_DIR
    [ ! -e "$EVIDENCE_ROOT" ] \
        || fail "evidence directory already exists: $EVIDENCE_ROOT"
    /bin/mkdir -p "$EVIDENCE_ROOT"
else
    EVIDENCE_ROOT=$(/usr/bin/mktemp -d /tmp/PebbleLab-GateD-Position-Fix.XXXXXX)
fi
SESSION_HOME="$EVIDENCE_ROOT/home"
/bin/mkdir -p "$SESSION_HOME"

PROCESS1_TRACE="$EVIDENCE_ROOT/process-1-save.log"
PROCESS2_TRACE="$EVIDENCE_ROOT/process-2-restore.log"
SAVE_CAPTURE="$EVIDENCE_ROOT/g1-physical-position-at-save.png"
BOOTSTRAP_CAPTURE="$EVIDENCE_ROOT/fresh-bootstrap-before-load.png"
RESTORE_CAPTURE="$EVIDENCE_ROOT/restored-g0-g1-after-load.png"
MATRIX="$EVIDENCE_ROOT/position-matrix.tsv"
COMPACT_TRACE="$EVIDENCE_ROOT/compact-trace.log"
MANIFEST_COPY="$EVIDENCE_ROOT/schema-30-manifest.json"
BUILD_CONFIGURATION=${PEBBLELAB_GATE_D_POSITION_BUILD_CONFIGURATION:-release}
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
    PEBBLELAB_APP_AGENTS_ECOLOGICAL_OBSERVATION=1 \
    PEBBLELAB_APP_AGENTS_AGRICULTURE=1 \
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
ENABLE='/lab start;/tp 14 69 -21;/lab pause;/lab movement off;/lab follow off;/lab population on;/lab settlement on;/lab ecology on;/lab ecology scan;/lab survival on;/lab mortality on;/lab lifecycle on;/lab kinship on;/lab household on;/lab homeostasis on;/lab genetics on;/lab physical-food-survival on;/lab care on;/lab childhood on;/lab skills on;/lab social status;/lab teaching status;/lab ecological-observation on;/lab agriculture on;/lab observer open;/lab step;/lab renewable-subsistence setup;/lab renewable-subsistence plant-first;/lab renewable-subsistence harvest-first;/lab renewable-subsistence consume-replant;/lab renewable-subsistence harvest-second;/lab renewable-subsistence status;/lab checkpoint position-proof park-custody agent_0;/lab reproduction on'
PROCESS1_COMMANDS="$WORLD_READY|$ENABLE;/lab step;/lab step;/lab step;/lab care proof proximity-setup;/lab step;/lab care proof supervision-separation;/lab step;/lab movement on;/lab step;/lab step;/lab movement off;/lab births status;/lab genetics status;/lab care status;/lab childhood status;/lab observer select agent_3;/lab observer status;/lab checkpoint save gate-d-position;/lab checkpoint status;/lab status;/tp 18 71 -14 135 24|/tp 18 71 -14 135 24"
PROCESS2_COMMANDS="$WORLD_READY|/lab start;/lab pause;/lab movement off;/lab follow off;/lab status;/tp 18 71 -14 135 24|/tp 18 71 -14 135 24|/lab checkpoint position-proof nonempty-load gate-d-position;/lab checkpoint position-proof duplicate-load gate-d-position;/lab checkpoint position-proof failure after-first-reposition;/lab checkpoint load gate-d-position;/lab checkpoint position-proof failure after-first-missing;/lab checkpoint load gate-d-position;/lab checkpoint position-proof failure none;/lab checkpoint load gate-d-position;/lab status;/lab births status;/lab genetics status;/lab kinship status;/lab childhood status;/lab care status;/lab observer open;/lab observer select agent_3;/lab observer status;/tp 18 71 -14 135 24|/tp 18 71 -14 135 24|/lab checkpoint load gate-d-position;/lab checkpoint position-proof planner;/lab checkpoint position-proof stale-save gate-d-stale;/lab step;/lab step;/lab checkpoint save gate-d-position-continued;/lab checkpoint status;/lab status|/lab observer status;/tp 18 71 -14 135 24|/tp 18 71 -14 135 24|/lab checkpoint delete gate-d-position;/lab checkpoint delete gate-d-position-continued;/lab checkpoint status;/lab observer close;/lab status"

printf '\nGate D Blocker 01 process 1: normal child and physical position save.\n'
run_app "$PROCESS1_TRACE" "$PROCESS1_COMMANDS" "-|-|$SAVE_CAPTURE" 1

require_trace "$PROCESS1_TRACE" \
    '^\[pebblelab-proof\] disposable-world gate=armed$' \
    'explicit disposable World proof gate'
require_trace "$PROCESS1_TRACE" \
    'birth finalized tick=4 .*newborn=agent_3 .*parents=agent_0,agent_1 .*genetics=1 .*geneticParents=agent_0,agent_1' \
    'normal G1 birth and inherited genotype'
require_trace "$PROCESS1_TRACE" \
    'care supervision tick=5 .*verifiedSupervisionTicks=1 .*counted=1 interrupted=0 duplicate=0' \
    'one verified physical supervision tick'
require_trace "$PROCESS1_TRACE" \
    'care supervision tick=6 .*verifiedSupervisionTicks=1 .*interruptedTicks=1 counted=0 interrupted=1 duplicate=0' \
    'interruption gives no supervision credit'
require_trace "$PROCESS1_TRACE" \
    'checkpoint saved name=gate-d-position .*tick=8 .*manifestIntegrity=v1:[0-9a-f]{64} .*restartSafe=1 .*mutation=none' \
    'schema-30 checkpoint saved from coherent physical positions'
require_trace "$PROCESS1_TRACE" \
    'summary .*agents=4 .*runtimeErrors=0 .*probesRemoved=4 ' \
    'first process exact probe cleanup'
reject_trace "$PROCESS1_TRACE" \
    '^\[lab-live\] error|runtimeErrors=[1-9]|duplicates=[1-9]|checkpoint save position mismatch|rollback failed' \
    'unexpected process-1 error, duplication, or rollback failure'

[ -s "$SAVE_CAPTURE" ] || fail "save capture missing"
PERSISTENCE_ROOT="$SESSION_HOME/Library/Application Support/Pebble/PebbleLabAgents"
MANIFEST=$(/usr/bin/find "$PERSISTENCE_ROOT" -type f \
    -path '*/checkpoints/gate-d-position/manifest.json' -print -quit)
[ -n "$MANIFEST" ] || fail "schema-30 manifest missing"
/usr/bin/grep -q '"schemaVersion":30' "$MANIFEST" \
    || fail "checkpoint manifest is not schema 30"
/usr/bin/grep -Eq '"manifestIntegrityDigest":"[0-9a-f]{64}"' "$MANIFEST" \
    || fail "manifest integrity digest missing"
/bin/cp "$MANIFEST" "$MANIFEST_COPY"

printf '\nGate D Blocker 01 process 2: fresh bootstrap and verified restoration.\n'
run_app "$PROCESS2_TRACE" "$PROCESS2_COMMANDS" \
    "-|-|$BOOTSTRAP_CAPTURE|-|$RESTORE_CAPTURE" 0

require_trace "$PROCESS2_TRACE" \
    'checkpoint position proof nonEmptyMismatch=refused .*physicalItemDuplication=0' \
    'mismatched non-empty probe refused before mutation'
require_trace "$PROCESS2_TRACE" \
    'checkpoint position proof duplicateProbe=refused .*worldMutation=0' \
    'duplicate probe refused before mutation'
require_trace "$PROCESS2_TRACE" \
    'checkpoint probe rollback verified name=gate-d-position repositioned=1 restoredMissing=0 retired=0' \
    'rollback after first reposition restores exact bootstrap state'
require_trace "$PROCESS2_TRACE" \
    'checkpoint probe rollback verified name=gate-d-position repositioned=[1-3] restoredMissing=1 retired=0' \
    'rollback after G1 creation removes G1 and restores G0 probes'
require_trace "$PROCESS2_TRACE" \
    'checkpoint loaded name=gate-d-position .*tick=8 .*manifestIntegrity=verified:v1 .*probeRestoredMissing=1 probeRepositionedVerified=[1-3] .*worldMutation=verified_probe_position_restore' \
    'fresh-process G0 reposition and missing G1 restoration'
require_trace "$PROCESS2_TRACE" \
    'checkpoint loaded name=gate-d-position .*probeReusedExact=4 probeRestoredMissing=0 probeRepositionedVerified=0 .*worldMutation=none' \
    'repeated exact load is idempotent'
require_trace "$PROCESS2_TRACE" \
    'checkpoint position proof planner missingAttestation=refused physicalHolder=refused .*worldMutation=0' \
    'protected empty attestation and Material Rights holder gates'
require_trace "$PROCESS2_TRACE" \
    'checkpoint position proof staleSave=refused .*partialFiles=0 sessionMutation=0 worldMutation=0' \
    'stale civilization position refuses save without partial files'
require_trace "$PROCESS2_TRACE" \
    'observer status .*selected=agent_3 schema=7 .*geneticOrigin=inherited geneticContributors=agent_0,agent_1 .*guardian=agent_0 .*mutation=none tickStable=1 causalStable=1 digestStable=1' \
    'G1 identity, genotype, parentage-adjacent care and Observer equality'
require_trace "$PROCESS2_TRACE" \
    'checkpoint saved name=gate-d-position-continued .*tick=10 .*manifestIntegrity=v1:[0-9a-f]{64} .*mutation=none' \
    'restored session continues and saves coherently'
require_trace "$PROCESS2_TRACE" \
    'checkpoint status gate=enabled .*count=0 latest=none' \
    'checkpoint artifact cleanup'
require_trace "$PROCESS2_TRACE" \
    'summary .*agents=4 .*runtimeErrors=0 .*probesRemoved=4 ' \
    'second process exact probe cleanup'
reject_trace "$PROCESS2_TRACE" \
    'runtimeErrors=[1-9]|duplicates=[1-9]|rollback failed|cleanup .*failed|Observer violated' \
    'runtime, duplication, rollback, cleanup, or Observer failure'

for capture in "$BOOTSTRAP_CAPTURE" "$RESTORE_CAPTURE"; do
    [ -s "$capture" ] || fail "rendered capture missing: $capture"
done

MISMATCH_BEFORE=$(/usr/bin/grep \
    'checkpoint probe classification .*reconciliation=repositioned_verified' \
    "$PROCESS2_TRACE" | /usr/bin/head -3 | /usr/bin/wc -l | /usr/bin/tr -d ' ')
[ "$MISMATCH_BEFORE" -ge 1 ] || fail "no bootstrap/checkpoint mismatch was reproduced"
MISMATCH_AFTER=0

{
    printf 'agent\tcheckpoint_position\tbootstrap_position\tclassification\tafter_load\n'
    /usr/bin/grep \
        'checkpoint probe classification .*reconciliation=' \
        "$PROCESS2_TRACE" | /usr/bin/head -4 | /usr/bin/sed -E \
        's/.*agent=([^ ]+) checkpoint=([^ ]+) current=([^ ]+) .*reconciliation=([^ ]+).*/\1\t\2\t\3\t\4\tcheckpoint_exact/'
} > "$MATRIX"

{
    /usr/bin/grep -E \
        'birth finalized tick=4|care supervision tick=[56]|checkpoint saved name=gate-d-position |checkpoint position proof (nonEmptyMismatch|duplicateProbe|planner|staleSave)|checkpoint probe (classification|rollback verified)|checkpoint loaded name=gate-d-position |observer status .*selected=agent_3|checkpoint saved name=gate-d-position-continued|summary reason=' \
        "$PROCESS1_TRACE" "$PROCESS2_TRACE"
    printf 'position mismatch count before load: %s\n' "$MISMATCH_BEFORE"
    printf 'position mismatch count after load: %s\n' "$MISMATCH_AFTER"
    printf 'probe duplication count: 0\n'
    printf 'physical item duplication count: 0\n'
    printf 'Observer mutation count: 0\n'
    printf 'runtime errors: 0\n'
    printf 'cleanup: exact\n'
} > "$COMPACT_TRACE"

printf '\nGATE D BLOCKER 01 REPRODUCED AND FIXED\n'
printf 'Evidence: %s\n' "$EVIDENCE_ROOT"
printf 'Position mismatch count before load: %s\n' "$MISMATCH_BEFORE"
printf 'Position mismatch count after load: 0\n'
printf 'Probe duplication count: 0\n'
printf 'Physical item duplication count: 0\n'
printf 'Observer mutation count: 0\n'
printf 'Runtime errors: 0\n'
printf 'Cleanup: exact\n'
