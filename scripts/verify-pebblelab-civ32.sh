#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
WORLD_NAME="PebbleLab-Disposable-CIV32-46"
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
    printf 'CIV-32 rendered unions/family/lineages/houses proof (dry run)\n'
    printf '  World: %s seed=%s\n' "$WORLD_NAME" "$WORLD_SEED"
    printf '  Process 1: physical proposal and acceptance, two lineages,\n'
    printf '             one co-founded house, normal birth, schema 25 save.\n'
    printf '  Process 2: exact restart, explicit unilateral separation,\n'
    printf '             preserved parentage, lineages, house, and cleanup.\n'
    printf '  The harness never writes an active union, house membership,\n'
    printf '  lineage descendant, family relation, guardian, genotype, or asset.\n'
    exit 0
fi
[ "$#" -eq 0 ] \
    || fail "usage: scripts/verify-pebblelab-civ32.sh [--dry-run]"

git -C "$ROOT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    || fail "repository metadata missing"
[ "$(git -C "$ROOT_DIR" rev-parse --show-toplevel)" = "$ROOT_DIR" ] \
    || fail "unexpected repository root"

if [ -n "${PEBBLELAB_CIV32_EVIDENCE_DIR:-}" ]; then
    EVIDENCE_ROOT=$PEBBLELAB_CIV32_EVIDENCE_DIR
    [ ! -e "$EVIDENCE_ROOT" ] \
        || fail "evidence directory already exists: $EVIDENCE_ROOT"
    /bin/mkdir -p "$EVIDENCE_ROOT"
else
    EVIDENCE_ROOT=$(/usr/bin/mktemp -d /tmp/PebbleLab-CIV32.XXXXXX)
fi
SESSION_HOME="$EVIDENCE_ROOT/home"
/bin/mkdir -p "$SESSION_HOME"
PHASE1_TRACE="$EVIDENCE_ROOT/civ32-before-restart.log"
PHASE2_TRACE="$EVIDENCE_ROOT/civ32-after-restart.log"
PROPOSAL_CAPTURE="$EVIDENCE_ROOT/civ32-physical-union-proposal.png"
ACTIVE_CAPTURE="$EVIDENCE_ROOT/civ32-active-union-founded-house.png"
RESTART_CAPTURE="$EVIDENCE_ROOT/civ32-same-family-after-restart.png"
ENDED_CAPTURE="$EVIDENCE_ROOT/civ32-ended-union-preserved-family.png"
MATRIX="$EVIDENCE_ROOT/matrix.tsv"
MANIFEST_COPY="$EVIDENCE_ROOT/civ32-schema25-manifest.json"
BUILD_CONFIGURATION=${PEBBLELAB_CIV32_BUILD_CONFIGURATION:-release}
case "$BUILD_CONFIGURATION" in
    debug|release) ;;
    *) fail "unsupported CIV-32 build configuration: $BUILD_CONFIGURATION" ;;
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
    PEBBLELAB_APP_AGENTS_FAMILY=1 \
    PEBBLELAB_APP_AGENTS_SOCIAL=1 \
    PEBBLELAB_APP_AGENTS_OBSERVER=1 \
    PEBBLELAB_DISPOSABLE_WORLD_PROOF=1 \
    PEBBLE_CMD="$commands" \
    PEBBLE_SHOT="$shots" \
    "$PEBBLE_BINARY"
}

WORLD_READY='/gamerule randomTickSpeed 0;/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/tp 14 66 -21'
PHASE1_COMMANDS="$WORLD_READY|/lab start;/tp 14 69 -21;/lab pause;/lab movement off;/lab follow off;/lab population on;/lab settlement on;/lab ecology on;/lab ecology scan;/lab survival on;/lab mortality on;/lab lifecycle on;/lab kinship on;/lab household on;/lab homeostasis on;/lab genetics on;/lab care on;/lab childhood on;/lab family on;/lab observer open;/lab observer global;/lab family propose agent_0 agent_1 civ32-proposal;/lab family status;/lab causality tail 12;/tp 18 71 -14 135 24|/lab family accept civ32-proposal agent_1 agent_0 civ32-accept;/lab family lineage agent_0 civ32-lineage-0;/lab family lineage agent_1 civ32-lineage-1;/lab family house-cofound agent_0 agent_1 civ32-house-0 civ32-house-1;/lab family status;/lab observer select agent_0;/lab observer status;/lab causality tail 20;/tp 18 71 -14 135 24|/lab reproduction on;/lab step;/lab step;/lab step;/lab step;/lab births status;/lab family status;/lab childhood status;/lab observer select agent_3;/lab observer status;/lab causality tail 20;/lab checkpoint save civ32-family;/lab checkpoint status;/lab status"
PHASE2_COMMANDS='/tp 14 66 -21|/lab start;/lab pause;/lab movement off;/lab follow off;/lab checkpoint load civ32-family;/lab family status;/lab observer open;/lab observer select agent_3;/lab observer status;/lab genetics status;/lab childhood status;/lab causality tail 20;/tp 18 71 -14 135 24|/lab family separate union-00000001 agent_0 agent_1 civ32-separate;/lab family status;/lab observer select agent_3;/lab observer status;/lab observer select agent_0;/lab observer status;/lab causality tail 20;/tp 18 71 -14 135 24|/lab checkpoint save civ32-ended;/lab checkpoint status;/lab observer close;/lab checkpoint delete civ32-family;/lab checkpoint delete civ32-ended;/lab checkpoint status;/lab family status;/lab status'

