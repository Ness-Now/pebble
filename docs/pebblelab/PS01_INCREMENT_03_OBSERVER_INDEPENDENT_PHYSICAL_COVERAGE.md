# PS01 Increment 03 — Observer-Independent Physical Coverage

Status: **COMPLETE AND PUBLISHED — PASS — SENIOR REVIEW APPROVED — REMOTE
VERIFIED**.

PLAYABLE SLICE 01 remains **REQUIRED — IN PROGRESS / NOT COMPLETE**.
CIV-48 remains **NOT STARTED — IMPLEMENTATION NOT AUTHORIZED**. The next
authorized action is `REVIEW-AND-SELECT-PLAYABLE-SLICE-01-INCREMENT-04`, a
review, audit and selection step only. It does not preselect or authorize
Increment 04 implementation.

## Published identity and review

- Publication HEAD: `0e7f36202debd088e4f1c84de96078be78b6b6fd`.
- Tree: `33a3675301a6fe088fde62b373f7e73505ba346d`.
- Parent: `757cad2742e4b76e13010035f246da1e375a01a4`.
- Commit message: `feat(ps01): add observer-independent physical coverage`.
- Accepted review ZIP SHA-256:
  `4183fedfb071f900afe349b317ecd58e215206efd5afb8427b004c2bcc3c6f04`.
- Independent senior review: **PASS — P0 0 / P1 0 / P2 blocking 0**.
- Manual publication: completed.
- Independent canonical remote verification: completed.

## Canonical program position

- Increment 01: **COMPLETE AND PUBLISHED — PASS — SENIOR REVIEW APPROVED —
  REMOTE VERIFIED**.
- Increment 02: **COMPLETE AND PUBLISHED — PASS — SENIOR REVIEW APPROVED —
  REMOTE VERIFIED**.
- Increment 03: **COMPLETE AND PUBLISHED — PASS — SENIOR REVIEW APPROVED —
  REMOTE VERIFIED**.
- PLAYABLE SLICE 01: **REQUIRED — IN PROGRESS / NOT COMPLETE**.
- Next authorized action:
  `REVIEW-AND-SELECT-PLAYABLE-SLICE-01-INCREMENT-04`, review/audit/selection
  only, with no implementation authority or preselected scope.
- CIV-48: **NOT STARTED — IMPLEMENTATION NOT AUTHORIZED**.
- Gate H: **PLANNED**, still dependent on CIV-48 through CIV-52. No Gate H
  acquisition work is authorized.

## Published bounded scope

This increment gives each valid, active Pebble founder a finite physical
simulation opportunity that does not disappear or change merely because the
Observer/player moves away. It establishes the technical World coverage needed
to make later sensing, bounded pathing, natural-resource observation,
random-tick opportunity, and ordinary-entity opportunity causally
interpretable. It does not activate those later behaviors.

The normal sandbox remains unprovisioned. No food, tool, seed, crop, livestock,
ore, terrain, physiology, death timing, time, pause, speed, reproduction,
subsistence, production, economy, culture, settlement, migration, Save/Continue,
or Observer-authority behavior is added or changed.

## Canonical baseline

- Repository: `Ness-Now/pebble`.
- Canonical branch: `lab/pebblelab-v1`.
- Verified remote HEAD:
  `757cad2742e4b76e13010035f246da1e375a01a4`.
- Tree: `5d0bc99d7395cde9d08c840d902e781d3ade6161`.
- Parent: `056c6b625d7482581028cf149329bc292948d53d`.
- Message: `docs(ps01): record increment 02 publication`.
- Implementation branch:
  `codex/ps01-increment-03-observer-independent-physical-coverage`.

The implementation branch was created directly from that baseline. Its sole
product commit is the published identity above.

## Architecture and authority

`PebbleCore` remains the sole owner of World time, chunks, generation,
scheduled and random block work, block entities, ordinary entities, movement,
pathfinding, collision, World randomness, and persistence. The implementation
extends the one World scheduler with a bounded technical coverage request. It
does not create a second clock, loop, entity scheduler, random authority,
physical World, or durable roster.

`Pebble` derives coverage roots from the current authoritative live
`AgentSimulationSession` population and its exact physical-probe bindings. A
request is valid only when session, population, probe, World, living state,
dimension, and the maximum active-population contract agree. PebbleAgents
neither reads chunks nor controls streaming. Observer/player interest remains a
separate World input and is not civilization state.

