#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
BASELINE=24c679581f7dfd93d26bffa2e9486a5340af0d9c
EVIDENCE_DIR=${PEBBLELAB_GATE_D_EVALUATION_11_EVIDENCE:-/tmp/PebbleLab-GateD-Evaluation11-final3}
OUTPUT_PARENT=${PEBBLELAB_GATE_D_EVALUATION_11_REVIEW_PARENT:-/tmp}

fail() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

copy_required() {
    source_path=$1
    destination_path=$2
    [ -s "$source_path" ] || fail "required evidence missing: $source_path"
    /bin/cp "$source_path" "$destination_path"
}

cd "$ROOT_DIR"
[ "$(git rev-parse --show-toplevel)" = "$ROOT_DIR" ] \
    || fail 'unexpected repository root'
[ "$(git branch --show-current)" = codex/gate-d-evaluation-11 ] \
    || fail 'unexpected branch'
[ "$(git rev-parse origin/lab/pebblelab-v1)" = "$BASELINE" ] \
    || fail 'canonical remote no longer matches the required baseline'
[ -z "$(git status --short)" ] || fail 'worktree must be clean'
[ -d "$EVIDENCE_DIR" ] || fail "evidence directory missing: $EVIDENCE_DIR"

/usr/bin/grep -q \
    'V4-GATE-D-v1 EVALUATION 11 integrated campaign: PASS' \
    <(PEBBLELAB_GATE_D_EVALUATION_11_EVIDENCE_DIR=/dev/null \
        scripts/evaluate-pebblelab-gate-d-11.sh --dry-run 2>/dev/null \
        || true) && fail 'dry-run unexpectedly emitted a verdict'
/usr/bin/grep -q \
    'evaluation11 blocker10 inherited support destructive .*currentDamage=2 .*exactRollback=1' \
    "$EVIDENCE_DIR/process-d-b10-checkpoint-c.log" \
    || fail 'integrated damage-two Blocker 10 proof is absent'
/usr/bin/grep -q \
    'evaluation11 safe-after-refusal blocker07 inherited estate use .*damage=2>3' \
    "$EVIDENCE_DIR/process-d-b10-checkpoint-c.log" \
    || fail 'safe action after Blocker 10 refusal is absent'
/usr/bin/grep -q \
    'checkpoint loaded name=e11-checkpoint-c .*committedCurrentReconciliationThisLoad=1' \
    "$EVIDENCE_DIR/process-e-post-c-continuation.log" \
    || fail 'checkpoint C fresh restore is absent'
/usr/bin/grep -q \
    'wild subsistence gathering .*interaction=canonicalBreak .*custody=real' \
    "$EVIDENCE_DIR/current-wild-physical-path.log" \
    || fail 'current wild gathering path is absent'
/usr/bin/grep -q \
    'PASS: all 35 PebbleLab verification steps succeeded' \
    "$EVIDENCE_DIR/repository-gate.log" \
    || fail 'repository gate did not pass 35/35'
ASSERTION_RESULT=$(/usr/bin/grep -Eo '[0-9]+ passed, 0 failed' \
    "$EVIDENCE_DIR/repository-gate.log" | /usr/bin/tail -1)
[ "$ASSERTION_RESULT" = '3772 passed, 0 failed' ] \
    || fail "unexpected repository assertion result: $ASSERTION_RESULT"
for blocker in 01 02 03 04 05 06 07; do
    /usr/bin/grep -Eq \
        'REPRODUCED AND FIXED|TARGETED PROOF PASSED' \
        "$EVIDENCE_DIR/blocker-$blocker-run.log" \
        || fail "Blocker $blocker runner did not pass"
done
for blocker in 08 09 10; do
    /usr/bin/grep -q 'canonical remote is not the Blocker' \
        "$EVIDENCE_DIR/blocker-$blocker-run.log" \
        || fail "Blocker $blocker historical-wrapper limitation changed"
done

