#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
RUNBOOK="$ROOT_DIR/docs/pebblelab-3d-live-prototype.md"
WORLD_NAME="PebbleLab-Disposable-H1-424242"
WORLD_SEED="424242"
LAB_COMMANDS='/lab start;/lab pause;/lab movement off;/lab focus agent_1;/lab interaction setup distant 4;/lab interaction auto on;/lab step;/lab interaction status;/lab status'

usage() {
    cat <<EOF
Usage: scripts/verify-pebblelab-live.sh [--dry-run]
       scripts/verify-pebblelab-live.sh --help

Launches Pebble for a reproducible, operator-verified H1 live check. The app is
given an isolated temporary Foundation home, so personal Pebble worlds are not
visible. Create exactly one disposable world in the UI with:

  name: $WORLD_NAME
  seed: $WORLD_SEED

The launcher reuses Pebble's existing PEBBLE_CMD and PEBBLE_SHOT hooks. It does
not use PEBBLE_AUTOLOAD/PEBBLE_NEWWORLD because that hook hard-codes WGTest-*.
It does not claim to parse chat or validate pixels; inspect the retained trace
and capture using $RUNBOOK.

Options:
  --dry-run  Print the environment, commands, and manual steps; do not launch.
  --help     Show this help and exit.
EOF
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
    printf '  PEBBLELAB_APP_AGENTS=1\n'
    printf '  PEBBLELAB_APP_PROBES=1\n'
    printf '  PEBBLELAB_DEBUG_ENTITIES=1\n'
    printf '  PEBBLELAB_APP_AGENTS_OVERLAY=1\n'
    printf '  PEBBLELAB_APP_AGENTS_TRACE=1\n'
    printf '  PEBBLELAB_APP_AGENTS_TRACE_EVERY=1\n'
    printf '  PEBBLELAB_APP_AGENTS_INTERACT=1\n'
    printf '  PEBBLE_CMD=%s\n' "$LAB_COMMANDS"
    printf '  PEBBLE_SHOT=%s@240\n' "$capture_path"
    printf '\nExisting /lab commands executed after the World is ready:\n'
    old_ifs=$IFS
    IFS=';'
    for command in $LAB_COMMANDS; do printf '  %s\n' "$command"; done
    IFS=$old_ifs
    printf '\nManual steps:\n'
    printf '  1. In the isolated, empty world list, create a Survival world named exactly %s.\n' "$WORLD_NAME"
    printf '  2. Enter the fixed seed %s and create the world. Do not create or open any other world.\n' "$WORLD_SEED"
    printf '  3. Wait for command execution, capture, and normal automatic termination.\n'
    printf '  4. Inspect the trace for a distant active target and approach_resource with no movement or harvest.\n'
    printf '  5. Inspect the PNG manually; the hook does not provide a pixel assertion.\n'
    printf '  6. Keep or manually remove only this validated PebbleLab temporary session directory. The script deletes nothing.\n'
}

if [ "$DRY_RUN" -eq 1 ]; then
    DRY_TMP_BASE=${TMPDIR:-/tmp}
    DRY_TMP_BASE=${DRY_TMP_BASE%/}
    print_plan "$DRY_TMP_BASE/PebbleLab-live.XXXXXX" \
        "$DRY_TMP_BASE/PebbleLab-live.XXXXXX/captures/h1-target-lock.png" \
        "$DRY_TMP_BASE/PebbleLab-live.XXXXXX/pebble-live.log"
    printf '\nDRY RUN: Pebble was not launched and no directory was created.\n'
    exit 0
fi

[ -d "$ROOT_DIR/.git" ] || { printf 'Repository not found: %s\n' "$ROOT_DIR" >&2; exit 1; }
[ -f "$RUNBOOK" ] || { printf 'Runbook not found: %s\n' "$RUNBOOK" >&2; exit 1; }

TMP_BASE=${TMPDIR:-/tmp}
TMP_BASE=${TMP_BASE%/}
SESSION_ROOT=$(mktemp -d "$TMP_BASE/PebbleLab-live.XXXXXX")
case "$SESSION_ROOT" in
    "$TMP_BASE"/PebbleLab-live.*) ;;
    *) printf 'Refusing unsafe temporary path: %s\n' "$SESSION_ROOT" >&2; exit 1 ;;
esac

SESSION_HOME="$SESSION_ROOT/home"
CAPTURE_DIR="$SESSION_ROOT/captures"
CAPTURE_PATH="$CAPTURE_DIR/h1-target-lock.png"
TRACE_PATH="$SESSION_ROOT/pebble-live.log"
/bin/mkdir -p "$SESSION_HOME" "$CAPTURE_DIR"

print_plan "$SESSION_ROOT" "$CAPTURE_PATH" "$TRACE_PATH"
printf '\nLaunching Pebble now. Personal Pebble data is hidden by CFFIXED_USER_HOME.\n\n'

cd "$ROOT_DIR"
CFFIXED_USER_HOME="$SESSION_HOME" \
PEBBLELAB_APP_AGENTS=1 \
PEBBLELAB_APP_PROBES=1 \
PEBBLELAB_DEBUG_ENTITIES=1 \
PEBBLELAB_APP_AGENTS_OVERLAY=1 \
PEBBLELAB_APP_AGENTS_TRACE=1 \
PEBBLELAB_APP_AGENTS_TRACE_EVERY=1 \
PEBBLELAB_APP_AGENTS_INTERACT=1 \
PEBBLE_CMD="$LAB_COMMANDS" \
PEBBLE_SHOT="$CAPTURE_PATH@240" \
swift run -c release Pebble 2>&1 | /usr/bin/tee "$TRACE_PATH"

printf '\nPebble exited normally. This only proves launcher completion.\n'
printf 'Manual live evidence remains required; see %s\n' "$RUNBOOK"
printf 'Retained isolated session: %s\n' "$SESSION_ROOT"
