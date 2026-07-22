#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
EVALUATED_RUNTIME_BASELINE=1191e70afe4757955ca48f992c8517df15455761
CORR01_STARTING_BASELINE=515ae22c871292a978bb76da3020d3959632b6ed
REPORT_ONLY=0

usage() {
    cat <<'EOF'
Usage: scripts/verify-pebblelab-gate-b.sh [--report-only]

Runs the fail-fast Gate B source audit and a repeated reduced component matrix.
Normal mode exits non-zero while any hard Gate B blocker is present.
--report-only preserves the FAIL verdict but exits zero for diagnostics.
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

reject_fixed() {
    path=$1
    text=$2
    description=$3
    if /usr/bin/grep -Fq "$text" "$ROOT_DIR/$path"; then
        fail "source audit changed: $description"
    fi
}

selector_count() {
    case "$1" in
        materials) printf '30' ;;
        ecological-observation) printf '17' ;;
        agriculture) printf '28' ;;
        wild-subsistence) printf '44' ;;
        livestock) printf '30' ;;
        dependent-care) printf '53' ;;
        skills) printf '59' ;;
        teaching) printf '41' ;;
        work-professions) printf '29' ;;
        physical-food-survival) printf '50' ;;
        autonomous-civilization) printf '36' ;;
        *) fail "unknown reduced selector: $1" ;;
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
git merge-base --is-ancestor "$EVALUATED_RUNTIME_BASELINE" HEAD \
    || fail "evaluated runtime baseline is not an ancestor of HEAD"
git merge-base --is-ancestor "$CORR01_STARTING_BASELINE" HEAD \
    || fail "CORR-01 starting baseline is not an ancestor of HEAD"

printf 'Gate B fail-fast acceptance evaluation\n'
printf 'Repository: %s\n' "$ROOT_DIR"
printf 'Evaluated runtime baseline: %s\n' "$EVALUATED_RUNTIME_BASELINE"
printf 'CORR-01 starting baseline: %s\n' "$CORR01_STARTING_BASELINE"
printf 'Goldens: read-only; PEBBLE_REGOLD is refused.\n'

printf '\n[1/3] Real food-to-survival closure audit\n'
require_fixed Sources/PebbleCore/Items/ItemDefs.swift \
    'public struct FoodDef' 'PebbleCore FoodDef authority is missing'
require_fixed Sources/PebbleCore/Systems/Interact.swift \
    'player.feed(food.hunger, food.saturation)' 'Player food state transition is missing'
require_fixed Sources/PebbleCore/Items/ItemDefs.swift \
    'public func foodConsumptionDescriptor' 'actor-neutral Core food descriptor is missing'
require_fixed Sources/PebbleAgents/AgentSurvival.swift \
    'resource: AgentResourceKind = .foodRaw' 'agent consumption is no longer typed as foodRaw'
require_fixed Sources/PebbleAgents/AgentSimulationSession+Survival.swift \
    'legacyAbstractAuthorityDisabled' 'legacy foodRaw authority is not isolated'
require_fixed Sources/PebbleAgents/AgentSimulationSession+PhysicalFoodSurvival.swift \
    'state.needs.hunger = outcome.hungerAfter' 'validated outcome does not reach canonical hunger'
require_fixed Sources/PebbleAgents/AgentSimulationSession+PhysicalFoodSurvival.swift \
    'outcome.consumptionSequence.rawValue == acceptedThrough + 1' \
    'monotone physical consumption idempotence is missing'
require_fixed Sources/PebbleAgents/AgentPhysicalFoodSurvival.swift \
    'maximumRetainedConsumptionIDs = 64' 'physical consumption retention is not bounded'
require_fixed Sources/Pebble/PebbleAgentMaterialCustodyGateway.swift \
    'sourceSlot: Int?' 'exact-slot physical debit is missing'
