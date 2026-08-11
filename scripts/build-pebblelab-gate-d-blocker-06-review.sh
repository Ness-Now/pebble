#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
BASELINE=82a2e50da4db2fe861b88801e033788a2de16dd4
RED_EVIDENCE=${PEBBLELAB_GATE_D_BLOCKER_06_RED_EVIDENCE:-/tmp/PebbleLab-GateD-Blocker06.eR3gYx}
TARGETED_EVIDENCE=${PEBBLELAB_GATE_D_BLOCKER_06_TARGETED_EVIDENCE:-/tmp/PebbleLab-GateD-Blocker06-Targeted-03}
REGRESSION_EVIDENCE=${PEBBLELAB_GATE_D_BLOCKER_06_REGRESSION_EVIDENCE:-/tmp/PebbleLab-GateD-Blocker06-Regression-01}
OUTPUT_PARENT=${PEBBLELAB_GATE_D_BLOCKER_06_REVIEW_PARENT:-/tmp}

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
[ -z "$(git status --short)" ] || fail "worktree must be clean"
[ -d "$RED_EVIDENCE" ] || fail "baseline-red evidence missing"
[ -d "$TARGETED_EVIDENCE" ] || fail "targeted evidence missing"
[ -d "$REGRESSION_EVIDENCE" ] || fail "regression evidence missing"

HEAD_COMMIT=$(git rev-parse HEAD)
HEAD_SHORT=$(git rev-parse --short=12 HEAD)
BUNDLE_NAME="PebbleLab-Gate-D-Blocker-06-Review-$HEAD_SHORT"
BUNDLE_DIR="$OUTPUT_PARENT/$BUNDLE_NAME"
ZIP_PATH="$OUTPUT_PARENT/$BUNDLE_NAME.zip"
[ ! -e "$BUNDLE_DIR" ] || fail "bundle directory exists: $BUNDLE_DIR"
[ ! -e "$ZIP_PATH" ] || fail "bundle ZIP exists: $ZIP_PATH"

/bin/mkdir -p \
    "$BUNDLE_DIR/evidence/baseline-red" \
    "$BUNDLE_DIR/evidence/targeted" \
    "$BUNDLE_DIR/evidence/regressions" \
    "$BUNDLE_DIR/evidence/blockers-01-05-captures" \
    "$BUNDLE_DIR/traces"

/bin/cp "$RED_EVIDENCE/co-mingled-no-fault.log" \
    "$BUNDLE_DIR/evidence/baseline-red/"
/bin/cp "$RED_EVIDENCE/co-mingled-no-fault.png" \
    "$BUNDLE_DIR/evidence/baseline-red/"
