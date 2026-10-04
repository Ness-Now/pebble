# PS01 Increment 08 — Final candidate after published B04

Status: **PUBLICATION CHAIN READY / USER PUSH PENDING / NOT PUBLISHED**.
Publication reconciliation mission: `PUBLISH-RECONCILIATION-PS01-INCREMENT-08-NORMAL-CONTINUITY`.
Mission: `RESUME-PS01-I08-B03-AFTER-PUBLISHED-B04-AND-RECONSTITUTE-FINAL-CANDIDATE`.

## Final independent review and pending user publication

The supervisor-provided final independent review concluded
**PS01_INCREMENT_08_FINAL_INDEPENDENT_REVIEW_PASS**, with **P0 0 / P1 0 / blocking P2 0**.
The exact approved candidate is `eab79c7e2723f3aafbbd5bb65c8562b2b911cae8`, tree
`ff7582d0ed096eae057d00e2cedec6dc761cd496`, sole parent `c58fe2c0fbb2c5b568426c5f936e7a50e573ff08`,
subject `feat(ps01): add coherent normal World and civilization continuation`.
The review explicitly finds this commit **safe to publish unchanged within the
documented Increment-08 scope**. This documentation-only reconciliation records
that accepted conclusion; it does not amend the candidate or rerun qualification.

The local publication chain is exactly:

`c58fe2c0fbb2c5b568426c5f936e7a50e573ff08` →
`eab79c7e2723f3aafbbd5bb65c8562b2b911cae8` → this single documentation reconciliation commit.

Its final documentation SHA/tree are reported externally after commit creation.
No historical FAIL commit or unrelated commit enters this chain. The publication
branch is `codex/ps01-increment-08-final-after-b04` in
`/Users/nessnow/.codex/worktrees/ps01-i08-final-after-b04/pebble-lab`.
Fetched canonical remains `c58fe2c0fbb2c5b568426c5f936e7a50e573ff08`. **User push is pending;
I08 is not remotely published.** Only successful user push followed by remote
verification of the exact publication chain permits Increment 08 itself to become
`COMPLETE_AND_PUBLISHED`. Codex does not push.

After verified publication, the next action remains **supervisor selection /
roadmap recalibration**. Publication does not start another increment, Wave 6,
CIV-48 or Gate H. PS01 remains **IN PROGRESS / NOT COMPLETE**; CIV-48 remains
**NOT STARTED / IMPLEMENTATION NOT AUTHORIZED**; Gate H remains **PLANNED**.
B01 and B04 remain published. Historical FAIL evidence and residual limits below
remain unchanged.

## Canonical and historical ownership

Fetched `origin/lab/pebblelab-v1` and independent `git ls-remote` both identify
`c58fe2c0fbb2c5b568426c5f936e7a50e573ff08`. The published chain is
`9919e575819dca02ee8e893a37ac9eaaebc36012` →
`aa07e3ce71c34842e45611d8e9064de9cb563a16` → `c58fe2c`.
B01 and B04 remain **BLOCKER_FIX_PUBLISHED**. B04's exact shared Core correction,
dedicated record, evidence manifest, qualification scripts and deterministic
driver are preserved. This mission does not reopen or duplicate that fix.

The historical worktree `/Users/nessnow/Dev/pebble-lab` remains on
`codex/ps01-increment-08-normal-continuity` at
`8b7b1970c0f85e14b905ab032c2448057e9737b9`, with exactly nine unstaged tracked
modifications, 236 insertions / 19 deletions, no staged or untracked files.
Its dirty diff SHA-256 is
`b5b98710ee334c47ecc3b38f5a1bdbb6416c45127a7e72eaaf735f3ba5760d1c`.
Historical FAIL candidates `066704f53275ca56f863b5911d8799d8072c2196` and
`8b7b197` retain their exact raw commit objects. Neither is an ancestor of the
new canonical-based candidate. No rebase, amendment or cherry-pick occurred.

Before reconstruction, the complete committed tree, exact nine modified files,
modes, ordinary/full-index binary patches, status, raw commit objects, Git bundle
and per-file hashes were preserved externally at
`/Users/nessnow/.codex/artifacts/ps01-i08-b03-safety-20261004`.
Safety manifest SHA-256:
`2799432100705cb0e1485974c0843e9dc691bcdbcb2473b1a07d3f660f01528a`;
committed archive:
`e19a5bf770613d6cf6f0bddf3058d1530fd1089adfdd1207387a9e6d4868a0c1`;
verified Git bundle:
`e865c00a480c8c2a2868bf403fed1e07996c8680276419b5b6cb5a9a996cb0f3`.
The safety artifact is retained permanently.

## Reconstitution proof and file mapping

New branch: `codex/ps01-increment-08-final-after-b04`.
New managed worktree:
`/Users/nessnow/.codex/worktrees/ps01-i08-final-after-b04/pebble-lab`.
Before expensive qualification its HEAD/base was exactly `c58fe2c`, all nine B03
files matched the safety copy byte-for-byte, every historical I08/B02 change was
present, and `git diff --check` passed. No historical FAIL commit was replayed.

The old root for every left-hand path is `/Users/nessnow/Dev/pebble-lab`;
the final root for every right-hand path is the new managed worktree above.
`reconstitution-proof.json` in the evidence archive contains each complete
absolute OLD HISTORICAL FILE → FINAL RECONSTITUTED FILE mapping, before/after
SHA-256, canonical hash, mode and B03 attribution.

| OLD HISTORICAL FILE | FINAL RECONSTITUTED FILE | Reconstruction |
| --- | --- | --- |
| `Sources/Pebble/CommandsM.swift` | `Sources/Pebble/CommandsM.swift` | Exact preserved I08/B02/B03 bytes and mode |
| `Sources/Pebble/PebbleAgentController+Commands.swift` | `Sources/Pebble/PebbleAgentController+Commands.swift` | Exact preserved I08/B02/B03 bytes and mode |
| `Sources/Pebble/PebbleAgentController+Lifecycle.swift` | `Sources/Pebble/PebbleAgentController+Lifecycle.swift` | Exact preserved I08/B02/B03 bytes and mode |
| `Sources/Pebble/PebbleAgentController+Persistence.swift` | `Sources/Pebble/PebbleAgentController+Persistence.swift` | Exact preserved I08/B02/B03 bytes and mode |
| `Sources/Pebble/PebbleAgentController+WorldContinuation.swift` | `Sources/Pebble/PebbleAgentController+WorldContinuation.swift` | Exact preserved I08/B02/B03 bytes and mode |
| `Sources/Pebble/PebbleAgentController.swift` | `Sources/Pebble/PebbleAgentController.swift` | Exact preserved I08/B02/B03 bytes and mode |
| `Sources/Pebble/PebbleIncrement08ContinuationHarness.swift` | `Sources/Pebble/PebbleIncrement08ContinuationHarness.swift` | Exact preserved I08/B02/B03 bytes and mode |
| `Sources/Pebble/PebbleWorldEcologicalObservationReceiptStore.swift` | `Sources/Pebble/PebbleWorldEcologicalObservationReceiptStore.swift` | Exact preserved I08/B02/B03 bytes and mode |
| `Sources/Pebble/main.swift` | `Sources/Pebble/main.swift` | Exact preserved I08/B02/B03 bytes and mode |
| `Sources/PebbleCore/Game/GameCore.swift` | `Sources/PebbleCore/Game/GameCore.swift` | Exact preserved I08/B02/B03 bytes and mode |
| `Sources/PebbleCore/Game/Saves.swift` | `Sources/PebbleCore/Game/Saves.swift` | Exact preserved I08/B02/B03 bytes and mode |
| `Sources/pebsmoke/PebbleCoreWorldContinuationSmoke.swift` | `Sources/pebsmoke/PebbleCoreWorldContinuationSmoke.swift` | Exact preserved I08/B02/B03 bytes and mode |
| `Sources/pebsmoke/main.swift` | `Sources/pebsmoke/main.swift` | Canonical B04 dispatch retained; exact I08 dispatch added |
| `docs/pebblelab/DOCUMENTATION_INDEX.md` | `docs/pebblelab/DOCUMENTATION_INDEX.md` | Canonical B01/B04 index retained; I08 record added |
| `docs/pebblelab/PS01_INCREMENT_08_NORMAL_CONTINUITY.md` | `docs/pebblelab/PS01_INCREMENT_08_NORMAL_CONTINUITY.md` | Exact preserved I08/B02/B03 bytes and mode |
| `scripts/verify-pebblelab-ps01-increment-08-live.sh` | `scripts/verify-pebblelab-ps01-increment-08-live.sh` | Exact preserved I08/B02/B03 bytes and mode |
| `scripts/verify-pebblelab-ps01-increment-08.sh` | `scripts/verify-pebblelab-ps01-increment-08.sh` | Exact preserved I08/B02/B03 bytes and mode |

Fifteen files initially transferred exactly. Only smoke dispatch and the index
required a merge with the newer canonical. Candidate documentation is then
additive: this final chronology precedes the original B02 record retained
verbatim below; current-state/start/index summaries reconcile B04 publication
and I08 local candidate status. Published B01/B04 dedicated documentation and
roadmap/manifest authority are not overwritten by older I08 documentation.
Runtime source/script hashes remain frozen across qualification.

