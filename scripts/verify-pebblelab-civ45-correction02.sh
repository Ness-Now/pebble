#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
cd "$ROOT_DIR"

BUILD_CONFIGURATION=${PEBBLELAB_CIV45_BUILD_CONFIGURATION:-release}
case "$BUILD_CONFIGURATION" in debug|release) ;; *) exit 2 ;; esac
if [[ ${PEBBLELAB_CIV45_C02_SKIP_BUILD:-0} != 1 ]]; then
    swift build -c "$BUILD_CONFIGURATION" --product pebsmoke
fi

TMP_BASE=${TMPDIR:-/tmp}
TMP_BASE=${TMP_BASE%/}
RUN_HOME=$(mktemp -d "$TMP_BASE/pebblelab-civ45-correction02.XXXXXX")
cleanup() {
    rm -rf -- "$RUN_HOME"
}
trap cleanup EXIT

BIN=".build/$BUILD_CONFIGURATION/pebsmoke"
STRUCTURAL_HOME="$RUN_HOME/structural"
mkdir -p "$STRUCTURAL_HOME"
CFFIXED_USER_HOME="$STRUCTURAL_HOME" \
    PEBBLELAB_SMOKE_ONLY=civ-45-correction02 \
    "$BIN"

for phase in before-transaction during-transaction after-commit-before-return after-return; do
    case "$phase" in
        before-transaction|during-transaction)
            expected=old
            expected_writer_rc=77
            ;;
        after-commit-before-return)
            expected=new
            expected_writer_rc=77
            ;;
        after-return)
            expected=new
            expected_writer_rc=0
            ;;
    esac
    PHASE_HOME="$RUN_HOME/$phase"
    mkdir -p "$PHASE_HOME"
    set +e
    CFFIXED_USER_HOME="$PHASE_HOME" \
        PEBBLELAB_SMOKE_ONLY=civ-45-correction02-crash-writer \
        PEBBLELAB_CIV45_C02_CRASH_PHASE="$phase" \
        "$BIN"
    writer_rc=$?
    set -e
    if [[ $writer_rc -ne $expected_writer_rc ]]; then
        echo "unexpected writer exit: phase=$phase got=$writer_rc expected=$expected_writer_rc" >&2
        exit 1
    fi
    CFFIXED_USER_HOME="$PHASE_HOME" \
        PEBBLELAB_SMOKE_ONLY=civ-45-correction02-crash-reader \
        PEBBLELAB_CIV45_C02_EXPECT="$expected" \
        "$BIN"
done
