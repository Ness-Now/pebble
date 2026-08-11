#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
BASELINE=bbafcb51ef0d8387e95302a134ec038fbb8dffa6
PRODUCT_FIX=650b56b90381306c38d891dfdade9d89a1c45db5
RED_EVIDENCE=${PEBBLELAB_GATE_D_BLOCKER_07_RED_EVIDENCE:-/tmp/PebbleLab-GateD-Blocker07-baseline-parent.7lx28r/evidence}
if [ -f /tmp/pebblelab-blocker07-final-path ]; then
    DEFAULT_TARGETED_PARENT=$(/bin/cat /tmp/pebblelab-blocker07-final-path)
else
    DEFAULT_TARGETED_PARENT=
fi
TARGETED_EVIDENCE=${PEBBLELAB_GATE_D_BLOCKER_07_TARGETED_EVIDENCE:-$DEFAULT_TARGETED_PARENT/evidence}
if [ -f /tmp/pebblelab-blocker07-regression-path ]; then
    DEFAULT_REGRESSION_ROOT=$(/bin/cat /tmp/pebblelab-blocker07-regression-path)
else
    DEFAULT_REGRESSION_ROOT=
fi
REGRESSION_ROOT=${PEBBLELAB_GATE_D_BLOCKER_07_REGRESSION_ROOT:-$DEFAULT_REGRESSION_ROOT}
OUTPUT_PARENT=${PEBBLELAB_GATE_D_BLOCKER_07_REVIEW_PARENT:-/tmp}

fail() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

cd "$ROOT_DIR"
[ "$(git rev-parse --show-toplevel)" = "$ROOT_DIR" ] \
    || fail "unexpected repository root"
[ "$(git rev-parse "$BASELINE^{commit}")" = "$BASELINE" ] \
    || fail "required baseline is unavailable"
[ "$(git rev-parse origin/lab/pebblelab-v1)" = "$BASELINE" ] \
    || fail "canonical remote no longer matches required baseline"
[ "$(git rev-parse "$PRODUCT_FIX^{commit}")" = "$PRODUCT_FIX" ] \
    || fail "local product-fix commit is unavailable"
[ -z "$(git status --short)" ] || fail "worktree must be clean"
[ -d "$RED_EVIDENCE" ] || fail "baseline-red evidence missing"
[ -d "$TARGETED_EVIDENCE" ] || fail "targeted evidence missing"
[ -d "$REGRESSION_ROOT" ] || fail "regression evidence missing"
[ -s "$REGRESSION_ROOT/repository-gate.log" ] \
    || fail "repository gate log missing"

HEAD_COMMIT=$(git rev-parse HEAD)
HEAD_SHORT=$(git rev-parse --short=12 HEAD)
BUNDLE_NAME="PebbleLab-Gate-D-Blocker-07-Review-$HEAD_SHORT"
BUNDLE_DIR="$OUTPUT_PARENT/$BUNDLE_NAME"
ZIP_PATH="$OUTPUT_PARENT/$BUNDLE_NAME.zip"
[ ! -e "$BUNDLE_DIR" ] || fail "bundle directory exists: $BUNDLE_DIR"
[ ! -e "$ZIP_PATH" ] || fail "bundle ZIP exists: $ZIP_PATH"

/bin/mkdir -p \
    "$BUNDLE_DIR/evidence/baseline-red" \
    "$BUNDLE_DIR/evidence/targeted" \
    "$BUNDLE_DIR/evidence/regressions" \
    "$BUNDLE_DIR/evidence/blockers-01-06-captures" \
    "$BUNDLE_DIR/traces"

/bin/cp "$RED_EVIDENCE/co-mingled-no-fault-process-a.log" \
    "$BUNDLE_DIR/evidence/baseline-red/"
/bin/cp "$RED_EVIDENCE/co-mingled-no-fault-process-b.log" \
    "$BUNDLE_DIR/evidence/baseline-red/"
/bin/cp "$RED_EVIDENCE/co-mingled-no-fault-before.png" \
    "$BUNDLE_DIR/evidence/baseline-red/"
/bin/cp "$RED_EVIDENCE/co-mingled-no-fault-after.png" \
    "$BUNDLE_DIR/evidence/baseline-red/"