## B03 retained compensation ownership audit

**PS01-I08-BLOCKER-03 — RETAINED COMPENSATION OWNERSHIP / DESTRUCTIVE CLEANUP**
repairs I08 product failure semantics. P1-A discarded `pendingWorldContinuation`
after failed completion compensation. P1-B allowed destructive commands to
remove the session, probes and the retained compensation owner while unresolved.
The additional `/labprobe clear`, direct Core cleanup and `/kill @e` paths are
covered. Physical drop input obeys the lifecycle hard halt.

The existing pending record retains the original checkpoint, probe object
snapshots, prior handoff and World/session identity. Completion disposes it only
after exact custody return is verified. Explicit cancellation verifies that
same retained owner and matching failure identity before clearing its latch.
Stop, clear, start/reset, demo and checkpoint mutations refuse unresolved
ownership; direct stop/shutdown/rebuild and probe cleanup also refuse. Core
freezes ordinary tick/input progression, replacement/exit/termination require
the barrier, and bound portal travel refuses. Mortality/population/restore
cleanup cannot progress around those production guards.

The private lifecycle teardown may discard ownership only after successful
persistence/publication and committed irreversible finalization. A hard failure
never authorizes destruction. Explicit safe recovery (`cancelPreparedLifecycle`
or ordinary `/lab resume`) returns the original three physical items without
duplication and permits a subsequent ordinary save/replacement. No equivalent
production disposal path was missed during migration. The read-only audit is
recorded in `b03-ownership-audit.json`.

## Post-B04 qualification — complete final source

All qualification below ran from the new canonical-based worktree, with fresh
isolated homes and frozen native executables. No runtime/script source changed
between reconstruction, builds, qualification and delivery. The complete
campaign passes **366 / 0**: 45 Core + 319 named
product assertions + two exact paired semantic comparisons. The adversarial
169 product assertions are included in that total, not counted twice.
Separate focused, owning, offline authority and VGS runs are reported below.

| Exact command (log redirection omitted) | Result | Exit |
| --- | --- | ---: |
| `swift build --product Pebble --scratch-path /tmp/ps01-i08-final-after-b04-20261004/debug-build` | native debug Pebble 117.10s | 0 |
| `swift build -c release --product Pebble` | native release Pebble 566.18s | 0 |
| `swift build -c release --product pebsmoke` | native release pebsmoke 184.00s | 0 |
| `bash /tmp/ps01-i08-final-after-b04-20261004/focused-final/run.sh compensation` | 71/0 | 0 |
| `bash /tmp/ps01-i08-final-after-b04-20261004/focused-final/run.sh replacement` | 99/0 | 0 |
| `PEBBLELAB_I08_SKIP_BUILD=1 scripts/verify-pebblelab-ps01-increment-08.sh /tmp/ps01-i08-final-after-b04-20261004/qualification-final` | 366/0 | 0 |
| `bash /tmp/ps01-i08-final-after-b04-20261004/owning-final/run.sh` | 1270/0 | 0 |
| `scripts/verify-pebblelab-live.sh --dry-run --persistence` | canonical live preflight | 0 |
| `PEBBLELAB_I08_EVIDENCE_ROOT=/tmp/ps01-i08-final-after-b04-20261004/visual-final scripts/verify-pebblelab-ps01-increment-08-live.sh --dry-run` | I08 rendered preflight | 0 |
| `PEBBLELAB_I08_EVIDENCE_ROOT=/tmp/ps01-i08-final-after-b04-20261004/visual-final scripts/verify-pebblelab-ps01-increment-08-live.sh` | 8 visual/continuity assertions; both process exits 0 | 0 |
| `python3 /tmp/ps01-i08-final-after-b04-20261004/visual-final/inspect-conservation.py /tmp/ps01-i08-final-after-b04-20261004/visual-final` | 4/0; 8 acquired = 7 consumed + 1 carried | 0 |
| `python3 /tmp/ps01-i08-final-after-b04-20261004/inspect-determinism.py /tmp/ps01-i08-final-after-b04-20261004/qualification-final` | 8/0 additional read-only authority checks | 0 |
| `CFFIXED_USER_HOME=/tmp/ps01-i08-final-after-b04-20261004/canonical/home scripts/verify-pebblelab.sh` | stage 5; 5789/3, exactly published historical failures | 1 |
| `CFFIXED_USER_HOME=/tmp/ps01-i08-final-after-b04-20261004/canonical/home bash /tmp/ps01-i08-final-after-b04-20261004/canonical/remaining.sh` | canonical supplemental stages 6–35, 30/30 | 0 |

| Complete campaign phase | Assertions | Exit |
| --- | ---: | ---: |
| faults-faults.log | 169 / 0 | 0 |
| envelope-20-envelope.log | 6 / 0 | 0 |
| envelope-20-read.log | 9 / 0 | 0 |
| envelope-30-envelope.log | 6 / 0 | 0 |
| envelope-30-read.log | 9 / 0 | 0 |
| deterministic-a-envelope.log | 6 / 0 | 0 |
| deterministic-a-read.log | 9 / 0 | 0 |
| deterministic-b-envelope.log | 6 / 0 | 0 |
| deterministic-b-read.log | 9 / 0 | 0 |
| retention-retention.log | 11 / 0 | 0 |
| retention-read.log | 9 / 0 | 0 |
| retention-manual-retention-manual.log | 12 / 0 | 0 |
| retention-manual-read.log | 9 / 0 | 0 |
| positive-write.log | 7 / 0 | 0 |
| positive-read.log | 10 / 0 | 0 |
| scarcity-write.log | 6 / 0 | 0 |
| scarcity-read.log | 9 / 0 | 0 |
| zero-zero.log | 8 / 0 | 0 |
| zero-read.log | 9 / 0 | 0 |

The seven owning suites are checkpoint/replay **49/0**, persistence
reconciliation **19/0**, I07 focused **175/0**, ecological observation **89/0**,
agriculture **86/0**, B01 mortality/checkpoint compaction **14/0** and published
B04 focused Core **838/0**, total **1,270/0**, all exits 0. B04's already
published TSan/stress campaign was not rerun; its source and focused owning
correction remain intact. Full canonical remains **FAIL: 5,789 passed / 3
failed**, exit 1 at stage 5, with exactly zoo bit-identical, combat lockstep and
eight A* node-identical. Supplemental unchanged stages 6–35 pass **30/30**,
exit 0. No regold, golden changes or weakened comparison occurred.

### Natural food, scarcity and genuine zero population

Natural seed 14 saves at World **9657** / civilization **1921**, with **five
acquired/carried items**. Ordinary fresh entry restores all five, consumes four
and continues to civilization **1924**, without founder reconstruction.
Scarcity seed 46 saves at World **1252** / civilization **240** and continues
normally to **243**. Receipt retention and standalone manual retention both
survive fresh ordinary entry with exact durable/causal/material authority.

Seed-46 extinction is genuine: the final normal I08 path starts 24 natural
founders, runs ordinary 1 Hz cognition with one Core tick at a time, and reaches
World **27652** / civilization **1380**, population **zero**. Ordinary
capture, Save/Continue and Save/Exit preserve the exact durable boundary.
Fresh-process restore loads zero agents and zero new founders, preserves the
durable digest and advances to **1381**, still zero. No empty civilization,
death, population outcome or replacement founder was synthesized.

### Determinism and meaningful authority

The two independent 24-founder A/B writer and reader processes compare exact
semantic JSON at the saved and continued boundaries. An additional **8/0**
read-only inspection compares World/civilization time, civilization identity,
finalized durable digest, the full causal ledger/rolling digest, population,
material and protected custody authority, and full durable continuation state.
Pre-exit reports and post-exit captures are compared as separate A/B pairs:
checkpoint capture reconciles physiological timing. No runtime cache or
process-local incarnation equality is required.

### Final-source Visual Game Smoke V5

All three PNGs were actually inspected: natural forest, river, hillside and
situated Pebbles before save and after fresh restore; continued nighttime
terrain and Pebbles remain visible. Loading and the Observer panel do not
obstruct the scene. All report 1,824 uploaded sections, nine ready surface
chunks and positive target geometry. Both application processes and the complete
driver exit **0**; the eight driver assertions and four independent durable
conservation assertions pass **12/0**.

World `wmusyo8cnh3rs`, civilization `live-14-208-67--32`: writer civilization
1921 carries four; the fresh reader creates zero founders, captures at 2162
after consuming six, and continues to 2402 with seven consumed and one carried.
Final selected Core/checkpoint/custody authority proves **8 acquired = 7
consumed + 1 carried**, four real harvest outcomes, zero retained-evidence
evictions and no dropped consumption evidence.