Coverage is recomputed technical state. It is not serialized in the
civilization checkpoint or replay. On restore or restart Pebble reconstructs it
from the restored live session/probe/World binding. Stop, reset, death, movement,
admission, and dimension changes therefore cannot leave an independently
maintained coverage roster behind.

The controller also validates the World snapshot against the roots it derives
for the current update. A merely `ready` snapshot for an older root set is
treated as pending, not current readiness. This closes the admission-transition
case without allowing one civilization update to publish against stale World
coverage.

## Explicit bounds and geometry

- Maximum active roots: 30, inherited from the validated normal population
  ceiling.
- Per-root radius: one chunk in X and Z around the probe's resident chunk.
- Per-root neighborhood: at most 3 x 3 = 9 chunks.
- Theoretical undeduplicated ceiling: 30 x 9 = 270 chunks.
- Covered chunks are one canonical sorted union; overlap reduces work.
- No physical target is scheduled once per root. Work is scheduled once from
  the deduplicated covered set.

The published navigation-observation radius is eight blocks. For any start
coordinate in a 16 x 16 root chunk, adding or subtracting eight produces a
coordinate in the previous, resident, or next chunk on each axis. The complete
direct radius-eight square is therefore contained by the 3 x 3 halo, including
root-chunk edges and corners. A path detour may exceed that geometry; it is not
allowed to reinterpret outside state as blocked and is handled by the bounded
path result described below.

The 270-chunk figure is a hard structural ceiling for this increment, not a
generic scalability claim. No claim is made above 30 roots.

## Chunk generation and fairness

The existing World generation queue remains authoritative and bounded at 24
jobs. While agent coverage is incomplete, each refill reserves six jobs for
player/render interest and permits at most 18 agent jobs. Agent jobs are
canonical and evaluated first; player jobs then occupy the reserved capacity.
This prevents permanent starvation in either direction without introducing a
second queue.

The direct 30-disjoint-root attack observed 18 agent jobs plus 6 player jobs,
24 total. Pending and refused requests remain explicit. With successful static
generation, all 270 chunks converge in 15 bounded refill waves. Injected
generation refusal stays `refused`; it is never published as absence.

## Readiness and fail-closed publication

Coverage status is `inactive`, `pending`, `ready`, or `refused`. A live agent
may publish bounded sensor/path facts only while the World status and the
controller's current derived roots agree exactly. While generation is pending,
refused, stale, unavailable, or dimension-inactive, the controller does not
advance the candidate civilization transition through a false negative.

An indeterminate bounded movement result rolls back any earlier physical moves
in that candidate update, restores the session/replay candidate, and publishes
no false blocked-path memory. This is fail-closed unavailability, not a runtime
hard failure and not an ordinary statement that a resource, entity, path, or
opportunity is absent.

## Bounded pathfinding contract

The historical `findPath` implementation is deterministic A*. It chooses the
lowest estimated total cost using its existing stable scan/tie behavior,
returns an empty path for an identical start and target, and stops at
`maxNodes`. Historically it may return a best-effort partial path when the best
remaining Manhattan distance is at most 24, otherwise `nil`. That API does not
distinguish a genuinely blocked target, unloaded state, or node-budget
exhaustion.

Increment 03 adds a Core-owned, opt-in `PhysicalPathSearchDomain` and an
explicit `PhysicalPathSearchResult` for Pebble's covered navigation path:

- `path`: a path found wholly inside the declared ready domain;
- `noPath`: the complete ready bounded domain was explored and no path exists;
- `coverageLimited`: a potentially relevant continuation crosses the declared
  coverage boundary;
- `coverageUnavailable`: a required member of the declared domain is not
  physically ready;
- `nodeBudgetExhausted`: the finite search budget prevents a truthful result.

The optional domain is supplied only by the Pebble live movement executor from
the ready PebbleCore coverage snapshot. The legacy signature and every
historical/default caller remain behaviorally unchanged when no domain is
provided. **Default historical callers changed: NO.** No `maxNodes` change is
used as a spatial proxy.

