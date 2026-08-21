#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
BASELINE=e8bc2fc8add491c324f15478fcd1b82d77566d57
PRODUCT_COMMIT=0318133fe95949c441974871f2581f38c43c6128
EVALUATION_01_HEAD=e75ab82981169baf1cdc67d9454e6d569e989167
EVALUATION_02_HEAD=2f95826f474c9f2a366f4b06df90a8643beb7a98
EVALUATION_03_HEAD=56af9648da0155cfba25588320d2070d211a1cd7
EVALUATION_04_HEAD=07ded1e583b62137b5e8b6cc32d8a61ead73cc53
BRANCH=codex/gate-e-blocker-04-composed-asset-commitment-authority
LIVE_DIR=${PEBBLELAB_BLOCKER04_LIVE_DIR:-/var/folders/23/t4l5dv055dl3x1zqylcpl9wc0000gn/T/PebbleLab-live.37FmBh}
BLOCKER01_LIVE_DIR=${PEBBLELAB_BLOCKER01_LIVE_DIR:-/tmp/pebblelab-gate-e-blocker-01.XJ82FJ}
BLOCKER02_LIVE_DIR=${PEBBLELAB_BLOCKER02_LIVE_DIR:-/tmp/pebblelab-gate-e-blocker-02.gcTBKE}
BLOCKER03_LIVE_DIR=${PEBBLELAB_BLOCKER03_LIVE_DIR:-/var/folders/23/t4l5dv055dl3x1zqylcpl9wc0000gn/T/PebbleLab-live.WS1fER}
VALIDATION_DIR=${PEBBLELAB_BLOCKER04_VALIDATION_DIR:-/tmp/PebbleLab-Gate-E-Blocker-04-Validation.JRGJxK}
OUTPUT_PARENT=${PEBBLELAB_BLOCKER04_REVIEW_PARENT:-/tmp}

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

copy_checkpoint() {
    persistence_root=$1
    checkpoint_name=$2
    destination_root=$3
    checkpoint_dir=$(/usr/bin/find "$persistence_root" -type d \
        -path "*/checkpoints/$checkpoint_name" -print -quit)
    [ -n "$checkpoint_dir" ] || fail "checkpoint missing: $checkpoint_name"
    /bin/mkdir -p "$destination_root/$checkpoint_name"
    copy_required "$checkpoint_dir/manifest.json" \
        "$destination_root/$checkpoint_name/manifest.json"
    copy_required "$checkpoint_dir/session.json" \
        "$destination_root/$checkpoint_name/session.json"
}

