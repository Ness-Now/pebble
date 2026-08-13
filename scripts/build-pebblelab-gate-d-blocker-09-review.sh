#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
BASELINE=4ea6fba4b615d72a96087bb98bf5bbca4b560e4b
PRODUCT_FIX=ee742afb41fda44c77d8b98f868fbe759934057e
EVALUATION_09_A=fab16936274b1d75d528967c149c4d0e0e78251f
EVALUATION_09_B=7f5a2955b89c4dc44f1f14cf7d4cef98009dd93d
RED_EVIDENCE=${PEBBLELAB_GATE_D_BLOCKER_09_RED_EVIDENCE:-/tmp/PebbleLab-GateD-Blocker09-Baseline-Red}
TARGETED_EVIDENCE=${PEBBLELAB_GATE_D_BLOCKER_09_TARGETED_EVIDENCE:-/tmp/PebbleLab-GateD-Blocker09-Green-Exact-2}
REGRESSION_ROOT=${PEBBLELAB_GATE_D_BLOCKER_09_REGRESSION_ROOT:-/tmp/PebbleLab-GateD-Blocker09-Regressions}
REPOSITORY_GATE_LOG=${PEBBLELAB_GATE_D_BLOCKER_09_REPOSITORY_GATE_LOG:-/tmp/PebbleLab-GateD-Blocker09-Final-Repository-Gate.log}
OUTPUT_PARENT=${PEBBLELAB_GATE_D_BLOCKER_09_REVIEW_PARENT:-/tmp}

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
    || fail 'unexpected repository root'
[ "$(git rev-parse origin/lab/pebblelab-v1)" = "$BASELINE" ] \
    || fail 'canonical remote no longer matches the required baseline'
[ "$(git rev-parse "$PRODUCT_FIX^{commit}")" = "$PRODUCT_FIX" ] \
    || fail 'product-fix commit is unavailable'
git merge-base --is-ancestor "$PRODUCT_FIX" HEAD \
    || fail 'product-fix commit is not an ancestor of review HEAD'
if git merge-base --is-ancestor "$EVALUATION_09_A" HEAD \
    || git merge-base --is-ancestor "$EVALUATION_09_B" HEAD; then
    fail 'Evaluation 09 evidence commit must not be an ancestor'
fi
[ -z "$(git status --short)" ] || fail 'worktree must be clean'
[ -d "$RED_EVIDENCE" ] || fail "baseline-red evidence missing: $RED_EVIDENCE"
[ -d "$TARGETED_EVIDENCE" ] || fail "targeted evidence missing: $TARGETED_EVIDENCE"
[ -d "$REGRESSION_ROOT" ] || fail "regression evidence missing: $REGRESSION_ROOT"
[ -s "$REPOSITORY_GATE_LOG" ] || fail 'repository gate log missing'

/usr/bin/grep -q \
    'Material Rights conflicts with physical custody: holder/material/quantity asset:civ27:live-pickaxe' \
    "$RED_EVIDENCE/process-b.log" \
    || fail 'baseline-red checkpoint refusal is missing'
/usr/bin/grep -q \
    'blocker09 checkpoint identity adversarial missing=refused oldIdentity=refused futureIdentity=refused wrongHolder=refused wrongQuantity=refused ambiguity=refused duplicateReservation=refused' \
    "$TARGETED_EVIDENCE/process-b.log" \
    || fail 'targeted adversarial evidence is incomplete'
/usr/bin/grep -q 'blocker07 inherited estate use .*damage=1>2' \
    "$TARGETED_EVIDENCE/process-c.log" \
    || fail 'second legitimate tool evolution is missing'
/usr/bin/grep -q 'blocker09 checkpoint identity .*durableDamage=0 .*currentDamage=2 physicalDamage=2' \
    "$TARGETED_EVIDENCE/process-d.log" \
    || fail 'damage-two fresh restore is missing'
/usr/bin/grep -q 'PASS: all 35 PebbleLab verification steps succeeded' \
    "$REPOSITORY_GATE_LOG" \
    || fail 'repository gate did not pass 35/35'
ASSERTION_RESULT=$(/usr/bin/grep -Eo '[0-9]+ passed, 0 failed' \
    "$REPOSITORY_GATE_LOG" | /usr/bin/tail -1)