The nine focused path assertions cover same-cell/root operation, radius-eight
corner geometry, a simple in-domain path, an in-domain obstacle detour, an
outside-domain-only detour, an unavailable member chunk, budget exhaustion, a
fully explored genuine no-path, legacy best-effort compatibility, and
camera-near/far/return equivalence (some assertions combine related geometry).

## Deterministic scheduling and World randomness

Zero-root mode takes the literal historical World branches. It preserves
baseline tick ordering and World RNG consumption for scheduled ticks, random
ticks, block entities, ordinary entities, weather, player streaming,
generation, unloading, and existing deterministic digests.

Active coverage must protect agent-covered results from camera-only membership,
enumeration, and shared-RNG consumption. The keyed streams are World-owned and
derived only through explicit stable mixing from World seed, dimension, World
tick, physical coordinate/chunk/entity identity, operation domain, and where
needed a sample ordinal or stable block/type identifier. They do not use player
position, camera focus, Swift `Hasher`, collection iteration order, memory
address, Observer selection, or cognition order.

| Domain | Baseline | Active-coverage treatment | Domain separator |
| --- | --- | --- | --- |
| Scheduled block handlers | Due queue invokes handlers with shared game/farming RNG | Due time, priority, queue and budgets remain unchanged; only covered handler-local game/farming RNG is scoped by tick, coordinate and block identity | `0x5c4e_d001` |
| Random coordinate selection | Shared `World.rng` samples around player `simCenter` | Covered chunks are canonically enumerated and coordinates sampled from a chunk/tick keyed stream | `0x7a11_c001` |
| Random block handlers | Selected handlers consume shared game/farming RNG | Covered handler-local RNG is keyed by tick, World coordinate and sample ordinal | `0x7a11_d001` |
| Block entities | Globally loaded list, shared handler RNG | Coverage retention supplies membership; covered entities tick once in coordinate order with scoped handler RNG; player-only work retains legacy order | `0xbe00_0001` |
| Ordinary entities | Player simulation eligibility, loaded residency, shared handler RNG | Same World-owned entity list; covered entities tick once in stable persisted-ID order and player-only overlap is skipped; handler RNG is scoped | `0xe171_7001` |
| Weather | Shared `World.rng` after other World draws | With active coverage, the World-owned transition is keyed by tick and weather state; zero-root behavior is literal legacy | `0x7ea7_4e01` |

Scheduled event timing itself is not randomized. Only randomness used inside a
covered due handler is isolated. Block entities and ordinary entities remain in
their existing World lists and loops; there is no per-agent processing pass.

Audited but unchanged are pathfinding randomness (none), scheduled due-tick and
priority semantics, fluid budgets, daylight and World time, chunk-generation
coordinate randomness, player-only legacy processing, and other gameplay RNG
domains outside the covered handler contract.

### Weather decision

Baseline weather consumes `World.rng`. Baseline player-centered random-tick
sampling also consumes that stream, so a different camera path may consume a
different number of draws before a weather transition. That can change rain or
light state subsequently observed by agent-covered crop/random-tick work.
Active coverage therefore uses the World-owned keyed weather transition above.
This is required by the selected agent-relevant contract; it is not an assertion
that all World events become globally camera-identical. The no-agent proof
confirms exact baseline weather/RNG behavior. The active-coverage proof makes
camera-only RNG histories diverge while the relevant weather state/digest
remains equal.

## Scheduler, overlap, and camera proofs

The final dedicated selector passed **34/34**, exit 0. It proves:

- literal empty-coverage legacy behavior;
- near, far, moving, and returning camera equivalence;
- sorted/reversed root enumeration equivalence;
- overlap and duplicate-root handling;
- root movement and last-root removal;
- pending, unavailable, refused, and stale-root truthfulness;
- random-tick, scheduled-tick, block-entity, and ordinary-entity opportunity;
- no duplicate target processing for overlapping roots;
- ordinary entity cessation after final-root removal;
- all bounded path result classes and default compatibility;
- weather isolation and zero-agent weather compatibility;
- 18/6 queue fairness and 15-wave maximum convergence.

The direct same-input coverage digest was identical for camera near, far, and
moved/returned: `27acff72dab39e44`. “Agent-relevant” means physical scheduling,
readiness, receipts, and resulting facts whose physical targets are inside the
declared ready covered union. Player-only results outside that union may
legitimately differ.

## Lifecycle and persistence

Direct and rendered lifecycle evidence covers:

