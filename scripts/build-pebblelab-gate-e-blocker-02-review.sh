#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
BASELINE=9ede5d73229c3c9284d163ed17cc76bcf92ebe0e
EVALUATION_HEAD=2f95826f474c9f2a366f4b06df90a8643beb7a98
EVALUATION_SHA=4e10d129927af5c8443f9f8e26fec0d276f797cf82126b93792f32c26c646d57
BRANCH=codex/gate-e-blocker-02-evolved-production-identity
LIVE_DIR=${PEBBLELAB_BLOCKER02_LIVE_DIR:-/tmp/pebblelab-gate-e-blocker-02.FlI3hm}
BLOCKER01_LIVE_DIR=${PEBBLELAB_BLOCKER01_LIVE_DIR:-/tmp/pebblelab-gate-e-blocker-01.cvzT78}
VALIDATION_DIR=${PEBBLELAB_BLOCKER02_VALIDATION_DIR:-/tmp/pebblelab-gate-e-blocker-02-evidence.O02eEG}
OUTPUT_PARENT=${PEBBLELAB_BLOCKER02_REVIEW_PARENT:-/tmp}

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
    || fail 'candidate is not rooted at the exact published baseline'
if git merge-base --is-ancestor "$EVALUATION_HEAD" HEAD; then
    fail 'Evaluation 02 evidence entered Blocker 02 ancestry'
fi
[ -z "$(git status --short)" ] || fail 'worktree must be clean'

FOCUSED_LOG="$VALIDATION_DIR/focused-blocker-02.log"
BLOCKER01_FOCUSED_LOG="$VALIDATION_DIR/focused-blocker-01.log"
GATE_LOG="$VALIDATION_DIR/repository-gate.log"
PROCESS_1="$LIVE_DIR/blocker-02-process-1.log"
PROCESS_2="$LIVE_DIR/blocker-02-process-2.log"
BLOCKER01_SUMMARY="$VALIDATION_DIR/live-blocker-01.log"

