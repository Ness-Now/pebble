#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
REEVALUATION_BASELINE=fc618de61437c4acd63ec0ff41823e6d91b56d0a
REPORT_ONLY=0

SHORT_SEEDS='46 71 113 197 337'
MEDIUM_SEEDS='509 887 1597'
STRESS_SEEDS='2593 4099'
SHORT_HORIZON_TICKS=800
MEDIUM_HORIZON_TICKS=4800
STRESS_HORIZON_TICKS=6400

usage() {
    cat <<'EOF'
Usage: scripts/verify-pebblelab-gate-b.sh [--report-only]

Runs Gate B re-evaluation #2 in acceptance-first order. The evaluator declares
the fixed 5/3/2 campaign, checks the published blocker seams, and refuses to
run or credit the expensive campaign after a proven hard acceptance blocker.

Normal mode exits zero only for a Gate B candidate PASS and non-zero for FAIL.
--report-only preserves the same verdict but exits zero after writing evidence.
EOF
}

fail() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

require_fixed() {
    path=$1
    text=$2
    description=$3
    /usr/bin/grep -Fq "$text" "$ROOT_DIR/$path" \
        || fail "source audit inconclusive: $description"
}

selector_count() {
    case "$1" in
        physical-food-survival) printf '50' ;;
        autonomous-civilization) printf '36' ;;
        livestock) printf '30' ;;
        work-professions) printf '29' ;;
        dependent-care) printf '53' ;;
        teaching) printf '41' ;;
        *) fail "unknown focused selector: $1" ;;
    esac
}

if [ "$#" -gt 1 ]; then
    usage >&2
    exit 2
fi
if [ "$#" -eq 1 ]; then
    case "$1" in
        --report-only) REPORT_ONLY=1 ;;
        --help|-h) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
fi

if [ "${PEBBLE_REGOLD+x}" = x ]; then
    fail "PEBBLE_REGOLD must be absent (an empty value is also refused)."
fi

[ -d "$ROOT_DIR/.git" ] || fail "repository metadata not found at $ROOT_DIR"
cd "$ROOT_DIR"
git merge-base --is-ancestor "$REEVALUATION_BASELINE" HEAD \
    || fail "Gate B re-evaluation baseline is not an ancestor of HEAD"

HEAD_SHA=$(git rev-parse HEAD)
BRANCH=$(git branch --show-current)
EVIDENCE_BASE=${PEBBLELAB_GATE_B_EVIDENCE_ROOT:-${TMPDIR:-/tmp}}
EVIDENCE_BASE=${EVIDENCE_BASE%/}
if [ -n "${PEBBLELAB_GATE_B_EVIDENCE_ROOT:-}" ]; then
    EVIDENCE_ROOT="$EVIDENCE_BASE"
    mkdir -p "$EVIDENCE_ROOT"
else
    EVIDENCE_ROOT=$(mktemp -d "$EVIDENCE_BASE/PebbleLab-gate-b2.XXXXXX")
fi
RUN_MATRIX="$EVIDENCE_ROOT/fixed-seed-matrix.tsv"
SOURCE_AUDIT="$EVIDENCE_ROOT/integrated-readiness-audit.txt"

printf 'Gate B re-evaluation #2 — acceptance-first candidate evaluation\n'
printf 'Repository: %s\n' "$ROOT_DIR"
printf 'Branch: %s\n' "$BRANCH"
printf 'HEAD: %s\n' "$HEAD_SHA"
printf 'Baseline ancestor: %s\n' "$REEVALUATION_BASELINE"
printf 'Evidence root: %s\n' "$EVIDENCE_ROOT"
printf 'Goldens: read-only; PEBBLE_REGOLD is refused.\n'
printf '\nFixed seeds declared before execution (no rerolls):\n'
printf '  short  (%s ticks): %s\n' "$SHORT_HORIZON_TICKS" "$SHORT_SEEDS"
printf '  medium (%s ticks): %s\n' "$MEDIUM_HORIZON_TICKS" "$MEDIUM_SEEDS"
printf '  stress (%s ticks): %s\n' "$STRESS_HORIZON_TICKS" "$STRESS_SEEDS"