The earlier live run's nine-item result remains historical supporting evidence.
Its World capture boundaries were 9671/10876/12076; final boundaries are
9668/10873/12073. Core direct physical randomness includes authoritative World
time. Actual harvest quantities are now 1+3+3+1, versus prior 2+2+3+2, with the
last acquisition at civilization 2342 rather than 2341. This is ordinary live
boundary evolution; exact conservation and same-source A/B authority remain
proved. Terrain generation algorithms and the published B04 correction are
unchanged. No exact historical loot total was imposed.

### Builds and executable attribution

Native initial debug Pebble build: **117.10s / exit 0**, SHA-256
`d19924e7671607aef88ba2d9bff39c9f58045befa7061c5a3fdbfb1267785e35`.
The canonical all-target debug build also passes **470.60s / exit 0**; its
Pebble SHA-256 is
`0dced26a2572a0fe7debb5630270a4f61ac8091d5909b96def73efc6e2190319`.
Release Pebble build: **566.18s / exit 0**; release pebsmoke: **184.00s / exit 0**.
Canonical native release PebbleLab build: **692.47s / exit 0**.

All final focused/product/VGS runs use release Pebble SHA-256
`6b741347be178bb40c22c3c0fef5e99b6d7993122415cc457dcb2285ffadb92d`.
Release pebsmoke owning/full gate SHA-256:
`7180d57274a25345207fa9bea9380dd4c3b0d28edae556e579c9091d35030a4a`.
Release PebbleLab supplemental gate SHA-256:
`a92a7078a02ee4b61ffe4a9b6e20fdd02349b068e31ffe0fb9f6af898a2b0c2e`.
Every executable was checked as native **Mach-O arm64**, then preserved under
explicit native paths with its hash. No Rosetta/x86 copy is attributed here.

Original execution root: `/tmp/ps01-i08-final-after-b04-20261004`.
Permanent additive archive:
`/Users/nessnow/.codex/artifacts/ps01-i08-final-after-b04-20261004`, including
logs, drivers, captures, native executables, durable homes, source hashes,
supplemental outputs, final results and delivery identity. The separately
immutable safety artifact is never removed. Machine-readable attribution is in
[PS01_INCREMENT_08_FINAL_EVIDENCE.json](PS01_INCREMENT_08_FINAL_EVIDENCE.json).
The single coherent local candidate commit is directly above `c58fe2c`; its
SHA/tree and exact Git audit are recorded in the external `delivery-manifest.json`
after commit creation rather than through a circular self-SHA claim.

### Residual limits and project status

Qualification is bounded to the authorized normal paths, 20/24/30 founder
envelope, the two natural conditions and tested failure/retry boundaries.
Arbitrary crash recovery, old migrations, higher populations and multi-dimension
civilization continuation are not claimed. Population-capacity/demographic
headroom remains a PS01 integration issue. Published B01 bounded-history trust
risks and B04's arbitrary-GenCtx context-identity limitation remain non-blocking
owning follow-ups; neither was reopened or disguised as a new I08 correction.

I08 is **PUBLICATION CHAIN READY / USER PUSH PENDING / NOT PUBLISHED**,
with accepted final independent review PASS for the unchanged candidate above.
PS01 remains **IN PROGRESS / NOT COMPLETE**. CIV-48 remains **NOT STARTED /
IMPLEMENTATION NOT AUTHORIZED**. Gate H remains **PLANNED**. B01 and B04 remain
published. **Push attempted: NO**.

## Immutable historical review chronology

1. The original blocked I08 attempt and B01 pre-fix failure remain FAIL.
   B01 was independently corrected and published; neither the failed checkpoint
   nor its attribution is reclassified by later qualification.
2. Original local I08 qualification produced candidate `066704f`; independent
   senior review returned **FAIL**, exposing the B02 post-publication replacement
   custody cancellation P1. Its unchanged-owner regression failed 5/1.
3. B02 local correction/requalification produced `8b7b197`; the second independent
   senior review also returned **FAIL**, exposing B03 P1-A/P1-B. Neither reviewed
   FAIL commit enters the new candidate ancestry or publication path.
4. B03 correction found equivalent destructive paths, including the missed
   `/kill @e` path and physical drop input. Final pre-B04 focused support was
   71/71, combined 99/99 and 45 Core + 169 product / 0. These are historical
   supporting results, not post-B04 qualification.
5. The superseded qualification run ended **143**. The subsequent complete
   attempt crashed **139** while old-worker/new-World generation overlapped.
   Both interrupted campaigns remain historical FAIL/incomplete evidence.
6. Canonical TSan independently established the real shared stronghold cache
   race. B04 attribution remains
   `PREEXISTING_SHARED_CORE_DEFECT_DISCOVERED_BY_I08`, owned by PebbleCore.
   Intermittent canonical native PASS did not erase the race. B04 was developed,
   independently approved and published separately in the chain above.
7. This supervisor-authorized mission reconstitutes the complete corrected I08
   semantics on new canonical, with no replay of historical FAIL commits, and
   requalifies the final source. Previous portal/VGS harness failures and the
   canonical zoo/combat/eight-A* failures remain historical FAIL evidence.

8. Final post-B04 candidate `eab79c7e2723f3aafbbd5bb65c8562b2b911cae8` completed qualification and
   received **PS01_INCREMENT_08_FINAL_INDEPENDENT_REVIEW_PASS**, P0 0 / P1 0 /
   blocking P2 0, safe to publish unchanged. This additive documentation
   reconciliation prepares the exact two-commit local publication chain;
   user push and remote verification remain pending. Earlier FAIL evidence
   stays FAIL.

Original archives remain at
`/Users/nessnow/Dev/pebble-lab-i08-resumed-evidence-20261002` and
`/Users/nessnow/Dev/pebble-lab-i08-b02-evidence-20261002`.
An additive copy of 118 B03/support/TSan text artifacts and their original-path
hash manifest is retained at
`/Users/nessnow/.codex/artifacts/ps01-i08-final-after-b04-20261004/historical-b03-support`.
No original evidence was modified. The supplementary offline validator's own
pre-exit/post-capture boundary and WorldRecord schema diagnostics are retained
separately; they are validator errors, not product qualification failures, and
required no runtime or product-assertion change.

PS01 remains **IN PROGRESS / NOT COMPLETE**. CIV-48 remains
**NOT STARTED / IMPLEMENTATION NOT AUTHORIZED**. Gate H remains **PLANNED**.
I08 is not published. **Push attempted: NO**.

## Historical B02 candidate record — retained verbatim, superseded

<details>
<summary>Historical 8b7b197 local qualification followed by independent-review FAIL</summary>

# PS01 Increment 08 — Blocker 02 correction candidate

Status: **LOCAL REQUALIFIED CORRECTION CANDIDATE — READY FOR INDEPENDENT SENIOR REVIEW — NOT PUBLISHED**.
Mission: `RESOLVE-PS01-I08-BLOCKER-02-POST-PUBLICATION-WORLD-REPLACEMENT-CUSTODY-CANCELLATION`.

Canonical baseline remains `9919e575819dca02ee8e893a37ac9eaaebc36012`.
The independently reviewed candidate is immutable local commit
`066704f53275ca56f863b5911d8799d8072c2196`, tree
`d377fd85a19465423aa4797bbfe03c279177fc12`, sole parent `9919e575`.
Independent disposition: **PS01_INCREMENT_08_INDEPENDENT_REVIEW_FAIL**.
This separate correction supersedes that candidate's prior locally qualified
status without erasing its PASS evidence or the subsequent independent FAIL.
The correction commit/tree are recorded in the external delivery manifest;
this record is part of that new commit, not an amendment to `066704f`.

## Blocker 02 — exact reproduction and attribution

**PS01-I08-BLOCKER-02 — POST-PUBLICATION WORLD-REPLACEMENT CUSTODY CANCELLATION (P1)**.
Classification: **PRODUCT_FAILURE_SEMANTICS_DEFECT**, introduced by the I08
publication/finalization integration, not B01 or mortality checkpoint authority.

The unchanged reviewed debug executable reproduces successful outgoing
publication followed by destination metadata write refusal:
`writes=2 session=true carried=0 escrow=3 ready=true pending=false
hardFailure=false published=true`. The old World/session remains active;
World time advances `52>53` with zero runtime errors; save retry refuses:
`checkpoint save physical probe set is invalid targets=agent_0:entityCollision
overlaps=0`. The original independent review log is preserved verbatim.

Eight forensic checks establish that state. The LLDB driver exits 0 and the
isolated diagnostic process is deliberately killed with exit 9; this is
historical FAIL diagnosis, not qualification. The new regression on unchanged
product owners fails **5 passed / 1 failed, exit 1**, at assertion 6:
`refused replacement returns exact original live custody and civilization`.
Initial correction evidence passes 7/0; expanded development attacks pass 32/0.
Those development snapshots remain separately attributed. Final-source focused
and complete campaigns below supersede them for candidate qualification.

## Lifecycle state-machine audit and correction

Running custody belongs to the original live probes/session. Existing capture
retains the reversible probe snapshots and prior handoff; existing preparation
moves material to protected escrow; Core crosses its synchronous physical
barrier; Pebble publishes the correlated reference. Publication is a durable
snapshot, not final teardown. The reviewed unconditional completion defer
incorrectly discarded compensation before destination admission could refuse.

