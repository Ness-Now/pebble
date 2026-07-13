#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
RUNBOOK="$ROOT_DIR/docs/pebblelab-3d-live-prototype.md"
MODE="survival"
WORLD_SEED="12345"

usage() {
    cat <<EOF
Usage: scripts/verify-pebblelab-live.sh [--dry-run] [--survival|--economy|--h2]
       scripts/verify-pebblelab-live.sh --help

Launches Pebble for a reproducible, operator-verified Phase J live check. The app is
given an isolated temporary Foundation home, so personal Pebble worlds are not
visible. The existing autoload/new-world hook creates exactly one world with:

  name: ${WORLD_NAME:-PebbleLab-Disposable-<mode>-12345}
  seed: $WORLD_SEED

The launcher reuses Pebble's existing PEBBLE_AUTOLOAD, PEBBLE_NEWWORLD,
PEBBLE_CMD, and PEBBLE_SHOT hooks. PEBBLE_NEWWORLD_NAME is accepted only for a
PebbleLab-Disposable-* name. It does not claim to validate pixels; inspect the
retained trace and capture using $RUNBOOK.

Options:
  --dry-run  Print the environment, commands, and manual steps; do not launch.
  --survival Run the Phase J hunger, consumption, and rest proof (default).
  --economy  Run the preserved Phase I closed-economy proof.
  --h2       Run the preserved H2 navigate-to-harvest proof.
  --help     Show this help and exit.
EOF
}

fail() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

require_trace() {
    pattern=$1
    description=$2
    /usr/bin/grep -Eq "$pattern" "$TRACE_PATH" \
        || fail "live trace missing: $description"
}

DRY_RUN=0
MODE_OPTIONS=0
for option in "$@"; do
    case "$option" in
        --dry-run) DRY_RUN=1 ;;
        --survival) MODE="survival"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --economy) MODE="economy"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --h2) MODE="h2"; MODE_OPTIONS=$((MODE_OPTIONS + 1)) ;;
        --help|-h) usage; exit 0 ;;
        *) printf 'Unknown option: %s\n' "$option" >&2; usage >&2; exit 2 ;;
    esac
done
[ "$#" -le 2 ] || { usage >&2; exit 2; }
[ "$MODE_OPTIONS" -le 1 ] || fail "choose only one live scenario"

if [ "$MODE" = "h2" ]; then
    WORLD_NAME="PebbleLab-Disposable-H2-12345"
    CAPTURE_NAME="h2-navigate-harvest.png"
    LAB_COMMANDS='/lab start;/lab pause;/lab movement off;/lab focus agent_2;/lab interaction setup distant 4;/lab interaction auto on;/lab movement on;/lab overlay full;/lab step;/lab step;/lab step;/lab step;/lab interaction status;/lab status'
elif [ "$MODE" = "economy" ]; then
    WORLD_NAME="PebbleLab-Disposable-I-12345"
    CAPTURE_NAME="phase-i-closed-economy.png"
    LAB_COMMANDS='/lab start;/lab pause;/lab movement off;/lab focus agent_2;/lab economy setup;/lab economy auto on;/lab movement on;/lab overlay full;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab economy status;/lab status'
else
    WORLD_NAME="PebbleLab-Disposable-J-12345"
    CAPTURE_NAME="phase-j-autonomous-survival.png"
    LAB_COMMANDS='/lab start;/lab pause;/lab movement off;/lab focus agent_2;/lab economy setup;/lab survival on;/lab overlay full;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab economy auto on;/lab movement on;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab step;/lab survival status;/lab economy status;/lab status'
fi

if [ "${PEBBLE_REGOLD+x}" = x ]; then
    printf 'PEBBLE_REGOLD must be absent (an empty value is also refused).\n' >&2
    exit 1
fi

