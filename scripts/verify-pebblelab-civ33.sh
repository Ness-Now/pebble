#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
WORLD_NAME="PebbleLab-Disposable-CIV33-46"
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
    printf 'CIV-33 rendered estates/inheritance proof (dry run)\n'
    printf '  World: %s seed=%s\n' "$WORLD_NAME" "$WORLD_SEED"
    printf '  Process 1: normal union and child birth; a real agent-held\n'
    printf '             asset; normal homeostatic death; verified custody\n'
    printf '             exit; one estate; rollback proof; schema 28 save.\n'
    printf '  Process 2: exact restart; same open estate; real whole-asset\n'
    printf '             settlement; Observer schema 6; exact cleanup.\n'
    printf '  The harness never writes an estate, beneficiary, owner,\n'
    printf '  custodian, claim, permission, death, or physical receipt.\n'
    exit 0
fi
[ "$#" -eq 0 ] \
    || fail "usage: scripts/verify-pebblelab-civ33.sh [--dry-run]"

git -C "$ROOT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    || fail "repository metadata missing"
[ "$(git -C "$ROOT_DIR" rev-parse --show-toplevel)" = "$ROOT_DIR" ] \
    || fail "unexpected repository root"

if [ -n "${PEBBLELAB_CIV33_EVIDENCE_DIR:-}" ]; then
    EVIDENCE_ROOT=$PEBBLELAB_CIV33_EVIDENCE_DIR
    [ ! -e "$EVIDENCE_ROOT" ] \
        || fail "evidence directory already exists: $EVIDENCE_ROOT"
    /bin/mkdir -p "$EVIDENCE_ROOT"
else
    EVIDENCE_ROOT=$(/usr/bin/mktemp -d /tmp/PebbleLab-CIV33.XXXXXX)
fi
SESSION_HOME="$EVIDENCE_ROOT/home"
/bin/mkdir -p "$SESSION_HOME"
PHASE1_TRACE="$EVIDENCE_ROOT/civ33-before-restart.log"
PHASE2_TRACE="$EVIDENCE_ROOT/civ33-after-restart.log"
PREDEATH_CAPTURE="$EVIDENCE_ROOT/civ33-predeath-physical-asset.png"
OPEN_CAPTURE="$EVIDENCE_ROOT/civ33-open-estate.png"
RESTART_CAPTURE="$EVIDENCE_ROOT/civ33-same-estate-after-restart.png"
SETTLED_CAPTURE="$EVIDENCE_ROOT/civ33-settled-inheritance.png"
MATRIX="$EVIDENCE_ROOT/matrix.tsv"
COMPACT_TRACE="$EVIDENCE_ROOT/civ33-compact-trace.log"
MANIFEST_COPY="$EVIDENCE_ROOT/civ33-schema28-manifest.json"
BUILD_CONFIGURATION=${PEBBLELAB_CIV33_BUILD_CONFIGURATION:-release}
case "$BUILD_CONFIGURATION" in
    debug|release) ;;
    *) fail "unsupported CIV-33 build configuration: $BUILD_CONFIGURATION" ;;
esac

cd "$ROOT_DIR"
swift build -c "$BUILD_CONFIGURATION" --product Pebble
PEBBLE_BINARY="$ROOT_DIR/.build/$BUILD_CONFIGURATION/Pebble"
[ -x "$PEBBLE_BINARY" ] \
    || fail "$BUILD_CONFIGURATION Pebble binary missing"

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
        run_pebble "$commands" "$shots" 2>&1 \
            | /usr/bin/tee "$run_trace"
    else
        CFFIXED_USER_HOME="$SESSION_HOME" \
        PEBBLE_AUTOLOAD=1 \
        run_pebble "$commands" "$shots" 2>&1 \
            | /usr/bin/tee "$run_trace"
    fi
    if /usr/bin/pgrep -x Pebble >/dev/null 2>&1; then
        fail "Pebble process remained after phase: $run_trace"
    fi
}

