#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
BUILD_CONFIGURATION=${PEBBLELAB_GATE_G_E02_BUILD_CONFIGURATION:-release}
OUTPUT_DIR=${PEBBLELAB_GATE_G_E02_OUTPUT_DIR:-}
export LC_ALL=C
export TZ=UTC

case "$BUILD_CONFIGURATION" in
    debug|release) ;;
    *)
        printf 'ERROR: unsupported Gate G Evaluation 02 build configuration: %s\n' \
            "$BUILD_CONFIGURATION" >&2
        exit 1
        ;;
esac

if [ "${PEBBLE_REGOLD+x}" = x ]; then
    printf 'ERROR: PEBBLE_REGOLD must be absent.\n' >&2
    exit 1
fi

git -C "$ROOT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1
[ "$(git -C "$ROOT_DIR" rev-parse --show-toplevel)" = "$ROOT_DIR" ]

if [ -z "$OUTPUT_DIR" ]; then
    OUTPUT_DIR=$(mktemp -d "${TMPDIR:-/tmp}/pebblelab-gate-g-e02.XXXXXX")
fi
mkdir -p "$OUTPUT_DIR"
OUTPUT_DIR=$(CDPATH= cd -- "$OUTPUT_DIR" && pwd -P)

CHECKPOINT_PATH="$OUTPUT_DIR/checkpoint.json"
BIRTH_CHECKPOINT_PATH="$OUTPUT_DIR/birth-checkpoint.json"
BASE_CHECKPOINT_PATH="$OUTPUT_DIR/base-checkpoint.json"
REPLAY_MANIFEST_PATH="$OUTPUT_DIR/replay-manifest.json"
REPLAY_RECORDS_PATH="$OUTPUT_DIR/replay-records.ndjson"
RESULT_PATH="$OUTPUT_DIR/result.json"
METADATA_PATH="$OUTPUT_DIR/command-metadata.txt"

cd "$ROOT_DIR"
{
    printf 'evaluation=V4-GATE-G-v1 Evaluation 02\n'
    printf 'captured_at_utc=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf 'pwd=%s\n' "$ROOT_DIR"
    printf 'branch=%s\n' "$(git branch --show-current)"
    printf 'head=%s\n' "$(git rev-parse HEAD)"
    printf 'tree=%s\n' "$(git rev-parse HEAD^{tree})"
    printf 'build_configuration=%s\n' "$BUILD_CONFIGURATION"
    printf 'pebble_regold=ABSENT\n'
    printf 'uname=%s\n' "$(uname -a)"
    swift --version
} > "$METADATA_PATH"
swift build -c "$BUILD_CONFIGURATION" --product pebsmoke

PEBBLELAB_SMOKE_ONLY=gate-g-evaluation-02 \
PEBBLELAB_GATE_G_E02_CHECKPOINT_PATH="$CHECKPOINT_PATH" \
PEBBLELAB_GATE_G_E02_BIRTH_CHECKPOINT_PATH="$BIRTH_CHECKPOINT_PATH" \
PEBBLELAB_GATE_G_E02_BASE_CHECKPOINT_PATH="$BASE_CHECKPOINT_PATH" \
PEBBLELAB_GATE_G_E02_REPLAY_MANIFEST_PATH="$REPLAY_MANIFEST_PATH" \
PEBBLELAB_GATE_G_E02_REPLAY_RECORDS_PATH="$REPLAY_RECORDS_PATH" \
PEBBLELAB_GATE_G_E02_RESULT_PATH="$RESULT_PATH" \
    ".build/$BUILD_CONFIGURATION/pebsmoke" \
    | tee "$OUTPUT_DIR/scenario.log"

PEBBLELAB_SMOKE_ONLY=gate-g-evaluation-02-restart-read \
PEBBLELAB_GATE_G_E02_CHECKPOINT_PATH="$CHECKPOINT_PATH" \
PEBBLELAB_GATE_G_E02_BIRTH_CHECKPOINT_PATH="$BIRTH_CHECKPOINT_PATH" \
PEBBLELAB_GATE_G_E02_BASE_CHECKPOINT_PATH="$BASE_CHECKPOINT_PATH" \
PEBBLELAB_GATE_G_E02_REPLAY_MANIFEST_PATH="$REPLAY_MANIFEST_PATH" \
PEBBLELAB_GATE_G_E02_REPLAY_RECORDS_PATH="$REPLAY_RECORDS_PATH" \
PEBBLELAB_GATE_G_E02_RESULT_PATH="$RESULT_PATH" \
    ".build/$BUILD_CONFIGURATION/pebsmoke" \
    | tee "$OUTPUT_DIR/restart-read.log"

shasum -a 256 \
    "$CHECKPOINT_PATH" \
    "$BIRTH_CHECKPOINT_PATH" \
    "$BASE_CHECKPOINT_PATH" \
    "$REPLAY_MANIFEST_PATH" \
    "$REPLAY_RECORDS_PATH" \
    "$RESULT_PATH" \
    "$METADATA_PATH" \
    "$OUTPUT_DIR/scenario.log" \
    "$OUTPUT_DIR/restart-read.log" \
    > "$OUTPUT_DIR/SHA256SUMS"

printf 'Gate G Evaluation 02 %s evidence: %s\n' \
    "$BUILD_CONFIGURATION" "$OUTPUT_DIR"
