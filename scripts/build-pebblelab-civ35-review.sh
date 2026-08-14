#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
BASELINE=8b7faa4cd03e315dec5696f72ec1ad75e333c77f
BRANCH=codex/civ-35-barter-local-exchange-v1
LIVE_DIR=${PEBBLELAB_CIV35_LIVE_DIR:-/var/folders/23/t4l5dv055dl3x1zqylcpl9wc0000gn/T/PebbleLab-live.05BFyO}
FOCUSED_LOG=${PEBBLELAB_CIV35_FOCUSED_LOG:-/tmp/PebbleLab-CIV35-focused.log}
GATE_LOG=${PEBBLELAB_CIV35_GATE_LOG:-/tmp/PebbleLab-CIV35-repository-gate.log}
OUTPUT_PARENT=${PEBBLELAB_CIV35_REVIEW_PARENT:-/tmp}

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
[ "$(git branch --show-current)" = "$BRANCH" ] \
    || fail 'unexpected branch'
[ "$(git rev-parse origin/lab/pebblelab-v1)" = "$BASELINE" ] \
    || fail 'canonical remote no longer matches the required baseline'
[ "$(git merge-base HEAD "$BASELINE")" = "$BASELINE" ] \
    || fail 'candidate is not based on the exact published baseline'
[ -z "$(git status --short)" ] || fail 'worktree must be clean'

/usr/bin/grep -q '22 passed, 0 failed' "$FOCUSED_LOG" \
    || fail 'focused CIV-35 result is absent'
/usr/bin/grep -q '3830 passed, 0 failed' "$GATE_LOG" \
    || fail 'complete assertion result is absent'
/usr/bin/grep -q 'PASS: all 35 PebbleLab verification steps succeeded' \
    "$GATE_LOG" || fail 'repository gate did not pass 35/35'
/usr/bin/grep -q 'barter proof normalProductPath=PASS' \
    "$LIVE_DIR/barter-phase1.log" || fail 'normal live product path is absent'
/usr/bin/grep -q 'CANDIDATE_PHYSICAL_ROLLBACK operation=advanceOneTick' \
    "$LIVE_DIR/barter-phase1.log" || fail 'mid-exchange rollback is absent'
/usr/bin/grep -q 'bartered produced tool used .*downstreamUse=PASS' \
    "$LIVE_DIR/barter-phase2.log" || fail 'fresh-process downstream use is absent'
/usr/bin/grep -q 'checkpoint saved name=barter-final-v32 .*restartSafe=1' \
    "$LIVE_DIR/barter-phase2.log" || fail 'final checkpoint is absent'

HEAD_COMMIT=$(git rev-parse HEAD)
HEAD_SHORT=$(git rev-parse --short=12 HEAD)
BUNDLE_NAME="PebbleLab-CIV-35-Review-$HEAD_SHORT"
BUNDLE_DIR="$OUTPUT_PARENT/$BUNDLE_NAME"
ZIP_PATH="$OUTPUT_PARENT/$BUNDLE_NAME.zip"
[ ! -e "$BUNDLE_DIR" ] || fail "bundle directory exists: $BUNDLE_DIR"
[ ! -e "$ZIP_PATH" ] || fail "bundle ZIP exists: $ZIP_PATH"

/bin/mkdir -p "$BUNDLE_DIR/raw" "$BUNDLE_DIR/captures" \
    "$BUNDLE_DIR/checkpoints/barter-v32" \
    "$BUNDLE_DIR/checkpoints/barter-final-v32"

copy_required "$FOCUSED_LOG" "$BUNDLE_DIR/raw/focused-barter.log"
copy_required "$GATE_LOG" "$BUNDLE_DIR/raw/repository-gate.log"
copy_required "$LIVE_DIR/barter-phase1.log" "$BUNDLE_DIR/raw/barter-phase1.log"
copy_required "$LIVE_DIR/barter-phase2.log" "$BUNDLE_DIR/raw/barter-phase2.log"
copy_required docs/pebblelab/CIV_35_PHASE_SUMMARY.md \
    "$BUNDLE_DIR/raw/CIV_35_PHASE_SUMMARY.md"

for capture in \
    barter-pre-exchange.png \
    barter-offer.png \
    barter-post-exchange.png \
    barter-restored.png \
    barter-produced-tool-used.png \
    barter-final.png; do
    copy_required "$LIVE_DIR/captures/$capture" "$BUNDLE_DIR/captures/$capture"
done

PERSISTENCE_ROOT="$LIVE_DIR/home/Library/Application Support/Pebble/PebbleLabAgents"
for checkpoint in barter-v32 barter-final-v32; do
    checkpoint_dir=$(/usr/bin/find "$PERSISTENCE_ROOT" -type d \
        -path "*/checkpoints/$checkpoint" -print -quit)
    [ -n "$checkpoint_dir" ] || fail "checkpoint missing: $checkpoint"
    copy_required "$checkpoint_dir/manifest.json" \
        "$BUNDLE_DIR/checkpoints/$checkpoint/manifest.json"
    copy_required "$checkpoint_dir/session.json" \
        "$BUNDLE_DIR/checkpoints/$checkpoint/session.json"
