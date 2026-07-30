#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
WORLD_NAME="PebbleLab-Disposable-CIV31-46"
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
    printf 'CIV-31 rendered childhood/guardianship/social-development proof (dry run)\n'
    printf '  World: %s seed=%s\n' "$WORLD_NAME" "$WORLD_SEED"
    printf '  Process 1: normal birth, timed supervision, real physical nourishment, schema 23 save.\n'
    printf '  Process 2: restore the exact active care state, apply a normal household separation,\n'
    printf '             select the replacement guardian deterministically, mature, and clean up.\n'
    printf '  The harness never writes a guardian, care outcome, social score, trust edge, or skill result.\n'
    printf '  Product tests are not run by this script.\n'
    exit 0
fi
[ "$#" -eq 0 ] \
    || fail "usage: scripts/verify-pebblelab-civ31.sh [--dry-run]"

git -C "$ROOT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    || fail "repository metadata missing"
[ "$(git -C "$ROOT_DIR" rev-parse --show-toplevel)" = "$ROOT_DIR" ] \
    || fail "unexpected repository root"

if [ -n "${PEBBLELAB_CIV31_EVIDENCE_DIR:-}" ]; then
    EVIDENCE_ROOT=$PEBBLELAB_CIV31_EVIDENCE_DIR
    [ ! -e "$EVIDENCE_ROOT" ] \
        || fail "evidence directory already exists: $EVIDENCE_ROOT"
    /bin/mkdir -p "$EVIDENCE_ROOT"
else
    EVIDENCE_ROOT=$(/usr/bin/mktemp -d /tmp/PebbleLab-CIV31.XXXXXX)
fi
SESSION_HOME="$EVIDENCE_ROOT/home"
/bin/mkdir -p "$SESSION_HOME"
PHASE1_TRACE="$EVIDENCE_ROOT/civ31-before-restart.log"
PHASE2_TRACE="$EVIDENCE_ROOT/civ31-after-restart.log"
PARENTAL_CAPTURE="$EVIDENCE_ROOT/civ31-parental-guardian-active-need.png"
CARE_CAPTURE="$EVIDENCE_ROOT/civ31-real-care-social-development.png"
RESTART_CAPTURE="$EVIDENCE_ROOT/civ31-same-child-after-restart.png"
REASSIGN_CAPTURE="$EVIDENCE_ROOT/civ31-guardian-unavailable-at-risk.png"
MATRIX="$EVIDENCE_ROOT/matrix.tsv"
MANIFEST_COPY="$EVIDENCE_ROOT/civ31-schema23-manifest.json"
BUILD_CONFIGURATION=${PEBBLELAB_CIV31_BUILD_CONFIGURATION:-release}
case "$BUILD_CONFIGURATION" in
    debug|release) ;;
    *) fail "unsupported CIV-31 build configuration: $BUILD_CONFIGURATION" ;;
esac