cat >"$EVIDENCE_ROOT/configuration.json" <<EOF
{
  "schemaVersion": 1,
  "evaluation": "Gate B re-evaluation #2",
  "head": "$HEAD_SHA",
  "branch": "$BRANCH",
  "candidateResult": "FAIL",
  "short": {"seeds": [46, 71, 113, 197, 337], "ticks": $SHORT_HORIZON_TICKS},
  "medium": {"seeds": [509, 887, 1597], "ticks": $MEDIUM_HORIZON_TICKS},
  "stress": {"seeds": [2593, 4099], "ticks": $STRESS_HORIZON_TICKS}
}
EOF

printf '\n[1/3] Published blocker regression checks\n'
require_fixed Sources/PebbleAgents/AgentSimulationSession+PhysicalFoodSurvival.swift \
    'state.needs.hunger = outcome.hungerAfter' \
    'validated physical food does not reach canonical hunger'
require_fixed Sources/PebbleAgents/AgentSimulationSession+PhysicalFoodSurvival.swift \
    'outcome.consumptionSequence.rawValue == acceptedThrough + 1' \
    'non-exhausting monotone food idempotence is missing'
require_fixed Sources/Pebble/PebbleAgentFoodConsumptionExecutor.swift \
    'gateway.consume(' 'real custody debit is missing'
require_fixed Sources/Pebble/PebbleAgentController+AutonomousCivilization.swift \
    'selectAutonomousActivities' 'normal autonomous selection is missing'
require_fixed Sources/Pebble/PebbleAgentController+AutonomousExecution.swift \
    'livestockExecutor.feed' 'real livestock executor reuse is missing'
require_fixed Sources/Pebble/PebbleAgentController+Tick.swift \
    'prepareDependent' 'dependent physical-food care is missing'
require_fixed Sources/Pebble/PebbleAgentController+AutonomousCivilization.swift \
    '$0.status == .suspended && $0.suspensionReason == .crisis' \
    'normal crisis replacement review is missing'

swift build -c release --product pebsmoke >"$EVIDENCE_ROOT/build.log" 2>&1 \
    || fail "release pebsmoke build failed; see $EVIDENCE_ROOT/build.log"

FOCUSED_TOTAL=0
for selector in \
    physical-food-survival autonomous-civilization livestock \
    work-professions dependent-care teaching
do
    expected=$(selector_count "$selector")
    output="$EVIDENCE_ROOT/focused-$selector.log"
    PEBBLELAB_SMOKE_ONLY="$selector" \
        swift run -c release --skip-build pebsmoke >"$output" 2>&1 \
        || fail "$selector focused regression failed; see $output"
    /usr/bin/grep -Fq "$expected passed, 0 failed" "$output" \
        || fail "$selector count differs from $expected/0"
    FOCUSED_TOTAL=$((FOCUSED_TOTAL + expected))
    printf '  %-26s %3d passed, 0 failed\n' "$selector" "$expected"
done
printf '  focused total              %3d passed, 0 failed\n' "$FOCUSED_TOTAL"
printf 'Historical blockers: no focused regression detected.\n'

printf '\n[2/3] Integrated Teaching readiness audit\n'
PRODUCT_TEACHING_CALLS=$(
    /usr/bin/grep -R -n --include='*.swift' \
        'selectMentorAndStartApprenticeship' Sources/Pebble 2>/dev/null \
        | /usr/bin/grep -v '/PebbleAgentController+TeachingProof.swift:' || true
)
{
    printf 'head=%s\n' "$HEAD_SHA"
    printf 'normal_product_calls_to_selectMentorAndStartApprenticeship=%s\n' \
        "$([ -n "$PRODUCT_TEACHING_CALLS" ] && printf 'present' || printf 'absent')"
    printf 'proof_only_call=Sources/Pebble/PebbleAgentController+TeachingProof.swift:218\n'
    printf 'autonomous_execution_behavior=publishes_demonstration_only_for_preexisting_active_apprenticeship\n'
    printf 'classification=ARCHITECTURE_BLOCKER\n'
    printf 'pillar=B7\n'
} >"$SOURCE_AUDIT"