- normal founder bootstrap: coverage moves from pending to ready;
- physical movement: the root follows the authoritative probe across chunks
  and old unshared coverage disappears;
- admission: a new root is not usable until the existing session/probe binding
  is valid and World coverage reconciles;
- death: finalized actors lose probe authority and coverage;
- terminal cohort: all roots and probes disappear after the Increment 02
  terminal boundary;
- stop: all probes and roots disappear and World coverage returns inactive;
- reset: old coverage disappears before normal bootstrap reconstructs it;
- checkpoint restore/restart: exact probe custody is reused/reconciled and
  coverage is rederived;
- inactive dimension: coverage is not claimed ready in the wrong World
  dimension.

In the admission attack, population/probes became 21 while the previous World
snapshot still described 20 roots. The controller explicitly reported pending,
kept civilization tick zero, and advanced only after World coverage became
ready for all 21. Stop reported population zero, probes zero, inactive coverage,
zero roots, and no runtime error.

Checkpoint inspection found no serialized coverage root, covered-chunk, or
physical-simulation-coverage field. Restoring with a different camera location
reconstructs coverage from physical authorities; camera position never enters
civilization replay causality.

The final Increment 02 rendered regression passed all four founder/seed
configurations. Every cohort terminated at civilization tick 23 with unique
death receipts, zero remaining probes, inactive zero-root coverage, an
extinction checkpoint that restored with zero probes, a valid post-extinction
step 24, and zero stop/runtime errors.

## Bounded performance

The direct release microbenchmark preloads empty lit chunks, disables spawning,
and averages five World ticks. It measures scheduler cost, not renderer startup
or Swift compilation.

| Seed | Founders | Clustered chunks | Overlap ratio (`chunks / 9N`) | Clustered tick | Separated chunks | Repeated separated tick |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 46 | 20 | 9 | 0.05000 | 0.023-0.024 ms | 180 | 0.567-0.619 ms |
| 46 | 24 | 9 | 0.04167 | 0.021-0.023 ms | 216 | 0.661-0.702 ms |
| 46 | 30 | 9 | 0.03333 | 0.020-0.022 ms | 270 | 0.824-0.870 ms |
| 887 | 20 | 9 | 0.05000 | 0.020-0.025 ms | 180 | 0.531-0.561 ms |
| 887 | 24 | 9 | 0.04167 | 0.020-0.022 ms | 216 | 0.627-0.672 ms |
| 887 | 30 | 9 | 0.03333 | 0.020-0.023 ms | 270 | 0.799-0.901 ms |

Across the repeated maximum separated cases, 30 roots/270 chunks cost
0.799-0.901 ms per World tick. A separate post-gate wall-clock run recorded one
isolated 2.997 ms sample for seed 887; it was not reproduced in five repeated
runs and is retained in the evidence rather than hidden. The final timed process
reported peak footprint 188,367,520 bytes and maximum resident size 196,083,712
bytes. No claim is made beyond this exact synthetic 30-root configuration.

The normal rendered clustered layouts deduplicated to:

| Founders / seed | Roots | Covered chunks | Eliminated overlap | Ratio |
| --- | ---: | ---: | ---: | ---: |
| 20 / 46 | 20 | 12 | 168 | 0.06667 |
| 24 / 46 | 24 | 12 | 204 | 0.05556 |
| 24 / 887 | 24 | 9 | 207 | 0.04167 |
| 30 / 887 | 30 | 9 | 261 | 0.03333 |

## Normal rendered campaigns

### Campaign A — long remote coverage stress

All four scenarios used normal founder startup and the existing `/lab speed 1`
control after startup (one civilization update per second rather than the
default four) solely to retain living founders for the longer World-side
remote dwell. There was no pause, provisioned resource, terrain edit,
physiology override, or disposable World fixture.

The Observer began near the founders, moved approximately 32 chunks away,
remained remote for 41-45 World ticks, then returned using terrain-correct top
positioning. Every run retained ready sensor/path status, zero pending/refused
coverage at the captured boundaries, continued remote probe ticks, stable
coverage digest, zero runtime error, and zero physical hard failure.