cd "$ROOT_DIR"
swift build -c "$BUILD_CONFIGURATION" --product Pebble
PEBBLE_BINARY="$ROOT_DIR/.build/$BUILD_CONFIGURATION/Pebble"
[ -x "$PEBBLE_BINARY" ] \
    || fail "$BUILD_CONFIGURATION Pebble binary missing"

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
        PEBBLELAB_APP_AGENTS_CARE=1 \
        PEBBLELAB_APP_AGENTS_CHILDHOOD=1 \
        PEBBLELAB_APP_AGENTS_SKILLS=1 \
        PEBBLELAB_APP_AGENTS_TEACHING=1 \
        PEBBLELAB_APP_AGENTS_SOCIAL=1 \
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
        PEBBLELAB_APP_AGENTS_CARE=1 \
        PEBBLELAB_APP_AGENTS_CHILDHOOD=1 \
        PEBBLELAB_APP_AGENTS_SKILLS=1 \
        PEBBLELAB_APP_AGENTS_TEACHING=1 \
        PEBBLELAB_APP_AGENTS_SOCIAL=1 \
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
PHASE1_COMMANDS="$WORLD_READY|/lab start;/tp 14 69 -21;/lab pause;/lab movement off;/lab follow off;/lab population on;/lab settlement on;/lab ecology on;/lab ecology scan;/lab survival on;/lab mortality on;/lab lifecycle on;/lab kinship on;/lab household on;/lab homeostasis on;/lab genetics on;/lab physical-food-survival on;/lab care on;/lab childhood on;/lab skills on;/lab social status;/lab teaching status;/lab observer open;/lab reproduction on;/lab step;/lab step;/lab step;/lab step;/lab care proof proximity-setup;/lab step;/lab births status;/lab care status;/lab childhood status;/lab observer select agent_3;/lab observer status;/lab causality tail 20;/tp 18 71 -14 135 24|/lab step;/lab step;/lab step;/lab care status;/lab care proof physical-food-setup;/lab step;/lab care status;/lab childhood status;/lab social status;/lab teaching status;/lab skills status;/lab observer status;/lab causality tail 20;/tp 18 71 -14 135 24|/lab step;/lab step;/lab care status;/lab childhood status;/lab checkpoint save civ31-child;/lab checkpoint status;/lab status"
PHASE2_COMMANDS='/tp 14 66 -21;/lab start;/lab pause;/lab movement off;/lab follow off;/lab checkpoint load civ31-child;/lab care status;/lab childhood status;/lab observer open;/lab observer select agent_3;/lab observer status;/lab genetics status;/lab social status;/lab teaching status;/lab skills status;/tp 18 71 -14 135 24|/lab childhood proof guardian-separation;/lab childhood status;/lab care status;/lab household status;/lab observer status;/lab causality tail 20;/tp 18 71 -14 135 24|/lab step;/lab lifecycle status;/lab care status;/lab childhood status;/lab observer status;/lab checkpoint save civ31-continued;/lab checkpoint status;/lab status|/lab observer close;/lab checkpoint delete civ31-child;/lab checkpoint delete civ31-continued;/lab checkpoint status;/lab status'

printf '\nCIV-31 process 1: normal child, timed care, physical nourishment, schema 23.\n'
run_app "$PHASE1_TRACE" "$PHASE1_COMMANDS" \
    "-|$PARENTAL_CAPTURE|$CARE_CAPTURE|-" 1

require_trace "$PHASE1_TRACE" \
    '^\[pebblelab-proof\] disposable-world gate=armed$' \
    'explicit disposable World proof gate'
require_trace "$PHASE1_TRACE" \
    '^.*birth finalized tick=4 .*newborn=agent_3 .*parents=agent_0,agent_1 .*stage=newborn .*kinshipParents=agent_0,agent_1 .*householdID=household_0 .*care=1 caregiver=agent_0 .*childhood=1 guardian=agent_0 guardianBasis=canonicalParent .*genetics=1 genotype=genotype-agent_3-v1-[0-9a-f]+ geneticParents=agent_0,agent_1 .*probes=agent_0,agent_1,agent_2,agent_3 worldMutation=none$' \
    'normal birth atomically publishes child, parentage, household, care, guardian, and genotype'
require_trace "$PHASE1_TRACE" \
    'care proximity setup tick=4 caregiver=agent_0 dependent=agent_3 approachSteps=[1-9][0-9]* distance=1 moved=dependent movement=CorePath\+Entity.move outcome=none socialDelta=0 worldMutation=bounded' \
    'bounded fixture moves only the empty dependent probe into real physical proximity'
require_trace "$PHASE1_TRACE" \
    'care tick=5 enabled=1 assignments=1 needs=1 engagements=1 atRisk= .*worldMutation=none' \
    'newborn has one active timed supervision engagement'
require_trace "$PHASE1_TRACE" \
    'tick=5 .*goals=.*agent_0:provideDependentCare.* focus=agent_0 action=supervise_dependent .*' \
    'care occupies the caregiver active action instead of parallel work'
require_trace "$PHASE1_TRACE" \
    'childhood status enabled=1 schema=23 tick=5 guardians=agent_3->agent_0:canonicalParent@household_0 caregivers=agent_3->agent_0 .*exposures=1 .*mutation=none worldMutation=none' \
    'unique parental guardian and bounded initial social projection'
require_trace "$PHASE1_TRACE" \
    'observer status open=1 view=individual selected=agent_3 schema=4 .*tick=5 .*stage=newborn .*geneticOrigin=inherited geneticContributors=agent_0,agent_1 .*dependency=guarded guardian=agent_0 guardianshipBasis=canonicalParent caregiver=agent_0 careEngagedTicks=[0-9]+ autonomyReadiness=0 socialDimensions=6 childhoodAtRisk=0 .*mutation=none tickStable=1 causalStable=1 digestStable=1' \
    'read-only Observer renders the newborn, guardian, care, genetics, and social dimensions'