The correction retains the existing pending record after successful outgoing
publication until verified cancellation or actual session teardown. Core's
transient lifecycle state is idle/prepared/blocked. A prepared decision freezes
Core ticks, civilization updates and another save; repeated preparation retains
one boundary. Destination refusal cancels before returning to the caller.
Verified cancellation returns exact custody to the original probes, retires
live escrow, restores the prior handoff and releases the freeze. An unverifiable
return uses the existing Pebble physical hard-failure latch and blocks Core
progression, save, teardown and retries. No replacement custody or founders are
created. No persistence engine, schema or history authority is added.

| Exit between preparation and finalization | Correct ownership result |
| --- | --- |
| Capture, custody, Core persistence or publication refusal | Existing compensation followed by owner verification; hard-block if verification fails |
| `createWorld` destination metadata write refusal | Deferred verified cancellation; original World/session remains authoritative |
| `loadWorld` initial missing destination | No preparation occurred |
| `loadWorld` missing second read after preparation | Equivalent deferred cancellation |
| Nonempty finalization preflight in create/load/exit | Cancel before teardown; uncertain custody hard-halts the retained owner |
| Successful finalization | Existing stop destroys the old session and discards pending compensation; Core removes remaining empty probes unconditionally |
| Post-teardown removal-count mismatch | Hard invariant, never a recoverable return into a destroyed session |
| Destination restore refusal after old teardown | Outgoing teardown committed; existing new-entry refusal owns the result; no cancellation into the new World |
| Duplicate cancellation | No-op after verified cancellation/committed teardown; refused without mutation after hard failure |

The preflight attack traverses actual `createWorld`: destination metadata
succeeds once, then finalization refuses before teardown. A disclosed duplicate
live stack alongside original escrow is corruption input, not normal product
behavior. The refusal creates no material beyond that input. Separate halted
fault fixtures are never forced through successful cleanup.

## Reference and custody cancellation semantics

The already-published disk checkpoint plus escrow remains a coherent durable
snapshot when live custody returns. Returning custody dirties the live chunks;
the next existing Core physical write atomically invalidates that reference,
exactly as in Save/Continue. No new publication model or explicit invalidation
of a still-coherent snapshot is introduced. The regression proves reference
preservation, next-write invalidation, save retry and subsequent successful
World replacement/ordinary return without duplicated civilization effects.

## Final-source requalification

All commands below run from `/Users/nessnow/Dev/pebble-lab`. Original execution
roots under `/tmp` and their frozen drivers, binaries, logs, reports, runtime
homes, captures and source hashes are retained in:
`/Users/nessnow/Dev/pebble-lab-i08-b02-evidence-20261002`.
The earlier reviewed archive remains immutable at
`/Users/nessnow/Dev/pebble-lab-i08-resumed-evidence-20261002`.

| Exact command (log redirection omitted) | Result | Exit |
| --- | --- | ---: |
| `bash /tmp/ps01-i08-b02-20261002/p1-before/run.sh` | Eight forensic checks confirm historical P1; diagnostic process deliberately killed (9), not qualification | 0 |
| `bash /tmp/ps01-i08-b02-20261002/focused-before/run.sh` | Unchanged owners: 5/1, fails assertion 6 | 1 |
| `swift build --product Pebble` | Final-source debug build, 10.34s | 0 |
| `swift build -c release --product Pebble` | Final-source release build, 194.82s | 0 |
| `swift build -c release --product pebsmoke` | Final-source release build, 0.16s | 0 |
| `bash /tmp/ps01-i08-b02-20261002/focused-final/run.sh` | Focused B02 regression/attacks: 32/0 | 0 |
| `bash /tmp/ps01-i08-b02-20261002/adversarial-final/run.sh` | 42 Core + 102 product fault assertions / 0 | 0 |
| `PEBBLELAB_I08_SKIP_BUILD=1 scripts/verify-pebblelab-ps01-increment-08.sh /tmp/ps01-i08-b02-20261002/qualification-final` | 42 Core + 252 named boundary + 2 deterministic comparisons = 296/0 | 0 |
| `bash /tmp/ps01-i08-b02-20261002/owning-final/run.sh` | Six owning suites: 432/0 | 0 |
| `scripts/verify-pebblelab-live.sh --dry-run --persistence` | Canonical live dry-run | 0 |
| `PEBBLELAB_I08_EVIDENCE_ROOT=/tmp/ps01-i08-b02-20261002/visual-final scripts/verify-pebblelab-ps01-increment-08-live.sh --dry-run` | I08 live dry-run | 0 |
| `PEBBLELAB_I08_EVIDENCE_ROOT=/tmp/ps01-i08-b02-20261002/visual-final bash /tmp/ps01-i08-b02-20261002/visual-final/run.sh` | Fresh rendered two-process product path; eight assertions | 0 |
| `python3 /tmp/ps01-i08-b02-20261002/visual-final/inspect-conservation.py /tmp/ps01-i08-b02-20261002/visual-final` | Four read-only physical conservation assertions | 0 |
| `CFFIXED_USER_HOME=/tmp/ps01-i08-b02-20261002/canonical/home scripts/verify-pebblelab.sh` | FAIL stage 5: 4948/3, exactly three historical failures | 1 |
| `CFFIXED_USER_HOME=/tmp/ps01-i08-b02-20261002/canonical/home bash /tmp/ps01-i08-b02-20261002/canonical/remaining.sh` | Unchanged canonical stages 6–35: 30/30 | 0 |

The full 296 total includes the complete 102-assertion adversarial campaign;
repeated focused runs are not counted as unique additional assertions there.
The owning counts are checkpoint/replay 49, persistence/reconciliation 19,
I07 focused 175, ecological observation 89, agriculture 86, published B01 14;
each exits 0. No owning authority used by I07 natural renewal was changed, so
its entire historical long renewal campaign was not rerun.

Normal 20/30 founder envelope writers/readers pass 6+9 each; deterministic
24-founder A/B writers/readers pass 6+9 each plus two exact comparisons.
Receipt retention passes 11+9, standalone manual retention 12+9, natural
positive 7+10, scarcity 6+9, genuine natural zero 8+9. Semantic equivalence
uses the existing durable checkpoint and physical boundary, not byte identity
of derived/transient runtime structures.

Natural positive seed 14 saves at World 9657 / civilization 1921 with five
acquired/carried food items; fresh ordinary entry restores all five and then
consumes four. Seed 46 non-extinct state saves at World 1252 / civilization 240.
Natural seed-46 extinction reaches World 27652 / civilization 1380, then
crosses Save/Continue, Save/Exit and fresh-process entry with population zero,
unchanged durable digest and no founder creation. It advances to 1381 while
remaining zero. No deaths, empty civilization or expected results are injected.

## Visual Game Smoke V5 and executable attribution

All three final-source captures were inspected. Before-save and restored
frames show rendered natural forest/water/terrain and situated Pebbles; the
Observer is closed and loading is absent. The continued frame is naturally
night-dark with terrain and Pebbles still visible. All three report 1824
uploaded sections, nine ready surface chunks and positive target geometry.
The driver exits 0, not merely an application PASS marker.

World `wmuqv3cuff3ya`, civilization `live-14-208-67--32`: before-save tick
1921 carries four items; restore capture tick 2162 has consumed five; continued
capture tick 2402 has consumed seven and carries two. Read-only inspection of
the final Core-selected checkpoint verifies **9 acquired = 7 consumed + 2
carried**, complete retained evidence, natural physical provenance and exact
live/manifest agreement. The reader creates zero founders.

Final release Pebble SHA-256:
`d0d5f9f5e79d865b9a1c8c9daab4cd6763eabb9cf0b2623f5c5e95897f9a8225`.
Final native release pebsmoke SHA-256:
`e05d0d8a6fb4d76255149ae396687834f51bb5dd2c04c64b44a21463848c25b8`.
Debug focused Pebble SHA-256:
`06366858b8fffa77897bfa58cf16dc305d8a3d61e6e0554d96ecaff83817dcfa`.
Source/script hashes remained frozen across final qualification and are
checked against the delivered runtime source. Canonical native PebbleLab is
also archived. A Python/Rosetta archive helper initially selected cached
x86_64 files via its Swift bin-path subprocess; those copies are explicitly
preserved under `canonical/nonqualification-x86_64-copy`, not attributed to
any campaign. `canonical/native-executable` contains the actual native files.

## Historical evidence, limits and project status

Canonical remains **FAIL**, not PASS, solely on the historical zoo bit-identical,
combat lockstep and eight A* node-identical comparisons. No regold, golden
regeneration or weaker comparison occurred. The independent P1 and failed
before-correction regression remain FAIL. A development release build was
interrupted (130) before qualification; its source/build logs remain separate.
Earlier source snapshots are never reattributed to the final corrected binary.

B01 remains **BLOCKER_FIX_PUBLISHED**; its source and published documentation
are unchanged. Portal remains **HARNESS_ASSERTION_DEFECT** and the prior VGS
issue **HARNESS_CAPTURE_READINESS_DEFECT**. Historical failed captures and
wrapper failure remain preserved in the earlier archives. No new contradiction
or architecture blocker was found.