| Founders / seed | Near (World/civ) | Far (World/civ) | Return (World/civ) | Remote ticks | Coverage digest | FPS near/far/return |
| --- | --- | --- | --- | ---: | --- | --- |
| 20 / 46 | 101 / 2 | 194 / 6 | 296 / 12 | 44 | `43b34fb3c4f14ec4` | 107 / 103 / 104 |
| 24 / 46 | 99 / 2 | 195 / 7 | 297 / 12 | 45 | `eabf941c7602898f` | 105 / 103 / 105 |
| 24 / 887 | 97 / 2 | 185 / 6 | 274 / 11 | 41 | `d61d862140c9ae7d` | 110 / 120 / 113 |
| 30 / 887 | 101 / 2 | 189 / 6 | 280 / 11 | 42 | `b10ef29d49306964` | 111 / 118 / 113 |

Phase-boundary steady rendering was 103-120 FPS. Initial World/render bootstrap
produced 825.318-843.483 ms maximum frame spikes. Those startup spikes are not
steady-state World tick cost and are not release-build elapsed time.

### Campaign B — default-rate cross-check

All four configurations were rerun at the unchanged default cognitive rate of
4 Hz with no speed or pause command and the same unprovisioned normal startup.
The Observer left the normal simulation region before terminal collapse,
remained remote 11-12 World ticks, and returned.

| Founders / seed | Near (World/civ) | Far (World/civ) | Return (World/civ) | Remote ticks | Probe ticks near/far/return |
| --- | --- | --- | --- | ---: | --- |
| 20 / 46 | 35 / 2 | 63 / 8 | 90 / 13 | 11 | 14 / 42 / 69 |
| 24 / 46 | 32 / 3 | 60 / 8 | 89 / 14 | 11 | 15 / 43 / 72 |
| 24 / 887 | 32 / 2 | 60 / 8 | 87 / 13 | 11 | 14 / 42 / 69 |
| 30 / 887 | 33 / 3 | 62 / 9 | 90 / 14 | 12 | 16 / 45 / 73 |

Coverage remained ready with the clustered chunk counts above; sensors and
bounded paths remained truthful; probes progressed remotely; relevant coverage
digests matched Campaign A; runtime errors and physical hard failures were zero.
The runs intentionally ended before the known unprovisioned starvation boundary
at civilization tick 23.

## Visual evidence and retained superseded attempts

Final captures from Campaign A show terrain-correct near, remote, and returned
Observer positions. Near and returned views are above terrain with World and
HUD state legible. Remote water views are above the seabed and are not
underground/cutaway artifacts. Founders are not expected to render at the
remote camera; structured state remains authoritative.

The earlier relative-teleport attempt is retained and classified exactly as:
**SUPERSEDED VISUAL EVIDENCE — HARNESS CAMERA HEIGHT DEFECT**. Its relative
teleports retained the former Y coordinate, producing misleading underground
or cutaway-like return views. It is not cited as final visual proof. A separate
post-fix attempt whose wrapper looked for an invisible chat-speed string is
retained as **SUPERSEDED HARNESS ASSERTION — STDOUT SPEED CONFIRMATION DEFECT**;
its product state is not used as final campaign evidence.

The final proof hook is launch-gated, read-only, and proof-only. It owns no
gameplay decision, mutation, or persistence. The `top` coordinate correction is
harness-only.

## Failure attacks

The final evidence includes deterministic attacks for unavailable generation,
injected refusal, stale coverage after admission, stale/duplicate/invalid probe
binding, duplicate and overlapping roots, reversed enumeration, rapid camera
movement, probe movement across a chunk boundary, last-root removal, death and
terminal cohort cleanup, stop/reset, checkpoint restore with different camera
position, bounded-path boundary/unavailable/budget distinctions, and the
maximum 30-root/270-chunk set.

Failures remain explicit and fail closed. No missing chunk is converted to an
empty observation or blocked path; no indeterminate candidate cognition is
published; no overlap duplicates a target, event, receipt, or generation
request; and no root survives loss of physical authority.

## Regression, build, and canonical gate

The final touched-owner regression matrix passed 18 selectors, **1,576/1,576
assertions**, exit 0:

| Selector | Assertions |
| --- | ---: |
| `founder-bootstrap` | 65 |
| `safe-entity-placement` | 18 |
| `candidate-physical-atomicity` | 3 |
| `checkpoint-replay` | 49 |
| `persistence-reconciliation` | 19 |
| `population-migration` | 66 |
| `observer` | 20 |
| `mortality` | 93 |
| `lifecycle` | 80 |
| `physical-actions` | 38 |
| `materials` | 35 |
| `material-rights` | 23 |
| `ecological-observation` | 68 |
| `agriculture` | 86 |
| `harvest` | 46 |
| `embodiment` | 756 |
| `bounded-autonomous-navigation` | 26 |
| `ps01-increment-02` | 85 |

The final release command was:

```sh
swift build -c release --product Pebble
```

It exited 0 and completed in 166.55 seconds. The only warnings were pre-existing
unused `lightViewM` and `lightProjM` variables in `WorldRenderer.swift`; that
file is unchanged by this increment. Build elapsed time is not runtime
performance.

The exact canonical gate was:

```sh
scripts/verify-pebblelab.sh
```

It passed all 35/35 repository steps, including 4,843/4,843 smoke assertions,
with exit 0. `PEBBLE_REGOLD` was absent; the gate refuses even an empty value and
reports goldens read-only. Regold: false.

## Minimality classification

Every changed file has one direct Increment 03 role:

### Required product

- `Sources/PebbleCore/World/PhysicalSimulationCoverage.swift`: bounded request,
  canonical union/status, stable World-owned seed derivation, and diagnostics.
- `Sources/PebbleCore/World/GameWorld.swift`: one-scheduler coverage eligibility,
  deduplication, active-only RNG isolation, and literal legacy branches.
- `Sources/PebbleCore/Game/GameCore.swift`: one generation queue, 18/6 fairness,
  retention/unloading integration, and request publication.
- `Sources/PebbleCore/Entity/AI.swift`: opt-in bounded Core path domain/result;
  legacy path API preserved.
- `Sources/Pebble/PebbleAgentController+PhysicalSimulationCoverage.swift`:
  exact session/probe/World root derivation.
- `Sources/Pebble/PebbleAgentController.swift`: current-root readiness,
  diagnostics, and bounded test seam.
- `Sources/Pebble/PebbleAgentController+Tick.swift`: fail-closed candidate
  publication boundary.
- `Sources/Pebble/PebbleAgentController+Lifecycle.swift`: lifecycle-driven
  coverage reconciliation.
- `Sources/Pebble/PebbleAgentMovementExecutor.swift`: opt-in bounded path use and
  rollback for indeterminate results.

### Required test/proof

- `Sources/pebsmoke/PebbleCorePhysicalSimulationCoverageSmoke.swift`: focused
  scheduler, RNG, path, fairness, lifecycle, and performance proofs.
- `Sources/pebsmoke/main.swift`: actual focused/performance selectors.

### Required harness

- `Sources/Pebble/PebbleIncrement03CoverageLiveProof.swift`: gated structured
  live diagnostics and camera phases.
- `Sources/Pebble/main.swift`: launch-gated proof installation and harness-only
  command surface; normal startup remains unchanged without the gate.
- `scripts/verify-pebblelab-ps01-increment-03.py`: final rendered/default-rate
  campaign runner, structured validator, and image capture orchestration.

### Required phase documentation

- `docs/pebblelab/PS01_INCREMENT_03_OBSERVER_INDEPENDENT_PHYSICAL_COVERAGE.md`.

Unnecessary files: **0**. Unused RNG domains, speculative scheduler framework,
and nonessential debug support are absent. The test-only generation-refusal
seam is bounded to fault injection; the live diagnostic hook is explicitly
launch-gated, read-only, non-authoritative, and non-persistent.

## Findings and exclusions

- P0: 0.
- P1: 0. The bounded-path readiness finding is closed.
- P2: 0.

Increment 03 status: **COMPLETE AND PUBLISHED — PASS — SENIOR REVIEW APPROVED
— REMOTE VERIFIED**.

PLAYABLE SLICE 01 status: **REQUIRED — IN PROGRESS / NOT COMPLETE**.

CIV-48 status: **NOT STARTED — IMPLEMENTATION NOT AUTHORIZED**.

This report does not select Increment 04, claim survival, claim whole-World
camera invariance, or claim generic simulation scale beyond the validated
maximum of 30 active coverage roots. Physical history that was player-only
before later entering agent coverage is outside the stronger proven contract.
Any future agent-relevant mechanic that consumes another shared RNG domain
must be audited; camera independence is not inherited automatically.