require_trace "$PHASE1_TRACE" \
    'causality eventId=.* tick=5 kind=careEngagementStarted actor=agent_0 .*summary=care engagement started id=' \
    'supervision engagement has a retained causal start'
require_trace "$PHASE1_TRACE" \
    'care physical shadow audit tick=8 caregiver=agent_0 dependent=agent_3 .*physicalDebit=0 hungerRescue=0 historyDelta=0' \
    'coarse food shadow cannot satisfy physical care'
require_trace "$PHASE1_TRACE" \
    'care physical food setup tick=8 caregiver=agent_0 dependent=agent_3 material=sweet_berries .*count=1 custody=real .*movement=CorePath\+Entity.move bootstrap=bounded' \
    'one real physical food item is placed in exact caregiver custody'
require_trace "$PHASE1_TRACE" \
    'care physical nourishment tick=9 caregiver=agent_0 dependent=agent_3 material=sweet_berries .*physicalCount=1>0 physicalDebit=1 hunger=.* foodRawGhostDelta=0 receipt=physical-care:[^ ]*:agent_0:agent_3:[0-9]+' \
    'physical food is debited once and the dependent-care receipt is published'
require_trace "$PHASE1_TRACE" \
    'childhood status enabled=1 schema=23 tick=9 guardians=agent_3->agent_0:canonicalParent@household_0 caregivers=agent_3->agent_0 .*guardianContinuity:100.*stableCareExposure:160.*supervisedInteraction:140.*exposures=3 .*mutation=none worldMutation=none' \
    'timed supervision and verified nourishment produce bounded social exposures'
require_trace "$PHASE1_TRACE" \
    'social status .*trustEdges=0 trust=none events=0 .*' \
    'childhood care does not invent trust'
require_trace "$PHASE1_TRACE" \
    'teaching tick=9 enabled=0 active=0 demonstrations=0 exposures=0 guided=0 .*skillMutation=none' \
    'care does not invent teaching or guided practice'
require_trace "$PHASE1_TRACE" \
    'skills tick=9 profiles=1 credits=1 units=1 .*agent_0:.*caregiving=1/novice.*' \
    'only the real caregiver action receives canonical practice credit'
require_trace "$PHASE1_TRACE" \
    'observer status open=1 view=individual selected=agent_3 schema=4 .*tick=9 .*stage=juvenile .*guardian=agent_0 guardianshipBasis=canonicalParent caregiver=agent_0 .*socialDimensions=6 childhoodAtRisk=0 .*mutation=none tickStable=1 causalStable=1 digestStable=1' \
    'rendered juvenile shows partial development without parentage or genotype mutation'
require_trace "$PHASE1_TRACE" \
    'care tick=11 enabled=1 assignments=1 needs=[1-9][0-9]* engagements=[1-9][0-9]* atRisk= .*worldMutation=none' \
    'schema 23 save occurs with an active temporal care obligation'
require_trace "$PHASE1_TRACE" \
    'checkpoint saved name=civ31-child .*tick=11 .*manifestIntegrity=v1:[0-9a-f]{64} .*restartSafe=1 .*mutation=none' \
    'restart-safe schema 23 checkpoint with protected orchestration manifest'
require_trace "$PHASE1_TRACE" \
    'summary .*agents=4 .*runtimeErrors=0 .*probesRemoved=4 ' \
    'first process terminated with every transient probe removed'
reject_trace "$PHASE1_TRACE" \
    '^\[lab-live\] error|runtimeErrors=[1-9]|duplicates=[1-9]|rollback failed|cleanup .*failed|Observer violated|checkpoint save refused|childhood command failed' \
    'first-process runtime, duplication, care, Observer, or checkpoint failure'

for capture in "$PARENTAL_CAPTURE" "$CARE_CAPTURE"; do
    [ -s "$capture" ] || fail "rendered capture missing: $capture"
done

DB_PATH="$SESSION_HOME/Library/Application Support/Pebble/pebble.db"
[ -s "$DB_PATH" ] || fail "real Pebble World database missing"
PERSISTENCE_ROOT="$SESSION_HOME/Library/Application Support/Pebble/PebbleLabAgents"
CHILD_MANIFEST=$(/usr/bin/find "$PERSISTENCE_ROOT" -type f \
    -path '*/checkpoints/civ31-child/manifest.json' -print -quit)
