#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
WORLD_NAME="PebbleLab-Disposable-CIV30-46"
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
    printf 'CIV-30 rendered genetics/development/phenotype proof (dry run)\n'
    printf '  World: %s seed=%s\n' "$WORLD_NAME" "$WORLD_SEED"
    printf '  Process 1: initialize founders, reproduce normally, render inherited child, save schema 22.\n'
    printf '  Process 2: restore the same World/checkpoint, continue development, render again, clean up.\n'
    printf '  No genotype or phenotype result is injected by the harness.\n'
    printf '  Product tests are not run by this script.\n'
    exit 0
fi
[ "$#" -eq 0 ] \
    || fail "usage: scripts/verify-pebblelab-civ30.sh [--dry-run]"

git -C "$ROOT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    || fail "repository metadata missing"
[ "$(git -C "$ROOT_DIR" rev-parse --show-toplevel)" = "$ROOT_DIR" ] \
    || fail "unexpected repository root"

if [ -n "${PEBBLELAB_CIV30_EVIDENCE_DIR:-}" ]; then
    EVIDENCE_ROOT=$PEBBLELAB_CIV30_EVIDENCE_DIR
    [ ! -e "$EVIDENCE_ROOT" ] \
        || fail "evidence directory already exists: $EVIDENCE_ROOT"
    /bin/mkdir -p "$EVIDENCE_ROOT"
else
    EVIDENCE_ROOT=$(/usr/bin/mktemp -d /tmp/PebbleLab-CIV30.XXXXXX)
fi
SESSION_HOME="$EVIDENCE_ROOT/home"
/bin/mkdir -p "$SESSION_HOME"
PHASE1_TRACE="$EVIDENCE_ROOT/civ30-before-restart.log"
PHASE2_TRACE="$EVIDENCE_ROOT/civ30-after-restart.log"
FOUNDER_CAPTURE="$EVIDENCE_ROOT/civ30-founders-before-birth.png"
SECOND_FOUNDER_CAPTURE="$EVIDENCE_ROOT/civ30-second-founder-before-birth.png"
CHILD_CAPTURE="$EVIDENCE_ROOT/civ30-child-inheritance.png"
RESTART_CAPTURE="$EVIDENCE_ROOT/civ30-child-after-restart.png"
MATRIX="$EVIDENCE_ROOT/matrix.tsv"

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
        PEBBLELAB_APP_AGENTS_INTERACT=1 \
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
        PEBBLELAB_APP_AGENTS_OVERLAY=1 \
        PEBBLELAB_APP_AGENTS_TRACE=1 \
        PEBBLELAB_APP_AGENTS_TRACE_EVERY=1 \
        PEBBLELAB_APP_AGENTS_INTERACT=1 \
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

WORLD_READY='/gamerule randomTickSpeed 0;/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/tp 14 66 -21'
PHASE1_COMMANDS="$WORLD_READY|/lab start;/tp 14 69 -21;/lab pause;/lab movement off;/lab follow off;/lab population on;/lab settlement on;/lab ecology on;/lab ecology scan;/lab survival on;/lab mortality on;/lab lifecycle on;/lab kinship on;/lab household on;/lab homeostasis on;/lab genetics on;/lab genetics status;/lab observer open;/lab observer select agent_0;/lab observer status;/tp 18 71 -14 135 24|/lab reproduction on;/lab step;/lab step;/lab lifecycle status;/lab reproduction status;/lab genetics status;/lab observer select agent_1;/lab observer status;/tp 18 71 -14 135 24|/lab step;/lab step;/lab births status;/lab genetics status;/lab observer select agent_3;/lab observer status;/lab checkpoint save civ30-child;/lab checkpoint status;/lab status;/tp 18 71 -14 135 24"
PHASE2_COMMANDS='/tp 14 66 -21;/lab start;/lab pause;/lab movement off;/lab follow off;/lab overlay off;/lab checkpoint load civ30-child;/lab genetics status;/lab births status;/lab observer open;/lab observer select agent_3;/lab observer status;/tp 18 71 -14 135 24|/lab step;/lab step;/lab genetics status;/lab lifecycle status;/lab observer status;/lab checkpoint save civ30-continued;/lab checkpoint status;/lab status;/tp 18 71 -14 135 24|/lab observer close;/lab checkpoint delete civ30-child;/lab checkpoint delete civ30-continued;/lab status'