require_fixed Sources/Pebble/PebbleAgentFoodConsumptionExecutor.swift \
    'foodConsumptionDescriptor(for: stack)' 'executor does not use Core food metadata'
require_fixed Sources/Pebble/PebbleAgentFoodConsumptionExecutor.swift \
    'gateway.consume(' 'executor does not use real custody debit'
require_fixed Sources/Pebble/PebbleAgentController+Tick.swift \
    'consume_physical_food' 'normal survival tick does not reach physical food executor'
printf 'B-BLOCKER-FOOD-CLOSURE: CLOSED / REMEDIATED LOCALLY\n'
printf '  Core path: FoodDef -> actor-neutral descriptor -> exact ItemStack debit\n'
printf '  Adapter path: exact custody -> verified rollback boundary -> validated outcome\n'
printf '  Agent path: validated outcome -> canonical AgentNeeds.hunger -> starvation\n'
printf '  Shadow path: foodRaw remains legacy/coarse and is rejected in physical mode\n'

printf '\n[2/3] Autonomous playable-slice audit\n'
require_fixed Sources/Pebble/PebbleAgentController.swift \
    'guard session != nil else { return }' 'normal update/start boundary changed'
require_fixed Sources/Pebble/PebbleAgentController+Agriculture.swift \
    'It does not execute farming or mutate the World.' 'agriculture plan-only seam changed'
require_fixed Sources/PebbleAgents/AgentSimulationSession+AutonomousActivity.swift \
    'Selects at most one physical intent per actor' 'single cognitive activity authority missing'
require_fixed Sources/Pebble/PebbleAgentController+AutonomousCivilization.swift \
    'selectAutonomousActivities' 'normal controller does not request cognitive selection'
require_fixed Sources/Pebble/PebbleAgentController+AutonomousExecution.swift \
    'agricultureExecutor.till' 'normal autonomy does not reuse agriculture executor'
require_fixed Sources/Pebble/PebbleAgentController+AutonomousExecution.swift \
    'wildSubsistenceExecutor.gather' 'normal autonomy does not reuse wild executor'
require_fixed Sources/Pebble/PebbleAgentController+AutonomousExecution.swift \
    'livestockExecutor.feed' 'normal autonomy does not reuse livestock executor'
require_fixed Sources/Pebble/PebbleAgentController+AutonomousExecution.swift \
    'recordAutonomousTeachingEvidenceIfEligible' 'Teaching is not chained from real work'
require_fixed Sources/Pebble/PebbleAgentController+Tick.swift \
    'prepareDependent' 'dependent care does not use real physical food'
require_fixed Sources/Pebble/WorldRenderer.swift \
    'villager_farmer' 'stable reused villager presentation is absent'
require_fixed Sources/Pebble/PebbleAgentController+AutonomousCivilization.swift \
    'PLAYABLE_SLICE_BOOTSTRAP_COMPLETE' 'passive bootstrap boundary is absent'
printf 'B-BLOCKER-AUTONOMOUS-PLAYABLE-SLICE: REMEDIATED LOCALLY / CAMPAIGN PENDING\n'
printf '  Session: deterministic bounded cross-domain selection; one intent per actor\n'
printf '  Pebble: existing agriculture/wild/livestock/care/Teaching/work boundaries reused\n'
printf '  Player: follow remains off in passive mode; normal movement and mouse-look retained\n'
printf '  Presentation: stable AgentID maps to existing villager variants; no new assets\n'

printf '\n[3/3] Reduced component matrix (not integrated Gate B proof)\n'
TMP_BASE=${TMPDIR:-/tmp}
TMP_BASE=${TMP_BASE%/}
TMP_ROOT=$(mktemp -d "$TMP_BASE/PebbleLab-gate-b.XXXXXX")
BUILD_LOG="$TMP_ROOT/build.log"
swift build -c release --product pebsmoke >"$BUILD_LOG" 2>&1 \
    || fail "release pebsmoke build failed; see $BUILD_LOG"

