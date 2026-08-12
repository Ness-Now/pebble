#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
BASELINE=02c7778769c8a6d971f4eb8bd73e5a3f7afc8c1e
PRODUCT_FIX=a7f1fd7bf92a6d049d7601945209eb9c98d06058
EVALUATION_08=c08f26ce575c814ad200779ff3d26ca430ee02d7
RED_EVIDENCE=${PEBBLELAB_GATE_D_BLOCKER_08_RED_EVIDENCE:-/tmp/PebbleLab-GateD-Blocker08-WIP-Red-1307134}
TARGETED_EVIDENCE=${PEBBLELAB_GATE_D_BLOCKER_08_TARGETED_EVIDENCE:-/tmp/PebbleLab-GateD-Blocker08-WIP-Green-1307134}
BLOCKER_01_EVIDENCE=${PEBBLELAB_GATE_D_BLOCKER_08_BLOCKER_01_EVIDENCE:-/tmp/PebbleLab-GateD-Blocker08-WIP-B01-1307134}
BLOCKER_05_EVIDENCE=${PEBBLELAB_GATE_D_BLOCKER_08_BLOCKER_05_EVIDENCE:-/tmp/PebbleLab-GateD-Blocker08-WIP-B05-1307134}
BLOCKER_07_EVIDENCE=${PEBBLELAB_GATE_D_BLOCKER_08_BLOCKER_07_EVIDENCE:-/tmp/PebbleLab-GateD-Blocker08-WIP-B07-1307134}
REGRESSION_ROOT=${PEBBLELAB_GATE_D_BLOCKER_08_REGRESSION_ROOT:-/tmp/PebbleLab-GateD-Blocker08-Regressions}
REPOSITORY_GATE_LOG=${PEBBLELAB_GATE_D_BLOCKER_08_REPOSITORY_GATE_LOG:-/tmp/PebbleLab-GateD-Blocker08-Final-Repository-Gate.log}
OUTPUT_PARENT=${PEBBLELAB_GATE_D_BLOCKER_08_REVIEW_PARENT:-/tmp}

fail() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