done

/bin/cat > "$BUNDLE_DIR/00_README_FIRST.md" <<'EOF'
# Read this first

Verdict: `CIV-35 — Barter and Local Exchange V1` is an
`IMPLEMENTED_LOCAL_REVIEW_CANDIDATE`, not a published phase. Review the exact
Git identity in `02_BASELINE_AND_GIT.md`, then the authority and atomicity
reports. `PATCH.diff` is the complete binary-safe patch from the required
published baseline. `CHECKSUMS.sha256` covers every other bundle file.

Raw focused, repository-gate and two-process live traces are under `raw/`.
Both durable checkpoints and all six inspected native captures are included.
EOF

/bin/cat > "$BUNDLE_DIR/01_EXECUTIVE_SUMMARY.md" <<'EOF'
# Executive summary

Two local inhabitants exchange real current physical goods: agent_0 offers
one CIV-34-produced stone pickaxe for two CIV-34-produced breads held by
agent_1. Agent_1 independently accepts from current local evidence. Pebble
prevalidates and transfers both exact Core inventory sides before the sole
session publishes one exchange and reconciles CIV-26 rights.

A deterministic fault fires after the first real transfer. Existing candidate
compensation restores the exact physical state and leaves session and recorder
unchanged; immediate retry completes once. A fresh process restores the
exchanged custody without duplication, and agent_1 uses the same pickaxe in a
real stone-to-air action. No debt, market, price or currency semantics exist.
EOF

{
    printf '# Baseline and Git\n\n'
    printf '```text\n'
    printf 'repository: Ness-Now/pebble\n'
    printf 'baseline: %s\n' "$BASELINE"
    printf 'branch: %s\n' "$BRANCH"
    printf 'candidate HEAD: %s\n' "$HEAD_COMMIT"
    printf 'push attempted: NO\n'
    printf '```\n'
} > "$BUNDLE_DIR/02_BASELINE_AND_GIT.md"

/bin/cat > "$BUNDLE_DIR/03_REUSE_FIRST_AUDIT.md" <<'EOF'
# Reuse-first audit

- Physical stacks, extraction, insertion and capacity: PebbleCore.
- Live transfer, inspection and fingerprints: existing
  `PebbleAgentMaterialCustodyGateway`.
- Tick-wide rollback: existing `PebbleCandidatePhysicalTransaction`.
- Holder, owner, custodian, claims and permissions: CIV-26 Material Rights.
- Production provenance and real output identity: CIV-34 production records.
- Locality: existing bounded physical-signal adapter.
- Decisions, history, checkpoint, replay and causality: sole
  `AgentSimulationSession`.
- Read-only inspection: Observer.

No parallel inventory, transfer engine, market, price oracle, currency or
obligation system was introduced.
EOF

/bin/cat > "$BUNDLE_DIR/04_ARCHITECTURE_AND_AUTHORITY.md" <<'EOF'
# Architecture and authority

PebbleAgents owns deterministic opportunity, offer, counterparty decision and
verified history only. Pebble owns observation plus physical prevalidation,
mutation, verification and compensation. PebbleCore remains physical truth.
Rights publication follows verified physical success and cannot create or
replace matter. `AgentSimulationSession` remains the sole aggregate root.
EOF

/bin/cat > "$BUNDLE_DIR/05_BARTER_CONTRACT.md" <<'EOF'
# Barter contract

CIV-35 is immediate spot barter. One bounded opportunity binds two distinct
agents, two exact stack-scoped assets, current full-custody fingerprints,
quantities, local evidence and causal needs. Offer and acceptance do not move
matter. Completion requires two verified physical receipts now. Self-trade,
empty/invalid sides, overlapping assets and duplicate operations fail closed.
No future delivery or obligation is representable.
EOF

/bin/cat > "$BUNDLE_DIR/06_LOCAL_DISCOVERY_AND_DECISION.md" <<'EOF'
# Local discovery and decision

The decisive pair is one Manhattan cell apart. Opportunity formation uses the
existing bounded distance, line-of-sight and ready-chunk signal. Agent_0 has a
physical-food need for bread x2; agent_1 has a missing-useful-tool need for a
stone pickaxe. There is no settlement inventory query, global supply/demand,
best-trade search or numerical price.
EOF

/bin/cat > "$BUNDLE_DIR/07_OFFERS_ACCEPTANCE_REJECTION.md" <<'EOF'
# Offers, acceptance and rejection