[ -n "$ASSERTION_RESULT" ] || fail 'repository assertion count is missing'
ASSERTION_COUNT=${ASSERTION_RESULT%% *}

HEAD_COMMIT=$(git rev-parse HEAD)
HEAD_SHORT=$(git rev-parse --short=12 HEAD)
BUNDLE_NAME="PebbleLab-Gate-D-Blocker-09-Review-$HEAD_SHORT"
BUNDLE_DIR="$OUTPUT_PARENT/$BUNDLE_NAME"
ZIP_PATH="$OUTPUT_PARENT/$BUNDLE_NAME.zip"
[ ! -e "$BUNDLE_DIR" ] || fail "bundle directory exists: $BUNDLE_DIR"
[ ! -e "$ZIP_PATH" ] || fail "bundle ZIP exists: $ZIP_PATH"

/bin/mkdir -p "$BUNDLE_DIR/evidence" "$BUNDLE_DIR/traces"
copy_tree "$RED_EVIDENCE" "$BUNDLE_DIR/evidence/baseline-red"
copy_tree "$TARGETED_EVIDENCE" "$BUNDLE_DIR/evidence/blocker09-targeted"
copy_tree "$REGRESSION_ROOT" "$BUNDLE_DIR/evidence/blockers-01-08"
/bin/cp "$REPOSITORY_GATE_LOG" "$BUNDLE_DIR/evidence/final-repository-gate.log"
/bin/cp /tmp/PebbleLab-GateD-Blocker09-dedicated-exact-2.log \
    "$BUNDLE_DIR/evidence/blocker09-dedicated-runner.log"

/usr/bin/grep -E \
    'blocker07 inherited estate use|checkpoint command failed|checkpoint saved name=blocker09-damage1' \
    "$RED_EVIDENCE/process-b.log" \
    > "$BUNDLE_DIR/traces/baseline-red-first-divergence.log"
/usr/bin/grep -E \
    'blocker09 checkpoint identity|blocker09 checkpoint identity adversarial|checkpoint saved name=blocker09-damage1|custody handoff persisted' \
    "$TARGETED_EVIDENCE/process-b.log" \
    > "$BUNDLE_DIR/traces/damage-one-save-and-adversarials.log"
/usr/bin/grep -E \
    'checkpoint loaded name=blocker09-damage1|persistence reconciliation candidate|blocker07 inherited estate use|blocker09 checkpoint identity|checkpoint saved name=blocker09-damage2|custody handoff persisted' \
    "$TARGETED_EVIDENCE/process-c.log" \
    > "$BUNDLE_DIR/traces/damage-one-restore-and-second-use.log"
/usr/bin/grep -E \
    'checkpoint loaded name=blocker09-damage2|persistence reconciliation candidate|blocker09 checkpoint identity|estate' \
    "$TARGETED_EVIDENCE/process-d.log" \
    > "$BUNDLE_DIR/traces/damage-two-restore-and-estate-history.log"

/bin/cat > "$BUNDLE_DIR/traces/identity-timeline.csv" <<'EOF'
boundary,durableDamage,currentVerifiedDamage,physicalDamage,checkpointResult
registration-and-settlement,0,0,0,pre-use-saved
first-legitimate-use,0,1,1,saved
first-fresh-restore,0,1,1,matched
second-legitimate-use,0,2,2,saved
second-fresh-restore,0,2,2,matched
EOF

/bin/cat > "$BUNDLE_DIR/traces/conservation.csv" <<'EOF'
boundary,physicalLoss,physicalDuplication,syntheticMaterial,duplicateAssets,duplicateReceipts,duplicateSettlements,observerMutationCount
baseline-refusal,0,0,0,0,0,0,0
damage-one-save-and-restore,0,0,0,0,0,0,0
damage-two-save-and-restore,0,0,0,0,0,0,0
EOF

/bin/cat > "$BUNDLE_DIR/00_README_FIRST.md" <<'EOF'
# Gate D Blocker 09 senior-review bundle

This bundle supports review of one targeted local product correction. It does
not reevaluate or acquire Gate D. Evaluation 09 remains immutable historical
FAIL evidence; Evaluation 10 and CIV-34 are not started. Raw evidence is under
`evidence/`, authoritative excerpts and tables under `traces/`, and the patch is
against the exact published baseline.
EOF

