# PS01 Increment 07 — Normal Autonomous Renewable Food Continuity

Status: **COMPLETE AND PUBLISHED — PASS — REMOTE VERIFIED**.

Final qualification disposition: **P0 0 / P1 0 / blocking P2 0**.

PLAYABLE SLICE 01 remains **REQUIRED — IN PROGRESS / NOT COMPLETE**.
CIV-48 remains **NOT STARTED — IMPLEMENTATION NOT AUTHORIZED**. Gate H remains
**PLANNED**. Increment 08 is **UNSELECTED**.

## Publication identity

- Repository: `Ness-Now/pebble`.
- Canonical branch: `lab/pebblelab-v1`.
- Published product/qualification commit:
  `373b5e3688d25e1e139dd735a76d48e38743c1f8`.
- Published tree: `56e50d1f910f8825ae344aab50e4a65553ae06ef`.
- Published parent: `e05f2f67e6d7b3b738f00ced4f3368e58a4e92ce`.
- Published subject:
  `feat(ps01): implement increment 07 renewable food continuity`.
- Final product patch SHA-256:
  `4393eac462e3b0b24cb6aaa1ceb6b02196deb58fdb5e053af95d53fbf25f48c8`.
- Core streaming determinism fix V2 patch SHA-256:
  `bf4fcee2e4b1c0697ed61ff263f7ce29fc7066d902ef437c35941088c8ab5764`.
- Final validation V3 patch SHA-256:
  `6bbca0d5abd2e3f57e9f57be6ceb5178e68bcb0a4c413af311ef18c03fd41656`.
- Current schema: **45**.
- Final qualification archive SHA-256:
  `742f12009735032c0ea0a0e43b01bf2db8d1549b9a066afc552f664505eb348a`.
- Accepted Tranche-1 post-Core-fix archive SHA-256:
  `3488ca99ce60d6cd561aeb413605e06055fa0595d220f9bc5f4c2b4ed0e1dd80`.
- Evidence location outside the repository:
  `/Users/nessnow/Dev/pebble-lab-i07-evidence/`.
- Publication: **MANUAL USER PUSH COMPLETED**.
- Remote verification: **PASS**.
- Codex push attempted: **NO**.

Final validation V3 differs from V2 only by restoring one historical blank
line. Product/Core hashes remain exact, semantic tokens are unchanged and no
semantic qualification rerun was required.

## Accepted product mechanism

Normal hunger-qualified founders use naturally generated mature sweet berry
bushes. PebbleCore remains the sole physical authority for World state, growth,
direct-action randomness, physical identity and ItemEntity drops. Its
actor-neutral preserving harvest changes a mature stage-2 or stage-3 bush to a
living stage-1 bush and produces physical `sweet_berries` ItemEntity material.

Pebble remains the sole sensor, executor, custody, verification and rollback
owner. It prevalidates the actor, source, reach and occupancy; invokes Core;
verifies the exact source mutation and physical drops; transfers exact
Core-reported entities into real inventory; and publishes only after custody
and conservation are verified. Failed post-mutation work restores the source
and custody and removes transaction drops with exact verification. An
unverifiable rollback remains a hard failure.

Owned material is ordinarily consumed through the existing physical-food
authority. Natural Core random ticks renew the same living source. Fresh
evidence then leads through ordinary cognition and navigation to a second
preserving acquisition from that same source. Quantity, physical identity,
source stage, custody and consumption remain exactly reconcilable.

There is no proof-only productive setup, accelerated growth, expected-result
injection or second ecology/growth authority in the normal product path.
Disposable proof fixtures remain explicit and non-authoritative.

## Core streaming determinism blocker and accepted correction

`CORE_STREAMING_DETERMINISM_BLOCKER_FIX = PUBLISHED`.

Qualification discovered that asynchronous generation-completion order could
influence authoritative chunk adoption and physical entity-ID allocation. The
historical failed evidence remains preserved. The accepted correction retains
concurrent generation, while making worker timing non-authoritative:

- requests receive deterministic admission and sequence authority;
- complete admitted waves publish before authoritative progression;
- results commit in deterministic request order;
- stale-save, obsolete player-ring and old-epoch results follow deterministic
  tombstone, requeue or rejection policy;
- agent-coverage and explicit/system requests retain their existing authority;
- physical lighting advances from World ticks with deterministic distance and
  coordinate ties, not independently from rendered frames; and
- `nextEntityId` remains Core's sole durable physical identity allocator.

Forced completion-order inversion, capacity, wave-barrier, freshness,
cancellation, explicit continuation and epoch rejection regressions passed.
The post-V2 full natural determinism comparison passed with exact terminal
durable-state and physical-ID equality.

## Qualification evidence

### Natural continuity and determinism