Qualification is bounded to the approved normal paths, 20/24/30 founder envelope
and two natural conditions. Arbitrary crash recovery, historical migrations,
higher capacities and institutional mechanics remain out of scope. Existing
B01 bounded-history trust risks remain unchanged and non-blocking.

I08 is a **local requalified correction candidate**, not independently approved
or published. PS01 remains **REQUIRED — IN PROGRESS / NOT COMPLETE**.
CIV-48 remains **NOT STARTED — IMPLEMENTATION NOT AUTHORIZED**. Gate H remains
**PLANNED**. The user is the sole publisher. **Push attempted: NO**.

## Reviewed candidate record — superseded, retained verbatim

<details>
<summary>Historical local candidate 066704f — independently reviewed FAIL</summary>

# PS01 Increment 08 — Normal World/Civilization Save-and-Continue Continuity

Status: **LOCAL QUALIFIED CANDIDATE — READY FOR INDEPENDENT SUPERVISOR REVIEW — NOT PUBLISHED**.
Mission: `RESUME-PS01-INCREMENT-08-AFTER-PUBLISHED-BLOCKER-01`.
Canonical parent: `9919e575819dca02ee8e893a37ac9eaaebc36012`, following
`79517ab038ff6b33326fd8d38595cb30fe906c8c` → published shared B01 correction
`781329891411a883f62bc0b818b47f29e908bd9d` → documentation publication `9919e575`.

PS01 remains **REQUIRED — IN PROGRESS / NOT COMPLETE**. CIV-48 remains
**NOT STARTED — IMPLEMENTATION NOT AUTHORIZED**. Gate H remains **PLANNED**.
The user remains the sole publisher. No push is authorized.

## Lossless reconciliation

The initial nine tracked modifications and six untracked files matched all 15
preserved blocked-candidate hashes. External safety evidence is retained at
`/Users/nessnow/Dev/pebble-lab-i08-resume-safety-20261002`, including the exact
files, modes, status and binary tracked diff. Stash
`b7c6fbee386853f17fdaa5d18a43dbb033f6169c` remains retained.

The branch was fast-forwarded to `9919e575`, then the candidate was reapplied
without a merge or candidate commit. Twelve files remained byte-identical;
the other three (`main.swift` in Pebble and pebsmoke, and DOCUMENTATION_INDEX)
retained canonical B01 additions alongside the original I08 content. Removing
only those additions reconstructs every original candidate file exactly.
Published B01 authority and documentation remain unchanged in this increment.

## Current architecture and semantics

The original bounded I08 architecture is retained. Core owns the existing
SQLite World persistence and its physical revision. Pebble stages an existing
checkpoint bundle in one of two reserved slots, validates it, performs the
existing physical-custody handoff, crosses Core's synchronous save barrier,
then publishes a correlated opaque reference against that exact revision.
Physical writes invalidate the reference in the same SQLite statement.

Save/Continue returns verified custody to the same live probes without
replacing the session. Save/Exit finalizes only after successful publication.
Ordinary matching World entry restores the existing checkpoint through its
transactional loader before Core progression, with no founder bootstrap.
Zero population remains zero. Dimension travel is refused before destination
preparation while this dimension-bound continuation is required.

Capture, handoff, Core persistence and publication failures refuse destruction
and compensate live custody. An unverifiable compensation halts the session.
Partial durable World writes can remain after refusal, but invalidate any
usable continuation reference; the retained live state owns retry. Missing,
corrupt, stale, incompatible or unreconcilable evidence blocks World progression,
saving and replacement founders. This is bounded fail-closed coordination,
not arbitrary crash recovery or historical-save migration.

Durable civilization identity/state follows the existing checkpoint authority.
Material follows Core custody and Pebble reconciliation. Physical probe
incarnations, timing credit and caches retain their existing reconstructible,
derived or transient semantics; they do not become new durable authority.
The receipt compatibility change preserves current receipts and standalone
manual checkpoint history while allowing obsolete ordinary-boundary evidence
to retire and invalidate its obsolete reference.

## Resolved resumption blockers

B01 is closed and published. The same genuine seed-46 / 24-founder terminal
I08 product path now passes ordinary capture, save/exit and fresh-process
re-entry: **8 writer + 9 reader assertions, exit 0**. The terminal civilization
is at tick 1380 / World tick 27652, durable digest
`80e92cdcf8878b473210a5a8eda4e91948992265689b89bd0d707000a03b12e3`.
It progresses to tick 1381 without resurrection. No synthetic empty state,
injected death, replacement founder or manual checkpoint sequence is used.

Portal classification: **HARNESS_ASSERTION_DEFECT**. The original input passed
raw block ID 623 to Core's encoded-cell API, producing actual block ID 38.
No portal operation occurred. Only `portalCooldown == 200` was false; bindings,
dimension, World identity and custody were unchanged. An isolated run had no
error before or after. The full run's printed JSON-decoding error was retained
from an earlier corrupt-metadata attack. Core portal refusal does not own that
controller diagnostic. No errors were cleared or product semantics relaxed.

The harness now uses `cell(B.end_portal)` and verifies that the real portal
intersects the Player AABB. The original refusal assertion is unchanged.
Corrected isolated evidence is **9/0, exit 0**; the complete release campaign
is **34 Core + 56 adversarial assertions, all passing, driver exit 0**.
Historical isolated **5/1** and full **52/1** failures remain failures.

Visual classification: **HARNESS_CAPTURE_READINESS_DEFECT**. A diagnostic entry
restored valid physical/civilization state, but the LoadingScreen timed out
with zero GPU terrain sections and generated, unlit neighbors. The old I08
reader/resave stage froze World ticks before normal lighting could finish.
Its absence-of-loading-screen / one-frame gate accepted an unrendered scene.
Missing terrain before save was therefore not established as a restore defect.

The launch-gated visual harness now permits ordinary World progression until
existing lit surface meshes around the subject are uploaded, then freezes only
for capture. It waits for ordinary presentation commands to finish. The existing
compact overlay and GUI-scale option leave the phenomenon visible. No renderer,
World-generation or cognitive authority changes were introduced.

## Visual Game Smoke V5 — current PASS

Both launchers received dry-runs before the clean campaign. The frozen visual
writer/reader driver exited **0**, with **8 explicit readiness, identity and
continuity assertions**. All three 3024×1898 captures were visually inspected.
Natural lake/shoreline/tree terrain and situated Pebbles are visible before
save and after fresh-process restore; continued operation remains rendered,
including the natural night transition. The Observer is closed.

| Boundary | World tick | Civilization tick | Consumed | Evidence |
| --- | ---: | ---: | ---: | --- |
| Before save | 9671 | 1921 | 0 | Four naturally acquired berries; Save/Continue and Save/Exit pass |
| Exact restore entry | 9671 | 1921 | 0 | Four berries adopted from two protected spills; zero duplicates; no founders |
| Ready after-restore capture | 10876 | 2162 | 5 | Same natural World and civilization; uploaded terrain |
| Continued capture | 12076 | 2402 | 7 | Ordinary food use increases; two berries remain; final clean exit |

World identity: `wmuqm0qj4db33`. Civilization: `live-14-208-67--32`.
Entry durable/reconciled digest equals writer digest
`6e0bfea716d8d43b6a24429f8d95bb56d1c7cf209964552c0df158b7814c2fb2`.
Each capture reports 1824 uploaded sections and nine ready surface chunks.
Read-only final checkpoint inspection passes four additional conservation
assertions: four canonical physical harvest outcomes total nine berries, exactly
seven consumed plus two carried. The camera is render-only; Player mutation is none. Fresh entry precedes
ordinary visual preparation/progression; the later ready capture is not
presented as a tick-zero screenshot.

Frozen visual executable SHA-256:
`d37424d3e93f3f5eef2f726b4a90093a7626044fbffb0e5c04d45ee1f4e3c0f5`.
Historical Visual-03/04 remain unacceptable qualification evidence. The prior
complete driver exit 127 remains FAIL. The new diagnostic was deliberately
terminated after diagnosis (143) and is not qualification evidence.

## Final comprehensive qualification

All five required I08 categories have current evidence: persistence/restart,
deterministic headless, live product path, adversarial QA and Visual Game Smoke
V5. The canonical regression remains **FAIL**, with only its three explicitly
attributed historical failures. This candidate is not published or supervisor
approved.

The complete frozen campaign passes **242 assertions**: 34 Core, 206 named
product-boundary assertions and two deterministic comparisons. It covers
Save/Continue without replacing the running civilization, Save/Exit followed
by fresh-process entry, the 20/24/30 founder envelope, ordinary and manual
receipt retention, positive natural custody, seed-46 scarcity, and genuine
natural extinction. Every reader restores before first progression, creates
zero founders, refuses duplicate restoration, and verifies exact durable and
causal digests plus conserved population/material.