Agent_0 creates `civ35-primary`; matter remains unchanged. On a later normal
tick, agent_1 rechecks its active need and current local physical signal before
explicit acceptance. The focused variation proves rejection publishes no
physical receipt, followed by an alternative accepted offer. Withdrawal and
expiry remove authority for later acceptance. Pending offers are bounded.
EOF

/bin/cat > "$BUNDLE_DIR/08_PHYSICAL_TWO_SIDED_TRANSFER.md" <<'EOF'
# Physical two-sided transfer

Pebble rechecks both CIV-26 disposal decisions and both current fingerprints.
Read-only prevalidation simulates pickaxe insertion and bread insertion with
canonical Core rules before mutation. It then transfers pickaxe x1 and bread
x2 through the existing custody gateway, verifies both endpoints and emits the
two receipt identities retained in the completed record. Publication follows
both receipts only.
EOF

/bin/cat > "$BUNDLE_DIR/09_RIGHTS_AND_CUSTODY.md" <<'EOF'
# Rights and custody

Before exchange, each producer is physical holder and recognized owner of its
asset. Holder alone is insufficient to dispose: the focused unauthorized
scenario returns `noUseRight`. After verified exchange, the pickaxe record
names agent_1 as holder, custodian and recognized owner with a received claim;
the bread record names agent_0 equivalently. Two bounded rights transitions
cite the completed barter event. Tool use later evolves only current pickaxe
identity, not its asset or provenance.
EOF

/bin/cat > "$BUNDLE_DIR/10_ATOMICITY_AND_ROLLBACK.md" <<'EOF'
# Atomicity and rollback

The phase-1 trace reaches a real first-leg mutation and then throws the
deterministic barter post-mutation fault. The candidate transaction reports
the registered/completed reverse transfer, zero retained receipts, unchanged
published session and unchanged recorder. The next same-process tick repeats
agent_1's evaluation and completes once. No half-barter becomes observable.
EOF

/bin/cat > "$BUNDLE_DIR/11_CONTENTION_AND_STALE_AUTHORITY.md" <<'EOF'
# Contention and stale authority

An exact asset may be reserved by only one open/accepted offer. A competing
offer is refused, preventing double spend and duplicate receipts. Current
fingerprints defeat historical authority after external custody change. Live
probes return `staleSource`, `invalidRequest` or `insufficientQuantity`, and
`destinationFull` without mutation or substitute selection.
EOF

/bin/cat > "$BUNDLE_DIR/12_CIV34_PRODUCED_GOOD_INTEGRATION.md" <<'EOF'
# CIV-34 produced-good integration

Agent_0's pickaxe retains production operation
`barter-production:barter:agent_0:produce-pickaxe`, output identity and physical
custody continuously into the offer and exchange. No fixture replaces it.
After restart, agent_1 uses that same item: `stone_pickaxe`, damage 0 to 1,
real World stone to air. The use event cites production and barter completion.
EOF

/bin/cat > "$BUNDLE_DIR/13_RESTART_AND_REPLAY.md" <<'EOF'
# Restart and replay

Schema 32 refuses checkpoint readiness while any offer is open or accepted;
pending physical authority is deliberately not durable. Completed terminal
history and rights are durable. A second Pebble process restores two stacks,
quantity three, with `custodyDuplicates=0`; no barter completion repeats.
Typed replay reconstructs social history only and never invokes a World
transfer.
EOF

/bin/cat > "$BUNDLE_DIR/14_OBSERVER_AND_CAUSALITY.md" <<'EOF'
# Observer and causality

Observer schema 9 projects participants, exact goods and quantities, causal
needs, offer status, rejection/stale/completed reasons, verified receipts and
post-exchange rights. Snapshot generation advances neither tick nor causal
sequence and mutates no custody (`observerMutationCount=0`). The Chronicle
orders offer, counterparty decision, barter completion and both rights events.
EOF

/bin/cat > "$BUNDLE_DIR/15_CONSERVATION.md" <<'EOF'
# Conservation

The completed barter moves one pickaxe and two breads between holders without
consumption. Campaign totals are `physicalLoss=0`, `physicalDuplication=0`,
`syntheticMaterial=0`, `duplicateExchangeReceipts=0` and
`duplicateReservations=0`. The later authorized durability change is outside
the exchange and is reconciled through the existing rights-use path.
EOF

/bin/cat > "$BUNDLE_DIR/16_REGRESSIONS.md" <<'EOF'
# Regressions

The complete 3,830-assertion smoke suite includes CIV-26 rights/custody,
CIV-27 persistence/reconciliation, CIV-28 Observer, Gate D physical boundaries
and evolved identities, CIV-33 estates, and all CIV-34 Core production and
produced-tool proofs. The canonical repository gate passes 35/35. Goldens are
read-only and were not regenerated.
EOF

