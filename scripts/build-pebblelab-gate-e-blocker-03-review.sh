#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
BASELINE=bfb721d7f49f8af567c86580cdf4c106da977a25
PRODUCT_COMMIT=301dfd58aacd3aa0af653fa460ad38484df1d762
EVALUATION_01_HEAD=e75ab82981169baf1cdc67d9454e6d569e989167
EVALUATION_02_HEAD=2f95826f474c9f2a366f4b06df90a8643beb7a98
EVALUATION_03_HEAD=56af9648da0155cfba25588320d2070d211a1cd7
EVALUATION_03_SHA=c3e203e507ff8fd28781b9a067317493fd348e839e6e0b8386d95d18251af883
BRANCH=codex/gate-e-blocker-03-terminal-market-reservation-authority
LIVE_DIR=${PEBBLELAB_BLOCKER03_LIVE_DIR:-/var/folders/23/t4l5dv055dl3x1zqylcpl9wc0000gn/T/PebbleLab-live.5k4M7m}
BLOCKER01_LIVE_DIR=${PEBBLELAB_BLOCKER01_LIVE_DIR:-/tmp/pebblelab-gate-e-blocker-01.GjXmAX}
BLOCKER02_LIVE_DIR=${PEBBLELAB_BLOCKER02_LIVE_DIR:-/tmp/pebblelab-gate-e-blocker-02.lbs212}
VALIDATION_DIR=${PEBBLELAB_BLOCKER03_VALIDATION_DIR:-/tmp/PebbleLab-Gate-E-Blocker-03-Evidence.HVLeee}
OUTPUT_PARENT=${PEBBLELAB_BLOCKER03_REVIEW_PARENT:-/tmp}

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

cd "$ROOT_DIR"
[ "$(git rev-parse --show-toplevel)" = "$ROOT_DIR" ] \
    || fail 'unexpected repository root'
[ "$(git branch --show-current)" = "$BRANCH" ] \
    || fail 'unexpected branch'
[ "$(git rev-parse origin/lab/pebblelab-v1)" = "$BASELINE" ] \
    || fail 'canonical remote no longer matches the required baseline'
[ "$(git merge-base HEAD "$BASELINE")" = "$BASELINE" ] \
    || fail 'candidate is not rooted at the exact published baseline'
[ "$(git rev-parse "$PRODUCT_COMMIT")" = "$PRODUCT_COMMIT" ] \
    || fail 'product correction commit is unavailable'
git merge-base --is-ancestor "$PRODUCT_COMMIT" HEAD \
    || fail 'candidate does not contain the product correction commit'
[ "$(git rev-parse codex/gate-e-evaluation-03)" = "$EVALUATION_03_HEAD" ] \
    || fail 'Evaluation 03 branch was changed'
for evidence_head in \
    "$EVALUATION_01_HEAD" "$EVALUATION_02_HEAD" "$EVALUATION_03_HEAD"; do
    if git merge-base --is-ancestor "$evidence_head" HEAD; then
        fail "historical evaluation evidence entered correction ancestry: $evidence_head"
    fi
done
[ -z "$(git status --short)" ] || fail 'worktree must be clean'

FOCUSED_LOG="$VALIDATION_DIR/blocker-03-focused.log"
BLOCKER01_FOCUSED_LOG="$VALIDATION_DIR/gate-e-blocker-01-focused.log"
BLOCKER02_FOCUSED_LOG="$VALIDATION_DIR/gate-e-blocker-02-focused.log"
GATE_LOG="$VALIDATION_DIR/repository-gate.log"
LIVE_DRIVER="$VALIDATION_DIR/blocker-03-live-driver.log"
PHASE_1="$LIVE_DIR/market-phase1.log"
PHASE_2="$LIVE_DIR/market-phase2.log"
PHASE_3="$LIVE_DIR/market-phase3.log"
PHASE_4="$LIVE_DIR/market-phase4.log"

require_text '25 passed, 0 failed' "$FOCUSED_LOG"
require_text '27 passed, 0 failed' "$BLOCKER01_FOCUSED_LOG"
require_text '33 passed, 0 failed' "$BLOCKER02_FOCUSED_LOG"
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
    require_text "$count passed, 0 failed" "$VALIDATION_DIR/$name.log"