WORLD_READY='/gamerule randomTickSpeed 0;/gamerule doMobSpawning false;/gamerule doDaylightCycle false;/gamerule doWeatherCycle false;/time set 1000;/weather clear;/tp 14 66 -21'
PHASE1_COMMANDS="$WORLD_READY|/lab start;/tp 14 68 -18;/lab pause;/lab movement off;/lab follow off;/lab overlay full;/lab persistence-reconciliation setup;/lab survival on;/lab population on;/lab settlement on;/lab ecology on;/lab ecology scan;/lab mortality on;/lab lifecycle on;/lab kinship on;/lab household on;/lab physical-food-survival on;/lab homeostasis on;/lab genetics on;/lab care on;/lab childhood on;/lab family on;/lab family propose agent_0 agent_1 civ33-proposal;/lab family accept civ33-proposal agent_1 agent_0 civ33-accept;/lab reproduction on;/lab step;/lab step;/lab step;/lab step;/lab births status;/lab childhood status;/lab family status;/lab care proof proximity-setup;/lab estates on;/lab homeostasis proof estate-setup;/lab estates status;/lab observer open;/lab observer select agent_0;/lab observer status;/tp 18 71 -14 135 24|/lab homeostasis proof estate-advance 18;/lab homeostasis status;/lab estates status;/lab observer select agent_0;/lab observer status;/tp 18 71 -14 135 24|/lab homeostasis proof estate-advance 1;/lab mortality status;/lab estates status;/lab observer global;/lab observer status;/lab causality tail 20;/lab estates accept latest agent_1;/lab estates proof rollback latest next;/lab estates status;/lab checkpoint save civ33-open;/lab checkpoint status;/tp 18 71 -14 135 24|/lab status"
PHASE2_COMMANDS='/tp 14 66 -21|/lab start;/lab pause;/lab movement off;/lab follow off;/lab overlay full;/lab checkpoint load civ33-open;/lab persistence-reconciliation status;/lab estates status;/lab observer open;/lab observer global;/lab observer status;/lab causality tail 20;/tp 18 71 -14 135 24|/lab estates settle latest next;/lab estates status;/lab persistence-reconciliation status;/lab observer select agent_1;/lab observer status;/lab causality tail 20;/lab observer global;/tp 18 71 -14 135 24|/lab checkpoint save civ33-settled;/lab checkpoint status;/lab observer close;/lab estates proof cleanup;/lab checkpoint delete civ33-open;/lab checkpoint delete civ33-settled;/lab checkpoint status;/lab estates status;/lab status'

printf '\nCIV-33 process 1: normal birth, death, physical exit, and open estate.\n'
run_app "$PHASE1_TRACE" "$PHASE1_COMMANDS" \
    "-|$PREDEATH_CAPTURE|-|$OPEN_CAPTURE" 1

require_trace "$PHASE1_TRACE" \
    '^\[pebblelab-proof\] disposable-world gate=armed$' \
    'explicit disposable World proof gate'
require_trace "$PHASE1_TRACE" \
    '^.*birth finalized tick=4 .*newborn=agent_3 .*parents=agent_0,agent_1 .*kinshipParents=agent_0,agent_1 .*guardian=agent_0 .*genetics=1 genotype=genotype-agent_3-v1-[0-9a-f]+ geneticParents=agent_0,agent_1 .*probes=agent_0,agent_1,agent_2,agent_3 worldMutation=none$' \
    'normal birth remains the child, parentage, guardian, and genotype authority'
require_trace "$PHASE1_TRACE" \
    'estate proof setup decedent=agent_0 asset=asset:civ27:live-pickaxe physicalItem=iron_pickaxe:1 holder=agent:agent_0 custodian=agent_1 owner=agent_0 .*worldMutation=physicalCustodyOnly' \
    'real registered asset is physically held by its living owner'
require_trace "$PHASE1_TRACE" \
    'estate proof advance ticks=18 tick=4>22 fedAgents=agent_1,agent_2 deprivedAgent=agent_0 dependentMeals=[1-9][0-9]* decedent=agent_0 vital=incapacitated health=[1-9][0-9]* deaths=0>0 estate=none .*holder=agent:agent_0 owner=agent_0 physicalQuantity=1 activeAgents=4 probes=4 runtimeErrors=0' \
    'normal physiology reaches incapacity without premature death or estate'
