#!/usr/bin/env bash
# Shared Core qualification only; never invokes the I08 campaign or regold.
set -euo pipefail
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
MODE=${1:---native}
case "$MODE" in
    --native|--tsan|--stress) ;;
    *) echo "usage: $0 [--native|--tsan|--stress]" >&2; exit 2 ;;
esac
if [ "${PEBBLE_REGOLD+x}" = x ]; then
    echo "PEBBLE_REGOLD must be absent" >&2; exit 2
fi
cd "$ROOT"
OUT=$(mktemp -d "${TMPDIR:-/tmp}/PebbleCore-B04.XXXXXX")
echo "B04 evidence: $OUT"
if [ "$MODE" = --tsan ]; then
    swift build -c debug --sanitize=thread --target PebbleCore \
        --scratch-path "$OUT/build" > "$OUT/build.log" 2>&1
    CORE="$OUT/build/arm64-apple-macosx/debug"
    cat > "$OUT/main.swift" <<'SWIFT'
import Foundation
import PebbleCore
var passed = 0
var failed = 0
func section(_ name: String) { print("— \(name)") }
func check(_ name: String, _ condition: Bool, _ detail: String = "") {
    if condition { passed += 1; print("  ✓ \(name)") }
    else { failed += 1; print("  ✗ \(name) \(detail)") }
}
setbuf(stdout, nil)
switch ProcessInfo.processInfo.environment["PEBBLELAB_SMOKE_ONLY"] {
case "core-stronghold-ordinary":
    runPebbleCoreStrongholdOrdinaryReplacementSmoke(replacements: 1)
case "core-stronghold-repeated":
    runPebbleCoreStrongholdOrdinaryReplacementSmoke(replacements: 8)
default:
    runPebbleCoreStrongholdConcurrencySmoke()
}
print("\n\(passed) passed, \(failed) failed")
exit(failed > 0 ? 1 : 0)
SWIFT
    swiftc -g -sanitize=thread -I "$CORE/Modules" "$OUT/main.swift" \
        Sources/pebsmoke/PebbleCoreStrongholdConcurrencySmoke.swift \
        "$CORE/PebbleCore.build/"*.o -o "$OUT/b04-tsan"
    BINARY="$OUT/b04-tsan"
else
    swift build -c release --product pebsmoke > "$OUT/build.log" 2>&1
    BINARY="$ROOT/.build/release/pebsmoke"
fi
shasum -a 256 "$BINARY" | tee "$OUT/executable.sha256"
REPETITIONS=1
if [ "$MODE" = --stress ]; then REPETITIONS=6; fi
for suite in core-stronghold-concurrency core-stronghold-ordinary core-stronghold-repeated; do
    for ((iteration=1; iteration<=REPETITIONS; iteration++)); do
        RUN="$OUT/$suite-$iteration"
        mkdir -p "$RUN/home"
        set +e
        CFFIXED_USER_HOME="$RUN/home" TSAN_OPTIONS=halt_on_error=1:exitcode=66 \
            PEBBLELAB_SMOKE_ONLY="$suite" "$BINARY" > "$RUN/output.log" 2>&1
        RESULT=$?
        set -e
        printf '%s run=%s exit=%s\n' "$suite" "$iteration" "$RESULT" | tee -a "$OUT/results.txt"
        tail -n 2 "$RUN/output.log"
        if [ "$RESULT" -ne 0 ]; then exit "$RESULT"; fi
    done
done
