#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)

if [ "${1:-}" = "--dry-run" ]; then
    [ "$#" -eq 1 ] || { printf 'usage: %s [--dry-run]\n' "$0" >&2; exit 1; }
    PEBBLELAB_GATE_E_BLOCKER_03=1 \
        exec "$SCRIPT_DIR/verify-pebblelab-live.sh" --dry-run --markets
fi
[ "$#" -eq 0 ] || { printf 'usage: %s [--dry-run]\n' "$0" >&2; exit 1; }

PEBBLELAB_GATE_E_BLOCKER_03=1 \
    exec "$SCRIPT_DIR/verify-pebblelab-live.sh" --markets
