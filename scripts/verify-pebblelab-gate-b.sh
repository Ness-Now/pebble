#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
EVALUATED_RUNTIME_BASELINE=1191e70afe4757955ca48f992c8517df15455761
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
        dependent-care) printf '48' ;;
        skills) printf '59' ;;
        teaching) printf '41' ;;
        work-professions) printf '29' ;;
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
git diff --quiet "$EVALUATED_RUNTIME_BASELINE" -- \
    Package.swift Package.resolved \
    Sources/PebbleCore Sources/PebbleAgents Sources/Pebble \
    || fail "runtime differs from the evaluated Gate B baseline; perform a new audit"

printf 'Gate B fail-fast acceptance evaluation\n'
printf 'Repository: %s\n' "$ROOT_DIR"
printf 'Evaluated runtime baseline: %s\n' "$EVALUATED_RUNTIME_BASELINE"
printf 'Runtime product diff from baseline: none\n'
printf 'Goldens: read-only; PEBBLE_REGOLD is refused.\n'

printf '\n[1/3] Real food-to-survival closure audit\n'
require_fixed Sources/PebbleCore/Items/ItemDefs.swift \
    'public struct FoodDef' 'PebbleCore FoodDef authority is missing'
require_fixed Sources/PebbleCore/Systems/Interact.swift \
    'player.feed(food.hunger, food.saturation)' 'Player food state transition is missing'
require_fixed Sources/PebbleCore/Systems/Interact.swift \
    'player.consumeHeld(1)' 'Player exact held-item debit is missing'
require_fixed Sources/PebbleAgents/AgentSurvival.swift \
    'resource: AgentResourceKind = .foodRaw' 'agent consumption is no longer typed as foodRaw'
require_fixed Sources/PebbleAgents/AgentSimulationSession+Survival.swift \
    'state.resourceInventory.count(of: .foodRaw)' 'agent survival inventory source changed'
require_fixed Sources/PebbleAgents/AgentSimulationSession+Survival.swift \
    'inventory.remove(.foodRaw, quantity: 1)' 'agent survival debit changed'
reject_fixed Sources/PebbleAgents/AgentSimulationSession+Survival.swift \
    'ItemStack' 'agent survival now mentions physical ItemStack; reevaluate closure'
require_fixed Sources/Pebble/PebbleAgentMaterialCustodyGateway.swift \
    'The result is derived from real custody and is never written into a session' \
    'coarse projection contract changed'
printf 'B-BLOCKER-FOOD-CLOSURE: CONFIRMED\n'
printf '  Core path: FoodDef -> Player.feed -> Player.consumeHeld\n'
printf '  Agent path: abstract foodRaw -> AgentResourceInventory debit -> agent hunger\n'
printf '  Missing: one transactional exact ItemStack -> canonical agent survival bridge\n'

printf '\n[2/3] Autonomous playable-slice audit\n'
require_fixed Sources/Pebble/PebbleAgentController.swift \
    'guard session != nil else { return }' 'normal update/start boundary changed'
require_fixed Sources/Pebble/PebbleAgentController+Agriculture.swift \
    'It does not execute farming or mutate the World.' 'agriculture plan-only seam changed'
require_fixed Sources/Pebble/PebbleAgentController+WildSubsistence.swift \
    'case "fish":' 'manual fishing proof phase changed'
require_fixed Sources/Pebble/PebbleAgentController+Livestock.swift \
    'case "feed": try runLivestockFeedProof' 'manual livestock proof phase changed'
require_fixed Sources/Pebble/PebbleAgentController+WorkProfessions.swift \
    'case "refresh":' 'manual work refresh path changed'
require_fixed Sources/Pebble/PebbleAgentController+Teaching.swift \
    'case "proof":' 'manual Teaching proof path changed'
reject_fixed Sources/Pebble/PebbleAgentController+Tick.swift \
    'wildSubsistenceExecutor' 'normal tick now reaches wild executor; reevaluate autonomy'