printf '\nCIV-30 process 1: deterministic founders and normal inherited birth.\n'
run_app "$PHASE1_TRACE" "$PHASE1_COMMANDS" \
    "-|$FOUNDER_CAPTURE|$SECOND_FOUNDER_CAPTURE|$CHILD_CAPTURE" 1

require_trace "$PHASE1_TRACE" \
    '^\[pebblelab-proof\] disposable-world gate=armed$' \
    'explicit disposable World proof gate'
require_trace "$PHASE1_TRACE" \
    'ecology=on tick=0 patches=[12] reads=[0-9]+ duplicateHabitatsDiscarded=[1-9][0-9]* mutation=none' \
    'bounded live habitat scan discarded an overlapping duplicate deterministically'
require_trace "$PHASE1_TRACE" \
    'genetics status enabled=1 schema=22 model=1 tick=0 profiles=3 rows=.*agent_0/founder/.*agent_1/founder/.*agent_2/founder/.*mutation=none' \
    'three deterministic founder genotypes and bounded projections'
require_trace "$PHASE1_TRACE" \
    'observer status open=1 view=individual selected=agent_0 schema=3 .*genotype=genotype-agent_0-v1-[0-9a-f]+ geneticOrigin=founder geneticContributors=agent_0 development=[0-9]+ trajectory=.* phenotype=.* mutation=none tickStable=1 causalStable=1 digestStable=1' \
    'rendered founder genotype/development/phenotype and read-only Observer'
require_trace "$PHASE1_TRACE" \
    'observer status open=1 view=individual selected=agent_1 schema=3 .*genotype=genotype-agent_1-v1-[0-9a-f]+ geneticOrigin=founder geneticContributors=agent_1 development=[0-9]+ trajectory=.* phenotype=.* mutation=none tickStable=1 causalStable=1 digestStable=1' \
    'second rendered founder has a distinct deterministic genotype'
require_trace "$PHASE1_TRACE" \
    'reproduction tick=2 enabled=1 eligible=.* plan=reproduction-plan-00000002-agent_0-agent_1 parents=agent_0,agent_1 created=2 due=4 ' \
    'normal existing reproduction plan with canonical contributors'
require_trace "$PHASE1_TRACE" \
    '^.*birth finalized tick=4 birth=birth-00000001 plan=reproduction-plan-00000002-agent_0-agent_1 newborn=agent_3 ordinal=3 parents=agent_0,agent_1 .*kinship=1 kinshipParents=agent_0,agent_1 .*household=1 .*genetics=1 genotype=genotype-agent_3-v1-[0-9a-f]+ geneticParents=agent_0,agent_1 population=4 nextOrdinal=4 probes=agent_0,agent_1,agent_2,agent_3 worldMutation=none$' \
    'one normal birth atomically publishes parentage and inherited genotype'
require_trace "$PHASE1_TRACE" \
    'genetics status enabled=1 schema=22 model=1 tick=4 profiles=4 rows=.*agent_3/inherited/genotype-agent_3-v1-[0-9a-f]+/agent_0,agent_1/.* transitions=[0-9]+ evicted=[0-9]+ digest=[0-9a-f]+ mutation=none' \
    'child inherited loci and provenance are inspectable'
require_trace "$PHASE1_TRACE" \
    'observer status open=1 view=individual selected=agent_3 schema=3 .*genotype=genotype-agent_3-v1-[0-9a-f]+ geneticOrigin=inherited geneticContributors=agent_0,agent_1 development=[0-9]+ trajectory=.* phenotype=.* mutation=none tickStable=1 causalStable=1 digestStable=1' \
    'rendered child inheritance and strictly read-only Observer'
require_trace "$PHASE1_TRACE" \
    'checkpoint saved name=civ30-child .*tick=4 .*restartSafe=1 .*mutation=none' \
    'restart-safe schema 22 child checkpoint'
require_trace "$PHASE1_TRACE" \
    'summary .*agents=4 .*runtimeErrors=0 .*probesRemoved=4 ' \
    'first process terminated with every transient probe removed'
reject_trace "$PHASE1_TRACE" \
    '^\[lab-live\] error|runtimeErrors=[1-9]|rollback failed|cleanup .*failed|Observer violated|genetics command failed|checkpoint save refused' \
    'first-process runtime, genetics, checkpoint, or read-only failure'
[ -s "$FOUNDER_CAPTURE" ] || fail "founder Observer capture missing"
[ -s "$SECOND_FOUNDER_CAPTURE" ] \
    || fail "second founder Observer capture missing"