print_plan() {
    session_root=$1
    capture_path=$2
    trace_path=$3
    printf 'PebbleLab live verification launcher\n'
    printf 'Scenario: %s\n' "$MODE"
    printf 'Repository: %s\n' "$ROOT_DIR"
    printf 'Runbook: %s\n' "$RUNBOOK"
    printf 'Isolated session root: %s\n' "$session_root"
    printf 'Disposable world name: %s\n' "$WORLD_NAME"
    printf 'Fixed seed: %s\n' "$WORLD_SEED"
    printf 'Capture: %s\n' "$capture_path"
    printf 'Trace: %s\n' "$trace_path"
    printf '\nEnvironment:\n'
    printf '  CFFIXED_USER_HOME=%s/home\n' "$session_root"
    printf '  PEBBLE_AUTOLOAD=1\n'
    printf '  PEBBLE_NEWWORLD=%s\n' "$WORLD_SEED"
    printf '  PEBBLE_NEWWORLD_NAME=%s\n' "$WORLD_NAME"
    printf '  PEBBLELAB_APP_AGENTS=1\n'
    printf '  PEBBLELAB_APP_AGENTS_MOVE=1\n'
    printf '  PEBBLELAB_APP_PROBES=1\n'
    printf '  PEBBLELAB_DEBUG_ENTITIES=1\n'
    printf '  PEBBLELAB_APP_AGENTS_OVERLAY=1\n'
    printf '  PEBBLELAB_APP_AGENTS_TRACE=1\n'
    printf '  PEBBLELAB_APP_AGENTS_TRACE_EVERY=1\n'
    printf '  PEBBLELAB_APP_AGENTS_INTERACT=1\n'
    printf '  PEBBLE_CMD=%s\n' "$LAB_COMMANDS"
    printf '  PEBBLE_SHOT=%s@240\n' "$capture_path"
    printf '\nExisting /lab commands executed after the disposable World is ready:\n'
    old_ifs=$IFS
    IFS=';'
    for command in $LAB_COMMANDS; do printf '  %s\n' "$command"; done
    IFS=$old_ifs
    printf '\nOperator checks:\n'
    printf '  1. Wait for automatic disposable-world creation, commands, capture, and normal termination.\n'
    if [ "$MODE" = "h2" ]; then
        printf '  2. Inspect four tick records: route/index progression, three single steps, then harvest_block.\n'
        printf '  3. Confirm target reservation, adjacent arrival, inventory 0->1, resource_harvested, and no runtime error.\n'
    elif [ "$MODE" = "economy" ]; then
        printf '  2. Confirm two different fixtures are harvested before the delivery quota switches the goal.\n'
        printf '  3. Confirm bounded return_home steps, deliver_resource, empty inventory, camp stock 2, and exact conservation.\n'
    else
        printf '  2. Confirm hunger growth, satisfyHunger, food-only targeting, three route steps, harvest, and consume_food.\n'
        printf '  3. Confirm consumed=1 conservation, fatigue-driven homeRest, rest recovery, normal goal resumption, and zero corridor changes.\n'
    fi
    printf '  4. Inspect the PNG manually; the hook does not provide a pixel assertion.\n'
    printf '  5. Keep or manually remove only this validated PebbleLab temporary session directory. The script deletes nothing.\n'
}

if [ "$DRY_RUN" -eq 1 ]; then
    DRY_TMP_BASE=${TMPDIR:-/tmp}
    DRY_TMP_BASE=${DRY_TMP_BASE%/}
    print_plan "$DRY_TMP_BASE/PebbleLab-live.XXXXXX" \
        "$DRY_TMP_BASE/PebbleLab-live.XXXXXX/captures/$CAPTURE_NAME" \
        "$DRY_TMP_BASE/PebbleLab-live.XXXXXX/pebble-live.log"
    printf '\nDRY RUN: Pebble was not launched and no directory was created.\n'
    exit 0
fi

[ -d "$ROOT_DIR/.git" ] || { printf 'Repository not found: %s\n' "$ROOT_DIR" >&2; exit 1; }
[ -f "$RUNBOOK" ] || { printf 'Runbook not found: %s\n' "$RUNBOOK" >&2; exit 1; }
case "$WORLD_NAME" in
    PebbleLab-Disposable-*) ;;
    *) printf 'Refusing non-disposable world name: %s\n' "$WORLD_NAME" >&2; exit 1 ;;
esac

TMP_BASE=${TMPDIR:-/tmp}
TMP_BASE=${TMP_BASE%/}
SESSION_ROOT=$(mktemp -d "$TMP_BASE/PebbleLab-live.XXXXXX")
case "$SESSION_ROOT" in
    "$TMP_BASE"/PebbleLab-live.*) ;;
    *) printf 'Refusing unsafe temporary path: %s\n' "$SESSION_ROOT" >&2; exit 1 ;;