/bin/cp "$TARGETED_EVIDENCE"/*.log "$BUNDLE_DIR/evidence/targeted/"
/bin/cp "$TARGETED_EVIDENCE"/*.png "$BUNDLE_DIR/evidence/targeted/"
/bin/cp "$REGRESSION_EVIDENCE"/*.log \
    "$BUNDLE_DIR/evidence/regressions/"

for blocker_number in 01 02 03 04 05; do
    blocker_log="$REGRESSION_EVIDENCE/blocker-$blocker_number.log"
    blocker_evidence=$(
        /usr/bin/grep -Eo 'Evidence: /tmp/[^[:space:]]+' "$blocker_log" \
            | /usr/bin/tail -n 1 | /usr/bin/cut -d' ' -f2-
    )
    if [ -d "$blocker_evidence" ]; then
        while IFS= read -r capture_file; do
            capture_name=$(/usr/bin/basename "$capture_file")
            /bin/cp "$capture_file" \
                "$BUNDLE_DIR/evidence/blockers-01-05-captures/blocker-$blocker_number-$capture_name"
        done < <(/usr/bin/find "$blocker_evidence" -maxdepth 1 \
            -type f -name '*.png' | /usr/bin/sort)
    fi
done

/usr/bin/grep -E \
    'estate co-mingled proof setup|mortality physical custody|Estate boundary refused|estate asset settled|estate physical authority' \
    "$RED_EVIDENCE/co-mingled-no-fault.log" \
    > "$BUNDLE_DIR/traces/baseline-red-first-divergence.log"
/usr/bin/grep -hE \
    'estate source authority adversarial|estate rollback proof refused|estate settlement rollback lateFailure=verified|estate asset settled|estate physical authority' \
    "$TARGETED_EVIDENCE"/*.log \
    > "$BUNDLE_DIR/traces/estate-authority-and-rollback.log"
/usr/bin/grep -hE \
    'checkpoint saved name=blocker06|checkpoint loaded name=blocker06|estate blocker06 cleanup|stop probesRemoved' \
    "$TARGETED_EVIDENCE"/*.log \
    > "$BUNDLE_DIR/traces/restart-and-cleanup.log"

/bin/cat > "$BUNDLE_DIR/traces/conservation.csv" <<'EOF'
campaign,boundary,tracked_pickaxe_total,unrelated_hoe_total,physical_loss,physical_duplication,synthetic_material,estate_receipts,duplicate_receipts
no-fault,after-settlement,1,1,0,0,0,1,0
no-fault,after-fresh-restart,1,1,0,0,0,1,0
late-fault,after-exact-rollback,1,1,0,0,0,0,0
late-fault,after-immediate-retry,1,1,0,0,0,1,0
late-fault,after-fresh-restart,1,1,0,0,0,1,0
EOF

/bin/cat > "$BUNDLE_DIR/traces/test-matrix.csv" <<'EOF'
scope,passed,failed
estates-inheritance-succession,84,0
mortality-physical-exit,93,0
homeostasis-health,30,0
material-custody,35,0
material-rights,21,0
checkpoint-replay,49,0
persistence-reconciliation,18,0
repository-shared-smoke,3761,0
repository-gate-steps,35,0
EOF

/bin/cat > "$BUNDLE_DIR/00_README_FIRST.md" <<'EOF'
# Gate D Blocker 06 review bundle

This bundle supports senior review of a targeted product correction. It does
not reevaluate or acquire Gate D.

```text
Gate D Evaluation 06: FAIL — HISTORICAL EVIDENCE
Gate D Blocker 06: BLOCKER_FIX_LOCAL_CANDIDATE
Gate D: EVALUATED_FAIL_NOT_ACQUIRED
CIV-34: NOT_STARTED
push: NOT_ATTEMPTED
```

Start with `01_EXECUTIVE_SUMMARY.md`, then inspect the authority and
transaction reports, `traces/`, and the raw Process A/B logs under
`evidence/targeted/`. `PATCH.diff` is the complete patch against the exact
published baseline. `CHECKSUMS.sha256` covers every other file in this
directory.
EOF

/bin/cat > "$BUNDLE_DIR/01_EXECUTIVE_SUMMARY.md" <<'EOF'
# Executive summary

The correction is fully green as a local review candidate. One estate-tracked
`iron_pickaxe ×1` remains immediately settlable when normal mortality adds an
unrelated `iron_hoe ×1` to the same durable container. The pickaxe transfers
once; the hoe stays once; loss, duplication and synthetic material remain zero.

Asset-scoped physical authority now reacquires the current real holder state
and uses the current complete fingerprint only as the immediate atomic gateway
precondition. True changes to the tracked stack remain fail-closed.

The rollback proof can report `lateFailure=verified` only after a successful
physical transfer and exact post-mutation verification. The injected failure
rolls back physical and civilization state exactly, and immediate same-process
retry succeeds without restart or reconciliation.
EOF

/bin/cat > "$BUNDLE_DIR/02_ROOT_CAUSE.md" <<'EOF'
# Root cause

The estate entry retained a full-container fingerprint observed at opening.
Mortality later added an unrelated hoe to that container. The tracked pickaxe
was unchanged, but the container fingerprint drifted, so settlement refused
`stale estate source` before mutation.

Fresh reconciliation later appeared to repair the condition because it
reacquired a current exact holder observation. Separately, the old rollback
proof accepted any settlement error and mislabeled this pre-mutation refusal
as a verified late rollback.

The baseline-red log records the first divergence and the absence of a
settlement publication.
EOF

/bin/cat > "$BUNDLE_DIR/03_ESTATE_PHYSICAL_AUTHORITY.md" <<'EOF'
# Estate physical authority

Durable authority remains the estate entry, expected holder, exact material
identity and exact quantity, plus existing estate and rights constraints.
PebbleCore remains physical truth. Pebble reacquires exactly one matching stack
at the expected holder. The resulting current endpoint fingerprint is used
only as the next gateway mutation's atomic precondition.

The operation refuses missing, changed, wrong-quantity, wrong-holder or
multiple indistinguishable matching stacks. No new material identity or schema
was introduced.
EOF

/bin/cat > "$BUNDLE_DIR/04_CO_MINGLED_CUSTODY_DESIGN.md" <<'EOF'
# Co-mingled custody design

Unrelated slot drift does not identify or invalidate the tracked asset. The
proof covers an unrelated item added by normal mortality and an unrelated item
temporarily removed by adversarial instrumentation. Both retain exact tracked
authority.

Settlement extracts only the exact tracked pickaxe. The unrelated hoe remains
in the durable source container and remains socially blocked because it has no
Material Rights registration. Conservation is tabulated in
`traces/conservation.csv`.
EOF

/bin/cat > "$BUNDLE_DIR/05_SETTLEMENT_TRANSACTION_BOUNDARY.md" <<'EOF'
# Settlement transaction boundary

The order is durable authority validation, current source observation, current
source/destination fingerprints, gateway transfer, exact physical verification,
estate and Material Rights candidate construction, replay/receipt staging, then
publication. Any physical late failure is compensated by the existing gateway.

The source and destination must each have an unambiguous tracked state. A
same-identity destination stack is refused instead of relying on a merge that
would erase the one-stack association.
EOF

/bin/cat > "$BUNDLE_DIR/06_TRUE_LATE_FAULT_PROOF.md" <<'EOF'
# True late-fault proof

The dedicated seam is reached only after the transfer is physically written
and the expected source/destination states are re-read and verified. The trace
then records `physicalMutationOccurred=1`, `postMutationVerified=1` and
`faultInjectionReached=1`.

A deliberately stale wrong-holder source instead records seam 0, mutation 0,
late verification 0 and no rollback claim. Thus a pre-mutation refusal cannot
masquerade as rollback evidence.
EOF

/bin/cat > "$BUNDLE_DIR/07_ROLLBACK_AND_IMMEDIATE_RETRY.md" <<'EOF'
# Rollback and immediate retry

After the true late fault, source pickaxe and hoe, destination, estate,
Material Rights, session, recorder/replay and gateway receipts match their
pre-action state exactly. No settlement receipt survives.

Without restart, reconciliation or manual refresh, the next normal settlement
succeeds. Its checkpoint survives a fresh process and permits a productive
tick before exact fixture cleanup.
EOF

/bin/cat > "$BUNDLE_DIR/08_ADVERSARIAL_STALE_SOURCE_RESULTS.md" <<'EOF'
# Adversarial stale-source results

| Mutation | Result |
| --- | --- |
| unrelated hoe added | allowed |
| unrelated hoe removed | allowed |
| tracked pickaxe removed | refused: missing |
| tracked pickaxe state changed | refused: identity mismatch |
| exact tracked stack duplicated | refused: ambiguous |
| tracked pickaxe at wrong holder | refused: missing |

Every adversarial fixture restores source, destination, session and gateway
receipt cache before the next case.
EOF

/bin/cat > "$BUNDLE_DIR/09_BLOCKERS_01_05_REVALIDATION.md" <<'EOF'
# Blockers 01–05 revalidation

All five published dedicated runners pass on the corrected product. Their raw
logs are under `evidence/regressions/`; native captures found in their evidence
directories are copied under `evidence/blockers-01-05-captures/`.

- Blocker 01: exact position restoration and normal continuation.
- Blocker 02: current versus historical ecological receipt authority.
- Blocker 03: current-cycle agricultural maturity authority.
- Blocker 04: candidate physical compensation and hard failure.
- Blocker 05: non-empty physical custody escrow and fail-closed stale handoff.

Commands:

```bash
scripts/verify-pebblelab-gate-d-position-restore-fix.sh
scripts/verify-pebblelab-gate-d-ecological-observer-fix.sh
scripts/verify-pebblelab-gate-d-agriculture-cycle-observation-fix.sh
PEBBLELAB_GATE_D_BLOCKER_04_BUILD_CONFIGURATION=release scripts/verify-pebblelab-gate-d-candidate-physical-atomicity-fix.sh
scripts/verify-pebblelab-gate-d-restart-physical-care-custody-fix.sh
```
EOF

/bin/cat > "$BUNDLE_DIR/10_TEST_RESULTS.md" <<'EOF'
# Test results

The dedicated Blocker 06 campaign passes no-fault, true late-fault, exact
rollback, immediate retry and two fresh-process continuations. Focused suites
pass 84 estates, 93 mortality, 30 homeostasis, 35 materials, 21 Material
Rights, 49 checkpoint/replay and 18 persistence/reconciliation checks, all
with zero failures.

`scripts/verify-pebblelab.sh` passes 35/35. Its shared smoke suite reports 3761
passed and 0 failed. No golden regeneration was attempted. Exact commands and
complete output are represented by the following commands, the regression logs
and `traces/test-matrix.csv`:

```bash
scripts/verify-pebblelab-gate-d-estate-source-physical-authority-fix.sh
PEBBLELAB_SMOKE_ONLY=estates-inheritance-succession .build/release/pebsmoke
PEBBLELAB_SMOKE_ONLY=mortality .build/release/pebsmoke
PEBBLELAB_SMOKE_ONLY=homeostasis-health .build/release/pebsmoke
PEBBLELAB_SMOKE_ONLY=materials .build/release/pebsmoke
PEBBLELAB_SMOKE_ONLY=material-rights .build/release/pebsmoke
PEBBLELAB_SMOKE_ONLY=checkpoint-replay .build/release/pebsmoke
PEBBLELAB_SMOKE_ONLY=persistence-reconciliation .build/release/pebsmoke
scripts/verify-pebblelab.sh
```
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
    printf 'local branch: codex/gate-d-blocker-06-estate-source-physical-authority\n'
    printf 'bundle source HEAD: %s\n' "$HEAD_COMMIT"
    printf 'worktree at bundle creation: clean\n'
    printf 'push: NOT_ATTEMPTED\n'
    printf '```\n\n'
    printf 'The branch was created directly from the required baseline. '
    printf 'No Evaluation 06 commit was cherry-picked. '
    printf '`PATCH.diff` is the complete diff from `%s` to `%s`.\n' \
        "$BASELINE" "$HEAD_COMMIT"
} >> "$BUNDLE_DIR/11_GIT_STATE.md"

/bin/cat > "$BUNDLE_DIR/12_OPEN_RISKS.md" <<'EOF'
# Open risks and bounded limits

The estate reference still identifies one bounded physical stack, not an
individual unit within a merged stack. Multiple physically indistinguishable
matching stacks remain deliberately ambiguous and fail closed.

This correction does not redesign Material Rights, add divisible inheritance,
change durable schema 30, change Observer schema 7, support abrupt custody loss,
or acquire Gate D. Evaluation 06 remains historical FAIL evidence. Evaluation
07 and CIV-34 are not started.
EOF

/bin/cat > "$BUNDLE_DIR/REPORT.json" <<EOF
{
  "contract": "V4-GATE-D-v1",
  "mission": "Gate D Blocker 06 — Estate Source Physical Authority",
  "baseline": "$BASELINE",
  "head": "$HEAD_COMMIT",
  "branch": "codex/gate-d-blocker-06-estate-source-physical-authority",
  "evaluation06": "FAIL_HISTORICAL_EVIDENCE",
  "blocker06": "BLOCKER_FIX_LOCAL_CANDIDATE",
  "gateD": "EVALUATED_FAIL_NOT_ACQUIRED",
  "civ34": "NOT_STARTED",
  "push": "NOT_ATTEMPTED",
  "schemaChanged": false,
  "observerSchema": 7,
  "trackedPhysicalTotal": 1,
  "unrelatedPhysicalTotal": 1,
  "physicalLoss": 0,
  "physicalDuplication": 0,
  "syntheticMaterial": 0,
  "estateReceiptCount": 1,
  "duplicateReceiptCount": 0,
  "lateFaultSeamReached": true,
  "lateFaultPhysicalMutationOccurred": true,
  "lateFaultPostMutationVerified": true,
  "rollback": "exact",
  "immediateSameProcessRetry": "passed",
  "freshProcessContinuation": "passed",
  "blockers01Through05": "passed",
  "repositoryGate": {"passed": 35, "total": 35, "failed": 0},
  "repositorySharedSmoke": {"passed": 3761, "failed": 0},
  "nativeCapturesInspected": 6,
  "goldenRegenerationAttempted": false,
  "nextAction": "senior review and manual publication of Gate D Blocker 06"
}
EOF

git diff --binary "$BASELINE..$HEAD_COMMIT" > "$BUNDLE_DIR/PATCH.diff"
git diff --check "$BASELINE..$HEAD_COMMIT"
{
    printf 'pwd: %s\n' "$ROOT_DIR"
    printf 'branch: %s\n' "$(git branch --show-current)"
    printf 'HEAD: %s\n' "$HEAD_COMMIT"
    printf 'origin/lab/pebblelab-v1: %s\n' \
        "$(git rev-parse origin/lab/pebblelab-v1)"
    printf 'status:\n'
    git status --short
    printf 'commits since baseline:\n'
    git log --oneline "$BASELINE..$HEAD_COMMIT"
} > "$BUNDLE_DIR/traces/git-state.txt"

(
    cd "$BUNDLE_DIR"
    /usr/bin/find . -type f ! -name CHECKSUMS.sha256 -print0 \
        | /usr/bin/sort -z \
        | /usr/bin/xargs -0 /usr/bin/shasum -a 256 \
        > CHECKSUMS.sha256
    /usr/bin/shasum -a 256 -c CHECKSUMS.sha256
)
(
    cd "$OUTPUT_PARENT"
    /usr/bin/zip -q -r "$ZIP_PATH" "$BUNDLE_NAME"
)
/usr/bin/unzip -t "$ZIP_PATH" >/dev/null
/usr/bin/shasum -a 256 "$ZIP_PATH" > "$ZIP_PATH.sha256"

printf 'Gate D Blocker 06 review bundle: %s\n' "$ZIP_PATH"
printf 'ZIP checksum: %s\n' "$ZIP_PATH.sha256"
printf 'Bundle directory: %s\n' "$BUNDLE_DIR"