[ -s "$CHILD_CAPTURE" ] || fail "child inheritance capture missing"

DB_PATH="$SESSION_HOME/Library/Application Support/Pebble/pebble.db"
[ -s "$DB_PATH" ] || fail "real Pebble World database missing"
PERSISTENCE_ROOT="$SESSION_HOME/Library/Application Support/Pebble/PebbleLabAgents"
CHILD_MANIFEST=$(/usr/bin/find "$PERSISTENCE_ROOT" -type f \
    -path '*/checkpoints/civ30-child/manifest.json' -print -quit)
[ -n "$CHILD_MANIFEST" ] || fail "schema 22 child manifest missing"
/usr/bin/grep -q '"schemaVersion":22' "$CHILD_MANIFEST" \
    || fail "child checkpoint manifest is not schema 22"

PHASE1_SIM=$(/usr/bin/sed -n \
    's/.*checkpoint saved name=civ30-child .* simulation=\([^ ]*\) digest=.*/\1/p' \
    "$PHASE1_TRACE" | /usr/bin/tail -1)
PHASE1_DIGEST=$(/usr/bin/sed -n \
    's/.*checkpoint saved name=civ30-child .* digest=\([0-9a-f]*\) storageDigest=.*/\1/p' \
    "$PHASE1_TRACE" | /usr/bin/tail -1)
PHASE1_WORLD=$(/usr/bin/sed -n \
    's/.*observer status .*selected=agent_3 schema=3 world=\([^ ]*\) storage=.*/\1/p' \
    "$PHASE1_TRACE" | /usr/bin/tail -1)
CHILD_GENOTYPE=$(/usr/bin/sed -n \
    's/.*observer status .*selected=agent_3 schema=3 .* genotype=\([^ ]*\) geneticOrigin=inherited.*/\1/p' \
    "$PHASE1_TRACE" | /usr/bin/tail -1)
CHILD_DEVELOPMENT_BEFORE=$(/usr/bin/sed -n \
    's/.*observer status .*selected=agent_3 schema=3 .* development=\([0-9]*\) trajectory=.*/\1/p' \
    "$PHASE1_TRACE" | /usr/bin/tail -1)
[ -n "$PHASE1_SIM" ] && [ -n "$PHASE1_DIGEST" ] \
    && [ -n "$PHASE1_WORLD" ] && [ -n "$CHILD_GENOTYPE" ] \
    && [ -n "$CHILD_DEVELOPMENT_BEFORE" ] \
    || fail "pre-restart identity extraction failed"

printf '\nCIV-30 process 2: real restart and continued development.\n'
run_app "$PHASE2_TRACE" "$PHASE2_COMMANDS" \
    "-|$RESTART_CAPTURE|-" 0

require_trace "$PHASE2_TRACE" \
    "checkpoint loaded name=civ30-child .*tick=4 simulation=$PHASE1_SIM digest=$PHASE1_DIGEST .*restartSafe=1 probes=4 paused=1 .*probeReconciliation=restored_verified:agent_3 .*worldMutation=none" \
    'same schema 22 child state and verified physical probe restored in a new process'
require_trace "$PHASE2_TRACE" \
    "observer status open=1 view=individual selected=agent_3 schema=3 world=$PHASE1_WORLD .*simulation=$PHASE1_SIM tick=4 .*genotype=$CHILD_GENOTYPE geneticOrigin=inherited geneticContributors=agent_0,agent_1 .*mutation=none tickStable=1 causalStable=1 digestStable=1" \
    'same child genotype and provenance immediately after restart'
require_trace "$PHASE2_TRACE" \
    "genetics status enabled=1 schema=22 model=1 tick=6 profiles=4 rows=.*agent_3/inherited/$CHILD_GENOTYPE/agent_0,agent_1/.* mutation=none" \
    'same inherited genotype after continued simulation'
require_trace "$PHASE2_TRACE" \
    "observer status open=1 view=individual selected=agent_3 schema=3 world=$PHASE1_WORLD .*simulation=$PHASE1_SIM tick=6 .*stage=juvenile .*genotype=$CHILD_GENOTYPE geneticOrigin=inherited geneticContributors=agent_0,agent_1 development=[0-9]+ trajectory=.* phenotype=.*mutation=none tickStable=1 causalStable=1 digestStable=1" \
    'rendered post-restart development, phenotype, and read-only Observer'