/bin/cat > "$BUNDLE_DIR/01_EXECUTIVE_SUMMARY.md" <<EOF
# Executive summary

The checkpoint adapter now validates exact PebbleCore custody against the
current verified material identity while separately proving that identity is a
canonical evolution of the immutable durable asset reference. Damage 0→1 and
1→2 each save and fresh-restore exactly; historical registration and settlement
remain damage 0. All identity substitution and reservation adversarials fail
closed. The repository gate is 35/35 with $ASSERTION_COUNT assertions and zero
failures.
EOF

/bin/cat > "$BUNDLE_DIR/02_ROOT_CAUSE.md" <<'EOF'
# Root cause

Checkpoint save searched physical custody using `record.asset.materialIdentity`
and required `lastVerifiedHolder.materialIdentity` to equal it. Normal inherited
tool use had already advanced both PebbleCore and the current verified holder
from damage 0 to damage 1, while the durable registration and settlement
correctly remained damage 0. The adapter therefore rejected a coherent current
state before checkpoint publication.
EOF

/bin/cp docs/pebblelab/GATE_D_BLOCKER_09_EVOLVED_MATERIAL_IDENTITY_CHECKPOINT_SAVE.md \
    "$BUNDLE_DIR/03_DURABLE_VS_CURRENT_IDENTITY.md"

/bin/cat > "$BUNDLE_DIR/04_CHECKPOINT_CUSTODY_VALIDATION.md" <<'EOF'
# Checkpoint custody validation

The durable reference first permits or refuses the current verified identity
under the canonical Material Rights evolution rule. PebbleCore must then contain
the exact current identity, holder and quantity. Reservation accounting uses
that exact current identity and the existing current fingerprint boundary is
retained. Checkpoint save never repairs Material Rights or creates physical
matter.
EOF

/bin/cat > "$BUNDLE_DIR/05_EVOLVED_IDENTITY_SAVE.md" <<'EOF'
# Evolved identity save

The baseline-red trace proves damage-1 physical/current truth followed by the
holder/material/quantity refusal. The corrected trace proves exact damage-1
truth, restart-safe save and protected handoff. See
`traces/baseline-red-first-divergence.log` and
`traces/damage-one-save-and-adversarials.log`.
EOF

/bin/cat > "$BUNDLE_DIR/06_PROTECTED_CUSTODY_ROUNDTRIP.md" <<'EOF'
# Protected custody round trip

Manifest-v2 evidence and graceful checkpoint-bound World escrow carry the exact
damage-1 and damage-2 stacks. Fresh loads restore physical custody before one
current Material Rights reconciliation. No manifest-only recreation, identity
downgrade or synthetic material occurs.
EOF

/bin/cat > "$BUNDLE_DIR/07_REPEATED_EVOLUTION.md" <<'EOF'
# Repeated evolution

After the damage-1 fresh load, the first attempted second use is allowed and
performs another real block mutation and drop acquisition. Current identity
advances to damage 2, the second restart-safe checkpoint succeeds, and a second
fresh process restores damage 2 exactly. The fix is not specialized to 0→1.
EOF

/bin/cat > "$BUNDLE_DIR/08_ADVERSARIAL_IDENTITY_CASES.md" <<'EOF'
# Adversarial identity cases

Missing current material, stale registration identity substitution, an
unverified future identity, wrong holder, wrong quantity, ambiguous duplicate
current stacks and duplicate reservation all refuse. The copied physical and
session candidates remain byte-equivalent and publish no checkpoint or handoff.
EOF

/bin/cat > "$BUNDLE_DIR/09_ESTATE_HISTORY_CONTINUITY.md" <<'EOF'
# Estate history continuity

The asset ID and registered identity remain stable. Settlement observation and
the single settlement receipt remain damage 0 and unchanged. Only the current
destination/holder observation advances to damage 1 and then 2. No new estate
asset or settlement is created by tool use, save or restore.
EOF

/bin/cat > "$BUNDLE_DIR/10_BLOCKERS_01_08_REVALIDATION.md" <<'EOF'
# Blockers 01–08 revalidation