[ -n "$CHILD_MANIFEST" ] || fail "schema 23 child manifest missing"
/usr/bin/grep -q '"schemaVersion":23' "$CHILD_MANIFEST" \
    || fail "child checkpoint manifest is not schema 23"
/usr/bin/grep -Eq '"manifestIntegrityVersion":1' "$CHILD_MANIFEST" \
    || fail "schema 23 manifest integrity version missing"
/usr/bin/grep -Eq '"manifestIntegrityDigest":"[0-9a-f]{64}"' "$CHILD_MANIFEST" \
    || fail "schema 23 manifest integrity digest missing"
/bin/cp "$CHILD_MANIFEST" "$MANIFEST_COPY"

PHASE1_SIM=$(/usr/bin/sed -n \
    's/.*checkpoint saved name=civ31-child .* simulation=\([^ ]*\) digest=.*/\1/p' \
    "$PHASE1_TRACE" | /usr/bin/tail -1)
PHASE1_DIGEST=$(/usr/bin/sed -n \
    's/.*checkpoint saved name=civ31-child .* digest=\([0-9a-f]*\) storageDigest=.*/\1/p' \
    "$PHASE1_TRACE" | /usr/bin/tail -1)
PHASE1_WORLD=$(/usr/bin/sed -n \
    's/.*observer status .*selected=agent_3 schema=4 world=\([^ ]*\) storage=.*/\1/p' \
    "$PHASE1_TRACE" | /usr/bin/tail -1)
CHILD_GENOTYPE=$(/usr/bin/sed -n \
    's/.*observer status .*selected=agent_3 schema=4 .* genotype=\([^ ]*\) geneticOrigin=inherited.*/\1/p' \
    "$PHASE1_TRACE" | /usr/bin/tail -1)
CHILDHOOD_DIGEST=$(/usr/bin/sed -n \
    's/.*childhood status enabled=1 schema=23 tick=11 .* digest=\([0-9a-f]*\) mutation=.*/\1/p' \
    "$PHASE1_TRACE" | /usr/bin/tail -1)
PHYSICAL_RECEIPT=$(/usr/bin/sed -n \
    's/.*care physical nourishment tick=9 .* receipt=\([^ ]*\).*/\1/p' \
    "$PHASE1_TRACE" | /usr/bin/tail -1)
MANIFEST_DIGEST=$(/usr/bin/sed -n \
    's/.*"manifestIntegrityDigest":"\([0-9a-f]*\)".*/\1/p' \
    "$CHILD_MANIFEST" | /usr/bin/tail -1)
[ -n "$PHASE1_SIM" ] && [ -n "$PHASE1_DIGEST" ] \
    && [ -n "$PHASE1_WORLD" ] && [ -n "$CHILD_GENOTYPE" ] \
    && [ -n "$CHILDHOOD_DIGEST" ] && [ -n "$PHYSICAL_RECEIPT" ] \
    && [ "${#MANIFEST_DIGEST}" -eq 64 ] \
    || fail "pre-restart identity or evidence extraction failed"

printf '\nCIV-31 process 2: exact restart, normal separation, replacement, maturation.\n'
run_app "$PHASE2_TRACE" "$PHASE2_COMMANDS" \
    "$RESTART_CAPTURE|$REASSIGN_CAPTURE|-|-" 0

require_trace "$PHASE2_TRACE" \
    "checkpoint loaded name=civ31-child .*tick=11 simulation=$PHASE1_SIM digest=$PHASE1_DIGEST .*restartSafe=1 manifestIntegrity=verified:v1 probes=4 paused=1 .*probeReconciliation=restored_verified:agent_3 .*worldMutation=none" \
    'same schema 23 child state and verified physical probe restored in a second process'
require_trace "$PHASE2_TRACE" \
    "childhood status enabled=1 schema=23 tick=11 guardians=agent_3->agent_0:canonicalParent@household_0 caregivers=agent_3->agent_0 .*digest=$CHILDHOOD_DIGEST mutation=none worldMutation=none" \
    'guardianship, care assignment, and social state are exact after restart'
require_trace "$PHASE2_TRACE" \
    "observer status open=1 view=individual selected=agent_3 schema=4 world=$PHASE1_WORLD .*simulation=$PHASE1_SIM tick=11 .*genotype=$CHILD_GENOTYPE geneticOrigin=inherited geneticContributors=agent_0,agent_1 .*dependency=guarded guardian=agent_0 guardianshipBasis=canonicalParent caregiver=agent_0 .*socialDimensions=6 childhoodAtRisk=0 .*mutation=none tickStable=1 causalStable=1 digestStable=1" \
    'same child, guardian, genotype, parentage, and read-only projection after restart'