require_trace "$PHASE2_TRACE" \
    'checkpoint saved name=civ30-continued .*tick=6 .*restartSafe=1 .*mutation=none' \
    'continued schema 22 checkpoint'
require_trace "$PHASE2_TRACE" \
    'checkpoint deleted name=civ30-child' \
    'child checkpoint proof artifact cleanup'
require_trace "$PHASE2_TRACE" \
    'checkpoint deleted name=civ30-continued' \
    'continued checkpoint proof artifact cleanup'
require_trace "$PHASE2_TRACE" \
    'observer closed mutation=none tickStable=1 causalStable=1 digestStable=1' \
    'Observer close remains read-only'
require_trace "$PHASE2_TRACE" \
    'summary .*agents=4 .*runtimeErrors=0 .*probesRemoved=4 ' \
    'second process terminated with every transient probe removed'
reject_trace "$PHASE2_TRACE" \
    '^\[lab-live\] error|runtimeErrors=[1-9]|duplicates=[1-9]|rollback failed|cleanup .*failed|Observer violated|checkpoint load refused|genetics command failed' \
    'second-process runtime, duplication, checkpoint, or read-only failure'
[ -s "$RESTART_CAPTURE" ] || fail "post-restart child capture missing"

CHILD_GENOTYPE_AFTER=$(/usr/bin/sed -n \
    's/.*observer status .*selected=agent_3 schema=3 .* genotype=\([^ ]*\) geneticOrigin=inherited.*/\1/p' \
    "$PHASE2_TRACE" | /usr/bin/tail -1)
CHILD_DEVELOPMENT_AFTER=$(/usr/bin/sed -n \
    's/.*observer status .*selected=agent_3 schema=3 .* development=\([0-9]*\) trajectory=.*/\1/p' \
    "$PHASE2_TRACE" | /usr/bin/tail -1)
[ "$CHILD_GENOTYPE_AFTER" = "$CHILD_GENOTYPE" ] \
    || fail "child genotype changed across restart"
[ -n "$CHILD_DEVELOPMENT_AFTER" ] \
    && [ "$CHILD_DEVELOPMENT_AFTER" -ge "$CHILD_DEVELOPMENT_BEFORE" ] \
    || fail "child development regressed across restart"

if /usr/bin/pgrep -x Pebble >/dev/null 2>&1 \
    || /usr/bin/pgrep -x swift-run >/dev/null 2>&1 \
    || /usr/bin/pgrep -x pebsmoke >/dev/null 2>&1; then
    fail "residual PebbleLab process after CIV-30 proof"
fi

{
    printf 'field\tbeforeRestart\tafterRestart\tresult\n'
    printf 'world\t%s\t%s\tMATCH\n' "$PHASE1_WORLD" "$PHASE1_WORLD"
    printf 'simulation\t%s\t%s\tMATCH\n' "$PHASE1_SIM" "$PHASE1_SIM"
    printf 'parents\tagent_0,agent_1\tagent_0,agent_1\tMATCH\n'
    printf 'child\tagent_3\tagent_3\tMATCH\n'
    printf 'genotype\t%s\t%s\tMATCH\n' \
        "$CHILD_GENOTYPE" "$CHILD_GENOTYPE_AFTER"
    printf 'development\t%s\t%s\tCONTINUED\n' \
        "$CHILD_DEVELOPMENT_BEFORE" "$CHILD_DEVELOPMENT_AFTER"
    printf 'checkpointSchema\t22\t22\tMATCH\n'
    printf 'attributionCount\t1\t1\tNO_DUPLICATION\n'
    printf 'observerMutationCount\t0\t0\tREAD_ONLY\n'
    printf 'duplicationCount\t0\t0\tZERO\n'
    printf 'runtimeErrors\t0\t0\tZERO\n'
    printf 'cleanup\tprobesRemoved=4\tprobesRemoved=4\tEXACT\n'
} > "$MATRIX"

printf '\nCIV-30 two-process rendered campaign passed.\n'
printf 'Evidence: %s\n' "$EVIDENCE_ROOT"
printf 'World: %s seed=%s\n' "$WORLD_NAME" "$WORLD_SEED"
printf 'Child: agent_3 genotype=%s development=%s>%s\n' \
    "$CHILD_GENOTYPE" "$CHILD_DEVELOPMENT_BEFORE" \
    "$CHILD_DEVELOPMENT_AFTER"
printf 'Observer mutation count: 0\n'
printf 'Duplication count: 0\n'
printf 'Runtime errors: 0\n'
printf 'Cleanup: exact\n'
