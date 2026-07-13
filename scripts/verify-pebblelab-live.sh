#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
RUNBOOK="$ROOT_DIR/docs/pebblelab-3d-live-prototype.md"
WORLD_NAME="PebbleLab-Disposable-H2-12345"
WORLD_SEED="12345"
LAB_COMMANDS='/lab start;/lab pause;/lab movement off;/lab focus agent_2;/lab interaction setup distant 4;/lab interaction auto on;/lab movement on;/lab overlay full;/lab step;/lab step;/lab step;/lab step;/lab interaction status;/lab status'

usage() {
    cat <<EOF
Usage: scripts/verify-pebblelab-live.sh [--dry-run]
       scripts/verify-pebblelab-live.sh --help

Launches Pebble for a reproducible, operator-verified H2 live check. The app is
given an isolated temporary Foundation home, so personal Pebble worlds are not
visible. The existing autoload/new-world hook creates exactly one world with:

  name: $WORLD_NAME
  seed: $WORLD_SEED

The launcher reuses Pebble's existing PEBBLE_AUTOLOAD, PEBBLE_NEWWORLD,
PEBBLE_CMD, and PEBBLE_SHOT hooks. PEBBLE_NEWWORLD_NAME is accepted only for a
PebbleLab-Disposable-* name. It does not claim to validate pixels; inspect the
retained trace and capture using $RUNBOOK.

Options:
  --dry-run  Print the environment, commands, and manual steps; do not launch.
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
case ${1:-} in
    "") ;;
    --dry-run) DRY_RUN=1 ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
esac
[ "$#" -le 1 ] || { usage >&2; exit 2; }

if [ "${PEBBLE_REGOLD+x}" = x ]; then
    printf 'PEBBLE_REGOLD must be absent (an empty value is also refused).\n' >&2
    exit 1
fi

print_plan() {
    session_root=$1
    capture_path=$2
    trace_path=$3
    printf 'PebbleLab live verification launcher\n'
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
    printf '  2. Inspect four tick records: route/index progression, three single steps, then harvest_block.\n'
    printf '  3. Confirm target reservation, adjacent arrival, inventory 0->1, resource_harvested, and no runtime error.\n'
    printf '  4. Inspect the PNG manually; the hook does not provide a pixel assertion.\n'
    printf '  5. Keep or manually remove only this validated PebbleLab temporary session directory. The script deletes nothing.\n'
}

if [ "$DRY_RUN" -eq 1 ]; then
    DRY_TMP_BASE=${TMPDIR:-/tmp}
    DRY_TMP_BASE=${DRY_TMP_BASE%/}
    print_plan "$DRY_TMP_BASE/PebbleLab-live.XXXXXX" \
        "$DRY_TMP_BASE/PebbleLab-live.XXXXXX/captures/h2-navigate-harvest.png" \
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
CAPTURE_PATH="$CAPTURE_DIR/h2-navigate-harvest.png"
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
require_trace 'interaction setup mode=distant distance=4 .*corridorObserved=9 corridorChanged=0 fixtureSetupMutations=1' 'setup changed only the final fixture block'
require_trace 'tick=1 .*focus=agent_2 action=approach_resource .*reservationOwner=agent_2 navigation=active routeLength=4 routeIndex=1 stepsRemaining=2' 'tick 1 target reservation and first step'
require_trace 'tick=2 .*focus=agent_2 action=approach_resource .*navigation=active routeLength=4 routeIndex=2 stepsRemaining=1' 'tick 2 single-step route progress'
require_trace 'tick=3 .*focus=agent_2 action=approach_resource .*navigation=arrived routeLength=4 routeIndex=3 stepsRemaining=0' 'tick 3 adjacent arrival'
require_trace 'tick=4 .*focus=agent_2 action=harvest_block .*navigation=idle routeLength=0 .*invalidation=harvested .*interactionSucceeded=1' 'tick 4 transactional harvest'
require_trace 'tick=1 .*corridorObserved=9 corridorChanged=0 fixtureSetupMutations=1' 'corridor unchanged during tick 1'
require_trace 'tick=2 .*corridorObserved=9 corridorChanged=0 fixtureSetupMutations=1' 'corridor unchanged during tick 2'
require_trace 'tick=3 .*corridorObserved=9 corridorChanged=0 fixtureSetupMutations=1' 'corridor unchanged during tick 3'
require_trace 'tick=4 .*corridorObserved=9 corridorChanged=0 fixtureSetupMutations=1' 'corridor unchanged after harvest'
require_trace 'interaction gate=enabled .*actualDistance=1 .*harvested=yes .*inventory=1/8 outcome=succeeded memory=resource_harvested .*corridorObserved=9 corridorChangedSetup=0 corridorChangedNavigation=0 corridorChangedHarvest=0 fixtureSetupMutations=1' 'final inventory, memory, and read-only corridor'
require_trace 'summary .*runtimeErrors=0 .*interactionRestored=1 .*corridorObserved=9 corridorChangedCleanup=0 cleanupRestoredBlocks=1' 'clean runtime and one-block cleanup'

printf '\nPASS: H2 live trace and capture evidence verified.\n'
printf 'The PNG still requires visual inspection; see %s\n' "$RUNBOOK"
printf 'Retained isolated session: %s\n' "$SESSION_ROOT"
