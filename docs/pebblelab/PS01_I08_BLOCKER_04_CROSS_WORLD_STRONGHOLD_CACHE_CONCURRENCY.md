# PS01 I08 Blocker 04 — Cross-World stronghold cache concurrency

Status: **SENIOR REVIEW APPROVED — LOCAL PUBLICATION CHAIN READY FOR USER PUSH — NOT PUBLISHED**.
Status after successful user push and remote verification: **BLOCKER_FIX_PUBLISHED**.
Mission: `RESOLVE-PS01-I08-BLOCKER-04-CROSS-WORLD-STRONGHOLD-CACHE-CONCURRENCY`.
Attribution: `PREEXISTING_SHARED_CORE_DEFECT_DISCOVERED_BY_I08`.
Owner: **PebbleCore**.

This dedicated branch starts directly at canonical
`9919e575819dca02ee8e893a37ac9eaaebc36012`, fetched from
`https://github.com/Ness-Now/pebble.git` and checked against both the remote
tracking ref and `git ls-remote`. It contains no I08, B02 or B03 implementation.
The unchanged approved correction is `aa07e3ce71c34842e45611d8e9064de9cb563a16`, tree
`daf3cd604f70c455da0ed13a04cc0b5703856ab8`, sole parent
`9919e575819dca02ee8e893a37ac9eaaebc36012`, subject
`fix(core): isolate cross-world seeded structure caches`.
The containing documentation commit is identified by Git delivery metadata
rather than embedded self-referentially. The local publication chain contains
exactly the canonical baseline, this approved correction, then that one
documentation-only commit.

I08 remains selected / implementation in progress / not qualified / not
published. PS01 remains required / in progress / not complete. CIV-48 remains
not started / implementation not authorized. Gate H remains planned. This
mission does not run the I08 campaign, reconcile its worktree or acquire a gate.

## Independent review and publication reconciliation

Reconciliation mission:
`PUBLISH-RECONCILIATION-PS01-I08-BLOCKER-04-STRONGHOLD-CACHE-CONCURRENCY`.
Independent senior review: **PS01_I08_BLOCKER_04_INDEPENDENT_REVIEW_PASS**;
**P0 0 / P1 0 / blocking P2 0**. The independent reviewer explicitly concluded
that exact correction `aa07e3ce71c34842e45611d8e9064de9cb563a16` is safe to
publish unchanged as the bounded shared Core correction. It is not amended.
The earlier local-candidate / supervisor-review-required status is superseded
by this approval; its qualification and historical FAIL evidence remain intact.

At documentation reconciliation the fetched canonical remote remains
`9919e575819dca02ee8e893a37ac9eaaebc36012`. This prepares a **local publication
chain** only. **User push and subsequent exact remote verification are pending**;
B04 is not yet published. Only after both succeed does its publication status
become **BLOCKER_FIX_PUBLISHED**. No I08 lifecycle code is included in B04.

The established B01 product/documentation publication chain is already in
that canonical history. Publishing B04 does not qualify I08. The separate
uncommitted B03 correction remains paused pending B04 publication/reconciliation
and explicit I08 resumption. All earlier I08/B01/B02/B03 FAIL records retain
their original meaning; corrected evidence is additive.

## Protected I08/B03 worktree

The existing `/Users/nessnow/Dev/pebble-lab` checkout remains on
`codex/ps01-increment-08-normal-continuity` at
`8b7b1970c0f85e14b905ab032c2448057e9737b9`. Its nine modified tracked files,
236 insertions, 19 deletions and absence of untracked files were recorded before
work. The complete binary diff SHA-256 is
`b5b98710ee334c47ecc3b38f5a1bdbb6416c45127a7e72eaaf735f3ba5760d1c`.
The staged diff is empty. Per-file hashes and the final equality check are in
[the additive evidence record](PS01_I08_BLOCKER_04_EVIDENCE.json).

The B04 checkout is
`/Users/nessnow/.codex/worktrees/ps01-i08-blocker-04/pebble-lab`, branch
`codex/ps01-i08-blocker-04-stronghold-cache-concurrency`. No reset, stash,
rebase, clean, source edit or commit was performed in the protected checkout.

## Immutable historical discovery and attribution