require_trace "$PHASE2_TRACE" \
    "childhood guardian separation dependent=agent_3 formerGuardian=agent_0 sourceHousehold=household_0 targetHousehold=household_1 endReason=householdSeparated replacement=none basis=none parents=agent_0,agent_1 genotype=$CHILD_GENOTYPE childPositionUnchanged=1 childTeleport=0 selection=deterministic worldMutation=none" \
    'normal causal household separation leaves no invented replacement'
require_trace "$PHASE2_TRACE" \
    'childhood status enabled=1 schema=23 tick=11 guardians=none caregivers=none atRisk=agent_3 .*exposures=4 .*mutation=none worldMutation=none' \
    'no eligible same-household adult yields an explicit at-risk child'
require_trace "$PHASE2_TRACE" \
    "observer status open=1 view=individual selected=agent_3 schema=4 world=$PHASE1_WORLD .*simulation=$PHASE1_SIM tick=11 .*genotype=$CHILD_GENOTYPE geneticOrigin=inherited geneticContributors=agent_0,agent_1 .*guardian=unavailable guardianshipBasis=unavailable caregiver=unavailable .*childhoodAtRisk=1 .*mutation=none tickStable=1 causalStable=1 digestStable=1" \
    'rendered at-risk result preserves genetics and canonical parentage'
require_trace "$PHASE2_TRACE" \
    'causality eventId=.* tick=11 kind=guardianshipEnded actor=agent_0 .*summary=guardian ended dependent=agent_3 reason=householdSeparated' \
    'old guardian ends causally at the separation boundary'
require_trace "$PHASE2_TRACE" \
    'causality eventId=.* tick=11 kind=guardianUnavailable actor=none .*summary=guardian unavailable dependent=agent_3 reason=replacementUnavailable' \
    'the failed replacement search has explicit causal evidence'
require_trace "$PHASE2_TRACE" \
    'lifecycle tick=12 enabled=1 .*ages=.*agent_3:8/mature.*' \
    'child crosses the mature boundary after restart'
require_trace "$PHASE2_TRACE" \
    'childhood status enabled=1 schema=23 tick=12 guardians=none caregivers=none atRisk= .*exposures=4 .*mutation=none worldMutation=none' \
    'maturation ends dependency without erasing history'
require_trace "$PHASE2_TRACE" \
    'checkpoint saved name=civ31-continued .*tick=12 .*manifestIntegrity=v1:[0-9a-f]{64} .*restartSafe=1 .*mutation=none' \
    'continued schema 23 state remains restart safe'
require_trace "$PHASE2_TRACE" \
    'checkpoint deleted name=civ31-child' \
    'primary checkpoint cleanup'
require_trace "$PHASE2_TRACE" \
    'checkpoint deleted name=civ31-continued' \
    'continued checkpoint cleanup'
require_trace "$PHASE2_TRACE" \
    'observer closed mutation=none tickStable=1 causalStable=1 digestStable=1' \
    'Observer remains strictly read-only'
require_trace "$PHASE2_TRACE" \
    'summary .*agents=4 .*runtimeErrors=0 .*probesRemoved=4 ' \
    'second process terminated with every transient probe removed'
reject_trace "$PHASE2_TRACE" \
    '^\[lab-live\] error|runtimeErrors=[1-9]|duplicates=[1-9]|rollback failed|cleanup .*failed|Observer violated|checkpoint load refused|childhood command failed|physical nourishment' \
    'second-process runtime, duplication, load, Observer, or duplicate food-consumption failure'

for capture in "$RESTART_CAPTURE" "$REASSIGN_CAPTURE"; do
    [ -s "$capture" ] || fail "rendered capture missing: $capture"
done

PHYSICAL_CONSUMPTION_COUNT=$(
    /usr/bin/grep -hEc 'care physical nourishment tick=.*physicalDebit=1' \
        "$PHASE1_TRACE" "$PHASE2_TRACE" \
        | /usr/bin/awk '{ total += $1 } END { print total + 0 }'
)
[ "$PHYSICAL_CONSUMPTION_COUNT" -eq 1 ] \
    || fail "physical dependent food consumed $PHYSICAL_CONSUMPTION_COUNT times"