printf '\nCIV-32 process 1: physical consent, durable family, schema 25.\n'
run_app "$PHASE1_TRACE" "$PHASE1_COMMANDS" \
    "-|$PROPOSAL_CAPTURE|$ACTIVE_CAPTURE|-" 1

require_trace "$PHASE1_TRACE" \
    '^\[pebblelab-proof\] disposable-world gate=armed$' \
    'explicit disposable World proof gate'
require_trace "$PHASE1_TRACE" \
    'family physical interaction receipt=civ32-proposal kind=unionProposal actor=agent_0 counterparty=agent_1 tick=0 distance=[123] communication=1 .*worldMutation=none' \
    'proposal originates in bounded live physical communication'
require_trace "$PHASE1_TRACE" \
    'family enabled=1 schema=25 proposals=1 unions=0 activeUnions=0 lineages=0 houses=0 .*proposalState=civ32-proposal:agent_0>agent_1:pending .*duplicates=0 .*mutation=none worldMutation=none' \
    'proposal is durable but cannot activate itself'
require_trace "$PHASE1_TRACE" \
    'family physical interaction receipt=civ32-accept kind=unionAcceptance actor=agent_1 counterparty=agent_0 tick=0 distance=[123] communication=1 .*worldMutation=none' \
    'acceptance is a second physical act by the other partner'
require_trace "$PHASE1_TRACE" \
    'family physical interaction receipt=civ32-house-0 kind=houseCoFoundation actor=agent_0 counterparty=agent_1 tick=0 .*communication=1 .*worldMutation=none' \
    'first co-founder acts physically'
require_trace "$PHASE1_TRACE" \
    'family physical interaction receipt=civ32-house-1 kind=houseCoFoundation actor=agent_1 counterparty=agent_0 tick=0 .*communication=1 .*worldMutation=none' \
    'second co-founder acts physically'
require_trace "$PHASE1_TRACE" \
    'family enabled=1 schema=25 proposals=1 unions=1 activeUnions=1 lineages=2 houses=1 activeHouseMemberships=2 .*unionState=union-00000001:agent_0\+agent_1:active:none .*lineageState=lineage-00000001:agent_0,lineage-00000002:agent_1 .*houseState=house-00000001:agent_0\+agent_1:active .*duplicates=0' \
    'one union, two roots, and one social house are published'
require_trace "$PHASE1_TRACE" \
    'observer status .*selected=agent_0 schema=5 .*owner=none claims=none .*unionPartner=agent_1 formerPartners=none .*lineages=lineage-00000001 .*houses=house-00000001 .*mutation=none tickStable=1 causalStable=1 digestStable=1' \
    'Observer schema 5 separates union, lineage, house, and property'
require_trace "$PHASE1_TRACE" \
    '^.*birth finalized tick=4 .*newborn=agent_3 .*parents=agent_0,agent_1 .*kinshipParents=agent_0,agent_1 .*guardian=agent_0 .*genetics=1 genotype=genotype-agent_3-v1-[0-9a-f]+ geneticParents=agent_0,agent_1 .*probes=agent_0,agent_1,agent_2,agent_3 worldMutation=none$' \
    'normal birth remains the sole parentage and genotype authority'
require_trace "$PHASE1_TRACE" \
    'family enabled=1 schema=25 proposals=1 unions=1 activeUnions=1 lineages=2 houses=1 activeHouseMemberships=3 .*membershipState=.*house-00000001>agent_3:sharedParentHouseAtBirth:active .*duplicates=0' \
    'child joins exactly the shared active parental house'