esac

SESSION_HOME="$SESSION_ROOT/home"
CAPTURE_DIR="$SESSION_ROOT/captures"
CAPTURE_PATH="$CAPTURE_DIR/$CAPTURE_NAME"
TRACE_PATH="$SESSION_ROOT/pebble-live.log"
/bin/mkdir -p "$SESSION_HOME" "$CAPTURE_DIR"

print_plan "$SESSION_ROOT" "$CAPTURE_PATH" "$TRACE_PATH"
printf '\nLaunching Pebble now. Personal Pebble data is hidden by CFFIXED_USER_HOME.\n\n'

cd "$ROOT_DIR"
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
PEBBLE_CMD="$LAB_COMMANDS" \
PEBBLE_SHOT="$CAPTURE_PATH@240" \
swift run -c release Pebble 2>&1 | /usr/bin/tee "$TRACE_PATH"

[ -s "$CAPTURE_PATH" ] || fail "capture was not written: $CAPTURE_PATH"
if [ "$MODE" = "h2" ]; then
    require_trace 'interaction setup mode=distant distance=4 .*corridorObserved=9 corridorChanged=0 fixtureSetupMutations=1' 'setup changed only the final fixture block'
    require_trace 'tick=1 .*focus=agent_2 action=approach_resource .*reservationOwner=agent_2 navigationPurpose=resource navigation=active routeLength=4 routeIndex=1 stepsRemaining=2' 'tick 1 target reservation and first step'
    require_trace 'tick=2 .*focus=agent_2 action=approach_resource .*navigationPurpose=resource navigation=active routeLength=4 routeIndex=2 stepsRemaining=1' 'tick 2 single-step route progress'
    require_trace 'tick=3 .*focus=agent_2 action=approach_resource .*navigationPurpose=resource navigation=arrived routeLength=4 routeIndex=3 stepsRemaining=0' 'tick 3 adjacent arrival'
    require_trace 'tick=4 .*focus=agent_2 action=harvest_block .*navigationPurpose=none navigation=idle routeLength=0 .*invalidation=harvested .*interactionSucceeded=1' 'tick 4 transactional harvest'
    require_trace 'tick=1 .*corridorObserved=9 corridorChanged=0 fixtureSetupMutations=1' 'corridor unchanged during tick 1'
    require_trace 'tick=2 .*corridorObserved=9 corridorChanged=0 fixtureSetupMutations=1' 'corridor unchanged during tick 2'
    require_trace 'tick=3 .*corridorObserved=9 corridorChanged=0 fixtureSetupMutations=1' 'corridor unchanged during tick 3'
    require_trace 'tick=4 .*corridorObserved=9 corridorChanged=0 fixtureSetupMutations=1' 'corridor unchanged after harvest'
    require_trace 'interaction gate=enabled .*actualDistance=1 .*harvested=yes .*inventory=1/8 outcome=succeeded memory=resource_harvested .*corridorObserved=9 corridorChangedSetup=0 corridorChangedNavigation=0 corridorChangedHarvest=0 fixtureSetupMutations=1' 'final inventory, memory, and read-only corridor'
    require_trace 'summary .*runtimeErrors=0 .*interactionRestored=1 .*corridorObserved=9 corridorChangedCleanup=0 cleanupRestoredBlocks=1' 'clean runtime and one-block cleanup'
    printf '\nPASS: H2 live trace and capture evidence verified.\n'
