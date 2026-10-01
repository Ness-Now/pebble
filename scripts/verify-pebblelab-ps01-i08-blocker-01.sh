#!/usr/bin/env bash
set -euo pipefail
[ "${PEBBLE_REGOLD+x}" != x ] || { printf 'PEBBLE_REGOLD must be absent.\n' >&2; exit 1; }
ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
EVIDENCE_ROOT=${1:?Supply an isolated /tmp evidence directory}
case "$EVIDENCE_ROOT" in /tmp/*|/private/tmp/*) ;; *) exit 2;; esac
[ ! -e "$EVIDENCE_ROOT/home" ] || { printf 'Refusing existing runtime.\n' >&2; exit 2; }
mkdir -p "$EVIDENCE_ROOT"
cd "$ROOT_DIR"
swift build -c release --product Pebble > "$EVIDENCE_ROOT-build.log" 2>&1
BIN_DIR=$(swift build -c release --show-bin-path)
mkdir -p "$EVIDENCE_ROOT/home" "$EVIDENCE_ROOT/executable"
cp "$BIN_DIR/Pebble" "$EVIDENCE_ROOT/executable/Pebble"
shasum -a 256 "$EVIDENCE_ROOT/executable/Pebble" > "$EVIDENCE_ROOT/executable.sha256"
ENV_ARGS=("CFFIXED_USER_HOME=$EVIDENCE_ROOT/home"
    PEBBLELAB_DEBUG_ENTITIES=1 PEBBLELAB_MORTALITY_CHECKPOINT_BLOCKER=1
    "PEBBLELAB_MORTALITY_CHECKPOINT_OUTPUT=$EVIDENCE_ROOT/state")
for gate in AGENTS PROBES AGENTS_MOVE AGENTS_INTERACT AGENTS_MATERIAL \
    AGENTS_PERSISTENCE AGENTS_POPULATION AGENTS_LIFECYCLE AGENTS_KINSHIP \
    AGENTS_HOUSEHOLDS AGENTS_CARE AGENTS_CHILDHOOD AGENTS_FAMILY \
    AGENTS_MORTALITY AGENTS_HOMEOSTASIS AGENTS_GENETICS AGENTS_SKILLS \
    AGENTS_ECOLOGICAL_OBSERVATION AGENTS_WILD_SUBSISTENCE \
    AGENTS_AUTONOMOUS_CIVILIZATION; do
    ENV_ARGS+=("PEBBLELAB_APP_$gate=1")
done
# Normal seed-46 founders and World biology; no I08 continuation code, physical
# fixture, injected death or synthesized state. This is headless diagnostics.
env "${ENV_ARGS[@]}" "$EVIDENCE_ROOT/executable/Pebble"