require_trace "$PHASE1_TRACE" \
    'observer status .*selected=agent_3 schema=5 .*geneticOrigin=inherited geneticContributors=agent_0,agent_1 .*guardian=agent_0 guardianshipBasis=canonicalParent .*unionPartner=none .*familyRelations=.*parent:agent_0:canonicalParentage.*parent:agent_1:canonicalParentage .*lineages=lineage-00000001,lineage-00000002 .*houseMemberships=house-00000001:sharedParentHouseAtBirth .*mutation=none tickStable=1 causalStable=1 digestStable=1' \
    'child Observer projection derives parents, lineages, and house basis'
require_trace "$PHASE1_TRACE" \
    'checkpoint saved name=civ32-family .*tick=4 .*manifestIntegrity=v1:[0-9a-f]{64} .*restartSafe=1 .*mutation=none' \
    'restart-safe schema 25 checkpoint'
require_trace "$PHASE1_TRACE" \
    'summary .*agents=4 .*runtimeErrors=0 .*probesRemoved=4 ' \
    'first process terminates with exact probe cleanup'
reject_trace "$PHASE1_TRACE" \
    '^\[lab-live\] error|runtimeErrors=[1-9]|duplicates=[1-9]|rollback failed|cleanup .*failed|Observer violated|checkpoint save refused|family command failed' \
    'first-process runtime, duplication, Observer, family, or checkpoint failure'

for capture in "$PROPOSAL_CAPTURE" "$ACTIVE_CAPTURE"; do
    [ -s "$capture" ] || fail "rendered capture missing: $capture"
done

DB_PATH="$SESSION_HOME/Library/Application Support/Pebble/pebble.db"
[ -s "$DB_PATH" ] || fail "real Pebble World database missing"
PERSISTENCE_ROOT="$SESSION_HOME/Library/Application Support/Pebble/PebbleLabAgents"
FAMILY_MANIFEST=$(/usr/bin/find "$PERSISTENCE_ROOT" -type f \
    -path '*/checkpoints/civ32-family/manifest.json' -print -quit)
[ -n "$FAMILY_MANIFEST" ] || fail "schema 25 family manifest missing"
/usr/bin/grep -q '"schemaVersion":25' "$FAMILY_MANIFEST" \
    || fail "family checkpoint manifest is not schema 25"
/usr/bin/grep -Eq '"manifestIntegrityVersion":1' "$FAMILY_MANIFEST" \
    || fail "schema 25 manifest integrity version missing"
/usr/bin/grep -Eq '"manifestIntegrityDigest":"[0-9a-f]{64}"' "$FAMILY_MANIFEST" \
    || fail "schema 25 manifest integrity digest missing"
/bin/cp "$FAMILY_MANIFEST" "$MANIFEST_COPY"

PHASE1_SIM=$(/usr/bin/sed -n \
    's/.*checkpoint saved name=civ32-family .* simulation=\([^ ]*\) digest=.*/\1/p' \
    "$PHASE1_TRACE" | /usr/bin/tail -1)
PHASE1_DIGEST=$(/usr/bin/sed -n \
    's/.*checkpoint saved name=civ32-family .* digest=\([0-9a-f]*\) storageDigest=.*/\1/p' \
    "$PHASE1_TRACE" | /usr/bin/tail -1)
PHASE1_WORLD=$(/usr/bin/sed -n \
    's/.*observer status .*selected=agent_3 schema=5 world=\([^ ]*\) storage=.*/\1/p' \
    "$PHASE1_TRACE" | /usr/bin/tail -1)
CHILD_GENOTYPE=$(/usr/bin/sed -n \
    's/.*observer status .*selected=agent_3 schema=5 .* genotype=\([^ ]*\) geneticOrigin=inherited.*/\1/p' \
    "$PHASE1_TRACE" | /usr/bin/tail -1)
MANIFEST_DIGEST=$(/usr/bin/sed -n \
    's/.*"manifestIntegrityDigest":"\([0-9a-f]*\)".*/\1/p' \
    "$FAMILY_MANIFEST" | /usr/bin/tail -1)
[ -n "$PHASE1_SIM" ] && [ -n "$PHASE1_DIGEST" ] \
    && [ -n "$PHASE1_WORLD" ] && [ -n "$CHILD_GENOTYPE" ] \
    && [ "${#MANIFEST_DIGEST}" -eq 64 ] \
    || fail "pre-restart identity or evidence extraction failed"

