#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
BASELINE=5bc9d3088c2550fb042fe065235cb0154a226ff0
EVALUATION_HEAD=e75ab82981169baf1cdc67d9454e6d569e989167
EVALUATION_SHA=9db1a5b478f1ed0ca9efcac5612efc29928b61143a92e198123285920444fc93
BRANCH=codex/gate-e-blocker-01-exact-production-provenance
LIVE_DIR=${PEBBLELAB_BLOCKER01_LIVE_DIR:-/tmp/pebblelab-gate-e-blocker-01.aQ3ez1}
VALIDATION_DIR=${PEBBLELAB_BLOCKER01_VALIDATION_DIR:-/tmp/pebblelab-blocker-01-validation}
OUTPUT_PARENT=${PEBBLELAB_BLOCKER01_REVIEW_PARENT:-/tmp}

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

require_text() {
    needle=$1
    path=$2
    /usr/bin/grep -Fq "$needle" "$path" \
        || fail "required evidence absent from $path: $needle"
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

FOCUSED_LOG="$VALIDATION_DIR/gate-e-blocker-01.log"
GATE_LOG="$VALIDATION_DIR/repository-gate-final.log"
LIVE_SUMMARY="$VALIDATION_DIR/live-proof.log"
PROCESS_1="$LIVE_DIR/blocker-01-process-1.log"
PROCESS_2="$LIVE_DIR/blocker-01-process-2.log"

require_text '27 passed, 0 failed' "$FOCUSED_LOG"
for result in \
    'production:36' \
    'barter:54' \
    'contracts:30' \
    'material-rights:23' \
    'checkpoint-replay:49' \
    'persistence-reconciliation:19' \
    'candidate-physical-atomicity:3' \
    'observer:20' \
    'autonomous-civilization:36'; do
    name=${result%%:*}
    count=${result##*:}
    require_text "$count passed, 0 failed" "$VALIDATION_DIR/$name.log"
done
require_text '3950 passed, 0 failed' "$GATE_LOG"
require_text 'PASS: all 35 PebbleLab verification steps succeeded.' "$GATE_LOG"
require_text 'PASS: Gate E Blocker 01 exact produced-asset provenance live proof.' "$LIVE_SUMMARY"
require_text 'Fresh processes: 2' "$LIVE_SUMMARY"
require_text 'Checkpoint schema: 33' "$LIVE_SUMMARY"
require_text 'Observer schema: 10' "$LIVE_SUMMARY"
require_text 'Unexpected runtime errors: 0' "$LIVE_SUMMARY"
require_text 'matchingHistorical=3' "$PROCESS_1"
require_text 'attributedOperations=contract-bootstrap-production:gate-e-blocker-01:agent_1:bread:p3' "$PROCESS_2"
require_text 'attributedQuantity=1 otherMatchingRecords=2 falseMatchingAttributed=0' "$PROCESS_2"
require_text 'checkpoint loaded name=gate-e-blocker-01-open-v33' "$PROCESS_2"
require_text 'domain=contract reason=contractBoundary("current_rights_or_exact_physical_authority_refused")' "$PROCESS_2"
require_text 'contract blocker-01 returned' "$PROCESS_2"
require_text 'contract proof result=PASS' "$PROCESS_2"
require_text 'duplicateFulfillmentCount=0' "$PROCESS_2"
require_text 'physicalLoss=0 physicalDuplication=0 syntheticMaterial=0' "$PROCESS_2"
require_text 'runtimeErrors=0' "$PROCESS_1"
require_text 'runtimeErrors=0' "$PROCESS_2"

HEAD_COMMIT=$(git rev-parse HEAD)
HEAD_SHORT=$(git rev-parse --short=12 HEAD)
BUNDLE_NAME="PebbleLab-Gate-E-Blocker-01-Review-$HEAD_SHORT"
BUNDLE_DIR="$OUTPUT_PARENT/$BUNDLE_NAME"
ZIP_PATH="$OUTPUT_PARENT/$BUNDLE_NAME.zip"
[ ! -e "$BUNDLE_DIR" ] || fail "bundle directory exists: $BUNDLE_DIR"
[ ! -e "$ZIP_PATH" ] || fail "bundle ZIP exists: $ZIP_PATH"

/bin/mkdir -p "$BUNDLE_DIR/raw/owning-regressions" \
    "$BUNDLE_DIR/captures" \
    "$BUNDLE_DIR/checkpoints/gate-e-blocker-01-open-v33" \
    "$BUNDLE_DIR/checkpoints/gate-e-blocker-01-fulfilled-v33"

copy_required "$FOCUSED_LOG" "$BUNDLE_DIR/raw/focused-blocker-01.log"
copy_required "$GATE_LOG" "$BUNDLE_DIR/raw/repository-gate.log"
copy_required "$LIVE_SUMMARY" "$BUNDLE_DIR/raw/live-proof-summary.log"
copy_required "$PROCESS_1" "$BUNDLE_DIR/raw/blocker-01-process-1.log"
copy_required "$PROCESS_2" "$BUNDLE_DIR/raw/blocker-01-process-2.log"
copy_required docs/pebblelab/GATE_E_BLOCKER_01_EXACT_PRODUCTION_PROVENANCE.md \
    "$BUNDLE_DIR/raw/GATE_E_BLOCKER_01_EXACT_PRODUCTION_PROVENANCE.md"

for name in production barter contracts material-rights checkpoint-replay \
    persistence-reconciliation candidate-physical-atomicity observer \
    autonomous-civilization; do
    copy_required "$VALIDATION_DIR/$name.log" \
        "$BUNDLE_DIR/raw/owning-regressions/$name.log"
done

for capture in \
    blocker-01-three-productions.png \
    blocker-01-normal-proposal.png \
    blocker-01-open-debt.png \
    blocker-01-restored-open.png \
    blocker-01-displaced.png \
    blocker-01-refused-open.png \
    blocker-01-returned.png \
    blocker-01-fulfilled.png \
    blocker-01-final.png; do
    copy_required "$LIVE_DIR/captures/$capture" \
        "$BUNDLE_DIR/captures/$capture"
done

PERSISTENCE_ROOT="$LIVE_DIR/home/Library/Application Support/Pebble/PebbleLabAgents"
for checkpoint in gate-e-blocker-01-open-v33 \
    gate-e-blocker-01-fulfilled-v33; do
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

Verdict: `V4-GATE-E-v1 Blocker 01` is an
`IMPLEMENTED_LOCAL_REVIEW_CANDIDATE`. It is not published and does not acquire
Gate E. Evaluation 01 remains immutable `FAIL — PRODUCT CORRECTION REQUIRED`.
Evaluation 02 and CIV-38 are not started.

Review the exact Git identity first, then the authority, binding, contract,
barter, retention and atomicity reports. `PATCH.diff` is the complete
binary-safe patch from the evaluated published baseline. Raw focused, owning,
canonical-gate and two-process live traces, both checkpoints and all nine
inspected native captures are included. `CHECKSUMS.sha256` covers every other
file in this directory.
EOF

/bin/cat > "$BUNDLE_DIR/01_EXECUTIVE_SUMMARY.md" <<'EOF'
# Executive summary

Evaluation 01 found that CIV-36 attributed every historical production by the
current holder with a matching output to one exact promised asset. Three
distinct `bread x1` operations therefore became quantity 3 provenance for a
one-bread leg. The unchanged validator correctly refused the ambiguity.

The correction binds a minimal validated origin proof to the exact durable
Material Rights asset while its causal production record is live. CIV-35 and
CIV-36 now consume only that asset-bound proof. Current physical authority is
still reacquired independently. A two-process product proof reproduces three
identical breads, open debt, restart, adversarial displacement/refusal, return
and exact-once fulfillment with zero loss, duplication or synthetic material.
EOF

{
    printf '# Baseline and Git\n\n```text\n'
    printf 'repository: Ness-Now/pebble\n'
    printf 'canonical branch: lab/pebblelab-v1\n'
    printf 'baseline: %s\n' "$BASELINE"
    printf 'blocker branch: %s\n' "$BRANCH"
    printf 'candidate HEAD: %s\n' "$HEAD_COMMIT"
    printf 'evaluation branch: codex/gate-e-evaluation-01\n'
    printf 'evaluation evidence HEAD: %s\n' "$EVALUATION_HEAD"
    printf 'push attempted: NO\n```\n'
} > "$BUNDLE_DIR/02_BASELINE_AND_GIT.md"

{
    printf '# Evaluation 01 failure\n\n'
    printf '```text\n'
    printf 'evaluated baseline: %s\n' "$BASELINE"
    printf 'evaluation evidence HEAD: %s\n' "$EVALUATION_HEAD"
    printf 'verdict: FAIL — PRODUCT CORRECTION REQUIRED\n'
    printf 'review bundle SHA-256: %s\n' "$EVALUATION_SHA"
    printf '```\n\n'
    printf 'This historical result is immutable. The blocker candidate does not rewrite it as PASS.\n'
} > "$BUNDLE_DIR/03_EVALUATION_01_FAILURE.md"

/bin/cat > "$BUNDLE_DIR/04_ROOT_CAUSE.md" <<'EOF'
# Root cause

CIV-35/CIV-36 reconstructed provenance from `current holder + matching output`
over all retained production records. That is neither asset identity nor causal
origin. Three same-actor `bread x1` records were all attached to one `bread x1`
asset. Exact validator equality then received `3 != 1` and failed closed. The
validator remains unchanged; the attribution source is corrected.
EOF

/bin/cat > "$BUNDLE_DIR/05_PROVENANCE_AUTHORITY_MODEL.md" <<'EOF'
# Provenance authority model

PebbleCore/current Pebble observation owns physical truth. CIV-26 Material
Rights owns the durable stack-scoped asset and current observation. The new
origin proof is immutable historical evidence on that asset. CIV-35/CIV-36 cite
the proof but cannot use it to move matter. Current holder, identity, quantity
and current custody fingerprint must still be observed immediately before a
physical action. Holder, owner, producer and contract performer are distinct.
EOF

/bin/cat > "$BUNDLE_DIR/06_PRODUCTION_BINDING.md" <<'EOF'
# Production binding

Binding accepts only unique sorted live operation IDs and requires exact
producer/source/output, receipt, final fingerprint and represented quantity.
No operation may already belong to another asset. Multiple origins require an
exact causal before/after custody-fingerprint chain and remain bounded by the
causal cause limit. The persisted proof includes those fields, causal identity
and a deterministic digest. Forgery, identity/quantity mismatch, missing
claimed origin, cross-asset reuse and ambiguity fail closed.
EOF

/bin/cat > "$BUNDLE_DIR/07_CONTRACT_INTEGRATION.md" <<'EOF'
# Contract integration

Normal CIV-36 discovery reads only the exact promised asset's bound production
IDs. The reproduced P3 leg has one ID and quantity one despite three visible
same-actor bread records. Ordinary assets remain valid with an empty provenance
claim. Exact validator equality, current-custody reacquisition, predictable
publication prevalidation, both rollback paths, immediate retry, exact-once
fulfillment and restart durability remain intact.
EOF

/bin/cat > "$BUNDLE_DIR/08_BARTER_REGRESSION.md" <<'EOF'
# Barter regression

CIV-35 now reads the same exact asset-bound proof. The focused campaign covers
multiple identical outputs by one actor and one exact barter leg: unrelated
operations are not attributed, normal discovery and physical exchange remain
available, and custody transfer preserves original production origin.
EOF

/bin/cat > "$BUNDLE_DIR/09_CURRENT_PHYSICAL_AUTHORITY.md" <<'EOF'
# Current physical authority

After fresh restore, the exact promised P3 bread is moved physically to another
agent without changing the historical origin. Normal fulfillment refuses with
`current_rights_or_exact_physical_authority_refused`; debt remains outstanding
and no replacement is synthesized. Returning that same asset restores current
authority. Normal discovery and physical fulfillment then succeed once.
EOF

/bin/cat > "$BUNDLE_DIR/10_RETENTION_AND_PERSISTENCE.md" <<'EOF'
# Retention and persistence

Production history stays bounded (`maximumRecords`, default 256). Binding is
performed only while the exact source records are retained. Thereafter the
minimal immutable proof persists with the rights asset, including a digest and
causal/output/custody chain. A still-retained record must match every copied
field. Compaction therefore neither dangles nor reassigns provenance.

No schema bump is needed: the proof is an optional field on the existing
schema-33 Codable rights record. Older schema-33 checkpoints decode absence as
no claim. New state round-trips exactly, performs no World action on cognition
load and rejects corrupt/dangling causal proof. Observer remains schema 10.
EOF

/bin/cat > "$BUNDLE_DIR/11_ATOMICITY.md" <<'EOF'
# Atomicity

The correction does not change CIV-36 physical transaction ownership.
Predictable publication capacity is checked before mutation. Ordinary and
explicit post-mutation failures use verified compensation. The reacquired
current fingerprint is the immediate execution precondition. Publication
follows physical verification; failure retains open debt for exact retry.
EOF

/bin/cat > "$BUNDLE_DIR/12_FOCUSED_TESTS.md" <<'EOF'
# Focused tests

`PEBBLESMOKE_GATE_E_BLOCKER_01=1 swift run -c release pebsmoke`:

```text
27 passed, 0 failed
```

Coverage includes the three-bread collision, product-equivalent contract
discovery, custody transfer, restart, compaction, forged/corrupt proof,
identity/quantity mismatches, missing/ambiguous provenance, displaced matter,
return and exact-once fulfillment, CIV-35 and transferred produced-tool use.
The complete output is `raw/focused-blocker-01.log`.
EOF

/bin/cat > "$BUNDLE_DIR/13_REGRESSIONS.md" <<'EOF'
# Regressions

```text
production: 36/36
barter: 54/54
contracts: 30/30
material-rights: 23/23
checkpoint-replay: 49/49
persistence-reconciliation: 19/19
candidate-physical-atomicity: 3/3
observer: 20/20
autonomous-civilization: 36/36
owning total: 270/270, 0 failures
repository gate: 35/35, 3950/3950, 0 failures
goldens: NOT REGENERATED
```

Raw outputs are under `raw/owning-regressions/` and
`raw/repository-gate.log`.
EOF

/bin/cat > "$BUNDLE_DIR/14_LIVE_PROOF.md" <<'EOF'
# Live proof

Process 1 normally produces P1/P2/P3 as three distinct real breads and rights
assets, forms one normal one-bread promise, transfers real consideration, opens
debt and saves a restart-safe checkpoint. Process 2 restores fresh with all
three records, attributes only P3, displaces P3, observes fulfillment refusal
and open debt, returns P3, then completes normal physical fulfillment once.

```text
matching historical records: 3
promised quantity: 1
attributed operations: contract-bootstrap-production:gate-e-blocker-01:agent_1:bread:p3
attributed quantity: 1
false matching operations: 0
fresh processes: 2
captures inspected: 9
unexpected runtime errors: 0
```
EOF

/bin/cat > "$BUNDLE_DIR/15_CONSERVATION.md" <<'EOF'
# Conservation

```text
physicalLoss: 0
physicalDuplication: 0
syntheticMaterial: 0
observerMutationCount: 0
duplicate fulfillment: 0
synthetic replacement after displacement: 0
```

Production provenance never reconstructs absent matter and never substitutes
for current custody authority.
EOF

/bin/cat > "$BUNDLE_DIR/16_LIMITATIONS_AND_NON_CLAIMS.md" <<'EOF'
# Limitations and non-claims

- Evaluation 01 remains FAIL historical evidence.
- Blocker 01 is local and not senior-review approved or published.
- Gate E remains planned and not acquired.
- Evaluation 02 is not started and must be completely fresh after publication
  and remote verification.
- CIV-38 remains optional and not started.
- The proof is bounded stack-scoped origin evidence, not a per-unit UUID system,
  general supply-chain ledger, current ownership oracle or physical authority.
- Push attempted: NO.
EOF

{
    printf '{\n'
    printf '  "bundle": "V4-GATE-E-v1 Blocker 01",\n'
    printf '  "status": "IMPLEMENTED_LOCAL_REVIEW_CANDIDATE",\n'
    printf '  "repository": "Ness-Now/pebble",\n'
    printf '  "baseline": "%s",\n' "$BASELINE"
    printf '  "branch": "%s",\n' "$BRANCH"
    printf '  "candidateHead": "%s",\n' "$HEAD_COMMIT"
    printf '  "evaluation01": {\n'
    printf '    "evidenceHead": "%s",\n' "$EVALUATION_HEAD"
    printf '    "verdict": "FAIL — PRODUCT CORRECTION REQUIRED",\n'
    printf '    "reviewBundleSHA256": "%s"\n' "$EVALUATION_SHA"
    printf '  },\n'
    printf '  "provenance": {"matchingRecords": 3, "assetQuantity": 1, "operationIDs": ["contract-bootstrap-production:gate-e-blocker-01:agent_1:bread:p3"], "attributedQuantity": 1, "falseMatchingAttributed": 0, "exactBinding": "PASS", "ambiguityPolicy": "FAIL CLOSED"},\n'
    printf '  "validation": {"focusedPassed": 27, "focusedFailed": 0, "owningPassed": 270, "owningFailed": 0, "repositoryStepsPassed": 35, "repositoryStepsTotal": 35, "assertionsPassed": 3950, "assertionsFailed": 0},\n'
    printf '  "liveProof": {"status": "PASS", "freshProcesses": 2, "capturesInspected": 9, "unexpectedRuntimeErrors": 0, "physicalLoss": 0, "physicalDuplication": 0, "syntheticMaterial": 0, "observerMutationCount": 0, "duplicateFulfillment": 0},\n'
    printf '  "checkpointSchema": 33,\n'
    printf '  "observerSchema": 10,\n'
    printf '  "goldens": "NOT REGENERATED",\n'
    printf '  "gateE": "PLANNED — NOT ACQUIRED",\n'
    printf '  "evaluation02": "NOT_STARTED",\n'
    printf '  "civ38": "OPTIONAL — NOT STARTED",\n'
    printf '  "push": "NOT_ATTEMPTED"\n'
    printf '}\n'
} > "$BUNDLE_DIR/REPORT.json"

git diff --binary "$BASELINE"..HEAD > "$BUNDLE_DIR/PATCH.diff"
[ -s "$BUNDLE_DIR/PATCH.diff" ] || fail 'PATCH.diff is empty'

(
    cd "$BUNDLE_DIR"
    /usr/bin/find . -type f ! -name CHECKSUMS.sha256 -print \
        | LC_ALL=C /usr/bin/sort \
        | while IFS= read -r path; do
            /usr/bin/shasum -a 256 "$path"
        done > CHECKSUMS.sha256
    /usr/bin/shasum -a 256 -c CHECKSUMS.sha256 >/dev/null
)

/usr/bin/python3 -m json.tool "$BUNDLE_DIR/REPORT.json" >/dev/null
(
    cd "$OUTPUT_PARENT"
    /usr/bin/zip -qry "$ZIP_PATH" "$BUNDLE_NAME"
)
/usr/bin/unzip -tq "$ZIP_PATH" >/dev/null

ZIP_SHA=$(/usr/bin/shasum -a 256 "$ZIP_PATH" | /usr/bin/awk '{print $1}')
CHECKSUM_COUNT=$(/usr/bin/wc -l < "$BUNDLE_DIR/CHECKSUMS.sha256" \
    | /usr/bin/tr -d ' ')

printf 'Review bundle directory: %s\n' "$BUNDLE_DIR"
printf 'Review ZIP: %s\n' "$ZIP_PATH"
printf 'SHA-256: %s\n' "$ZIP_SHA"
printf 'Internal checksums: %s/%s PASS\n' "$CHECKSUM_COUNT" "$CHECKSUM_COUNT"
printf 'Unzip: PASS\n'