require_trace "$PHASE1_TRACE" \
    'mortality physical custody tick=23 agent=agent_0 kind=transferred trackedAssets=asset:civ27:live-pickaxe physicalStacks=.*iron_pickaxe:1.*receipt=.* destination=container:.* probeEmpty=1 socialRecordsInvented=0' \
    'verified complete physical custody exit precedes social estate opening'
require_trace "$PHASE1_TRACE" \
    'mortality material exit tick=23 agent=agent_0 .*assets=asset:civ27:live-pickaxe holderBefore=agent:agent_0 holderAfter=container:.* quantity=1>1 receipt=.*socialRoles=unchanged inheritance=none' \
    'physical identity and quantity are conserved through terminal exit'
require_trace "$PHASE1_TRACE" \
    'estate proof advance ticks=1 tick=22>23 .*deprivedAgent=agent_0 .*vital=dead health=0 deaths=0>1 estate=estate-[^ ]+ estateStatus=openUnadministered tier=primaryPartnerAndChildren administrator=agent_1 holder=container:.* owner=agent_0 physicalQuantity=1 activeAgents=3 probes=3 runtimeErrors=0' \
    'normal homeostatic death opens exactly one primary-tier estate'
require_trace "$PHASE1_TRACE" \
    'estates schema=28 enabled=1 .*count=1 retained=1 settlements=0 .*decedent=agent_0 .*status=openUnadministered tier=primaryPartnerAndChildren beneficiaries=.*agent_1:activeUnionPartnerAtDeath.*agent_3:canonicalChild.*successorPlanVersion=1 successorPlanDigest=[0-9a-f]{16} successorPlanRows=[1-9][0-9]* successorPlanEvent=.*administrator=none administrationStatus=nominated .*physical=transferred .*physicalStacks=1 physicalItems=1 assets=.*asset:civ27:live-pickaxe~iron_pickaxe:1~container:.*~agent_0~agent_1~agent_1~pendingSettlement~none~container:.*~agent_0~agent_1~none duplicateEstateIDs=0' \
    'estate separates successor owner assignment from pending physical custody'
require_trace "$PHASE1_TRACE" \
    'estate administration accepted estate=estate-[^ ]+ administrator=agent_1 count=1' \
    'nominated administrator explicitly accepts once'
require_trace "$PHASE1_TRACE" \
    'estate settlement rollback lateFailure=verified session=exact estate=exact materialRights=exact source=restored destination=restored replay=unchanged' \
    'late physical settlement failure restores all authorities exactly'
require_trace "$PHASE1_TRACE" \
    'estates schema=28 enabled=1 .*status=openAdministered .*successorPlanVersion=1 successorPlanDigest=[0-9a-f]{16} .*administrator=agent_1 administrationStatus=active acceptance=estate-accept:.*assets=.*pendingSettlement.*duplicateEstateIDs=0' \
    'accepted estate remains open and physically unsettled after rollback'
require_trace "$PHASE1_TRACE" \
    'checkpoint saved name=civ33-open .*tick=23 .*manifestIntegrity=v1:[0-9a-f]{64} .*restartSafe=1 .*mutation=none' \
    'restart-safe schema 28 open-estate checkpoint'
require_trace "$PHASE1_TRACE" \
    'observer status .*schema=6 .*estate=estate-[^ ]+ estateStatus=openUnadministered .*estateTier=primaryPartnerAndChildren estateAssets=1 estateSettledAssets=0 .*mutation=none tickStable=1 causalStable=1 digestStable=1' \
    'Observer schema 6 projects estate authority read-only'
require_trace "$PHASE1_TRACE" \
    'summary .*agents=3 .*runtimeErrors=0 .*probesRemoved=3 ' \
    'first process terminates with exact live-probe cleanup'
reject_trace "$PHASE1_TRACE" \
    '^\[lab-live\] error|runtimeErrors=[1-9]|duplicateEstateIDs=[1-9]|rollback failed|cleanup .*failed|Observer violated|checkpoint save refused|Estate boundary refused|Homeostasis command failed' \
    'first-process runtime, duplication, rollback, Observer, or save failure'

for capture in "$PREDEATH_CAPTURE" "$OPEN_CAPTURE"; do
    [ -s "$capture" ] || fail "rendered capture missing: $capture"
done