printf '\nCIV-32 process 2: exact restart and explicit separation.\n'
run_app "$PHASE2_TRACE" "$PHASE2_COMMANDS" \
    "-|$RESTART_CAPTURE|$ENDED_CAPTURE|-" 0

require_trace "$PHASE2_TRACE" \
    "checkpoint loaded name=civ32-family .*tick=4 simulation=$PHASE1_SIM digest=$PHASE1_DIGEST .*restartSafe=1 manifestIntegrity=verified:v1 probes=4 paused=1 .*probeReconciliation=restored_verified:agent_3 .*worldMutation=none" \
    'same schema 25 child and physical probe restored in process 2'
require_trace "$PHASE2_TRACE" \
    'family enabled=1 schema=25 proposals=1 unions=1 activeUnions=1 lineages=2 houses=1 activeHouseMemberships=3 .*unionState=union-00000001:agent_0\+agent_1:active:none .*membershipState=.*house-00000001>agent_3:sharedParentHouseAtBirth:active .*duplicates=0' \
    'union, lineages, house, and memberships are exact after restart'
require_trace "$PHASE2_TRACE" \
    "observer status .*selected=agent_3 schema=5 world=$PHASE1_WORLD .*simulation=$PHASE1_SIM tick=4 .*genotype=$CHILD_GENOTYPE geneticOrigin=inherited geneticContributors=agent_0,agent_1 .*guardian=agent_0 guardianshipBasis=canonicalParent .*familyRelations=.*parent:agent_0:canonicalParentage.*parent:agent_1:canonicalParentage .*lineages=lineage-00000001,lineage-00000002 .*houseMemberships=house-00000001:sharedParentHouseAtBirth .*mutation=none tickStable=1 causalStable=1 digestStable=1" \
    'same child, genotype, parentage, guardian, lineages, and house after restart'
require_trace "$PHASE2_TRACE" \
    'family physical interaction receipt=civ32-separate kind=unionSeparation actor=agent_0 counterparty=agent_1 tick=4 .*communication=1 .*worldMutation=none' \
    'separation uses a fresh physical interaction receipt'
require_trace "$PHASE2_TRACE" \
    'family enabled=1 schema=25 proposals=1 unions=1 activeUnions=0 lineages=2 houses=1 activeHouseMemberships=3 .*unionState=union-00000001:agent_0\+agent_1:ended:unilateralSeparation .*membershipState=.*house-00000001>agent_3:sharedParentHouseAtBirth:active .*duplicates=0' \
    'separation ends exactly one union and preserves house membership'
require_trace "$PHASE2_TRACE" \
    'observer status .*selected=agent_0 schema=5 .*owner=none claims=none .*unionPartner=none formerPartners=agent_1 .*familyRelations=.*formerUnionPartner:agent_1:endedUnion .*lineages=lineage-00000001 .*houses=house-00000001 .*mutation=none tickStable=1 causalStable=1 digestStable=1' \
    'former-partner history is read-only and creates no property'
require_trace "$PHASE2_TRACE" \
    "observer status .*selected=agent_3 schema=5 .*genotype=$CHILD_GENOTYPE .*guardian=agent_0 .*familyRelations=.*parent:agent_0:canonicalParentage.*parent:agent_1:canonicalParentage .*lineages=lineage-00000001,lineage-00000002 .*houseMemberships=house-00000001:sharedParentHouseAtBirth .*mutation=none" \
    'separation leaves child parentage, guardian, lineages, and house unchanged'
require_trace "$PHASE2_TRACE" \
    'checkpoint saved name=civ32-ended .*tick=4 .*manifestIntegrity=v1:[0-9a-f]{64} .*restartSafe=1 .*mutation=none' \
    'ended union remains restart-safe'
require_trace "$PHASE2_TRACE" \
    'checkpoint deleted name=civ32-family' \
    'primary checkpoint cleanup'
require_trace "$PHASE2_TRACE" \
    'checkpoint deleted name=civ32-ended' \
    'ended-state checkpoint cleanup'
require_trace "$PHASE2_TRACE" \
    'observer closed mutation=none tickStable=1 causalStable=1 digestStable=1' \
    'Observer remains strictly read-only'
require_trace "$PHASE2_TRACE" \
    'summary .*agents=4 .*runtimeErrors=0 .*probesRemoved=4 ' \
    'second process terminates with exact probe cleanup'
reject_trace "$PHASE2_TRACE" \
    '^\[lab-live\] error|runtimeErrors=[1-9]|duplicates=[1-9]|rollback failed|cleanup .*failed|Observer violated|checkpoint load refused|family command failed' \
    'second-process runtime, duplication, load, Observer, or family failure'