copy_tree() {
    source_dir=$1
    destination_dir=$2
    /bin/mkdir -p "$destination_dir"
    /bin/cp -R "$source_dir"/. "$destination_dir"/
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
git merge-base --is-ancestor "$PRODUCT_FIX" HEAD \
    || fail "product-fix commit is not an ancestor of review HEAD"
if git merge-base --is-ancestor "$EVALUATION_08" HEAD; then
    fail "Evaluation 08 evidence commit must not be an ancestor"
fi
[ -z "$(git status --short)" ] || fail "worktree must be clean"

for required_dir in \
    "$RED_EVIDENCE" \
    "$TARGETED_EVIDENCE" \
    "$BLOCKER_01_EVIDENCE" \
    "$BLOCKER_05_EVIDENCE" \
    "$BLOCKER_07_EVIDENCE" \
    "$REGRESSION_ROOT"; do
    [ -d "$required_dir" ] || fail "evidence directory missing: $required_dir"
done
[ -s "$REPOSITORY_GATE_LOG" ] || fail "repository gate log missing"

/usr/bin/grep -q \
    'invalid physical creation position for agent_3:entityCollision' \
    "$RED_EVIDENCE/baseline-red.log" \
    || fail "baseline-red entityCollision missing"
/usr/bin/grep -q \
    'checkpoint probe rollback verified name=e08-succession' \
    "$RED_EVIDENCE/baseline-red.log" \
    || fail "baseline-red rollback evidence missing"
/usr/bin/grep -q \
    'persistence reconciliation status enabled=0 runs=0' \
    "$RED_EVIDENCE/baseline-red.log" \
    || fail "baseline-red zero-reconciliation evidence missing"
/usr/bin/jq -e '
    .mixedPlan.reusedExact == 1
    and .mixedPlan.repositioned == 1
    and .mixedPlan.restoredMissing == 2
    and .mixedPlan.retired == 1
    and .physicalBoundary == "acquired"
    and .committedCurrentReconciliationThisLoad == 1
    and .firstInheritedUse == "allowed"
    and .physicalLoss == 0
    and .physicalDuplication == 0
    and .syntheticMaterial == 0
    and .duplicateProbes == 0
' "$TARGETED_EVIDENCE/result.json" >/dev/null \
    || fail "targeted result contract is not green"
/usr/bin/grep -q 'PASS: all 35 PebbleLab verification steps succeeded' \
    "$REPOSITORY_GATE_LOG" \
    || fail "repository gate did not pass 35/35"
/usr/bin/grep -q '3768 passed, 0 failed' "$REPOSITORY_GATE_LOG" \
    || fail "repository assertion count is not 3768/0"

HEAD_COMMIT=$(git rev-parse HEAD)
HEAD_SHORT=$(git rev-parse --short=12 HEAD)
BUNDLE_NAME="PebbleLab-Gate-D-Blocker-08-Review-$HEAD_SHORT"
BUNDLE_DIR="$OUTPUT_PARENT/$BUNDLE_NAME"
ZIP_PATH="$OUTPUT_PARENT/$BUNDLE_NAME.zip"
[ ! -e "$BUNDLE_DIR" ] || fail "bundle directory exists: $BUNDLE_DIR"
[ ! -e "$ZIP_PATH" ] || fail "bundle ZIP exists: $ZIP_PATH"

/bin/mkdir -p \
    "$BUNDLE_DIR/evidence" \
    "$BUNDLE_DIR/evidence/exact-reruns" \
    "$BUNDLE_DIR/evidence/prior-same-runtime-reruns" \
    "$BUNDLE_DIR/traces"
copy_tree "$RED_EVIDENCE" "$BUNDLE_DIR/evidence/baseline-red"
copy_tree "$TARGETED_EVIDENCE" "$BUNDLE_DIR/evidence/blocker08-targeted"
copy_tree "$BLOCKER_01_EVIDENCE" "$BUNDLE_DIR/evidence/exact-reruns/blocker01"
copy_tree "$BLOCKER_05_EVIDENCE" "$BUNDLE_DIR/evidence/exact-reruns/blocker05"
copy_tree "$BLOCKER_07_EVIDENCE" "$BUNDLE_DIR/evidence/exact-reruns/blocker07"

for blocker in 02 03 04 06; do
    /bin/cp "$REGRESSION_ROOT/blocker-$blocker.log" \
        "$BUNDLE_DIR/evidence/prior-same-runtime-reruns/"
done
/bin/cp /tmp/PebbleLab-GateD-Blocker08-WIP-B01-1307134.log \
    "$BUNDLE_DIR/evidence/exact-reruns/blocker01-runner.log"
/bin/cp /tmp/PebbleLab-GateD-Blocker08-WIP-B05-1307134.log \
    "$BUNDLE_DIR/evidence/exact-reruns/blocker05-runner.log"
/bin/cp /tmp/PebbleLab-GateD-Blocker08-WIP-B07-1307134.log \
    "$BUNDLE_DIR/evidence/exact-reruns/blocker07-runner.log"
/bin/cp "$REPOSITORY_GATE_LOG" \
    "$BUNDLE_DIR/evidence/final-repository-gate.log"

/usr/bin/grep -E \
    'checkpoint probe classification|checkpoint collective placement authority|createProbe|entityCollision|rollback verified|error PebbleAgents checkpoint' \
    "$RED_EVIDENCE/baseline-red.log" \
    > "$BUNDLE_DIR/traces/baseline-red-first-divergence.log"
/usr/bin/grep -E \
    'checkpoint collective placement semantics|checkpoint collective placement authority|checkpoint missing probe application order|checkpoint missing probe created|checkpoint physical boundary acquired|persistence reconciliation candidate|checkpoint loaded name=e08-succession' \
    "$TARGETED_EVIDENCE/normal-order.log" \
    > "$BUNDLE_DIR/traces/normal-collective-application.log"
/usr/bin/grep -E \
    'checkpoint missing probe application order|checkpoint missing probe created|checkpoint physical boundary acquired|checkpoint loaded name=e08-succession' \
    "$TARGETED_EVIDENCE/reverse-order.log" \
    > "$BUNDLE_DIR/traces/reverse-collective-application.log"
/usr/bin/grep -E \
    'checkpoint collective placement authority|checkpoint collective mixed plan|checkpoint physical boundary acquired|persistence reconciliation candidate|checkpoint loaded name=e08-succession' \
    "$TARGETED_EVIDENCE/mixed-plan.log" \
    > "$BUNDLE_DIR/traces/mixed-plan.log"
/usr/bin/grep -E \
    'after first missing creation|checkpoint probe rollback verified|failurePoint=after-first-missing|checkpoint missing probe created|checkpoint loaded name=e08-succession' \
    "$TARGETED_EVIDENCE/normal-order.log" \
    > "$BUNDLE_DIR/traces/partial-creation-rollback-and-retry.log"
/usr/bin/grep -E \
    'persistence reconciliation candidate|after Material Rights reconciliation candidate|checkpoint probe rollback verified|checkpoint loaded name=blocker07-fault' \
    "$BLOCKER_07_EVIDENCE/fault-process-b.log" \
    > "$BUNDLE_DIR/traces/post-boundary-rollback-and-retry.log"
/usr/bin/grep -E \
    'blocker07 inherited estate use|estate physical authority|persistence reconciliation status' \
    "$TARGETED_EVIDENCE/normal-order.log" \
    > "$BUNDLE_DIR/traces/e08-decisive-continuation.log"
/usr/bin/grep -E \
    'foreignCollision=refused|actualOverlap=refused|adjacent=valid' \
    "$TARGETED_EVIDENCE/normal-order.log" \
    > "$BUNDLE_DIR/traces/collision-semantics.log"

/bin/cat > "$BUNDLE_DIR/traces/mixed-plan.csv" <<'EOF'
classification,count,result
reused_exact,1,exact
repositioned_verified,1,exact
restored_missing,2,exact
retired,1,exact
complete_physical_boundary,1,acquired
current_reconciliation_committed,1,exact
EOF

/bin/cat > "$BUNDLE_DIR/traces/conservation.csv" <<'EOF'
boundary,physicalLoss,physicalDuplication,syntheticMaterial,duplicateProbes,publishedReconciliationRuns
failed-partial-creation,0,0,0,0,0
failed-post-reconciliation-candidate,0,0,0,0,0
successful-normal-load,0,0,0,0,1
successful-reverse-load,0,0,0,0,1
successful-mixed-load,0,0,0,0,1
EOF

/bin/cat > "$BUNDLE_DIR/00_README_FIRST.md" <<'EOF'
# Gate D Blocker 08 senior-review bundle

This bundle supports review of one targeted local product correction. It does
not reevaluate or acquire Gate D.

```text
Gate D Evaluation 08: EVALUATED_FAIL_NOT_ACQUIRED — HISTORICAL EVIDENCE
Gate D Blocker 08: BLOCKER_FIX_LOCAL_CANDIDATE
Gate D: EVALUATED_FAIL_NOT_ACQUIRED
Independent Gate D Evaluation 09: NOT_STARTED
CIV-34: NOT_STARTED
push: NOT_ATTEMPTED
```

Raw baseline-red, targeted, exact rerun, native-capture and repository-gate
evidence is under `evidence/`. Machine-authoritative excerpts and conservation
tables are under `traces/`. `PATCH.diff` is against the exact published
baseline. `CHECKSUMS.sha256` covers every other file.
EOF

/bin/cat > "$BUNDLE_DIR/01_EXECUTIVE_SUMMARY.md" <<'EOF'
# Executive summary

The local candidate fixes the false collision that occurred when a collectively
valid checkpoint target layout was rejudged by isolated missing-probe creation.
One bounded complete-target authority now survives from collective validation
through exact application and final physical-boundary verification.

Adjacent layouts restore; true overlap and foreign World collision fail before
mutation. Normal, reversed and mixed application all restore exact positions
and custody. Both partial-creation and post-reconciliation candidate faults
rollback exactly and retry immediately. Successful load commits one current
reconciliation; failed loads commit zero. First inherited use performs a real
physical mutation. The final repository gate is 35/35 and 3768/0.
EOF

/bin/cat > "$BUNDLE_DIR/02_ROOT_CAUSE.md" <<'EOF'
# Root cause

Evaluation 08 saved a valid adjacent descendant layout. The restore planner
accepted the complete target set, but baseline `createProbe(agent_3)` repeated
ordinary isolated placement validation against transient plan-owned probes and
escrow. It returned `entityCollision` before physical-boundary acquisition.

Rollback was already exact, so retries repeated the same false refusal without
leaking probes, custody, session state or reconciliation runs. The first
divergence is preserved in `traces/baseline-red-first-divergence.log`.
EOF

/bin/cp docs/pebblelab/GATE_D_BLOCKER_08_COLLECTIVE_PROBE_RESTORE_PLACEMENT.md \
    "$BUNDLE_DIR/03_COLLECTIVE_PLACEMENT_AUTHORITY.md"

/bin/cat > "$BUNDLE_DIR/04_RESTORE_PLAN_AND_APPLICATION.md" <<'EOF'
# Restore plan and application

The loader classifies the complete target as reused, repositioned, missing or
retired, then validates all target AABBs against PebbleCore. The acquired
authority binds exact World identity, agent identities, positions and only the
transaction-owned current entities that may be ignored during application.

Retirement, repositioning, missing-probe creation and custody adoption are
followed by an exact final whole-set verification. No target position is
invented. The authority is candidate-local, never durable or generally usable.
EOF

/bin/cat > "$BUNDLE_DIR/05_COLLISION_SEMANTICS.md" <<'EOF'
# Collision semantics

Adjacency is determined by actual PebbleCore AABBs, not Manhattan distance.
Non-intersecting adjacent targets pass. Two intersecting target bodies fail
collective validation before mutation. A foreign collision-authoritative World
entity fails closed with no relocation or publication.

Transaction-owned probes and custody spills may be excluded only from their
old transient positions for the matching candidate. Target bodies remain
mutually checked, and ordinary probe creation remains collision-authoritative.
EOF

/bin/cat > "$BUNDLE_DIR/06_MIXED_PLAN_PROOF.md" <<'EOF'
# Mixed plan proof

One independent load composes one `reused_exact`, one
`repositioned_verified`, two `restored_missing` and one `retired` probe. All
four active descendants end at their exact saved positions; the dead bootstrap
parent is absent; protected custody is restored to the correct identities; and
the complete physical boundary is acquired before one current reconciliation.

The result is recorded in `evidence/blocker08-targeted/result.json` and
`traces/mixed-plan.csv`.
EOF

/bin/cat > "$BUNDLE_DIR/07_PARTIAL_CREATION_ROLLBACK.md" <<'EOF'
# Partial creation rollback

The injected fault follows creation of the first missing probe. Rollback
removes every created probe, restores repositioned and retired bootstrap probes,
mapping, positions, custody spills, chunk state, session and recorder. It
publishes zero reconciliation runs and leaks no probe or material.

Immediate same-process load retry succeeds without manual repair. The existing
post-reconciliation-candidate fault proves the later Blocker 07 rollback
boundary remains exact under the new placement mechanism.
EOF

/bin/cat > "$BUNDLE_DIR/08_PHYSICAL_BOUNDARY_AND_RECONCILIATION.md" <<'EOF'
# Physical boundary and reconciliation

Final verification proves active session IDs equal active physical probe IDs,
with one exact probe per identity, exact World and position, exact custody, no
unexpected Lab probe and no target overlap. Only then is the physical
checkpoint boundary acquired.

Material Rights reconciliation is staged after that boundary. Successful load
publishes exactly one current run. Failed placement and failed later candidates
publish zero. Material Rights remains a constraint and verified projection,
never physical restoration authority.
EOF

/bin/cat > "$BUNDLE_DIR/09_E08_DECISIVE_CONTINUATION.md" <<'EOF'
# Evaluation 08 decisive continuation

The previously blocked succession checkpoint now restores both missing
descendants, exact protected custody and one coherent current reconciliation.
The inherited pickaxe is used on the first attempt without manual
reconciliation, second load or second-use workaround.

The action changes pickaxe damage from 0 to 1, removes one real World block and
acquires its real drop. Historical settlement receipt remains preserved while
the current destination observation advances.
EOF

/bin/cat > "$BUNDLE_DIR/10_BLOCKERS_REVALIDATION.md" <<'EOF'
# Blockers revalidation

Exact final-tree release reruns pass for Blocker 01 position restore, Blocker
05 physical custody escrow and Blocker 07 post-physical reconciliation. The
dedicated Blocker 08 runner passes all target, collision, order, rollback and
continuation contracts.

Blockers 02, 03, 04 and 06 passed the earlier same-runtime campaign. The only
post-campaign addition was gated mixed-plan proof instrumentation; it did not
alter product restore semantics. The final canonical 35/35 gate covers the
complete final runtime again.
EOF

/bin/cat > "$BUNDLE_DIR/11_TEST_RESULTS.md" <<'EOF'
# Test results

```text
Blocker 08 dedicated runner: PASS
PebbleCore placement smoke: 18/18
Blocker 01 exact final rerun: PASS
Blocker 05 exact final rerun: PASS
Blocker 07 exact final rerun: PASS
Blockers 02, 03, 04 and 06 same-runtime reruns: PASS
canonical repository gate: 35/35
repository shared assertions: 3768 passed, 0 failed
golden regeneration: NOT ATTEMPTED
```
EOF

{
    printf '# Git state\n\n'
    printf '%s\n' '```text'
    printf 'baseline: %s\n' "$BASELINE"
    printf 'product fix: %s\n' "$PRODUCT_FIX"
    printf 'review HEAD: %s\n' "$HEAD_COMMIT"
    printf '%s\n' \
        'branch: codex/gate-d-blocker-08-collective-probe-restore-placement'
    printf '%s\n' 'Evaluation 08 commit ancestor: NO'
    printf '%s\n' 'worktree at bundle build: clean'
    printf '%s\n' 'push attempted: NO'
    printf '%s\n' '```'
} > "$BUNDLE_DIR/12_GIT_STATE.md"

/bin/cat > "$BUNDLE_DIR/13_OPEN_RISKS.md" <<'EOF'
# Open risks and limits

- Senior review and manual publication remain required.
- Evaluation 08 remains immutable historical FAIL evidence; Gate D is not
  acquired and Evaluation 09 is not started.
- Real external World changes may legitimately make an old checkpoint collide
  and fail closed.
- Non-empty nonpersistent custody still requires exact Blocker 05
  checkpoint-bound physical escrow; manifest state does not create matter.
- Abrupt-loss support, nearest-free relocation and reusable consumed escrow are
  not claimed.
EOF

/usr/bin/git diff --binary "$BASELINE"..HEAD > "$BUNDLE_DIR/PATCH.diff"

/usr/bin/jq -n \
    --arg baseline "$BASELINE" \
    --arg productFix "$PRODUCT_FIX" \
    --arg reviewHead "$HEAD_COMMIT" \
    '{
      verdict: "BLOCKER_FIX_LOCAL_CANDIDATE",
      gateDEvaluation08: "evaluatedFailNotAcquiredHistoricalEvidence",
      gateD: "evaluatedFailNotAcquired",
      evaluation09: "notStarted",
      civ34: "notStarted",
      baseline: $baseline,
      productFixCommit: $productFix,
      reviewHead: $reviewHead,
      placement: {
        adjacent: "restored",
        overlap: "refusedBeforeMutation",
        foreignCollision: "refusedBeforeMutation",
        normalOrder: ["agent_3", "agent_4"],
        reverseOrder: ["agent_4", "agent_3"]
      },
      mixedPlan: {
        reusedExact: 1,
        repositionedVerified: 1,
        restoredMissing: 2,
        retired: 1
      },
      rollback: {
        partialCreation: "exact",
        postReconciliationCandidate: "exact",
        immediateRetries: "passed"
      },
      reconciliation: {
        successfulLoadCommittedRuns: 1,
        failedLoadPublishedRuns: 0
      },
      inheritedFirstUse: "allowedWithPhysicalMutation",
      conservation: {
        physicalLoss: 0,
        physicalDuplication: 0,
        syntheticMaterial: 0,
        duplicateProbes: 0,
        observerMutationCount: 0
      },
      validation: {
        repositoryStepsPassed: 35,
        repositoryStepsTotal: 35,
        assertionsPassed: 3768,
        assertionsFailed: 0,
        checkpointSchema: 30,
        observerSchema: 7,
        goldenRegenerationAttempted: false
      },
      pushAttempted: false
    }' > "$BUNDLE_DIR/REPORT.json"

(
    cd "$BUNDLE_DIR"
    /usr/bin/find . -type f ! -name CHECKSUMS.sha256 -print \
        | LC_ALL=C /usr/bin/sort \
        | while IFS= read -r bundle_file; do
            /usr/bin/shasum -a 256 "$bundle_file"
        done > CHECKSUMS.sha256
)

(
    cd "$OUTPUT_PARENT"
    /usr/bin/zip -q -r "$ZIP_PATH" "$BUNDLE_NAME"
)

printf 'Bundle: %s\n' "$BUNDLE_DIR"
printf 'ZIP: %s\n' "$ZIP_PATH"
/usr/bin/shasum -a 256 "$ZIP_PATH"
printf 'Internal checksums: '
/usr/bin/wc -l < "$BUNDLE_DIR/CHECKSUMS.sha256"