done
require_text '3983 passed, 0 failed' "$GATE_LOG"
require_text 'PASS: all 35 PebbleLab verification steps succeeded.' "$GATE_LOG"
require_text 'Goldens: read-only; PEBBLE_REGOLD is refused.' "$GATE_LOG"
require_text 'PASS: Gate E Blocker 01 exact produced-asset provenance live proof.' \
    "$VALIDATION_DIR/blocker-01-live-driver.log"
require_text 'Fresh processes: 2' "$VALIDATION_DIR/blocker-01-live-driver.log"
require_text 'PASS: Gate E Blocker 02 evolved current identity live proof.' \
    "$VALIDATION_DIR/blocker-02-live-driver.log"
require_text 'Fresh processes: 2' "$VALIDATION_DIR/blocker-02-live-driver.log"
require_text 'PASS: Blocker 03 active reservation, terminal-history release, ordinary post-restart re-entry, conservation, and cleanup verified.' \
    "$LIVE_DRIVER"

require_text 'liveAccepted=1' "$PHASE_2"
require_text 'targetReserved=1' "$PHASE_2"
require_text 'terminalAccepted=1' "$PHASE_2"
require_text 'terminalOnlyReleased=1' "$PHASE_2"
require_text 'candidateMidFaultInjected=1 candidatePostMutationFaultInjected=1' "$PHASE_2"
require_text 'checkpoint saved name=market-traded-v34' "$PHASE_2"
require_text 'checkpoint loaded name=market-traded-v34' "$PHASE_3"
require_text 'terminalAccepted=2' "$PHASE_3"
require_text 'priceRows=2 trades=2' "$PHASE_3"
require_text 'checkpoint saved name=market-final-v34' "$PHASE_3"
require_text 'checkpoint loaded name=market-final-v34' "$PHASE_4"
require_text 'currentHolder=agent:agent_2 currentQuantity=2' "$PHASE_4"
require_text 'asset=market-asset:9-consideration-bread2 normalDepositDecision=1 depositPhysicalMutation=1 ordinaryAutonomousSelection=1 reservationAuthorityBefore=0' "$PHASE_4"
require_text 'checkpoint saved name=market-blocker03-reentered-v34' "$PHASE_4"
require_text 'physicalLoss=0 physicalDuplication=0 syntheticTradeMaterial=0 duplicateReservations=0 duplicateDeposits=0 observerMutationCount=0' "$PHASE_4"
require_text 'mutation=none tickStable=1 causalStable=1 digestStable=1' "$PHASE_4"
require_text 'Restored disposable market air cell after restart; completed economic custody was preserved.' "$PHASE_4"
require_text 'runtimeErrors=0' "$PHASE_4"
require_text 'probesRemoved=3' "$PHASE_4"

HEAD_COMMIT=$(git rev-parse HEAD)
HEAD_SHORT=$(git rev-parse --short=12 HEAD)
BUNDLE_NAME="PebbleLab-Gate-E-Blocker-03-Review-$HEAD_SHORT"
BUNDLE_DIR="$OUTPUT_PARENT/$BUNDLE_NAME"
ZIP_PATH="$OUTPUT_PARENT/$BUNDLE_NAME.zip"
[ ! -e "$BUNDLE_DIR" ] || fail "bundle directory exists: $BUNDLE_DIR"
[ ! -e "$ZIP_PATH" ] || fail "bundle ZIP exists: $ZIP_PATH"

/bin/mkdir -p \
    "$BUNDLE_DIR/raw/validation" \
    "$BUNDLE_DIR/raw/live/blocker-03" \
    "$BUNDLE_DIR/raw/live/blocker-01" \
    "$BUNDLE_DIR/raw/live/blocker-02" \
    "$BUNDLE_DIR/captures/blocker-03" \
    "$BUNDLE_DIR/captures/blocker-01" \
    "$BUNDLE_DIR/captures/blocker-02" \
    "$BUNDLE_DIR/checkpoints/blocker-03" \
    "$BUNDLE_DIR/checkpoints/blocker-01" \
    "$BUNDLE_DIR/checkpoints/blocker-02" \
    "$BUNDLE_DIR/product"