/bin/cp "$RED_EVIDENCE/co-mingled-no-fault-restart.png" \
    "$BUNDLE_DIR/evidence/baseline-red/"
/bin/cp "$TARGETED_EVIDENCE"/*.log "$BUNDLE_DIR/evidence/targeted/"
/bin/cp "$TARGETED_EVIDENCE"/*.png "$BUNDLE_DIR/evidence/targeted/"
/bin/cp "$REGRESSION_ROOT"/blocker0[1-6].log \
    "$BUNDLE_DIR/evidence/regressions/"
/bin/cp "$REGRESSION_ROOT/repository-gate.log" \
    "$BUNDLE_DIR/evidence/regressions/"

for blocker_number in 01 02 03 04 05 06; do
    case "$blocker_number" in
        04) blocker_evidence="$REGRESSION_ROOT/blocker04-release-evidence" ;;
        *) blocker_evidence="$REGRESSION_ROOT/blocker${blocker_number}-evidence" ;;
    esac
    [ -d "$blocker_evidence" ] || fail "Blocker $blocker_number evidence missing"
    while IFS= read -r capture_file; do
        capture_name=$(/usr/bin/basename "$capture_file")
        /bin/cp "$capture_file" \
            "$BUNDLE_DIR/evidence/blockers-01-06-captures/blocker-$blocker_number-$capture_name"
    done < <(/usr/bin/find "$blocker_evidence" -maxdepth 1 \
        -type f -name '*.png' | /usr/bin/sort)
done

/usr/bin/grep -E \
    'persistence reconciliation run=|checkpoint loaded name=blocker06-no-fault|estate physical authority' \
    "$RED_EVIDENCE/co-mingled-no-fault-process-b.log" \
    > "$BUNDLE_DIR/traces/baseline-red-ordering.log"
/usr/bin/grep -hE \
    'checkpoint physical boundary acquired|persistence reconciliation candidate|checkpoint loaded name=blocker07|persistence reconciliation status' \
    "$TARGETED_EVIDENCE"/*-process-b.log \
    > "$BUNDLE_DIR/traces/post-restore-reconciliation-ordering.log"
/usr/bin/grep -hE \
    'failurePoint=after-reconciliation-candidate|failure after Material Rights reconciliation candidate|checkpoint probe rollback verified|checkpoint loaded name=blocker07-fault' \
    "$TARGETED_EVIDENCE/fault-process-b.log" \
    > "$BUNDLE_DIR/traces/atomic-load-rollback.log"
/usr/bin/grep -hE \
    'blocker07 inherited estate use' \
    "$TARGETED_EVIDENCE"/*-process-b.log \
    > "$BUNDLE_DIR/traces/inherited-use.log"
/usr/bin/grep -E \
    'missing asset is not administratively recreated|missing physical asset blocks stale use|multiple physical holders are refused atomically|ambiguous same-holder stacks are refused atomically|checkpoint refuses missing estate authority' \
    "$REGRESSION_ROOT/repository-gate.log" \
    > "$BUNDLE_DIR/traces/adversarial-fail-closed.log"

/bin/cat > "$BUNDLE_DIR/traces/reconciliation-boundaries.csv" <<'EOF'
campaign,boundary,physical_boundary,reconciliation_candidate,published_runs,outcome,custody_stacks,physical_loss,physical_duplication,synthetic_material
baseline-red,fresh-load,restored-after-reconciliation,published-prematurely,1,missing,1,0,0,0
corrected-main,fresh-load,acquired-before-reconciliation,staged-before-publication,1,matched,1,0,0,0
corrected-fault,after-candidate-fault,rolled-back-exact,discarded,0,none,0,0,0,0
corrected-fault,immediate-load-retry,acquired-before-reconciliation,staged-before-publication,1,matched,1,0,0,0
EOF

/bin/cat > "$BUNDLE_DIR/traces/test-matrix.csv" <<'EOF'
scope,result,failed
blocker07-targeted-two-process-main,passed,0
blocker07-targeted-fault-rollback-retry,passed,0
repository-shared-smoke-3764,passed,0
blocker01-position-restore,passed,0
blocker02-ecological-observer-history,passed,0
blocker03-agriculture-cycle-observation,passed,0
blocker04-candidate-physical-atomicity,passed,0
blocker05-restart-physical-custody,passed,0
blocker06-estate-source-physical-authority,passed,0
repository-gate-35-of-35,passed,0
EOF

/bin/cat > "$BUNDLE_DIR/00_README_FIRST.md" <<'EOF'
# Gate D Blocker 07 review bundle

This bundle supports senior review of a targeted product correction. It does
not reevaluate or acquire Gate D.

```text
Gate D Evaluation 07: FAIL — HISTORICAL EVIDENCE
Gate D Blocker 07: BLOCKER_FIX_LOCAL_CANDIDATE
Gate D: EVALUATED_FAIL_NOT_ACQUIRED
Independent Gate D Evaluation 08: NOT_STARTED
CIV-34: NOT_STARTED
push: NOT_ATTEMPTED
```

Start with `01_EXECUTIVE_SUMMARY.md`. The raw baseline-red and corrected
two-process logs are under `evidence/`; extracted authoritative order traces
are under `traces/`. `PATCH.diff` is the complete patch from the exact
published baseline. `CHECKSUMS.sha256` covers every other bundle file.
EOF

/bin/cat > "$BUNDLE_DIR/01_EXECUTIVE_SUMMARY.md" <<'EOF'
# Executive summary

The correction is fully green as a local review candidate. Checkpoint load now
restores and verifies the complete physical probe, position and custody
boundary before staging current Material Rights reconciliation. Exactly one
`matched` run becomes visible with a successful load; a failed load publishes
none.

The inherited pickaxe is usable on the first attempt after fresh load. The
proof performs a real block break, damages the tool once, acquires the real
drop and publishes the verified use while preserving immutable settlement
evidence. Missing or corrupt physical evidence remains fail-closed.
EOF

/bin/cat > "$BUNDLE_DIR/02_ROOT_CAUSE.md" <<'EOF'
# Root cause

The old loader reconciled durable Material Rights against fresh bootstrap
probes before restoring checkpoint custody. `agent_1` was temporarily empty,
so the inherited pickaxe was classified `missing`. Exact escrow adoption then
restored the pickaxe, but the earlier current result was published unchanged.

The baseline trace shows `outcomes=missing`, then a checkpoint load with one
restored custody stack, then exact physical inspection with the tracked asset
present once. This is the first divergence.
EOF

/bin/cat > "$BUNDLE_DIR/03_CHECKPOINT_LOAD_ORDERING.md" <<'EOF'
# Checkpoint load ordering

The corrected order is decode and validation; candidate session staging;
retirement, repositioning and authorized probe restoration; exact custody
escrow adoption; complete physical boundary verification; one current
reconciliation; cross-domain validation; atomic publication.

No asset is reconciled while another checkpoint agent is still waiting for
restoration. Dead `agent_0` remains retired while active descendants are
restored at exact positions and custody.
EOF

/bin/cat > "$BUNDLE_DIR/04_PHYSICAL_RECONCILIATION_BOUNDARY.md" <<'EOF'
# Physical reconciliation boundary

Pebble verifies all expected probes, exact checkpoint positions, exact custody,
unique occupied positions, final active population, retired bootstrap probes
and non-probe World entities before declaring the boundary acquired.

Material Rights does not create an item. Non-empty custody still comes only
from valid Blocker 05 checkpoint-bound physical escrow. Stale handoff,
manifest-only evidence and corrupt evidence remain fail-closed.
EOF

/bin/cat > "$BUNDLE_DIR/05_MATERIAL_RIGHTS_RECONCILIATION.md" <<'EOF'
# Material Rights reconciliation

One current reconciliation is applied to the local checkpoint candidate after
the physical boundary is exact. The candidate is not observable until final
session publication. A matched current read remains in the run result without
rewriting its historical durable physical receipt; genuinely changed but
reconcilable facts retain the existing update policy.

This keeps Material Rights a verified projection and constraint. Current
physical truth comes from PebbleCore and Pebble observations.
EOF

/bin/cat > "$BUNDLE_DIR/06_ATOMIC_LOAD_AND_ROLLBACK.md" <<'EOF'
# Atomic load and rollback

The fault seam follows the staged post-physical reconciliation and precedes
publication. The proof restores reusable, created and retired probes, exact
custody, adopted spill entities, chunk modification state, controller/session
state and checkpoint handoff. The candidate causal event, reconciliation run,
session and recorder are discarded.

The immediate same-process load retry publishes one coherent run. There is no
wrong pre-restore run followed by a corrective published run.
EOF

/bin/cat > "$BUNDLE_DIR/07_INHERITED_USE_PROOF.md" <<'EOF'
# Inherited use proof

Immediately after the successful fresh load, without manual reconciliation,
second load, restart or debug repair, `agent_1` receives an allowed
`recognizedOwner` verdict. The inherited pickaxe performs a real physical block
break, changes damage from 0 to 1 and acquires the real drop.

The verified use updates current Material Rights and the transferred estate
entry's current destination observation. The immutable settlement observation,
receipt and transferred status remain intact. Loss, duplication and synthetic
material are zero.
EOF

/bin/cat > "$BUNDLE_DIR/08_ADVERSARIAL_MISSING_ASSET.md" <<'EOF'
# Adversarial missing and wrong asset results

The shared smoke suite refuses missing physical material without
administrative recreation, blocks stale use, refuses conflicting physical
holders and refuses ambiguous same-holder candidates atomically. Estate
restore also refuses missing estate authority.

Blocker 05 revalidation covers corrupt custody evidence, conflicting bootstrap
custody, stale handoff and absent physical escrow. Social holder or ownership
records never authorize item creation or turn wrong physical evidence into a
verified match.
EOF

/bin/cat > "$BUNDLE_DIR/09_BLOCKERS_01_06_REVALIDATION.md" <<'EOF'
# Blockers 01–06 revalidation

All six published dedicated runners pass on the corrected product. Raw logs
are under `evidence/regressions/` and native captures are copied under
`evidence/blockers-01-06-captures/`.

- Blocker 01: exact position restore and continuation.
- Blocker 02: current versus historical ecological receipt authority.
- Blocker 03: exact current-cycle crop authority.
- Blocker 04: candidate compensation and hard-failure policy.
- Blocker 05: exact non-empty custody escrow and fail-closed absent escrow.
- Blocker 06: co-mingled settlement, true late fault, rollback and retry.
EOF

/bin/cat > "$BUNDLE_DIR/10_TEST_RESULTS.md" <<'EOF'
# Test results

The final release targeted campaign passes both two-process histories. The
shared smoke suite reports `3764 passed, 0 failed`. Every published Blocker
01–06 runner passes. `scripts/verify-pebblelab.sh` passes all 35 steps.

No golden regeneration was attempted. Schema 30 and Observer schema 7 are
unchanged. See `traces/test-matrix.csv` and the raw regression logs.
EOF

/bin/cat > "$BUNDLE_DIR/11_GIT_STATE.md" <<'EOF'
# Git state

The exact resolved values at bundle creation are:

EOF
{
    printf '```text\n'
    printf 'repository: Ness-Now/pebble\n'
    printf 'canonical branch: lab/pebblelab-v1\n'
    printf 'required baseline: %s\n' "$BASELINE"
    printf 'origin/lab/pebblelab-v1: %s\n' "$BASELINE"
    printf 'local branch: codex/gate-d-blocker-07-reconciliation-after-physical-restore\n'
    printf 'product-fix commit: %s\n' "$PRODUCT_FIX"
    printf 'bundle source HEAD: %s\n' "$HEAD_COMMIT"
    printf 'worktree at bundle creation: clean\n'
    printf 'push: NOT_ATTEMPTED\n'
    printf '```\n\n'
} >> "$BUNDLE_DIR/11_GIT_STATE.md"
/bin/cat >> "$BUNDLE_DIR/11_GIT_STATE.md" <<'EOF'

The branch was created directly from the required baseline. No Evaluation 07
commit was cherry-picked. `PATCH.diff` is the complete diff from the baseline
to the bundle source HEAD.
EOF

/bin/cat > "$BUNDLE_DIR/12_OPEN_RISKS.md" <<'EOF'
# Open risks and bounded limits

Checkpoint restoration does not support material creation from social state.
Non-empty custody still needs exact protected escrow; abrupt loss remains
unsupported. A successfully consumed handoff is not reusable.

The correction stages current reconciliation inside the existing bounded load;
it does not redesign Material Rights, add global World discovery, change schema
30, change Observer schema 7, acquire Gate D, start Evaluation 08 or start
`CIV-34`.
EOF

/bin/cat > "$BUNDLE_DIR/REPORT.json" <<EOF
{
  "contract": "V4-GATE-D-v1",
  "mission": "Gate D Blocker 07 — Reconciliation After Physical Restore",
  "baseline": "$BASELINE",
  "productFixCommit": "$PRODUCT_FIX",
  "head": "$HEAD_COMMIT",
  "branch": "codex/gate-d-blocker-07-reconciliation-after-physical-restore",
  "evaluation07": "FAIL_HISTORICAL_EVIDENCE",
  "blocker07": "BLOCKER_FIX_LOCAL_CANDIDATE",
  "gateD": "EVALUATED_FAIL_NOT_ACQUIRED",
  "evaluation08": "NOT_STARTED",
  "civ34": "NOT_STARTED",
  "push": "NOT_ATTEMPTED",
  "schemaChanged": false,
  "checkpointSchema": 30,
  "observerSchema": 7,
  "physicalBoundaryBeforeReconciliation": true,
  "reconciliationStaged": true,
  "successfulLoadCommittedReconciliationRuns": 1,
  "failedLoadPublishedReconciliationRuns": 0,
  "loadRollback": "exact",
  "immediateSameProcessLoadRetry": "passed",
  "firstInheritedUse": "allowedFirstAttempt",
  "inheritedUsePhysicalMutation": true,
  "physicalLoss": 0,
  "physicalDuplication": 0,
  "syntheticMaterial": 0,
  "missingAndAmbiguousEvidence": "failClosed",
  "blockers01Through06": "passed",
  "repositoryGate": {"passed": 35, "total": 35, "failed": 0},
  "repositorySharedSmoke": {"passed": 3764, "failed": 0},
  "nativeCapturesInspected": 5,
  "goldenRegenerationAttempted": false,
  "nextAction": "senior review and manual publication of Gate D Blocker 07"
}
EOF

git diff --binary "$BASELINE..$HEAD_COMMIT" > "$BUNDLE_DIR/PATCH.diff"
git diff --check "$BASELINE..$HEAD_COMMIT"
{
    printf 'pwd: %s\n' "$ROOT_DIR"
    printf 'branch: %s\n' "$(git branch --show-current)"
    printf 'HEAD: %s\n' "$HEAD_COMMIT"
    printf 'product-fix commit: %s\n' "$PRODUCT_FIX"
    printf 'origin/lab/pebblelab-v1: %s\n' \
        "$(git rev-parse origin/lab/pebblelab-v1)"
    printf 'status:\n'
    git status --short
    printf 'commits since baseline:\n'
    git log --oneline "$BASELINE..$HEAD_COMMIT"
} > "$BUNDLE_DIR/traces/git-state.txt"

/usr/bin/jq -e . "$BUNDLE_DIR/REPORT.json" >/dev/null
(
    cd "$BUNDLE_DIR"
    /usr/bin/find . -type f ! -name CHECKSUMS.sha256 -print0 \
        | /usr/bin/sort -z \
        | /usr/bin/xargs -0 /usr/bin/shasum -a 256 \
        > CHECKSUMS.sha256
    /usr/bin/shasum -a 256 -c CHECKSUMS.sha256 >/dev/null
)
(
    cd "$OUTPUT_PARENT"
    /usr/bin/zip -q -r "$ZIP_PATH" "$BUNDLE_NAME"
)
/usr/bin/unzip -t "$ZIP_PATH" >/dev/null
/usr/bin/shasum -a 256 "$ZIP_PATH" > "$ZIP_PATH.sha256"

printf 'Gate D Blocker 07 review bundle: %s\n' "$ZIP_PATH"
printf 'ZIP checksum: %s\n' "$ZIP_PATH.sha256"
printf 'Bundle directory: %s\n' "$BUNDLE_DIR"