HEAD_COMMIT=$(git rev-parse HEAD)
HEAD_SHORT=$(git rev-parse --short=12 HEAD)
BUNDLE_NAME="PebbleLab-Gate-D-Evaluation-11-Review-$HEAD_SHORT"
BUNDLE_DIR="$OUTPUT_PARENT/$BUNDLE_NAME"
ZIP_PATH="$OUTPUT_PARENT/$BUNDLE_NAME.zip"
[ ! -e "$BUNDLE_DIR" ] || fail "bundle directory exists: $BUNDLE_DIR"
[ ! -e "$ZIP_PATH" ] || fail "bundle ZIP exists: $ZIP_PATH"

/bin/mkdir -p "$BUNDLE_DIR/raw" "$BUNDLE_DIR/captures" \
    "$BUNDLE_DIR/traces"

for evidence_file in \
    process-a-generations-renewable.log \
    process-b-mortality-succession.log \
    process-c-collective-first-use.log \
    process-d-b10-checkpoint-c.log \
    process-e-post-c-continuation.log \
    current-wild-physical-path.log \
    campaign-result.json \
    generational-timeline.json \
    childhood-development.json \
    checkpoint-isolation.json \
    blocker-10-composition.json \
    conservation.json \
    analysis-artifact-digests.json \
    e11-checkpoint-a-manifest.json \
    e11-checkpoint-a-session.json \
    e11-succession-manifest.json \
    e11-succession-session.json \
    e11-checkpoint-b-manifest.json \
    e11-checkpoint-b-session.json \
    e11-post-b10-refusal-manifest.json \
    e11-post-b10-refusal-session.json \
    e11-checkpoint-c-manifest.json \
    e11-checkpoint-c-session.json \
    repository-gate.log; do
    copy_required "$EVIDENCE_DIR/$evidence_file" \
        "$BUNDLE_DIR/raw/$evidence_file"
done

if [ -s "$EVIDENCE_DIR/seed-73-bootstrap-refusal.log" ]; then
    /bin/cp "$EVIDENCE_DIR/seed-73-bootstrap-refusal.log" \
        "$BUNDLE_DIR/raw/seed-73-bootstrap-refusal.log"
fi
for blocker in 01 02 03 04 05 06 07 08 09 10; do
    copy_required "$EVIDENCE_DIR/blocker-$blocker-run.log" \
        "$BUNDLE_DIR/raw/blocker-$blocker-run.log"