DB_PATH="$SESSION_HOME/Library/Application Support/Pebble/pebble.db"
[ -s "$DB_PATH" ] || fail "real Pebble World database missing"
PERSISTENCE_ROOT="$SESSION_HOME/Library/Application Support/Pebble/PebbleLabAgents"
OPEN_MANIFEST=$(/usr/bin/find "$PERSISTENCE_ROOT" -type f \
    -path '*/checkpoints/civ33-open/manifest.json' -print -quit)
[ -n "$OPEN_MANIFEST" ] || fail "schema 28 open-estate manifest missing"
/usr/bin/grep -q '"schemaVersion":28' "$OPEN_MANIFEST" \
    || fail "open-estate checkpoint manifest is not schema 28"
/usr/bin/grep -Eq '"manifestIntegrityVersion":1' "$OPEN_MANIFEST" \
    || fail "schema 28 manifest integrity version missing"
/usr/bin/grep -Eq '"manifestIntegrityDigest":"[0-9a-f]{64}"' "$OPEN_MANIFEST" \
    || fail "schema 28 manifest integrity digest missing"
/bin/cp "$OPEN_MANIFEST" "$MANIFEST_COPY"

PHASE1_SIM=$(/usr/bin/sed -n \
    's/.*checkpoint saved name=civ33-open .* simulation=\([^ ]*\) digest=.*/\1/p' \
    "$PHASE1_TRACE" | /usr/bin/tail -1)
PHASE1_DIGEST=$(/usr/bin/sed -n \
    's/.*checkpoint saved name=civ33-open .* digest=\([0-9a-f]*\) storageDigest=.*/\1/p' \
    "$PHASE1_TRACE" | /usr/bin/tail -1)
PHASE1_WORLD=$(/usr/bin/sed -n \
    's/.*observer status .*schema=6 world=\([^ ]*\) storage=.*/\1/p' \
    "$PHASE1_TRACE" | /usr/bin/tail -1)
ESTATE_ID=$(/usr/bin/sed -n \
    's/.*estates schema=28 .* latest=\([^ ]*\) decedent=agent_0.*/\1/p' \
    "$PHASE1_TRACE" | /usr/bin/tail -1)
MANIFEST_DIGEST=$(/usr/bin/sed -n \
    's/.*"manifestIntegrityDigest":"\([0-9a-f]*\)".*/\1/p' \
    "$OPEN_MANIFEST" | /usr/bin/tail -1)
[ -n "$PHASE1_SIM" ] && [ -n "$PHASE1_DIGEST" ] \
    && [ -n "$PHASE1_WORLD" ] && [ -n "$ESTATE_ID" ] \
    && [ "${#MANIFEST_DIGEST}" -eq 64 ] \
    || fail "pre-restart identity or manifest evidence extraction failed"

printf '\nCIV-33 process 2: exact restart and physical inheritance settlement.\n'
run_app "$PHASE2_TRACE" "$PHASE2_COMMANDS" \
    "-|$RESTART_CAPTURE|$SETTLED_CAPTURE|-" 0

require_trace "$PHASE2_TRACE" \
    "checkpoint loaded name=civ33-open .*tick=23 simulation=$PHASE1_SIM digest=$PHASE1_DIGEST .*restartSafe=1 manifestIntegrity=verified:v1 probes=3 paused=1 .*probeReconciliation=retired_verified:agent_0 probeRetired=agent_0 probeRestored=agent_3 physicalReconciliation=applied:matched worldMutation=none" \
    'same schema 28 open estate and child probe restored in process 2'
require_trace "$PHASE2_TRACE" \
    "estates schema=28 enabled=1 .*count=1 retained=1 settlements=0 latest=$ESTATE_ID decedent=agent_0 .*status=openAdministered tier=primaryPartnerAndChildren .*successorPlanVersion=1 successorPlanDigest=[0-9a-f]{16} .*administrator=agent_1 administrationStatus=active .*assets=.*pendingSettlement.*container:.*~agent_0~agent_1~none duplicateEstateIDs=0" \
    'same unsettled estate, beneficiary plan, and rights after restart'
require_trace "$PHASE2_TRACE" \
    'observer status .*schema=6 .*estate=estate-[^ ]+ estateStatus=openAdministered estateAdministrator=agent_1 estateTier=primaryPartnerAndChildren estateAssets=1 estateSettledAssets=0 .*mutation=none tickStable=1 causalStable=1 digestStable=1' \
    'same open estate is read-only after restart'