The seed-14 positive writer reaches civilization tick 1921 with five naturally
acquired/carried berries. Fresh entry restores that exact boundary, digest
`374b22dc92daa027fc74de98867b4f0835f5316f114b79e3addb00c409be29f6`,
then consumes four berries through ordinary subsistence by tick 1924. The
seed-46 scarcity case carries no material and continues without manufacturing
food. The terminal seed-46 case again restores tick 1380 with zero population,
the same terminal digest as the initial minimal B01-dependent run, and advances
to tick 1381 without resurrection.

Deterministic A/B runs compare the full normalized boundary reports and the
post-restart continuation reports exactly. Checkpoint durable state and causal
evidence restore exactly; physical probe incarnations and process-local timing
or caches are not asserted byte-identical. This follows the existing owning
checkpoint/custody semantics rather than adding durable cache authority.

The final coverage audit added a test-only escrow helper and call to the
existing fault campaign. Removing those two additions reconstructs the
comprehensive-run harness byte-for-byte. All 13 other candidate files except
the evidence document are unchanged, including every product owner, the
visual path and both launchers. The full final release adversarial rerun passes
**34 Core + 74 fault assertions, driver exit 0**. These counts describe separate
executions; they are not added to 242 as if they were unique assertions.

The added attacks remove a real persisted escrow stack or duplicate its token
using a distinct Core-allocated entity identity. A disclosed adversarial
revision correlation reaches the existing strict custody validator. Missing
escrow refuses with `checkpoint-bound escrow is absent`; duplicated escrow
refuses with `duplicate token`. Neither publishes a session, permits time or
save, or overwrites retry evidence. Repairing the original physical component
restores the exact tick/digest and three controlled fault-test berries, with
no founder or duplicate effect. These are adversarial inputs, not normal
product provisioning.

The first added-test build failed on immutable identity/type misuse; the next
release attempt exited 133 because the harness accessed `GameCore.world` after
ordinary exit had legitimately cleared it. Both failed artifacts remain
preserved. Core identity allocation now occurs before exit. The corrected
debug and release campaigns each pass all 34 + 74 assertions; no product
authority was relaxed. Final debug/release builds exit 0 (12.44s / 206.53s).

Evidence is externally archived at
`/Users/nessnow/Dev/pebble-lab-i08-resumed-evidence-20261002`. Exact executed
commands below use the original runtime root; wrappers, binaries, source
hashes, logs, saves, captures and source-control comparisons are retained in
the corresponding archive subdirectories. Drivers were frozen before use.

| Executed command | Passed / failed | Exit |
| --- | --- | ---: |
| `bash /tmp/ps01-i08-resume-20261002/zero/run.sh` | 8 writer + 9 reader / 0 | 0 |
| `bash /tmp/ps01-i08-resume-20261002/portal-corrected/run.sh` | 9 / 0 | 0 |
| `bash /tmp/ps01-i08-resume-20261002/adversarial-01/run.sh` | 34 Core + 56 faults / 0 | 0 |
| `scripts/verify-pebblelab-live.sh --dry-run --persistence` | Launcher contract dry-run | 0 |
| `PEBBLELAB_I08_EVIDENCE_ROOT=/tmp/ps01-i08-resume-20261002/visual-01 scripts/verify-pebblelab-ps01-increment-08-live.sh --dry-run` | I08 visual dry-run | 0 |
| `PEBBLELAB_I08_EVIDENCE_ROOT=/tmp/ps01-i08-resume-20261002/visual-01 bash /tmp/ps01-i08-resume-20261002/visual-01/run.sh` | 8 driver assertions / 0; four additional read-only conservation assertions | 0 |
| `PEBBLELAB_I08_SKIP_BUILD=1 scripts/verify-pebblelab-ps01-increment-08.sh /tmp/ps01-i08-resume-20261002/qualification-final` | 242 / 0 | 0 |
| `bash /tmp/ps01-i08-resume-20261002/owning/run.sh` | 432 / 0 | 0 |
| `CFFIXED_USER_HOME=/tmp/ps01-i08-resume-20261002/canonical/home scripts/verify-pebblelab.sh` | 4940 / 3; stops at stage 5 | 1 |
| `CFFIXED_USER_HOME=/tmp/ps01-i08-resume-20261002/canonical/home bash /tmp/ps01-i08-resume-20261002/canonical/remaining.sh` | All 30 remaining canonical stages 6–35 | 0 |
| `bash /tmp/ps01-i08-resume-20261002/escrow-debug/run.sh` | 34 Core + 74 faults / 0 | 0 |
| `bash /tmp/ps01-i08-resume-20261002/escrow-qualified/run.sh` | 34 Core + 74 faults / 0 | 0 |

Owning suites use the archived release `pebsmoke` with isolated
`CFFIXED_USER_HOME` and `PEBBLELAB_SMOKE_ONLY`: checkpoint/replay **49**,
persistence/reconciliation **19**, I07 focused **175**, ecological observation
**89**, agriculture **86**, and published B01 compaction regression **14**.
All six suites exit 0 with zero failures.

Canonical builds pass for debug, release Pebble, PebbleLab and pebsmoke.
Its only failed comparisons remain `zoo: 55 mob types × 200 ticks bit-identical
(3 checkpoints)`, `combat: player + 5 mobs, damage/knockback in lockstep`, and
`8 A* paths node-identical`. No golden or comparison changed. The supplemental
wrapper retains the exact canonical stages 6–35 body and does not turn the
main exit 1 into PASS.

The natural, deterministic and visual runs used frozen Pebble SHA-256
`d37424d3e93f3f5eef2f726b4a90093a7626044fbffb0e5c04d45ee1f4e3c0f5`.
The final additive release attack campaign uses
`648a8f6fbcd87ebcc39819493916d2aa700949dd046580eeab06ec0694164459`.
The owning and canonical suites used the same runtime sources. Release
pebsmoke is unchanged:
`f72e53986b92e584b6817190504c53cb2cfd9d94032a5ada5ba96d97afcf5f5e`.
The archive's source-control proof precisely scopes the test-only difference;
the earlier runs are not attributed to the later executable.

## Candidate delivery scope

One coherent I08 candidate is based directly on `9919e575`, containing these
15 paths. Commit SHA/tree/parent and final Git state are recorded externally
with the delivery, avoiding a self-referential commit identifier in this file.

- `Sources/Pebble/PebbleAgentController+Lifecycle.swift`
- `Sources/Pebble/PebbleAgentController+Persistence.swift`
- `Sources/Pebble/PebbleAgentController+WorldContinuation.swift`
- `Sources/Pebble/PebbleAgentController.swift`
- `Sources/Pebble/PebbleIncrement08ContinuationHarness.swift`
- `Sources/Pebble/PebbleWorldEcologicalObservationReceiptStore.swift`
- `Sources/Pebble/main.swift`
- `Sources/PebbleCore/Game/GameCore.swift`
- `Sources/PebbleCore/Game/Saves.swift`
- `Sources/pebsmoke/PebbleCoreWorldContinuationSmoke.swift`
- `Sources/pebsmoke/main.swift`
- `docs/pebblelab/DOCUMENTATION_INDEX.md`
- `docs/pebblelab/PS01_INCREMENT_08_NORMAL_CONTINUITY.md`
- `scripts/verify-pebblelab-ps01-increment-08-live.sh`
- `scripts/verify-pebblelab-ps01-increment-08.sh`

The external safety copy and stash remain retained after verification.
Push attempted: **NO**.

## Scope and residual limits

No food/growth, navigation, cognition or demographic authority was changed.
I07's full expensive natural-renewal campaign is not repeated; focused owning
checks, current-custody continuation and B01's published regression are used.
No regold, regenerated golden or weakened comparison is permitted.

No support above 30 active roots, unlimited duration, arbitrary crash recovery,
historical-save migration, multi-dimensional civilization, general time-control
redesign or institutions is claimed. B01's documented bounded-history trust
risks remain inherited and unchanged. PS01's remaining integration and
characterization questions remain for subsequent supervisor review.

## Historical blocked candidate record — immutable attribution

The original stopped record follows verbatim. Its baseline, blocker status,
unknown diagnoses and failed qualification describe the **pre-B01 blocked
candidate**, not this resumption. Its externally preserved evidence remains at
`/Users/nessnow/Dev/pebble-lab-i08-evidence/blocked-candidate`.

<details>
<summary>Original blocked record (historical)</summary>

# PS01 Increment 08 — Normal World/Civilization Save-and-Continue Continuity

Status: **BLOCKED LOCAL IMPLEMENTATION — QUALIFICATION FAILED / INCOMPLETE — NOT PUBLISHED**.
The supervisor approved selection and authorized the bounded implementation in
`IMPLEMENT-PLAYABLE-SLICE-01-INCREMENT-08-NORMAL-WORLD-CIVILIZATION-CONTINUITY`.
Published canonical baseline remains
`79517ab038ff6b33326fd8d38595cb30fe906c8c` (parent
`373b5e3688d25e1e139dd735a76d48e38743c1f8`, subject
`docs(ps01): record increment 07 publication`). Implementation branch:
`codex/ps01-increment-08-normal-continuity`.