The bundle includes exact final logs for every published runner. Blocker 04 was
rerun after its static registration audit exposed and caused removal of a
proof-only direct `.register` call. Blockers 05, 07 and 08 retain strict escrow,
post-physical reconciliation and collective placement semantics respectively.
EOF

/bin/cat > "$BUNDLE_DIR/11_CONSERVATION.md" <<'EOF'
# Conservation

Across baseline refusal, both successful checkpoint boundaries and both fresh
restores: physical loss, physical duplication, synthetic material, duplicate
assets, duplicate receipts, duplicate settlements and Observer mutations are
all zero. Tool damage is an explicit transformation of the same physical item.
EOF

/bin/cat > "$BUNDLE_DIR/12_TEST_RESULTS.md" <<EOF
# Test results

The dedicated four-process Blocker 09 campaign passes. Focused Material Rights,
estate/succession, checkpoint/replay, persistence reconciliation, custody and
physical-action suites pass. Published Blockers 01–08 pass. The canonical
repository gate passes 35/35 with $ASSERTION_COUNT assertions and zero failures.
No golden was regenerated.
EOF

/bin/cat > "$BUNDLE_DIR/13_GIT_STATE.md" <<EOF
# Git state

    baseline: $BASELINE
    product fix: $PRODUCT_FIX
    review HEAD: $HEAD_COMMIT
    Evaluation 09 commits are ancestors: NO / NO
    branch: $(git branch --show-current)
    worktree: clean
    push: NOT_ATTEMPTED
EOF

/bin/cat > "$BUNDLE_DIR/14_OPEN_RISKS.md" <<'EOF'
# Open risks and limits

The bounded model still has no universal per-unit material UUID. Legitimate
evolution is exactly the existing same-item-key Material Rights policy, not an
arbitrary category match. Unsupported abrupt custody loss remains unsupported;
missing, stale or corrupt escrow fails closed. The correction does not acquire
Gate D or start Evaluation 10.
EOF

/usr/bin/jq -n \
    --arg baseline "$BASELINE" \
    --arg productFix "$PRODUCT_FIX" \
    --arg head "$HEAD_COMMIT" \
    --argjson assertions "$ASSERTION_COUNT" \
    '{
      blocker: "Gate D Blocker 09",
      status: "BLOCKER_FIX_LOCAL_CANDIDATE",
      evaluation09: "EVALUATED_FAIL_NOT_ACQUIRED_HISTORICAL_EVIDENCE",
      gateD: "EVALUATED_FAIL_NOT_ACQUIRED",
      evaluation10: "NOT_STARTED",
      civ34: "NOT_STARTED",
      baseline: $baseline,
      productFix: $productFix,
      reviewHead: $head,
      damageEvolution: [0,1,2],
      currentIdentityRoundTrips: "exact",
      adversarialIdentityCases: "allFailClosed",
      blockers01Through08: "passed",
      repositoryGate: {stepsPassed: 35, stepsTotal: 35, assertionsPassed: $assertions, assertionsFailed: 0},
      checkpointSchema: 30,
      observerSchema: 7,
      physicalLoss: 0,
      physicalDuplication: 0,
      syntheticMaterial: 0,
      push: "NOT_ATTEMPTED"
    }' > "$BUNDLE_DIR/REPORT.json"

git diff --binary "$BASELINE"..HEAD > "$BUNDLE_DIR/PATCH.diff"
(
    cd "$BUNDLE_DIR"
    /usr/bin/find . -type f ! -name CHECKSUMS.sha256 -print0 \
        | LC_ALL=C /usr/bin/sort -z \
        | /usr/bin/xargs -0 shasum -a 256 \
        > CHECKSUMS.sha256
)
(
    cd "$OUTPUT_PARENT"
    /usr/bin/zip -qry "$ZIP_PATH" "$BUNDLE_NAME"
)
/usr/bin/unzip -t "$ZIP_PATH" >/dev/null
(
    cd "$BUNDLE_DIR"
    shasum -a 256 -c CHECKSUMS.sha256 >/dev/null
)

printf 'Review bundle: %s\n' "$ZIP_PATH"
printf 'External SHA-256: '
shasum -a 256 "$ZIP_PATH" | /usr/bin/awk '{print $1}'
printf 'Internal checksum count: %s\n' "$(wc -l < "$BUNDLE_DIR/CHECKSUMS.sha256" | tr -d ' ')"
