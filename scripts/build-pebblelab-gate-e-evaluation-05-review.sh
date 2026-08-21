#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
BASELINE=9d841cc28dd4a43f70aff6265ead2e25fa6f160c
BRANCH=codex/gate-e-evaluation-05
EVALUATION_01_HEAD=e75ab82981169baf1cdc67d9454e6d569e989167
EVALUATION_02_HEAD=2f95826f474c9f2a366f4b06df90a8643beb7a98
EVALUATION_03_HEAD=56af9648da0155cfba25588320d2070d211a1cd7
EVALUATION_04_HEAD=07ded1e583b62137b5e8b6cc32d8a61ead73cc53

EVIDENCE_DIR=${PEBBLELAB_E05_EVIDENCE_DIR:-/tmp/pebblelab-gate-e-evaluation-05-correction.lMNnE8}
PRODUCTION_DIR=${PEBBLELAB_E05_PRODUCTION_DIR:-/var/folders/23/t4l5dv055dl3x1zqylcpl9wc0000gn/T/PebbleLab-live.Gl7quv}
BARTER_DIR=${PEBBLELAB_E05_BARTER_DIR:-/var/folders/23/t4l5dv055dl3x1zqylcpl9wc0000gn/T/PebbleLab-live.wZnLrG}
CONTRACTS_DIR=${PEBBLELAB_E05_CONTRACTS_DIR:-/var/folders/23/t4l5dv055dl3x1zqylcpl9wc0000gn/T/PebbleLab-live.bdw9me}
MARKETS_DIR=${PEBBLELAB_E05_MARKETS_DIR:-/var/folders/23/t4l5dv055dl3x1zqylcpl9wc0000gn/T/PebbleLab-live.EpmPos}
BLOCKER04_DIR=${PEBBLELAB_E05_BLOCKER04_DIR:-/var/folders/23/t4l5dv055dl3x1zqylcpl9wc0000gn/T/PebbleLab-live.DQ3H9X}
BLOCKER01_DIR=${PEBBLELAB_E05_BLOCKER01_DIR:-/tmp/pebblelab-gate-e-blocker-01.uqvmNc}
BLOCKER02_DIR=${PEBBLELAB_E05_BLOCKER02_DIR:-/tmp/pebblelab-gate-e-blocker-02.FX0ofy}
BLOCKER03_DIR=${PEBBLELAB_E05_BLOCKER03_DIR:-/var/folders/23/t4l5dv055dl3x1zqylcpl9wc0000gn/T/PebbleLab-live.KqJbyH}
OUTPUT_PARENT=${PEBBLELAB_E05_REVIEW_PARENT:-$ROOT_DIR/..}

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

copy_log_set() {
    source_dir=$1
    destination_dir=$2
    expected=$3
    /bin/mkdir -p "$destination_dir"
    actual=0
    while IFS= read -r source_path; do
        copy_required "$source_path" "$destination_dir/$(basename "$source_path")"
        actual=$((actual + 1))
    done < <(/usr/bin/find "$source_dir" -maxdepth 1 -type f -name '*.log' -print | LC_ALL=C sort)
    [ "$actual" = "$expected" ] \
        || fail "expected $expected logs in $source_dir, found $actual"
}

copy_captures() {
    source_dir=$1
    destination_dir=$2
    expected=$3
    /bin/mkdir -p "$destination_dir"
    actual=0
    while IFS= read -r source_path; do
        copy_required "$source_path" "$destination_dir/$(basename "$source_path")"
        actual=$((actual + 1))
    done < <(/usr/bin/find "$source_dir" -maxdepth 1 -type f -name '*.png' -print | LC_ALL=C sort)
    [ "$actual" = "$expected" ] \
        || fail "expected $expected captures in $source_dir, found $actual"
}