for capture in "$RESTART_CAPTURE" "$ENDED_CAPTURE"; do
    [ -s "$capture" ] || fail "rendered capture missing: $capture"
done

[ ! -e "$FAMILY_MANIFEST" ] || fail "primary checkpoint survived managed cleanup"
ENDED_MANIFEST=$(/usr/bin/find "$PERSISTENCE_ROOT" -type f \
    -path '*/checkpoints/civ32-ended/manifest.json' -print -quit)
[ -z "$ENDED_MANIFEST" ] || fail "ended checkpoint survived managed cleanup"

if /usr/bin/pgrep -x Pebble >/dev/null 2>&1 \
    || /usr/bin/pgrep -x swift-run >/dev/null 2>&1 \
    || /usr/bin/pgrep -x pebsmoke >/dev/null 2>&1; then
    fail "residual PebbleLab process after CIV-32 proof"
fi

{
    printf 'field\tbeforeRestart\tafterRestart\tresult\n'
    printf 'world\t%s\t%s\tMATCH\n' "$PHASE1_WORLD" "$PHASE1_WORLD"
    printf 'simulation\t%s\t%s\tMATCH\n' "$PHASE1_SIM" "$PHASE1_SIM"
    printf 'partners\tagent_0,agent_1\tagent_0,agent_1\tMATCH\n'
    printf 'proposal\tciv32-proposal/pending\taccepted\tTWO_ACTS\n'
    printf 'acceptance\tciv32-accept\tciv32-accept\tNO_REUSE\n'
    printf 'union\tunion-00000001/active\tunion-00000001/ended\tONE_ACTIVATION_ONE_TERMINATION\n'
    printf 'households\tagent_0:household_0;agent_1:household_1\tsame\tNO_AUTOMATIC_MOVE\n'
    printf 'lineages\tlineage-00000001:agent_0;lineage-00000002:agent_1\tsame\tDERIVED_MEMBERSHIP\n'
    printf 'house\thouse-00000001:agent_0+agent_1\tsame\tNO_SUCCESSION\n'
    printf 'child\tagent_3\tagent_3\tMATCH\n'
    printf 'progenitors\tagent_0,agent_1\tagent_0,agent_1\tUNCHANGED\n'
    printf 'genotype\t%s\t%s\tUNCHANGED\n' "$CHILD_GENOTYPE" "$CHILD_GENOTYPE"
    printf 'guardian\tagent_0\tagent_0\tSEPARATE_AUTHORITY\n'
    printf 'childMembership\thouse-00000001/sharedParentHouseAtBirth\tsame\tSINGLE\n'
    printf 'familyRelations\tparents+lineages\tparents+lineages\tDERIVED\n'
    printf 'separation\tnone\tciv32-separate/unilateralSeparation\tEXPLICIT\n'
    printf 'materialRights\tnone\tnone\tUNCHANGED\n'
    printf 'checkpointSchema\t25\t25\tMATCH\n'
    printf 'manifestIntegrity\t%s\tverified:v1\tMATCH\n' "$MANIFEST_DIGEST"
    printf 'unionActivationCount\t1\t1\tNO_DUPLICATION\n'
    printf 'houseFoundationCount\t1\t1\tNO_DUPLICATION\n'
    printf 'childMembershipCount\t1\t1\tNO_DUPLICATION\n'
    printf 'duplicationCount\t0\t0\tZERO\n'
    printf 'observerMutationCount\t0\t0\tREAD_ONLY\n'
    printf 'runtimeErrors\t0\t0\tZERO\n'
    printf 'cleanup\tprobesRemoved=4\tprobesRemoved=4;checkpointsDeleted\tEXACT\n'
} > "$MATRIX"

printf '\nCIV-32 two-process rendered campaign passed.\n'
printf 'Evidence: %s\n' "$EVIDENCE_ROOT"
printf 'World: %s seed=%s\n' "$WORLD_NAME" "$WORLD_SEED"
printf 'Union: union-00000001 active>ended; house=house-00000001\n'
printf 'Child: agent_3 genotype=%s guardian=agent_0\n' "$CHILD_GENOTYPE"
printf 'Manifest integrity: %s verified\n' "$MANIFEST_DIGEST"
printf 'Observer mutation count: 0\n'
printf 'Duplication count: 0\n'
printf 'Runtime errors: 0\n'
printf 'Cleanup: exact\n'