elif [ "$MODE" = "economy" ]; then
    require_trace 'economy setup actor=agent_2 fixtures=.*foodRaw.*wood.*stone.*corridorChanged=0 fixtureSetupMutations=3' 'three target-only fixtures were created'
    require_trace 'action=harvest_block .*inventoryByResource=.*foodRaw:1.*fixtures=.*foodRaw:0:harvested.*conservation=1:1\+0\+0:exact' 'first resource harvested exactly once'
    require_trace 'action=harvest_block .*inventoryByResource=.*foodRaw:1,wood:1.*fixtures=.*wood:1:harvested.*conservation=2:2\+0\+0:exact' 'second resource kind harvested exactly once'
    require_trace 'goals=.*agent_2:deliverResources.*action=return_home .*navigationPurpose=homeDelivery' 'delivery goal uses bounded home route'
    require_trace 'action=deliver_resource .*inventoryByResource=.*foodRaw:0,wood:0.*campStock=.*foodRaw:1,wood:1.*deliveryOutcome=succeeded .*conservation=2:0\+2\+0:exact' 'atomic delivery and exact conservation'
    require_trace 'economy active=yes .*inventoryTotal=0/8 .*campStockTotal=2 .*deliveryOutcome=succeeded .*memory=resource_delivered .*conservation=2:0\+2\+0:exact .*corridorChangedSetup=0 corridorChangedNavigation=0 corridorChangedHarvest=0' 'final economy status'
    require_trace 'summary .*runtimeErrors=0 .*interactionRestored=1 .*conservation=2:0\+2\+0:exact .*corridorChangedCleanup=0 cleanupRestoredBlocks=3' 'clean runtime and three-block cleanup'
    printf '\nPASS: Phase I closed-economy live trace and capture evidence verified.\n'
else
    require_trace 'economy setup actor=agent_2 fixtures=.*foodRaw.*wood.*stone.*corridorChanged=0 fixtureSetupMutations=3' 'three target-only fixtures were created'
    require_trace 'tick=1 .*movement=off .*survival=on .*hunger=0\.05 fatigue=0\.06 health=100' 'bounded survival need progression starts deterministically'
    require_trace 'tick=7 .*movement=off .*survival=on .*hunger=0\.35 fatigue=0\.42 health=100' 'pre-hunger progression remains bounded without movement'
    require_trace 'tick=8 .*action=approach_resource .*resourceSeen=foodRaw@.*reservationOwner=agent_2 navigationPurpose=resource navigation=active .*survival=on' 'threshold-crossing tick selects foodRaw and starts reserved navigation'
    require_trace 'tick=9 .*goals=.*agent_2:satisfyHunger.*focus=agent_2 action=approach_resource .*resourceSeen=foodRaw@.*navigationPurpose=resource navigation=active' 'hunger goal engages and the food route progresses one step'
    require_trace 'tick=10 .*focus=agent_2 action=approach_resource .*navigationPurpose=resource navigation=arrived' 'food route reaches cardinal adjacency'
    require_trace 'tick=11 .*focus=agent_2 action=harvest_block .*interactionSucceeded=1 .*inventoryByResource=.*foodRaw:1.*conservation=1:1\+0\+0:exact' 'foodRaw harvest uses the existing transaction'
    require_trace 'tick=12 .*focus=agent_2 action=consume_food .*hunger=0\.00 .*foodConsumed=1 .*consumptionOutcome=succeeded consumptionSucceeded=1 survivalMemory=food_consumed .*inventoryByResource=.*foodRaw:0.*conservation=1:0\+0\+1:exact' 'atomic food consumption and extended conservation'
    require_trace 'tick=13 .*goals=.*agent_2:rest.*action=return_home .*survivalStatus=exhausted' 'fatigue switches to committed rest'
    require_trace 'tick=14 .*focus=agent_2 action=return_home .*navigationPurpose=homeRest navigation=active' 'rest reuses bounded home route'
    require_trace 'tick=16 .*focus=agent_2 action=return_home .*navigationPurpose=homeRest navigation=arrived' 'rest route arrives at home one step per tick'
    require_trace 'tick=17 .*focus=agent_2 action=rest .*survivalStatus=stable .*fatigue=0\.00' 'rest recovers fatigue at home'
    require_trace 'tick=18 .*goals=.*agent_2:collectResource.*survivalStatus=stable' 'normal economy goal resumes after recovery'
    require_trace 'survival active=yes .*foodRaw=0 foodConsumed=1 .*consumptionOutcome=succeeded memory=food_consumed .*conservation=1:0\+0\+1:exact' 'survival status exposes the successful transaction'
    require_trace 'summary .*runtimeErrors=0 .*interactionRestored=1 .*conservation=1:0\+0\+1:exact .*corridorChangedCleanup=0 cleanupRestoredBlocks=3' 'clean survival runtime and fixture-only cleanup'
    printf '\nPASS: Phase J survival live trace and capture evidence verified.\n'
fi
printf 'The PNG still requires visual inspection; see %s\n' "$RUNBOOK"
printf 'Retained isolated session: %s\n' "$SESSION_ROOT"