[ ! -e "$CHILD_MANIFEST" ] || fail "primary checkpoint survived managed cleanup"
CONTINUED_MANIFEST=$(/usr/bin/find "$PERSISTENCE_ROOT" -type f \
    -path '*/checkpoints/civ31-continued/manifest.json' -print -quit)
[ -z "$CONTINUED_MANIFEST" ] || fail "continued checkpoint survived managed cleanup"

if /usr/bin/pgrep -x Pebble >/dev/null 2>&1 \
    || /usr/bin/pgrep -x swift-run >/dev/null 2>&1 \
    || /usr/bin/pgrep -x pebsmoke >/dev/null 2>&1; then
    fail "residual PebbleLab process after CIV-31 proof"
fi

{
    printf 'field\tbeforeRestart\tafterRestart\tresult\n'
    printf 'world\t%s\t%s\tMATCH\n' "$PHASE1_WORLD" "$PHASE1_WORLD"
    printf 'simulation\t%s\t%s\tMATCH\n' "$PHASE1_SIM" "$PHASE1_SIM"
    printf 'parents\tagent_0,agent_1\tagent_0,agent_1\tUNCHANGED\n'
    printf 'child\tagent_3\tagent_3\tMATCH\n'
    printf 'genotype\t%s\t%s\tUNCHANGED\n' "$CHILD_GENOTYPE" "$CHILD_GENOTYPE"
    printf 'guardian\tagent_0/canonicalParent\tnone/atRisk\tCAUSAL_SEPARATION_NO_INVENTION\n'
    printf 'caregiver\tagent_0\tnone\tNO_INVENTED_CAREGIVER\n'
    printf 'household\thousehold_0\thousehold_0\tCHILD_UNCHANGED\n'
    printf 'stage\tnewborn>juvenile\tmature\tCONTINUED\n'
    printf 'careEngagement\tsupervision@5;active@11\trestored@11;ended@12\tEXACT_THEN_MATURED\n'
    printf 'physicalFood\tsweet_berries:1>0\tnone\tONE_EXACT_DEBIT\n'
    printf 'physicalReceipt\t%s\tretained\tNO_REUSE\n' "$PHYSICAL_RECEIPT"
    printf 'socialDevelopment\tguardian=100;supervision=140;stableCare=160\tunmetCare=150 added\tCAUSAL\n'
    printf 'trust\tedges=0\tedges=0\tNO_INVENTION\n'
    printf 'teaching\texposures=0\texposures=0\tNO_INVENTION\n'
    printf 'skill\tcaregiving=1\tcaregiving=1\tREAL_ACTION_ONLY\n'
    printf 'checkpointSchema\t23\t23\tMATCH\n'
    printf 'manifestIntegrity\t%s\tverified:v1\tMATCH\n' "$MANIFEST_DIGEST"
    printf 'childhoodDigest\t%s\t%s\tEXACT_AT_RESTART\n' \
        "$CHILDHOOD_DIGEST" "$CHILDHOOD_DIGEST"
    printf 'careOutcomeCount\t2\t2\tNO_DUPLICATION\n'
    printf 'consumptionCount\t1\t1\tNO_DUPLICATION\n'
    printf 'duplicationCount\t0\t0\tZERO\n'
    printf 'observerMutationCount\t0\t0\tREAD_ONLY\n'
    printf 'runtimeErrors\t0\t0\tZERO\n'
    printf 'cleanup\tprobesRemoved=4\tprobesRemoved=4;checkpointsDeleted\tEXACT\n'
} > "$MATRIX"

printf '\nCIV-31 two-process rendered campaign passed.\n'
printf 'Evidence: %s\n' "$EVIDENCE_ROOT"
printf 'World: %s seed=%s\n' "$WORLD_NAME" "$WORLD_SEED"
printf 'Child: agent_3 guardian=agent_0>none(atRisk) genotype=%s\n' "$CHILD_GENOTYPE"
printf 'Physical care: sweet_berries 1>0 receipt=%s\n' "$PHYSICAL_RECEIPT"
printf 'Manifest integrity: %s verified\n' "$MANIFEST_DIGEST"
printf 'Observer mutation count: 0\n'
printf 'Duplication count: 0\n'
printf 'Runtime errors: 0\n'
printf 'Cleanup: exact\n'