/bin/cat > "$BUNDLE_DIR/17_LIVE_VISUAL_PROOF.md" <<'EOF'
# Live visual proof

Seed 46 ran in two fresh Pebble processes under an isolated home. Phase 1
shows pre-exchange, open offer and post-exchange state and contains one expected
fault. Phase 2 shows fresh restore, exact produced-tool use and final cleanup
with zero runtime errors. All six native captures were manually inspected;
structured traces, not pixels, carry exact quantities and receipt authority.
EOF

/bin/cat > "$BUNDLE_DIR/18_TEST_RESULTS.md" <<'EOF'
# Test results

```text
focused CIV-35: 22 passed, 0 failed
complete smoke: 3830 passed, 0 failed
repository gate: 35/35, 0 failures
checkpoint schema: 32
Observer schema: 9
golden regeneration: not attempted
live fresh process count: 2
live phase-1 runtime errors: 1 expected injected fault
live phase-2 runtime errors: 0
```
EOF

/bin/cat > "$BUNDLE_DIR/19_LIMITATIONS_AND_NON_CLAIMS.md" <<'EOF'
# Limitations and non-claims

CIV-35 does not prove debt, future promises, durable contracts, credit,
markets, market price discovery, currency, accounting, merchant organizations,
large-scale trade or global logistics. It adds no loans, interest, default,
contract enforcement, order book, matching engine, market stall authority,
supply/demand curve, guild, firm, shop, taxation, wage or trade-law system.
CIV-36, CIV-37 and CIV-38 remain outside this candidate.
EOF

/usr/bin/jq -n \
    --arg baseline "$BASELINE" \
    --arg branch "$BRANCH" \
    --arg head "$HEAD_COMMIT" \
    --arg liveEvidence "$LIVE_DIR" \
    '{
      phase: "CIV-35",
      title: "Barter and Local Exchange V1",
      verdict: "IMPLEMENTED_LOCAL_REVIEW_CANDIDATE",
      published: false,
      baseline: $baseline,
      branch: $branch,
      head: $head,
      pushAttempted: false,
      exchange: {
        offeror: "agent_0",
        counterparty: "agent_1",
        offered: "stone_pickaxe:1",
        requested: "bread:2",
        normalProductPath: "PASS",
        secondVariation: "PASS"
      },
      atomicity: {
        trueMidExchangeMutation: true,
        rollback: "exact",
        immediateRetry: "PASS"
      },
      restart: {
        freshProcess: "PASS",
        duplicateExchangeCount: 0,
        downstreamRealUse: "PASS"
      },
      accounting: {
        physicalLoss: 0,
        physicalDuplication: 0,
        syntheticMaterial: 0,
        duplicateExchangeReceipts: 0,
        duplicateReservations: 0,
        observerMutationCount: 0
      },
      validation: {
        focusedPassed: 22,
        focusedFailed: 0,
        assertionsPassed: 3830,
        assertionsFailed: 0,
        repositoryStepsPassed: 35,
        repositoryStepsTotal: 35,
        checkpointSchema: 32,
        observerSchema: 9,
        goldenRegenerationAttempted: false,
        freshProcessCount: 2,
        nativeCapturesInspected: 6,
        phase1ExpectedRuntimeErrors: 1,
        phase2RuntimeErrors: 0,
        liveEvidenceRoot: $liveEvidence
      }
    }' > "$BUNDLE_DIR/REPORT.json"

git diff --binary "$BASELINE"..HEAD > "$BUNDLE_DIR/PATCH.diff"

(
    cd "$BUNDLE_DIR"
    /usr/bin/find . -type f ! -name CHECKSUMS.sha256 -print \
        | LC_ALL=C /usr/bin/sort \
        | while IFS= read -r file; do
            /usr/bin/shasum -a 256 "$file"
        done > CHECKSUMS.sha256
    /usr/bin/shasum -a 256 -c CHECKSUMS.sha256 >/dev/null
    /usr/bin/jq empty REPORT.json
)

(
    cd "$OUTPUT_PARENT"
    /usr/bin/zip -qry "$ZIP_PATH" "$BUNDLE_NAME"
)
/usr/bin/unzip -t "$ZIP_PATH" >/dev/null

EXTERNAL_SHA=$(/usr/bin/shasum -a 256 "$ZIP_PATH" | /usr/bin/awk '{print $1}')
CHECKSUM_COUNT=$(/usr/bin/wc -l < "$BUNDLE_DIR/CHECKSUMS.sha256" \
    | /usr/bin/tr -d ' ')
printf 'review bundle: %s\n' "$ZIP_PATH"
printf 'external SHA-256: %s\n' "$EXTERNAL_SHA"
printf 'internal checksum count: %s\n' "$CHECKSUM_COUNT"
printf 'internal checksums: PASS\n'
printf 'unzip validation: PASS\n'