if [ -n "$PRODUCT_TEACHING_CALLS" ]; then
    printf '%s\n' "$PRODUCT_TEACHING_CALLS" >>"$SOURCE_AUDIT"
    fail "Teaching readiness audit changed; review the newly integrated call before campaign execution"
fi

printf '  normal autonomous/local apprenticeship initiation: ABSENT\n'
printf '  demonstration publication after an existing apprenticeship: PRESENT\n'
printf '  proof-only initiation: PRESENT\n'
printf '  B7 integrated causal chain: HARD FAIL\n'
printf '  classification: ARCHITECTURE BLOCKER\n'

printf '\n[3/3] Fixed campaign disposition\n'
printf 'tier\tseed\tticks\tstatus\treason\n' >"$RUN_MATRIX"
for seed in $SHORT_SEEDS; do
    printf 'short\t%s\t%s\tNOT_RUN\tB7_HARD_FAIL_BEFORE_CAMPAIGN\n' \
        "$seed" "$SHORT_HORIZON_TICKS" >>"$RUN_MATRIX"
done
for seed in $MEDIUM_SEEDS; do
    printf 'medium\t%s\t%s\tNOT_RUN\tB7_HARD_FAIL_BEFORE_CAMPAIGN\n' \
        "$seed" "$MEDIUM_HORIZON_TICKS" >>"$RUN_MATRIX"
done
for seed in $STRESS_SEEDS; do
    printf 'stress\t%s\t%s\tNOT_RUN\tB7_HARD_FAIL_BEFORE_CAMPAIGN\n' \
        "$seed" "$STRESS_HORIZON_TICKS" >>"$RUN_MATRIX"
done
column -t -s "$(printf '\t')" "$RUN_MATRIX" 2>/dev/null || /bin/cat "$RUN_MATRIX"

cat <<EOF

Acceptance policy applied:
  - no seed was rerolled, hidden, or credited
  - no post-bootstrap productive injection was attempted
  - the 5/3/2 campaign was not run after a proven hard architecture blocker
  - component proofs were not substituted for integrated Teaching evidence

Pillar disposition at this fail-fast boundary:
  B1  FAIL  society-scale integrated ledger campaign not executed
  B2  PASS  published adult/dependent physical-food closure did not regress
  B3  FAIL  fixed multi-seed integrated campaign not executed
  B4  FAIL  growth/harvest/next-cycle continuity not established
  B5  FAIL  resource-bounded livestock continuity not established in campaign
  B6  FAIL  care continuity not established in a medium and stress World
  B7  FAIL  no normal autonomous/local apprenticeship initiation path
  B8  FAIL  durable specialization not established across medium Worlds
  B9  FAIL  designated stress replacement runs not executed
  B10 FAIL  composite local-information campaign not executed
  B11 FAIL  seed-509 repeat and seed-887 reconcile campaign not executed
  B12 FAIL  final passive re-evaluation is separate and cannot repair B7

Primary hard blocker:
  GATE-B-CORR-03 candidate scope: integrate autonomous/local apprenticeship
  initiation from real practice and local opportunity, without a scheduler,
  then rerun the complete 5/3/2 campaign.

GATE B RE-EVALUATION #2
CANDIDATE RESULT: FAIL
Gate R: ACQUIRED
Gate B canonically acquired: NO
CIV-26 started: NO
Evidence root: $EVIDENCE_ROOT
EOF

if [ "$REPORT_ONLY" -eq 1 ]; then
    printf '\nREPORT-ONLY: diagnostics complete; FAIL verdict preserved.\n'
    exit 0
fi

exit 2