for log in \
    blocker-03-focused gate-e-blocker-01-focused gate-e-blocker-02-focused \
    production barter contracts markets material-rights \
    candidate-physical-atomicity checkpoint-replay persistence-reconciliation \
    observer autonomous-civilization repository-gate \
    blocker-03-live-dry-run blocker-03-live-driver \
    blocker-01-live-dry-run blocker-01-live-driver \
    blocker-02-live-dry-run blocker-02-live-driver; do
    copy_required "$VALIDATION_DIR/$log.log" \
        "$BUNDLE_DIR/raw/validation/$log.log"
done

for phase in market-phase1 market-phase2 market-phase3 market-phase4; do
    copy_required "$LIVE_DIR/$phase.log" \
        "$BUNDLE_DIR/raw/live/blocker-03/$phase.log"
done
copy_required "$BLOCKER01_LIVE_DIR/blocker-01-process-1.log" \
    "$BUNDLE_DIR/raw/live/blocker-01/process-1.log"
copy_required "$BLOCKER01_LIVE_DIR/blocker-01-process-2.log" \
    "$BUNDLE_DIR/raw/live/blocker-01/process-2.log"
copy_required "$BLOCKER02_LIVE_DIR/blocker-02-process-1.log" \
    "$BUNDLE_DIR/raw/live/blocker-02/process-1.log"
copy_required "$BLOCKER02_LIVE_DIR/blocker-02-process-2.log" \
    "$BUNDLE_DIR/raw/live/blocker-02/process-2.log"