done
for capture in "$EVIDENCE_DIR"/*.png; do
    [ -s "$capture" ] || fail 'native capture set is empty'
    /bin/cp "$capture" "$BUNDLE_DIR/captures/"
done

/usr/bin/grep -E \
    'birth finalized|renewable|candidate physical fault|CANDIDATE_PHYSICAL_ROLLBACK|checkpoint saved|custody handoff' \
    "$EVIDENCE_DIR/process-a-generations-renewable.log" \
    > "$BUNDLE_DIR/traces/process-a-authoritative.log" || true
/usr/bin/grep -E \
    'checkpoint loaded|birth finalized|childhood|development|mortality exit|estate|lateFailure|settled' \
    "$EVIDENCE_DIR/process-b-mortality-succession.log" \
    > "$BUNDLE_DIR/traces/process-b-authoritative.log" || true
/usr/bin/grep -E \
    'collective|foreignCollision|rollback verified|physical boundary|reconciliation candidate|inherited estate use|blocker09|checkpoint saved' \
    "$EVIDENCE_DIR/process-c-collective-first-use.log" \
    > "$BUNDLE_DIR/traces/process-c-authoritative.log" || true
/usr/bin/grep -E \
    'checkpoint loaded|damage=1>2|inherited support destructive|post-b10-refusal|safe-after-refusal|mutation family composition|checkpoint-c' \
    "$EVIDENCE_DIR/process-d-b10-checkpoint-c.log" \
    > "$BUNDLE_DIR/traces/blocker-10-composition.log" || true
/usr/bin/grep -E \
    'checkpoint loaded|inherited support destructive|step tick=28|care tick=28|observer status' \
    "$EVIDENCE_DIR/process-e-post-c-continuation.log" \
    > "$BUNDLE_DIR/traces/process-e-continuation.log" || true

cat > "$BUNDLE_DIR/00_README_FIRST.md" <<'EOF'
# Gate D Evaluation 11 senior-review bundle

This is a local independent whole-gate PASS evidence candidate. It contains no
product correction, does not acquire or publish Gate D, does not start CIV-34,
and was not pushed. Raw traces and durable files are under `raw/`, focused
excerpts under `traces/`, and inspected native captures under `captures/`.
EOF

cat > "$BUNDLE_DIR/01_EXECUTIVE_SUMMARY.md" <<'EOF'
# Executive summary

The new E11 history proves G0→G1→G2, childhood-shaped durable development,
renewable subsistence, multi-holder physical custody restart, causal mortality,
family distinctions, goods and obligations across people, estate succession,
late rollback/retry, inherited use, repeated current identity evolution,
mixed collective restore, B10 exact refusal with an evolved inherited tool,
safe use after refusal, A/B/C isolation and post-C continuation. Verdict: PASS
as a local candidate only; senior review remains mandatory.
EOF

cat > "$BUNDLE_DIR/02_BASELINE_AND_GIT.md" <<EOF
# Baseline and Git

    baseline: $BASELINE
    branch: codex/gate-d-evaluation-11
    evaluation HEAD: $HEAD_COMMIT
    origin/lab/pebblelab-v1: $BASELINE
    Evaluation 10 ancestry: absent
    product corrections: 0
    push: NOT_ATTEMPTED
EOF

cat > "$BUNDLE_DIR/03_GATE_CONTRACT.md" <<'EOF'
# Gate contract

Gate D composes CIV-29 through CIV-33 and renewable subsistence in one causal
history: multiple generations, childhood consequences, causal aging/death,
durable family distinctions, goods and obligations across people, and exact
fresh-process coherence. Any required FAIL or NOT PROVEN property forbids PASS.
EOF

cat > "$BUNDLE_DIR/04_EVALUATION_DESIGN.md" <<'EOF'
# Evaluation design

Processes A–E create and restore one new controlled E11 civilization. A makes
G1, renewable output, two holders and checkpoint A. B restores, develops G1,
creates G2, causes G0 death and settles the estate. C attacks checkpoint loads,
restores collectively, uses the inherited asset and saves B. D restores B,
evolves the tool, attacks B10, checkpoints immediately, uses safely, audits
till/place and saves C. E restores C, attacks B10 again and continues normally.
A separate fresh E11 World exercises current wild gathering without the
obsolete schema-14 final wrapper.
EOF

cat > "$BUNDLE_DIR/05_GENERATIONAL_TIMELINE.md" <<'EOF'
# Generational timeline

G0 is agent_0, agent_1 and agent_2. Birth 1 creates G1 agent_3 from
agent_0/agent_1. Birth 2 creates G2 agent_4 from agent_2/agent_3. Both births
have unique IDs, canonical parentage, physical embodiment and inherited
genotypes. `raw/generational-timeline.json` contains exact events and digests.
EOF

cat > "$BUNDLE_DIR/06_CHILDHOOD_DEVELOPMENT.md" <<'EOF'
# Childhood and development

G1 records interrupted supervision, resumed verified supervision/care and a
stable mature development profile with reserve 7115. G2 remains protected and
juvenile. Parent agent_2/agent_3, guardian agent_2, caregiver agent_3,
household_2, genotype, development and physiology are separate authorities.
The evidence persists through checkpoint C and its fresh restore.
EOF

cat > "$BUNDLE_DIR/07_RENEWABLE_SUBSISTENCE.md" <<'EOF'
# Renewable subsistence

External World progression yields current ecological evidence, planting,
growth, physical harvest, custody, consumption, reserve and a second output.
A late post-validation failure compensates physical mutations and publishes no
candidate state; immediate retry passes. Loss, duplication, synthetic material,
duplicate receipts and duplicate sites are zero.
EOF

cat > "$BUNDLE_DIR/08_CHECKPOINT_A_CUSTODY_RESTART.md" <<'EOF'
# Checkpoint A custody and restart

agent_0 and agent_1 each hold one exact physical carrot before checkpoint A.
The checkpoint binds two non-empty custodies to protected World escrow. A fresh
process adopts the exact holder/material pairs, with two restored stacks,
quantity two, no swap, no duplicate and no manifest-only recreation.
EOF

cat > "$BUNDLE_DIR/09_MORTALITY_FAMILY_OBLIGATIONS.md" <<'EOF'
# Mortality, family and obligations

Compounded homeostatic failure causally kills G0 agent_0. The active population
and probes become five to four, while the historical person, parentage, union
history, lineage and house evidence remain. Death never resurrects on later
loads. agent_3's caregiver obligation to G2 agent_4 remains active through
death and checkpoint C restore, distinct from ownership, custody and parentage.
EOF

cat > "$BUNDLE_DIR/10_ESTATE_SUCCESSION.md" <<'EOF'
# Estate and succession

The decedent source holds the tracked iron pickaxe and unrelated iron hoe.
Asset-scoped authority transfers the pickaxe exactly once to beneficiary and
custodian agent_1, preserves the unrelated hoe, records one settlement receipt
and retains the exact historical estate/beneficiary proof.
EOF

cat > "$BUNDLE_DIR/11_TRUE_LATE_FAULT.md" <<'EOF'
# True late estate fault

Source authority and current custody validate, the physical transfer occurs,
post-mutation verification passes and the explicit late seam fires. World,
source, destination, estate, Material Rights, session, replay and receipts roll
back exactly. Immediate same-process retry settles successfully. The earlier
pre-mutation refusal correctly claims no late rollback.
EOF

cat > "$BUNDLE_DIR/12_INHERITED_USE_AND_B09.md" <<'EOF'
# Inherited use and Blocker 09

First inherited use after fresh load needs no repair, extra load or manual
reconciliation. It removes a real block, wears the real pickaxe and acquires
the real drop. Later uses evolve damage 1→2 and 2→3. The asset ID, durable
damage-0 registration, historical settlement and single receipt remain stable;
current verified identity advances and saves/restores exactly.
EOF

cat > "$BUNDLE_DIR/13_BLOCKER10_PHYSICAL_SAFETY.md" <<'EOF'
# Blocker 10 physical safety

At current damage 2, inherited-tool holder agent_1 breaks the exact support
beneath active G1 agent_3. A real candidate mutation occurs, post-mutation
placement rejects it, and rollback leaves zero World/tool/drop/custody/rights/
estate/session/recorder delta. The probe stays valid. Immediate checkpoint
passes and the next safe use advances damage 2→3. The refusal repeats after a
fresh checkpoint-C restore at current damage 3.
EOF

cat > "$BUNDLE_DIR/14_CHECKPOINT_B_C.md" <<'EOF'
# Checkpoints B and C

Checkpoint B protects current pickaxe damage 1; fresh restore is exact and
commits one current reconciliation. After damage 2, B10 refusal and safe damage
3, checkpoint C protects exact damage 3. C fresh-restores four active probes,
three protected custody stacks and one current reconciliation. A, B and C have
distinct IDs, session states and integrity digests.
EOF

cat > "$BUNDLE_DIR/15_COLLECTIVE_PROBE_RESTORE.md" <<'EOF'
# Collective probe restore

The mixed plan has reused_exact=1, repositioned_verified=1,
restored_missing=2 and retired=1. Complete target-set validation precedes
bounded collective application, exact custody and the physical boundary.
Valid adjacency passes; true overlap and foreign collision fail closed. No
nearest-free relocation, position invention or application-order dependence
occurs.
EOF

cat > "$BUNDLE_DIR/16_ADVERSARIAL_ROLLBACKS.md" <<'EOF'
# Adversarial rollbacks

A fault after the first missing-probe creation removes created probes, restores
repositioned and retired probes, restores custody/escrow, leaves session and
recorder unchanged and publishes zero reconciliation; retry passes. A second
fault after physical-boundary acquisition and reconciliation-candidate staging
rolls back the same domains, discards the candidate and retries successfully.
EOF

cat > "$BUNDLE_DIR/17_IDENTITY_ADVERSARIALS.md" <<'EOF'
# Identity adversarials

For the evolved pickaxe, missing current material, old registration identity,
future unverified identity, wrong holder, wrong quantity, ambiguous duplicate
and double reservation all fail closed. World/session/checkpoint/handoff
publication remain unchanged and no save repairs the adversarial state.
EOF

cat > "$BUNDLE_DIR/18_BLOCKERS_01_10_COMPOSITION.md" <<'EOF'
# Blockers 01–10 in composition

B01 exact position, B02 historical ecology, B03 current-cycle observation,
B04 candidate atomicity, B05 strict escrow, B06 estate authority/late fault,
B07 restore-before-reconciliation, B08 collective placement, B09 evolved
identity and B10 active-probe safety all pass in composition. Dedicated B01–07
runners pass. B08–10 historical wrappers are inconclusive on the published ref
because their preflights pin old affected baselines; B08 also lacks its signed
historical SESSION_HOME. No fixture or ref was fabricated.
EOF

cat > "$BUNDLE_DIR/19_CONSERVATION.md" <<'EOF'
# Conservation

The population equation is 3 founders + 2 births - 1 death = 4 active agents.
At checkpoint C, agent_1 holds the sole damage-3 pickaxe plus three real dirt
drops, agent_3 holds one carrot reserve, and the unrelated estate hoe remains
preserved. Loss, duplication, synthetic material and duplicate probes/assets/
settlements/receipts/sites are zero. See `raw/conservation.json`.
EOF

cat > "$BUNDLE_DIR/20_VISUAL_EVIDENCE.md" <<'EOF'
# Visual evidence

Native captures show the renewable/G1 state, checkpoint A, first restore,
G2/mortality, succession, load adversarials, damage 1, damage 2/B10 refusal,
checkpoint C restore, post-C refusal and current wild gathering. Representative
captures were inspected. Observer V7 is visibly read-only; authoritative proof
remains the traces, World/session files, manifests and custody observations.
EOF

cat > "$BUNDLE_DIR/21_TEST_MATRIX.md" <<EOF
# Test matrix

    integrated whole-gate campaign: PASS
    B01 dedicated: PASS
    B02 dedicated: PASS
    B03 dedicated: PASS
    B04 dedicated: PASS
    B05 dedicated: PASS
    B06 dedicated: PASS
    B07 dedicated: PASS
    B08 dedicated: INCONCLUSIVE — stale historical baseline + signed fixture absent
    B08 integrated current semantics: PASS
    B09 dedicated: INCONCLUSIVE — stale historical baseline preflight
    B09 integrated current semantics: PASS
    B10 dedicated: INCONCLUSIVE — stale historical baseline preflight
    B10 integrated current semantics: PASS
    historical wild wrapper: INCONCLUSIVE — schema 14 final vs canonical 30
    current wild break/drop/custody path: PASS
    repository gate: 35/35; $ASSERTION_RESULT
    checkpoint / Observer schemas: 30 / 7
    golden regeneration: NOT ATTEMPTED
EOF

cat > "$BUNDLE_DIR/22_OPEN_RISKS.md" <<'EOF'
# Open risks

Senior review and publication remain outstanding; Gate D is not acquired.
Historical B08–B10 wrappers are not rerunnable after canonical publication
without falsifying their pinned remote-ref preconditions; their current
semantics are instead covered directly by E11. The old wild final wrapper
still asserts schema 14 and is not the canonical 35-step gate. A supplementary
seed-73 bootstrap refused before population initialization due to terrain and
was not used as decisive Gate D evidence. No product correction was made.
EOF

jq -n \
    --arg baseline "$BASELINE" \
    --arg head "$HEAD_COMMIT" \
    --arg assertions "$ASSERTION_RESULT" \
    '{
      evaluation: "V4-GATE-D-v1 Evaluation 11",
      verdict: "PASS_LOCAL_EVIDENCE_CANDIDATE_FOR_SENIOR_REVIEW",
      gateD: "NOT_YET_ACQUIRED_OR_PUBLISHED",
      baseline: $baseline,
      reviewHead: $head,
      integrated: {
        generations: "G0_TO_G1_TO_G2_PASS",
        childhoodDevelopment: "PASS",
        renewableSubsistence: "PASS",
        multipleProtectedCustodies: "PASS",
        collectiveMixedRestore: "PASS",
        mortality: "PASS",
        goodsAcrossPeople: "PASS",
        obligationsAcrossPeople: "PASS",
        estateSuccession: "PASS",
        lateFaultRetry: "PASS",
        evolvedIdentity: "PASS",
        blocker10: "PASS"
      },
      blockers: {
        B01: "PASS_DEDICATED_AND_COMPOSITION",
        B02: "PASS_DEDICATED_AND_COMPOSITION",
        B03: "PASS_DEDICATED_AND_COMPOSITION",
        B04: "PASS_DEDICATED_AND_COMPOSITION",
        B05: "PASS_DEDICATED_AND_COMPOSITION",
        B06: "PASS_DEDICATED_AND_COMPOSITION",
        B07: "PASS_DEDICATED_AND_COMPOSITION",
        B08: "PASS_COMPOSITION_DEDICATED_INCONCLUSIVE",
        B09: "PASS_COMPOSITION_DEDICATED_INCONCLUSIVE_STALE_PREFLIGHT",
        B10: "PASS_COMPOSITION_DEDICATED_INCONCLUSIVE_STALE_PREFLIGHT"
      },
      conservation: {
        physicalLoss: 0,
        physicalDuplication: 0,
        syntheticMaterial: 0,
        duplicateProbes: 0,
        duplicateAssets: 0,
        duplicateSettlements: 0,
        duplicateReceipts: 0
      },
      observerMutationCount: 0,
      repositoryGate: {stepsPassed: 35, stepsTotal: 35, assertions: $assertions},
      schemas: {checkpoint: 30, observer: 7},
      goldenRegeneration: "NOT_ATTEMPTED",
      productCorrections: 0,
      seniorReview: "MANDATORY",
      civ34: "NOT_STARTED",
      push: "NOT_ATTEMPTED"
    }' > "$BUNDLE_DIR/REPORT.json"

git diff --binary "$BASELINE"..HEAD > "$BUNDLE_DIR/PATCH.diff"

(
    cd "$BUNDLE_DIR"
    /usr/bin/find . -type f ! -name CHECKSUMS.sha256 -print0 \
        | LC_ALL=C /usr/bin/sort -z \
        | /usr/bin/xargs -0 shasum -a 256 > CHECKSUMS.sha256
    shasum -a 256 -c CHECKSUMS.sha256 >/dev/null
)

(
    cd "$OUTPUT_PARENT"
    /usr/bin/zip -q -r "$ZIP_PATH" "$BUNDLE_NAME"
)
/usr/bin/unzip -t "$ZIP_PATH" >/dev/null
ZIP_SHA=$(shasum -a 256 "$ZIP_PATH" | /usr/bin/awk '{print $1}')
CHECKSUM_COUNT=$(/usr/bin/wc -l < "$BUNDLE_DIR/CHECKSUMS.sha256" \
    | /usr/bin/tr -d ' ')

printf 'review bundle: %s\n' "$ZIP_PATH"
printf 'external SHA-256: %s\n' "$ZIP_SHA"
printf 'internal checksum count: %s\n' "$CHECKSUM_COUNT"
printf 'unzip test: PASS\n'
printf 'internal checksum validation: PASS\n'