require_text '33 passed, 0 failed' "$FOCUSED_LOG"
require_text '27 passed, 0 failed' "$BLOCKER01_FOCUSED_LOG"
for result in \
    'production:36' \
    'barter:54' \
    'contracts:30' \
    'markets:31' \
    'material-rights:23' \
    'candidate-physical-atomicity:3' \
    'checkpoint-replay:49' \
    'persistence-reconciliation:19' \
    'observer:20' \
    'autonomous-civilization:36'; do
    name=${result%%:*}
    count=${result##*:}
    require_text "$count passed, 0 failed" "$VALIDATION_DIR/owning-$name.log"
done
require_text '3983 passed, 0 failed' "$GATE_LOG"
require_text 'PASS: all 35 PebbleLab verification steps succeeded.' "$GATE_LOG"
require_text 'Goldens: read-only; PEBBLE_REGOLD is refused.' "$GATE_LOG"
require_text 'PASS: Gate E Blocker 01 exact produced-asset provenance live proof.' "$BLOCKER01_SUMMARY"
require_text 'Fresh processes: 2' "$BLOCKER01_SUMMARY"

require_text 'damage=0>1 world=stone>air dropsAcquired=1 downstreamUse=PASS' "$PROCESS_1"
require_text 'originIdentity=stone_pickaxe:damage0 currentIdentity=stone_pickaxe:damage1' "$PROCESS_1"
require_text 'checkpoint saved name=gate-e-blocker-02-damage1-v34' "$PROCESS_1"
require_text 'runtimeErrors=0' "$PROCESS_1"
require_text 'checkpoint loaded name=gate-e-blocker-02-damage1-v34' "$PROCESS_2"
require_text 'custodyDuplicates=0' "$PROCESS_2"
require_text 'damage=1>2 world=stone>air dropsAcquired=1 downstreamUse=PASS' "$PROCESS_2"
require_text 'originIdentity=stone_pickaxe:damage0 currentIdentity=stone_pickaxe:damage2' "$PROCESS_2"
require_text 'normalEconomicDiscovery=1' "$PROCESS_2"
require_text 'normalBarterSettlementAfterEvolution=1' "$PROCESS_2"
require_text 'historicalOriginAsCurrentAuthority=refused' "$PROCESS_2"
require_text 'physicalLoss=0 physicalDuplication=0 syntheticMaterial=0' "$PROCESS_2"
require_text 'duplicateProductionReceipts=0 duplicateBarterReceipts=0 duplicateReservations=0' "$PROCESS_2"
require_text 'observerMutationCount=0 currencyAuthority=0 checkpointSchema=34 replaySchema=34 observerSchema=11' "$PROCESS_2"
require_text 'checkpoint saved name=gate-e-blocker-02-damage2-v34' "$PROCESS_2"
require_text 'Barter disposable fixture cleanup cells=exact exchangedCustody=retained' "$PROCESS_2"
require_text 'runtimeErrors=0' "$PROCESS_2"

HEAD_COMMIT=$(git rev-parse HEAD)
HEAD_SHORT=$(git rev-parse --short=12 HEAD)
BUNDLE_NAME="PebbleLab-Gate-E-Blocker-02-Review-$HEAD_SHORT"
BUNDLE_DIR="$OUTPUT_PARENT/$BUNDLE_NAME"
ZIP_PATH="$OUTPUT_PARENT/$BUNDLE_NAME.zip"
[ ! -e "$BUNDLE_DIR" ] || fail "bundle directory exists: $BUNDLE_DIR"
[ ! -e "$ZIP_PATH" ] || fail "bundle ZIP exists: $ZIP_PATH"

/bin/mkdir -p \
    "$BUNDLE_DIR/raw/owning-regressions" \
    "$BUNDLE_DIR/raw/blocker-01" \
    "$BUNDLE_DIR/captures" \
    "$BUNDLE_DIR/checkpoints/gate-e-blocker-02-damage1-v34" \
    "$BUNDLE_DIR/checkpoints/gate-e-blocker-02-damage2-v34" \
    "$BUNDLE_DIR/checkpoints/blocker-01/gate-e-blocker-01-open-v33" \
    "$BUNDLE_DIR/checkpoints/blocker-01/gate-e-blocker-01-fulfilled-v33"

copy_required "$FOCUSED_LOG" "$BUNDLE_DIR/raw/focused-blocker-02.log"
copy_required "$BLOCKER01_FOCUSED_LOG" "$BUNDLE_DIR/raw/blocker-01/focused-blocker-01.log"
copy_required "$VALIDATION_DIR/build-pebsmoke-release.log" "$BUNDLE_DIR/raw/build-pebsmoke-release.log"
copy_required "$GATE_LOG" "$BUNDLE_DIR/raw/repository-gate.log"
copy_required "$VALIDATION_DIR/live-blocker-01-dry-run.log" "$BUNDLE_DIR/raw/blocker-01/live-dry-run.log"
copy_required "$BLOCKER01_SUMMARY" "$BUNDLE_DIR/raw/blocker-01/live-proof.log"
copy_required "$PROCESS_1" "$BUNDLE_DIR/raw/blocker-02-process-1.log"
copy_required "$PROCESS_2" "$BUNDLE_DIR/raw/blocker-02-process-2.log"
copy_required "$BLOCKER01_LIVE_DIR/blocker-01-process-1.log" "$BUNDLE_DIR/raw/blocker-01/process-1.log"
copy_required "$BLOCKER01_LIVE_DIR/blocker-01-process-2.log" "$BUNDLE_DIR/raw/blocker-01/process-2.log"
copy_required docs/pebblelab/GATE_E_BLOCKER_02_EVOLVED_PRODUCTION_IDENTITY.md \
    "$BUNDLE_DIR/raw/GATE_E_BLOCKER_02_EVOLVED_PRODUCTION_IDENTITY.md"

for name in production barter contracts markets material-rights \
    candidate-physical-atomicity checkpoint-replay persistence-reconciliation \
    observer autonomous-civilization; do
    copy_required "$VALIDATION_DIR/owning-$name.log" \
        "$BUNDLE_DIR/raw/owning-regressions/$name.log"
done

for capture in \
    blocker-02-setup.png \
    blocker-02-first-discovery.png \
    blocker-02-damage-1.png \
    blocker-02-restored-damage-1.png \
    blocker-02-damage-2.png \
    blocker-02-evolved-discovery.png \
    blocker-02-evolved-settled.png \
    blocker-02-final.png; do
    copy_required "$LIVE_DIR/captures/$capture" "$BUNDLE_DIR/captures/$capture"
done

PERSISTENCE_ROOT="$LIVE_DIR/home/Library/Application Support/Pebble/PebbleLabAgents"
for checkpoint in gate-e-blocker-02-damage1-v34 gate-e-blocker-02-damage2-v34; do
    checkpoint_dir=$(/usr/bin/find "$PERSISTENCE_ROOT" -type d \
        -path "*/checkpoints/$checkpoint" -print -quit)
    [ -n "$checkpoint_dir" ] || fail "checkpoint missing: $checkpoint"
    copy_required "$checkpoint_dir/manifest.json" "$BUNDLE_DIR/checkpoints/$checkpoint/manifest.json"
    copy_required "$checkpoint_dir/session.json" "$BUNDLE_DIR/checkpoints/$checkpoint/session.json"
done

BLOCKER01_PERSISTENCE="$BLOCKER01_LIVE_DIR/home/Library/Application Support/Pebble/PebbleLabAgents"
for checkpoint in gate-e-blocker-01-open-v33 gate-e-blocker-01-fulfilled-v33; do
    checkpoint_dir=$(/usr/bin/find "$BLOCKER01_PERSISTENCE" -type d \
        -path "*/checkpoints/$checkpoint" -print -quit)
    [ -n "$checkpoint_dir" ] || fail "Blocker 01 checkpoint missing: $checkpoint"
    copy_required "$checkpoint_dir/manifest.json" "$BUNDLE_DIR/checkpoints/blocker-01/$checkpoint/manifest.json"
    copy_required "$checkpoint_dir/session.json" "$BUNDLE_DIR/checkpoints/blocker-01/$checkpoint/session.json"
done

/bin/cat > "$BUNDLE_DIR/00_README_FIRST.md" <<'EOF'
# Read this first

Verdict: `V4-GATE-E-v1 Blocker 02` is an
`IMPLEMENTED_LOCAL_REVIEW_CANDIDATE`. It is not published and does not acquire
Gate E. Evaluation 02 remains immutable historical FAIL evidence. Evaluation
03 and CIV-38 are not started.

Start with Git identity and the three-authority model, then challenge the raw
focused and two-process live traces. `PATCH.diff` is the complete binary-safe
diff from the exact published baseline. Both schema-34 checkpoints, raw
session/manifest files, proportional regressions, Blocker 01 non-regression,
repository-gate output and all eight inspected captures are included.
`CHECKSUMS.sha256` covers every other file in the archive.
EOF

/bin/cat > "$BUNDLE_DIR/01_EXECUTIVE_SUMMARY.md" <<'EOF'
# Executive summary

Evaluation 02 proved that a normally produced damage-0 pickaxe retained valid
durable identity after transfer and legitimate use to damage 1, yet shared
production-provenance validation rejected it because immutable origin identity
was compared for exact equality with current identity.

The correction changes only that shared comparison to the existing Material
Rights continuity primitive. Immutable origin remains exact and current
holder, quantity, identity and custody fingerprint remain separate exact
mutation authority. Focused checks pass 33/33; a fresh two-process proof
restores damage 1, advances normally to damage 2, rediscovers and physically
settles the evolved tool, and reports zero loss, duplication or synthesis.
EOF

{
    printf '# Baseline and Git\n\n```text\n'
    printf 'repository: Ness-Now/pebble\n'
    printf 'canonical branch: lab/pebblelab-v1\n'
    printf 'baseline: %s\n' "$BASELINE"
    printf 'blocker branch: %s\n' "$BRANCH"
    printf 'candidate HEAD: %s\n' "$HEAD_COMMIT"
    printf 'Evaluation 02 evidence HEAD in ancestry: NO\n'
    printf 'push attempted: NO\n```\n'
} > "$BUNDLE_DIR/02_BASELINE_AND_GIT.md"

{
    printf '# Evaluation 02 failure\n\n```text\n'
    printf 'evaluated baseline: %s\n' "$BASELINE"
    printf 'evaluation evidence HEAD: %s\n' "$EVALUATION_HEAD"
    printf 'verdict: FAIL — PRODUCT CORRECTION REQUIRED\n'
    printf 'review bundle SHA-256: %s\n' "$EVALUATION_SHA"
    printf '```\n\nThis historical result remains immutable and is not rewritten as PASS.\n'
} > "$BUNDLE_DIR/03_EVALUATION_02_FAILURE.md"

/bin/cat > "$BUNDLE_DIR/04_ROOT_CAUSE.md" <<'EOF'
# Root cause

The durable asset reference already allowed a legitimate current identity, but
`materialProductionProvenanceMatches` required the immutable production-origin
identity to equal the current full identity. Damage `0 != 1` therefore
invalidated historically true provenance. The mismatch was in one shared
Material Rights boundary, not in physical continuity or the current custody
gateway.
EOF

/bin/cat > "$BUNDLE_DIR/05_IDENTITY_AUTHORITY_MODEL.md" <<'EOF'
# Identity authority model

Three authorities remain independent: immutable production origin says asset A
originated in operation P as I0; existing durable-asset continuity decides
whether current I1 is representable by A; exact current physical authority
requires current holder, I1, quantity and custody fingerprint. Neither history
nor continuity can move matter without the exact current observation.
EOF

/bin/cat > "$BUNDLE_DIR/06_IMMUTABLE_PRODUCTION_ORIGIN.md" <<'EOF'
# Immutable production origin

The decisive asset retains operation
`barter-production:barter:agent_0:produce-pickaxe`, producer `agent_0`, origin
`stone_pickaxe damage=0`, quantity 1 and digest `e91679bbdf3ee8a6` throughout
both processes and both durability evolutions. Origin rewrite count is zero.
The source production record may compact; the validated bounded origin proof
remains on the exact durable Material Rights asset.
EOF

/bin/cat > "$BUNDLE_DIR/07_CURRENT_ASSET_CONTINUITY.md" <<'EOF'
# Current asset continuity

The correction reuses `AgentMaterialAssetReference.permitsCurrentIdentity`.
The same asset legitimately advances damage `0 -> 1 -> 2`; item-key
replacement, incompatible identity and another asset's provenance remain
refused. No second evolution model or item-specific exception was introduced.
EOF

/bin/cat > "$BUNDLE_DIR/08_CURRENT_PHYSICAL_AUTHORITY.md" <<'EOF'
# Current physical authority

Current holder, exact evolved identity, quantity and custody fingerprint remain
separate exact requirements. Wrong holder, quantity and stale fingerprint fail
closed. Historical damage 0 cannot spend damage 1 or 2. After damage 2, stale
damage-1 authority is refused and freshly reacquired damage-2 authority
succeeds.
EOF

/bin/cat > "$BUNDLE_DIR/09_BARTER_REGRESSION.md" <<'EOF'
# Barter regression

Focused discovery accepts the evolved produced asset without mutation. The
two-process live proof restores damage 1, performs a second physical use, then
normal cognition discovers, offers, independently accepts and physically
settles a reverse barter of the damage-2 tool. Duplicate barter receipts remain
zero in live evidence and exactly-once in the focused duplicate attempt.
EOF

/bin/cat > "$BUNDLE_DIR/10_CONTRACT_REGRESSION.md" <<'EOF'
# Contract regression

Focused CIV-36 paths accept legitimate evolved production provenance for both
consideration discovery and performance fulfillment only when exact current
physical authority is present. Historical provenance does not relax the
fulfillment gateway.
EOF

/bin/cat > "$BUNDLE_DIR/11_MARKET_REGRESSION.md" <<'EOF'
# Market regression

Focused CIV-37 deposits the exact evolved asset into real market custody and
continues normal listing action after schema-34 restore. Historical agent
observation cannot spend market-held matter. The correction therefore applies
at the shared provenance boundary without weakening market custody.
EOF

/bin/cat > "$BUNDLE_DIR/12_BLOCKER_01_NON_REGRESSION.md" <<'EOF'
# Blocker 01 non-regression

The exact prior focused suite passes 27/27 and its dedicated two-process live
proof passes. Three same-actor `bread x1` records bind only P3 to the exact
one-bread asset; false attribution is zero. Displacement refuses fulfillment,
same-asset return restores current authority and fulfillment occurs exactly
once. Blocker 01 remains fixed and published.
EOF

/bin/cat > "$BUNDLE_DIR/13_RETENTION_AND_RESTART.md" <<'EOF'
# Retention and restart

Process 2 is a fresh OS process restoring
`gate-e-blocker-02-damage1-v34`. Asset ID, operation, origin damage 0, holder
and current damage 1 survive with `custodyDuplicates=0`. Focused compaction
evicts the source production record, then evolution and restart retain valid
immutable origin; deliberately corrupted retained origin fails closed.
EOF

/bin/cat > "$BUNDLE_DIR/14_REPLAY_AND_OBSERVER.md" <<'EOF'
# Replay and Observer

Schema-34 replay preserves historical origin and current damage without
physical duplication or action replay. Observer schema 11 exposes the evolved
asset and current holder read-only. It creates no authority and
`observerMutationCount=0`.
EOF

/bin/cat > "$BUNDLE_DIR/15_CONSERVATION.md" <<'EOF'
# Conservation

Final live counters are `physicalLoss=0`, `physicalDuplication=0`,
`syntheticMaterial=0`, `duplicateProductionReceipts=0`,
`duplicateBarterReceipts=0`, `duplicateReservations=0` and
`observerMutationCount=0`. Each real broken-stone output enters custody through
the published acquisition path. Durability evolution is identity evolution,
not material creation.
EOF

/bin/cat > "$BUNDLE_DIR/16_FOCUSED_TESTS.md" <<'EOF'
# Focused tests

The Blocker 02 suite passes 33/33. It covers two legitimate durability
evolutions; barter discovery/settlement; CIV-36 and CIV-37 provenance
consumers; wrong item, quantity, holder and fingerprint; forged or foreign
origin; disallowed continuity; compaction/restart/corruption; replay, Observer
and conservation. Raw output is `raw/focused-blocker-02.log`.
EOF

/bin/cat > "$BUNDLE_DIR/17_REGRESSIONS.md" <<'EOF'
# Regressions

Owning selectors pass 301/301: production 36, barter 54, contracts 30, markets
31, material rights 23, candidate physical atomicity 3, checkpoint/replay 49,
persistence reconciliation 19, Observer 20 and autonomous civilization 36.
Blocker 01 passes 27/27 plus its dedicated live proof. The repository gate
passes 35/35 with 3983/3983 assertions. Goldens were not regenerated.
EOF

/bin/cat > "$BUNDLE_DIR/18_LIVE_PROOF.md" <<'EOF'
# Live proof

Two fresh processes use a disposable World and double-gated evaluation-only
routing. Process 1 normally produces damage 0, barters to `agent_1`, uses the
same tool to damage 1 and checkpoints. Process 2 restores exactly, uses it to
damage 2, performs normal discovery and physical reverse settlement, then
checkpoints and cleans up. Eight captures were individually inspected. Both
processes report zero expected and unexpected runtime errors.
EOF

/bin/cat > "$BUNDLE_DIR/19_LIMITATIONS_AND_NON_CLAIMS.md" <<'EOF'
# Limitations and non-claims

- This correction does not acquire Gate E or turn Evaluation 02 into PASS.
- It does not start Evaluation 03 or CIV-38.
- It does not define continuity after tool destruction or item-key replacement.
- It does not make provenance a current custody or disposition authority.
- It changes neither checkpoint/replay schema 34 nor Observer schema 11.
- It is not pushed, published or remotely verified.
EOF

git diff --binary "$BASELINE" "$HEAD_COMMIT" > "$BUNDLE_DIR/PATCH.diff"

/bin/cat > "$BUNDLE_DIR/REPORT.json" <<EOF
{
  "status": "IMPLEMENTED_LOCAL_REVIEW_CANDIDATE",
  "baseline": "$BASELINE",
  "branch": "$BRANCH",
  "head": "$HEAD_COMMIT",
  "evaluation02": {
    "evidenceHead": "$EVALUATION_HEAD",
    "ancestor": false,
    "verdict": "FAIL — HISTORICAL IMMUTABLE EVIDENCE",
    "bundleSHA256": "$EVALUATION_SHA"
  },
  "identity": {
    "assetID": "barter-asset:agent_0:stone-pickaxe",
    "productionOperationID": "barter-production:barter:agent_0:produce-pickaxe",
    "origin": {"itemKey": "stone_pickaxe", "damage": 0, "quantity": 1},
    "currentAfterFirstUse": {"itemKey": "stone_pickaxe", "damage": 1, "quantity": 1, "holder": "agent_1"},
    "currentAfterSecondUse": {"itemKey": "stone_pickaxe", "damage": 2, "quantity": 1},
    "originCurrentExactEquality": false,
    "permitsCurrentIdentity": true,
    "originRewriteCount": 0,
    "boundProductionOperationCount": 1
  },
  "live": {
    "freshProcesses": 2,
    "normalBarterDiscoveryAfterEvolution": true,
    "normalBarterSettlementAfterEvolution": true,
    "secondEvolution": true,
    "staleCurrentAuthorityRefused": true,
    "currentAuthorityRetrySucceeded": true,
    "capturesInspected": 8,
    "expectedRuntimeErrors": 0,
    "unexpectedRuntimeErrors": 0,
    "cleanup": "exact disposable cells; three probes removed per process"
  },
  "counters": {
    "physicalLoss": 0,
    "physicalDuplication": 0,
    "syntheticMaterial": 0,
    "duplicateProductionReceipts": 0,
    "duplicateBarterReceipts": 0,
    "duplicateReservations": 0,
    "observerMutationCount": 0,
    "currencyAuthority": 0
  },
  "schemas": {"checkpoint": 34, "replay": 34, "observer": 11},
  "validation": {
    "focusedBlocker02": "33/33",
    "owningRegressions": "301/301",
    "focusedBlocker01": "27/27",
    "repositoryGate": "35/35",
    "repositoryAssertions": "3983/3983",
    "goldensRegenerated": false
  },
  "program": {
    "gateE": "PLANNED — NOT ACQUIRED",
    "evaluation03": "NOT_STARTED",
    "civ38": "OPTIONAL — NOT STARTED",
    "push": "NOT_ATTEMPTED"
  }
}
EOF

python3 -m json.tool "$BUNDLE_DIR/REPORT.json" >/dev/null

(
    cd "$BUNDLE_DIR"
    /usr/bin/find . -type f ! -name CHECKSUMS.sha256 -print0 \
        | LC_ALL=C /usr/bin/sort -z \
        | /usr/bin/xargs -0 /usr/bin/shasum -a 256 > CHECKSUMS.sha256
    /usr/bin/shasum -a 256 -c CHECKSUMS.sha256 >/dev/null
)

CHECKSUM_COUNT=$(/usr/bin/wc -l < "$BUNDLE_DIR/CHECKSUMS.sha256" | /usr/bin/tr -d ' ')
(
    cd "$OUTPUT_PARENT"
    /usr/bin/zip -qry "$ZIP_PATH" "$BUNDLE_NAME"
)
/usr/bin/unzip -tq "$ZIP_PATH" >/dev/null
ZIP_SHA=$(/usr/bin/shasum -a 256 "$ZIP_PATH" | /usr/bin/awk '{print $1}')

printf 'Review ZIP: %s\n' "$ZIP_PATH"
printf 'SHA-256: %s\n' "$ZIP_SHA"
printf 'Internal checksums: %s/%s PASS\n' "$CHECKSUM_COUNT" "$CHECKSUM_COUNT"
printf 'REPORT.json: PASS\n'
printf 'unzip -t: PASS\n'