B03 final qualification crashed with **exit 139** while an outgoing seed-14
World generation worker entered `strongholdChunks` through `requestChunk`,
and ordinary C07 `loadWorld` synchronously generated incoming seed 73.
The failing release executable SHA-256 is
`e021ff7e4dddb573566eb810e3b51d0a173258f83a8ba95d47903fc48126d026`.
This remains historical FAIL evidence.

The original crash report, Core log and executable-hash record remain at
`/tmp/ps01-i08-b03-20261002/qualification-crashed-core/`, with the unchanged
segmentation-fault driver log beside that directory. Their hashes are retained
in the additive evidence record; later B03 native PASS controls are separate.

The prior attribution compared canonical `9919e575...`, original I08
`066704f53275ca56f863b5911d8799d8072c2196`, B02 `8b7b197...` and dirty B03.
The structure/cache sources and relevant generation ownership were identical.
The canonical diagnostic used one retained `GameCore`, ordinary World
creation, `frame` streaming and `loadWorld`, without continuation callbacks or
an agent controller. Its TSan failure is **exit 134**, executable SHA-256
`605f464412eeef71a673a539262eb5d3091be43f31ed7d0622e3e14aaa9a875b`.
The preserved diagnostic reports thread T20 reading the global cache at
`StructUnderground.swift:10` through asynchronous `requestChunk`, concurrent
with a main-thread write at line 11 through `ensureChunksLoaded` →
`enterWorld` → `loadWorld`.

The original attribution directory is
`/tmp/ps01-i08-b03-attribution-20261003`; the decisive ordinary canonical log is
`runs/canonical-ordinary-tsan-second-batch/run-3.log`, with its unchanged
`results.txt` reporting `0, 0, 134`. B02 ordinary/sequence and B03 sequence
TSan failures, intermittent native controls, and the B03 release crash remain
untouched. Earlier project failures retain their original meanings.

B04 reconfirmed canonical source identity and read that exact diagnostic.
A freshly built canonical focused diagnostic additionally exposed 570 wrong
cross-seed plan answers and the unsynchronized stronghold cache under TSan
(exit 134). Three fresh ungated canonical single-replacement controls exited
0; those intermittent passes do not negate the historical ordinary race.
Two preliminary eight-replacement diagnostics (canonical and corrected) hit
an external 180-second cap; their command exits are 1 and their result is
**INCOMPLETE_TIMEOUT**, not PASS. Completed corrected evidence is additive.
An initial release build was rejected because a test source changed during
compilation, and an owning-suite preparation tried the convenience binary
symlink before the package build completed. Both are recorded as failed
preparation attempts; neither supplies qualification evidence. Stable-source
builds and completed owning runs supersede only those attempts.

## Cache identity, lifetime and call-path audit

`StructUnderground.swift` declared one process-global optional tuple containing
one seed and its 19 ring origins. Its only writer and all reads were inside
`strongholdChunks`; the stronghold definition's `check` was its only caller.
The code checked the seed, replaced the tuple, then read the global tuple
again without synchronization. Another seed could replace it between those
operations; unsynchronized optional/array lifetime access could also crash.
There was no World-reset or clear path for this cache.

`strongholdPositions(seed)` is a pure seeded calculation, also used by eyes of
ender. Its result has no World, epoch, time, terrain, persistence or actor
state. Same-seed reuse across World replacement is logically valid; different
seeds require independent values. Reset is not logically required.

The adjacent process-global structure-plan cache already had its own lock,
but its key was only dimension / structure ID / origin coordinates. Its lock
is released before `def.check` reaches stronghold lookup. It neither protected
the stronghold tuple nor prevented a cached plan from another seed being
returned. It clears only when its entry count exceeds 600, under its own lock;
World replacement does not clear it. A lock on the stronghold tuple alone would
leave this deterministic cross-seed contamination defect.

`generateChunk` constructs `GenCtx` from the captured seed and dimension.
The registered structure framework is shared by direct generation, synchronous
`ensureChunksLoaded` during World admission/teleport, and streaming generation
through `requestChunk`. Nether/End use the same plan owner with their own
structure sets. Generator dictionaries have `genLock`; those locks do not
cover structure lookup. Structure registration uses the existing once-only
Swift static initialization, whose order is unchanged.