copy_checkpoint() {
    session_root=$1
    checkpoint_name=$2
    destination_root=$3
    checkpoint_dir=$(/usr/bin/find \
        "$session_root/home/Library/Application Support/Pebble/PebbleLabAgents" \
        -type d -path "*/checkpoints/$checkpoint_name" -print -quit)
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
[ "$(git branch --show-current)" = "$BRANCH" ] || fail 'unexpected branch'
[ "$(git rev-parse origin/lab/pebblelab-v1)" = "$BASELINE" ] \
    || fail 'canonical remote no longer matches the required baseline'
[ "$(git merge-base HEAD "$BASELINE")" = "$BASELINE" ] \
    || fail 'evaluation branch is not rooted at the required baseline'
[ "$(git rev-list --count "$BASELINE"..HEAD)" = 4 ] \
    || fail 'Evaluation 05 must contain its four evaluation-only evidence commits'
[ -z "$(git status --short)" ] || fail 'worktree must be clean'

for evidence_head in \
    "$EVALUATION_01_HEAD" "$EVALUATION_02_HEAD" \
    "$EVALUATION_03_HEAD" "$EVALUATION_04_HEAD"; do
    if git merge-base --is-ancestor "$evidence_head" HEAD; then
        fail "historical evaluation evidence entered Evaluation 05 ancestry: $evidence_head"
    fi
done

unexpected_paths=$(git diff --name-only "$BASELINE"..HEAD | /usr/bin/grep -Ev \
    '^(Sources/pebsmoke/PebbleAgentsComposedAssetCommitmentSmoke.swift|Sources/pebsmoke/PebbleAgentsGateEEvaluation05Smoke.swift|Sources/pebsmoke/main.swift|docs/pebblelab/GATE_E_EVALUATION_05_REPORT.md|docs/pebblelab/GATE_E_EVALUATION_05_REPORT.json|scripts/build-pebblelab-gate-e-evaluation-05-review.sh|scripts/verify-pebblelab-live.sh)$' || true)
[ -z "$unexpected_paths" ] || fail "non-evaluation path changed: $unexpected_paths"

VALIDATION_DIR="$EVIDENCE_DIR/validation"
DRY_RUN_DIR="$EVIDENCE_DIR/dry-runs"
LIVE_DRIVER_DIR="$EVIDENCE_DIR/live"

require_text '21 passed, 0 failed' "$VALIDATION_DIR/evaluation-05-focused.log"
for result in \
    'production:36' 'barter:56' 'contracts:32' 'markets:31' \
    'material-rights:23' 'candidate-physical-atomicity:3' \
    'checkpoint-replay:49' 'persistence-reconciliation:19' \
    'observer:20' 'autonomous-civilization:36'; do
    selector=${result%%:*}
    count=${result##*:}
    require_text "$count passed, 0 failed" "$VALIDATION_DIR/owning-$selector.log"
done
for result in '01:27' '02:33' '03:25' '04:28'; do
    blocker=${result%%:*}
    count=${result##*:}
    require_text "$count passed, 0 failed" \
        "$VALIDATION_DIR/focused-gate-e-blocker-$blocker.log"
done
require_text '4015 passed, 0 failed' "$VALIDATION_DIR/repository-verification.log"
require_text 'PASS: all 35 PebbleLab verification steps succeeded.' \
    "$VALIDATION_DIR/repository-verification.log"
require_text 'Goldens: read-only; PEBBLE_REGOLD is refused.' \
    "$VALIDATION_DIR/repository-verification.log"

require_text 'PASS: canonical production, adversarial rollback, exact custody restart, produced-tool use, and cleanup verified.' \
    "$LIVE_DRIVER_DIR/e05-production-driver.log"
require_text 'PASS: CIV-35 normal discovery, local consent, sustainable offers, atomic rollback/retry, restart, downstream use, and cleanup verified.' \
    "$LIVE_DRIVER_DIR/e05-barter-driver.log"
require_text 'PASS: CIV-36 capacity prevalidation, current asset authority, ordinary and explicit exact rollback/retry, three-process durability, exact-once fulfillment, and cleanup verified.' \
    "$LIVE_DRIVER_DIR/e05-contracts-driver.log"
require_text 'PASS: physical market custody, two exact settlement rollbacks, price discovery, ordinary post-terminal re-entry, live-listing restart, withdrawal, and exact cleanup verified.' \
    "$LIVE_DRIVER_DIR/e05-markets-driver.log"
require_text 'PASS: Blocker 04 composed exclusion, same-operation continuation, terminal release, restart, conservation, and cleanup verified.' \
    "$LIVE_DRIVER_DIR/e05-blocker04-driver.log"
require_text 'PASS: Gate E Blocker 01 exact produced-asset provenance live proof.' \
    "$LIVE_DRIVER_DIR/e05-blocker01-driver.log"
require_text 'PASS: Gate E Blocker 02 evolved current identity live proof.' \
    "$LIVE_DRIVER_DIR/e05-blocker02-driver.log"
require_text 'PASS: Blocker 03 active reservation, terminal-history release, ordinary post-restart re-entry, conservation, and cleanup verified.' \
    "$LIVE_DRIVER_DIR/e05-blocker03-driver.log"

require_text 'dropsAcquired=1 downstreamUse=PASS' "$BARTER_DIR/barter-phase2.log"
require_text 'physicalLoss=0 physicalDuplication=0 syntheticMaterial=0 duplicateExchangeReceipts=0 duplicateReservations=0' \
    "$BARTER_DIR/barter-phase1.log"
require_text 'protected post-mutation error policy domain=contract action=consideration' \
    "$CONTRACTS_DIR/contract-phase1.log"
require_text 'CANDIDATE_PHYSICAL_ROLLBACK operation=advanceOneTick' \
    "$CONTRACTS_DIR/contract-phase1.log"
require_text 'contract physical publication' "$CONTRACTS_DIR/contract-phase1.log"
require_text 'checkpoint saved name=contract-open-v33' "$CONTRACTS_DIR/contract-phase1.log"
require_text 'sellerNeedRequestedQuantity=3 sellerPhysicalQuantityReceived=2 sellerNeedFinalStatus=active' \
    "$MARKETS_DIR/market-phase2.log"
require_text 'priceHistoryAppended=1 localPriceHistoryCreated=1 duplicateMarketTradeReceipts=0' \
    "$MARKETS_DIR/market-phase2.log"
require_text 'market deposit completed seller=agent_2' "$MARKETS_DIR/market-phase4.log"
require_text 'market normal listing decision seller=agent_2' "$MARKETS_DIR/market-phase4.log"
require_text 'checkpoint saved name=market-reentered-open-v34' "$MARKETS_DIR/market-phase4.log"
require_text 'checkpoint loaded name=market-reentered-open-v34' "$MARKETS_DIR/market-phase5.log"
require_text 'custodyDuplicates=0 physicalBoundary=acquired' "$MARKETS_DIR/market-phase5.log"
require_text 'market unsold withdrawal completed deposit=' "$MARKETS_DIR/market-phase5.log"
require_text 'seller=agent_2 receipt=market:withdraw:' "$MARKETS_DIR/market-phase5.log"
require_text 'physical=market:central:[]' "$MARKETS_DIR/market-phase5.log"
require_text 'physicalLoss=0 physicalDuplication=0 syntheticTradeMaterial=0 duplicateReservations=0 duplicateDeposits=0 observerMutationCount=0' \
    "$MARKETS_DIR/market-phase5.log"
require_text 'checkpoint saved name=market-reentered-final-v34' "$MARKETS_DIR/market-phase5.log"
require_text 'runtimeErrors=0' "$MARKETS_DIR/market-phase5.log"
require_text 'probesRemoved=3' "$MARKETS_DIR/market-phase5.log"
require_text 'crossSystemDuplicateLiveCommitments=0' "$BLOCKER04_DIR/market-phase4.log"
require_text 'physicalLoss=0 physicalDuplication=0 syntheticMaterial=0 duplicateDeposits=0 duplicateReservations=0 duplicateReceipts=0 duplicateSettlements=0 observerMutationCount=0 unexpectedRuntimeErrors=0 readOnly=1' \
    "$BLOCKER04_DIR/market-phase4.log"
require_text 'probesRemoved=3' "$BLOCKER04_DIR/market-phase4.log"

HEAD_COMMIT=$(git rev-parse HEAD)
HEAD_SHORT=$(git rev-parse --short=12 HEAD)
BUNDLE_NAME="PebbleLab-GateE-Evaluation05-Review-$HEAD_SHORT"
BUNDLE_DIR="$OUTPUT_PARENT/$BUNDLE_NAME"
ZIP_PATH="$OUTPUT_PARENT/$BUNDLE_NAME.zip"
[ ! -e "$BUNDLE_DIR" ] || fail "bundle directory exists: $BUNDLE_DIR"
[ ! -e "$ZIP_PATH" ] || fail "bundle ZIP exists: $ZIP_PATH"

/bin/mkdir -p \
    "$BUNDLE_DIR/evaluation" \
    "$BUNDLE_DIR/raw/validation" \
    "$BUNDLE_DIR/raw/dry-runs" \
    "$BUNDLE_DIR/raw/live/drivers" \
    "$BUNDLE_DIR/raw/live/sessions" \
    "$BUNDLE_DIR/captures" \
    "$BUNDLE_DIR/checkpoints" \
    "$BUNDLE_DIR/git"

copy_required docs/pebblelab/GATE_E_EVALUATION_05_REPORT.md \
    "$BUNDLE_DIR/evaluation/GATE_E_EVALUATION_05_REPORT.md"
copy_required docs/pebblelab/GATE_E_EVALUATION_05_REPORT.json \
    "$BUNDLE_DIR/evaluation/GATE_E_EVALUATION_05_REPORT.repository.json"
copy_required scripts/build-pebblelab-gate-e-evaluation-05-review.sh \
    "$BUNDLE_DIR/evaluation/build-review-archive.sh"
copy_required scripts/verify-pebblelab-live.sh \
    "$BUNDLE_DIR/evaluation/verify-pebblelab-live.sh"

copy_log_set "$VALIDATION_DIR" "$BUNDLE_DIR/raw/validation" 16
copy_log_set "$DRY_RUN_DIR" "$BUNDLE_DIR/raw/dry-runs" 8
copy_log_set "$LIVE_DRIVER_DIR" "$BUNDLE_DIR/raw/live/drivers" 8
copy_log_set "$PRODUCTION_DIR" "$BUNDLE_DIR/raw/live/sessions/e05-production" 2
copy_log_set "$BARTER_DIR" "$BUNDLE_DIR/raw/live/sessions/e05-barter" 2
copy_log_set "$CONTRACTS_DIR" "$BUNDLE_DIR/raw/live/sessions/e05-contracts" 4
copy_log_set "$MARKETS_DIR" "$BUNDLE_DIR/raw/live/sessions/e05-markets" 5
copy_log_set "$BLOCKER04_DIR" "$BUNDLE_DIR/raw/live/sessions/e05-blocker04" 4
copy_log_set "$BLOCKER01_DIR" "$BUNDLE_DIR/raw/live/sessions/aux-blocker01" 2
copy_log_set "$BLOCKER02_DIR" "$BUNDLE_DIR/raw/live/sessions/aux-blocker02" 2
copy_log_set "$BLOCKER03_DIR" "$BUNDLE_DIR/raw/live/sessions/aux-blocker03" 4

copy_captures "$PRODUCTION_DIR/captures" "$BUNDLE_DIR/captures/e05-production" 6
copy_captures "$BARTER_DIR/captures" "$BUNDLE_DIR/captures/e05-barter" 6
copy_captures "$CONTRACTS_DIR/captures" "$BUNDLE_DIR/captures/e05-contracts" 12
copy_captures "$MARKETS_DIR/captures" "$BUNDLE_DIR/captures/e05-markets" 17
copy_captures "$BLOCKER04_DIR/captures" "$BUNDLE_DIR/captures/e05-blocker04" 13
copy_captures "$BLOCKER01_DIR/captures" "$BUNDLE_DIR/captures/aux-blocker01" 9
copy_captures "$BLOCKER02_DIR/captures" "$BUNDLE_DIR/captures/aux-blocker02" 8
copy_captures "$BLOCKER03_DIR/captures" "$BUNDLE_DIR/captures/aux-blocker03" 16

for checkpoint in production-v31 production-final-v31; do
    copy_checkpoint "$PRODUCTION_DIR" "$checkpoint" "$BUNDLE_DIR/checkpoints/e05-production"
done
for checkpoint in barter-v32 barter-final-v32; do
    copy_checkpoint "$BARTER_DIR" "$checkpoint" "$BUNDLE_DIR/checkpoints/e05-barter"
done
for checkpoint in contract-open-v33 contract-fulfilled-v33 contract-final-v33; do
    copy_checkpoint "$CONTRACTS_DIR" "$checkpoint" "$BUNDLE_DIR/checkpoints/e05-contracts"
done
for checkpoint in market-open-v34 market-traded-v34 market-final-v34 \
    market-reentered-open-v34 market-reentered-final-v34; do
    copy_checkpoint "$MARKETS_DIR" "$checkpoint" "$BUNDLE_DIR/checkpoints/e05-markets"
done
for checkpoint in gate-e-blocker04-live-contract-v34 \
    gate-e-blocker04-released-v34 gate-e-blocker04-barter-completed-v34; do
    copy_checkpoint "$BLOCKER04_DIR" "$checkpoint" "$BUNDLE_DIR/checkpoints/e05-blocker04"
done
for checkpoint in gate-e-blocker-01-open-v33 gate-e-blocker-01-fulfilled-v33; do
    copy_checkpoint "$BLOCKER01_DIR" "$checkpoint" "$BUNDLE_DIR/checkpoints/aux-blocker01"
done
for checkpoint in gate-e-blocker-02-damage1-v34 gate-e-blocker-02-damage2-v34; do
    copy_checkpoint "$BLOCKER02_DIR" "$checkpoint" "$BUNDLE_DIR/checkpoints/aux-blocker02"
done
for checkpoint in market-open-v34 market-traded-v34 market-final-v34 \
    market-blocker03-reentered-v34; do
    copy_checkpoint "$BLOCKER03_DIR" "$checkpoint" "$BUNDLE_DIR/checkpoints/aux-blocker03"
done

git diff --binary "$BASELINE"..HEAD > "$BUNDLE_DIR/git/BASELINE_TO_EVIDENCE.patch"
[ -s "$BUNDLE_DIR/git/BASELINE_TO_EVIDENCE.patch" ] \
    || fail 'baseline-to-evidence patch is empty'
git log --oneline --decorate "$BASELINE"..HEAD > "$BUNDLE_DIR/git/GIT_LOG.txt"
git diff --stat "$BASELINE"..HEAD > "$BUNDLE_DIR/git/DIFF_STAT.txt"
git diff --check "$BASELINE"..HEAD > "$BUNDLE_DIR/git/DIFF_CHECK.txt"

{
    printf 'repository=Ness-Now/pebble\n'
    printf 'canonical_branch=lab/pebblelab-v1\n'
    printf 'evaluated_baseline=%s\n' "$BASELINE"
    printf 'canonical_remote_sha_verified=%s\n' "$(git rev-parse origin/lab/pebblelab-v1)"
    printf 'evaluation_branch=%s\n' "$BRANCH"
    printf 'final_evidence_head=%s\n' "$HEAD_COMMIT"
    printf 'merge_base=%s\n' "$(git merge-base HEAD "$BASELINE")"
    printf 'evidence_commit_count=%s\n' "$(git rev-list --count "$BASELINE"..HEAD)"
    printf 'product_correction_made=NO\n'
    printf 'worktree=clean\n'
    printf 'push=NOT_ATTEMPTED\n'
} > "$BUNDLE_DIR/GIT_STATE.txt"

{
    printf 'evaluation_01_head=%s ancestor=NO\n' "$EVALUATION_01_HEAD"
    printf 'evaluation_02_head=%s ancestor=NO\n' "$EVALUATION_02_HEAD"
    printf 'evaluation_03_head=%s ancestor=NO\n' "$EVALUATION_03_HEAD"
    printf 'evaluation_04_head=%s ancestor=NO\n' "$EVALUATION_04_HEAD"
} > "$BUNDLE_DIR/ANCESTRY.txt"

/bin/cat > "$BUNDLE_DIR/00_README_FIRST.md" <<EOF
# Gate E Evaluation 05 review archive

Verdict: **LOCAL PASS CANDIDATE — SENIOR REVIEW REQUIRED**

Evaluated baseline: $BASELINE

Final evidence HEAD: $HEAD_COMMIT

This archive is evaluation-only. It does not claim Gate E acquisition, does
not start CIV-38, does not add currency as a dependency, contains no product
correction, and records no push. Start with the durable report, REPORT.json,
GIT_STATE.txt, and ANCESTRY.txt, then inspect the focused/regression logs,
raw live traces, checkpoints and 87 inspected captures.

The 87 captures comprise 54 decisive Evaluation 05 captures and 33 successful
auxiliary Blocker captures. The earlier stale-checkpoint experiment was not
rerun, retained, or counted; the corrected market proof restarts only a live
checkpoint saved together with its required physical escrow.
EOF

/usr/bin/python3 - "$HEAD_COMMIT" \
    docs/pebblelab/GATE_E_EVALUATION_05_REPORT.json \
    "$BUNDLE_DIR/REPORT.json" <<'PY'
import json
import pathlib
import sys

head, source, destination = sys.argv[1:]
report = json.loads(pathlib.Path(source).read_text())
report["finalEvidenceHead"] = head
report["finalEvidenceHeadResolution"] = "Resolved by the clean-worktree review archive builder."
pathlib.Path(destination).write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n")
PY

{
    printf '# Validation commands and results\n\n'
    printf -- '- `PEBBLELAB_SMOKE_ONLY=gate-e-evaluation-05 swift run -c release pebsmoke`: 21/21.\n'
    printf -- '- Owning selectors (`production`, `barter`, `contracts`, `markets`, `material-rights`, `candidate-physical-atomicity`, `checkpoint-replay`, `persistence-reconciliation`, `observer`, `autonomous-civilization`): 305/305.\n'
    printf -- '- Gate E Blockers 01–04 focused selectors: 113/113.\n'
    printf -- '- `scripts/verify-pebblelab.sh`: 35/35 steps and 4015/4015 assertions.\n'
    printf -- '- Gate E production, barter, contracts, markets, and Blocker 01–04 live launchers were dry-run before execution.\n'
    printf '\nExact stdout and stderr are retained under `raw`.\n'
} > "$BUNDLE_DIR/VALIDATION_COMMANDS.md"

{
    printf '# Capture inspection\n\n'
    printf 'All 87 captures were manually inspected before packaging.\n\n'
    printf '| Group | Captures | Classification |\n'
    printf '|---|---:|---|\n'
    printf '| E05 production | 6 | decisive |\n'
    printf '| E05 barter | 6 | decisive |\n'
    printf '| E05 contracts | 12 | decisive |\n'
    printf '| E05 markets | 17 | decisive |\n'
    printf '| E05 Blocker 04 composition | 13 | decisive |\n'
    printf '| Auxiliary Blockers 01–03 | 33 | passing support |\n'
    printf '| Excluded diagnostics | 0 | not retained or counted |\n\n'
    printf 'PNG inventory:\n\n```text\n'
    /usr/bin/find "$BUNDLE_DIR/captures" -type f -name '*.png' -print \
        | LC_ALL=C sort | while IFS= read -r capture; do /usr/bin/file "$capture"; done
    printf '```\n'
} > "$BUNDLE_DIR/CAPTURE_INSPECTION.md"

{
    printf '# Cleanup evidence\n\n'
    printf 'Decisive and dedicated passing campaigns conserved state and removed all three probes per process. '
    printf 'Production, barter, contracts and Blockers 01–04 record exact fixture cleanup. '
    printf 'The ordinary market campaign legitimately reentered with a new exact asset after terminal release, '
    printf 'saved the new escrow with its live checkpoint, restarted, withdrew, and recorded exact cleanup.\n\n'
    printf 'Excluded diagnostics: 0 processes and 0 captures. The earlier stale-checkpoint experiment was not '
    printf 'rerun, retained, or used as passing evidence.\n'
} > "$BUNDLE_DIR/CLEANUP_EVIDENCE.md"

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
/usr/bin/unzip -tq "$ZIP_PATH" >/dev/null || fail 'ZIP integrity failed'
if /usr/bin/zipinfo -1 "$ZIP_PATH" \
    | /usr/bin/awk 'BEGIN { bad=0 } /^\// { bad=1 } /(^|\/)\.\.($|\/)/ { bad=1 } /\\/ { bad=1 } END { exit bad ? 0 : 1 }'; then
    fail 'unsafe archive path detected'
fi

VALIDATION_EXTRACT=$(mktemp -d "${TMPDIR:-/tmp}/PebbleLab-E05-Review-Validate.XXXXXX")
/usr/bin/unzip -q "$ZIP_PATH" -d "$VALIDATION_EXTRACT"
if [ -n "$(find "$VALIDATION_EXTRACT" -type l -print -quit)" ]; then
    fail 'symlink found after fresh extraction'
fi
(
    cd "$VALIDATION_EXTRACT/$BUNDLE_NAME"
    shasum -a 256 -c CHECKSUMS.sha256 >/dev/null
)

ZIP_SHA=$(shasum -a 256 "$ZIP_PATH" | /usr/bin/awk '{print $1}')
shasum -a 256 "$ZIP_PATH" > "$ZIP_PATH.sha256"
printf 'Review ZIP: %s\n' "$ZIP_PATH"
printf 'Review ZIP SHA-256: %s\n' "$ZIP_SHA"
printf 'Internal checksums: %s/%s PASS\n' "$INTERNAL_COUNT" "$INTERNAL_COUNT"
printf 'Safe relative paths: PASS\n'
printf 'Source symlink validation: PASS\n'
printf 'ZIP integrity: PASS\n'
printf 'Fresh extraction symlink validation: PASS\n'
printf 'Fresh extraction checksum validation: PASS\n'
printf 'Validation extraction retained: %s\n' "$VALIDATION_EXTRACT"