PLAYABLE SLICE 01 remains **REQUIRED — IN PROGRESS / NOT COMPLETE**.
CIV-48 remains **NOT STARTED — IMPLEMENTATION NOT AUTHORIZED**; Gate H remains
**PLANNED**. This record does not canonize publication or PS01 completion.

## Contract blocker and stop

Implementation stopped under the mission's explicit contract-blocker rule.
The normal seed-46, 24-founder extinction campaign reached zero active agents
without injected deaths or replacement state. Its next ordinary save refused:

```text
normal continuation capture refused: refused("PebbleAgents checkpoint command failed: checkpoint bound exceeded: mortality causal chain")
```

The required zero-population future continuation was therefore not established.
The current checkpoint authority rejects the naturally produced terminal state;
I08 cannot satisfy that acceptance condition by merely wiring the existing
checkpoint loader. The code remains fail-closed. No empty replacement
civilization was synthesized and no validator, golden or owning proof was
weakened.

`AgentCheckpoint.swift` uses this same error for missing mortality-chain events
that do not satisfy its retained-history contract and for a compound predicate
checking kinds, actors, causes, sequence ordering and post-finalization mortality
events. **The exact failing predicate is unknown.** The error does not establish
that a numerical history bound was exhausted. The owning PebbleAgents code is
unchanged in this candidate; that alone does not settle the root cause or
exclude an integration interaction.

The smallest recommended correction to the mission is a focused investigation
of normal cohort extinction against the existing mortality/checkpoint contract,
followed by the smallest owning compatibility correction if warranted, retaining
strict causal admission and existing identities. Then resume I08 qualification.
This record does not authorize that correction or substitute a synthetic
zero-population fixture for the failed normal trajectory.

Two additional acceptance issues remain: the final portal adversarial assertion
failed, with its exact failed condition unresolved; and rendered evidence did
not establish credible immediate World visibility after restore. They require
resolution before any ready claim, independently of the mortality blocker.

## Problem and ownership audit

Ordinary Core exit already prepared physical custody, synchronously saved the
World, then finalized Pebble's session. Existing checkpoint loading required
an active session; I07's fresh-process reader explicitly constructed founders.
Normal World re-entry therefore lacked its matching civilization continuation.

The implementation retains Core's save queue, pending capture horizon,
WorldRecord, SQLite database, physical identity allocation and lifecycle
barriers. It retains the existing Pebble checkpoint codec, immutable checkpoint
bundle store, World binding, custody escrow tokens, collective placement,
reconciliation, verification and rollback. PebbleAgents and
AgentSimulationSession remain unchanged, as do Observer/Chronicle authorities.

## One coherent continuation boundary

Pebble stages an existing checkpoint bundle, prepares existing tagged physical
custody handoff, asks Core to synchronously save, then publishes an opaque
checkpoint reference against Core's current physical persistence revision.
The reference also protects WorldRecord identity/state, checkpoint identity,
manifest integrity and the normal-founder product policy. At most two reserved
ordinary checkpoint slots are used; manual commands cannot operate those slots.

A SQLite trigger invalidates the reference in the same statement as every
later World, Player, advancement, chunk or physical-receipt write, including
streaming. A failed/partial World save therefore cannot leave an older
civilization reference selected against newer physical state. Compare-and-
publish refuses an intervening physical write. The existing World record
retains a generic external-continuation requirement so missing reference
metadata does not silently become a civilization-free World.

This is coordinated, fail-closed publication rather than a new persistence
engine or a promise of arbitrary crash recovery. Partial physical writes may
remain durable after refusal; no torn continuation is exposed. The retained
live World/session is the retry authority until a new complete boundary is
published. The previous successful pair remains selected only while its
physical revision remains unchanged.

Save while remaining in the World returns verified escrow custody to the same
live probes, with the same civilization and causal state. The disk boundary
retains checkpoint-protected escrow for future adoption. A successful exit
finalizes only after publication; probes remain nonpersistent.

World entry restores through the existing checkpoint loader with an absent
current session, before the first physical or cognitive tick. It restores the
normal-founder policy without constructing any founders, materializes bounded
saved cells through Core, verifies binding and placement, adopts exact tagged
custody once, and publishes the restored session only after verification.
The restore code has no empty-population founder fallback; the initial-founder
policy is not a roster. Natural zero-population save/restore qualification is
blocked as described above. The restored movement-validation
guard derives from saved movement policy/history; no founder-start side effect
is needed. Save while remaining also preserves pending scheduler credit.

## Durable and transient state

The existing checkpoint defines civilization identity, durable cognition,
domain gates, needs, causal history, retained uncertainty and ongoing work.
Physical custody is Core material reconciled by Pebble; its manifest evidence
never creates free material. WorldRecord and physical saves remain Core truth.
Normal policy/count and checkpoint orchestration retain their existing product
meaning. Anchor/coverage derive from checkpoint and current physical roots.

Probe objects/physical incarnation IDs, render camera, credit, sensor caches,
executor diagnostics and process-local timing are not new durable authority.
The existing loader reconstructs or invalidates those structures. Reconciliation
and physiological rebase retain their owning contracts; semantic equality is
required at the boundary appropriate to those authorities, not byte equality
of process-local objects. Normal PS01 without reconciliation effects is checked
for exact durable-state and causal-digest equality on entry.

## Receipt-retention compatibility

Ordinary continuation bundles are correlated with one exact physical revision;
they are not independently loadable historical checkpoints. Existing receipt
retention protects all current candidate receipts and all valid standalone
manual checkpoints. It now excludes the reserved ordinary slots from the
historical-checkpoint scan. Any later receipt removal invalidates the ordinary
reference in the same SQLite statement. This cannot remove a receipt needed by
the current candidate; a new save validates and captures the current evidence.

The narrow compatibility change also avoids repeatedly decoding two ordinary
autosave bundles during every cognitive transition. A progress sample exposed
that otherwise unnecessary work during the initial natural campaign. Focused
qualification checks ordinary obsolete receipt retirement, continued protection
of current receipts, unchanged manual checkpoint protection, coherent retry and
fresh-process restore. Core ecological, agricultural and physical receipt
owners retain their contracts; no food/growth/renewal mechanic changes.

## Refusal and retry

Capture, custody, World-write and late-publication failures refuse destruction.
Verified custody return restores the current physical incarnation before retry.
Missing/corrupt/stale metadata or checkpoint components, incompatible World or
dimension, unavailable placement, duplicate restore and reconciliation failures
refuse publication. A refused World entry cannot tick, save or create replacement
founders; returning to title preserves its durable evidence for a later retry.
The durable requirement also forces coupled saving when the live session is
unexpectedly missing; physical-only fallback cannot report success. Dimension
travel would clear the bound probes under Core's existing contract, so portals
refuse before destination preparation while continuation is required. Respawn
uses the bound current dimension when an old bed/anchor points elsewhere. This
is refusal of an incompatible dimension, not multi-dimensional civilization
support. No arbitrary legacy migration or crash-recovery subsystem is introduced.

## Non-goals

No demographic/reproduction/food-pressure changes; no agriculture, productive
economy, knowledge/culture, migration, general time controls or acceleration;
no support above 30 roots, unlimited duration, arbitrary historical migration,
CIV-48, organizations, institutions or Gate H. Autosave uses the same coherent
boundary because it already writes the ordinary World; no new autosave feature
or UI is introduced.

## Qualification

All categories are required: persistence/restart, deterministic headless,
live product path, adversarial QA and Visual Game Smoke V5. Qualification
failed / remains incomplete; results are recorded below. No goldens were
regenerated or weakened.

The bounded campaign includes natural 24-founder seed-14 nonempty custody and
fresh-process re-entry without a founder or checkpoint command; seed-46
scarcity; focused 20/24/30 envelope; natural zero population; deterministic
repeat; controlled failure custody separately disclosed; owning Core lifecycle
suites; canonical verifier; and rendered save/restore/continued food use.
I07's entire natural-renewal campaign is not repeated: this candidate does not
change Core food/growth, navigation or cognition authorities. The published
three known full-smoke failures retain their historical attribution.

## Qualification provenance

The frozen normal-path campaign uses build 12 in isolated copied executables.
The later missing-session and dimension guards only add refusal for paths
absent from that campaign: its session remains active and its dimension remains
unchanged. The active-session save branch and normal restore/custody behavior
are unchanged. Those guards received a separate final-build adversarial run and
canonical gate rerun; the adversarial run failed as recorded below.
No food, growth, movement, cognition, checkpoint codec,
World correlation or receipt-retention behavior changes after build 12.
The final build also received a two-process rendered resave/re-entry of the
actual successful normal seed-14 World boundary, including its remaining two
naturally acquired berries and preserved fear/safety priority. No founder-start
command or productive fixture is used. The additional observational continuation
checks enabled ordinary subsistence and physical progression; it does not force
another food outcome. The original primary natural read still requires and
establishes actual consumption. Captures wait for the normal LoadingScreen to
close; the Observer pane is closed. Inspection nevertheless found that terrain
was not visible in the immediate boundary captures. Closing the LoadingScreen
did not establish rendered World readiness.