for capture in "$LIVE_DIR"/captures/*.png; do
    copy_required "$capture" "$BUNDLE_DIR/captures/blocker-03/$(basename "$capture")"
done
for capture in "$BLOCKER01_LIVE_DIR"/captures/*.png; do
    copy_required "$capture" "$BUNDLE_DIR/captures/blocker-01/$(basename "$capture")"
done
for capture in "$BLOCKER02_LIVE_DIR"/captures/*.png; do
    copy_required "$capture" "$BUNDLE_DIR/captures/blocker-02/$(basename "$capture")"
done
[ "$(find "$BUNDLE_DIR/captures/blocker-03" -type f | wc -l | tr -d ' ')" = 16 ] \
    || fail 'expected 16 Blocker 03 captures'
[ "$(find "$BUNDLE_DIR/captures/blocker-01" -type f | wc -l | tr -d ' ')" = 9 ] \
    || fail 'expected 9 Blocker 01 captures'
[ "$(find "$BUNDLE_DIR/captures/blocker-02" -type f | wc -l | tr -d ' ')" = 8 ] \
    || fail 'expected 8 Blocker 02 captures'

BLOCKER03_PERSISTENCE="$LIVE_DIR/home/Library/Application Support/Pebble/PebbleLabAgents"
for checkpoint in \
    market-open-v34 market-traded-v34 market-final-v34 \
    market-blocker03-reentered-v34; do
    copy_checkpoint "$BLOCKER03_PERSISTENCE" "$checkpoint" \
        "$BUNDLE_DIR/checkpoints/blocker-03"
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

copy_required docs/pebblelab/GATE_E_BLOCKER_03_TERMINAL_MARKET_RESERVATION_AUTHORITY.md \
    "$BUNDLE_DIR/product/GATE_E_BLOCKER_03_TERMINAL_MARKET_RESERVATION_AUTHORITY.md"
copy_required scripts/build-pebblelab-gate-e-blocker-03-review.sh \
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
    printf 'worktree=clean\n'
    printf 'push=NOT_ATTEMPTED\n'
} > "$BUNDLE_DIR/GIT_STATE.txt"

/bin/cat > "$BUNDLE_DIR/00_README_FIRST.md" <<'EOF'
# Read this first

Verdict: `V4-GATE-E-v1 Blocker 03` is an
`IMPLEMENTED_LOCAL_REVIEW_CANDIDATE — NOT PUBLISHED`.

Evaluation 03 remains immutable historical FAIL evidence. Gate E remains
planned and not acquired; Evaluation 04 and CIV-38 are not started. Review
`GIT_STATE.txt`, the product record, `PATCH.diff`, `REPORT.json`, focused and
owning logs, four-process live traces, checkpoints and captures.

`CHECKSUMS.sha256` covers every other internal file. The 16 Blocker 03
captures were manually inspected. The archive also includes the fresh Blocker
01 and Blocker 02 focused/live regressions requested for this correction.
EOF

/bin/cat > "$BUNDLE_DIR/01_EXECUTIVE_REPORT.md" <<EOF
# Blocker 03 executive report

Affected baseline: \`$BASELINE\`

Candidate HEAD: \`$HEAD_COMMIT\`

Evaluation 03 evidence HEAD: \`$EVALUATION_03_HEAD\` (not an ancestor)

The defect let an accepted proposal remain current reservation authority after
its listing and deposit became terminal. The correction derives reservation
from the coherent live triad: proposed/open/listed or
accepted/reserved/reserved. Accepted/completed/sold remains exact history but
does not reserve current matter.

Focused Blocker 03 checks pass 25/25; owning checks pass 301/301; Blocker 01
and 02 focused checks pass 27/27 and 33/33; the canonical gate passes 35/35
steps and 3983/3983 assertions. Fresh Blocker 01 and 02 two-process live proofs
pass. The four-process Blocker 03 campaign has 16 inspected captures and proves
strict active reservation, terminal release, schema-34 restart, ordinary
post-restart selection/deposit/listing/withdrawal, schema-11 read-only
observation, exact cleanup and zero unexpected duplication or loss.

This archive does not claim publication or Gate E acquisition.
EOF

/bin/cat > "$BUNDLE_DIR/02_AUTHORITY_AND_PROOF.md" <<'EOF'
# Authority and proof map

- Current reservation authority requires a coherent live proposal, listing and
  deposit state; a proposal status alone is insufficient.
- Exact current Material Rights and physical observations remain mandatory.
- Active accepted/reserved/reserved state blocks incompatible reuse.
- Terminal accepted/completed/sold state keeps trade and price provenance but
  releases reservation.
- Restart and replay retain that distinction without reexecuting World effects.
- Compaction cannot recreate terminal authority or discard live authority.
- Observer schema 11 remains derived and read-only.
- Checkpoint schema 34 is unchanged.
EOF

{
    printf '# Capture inspection\n\n'
    printf 'Blocker 03 captures: 16/16 manually inspected.\n\n```text\n'
    for capture in "$BUNDLE_DIR"/captures/blocker-03/*.png; do
        /usr/bin/file "$capture"
    done
    printf '```\n\nBlocker 01 captures included: 9. Blocker 02 captures included: 8.\n'
} > "$BUNDLE_DIR/CAPTURE_INSPECTION.md"

/bin/cat > "$BUNDLE_DIR/REPORT.json" <<EOF
{
  "task": "V4-GATE-E-v1 Blocker 03",
  "status": "IMPLEMENTED_LOCAL_REVIEW_CANDIDATE — NOT PUBLISHED",
  "affectedBaseline": "$BASELINE",
  "branch": "$BRANCH",
  "productCommit": "$PRODUCT_COMMIT",
  "candidateHead": "$HEAD_COMMIT",
  "evaluation03": {
    "evidenceHead": "$EVALUATION_03_HEAD",
    "reviewZipSHA256": "$EVALUATION_03_SHA",
    "status": "FAIL — HISTORICAL IMMUTABLE EVIDENCE",
    "ancestorOfCandidate": false
  },
  "gateE": "PLANNED — NOT ACQUIRED",
  "evaluation04": "NOT_STARTED",
  "civ38": "OPTIONAL — NOT STARTED",
  "schemas": {"checkpoint": 34, "replay": 34, "observer": 11},
  "tests": {
    "focusedBlocker03": {"passed": 25, "failed": 0},
    "owning": {"passed": 301, "failed": 0},
    "blocker01Focused": {"passed": 27, "failed": 0},
    "blocker02Focused": {"passed": 33, "failed": 0},
    "repositoryGate": {"stepsPassed": 35, "stepsFailed": 0, "assertionsPassed": 3983, "assertionsFailed": 0}
  },
  "live": {
    "blocker03FreshProcesses": 4,
    "blocker03InspectedCaptures": 16,
    "blocker01FreshProcesses": 2,
    "blocker01Captures": 9,
    "blocker02FreshProcesses": 2,
    "blocker02Captures": 8
  },
  "counters": {
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
    find . -type f ! -name CHECKSUMS.sha256 -print \
        | LC_ALL=C sort \
        | while IFS= read -r path; do
            shasum -a 256 "$path"
        done > CHECKSUMS.sha256
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

VALIDATION_EXTRACT=$(mktemp -d "${TMPDIR:-/tmp}/PebbleLab-B03-Review-Validate.XXXXXX")
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