require_trace "$PHASE2_TRACE" \
    "estate asset settled estate=$ESTATE_ID entry=[^ ]+ status=transferred beneficiary=agent_1 custodian=agent_1 receipt=estate-settle:" \
    'one whole asset is physically transferred through the Pebble adapter'
require_trace "$PHASE2_TRACE" \
    "estates schema=28 enabled=1 .*count=1 retained=1 settlements=1 latest=$ESTATE_ID .*status=settled tier=primaryPartnerAndChildren .*successorPlanVersion=1 successorPlanDigest=[0-9a-f]{16} .*administrator=none administrationStatus=ended .*assets=.*~agent_1~transferred~none~agent:agent_1~agent_1~none~estate-settle:.*duplicateEstateIDs=0" \
    'settlement publishes the intended custodian, direct adult holder/owner, and terminal estate once'
require_trace "$PHASE2_TRACE" \
    'persistence reconciliation status enabled=1 .*outcome=matched asset=asset:civ27:live-pickaxe holder=agent:agent_1 .*owner=agent_1 .*duplicates=0' \
    'Material Rights and physical reconciliation agree on the successor'
require_trace "$PHASE2_TRACE" \
    'observer status .*selected=agent_1 schema=6 .*holder=agent:agent_1 custodian=none owner=agent_1 .*estate=estate-[^ ]+ estateStatus=settled .*estateSettledAssets=1 .*mutation=none tickStable=1 causalStable=1 digestStable=1' \
    'Observer shows inherited ownership without mutation'
require_trace "$PHASE2_TRACE" \
    'checkpoint saved name=civ33-settled .*tick=23 .*manifestIntegrity=v1:[0-9a-f]{64} .*restartSafe=1 .*mutation=none' \
    'settled estate remains checkpoint-valid'
require_trace "$PHASE2_TRACE" \
    'observer closed mutation=none tickStable=1 causalStable=1 digestStable=1' \
    'Observer remains strictly read-only'
require_trace "$PHASE2_TRACE" \
    'estate proof cleanup world=exact trackedAssetRemoved=1 fixtureContainerRemoved=1 untrackedItemsRemoved=0 session=unchanged probes=3 duplicates=0' \
    'settled physical asset and reconciliation fixture are cleaned exactly'
require_trace "$PHASE2_TRACE" \
    'checkpoint deleted name=civ33-open' \
    'open-estate checkpoint cleanup'
require_trace "$PHASE2_TRACE" \
    'checkpoint deleted name=civ33-settled' \
    'settled-estate checkpoint cleanup'
require_trace "$PHASE2_TRACE" \
    'summary .*agents=3 .*runtimeErrors=0 .*probesRemoved=3 ' \
    'second process terminates with exact probe cleanup'
reject_trace "$PHASE2_TRACE" \
    '^\[lab-live\] error|runtimeErrors=[1-9]|duplicateEstateIDs=[1-9]|rollback failed|cleanup .*failed|Observer violated|checkpoint load refused|checkpoint save refused|Estate boundary refused' \
    'second-process runtime, duplication, load, settlement, Observer, or cleanup failure'

for capture in "$RESTART_CAPTURE" "$SETTLED_CAPTURE"; do
    [ -s "$capture" ] || fail "rendered capture missing: $capture"
done

[ ! -e "$OPEN_MANIFEST" ] || fail "open-estate checkpoint survived cleanup"
SETTLED_MANIFEST=$(/usr/bin/find "$PERSISTENCE_ROOT" -type f \
    -path '*/checkpoints/civ33-settled/manifest.json' -print -quit)
[ -z "$SETTLED_MANIFEST" ] \
    || fail "settled-estate checkpoint survived cleanup"

if /usr/bin/pgrep -x Pebble >/dev/null 2>&1 \
    || /usr/bin/pgrep -x swift-run >/dev/null 2>&1 \
    || /usr/bin/pgrep -x pebsmoke >/dev/null 2>&1; then
    fail "residual PebbleLab process after CIV-33 proof"
fi