## Commands, counts and outcomes

Evidence is preserved outside the repository at
`/Users/nessnow/Dev/pebble-lab-i08-evidence/blocked-candidate/`.
Its README records archive scope, original paths, binary identities, source
hashes, cleanup and failures. Early and superseded failures remain failures.

Each owning suite used a separate isolated home:

```sh
CFFIXED_USER_HOME=/tmp/ps01-i08-owning-final/home-checkpoint-replay PEBBLELAB_SMOKE_ONLY=checkpoint-replay .build/arm64-apple-macosx/release/pebsmoke
CFFIXED_USER_HOME=/tmp/ps01-i08-owning-final/home-reconciliation PEBBLELAB_SMOKE_ONLY=persistence-reconciliation .build/arm64-apple-macosx/release/pebsmoke
CFFIXED_USER_HOME=/tmp/ps01-i08-owning-final/home-increment07-focused PEBBLELAB_SMOKE_ONLY=ps01-increment-07-focused .build/arm64-apple-macosx/release/pebsmoke
CFFIXED_USER_HOME=/tmp/ps01-i08-owning-final/home-ecological-observation PEBBLELAB_SMOKE_ONLY=ecological-observation .build/arm64-apple-macosx/release/pebsmoke
CFFIXED_USER_HOME=/tmp/ps01-i08-owning-final/home-agriculture PEBBLELAB_SMOKE_ONLY=agriculture .build/arm64-apple-macosx/release/pebsmoke
```

| Owning suite | Result |
| --- | --- |
| Checkpoint/replay | 49 passed / 0 failed |
| Persistence reconciliation | 19 passed / 0 failed |
| Increment 07 focused | 175 passed / 0 failed |
| Ecological observation | 89 passed / 0 failed |
| Agriculture | 86 passed / 0 failed |

```sh
scripts/verify-pebblelab-ps01-increment-08.sh /tmp/ps01-i08-qualification-02
```

The frozen build-12 campaign exited **1**, with **221 passed assertions and
one failed assertion** before termination: 31 Core focused assertions plus 190
named live-boundary assertions. It did not execute the zero-population reader
or reach its terminal deterministic comparison / overall PASS.

| Bounded case | Writer / reader passed assertions | Evidence |
| --- | --- | --- |
| Controlled fault custody | 52 / not a fresh-process reader | Explicitly provided three berries; separate from natural proof |
| 20 founders, seed 46 | 6 / 9 | Ordinary save/exit and fresh entry |
| 30 founders, seed 46 | 6 / 9 | Ordinary save/exit and fresh entry |
| 24 founders, deterministic A and B | 6 / 9 each | Durable digest and causal boundary equality on entry |
| Natural receipt retention | 11 / 9 | Current evidence protected; obsolete ordinary evidence retired |
| Manual history retention control | 12 / 9 | Standalone checkpoint evidence remains protected |
| 24 founders, natural seed 14 | 7 / 10 | Five naturally acquired berries restored; four consumed afterward; zero founders created on entry |
| 24 founders, natural seed 46 scarcity | 6 / 9 | No food fixture; empty custody remains empty; progression resumes |
| Natural zero population, seed 46 | 5 passed, next assertion failed / not run | Mortality causal-chain admission refuses save |

A subsequent read-only comparison of the already emitted A/B JSON reports
found exact paired-boundary and post-restart equality. That comparison is
separate evidence; it does not convert the failed full campaign to PASS.

```sh
bash /tmp/ps01-i08-final-guards.sh /tmp/ps01-i08-final-guards-02
```

The frozen build-17 guard campaign exited **1**: Core **34/34** passed
(20 I08 checks and 14 existing CIV-45 C07/C08 checks); fault assertions **52
passed, then assertion 53 failed** at incompatible portal travel. Later
assertions and remaining normal cases were not run. The last printed
`lastError` was left by an earlier intentionally corrupt-metadata attack; it
does not diagnose the portal failure. A later harness-only diagnostic edit
builds in debug but was not executed or release-qualified before the stop.

```sh
CFFIXED_USER_HOME=/tmp/ps01-i08-canonical-home scripts/verify-pebblelab.sh
CFFIXED_USER_HOME=/tmp/ps01-i08-canonical-home bash /tmp/ps01-i08-canonical-remaining.sh
```

The final canonical command exited **1** at step 5: **4926 passed / 3 failed**.
The three names match I07's published historical full-smoke failures: zoo
bit-identical, combat lockstep and eight A* paths node-identical. No new failure
name appeared in that suite; this is still a failing canonical gate.
The separately disclosed supplemental run of the original steps 6–35 passed
**30/30 stages** on the earlier frozen candidate. It neither bypasses step 5
nor establishes a final full-gate PASS. The verifier and goldens are unchanged.

## Live evidence and Visual Game Smoke V5

The canonical launcher dry-run and each rendered launcher's dry-run completed
before execution:

```sh
scripts/verify-pebblelab-live.sh --dry-run --persistence
PEBBLELAB_I08_EVIDENCE_ROOT=/tmp/ps01-i08-visual-03 scripts/verify-pebblelab-ps01-increment-08-live.sh --dry-run
PEBBLELAB_I08_EVIDENCE_ROOT=/tmp/ps01-i08-visual-03 scripts/verify-pebblelab-ps01-increment-08-live.sh
PEBBLELAB_I08_EVIDENCE_ROOT=/tmp/ps01-i08-visual-04 bash /tmp/ps01-i08-final-rendered-reentry.sh --dry-run
PEBBLELAB_I08_EVIDENCE_ROOT=/tmp/ps01-i08-visual-04 bash /tmp/ps01-i08-final-rendered-reentry.sh
```

Visual-03's two-process launcher exited **0**, establishing its asserted normal
product save/continue, save/exit, matching World entry, exact four-berry custody
adoption and later five consumed berries. The reader created zero founders,
used no checkpoint-load command and ended with zero probes. Its captures
failed visual qualification: the Observer pane obscured the physical result,
and the restore capture showed the LoadingScreen.

Visual-04 used a read-only copy of the actual successful Visual-03 saved World
and its matching checkpoint, retaining two naturally acquired berries. Both
fresh processes emitted their normal product PASS marker: existing simulation
identity `live-14-208-67--32`, World `wmupuqczcjbzu`, 24 living roots, zero
founders created, subsistence enabled, successful ordinary save/continue and
save/exit, zero final probes. Resave stayed at civilization tick 2161;
observation reached tick 2401 and consumed count rose from 5 to 7. No productive
fixture or expected result was injected. This is supplementary observed
behavior, not a second independently qualified launcher.

The complete Visual-04 command exited **127** after the running helper script
was edited, causing `erve: command not found`. Both app PASS markers do not
override that harness failure. All three captures were subsequently inspected:
before-save and immediate after-restore show actors/HUD against sky with no
rendered terrain; the later continued capture shows the natural forest/lake
and actors. Exact cause of missing immediate terrain is unresolved. Therefore
**Visual Game Smoke V5 is FAIL / NOT QUALIFIED**, even apart from the driver
failure. Camera telemetry reports render-only authority and unchanged Player.

Controlled proof scenario executed: **YES**. Normal-world scenarios executed:
**YES**, seed 14 natural food and seed 46 scarcity/extinction, with focused
20/24/30 founder bounds. Temporal telemetry inspected: **YES**. Pebble client
launched: **YES**. Real rendered World captured: **YES**. Representative
screenshots inspected: **YES**. Visual anomaly found: **YES**. Screenshot paths
are the archived `visual-03/captures/` and `visual-04/captures/` files.
Process cleanup verified: **YES**, no Pebble/PebbleLab/pebsmoke process remained
at final inspection. Successful rendered exits report `probesFinal=0`.
Disposable durable Worlds, including refused attempts, are retained as evidence;
they were not silently deleted or treated as repaired continuations. The failed
zero attempt's live terminal session was not checkpointed and cannot be claimed
as a retained zero-population restore artifact.

## Local Git and delivery

Starting implementation parent and final HEAD:
`79517ab038ff6b33326fd8d38595cb30fe906c8c`.
HEAD tree: `70218a4d58875622b6d3c0dd75c998d7458341c6`.
Exact canonical remote was fetched and reverified unchanged at stop.
The blocked work remains uncommitted on
`codex/ps01-increment-08-normal-continuity`: nine modified files and six new
files. There is no candidate commit SHA or candidate commit tree. Raw changed
sources, diff and hashes are retained for review without a ready claim.
Commits created: **NONE**. Push attempted: **NO**.

Final disposition: **INCREMENT_08_CONTRACT_BLOCKER**.

## Open risks

A persisted reference is invalidated by later physical writes until the next
complete boundary. A refused save retains live retry state and may leave
physical writes on disk with no usable continuation; fresh entry refuses
honestly. Arbitrary process crashes, user-edited save repair and arbitrary
legacy migration remain outside the contract. Population capacity, unactivated
slice domains, longer authority saturation, observer completeness and eventual
PS01 characterization remain open after this increment.

</details>

</details>

</details>