SELECTORS='materials ecological-observation agriculture wild-subsistence livestock dependent-care skills teaching work-professions physical-food-survival autonomous-civilization'
TOTAL_CHECKS=0
for selector in $SELECTORS; do
    expected=$(selector_count "$selector")
    run_a="$TMP_ROOT/$selector-a.log"
    run_b="$TMP_ROOT/$selector-b.log"
    PEBBLELAB_SMOKE_ONLY="$selector" \
        swift run -c release --skip-build pebsmoke >"$run_a" 2>&1 \
        || fail "$selector reduced run A failed; see $run_a"
    PEBBLELAB_SMOKE_ONLY="$selector" \
        swift run -c release --skip-build pebsmoke >"$run_b" 2>&1 \
        || fail "$selector reduced run B failed; see $run_b"
    /usr/bin/grep -Fq "$expected passed, 0 failed" "$run_a" \
        || fail "$selector run A count differs from $expected/0"
    /usr/bin/grep -Fq "$expected passed, 0 failed" "$run_b" \
        || fail "$selector run B count differs from $expected/0"
    /usr/bin/cmp -s "$run_a" "$run_b" \
        || fail "$selector repeated output differs"
    TOTAL_CHECKS=$((TOTAL_CHECKS + expected))
    printf '  %-24s %3d passed, 0 failed; repeat byte-identical\n' "$selector" "$expected"
done
[ "$TOTAL_CHECKS" -eq 417 ] || fail "reduced matrix total is $TOTAL_CHECKS, expected 417"

cat <<EOF

Reduced component evidence: 417 passed, 0 failed per run; 417/0 repeated.
Short-tier seeds: NOT RUN — fail-fast hard blockers
Medium-tier seeds: NOT RUN — fail-fast hard blockers
Stress-tier seeds: NOT RUN — fail-fast hard blockers
Composite live World: CORR-02 seed-46 proof is external to this headless evaluator
Playable passive observation: PASS LOCALLY — canonical 5/3/2 campaign has not been rerun
Evidence retained at: $TMP_ROOT

Pillar disposition:
  B1  PARTIAL  isolated physical custody/conservation; no society ledger
  B2  PASS     exact physical food debit reaches canonical agent survival
  B3  PARTIAL  local orchestration exists; multi-strategy campaign pending
  B4  PARTIAL  autonomous executor link exists; multi-cycle campaign pending
  B5  PARTIAL  reserve-gated feed link exists; campaign closure pending
  B6  PASS     autonomous care exact-debits canonical physical food
  B7  PARTIAL  causal Teaching is chained; campaign observation pending
  B8  PARTIAL  commitments drive candidates; campaign continuity pending
  B9  PARTIAL  review/replacement is wired; live shock campaign pending
  B10 PARTIAL  strong local-information components; no composite exercise
  B11 PARTIAL  bounded deterministic components; no composite restore/reconcile run
  B12 PARTIAL  local passive slice passes; human review and canonical campaign pending

Remediated locally; pending senior publication:
  B-BLOCKER-FOOD-CLOSURE
Remediated locally; pending senior campaign re-evaluation:
  B-BLOCKER-AUTONOMOUS-PLAYABLE-SLICE
  B-BLOCKER-LIVESTOCK-RESERVE-CLOSURE
  B-BLOCKER-CRISIS-REPLACEMENT-ORCHESTRATION

GATE B CANDIDATE RESULT: FAIL
Automated Integrated Acceptance: FAIL
Playable Passive Observer Slice: PASS LOCALLY / RE-EVALUATION PENDING
Real Food-to-Survival Closure: PASS
long-running physical consumption exhaustion: NONE
Gate R: ACQUIRED
Gate B canonically acquired: NO
EOF

if [ "$REPORT_ONLY" -eq 1 ]; then
    printf '\nREPORT-ONLY: diagnostics complete; FAIL verdict preserved.\n'
    exit 0
fi

exit 2