reject_fixed Sources/Pebble/PebbleAgentController+Tick.swift \
    'livestockExecutor' 'normal tick now reaches livestock executor; reevaluate autonomy'
reject_fixed Sources/Pebble/PebbleAgentController+Tick.swift \
    'workCommitment' 'normal tick now reaches work commitments; reevaluate autonomy'
require_fixed Sources/PebbleCore/Entity/LabCoreAgentEntity.swift \
    'not rendered' 'agent visual embodiment contract changed'
printf 'B-BLOCKER-AUTONOMOUS-PLAYABLE-SLICE: CONFIRMED\n'
printf '  Agriculture: automatic plan only; physical cycle remains proof-command driven\n'
printf '  Wild/livestock/Teaching/work: proof command or harness selects each transition\n'
printf '  WorkCommitment -> normal domain executor link: absent\n'
printf '  Normal agent visual identity: absent; debug bodies are undifferentiated markers\n'

printf '\n[3/3] Reduced component matrix (not integrated Gate B proof)\n'
TMP_BASE=${TMPDIR:-/tmp}
TMP_BASE=${TMP_BASE%/}
TMP_ROOT=$(mktemp -d "$TMP_BASE/PebbleLab-gate-b.XXXXXX")
BUILD_LOG="$TMP_ROOT/build.log"
swift build -c release --product pebsmoke >"$BUILD_LOG" 2>&1 \
    || fail "release pebsmoke build failed; see $BUILD_LOG"

SELECTORS='materials ecological-observation agriculture wild-subsistence livestock dependent-care skills teaching work-professions'
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
[ "$TOTAL_CHECKS" -eq 326 ] || fail "reduced matrix total is $TOTAL_CHECKS, expected 326"

cat <<EOF

Reduced component evidence: 326 passed, 0 failed per run; 326/0 repeated.
Short-tier seeds: NOT RUN — fail-fast hard blockers
Medium-tier seeds: NOT RUN — fail-fast hard blockers
Stress-tier seeds: NOT RUN — fail-fast hard blockers
Composite live World: NOT RUN — no autonomous composite candidate exists
Playable passive observation: NOT RUN — launching scripted proof commands cannot prove autonomy
Evidence retained at: $TMP_ROOT

Pillar disposition:
  B1  PARTIAL  isolated physical custody/conservation; no society ledger
  B2  FAIL     physical food and canonical agent survival are disconnected
  B3  PARTIAL  multiple strategies exist only as separate proofs
  B4  PARTIAL  one real agricultural cycle; no autonomous continuity
  B5  FAIL     real feed/reserve decision is not product-wired end to end
  B6  PARTIAL  care is autonomous after setup but consumes abstract foodRaw
  B7  PARTIAL  causal Teaching proof is command-driven
  B8  PARTIAL  derived specialization is proven but not autonomously exercised
  B9  FAIL     no physical shock -> autonomous review/replacement chain
  B10 PARTIAL  strong local-information components; no composite exercise
  B11 PARTIAL  bounded deterministic components; no composite restore/reconcile run
  B12 FAIL     no autonomous playable passive-observer slice

Primary blockers:
  B-BLOCKER-FOOD-CLOSURE
  B-BLOCKER-AUTONOMOUS-PLAYABLE-SLICE
Additional integrated blockers:
  B-BLOCKER-LIVESTOCK-RESERVE-CLOSURE
  B-BLOCKER-CRISIS-REPLACEMENT-ORCHESTRATION

GATE B CANDIDATE RESULT: FAIL
Automated Integrated Acceptance: FAIL
Playable Passive Observer Slice: FAIL
Real Food-to-Survival Closure: FAIL
Gate R: ACQUIRED
Gate B canonically acquired: NO
EOF

if [ "$REPORT_ONLY" -eq 1 ]; then
    printf '\nREPORT-ONLY: diagnostics complete; FAIL verdict preserved.\n'
    exit 0
fi

exit 2