`requestChunk` captures the outgoing World, seed, immutable ticket and
calculation group before dispatching to the concurrent generation queue.
`resetChunkGenerationRuntime` increments the epoch, clears current request and
completion state under the existing owners, and replaces the group. It does
not cancel or drain already executing calculations. Old workers can finish
using their captured World and seed; calculated results are keyed by epoch
and sequence. Main-thread delivery rejects a mismatched epoch before adoption.
Current World identity and save-freshness checks also remain in force.

Thus the defect combines **unsynchronized shared mutable stronghold lifetime**
and **incomplete plan-cache seed identity**. Supported old-worker overlap is
safe once calculation data and cache keys are correct; draining workers or
redesigning lifecycle ownership is unnecessary.

## Correction architecture

- Remove the global mutable stronghold tuple and helper entirely.
- Derive the same 19 origins once in `GenCtx.init`, retaining them as an
  immutable internal value beside its immutable seed. The registered check
  reads this context-owned array. It is released with the calculation context;
  there is no global seed retention, second authority or reset ordering.
- Add `ctx.seed` to the existing locked plan-cache key. Preserve the lock's
  small lookup/publication scope, existing count-based eviction, seeded
  planning/build RNGs, structure order and all algorithms.

No expensive generation is globally serialized. No worker drain, result
injection, lifecycle/custody change, renderer/persistence change, PebbleAgents
change or golden update is present. Late old plans can only serve the same
seed. Correcting erroneous mixed-seed cache reuse restores isolated seeded
semantics; it introduces no intentional seeded generation output change.

## Focused regression and qualification

The new `PebbleCoreStrongholdConcurrencySmoke.swift` is dispatched by
`PEBBLELAB_SMOKE_ONLY=core-stronghold-concurrency` and also runs in full smoke.
It checks all 19 origins for seeds 0, 14, 46, 73, 887 and UInt32.max, placement
RNG neutrality, exact repeated plan geometry, and all 570 foreign-seed queries.
Six workers execute 7,296 placement/plan pairs with lock-protected aggregation.

The overlap regression retains one ordinary `GameCore`. Two real outgoing
`requestChunk` calculations are preempted through the existing test hook.
A scheduling envelope around the real registered stronghold check releases
them when synchronous incoming `loadWorld` reaches that check, and waits for
an outgoing lookup. The envelope forwards the original check and plan without
injecting outputs or modifying structure fields/order. It is restored only
after both calculations and main-thread deliveries finish. It proves the
14 → 73 → 887 → 14 topology, epoch advancement, six total stale-result
rejections, no outgoing chunk adoption and incoming blocks/biomes equal to
isolated seeded generation. Scheduling waits have explicit 30-second bounds.

Separate ungated dispatches exercise ordinary natural seed-14 creation,
`frame` streaming and one or eight normal `loadWorld` boundaries alternating
14/73, with no scheduling envelope or continuation behavior.

The reproducible runner is
[`verify-pebblelab-ps01-i08-blocker-04.sh`](../../scripts/verify-pebblelab-ps01-i08-blocker-04.sh).
It refuses regold, uses disposable `CFFIXED_USER_HOME` directories, preserves
logs and hashes, and exits nonzero for any failed case. `--tsan` compiles the
actual PebbleCore target with `--sanitize=thread` and links the same regression
source into a small counter/dispatch driver; it supplies no alternate Core.
`--stress` fixes the bound at six fresh processes per each of three cases.

Detailed completed results, executable hashes, commands, assertion counts,
log hashes and preliminary limitations are recorded in
[PS01_I08_BLOCKER_04_EVIDENCE.json](PS01_I08_BLOCKER_04_EVIDENCE.json).

| Completed command / coverage | Exit | Exact result |
| --- | --- | --- |
| `swift build -c release` | 0 | Stable final package build. |
| `scripts/verify-pebblelab-ps01-i08-blocker-04.sh --tsan` | 0 | Focused 838/0; ordinary single 6/0; ordinary eight replacements 34/0; zero TSan diagnostics. |
| Final-source focused TSan rerun | 0 | 838/0; zero TSan diagnostics. |
| `scripts/verify-pebblelab-ps01-i08-blocker-04.sh --stress` | 0 | Six fresh runs per case, 18 processes, 72 replacements, 5,268/0 assertions; every exit 0. |
| `PEBBLELAB_SMOKE_ONLY=civ-45-correction07` owning run | 0 | 8/0; ordinary lifecycle/load durability. |
| `PEBBLELAB_SMOKE_ONLY=civ-45-correction08` owning run | 0 | 6/0; lifecycle/probe retention and replacement. |
| `PEBBLELAB_SMOKE_ONLY=ps01-increment-03-coverage` owning run | 0 | 48/0; physical coverage and ordered streaming determinism. |
| `CFFIXED_USER_HOME=/tmp/ps01-i08-b04-20261003/canonical-gate-home scripts/verify-pebblelab.sh` | 1 | Stages 1–4 pass; stage 5 full smoke is 5,758/3; stages 6–35 do not run. |