copy_captures() {
    source_dir=$1
    destination_dir=$2
    expected=$3
    for capture in "$source_dir"/*.png; do
        copy_required "$capture" "$destination_dir/$(basename "$capture")"
    done
    actual=$(/usr/bin/find "$destination_dir" -type f | /usr/bin/wc -l | tr -d ' ')
    [ "$actual" = "$expected" ] \
        || fail "expected $expected captures in $destination_dir, found $actual"
}

cd "$ROOT_DIR"
[ "$(git rev-parse --show-toplevel)" = "$ROOT_DIR" ] \
    || fail 'unexpected repository root'
[ "$(git branch --show-current)" = "$BRANCH" ] || fail 'unexpected branch'
[ "$(git rev-parse origin/lab/pebblelab-v1)" = "$BASELINE" ] \
    || fail 'canonical remote no longer matches the required baseline'
[ "$(git merge-base HEAD "$BASELINE")" = "$BASELINE" ] \
    || fail 'candidate is not rooted at the exact published baseline'
[ "$(git rev-parse "$PRODUCT_COMMIT")" = "$PRODUCT_COMMIT" ] \
    || fail 'product correction commit is unavailable'
[ "$(git rev-parse HEAD^)" = "$PRODUCT_COMMIT" ] \
    || fail 'candidate must contain one documentation commit after the product commit'
[ "$(git rev-parse codex/gate-e-evaluation-04)" = "$EVALUATION_04_HEAD" ] \
    || fail 'Evaluation 04 branch was changed'
for evidence_head in \
    "$EVALUATION_01_HEAD" "$EVALUATION_02_HEAD" \
    "$EVALUATION_03_HEAD" "$EVALUATION_04_HEAD"; do
    if git merge-base --is-ancestor "$evidence_head" HEAD; then
        fail "historical evaluation evidence entered correction ancestry: $evidence_head"
    fi
done
[ -z "$(git status --short)" ] || fail 'worktree must be clean'

FOCUSED_LOG="$VALIDATION_DIR/final-gate-e-blocker-04.log"
GATE_LOG="$VALIDATION_DIR/final-repository-verification.log"
LIVE_DRIVER="$VALIDATION_DIR/final6-blocker-04-live-driver.log"
PHASE_1="$LIVE_DIR/market-phase1.log"
PHASE_2="$LIVE_DIR/market-phase2.log"
PHASE_3="$LIVE_DIR/market-phase3.log"
PHASE_4="$LIVE_DIR/market-phase4.log"

require_text '28 passed, 0 failed' "$FOCUSED_LOG"
for result in \
    'production:36' 'barter:56' 'contracts:32' 'markets:31' \
    'material-rights:23' 'candidate-physical-atomicity:3' \
    'checkpoint-replay:49' 'persistence-reconciliation:19' \
    'observer:20' 'autonomous-civilization:36'; do
    name=${result%%:*}
    count=${result##*:}
    require_text "$count passed, 0 failed" "$VALIDATION_DIR/final-$name.log"
done
for result in '01:27' '02:33' '03:25'; do
    blocker=${result%%:*}
    count=${result##*:}
    require_text "$count passed, 0 failed" \
        "$VALIDATION_DIR/final-gate-e-blocker-$blocker.log"
done
require_text '4015 passed, 0 failed' "$GATE_LOG"
require_text 'PASS: all 35 PebbleLab verification steps succeeded.' "$GATE_LOG"
require_text 'Goldens: read-only; PEBBLE_REGOLD is refused.' "$GATE_LOG"
require_text 'PASS: Gate E Blocker 01 exact produced-asset provenance live proof.' \
    "$VALIDATION_DIR/final-gate-e-blocker-01-live-driver.log"
require_text 'PASS: Gate E Blocker 02 evolved current identity live proof.' \
    "$VALIDATION_DIR/final-gate-e-blocker-02-live-driver.log"
require_text 'PASS: Blocker 03 active reservation, terminal-history release, ordinary post-restart re-entry, conservation, and cleanup verified.' \
    "$VALIDATION_DIR/final-gate-e-blocker-03-live-driver.log"
require_text 'PASS: Blocker 04 composed exclusion, same-operation continuation, terminal release, restart, conservation, and cleanup verified.' \
    "$LIVE_DRIVER"

require_text 'contractLive=1 barterLive=0 marketLive=0' "$PHASE_1"
require_text 'observedMarketOpportunities=1 ordinarySelectedTarget=0' "$PHASE_1"
require_text 'checkpoint saved name=gate-e-blocker04-live-contract-v34' "$PHASE_1"
require_text 'checkpoint loaded name=gate-e-blocker04-live-contract-v34' "$PHASE_2"
require_text 'contractAdvanced=1 barterPending=0 barterCompleted=0' "$PHASE_2"
require_text 'checkpoint saved name=gate-e-blocker04-released-v34' "$PHASE_2"
require_text 'checkpoint loaded name=gate-e-blocker04-released-v34' "$PHASE_3"
require_text 'contractLive=0 barterLive=1 marketLive=0' "$PHASE_3"
require_text 'barterPending=0 barterCompleted=1' "$PHASE_3"
require_text 'checkpoint saved name=gate-e-blocker04-barter-completed-v34' "$PHASE_3"
require_text 'checkpoint loaded name=gate-e-blocker04-barter-completed-v34' "$PHASE_4"
require_text 'normalDepositDecision=1 depositPhysicalMutation=1 ordinaryAutonomousSelection=1 reservationAuthorityBefore=0' "$PHASE_4"
require_text 'crossSystemDuplicateLiveCommitments=0' "$PHASE_4"
require_text 'physicalLoss=0 physicalDuplication=0 syntheticMaterial=0' "$PHASE_4"
require_text 'mutation=none tickStable=1 causalStable=1 digestStable=1' "$PHASE_4"
require_text 'Restored disposable market air cell after restart; completed economic custody was preserved.' "$PHASE_4"
require_text 'runtimeErrors=0' "$PHASE_4"
require_text 'probesRemoved=3' "$PHASE_4"

HEAD_COMMIT=$(git rev-parse HEAD)
HEAD_SHORT=$(git rev-parse --short=12 HEAD)
BUNDLE_NAME="PebbleLab-Gate-E-Blocker-04-Review-$HEAD_SHORT"
BUNDLE_DIR="$OUTPUT_PARENT/$BUNDLE_NAME"
ZIP_PATH="$OUTPUT_PARENT/$BUNDLE_NAME.zip"
[ ! -e "$BUNDLE_DIR" ] || fail "bundle directory exists: $BUNDLE_DIR"
[ ! -e "$ZIP_PATH" ] || fail "bundle ZIP exists: $ZIP_PATH"

/bin/mkdir -p \
    "$BUNDLE_DIR/raw/validation" \
    "$BUNDLE_DIR/raw/live/blocker-04" \
    "$BUNDLE_DIR/raw/live/blocker-01" \
    "$BUNDLE_DIR/raw/live/blocker-02" \
    "$BUNDLE_DIR/raw/live/blocker-03" \
    "$BUNDLE_DIR/captures/blocker-04" \
    "$BUNDLE_DIR/captures/blocker-01" \
    "$BUNDLE_DIR/captures/blocker-02" \
    "$BUNDLE_DIR/captures/blocker-03" \
    "$BUNDLE_DIR/checkpoints/blocker-04" \
    "$BUNDLE_DIR/checkpoints/blocker-01" \
    "$BUNDLE_DIR/checkpoints/blocker-02" \
    "$BUNDLE_DIR/checkpoints/blocker-03" \
    "$BUNDLE_DIR/product"

for log in \
    final-gate-e-blocker-04 final-gate-e-blocker-01 \
    final-gate-e-blocker-02 final-gate-e-blocker-03 \
    final-production final-barter final-contracts final-markets \
    final-material-rights final-candidate-physical-atomicity \
    final-checkpoint-replay final-persistence-reconciliation \
    final-observer final-autonomous-civilization \
    final-release-pebsmoke-build final-release-pebsmoke-rebuild-2 \
    final-release-pebble-build final-release-pebble-rebuild \
    final-repository-verification final6-blocker-04-live-dry-run \
    final6-blocker-04-live-driver \
    final-gate-e-blocker-01-live-dry-run final-gate-e-blocker-01-live-driver \
    final-gate-e-blocker-02-live-dry-run final-gate-e-blocker-02-live-driver \
    final-gate-e-blocker-03-live-dry-run final-gate-e-blocker-03-live-driver; do
    copy_required "$VALIDATION_DIR/$log.log" "$BUNDLE_DIR/raw/validation/$log.log"
done

for phase in market-phase1 market-phase2 market-phase3 market-phase4; do
    copy_required "$LIVE_DIR/$phase.log" "$BUNDLE_DIR/raw/live/blocker-04/$phase.log"
    copy_required "$BLOCKER03_LIVE_DIR/$phase.log" "$BUNDLE_DIR/raw/live/blocker-03/$phase.log"
done
for process in 1 2; do
    copy_required "$BLOCKER01_LIVE_DIR/blocker-01-process-$process.log" \
        "$BUNDLE_DIR/raw/live/blocker-01/process-$process.log"
    copy_required "$BLOCKER02_LIVE_DIR/blocker-02-process-$process.log" \
        "$BUNDLE_DIR/raw/live/blocker-02/process-$process.log"
done

copy_captures "$LIVE_DIR/captures" "$BUNDLE_DIR/captures/blocker-04" 13
copy_captures "$BLOCKER01_LIVE_DIR/captures" "$BUNDLE_DIR/captures/blocker-01" 9
copy_captures "$BLOCKER02_LIVE_DIR/captures" "$BUNDLE_DIR/captures/blocker-02" 8
copy_captures "$BLOCKER03_LIVE_DIR/captures" "$BUNDLE_DIR/captures/blocker-03" 16

BLOCKER04_PERSISTENCE="$LIVE_DIR/home/Library/Application Support/Pebble/PebbleLabAgents"
for checkpoint in gate-e-blocker04-live-contract-v34 \
    gate-e-blocker04-released-v34 gate-e-blocker04-barter-completed-v34; do
    copy_checkpoint "$BLOCKER04_PERSISTENCE" "$checkpoint" \
        "$BUNDLE_DIR/checkpoints/blocker-04"
done
BLOCKER01_PERSISTENCE="$BLOCKER01_LIVE_DIR/home/Library/Application Support/Pebble/PebbleLabAgents"
for checkpoint in gate-e-blocker-01-open-v33 gate-e-blocker-01-fulfilled-v33; do
    copy_checkpoint "$BLOCKER01_PERSISTENCE" "$checkpoint" \
        "$BUNDLE_DIR/checkpoints/blocker-01"
done
BLOCKER02_PERSISTENCE="$BLOCKER02_LIVE_DIR/home/Library/Application Support/Pebble/PebbleLabAgents"
for checkpoint in gate-e-blocker-02-damage1-v34 gate-e-blocker-02-damage2-v34; do
    copy_checkpoint "$BLOCKER02_PERSISTENCE" "$checkpoint" \
        "$BUNDLE_DIR/checkpoints/blocker-02"
done
BLOCKER03_PERSISTENCE="$BLOCKER03_LIVE_DIR/home/Library/Application Support/Pebble/PebbleLabAgents"
for checkpoint in market-open-v34 market-traded-v34 market-final-v34 \
    market-blocker03-reentered-v34; do
    copy_checkpoint "$BLOCKER03_PERSISTENCE" "$checkpoint" \
        "$BUNDLE_DIR/checkpoints/blocker-03"
done

copy_required docs/pebblelab/GATE_E_BLOCKER_04_COMPOSED_ASSET_COMMITMENT_AUTHORITY.md \
    "$BUNDLE_DIR/product/GATE_E_BLOCKER_04_COMPOSED_ASSET_COMMITMENT_AUTHORITY.md"
copy_required scripts/build-pebblelab-gate-e-blocker-04-review.sh \
    "$BUNDLE_DIR/product/build-review-bundle.sh"

git diff --binary "$BASELINE"..HEAD > "$BUNDLE_DIR/PATCH.diff"
[ -s "$BUNDLE_DIR/PATCH.diff" ] || fail 'baseline-to-candidate patch is empty'
git log --oneline --decorate "$BASELINE"..HEAD > "$BUNDLE_DIR/GIT_LOG.txt"
{
    printf 'repository=Ness-Now/pebble\n'
    printf 'canonical_branch=lab/pebblelab-v1\n'
    printf 'canonical_remote_head=%s\n' "$(git rev-parse origin/lab/pebblelab-v1)"
    printf 'affected_baseline=%s\n' "$BASELINE"
    printf 'branch=%s\n' "$BRANCH"
    printf 'product_commit=%s\n' "$PRODUCT_COMMIT"
    printf 'candidate_head=%s\n' "$HEAD_COMMIT"
    printf 'merge_base=%s\n' "$(git merge-base HEAD "$BASELINE")"
    printf 'evaluation_01_evidence_ancestor=NO\n'
    printf 'evaluation_02_evidence_ancestor=NO\n'
    printf 'evaluation_03_evidence_ancestor=NO\n'
    printf 'evaluation_04_evidence_ancestor=NO\n'
    printf 'worktree=clean\n'
    printf 'push=NOT_ATTEMPTED\n'
} > "$BUNDLE_DIR/GIT_STATE.txt"

/bin/cat > "$BUNDLE_DIR/00_README_FIRST.md" <<'EOF'
# Read this first

Verdict: `V4-GATE-E-v1 Blocker 04` is an
`IMPLEMENTED_LOCAL_REVIEW_CANDIDATE — NOT PUBLISHED`.

Evaluation 04 remains immutable historical FAIL evidence. Gate E remains
planned and not acquired; Evaluation 05 and CIV-38 are not started. Review
`GIT_STATE.txt`, the product record, `PATCH.diff`, `REPORT.json`, focused and
owning logs, four-process live traces, checkpoints and captures.

`CHECKSUMS.sha256` covers every other internal file. All 13 Blocker 04 captures
were manually inspected. The archive also includes fresh Blocker 01, 02 and 03
focused/live regressions from the finalized correction sources.
EOF

/bin/cat > "$BUNDLE_DIR/01_EXECUTIVE_REPORT.md" <<EOF
# Blocker 04 executive report

Affected baseline: \`$BASELINE\`

Product commit: \`$PRODUCT_COMMIT\`

Candidate HEAD: \`$HEAD_COMMIT\`

Evaluation 04 evidence HEAD: \`$EVALUATION_04_HEAD\` (not an ancestor)

The defect let one exact durable asset back incompatible accepted contract and
market consideration commitments. The correction derives one deterministic
aggregate commitment projection from live barter, contract and market state,
admits only same-operation continuation, and releases terminal authority.

Focused Blocker 04 checks pass 28/28; owning checks pass 305/305; published
Blocker 01 through 03 focused checks pass 27/27, 33/33 and 25/25; the canonical
gate passes 35/35 steps and 4015/4015 assertions. The fresh four-process
Blocker 04 campaign has 13 inspected captures and proves cross-system
exclusion, restart, same-operation continuation, terminal release, ordinary
market reuse, conservation, read-only observation and exact cleanup. Fresh
inherited live regressions add eight processes and 33 captures.

This archive does not claim publication or Gate E acquisition.
EOF

/bin/cat > "$BUNDLE_DIR/02_AUTHORITY_AND_PROOF.md" <<'EOF'
# Authority and proof map

- One derived aggregate projection composes live exact-asset commitments from
  barter, contracts and markets without adding persisted lock state.
- The owning logical operation may continue; incompatible operations fail
  before physical mutation.
- Terminal records retain provenance but grant no current commitment authority.
- Exact current Material Rights and Pebble physical gateways remain mandatory.
- Verified economic receipts fulfill the exact motivating need once.
- Restart, replay and compaction reproduce live exclusion and terminal release.
- Checkpoint/replay schema 34 and Observer schema 11 are unchanged.
EOF

/bin/cat > "$BUNDLE_DIR/VALIDATION_COMMANDS.md" <<'EOF'
# Validation commands

Final validation used the release `pebsmoke` binary for selectors
`gate-e-blocker-04`, `production`, `barter`, `contracts`, `markets`,
`material-rights`, `candidate-physical-atomicity`, `checkpoint-replay`,
`persistence-reconciliation`, `observer`, `autonomous-civilization`, and Gate E
Blockers 01 through 03. The full repository command was:

```text
scripts/verify-pebblelab.sh
```

The Blocker 04 live launcher was run first with `--dry-run`, then as the gated
four-process disposable campaign. Published Blocker 01 through 03 live
launchers were likewise run from fresh isolated session roots. Exact stdout and
stderr are retained under `raw/validation` and `raw/live`.
EOF

{
    printf '# Capture inspection\n\n'
    printf 'Blocker 04 captures: 13/13 manually inspected.\n\n```text\n'
    for capture in "$BUNDLE_DIR"/captures/blocker-04/*.png; do
        /usr/bin/file "$capture"
    done
    printf '```\n\nInherited regression captures included: Blocker 01 = 9, Blocker 02 = 8, Blocker 03 = 16.\n'
} > "$BUNDLE_DIR/CAPTURE_INSPECTION.md"

/bin/cat > "$BUNDLE_DIR/REPORT.json" <<EOF
{
  "task": "V4-GATE-E-v1 Blocker 04",
  "status": "IMPLEMENTED_LOCAL_REVIEW_CANDIDATE — NOT PUBLISHED",
  "affectedBaseline": "$BASELINE",
  "branch": "$BRANCH",
  "productCommit": "$PRODUCT_COMMIT",
  "candidateHead": "$HEAD_COMMIT",
  "evaluation04": {
    "evidenceHead": "$EVALUATION_04_HEAD",
    "status": "FAIL — HISTORICAL IMMUTABLE EVIDENCE",
    "ancestorOfCandidate": false
  },
  "gateE": "PLANNED — NOT ACQUIRED",
  "evaluation05": "NOT_STARTED",
  "civ38": "OPTIONAL — NOT STARTED",
  "schemas": {"checkpoint": 34, "replay": 34, "observer": 11},
  "tests": {
    "focusedBlocker04": {"passed": 28, "failed": 0},
    "owning": {"passed": 305, "failed": 0},
    "blocker01Focused": {"passed": 27, "failed": 0},
    "blocker02Focused": {"passed": 33, "failed": 0},
    "blocker03Focused": {"passed": 25, "failed": 0},
    "repositoryGate": {"stepsPassed": 35, "stepsFailed": 0, "assertionsPassed": 4015, "assertionsFailed": 0}
  },
  "live": {
    "blocker04FreshProcesses": 4,
    "blocker04InspectedCaptures": 13,
    "auxiliaryRegressionFreshProcesses": 8,
    "auxiliaryRegressionCaptures": 33
  },
  "counters": {
    "crossSystemDuplicateLiveCommitments": 0,
    "physicalLoss": 0,
    "physicalDuplication": 0,
    "syntheticMaterial": 0,
    "duplicateDeposits": 0,
    "duplicateReservations": 0,
    "duplicateReceipts": 0,
    "duplicateSettlements": 0,
    "observerMutations": 0,
    "unexpectedRuntimeErrors": 0
  },
  "cleanup": "exact",
  "goldensRegenerated": false,
  "push": "NOT_ATTEMPTED"
}
EOF

/usr/bin/python3 -m json.tool "$BUNDLE_DIR/REPORT.json" >/dev/null \
    || fail 'REPORT.json is invalid'
if [ -n "$(find "$BUNDLE_DIR" -type l -print -quit)" ]; then
    fail 'unintended symlink in bundle source'
fi
(
    cd "$BUNDLE_DIR"
    find . -type f ! -name CHECKSUMS.sha256 -print | LC_ALL=C sort \
        | while IFS= read -r path; do shasum -a 256 "$path"; done \
        > CHECKSUMS.sha256
    shasum -a 256 -c CHECKSUMS.sha256 >/dev/null
)

INTERNAL_COUNT=$(wc -l < "$BUNDLE_DIR/CHECKSUMS.sha256" | tr -d ' ')
(
    cd "$OUTPUT_PARENT"
    /usr/bin/zip -qry "$BUNDLE_NAME.zip" "$BUNDLE_NAME"
)
/usr/bin/unzip -tq "$ZIP_PATH" >/dev/null || fail 'unzip integrity failed'
if /usr/bin/zipinfo -1 "$ZIP_PATH" \
    | /usr/bin/awk 'BEGIN { bad=0 } /^\// { bad=1 } /(^|\/)\.\.($|\/)/ { bad=1 } /\\/ { bad=1 } END { exit bad ? 0 : 1 }'; then
    fail 'unsafe archive path detected'
fi

VALIDATION_EXTRACT=$(mktemp -d "${TMPDIR:-/tmp}/PebbleLab-B04-Review-Validate.XXXXXX")
/usr/bin/unzip -q "$ZIP_PATH" -d "$VALIDATION_EXTRACT"
if [ -n "$(find "$VALIDATION_EXTRACT" -type l -print -quit)" ]; then
    fail 'symlink found after extraction'
fi
(
    cd "$VALIDATION_EXTRACT/$BUNDLE_NAME"
    shasum -a 256 -c CHECKSUMS.sha256 >/dev/null
)

ZIP_SHA=$(shasum -a 256 "$ZIP_PATH" | /usr/bin/awk '{print $1}')
printf 'Review ZIP: %s\n' "$ZIP_PATH"
printf 'Review ZIP SHA-256: %s\n' "$ZIP_SHA"
printf 'Internal checksums: %s/%s PASS\n' "$INTERNAL_COUNT" "$INTERNAL_COUNT"
printf 'Safe archive paths: PASS\n'
printf 'Symlink validation: PASS\n'
printf 'Unzip integrity: PASS\n'
printf 'Extracted checksum validation: PASS\n'
printf 'Validation extraction retained: %s\n' "$VALIDATION_EXTRACT"