- POST-V2 full natural determinism: **PASS**.
- Exact terminal durable state and physical identity equality: **PASS**.
- Normal preserving acquisition, living stage-1 source, natural renewal and
  second preserving acquisition from the same source: **PASS**.
- Scarcity seed 46: **PASS**, with no fabricated food, harvest, custody or
  consumption.
- Scarcity seed 887: **PASS**, with the same non-fabrication result.
- Fault matrix: **PASS**.
- Fresh-process restart: **PASS**; restart grants no free growth, material or
  duplicate custody.
- Controlled renewable-food chain: **PASS**.

### Focused and full smoke

- Increment-07 focused: **175 / 175 PASS**.
- Core physical coverage and streaming: **48 / 48 PASS**.
- Embodiment: **793 / 793 PASS**.
- Bounded navigation: **26 / 26 PASS**.
- Wild subsistence: **55 / 55 PASS**.
- Agriculture: **86 / 86 PASS**.
- Persistence and physical identity: **87 / 87 PASS**.
- Full smoke: **4,906 / 4,909**.

The three full-smoke failures are known pre-existing failures: zoo
bit-identical, combat lockstep, and eight A* paths node-identical. They are not
attributed to Increment 07. No golden was regenerated.

### Performance characterization

The canonical headless characterization passed:

| Founders | Median | p95 | Maximum |
| ---: | ---: | ---: | ---: |
| 20 | 83.377 ms | 123.589 ms | 158.491 ms |
| 24 | 109.425 ms | 132.974 ms | 135.213 ms |
| 30 | 145.986 ms | 193.104 ms | 199.167 ms |

Every run recorded zero catch-up drops, runtime errors and fatal-integrity
halts. These headless aggregate timings are not converted into rendered
ticks-per-second, and no support above 30 founders is claimed.

## Visual Game Smoke chronology

The initial Visual Game Smoke attempt is preserved as **FAIL — HARNESS
CONTRACT BLOCKER; NOT AN ESTABLISHED PRODUCT FAILURE**. Its 1,800-second
watchdog conflicted with duplicated long renewal requirements, its camera
moved the physical Player, and its captures were poorly framed.

The validation-only correction ends at the first normal preserving
acquisition, uses a render-only observer `CamState`, keeps the physical Player
unchanged, uses a radian look-at calculation, records two representative
captures and retains a configurable safety watchdog. It did not change the
product mechanism or replace Tranche-1 renewal proof.

Corrected Visual Game Smoke: **PASS — SUPERVISOR APPROVED**. The live run
reached first preserving acquisition at World tick 9,671 / civilization tick
1,921 by `agent_16`, quantity 2, source `(211, 65, -27)`, with a living stage-1
source, verified custody and exact conservation. The Player remained at
`(208.5, 67, -31.5)`. Both captures were accepted as representative.

## Non-blocking watches

- Authoritative ticks may wait for the slowest generation worker.
- Generation concurrency remains bounded to 24 jobs.
- There is no hard worker timeout.
- Moving streaming frontiers may create repeated waits.
- Rendered throughput remains below headless throughput.
- The 20-founder p95 increased relative to Increment 06, while the canonical
  performance gate still passed.
- Two pre-existing `WorldRenderer` warnings remain for `lightViewM` and
  `lightProjM`.

These watches are non-blocking and introduce no retrospective performance
threshold.

## Published disposition and non-claims

- Increment 07: **COMPLETE AND PUBLISHED — PASS — REMOTE VERIFIED**.
- Core streaming determinism blocker fix: **PUBLISHED**.
- Final Risk-C: **P0 0 / P1 0 / blocking P2 0**.
- PS01: **REQUIRED — IN PROGRESS / NOT COMPLETE**.
- Renewable Physical Subsistence: **RESOLVED FOR THE BOUNDED NORMAL
  SWEET-BERRY CONTINUITY CONTRACT**.
- Demographic capacity/headroom: **UNRESOLVED**.
- Increment 08: **UNSELECTED**.
- CIV-48: **NOT STARTED — IMPLEMENTATION NOT AUTHORIZED**.
- Gate H: **PLANNED**.
- Publication: **MANUAL USER PUSH COMPLETED**.
- Remote verification: **PASS**.
- Codex push attempted: **NO**.

Increment 07 proves one normal, bounded, persistent renewable sweet-berry path.
It does not establish a general food economy, activate carrots/crops for normal
founders, add a second ecology, solve demographic headroom, complete PS01,
acquire Gate H or authorize CIV-48. Increment 08 remains unselected; the next
authorized technical action after this reconciliation is published and remote
verified is the read-only
`REVIEW-AND-SELECT-PLAYABLE-SLICE-01-INCREMENT-08` mission.