The three full-smoke failures are unchanged historical **zoo bit-identical**,
**combat lockstep**, and **eight A* paths node-identical** failures. The full
smoke adds exactly 838 passing B04 assertions to canonical's 4,920/3 accounting.
Core RNG/noise, terrain/feature/structure goldens, lighting and the new seeded
ownership checks pass. No comparison was weakened, no golden changed, and the
repository gate is **not PASS**.

Native smoke/stress executable SHA-256:
`8f6b00553fedb25cd80580a7dbf74b37c2852910fe11e59e553ab949a6027612`.
All-case TSan executable SHA-256:
`cab92913d39351eca183e77504f8bd23397edbb0d210fa84619816c8ce2686f0`.
Final-source focused TSan executable SHA-256:
`6fd3135ca8271c7c95a50c07fa68d761cbd9f05e945eee1f8fd0a53b5cf95a3b`.
The native disposable databases contain zero World rows and zero chunk rows
after all 18 runs; all diagnostic processes exited. Historical artifacts and
the protected worktree remain unchanged.

## Determinism evidence

[`pebblecore-stronghold-determinism.swift`](../../scripts/pebblecore-stronghold-determinism.swift)
was compiled against clean canonical Core before editing and against corrected
Core. Each seed runs in a fresh process to exclude baseline cache poisoning.
For all six seeds it captures all 19 origins, all 19 plan piece/ref boxes and
five full generation outputs: the first stronghold chunk, its east neighbour,
overworld (0,0), nether (0,0), and end (0,0). Output includes block/biome SHA-256,
complete block-entity/entity specifications with sorted data keys, and structure
refs. Both corrected native and TSan builds ran twice per seed. All twelve
outputs per build match their canonical counterpart byte-for-byte, and the
six distinct seed captures have distinct hashes. The comparison matrix covers
114 stronghold plans and 30 complete chunk outputs; deterministic Core and
generation sections also retain **352 / 0** owning assertions. Goldens are untouched.

## Independent non-blocking context-identity risk

**NON_BLOCKING_RISK — PRE-EXISTING GENERAL PLAN-CACHE CONTEXT IDENTITY LIMITATION**.
Arbitrary public `GenCtx` instances can supply terrain/biome closures whose
behavior is not fully represented by the cache key. The reviewer demonstrated
both canonical and corrected village examples in which different height
behavior can share a cache identity. This limitation exists on canonical and
is not introduced by B04. Normal canonical seeded generation is adequately
identified by the corrected seed-qualified key; stronghold plans do not depend
on those arbitrary terrain/biome probes.

This is a separate future owning follow-up, outside B04. Approval does not
claim universally correct plan-cache reuse for every arbitrary public `GenCtx`.
No context-identity expansion or additional correction is part of this
publication reconciliation.

## Residual risks and non-claims

The proof is bounded to these seeds, coordinates, ordinary replacement paths
and supported scheduling seams on macOS arm64 / Swift 6.3.2. TSan cleanliness
is stronger evidence than intermittent native success, not a proof that every
Core subsystem is free of races. Existing generator-cache retention and
plan-context assumptions beyond normal seed-derived generation are unchanged.
Epoch rejection deliberately allows old computation to consume CPU until it
finishes; this correction does not redesign cancellation or queue capacity.

Visual Game Smoke Policy V5 was read and applied proportionally: this is a
shared calculation/cache ownership correction with unchanged isolated physical
outputs. Headless ordinary Core admission, scheduled overlap, TSan and exact
output comparison address its risk. No rendered-game or I08 visual campaign
is claimed. Pebble process launched: NO. Representative screenshot inspected:
NO. No gate, I08 qualification or publication follows from these local checks.

`Push attempted: NO`.