{
    printf 'field\tbeforeRestart\tafterRestart\tresult\n'
    printf 'world\t%s\t%s\tMATCH\n' "$PHASE1_WORLD" "$PHASE1_WORLD"
    printf 'simulation\t%s\t%s\tMATCH\n' "$PHASE1_SIM" "$PHASE1_SIM"
    printf 'decedent\tagent_0\tagent_0\tMATCH\n'
    printf 'death\tcompoundedHomeostaticFailure/tick23\tsame\tSINGLE\n'
    printf 'physicalAsset\tiron_pickaxe:1\tiron_pickaxe:1\tCONSERVED\n'
    printf 'estate\t%s/openAdministered\t%s/settled\tSINGLE\n' \
        "$ESTATE_ID" "$ESTATE_ID"
    printf 'successorTier\tprimaryPartnerAndChildren\tsame\tCANONICAL\n'
    printf 'beneficiaries\tagent_1:partner;agent_3:child\tsame\tCANONICAL\n'
    printf 'administrator\tagent_1/active\tagent_1/ended\tEXPLICIT_ACCEPTANCE\n'
    printf 'holder\tverified-container\tagent:agent_1\tPHYSICAL_TRANSFER\n'
    printf 'owner\tagent_0\tagent_1\tAFTER_PHYSICAL_PROOF\n'
    printf 'intendedCustodian\tagent_1\tagent_1\tPRESERVED_ASSIGNMENT\n'
    printf 'currentCustodian\tagent_1\tnone\tDIRECT_ADULT_HOLDER\n'
    printf 'claims\tpreserved-owner\towner-replaced\tBOUNDED_POLICY\n'
    printf 'permissions\tpreserved\tpreserved\tUNCHANGED\n'
    printf 'rollback\texact\tunchanged\tVERIFIED\n'
    printf 'checkpointSchema\t28\t28\tMATCH\n'
    printf 'manifestIntegrity\t%s\tverified:v1\tMATCH\n' \
        "$MANIFEST_DIGEST"
    printf 'estateOpeningCount\t1\t1\tNO_DUPLICATION\n'
    printf 'settlementCount\t0\t1\tSINGLE\n'
    printf 'duplicationCount\t0\t0\tZERO\n'
    printf 'observerMutationCount\t0\t0\tREAD_ONLY\n'
    printf 'runtimeErrors\t0\t0\tZERO\n'
    printf 'cleanup\tprobesRemoved=3\tprobesRemoved=3;assets+checkpointsRemoved\tEXACT\n'
} > "$MATRIX"

{
    printf 'world=%s\n' "$PHASE1_WORLD"
    printf 'simulation=%s\n' "$PHASE1_SIM"
    printf 'estate=%s\n' "$ESTATE_ID"
    printf 'manifestIntegrityDigest=%s\n' "$MANIFEST_DIGEST"
    /usr/bin/grep -E \
        '^\[lab-live\] (birth finalized|estate proof setup|estate proof advance|mortality physical custody|mortality material exit|mortality exit|estates schema=28|estate administration accepted|estate settlement rollback|checkpoint saved name=civ33-(open|settled)|checkpoint loaded name=civ33-open|estate asset settled|observer status|estate proof cleanup)' \
        "$PHASE1_TRACE" "$PHASE2_TRACE"
    printf 'estateOpeningCount=1\n'
    printf 'assetSettlementCount=1\n'
    printf 'duplicationCount=0\n'
    printf 'observerMutationCount=0\n'
    printf 'runtimeErrors=0\n'
    printf 'cleanup=exact\n'
} > "$COMPACT_TRACE"

printf '\nCIV-33 two-process rendered campaign passed.\n'
printf 'Evidence: %s\n' "$EVIDENCE_ROOT"
printf 'World: %s seed=%s\n' "$WORLD_NAME" "$WORLD_SEED"
printf 'Estate: %s openAdministered>settled\n' "$ESTATE_ID"
printf 'Asset: iron_pickaxe:1 agent_0>agent_1\n'
printf 'Manifest integrity: %s verified\n' "$MANIFEST_DIGEST"
printf 'Observer mutation count: 0\n'
printf 'Duplication count: 0\n'
printf 'Runtime errors: 0\n'
printf 'Cleanup: exact\n'
