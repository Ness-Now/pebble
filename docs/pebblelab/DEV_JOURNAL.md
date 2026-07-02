# PebbleLab Development Journal

## 2026-07-02 — Phase 5.5C behavior loop memory-goal bridge hardening smoke

Branch: `lab/pebblelab-v1`

### Objective

Harden the fixture-only behavior-loop memory-goal bridge with the scenario
`behavior_loop_memory_goal_bridge_hardening_smoke`.

### Starting Point

Phase 5.5B added the first bridge fixture connecting controlled
goal-selection-from-memory decisions to abstract selected goals/actions/results.
It produced five bridge decisions and kept behavior action execution, memory
writes, retrieval reruns, movement stack, World, and terrain out of scope.

### Implementation

- Added hardening types, report, invariant report, metrics, digest, and event
  support in `LabBehaviorLoopMemoryGoalBridge.swift`.
- Added 23 hardening cases for baseline compatibility, safety, curiosity,
  nearby observation, idle mapping, empty retrieval, low-confidence memory,
  currentGoal continuity, unknown suggested goals, missing suggested goals,
  selected action/result presence, deterministic action mapping,
  safety/curiosity conflict, known v0 goals, deterministic order, and boundary
  flags.
- Enforced safety/fear priority before memory suggestions can override the
  selected goal.
- Sanitized unknown suggested goals to the current known goal or idle fallback.
- Added `behaviorLoopMemoryGoalBridgeHardening*` metrics.
- Added `lab_behavior_loop_memory_goal_bridge_hardening_recorded`.

### Boundaries

- No behavior action execution.
- No memory mutation or write.
- No retrieval rerun.
- No movement stack or movement intent.
- No World or terrain mutation.
- No Core entity or physical placeholder movement.
- No live `agents_basic` bridge integration.
- No mood, relationships, communication, Python, LLM, embeddings, or RL.

### Validation

Commands requested for this phase:

- `git status`;
- `swift build`;
- `swift build -c release --product Pebble`;
- `swift run PebbleLab -- --scenario behavior_loop_memory_goal_bridge_hardening_smoke --seed 42 --ticks 3 --out runs/check_behavior_loop_memory_goal_bridge_hardening`;
- debug non-regression runs for bridge fixture, goal selection, memory
  retrieval, memory update, behavior loop, `agents_basic`, and
  `regression_smoke`;
- `swift run -c release pebsmoke`;
- `git diff --check`;
- `git diff --cached --check`.

Results are recorded in the Phase 5.5C commit summary.

### Next Step

Phase 5.6A — Cognitive Loop Integration Planning.

## 2026-07-02 — Phase 5.5B behavior loop memory-goal bridge fixture smoke

Branch: `lab/pebblelab-v1`

### Objective

Implement the first fixture-only behavior-loop memory-goal bridge scenario:
`behavior_loop_memory_goal_bridge_fixture_smoke`.

### Starting Point

Phase 5.5A defined the bridge contract after the behavior loop, memory update,
memory retrieval, and goal-selection-from-memory fixtures had each been created
and hardened in isolation.

### Implementation

- Added `LabBehaviorLoopMemoryGoalBridge.swift`.
- Added five synthetic bridge inputs for safety, curiosity, nearby-agent
  observation, empty retrieval, and low-confidence/currentGoal continuity.
- Produced bridge decisions with `selectedGoalForBehaviorLoop`,
  abstract `selectedAction`, action reason, memory influence reason, and
  bounded behavior result summaries.
- Added scenario support for `behavior_loop_memory_goal_bridge_fixture_smoke`.
- Wrote `behavior_loop_memory_goal_bridge_report.json`,
  `behavior_loop_memory_goal_bridge_invariant_report.json`,
  `behavior_loop_memory_goal_bridge_decisions.json`, and
  `behavior_loop_memory_goal_bridge_digest.json`.
- Added `behaviorLoopMemoryGoalBridge*` metrics.
- Added `lab_behavior_loop_memory_goal_bridge_recorded` and summary events.

### Boundaries

- No behavior action execution.
- No memory mutation or memory write.
- No retrieval rerun.
- No movement intent or movement stack.
- No World or terrain mutation.
- No Core entity or physical placeholder movement.
- No mood, relationships, communication, Python, LLM, embeddings, or RL.

### Validation

Commands requested for this phase:

- `git status`;
- `swift build`;
- `swift build -c release --product Pebble`;
- `swift run PebbleLab -- --scenario behavior_loop_memory_goal_bridge_fixture_smoke --seed 42 --ticks 3 --out runs/check_behavior_loop_memory_goal_bridge_fixture`;
- debug non-regression runs for goal selection, memory retrieval, memory
  update, behavior loop, `agents_basic`, and `regression_smoke`;
- `swift run -c release pebsmoke`;
- `git diff --check`;
- `git diff --cached --check`.

Results are recorded in the Phase 5.5B commit summary.

### Next Step

Phase 5.5C — Behavior Loop Memory-Goal Bridge Hardening.

## 2026-06-19 - Phase 4.8B Terrain Scan Smoke

Branch: `lab/pebblelab-v1`

### Objective

Implement the fixed radius-1 read-only terrain scan specified by Phase 4.8A
for one synchronized PebbleLab agent.

### Files Modified

- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/LabWorldInteraction.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/ROADMAP.md`
- `docs/pebblelab/PHASE_4_TERRAIN_SCAN_PLAN.md`
- `docs/pebblelab/DEV_JOURNAL.md`

### Technical Decisions

- The radius remains a scenario constant equal to `1`.
- The scan uses one fixed Y layer at `agent.position.y - 1`.
- Cells are emitted in nested `dz`, then `dx`, order.
- Each target independently checks loaded and ready state before `getBlock`.
- Missing/unready targets retain absent cell data and fail the smoke; they are
  never decoded as air.
- Per-cell chunk `modified`, `version`, and `dirty` state is compared around
  the guarded read.
- One aggregate event avoids per-cell event volume.
- A 15-check report gates scenario success; its no-mutation check is explicitly
  a code-review contract backed by runtime unchanged-chunk checks.

### Read-Only Guardrails

The implementation does not call block mutation, chunk generation, raycast,
pathfinding, collision, mining, construction, inventory, renderer, registry,
or save/load paths. It remains single-agent and has no configurable radius.

### Validation Commands

The local managed environment required SwiftPM's internal sandbox to be
disabled and module caches redirected under `.build`; the underlying build and
run products are unchanged.

- `swift build --disable-sandbox`
- `swift build --disable-sandbox -c release --product PebbleLab -j 4`
- `swift build --disable-sandbox -c release --product Pebble -j 4`
- `swift run --disable-sandbox -c release PebbleLab -- --scenario terrain_scan_smoke --seed 42 --ticks 5 --out runs/check_terrain_scan_smoke`
- `swift run --disable-sandbox -c release PebbleLab -- --scenario world_observation_multi_smoke --seed 42 --ticks 5 --out runs/check_world_observation_after_terrain_scan`
- `swift run --disable-sandbox -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_terrain_scan`
- `swift run --disable-sandbox -c release pebsmoke`

### Results

- Terrain scan planned/observed/loaded/ready: `9/9/9/9`.
- Radius/order/relation: `1 / dz_then_dx / around_below`.
- Unique chunks/distinct block IDs: `1/1`.
- Chunk state unchanged and final divergence zero.
- Invariant report: `15 passed, 0 failed`.
- Existing world-observation and regression scenarios passed.
- `pebsmoke`: `456 passed, 0 failed`.

### Next Step

Phase 4.8C: terrain scan edge and invariant hardening, followed later by
read-only terrain semantics/traversability planning. Terrain mutation remains
deferred.

## 2026-06-19 - Phase 4.8C Edge Terrain Scan Smoke

Branch: `lab/pebblelab-v1`

### Objective

Validate the existing fixed radius-1 read-only terrain scan when its origin is
on both an X and Z chunk boundary.

### Files Modified

- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/LabWorldInteraction.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`

### Position And Chunk Contract

- Agent position: `(16, 64, 16)`.
- Scan origin: `(16, 63, 16)`.
- Fixed radius/order: `1 / dz_then_dx`.
- Target chunks: `(0,0)`, `(1,0)`, `(0,1)`, `(1,1)`.
- Expected and observed unique chunk count: `4`.

The scenario reuses `scanTerrainAroundBelow` without a second scan path. The
existing scenario preparation loads the radius-1 chunk region before the scan;
the scan itself neither loads nor generates chunks.

### Invariant Hardening

`terrain_scan_edge_smoke` adds two conditional checks to the shared report:

- `edge_scan_crosses_chunk_boundary` requires more than one unique chunk;
- `edge_scan_expected_unique_chunks` requires exactly four chunks.

The original `terrain_scan_smoke` keeps its existing 15-check contract. The
edge scenario has 17 checks.

### Read-Only Guardrails

Every cell still checks loaded/ready state before `World.getBlock`, decodes
only present cells, and compares chunk `modified`, `version`, and `dirty`
state. No mutation, chunk loading, registry, save/load, renderer, pathfinding,
collision, or gameplay path was added.

### Validation Commands

- `swift build`
- `swift run -c release PebbleLab -- --scenario terrain_scan_edge_smoke --seed 42 --ticks 5 --out runs/check_terrain_scan_edge_smoke`
- `swift run -c release PebbleLab -- --scenario terrain_scan_smoke --seed 42 --ticks 5 --out runs/check_terrain_scan_smoke_after_edge`
- `swift run -c release PebbleLab -- --scenario world_observation_multi_smoke --seed 42 --ticks 5 --out runs/check_world_observation_after_edge_scan`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_edge_scan`
- `swift build -c release --product Pebble`
- `swift run -c release pebsmoke`

### Results

- Planned/observed/loaded/ready cells: `9/9/9/9`.
- Unique chunks: `4`.
- Chunk state unchanged and terrain scan success: `true`.
- Edge invariant report: `17 passed, 0 failed`.
- Central terrain scan, world observation, and regression scenarios passed.
- Pebble release build passed.
- `pebsmoke`: `456 passed, 0 failed`.

### Next Step

Phase 4.8D: terrain scan contract cleanup and shared invariant hardening before
planning terrain semantics or traversability. Terrain mutation remains
deferred.

## 2026-06-19 - Phase 4.8D Terrain Scan Contract Cleanup

Branch: `lab/pebblelab-v1`

### Objective

Centralize the fixed terrain-scan scenario rules without changing the
observable behavior of the central or edge smoke tests.

### Files Modified

- `Sources/PebbleLab/LabTerrainScanContract.swift` (new)
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/LabWorldInteraction.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`

### Refactor

`LabTerrainScanScenarioContract` now owns each scenario's:

- agent X/Z position;
- fixed radius, relation, and ordering;
- expected planned and observed cell counts;
- optional expected unique chunk count;
- chunk-boundary requirement.

`terrainScanScenarioContract(for:)` defines the two existing contracts, and
`isTerrainScanScenario` centralizes scenario recognition. Scenario preparation
uses contract positions, `main.swift` passes the selected contract into the
shared scan/report path, and invariant expectations are derived from the same
contract. Edge checks retain their existing names and are enabled by the
contract rather than a scenario string inside the report.

### Unchanged Behavior

- No scenario, JSON output, metric, or event was added.
- Radius remains fixed at `1`; scans remain single-agent and read-only.
- Central scan: position `(8,64,8)`, one chunk, 15 checks.
- Edge scan: position `(16,64,16)`, four chunks, 17 checks.
- Loaded/ready guards, deterministic `dz_then_dx` order, packed-cell decoding,
  and unchanged-chunk checks are unchanged.
- No PebbleCore, registry, save/load, renderer, resource, mutation,
  pathfinding, collision, or terrain-semantics code changed.

### Validation Commands

- `swift build`
- `swift run -c release PebbleLab -- --scenario terrain_scan_smoke --seed 42 --ticks 5 --out runs/check_terrain_scan_smoke_after_contract_cleanup`
- `swift run -c release PebbleLab -- --scenario terrain_scan_edge_smoke --seed 42 --ticks 5 --out runs/check_terrain_scan_edge_smoke_after_contract_cleanup`
- `swift run -c release PebbleLab -- --scenario world_observation_multi_smoke --seed 42 --ticks 5 --out runs/check_world_observation_after_contract_cleanup`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_contract_cleanup`
- `swift build -c release --product Pebble`
- `swift run -c release pebsmoke`

### Results

- Central terrain scan: success, `9/9/9/9` planned/observed/loaded/ready,
  unique chunks `1`, invariant checks `15/15`.
- Edge terrain scan: success, `9/9/9/9`, unique chunks `4`, invariant checks
  `17/17`, both edge checks preserved.
- World observation and regression scenarios passed.
- Pebble release build passed.
- `pebsmoke`: `456 passed, 0 failed`.

### Next Step

Phase 4.9A: read-only terrain semantics planning. Define a minimal semantic
classification contract before adding any classification code. Mutation,
pathfinding, collision, and traversability decisions remain out of scope.

## 2026-06-19 — Phase 4.9A Read-Only Terrain Semantics Planning

Branch: `lab/pebblelab-v1`

### Objective

Define the first bounded terrain-semantics contract for the cells already
captured by the central and edge terrain scans, without implementing a Swift
classifier or changing runtime behavior.

### Files Created Or Modified

- `docs/pebblelab/PHASE_4_TERRAIN_SEMANTICS_PLAN.md` (new)
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`

### Technical Decisions

- Future classification is a pure `LabTerrainScanCell` to semantic-cell
  transformation and must not reread `World`.
- Raw scan cells remain unchanged; future semantic results belong in a
  parallel `semanticCells` array with identical ordering.
- Exact air and liquid identities are preferred over broad substring rules.
- Valid unmatched blocks fall back to `other`; the current scan cell lacks a
  reliable solid flag, so 4.9B must not infer solidity universally.
- Semantic labels explicitly do not imply traversability, collision, hazard,
  mining value, or agent behavior.

### Risks

Block names and IDs can be over-interpreted, broad plant/liquid rules can
misclassify blocks, and semantic labels can be mistaken for navigation facts.
The plan mitigates these risks with conservative exact rules, confidence and
reason fields, `unknown`/`other` fallbacks, one-to-one invariants, and a strict
no-world-access boundary.

### Still Prohibited

No Swift, PebbleCore, registry, save/load, renderer, resource, or golden change
was made. Pathfinding, traversability, collision, mutation, mining,
construction, inventory, multi-agent/vertical scans, and ML integrations
remain out of scope.

### Validation Commands

- `swift build`
- `swift run -c release pebsmoke`

### Results

- Documentation-only diff confirmed; no Swift file changed.
- `swift build` passed.
- `pebsmoke`: `456 passed, 0 failed`.

### Next Step

Phase 4.9B: implement terrain cell semantic classification v0 as a pure,
read-only transformation over the existing nine scan cells.

## 2026-06-19 — Phase 4.9B Terrain Cell Semantic Classification V0

Branch: `lab/pebblelab-v1`

### Objective

Classify the nine cells already captured by both terrain-scan scenarios using
a pure PebbleLab transform, without rereading or mutating the world and without
introducing traversability or agent behavior.

### Files Created Or Modified

- `Sources/PebbleLab/LabTerrainSemantics.swift` (new)
- `Sources/PebbleLab/LabWorldInteraction.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`
- `docs/pebblelab/PHASE_4_TERRAIN_SEMANTICS_PLAN.md`

### Classification Rules

- Unsuccessful, unavailable, incomplete, or invalid packed cells become
  `unknown`.
- Exact air names become `air`; exact `water` and `lava` become `liquid`.
- A reviewed exact plant set plus `_leaves` and `_sapling` suffixes becomes
  `plantLike`.
- A small reviewed exact set of common blocks becomes `solid`.
- Every other valid cell becomes `other`.

No broad name substring rule is used. The classifier receives only
`LabTerrainScanCell`; it has no `World` parameter or PebbleCore dependency.

### Outputs And Invariants

- `terrain_scan_snapshot.json` retains raw `cells` and adds ordered
  `semanticCells` plus a separate `semanticSummary`.
- `metrics.json` adds the eight `terrainSemantic*` fields.
- `events.ndjson` adds one `lab_terrain_semantics_recorded` event per scan.
- `terrain_semantics_invariant_report.json` checks scan presence, one-to-one
  mapping, unavailable-cell handling, packed values, counts, ordering, raw
  scan success, pure classification, and no mutation path.
- Final run success requires both the existing terrain scan contract and the
  semantic invariant report; raw `terrainScanSuccess` keeps its prior meaning.

### Still Prohibited

No PebbleCore, registry, save/load, renderer, resource, or golden path changed.
World rereads, chunk loading, mutation, traversability, pathfinding, collision,
mining, construction, multi-agent scans, and behavior changes remain out of
scope.

### Validation Commands

- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario terrain_scan_smoke --seed 42 --ticks 5 --out runs/check_terrain_semantics_central`
- `swift run -c release PebbleLab -- --scenario terrain_scan_edge_smoke --seed 42 --ticks 5 --out runs/check_terrain_semantics_edge`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_terrain_semantics`
- `swift run -c release PebbleLab -- --scenario world_observation_multi_smoke --seed 42 --ticks 5 --out runs/check_world_observation_after_terrain_semantics`
- `swift run -c release pebsmoke`

### Results

- Debug and Pebble release builds passed.
- Central terrain semantics: `9` cells classified, `10/10` semantic checks,
  raw scan success and semantic success both `true`.
- Edge terrain semantics: `9` cells classified across `4` chunks, `10/10`
  semantic checks, raw scan success and semantic success both `true`.
- With seed `42`, all captured cells in both runs were exact `water` identities
  and classified as `liquid` with confidence `1.0`.
- Regression and multi-agent world observation scenarios passed.
- `pebsmoke`: `456 passed, 0 failed`.

### Next Step

Phase 4.9C: harden central/edge semantic fixtures and rule coverage before any
docs-only traversability planning. Traversability, pathfinding, collision, and
mutation remain explicitly deferred.

## 2026-06-19 — Phase 4.9C Terrain Semantics Fixture Smoke

Branch: `lab/pebblelab-v1`

### Objective

Exercise every terrain semantic classification branch with deterministic
synthetic `LabTerrainScanCell` fixtures, without world access, chunk setup,
agents, or gameplay behavior.

### Files Modified

- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/LabTerrainSemantics.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`

### Rule Coverage

The smoke contains 21 fixtures:

- exact water/lava liquid identities;
- all three exact air identities;
- five reviewed solid identities, including `grass_block` as solid rather
  than plant-like;
- five reviewed exact/suffix plant identities;
- unavailable, unsuccessful, incomplete, and invalid packed cells as unknown;
- a valid `mystery_block` fallback as other.

Fixture IDs are stable synthetic values. Packed values are produced directly
from each fixture's ID and metadata; no registry is consulted.

### Outputs

- `terrain_semantics_fixture_report.json` records expected and actual kind and
  reason for every fixture.
- `metrics.json` exposes fixture totals, per-kind counts, and success.
- `events.ndjson` contains one `lab_terrain_semantics_fixture_recorded` event.

### Still Prohibited

No PebbleCore, registry, save/load, renderer, resource, or golden path changed.
The scenario creates no agent or chunk and performs no world read. Mutation,
traversability, pathfinding, collision, mining, construction, and ML systems
remain out of scope.

### Validation Commands

- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario terrain_semantics_fixture_smoke --seed 42 --ticks 0 --out runs/check_terrain_semantics_fixture`
- `swift run -c release PebbleLab -- --scenario terrain_scan_smoke --seed 42 --ticks 5 --out runs/check_terrain_semantics_central_after_fixtures`
- `swift run -c release PebbleLab -- --scenario terrain_scan_edge_smoke --seed 42 --ticks 5 --out runs/check_terrain_semantics_edge_after_fixtures`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_semantics_fixtures`
- `swift run -c release PebbleLab -- --scenario world_observation_multi_smoke --seed 42 --ticks 5 --out runs/check_world_observation_after_semantics_fixtures`
- `swift run -c release pebsmoke`

### Results

- Fixture report: `21 passed, 0 failed`.
- Expected-kind counts: unknown `5`, air `3`, solid `5`, liquid `2`,
  plant-like `5`, other `1`.
- Debug and Pebble release builds passed.
- Central and edge terrain scans passed with nine semantic cells each; edge
  coverage remains four chunks.
- Regression and multi-agent world observation scenarios passed.
- `pebsmoke`: `456 passed, 0 failed`.

### Next Step

Phase 4.10A: terrain traversability planning, docs-only. Define the boundary
between descriptive semantics and possible movement evidence before adding
any traversability, pathfinding, collision, or behavior code.

## 2026-06-19 — Phase 4.10A Terrain Traversability Planning

Branch: `lab/pebblelab-v1`

### Objective

Define a conservative read-only traversability contract without implementing
traversability, vertical scanning, pathfinding, collision, or agent behavior.

### Files Created Or Modified

- `docs/pebblelab/PHASE_4_TRAVERSABILITY_PLAN.md` (new)
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`

### Technical Decisions

- Semantic kind remains a description of one captured cell.
- Traversability requires at least a support/feet/head semantic column and is
  only a candidate occupancy assessment.
- Pathfinding remains graph search over positions and is not part of the
  traversability classifier.
- Collision remains PebbleCore's physical truth and cannot be replaced by a
  read-only label.
- Phase 4.10B should be a pure synthetic column fixture smoke. Connecting to a
  real vertical scan is deferred to a later contract phase.
- Missing or ambiguous evidence returns `unknown`; liquid support is `unsafe`;
  solid support with clear air feet/head is only a `traversable` candidate.

### Risks

The main risks are conflating semantics with movement, declaring positions
traversable from below-only evidence, overinterpreting liquids/plants/other,
rereading or mutating the world, coupling fixtures to block IDs, and quietly
introducing pathfinding or collision assumptions. Separate types, pure
synthetic columns, conservative results, and explicit review invariants bound
those risks.

### Still Prohibited

No Swift, PebbleCore, registry, save/load, renderer, resource, or golden file
was changed. Traversability code, vertical scans, pathfinding, collision,
movement decisions, mutation, mining, construction, multi-agent navigation,
and ML integrations remain out of scope.

### Validation Commands

- `swift build`
- `swift run -c release pebsmoke`

### Results

- Documentation-only diff confirmed; no Swift file changed.
- `swift build` passed.
- `pebsmoke`: `456 passed, 0 failed`.

### Next Step

Phase 4.10B: add a pure `terrain_traversability_fixture_smoke` over synthetic
support/feet/head semantic columns, with no world access or gameplay behavior.

## 2026-06-19 — Phase 4.10B Terrain Traversability Fixture Smoke

Branch: `lab/pebblelab-v1`

### Objective

Implement and audit a pure traversability classifier over synthetic
support/feet/head semantic columns, without connecting it to a world scan,
physics, pathfinding, or agent behavior.

### Files Created Or Modified

- `Sources/PebbleLab/LabTerrainTraversability.swift` (new)
- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`
- `docs/pebblelab/PHASE_4_TRAVERSABILITY_PLAN.md`

### Traversability V0 Rules

- Missing cells and unknown semantics return `unknown`.
- Solid feet/head returns `occupiedVerticalSpace`.
- Air support returns `unsupported`.
- Liquid support or vertical liquid returns `unsafe`.
- Other support and plant-like vertical space return `unknown`.
- Solid support with air feet/head returns a `traversable` candidate.
- Remaining combinations fall back to `other`.

The classifier accepts only `LabTerrainColumnSemantic`. It has no `World`
parameter and produces no neighbors, routes, costs, movement, or actions.

### Fixtures And Outputs

Fifteen fixtures cover clear support, unsupported air, solid obstructions,
liquid support/space, unknown semantics, plant-like space, missing data, and
unclassified support.

- `terrain_traversability_fixture_report.json` records expected and actual
  kind/reason for each fixture.
- `terrain_traversability_invariant_report.json` audits 11 runtime and
  code-review contracts.
- `metrics.json` exposes result and fixture counts.
- `events.ndjson` contains one `lab_terrain_traversability_recorded` event.

### Still Prohibited

No PebbleCore, registry, save/load, renderer, resource, or golden path changed.
No live vertical scan, world read, mutation, pathfinding, collision, neighbor
expansion, route, cost, movement, goal selection, or multi-agent navigation
was added.

### Validation Commands

- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario terrain_traversability_fixture_smoke --seed 42 --ticks 0 --out runs/check_terrain_traversability_fixture`
- `swift run -c release PebbleLab -- --scenario terrain_semantics_fixture_smoke --seed 42 --ticks 0 --out runs/check_terrain_semantics_fixture_after_traversability`
- `swift run -c release PebbleLab -- --scenario terrain_scan_smoke --seed 42 --ticks 5 --out runs/check_terrain_scan_after_traversability`
- `swift run -c release PebbleLab -- --scenario terrain_scan_edge_smoke --seed 42 --ticks 5 --out runs/check_terrain_scan_edge_after_traversability`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_traversability`
- `swift run -c release PebbleLab -- --scenario world_observation_multi_smoke --seed 42 --ticks 5 --out runs/check_world_observation_after_traversability`
- `swift run -c release pebsmoke`

### Results

- Fixture report: `15 passed, 0 failed`.
- Invariant report: `11 passed, 0 failed`.
- Result counts: traversable `1`, blocked `0`, unknown `8`, unsupported `1`,
  unsafe `3`, occupied vertical space `2`, other `0`.
- Debug and Pebble release builds passed.
- Semantic fixture, central terrain scan, edge terrain scan, regression, and
  multi-agent world observation scenarios passed.
- The edge scan remains successful across four chunks.
- `pebsmoke`: `456 passed, 0 failed`.

### Next Step

Phase 4.11A: vertical column scan planning, docs-only. Define how support,
feet, and head cells could be captured read-only before any live
traversability integration is considered.

## 2026-06-19 — Phase 4.11A Vertical Column Scan Planning

Branch: `lab/pebblelab-v1`

### Objective

Define a bounded read-only support/feet/head scan contract before connecting
synthetic traversability rules to real terrain evidence.

### Files Created Or Modified

- `docs/pebblelab/PHASE_4_VERTICAL_COLUMN_SCAN_PLAN.md` (new)
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`

### Technical Decisions

- Phase 4.11B begins central-only at `(8, y, 8)` with fixed radius one.
- Horizontal order remains `dz_then_dx`; each column uses deterministic
  `support_feet_head` order.
- Nine columns produce exactly 27 planned raw cells.
- Every role independently checks loaded/ready before reading and audits chunk
  modified/version/dirty state.
- Raw scan, semantic transform, traversability transform, future pathfinding,
  and future movement remain separate layers with separate success contracts.
- Existing terrain snapshots stay unchanged; column scans receive dedicated
  outputs and invariants.
- A focused future `LabTerrainColumnScan.swift` module is preferred over
  placing scan logic in `main.swift`.

### Layer Relationship

The vertical scan is the only world-reading layer. Semantics transform its
captured cells without rereading. Traversability transforms complete semantic
columns without world access. Pathfinding and collision remain future,
separate concerns; no agent action consumes the result in 4.11B.

### Risks

The plan addresses unloaded-as-air mistakes, repeated world reads, duplicated
scan logic, monolithic orchestration, premature pathfinding/collision,
regression of existing snapshots, engine coupling, configurable scope growth,
and unaudited output growth through fixed bounds and layered reports.

### Still Prohibited

No Swift, PebbleCore, registry, save/load, renderer, resource, or golden file
was changed. Vertical scanning, pathfinding, collision, movement, goal
selection, mutation, mining, construction, multi-agent scans, configurable
radius, and ML integrations remain out of scope in this docs-only phase.

### Validation Commands

- `swift build`
- `swift run -c release pebsmoke`

### Results

- Documentation-only diff confirmed; no Swift file changed.
- `swift build` passed.
- `pebsmoke`: `456 passed, 0 failed`.

### Next Step

Phase 4.11B: implement central-only `terrain_column_scan_smoke` with nine
columns, 27 guarded raw reads, dedicated snapshot/metrics/event, and a raw
invariant report.

## 2026-06-19 — Phase 4.11B Terrain Column Scan Smoke

Branch: `lab/pebblelab-v1`

### Objective

Implement the first real read-only support/feet/head column scan around one
synchronized central agent, without adding navigation, collision, movement,
or mutation behavior.

### Files Created Or Modified

- `Sources/PebbleLab/LabTerrainColumnScan.swift` (new)
- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`
- `docs/pebblelab/PHASE_4_VERTICAL_COLUMN_SCAN_PLAN.md`

### Technical Decisions

- The scenario uses one agent at central coordinates `(8, y, 8)`, fixed radius
  one, nine columns, and exactly 27 cells.
- Horizontal order is `dz_then_dx`; vertical order is
  `support_feet_head`.
- Each role independently checks loaded/ready, reads only when both hold, and
  compares chunk modified/version/dirty state before and after.
- `LabTerrainColumnScan.swift` owns raw capture, pure semantic/traversability
  derivation, summaries, and the 18-check invariant report; `main.swift` only
  orchestrates the run and outputs.
- Existing terrain scan snapshots are unchanged. Column evidence is written to
  dedicated snapshot and invariant files.

### Outputs And Invariants

- `terrain_column_scan_snapshot.json`
- `terrain_column_scan_invariant_report.json`
- `terrainColumnScan*` and separate derived metrics in `metrics.json`
- one `lab_terrain_column_scan_recorded` event
- 18 checks covering links, divergence, fixed bounds and order, loaded/ready
  guards, role completeness, coordinate uniqueness, packed cells, unchanged
  chunks, and explicit no-mutation/no-pathfinding/no-movement review guards

### Still Prohibited

No PebbleCore, registry, save/load, renderer, resource, or golden change was
made. No mutation, pathfinding, collision, route, cost, movement command,
goal selection, edge scan, multi-agent scan, or configurable radius was added.

### Validation Commands

- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario terrain_column_scan_smoke --seed 42 --ticks 5 --out runs/check_terrain_column_scan`
- `swift run -c release PebbleLab -- --scenario terrain_traversability_fixture_smoke --seed 42 --ticks 0 --out runs/check_terrain_traversability_fixture_after_column_scan`
- `swift run -c release PebbleLab -- --scenario terrain_semantics_fixture_smoke --seed 42 --ticks 0 --out runs/check_terrain_semantics_fixture_after_column_scan`
- `swift run -c release PebbleLab -- --scenario terrain_scan_smoke --seed 42 --ticks 5 --out runs/check_terrain_scan_after_column_scan`
- `swift run -c release PebbleLab -- --scenario terrain_scan_edge_smoke --seed 42 --ticks 5 --out runs/check_terrain_scan_edge_after_column_scan`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_column_scan`
- `swift run -c release PebbleLab -- --scenario world_observation_multi_smoke --seed 42 --ticks 5 --out runs/check_world_observation_after_column_scan`
- `swift run -c release pebsmoke`

### Results

- Central raw scan: nine columns, 27/27 observed, loaded, and ready cells.
- Chunk state remained unchanged and raw scan success was true.
- Invariant report: `18 passed, 0 failed`.
- Semantic derivation covered 27 cells; traversability derivation covered nine
  columns and remained separate from raw scan success.
- All required builds and existing scenario regressions passed.
- `pebsmoke`: `456 passed, 0 failed`.

### Next Step

Phase 4.11C: add an edge-position terrain column scan smoke that reuses the
same fixed read-only contract across chunk boundaries.

## 2026-06-19 — Phase 4.11C Terrain Column Scan Edge Smoke

Branch: `lab/pebblelab-v1`

### Objective

Validate the existing read-only support/feet/head column scan at a chunk
corner without introducing a second scan path or expanding into navigation.

### Files Modified

- `Sources/PebbleLab/LabTerrainColumnScan.swift`
- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`
- `docs/pebblelab/PHASE_4_VERTICAL_COLUMN_SCAN_PLAN.md`

### Technical Decisions

- A small `LabTerrainColumnScanScenarioContract` centralizes scenario,
  position, fixed radius, expected column/cell counts, expected chunk count,
  and boundary-crossing requirements.
- The central scenario remains at `(8, y, 8)`; the edge scenario uses exactly
  `(16, y, 16)`.
- Both scenarios call the unchanged guarded `scanTerrainColumns` read path.
- The edge 3x3 footprint spans exactly chunks `(0,0)`, `(1,0)`, `(0,1)`, and
  `(1,1)`.
- The common 18-check report is preserved; the edge contract adds two checks
  for boundary crossing and exactly four unique chunks.

### Outputs And Derived Layers

The edge scenario reuses `terrain_column_scan_snapshot.json`,
`terrain_column_scan_invariant_report.json`, `metrics.json`, and
`events.ndjson`. Its 27 semantics and nine traversability values are derived
from captured cells without rereading the world and remain separate from
agent decisions.

### Still Prohibited

No PebbleCore, registry, save/load, renderer, resource, or golden file was
changed. No mutation, pathfinding, collision, route, cost, movement command,
goal selection, multi-agent scan, or configurable radius was added.

### Validation Commands

- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario terrain_column_scan_smoke --seed 42 --ticks 5 --out runs/check_terrain_column_scan_after_edge`
- `swift run -c release PebbleLab -- --scenario terrain_column_scan_edge_smoke --seed 42 --ticks 5 --out runs/check_terrain_column_scan_edge`
- `swift run -c release PebbleLab -- --scenario terrain_traversability_fixture_smoke --seed 42 --ticks 0 --out runs/check_terrain_traversability_fixture_after_column_edge`
- `swift run -c release PebbleLab -- --scenario terrain_semantics_fixture_smoke --seed 42 --ticks 0 --out runs/check_terrain_semantics_fixture_after_column_edge`
- `swift run -c release PebbleLab -- --scenario terrain_scan_smoke --seed 42 --ticks 5 --out runs/check_terrain_scan_after_column_edge`
- `swift run -c release PebbleLab -- --scenario terrain_scan_edge_smoke --seed 42 --ticks 5 --out runs/check_terrain_scan_edge_after_column_edge`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_column_edge`
- `swift run -c release PebbleLab -- --scenario world_observation_multi_smoke --seed 42 --ticks 5 --out runs/check_world_observation_after_column_edge`
- `swift run -c release pebsmoke`

### Results

- Agent position: `(16,64,16)`.
- Edge raw scan: nine columns and 27/27 observed, loaded, ready cells.
- Unique chunks: exactly four, `(0,0)`, `(1,0)`, `(0,1)`, `(1,1)`.
- Chunk state remained unchanged; raw and derived success values were true.
- Edge invariant report: `20 passed, 0 failed`.
- Central scan retained its `18 passed, 0 failed` report.
- All required builds and existing scenario regressions passed.
- `pebsmoke`: `456 passed, 0 failed`.

### Next Step

Phase 4.11D: clean up and review the shared column-scan contracts and invariant
surface before planning pathfinding or any behavior consuming traversability.

## 2026-06-19 — Phase 4.12A Terrain Pathfinding Planning

Branch: `lab/pebblelab-v1`

### Objective

Define a strict, bounded pathfinding contract before introducing any graph
search code or connecting traversability evidence to movement.

### Files Created Or Modified

- `docs/pebblelab/PHASE_4_PATHFINDING_PLAN.md` (new)
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`

### Technical Decisions

- Phase 4.12B will be `terrain_pathfinding_fixture_smoke`, with synthetic
  traversability grids only and no `World`, chunks, or real agents.
- Bounded BFS is preferred over A* for uniform-cost fixture grids.
- Only exact `.traversable` nodes are passable in v0.
- Neighbors are four-directional in fixed north/east/south/west order.
- Search uses uniform cost one, a mandatory `maxVisited`, and visited-node
  tracking.
- Results are abstract evidence only and never command movement.

### Layer Distinctions

Scans capture world evidence; semantics describe cells; traversability
evaluates candidate columns; pathfinding searches an abstract graph; movement
executes a request; collision remains engine truth. Agent decisions select
goals independently. None of these layers is allowed to silently stand in for
another.

### Risks

The plan addresses premature live integration, confusion between route and
movement, collision overclaims, passable unknown/unsafe nodes, nondeterministic
ties, infinite loops, unbounded graph growth, premature A*, world access or
mutation, and cost complexity before fixture coverage.

### Still Prohibited

No Swift, PebbleCore, registry, save/load, renderer, resource, or golden file
was changed. Pathfinding code, A*, Dijkstra, graph expansion, live world reads,
collision, movement, goals, mutation, mining, construction, multi-agent
navigation, and ML integrations remain out of scope.

### Validation Commands

- `swift build`
- `swift run -c release pebsmoke`

### Results

- Documentation-only diff confirmed; no Swift file changed.
- `swift build` passed.
- `pebsmoke`: `456 passed, 0 failed`.

### Next Step

Phase 4.12B: implement a pure `terrain_pathfinding_fixture_smoke` using
bounded deterministic BFS over synthetic traversability grids.

## 2026-06-19 — Phase 4.12B Terrain Pathfinding Fixture Smoke

Branch: `lab/pebblelab-v1`

### Objective

Validate a bounded deterministic path search over synthetic traversability
grids without connecting search to world reads, live scans, agents, movement,
collision, or mutation.

### Files Created Or Modified

- `Sources/PebbleLab/LabTerrainPathfinding.swift` (new)
- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`
- `docs/pebblelab/PHASE_4_PATHFINDING_PLAN.md`

### BFS Contract

- Only exact `.traversable` synthetic nodes are passable.
- Expansion order is fixed: north, east, south, west.
- Edges are four-directional, horizontal, and uniform-cost.
- Start and goal must exist and be traversable.
- Discovered nodes, including start, count against mandatory `maxVisited`.
- Visited tracking prevents cycles; exceeding the bound returns
  `searchLimitReached`.
- Results are abstract evidence only and do not command movement or claim
  collision safety.

### Fixtures And Outputs

Twelve fixtures cover straight and turning paths, invalid start/goal, a blocked
wall, unknown and unsafe detours, forbidden diagonal shortcuts, bounded-search
failure, deterministic tie-breaking, identical start/goal, and missing goal.

Outputs:

- `terrain_pathfinding_fixture_report.json`
- `terrain_pathfinding_invariant_report.json`
- `terrainPathfinding*` metrics
- one `lab_terrain_pathfinding_fixture_recorded` event

The invariant report contains 15 checks for input/status coherence, path node
eligibility, endpoints, four-neighbor steps, diagonal exclusion, visited
bounds, deterministic order, summary counts, and explicit no-world,
no-mutation, no-movement, and no-collision review guards.

### Still Prohibited

No PebbleCore, registry, save/load, renderer, resource, or golden file was
changed. No live pathfinding, `World`, chunk, live scan, real agent, movement,
collision, goal selection, behavior tree, mutation, A*, Dijkstra, diagonal,
terrain cost, multi-agent navigation, or ML integration was added.

### Validation Commands

- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario terrain_pathfinding_fixture_smoke --seed 42 --ticks 0 --out runs/check_terrain_pathfinding_fixture`
- `swift run -c release PebbleLab -- --scenario terrain_column_scan_smoke --seed 42 --ticks 5 --out runs/check_column_scan_after_pathfinding_fixture`
- `swift run -c release PebbleLab -- --scenario terrain_column_scan_edge_smoke --seed 42 --ticks 5 --out runs/check_column_scan_edge_after_pathfinding_fixture`
- `swift run -c release PebbleLab -- --scenario terrain_traversability_fixture_smoke --seed 42 --ticks 0 --out runs/check_traversability_fixture_after_pathfinding_fixture`
- `swift run -c release PebbleLab -- --scenario terrain_semantics_fixture_smoke --seed 42 --ticks 0 --out runs/check_semantics_fixture_after_pathfinding_fixture`
- `swift run -c release PebbleLab -- --scenario terrain_scan_smoke --seed 42 --ticks 5 --out runs/check_terrain_scan_after_pathfinding_fixture`
- `swift run -c release PebbleLab -- --scenario terrain_scan_edge_smoke --seed 42 --ticks 5 --out runs/check_terrain_scan_edge_after_pathfinding_fixture`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_pathfinding_fixture`
- `swift run -c release PebbleLab -- --scenario world_observation_multi_smoke --seed 42 --ticks 5 --out runs/check_world_observation_after_pathfinding_fixture`
- `swift run -c release pebsmoke`

### Results

- Fixture report: `12 passed, 0 failed`.
- Status counts: found `6`, not found `2`, invalid start `1`, invalid goal
  `2`, search limit reached `1`, unknown `0`.
- Invariant report: `15 passed, 0 failed`.
- Debug and Pebble release builds passed.
- Column, terrain, semantics, traversability, regression, and multi-agent world
  observation scenarios passed.
- `pebsmoke`: `456 passed, 0 failed`.

### Next Step

Phase 4.12C: harden fixture coverage and clean up the pathfinding contract
before any docs-only plan for live pathfinding integration.

## 2026-06-19 — Phase 4.12C Pathfinding Fixture Hardening

Branch: `lab/pebblelab-v1`

### Objective

Strengthen the bounded fixture-only BFS contract with malformed requests,
duplicate coordinates, cycles, vertical separation, and more demanding
deterministic tie-breaking before considering any live integration.

### Files Modified

- `Sources/PebbleLab/LabTerrainPathfinding.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`
- `docs/pebblelab/PHASE_4_PATHFINDING_PLAN.md`

### New Fixtures

- `missing_start_invalid`
- `unsupported_neighbor_mode_unknown`
- `non_positive_search_limit_reached`
- `duplicate_coordinates_first_node_wins`
- `cycle_graph_does_not_loop`
- `cycle_graph_not_found_does_not_loop`
- `vertical_neighbor_not_used`
- `complex_equal_paths_neighbor_order_stable`

The suite grows from 12 to 20 fixtures.

### Contract Decisions

- Duplicate coordinates use the first node encountered; BFS and invariants
  share the same first-wins map helper.
- Unsupported neighbor mode returns `.unknown` with reason
  `unsupported_neighbor_mode`.
- Non-positive `maxVisited` returns `.searchLimitReached` with reason
  `non_positive_search_limit`.
- Fixture results record optional expected reasons and actual reasons; expected
  reasons participate in pass/fail.
- Visited tracking must terminate reachable and unreachable cycles.
- Found paths remain horizontal, four-directional, and contain no repeated
  node.

### Invariant Hardening

Eight checks cover missing start, unsupported mode, non-positive limit,
duplicate coordinates, cycles, vertical steps, repeated path nodes, and reason
matching. Existing checks remain, with `every_fixture_has_start_goal_keys`
clarifying that request keys exist even when their nodes intentionally do not.
The report grows from 15 to 23 checks.

### Still Prohibited

No PebbleCore, registry, save/load, renderer, resource, or golden file was
changed. No `World`, chunk, live scan, real agent, live pathfinding, movement,
collision, mutation, A*, Dijkstra, diagonal, weighted cost, multi-agent
navigation, or ML integration was added.

### Validation Commands

- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario terrain_pathfinding_fixture_smoke --seed 42 --ticks 0 --out runs/check_terrain_pathfinding_fixture_hardened`
- `swift run -c release PebbleLab -- --scenario terrain_column_scan_smoke --seed 42 --ticks 5 --out runs/check_column_scan_after_pathfinding_hardening`
- `swift run -c release PebbleLab -- --scenario terrain_column_scan_edge_smoke --seed 42 --ticks 5 --out runs/check_column_scan_edge_after_pathfinding_hardening`
- `swift run -c release PebbleLab -- --scenario terrain_traversability_fixture_smoke --seed 42 --ticks 0 --out runs/check_traversability_fixture_after_pathfinding_hardening`
- `swift run -c release PebbleLab -- --scenario terrain_semantics_fixture_smoke --seed 42 --ticks 0 --out runs/check_semantics_fixture_after_pathfinding_hardening`
- `swift run -c release PebbleLab -- --scenario terrain_scan_smoke --seed 42 --ticks 5 --out runs/check_terrain_scan_after_pathfinding_hardening`
- `swift run -c release PebbleLab -- --scenario terrain_scan_edge_smoke --seed 42 --ticks 5 --out runs/check_terrain_scan_edge_after_pathfinding_hardening`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_pathfinding_hardening`
- `swift run -c release PebbleLab -- --scenario world_observation_multi_smoke --seed 42 --ticks 5 --out runs/check_world_observation_after_pathfinding_hardening`
- `swift run -c release pebsmoke`

### Results

- Fixture report: `20 passed, 0 failed`.
- Status counts: found `9`, not found `4`, invalid start `2`, invalid goal
  `2`, search limit reached `2`, unknown `1`.
- Invariant report: `23 passed, 0 failed`.
- Debug and Pebble release builds passed.
- Column, terrain, semantics, traversability, regression, and multi-agent world
  observation scenarios passed.
- `pebsmoke`: `456 passed, 0 failed`.

### Next Step

Phase 4.13A: plan live pathfinding integration docs-only, preserving the
strict separation between captured traversability, search evidence, movement,
and collision.

## 2026-06-19 — Phase 4.13A Live Pathfinding Integration Planning

Branch: `lab/pebblelab-v1`

### Objective

Define the exact boundary between captured live column traversability and the
existing fixture-proven BFS before adding any live pathfinding code.

### Files Created Or Modified

- `docs/pebblelab/PHASE_4_LIVE_PATHFINDING_INTEGRATION_PLAN.md` (new)
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`

### Technical Decisions

- Phase 4.13B begins central-only with seed 42, one agent, radius one, nine
  columns, and nine abstract nodes.
- Each node copies coordinates and traversability from one captured column;
  adaptation and BFS perform no world read.
- Start is fixed at offset `(0,0)` and goal at `(1,0)`.
- Neighbor mode remains `north_east_south_west`; `maxVisited` is nine.
- Phase 4.13B reuses `scanTerrainColumns` evidence and `findTerrainPath`; it
  does not introduce another scan or BFS.

### Negative Results

Seed 42 commonly produces water support and `.unsafe` column results. A
coherent `invalidStart`, `invalidGoal`, or `notFound` is therefore accepted as
successful integration evidence. Terrain, semantic rules, traversability, and
BFS must not be changed to manufacture a found route.

### Layer Relationship

Column scan reads and audits the world. Semantics and traversability transform
captured values. The live adapter creates nine abstract nodes. Existing BFS
returns search evidence. Movement, collision, and agent goal selection remain
future, separate layers.

### Risks

The plan addresses premature world coupling, repeated reads, terrain mutation
to force success, rejection of honest negative statuses, collision overclaims,
fixture BFS changes for live convenience, intelligent goal-selection leakage,
and premature edge or multi-agent expansion.

### Still Prohibited

No Swift, PebbleCore, registry, save/load, renderer, resource, or golden file
was changed. Live pathfinding code, world rereads, graph execution, movement,
collision, mutation, intelligent goals, edge/multi-agent search, A*, Dijkstra,
weighted costs, and ML integrations remain out of scope.

### Validation Commands

- `swift build`
- `swift run -c release pebsmoke`

### Results

- Documentation-only diff confirmed; no Swift file changed.
- `swift build` passed.
- `pebsmoke`: `456 passed, 0 failed`.

### Next Step

Phase 4.13B: implement central-only `terrain_pathfinding_column_smoke` as a
pure adapter from captured column traversability to the existing BFS, with no
movement or collision consumer.

## 2026-06-19 — Phase 4.13B Terrain Pathfinding Column Smoke

Branch: `lab/pebblelab-v1`

### Objective

Connect the central read-only column scan to the existing bounded BFS through
a pure, auditable adapter, without introducing movement, collision, mutation,
or a second search implementation.

### Files Created Or Modified

- `Sources/PebbleLab/LabTerrainPathfindingColumn.swift` (new)
- `Sources/PebbleLab/LabTerrainPathfinding.swift`
- `Sources/PebbleLab/LabTerrainColumnScan.swift`
- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`
- `docs/pebblelab/PHASE_4_LIVE_PATHFINDING_INTEGRATION_PLAN.md`

### Column-To-Node Mapping

The scenario reuses the central `scanTerrainColumns` contract at agent position
`x=8,z=8`. Its nine columns become nine nodes in the existing `dz_then_dx`
order. Each node copies the column coordinates, traversability kind, source
index, and reason. The adapter receives no `World`, performs no block or chunk
read, and calls the existing `findTerrainPath` implementation.

### Fixed Search Contract

- start: offset `(0,0)`;
- goal: offset `(1,0)`;
- neighbor mode: `north_east_south_west`;
- `maxVisited`: nine;
- accepted evidence: `found` or a coherent negative result;
- no substitute goal selection when start or goal is not traversable.

### Observed Result

Seed 42 produced nine unsafe nodes because the scanned support cells are
liquid. Start and goal were both unsafe, so the existing BFS returned
`invalidStart`, reason `start_missing_or_not_traversable`, path length zero,
and visited zero. This is the expected coherent negative result; no terrain was
changed to manufacture a route.

### Outputs And Invariants

The scenario adds `terrain_pathfinding_column_snapshot.json`,
`terrain_pathfinding_column_invariant_report.json`, eight
`terrainPathfindingColumn*` metrics, and one aggregate
`lab_terrain_pathfinding_column_recorded` event. The invariant report contains
26 checks covering source mapping, fixed request bounds, status coherence,
conditional found-path validity, and the no-reread/no-movement contract.

### Still Prohibited

No PebbleCore, registry, save/load, renderer, resource, or golden change was
made. No second BFS, edge or multi-agent pathfinding, world reread, movement,
route following, collision, mutation, A*, Dijkstra, weighted cost, intelligent
goal selection, Python, ML, LLM, or RL integration was added.

### Validation Commands

- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario terrain_pathfinding_column_smoke --seed 42 --ticks 5 --out runs/check_terrain_pathfinding_column`
- `swift run -c release PebbleLab -- --scenario terrain_pathfinding_fixture_smoke --seed 42 --ticks 0 --out runs/check_pathfinding_fixture_after_column_live`
- `swift run -c release PebbleLab -- --scenario terrain_column_scan_smoke --seed 42 --ticks 5 --out runs/check_column_scan_after_column_live_pathfinding`
- `swift run -c release PebbleLab -- --scenario terrain_column_scan_edge_smoke --seed 42 --ticks 5 --out runs/check_column_scan_edge_after_column_live_pathfinding`
- `swift run -c release PebbleLab -- --scenario terrain_traversability_fixture_smoke --seed 42 --ticks 0 --out runs/check_traversability_fixture_after_column_live_pathfinding`
- `swift run -c release PebbleLab -- --scenario terrain_semantics_fixture_smoke --seed 42 --ticks 0 --out runs/check_semantics_fixture_after_column_live_pathfinding`
- `swift run -c release PebbleLab -- --scenario terrain_scan_smoke --seed 42 --ticks 5 --out runs/check_terrain_scan_after_column_live_pathfinding`
- `swift run -c release PebbleLab -- --scenario terrain_scan_edge_smoke --seed 42 --ticks 5 --out runs/check_terrain_scan_edge_after_column_live_pathfinding`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_column_live_pathfinding`
- `swift run -c release PebbleLab -- --scenario world_observation_multi_smoke --seed 42 --ticks 5 --out runs/check_world_observation_after_column_live_pathfinding`
- `swift run -c release pebsmoke`

### Results

- Central live column pathfinding: nine nodes, nine unsafe, zero traversable,
  coherent `invalidStart`, run success true.
- Live invariant report: `26 passed, 0 failed`.
- Debug and Pebble release builds passed.
- Pathfinding fixture, central/edge column, traversability fixture, semantics
  fixture, central/edge terrain, regression, and multi-agent observation
  scenarios passed.
- `pebsmoke`: `456 passed, 0 failed`.

### Next Step

Phase 4.13C should plan edge live pathfinding docs-only, or Phase 4.14A should
plan movement docs-only. Movement, collision, mutation, route following, and
multi-agent pathfinding remain separate future concerns.

## 2026-06-19 — Phase 4.13C Edge Live Column Pathfinding Smoke

Branch: `lab/pebblelab-v1`

### Objective

Prove that the existing captured-column adapter and bounded BFS preserve their
contract when the source scan crosses chunk boundaries, without adding another
scan, adapter, BFS, or movement consumer.

### Files Modified

- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/LabTerrainColumnScan.swift`
- `Sources/PebbleLab/LabTerrainPathfindingColumn.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`
- `docs/pebblelab/PHASE_4_LIVE_PATHFINDING_INTEGRATION_PLAN.md`

### Edge Contract And Mapping

The shared column contract places the single synchronized agent at
`x=16,z=16`, with radius one, nine columns, and 27 support/feet/head cells
across chunks `(0,0)`, `(1,0)`, `(0,1)`, and `(1,1)`. The existing adapter maps
those captured columns one-to-one to nine nodes, preserving order, offsets,
coordinates, source indexes, traversability kinds, and reasons. It performs no
world or chunk reread.

### Fixed Search And Observed Result

Start remains offset `(0,0)`, goal remains `(1,0)`, `maxVisited` remains nine,
and neighbor mode remains `north_east_south_west`. Seed 42 produced nine unsafe
nodes. The existing BFS therefore returned coherent `invalidStart`, reason
`start_missing_or_not_traversable`, with path length zero and visited zero.
No fallback goal or terrain mutation was introduced.

### Outputs And Invariants

The scenario reuses `terrain_pathfinding_column_snapshot.json`,
`terrain_pathfinding_column_invariant_report.json`, the
`terrainPathfindingColumn*` metrics, and the aggregate
`lab_terrain_pathfinding_column_recorded` event. Two conditional edge checks
prove boundary crossing and exactly four chunks, bringing the edge report to
`28 passed, 0 failed`; the central report remains at 26 checks.

### Still Prohibited

No PebbleCore, registry, save/load, renderer, resource, or golden change was
made. No second BFS, world reread, movement, route following, collision,
mutation, multi-agent pathfinding, intelligent goal selection, A*, Dijkstra,
weighted cost, Python, ML, LLM, or RL integration was added.

### Validation Commands

- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario terrain_pathfinding_column_smoke --seed 42 --ticks 5 --out runs/check_terrain_pathfinding_column_after_edge`
- `swift run -c release PebbleLab -- --scenario terrain_pathfinding_column_edge_smoke --seed 42 --ticks 5 --out runs/check_terrain_pathfinding_column_edge`
- `swift run -c release PebbleLab -- --scenario terrain_pathfinding_fixture_smoke --seed 42 --ticks 0 --out runs/check_pathfinding_fixture_after_column_edge_live`
- `swift run -c release PebbleLab -- --scenario terrain_column_scan_smoke --seed 42 --ticks 5 --out runs/check_column_scan_after_column_edge_live`
- `swift run -c release PebbleLab -- --scenario terrain_column_scan_edge_smoke --seed 42 --ticks 5 --out runs/check_column_scan_edge_after_column_edge_live`
- `swift run -c release PebbleLab -- --scenario terrain_traversability_fixture_smoke --seed 42 --ticks 0 --out runs/check_traversability_fixture_after_column_edge_live`
- `swift run -c release PebbleLab -- --scenario terrain_semantics_fixture_smoke --seed 42 --ticks 0 --out runs/check_semantics_fixture_after_column_edge_live`
- `swift run -c release PebbleLab -- --scenario terrain_scan_smoke --seed 42 --ticks 5 --out runs/check_terrain_scan_after_column_edge_live`
- `swift run -c release PebbleLab -- --scenario terrain_scan_edge_smoke --seed 42 --ticks 5 --out runs/check_terrain_scan_edge_after_column_edge_live`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_column_edge_live`
- `swift run -c release PebbleLab -- --scenario world_observation_multi_smoke --seed 42 --ticks 5 --out runs/check_world_observation_after_column_edge_live`
- `swift run -c release pebsmoke`

### Results

- Edge live pathfinding: nine nodes, nine unsafe, coherent `invalidStart`, run
  success true.
- Underlying edge column scan: four unique chunks, 27 observed cells.
- Edge invariant report: `28 passed, 0 failed`.
- Debug and Pebble release builds passed.
- Central live pathfinding, pathfinding fixtures, central/edge column scans,
  traversability and semantics fixtures, central/edge terrain scans,
  regression, and multi-agent observation passed.
- `pebsmoke`: `456 passed, 0 failed`.

### Next Step

Phase 4.14A should plan movement docs-only, or Phase 4.13D should plan a
positive live pathfinding scenario docs-only. Movement, collision, mutation,
route following, and multi-agent pathfinding remain separate future concerns.

## 2026-06-19 — Phase 4.13D Positive Live Pathfinding Planning

Branch: `lab/pebblelab-v1`

### Objective

Define how PebbleLab can later prove a positive live path without changing
terrain, search rules, movement, or collision behavior.

### Files Created Or Modified

- `docs/pebblelab/PHASE_4_POSITIVE_LIVE_PATHFINDING_PLAN.md` (new)
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`

### Current Negative Evidence

Central `(8,8)` and edge `(16,16)` seed-42 scans both produce nine unsafe
nodes because support cells are liquid. Their `invalidStart` results are
correct and remain valuable refusal evidence, but they do not prove that the
live adapter and BFS can produce `found` from captured traversable columns.

### Options Considered

- a manually discovered fixed seed and position;
- a bounded deterministic read-only candidate list;
- replayed column snapshots as fixture/live hybrid coverage;
- a naturally solid generated area selected without block mutation.

The plan recommends bounded deterministic discovery when it stays small and
fast, with a manually documented fixed candidate as the simpler fallback.
Replayed snapshots may supplement regression tests but do not count as the live
positive proof.

### Recommended Strategy

Phase 4.13E should evaluate at most 16 fixed candidates in a documented order,
using the existing column scan, semantic/traversability transforms, adapter,
and BFS. It should stop at the first `found`, record every attempt compactly,
and fail with evidence if no candidate succeeds. Fixed start `(0,0)` and goal
`(1,0)` remain preferred; a simple first-traversable/first-neighbor rule is an
acceptable audited test-only fallback, not agent goal selection.

### Relationship With Movement Planning

Movement remains a future consumer. A positive path proves only abstract route
construction over captured nodes, not physical execution or collision safety.
Movement implementation should preferably wait until central negative, edge
negative, and positive live path evidence are all validated and Phase 4.14A has
defined a separate docs-only contract.

### Risks

The plan addresses terrain mutation to force success, test selection leaking
into agent policy, nondeterministic or unbounded discovery, validation runtime,
generation drift, world rereads during BFS, premature movement, and collision
overclaims.

### Still Prohibited

No Swift, PebbleCore, registry, save/load, renderer, resource, or golden file
was changed. No executable scenario, seed search, mutation, movement,
collision, route following, agent decision, multi-agent pathfinding, A*,
Dijkstra, weighted cost, Python, ML, LLM, or RL integration was added.

### Validation Commands

- `swift build`
- `swift run -c release pebsmoke`

### Results

- Documentation-only diff confirmed; no Swift file changed.
- `swift build` passed.
- `pebsmoke`: `456 passed, 0 failed`.

### Next Step

Phase 4.13E: implement a positive live column pathfinding smoke using bounded,
deterministic, read-only discovery and the existing scan/adapter/BFS stack.

## 2026-06-19 — Phase 4.13E Positive Live Column Pathfinding Smoke

Branch: `lab/pebblelab-v1`

### Objective

Produce the first live `found` path from naturally generated, read-only column
evidence while preserving the existing scan, semantic, traversability,
adapter, and BFS boundaries.

### Files Created Or Modified

- `Sources/PebbleLab/LabTerrainPathfindingPositive.swift` (new)
- `Sources/PebbleLab/LabTerrainPathfindingColumn.swift`
- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`
- `docs/pebblelab/PHASE_4_POSITIVE_LIVE_PATHFINDING_PLAN.md`

### Candidate Strategy

The smoke defines 16 candidates in a fixed order and stops at the first
positive result. Development probing identified seed 99 at `(8,8)` as a stable
naturally generated candidate, so it is explicitly placed at index zero. The
snapshot retains the complete candidate list and records every attempted
candidate; the validated run requires one attempt.

Each attempt creates an isolated world, generates only a radius-one chunk area
around the candidate through the existing generation path, captures nine
columns, maps nine nodes, and calls the existing BFS. No block is placed,
removed, or rewritten to obtain `found`.

### Start And Goal

The selected candidate succeeds with the preferred fixed strategy:

- start offset `(0,0)`, world key `(8,64,8)`;
- goal offset `(1,0)`, world key `(9,64,8)`;
- neighbor mode `north_east_south_west`;
- `maxVisited = 9`.

A pure fallback can choose the first traversable column and its first
traversable orthogonal neighbor, but it was not used by the validated run and
is explicitly test harness selection rather than agent goal selection.

### Positive Result

Candidate index zero, seed 99 at `(8,8)`, produced nine nodes including five
traversable nodes. `findTerrainPath` returned `found`, reason
`bounded_bfs_path_found`, path length two, and visited count three. Both path
nodes are captured traversable nodes and form one eastward four-neighbor step.

### Outputs And Invariants

The scenario adds `terrain_pathfinding_column_positive_snapshot.json`,
`terrain_pathfinding_column_positive_invariant_report.json`, six positive
metrics, and one aggregate positive event. The invariant report passes 26
checks covering candidate bounds, selected evidence, mapped nodes, path shape,
and the no-second-BFS/no-mutation/no-movement boundary.

### Still Prohibited

No PebbleCore, registry, save/load, renderer, resource, or golden change was
made. No second BFS, block mutation, world reread during BFS, movement,
collision, route following, multi-agent pathfinding, intelligent goal
selection, A*, Dijkstra, weighted cost, Python, ML, LLM, or RL integration was
added.

### Validation Commands

- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario terrain_pathfinding_column_positive_smoke --seed 42 --ticks 5 --out runs/check_terrain_pathfinding_column_positive`
- `swift run -c release PebbleLab -- --scenario terrain_pathfinding_column_smoke --seed 42 --ticks 5 --out runs/check_terrain_pathfinding_column_after_positive`
- `swift run -c release PebbleLab -- --scenario terrain_pathfinding_column_edge_smoke --seed 42 --ticks 5 --out runs/check_terrain_pathfinding_column_edge_after_positive`
- `swift run -c release PebbleLab -- --scenario terrain_pathfinding_fixture_smoke --seed 42 --ticks 0 --out runs/check_pathfinding_fixture_after_positive`
- `swift run -c release PebbleLab -- --scenario terrain_column_scan_smoke --seed 42 --ticks 5 --out runs/check_column_scan_after_positive`
- `swift run -c release PebbleLab -- --scenario terrain_column_scan_edge_smoke --seed 42 --ticks 5 --out runs/check_column_scan_edge_after_positive`
- `swift run -c release PebbleLab -- --scenario terrain_traversability_fixture_smoke --seed 42 --ticks 0 --out runs/check_traversability_fixture_after_positive`
- `swift run -c release PebbleLab -- --scenario terrain_semantics_fixture_smoke --seed 42 --ticks 0 --out runs/check_semantics_fixture_after_positive`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_positive`
- `swift run -c release PebbleLab -- --scenario world_observation_multi_smoke --seed 42 --ticks 5 --out runs/check_world_observation_after_positive`
- `swift run -c release pebsmoke`

### Results

- Positive snapshot: 16 configured candidates, one attempt, selected index zero,
  seed 99 at `(8,8)`.
- Selected path: `found`, length two, visited three, five traversable nodes.
- Positive invariant report: `26 passed, 0 failed`.
- Debug and Pebble release builds passed.
- Negative central/edge live pathfinding, pathfinding fixtures, central/edge
  column scans, traversability and semantics fixtures, regression, and
  multi-agent observation passed.
- `pebsmoke`: `456 passed, 0 failed`.

### Next Step

Phase 4.14A: define movement planning docs-only. A found path remains abstract
evidence and does not yet authorize displacement, collision assumptions, or
route following.

## 2026-06-19 — Phase 4.14A Movement Planning

Branch: `lab/pebblelab-v1`

### Objective

Define the first movement contract after positive live pathfinding while
preserving strict separation from collision, live agents, world mutation,
pathfinding, and agent decisions.

### Files Created Or Modified

- `docs/pebblelab/PHASE_4_MOVEMENT_PLAN.md` (new)
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`

### Technical Decisions

- Phase 4.14B begins fixture-only with synthetic node-key paths.
- Pathfinding supplies an already completed path and is never called by the
  movement layer.
- Movement intent describes one next-node transition.
- Fixture execution updates only an abstract movement state.
- One tick advances at most one horizontal four-neighbor edge.
- Diagonal and vertical movement are invalid in v0.
- Collision, real agent position updates, and `blocked` behavior are deferred.

### Layer Distinction

Pathfinding produces route evidence. Movement intent asks for one path edge.
Abstract movement execution advances fixture state. Collision remains the
engine's separate physical truth. Agent decision remains the separate choice to
follow a route. None of these boundaries is collapsed in Phase 4.14A.

### Fixture Recommendation

The future `terrain_path_movement_fixture_smoke` should cover single- and
multi-step completion, stable post-goal ticks, empty and one-node paths,
diagonal/vertical/non-neighbor rejection, wrong initial position, and explicit
world independence. At least ten fixtures and a dedicated invariant report are
required.

### Risks

The plan addresses confusion between abstract movement and physics, treating a
found path as executable, premature live movement, collision without a
contract, accidental live position mutation, hidden agent decisions,
pathfinding inside movement, unsupported diagonal/vertical steps, and
regression of existing pathfinding scenarios.

### Still Prohibited

No Swift, PebbleCore, registry, save/load, renderer, resource, or golden file
was changed. No movement code, live route following, collision, physics
integration, mutation, agent decision, multi-agent movement, A*, Dijkstra,
weighted costs, Python, ML, LLM, or RL integration was added.

### Validation Commands

- `swift build`
- `swift run -c release pebsmoke`

### Results

- Documentation-only diff confirmed; no Swift file changed.
- `swift build` passed.
- `pebsmoke`: `456 passed, 0 failed`.

### Next Step

Phase 4.14B: implement `terrain_path_movement_fixture_smoke` as a pure abstract
path consumer with no world, collision, real agent, or pathfinding dependency.

## 2026-06-19 — Phase 4.14B Terrain Path Movement Fixture Smoke

Branch: `lab/pebblelab-v1`

### Objective

Implement the first movement layer as a pure synthetic path consumer, proving
validation, one-edge progression, goal completion, and invalid-path refusal
without any live world or agent dependency.

### Files Created Or Modified

- `Sources/PebbleLab/LabTerrainMovement.swift` (new)
- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`
- `docs/pebblelab/PHASE_4_MOVEMENT_PLAN.md`

### Movement Rules

- Empty or malformed paths return `invalidPath`.
- One-node paths begin at `reachedGoal`.
- Multi-node paths require current position to equal the first node.
- Repeated nodes are invalid in v0.
- Every edge must remain at constant y and have horizontal Manhattan distance
  one.
- One call advances at most one path edge and increments target index in order.
- Reaching the final node sets `reachedGoal`.
- Additional post-goal ticks do not move.

### Fixtures

Twelve fixtures cover single-step and multi-step completion, post-goal idling,
empty and one-node paths, diagonal/vertical/non-neighbor rejection, wrong
initial position, explicit engine independence, repeated-node rejection, and
stable already-reached-goal ticks.

### Outputs And Invariants

The scenario writes `terrain_path_movement_fixture_report.json`,
`terrain_path_movement_invariant_report.json`, eight movement metrics, and one
aggregate event. Results are `12 passed, 0 failed`, six planned/executed steps,
six reached goals, and six invalid paths. The invariant report passes all 17
checks.

### Still Prohibited

No PebbleCore, registry, save/load, renderer, resource, or golden change was
made. Movement uses no world, chunk, real agent, placeholder, core entity,
pathfinding call, collision, physics integration, mutation, route following,
agent decision, multi-agent movement, Python, ML, LLM, or RL integration.

### Validation Commands

- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario terrain_path_movement_fixture_smoke --seed 42 --ticks 0 --out runs/check_terrain_path_movement_fixture`
- `swift run -c release PebbleLab -- --scenario terrain_pathfinding_column_positive_smoke --seed 42 --ticks 5 --out runs/check_positive_path_after_movement_fixture`
- `swift run -c release PebbleLab -- --scenario terrain_pathfinding_column_smoke --seed 42 --ticks 5 --out runs/check_negative_central_after_movement_fixture`
- `swift run -c release PebbleLab -- --scenario terrain_pathfinding_column_edge_smoke --seed 42 --ticks 5 --out runs/check_negative_edge_after_movement_fixture`
- `swift run -c release PebbleLab -- --scenario terrain_pathfinding_fixture_smoke --seed 42 --ticks 0 --out runs/check_pathfinding_fixture_after_movement_fixture`
- `swift run -c release PebbleLab -- --scenario terrain_column_scan_smoke --seed 42 --ticks 5 --out runs/check_column_scan_after_movement_fixture`
- `swift run -c release PebbleLab -- --scenario terrain_column_scan_edge_smoke --seed 42 --ticks 5 --out runs/check_column_scan_edge_after_movement_fixture`
- `swift run -c release PebbleLab -- --scenario terrain_semantics_fixture_smoke --seed 42 --ticks 0 --out runs/check_semantics_fixture_after_movement_fixture`
- `swift run -c release PebbleLab -- --scenario terrain_traversability_fixture_smoke --seed 42 --ticks 0 --out runs/check_traversability_fixture_after_movement_fixture`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_movement_fixture`
- `swift run -c release PebbleLab -- --scenario world_observation_multi_smoke --seed 42 --ticks 5 --out runs/check_world_observation_after_movement_fixture`
- `swift run -c release pebsmoke`

### Results

- Movement fixtures: `12 passed, 0 failed`.
- Steps: six planned, six executed.
- Final classifications: six reached goals, six invalid paths.
- Movement invariants: `17 passed, 0 failed`.
- Debug and Pebble release builds passed.
- Positive/negative pathfinding, pathfinding fixtures, central/edge column
  scans, semantics/traversability fixtures, regression, and multi-agent world
  observation passed.
- `pebsmoke`: `456 passed, 0 failed`.

### Next Step

Phase 4.14C: harden movement fixture state/index/error contracts before Phase
4.15A plans any live movement integration.

## 2026-06-19 — Phase 4.14C Terrain Movement Fixture Hardening

Branch: `lab/pebblelab-v1`

### Objective

Harden the fixture-only movement state machine around manually constructed
states, denied intents, terminal stability, partial progress, target indexes,
and exact intent deltas before any live integration planning.

### Files Modified

- `Sources/PebbleLab/LabTerrainMovement.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`
- `docs/pebblelab/PHASE_4_MOVEMENT_PLAN.md`

Existing metrics, event fields, scenario wiring, and output file names remain
unchanged.

### New Fixtures

Ten fixtures were added:

- partial multi-step progress remains moving;
- moving target index out of bounds;
- moving current node inconsistent with the expected previous path node;
- direct idle, blocked, and failed terminal states;
- invalid path stability over multiple ticks;
- reached-goal stability over multiple ticks;
- exact target-index progression;
- exact movement-intent deltas across multiple horizontal directions.

The fixture total grows from 12 to 22.

### Contract Decisions

- A moving state requires `targetIndex` inside the path and greater than zero.
- Its current node must equal `path[targetIndex - 1]`.
- Invalid indexes deny intent with `invalid_target_index`.
- Incoherent current nodes deny intent with
  `current_not_on_expected_path_edge`.
- A denied moving intent becomes `invalidPath` without movement.
- Idle, blocked, failed, invalid-path, and reached-goal states remain unchanged
  and immobile.
- Allowed intents move exactly once to `intent.to`; non-goal target indexes
  advance by exactly one.

### Invariant Hardening

Eight checks were added for terminal-state immobility, target-index validity,
current/path coherence, exact index progression, partial movement state,
intent deltas, denied-intent immobility, and allowed-intent execution. The
report now passes 25 checks.

### Still Prohibited

No PebbleCore, registry, save/load, renderer, resource, or golden change was
made. Movement still uses no world, chunk, real agent, placeholder, core
entity, pathfinding call, collision, physics integration, mutation, route
following, agent decision, or multi-agent movement.

### Validation Commands

- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario terrain_path_movement_fixture_smoke --seed 42 --ticks 0 --out runs/check_terrain_path_movement_fixture_hardened`
- `swift run -c release PebbleLab -- --scenario terrain_pathfinding_column_positive_smoke --seed 42 --ticks 5 --out runs/check_positive_path_after_movement_hardening`
- `swift run -c release PebbleLab -- --scenario terrain_pathfinding_column_smoke --seed 42 --ticks 5 --out runs/check_negative_central_after_movement_hardening`
- `swift run -c release PebbleLab -- --scenario terrain_pathfinding_column_edge_smoke --seed 42 --ticks 5 --out runs/check_negative_edge_after_movement_hardening`
- `swift run -c release PebbleLab -- --scenario terrain_pathfinding_fixture_smoke --seed 42 --ticks 0 --out runs/check_pathfinding_fixture_after_movement_hardening`
- `swift run -c release PebbleLab -- --scenario terrain_column_scan_smoke --seed 42 --ticks 5 --out runs/check_column_scan_after_movement_hardening`
- `swift run -c release PebbleLab -- --scenario terrain_column_scan_edge_smoke --seed 42 --ticks 5 --out runs/check_column_scan_edge_after_movement_hardening`
- `swift run -c release PebbleLab -- --scenario terrain_semantics_fixture_smoke --seed 42 --ticks 0 --out runs/check_semantics_fixture_after_movement_hardening`
- `swift run -c release PebbleLab -- --scenario terrain_traversability_fixture_smoke --seed 42 --ticks 0 --out runs/check_traversability_fixture_after_movement_hardening`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_movement_hardening`
- `swift run -c release PebbleLab -- --scenario world_observation_multi_smoke --seed 42 --ticks 5 --out runs/check_world_observation_after_movement_hardening`
- `swift run -c release pebsmoke`

### Results

- Movement fixtures: `22 passed, 0 failed`.
- Steps: 14 planned, 14 executed.
- Final classifications: nine reached goals, nine invalid paths, plus stable
  moving/idle/blocked/failed cases.
- Movement invariants: `25 passed, 0 failed`.
- Debug and Pebble release builds passed.
- Positive/negative pathfinding, pathfinding fixtures, central/edge column
  scans, semantics/traversability fixtures, regression, and multi-agent world
  observation passed.
- `pebsmoke`: `456 passed, 0 failed`.

### Next Step

Phase 4.15A: plan live movement integration docs-only, retaining fixture
movement as the authority for abstract state progression.

## 2026-06-19 — Phase 4.15A Live Movement Integration Planning

Branch: `lab/pebblelab-v1`

### Objective

Define the adapter boundary from positive live path evidence to abstract
movement execution before any real agent, placeholder, or core-entity position
is changed.

### Files Created Or Modified

- `docs/pebblelab/PHASE_4_LIVE_MOVEMENT_INTEGRATION_PLAN.md` (new)
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`

### Layer Distinction

Live pathfinding supplies a route derived from captured terrain. The movement
fixture proves stepping over supplied node keys. The future live adapter should
preserve selected-candidate/path provenance, initialize movement state, and
record abstract steps. Collision, physical synchronization, gameplay route
following, and the decision to follow a path remain separate future layers.

### Phase 4.15B Recommendation

Start with live path to abstract movement state. Reuse the positive selected
path and existing movement validation/step functions, execute one abstract edge
per record, and require final `reachedGoal`. Explicitly report
`liveAgentDisplaced = false`, `collisionPerformed = false`, and
`mutationPerformed = false`.

### Risks

The plan addresses premature real-agent displacement, abstract evidence being
presented as physics, hidden collision, repeated pathfinding, goal selection in
the adapter, unaudited live-position mutation, positive-path regression,
seed-99 overcoupling, and gameplay work before complete snapshots exist.

### Still Prohibited

No Swift, PebbleCore, registry, save/load, renderer, resource, or golden file
was changed. No live movement, route following, collision, physics integration,
position synchronization, mutation, agent decision, multi-agent movement,
Python, ML, LLM, or RL integration was added.

### Validation Commands

- `swift build`
- `swift run -c release pebsmoke`

### Results

- Documentation-only diff confirmed; no Swift file changed.
- `swift build` passed.
- `pebsmoke`: `456 passed, 0 failed`.

### Next Step

Phase 4.15B: implement `terrain_path_live_movement_smoke` as abstract movement
over positive live path evidence, with no live displacement or collision.

## 2026-06-19 — Phase 4.15B Terrain Path Live Movement Smoke

Branch: `lab/pebblelab-v1`

### Objective

Consume a naturally captured positive live path with the existing abstract
movement state machine, record every value-state transition, and reach the goal
without changing any live agent, physical placeholder, core entity, chunk, or
world block.

### Files Created Or Modified

- `Sources/PebbleLab/LabTerrainLiveMovement.swift` (new)
- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`
- `docs/pebblelab/PHASE_4_LIVE_MOVEMENT_INTEGRATION_PLAN.md`

### Positive Path And Abstract Movement

The existing bounded candidate pipeline selects candidate index zero, seed 99
at `(8,8)`. Its existing BFS returns `found` for the path
`(8,64,8) -> (9,64,8)`. The live movement adapter consumes that exact path,
initializes `targetIndex = 1`, and delegates to `stepTerrainMovement` once. The
recorded eastward intent has delta `(1,0,0)` and reaches `reachedGoal` without
running pathfinding inside movement or selecting another goal.

### Outputs And Invariants

The scenario writes `terrain_path_live_movement_snapshot.json`,
`terrain_path_live_movement_invariant_report.json`, `metrics.json`, and
`events.ndjson`. Metrics use the `terrainLiveMovement*` prefix and one
`lab_terrain_live_movement_recorded` event summarizes the run. All 18 dedicated
invariants pass, including exact path order, no skipped/diagonal/vertical steps,
and separation from fixture runtime evidence.

The snapshot and metrics explicitly report:

- `liveAgentDisplaced = false`;
- `collisionPerformed = false`;
- `mutationPerformed = false`.

### Still Prohibited

No PebbleCore, registry, save/load, renderer, resource, or golden file changed.
No live position synchronization, physical movement, collision, physics,
mutation, second BFS, pathfinding inside movement, gameplay route following,
goal selection, multi-agent movement, Python, ML, LLM, or RL integration was
added.

### Validation Commands

- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario terrain_path_live_movement_smoke --seed 42 --ticks 5 --out runs/check_terrain_path_live_movement`
- `swift run -c release PebbleLab -- --scenario terrain_path_movement_fixture_smoke --seed 42 --ticks 0 --out runs/check_movement_fixture_after_live_movement`
- `swift run -c release PebbleLab -- --scenario terrain_pathfinding_column_positive_smoke --seed 42 --ticks 5 --out runs/check_positive_path_after_live_movement`
- `swift run -c release PebbleLab -- --scenario terrain_pathfinding_column_smoke --seed 42 --ticks 5 --out runs/check_negative_central_after_live_movement`
- `swift run -c release PebbleLab -- --scenario terrain_pathfinding_column_edge_smoke --seed 42 --ticks 5 --out runs/check_negative_edge_after_live_movement`
- `swift run -c release PebbleLab -- --scenario terrain_pathfinding_fixture_smoke --seed 42 --ticks 0 --out runs/check_pathfinding_fixture_after_live_movement`
- `swift run -c release PebbleLab -- --scenario terrain_column_scan_smoke --seed 42 --ticks 5 --out runs/check_column_scan_after_live_movement`
- `swift run -c release PebbleLab -- --scenario terrain_column_scan_edge_smoke --seed 42 --ticks 5 --out runs/check_column_scan_edge_after_live_movement`
- `swift run -c release PebbleLab -- --scenario terrain_semantics_fixture_smoke --seed 42 --ticks 0 --out runs/check_semantics_fixture_after_live_movement`
- `swift run -c release PebbleLab -- --scenario terrain_traversability_fixture_smoke --seed 42 --ticks 0 --out runs/check_traversability_fixture_after_live_movement`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_live_movement`
- `swift run -c release PebbleLab -- --scenario world_observation_multi_smoke --seed 42 --ticks 5 --out runs/check_world_observation_after_live_movement`
- `swift run -c release pebsmoke`

### Results

- Live movement path: two nodes, one step, final `reachedGoal`.
- Live movement invariants: `18 passed, 0 failed`.
- No-displacement, no-collision, and no-mutation flags: false as required.
- Debug build and the principal release scenario passed.
- Full non-regression validation passed, including `pebsmoke` at
  `456 passed, 0 failed`.

### Next Step

Phase 4.15C: harden the live movement adapter without collision, or Phase 4.16A:
plan collision docs-only before any physical displacement is attempted.

## 2026-06-19 — Phase 4.15C Live Movement Adapter Hardening

Branch: `lab/pebblelab-v1`

### Objective

Strengthen the existing abstract live movement adapter before collision or real
displacement by auditing positive evidence provenance, exact path consumption,
movement-state construction, step recording, and output consistency.

### Files Modified

- `Sources/PebbleLab/LabTerrainLiveMovement.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`
- `docs/pebblelab/PHASE_4_LIVE_MOVEMENT_INTEGRATION_PLAN.md`

Metrics and event schemas remain unchanged because their existing fields fully
express the hardened contract.

### Invariant Hardening

The invariant report grows from 18 to 28 checks. New checks verify selected
candidate metadata presence and exact agreement with the positive summary,
exact selected-path consumption, initial `moving` state and target index one,
movement-step and summary counts, summary path length, successful moved steps,
and the canonical `move_to_next_path_node` intent reason.

A pure synthetic audit passes nil and invalid positive evidence to the adapter
and confirms that neither can create a movement snapshot or steps. No world,
chunk, agent, pathfinding, or separate scenario participates in this audit.

### Contract Decisions

The positive path remains candidate index zero, seed 99 at `(8,8)`, with path
`(8,64,8) -> (9,64,8)`. The adapter consumes it unchanged. Metrics and the
single aggregate event continue to read directly from the snapshot summary;
runner-level validation checks their agreement.

The safety flags remain contractual output, not commentary:

- `liveAgentDisplaced = false`;
- `collisionPerformed = false`;
- `mutationPerformed = false`.

### Still Prohibited

No PebbleCore, registry, save/load, renderer, resource, or golden file changed.
No live entity displacement, collision, physics integration, mutation,
pathfinding inside movement, second BFS, goal selection, gameplay route
following, multi-agent movement, avoidance, Python, ML, LLM, or RL integration
was added.

### Validation Commands

- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario terrain_path_live_movement_smoke --seed 42 --ticks 5 --out runs/check_terrain_path_live_movement_hardened`
- `swift run -c release PebbleLab -- --scenario terrain_path_movement_fixture_smoke --seed 42 --ticks 0 --out runs/check_movement_fixture_after_live_movement_hardening`
- `swift run -c release PebbleLab -- --scenario terrain_pathfinding_column_positive_smoke --seed 42 --ticks 5 --out runs/check_positive_path_after_live_movement_hardening`
- `swift run -c release PebbleLab -- --scenario terrain_pathfinding_column_smoke --seed 42 --ticks 5 --out runs/check_negative_central_after_live_movement_hardening`
- `swift run -c release PebbleLab -- --scenario terrain_pathfinding_column_edge_smoke --seed 42 --ticks 5 --out runs/check_negative_edge_after_live_movement_hardening`
- `swift run -c release PebbleLab -- --scenario terrain_pathfinding_fixture_smoke --seed 42 --ticks 0 --out runs/check_pathfinding_fixture_after_live_movement_hardening`
- `swift run -c release PebbleLab -- --scenario terrain_column_scan_smoke --seed 42 --ticks 5 --out runs/check_column_scan_after_live_movement_hardening`
- `swift run -c release PebbleLab -- --scenario terrain_column_scan_edge_smoke --seed 42 --ticks 5 --out runs/check_column_scan_edge_after_live_movement_hardening`
- `swift run -c release PebbleLab -- --scenario terrain_semantics_fixture_smoke --seed 42 --ticks 0 --out runs/check_semantics_fixture_after_live_movement_hardening`
- `swift run -c release PebbleLab -- --scenario terrain_traversability_fixture_smoke --seed 42 --ticks 0 --out runs/check_traversability_fixture_after_live_movement_hardening`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_live_movement_hardening`
- `swift run -c release PebbleLab -- --scenario world_observation_multi_smoke --seed 42 --ticks 5 --out runs/check_world_observation_after_live_movement_hardening`
- `swift run -c release pebsmoke`

### Results

- Hardened live movement path: two nodes, one abstract step, `reachedGoal`.
- Live movement invariants: `28 passed, 0 failed`.
- Snapshot, metrics, and event agree on path length two, one step, final goal,
  success true, and all three safety flags false.
- Debug/release builds and the full requested non-regression matrix passed.
- `pebsmoke`: `456 passed, 0 failed`.

### Next Step

Phase 4.16A: plan collision docs-only, or Phase 4.15D: add isolated live
movement failure-case fixtures while retaining zero physical displacement.

## 2026-06-19 — Phase 4.16A Collision Planning Docs-Only

Branch: `lab/pebblelab-v1`

### Objective And Starting State

Define collision and occupancy before any physical displacement. PebbleLab
starts this phase with a positive live-derived path, hardened abstract movement,
and explicit false displacement/collision/mutation flags, but no body-shape or
physical occupancy proof.

### Files Created Or Modified

- `docs/pebblelab/PHASE_4_COLLISION_PLAN.md` (new)
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`

No Swift file changed.

### Traversability Versus Collision

Traversability classifies whether a support/feet/head column is theoretically
passable. Collision asks whether a body with explicit dimensions can occupy or
cross the space without intersecting blocking shapes and with sufficient
support. A path `found` or abstract `reachedGoal` remains insufficient physical
evidence.

The plan proposes a provisional `0.6` block wide, `1.8` block high LabHuman
body centered in the node column and anchored at its feet plane. Collision v0
is conservative: full-cube support and known empty volume only, same-y
four-neighbor queries, and no jump, fall, swim, climb, diagonal, or vertical
transition.

### Future Architecture

Future concepts include `LabTerrainCollisionQuery`,
`LabTerrainCollisionResult`, `LabTerrainOccupancyStatus`, fixture definitions,
live snapshots, and invariant reports. Suggested future modules separate pure
collision evaluation, fixtures, and bounded live read-only sampling. Phase
4.16A creates none of those Swift files.

### Future Outputs And Invariants

Planned outputs are `terrain_collision_fixture_report.json`,
`terrain_collision_invariant_report.json`,
`terrain_collision_live_snapshot.json`, `metrics.json`, and `events.ndjson`.
Future invariants forbid movement, displacement, mutation, pathfinding, route
following, and goal selection; preserve support/feet/head evidence; require
deterministic occupancy and explicit blocked reasons; and keep fixture/live
evidence separate.

### Still Prohibited

No collision, movement, physical displacement, pathfinding change, movement
state-machine change, route following, physics, world mutation, multi-agent
movement, avoidance, registry/save/load/renderer/resource/golden change, or
Python, ML, LLM, or RL integration was added.

### Validation

- `swift build`
- `swift run -c release pebsmoke`
- `git status`

### Results

- Documentation-only diff confirmed; no Swift file changed.
- `swift build` passed.
- `pebsmoke`: `456 passed, 0 failed`.

### Next Step

Phase 4.16B: implement a fixture-only collision and occupancy smoke with
synthetic shapes, no `World`, no agent, no movement, and no mutation.

## 2026-06-19 — Phase 4.16B Collision Fixture Smoke

Branch: `lab/pebblelab-v1`

### Objective

Create the first pure collision and occupancy layer for PebbleLab. The phase
proves that a future `LabHuman` body contract can be represented and evaluated
against synthetic support/feet/head fixtures while remaining separate from
traversability, movement, pathfinding, live agents, physical displacement, and
world mutation.

### Files Created Or Modified

- `Sources/PebbleLab/LabTerrainCollision.swift` (new)
- `Sources/PebbleLab/LabTerrainCollisionFixtures.swift` (new)
- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`
- `docs/pebblelab/PHASE_4_COLLISION_PLAN.md`

No PebbleCore, renderer, shader, resource, registry, save/load, or golden file
changed.

### Body Contract

The fixture smoke uses `LabHumanV0`:

- width: `0.6`;
- depth: `0.6`;
- height: `1.8`;
- anchor: `feet_plane`;
- horizontal centering: `node_center`.

This is an occupancy fixture contract only. It is not a PebbleCore entity
shape, not a physics shape, and not a displacement guarantee.

### Fixtures Covered

Nineteen fixtures cover the v0 statuses:

- full-cube support with empty feet/head: `occupable`;
- missing support: `unsupported`;
- unknown support, unknown feet, unknown head, and special unmodeled support:
  `unknown`;
- liquid support: `liquidUnsupported`;
- feet full cube, liquid feet, and liquid head: `blocked`;
- head full cube: `verticalSpaceOccupied`;
- support/feet/head not loaded: `notLoaded`;
- support/feet/head not ready: `notReady`;
- loaded/ready guard precedence before success;
- out-of-bounds candidate: `outOfBounds`.

Every result includes an explicit reason string.

### Outputs, Invariants, Metrics, And Event

The scenario `terrain_collision_fixture_smoke` writes:

- `terrain_collision_fixture_report.json`;
- `terrain_collision_invariant_report.json`;
- `metrics.json`;
- `events.ndjson`.

The invariant report has 22 checks covering fixture-only execution, no world,
no movement, no agent/placeholder/core displacement, no mutation, no
pathfinding, no route following, no goal selection, body contract agreement,
determinism, explicit reasons, guard precedence, occupable requirements,
blocked reason preservation, fixture/live separation, status counts, and
expected status coverage.

Metrics use the `terrainCollision*` prefix and the run emits one aggregate
`lab_terrain_collision_fixture_recorded` event.

### Still Prohibited

No `World`, live chunk, live agent, physical placeholder, core entity,
movement runtime, `stepTerrainMovement`, `findTerrainPath`, route following,
live collision, physics integration, gravity, velocity, jump, fall, swim,
climb, multi-agent movement, avoidance, Python, ML, LLM, RL, or mutation was
added.

### Validation Commands

- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario terrain_collision_fixture_smoke --seed 42 --ticks 0 --out runs/check_terrain_collision_fixture`
- `swift run -c release PebbleLab -- --scenario terrain_path_live_movement_smoke --seed 42 --ticks 5 --out runs/check_live_movement_after_collision_fixture`
- `swift run -c release PebbleLab -- --scenario terrain_path_movement_fixture_smoke --seed 42 --ticks 0 --out runs/check_movement_fixture_after_collision_fixture`
- `swift run -c release PebbleLab -- --scenario terrain_pathfinding_column_positive_smoke --seed 42 --ticks 5 --out runs/check_positive_path_after_collision_fixture`
- `swift run -c release PebbleLab -- --scenario terrain_traversability_fixture_smoke --seed 42 --ticks 0 --out runs/check_traversability_after_collision_fixture`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_collision_fixture`
- `swift run -c release pebsmoke`

### Results

- Collision fixture report: `19 passed, 0 failed`, success true.
- Collision invariant report: `22 passed, 0 failed`, success true.
- All v0 occupancy statuses are covered.
- Metrics contain `terrainCollision*`.
- `events.ndjson` contains `lab_terrain_collision_fixture_recorded`.
- Debug/release builds, requested non-regression scenarios, and `pebsmoke`
  passed.
- `pebsmoke`: `456 passed, 0 failed`.

### Next Step

Phase 4.16C: add a bounded collision live read-only smoke that asks whether a
captured node is occupable without movement, displacement, pathfinding, route
following, physics, or mutation.

## 2026-06-19 — Phase 4.16C Collision Live Read-Only Smoke

Branch: `lab/pebblelab-v1`

### Objective

Add the first live read-only collision occupancy smoke. The phase reads a
single deterministic live node, adapts support/feet/head evidence to the
fixture collision evaluator, and writes an auditable result without movement,
pathfinding, route following, physics, displacement, or mutation.

### Files Created Or Modified

- `Sources/PebbleLab/LabTerrainCollisionLive.swift` (new)
- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`
- `docs/pebblelab/PHASE_4_COLLISION_PLAN.md`

No PebbleCore, renderer, shader, resource, registry, save/load, or golden file
changed.

### Live Node And Samples

The scenario `terrain_collision_live_readonly_smoke` prepares live chunks but
does not create an agent. It samples node `(8,64,8)` with seed 42:

- support `(8,63,8)`: water, semantic `liquid`, shape `liquid`;
- feet `(8,64,8)`: air, semantic `air`, shape `empty`;
- head `(8,65,8)`: air, semantic `air`, shape `empty`.

All three samples are loaded and ready, and each read preserves chunk
modified/version/dirty state.

### Occupancy Result

The live adapter builds a `LabTerrainCollisionColumnFixture` with source
`live_readonly_fixture_adapter` and calls `evaluateTerrainOccupancyFixture(...)`
with `LabHumanV0`.

The validated result is:

- status: `liquidUnsupported`;
- reason: `liquid_support`.

This is a successful negative occupancy result. Phase 4.16C proves a bounded
read-only live query and explicit reasoned classification, not physical
movement.

### Outputs, Invariants, Metrics, And Event

The scenario writes:

- `terrain_collision_live_snapshot.json`;
- `terrain_collision_live_invariant_report.json`;
- `metrics.json`;
- `events.ndjson`.

The invariant report has 25 checks covering snapshot presence, body contract,
requested node, support/feet/head sample order, loaded/ready preservation,
explicit status/reason, live adapter source, fixture adapter preservation,
no movement, no agent/placeholder/core displacement, no mutation, no
pathfinding, no route following, no goal selection, fixture/live separation,
single-result status count, and acceptance of non-occupable success.

Metrics use the `terrainCollisionLive*` prefix and the run emits one aggregate
`lab_terrain_collision_live_recorded` event.

### Safety Flags

The snapshot and event keep the safety flags explicit:

- `liveAgentDisplaced = false`;
- `physicalPlaceholderDisplaced = false`;
- `coreEntityDisplaced = false`;
- `movementPerformed = false`;
- `pathfindingPerformed = false`;
- `mutationPerformed = false`.

### Still Prohibited

No `World` mutation, terrain mutation, `World.setBlock`, `Chunk.set`, block
placement/breaking, `LabAgent` displacement or mutation, physical placeholder
displacement, core entity displacement, `stepTerrainMovement`,
`findTerrainPath`, BFS, A*, Dijkstra, route following, physics integration,
gravity, velocity, jump, fall, swim, climb, multi-agent movement, avoidance,
Python, ML, LLM, or RL integration was added.

### Validation Commands

- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario terrain_collision_live_readonly_smoke --seed 42 --ticks 5 --out runs/check_terrain_collision_live`
- `swift run -c release PebbleLab -- --scenario terrain_collision_fixture_smoke --seed 42 --ticks 0 --out runs/check_collision_fixture_after_live_collision`
- `swift run -c release PebbleLab -- --scenario terrain_path_live_movement_smoke --seed 42 --ticks 5 --out runs/check_live_movement_after_live_collision`
- `swift run -c release PebbleLab -- --scenario terrain_path_movement_fixture_smoke --seed 42 --ticks 0 --out runs/check_movement_fixture_after_live_collision`
- `swift run -c release PebbleLab -- --scenario terrain_pathfinding_column_positive_smoke --seed 42 --ticks 5 --out runs/check_positive_path_after_live_collision`
- `swift run -c release PebbleLab -- --scenario terrain_traversability_fixture_smoke --seed 42 --ticks 0 --out runs/check_traversability_after_live_collision`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_live_collision`
- `swift run -c release pebsmoke`

### Results

- Live collision snapshot: success true.
- Live occupancy result: `liquidUnsupported`, reason `liquid_support`.
- Live collision invariants: `25 passed, 0 failed`.
- Metrics contain `terrainCollisionLive*`.
- `events.ndjson` contains `lab_terrain_collision_live_recorded`.
- Debug/release builds, requested non-regression scenarios, and `pebsmoke`
  passed.
- `pebsmoke`: `456 passed, 0 failed`.

### Next Step

Phase 4.17A: plan physical movement integration docs-only before any real
agent, placeholder, or core entity displacement is attempted.

## 2026-06-19 — Phase 4.17A Physical Movement Integration Planning Docs-Only

Branch: `lab/pebblelab-v1`

### Objective

Plan the first future bridge from positive live path evidence, validated
abstract movement, and read-only live collision evidence to a physical movement
decision. This phase is documentation-only and does not implement
displacement.

### Starting State

PebbleLab already has terrain traversability fixtures, terrain scan and column
scan live evidence, pathfinding fixtures, live pathfinding negative and
positive smokes, movement fixture hardening, live path to abstract movement,
collision fixtures, and live read-only collision. These layers prove route,
value-state progression, and occupancy separately. None of them physically
moves a `LabAgent`, physical placeholder, or core entity.

### Files Created Or Modified

- `docs/pebblelab/PHASE_4_PHYSICAL_MOVEMENT_INTEGRATION_PLAN.md` (new)
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`

No Swift, PebbleCore, renderer, shader, resource, registry, save/load, or
golden file was modified.

### Why Docs-Only

Physical displacement is a new boundary. A path `found`, an abstract
`reachedGoal`, and a collision result are necessary evidence, but none should
silently become real agent movement. The plan defines a separate future
physical displacement adapter and requires explicit approval/denial evidence
before any position is changed.

### Future Approval Conditions

A future approved single-step displacement must require a positive path, a
selected 4-neighbor same-y edge, a valid movement intent, destination live
collision status `occupable`, loaded/ready evidence, preserved source/target
coordinates, required physical/core handles, source-position agreement, and
zero unexpected divergence. Non-occupable collision statuses must deny the
move.

### Refusal Path

Denied movement is a valid audited result. If the destination is liquid,
blocked, unknown, not loaded, not ready, unsupported, vertically occupied, or
out of bounds, the future adapter must leave the agent, physical placeholder,
core entity, and world unchanged while writing a status, reason, metrics, and
event.

### Future Outputs, Invariants, Metrics, And Event

The plan proposes:

- `physical_movement_integration_snapshot.json`;
- `physical_movement_integration_invariant_report.json`;
- `physicalMovement*` metrics;
- one aggregate `lab_physical_movement_integration_recorded` event.

The future invariant report should cover path evidence, selected-edge shape,
movement-intent agreement, collision evidence, denial for non-occupable
targets, no pathfinding/replanning/route following/goal selection, no physics,
no mutation, handle/link requirements, pre/post position agreement,
divergence, event, snapshot, metrics, and success-contract enforcement.

### Recommended Subdivision

The plan recommends splitting implementation:

- Phase 4.17B1 - Denied Physical Movement Smoke;
- Phase 4.17B2 - Approved Single-Step Physical Displacement Smoke;
- Phase 4.17C - Single-Step Displacement Hardening;
- Phase 4.18A - Route Following Planning Docs-Only.

This keeps the refusal path auditable before approving a physical move.

### Still Prohibited

No route following, multiple physical steps, dynamic replanning, multi-agent
movement, avoidance, reservations, combat, mining, construction, inventory,
full physics, jump, fall, swim, climb, velocity, friction, acceleration,
animation, rendering change, save/load change, registry change, Python, ML,
LLM, or RL integration is part of this phase.

### Validation Commands

- `git status`
- `swift build`
- `swift run -c release pebsmoke`
- `git status`

### Results

- Documentation-only plan created.
- No Swift files modified.
- `swift build` passed.
- `pebsmoke`: `456 passed, 0 failed`.
- Final `git status` was clean after commit.

### Next Step

Phase 4.17B1: implement a denied physical movement smoke over non-occupable
live collision evidence, with no displacement and a fully audited refusal.

## 2026-06-19 — Phase 4.17B1 Denied Physical Movement Smoke

Branch: `lab/pebblelab-v1`

### Objective

Add the first physical movement integration smoke as an expected denial. The
scenario attempts one single-step physical movement toward a non-occupable live
collision node and succeeds only because no displacement is applied.

### Files Created Or Modified

- `Sources/PebbleLab/LabPhysicalMovementIntegration.swift` (new)
- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`
- `docs/pebblelab/PHASE_4_PHYSICAL_MOVEMENT_INTEGRATION_PLAN.md`

No PebbleCore, renderer, shader, resource, registry, save/load, or golden file
changed.

### Collision Evidence

The scenario `physical_movement_denied_smoke` prepares the same bounded live
collision evidence used by Phase 4.16C. Destination node `(8,64,8)` has water
support at `(8,63,8)` and air at feet/head, so collision v0 returns:

- status: `liquidUnsupported`;
- reason: `liquid_support`.

The movement attempt is from `(7,64,8)` to `(8,64,8)`.

### Denial Result

The physical movement integration status is:

- status: `collisionDenied`;
- reason: `collision_denied_liquid_support_non_occupable`;
- `displacementApplied = false`.

The scenario uses a local `agent_0` and a local physical placeholder handle for
audit fields. It intentionally does not create a core entity, because creating
one would add a live world entity and blur the no-world-mutation boundary of
this denied smoke.

Pre/post positions are unchanged:

- abstract position: `(7,64,8) -> (7,64,8)`;
- physical placeholder position: `(7,64,8) -> (7,64,8)`;
- core entity position: not present.

Divergence remains `0 -> 0`.

### Outputs, Invariants, Metrics, And Event

The scenario writes:

- `physical_movement_integration_snapshot.json`;
- `physical_movement_integration_invariant_report.json`;
- `metrics.json`;
- `events.ndjson`.

The invariant report has 22 checks covering collision evidence, explicit
status/reason, non-occupable denial, no displacement, no pathfinding, no route
following, no goal selection, no multi-agent movement, no physics, no world
mutation, unchanged abstract/physical/core positions, preserved divergence,
runner output contracts, denial reason, the current `liquidUnsupported` case,
and the rule that approval requires `occupable`.

Metrics use the `physicalMovement*` prefix and the run emits one aggregate
`lab_physical_movement_integration_recorded` event.

### Still Prohibited

No route following, multi-agent movement, avoidance, reservation table, physics
integration, gravity, velocity, jump, fall, swim, climb, mining, construction,
inventory behavior, Python, ML, LLM, RL, world mutation, terrain mutation, or
approved physical displacement was added.

### Validation Commands

- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario physical_movement_denied_smoke --seed 42 --ticks 5 --out runs/check_physical_movement_denied`
- `swift run -c release PebbleLab -- --scenario terrain_collision_live_readonly_smoke --seed 42 --ticks 5 --out runs/check_collision_live_after_denied_movement`
- `swift run -c release PebbleLab -- --scenario terrain_collision_fixture_smoke --seed 42 --ticks 0 --out runs/check_collision_fixture_after_denied_movement`
- `swift run -c release PebbleLab -- --scenario terrain_path_live_movement_smoke --seed 42 --ticks 5 --out runs/check_live_movement_after_denied_movement`
- `swift run -c release PebbleLab -- --scenario physical_behavior_smoke --seed 42 --ticks 5 --out runs/check_physical_behavior_after_denied_movement`
- `swift run -c release PebbleLab -- --scenario physical_behavior_multi_smoke --seed 42 --ticks 5 --out runs/check_physical_behavior_multi_after_denied_movement`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_denied_movement`
- `swift run -c release pebsmoke`

### Results

- Denied physical movement snapshot: success true.
- Physical movement status: `collisionDenied`.
- Collision status: `liquidUnsupported`, reason `liquid_support`.
- Displacement applied: false.
- Divergence: `0 -> 0`.
- Invariant report: `22 passed, 0 failed`.
- Metrics contain `physicalMovement*`.
- `events.ndjson` contains `lab_physical_movement_integration_recorded`.
- Debug/release builds, requested non-regression scenarios, and `pebsmoke`
  passed.
- `pebsmoke`: `456 passed, 0 failed`.

### Next Step

Phase 4.17B2A: find or prove a reliable occupable live destination before
attempting an approved single-step physical displacement.

## 2026-06-19 — Phase 4.17B2A find occupable live destination smoke

### Objective

Find a reliable live destination with collision status `occupable` before any
approved physical displacement phase. This is a search-only smoke: it reads
live collision evidence, selects the first occupable candidate, and applies no
movement or displacement.

### Files Created/Modified

- Created `Sources/PebbleLab/LabPhysicalMovementOccupableSearch.swift`.
- Modified `Sources/PebbleLab/LabTerrainCollisionLive.swift`.
- Modified `Sources/PebbleLab/LabOptions.swift`.
- Modified `Sources/PebbleLab/LabScenarios.swift`.
- Modified `Sources/PebbleLab/LabOutput.swift`.
- Modified `Sources/PebbleLab/LabEvents.swift`.
- Modified `Sources/PebbleLab/main.swift`.
- Updated `docs/pebblelab/CHANGELOG.md`.
- Updated `docs/pebblelab/ROADMAP.md`.
- Updated `docs/pebblelab/PHASE_4_PHYSICAL_MOVEMENT_INTEGRATION_PLAN.md`.

### Search Strategy

The scenario `physical_movement_find_occupable_smoke` evaluates a tiny
deterministic multi-seed candidate list:

- candidate 0: seed 42, node `(8,64,8)`;
- candidate 1: seed 99, node `(8,64,8)`;
- candidate 2: seed 99, node `(9,64,8)`.

Seed 42 remains first so the search preserves the currently audited
`liquidUnsupported` destination. Seed 99 is included because the positive live
pathfinding smoke already proved a real live path through `(8,64,8)` and
`(9,64,8)` without mutation.

### Selected Candidate

The search selected candidate index `1`: seed `99`, node `(8,64,8)`. The live
read-only collision evidence is:

- support: `grass_block`;
- feet: `air`;
- head: `air`;
- status: `occupable`;
- reason: `full_cube_support_empty_body_volume`.

### Outputs, Invariants, Metrics, And Event

The smoke writes:

- `physical_movement_occupable_search_snapshot.json`;
- `physical_movement_occupable_search_invariant_report.json`;
- `metrics.json`;
- `events.ndjson`.

The invariant report has 22 checks covering non-empty bounded candidate order,
explicit status/reason, selected candidate existence, first-occupable
selection, coordinate preservation, no movement, no agent/placeholder/core
displacement, no pathfinding, no route following, no physics, no mutation, live
collision read-only reuse, preservation of the default collision live scenario,
and the success contract.

Metrics use the `physicalMovementOccupableSearch*` prefix. The run emits one
aggregate `lab_physical_movement_occupable_search_recorded` event.

### Still Prohibited

No movement, physical displacement, route following, pathfinding, physics
integration, world mutation, terrain mutation, agent mutation, placeholder
movement, core entity movement, multi-agent movement, avoidance, reservation
table, mining, construction, inventory behavior, Python, ML, LLM, or RL was
added.

### Validation Commands

- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario physical_movement_find_occupable_smoke --seed 42 --ticks 5 --out runs/check_physical_movement_find_occupable`
- `swift run -c release PebbleLab -- --scenario physical_movement_denied_smoke --seed 42 --ticks 5 --out runs/check_denied_movement_after_occupable_search`
- `swift run -c release PebbleLab -- --scenario terrain_collision_live_readonly_smoke --seed 42 --ticks 5 --out runs/check_collision_live_after_occupable_search`
- `swift run -c release PebbleLab -- --scenario terrain_collision_fixture_smoke --seed 42 --ticks 0 --out runs/check_collision_fixture_after_occupable_search`
- `swift run -c release PebbleLab -- --scenario terrain_path_live_movement_smoke --seed 42 --ticks 5 --out runs/check_live_movement_after_occupable_search`
- `swift run -c release PebbleLab -- --scenario physical_behavior_smoke --seed 42 --ticks 5 --out runs/check_physical_behavior_after_occupable_search`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_occupable_search`
- `swift run -c release pebsmoke`

### Results

- Occupable search snapshot: success true.
- Candidates evaluated: 3.
- Selected candidate: index `1`, seed `99`, node `(8,64,8)`.
- Selected status: `occupable`.
- Selected reason: `full_cube_support_empty_body_volume`.
- Invariant report: `22 passed, 0 failed`.
- Metrics contain `physicalMovementOccupableSearch*`.
- `events.ndjson` contains
  `lab_physical_movement_occupable_search_recorded`.
- Debug/release builds, requested non-regression scenarios, and `pebsmoke`
  passed.
- `pebsmoke`: `456 passed, 0 failed`.

### Next Step

Phase 4.17B2: approved single-step physical displacement smoke using the
identified occupable destination, still with no route following, multi-agent
movement, physics integration, terrain mutation, or gameplay movement.

## 2026-06-19 — Phase 4.17B2 approved single-step physical displacement smoke

### Objective

Apply PebbleLab's first approved physical displacement, strictly limited to one
single-step smoke. The phase combines an occupable live collision destination,
a local abstract agent, and a local physical placeholder sync. It does not add
route following, pathfinding during displacement, physics integration,
multi-agent movement, or terrain mutation.

### Files Created/Modified

- Modified `Sources/PebbleLab/LabPhysicalMovementIntegration.swift`.
- Modified `Sources/PebbleLab/LabOptions.swift`.
- Modified `Sources/PebbleLab/LabScenarios.swift`.
- Modified `Sources/PebbleLab/main.swift`.
- Updated `docs/pebblelab/CHANGELOG.md`.
- Updated `docs/pebblelab/ROADMAP.md`.
- Updated `docs/pebblelab/PHASE_4_PHYSICAL_MOVEMENT_INTEGRATION_PLAN.md`.
- Updated `docs/pebblelab/DEV_JOURNAL.md`.

### Source, Destination, And Collision

The approved edge is:

- source: `(7,64,8)`;
- destination: `(8,64,8)`;
- same-y: yes;
- 4-neighbor: yes;
- diagonal: no.

The collision evidence uses seed `99` and destination `(8,64,8)`:

- support: `grass_block`;
- feet: `air`;
- head: `air`;
- status: `occupable`;
- reason: `full_cube_support_empty_body_volume`.

### Displacement Result

The scenario creates local `agent_0` at `(7,64,8)` and a local physical
placeholder at the same position. It applies one abstract move and syncs the
physical placeholder once.

Result:

- status: `approved`;
- reason: `approved_occupable_destination_single_step`;
- `displacementApplied = true`;
- abstract position: `(7,64,8) -> (8,64,8)`;
- physical placeholder position: `(7,64,8) -> (8,64,8)`;
- core entity position: not present;
- divergence: `0 -> 0`.

The core entity remains absent by design. Creating one would add a live world
entity and is better left to a later hardening phase after the placeholder
single-step contract is stable.

### Outputs, Invariants, Metrics, And Event

The scenario writes:

- `physical_movement_integration_snapshot.json`;
- `physical_movement_integration_invariant_report.json`;
- `metrics.json`;
- `events.ndjson`.

The invariant report has 28 checks covering occupable destination evidence,
explicit collision reason, selected edge existence, 4-neighbor/same-y/no
diagonal rules, pre/post abstract and physical positions, approved status,
occupable approval gate, no pathfinding, no route following, no goal selection,
no multi-agent movement, no physics integration, no terrain/world mutation,
zero divergence before/after, runner outputs, and separation from the denied
smoke.

Metrics use the `physicalMovement*` prefix. The run emits one aggregate
`lab_physical_movement_integration_recorded` event.

### Still Prohibited

No route following, multi-agent movement, avoidance, reservation table, physics
integration, gravity, velocity, jump, fall, swim, climb, mining, construction,
inventory behavior, pathfinding during displacement, dynamic replanning,
terrain mutation, world mutation, Python, ML, LLM, or RL was added.

### Validation Commands

- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario physical_movement_approved_single_step_smoke --seed 42 --ticks 5 --out runs/check_physical_movement_approved_single_step`
- `swift run -c release PebbleLab -- --scenario physical_movement_find_occupable_smoke --seed 42 --ticks 5 --out runs/check_find_occupable_after_approved_move`
- `swift run -c release PebbleLab -- --scenario physical_movement_denied_smoke --seed 42 --ticks 5 --out runs/check_denied_movement_after_approved_move`
- `swift run -c release PebbleLab -- --scenario terrain_collision_live_readonly_smoke --seed 42 --ticks 5 --out runs/check_collision_live_after_approved_move`
- `swift run -c release PebbleLab -- --scenario terrain_collision_fixture_smoke --seed 42 --ticks 0 --out runs/check_collision_fixture_after_approved_move`
- `swift run -c release PebbleLab -- --scenario terrain_path_live_movement_smoke --seed 42 --ticks 5 --out runs/check_live_movement_after_approved_move`
- `swift run -c release PebbleLab -- --scenario physical_behavior_smoke --seed 42 --ticks 5 --out runs/check_physical_behavior_after_approved_move`
- `swift run -c release PebbleLab -- --scenario physical_behavior_multi_smoke --seed 42 --ticks 5 --out runs/check_physical_behavior_multi_after_approved_move`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_approved_move`
- `swift run -c release pebsmoke`

### Results

- Approved single-step snapshot: success true.
- Status: `approved`.
- Collision status: `occupable`.
- Displacement applied: true.
- Abstract position: `(7,64,8) -> (8,64,8)`.
- Physical placeholder position: `(7,64,8) -> (8,64,8)`.
- Divergence: `0 -> 0`.
- Invariant report: `28 passed, 0 failed`.
- Metrics contain `physicalMovement*`.
- `events.ndjson` contains `lab_physical_movement_integration_recorded`.
- Debug/release builds, requested non-regression scenarios, and `pebsmoke`
  passed.
- `pebsmoke`: `456 passed, 0 failed`.

### Next Step

Phase 4.17C: single-step displacement hardening, covering source mismatch,
missing handles, stale collision evidence, stale path evidence, divergence
cases, and explicit core-entity handling without introducing route following
or gameplay movement.

## 2026-06-19 — Phase 4.17C single-step displacement hardening

### Objective

Harden the single-step physical displacement contract before any route
following. The phase adds a bounded fixture-style smoke over local live
collision evidence and validates approved and denied one-step decisions without
pathfinding, route following, physics integration, multi-agent movement, or
terrain mutation.

### Files Created/Modified

- Modified `Sources/PebbleLab/LabPhysicalMovementIntegration.swift`.
- Modified `Sources/PebbleLab/LabOptions.swift`.
- Modified `Sources/PebbleLab/LabScenarios.swift`.
- Modified `Sources/PebbleLab/LabOutput.swift`.
- Modified `Sources/PebbleLab/LabEvents.swift`.
- Modified `Sources/PebbleLab/main.swift`.
- Updated `docs/pebblelab/CHANGELOG.md`.
- Updated `docs/pebblelab/ROADMAP.md`.
- Updated `docs/pebblelab/PHASE_4_PHYSICAL_MOVEMENT_INTEGRATION_PLAN.md`.
- Updated `docs/pebblelab/DEV_JOURNAL.md`.

### Cases Covered

The new scenario is `physical_movement_single_step_hardening_smoke`.

It covers eight deterministic cases:

- `approved_single_step`: `(7,64,8) -> (8,64,8)`, seed 99 collision
  `occupable`, displacement applied.
- `denied_non_occupable`: seed 42 collision `liquidUnsupported`, no
  displacement.
- `source_mismatch`: pre-position does not match claimed source, no
  displacement.
- `diagonal_denied`: same-y diagonal edge, no displacement.
- `vertical_denied`: vertical edge, no displacement.
- `missing_physical_handle`: no placeholder handle, no displacement.
- `divergence_before_move`: abstract and physical positions differ before the
  move, no displacement.
- `stale_collision_or_target_mismatch`: collision evidence node does not match
  the attempted target, no displacement.

### Approved And Denied Summary

Exactly one case is approved and applies displacement. Seven cases are denied
or refused and keep abstract and physical positions unchanged. The denied cases
exercise `collisionDenied`, `sourceMismatch`, `invalidEdge`,
`missingPhysicalHandle`, `divergenceBeforeMove`, and
`staleCollisionEvidence`.

### Outputs, Invariants, Metrics, And Event

The scenario writes:

- `physical_movement_single_step_hardening_report.json`;
- `physical_movement_single_step_hardening_invariant_report.json`;
- `metrics.json`;
- `events.ndjson`.

The invariant report has 28 checks covering required case presence, only one
approved displacement, denied-case immobility, approved abstract and physical
single-step movement, zero approved divergence, no pathfinding, no route
following, no physics, no world mutation, explicit status/reason, expected
status/displacement matching, and runner outputs.

Metrics use the `physicalMovementHardening*` prefix. The run emits one
aggregate `lab_physical_movement_single_step_hardening_recorded` event.

### Still Prohibited

No route following, dynamic replanning, pathfinding during displacement,
physics integration, gravity, velocity, jump, fall, swim, climb, multi-agent
movement, avoidance, reservation table, terrain mutation, world mutation,
mining, construction, inventory behavior, Python, ML, LLM, or RL was added.

### Validation Commands

- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario physical_movement_single_step_hardening_smoke --seed 42 --ticks 5 --out runs/check_physical_movement_single_step_hardening`
- `swift run -c release PebbleLab -- --scenario physical_movement_approved_single_step_smoke --seed 42 --ticks 5 --out runs/check_approved_single_step_after_hardening`
- `swift run -c release PebbleLab -- --scenario physical_movement_find_occupable_smoke --seed 42 --ticks 5 --out runs/check_find_occupable_after_hardening`
- `swift run -c release PebbleLab -- --scenario physical_movement_denied_smoke --seed 42 --ticks 5 --out runs/check_denied_movement_after_hardening`
- `swift run -c release PebbleLab -- --scenario terrain_collision_live_readonly_smoke --seed 42 --ticks 5 --out runs/check_collision_live_after_hardening`
- `swift run -c release PebbleLab -- --scenario terrain_collision_fixture_smoke --seed 42 --ticks 0 --out runs/check_collision_fixture_after_hardening`
- `swift run -c release PebbleLab -- --scenario physical_behavior_smoke --seed 42 --ticks 5 --out runs/check_physical_behavior_after_hardening`
- `swift run -c release PebbleLab -- --scenario physical_behavior_multi_smoke --seed 42 --ticks 5 --out runs/check_physical_behavior_multi_after_hardening`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_hardening`
- `swift run -c release pebsmoke`

### Results

- Hardening report: success true.
- Cases: `8 passed, 0 failed`.
- Summary: `1 approved`, `7 denied`, `1 displacementApplied`,
  `7 displacementRefused`.
- Invariant report: `28 passed, 0 failed`.
- Metrics contain `physicalMovementHardening*`.
- `events.ndjson` contains
  `lab_physical_movement_single_step_hardening_recorded`.
- Debug/release builds, requested non-regression scenarios, and `pebsmoke`
  passed.
- `pebsmoke`: `456 passed, 0 failed`.

### Next Step

Phase 4.18A: route following planning docs-only. Route following should remain
out of code until the single-step contract is stable and explicitly planned.

## 2026-06-19 — Phase 4.18A route following planning docs-only

### Objective

Define the future route following contract without implementing route
following. The phase creates a planning document for orchestrating multiple
approved single-step movements while keeping pathfinding, movement value-state,
collision, physical displacement, and future route following responsibilities
separate.

### Starting State

PebbleLab already validates terrain scans, column scans, traversability,
fixture pathfinding, live positive and negative pathfinding, movement fixtures,
live path to abstract movement, collision fixtures, live read-only collision,
denied physical movement, occupable destination search, approved single-step
physical movement, and single-step displacement hardening.

The current single-step contract has 8 hardening cases, 28 invariants, exactly
one approved displacement, and seven denied cases that do not move.

### Files Created/Modified

- Created `docs/pebblelab/PHASE_4_ROUTE_FOLLOWING_PLAN.md`.
- Updated `docs/pebblelab/CHANGELOG.md`.
- Updated `docs/pebblelab/DEV_JOURNAL.md`.
- Updated `docs/pebblelab/ROADMAP.md`.

No Swift files were modified.

### Why Docs-Only

Route following is a new orchestration boundary. It must not appear as a hidden
extension of single-step movement. The plan defines the audit surface before any
code exists: route records, per-edge collision checks, single-step adapter use,
stop reasons, metrics, and event shape.

### Route Following Contract

The future follower must consume an existing route, attempt one edge at a time,
check collision `occupable` before each edge, call the single-step adapter,
advance the route index by exactly one on success, stop on the first denial,
and never call pathfinding, replanning, goal selection, physics, terrain
mutation, or multi-agent movement.

### Stopping And Failure Modes

The plan defines future statuses for completed routes and stopped routes:
collision denial, invalid edge, source mismatch, divergence, missing physical
handle, stale path, stale collision, max steps, and unexpected mutation.
Expected stops can be invariant-successful if they preserve the last valid
position and emit an explicit reason.

### Future Outputs, Invariants, Metrics, And Event

The future route following smoke should write:

- `route_following_snapshot.json`;
- `route_following_invariant_report.json`;
- `metrics.json`;
- `events.ndjson`.

The plan proposes 30 invariant checks, `routeFollowing*` metrics, and one
aggregate `lab_route_following_recorded` event. Per-edge details belong in the
snapshot, not in per-edge events.

### Future Phase Progression

- Phase 4.18B: route following fixture smoke.
- Phase 4.18C: route following denied live smoke.
- Phase 4.18D: route following approved two-step smoke.
- Phase 4.18E: route following hardening.
- Phase 4.19A: multi-agent movement planning docs-only.

### Still Prohibited

No Swift code, route following, multi-step movement, dynamic replanning,
pathfinding inside a follower, physics integration, multi-agent movement,
avoidance, reservation table, terrain/world mutation, gameplay movement,
Python, ML, LLM, or RL was added.

### Validation Commands

- `git status`
- `swift build`
- `swift run -c release pebsmoke`
- `git diff --check`
- `git status`

### Results

The docs-only phase keeps implementation unchanged. Build and smoke validation
passed, and `pebsmoke` remains `456 passed, 0 failed`.

### Next Step

Phase 4.18B: route following fixture smoke. It should remain fixture-only and
prove route index progression, stop behavior, and no skipped nodes before any
live route following code.

## 2026-06-19 — Phase 4.18B route following fixture smoke

### Objective

Add the first route following layer as a fixture-only smoke. The scenario
simulates multi-edge orchestration over synthetic routes without `World`, live
agents, live collision, live physical placeholders, pathfinding, physics,
dynamic replanning, or mutation.

### Files Created/Modified

- Created `Sources/PebbleLab/LabRouteFollowing.swift`.
- Created `Sources/PebbleLab/LabRouteFollowingFixtures.swift`.
- Modified `Sources/PebbleLab/LabOptions.swift`.
- Modified `Sources/PebbleLab/LabScenarios.swift`.
- Modified `Sources/PebbleLab/LabOutput.swift`.
- Modified `Sources/PebbleLab/LabEvents.swift`.
- Modified `Sources/PebbleLab/main.swift`.
- Updated `docs/pebblelab/CHANGELOG.md`.
- Updated `docs/pebblelab/DEV_JOURNAL.md`.
- Updated `docs/pebblelab/ROADMAP.md`.
- Updated `docs/pebblelab/PHASE_4_ROUTE_FOLLOWING_PLAN.md`.

### Cases Covered

The new scenario is `route_following_fixture_smoke`.

It covers eight deterministic fixture cases:

- `completed_two_edges`;
- `stopped_collision_denied_second_edge`;
- `stopped_invalid_diagonal_edge`;
- `stopped_vertical_edge`;
- `stopped_source_mismatch`;
- `stopped_divergence_after_first_edge`;
- `stopped_max_steps`;
- `stopped_stale_collision`.

### Completed And Stopped Summary

The fixture report has one completed route and seven stopped routes. It records
9 attempted edge records, 5 completed edges, 5 synthetic displacements, and 4
denied edge records. The source mismatch and max-step stops happen before
another edge displacement; divergence stops immediately after the first
approved edge records divergence.

### Outputs, Invariants, Metrics, And Event

The scenario writes:

- `route_following_fixture_report.json`;
- `route_following_fixture_invariant_report.json`;
- `metrics.json`;
- `events.ndjson`.

The invariant report has 36 checks covering fixture-only/no-World behavior,
case presence, route lengths, contiguous approved edges, no skipped nodes,
index progression, completed/stopped semantics, stop-on-first-denial,
displacement gates, explicit status/reason, expected status/completed-edge
matching, and runner outputs.

Metrics use the `routeFollowingFixture*` prefix. The run emits one aggregate
`lab_route_following_fixture_recorded` event.

### Still Prohibited

No live route following, live agent displacement, live physical placeholder
movement, live collision, pathfinding, dynamic replanning, goal selection,
physics integration, multi-agent movement, avoidance, reservation table,
terrain mutation, world mutation, Python, ML, LLM, or RL was added.

### Validation Commands

- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario route_following_fixture_smoke --seed 42 --ticks 0 --out runs/check_route_following_fixture`
- `swift run -c release PebbleLab -- --scenario physical_movement_single_step_hardening_smoke --seed 42 --ticks 5 --out runs/check_single_step_hardening_after_route_fixture`
- `swift run -c release PebbleLab -- --scenario physical_movement_approved_single_step_smoke --seed 42 --ticks 5 --out runs/check_approved_single_step_after_route_fixture`
- `swift run -c release PebbleLab -- --scenario physical_movement_find_occupable_smoke --seed 42 --ticks 5 --out runs/check_find_occupable_after_route_fixture`
- `swift run -c release PebbleLab -- --scenario physical_movement_denied_smoke --seed 42 --ticks 5 --out runs/check_denied_movement_after_route_fixture`
- `swift run -c release PebbleLab -- --scenario terrain_collision_live_readonly_smoke --seed 42 --ticks 5 --out runs/check_collision_live_after_route_fixture`
- `swift run -c release PebbleLab -- --scenario terrain_collision_fixture_smoke --seed 42 --ticks 0 --out runs/check_collision_fixture_after_route_fixture`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_route_fixture`
- `swift run -c release pebsmoke`

### Results

- Route following fixture report: success true.
- Cases: `8 passed, 0 failed`.
- Summary: `1 completed`, `7 stopped`, `9 attemptedEdges`,
  `5 completedEdges`, `5 displacementsApplied`, `4 deniedEdges`.
- Invariant report: `36 passed, 0 failed`.
- Metrics contain `routeFollowingFixture*`.
- `events.ndjson` contains `lab_route_following_fixture_recorded`.
- Debug/release builds, requested non-regression scenarios, and `pebsmoke`
  passed.
- `pebsmoke`: `456 passed, 0 failed`.

### Next Step

Phase 4.18C: route following denied live smoke. It should use a short live route
with at least one collision-denied edge and succeed only if the follower stops
cleanly without route following gameplay, replanning, physics, or mutation.

## 2026-06-19 — Phase 4.18C denied live route following smoke

### Objective

Add the first live route following smoke as an expected stop, not an approved
multi-step route. The scenario `route_following_denied_live_smoke` attempts a
short deterministic live route and succeeds only if collision denies the first
edge, the follower stops immediately, and positions remain unchanged.

### Files Created/Modified

- Created `Sources/PebbleLab/LabRouteFollowingLive.swift`.
- Modified `Sources/PebbleLab/LabRouteFollowing.swift`.
- Modified `Sources/PebbleLab/LabOptions.swift`.
- Modified `Sources/PebbleLab/LabScenarios.swift`.
- Modified `Sources/PebbleLab/LabOutput.swift`.
- Modified `Sources/PebbleLab/LabEvents.swift`.
- Modified `Sources/PebbleLab/main.swift`.
- Updated `docs/pebblelab/CHANGELOG.md`.
- Updated `docs/pebblelab/DEV_JOURNAL.md`.
- Updated `docs/pebblelab/ROADMAP.md`.
- Updated `docs/pebblelab/PHASE_4_ROUTE_FOLLOWING_PLAN.md`.

### Route Used

The live route is one edge:

- from `(7,64,8)`;
- to `(8,64,8)`;
- seed `42`;
- route length `2`.

The destination is evaluated through the existing live read-only collision
adapter before any displacement decision.

### Collision Status And Stop Reason

The destination `(8,64,8)` reads support water/liquid with empty feet/head and
returns collision status `liquidUnsupported`, reason `liquid_support`.

The route follower records:

- status `stoppedCollisionDenied`;
- reason `stopped_collision_denied_liquid_support`;
- `attemptedEdges = 1`;
- `completedEdges = 0`;
- `stoppedAtIndex = 0`;
- `displacementsApplied = 0`;
- `deniedEdges = 1`.

The abstract agent and physical placeholder remain at `(7,64,8)`, with
divergence before/after equal to `0`.

### Outputs, Invariants, Metrics, And Event

The scenario writes:

- `route_following_live_snapshot.json`;
- `route_following_live_invariant_report.json`;
- `metrics.json`;
- `events.ndjson`.

The invariant report has 34 checks covering live route existence, edge shape,
starting positions, collision evidence, explicit status/reason, stop on first
denied edge, no displacement, final position preservation, no skipped nodes,
no pathfinding inside the follower, no replanning, no goal selection, no
multi-agent movement, no physics, no mutation, divergence zero, and runner
output contracts.

Metrics use the `routeFollowingLive*` prefix. The scenario emits one aggregate
`lab_route_following_recorded` event. Per-edge evidence stays in the snapshot.

### Still Prohibited

No approved live multi-step route following, long route following, pathfinding
inside the follower, dynamic replanning, goal selection, physics integration,
multi-agent movement, avoidance, reservation table, terrain mutation, world
mutation, Python, ML, LLM, or RL was added.

### Validation Commands

- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario route_following_denied_live_smoke --seed 42 --ticks 5 --out runs/check_route_following_denied_live`
- `swift run -c release PebbleLab -- --scenario route_following_fixture_smoke --seed 42 --ticks 0 --out runs/check_route_fixture_after_denied_live`
- `swift run -c release PebbleLab -- --scenario physical_movement_single_step_hardening_smoke --seed 42 --ticks 5 --out runs/check_single_step_hardening_after_denied_live`
- `swift run -c release PebbleLab -- --scenario physical_movement_approved_single_step_smoke --seed 42 --ticks 5 --out runs/check_approved_single_step_after_denied_live`
- `swift run -c release PebbleLab -- --scenario physical_movement_denied_smoke --seed 42 --ticks 5 --out runs/check_denied_movement_after_denied_live`
- `swift run -c release PebbleLab -- --scenario terrain_collision_live_readonly_smoke --seed 42 --ticks 5 --out runs/check_collision_live_after_denied_live`
- `swift run -c release PebbleLab -- --scenario terrain_collision_fixture_smoke --seed 42 --ticks 0 --out runs/check_collision_fixture_after_denied_live`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_denied_live`
- `swift run -c release pebsmoke`

### Results

- Route following live snapshot: success true.
- Status: `stoppedCollisionDenied`.
- Collision status: `liquidUnsupported`.
- Reason: `liquid_support`.
- Invariant report: `34 passed, 0 failed`.
- Metrics contain `routeFollowingLive*`.
- `events.ndjson` contains `lab_route_following_recorded`.
- Debug/release builds, requested non-regression scenarios, and `pebsmoke`
  passed.
- `pebsmoke`: `456 passed, 0 failed`.

### Next Step

Phase 4.18D: route following approved two-step smoke. It should remain short
and auditable, apply at most two approved single-step displacements, and still
avoid dynamic replanning, physics, long-route gameplay, and multi-agent
movement.

## 2026-06-19 — Phase 4.18D approved two-step live route following smoke

### Objective

Add the first approved live route following smoke. The scenario
`route_following_approved_two_step_smoke` follows exactly two live edges, then
completes because the last route node is reached. It remains a short smoke,
not gameplay route following.

### Files Created/Modified

- Modified `Sources/PebbleLab/LabRouteFollowingLive.swift`.
- Modified `Sources/PebbleLab/LabOptions.swift`.
- Modified `Sources/PebbleLab/LabScenarios.swift`.
- Modified `Sources/PebbleLab/main.swift`.
- Updated `docs/pebblelab/CHANGELOG.md`.
- Updated `docs/pebblelab/DEV_JOURNAL.md`.
- Updated `docs/pebblelab/ROADMAP.md`.
- Updated `docs/pebblelab/PHASE_4_ROUTE_FOLLOWING_PLAN.md`.

### Route Used

The live route uses seed 99 collision evidence:

- `(7,64,8) -> (8,64,8)`;
- `(8,64,8) -> (9,64,8)`.

Route length is `3`, with exactly `2` attempted edges.

### Collision Status And Reason Per Edge

- Edge 0 destination `(8,64,8)`: `occupable`,
  `full_cube_support_empty_body_volume`.
- Edge 1 destination `(9,64,8)`: `occupable`,
  `full_cube_support_empty_body_volume`.

Each destination is checked with live read-only collision before displacement.

### Completion And Positions

The scenario records:

- status `completed`;
- reason `completed_two_step_route`;
- `attemptedEdges = 2`;
- `completedEdges = 2`;
- `displacementsApplied = 2`;
- `deniedEdges = 0`;
- `stoppedAtIndex = nil`;
- final abstract position `(9,64,8)`;
- final physical placeholder position `(9,64,8)`;
- divergence before/final `0`.

### Outputs, Invariants, Metrics, And Event

The scenario writes:

- `route_following_live_snapshot.json`;
- `route_following_live_invariant_report.json`;
- `metrics.json`;
- `events.ndjson`.

The invariant report has 36 checks covering live route existence, route length
3, contiguous same-y 4-neighbor edges, start and physical position alignment,
collision before each edge, occupable collision per edge, explicit reasons,
displacement gates, route index progression, no skipped nodes, completed
status requiring the last node, final positions, divergence zero, no
pathfinding inside the follower, no replanning, no goal selection, no
multi-agent movement, no physics, no mutation, and runner output contracts.

Metrics use the `routeFollowingLive*` prefix. The scenario emits one aggregate
`lab_route_following_recorded` event.

### Still Prohibited

No long route following, gameplay route following, pathfinding inside the
follower, dynamic replanning, goal selection, physics integration, multi-agent
movement, avoidance, reservation table, terrain mutation, world mutation,
Python, ML, LLM, or RL was added.

### Validation Commands

- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario route_following_approved_two_step_smoke --seed 42 --ticks 5 --out runs/check_route_following_approved_two_step`
- `swift run -c release PebbleLab -- --scenario route_following_denied_live_smoke --seed 42 --ticks 5 --out runs/check_denied_live_route_after_approved_two_step`
- `swift run -c release PebbleLab -- --scenario route_following_fixture_smoke --seed 42 --ticks 0 --out runs/check_route_fixture_after_approved_two_step`
- `swift run -c release PebbleLab -- --scenario physical_movement_single_step_hardening_smoke --seed 42 --ticks 5 --out runs/check_single_step_hardening_after_approved_two_step`
- `swift run -c release PebbleLab -- --scenario physical_movement_approved_single_step_smoke --seed 42 --ticks 5 --out runs/check_approved_single_step_after_approved_two_step`
- `swift run -c release PebbleLab -- --scenario physical_movement_find_occupable_smoke --seed 42 --ticks 5 --out runs/check_find_occupable_after_approved_two_step`
- `swift run -c release PebbleLab -- --scenario physical_movement_denied_smoke --seed 42 --ticks 5 --out runs/check_denied_movement_after_approved_two_step`
- `swift run -c release PebbleLab -- --scenario terrain_collision_live_readonly_smoke --seed 42 --ticks 5 --out runs/check_collision_live_after_approved_two_step`
- `swift run -c release PebbleLab -- --scenario terrain_collision_fixture_smoke --seed 42 --ticks 0 --out runs/check_collision_fixture_after_approved_two_step`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_approved_two_step`
- `swift run -c release pebsmoke`
- `git diff --check`

### Results

- Route following live snapshot: success true.
- Status: `completed`.
- Route length: `3`.
- Attempted/completed edges: `2 / 2`.
- Displacements/denied edges: `2 / 0`.
- Invariant report: `36 passed, 0 failed`.
- Metrics contain `routeFollowingLive*`.
- `events.ndjson` contains `lab_route_following_recorded`.
- Debug/release builds, requested non-regression scenarios, and `pebsmoke`
  passed.
- `pebsmoke`: `456 passed, 0 failed`.

### Next Step

Phase 4.18E: route following hardening. It should keep route following short
and auditable while covering stale collision, source mismatch, divergence,
max-step, and denied-edge edge cases before any longer route or multi-agent
movement work.

## 2026-06-19 — Phase 4.18E live route following hardening

### Objective

Harden the live route following contract before any longer route or gameplay
follower work. The new scenario `route_following_live_hardening_smoke` runs a
bounded set of live/near-live route-following cases that cover completed and
stopped outcomes without adding pathfinding inside the follower, dynamic
replanning, physics, terrain mutation, or multi-agent movement.

### Files Created/Modified

- Modified `Sources/PebbleLab/LabRouteFollowing.swift`.
- Modified `Sources/PebbleLab/LabRouteFollowingLive.swift`.
- Modified `Sources/PebbleLab/LabOptions.swift`.
- Modified `Sources/PebbleLab/LabScenarios.swift`.
- Modified `Sources/PebbleLab/LabOutput.swift`.
- Modified `Sources/PebbleLab/main.swift`.
- Updated `docs/pebblelab/CHANGELOG.md`.
- Updated `docs/pebblelab/DEV_JOURNAL.md`.
- Updated `docs/pebblelab/ROADMAP.md`.
- Updated `docs/pebblelab/PHASE_4_ROUTE_FOLLOWING_PLAN.md`.

### Cases Covered

The hardening report covers 8 cases:

- `completed_two_step`;
- `stopped_collision_denied_first_edge`;
- `stopped_invalid_diagonal_edge`;
- `stopped_vertical_edge`;
- `stopped_source_mismatch`;
- `stopped_divergence_after_first_edge`;
- `stopped_stale_collision`;
- `stopped_max_steps`.

The completed case reuses the Phase 4.18D route
`(7,64,8) -> (8,64,8) -> (9,64,8)` with seed 99 collision evidence. The
collision-denied case reuses the Phase 4.18C first-edge denial under seed 42.
The source mismatch, divergence, stale collision, invalid-edge, and max-step
cases are controlled near-live harness snapshots that use the same live route
following and collision snapshot types while injecting the specific contract
fault without mutating terrain or world state.

### Completed And Stopped Summary

The scenario records:

- cases `8`;
- passed `8`;
- failed `0`;
- completed `1`;
- stopped `7`;
- attempted edges `9`;
- completed edges `4`;
- displacements applied `4`;
- denied edges `5`.

The stop cases preserve the last audited position, stop on the first denied or
invalid edge, and never continue to a later route edge after a failed contract
check.

### Outputs, Invariants, Metrics, And Event

The scenario writes:

- `route_following_live_hardening_report.json`;
- `route_following_live_hardening_invariant_report.json`;
- `metrics.json`;
- `events.ndjson`.

The invariant report has 42 checks covering case presence, explicit
status/reason, expected edge counts, expected displacements and denied edges,
completed final position, stopped final position preservation, stop on first
denied edge, no skipped nodes, route index progression, collision-before-
displacement, displacement requiring occupable collision, invalid-edge and
stale-collision no-displacement rules, max-step and divergence stops, no
pathfinding inside the follower, no replanning, no goal selection, no
multi-agent movement, no avoidance/reservation, no physics, no world/terrain
mutation, and runner output contracts.

Metrics use the `routeFollowingLiveHardening*` prefix. The scenario emits one
aggregate `lab_route_following_live_hardening_recorded` event.

### Still Prohibited

No long route following, gameplay route following, pathfinding inside the
follower, dynamic replanning, goal selection, physics integration, multi-agent
movement, avoidance, reservation table, terrain mutation, world mutation,
Python, ML, LLM, or RL was added.

### Validation Commands

- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario route_following_live_hardening_smoke --seed 42 --ticks 5 --out runs/check_route_following_live_hardening`
- `swift run -c release PebbleLab -- --scenario route_following_approved_two_step_smoke --seed 42 --ticks 5 --out runs/check_approved_two_step_after_route_hardening`
- `swift run -c release PebbleLab -- --scenario route_following_denied_live_smoke --seed 42 --ticks 5 --out runs/check_denied_live_after_route_hardening`
- `swift run -c release PebbleLab -- --scenario route_following_fixture_smoke --seed 42 --ticks 0 --out runs/check_fixture_route_after_route_hardening`
- `swift run -c release PebbleLab -- --scenario physical_movement_single_step_hardening_smoke --seed 42 --ticks 5 --out runs/check_single_step_hardening_after_route_hardening`
- `swift run -c release PebbleLab -- --scenario physical_movement_approved_single_step_smoke --seed 42 --ticks 5 --out runs/check_approved_single_step_after_route_hardening`
- `swift run -c release PebbleLab -- --scenario physical_movement_denied_smoke --seed 42 --ticks 5 --out runs/check_denied_movement_after_route_hardening`
- `swift run -c release PebbleLab -- --scenario terrain_collision_live_readonly_smoke --seed 42 --ticks 5 --out runs/check_collision_live_after_route_hardening`
- `swift run -c release PebbleLab -- --scenario terrain_collision_fixture_smoke --seed 42 --ticks 0 --out runs/check_collision_fixture_after_route_hardening`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_route_hardening`
- `swift run -c release pebsmoke`
- `git diff --check`

### Results

- Route following live hardening report: success true.
- Cases: `8 passed, 0 failed`.
- Invariant report: `42 passed, 0 failed`.
- Metrics contain `routeFollowingLiveHardening*`.
- `events.ndjson` contains `lab_route_following_live_hardening_recorded`.
- Debug/release builds, requested non-regression scenarios, and `pebsmoke`
  passed.
- `pebsmoke`: `456 passed, 0 failed`.

### Next Step

Phase 4.19A: multi-agent movement planning docs-only. Route following remains
single-agent and short; multi-agent movement, avoidance/reservation, physics,
dynamic replanning, and gameplay route following remain deferred.

## 2026-06-27 — Phase 4.19A multi-agent movement planning docs-only

### Objective

Create a technical plan for moving later from hardened single-agent route
following toward controlled multi-agent movement planning, without
implementing multi-agent movement.

### Starting State

PebbleLab already has physical placeholders, an experimental gated core entity
probe, fixture/live read-only collision, denied and approved single-step
physical movement, single-step hardening, fixture route following, denied live
route following, approved two-step live route following, and live route
following hardening. The latest route following hardening smoke validated 8
cases with 8 passed, 0 failed, 1 completed, 7 stopped, 9 attempted edges, 4
completed edges, 4 applied displacements, and 5 denied edges.

No multi-agent movement implementation exists yet.

### Files Created/Modified

- Created `docs/pebblelab/PHASE_4_MULTI_AGENT_MOVEMENT_PLAN.md`.
- Updated `docs/pebblelab/CHANGELOG.md`.
- Updated `docs/pebblelab/DEV_JOURNAL.md`.
- Updated `docs/pebblelab/ROADMAP.md`.

### Why Docs-Only

The single-agent route follower is now reliable enough to plan the next
boundary, but multi-agent movement introduces global conflicts that local route
following cannot solve safely. A docs-only phase keeps the next contract small
and reviewable before adding arbitration, reservations, or live movement.

### Single-Agent Route Following Vs Multi-Agent Movement

Single-agent route following has one agent, one route, one `currentIndex`, one
edge per step, local collision checks, and local stop states.

Multi-agent movement has N agents, N intentions, node conflicts, edge
conflicts, swaps, partial approvals, priority/order decisions, global tick
coherence, aggregate logs, and global invariants. The future route follower
should produce a next-edge intent; a separate arbiter should decide whether it
may be applied.

### Conflicts To Plan For

The plan defines same-destination conflicts, edge swaps, future crossing-edge
conflicts, occupied static destinations, moving-away destinations, chain
dependencies, cycles, route denial conflicts, priority conflicts, and stale
intent/source mismatch.

### Future Arbiter And State

The recommended v0 arbiter collects all intentions, sorts agents by stable
`agentId`, denies source mismatches and non-occupable destinations, resolves
same-destination conflicts by stable order, denies swaps and cycles, applies at
most one edge per agent per tick, does not replan, does not search
alternatives, does not push agents, and logs every denial reason.

The plan proposes future status and decision sketches such as
`LabMultiAgentMovementStatus`, `LabMultiAgentMoveDecision`,
`LabAgentMoveIntent`, `LabAgentMoveResolution`, and
`LabMultiAgentMovementSnapshot`.

### Future Outputs, Invariants, Metrics, And Event

The plan recommends:

- `multi_agent_movement_report.json`;
- `multi_agent_movement_invariant_report.json`;
- `multi_agent_movement_snapshot.json`;
- `metrics.json`;
- `events.ndjson`.

It proposes `multiAgentMovement*` metrics for attempts, agent count, intents,
approvals, denials, same-destination conflicts, swaps, occupied destinations,
source mismatches, collision denials, divergence, pathfinding/replanning/
physics/mutation guard flags, and success.

It also proposes one aggregate event:
`lab_multi_agent_movement_recorded`.

The future invariant list includes more than 35 checks covering agent and
intent presence, explicit sources and destinations, 4-neighbor same-y edges,
source/current-position coherence, duplicate approved destination prevention,
swap/cycle denial, occupied-destination denial, deterministic ordering,
denied-position preservation, one-edge movement, no skipped nodes, count
coherence, final position coherence, bounded divergence, single-step ownership
of displacement, collision-before-approval for live scenarios, no pathfinding,
no replanning, no goal selection, no avoidance, no reservation table in the
first fixture smoke, no physics, no world/terrain mutation, and report/metric/
event output contracts.

### Future Phases Recommended

- Phase 4.19B: multi-agent movement fixture planning/contract smoke.
- Phase 4.19C: multi-agent movement fixture hardening.
- Phase 4.19D: multi-agent live read-only collision intent smoke.
- Phase 4.19E: multi-agent approved physical movement smoke.
- Phase 4.19F: multi-agent movement hardening.

### Validation

Requested validation for this docs-only phase:

- `git status`;
- `swift build`;
- `swift run -c release pebsmoke`;
- `git diff --check`;
- `git status`.

### Next Step

Phase 4.19B: multi-agent movement fixture smoke. It should remain fixture-only
with synthetic agents and intentions, no `World`, no live collision, no
movement application, no reservation table runtime, no avoidance, no
replanning, and no pathfinding inside arbitration.

## 2026-06-27 — Phase 4.19B multi-agent movement fixture smoke

### Objective

Implement the first fixture-only multi-agent movement arbitration smoke. The
scenario validates deterministic arbitration over synthetic agents, synthetic
positions, and synthetic next-edge intentions before any live collision or
physical movement integration.

### Starting State

Phase 4.19A documented the future multi-agent movement contract. Route
following remained single-agent, hardened, and separate from global
arbitration. No multi-agent movement runtime existed yet.

### Files Created/Modified

- Created `Sources/PebbleLab/LabMultiAgentMovement.swift`.
- Modified `Sources/PebbleLab/LabOptions.swift`.
- Modified `Sources/PebbleLab/LabScenarios.swift`.
- Modified `Sources/PebbleLab/LabOutput.swift`.
- Modified `Sources/PebbleLab/LabEvents.swift`.
- Modified `Sources/PebbleLab/main.swift`.
- Updated `docs/pebblelab/CHANGELOG.md`.
- Updated `docs/pebblelab/DEV_JOURNAL.md`.
- Updated `docs/pebblelab/ROADMAP.md`.
- Updated `docs/pebblelab/PHASE_4_MULTI_AGENT_MOVEMENT_PLAN.md`.

### Why Fixture-Only

The smoke tests only the arbitration contract. It does not create or use
`World`, does not query live collision, does not call pathfinding, does not
call route following live, does not call live physical movement, and does not
touch placeholders, core entities, physics, terrain, or world mutation.

### Cases Covered

- `two_agents_different_destinations_approved`;
- `same_destination_conflict`;
- `occupied_destination_conflict`;
- `swap_conflict`;
- `source_mismatch`;
- `stale_intent_duplicate_source_or_route_index`;
- `missing_agent`;
- `invalid_edge_diagonal_or_vertical`.

### Arbitration Policy

The fixture arbiter sorts intentions by stable `agentId`. It denies missing
agents, stale intents, source mismatches, invalid non-4-neighbor or vertical
edges, and occupied static destinations before resolving global conflicts. It
denies both sides of a swap in v0, approves only the first stable agent for a
shared destination, applies approved moves to fixture-only abstract positions,
and preserves denied positions.

### Outputs, Invariants, Metrics, And Event

The scenario writes:

- `multi_agent_movement_fixture_report.json`;
- `multi_agent_movement_fixture_invariant_report.json`;
- `metrics.json`;
- `events.ndjson`.

The report records 8 cases, 8 passed, 0 failed, 10 fixture agents total, 11
intents, 3 approved moves, and 8 denied moves. Conflict totals are 1
same-destination denial, 1 occupied static destination denial, 2 swap denials,
1 source mismatch, 1 stale intent, 1 missing agent, and 1 invalid edge.

The invariant report has 47 checks and passes all of them. Metrics use the
`multiAgentMovementFixture*` prefix. The scenario emits one aggregate
`lab_multi_agent_movement_fixture_recorded` event.

### Confirmed Out Of Scope

No `World`, live collision, pathfinding, replanning, goal selection, avoidance,
reservation table runtime, physics, physical placeholder movement, core entity
movement, terrain mutation, or world mutation is performed. The runner prints
`dim=fixture`, and no `world_snapshot.json` is written for this scenario.

### Validation Commands

- `git status`
- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario multi_agent_movement_fixture_smoke --seed 42 --ticks 0 --out runs/check_multi_agent_movement_fixture`
- `swift run -c release PebbleLab -- --scenario route_following_live_hardening_smoke --seed 42 --ticks 5 --out runs/check_route_following_live_hardening_after_multi_agent_fixture`
- `swift run -c release PebbleLab -- --scenario route_following_approved_two_step_smoke --seed 42 --ticks 5 --out runs/check_route_approved_after_multi_agent_fixture`
- `swift run -c release PebbleLab -- --scenario route_following_denied_live_smoke --seed 42 --ticks 5 --out runs/check_route_denied_after_multi_agent_fixture`
- `swift run -c release PebbleLab -- --scenario route_following_fixture_smoke --seed 42 --ticks 0 --out runs/check_route_fixture_after_multi_agent_fixture`
- `swift run -c release PebbleLab -- --scenario physical_movement_single_step_hardening_smoke --seed 42 --ticks 5 --out runs/check_single_step_hardening_after_multi_agent_fixture`
- `swift run -c release PebbleLab -- --scenario physical_movement_approved_single_step_smoke --seed 42 --ticks 5 --out runs/check_approved_single_step_after_multi_agent_fixture`
- `swift run -c release PebbleLab -- --scenario physical_movement_denied_smoke --seed 42 --ticks 5 --out runs/check_denied_single_step_after_multi_agent_fixture`
- `swift run -c release PebbleLab -- --scenario terrain_collision_live_readonly_smoke --seed 42 --ticks 5 --out runs/check_collision_live_after_multi_agent_fixture`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_multi_agent_fixture`
- `swift run -c release pebsmoke`
- `git diff --check`

### Results

- Fixture report: success true.
- Invariant report: success true.
- Cases: 8 passed, 0 failed.
- Approved/denied totals: 3 / 8.
- Invariant checks: 47 passed, 0 failed.
- Metrics contain `multiAgentMovementFixture*`.
- `events.ndjson` contains `lab_multi_agent_movement_fixture_recorded`.
- `pebsmoke`: 456 passed, 0 failed.

### Next Step

Phase 4.19C: multi-agent movement fixture hardening. It should expand edge
coverage while staying fixture-only, with no live collision, physical movement
live, reservation table runtime, avoidance, replanning, physics, or mutation.

## 2026-06-27 — Phase 4.19C multi-agent movement fixture hardening

### Objective

Harden the fixture-only multi-agent movement arbiter with adversarial
synthetic intent cases before adding any live collision intent smoke or live
movement application.

### Starting State

Phase 4.19B added `multi_agent_movement_fixture_smoke` with 8 fixture cases,
8 passed, 0 failed, 3 approved moves, and 8 denied moves. It proved stable
`agentId` ordering, same-destination conflict handling, occupied destination,
swap denial, source mismatch, stale intent, missing agent, invalid edge, no
duplicate approved destination, no approved swap, denied-position
preservation, and no `World`.

### Files Created/Modified

- Modified `Sources/PebbleLab/LabMultiAgentMovement.swift`.
- Modified `Sources/PebbleLab/LabOptions.swift`.
- Modified `Sources/PebbleLab/LabScenarios.swift`.
- Modified `Sources/PebbleLab/LabOutput.swift`.
- Modified `Sources/PebbleLab/LabEvents.swift`.
- Modified `Sources/PebbleLab/main.swift`.
- Updated `docs/pebblelab/CHANGELOG.md`.
- Updated `docs/pebblelab/DEV_JOURNAL.md`.
- Updated `docs/pebblelab/ROADMAP.md`.
- Updated `docs/pebblelab/PHASE_4_MULTI_AGENT_MOVEMENT_PLAN.md`.

### Cases Covered

- `unordered_intents_still_resolve_by_agent_id`;
- `duplicate_intents_same_agent_denied`;
- `three_agent_cycle_denied`;
- `chain_dependency_denied`;
- `moving_away_destination_denied`;
- `invalid_vertical_edge`;
- `zero_length_edge_denied`;
- `all_denied_mixed_reasons`;
- `empty_intents_noop_success`;
- `max_agents_bound_exceeded`.

### Hardening Policy

The hardening path reuses the fixture arbiter. It still sorts by stable
`agentId`, so unordered input cannot change conflict winners. Duplicate
intents from one agent are all denied with `deniedDuplicateIntent`. Swaps are
denied before general cycle checks. Multi-agent cycles are denied with
`deniedCycleConflict`. Chain dependencies and moving-away destinations are
conservatively denied in v0 with explicit decisions rather than applying
simultaneous dependent movement. Zero-length edges are denied separately from
other invalid edges. A fixture-only max-agent bound denies all intents with
`deniedMaxAgents` when exceeded.

### Outputs, Invariants, Metrics, And Event

The scenario writes:

- `multi_agent_movement_fixture_hardening_report.json`;
- `multi_agent_movement_fixture_hardening_invariant_report.json`;
- `metrics.json`;
- `events.ndjson`.

The report records 10 cases, 10 passed, 0 failed, 1 approved move, and 20
denied moves. Conflict and guard totals are 2 duplicate-intent denials, 3
cycle denials, 2 chain-dependency denials, 2 moving-away destination denials,
2 vertical invalid-edge denials, 1 zero-length edge denial, 8 all-denied
cases, 1 empty-intents case, and 5 max-agent denials.

The invariant report has 43 checks and passes all of them. Metrics use the
`multiAgentMovementFixtureHardening*` prefix. The scenario emits one aggregate
`lab_multi_agent_movement_fixture_hardening_recorded` event.

### Confirmed Out Of Scope

No `World`, live collision, pathfinding, replanning, goal selection, avoidance,
reservation table runtime, physics, physical placeholder movement, core entity
movement, terrain mutation, or world mutation is performed. The runner prints
`dim=fixture`, and no `world_snapshot.json` is written for this scenario.

### Validation Commands

- `git status`
- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario multi_agent_movement_fixture_hardening_smoke --seed 42 --ticks 0 --out runs/check_multi_agent_movement_fixture_hardening`
- `swift run -c release PebbleLab -- --scenario multi_agent_movement_fixture_smoke --seed 42 --ticks 0 --out runs/check_multi_agent_fixture_after_hardening`
- `swift run -c release PebbleLab -- --scenario route_following_live_hardening_smoke --seed 42 --ticks 5 --out runs/check_route_following_live_hardening_after_multi_agent_hardening`
- `swift run -c release PebbleLab -- --scenario route_following_approved_two_step_smoke --seed 42 --ticks 5 --out runs/check_route_approved_after_multi_agent_hardening`
- `swift run -c release PebbleLab -- --scenario route_following_denied_live_smoke --seed 42 --ticks 5 --out runs/check_route_denied_after_multi_agent_hardening`
- `swift run -c release PebbleLab -- --scenario route_following_fixture_smoke --seed 42 --ticks 0 --out runs/check_route_fixture_after_multi_agent_hardening`
- `swift run -c release PebbleLab -- --scenario physical_movement_single_step_hardening_smoke --seed 42 --ticks 5 --out runs/check_single_step_hardening_after_multi_agent_hardening`
- `swift run -c release PebbleLab -- --scenario physical_movement_approved_single_step_smoke --seed 42 --ticks 5 --out runs/check_approved_single_step_after_multi_agent_hardening`
- `swift run -c release PebbleLab -- --scenario physical_movement_denied_smoke --seed 42 --ticks 5 --out runs/check_denied_single_step_after_multi_agent_hardening`
- `swift run -c release PebbleLab -- --scenario terrain_collision_live_readonly_smoke --seed 42 --ticks 5 --out runs/check_collision_live_after_multi_agent_hardening`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_multi_agent_hardening`
- `swift run -c release pebsmoke`
- `git diff --check`

### Results

- Hardening report: success true.
- Hardening invariant report: success true.
- Cases: 10 passed, 0 failed.
- Approved/denied totals: 1 / 20.
- Invariant checks: 43 passed, 0 failed.
- The original 4.19B fixture smoke remains green.
- Metrics contain `multiAgentMovementFixtureHardening*`.
- `events.ndjson` contains
  `lab_multi_agent_movement_fixture_hardening_recorded`.
- `pebsmoke`: 456 passed, 0 failed.

### Next Step

Phase 4.19D: multi-agent live read-only collision intent smoke. It should
collect live collision evidence for candidate multi-agent intentions without
applying movement, adding reservation runtime, avoidance, replanning, physics,
or mutation.

## 2026-06-27 — Phase 4.19D multi-agent live read-only collision intent smoke

### Objective

Bridge fixture-only multi-agent arbitration to future live physical
multi-agent movement by reading live collision evidence for synthetic
multi-agent intentions without applying movement.

### Starting State

Phase 4.19B proved deterministic fixture-only arbitration over 8 cases.
Phase 4.19C hardened that fixture arbiter over 10 adversarial cases,
including duplicate intents, cycles, chain dependencies, moving-away
destinations, zero-length edges, and max-agent bounds. Neither phase used
`World`, live collision, pathfinding, replanning, physics, or mutation.

### Files Created/Modified

- Modified `Sources/PebbleLab/LabMultiAgentMovement.swift`.
- Modified `Sources/PebbleLab/LabOptions.swift`.
- Modified `Sources/PebbleLab/LabScenarios.swift`.
- Modified `Sources/PebbleLab/LabOutput.swift`.
- Modified `Sources/PebbleLab/LabEvents.swift`.
- Modified `Sources/PebbleLab/main.swift`.
- Updated `docs/pebblelab/CHANGELOG.md`.
- Updated `docs/pebblelab/DEV_JOURNAL.md`.
- Updated `docs/pebblelab/ROADMAP.md`.
- Updated `docs/pebblelab/PHASE_4_MULTI_AGENT_MOVEMENT_PLAN.md`.

### Why Live Read-Only

The scenario uses live `World` collision evidence only to classify intent
destinations as occupable or non-occupable. It does not create or move
physical placeholders, create or move core entities, call route following
live, call single-step physical movement apply, or mutate terrain/world
state. Approved results are intent approvals only.

### Cases Covered

- `occupable_destination_intent_approved_readonly`;
- `two_occupable_destinations_non_conflicting_readonly`;
- `non_occupable_destination_denied_readonly`;
- `same_destination_conflict_after_occupable_collision`;
- `source_mismatch_skips_collision`;
- `invalid_edge_skips_collision`;
- `stale_intent_skips_collision`.

### Collision Evidence Policy

Valid same-y 4-neighbor intentions with matching current source read live
collision for their destination. Occupable destinations may be approved by
stable `agentId` arbitration. Non-occupable destinations are denied with
`deniedCollision`. Source mismatch, invalid edge, and stale intents are
denied before live collision is read.

### Outputs, Invariants, Metrics, And Event

The scenario writes:

- `multi_agent_live_collision_intent_report.json`;
- `multi_agent_live_collision_intent_invariant_report.json`;
- `metrics.json`;
- `events.ndjson`.

The report records 7 cases, 7 passed, 0 failed, 4 approved intent
resolutions, 5 denied intent resolutions, 5 occupable live destinations, 1
non-occupable live destination, 1 collision denial, 1 same-destination
conflict, 1 source mismatch, 1 invalid edge, and 1 stale intent.

The invariant report has 38 checks and passes all of them. Metrics use the
`multiAgentLiveCollisionIntent*` prefix. The scenario emits one aggregate
`lab_multi_agent_live_collision_intent_recorded` event.

### Confirmed Out Of Scope

No displacement, physical movement application, physical placeholder
movement, core entity movement, route following live, pathfinding, replanning,
goal selection, avoidance, reservation table runtime, physics, terrain
mutation, or world mutation is performed.

### Validation Commands

- `git status`
- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario multi_agent_live_collision_intent_smoke --seed 42 --ticks 5 --out runs/check_multi_agent_live_collision_intent`
- `swift run -c release PebbleLab -- --scenario multi_agent_movement_fixture_smoke --seed 42 --ticks 0 --out runs/check_multi_agent_fixture_after_live_collision_intent`
- `swift run -c release PebbleLab -- --scenario multi_agent_movement_fixture_hardening_smoke --seed 42 --ticks 0 --out runs/check_multi_agent_fixture_hardening_after_live_collision_intent`
- `swift run -c release PebbleLab -- --scenario terrain_collision_live_readonly_smoke --seed 42 --ticks 5 --out runs/check_collision_live_after_multi_agent_live_collision_intent`
- `swift run -c release PebbleLab -- --scenario route_following_live_hardening_smoke --seed 42 --ticks 5 --out runs/check_route_following_live_hardening_after_multi_agent_live_collision_intent`
- `swift run -c release PebbleLab -- --scenario physical_movement_single_step_hardening_smoke --seed 42 --ticks 5 --out runs/check_single_step_hardening_after_multi_agent_live_collision_intent`
- `swift run -c release PebbleLab -- --scenario physical_movement_approved_single_step_smoke --seed 42 --ticks 5 --out runs/check_approved_single_step_after_multi_agent_live_collision_intent`
- `swift run -c release PebbleLab -- --scenario physical_movement_denied_smoke --seed 42 --ticks 5 --out runs/check_denied_single_step_after_multi_agent_live_collision_intent`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_multi_agent_live_collision_intent`
- `swift run -c release pebsmoke`
- `git diff --check`

### Results

- Live collision intent report: success true.
- Live collision intent invariant report: success true.
- Cases: 7 passed, 0 failed.
- Approved/denied totals: 4 / 5.
- Occupable/non-occupable destination totals: 5 / 1.
- Invariant checks: 38 passed, 0 failed.
- Metrics contain `multiAgentLiveCollisionIntent*`.
- `events.ndjson` contains
  `lab_multi_agent_live_collision_intent_recorded`.

### Next Step

Phase 4.19E: multi-agent approved physical movement smoke. It should remain
small and bounded, with two or three agents maximum, one approved edge each,
no replanning, no route repair, no reservation runtime, no avoidance, and no
gameplay movement.

## 2026-06-27 — Phase 4.19E multi-agent approved physical movement smoke

### Objective

Apply the first controlled multi-agent physical placeholder movement: two
agents, two occupable destinations, one approved edge each, no conflicts, and
no denied live movement.

### Starting State

Phase 4.19B established fixture-only deterministic arbitration. Phase 4.19C
hardened fixture conflicts and dependency cases. Phase 4.19D added live
read-only collision intent evidence without displacement. Phase 4.19E builds
on that by allowing only the smallest approved physical movement case.

### Files Created/Modified

- Modified `Sources/PebbleLab/LabMultiAgentMovement.swift`.
- Modified `Sources/PebbleLab/LabOptions.swift`.
- Modified `Sources/PebbleLab/LabScenarios.swift`.
- Modified `Sources/PebbleLab/LabOutput.swift`.
- Modified `Sources/PebbleLab/LabEvents.swift`.
- Modified `Sources/PebbleLab/main.swift`.
- Updated `docs/pebblelab/CHANGELOG.md`.
- Updated `docs/pebblelab/DEV_JOURNAL.md`.
- Updated `docs/pebblelab/ROADMAP.md`.
- Updated `docs/pebblelab/PHASE_4_MULTI_AGENT_MOVEMENT_PLAN.md`.

### Why Approved-Only

Denied live multi-agent movement and live conflict handling require more
hardening. This phase proves only the success path: both destinations are
live occupable, there is no same-destination conflict, no swap conflict, no
source mismatch, and every intent can be applied as exactly one edge.

### Cases Covered

- `two_agents_two_approved_single_step_moves`;
- `deterministic_order_two_approved_moves`.

### Collision And Movement Application Policy

Each valid intent reads live collision for its destination using seed 99.
Only occupable destinations can be approved. Approved moves set a one-edge
abstract movement action on each synthetic agent and then synchronize the
existing physical placeholder bridge. No route follower state is created or
advanced.

### Outputs, Invariants, Metrics, And Event

The scenario writes:

- `multi_agent_approved_physical_movement_report.json`;
- `multi_agent_approved_physical_movement_invariant_report.json`;
- `metrics.json`;
- `events.ndjson`.

The report records 2 cases, 2 passed, 0 failed, 4 approved resolutions, 0
denied resolutions, 4 displacements applied, 4 occupable live destinations,
0 non-occupable live destinations, divergence before max 0, and divergence
after max 0.

The invariant report has 42 checks and passes all of them. Metrics use the
`multiAgentApprovedPhysicalMovement*` prefix. The scenario emits one
aggregate `lab_multi_agent_approved_physical_movement_recorded` event.

### Confirmed Movement

In each case, `agent_0` moves from `(7,64,8)` to `(8,64,8)` and `agent_1`
moves from `(9,64,7)` to `(9,64,8)`. Abstract final positions match physical
placeholder final positions. `divergenceBeforeMax` and `divergenceAfterMax`
are both 0.

### Confirmed Out Of Scope

No route following, pathfinding, replanning, goal selection, avoidance,
reservation table runtime, physics, terrain mutation, world mutation, denied
live multi-agent movement, long route following, route repair, save/load, or
gameplay movement is performed.

### Validation Commands

- `git status`
- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario multi_agent_approved_physical_movement_smoke --seed 42 --ticks 5 --out runs/check_multi_agent_approved_physical_movement`
- `swift run -c release PebbleLab -- --scenario multi_agent_live_collision_intent_smoke --seed 42 --ticks 5 --out runs/check_multi_agent_live_collision_intent_after_approved_multi_agent_movement`
- `swift run -c release PebbleLab -- --scenario multi_agent_movement_fixture_smoke --seed 42 --ticks 0 --out runs/check_multi_agent_fixture_after_approved_multi_agent_movement`
- `swift run -c release PebbleLab -- --scenario multi_agent_movement_fixture_hardening_smoke --seed 42 --ticks 0 --out runs/check_multi_agent_fixture_hardening_after_approved_multi_agent_movement`
- `swift run -c release PebbleLab -- --scenario terrain_collision_live_readonly_smoke --seed 42 --ticks 5 --out runs/check_collision_live_after_approved_multi_agent_movement`
- `swift run -c release PebbleLab -- --scenario physical_movement_approved_single_step_smoke --seed 42 --ticks 5 --out runs/check_approved_single_step_after_multi_agent_approved_movement`
- `swift run -c release PebbleLab -- --scenario physical_movement_single_step_hardening_smoke --seed 42 --ticks 5 --out runs/check_single_step_hardening_after_multi_agent_approved_movement`
- `swift run -c release PebbleLab -- --scenario physical_movement_denied_smoke --seed 42 --ticks 5 --out runs/check_denied_single_step_after_multi_agent_approved_movement`
- `swift run -c release PebbleLab -- --scenario route_following_live_hardening_smoke --seed 42 --ticks 5 --out runs/check_route_following_live_hardening_after_multi_agent_approved_movement`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_multi_agent_approved_movement`
- `swift run -c release pebsmoke`
- `git diff --check`

### Results

- Approved physical movement report: success true.
- Approved physical movement invariant report: success true.
- Cases: 2 passed, 0 failed.
- Approved/denied totals: 4 / 0.
- Displacements applied: 4.
- Occupable/non-occupable destination totals: 4 / 0.
- Divergence before/after max: 0 / 0.
- Metrics contain `multiAgentApprovedPhysicalMovement*`.
- `events.ndjson` contains
  `lab_multi_agent_approved_physical_movement_recorded`.

### Next Step

Phase 4.19F: multi-agent movement hardening. It should add denied live
movement and conflict coverage around same-destination, swap, collision
denied, source mismatch, stale collision, partial approval, and max
agents/tick bounds while keeping avoidance, reservation runtime, replanning,
physics, and gameplay movement out of scope.

## 2026-06-27 — Phase 4.19F multi-agent movement hardening

### Objective

Harden live multi-agent movement after the approved-only smoke by covering
controlled denials, conflicts, partial approval, divergence, stale collision
evidence, and a hardening-only max-agent bound.

### Starting State

Phase 4.19B added deterministic fixture-only arbitration. Phase 4.19C
hardened fixture arbitration. Phase 4.19D added live read-only collision
intent evidence with no displacement. Phase 4.19E added the first approved
multi-agent physical placeholder movement: two agents, two occupable
destinations, one edge each, no denials, and divergence zero.

### Files Created/Modified

- Modified `Sources/PebbleLab/LabMultiAgentMovement.swift`.
- Modified `Sources/PebbleLab/LabOptions.swift`.
- Modified `Sources/PebbleLab/LabScenarios.swift`.
- Modified `Sources/PebbleLab/LabOutput.swift`.
- Modified `Sources/PebbleLab/LabEvents.swift`.
- Modified `Sources/PebbleLab/main.swift`.
- Updated `docs/pebblelab/CHANGELOG.md`.
- Updated `docs/pebblelab/DEV_JOURNAL.md`.
- Updated `docs/pebblelab/ROADMAP.md`.
- Updated `docs/pebblelab/PHASE_4_MULTI_AGENT_MOVEMENT_PLAN.md`.

### Why Hardening

The previous live movement phase only proved the success path. This phase
keeps the same bounded physical placeholder contract but adds adversarial
live cases around collision denial, same-destination conflict, swap conflict,
source mismatch, stale intent, invalid edge, divergence before movement,
stale collision evidence, partial approval, all-denied outcomes, and
max-agent overflow. It remains a smoke/hardening harness, not gameplay
movement.

### Cases Covered

- `approved_two_agents_remains_green`;
- `collision_denied_preserves_position`;
- `partial_approval_one_approved_one_collision_denied`;
- `same_destination_live_conflict_denies_loser`;
- `swap_conflict_live_denies_both`;
- `source_mismatch_live_denied_before_collision`;
- `stale_intent_live_denied_before_collision`;
- `invalid_edge_live_denied_before_collision`;
- `divergence_before_movement_denied`;
- `stale_collision_evidence_denied`;
- `all_denied_live_mixed_reasons`;
- `max_agents_live_bound_exceeded`.

### Approved, Denied, And Partial Approval Policy

Valid intents are processed in stable `agentId` order. Source mismatch, stale
intent, invalid edge, divergence-before, swap conflict, and max-agent overflow
are denied before live collision is read. Remaining valid intents read live
collision evidence. Occupable destinations may be approved unless a
same-destination conflict makes the stable-order loser deny. Non-occupable
destinations are denied with `deniedCollision`. Only approved resolutions
apply one abstract edge and synchronize the physical placeholder.

The partial approval case uses controlled per-intent live evidence: one
agent reads seed 99 occupable evidence and moves, while the other reads seed
42 non-occupable evidence for its destination and remains unchanged.

### Divergence And Stale Collision Policy

The divergence case starts the physical placeholder at a different node than
the abstract agent and denies movement with `deniedDivergence` before
collision is read. The stale collision case reads live evidence for a
different node than the intent destination and denies with
`deniedStaleCollision`. Both are controlled hardening injections and do not
mutate terrain/world state.

### Outputs, Invariants, Metrics, And Event

The scenario writes:

- `multi_agent_movement_hardening_report.json`;
- `multi_agent_movement_hardening_invariant_report.json`;
- `metrics.json`;
- `events.ndjson`.

The report records 12 cases, 12 passed, 0 failed, 4 approved resolutions, 18
denied resolutions, 4 displacements applied, 6 occupable live destinations,
3 non-occupable live destinations, 3 collision denials, 1 same-destination
conflict, 2 swap denials, 2 source mismatches, 1 stale intent, 2 invalid
edges, 1 divergence denial, 1 stale collision denial, 9 all-denied cases,
5 max-agent denials, divergence before max 1, and divergence after max 1.

The invariant report has 55 checks and passes all of them. Metrics use the
`multiAgentMovementHardening*` prefix. The scenario emits one aggregate
`lab_multi_agent_movement_hardening_recorded` event.

### Confirmed Out Of Scope

No route following, pathfinding, replanning, goal selection, avoidance,
reservation table runtime, physics, terrain mutation, world mutation,
save/load change, registry change, social behavior, communication, long
route following, route repair, or gameplay movement is performed.

### Validation Commands

- `git status`
- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario multi_agent_movement_hardening_smoke --seed 42 --ticks 5 --out runs/check_multi_agent_movement_hardening`
- `swift run -c release PebbleLab -- --scenario multi_agent_approved_physical_movement_smoke --seed 42 --ticks 5 --out runs/check_multi_agent_approved_physical_after_hardening`
- `swift run -c release PebbleLab -- --scenario multi_agent_live_collision_intent_smoke --seed 42 --ticks 5 --out runs/check_multi_agent_live_collision_intent_after_hardening`
- `swift run -c release PebbleLab -- --scenario multi_agent_movement_fixture_smoke --seed 42 --ticks 0 --out runs/check_multi_agent_fixture_after_hardening`
- `swift run -c release PebbleLab -- --scenario multi_agent_movement_fixture_hardening_smoke --seed 42 --ticks 0 --out runs/check_multi_agent_fixture_hardening_after_hardening`
- `swift run -c release PebbleLab -- --scenario physical_movement_single_step_hardening_smoke --seed 42 --ticks 5 --out runs/check_single_step_hardening_after_multi_agent_hardening`
- `swift run -c release PebbleLab -- --scenario physical_movement_approved_single_step_smoke --seed 42 --ticks 5 --out runs/check_approved_single_step_after_multi_agent_hardening`
- `swift run -c release PebbleLab -- --scenario physical_movement_denied_smoke --seed 42 --ticks 5 --out runs/check_denied_single_step_after_multi_agent_hardening`
- `swift run -c release PebbleLab -- --scenario route_following_live_hardening_smoke --seed 42 --ticks 5 --out runs/check_route_following_live_hardening_after_multi_agent_hardening`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_multi_agent_hardening`
- `swift run -c release pebsmoke`
- `git diff --check`

### Results

- Multi-agent movement hardening report: success true.
- Multi-agent movement hardening invariant report: success true.
- Cases: 12 passed, 0 failed.
- Approved/denied totals: 4 / 18.
- Displacements applied: 4.
- Occupable/non-occupable destination totals: 6 / 3.
- Divergence before/after max: 1 / 1.
- Invariant checks: 55 passed, 0 failed.
- Metrics contain `multiAgentMovementHardening*`.
- `events.ndjson` contains
  `lab_multi_agent_movement_hardening_recorded`.

### Next Step

Phase 4.20A: multi-agent movement integration planning docs-only. It should
define the next integration boundary before adding reservation runtime,
avoidance, dynamic replanning, route repair, physics, save/load, social
behavior, gameplay movement, or long-running multi-agent navigation.

## 2026-06-27 — Phase 4.20A multi-agent movement integration planning docs-only

### Objective

Document how PebbleLab should integrate the validated 4.19 multi-agent
movement smokes into a future tick-level movement contract without
implementing that runtime integration yet.

### Starting State

Phase 4.19A documented the multi-agent movement contract. Phase 4.19B proved
fixture-only arbitration. Phase 4.19C hardened fixture arbitration. Phase
4.19D proved live read-only collision evidence for movement intents. Phase
4.19E proved approved physical placeholder application. Phase 4.19F hardened
live multi-agent movement with controlled refusals, partial approval,
same-destination conflict, swap conflict, source mismatch, stale intent,
invalid edge, divergence, stale collision, and max-agent bound coverage.

All 4.19 work kept route following live loops, pathfinding, replanning,
avoidance, reservation runtime, physics, terrain/world mutation, save/load,
registries, and gameplay movement out of scope.

### Files Created/Modified

- Created
  `docs/pebblelab/PHASE_4_MULTI_AGENT_MOVEMENT_INTEGRATION_PLAN.md`.
- Updated `docs/pebblelab/CHANGELOG.md`.
- Updated `docs/pebblelab/DEV_JOURNAL.md`.
- Updated `docs/pebblelab/ROADMAP.md`.

No Swift files were modified.

### Why Docs-Only

The previous phases validated several local contracts, but not their
orchestration. Jumping directly to reservation tables, avoidance, dynamic
replanning, pathfinding, autonomous movement, or long-running navigation
would mix ownership boundaries too early. This phase defines the integration
shape first.

### Integration Problem

The plan identifies the next problem as tick ownership:

- where movement intentions are produced;
- when they are collected;
- which layer stabilizes ordering;
- which layer arbitrates;
- which layer reads collision evidence;
- which layer applies approved moves;
- how denied moves become feedback;
- how reports and metrics stay useful;
- how to avoid turning the runner into a monolithic movement function.

### Target Architecture

The plan proposes these future layers:

- agent decision layer;
- intent collection layer;
- arbitration layer;
- collision evidence layer;
- application layer;
- feedback layer;
- reporting layer.

Each layer has explicit responsibilities and non-responsibilities. Agents
produce intents but do not move directly. The collector stabilizes inputs but
does not decide conflicts. The arbiter resolves conflicts but does not
pathfind, replan, avoid, reserve, or mutate world. Collision evidence remains
read-only. Application applies only approved resolutions. Feedback is output
only. Reporting does not affect simulation.

### Boundary Rules

The document defines separation rules for agent intent production,
collection, arbitration, collision evidence, application, feedback, and
reporting. Key rules: no direct agent mutation, no pathfinding inside the
arbiter, no world mutation inside arbitration or collision evidence, no
re-arbitration inside application, no memory/goal mutation inside feedback,
and no gameplay decisions inside reporting.

### Future Tick Input/Output

The plan proposes future Swift shapes only in documentation:

- `LabMultiAgentMovementTickInput`;
- `LabMultiAgentMovementTickOutput`;
- `LabMultiAgentMovementTickSummary`;
- `LabMovementFeedbackKind`;
- `LabMovementFeedback`.

These shapes are meant to unify the existing lower-level proofs into a
single future tick contract.

### Feedback Policy

The plan maps movement decisions to structured feedback:

- approved displacement -> `moved`;
- collision denial -> `blockedByCollision`;
- same-destination, swap, cycle, chain, moving-away denial ->
  `blockedByAgentConflict`;
- source mismatch -> `blockedBySourceMismatch`;
- divergence -> `blockedByDivergence`;
- stale intent or stale collision -> `blockedByStaleIntent`;
- invalid or zero-length edge -> `blockedByInvalidEdge`;
- max-agent overflow -> `blockedByMaxAgents`.

Feedback does not yet update memory, change goals, trigger replanning,
communicate, call LLM/Python/RL, or invent movement.

### Future Outputs, Invariants, Metrics, And Event

Future tick-level phases should write:

- `multi_agent_movement_tick_report.json`;
- `multi_agent_movement_tick_invariant_report.json`;
- `multi_agent_movement_tick_feedback.json`;
- `metrics.json`;
- `events.ndjson`.

The plan proposes `multiAgentMovementTick*` metrics and one aggregate
`lab_multi_agent_movement_tick_recorded` event. It also lists 50 future
invariant checks, including deterministic intent ordering, collision
evidence ownership, stale evidence denial, no duplicate approved
destination, no approved swap, denied position preservation, one-edge
approved movement, abstract/physical final match, feedback coverage, no
pathfinding, no replanning, no avoidance, no reservation runtime, no physics,
no mutation, and lower-level smoke health checks.

### Future Phases Recommended

- Phase 4.20B - Multi-Agent Movement Tick Fixture Smoke.
- Phase 4.20C - Multi-Agent Movement Tick Live Read-Only Smoke.
- Phase 4.20D - Multi-Agent Movement Tick Approved Application Smoke.
- Phase 4.20E - Multi-Agent Movement Tick Hardening.
- Phase 4.21A - Agent Intent Production Planning Docs-Only.
- Phase 4.21B - Agent Intent Production Fixture Smoke.

### Validation

Commands:

- `git status`
- `swift build`
- `swift run -c release pebsmoke`
- `git diff --check`
- `git status`

Results:

- Documentation plan created.
- CHANGELOG, DEV_JOURNAL, and ROADMAP updated.
- No Swift files modified.
- `swift build`: passed.
- `swift run -c release pebsmoke`: 456 passed, 0 failed.
- `git diff --check`: passed.

### Next Step

Phase 4.20B: Multi-Agent Movement Tick Fixture Smoke. It should implement
only a fixture-level tick input/output contract, with no `World`, no live
collision, no physical movement, no reservation runtime, no avoidance, no
pathfinding, no replanning, no goal selection, no physics, and no mutation.

## 2026-06-27 — Phase 4.20B multi-agent movement tick fixture smoke

### Objective

Implement the first tick-level multi-agent movement contract smoke as a
fixture-only scenario. The goal is to validate the shape of a synthetic tick
input, deterministic collection/arbitration, tick output, structured
feedback, reports, metrics, and aggregate event without introducing live
collision, physical movement application, or a multi-tick loop.

### Starting State

Phase 4.20A documented the integration boundary after the 4.19 local proofs:
fixture arbitration, fixture hardening, live read-only collision intent,
approved physical movement, and live movement hardening. Those phases proved
lower-level contracts, but not a single integrated tick input/output shape.

### Files Created/Modified

- Modified `Sources/PebbleLab/LabMultiAgentMovement.swift`.
- Modified `Sources/PebbleLab/LabOptions.swift`.
- Modified `Sources/PebbleLab/LabScenarios.swift`.
- Modified `Sources/PebbleLab/LabOutput.swift`.
- Modified `Sources/PebbleLab/LabEvents.swift`.
- Modified `Sources/PebbleLab/main.swift`.
- Updated `docs/pebblelab/CHANGELOG.md`.
- Updated `docs/pebblelab/DEV_JOURNAL.md`.
- Updated `docs/pebblelab/ROADMAP.md`.
- Updated
  `docs/pebblelab/PHASE_4_MULTI_AGENT_MOVEMENT_INTEGRATION_PLAN.md`.

### Why Fixture-Only

The phase validates tick orchestration shape without a `World`. It does not
read live collision evidence, does not create physical placeholders, does
not apply single-step movement, and does not call route following. This keeps
the first integration contract focused on deterministic intent ordering,
arbitration, feedback, and reporting.

### Tick Input/Output

The scenario `multi_agent_movement_tick_fixture_smoke` builds one synthetic
tick, `tick = 0`, with four abstract agents and four matching synthetic
physical positions. The input intentions are deliberately unordered:
`agent_1`, `agent_0`, `agent_2`, `agent_3`.

The output resolutions are sorted by stable `agentId`: `agent_0`,
`agent_1`, `agent_2`, `agent_3`. `agent_0` and `agent_2` are approved.
`agent_1` is denied by same-destination conflict. `agent_3` is denied for a
vertical invalid edge. Because this is fixture-only, abstract and physical
positions after the tick remain equal to their initial positions.

### Feedback Policy

The tick fixture adds `approvedForMovement` feedback for approved decisions
when `displacementApplied == false`. This avoids claiming `moved` before a
movement application phase. Denied same-destination conflict maps to
`blockedByAgentConflict`; denied invalid edge maps to `blockedByInvalidEdge`.

### Outputs, Invariants, Metrics, And Event

The scenario writes:

- `multi_agent_movement_tick_fixture_report.json`;
- `multi_agent_movement_tick_fixture_invariant_report.json`;
- `multi_agent_movement_tick_fixture_feedback.json`;
- `metrics.json`;
- `events.ndjson`.

The invariant report covers 40 checks. Metrics use the
`multiAgentMovementTickFixture*` prefix. The scenario emits one aggregate
`lab_multi_agent_movement_tick_fixture_recorded` event.

### Confirmed Out Of Scope

No `World`, live collision, physical movement, route following, pathfinding,
replanning, goal selection, avoidance, reservation runtime, physics,
terrain mutation, world mutation, physical placeholder movement, core entity
movement, autonomous movement, or multi-tick loop is performed.

### Validation Commands

- `git status`
- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario multi_agent_movement_tick_fixture_smoke --seed 42 --ticks 0 --out runs/check_multi_agent_movement_tick_fixture`
- `swift run -c release PebbleLab -- --scenario multi_agent_movement_hardening_smoke --seed 42 --ticks 5 --out runs/check_multi_agent_movement_hardening_after_tick_fixture`
- `swift run -c release PebbleLab -- --scenario multi_agent_approved_physical_movement_smoke --seed 42 --ticks 5 --out runs/check_multi_agent_approved_physical_after_tick_fixture`
- `swift run -c release PebbleLab -- --scenario multi_agent_live_collision_intent_smoke --seed 42 --ticks 5 --out runs/check_multi_agent_live_collision_intent_after_tick_fixture`
- `swift run -c release PebbleLab -- --scenario multi_agent_movement_fixture_smoke --seed 42 --ticks 0 --out runs/check_multi_agent_fixture_after_tick_fixture`
- `swift run -c release PebbleLab -- --scenario multi_agent_movement_fixture_hardening_smoke --seed 42 --ticks 0 --out runs/check_multi_agent_fixture_hardening_after_tick_fixture`
- `swift run -c release PebbleLab -- --scenario physical_movement_single_step_hardening_smoke --seed 42 --ticks 5 --out runs/check_single_step_hardening_after_tick_fixture`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_tick_fixture`
- `swift run -c release pebsmoke`
- `git diff --check`

### Results

- Tick fixture report: success true.
- Tick fixture invariant report: success true.
- Invariant checks: 40 passed, 0 failed.
- Approved/denied totals: 2 / 2.
- Feedback records: 4.
- Displacements applied: 0.
- Same-destination conflicts: 1.
- Invalid edges: 1.
- Abstract positions unchanged.
- Physical positions unchanged.
- Metrics contain `multiAgentMovementTickFixture*`.
- `events.ndjson` contains
  `lab_multi_agent_movement_tick_fixture_recorded`.

### Next Step

Phase 4.20C: Multi-Agent Movement Tick Live Read-Only Smoke. It should add
live collision evidence to the tick input/output contract while still
avoiding physical movement application, route following, pathfinding,
replanning, avoidance, reservation runtime, physics, and mutation.

## 2026-06-27 — Phase 4.20C multi-agent movement tick live read-only smoke

### Objective

Add the first tick-level live read-only collision smoke for multi-agent
movement. The scenario keeps the 4.20B tick input/output contract, adds live
collision evidence for valid intentions, produces structured feedback, and
still applies no movement.

### Starting State

Phase 4.20B proved the fixture-only tick shape with unordered input intents,
stable `agentId` resolution ordering, structured feedback, unchanged
abstract/physical positions, and no `World` use. Phase 4.19D had already
proved live collision intent evidence outside the tick contract.

### Files Created/Modified

- Modified `Sources/PebbleLab/LabMultiAgentMovement.swift`.
- Modified `Sources/PebbleLab/LabOptions.swift`.
- Modified `Sources/PebbleLab/LabScenarios.swift`.
- Modified `Sources/PebbleLab/LabOutput.swift`.
- Modified `Sources/PebbleLab/main.swift`.
- Updated `docs/pebblelab/CHANGELOG.md`.
- Updated `docs/pebblelab/DEV_JOURNAL.md`.
- Updated `docs/pebblelab/ROADMAP.md`.
- Updated
  `docs/pebblelab/PHASE_4_MULTI_AGENT_MOVEMENT_INTEGRATION_PLAN.md`.

### Why Live Read-Only

The phase connects tick-level arbitration and feedback to live terrain
collision evidence without moving agents. It uses `World` only to prepare and
read collision snapshots for valid collision-required intentions. It does
not create physical placeholders, core entities, route followers, or
single-step physical movement applications.

### Tick Input/Output

The scenario `multi_agent_movement_tick_live_readonly_smoke` creates one
synthetic tick with five abstract agents and matching synthetic physical
positions. Input intentions are deliberately unordered: `agent_1`,
`agent_0`, `agent_2`, `agent_3`, `agent_4`.

The output resolutions are sorted by stable `agentId`:

- `agent_0`: approved from live occupable evidence;
- `agent_1`: approved from live occupable evidence;
- `agent_2`: denied by live collision evidence;
- `agent_3`: denied source mismatch before collision;
- `agent_4`: denied invalid vertical edge before collision.

Abstract and physical positions remain unchanged. `displacementsApplied` is
0.

### Collision Evidence Policy

The scenario uses controlled per-intent read-only evidence seeds, matching
the hardening style introduced in 4.19F. `agent_0` and `agent_1` read seed
99 occupable destinations. `agent_2` reads seed 42 for a non-occupable
destination and is denied with `deniedCollision`. Source mismatch, stale
intent if present, and invalid edge are rejected before collision is read.

This is evidence injection for a lab smoke, not gameplay movement,
pathfinding, replanning, reservation, or avoidance.

### Feedback Policy

Approved read-only intentions emit `approvedForMovement` because no
displacement is applied. Collision denial emits `blockedByCollision`.
Source mismatch emits `blockedBySourceMismatch`. Invalid edge emits
`blockedByInvalidEdge`. `moved` remains reserved for future tick application
phases.

### Outputs, Invariants, Metrics, And Event

The scenario writes:

- `multi_agent_movement_tick_live_readonly_report.json`;
- `multi_agent_movement_tick_live_readonly_invariant_report.json`;
- `multi_agent_movement_tick_live_readonly_feedback.json`;
- `metrics.json`;
- `events.ndjson`.

The invariant report covers 42 checks. Metrics use the
`multiAgentMovementTickLiveReadonly*` prefix. The scenario emits one
aggregate `lab_multi_agent_movement_tick_live_readonly_recorded` event.

### Confirmed Out Of Scope

No physical movement, route following, pathfinding, replanning, goal
selection, avoidance, reservation runtime, physics, terrain mutation, world
mutation, physical placeholder movement, core entity movement, autonomous
movement, or multi-tick simulation loop is performed.

### Validation Commands

- `git status`
- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario multi_agent_movement_tick_live_readonly_smoke --seed 42 --ticks 5 --out runs/check_multi_agent_movement_tick_live_readonly`
- `swift run -c release PebbleLab -- --scenario multi_agent_movement_tick_fixture_smoke --seed 42 --ticks 0 --out runs/check_tick_fixture_after_tick_live_readonly`
- `swift run -c release PebbleLab -- --scenario multi_agent_movement_hardening_smoke --seed 42 --ticks 5 --out runs/check_multi_agent_movement_hardening_after_tick_live_readonly`
- `swift run -c release PebbleLab -- --scenario multi_agent_live_collision_intent_smoke --seed 42 --ticks 5 --out runs/check_multi_agent_live_collision_intent_after_tick_live_readonly`
- `swift run -c release PebbleLab -- --scenario multi_agent_movement_fixture_smoke --seed 42 --ticks 0 --out runs/check_multi_agent_fixture_after_tick_live_readonly`
- `swift run -c release PebbleLab -- --scenario multi_agent_movement_fixture_hardening_smoke --seed 42 --ticks 0 --out runs/check_multi_agent_fixture_hardening_after_tick_live_readonly`
- `swift run -c release PebbleLab -- --scenario physical_movement_single_step_hardening_smoke --seed 42 --ticks 5 --out runs/check_single_step_hardening_after_tick_live_readonly`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_tick_live_readonly`
- `swift run -c release pebsmoke`
- `git diff --check`

### Results

- Tick live read-only report: success true.
- Tick live read-only invariant report: success true.
- Invariant checks: 42 passed, 0 failed.
- Approved/denied totals: 2 / 3.
- Occupable/non-occupable destination totals: 2 / 1.
- Collision denied/source mismatch/invalid edge totals: 1 / 1 / 1.
- Feedback records: 5.
- Displacements applied: 0.
- Abstract positions unchanged.
- Physical positions unchanged.
- Metrics contain `multiAgentMovementTickLiveReadonly*`.
- `events.ndjson` contains
  `lab_multi_agent_movement_tick_live_readonly_recorded`.

### Next Step

Phase 4.20D: Multi-Agent Movement Tick Approved Application Smoke. It should
apply approved tick resolutions in a small controlled case while keeping
denied/conflict hardening, reservation runtime, avoidance, dynamic
replanning, route repair, physics, save/load, social behavior, and gameplay
movement out of scope.

## 2026-06-27 — Phase 4.20D multi-agent movement tick approved application smoke

### Objective

Add the first tick-level approved application smoke for multi-agent movement.
The scenario keeps the 4.20B/4.20C tick input/output shape, reads live
collision evidence, approves two non-conflicting one-edge intents, applies
both movements, and emits `moved` feedback.

### Starting State

Phase 4.20B proved a fixture-only tick contract with unchanged positions and
`approvedForMovement` feedback. Phase 4.20C attached read-only live collision
evidence to the same tick shape. Phase 4.19E and 4.19F had already proved
approved physical application and live hardening outside the integrated tick
contract.

### Files Created/Modified

- Modified `Sources/PebbleLab/LabMultiAgentMovement.swift`.
- Modified `Sources/PebbleLab/LabOptions.swift`.
- Modified `Sources/PebbleLab/LabScenarios.swift`.
- Modified `Sources/PebbleLab/LabOutput.swift`.
- Modified `Sources/PebbleLab/main.swift`.
- Updated `docs/pebblelab/CHANGELOG.md`.
- Updated `docs/pebblelab/DEV_JOURNAL.md`.
- Updated `docs/pebblelab/ROADMAP.md`.
- Updated
  `docs/pebblelab/PHASE_4_MULTI_AGENT_MOVEMENT_INTEGRATION_PLAN.md`.

### Why Approved-Only

This phase is an application smoke, not a hardening phase. It intentionally
covers only two agents, two non-conflicting destinations, and two approved
single-edge movements. Denied collision, same-destination, swap, source
mismatch, stale intent, invalid edge, divergence, and max-agent cases remain
covered by lower-level hardening and are deferred for tick-level hardening.

### Tick Input/Output

The scenario `multi_agent_movement_tick_approved_application_smoke` creates
one synthetic tick with two abstract agents and matching physical positions:

- `agent_0`: `(7,64,8)`;
- `agent_1`: `(9,64,7)`.

Input intents are deliberately unordered: `agent_1` is listed before
`agent_0`. Output resolutions are sorted by stable `agentId`.

The output updates both abstract and physical positions:

- `agent_0`: `(7,64,8) -> (8,64,8)`;
- `agent_1`: `(9,64,7) -> (9,64,8)`.

### Collision/Application Policy

The scenario uses controlled live collision evidence with seed 99 for both
destinations. Both destinations are occupable. Each approved resolution
applies exactly one 4-neighbor same-y edge by updating the abstract agent and
syncing the PebbleLab physical placeholder bridge. No route follower,
pathfinder, replanner, avoidance, reservation runtime, physics integration,
terrain mutation, or world mutation is involved.

### Feedback Policy

Approved read-only phases use `approvedForMovement`. This phase applies the
movement, so approved resolutions use `moved`. The invariant report verifies
that no `approvedForMovement` feedback remains when `displacementApplied` is
true.

### Outputs, Invariants, Metrics, And Event

The scenario writes:

- `multi_agent_movement_tick_approved_application_report.json`;
- `multi_agent_movement_tick_approved_application_invariant_report.json`;
- `multi_agent_movement_tick_approved_application_feedback.json`;
- `metrics.json`;
- `events.ndjson`.

The invariant report covers 49 checks. Metrics use the
`multiAgentMovementTickApprovedApplication*` prefix. The scenario emits one
aggregate `lab_multi_agent_movement_tick_approved_application_recorded`
event.

### Confirmed Out Of Scope

No route following, pathfinding, replanning, goal selection, avoidance,
reservation runtime, physics, terrain mutation, world mutation, core entity
movement, autonomous movement, denied tick application, or multi-tick
simulation loop is performed.

### Validation Commands

- `git status`
- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario multi_agent_movement_tick_approved_application_smoke --seed 42 --ticks 5 --out runs/check_multi_agent_movement_tick_approved_application`
- `swift run -c release PebbleLab -- --scenario multi_agent_movement_tick_live_readonly_smoke --seed 42 --ticks 5 --out runs/check_tick_live_readonly_after_tick_approved_application`
- `swift run -c release PebbleLab -- --scenario multi_agent_movement_tick_fixture_smoke --seed 42 --ticks 0 --out runs/check_tick_fixture_after_tick_approved_application`
- `swift run -c release PebbleLab -- --scenario multi_agent_movement_hardening_smoke --seed 42 --ticks 5 --out runs/check_multi_agent_movement_hardening_after_tick_approved_application`
- `swift run -c release PebbleLab -- --scenario multi_agent_approved_physical_movement_smoke --seed 42 --ticks 5 --out runs/check_multi_agent_approved_physical_after_tick_approved_application`
- `swift run -c release PebbleLab -- --scenario multi_agent_live_collision_intent_smoke --seed 42 --ticks 5 --out runs/check_multi_agent_live_collision_intent_after_tick_approved_application`
- `swift run -c release PebbleLab -- --scenario physical_movement_single_step_hardening_smoke --seed 42 --ticks 5 --out runs/check_single_step_hardening_after_tick_approved_application`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_tick_approved_application`
- `swift run -c release pebsmoke`
- `git diff --check`

### Results

- Tick approved application report: success true.
- Tick approved application invariant report: success true.
- Invariant checks: 49 passed, 0 failed.
- Approved/denied totals: 2 / 0.
- Occupable/non-occupable destination totals: 2 / 0.
- Displacements applied: 2.
- Divergence before/after max: 0 / 0.
- Feedback records: 2, both `moved`.
- Abstract final positions match physical final positions.
- Metrics contain `multiAgentMovementTickApprovedApplication*`.
- `events.ndjson` contains
  `lab_multi_agent_movement_tick_approved_application_recorded`.

### Next Step

Phase 4.20E: Multi-Agent Movement Tick Hardening. It should reintroduce
denied collision, partial approval, conflicts, source mismatch, stale intent,
invalid edges, divergence, and max-agent bounds at the integrated tick level
without adding reservation runtime, avoidance, dynamic replanning, route
repair, physics, save/load, social behavior, or gameplay movement.

## 2026-06-27 — Phase 4.20E multi-agent movement tick hardening

### Objective

Implement `multi_agent_movement_tick_hardening_smoke`, the first integrated
tick-level hardening scenario for multi-agent movement. The goal is to prove
that the tick input/output contract can represent approved movements, denied
movements, partial approval, conflicts, divergence, stale evidence, and
max-agent bounds while keeping feedback, metrics, events, and invariants
coherent.

### Starting State

Phase 4.20B validated fixture-only tick input/output and
`approvedForMovement` feedback without movement application. Phase 4.20C
added live read-only collision evidence while preserving all positions. Phase
4.20D applied two approved tick movements and used `moved` feedback for real
displacements. Phase 4.19F already proved the lower-level live hardening
movement semantics for collision denial, partial approval, conflicts, stale
intent, invalid edge, divergence, stale collision, and max-agent denial.

### Files Created/Modified

- `Sources/PebbleLab/LabMultiAgentMovement.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`
- `docs/pebblelab/PHASE_4_MULTI_AGENT_MOVEMENT_INTEGRATION_PLAN.md`

### Why Tick Hardening

The earlier smokes proved individual contracts. This phase hardens the
integrated tick shape so future agent intent production can consume one
coherent output: sorted resolutions, position before/after data, feedback for
each resolution, aggregate summary fields, metrics, and one event. It does
not introduce autonomous movement or a repeated tick loop.

### Cases Covered

- approved tick application remains green;
- collision denied tick preserves position;
- partial approval tick;
- same-destination tick conflict;
- swap conflict denies both;
- source mismatch denied before collision;
- stale intent denied before collision;
- invalid edge denied before collision;
- divergence before tick denied;
- stale collision tick denied;
- all-denied tick mixed reasons;
- max-agents tick bound exceeded.

### Collision/Application Policy

The tick hardening smoke reuses the validated 4.19F hardening movement core
and wraps each result as a tick-level contract. Approved movements apply one
controlled edge. Denied movements preserve abstract and physical positions.
Collision evidence is used only for the cases that require it, stale
collision evidence is denied, and no pathfinding, replanning, avoidance, or
reservation runtime is introduced.

### Feedback Policy

Applied approved movements emit `moved`. Read-only approved feedback from
4.20B/4.20C remains `approvedForMovement`, but 4.20E expects zero
`approvedForMovement` records because approved resolutions are applied.
Denials map to explicit feedback: collision, agent conflict, source mismatch,
divergence, stale intent, invalid edge, and max-agent bound.

### Outputs, Invariants, Metrics, and Event

The scenario writes:

- `multi_agent_movement_tick_hardening_report.json`;
- `multi_agent_movement_tick_hardening_invariant_report.json`;
- `multi_agent_movement_tick_hardening_feedback.json`;
- `metrics.json`;
- `events.ndjson`.

The invariant report checks case coverage, sorted resolutions, feedback
coherence, approved movement application, denied position preservation,
partial approval, conflict denial, divergence bounds, stale evidence denial,
max-agent denial, lower-level smoke compatibility, and the no
route-following/pathfinding/replanning/avoidance/reservation/physics/mutation
contract. Metrics use the `multiAgentMovementTickHardening*` prefix, and the
event is `lab_multi_agent_movement_tick_hardening_recorded`.

### Out-of-Scope Confirmations

This phase does not add route following, pathfinding, replanning, goal
selection, avoidance, reservation runtime, physics, autonomous movement,
repeated tick loops, terrain/world mutation, save/load changes, social
behavior, communication, or gameplay movement.

### Validation Commands

- `git status`
- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario multi_agent_movement_tick_hardening_smoke --seed 42 --ticks 5 --out runs/check_multi_agent_movement_tick_hardening`
- `swift run -c release PebbleLab -- --scenario multi_agent_movement_tick_approved_application_smoke --seed 42 --ticks 5 --out runs/check_tick_approved_application_after_tick_hardening`
- `swift run -c release PebbleLab -- --scenario multi_agent_movement_tick_live_readonly_smoke --seed 42 --ticks 5 --out runs/check_tick_live_readonly_after_tick_hardening`
- `swift run -c release PebbleLab -- --scenario multi_agent_movement_tick_fixture_smoke --seed 42 --ticks 0 --out runs/check_tick_fixture_after_tick_hardening`
- `swift run -c release PebbleLab -- --scenario multi_agent_movement_hardening_smoke --seed 42 --ticks 5 --out runs/check_multi_agent_movement_hardening_after_tick_hardening`
- `swift run -c release PebbleLab -- --scenario multi_agent_approved_physical_movement_smoke --seed 42 --ticks 5 --out runs/check_multi_agent_approved_physical_after_tick_hardening`
- `swift run -c release PebbleLab -- --scenario multi_agent_live_collision_intent_smoke --seed 42 --ticks 5 --out runs/check_multi_agent_live_collision_intent_after_tick_hardening`
- `swift run -c release PebbleLab -- --scenario physical_movement_single_step_hardening_smoke --seed 42 --ticks 5 --out runs/check_single_step_hardening_after_tick_hardening`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_tick_hardening`
- `swift run -c release pebsmoke`
- `git diff --check`

### Results

- Tick hardening report: success true.
- Tick hardening invariant report: success true.
- Hardening cases: 12 passed, 0 failed.
- Approved/denied totals: 4 / 18.
- Displacements applied: 4.
- Collision denied: 3.
- Partial approval cases: 2.
- Same-destination conflicts: 1.
- Swap conflicts: 2.
- Source mismatch: 2.
- Stale intent: 1.
- Invalid edges: 2.
- Divergence denied: 1.
- Stale collision: 1.
- Max-agent denials: 5.
- Feedback records: 22.
- Divergence before/after max: 1 / 1, from the intentionally divergent
  denied case.
- Metrics contain `multiAgentMovementTickHardening*`.
- `events.ndjson` contains
  `lab_multi_agent_movement_tick_hardening_recorded`.

### Next Step

Phase 4.21A: Agent Intent Production Planning Docs-Only. It should document
how agents will produce movement intentions from goals before any autonomous
loop, reservation runtime, avoidance, dynamic replanning, route repair,
physics, save/load, social behavior, communication, or gameplay movement is
introduced.

## 2026-06-27 — Phase 4.21A agent intent production planning docs-only

### Objective

Document the future contract for agent-produced movement intentions without
implementing runtime behavior. The phase answers how PebbleLab can later move
from scenario-created synthetic intents to policy-created
`LabAgentMoveIntent` values while preserving the tick movement contracts
validated in 4.20.

### Starting State

Phase 4.19A through 4.19F validated multi-agent movement primitives and live
hardening. Phase 4.20A through 4.20E validated tick input/output, read-only
collision evidence, approved application, feedback, and tick hardening. The
current tick scenarios still use synthetic intents. No agent policy produces
movement intent yet, and no autonomous movement loop exists.

### Files Created/Modified

- `docs/pebblelab/PHASE_4_AGENT_INTENT_PRODUCTION_PLAN.md`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`

No Swift files were modified.

### Why Docs-Only

The next risk is architectural ownership, not movement mechanics. PebbleLab
needs a documented boundary before introducing agent policy code: policy may
propose intent, but it must not move agents, read collision, arbitrate,
pathfind, replan, avoid, reserve positions, mutate memory, mutate goals, or
mutate the world.

### Problem To Solve

The current shape is `fixture/scenario creates intents`. The future shape
should be `agent policy proposes movement intent`. The plan keeps the first
agent policy narrow: observe context, produce zero or one proposal, validate
format, collect accepted intents, and pass them to the already validated tick
movement contract.

### Target Architecture

The plan defines these future layers:

- agent state observation;
- intent policy layer;
- intent validation layer;
- tick collection layer;
- movement tick layer;
- feedback consumption future;
- reporting boundary.

### Policy v0

The proposed first policy is deterministic, one-edge, same-y, fixture-hint
driven, and bounded. It may output `noIntent`, `proposeMove`, or
`invalidContext`. It performs no pathfinding, no route planning, no
replanning, no avoidance, no reservation runtime, no collision read, no goal
selection, no memory update, and no movement application.

### Relationship With Feedback

Feedback remains structured input for later phases only. `moved`,
`blockedByCollision`, `blockedByAgentConflict`, `blockedBySourceMismatch`,
`blockedByDivergence`, `blockedByStaleIntent`, `blockedByInvalidEdge`, and
`blockedByMaxAgents` are documented as future signals, but 4.21A does not
consume feedback, update memory, learn, replan, invoke LLM/RL, or change
goals.

### Future Outputs, Invariants, Metrics, and Event

The plan proposes:

- `agent_intent_production_report.json`;
- `agent_intent_production_invariant_report.json`;
- `agent_intent_proposals.json`;
- `metrics.json`;
- `events.ndjson`;
- `agentIntentProduction*` metrics;
- one aggregate `lab_agent_intent_production_recorded` event;
- more than 35 invariant checks covering deterministic ordering, accepted
  intent shape, no pathfinding, no replanning, no avoidance, no reservation
  runtime, no collision read, no movement, no memory update, no goal change,
  no LLM/Python/RL, and no mutation.

### Future Phases Recommended

- Phase 4.21B - Agent Intent Production Fixture Smoke.
- Phase 4.21C - Agent Intent Production Hardening.
- Phase 4.21D - Agent Intent To Tick Fixture Integration Smoke.
- Phase 4.21E - Agent Intent To Tick Live Read-Only Smoke.
- Phase 4.21F - Agent Intent To Tick Approved Application Smoke.
- Phase 4.22A - Feedback Consumption Planning Docs-Only.

### Validation Commands

- `git status`
- `swift build`
- `swift run -c release pebsmoke`
- `git diff --check`
- `git status`

### Results

- Planning document created.
- CHANGELOG, DEV_JOURNAL, and ROADMAP updated.
- No Swift files modified.
- No `PebbleCore`, renderer, shader, resource, registry, save/load, or golden
  files modified.

### Next Step

Phase 4.21B: Agent Intent Production Fixture Smoke. It should add the first
fixture-only intent production scenario without `World`, movement, collision
reads, pathfinding, replanning, avoidance, reservation runtime, feedback
consumption, memory update, goal selection, or terrain/world mutation.

## 2026-06-27 — Phase 4.21B agent intent production fixture smoke

### Objective

Implement `agent_intent_production_fixture_smoke`, the first fixture-only
contract where scenarios create agent contexts, a deterministic v0 policy
produces proposals, validation accepts safe proposals, and accepted proposals
become `LabAgentMoveIntent` values.

### Starting State

Phase 4.21A documented the future intent production boundary. Phase 4.20B-E
validated tick input/output, feedback, read-only collision, approved
application, and tick hardening. Before this phase, all movement intentions
were still created directly by scenarios.

### Files Created/Modified

- `Sources/PebbleLab/LabAgentIntentProduction.swift`
- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`
- `docs/pebblelab/PHASE_4_AGENT_INTENT_PRODUCTION_PLAN.md`

### Why Fixture-Only

The phase validates production shape only. It does not feed produced intents
into the tick movement contract, does not call live collision, does not apply
movement, and does not introduce autonomous agent behavior.

### Policy v0

The fixture v0 policy is deterministic. `idle` produces `noIntent`.
`wander_fixture` scans hints in the stable order `move_east`, `move_west`,
`move_north`, `move_south` and proposes the first matching one-edge same-y
move. Missing position produces `invalidContext`. The
`bad_fixture_invalid_vertical` role intentionally proposes a vertical edge so
validation can reject it.

### Context, Proposal, and Result Types

The phase adds `LabAgentIntentContext`, `LabAgentIntentDecision`,
`LabAgentIntentProposal`, `LabAgentIntentProductionResult`, and
`LabAgentIntentProductionSummary`, plus fixture report and invariant report
types.

### Accepted/Rejected Proposal Policy

Validation accepts only `proposeMove` proposals with a non-nil intent, matching
agent id, source and destination, one-edge Manhattan distance, same-y, and at
most one accepted intent per agent. `noIntent`, `invalidContext`, invalid
vertical proposals, and duplicates are rejected. Same-destination accepted
intents are allowed because this phase does not arbitrate conflicts.

### Outputs, Invariants, Metrics, and Event

The scenario writes:

- `agent_intent_production_fixture_report.json`;
- `agent_intent_production_fixture_invariant_report.json`;
- `agent_intent_proposals.json`;
- `metrics.json`;
- `events.ndjson`.

Metrics use the `agentIntentProductionFixture*` prefix, and the aggregate
event is `lab_agent_intent_production_fixture_recorded`. The invariant report
checks unordered contexts, sorted proposals, sorted accepted intents, one
proposal per agent, one accepted intent per agent, valid accepted intent
shape, rejected invalid/no-intent contexts, same-destination deferral to tick
arbitration, and the no World/collision/movement/feedback/memory/goals/
pathfinding/replanning/avoidance/reservation/mutation contract.

### Out-of-Scope Confirmations

No `World` is created. No collision is read. No movement is applied. No
feedback is consumed. No memory or goals are modified. No pathfinding,
replanning, avoidance, reservation runtime, physics, terrain/world mutation,
tick movement invocation, route following, LLM/Python/RL, social behavior, or
gameplay movement is added.

### Validation Commands

- `git status`
- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario agent_intent_production_fixture_smoke --seed 42 --ticks 0 --out runs/check_agent_intent_production_fixture`
- `swift run -c release PebbleLab -- --scenario multi_agent_movement_tick_hardening_smoke --seed 42 --ticks 5 --out runs/check_tick_hardening_after_agent_intent_fixture`
- `swift run -c release PebbleLab -- --scenario multi_agent_movement_tick_fixture_smoke --seed 42 --ticks 0 --out runs/check_tick_fixture_after_agent_intent_fixture`
- `swift run -c release PebbleLab -- --scenario multi_agent_movement_tick_live_readonly_smoke --seed 42 --ticks 5 --out runs/check_tick_live_readonly_after_agent_intent_fixture`
- `swift run -c release PebbleLab -- --scenario multi_agent_movement_tick_approved_application_smoke --seed 42 --ticks 5 --out runs/check_tick_approved_application_after_agent_intent_fixture`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_agent_intent_fixture`
- `swift run -c release pebsmoke`
- `git diff --check`

### Results

- Report success true.
- Invariant report success true.
- Contexts: 5.
- Proposals: 5.
- Accepted intents: 2.
- Rejected proposals: 3.
- `noIntent`: 1.
- `invalidContext`: 1.
- `invalidOneEdgeProposals`: 1.
- Accepted intents are sorted by stable `agentId`.
- Proposals are sorted by stable `agentId`.
- Same-destination accepted intents are preserved for later tick arbitration.
- Metrics contain `agentIntentProductionFixture*`.
- `events.ndjson` contains `lab_agent_intent_production_fixture_recorded`.

### Next Step

Phase 4.21C: Agent Intent Production Hardening. It should add adversarial
fixture cases for duplicate contexts, duplicate proposals, malformed moves,
unknown roles, missing data, deterministic ordering, and max proposal bounds,
still without tick integration, live collision, movement application,
feedback consumption, memory updates, goal selection, pathfinding,
replanning, avoidance, reservation runtime, physics, or terrain/world
mutation.

## 2026-06-27 — Phase 4.21C agent intent production hardening

### Objective

Implement `agent_intent_production_hardening_smoke`, the fixture-only
hardening scenario for agent intent production. The goal is to validate
duplicate handling, malformed proposals, stale proposals, wrong-source
proposals, max proposal bounds, deterministic hint ordering, deterministic
output ordering, and accepted/rejected counts without integrating with tick
movement.

### Starting State

Phase 4.21B added `agent_intent_production_fixture_smoke` with five
synthetic contexts, five sorted proposals, two accepted intents, three
rejected proposals, and no World/collision/movement/feedback/memory/goals/
pathfinding/replanning/reservation/mutation. It intentionally allowed two
accepted intents to target the same destination because production does not
arbitrate conflicts.

### Files Created/Modified

- `Sources/PebbleLab/LabAgentIntentProduction.swift`
- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`
- `docs/pebblelab/PHASE_4_AGENT_INTENT_PRODUCTION_PLAN.md`

### Why Fixture-Only Hardening

The intent production layer still owns only context-to-proposal and
proposal-to-intent validation. It should become robust against bad policy
output before any produced intent is passed into the tick movement contract.

### Cases Covered

- baseline fixture remains green;
- duplicate agent context denied;
- duplicate proposal denied;
- invalid diagonal proposal rejected;
- zero-length proposal rejected;
- stale proposal rejected;
- wrong-source proposal rejected;
- max proposals bound exceeded;
- deterministic hint ordering;
- unknown role produces `noIntent`.

### Policy v0

The v0 policy remains deterministic. `wander_fixture` still chooses hints in
the stable order east, west, north, south. Fixture-only bad roles produce
invalid diagonal, zero-length, stale, and wrong-source proposals to harden
validation; these roles are not gameplay policy.

### Accepted/Rejected Proposal Policy

Accepted intents must have a stable agent id, source, destination, one-edge
same-y move, matching source position, non-stale intent, and at most one
accepted intent per agent. Rejected proposals include `noIntent`,
`invalidContext`, duplicate proposals, invalid edge proposals, stale
proposals, wrong-source proposals, and proposals beyond max bounds.

### Duplicate, Max, Stale, and Wrong-Source Policy

Duplicate contexts are counted and deterministic output still allows at most
one accepted intent for that agent. Duplicate proposals are rejected. Stale
proposals are rejected before acceptance. Wrong-source proposals are rejected
when the proposal source differs from the stable context position. Max bounds
reject deterministic excess proposals after sorting.

### Outputs, Invariants, Metrics, and Event

The scenario writes:

- `agent_intent_production_hardening_report.json`;
- `agent_intent_production_hardening_invariant_report.json`;
- `agent_intent_proposals.json`;
- `metrics.json`;
- `events.ndjson`.

Metrics use the `agentIntentProductionHardening*` prefix, and the aggregate
event is `lab_agent_intent_production_hardening_recorded`. The invariant
report includes 54 checks covering case existence, sorted outputs,
accepted-intent shape, duplicate/stale/wrong-source/max rejections,
same-destination deferral, and no World/collision/movement/feedback/memory/
goals/pathfinding/replanning/avoidance/reservation/physics/mutation.

### Out-of-Scope Confirmations

No `World` is created. No collision is read. No movement is applied. No tick
movement contract is called. No feedback is consumed. No memory or goals are
modified. No pathfinding, replanning, avoidance, reservation runtime,
physics, route following, LLM/Python/RL, social behavior, communication,
gameplay movement, or terrain/world mutation is added.

### Validation Commands

- `git status`
- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario agent_intent_production_hardening_smoke --seed 42 --ticks 0 --out runs/check_agent_intent_production_hardening`
- `swift run -c release PebbleLab -- --scenario agent_intent_production_fixture_smoke --seed 42 --ticks 0 --out runs/check_agent_intent_fixture_after_hardening`
- `swift run -c release PebbleLab -- --scenario multi_agent_movement_tick_hardening_smoke --seed 42 --ticks 5 --out runs/check_tick_hardening_after_agent_intent_hardening`
- `swift run -c release PebbleLab -- --scenario multi_agent_movement_tick_fixture_smoke --seed 42 --ticks 0 --out runs/check_tick_fixture_after_agent_intent_hardening`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_agent_intent_hardening`
- `swift run -c release pebsmoke`
- `git diff --check`

### Results

- Hardening report success true.
- Hardening invariant report success true.
- Cases: 10 passed, 0 failed.
- Contexts total: 19.
- Proposals total: 20.
- Accepted intents total: 9.
- Rejected proposals total: 11.
- `noIntentTotal`: 2.
- `invalidContextTotal`: 1.
- `duplicateAgentContextsTotal`: 1.
- `duplicateProposalsTotal`: 2.
- `invalidOneEdgeProposalsTotal`: 3.
- `staleProposalsTotal`: 1.
- `wrongSourceProposalsTotal`: 1.
- `maxProposalsExceededTotal`: 1.
- Accepted move directions include east and west.
- Metrics contain `agentIntentProductionHardening*`.
- `events.ndjson` contains `lab_agent_intent_production_hardening_recorded`.

### Next Step

Phase 4.21D: Agent Intent To Tick Fixture Integration Smoke. It should feed
accepted produced intents into the fixture-only tick movement contract,
without live collision, physical movement application, feedback consumption,
memory updates, goal selection, pathfinding, replanning, avoidance,
reservation runtime, physics, or terrain/world mutation.

## 2026-06-27 — Phase 4.21D agent intent to tick fixture integration smoke

### Objective

Connect fixture-only agent intent production to the fixture-only movement
tick contract. This validates that policy-produced `LabAgentMoveIntent`
values can feed tick arbitration without adding live collision, physical
movement, feedback consumption, memory updates, goals, pathfinding,
replanning, reservation runtime, physics, or terrain/world mutation.

### Starting State

Phase 4.21B proved deterministic context-to-proposal production with two
accepted same-destination intents left unresolved. Phase 4.21C hardened the
production layer. Phase 4.20B already proved fixture-only tick arbitration
with stable `agentId` ordering, same-destination conflict denial, feedback,
unchanged positions, and no movement.

### Files Created or Modified

- `Sources/PebbleLab/LabAgentIntentProduction.swift`
- `Sources/PebbleLab/LabMultiAgentMovement.swift`
- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`
- `docs/pebblelab/PHASE_4_AGENT_INTENT_PRODUCTION_PLAN.md`

### Why Fixture-Only Integration

The goal is to validate ownership boundaries before live behavior grows:
the production layer proposes and validates intents, while the tick fixture
layer arbitrates conflicts and produces feedback. The scenario still avoids
World creation, live collision, physical movement, autonomous loops, and
feedback consumption.

### Production-to-Tick Flow

The scenario creates four intentionally unordered contexts. The v0 policy
produces sorted proposals, accepts two `wander_fixture` intents, rejects one
`idle` `noIntent`, and rejects one invalid vertical proposal. The accepted
intents are passed into a `LabMultiAgentMovementTickInput` with synthetic
abstract and physical positions. The tick fixture contract then resolves the
same-destination conflict.

### Same-Destination Handoff Policy

Production continues to allow both accepted intents to target `(1,64,0)`.
It does not arbitrate conflicts. The tick fixture layer approves `agent_0`
by stable `agentId` ordering and denies `agent_1` with
`deniedSameDestinationConflict`.

### Tick Arbitration Result

The integrated smoke expects two accepted production intents, one tick
approval, one tick denial, two feedback records, no displacement, and
unchanged abstract/physical positions. Approved feedback is
`approvedForMovement`; denied conflict feedback is `blockedByAgentConflict`.

### Outputs, Invariants, Metrics, and Event

The scenario writes:

- `agent_intent_to_tick_fixture_report.json`;
- `agent_intent_to_tick_fixture_invariant_report.json`;
- `agent_intent_to_tick_fixture_proposals.json`;
- `metrics.json`;
- `events.ndjson`.

Metrics use the `agentIntentToTickFixture*` prefix. The aggregate event is
`lab_agent_intent_to_tick_fixture_recorded`. The invariant report covers
contexts, proposals, accepted/rejected proposals, tick input construction,
same-destination handoff, stable ordering, feedback mapping, unchanged
positions, no displacement, and all fixture-only out-of-scope guarantees.

### Out-of-Scope Confirmations

No `World` is created. No collision is read. No movement is applied. No
physical placeholder or core entity is created or moved. No feedback is
consumed. No memory or goals are modified. No pathfinding, replanning,
avoidance, reservation runtime, physics, route following, LLM/Python/RL,
social behavior, communication, gameplay movement, or terrain/world mutation
is added.

### Validation Commands

- `git status`
- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario agent_intent_to_tick_fixture_smoke --seed 42 --ticks 0 --out runs/check_agent_intent_to_tick_fixture`
- `swift run -c release PebbleLab -- --scenario agent_intent_production_hardening_smoke --seed 42 --ticks 0 --out runs/check_agent_intent_hardening_after_intent_to_tick_fixture`
- `swift run -c release PebbleLab -- --scenario agent_intent_production_fixture_smoke --seed 42 --ticks 0 --out runs/check_agent_intent_fixture_after_intent_to_tick_fixture`
- `swift run -c release PebbleLab -- --scenario multi_agent_movement_tick_fixture_smoke --seed 42 --ticks 0 --out runs/check_tick_fixture_after_intent_to_tick_fixture`
- `swift run -c release PebbleLab -- --scenario multi_agent_movement_tick_hardening_smoke --seed 42 --ticks 5 --out runs/check_tick_hardening_after_intent_to_tick_fixture`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_intent_to_tick_fixture`
- `swift run -c release pebsmoke`
- `git diff --check`

### Results

- Integration report success true.
- Integration invariant report success true.
- Production contexts: 4.
- Production proposals: 4.
- Accepted intents: 2.
- Rejected proposals: 2.
- Tick agents: 4.
- Tick intents: 2.
- Tick resolutions: 2.
- Tick feedback: 2.
- Tick approved: 1.
- Tick denied: 1.
- Same-destination conflict resolved by tick fixture arbitration.
- Displacements applied: 0.
- Metrics contain `agentIntentToTickFixture*`.
- `events.ndjson` contains `lab_agent_intent_to_tick_fixture_recorded`.

### Next Step

Phase 4.21E: Agent Intent To Tick Live Read-Only Smoke. It should feed
produced intents into the live read-only tick contract, using `World` only
for collision evidence and still avoiding movement application, feedback
consumption, memory updates, goals, pathfinding, replanning, avoidance,
reservation runtime, physics, and terrain/world mutation.

## 2026-06-27 — Phase 4.21E agent intent to tick live read-only smoke

### Objective

Connect agent-produced fixture intents to the tick live read-only collision
contract. This proves that policy output can feed a live collision evidence
tick without applying movement or consuming feedback.

### Starting State

Phase 4.21D proved the fixture handoff: production accepted same-destination
intents and tick fixture arbitration resolved them. Phase 4.20C proved
tick-level live read-only collision evidence over synthetic intents. Phase
4.21E combines those boundaries while keeping movement application out of
scope.

### Files Created or Modified

- `Sources/PebbleLab/LabAgentIntentProduction.swift`
- `Sources/PebbleLab/LabMultiAgentMovement.swift`
- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`
- `docs/pebblelab/PHASE_4_AGENT_INTENT_PRODUCTION_PLAN.md`

### Why Live Read-Only Integration

The next ownership boundary is collision evidence: production should still
only propose valid one-edge intents, while the tick live read-only layer owns
occupability evidence and final approval or collision denial. This keeps
agent policy from learning about live collision too early.

### Production-to-Tick Flow

Five intentionally unordered contexts produce five sorted proposals. Three
valid `wander_fixture` proposals become accepted intents, while one idle
context produces `noIntent` and one invalid vertical proposal is rejected.
Accepted intents are placed into a `LabMultiAgentMovementTickInput` with
synthetic physical positions mirroring abstract positions.

### Collision Evidence Policy

The tick layer reads controlled live collision evidence only for accepted,
valid tick intents. `agent_0` and `agent_1` use seed 99 and observe
occupable destinations. `agent_2` uses seed 42 and observes a non-occupable
destination, producing `deniedCollision`.

### Production vs Tick Responsibility Boundary

Production does not read collision, does not decide occupancy, and does not
apply movement. Tick live read-only reads collision evidence, approves
occupable destinations, denies non-occupable destinations, and emits
feedback while preserving positions.

### Tick Approval and Denial Result

The tick output has three resolutions: two approved intents with
`approvedForMovement` feedback and one collision-denied intent with
`blockedByCollision` feedback. Abstract and physical positions remain
unchanged, and `displacementsApplied` remains zero.

### Outputs, Invariants, Metrics, and Event

The scenario writes:

- `agent_intent_to_tick_live_readonly_report.json`;
- `agent_intent_to_tick_live_readonly_invariant_report.json`;
- `agent_intent_to_tick_live_readonly_proposals.json`;
- `metrics.json`;
- `events.ndjson`.

Metrics use the `agentIntentToTickLiveReadonly*` prefix. The aggregate event
is `lab_agent_intent_to_tick_live_readonly_recorded`.

### Out-of-Scope Confirmations

No movement is applied. No feedback is consumed. No memory or goals are
modified. No physical placeholder or core entity is created or moved. No
route following, pathfinding, replanning, avoidance, reservation runtime,
physics, LLM/Python/RL, social behavior, communication, gameplay movement,
or terrain/world mutation is added.

### Validation Commands

- `git status`
- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario agent_intent_to_tick_live_readonly_smoke --seed 42 --ticks 5 --out runs/check_agent_intent_to_tick_live_readonly`
- `swift run -c release PebbleLab -- --scenario agent_intent_to_tick_fixture_smoke --seed 42 --ticks 0 --out runs/check_agent_intent_to_tick_fixture_after_live_readonly`
- `swift run -c release PebbleLab -- --scenario agent_intent_production_hardening_smoke --seed 42 --ticks 0 --out runs/check_agent_intent_hardening_after_live_readonly`
- `swift run -c release PebbleLab -- --scenario agent_intent_production_fixture_smoke --seed 42 --ticks 0 --out runs/check_agent_intent_fixture_after_live_readonly`
- `swift run -c release PebbleLab -- --scenario multi_agent_movement_tick_live_readonly_smoke --seed 42 --ticks 5 --out runs/check_tick_live_readonly_after_agent_intent_live_readonly`
- `swift run -c release PebbleLab -- --scenario multi_agent_movement_tick_fixture_smoke --seed 42 --ticks 0 --out runs/check_tick_fixture_after_agent_intent_live_readonly`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_agent_intent_live_readonly`
- `swift run -c release pebsmoke`
- `git diff --check`

### Results

- Live read-only integration report success true.
- Invariant report success true.
- Production contexts: 5.
- Proposals: 5.
- Accepted intents: 3.
- Rejected proposals: 2.
- Tick agents: 5.
- Tick intents: 3.
- Tick approved: 2.
- Tick denied: 1.
- Occupable destinations: 2.
- Non-occupable destinations: 1.
- Collision denied: 1.
- Tick feedback: 3.
- Displacements applied: 0.
- Metrics contain `agentIntentToTickLiveReadonly*`.
- `events.ndjson` contains `lab_agent_intent_to_tick_live_readonly_recorded`.

### Next Step

Phase 4.21F: Agent Intent To Tick Approved Application Smoke. It should feed
produced intents into the tick approved application contract and apply only
controlled approved movements while keeping denied hardening, feedback
consumption, memory updates, goals, pathfinding, replanning, avoidance,
reservation runtime, physics, and terrain/world mutation out of scope.

## 2026-06-28 — Phase 4.21F agent intent to tick approved application smoke

### Objective

Connect agent-produced intents to a tick that reads live collision evidence,
approves occupable moves, applies only approved one-edge movements, preserves
denied positions, and emits applied-movement feedback.

### Starting State

Phase 4.21E proved the production-to-live-readonly tick boundary: production
created candidate intents without reading collision, and the tick layer
approved or denied them without moving positions. Phase 4.20D separately
proved tick approved application for synthetic intents. Phase 4.21F combines
those contracts while keeping feedback consumption, memory, goals,
pathfinding, replanning, avoidance, reservation runtime, route following,
physics, and mutation out of scope.

### Files Created or Modified

- `Sources/PebbleLab/LabAgentIntentProduction.swift`
- `Sources/PebbleLab/LabMultiAgentMovement.swift`
- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`
- `docs/pebblelab/PHASE_4_AGENT_INTENT_PRODUCTION_PLAN.md`

### Why Approved Application Integration

The next boundary is controlled movement application. Production still only
proposes one-edge same-y intents; the tick layer owns collision evidence,
approval, denial, and application. This validates the full handoff without
starting autonomous loops or gameplay movement.

### Production-to-Tick Flow

Five intentionally unordered contexts produce five sorted proposals. Three
valid `wander_fixture` proposals become accepted intents, while one idle
context produces `noIntent` and one invalid vertical proposal is rejected.
The accepted intents are copied into a `LabMultiAgentMovementTickInput` with
synthetic physical positions matching abstract positions before application.

### Collision and Application Policy

The tick layer reads controlled live collision evidence for accepted intents.
`agent_0` and `agent_1` use seed 99 and observe occupable destinations.
`agent_2` uses seed 42 and observes a non-occupable destination. Only the two
approved moves are applied. The denied collision intent is not moved.

### Position and Feedback Result

`agent_0` moves from `(7,64,8)` to `(8,64,8)`. `agent_1` moves from
`(9,64,7)` to `(9,64,8)`. `agent_2` remains at `(7,64,8)`. Abstract and
physical positions are synchronized before and after with divergence zero.
Approved moves emit `moved`; the denied collision emits
`blockedByCollision`.

### Responsibility Boundary

Production does not read collision, does not arbitrate occupancy, and does
not apply movement. Tick approved application reads collision, applies only
approved moves, preserves denied positions, and emits feedback as structured
output only.

### Outputs, Invariants, Metrics, and Event

The scenario writes:

- `agent_intent_to_tick_approved_application_report.json`;
- `agent_intent_to_tick_approved_application_invariant_report.json`;
- `agent_intent_to_tick_approved_application_proposals.json`;
- `metrics.json`;
- `events.ndjson`.

Metrics use the `agentIntentToTickApprovedApplication*` prefix. The aggregate
event is `lab_agent_intent_to_tick_approved_application_recorded`.

### Out-of-Scope Confirmations

No feedback is consumed. No memory or goals are modified. No route following,
pathfinding, replanning, avoidance, reservation runtime, physics,
LLM/Python/RL, social behavior, communication, gameplay movement, or
terrain/world mutation is added.

### Validation Commands

- `git status`
- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario agent_intent_to_tick_approved_application_smoke --seed 42 --ticks 5 --out runs/check_agent_intent_to_tick_approved_application`
- `swift run -c release PebbleLab -- --scenario agent_intent_to_tick_live_readonly_smoke --seed 42 --ticks 5 --out runs/check_agent_intent_live_readonly_after_approved_application`
- `swift run -c release PebbleLab -- --scenario agent_intent_to_tick_fixture_smoke --seed 42 --ticks 0 --out runs/check_agent_intent_to_tick_fixture_after_approved_application`
- `swift run -c release PebbleLab -- --scenario agent_intent_production_hardening_smoke --seed 42 --ticks 0 --out runs/check_agent_intent_hardening_after_approved_application`
- `swift run -c release PebbleLab -- --scenario agent_intent_production_fixture_smoke --seed 42 --ticks 0 --out runs/check_agent_intent_fixture_after_approved_application`
- `swift run -c release PebbleLab -- --scenario multi_agent_movement_tick_approved_application_smoke --seed 42 --ticks 5 --out runs/check_tick_approved_application_after_agent_intent_approved_application`
- `swift run -c release PebbleLab -- --scenario multi_agent_movement_tick_live_readonly_smoke --seed 42 --ticks 5 --out runs/check_tick_live_readonly_after_agent_intent_approved_application`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_agent_intent_approved_application`
- `swift run -c release pebsmoke`
- `git diff --check`

### Results

- Approved application integration report success true.
- Invariant report success true.
- Production contexts: 5.
- Proposals: 5.
- Accepted intents: 3.
- Rejected proposals: 2.
- Tick agents: 5.
- Tick intents: 3.
- Tick approved: 2.
- Tick denied: 1.
- Occupable destinations: 2.
- Non-occupable destinations: 1.
- Collision denied: 1.
- Displacements applied: 2.
- Moved feedback: 2.
- Blocked-by-collision feedback: 1.
- Divergence before/after: 0/0.
- Metrics contain `agentIntentToTickApprovedApplication*`.
- `events.ndjson` contains `lab_agent_intent_to_tick_approved_application_recorded`.

### Next Step

Phase 4.22A: Feedback Consumption Planning Docs-Only. It should plan how
structured movement feedback may later be consumed by agent policy or memory,
without implementing memory updates, goal changes, replanning, pathfinding,
avoidance, reservation runtime, route following, physics, or gameplay
movement.

## 2026-06-28 — Phase 4.22A feedback consumption planning docs-only

### Objective

Document the future feedback consumption contract before implementing any
runtime behavior. The phase explains how `LabMovementFeedback` can later
become bounded policy context for agents while keeping memory, goals,
learning, replanning, pathfinding, movement, and mutation out of scope.

### Starting State

Phases 4.19A-F validated multi-agent movement primitives. Phases 4.20A-E
validated tick-level movement, feedback, approved application, and hardening.
Phases 4.21A-F validated agent intent production through approved tick
application. The current system produces `approvedForMovement`, `moved`, and
`blockedBy*` feedback, but agents do not consume it.

### Files Created or Modified

- `docs/pebblelab/PHASE_4_FEEDBACK_CONSUMPTION_PLAN.md`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`

### Why Docs-Only

Feedback consumption is the next responsibility boundary. Implementing it too
early could accidentally introduce memory mutation, goal changes, retries,
replanning, pathfinding, avoidance, reservation runtime, or hidden behavior
adaptation. The docs-only phase locks the contract first.

### Problem To Solve

The future transition is from tick-produced `LabMovementFeedback` to
agent-observed bounded feedback context. Feedback must stay deterministic,
traceable, and explicit; it must not become free-form memory or implicit
learning.

### Target Architecture

The plan defines a layered architecture:

- feedback observation layer;
- feedback normalization layer;
- agent feedback context layer;
- policy input augmentation layer;
- future decision policy layer;
- reporting boundary;
- future memory/learning boundary.

Each layer has explicit responsibilities and prohibitions.

### Feedback Semantics

The plan documents semantics for `approvedForMovement`, `moved`,
`blockedByCollision`, `blockedByAgentConflict`, `blockedBySourceMismatch`,
`blockedByDivergence`, `blockedByStaleIntent`, `blockedByInvalidEdge`, and
`blockedByMaxAgents`. Each kind is observation-only in the first consumption
phases.

### Future Types

The proposed future types are:

- `LabAgentFeedbackObservation`;
- `LabAgentFeedbackContext`;
- `LabAgentFeedbackConsumptionDecision`;
- `LabAgentFeedbackConsumptionResult`;
- `LabAgentFeedbackConsumptionSummary`.

They are documented only and not implemented.

### v0 Policy

The v0 policy is deterministic and observe-only. It accepts known feedback,
rejects unknown or malformed feedback, consumes at most one feedback item per
agent, and emits structured context. It does not mutate memory or goals,
retry, replan, pathfind, avoid, reserve, apply movement, read collision, call
LLM/RL/Python, or emit new movement intents.

### Relationship With Agent Intent Production

Later phases may pass feedback context into `LabAgentIntentContext.lastFeedback`.
The first integration remains plumbing only: no alternate move selection, no
retry loop, and no dynamic policy mutation.

### Future Phases

The plan recommends:

- Phase 4.22B — Feedback Consumption Fixture Smoke;
- Phase 4.22C — Feedback Consumption Hardening;
- Phase 4.22D — Feedback To Agent Intent Context Fixture Smoke;
- Phase 4.22E — Feedback To Agent Intent Context Hardening;
- Phase 4.22F — Feedback-Aware Intent Policy Planning Docs-Only;
- Phase 4.23A — Bounded Feedback-Aware Intent Policy Fixture Smoke.

### Outputs, Metrics, Event, and Invariants

Future outputs include `agent_feedback_consumption_report.json`,
`agent_feedback_consumption_invariant_report.json`,
`agent_feedback_contexts.json`, `metrics.json`, and `events.ndjson`.
Metrics use the `agentFeedbackConsumption*` prefix, and the proposed event is
`lab_agent_feedback_consumption_recorded`. The plan lists 50 future invariant
checks.

### Explicit Out of Scope

Memory updates, goal changes, learning, reward updates, LLM reasoning,
Python/RL integration, social communication, negotiation, pathfinding,
replanning, avoidance, reservation runtime, movement application, collision
reads, terrain/world mutation, inventory, mining, construction, and
autonomous loops remain out of scope.

### Risk Table

The plan covers risks including feedback accidentally becoming memory,
feedback changing policy too early, retry/replanning leaks, collision feedback
turning into pathfinding, social behavior appearing too early, divergence
feedback becoming repair, invalid edges hiding policy bugs, max-agent feedback
becoming scheduling, nondeterministic ordering, and report/metric drift.

### Validation Commands

- `git status`
- `swift build`
- `swift run -c release pebsmoke`
- `git diff --check`
- `git status`

### Results

- Feedback consumption plan created.
- CHANGELOG, DEV_JOURNAL, and ROADMAP updated.
- No Swift files modified.
- No PebbleCore, renderer, shader, resource, registry, save/load, or golden
  files modified.
- `swift build` passed.
- `swift run -c release pebsmoke` passed with `456 passed, 0 failed`.
- `git diff --check` passed.

### Next Step

Phase 4.22B — Feedback Consumption Fixture Smoke. It should consume
synthetic feedback and produce bounded feedback context without movement,
intent production integration, memory updates, goal changes, collision reads,
pathfinding, replanning, avoidance, reservation runtime, or mutation.

## 2026-06-28 — Phase 4.22B feedback consumption fixture smoke

### Objective

Implement the first fixture-only feedback consumption smoke:
`agent_feedback_consumption_fixture_smoke`.

### Starting Point

Phase 4.22A documented how future agents should observe structured
`LabMovementFeedback` as bounded policy context. Before this phase, feedback
was produced by movement ticks but no runtime smoke consumed synthetic
feedback into agent feedback context.

### Files Created or Modified

- Created `Sources/PebbleLab/LabAgentFeedbackConsumption.swift`.
- Updated `Sources/PebbleLab/LabOptions.swift`.
- Updated `Sources/PebbleLab/LabScenarios.swift`.
- Updated `Sources/PebbleLab/LabOutput.swift`.
- Updated `Sources/PebbleLab/LabEvents.swift`.
- Updated `Sources/PebbleLab/main.swift`.
- Updated `docs/pebblelab/CHANGELOG.md`.
- Updated `docs/pebblelab/DEV_JOURNAL.md`.
- Updated `docs/pebblelab/ROADMAP.md`.
- Updated `docs/pebblelab/PHASE_4_FEEDBACK_CONSUMPTION_PLAN.md`.

### Why Fixture-Only

This phase validates only the feedback consumption contract. It does not call
agent intent production, tick movement, live collision, physical movement, or
any autonomous loop. Fixture-only inputs keep ordering, duplicate, malformed,
and context semantics deterministic.

### Feedback Fixture Inputs

The scenario consumes six intentionally unordered feedback inputs:

- `agent_2`: `blockedByCollision`, accepted as blocked context.
- `agent_0`: `moved`, accepted as succeeded context.
- `agent_1`: `approvedForMovement`, accepted without marking movement as
  applied.
- `agent_3`: `blockedByAgentConflict`, accepted as blocked context.
- duplicate `agent_0`: `blockedByMaxAgents`, ignored and counted as duplicate.
- malformed feedback with empty agent id and missing required fields, rejected
  as invalid.

### Consumption v0

The v0 consumer sorts inputs by stable `agentId`, accepts known well-formed
feedback, produces at most one context per agent, ignores duplicate feedback,
and rejects malformed feedback.

It produces `LabAgentFeedbackObservation`,
`LabAgentFeedbackContext`, `LabAgentFeedbackConsumptionResult`, and summary
records. It never mutates memory or goals, never produces an intent, never
reads collision, and never applies movement.

### Accepted, Ignored, and Invalid Policy

- Accepted: known feedback kind, non-empty agent id, required fields present,
  and first accepted feedback for that agent.
- Ignored: duplicate feedback for an already accepted agent.
- Invalid: malformed feedback such as missing agent id or missing required
  fields.

### Outputs, Invariants, Metrics, and Event

The scenario writes:

- `agent_feedback_consumption_fixture_report.json`;
- `agent_feedback_consumption_fixture_invariant_report.json`;
- `agent_feedback_contexts.json`;
- `metrics.json`;
- `events.ndjson`.

The invariant report contains 50 checks covering deterministic ordering,
known feedback acceptance, malformed rejection, duplicate handling, context
semantics, last known position semantics, and all no-movement/no-mutation
boundaries. Metrics use the `agentFeedbackConsumptionFixture*` prefix, and the
event is `lab_agent_feedback_consumption_fixture_recorded`.

### Boundaries Confirmed

No movement is applied. The consumption layer does not read collision, produce
intents, call `produceAgentIntentProposalV0`, call agent intent production
scenarios, invoke tick movement scenarios, update memory, change goals,
pathfind, replan, avoid, reserve, learn, use LLM/RL/Python, create social
behavior, communicate, create a `World`, or mutate terrain/world.

### Validation Commands

- `git status`
- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario agent_feedback_consumption_fixture_smoke --seed 42 --ticks 0 --out runs/check_agent_feedback_consumption_fixture`
- `swift run -c release PebbleLab -- --scenario agent_intent_to_tick_approved_application_smoke --seed 42 --ticks 5 --out runs/check_agent_intent_approved_application_after_feedback_fixture`
- `swift run -c release PebbleLab -- --scenario agent_intent_to_tick_live_readonly_smoke --seed 42 --ticks 5 --out runs/check_agent_intent_live_readonly_after_feedback_fixture`
- `swift run -c release PebbleLab -- --scenario agent_intent_to_tick_fixture_smoke --seed 42 --ticks 0 --out runs/check_agent_intent_to_tick_fixture_after_feedback_fixture`
- `swift run -c release PebbleLab -- --scenario agent_intent_production_hardening_smoke --seed 42 --ticks 0 --out runs/check_agent_intent_hardening_after_feedback_fixture`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_feedback_fixture`
- `swift run -c release pebsmoke`
- `git diff --check`

### Results

- `feedbackObserved = 6`.
- `feedbackAccepted = 4`.
- `feedbackIgnored = 1`.
- `invalidFeedback = 1`.
- `contextsProduced = 4`.
- `moved = 1`.
- `approvedForMovement = 1`.
- `blockedByCollision = 1`.
- `blockedByAgentConflict = 1`.
- `duplicateFeedback = 1`.
- Reports, contexts JSON, metrics, and event are produced.

### Next Step

Phase 4.22C — Feedback Consumption Hardening.

## 2026-06-28 — Phase 4.22C feedback consumption hardening

### Objective

Implement `agent_feedback_consumption_hardening_smoke`, a fixture-only
hardening scenario for feedback consumption v0.

### Starting Point

Phase 4.22B added `agent_feedback_consumption_fixture_smoke`, which consumed
six synthetic feedback inputs, accepted four known feedbacks, ignored one
duplicate, rejected one malformed input, produced four bounded feedback
contexts, and confirmed no movement, collision read, intent production,
memory update, goal change, pathfinding, replanning, reservation runtime,
World use, or terrain/world mutation.

### Files Created or Modified

- Updated `Sources/PebbleLab/LabAgentFeedbackConsumption.swift`.
- Updated `Sources/PebbleLab/LabOptions.swift`.
- Updated `Sources/PebbleLab/LabScenarios.swift`.
- Updated `Sources/PebbleLab/LabOutput.swift`.
- Updated `Sources/PebbleLab/LabEvents.swift`.
- Updated `Sources/PebbleLab/main.swift`.
- Updated `docs/pebblelab/CHANGELOG.md`.
- Updated `docs/pebblelab/DEV_JOURNAL.md`.
- Updated `docs/pebblelab/ROADMAP.md`.
- Updated `docs/pebblelab/PHASE_4_FEEDBACK_CONSUMPTION_PLAN.md`.

### Why Hardening

The first fixture smoke proved the happy contract and a small duplicate /
malformed path. The hardening phase adds isolated cases for malformed inputs,
duplicates, max feedback bounds, tick mismatch, all known feedback kinds, and
repeatability before any feedback is allowed to influence agent intent
production.

### Cases Covered

- `baseline_fixture_remains_green`;
- `duplicate_feedback_denied`;
- `malformed_missing_agent_denied`;
- `malformed_missing_kind_denied`;
- `malformed_missing_required_fields_denied`;
- `deterministic_ordering_by_agent_id`;
- `one_feedback_per_agent_bound`;
- `all_known_kinds_observed`;
- `historical_collision_evidence_does_not_read_collision`;
- `max_feedback_bound_exceeded`;
- `tick_mismatch_denied`;
- `stable_repeatability`.

### Duplicate, Malformed, Max, and Tick Policies

Duplicate feedback is ignored after the first stable accepted feedback for an
agent and counted as `duplicateFeedback`. Malformed feedback with missing
agent id, missing kind, or missing required fields is rejected and counted as
invalid. The optional `maxFeedback` bound caps accepted feedback and counts
excess input as `maxFeedbackExceeded`. The optional `expectedTick` check
rejects mismatched feedback and counts `tickMismatchFeedback`.

### Deterministic Ordering

Inputs may be intentionally unordered, but observations and accepted contexts
are sorted by stable `agentId`. Stable repeatability runs the same inputs twice
and compares accepted context ids and summary totals.

### Outputs, Invariants, Metrics, and Event

The scenario writes:

- `agent_feedback_consumption_hardening_report.json`;
- `agent_feedback_consumption_hardening_invariant_report.json`;
- `agent_feedback_consumption_hardening_cases.json`;
- `metrics.json`;
- `events.ndjson`.

The invariant report has 58 checks. Metrics use
`agentFeedbackConsumptionHardening*`, and the aggregate event is
`lab_agent_feedback_consumption_hardening_recorded`.

### Boundaries Confirmed

No movement is applied. The consumption layer does not read collision, produce
intents, call `produceAgentIntentProposalV0`, call agent intent production
scenarios, invoke tick movement scenarios, update memory, change goals,
pathfind, replan, avoid, reserve, learn, use LLM/RL/Python, create social
behavior, communicate, create a `World`, or mutate terrain/world.

### Validation Commands

- `git status`
- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario agent_feedback_consumption_hardening_smoke --seed 42 --ticks 0 --out runs/check_agent_feedback_consumption_hardening`
- `swift run -c release PebbleLab -- --scenario agent_feedback_consumption_fixture_smoke --seed 42 --ticks 0 --out runs/check_agent_feedback_consumption_fixture_after_hardening`
- `swift run -c release PebbleLab -- --scenario agent_intent_to_tick_approved_application_smoke --seed 42 --ticks 5 --out runs/check_agent_intent_approved_application_after_feedback_hardening`
- `swift run -c release PebbleLab -- --scenario agent_intent_to_tick_live_readonly_smoke --seed 42 --ticks 5 --out runs/check_agent_intent_live_readonly_after_feedback_hardening`
- `swift run -c release PebbleLab -- --scenario agent_intent_to_tick_fixture_smoke --seed 42 --ticks 0 --out runs/check_agent_intent_to_tick_fixture_after_feedback_hardening`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_feedback_hardening`
- `swift run -c release pebsmoke`
- `git diff --check`

### Results

- `cases = 12`.
- `passed = 12`.
- `failed = 0`.
- `feedbackObservedTotal = 36`.
- `feedbackAcceptedTotal = 26`.
- `feedbackIgnoredTotal = 5`.
- `invalidFeedbackTotal = 5`.
- `contextsProducedTotal = 26`.
- `duplicateFeedbackTotal = 4`.
- `maxFeedbackExceededTotal = 1`.
- `tickMismatchFeedbackTotal = 1`.
- Every known feedback kind is observed.
- Hardening report, invariant report, cases JSON, metrics, and event are
  produced.

### Next Step

Phase 4.22D — Feedback To Agent Intent Context Fixture Smoke.

## 2026-06-28 — Phase 4.22D feedback to agent intent context fixture

### Objective

Implement `feedback_to_agent_intent_context_fixture_smoke`, a plumbing-only
fixture that carries accepted feedback contexts into
`LabAgentIntentContext.lastFeedback` without changing the agent intent policy
decision.

### Starting Point

Phase 4.22B added the fixture-only feedback consumption smoke. Phase 4.22C
hardened duplicate, malformed, max-feedback, tick-mismatch, ordering, and
repeatability behavior. Phase 4.21B-F validated agent intent production through
approved application, but feedback was still not visible to the intent context.

### Files Created or Modified

- Updated `Sources/PebbleLab/LabAgentFeedbackConsumption.swift`.
- Updated `Sources/PebbleLab/LabAgentIntentProduction.swift`.
- Updated `Sources/PebbleLab/LabOptions.swift`.
- Updated `Sources/PebbleLab/LabScenarios.swift`.
- Updated `Sources/PebbleLab/LabOutput.swift`.
- Updated `Sources/PebbleLab/LabEvents.swift`.
- Updated `Sources/PebbleLab/main.swift`.
- Updated `docs/pebblelab/CHANGELOG.md`.
- Updated `docs/pebblelab/DEV_JOURNAL.md`.
- Updated `docs/pebblelab/ROADMAP.md`.
- Updated `docs/pebblelab/PHASE_4_FEEDBACK_CONSUMPTION_PLAN.md`.

### Why Plumbing-Only

The phase proves that feedback can become bounded input data for a future
policy without making it behavioral yet. `lastFeedback` is preserved in the
agent intent context, but policy v0 is compared against a baseline with nil
feedback and must produce identical decisions.

### Feedback Fixture Inputs

The fixture uses six intentionally unordered feedback inputs: `agent_0` moved,
`agent_1` approved for movement, `agent_2` blocked by collision, `agent_3`
blocked by agent conflict, one duplicate `agent_0` blocked by max agents, and
one malformed feedback input.

### Feedback Consumption Summary

Consumption observes six feedback inputs, accepts four, ignores one duplicate,
rejects one malformed input, produces four feedback contexts, and preserves
stable `agentId` ordering. The consumption layer still reports
`collisionRead = false`, `movementApplied = false`, and `intentProduced = false`.

### Intent Context Injection

Five `LabAgentIntentContext` records are built. Four contain `lastFeedback`
for `agent_0` through `agent_3`, while `agent_4` has no feedback. The fixture
then runs the existing policy v0 only to verify plumbing behavior.

### Baseline Without Feedback

The same context shape is evaluated with `lastFeedback = nil`. Proposal
signatures must match exactly, proving `behaviorChangedByFeedback = false` and
`feedbackUsedForDecision = false`.

### Policy Behavior Unchanged

The policy still accepts three one-edge same-y intents, rejects two proposals
(`idle` and invalid vertical), and does not adapt to `moved`,
`approvedForMovement`, `blockedByCollision`, or `blockedByAgentConflict`.

### Outputs, Invariants, Metrics, and Event

The scenario writes:

- `feedback_to_agent_intent_context_fixture_report.json`;
- `feedback_to_agent_intent_context_fixture_invariant_report.json`;
- `feedback_to_agent_intent_contexts.json`;
- `metrics.json`;
- `events.ndjson`.

Metrics use the `feedbackToAgentIntentContextFixture*` prefix, and the
aggregate event is `lab_feedback_to_agent_intent_context_fixture_recorded`.

### Boundaries Confirmed

The integration does not call tick movement, read collision, apply movement,
update memory, change goals, pathfind, replan, avoid, use reservation runtime,
create a `World`, or mutate terrain/world.

### Validation Commands

- `git status`
- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario feedback_to_agent_intent_context_fixture_smoke --seed 42 --ticks 0 --out runs/check_feedback_to_agent_intent_context_fixture`
- `swift run -c release PebbleLab -- --scenario agent_feedback_consumption_hardening_smoke --seed 42 --ticks 0 --out runs/check_agent_feedback_hardening_after_feedback_to_context`
- `swift run -c release PebbleLab -- --scenario agent_feedback_consumption_fixture_smoke --seed 42 --ticks 0 --out runs/check_agent_feedback_fixture_after_feedback_to_context`
- `swift run -c release PebbleLab -- --scenario agent_intent_production_fixture_smoke --seed 42 --ticks 0 --out runs/check_agent_intent_fixture_after_feedback_to_context`
- `swift run -c release PebbleLab -- --scenario agent_intent_production_hardening_smoke --seed 42 --ticks 0 --out runs/check_agent_intent_hardening_after_feedback_to_context`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_feedback_to_context`
- `swift run -c release pebsmoke`
- `git diff --check`

### Results

- `feedbackObserved = 6`.
- `feedbackAccepted = 4`.
- `feedbackIgnored = 1`.
- `invalidFeedback = 1`.
- `contextsProduced = 4`.
- `intentContexts = 5`.
- `contextsWithFeedback = 4`.
- `contextsWithoutFeedback = 1`.
- `proposals = 5`.
- `acceptedIntents = 3`.
- `rejectedProposals = 2`.
- `behaviorChangedByFeedback = false`.
- `feedbackUsedForDecision = false`.

### Next Step

Phase 4.22E — Feedback To Agent Intent Context Hardening.

## 2026-06-29 — Phase 4.22E feedback to agent intent context hardening

### Objective

Implement `feedback_to_agent_intent_context_hardening_smoke`, a fixture-only
hardening scenario for the handoff from `LabAgentFeedbackContext` to
`LabAgentIntentContext.lastFeedback`.

### Starting Point

Phase 4.22D proved the first plumbing fixture: feedback contexts can be
injected into `lastFeedback`, policy v0 can still run for verification, and
the baseline without feedback produces identical proposal signatures.

### Files Created or Modified

- Updated `Sources/PebbleLab/LabAgentFeedbackConsumption.swift`.
- Updated `Sources/PebbleLab/LabEvents.swift`.
- Updated `Sources/PebbleLab/LabOptions.swift`.
- Updated `Sources/PebbleLab/LabOutput.swift`.
- Updated `Sources/PebbleLab/LabScenarios.swift`.
- Updated `Sources/PebbleLab/main.swift`.
- Updated `docs/pebblelab/CHANGELOG.md`.
- Updated `docs/pebblelab/DEV_JOURNAL.md`.
- Updated `docs/pebblelab/ROADMAP.md`.
- Updated `docs/pebblelab/PHASE_4_FEEDBACK_CONSUMPTION_PLAN.md`.

### Why Hardening

The fixture proved the data path. This phase checks the edge cases that could
accidentally turn feedback into behavior: missing feedback, partial feedback,
all feedback kinds, duplicate selection, malformed feedback, tick mismatch,
max feedback bounds, and repeatability.

### Cases List

The scenario validates 14 cases:

1. `baseline_fixture_remains_green`;
2. `missing_feedback_context_allowed`;
3. `partial_feedback_contexts_allowed`;
4. `all_feedback_kinds_preserved`;
5. `blocked_collision_does_not_change_to_wait`;
6. `moved_feedback_does_not_suppress_next_move`;
7. `agent_conflict_does_not_trigger_coordination`;
8. `invalid_edge_feedback_does_not_hide_invalid_policy`;
9. `duplicate_feedback_context_selection_stable`;
10. `malformed_feedback_not_injected`;
11. `tick_mismatch_feedback_not_injected`;
12. `max_feedback_bound_keeps_contexts_bounded`;
13. `deterministic_ordering_by_agent_id`;
14. `stable_repeatability`.

### Missing, Partial, and All Kinds

Missing feedback contexts are allowed and keep `lastFeedback = nil`. Partial
feedback is injected only for agents with accepted feedback. The all-kinds case
preserves `moved`, `approvedForMovement`, `blockedByCollision`,
`blockedByAgentConflict`, `blockedBySourceMismatch`, `blockedByDivergence`,
`blockedByStaleIntent`, `blockedByInvalidEdge`, and `blockedByMaxAgents`.

### Behavior Unchanged Cases

`blockedByCollision` does not become wait/noIntent. `moved` does not suppress
the next move. `blockedByAgentConflict` does not trigger coordination or
communication. `blockedByInvalidEdge` does not hide an invalid vertical policy
proposal.

### Duplicate, Malformed, Tick, and Max Policies

Duplicate feedback uses the first stable accepted feedback and counts the
duplicate. Malformed feedback and tick-mismatch feedback are rejected and not
injected. `maxFeedback` caps accepted contexts and counts the excess feedback.

### Baseline Comparison

Every case runs the feedback-bearing contexts and a baseline with identical
positions, roles, and hints but nil `lastFeedback`. Proposal signatures must
match exactly.

### Deterministic Ordering and Repeatability

Feedback inputs and context specs may be unordered, but observations and
proposals are sorted by stable `agentId`. The repeatability case runs twice
and compares feedback context ids, preserved feedback kinds, proposal
signatures, and summary totals.

### Outputs, Invariants, Metrics, and Event

The scenario writes:

- `feedback_to_agent_intent_context_hardening_report.json`;
- `feedback_to_agent_intent_context_hardening_invariant_report.json`;
- `feedback_to_agent_intent_context_hardening_cases.json`;
- `metrics.json`;
- `events.ndjson`.

Metrics use `feedbackToAgentIntentContextHardening*`, and the aggregate event
is `lab_feedback_to_agent_intent_context_hardening_recorded`.

### Boundaries Confirmed

No movement is applied. Neither consumption nor integration reads collision.
No tick movement is invoked. Memory, goals, pathfinding, replanning, avoidance,
reservation runtime, learning, LLM/RL/Python, social behavior, communication,
World use, and terrain/world mutation remain out of scope.

### Validation Commands

- `git status`
- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario feedback_to_agent_intent_context_hardening_smoke --seed 42 --ticks 0 --out runs/check_feedback_to_agent_intent_context_hardening`
- `swift run -c release PebbleLab -- --scenario feedback_to_agent_intent_context_fixture_smoke --seed 42 --ticks 0 --out runs/check_feedback_to_agent_intent_context_fixture_after_hardening`
- `swift run -c release PebbleLab -- --scenario agent_feedback_consumption_hardening_smoke --seed 42 --ticks 0 --out runs/check_agent_feedback_hardening_after_feedback_to_context_hardening`
- `swift run -c release PebbleLab -- --scenario agent_feedback_consumption_fixture_smoke --seed 42 --ticks 0 --out runs/check_agent_feedback_fixture_after_feedback_to_context_hardening`
- `swift run -c release PebbleLab -- --scenario agent_intent_production_fixture_smoke --seed 42 --ticks 0 --out runs/check_agent_intent_fixture_after_feedback_to_context_hardening`
- `swift run -c release PebbleLab -- --scenario agent_intent_production_hardening_smoke --seed 42 --ticks 0 --out runs/check_agent_intent_hardening_after_feedback_to_context_hardening`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_feedback_to_context_hardening`
- `swift run -c release pebsmoke`
- `git diff --check`

### Results

- `cases = 14`.
- `passed = 14`.
- `failed = 0`.
- `feedbackObservedTotal = 34`.
- `feedbackAcceptedTotal = 28`.
- `feedbackIgnoredTotal = 3`.
- `invalidFeedbackTotal = 3`.
- `contextsProducedTotal = 28`.
- `intentContextsTotal = 40`.
- `contextsWithFeedbackTotal = 28`.
- `contextsWithoutFeedbackTotal = 12`.
- `proposalsTotal = 40`.
- `acceptedIntentsTotal = 33`.
- `rejectedProposalsTotal = 7`.
- `behaviorChangedByFeedback = false`.
- `feedbackUsedForDecision = false`.

### Next Step

Phase 4.22F — Feedback-Aware Intent Policy Planning Docs-Only.

## 2026-06-29 — Phase 4.22F feedback-aware intent policy planning docs-only

### Objective

Create a docs-only plan for the future feedback-aware intent policy. The phase
prepares the transition from `LabAgentIntentContext.lastFeedback` to a bounded
deterministic feedback-aware policy without implementing that policy.

### Starting Point

Phases 4.22A-E validated feedback consumption, hardening, and injection into
`LabAgentIntentContext.lastFeedback`. The current policy v0 still ignores
feedback deliberately, with `behaviorChangedByFeedback = false` and
`feedbackUsedForDecision = false`.

### Why Docs-Only

The next step is behavioral. Before adding behavior, the plan locks the policy
boundary, feedback reactions, outputs, metrics, events, invariants, risks, and
recommended 4.23A contract. No Swift, runner, metric, event, or scenario is
added in this phase.

### New Document

Created `docs/pebblelab/PHASE_4_FEEDBACK_AWARE_INTENT_POLICY_PLAN.md`.

### Policy Boundary

Future v1 may read `lastFeedback`, position, role, and local hints; keep v0;
produce `noIntent`; or later choose a deterministic bounded local hint. It may
not read World or collision, apply movement, mutate memory or goals, pathfind,
replan, avoid, reserve, learn, call LLM/RL/Python, communicate, run a
multi-tick loop, or mutate terrain/world.

### Feedback Reaction Table

The table defines planned reactions for `moved`, `approvedForMovement`, and
every `blockedBy*` kind. The recommended first smoke keeps baseline behavior
for `moved` and `approvedForMovement`, and maps blocked feedback to
`noIntent`.

### Proposed v1 Policy

The proposed policy is `produceAgentIntentProposalFeedbackAwareV1`. It is
opt-in, computes the v0 baseline first, returns baseline for no feedback,
`moved`, and `approvedForMovement`, and returns `noIntent` for blocked
feedback in 4.23A. Directional alternatives are deferred.

### Future Phases

The plan recommends:

- Phase 4.23A - Bounded Feedback-Aware Intent Policy Fixture Smoke;
- Phase 4.23B - Feedback-Aware Intent Policy Hardening;
- Phase 4.23C - Feedback-Aware Intent To Tick Fixture Smoke;
- Phase 4.23D - Feedback-Aware Intent To Tick Live Read-Only Smoke;
- Phase 4.23E - Feedback-Aware Intent To Tick Approved Application Smoke;
- Phase 4.24A - Multi-Tick Closed Loop Planning Docs-Only.

### Outputs, Metrics, Event, and Invariants

Future outputs are `feedback_aware_intent_policy_report.json`,
`feedback_aware_intent_policy_invariant_report.json`,
`feedback_aware_intent_policy_decisions.json`, `metrics.json`, and
`events.ndjson`. Metrics use the `feedbackAwareIntentPolicy*` prefix, and the
future aggregate event is `lab_feedback_aware_intent_policy_recorded`.

The plan lists 54 future invariants covering v0 stability, opt-in v1,
baseline comparison, feedback reactions, no World/collision/movement/memory/
goals/pathfinding/replanning/avoidance/reservation/learning/social behavior,
and artifact writing.

### Out Of Scope

Pathfinding, dynamic replanning, avoidance, reservation runtime, social
coordination, communication, learning, reward updates, RL, LLM/Python, memory
mutation, goal mutation, live collision reads, movement application, World
access, terrain/world mutation, inventory/mining/construction, autonomous
multi-tick loops, and replacing v0 globally remain out of scope.

### Risk Table

The risk table covers v1 replacing v0, feedback becoming pathfinding, hidden
collision reads, social behavior, movement suppression, invalid-edge masking,
scheduler/reservation leakage, repair loops, nondeterministic alternates,
metrics drift, and reports hiding behavior changes.

### Recommended 4.23A Contract

Phase 4.23A should implement opt-in `produceAgentIntentProposalFeedbackAwareV1`
with v0 unchanged. No feedback, `moved`, and `approvedForMovement` return
baseline. All blocked feedback kinds return `noIntent`. The smoke compares v1
with v0 baseline and permits `behaviorChangedByFeedback = true` only for
intended blocked feedback cases.

### Validation Commands

- `git status`
- `swift build`
- `swift run -c release pebsmoke`
- `git diff --check`
- `git status`

### Results

- Plan document created.
- CHANGELOG updated.
- DEV_JOURNAL updated.
- ROADMAP updated.
- Feedback consumption plan cross-linked.
- No Swift files modified.

### Next Step

Phase 4.23A — Bounded Feedback-Aware Intent Policy Fixture Smoke.

## 2026-06-29 — Phase 4.23A bounded feedback-aware intent policy fixture

### Objective

Implement the first opt-in feedback-aware agent intent policy fixture:
`feedback_aware_intent_policy_fixture_smoke`.

### Starting Point

Phase 4.22F documented the feedback-aware policy plan. At the start of this
phase, `LabAgentIntentContext.lastFeedback` was already available from the
feedback-to-context plumbing, but policy v0 intentionally ignored it.

### Files Created Or Modified

- `Sources/PebbleLab/LabAgentIntentProduction.swift`
- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`
- `docs/pebblelab/PHASE_4_FEEDBACK_AWARE_INTENT_POLICY_PLAN.md`

### Why Opt-In

The existing v0 fixture and production scenarios are baseline contracts. The
new v1 policy is exposed only through
`feedback_aware_intent_policy_fixture_smoke`; v0 remains unchanged and is not
replaced globally.

### v0 Unchanged

The v1 policy computes `produceAgentIntentProposalV0(context:)` first and keeps
the baseline proposal for no feedback, `moved`, and `approvedForMovement`.
Existing v0 scenarios continue to call v0 directly.

### v1 Rules

- no feedback -> baseline;
- `moved` -> baseline;
- `approvedForMovement` -> baseline;
- `blockedByCollision` -> `noIntent`;
- `blockedByAgentConflict` -> `noIntent`;
- `blockedBySourceMismatch` -> `noIntent`;
- `blockedByDivergence` -> `noIntent`;
- `blockedByStaleIntent` -> `noIntent`;
- `blockedByInvalidEdge` -> `noIntent`;
- `blockedByMaxAgents` -> `noIntent`.

### Fixture Contexts

The fixture uses 10 deliberately unordered contexts:

- `agent_0_no_feedback`;
- `agent_1_moved`;
- `agent_2_approved`;
- `agent_3_collision`;
- `agent_4_conflict`;
- `agent_5_source_mismatch`;
- `agent_6_divergence`;
- `agent_7_stale`;
- `agent_8_invalid_edge`;
- `agent_9_max_agents`.

### Baseline Comparison

Every v1 decision stores its baseline v0 proposal and feedback-aware proposal.
The output decisions are sorted by stable `agentId`.

### Behavior Changed Only For Blocked Feedback

No feedback, `moved`, and `approvedForMovement` preserve the baseline. The
seven blocking feedback contexts change to explicit `noIntent`, so
`behaviorChangedByFeedback = true` and `behaviorChangedCount = 7`.

### Outputs, Invariants, Metrics, And Event

The scenario writes:

- `feedback_aware_intent_policy_fixture_report.json`;
- `feedback_aware_intent_policy_fixture_invariant_report.json`;
- `feedback_aware_intent_policy_decisions.json`;
- `feedbackAwareIntentPolicyFixture*` metrics;
- aggregate event `lab_feedback_aware_intent_policy_fixture_recorded`.

The invariant report includes 57 checks covering v0 availability, opt-in v1,
baseline-first evaluation, baseline retention, blocked feedback noIntent
reactions, explicit invalid-edge reason, sorted outputs, no World/collision/
movement/memory/goals/pathfinding/replanning/avoidance/reservation/mutation,
artifact writing, and success contract.

### Out Of Scope Confirmed

No tick movement, movement application, collision read, World access, memory
update, goal change, pathfinding, replanning, avoidance, reservation runtime,
learning, LLM/RL/Python, social behavior, communication, terrain mutation, or
world mutation was added.

### Validation Commands

- `git status`
- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_policy_fixture_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_intent_policy_fixture`
- `swift run -c release PebbleLab -- --scenario feedback_to_agent_intent_context_hardening_smoke --seed 42 --ticks 0 --out runs/check_feedback_to_agent_intent_context_hardening_after_feedback_aware_policy`
- `swift run -c release PebbleLab -- --scenario feedback_to_agent_intent_context_fixture_smoke --seed 42 --ticks 0 --out runs/check_feedback_to_agent_intent_context_fixture_after_feedback_aware_policy`
- `swift run -c release PebbleLab -- --scenario agent_feedback_consumption_hardening_smoke --seed 42 --ticks 0 --out runs/check_agent_feedback_hardening_after_feedback_aware_policy`
- `swift run -c release PebbleLab -- --scenario agent_feedback_consumption_fixture_smoke --seed 42 --ticks 0 --out runs/check_agent_feedback_fixture_after_feedback_aware_policy`
- `swift run -c release PebbleLab -- --scenario agent_intent_production_fixture_smoke --seed 42 --ticks 0 --out runs/check_agent_intent_fixture_after_feedback_aware_policy`
- `swift run -c release PebbleLab -- --scenario agent_intent_production_hardening_smoke --seed 42 --ticks 0 --out runs/check_agent_intent_hardening_after_feedback_aware_policy`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_feedback_aware_policy`
- `swift run -c release pebsmoke`
- `git diff --check`

### Results

- `feedback_aware_intent_policy_fixture_smoke` passes.
- Report success true.
- Invariant report success true.
- `contexts = 10`.
- `contextsWithFeedback = 9`.
- `contextsWithoutFeedback = 1`.
- `baselineProposals = 10`.
- `feedbackAwareProposals = 10`.
- `acceptedIntents = 3`.
- `rejectedProposals = 7`.
- `noIntent = 7`.
- `invalidOneEdgeProposals = 0`.
- `behaviorChangedCount = 7`.
- `feedbackAwareIntentPolicyFixture*` metrics are present.
- `lab_feedback_aware_intent_policy_fixture_recorded` event is present.

### Next Step

Phase 4.23B — Feedback-Aware Intent Policy Hardening.

## 2026-06-29 — Phase 4.23B feedback-aware intent policy hardening

### Objective

Implement `feedback_aware_intent_policy_hardening_smoke`, a fixture-only
hardening scenario for the opt-in feedback-aware v1 intent policy.

### Starting Point

Phase 4.23A introduced `produceAgentIntentProposalFeedbackAwareV1` as an
explicit opt-in policy. It computes v0 first, keeps v0 for no feedback,
`moved`, and `approvedForMovement`, and maps blocked feedback kinds to
`noIntent`. The v0 policy remains unchanged and existing v0 scenarios still
call v0 directly.

### Files Created Or Modified

- `Sources/PebbleLab/LabAgentIntentProduction.swift`
- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`
- `docs/pebblelab/PHASE_4_FEEDBACK_AWARE_INTENT_POLICY_PLAN.md`

### Why Hardening

The fixture smoke proved the basic v1 contract. This phase adds focused edge
coverage around every feedback reaction, baseline preservation, invalid v0
proposals, existing v0 noIntent decisions, deterministic ordering, and stable
repeatability before any tick integration is attempted.

### Cases Covered

- `baseline_fixture_remains_green`;
- `no_feedback_returns_baseline`;
- `moved_returns_baseline`;
- `approved_for_movement_returns_baseline`;
- `blocked_collision_returns_no_intent`;
- `blocked_agent_conflict_returns_no_intent`;
- `blocked_source_mismatch_returns_no_intent`;
- `blocked_divergence_returns_no_intent`;
- `blocked_stale_intent_returns_no_intent`;
- `blocked_invalid_edge_returns_no_intent_explicit_reason`;
- `blocked_max_agents_returns_no_intent`;
- `blocked_feedback_on_baseline_no_intent_stays_no_intent`;
- `blocked_feedback_on_baseline_invalid_becomes_no_intent`;
- `all_blocked_kinds_counted_once`;
- `deterministic_ordering_by_agent_id`;
- `stable_repeatability`.

### v0 Unchanged And v1 Opt-In

The v1 hardening path still computes baseline v0 proposals first. The existing
v0 producer is not replaced globally. The hardening scenario is the only new
caller, and v0 fixture/hardening scenarios remain independent.

### Feedback Reaction Policy

No feedback, `moved`, and `approvedForMovement` preserve the v0 baseline.
Blocked feedback kinds produce `noIntent` when baseline v0 would move or emit
an invalid proposal. If v0 already returns `noIntent`, the baseline signature is
preserved while the blocked reaction is still counted. `blockedByInvalidEdge`
keeps an explicit invalid-edge noIntent reason.

### Deterministic Ordering And Repeatability

Outputs are sorted by stable `agentId`. The repeatability case evaluates the
same inputs twice and requires matching proposal signatures and summary totals.

### Outputs, Invariants, Metrics, And Event

The scenario writes:

- `feedback_aware_intent_policy_hardening_report.json`;
- `feedback_aware_intent_policy_hardening_invariant_report.json`;
- `feedback_aware_intent_policy_hardening_cases.json`;
- `feedbackAwareIntentPolicyHardening*` metrics;
- aggregate event `lab_feedback_aware_intent_policy_hardening_recorded`.

The invariant report covers 58 checks across case existence, all cases passed,
baseline retention, blocked feedback noIntent behavior, sorted outputs,
repeatability, no World/collision/movement/memory/goals/pathfinding/
replanning/avoidance/reservation/mutation, artifact writing, and the success
contract.

### Out Of Scope Confirmed

No tick movement, movement application, collision read, World access, memory
update, goal change, pathfinding, replanning, avoidance, reservation runtime,
learning, LLM/RL/Python, social behavior, communication, terrain mutation, or
world mutation was added.

### Validation Commands

- `git status`
- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_policy_hardening_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_intent_policy_hardening`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_policy_fixture_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_intent_policy_fixture_after_hardening`
- `swift run -c release PebbleLab -- --scenario feedback_to_agent_intent_context_hardening_smoke --seed 42 --ticks 0 --out runs/check_feedback_to_agent_intent_context_hardening_after_policy_hardening`
- `swift run -c release PebbleLab -- --scenario feedback_to_agent_intent_context_fixture_smoke --seed 42 --ticks 0 --out runs/check_feedback_to_agent_intent_context_fixture_after_policy_hardening`
- `swift run -c release PebbleLab -- --scenario agent_feedback_consumption_hardening_smoke --seed 42 --ticks 0 --out runs/check_agent_feedback_hardening_after_policy_hardening`
- `swift run -c release PebbleLab -- --scenario agent_feedback_consumption_fixture_smoke --seed 42 --ticks 0 --out runs/check_agent_feedback_fixture_after_policy_hardening`
- `swift run -c release PebbleLab -- --scenario agent_intent_production_fixture_smoke --seed 42 --ticks 0 --out runs/check_agent_intent_fixture_after_policy_hardening`
- `swift run -c release PebbleLab -- --scenario agent_intent_production_hardening_smoke --seed 42 --ticks 0 --out runs/check_agent_intent_hardening_after_policy_hardening`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_policy_hardening`
- `swift run -c release pebsmoke`
- `git diff --check`

### Results

- `feedback_aware_intent_policy_hardening_smoke` passes.
- Report success true.
- Invariant report success true.
- `cases = 16`.
- `passed = 16`.
- `failed = 0`.
- All feedback reaction hardening cases are covered.
- Deterministic ordering and stable repeatability are verified.
- `feedbackAwareIntentPolicyHardening*` metrics are present.
- `lab_feedback_aware_intent_policy_hardening_recorded` event is present.

### Next Step

Phase 4.23C — Feedback-Aware Intent To Tick Fixture Smoke.

## 2026-06-29 — Phase 4.23C feedback-aware intent to tick fixture

### Objective

Implement `feedback_aware_intent_to_tick_fixture_smoke`, the first fixture-only
handoff from opt-in feedback-aware v1 intent policy into the multi-agent
movement tick fixture contract.

### Starting Point

Phase 4.23A added `produceAgentIntentProposalFeedbackAwareV1`. Phase 4.23B
hardened its opt-in behavior over 16 cases. v0 remained unchanged, and no
tick movement integration had yet consumed v1 proposals.

### Files Created Or Modified

- `Sources/PebbleLab/LabAgentIntentProduction.swift`
- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`
- `docs/pebblelab/PHASE_4_FEEDBACK_AWARE_INTENT_POLICY_PLAN.md`

### Why Fixture-Only

This phase tests the data handoff only. The tick layer is the existing fixture
arbitration path: no World, no live collision evidence, no movement
application, no route following, and no multi-tick loop.

### v1 Opt-In And v0 Unchanged

The scenario computes baseline v0 proposals for comparison, but runtime handoff
uses only explicit v1 decisions. `produceAgentIntentProposalV0` is not modified
and v1 remains scenario-specific.

### Fixture Contexts

The six deliberately unordered contexts are:

- `agent_0_no_feedback`: baseline east move, kept by v1;
- `agent_1_moved`: baseline west move, kept by v1;
- `agent_2_collision`: `blockedByCollision`, converted to `noIntent`;
- `agent_3_conflict`: `blockedByAgentConflict`, converted to `noIntent`;
- `agent_4_approved`: baseline east move, kept by v1;
- `agent_5_invalid_edge`: `blockedByInvalidEdge` over invalid vertical v0
  proposal, converted to `noIntent`.

### Baseline Versus Feedback-Aware Handoff

The v0 baseline has six proposals and five valid movement intents. The v1
handoff has six proposals and three movement intents. The reduction is two
movement inputs, with three `noIntent` proposals filtered before tick input.

### NoIntent Filtered Before Tick

The blocked collision, blocked agent-conflict, and blocked invalid-edge agents
do not enter the tick as movement intents. Their `noIntent` proposals remain in
the report and handoff JSON for auditability.

### Remaining Conflict Handled By Tick

The policy intentionally does not arbitrate the remaining same-destination
conflict between `agent_0_no_feedback` and `agent_1_moved`. Both intents target
`(1,64,0)`. The tick fixture resolves the conflict by stable `agentId`:
`agent_0_no_feedback` is approved and `agent_1_moved` is denied
same-destination conflict. `agent_4_approved` is also approved.

### Outputs, Invariants, Metrics, And Event

The scenario writes:

- `feedback_aware_intent_to_tick_fixture_report.json`;
- `feedback_aware_intent_to_tick_fixture_invariant_report.json`;
- `feedback_aware_intent_to_tick_handoff.json`;
- `feedbackAwareIntentToTickFixture*` metrics;
- aggregate event `lab_feedback_aware_intent_to_tick_fixture_recorded`.

The invariant report covers contexts, v0/v1 boundaries, sorted decisions,
filtered `noIntent`, movement intent reduction, tick input/output, remaining
conflict arbitration, unchanged positions, no live collision, no movement,
no World, no memory/goals, no pathfinding/replanning/avoidance/reservation,
no route following, artifact writing, and the success contract.

### Out Of Scope Confirmed

No live collision, movement application, World access, memory update, goal
change, pathfinding, replanning, avoidance, reservation runtime, route
following, gameplay movement, terrain mutation, or world mutation was added.

### Validation Commands

- `git status`
- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_to_tick_fixture_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_intent_to_tick_fixture`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_policy_hardening_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_policy_hardening_after_intent_to_tick_fixture`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_policy_fixture_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_policy_fixture_after_intent_to_tick_fixture`
- `swift run -c release PebbleLab -- --scenario feedback_to_agent_intent_context_hardening_smoke --seed 42 --ticks 0 --out runs/check_feedback_to_context_hardening_after_intent_to_tick_fixture`
- `swift run -c release PebbleLab -- --scenario feedback_to_agent_intent_context_fixture_smoke --seed 42 --ticks 0 --out runs/check_feedback_to_context_fixture_after_intent_to_tick_fixture`
- `swift run -c release PebbleLab -- --scenario agent_feedback_consumption_hardening_smoke --seed 42 --ticks 0 --out runs/check_agent_feedback_hardening_after_intent_to_tick_fixture`
- `swift run -c release PebbleLab -- --scenario agent_intent_production_fixture_smoke --seed 42 --ticks 0 --out runs/check_agent_intent_fixture_after_intent_to_tick_fixture`
- `swift run -c release PebbleLab -- --scenario agent_intent_to_tick_fixture_smoke --seed 42 --ticks 0 --out runs/check_agent_intent_to_tick_fixture_after_feedback_aware_intent_to_tick`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_feedback_aware_intent_to_tick_fixture`
- `swift run -c release pebsmoke`
- `git diff --check`

### Results

- `feedback_aware_intent_to_tick_fixture_smoke` passes.
- Report success true.
- Invariant report success true.
- `contexts = 6`.
- `contextsWithFeedback = 5`.
- `contextsWithoutFeedback = 1`.
- `baselineMovementIntentInputs = 5`.
- `feedbackAwareMovementIntentInputs = 3`.
- `movementIntentReduction = 2`.
- `noIntentFilteredOut = 3`.
- `tickApproved = 2`.
- `tickDenied = 1`.
- `tickDeniedSameDestinationConflict = 1`.
- `tickFeedbackEmitted = 3`.
- `displacementsApplied = 0`.
- `feedbackAwareIntentToTickFixture*` metrics are present.
- `lab_feedback_aware_intent_to_tick_fixture_recorded` event is present.

### Next Step

Phase 4.23D — Feedback-Aware Intent To Tick Live Read-Only Smoke.

## 2026-06-29 — Phase 4.23D feedback-aware intent to tick live read-only

### Objective

Implement `feedback_aware_intent_to_tick_live_readonly_smoke`, the first
handoff from opt-in feedback-aware v1 intent policy into the live read-only
movement tick contract.

### Starting Point

Phase 4.23A introduced the opt-in v1 policy. Phase 4.23B hardened the policy.
Phase 4.23C proved that v1 proposals can feed the fixture tick contract while
filtering `noIntent` proposals before tick input. Live collision was still out
of scope in 4.23C.

### Files Created Or Modified

- `Sources/PebbleLab/LabAgentIntentProduction.swift`
- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`
- `docs/pebblelab/PHASE_4_FEEDBACK_AWARE_INTENT_POLICY_PLAN.md`

### Why Live Read-Only

This phase proves the next boundary: the policy proposes without reading World
or collision, then the tick layer reads live collision evidence read-only and
emits approval/denial feedback without applying movement.

### v1 Opt-In And v0 Unchanged

The scenario computes v0 baseline proposals for comparison only. Runtime
handoff uses explicit v1 decisions. `produceAgentIntentProposalV0` remains
unchanged, and v1 is not made implicit.

### Fixture Contexts

The seven deliberately unordered contexts are:

- `agent_0_no_feedback`: no feedback, baseline move kept;
- `agent_1_moved`: `moved`, baseline move kept;
- `agent_2_collision_feedback`: `blockedByCollision`, converted to `noIntent`;
- `agent_3_conflict_feedback`: `blockedByAgentConflict`, converted to
  `noIntent`;
- `agent_4_approved`: `approvedForMovement`, baseline move kept;
- `agent_5_invalid_edge_feedback`: `blockedByInvalidEdge` over an invalid
  vertical baseline proposal, converted to `noIntent`;
- `agent_6_live_collision`: no feedback, baseline move kept, later denied by
  tick live collision evidence.

### Baseline Versus Feedback-Aware Handoff

The v0 baseline has seven proposals and six valid movement intents. The v1
handoff has seven proposals and four movement intents. Three `noIntent`
proposals are filtered before tick input, producing a movement intent reduction
of two.

### Remaining Conflict And Live Collision

The policy does not arbitrate the remaining same-destination conflict between
`agent_0_no_feedback` and `agent_1_moved`. The live read-only tick layer
resolves it by stable `agentId`: `agent_0_no_feedback` is approved and
`agent_1_moved` is denied same-destination conflict.

The tick layer reads collision evidence for the accepted movement intents.
`agent_4_approved` is approved on an occupable destination.
`agent_6_live_collision` is denied collision on a non-occupable destination.
The policy does not know either result in advance.

### Outputs, Invariants, Metrics, And Event

The scenario writes:

- `feedback_aware_intent_to_tick_live_readonly_report.json`;
- `feedback_aware_intent_to_tick_live_readonly_invariant_report.json`;
- `feedback_aware_intent_to_tick_live_readonly_handoff.json`;
- `feedbackAwareIntentToTickLiveReadonly*` metrics;
- aggregate event `lab_feedback_aware_intent_to_tick_live_readonly_recorded`.

The invariant report covers contexts, sorted decisions, v0/v1 boundaries,
filtered `noIntent`, reduced movement input, live read-only collision at tick
layer only, same-destination conflict arbitration by tick, collision denial,
unchanged positions, no movement application, no memory/goals, no
pathfinding/replanning/avoidance/reservation, no route following, no mutation,
artifact writing, and the success contract.

### Out Of Scope Confirmed

No collision or World read by policy, movement application, route following,
memory update, goal change, pathfinding, replanning, avoidance, reservation
runtime, gameplay movement, terrain mutation, or world mutation was added.

### Validation Commands

- `git status`
- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_to_tick_live_readonly_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_intent_to_tick_live_readonly`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_to_tick_fixture_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_intent_to_tick_fixture_after_live_readonly`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_policy_hardening_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_policy_hardening_after_live_readonly`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_policy_fixture_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_policy_fixture_after_live_readonly`
- `swift run -c release PebbleLab -- --scenario feedback_to_agent_intent_context_hardening_smoke --seed 42 --ticks 0 --out runs/check_feedback_to_context_hardening_after_live_readonly`
- `swift run -c release PebbleLab -- --scenario feedback_to_agent_intent_context_fixture_smoke --seed 42 --ticks 0 --out runs/check_feedback_to_context_fixture_after_live_readonly`
- `swift run -c release PebbleLab -- --scenario agent_feedback_consumption_hardening_smoke --seed 42 --ticks 0 --out runs/check_agent_feedback_hardening_after_live_readonly`
- `swift run -c release PebbleLab -- --scenario agent_intent_production_fixture_smoke --seed 42 --ticks 0 --out runs/check_agent_intent_fixture_after_live_readonly`
- `swift run -c release PebbleLab -- --scenario agent_intent_to_tick_live_readonly_smoke --seed 42 --ticks 0 --out runs/check_agent_intent_to_tick_live_readonly_after_feedback_aware_live_readonly`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_feedback_aware_live_readonly`
- `swift run -c release pebsmoke`
- `git diff --check`

### Results

- `feedback_aware_intent_to_tick_live_readonly_smoke` passes.
- Report success true.
- Invariant report success true.
- `contexts = 7`.
- `contextsWithFeedback = 5`.
- `contextsWithoutFeedback = 2`.
- `baselineMovementIntentInputs = 6`.
- `feedbackAwareMovementIntentInputs = 4`.
- `movementIntentReduction = 2`.
- `noIntentFilteredOut = 3`.
- `tickApproved = 2`.
- `tickDenied = 2`.
- `tickDeniedSameDestinationConflict = 1`.
- `tickDeniedCollision = 1`.
- `tickFeedbackEmitted = 4`.
- `occupableDestinations = 2`.
- `nonOccupableDestinations = 1`.
- `displacementsApplied = 0`.
- `policyReadCollision = false`.
- `policyWorldUsed = false`.
- `tickReadCollision = true`.
- `tickWorldReadOnlyUsed = true`.
- `worldMutated = false`.
- `feedbackAwareIntentToTickLiveReadonly*` metrics are present.
- `lab_feedback_aware_intent_to_tick_live_readonly_recorded` event is present.

### Next Step

Phase 4.23E — Feedback-Aware Intent To Tick Approved Application Smoke.

## 2026-06-29 — Phase 4.23E feedback-aware intent to tick approved application

### Objective

Connect the opt-in feedback-aware v1 policy to the live read-only tick layer,
then apply only approved movement displacements to lab position maps.

### Starting Point

Phase 4.23D already proved that feedback-aware v1 proposals can feed live
read-only tick arbitration: policy stays World-blind and collision-blind,
tick reads collision evidence, two intents are approved, one is denied by
agent conflict, one is denied by collision, and no movement is applied.

### Files Created Or Modified

- `Sources/PebbleLab/LabAgentIntentProduction.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`
- `docs/pebblelab/PHASE_4_FEEDBACK_AWARE_INTENT_POLICY_PLAN.md`

### Why Approved Application

This phase proves the final single-tick handoff before multi-tick planning:
v1 proposes, tick reads collision and arbitrates, and only approved moves are
applied to lab abstract/physical position maps. Denied and noIntent agents are
preserved, and terrain/World mutation remains forbidden.

### v1 Opt-In And v0 Unchanged

The scenario computes v0 baseline proposals only for comparison. Runtime
handoff uses explicit `produceAgentIntentProposalFeedbackAwareV1` decisions.
`produceAgentIntentProposalV0` remains unchanged and v1 is not made implicit.

### Contexts

The seven deliberately unordered contexts match 4.23D:

- `agent_0_no_feedback`: no feedback, v1 keeps baseline move east;
- `agent_1_moved`: `moved`, v1 keeps baseline move west to the same
  destination as `agent_0_no_feedback`;
- `agent_2_collision_feedback`: `blockedByCollision`, v1 becomes `noIntent`;
- `agent_3_conflict_feedback`: `blockedByAgentConflict`, v1 becomes
  `noIntent`;
- `agent_4_approved`: `approvedForMovement`, v1 keeps baseline move south;
- `agent_5_invalid_edge_feedback`: `blockedByInvalidEdge`, v1 becomes
  `noIntent`;
- `agent_6_live_collision`: no feedback, v1 keeps baseline move east and tick
  denies it by live collision evidence.

### Baseline Versus Feedback-Aware Handoff

The v0 baseline has seven proposals and six movement intent inputs. The v1
handoff has seven proposals and four movement intent inputs. Three `noIntent`
proposals are filtered before tick input, reducing movement attempts by two.

### Tick Collision Read Only At Tick Layer

The policy does not read collision or World. The tick approved-application
helper reads live collision evidence for the four accepted v1 movement intents.
It approves `agent_0_no_feedback` and `agent_4_approved`, denies
`agent_1_moved` by same-destination conflict, and denies
`agent_6_live_collision` by collision.

### Approved Movement Application

Approved movement is applied only to lab position maps. `agent_0_no_feedback`
moves to `(1,64,0)` and `agent_4_approved` moves to `(9,64,8)`.
`displacementsApplied = 2`, `abstractPositionsChanged = 2`, and
`physicalPositionsChanged = 2`.

### Denied And noIntent Preserved

Denied agents remain at their original positions:

- `agent_1_moved`: `(2,64,0)`;
- `agent_6_live_collision`: `(7,64,8)`.

Filtered noIntent agents also remain unchanged:

- `agent_2_collision_feedback`: `(7,64,8)`;
- `agent_3_conflict_feedback`: `(4,64,0)`;
- `agent_5_invalid_edge_feedback`: `(8,64,0)`.

Abstract/physical divergence remains zero before and after application.

### Outputs, Invariants, Metrics, And Event

The scenario writes:

- `feedback_aware_intent_to_tick_approved_application_report.json`;
- `feedback_aware_intent_to_tick_approved_application_invariant_report.json`;
- `feedback_aware_intent_to_tick_approved_application_handoff.json`;
- `feedbackAwareIntentToTickApprovedApplication*` metrics;
- aggregate event
  `lab_feedback_aware_intent_to_tick_approved_application_recorded`.

### Boundaries Confirmed

No policy collision read, policy World access, route following, memory update,
goal change, pathfinding, replanning, avoidance, reservation runtime,
terrain mutation, or world mutation was added.

### Validation Commands

- `git status`
- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_to_tick_approved_application_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_intent_to_tick_approved_application`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_to_tick_live_readonly_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_intent_to_tick_live_readonly_after_approved_application`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_to_tick_fixture_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_intent_to_tick_fixture_after_approved_application`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_policy_hardening_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_policy_hardening_after_approved_application`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_policy_fixture_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_policy_fixture_after_approved_application`
- `swift run -c release PebbleLab -- --scenario feedback_to_agent_intent_context_hardening_smoke --seed 42 --ticks 0 --out runs/check_feedback_to_context_hardening_after_approved_application`
- `swift run -c release PebbleLab -- --scenario feedback_to_agent_intent_context_fixture_smoke --seed 42 --ticks 0 --out runs/check_feedback_to_context_fixture_after_approved_application`
- `swift run -c release PebbleLab -- --scenario agent_feedback_consumption_hardening_smoke --seed 42 --ticks 0 --out runs/check_agent_feedback_hardening_after_approved_application`
- `swift run -c release PebbleLab -- --scenario agent_intent_production_fixture_smoke --seed 42 --ticks 0 --out runs/check_agent_intent_fixture_after_approved_application`
- `swift run -c release PebbleLab -- --scenario agent_intent_to_tick_approved_application_smoke --seed 42 --ticks 0 --out runs/check_agent_intent_to_tick_approved_application_after_feedback_aware_approved_application`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_feedback_aware_approved_application`
- `swift run -c release pebsmoke`
- `git diff --check`

### Results

- `feedback_aware_intent_to_tick_approved_application_smoke` passes.
- Report success true.
- Invariant report success true.
- `contexts = 7`.
- `contextsWithFeedback = 5`.
- `contextsWithoutFeedback = 2`.
- `baselineMovementIntentInputs = 6`.
- `feedbackAwareMovementIntentInputs = 4`.
- `movementIntentReduction = 2`.
- `noIntentFilteredOut = 3`.
- `tickApproved = 2`.
- `tickDenied = 2`.
- `tickDeniedSameDestinationConflict = 1`.
- `tickDeniedCollision = 1`.
- `tickFeedbackEmitted = 4`.
- `approvedAgentsMoved = 2`.
- `deniedAgentsPreserved = 2`.
- `noIntentAgentsPreserved = 3`.
- `displacementsApplied = 2`.
- `abstractPositionsChanged = 2`.
- `physicalPositionsChanged = 2`.
- `abstractPhysicalDivergenceBefore = 0`.
- `abstractPhysicalDivergenceAfter = 0`.
- `policyReadCollision = false`.
- `policyWorldUsed = false`.
- `tickReadCollision = true`.
- `tickWorldReadOnlyUsed = true`.
- `worldMutated = false`.

### Next Step

Phase 4.24A — Multi-Tick Closed Loop Planning Docs-Only.

## 2026-06-29 — Phase 4.24A multi-tick closed loop planning docs-only

### Objective

Document the future bounded multi-tick closed loop before implementing any
loop runner, scenario, metrics, or event code.

### Starting Point

Phases 4.19 through 4.23 validated the single-tick building blocks:
multi-agent movement primitives, tick feedback, agent intent production,
feedback consumption/injection, feedback-aware v1 policy, live read-only tick
handoff, and approved lab position map application. The current system can
produce feedback, consume it, inject it into `LabAgentIntentContext`, and use
v1 to shape the next proposal in isolated smokes. It does not yet run an
autonomous multi-tick loop.

### Why Docs-Only

The next feature combines several validated layers. A docs-only phase locks
the boundary before adding orchestration, especially the causality rule that
feedback emitted at tick `N` may only be consumed at tick `N+1`.

### New Document

Created `docs/pebblelab/PHASE_4_MULTI_TICK_CLOSED_LOOP_PLAN.md`.

### Closed Loop Boundary

Allowed future behavior is limited to fixed small tick counts, previous tick
feedback consumption, `lastFeedback` injection, explicit v1 policy calls,
`noIntent` filtering, selected tick contract execution, optional approved lab
position map application in approved-application phases, structured feedback
carryover, reports, metrics, events, and deterministic ordering.

Forbidden behavior remains pathfinding, replanning, avoidance, reservation
runtime, route following, gameplay autonomy, memory/goals, learning, RL,
Python/LLM calls, social behavior, communication, physics, terrain/world
mutation, renderer/resource/shader changes, registries, save/load, goldens,
and replacing v0 globally.

### Future Phases

The plan recommends:

- Phase 4.24B — Multi-Tick Closed Loop Fixture Smoke;
- Phase 4.24C — Multi-Tick Closed Loop Hardening;
- Phase 4.24D — Multi-Tick Closed Loop Live Read-Only Smoke;
- Phase 4.24E — Multi-Tick Closed Loop Approved Application Smoke;
- Phase 4.25A — Deterministic Bounded Alternate Local Hint Planning Docs-Only.

### Reports, Metrics, And Event

Future outputs are planned as:

- `multi_tick_closed_loop_report.json`;
- `multi_tick_closed_loop_invariant_report.json`;
- `multi_tick_closed_loop_ticks.json`;
- `multi_tick_closed_loop_feedback.json`;
- `metrics.json`;
- `events.ndjson`.

Future metrics use the `multiTickClosedLoop*` prefix, and the aggregate event
is planned as `lab_multi_tick_closed_loop_recorded`.

### Invariants

The plan lists 85 future invariants covering fixed tick count, no unbounded
loop, deterministic ordering, feedback consumed only on the next tick, no
future/cross-agent feedback leak, duplicate/stale/malformed feedback handling,
v1 opt-in, v0 availability, feedback-aware reactions, tick boundaries,
approved application boundaries, no mutation, no memory/goals, no
pathfinding/replanning/avoidance/reservation/route following, artifact
writing, and repeatability.

### Out Of Scope

Out of scope remains pathfinding, replanning, avoidance, reservation runtime,
route following, terrain/world mutation, core entity movement, physical
placeholder movement, renderer/resources/shaders, save/load, registries,
goldens, mining/construction/inventory, physics, learning/RL, LLM/Python,
social/communication, and autonomous gameplay loops beyond fixed smoke ticks.

### Validation Commands

- `git status`
- verify no Swift files changed
- `swift build`
- `swift run -c release pebsmoke`
- `git diff --check`
- `git status`

### Results

- Plan document created.
- CHANGELOG updated.
- DEV_JOURNAL updated.
- ROADMAP updated.
- Feedback-aware intent policy plan cross-linked.
- No Swift files modified.
- Validation commands pass.

### Next Step

Phase 4.24B — Multi-Tick Closed Loop Fixture Smoke.

## 2026-06-29 — Phase 4.24B multi-tick closed loop fixture smoke

### Objective

Implement the first fixture-only closed loop over multiple ticks:
`feedback-aware intent -> fixture tick -> feedback -> next tick feedback
context -> feedback-aware intent`.

### Starting Point

Phase 4.24A documented the bounded closed-loop contract after 4.23 validated
single-tick feedback-aware intent through approved application. The current
validated runtime pieces were single-tick and manually orchestrated; no
autonomous multi-tick loop existed.

### Files Created/Modified

- `Sources/PebbleLab/LabAgentIntentProduction.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`
- `docs/pebblelab/PHASE_4_MULTI_TICK_CLOSED_LOOP_PLAN.md`

### Why Fixture-Only

The first closed-loop smoke validates causality and handoff semantics without
live collision, World access, movement application, route following, or
terrain mutation. It proves the loop wiring before introducing read-only live
collision or approved application variants.

### Loop Contract

The scenario `multi_tick_closed_loop_fixture_smoke` runs exactly three ticks
with four synthetic agents. It keeps positions fixed and stores only the
feedback emitted by tick `N` for consumption at tick `N+1`.

Tick `0` starts without feedback. `agent_0_winner` and `agent_1_loser` both
target `(1,64,0)`, so the fixture tick approves the stable `agent_0_winner`
and denies `agent_1_loser` with `blockedByAgentConflict`. `agent_2_free` is
approved and `agent_3_idle` remains `noIntent`.

Tick `1` consumes only tick `0` feedback. The losing agent now has
`blockedByAgentConflict`, so opt-in v1 converts it to `noIntent`; the conflict
is reduced and the tick approves the remaining two movement intents.

Tick `2` consumes only tick `1` feedback. Because the loop is memoryless beyond
the previous feedback ledger, `agent_1_loser` has no tick `1` feedback and
returns to baseline movement, recreating the same-destination conflict.

### Feedback Carryover

The report records `feedbackConsumedTotal = 5`,
`feedbackCarriedToNextTickTotal = 8`, `sameTickFeedbackConsumedTotal = 0`,
`crossAgentFeedbackLeaksTotal = 0`, and `futureFeedbackConsumedTotal = 0`.
This confirms that feedback emitted at tick `N` is never consumed in the same
tick or leaked to another agent.

### Outputs, Invariants, Metrics, Event

The scenario writes:

- `multi_tick_closed_loop_report.json`
- `multi_tick_closed_loop_invariant_report.json`
- `multi_tick_closed_loop_ticks.json`
- `multi_tick_closed_loop_feedback.json`
- `metrics.json`
- `events.ndjson`

The invariant report passes 87 checks, including fixed tick count, deterministic
tick and agent ordering, previous-tick-only feedback consumption, conflict
reduction at tick `1`, memoryless return to conflict at tick `2`, fixture tick
no-collision behavior, no movement application, and no mutation.

Metrics use the `multiTickClosedLoop*` prefix, and the event is the aggregate
`lab_multi_tick_closed_loop_recorded`.

### Boundary Confirmation

The implementation does not use World, read live collision, apply movement,
consume same-tick feedback, update memory, change goals, pathfind, replan,
avoid, use reservation runtime, use route following, perform physics, or mutate
terrain/world.

### Validation Commands

- `git status`
- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario multi_tick_closed_loop_fixture_smoke --seed 42 --ticks 3 --out runs/check_multi_tick_closed_loop_fixture`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_to_tick_approved_application_smoke --seed 42 --ticks 5 --out runs/check_feedback_aware_approved_application_after_multi_tick_fixture`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_to_tick_live_readonly_smoke --seed 42 --ticks 5 --out runs/check_feedback_aware_live_readonly_after_multi_tick_fixture`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_to_tick_fixture_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_intent_to_tick_fixture_after_multi_tick_fixture`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_policy_hardening_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_policy_hardening_after_multi_tick_fixture`
- `swift run -c release PebbleLab -- --scenario feedback_to_agent_intent_context_hardening_smoke --seed 42 --ticks 0 --out runs/check_feedback_to_context_hardening_after_multi_tick_fixture`
- `swift run -c release PebbleLab -- --scenario agent_intent_production_fixture_smoke --seed 42 --ticks 0 --out runs/check_agent_intent_fixture_after_multi_tick_fixture`
- `swift run -c release PebbleLab -- --scenario agent_intent_to_tick_fixture_smoke --seed 42 --ticks 0 --out runs/check_agent_intent_to_tick_fixture_after_multi_tick_fixture`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_multi_tick_fixture`
- `swift run -c release pebsmoke`
- `git diff --check`

### Results

- `swift build` passed.
- `swift build -c release --product Pebble` passed.
- `multi_tick_closed_loop_fixture_smoke` passed.
- Report success true.
- Invariant report success true with 87 passed, 0 failed.
- Outputs, metrics, and event were written.
- Listed non-regressions passed.
- `swift run -c release pebsmoke` passed with 456 passed, 0 failed.
- `git diff --check` passed.

### Next Step

Phase 4.24C — Multi-Tick Closed Loop Hardening.

## 2026-06-29 — Phase 4.24C multi-tick closed loop hardening

### Objective

Add a fixture-only hardening scenario for the bounded multi-tick closed loop:
`multi_tick_closed_loop_hardening_smoke`.

### Starting Point

Phase 4.24B validated a three-tick fixture loop where feedback emitted by tick
`N` is consumed only at tick `N+1`, injected into opt-in feedback-aware v1
contexts, filtered before the fixture tick, and emitted again as structured
feedback. The loop stayed memoryless, deterministic, and fixture-only.

### Files Created/Modified

- `Sources/PebbleLab/LabAgentIntentProduction.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`
- `docs/pebblelab/PHASE_4_MULTI_TICK_CLOSED_LOOP_PLAN.md`

### Why Hardening

The fixture loop needs explicit guardrails before any live read-only or
approved application closed-loop variant. 4.24C keeps the loop synthetic and
exercises bad feedback timing, duplicate feedback, malformed feedback,
cross-agent leak attempts, unknown agents, missing feedback, repeatability,
and tick bounds without adding autonomy.

### Hardening Cases

The scenario covers 13 cases:

- `baseline_memoryless_fixture_loop`;
- `missing_feedback_allowed`;
- `duplicate_feedback_same_agent_same_tick`;
- `stale_feedback_ignored`;
- `future_feedback_ignored`;
- `same_tick_feedback_ignored`;
- `cross_agent_feedback_ignored`;
- `unknown_agent_feedback_ignored`;
- `malformed_feedback_ignored`;
- `blocked_feedback_only_affects_owner`;
- `all_agents_missing_feedback_stays_baseline`;
- `repeatability_stable_ordering`;
- `max_tick_bound_enforced`.

### Feedback Policy

Feedback candidates are sorted deterministically by tick, target agent, source
agent, kind, and reason. A candidate is eligible only when it targets a known
agent, carries a well-formed feedback value, belongs to the same agent, and
comes from exactly the previous tick. Duplicate eligible candidates for the
same target and source tick are deduped deterministically. Missing feedback is
allowed and keeps baseline behavior.

Stale, future, same-tick, cross-agent, unknown-agent, and malformed feedback
are ignored and counted. Same-tick and future feedback are never consumed.
Cross-agent leak attempts are counted but never injected.

### Outputs, Invariants, Metrics, Event

The scenario writes:

- `multi_tick_closed_loop_hardening_report.json`;
- `multi_tick_closed_loop_hardening_invariant_report.json`;
- `multi_tick_closed_loop_hardening_cases.json`;
- `multi_tick_closed_loop_hardening_feedback.json`;
- `metrics.json`;
- `events.ndjson`.

Metrics use the `multiTickClosedLoopHardening*` prefix. The scenario emits one
aggregate `lab_multi_tick_closed_loop_hardening_recorded` event and no
per-feedback/per-case event stream.

The invariant report validates case existence, deterministic ordering,
previous-tick-only consumption, duplicate dedupe, stale/future/same-tick
ignores, cross-agent leak prevention, unknown/malformed ignores, owner-only
blocked feedback behavior, repeatability, fixture tick arbitration, and output
writing.

### Boundary Confirmation

The hardening scenario does not use World, read collision, apply movement,
update memory, change goals, pathfind, replan, avoid, use reservation runtime,
use route following, perform physics, or mutate terrain/world. v1 remains
opt-in and v0 remains available.

### Validation Commands

- `git status`
- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario multi_tick_closed_loop_hardening_smoke --seed 42 --ticks 3 --out runs/check_multi_tick_closed_loop_hardening`
- `swift run -c release PebbleLab -- --scenario multi_tick_closed_loop_fixture_smoke --seed 42 --ticks 3 --out runs/check_multi_tick_closed_loop_fixture_after_hardening`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_to_tick_approved_application_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_approved_application_after_multi_tick_hardening`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_to_tick_live_readonly_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_live_readonly_after_multi_tick_hardening`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_to_tick_fixture_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_intent_to_tick_fixture_after_multi_tick_hardening`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_policy_hardening_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_policy_hardening_after_multi_tick_hardening`
- `swift run -c release PebbleLab -- --scenario feedback_to_agent_intent_context_hardening_smoke --seed 42 --ticks 0 --out runs/check_feedback_to_context_hardening_after_multi_tick_hardening`
- `swift run -c release PebbleLab -- --scenario agent_intent_production_fixture_smoke --seed 42 --ticks 0 --out runs/check_agent_intent_fixture_after_multi_tick_hardening`
- `swift run -c release PebbleLab -- --scenario agent_intent_to_tick_fixture_smoke --seed 42 --ticks 0 --out runs/check_agent_intent_to_tick_fixture_after_multi_tick_hardening`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_multi_tick_hardening`
- `swift run -c release pebsmoke`
- `git diff --check`

### Results

- `swift build` passed.
- `multi_tick_closed_loop_hardening_smoke` passed in the initial check with
  13 cases, 13 passed, 0 failed.
- Report success true.
- Invariant report success true.
- Outputs, metrics, and aggregate event were written.
- `swift build -c release --product Pebble` passed.
- Listed non-regressions passed.
- `swift run -c release pebsmoke` passed with 456 passed, 0 failed.
- `git diff --check` passed.

### Next Step

Phase 4.24D — Multi-Tick Closed Loop Live Read-Only Smoke.

## 2026-06-29 — Phase 4.24D multi-tick closed loop live read-only

### Objective

Add the first live read-only multi-tick closed loop scenario:
`multi_tick_closed_loop_live_readonly_smoke`.

### Starting Point

Phase 4.24B validated the first bounded fixture-only three-tick loop, and
Phase 4.24C hardened previous-tick-only feedback consumption against stale,
future, same-tick, duplicate, malformed, unknown-agent, and cross-agent
feedback. Neither phase used World or live collision.

### Files Created/Modified

- `Sources/PebbleLab/LabAgentIntentProduction.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`
- `docs/pebblelab/PHASE_4_MULTI_TICK_CLOSED_LOOP_PLAN.md`

### Why Live Read-Only

The closed loop needs to prove that live collision feedback can be emitted by
the tick layer and consumed by the next policy tick without giving the policy
direct collision or World access. This phase keeps the tick live read-only,
does not apply movement, and does not update lab position maps.

### Fixed Three Ticks And Agents

The smoke executes exactly three ticks over five agents:

- `agent_0_winner`: baseline east move, stable winner for same-destination
  conflict;
- `agent_1_loser`: baseline west move to the same destination, receives
  `blockedByAgentConflict`;
- `agent_2_free`: live read-only occupable south move;
- `agent_3_collision`: live read-only non-occupable east move, receives
  `blockedByCollision`;
- `agent_4_idle`: baseline `noIntent` missing-feedback control.

### Feedback Carryover

Feedback emitted at tick `N` is consumed only at tick `N+1`.

- Tick `0`: consumes no feedback, emits four feedback records.
- Tick `1`: consumes only tick `0` feedback; `agent_1_loser` and
  `agent_3_collision` become `noIntent` and are filtered before tick input.
- Tick `2`: consumes only tick `1` feedback; agents without tick `1` feedback
  return to baseline, documenting memoryless previous-tick-only behavior.

There is no same-tick feedback consumption, no future feedback consumption,
and no cross-agent feedback leak.

### Conflict And Collision Feedback

At tick `0`, `agent_1_loser` gets `blockedByAgentConflict` and
`agent_3_collision` gets `blockedByCollision`. At tick `1`, both feedback
kinds are visible only to their owning agents and v1 converts both agents to
`noIntent`. The tick therefore receives two movement intents instead of four,
and both conflict and collision are reduced for that tick.

### Tick Read-Only Boundary

The feedback-aware policy does not read collision or World. The tick layer
reads live collision/World in read-only mode only for accepted movement
intents that survive `noIntent` filtering. No movement is applied and no lab
position maps, terrain, or World state are mutated.

### Outputs, Invariants, Metrics, Event

The scenario writes:

- `multi_tick_closed_loop_live_readonly_report.json`;
- `multi_tick_closed_loop_live_readonly_invariant_report.json`;
- `multi_tick_closed_loop_live_readonly_ticks.json`;
- `multi_tick_closed_loop_live_readonly_feedback.json`;
- `metrics.json`;
- `events.ndjson`.

Metrics use the `multiTickClosedLoopLiveReadonly*` prefix, and the event is
the aggregate `lab_multi_tick_closed_loop_live_readonly_recorded`.

The invariant report validates 96 checks, including fixed tick count,
deterministic ordering, previous-tick-only feedback consumption, no
same-tick/future/cross-agent feedback consumption, conflict feedback carryover,
collision feedback carryover, tick `1` reduction, tick `2` memoryless behavior,
policy no collision/World access, tick read-only collision/World access, no
movement, and artifact writing.

### Boundary Confirmation

The implementation does not apply movement, update memory, change goals,
pathfind, replan, avoid, use reservation runtime, use route following, perform
physics, use learning/LLM/RL/Python, use social/communication behavior, or
mutate terrain/World. v1 remains opt-in and v0 remains available.

### Validation Commands

- `git status`
- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario multi_tick_closed_loop_live_readonly_smoke --seed 42 --ticks 3 --out runs/check_multi_tick_closed_loop_live_readonly`
- `swift run -c release PebbleLab -- --scenario multi_tick_closed_loop_hardening_smoke --seed 42 --ticks 3 --out runs/check_multi_tick_closed_loop_hardening_after_live_readonly`
- `swift run -c release PebbleLab -- --scenario multi_tick_closed_loop_fixture_smoke --seed 42 --ticks 3 --out runs/check_multi_tick_closed_loop_fixture_after_live_readonly`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_to_tick_approved_application_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_approved_application_after_multi_tick_live_readonly`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_to_tick_live_readonly_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_live_readonly_after_multi_tick_live_readonly`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_to_tick_fixture_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_intent_to_tick_fixture_after_multi_tick_live_readonly`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_policy_hardening_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_policy_hardening_after_multi_tick_live_readonly`
- `swift run -c release PebbleLab -- --scenario feedback_to_agent_intent_context_hardening_smoke --seed 42 --ticks 0 --out runs/check_feedback_to_context_hardening_after_multi_tick_live_readonly`
- `swift run -c release PebbleLab -- --scenario agent_intent_production_fixture_smoke --seed 42 --ticks 0 --out runs/check_agent_intent_fixture_after_multi_tick_live_readonly`
- `swift run -c release PebbleLab -- --scenario agent_intent_to_tick_live_readonly_smoke --seed 42 --ticks 0 --out runs/check_agent_intent_to_tick_live_readonly_after_multi_tick_live_readonly`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_multi_tick_live_readonly`
- `swift run -c release pebsmoke`
- `git diff --check`

### Results

- `swift build` passed.
- `multi_tick_closed_loop_live_readonly_smoke` passed with report success true.
- Invariant report success true with 96 passed, 0 failed.
- Tick `1` reduced both same-destination conflict and collision by consuming
  tick `0` feedback.
- Outputs, metrics, and aggregate event were written.
- Listed non-regressions passed.
- `swift build -c release --product Pebble` passed.
- `swift run -c release pebsmoke` passed with 456 passed, 0 failed.
- `git diff --check` passed.

### Next Step

Phase 4.24E — Multi-Tick Closed Loop Approved Application Smoke.

## 2026-06-29 — Phase 4.24E multi-tick closed loop approved application

### Objective

Add the first approved-application variant of the bounded multi-tick closed
loop. The scenario proves that feedback-aware v1 proposals can flow through a
live read-only tick, apply only approved movement to lab abstract/physical
position maps, carry feedback to the next tick, and keep denied and `noIntent`
agents preserved.

### Starting Point

Phase 4.24D validated the three-tick live read-only loop: feedback from tick
`N` is consumed only at tick `N+1`, the policy never reads collision or World,
and the tick layer can read collision evidence without applying movement.
Phase 4.23E had already validated single-tick approved application for
feedback-aware intent handoff.

### Files Created Or Modified

- `Sources/PebbleLab/LabAgentIntentProduction.swift`
- `Sources/PebbleLab/LabMultiTickClosedLoopApprovedApplication.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`
- `docs/pebblelab/PHASE_4_MULTI_TICK_CLOSED_LOOP_PLAN.md`

### Why Approved Application

The closed loop needs one more proof before larger loop planning: approved
tick outputs can update the lab position maps across ticks, and the next
tick's agent contexts are built from those updated positions. This remains a
lab-only application boundary. It does not move physical placeholders, core
entities, terrain, or World state.

### Fixed Three-Tick Loop

The scenario `multi_tick_closed_loop_approved_application_smoke` runs exactly
three ticks over five agents:

- `agent_0_winner`: participates in a same-destination conflict and wins by
  stable agent id when the conflict exists;
- `agent_1_loser`: loses the same-destination conflict and receives
  `blockedByAgentConflict`;
- `agent_2_free`: receives approved movement and demonstrates map updates
  across ticks;
- `agent_3_collision`: targets a non-occupable destination and receives
  `blockedByCollision`;
- `agent_4_idle`: remains a `noIntent` preservation control.

Tick `0` starts without feedback and emits both conflict and collision
feedback. Tick `1` consumes only tick `0` feedback, converts the blocked agents
to `noIntent`, and applies only approved lab-map movements. Tick `2` consumes
only tick `1` feedback, showing memoryless previous-tick-only behavior while
continuing approved map application.

### Feedback Carryover And Causality

Feedback emitted at tick `N` is available only to tick `N+1`. The scenario
records zero same-tick feedback consumption, zero future feedback consumption,
and zero cross-agent feedback leaks. Feedback is keyed by stable `agentId`,
and only the owning agent receives its prior tick feedback.

### Conflict And Collision

The policy does not arbitrate same-destination conflicts and does not inspect
occupancy. Remaining conflicts are handled by the tick layer. The tick layer
also reads collision/World in read-only mode only for accepted movement intents
that survive `noIntent` filtering.

### Approved Application Result

Approved tick outputs update both lab abstract and physical position maps.
Denied agents and `noIntent` agents are preserved. The validated totals are:

- `requestedTicks = 3`;
- `executedTicks = 3`;
- `agents = 5`;
- `contextsTotal = 15`;
- `contextsWithFeedbackTotal = 6`;
- `contextsWithoutFeedbackTotal = 9`;
- `movementIntentInputsTotal = 10`;
- `tickApprovedTotal = 6`;
- `tickDeniedTotal = 4`;
- `tickDeniedConflictTotal = 2`;
- `tickDeniedCollisionTotal = 2`;
- `tickFeedbackEmittedTotal = 10`;
- `feedbackConsumedTotal = 6`;
- `feedbackCarriedToNextTickTotal = 10`;
- `approvedApplicationsTotal = 6`;
- `approvedAgentsMovedTotal = 6`;
- `deniedAgentsPreservedTotal = 4`;
- `noIntentAgentsPreservedTotal = 5`;
- `displacementsAppliedTotal = 6`;
- `abstractPositionsChangedTotal = 6`;
- `physicalPositionsChangedTotal = 6`;
- `abstractPhysicalDivergenceBeforeMax = 0`;
- `abstractPhysicalDivergenceAfterMax = 0`.

### Outputs, Invariants, Metrics, Event

The scenario writes:

- `multi_tick_closed_loop_approved_application_report.json`;
- `multi_tick_closed_loop_approved_application_invariant_report.json`;
- `multi_tick_closed_loop_approved_application_ticks.json`;
- `multi_tick_closed_loop_approved_application_feedback.json`;
- `metrics.json`;
- `events.ndjson`.

Metrics use the `multiTickClosedLoopApprovedApplication*` prefix, and the
aggregate event is `lab_multi_tick_closed_loop_approved_application_recorded`.
The invariant report validates 90 checks covering fixed tick count, updated
positions in later contexts, feedback carryover, no same-tick/future/cross-agent
feedback consumption, conflict and collision feedback, approved-only lab map
movement, denied/noIntent preservation, zero divergence, policy no
collision/World access, tick read-only collision/World access, and artifact
writing.

### Boundary Confirmation

The phase keeps v1 opt-in and leaves v0 unchanged. It does not perform
pathfinding, replanning, avoidance, reservation runtime, route following,
physics, learning, LLM/RL/Python integration, memory updates, goal changes,
physical placeholder movement, core entity movement, terrain mutation, or World
mutation.

### Validation Commands

- `git status`
- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario multi_tick_closed_loop_approved_application_smoke --seed 42 --ticks 3 --out runs/check_multi_tick_closed_loop_approved_application`
- `swift run -c release PebbleLab -- --scenario multi_tick_closed_loop_live_readonly_smoke --seed 42 --ticks 3 --out runs/check_multi_tick_closed_loop_live_readonly_after_approved_application`
- `swift run -c release PebbleLab -- --scenario multi_tick_closed_loop_hardening_smoke --seed 42 --ticks 3 --out runs/check_multi_tick_closed_loop_hardening_after_approved_application`
- `swift run -c release PebbleLab -- --scenario multi_tick_closed_loop_fixture_smoke --seed 42 --ticks 3 --out runs/check_multi_tick_closed_loop_fixture_after_approved_application`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_to_tick_approved_application_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_approved_application_after_multi_tick_approved_application`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_to_tick_live_readonly_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_live_readonly_after_multi_tick_approved_application`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_to_tick_fixture_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_intent_to_tick_fixture_after_multi_tick_approved_application`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_policy_hardening_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_policy_hardening_after_multi_tick_approved_application`
- `swift run -c release PebbleLab -- --scenario feedback_to_agent_intent_context_hardening_smoke --seed 42 --ticks 0 --out runs/check_feedback_to_context_hardening_after_multi_tick_approved_application`
- `swift run -c release PebbleLab -- --scenario agent_intent_production_fixture_smoke --seed 42 --ticks 0 --out runs/check_agent_intent_fixture_after_multi_tick_approved_application`
- `swift run -c release PebbleLab -- --scenario agent_intent_to_tick_approved_application_smoke --seed 42 --ticks 0 --out runs/check_agent_intent_to_tick_approved_application_after_multi_tick_approved_application`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_multi_tick_approved_application`
- `swift run -c release pebsmoke`
- `git diff --check`

### Results

- `swift build` passed.
- `swift build -c release --product Pebble` passed.
- `multi_tick_closed_loop_approved_application_smoke` passed with report
  success true.
- Invariant report success true with 90 passed, 0 failed.
- Outputs, metrics, and aggregate event were written.
- Listed non-regressions passed.
- `swift run -c release pebsmoke` passed with 456 passed, 0 failed.
- `git diff --check` passed.

### Next Step

Phase 4.25A — Deterministic Bounded Alternate Local Hint Planning Docs-Only.

## 2026-06-29 — Phase 4.25A deterministic bounded alternate local hint planning docs-only

### Objective

Create a docs-only plan for deterministic bounded alternate local hints before
adding any implementation. The plan defines how future PebbleLab phases may
move from `blockedBy* -> noIntent` to a tiny opt-in local alternate hint rule
without becoming pathfinding, replanning, avoidance, reservation runtime,
memory, goals, or gameplay autonomy.

### Starting Point

Phase 4.23 introduced feedback-aware v1 as an opt-in policy while leaving v0
unchanged. Phase 4.24 validated a bounded three-tick closed loop through
fixture, hardening, live read-only, and approved application variants. Feedback
from tick `N` is consumed only at tick `N+1`; same-tick, future, and cross-agent
feedback leaks are rejected; tick handles arbitration and collision; approved
application updates only lab maps.

### Why Docs-Only

Alternate local hints are close enough to pathfinding and replanning that the
boundary needs to be locked before code exists. The phase therefore adds no
Swift, no scenarios, no runner behavior, no runtime metrics, and no events.

### New Document

Created `docs/pebblelab/PHASE_4_ALTERNATE_LOCAL_HINT_PLAN.md`.

### Boundary

Allowed future behavior is deliberately small: given previous-tick blocked
feedback, produce at most a fixed small number of deterministic one-edge local
hint candidates from a fixed table, then pass the selected hint through the
normal intent/tick pipeline. The policy must not read World, read collision,
inspect other agents directly, reserve cells, mutate memory/goals, or apply
movement.

### Non-Goals

The plan explicitly states that alternate local hints are not pathfinding,
replanning, avoidance, reservation runtime, long route following, gameplay
autonomy, learning, social behavior, LLM/RL/Python, World mutation, or terrain
mutation.

### Proposed Deterministic Rule

For blocked feedback, future v2 may read the original local hint, exclude the
failed direction, and choose from a fixed ordered table:

- failed `move_east` or `move_west` -> `[move_north, move_south]`;
- failed `move_north` or `move_south` -> `[move_east, move_west]`;
- unknown or empty hint -> no alternate.

The table does not read World, collision, terrain, other agents, or longer
routes. Tick remains responsible for final arbitration and collision denial.

### v2 Recommendation

The plan compares a pre-policy hint adapter with an explicit opt-in v2 policy.
It recommends future `produceAgentIntentProposalFeedbackAwareV2` because v0 and
v1 remain unchanged, behavior changes are visible in reports, and policy mode
can be asserted in invariants.

### Future Phases

- Phase 4.25B — Alternate Local Hint Fixture Smoke;
- Phase 4.25C — Alternate Local Hint Hardening;
- Phase 4.25D — Alternate Local Hint Live Read-Only Smoke;
- Phase 4.25E — Alternate Local Hint Approved Application Smoke;
- Phase 4.25F — Alternate Local Hint Multi-Tick Regression/Replay.

### Reports, Metrics, Event

Future outputs are planned as `alternate_local_hint_report.json`,
`alternate_local_hint_invariant_report.json`,
`alternate_local_hint_handoff.json`,
`alternate_local_hint_decisions.json`, `metrics.json`, and `events.ndjson`.
Metrics use the `alternateLocalHint*` prefix. The future aggregate event is
`lab_alternate_local_hint_recorded`.

### Invariants

The plan lists 82 future invariants covering v0/v1 stability, v2 opt-in,
bounded max alternates, deterministic candidate ordering, duplicate removal,
failed-direction exclusion, unknown/empty hint handling, one-edge local hints,
no route/search/pathfinding/replanning/avoidance/reservation, no policy
World/collision reads, tick-owned arbitration/collision, approved application
lab-map-only behavior, no terrain/World mutation, deterministic reports,
metrics, events, repeatability, and compatibility with 4.24B-E.

### Risk Table

The risk table covers alternate hints becoming pathfinding or replanning,
policy World/collision reads, unbounded candidates, route following,
reservation runtime, memory/goals mutation, v2 replacing v1 globally, v1
behavior drift, hidden blocked feedback, nondeterministic ordering, oscillation,
approved application drifting into gameplay movement, accidental live mutation,
and metrics hiding boundary violations.

### Out Of Scope

Pathfinding, replanning, avoidance, reservation runtime, route following,
multi-step routes, terrain/world mutation, core entity movement, physical
placeholder movement, renderer/resources/shaders, save/load, registries,
goldens, mining/construction/inventory, physics, learning/RL, LLM/Python,
social/communication, and autonomous gameplay loops remain out of scope.

### Validation Commands

- `git status`
- verify no Swift files changed
- `swift build`
- `swift run -c release pebsmoke`
- `git diff --check`
- `git status`

### Results

- Plan document created.
- CHANGELOG, DEV_JOURNAL, ROADMAP, and multi-tick plan cross-link updated.
- No Swift files modified.
- `swift build` passed.
- `swift run -c release pebsmoke` passed with 456 passed, 0 failed.
- `git diff --check` passed.

### Next Step

Phase 4.25B — Alternate Local Hint Fixture Smoke.

## 2026-06-30 — Phase 4.25B alternate local hint fixture smoke

### Objective

Implement the first fixture-only proof for deterministic bounded alternate
local hints. The phase adds an explicit opt-in v2 policy path while preserving
`produceAgentIntentProposalV0` and `produceAgentIntentProposalFeedbackAwareV1`.

### Starting Point

Phase 4.25A documented the alternate local hint boundary. Phase 4.24 had
validated multi-tick feedback flow through approved application, with blocked
feedback currently becoming `noIntent` in v1. This phase keeps the policy
World/collision boundary intact and exercises only a single fixture tick.

### Files Created/Modified

- Created `Sources/PebbleLab/LabAgentAlternateLocalHint.swift`.
- Updated `Sources/PebbleLab/LabOptions.swift`, `LabScenarios.swift`,
  `LabOutput.swift`, `LabEvents.swift`, and `main.swift`.
- Updated `CHANGELOG.md`, `DEV_JOURNAL.md`, `ROADMAP.md`, and
  `PHASE_4_ALTERNATE_LOCAL_HINT_PLAN.md`.

### Why Fixture-Only

The first implementation proves the local hint handoff without live collision,
World access, movement application, route following, pathfinding, replanning,
avoidance, reservation runtime, memory/goals, or terrain/world mutation.

### v2 Opt-In

The new fixture calls `produceAgentIntentProposalWithAlternateLocalHintsV2`
directly. v0 remains the baseline producer and v1 remains the blocked-feedback
to `noIntent` policy. v2 is not global and is only used by the new scenario.

### Fixture Contexts

The fixture uses six deterministic contexts:

- no feedback keeps baseline `move_east`;
- `approvedForMovement` keeps baseline `move_east`;
- blocked east feedback selects deterministic alternate `move_north`;
- blocked west feedback selects deterministic alternate `move_north`;
- blocked feedback with an empty hint becomes `noIntent`;
- blocked feedback with an unknown hint becomes `noIntent`.

### Deterministic Rule

Known failed directions use a fixed table capped at `maxAlternates = 2`:
east/west produce `[move_north, move_south]`, north/south produce
`[move_east, move_west]`. The failed direction is excluded, candidate order is
stable, and the first candidate is selected for the fixture.

### Tick Handoff

Only accepted movement proposals enter the fixture tick input. The two
`noIntent` proposals are filtered before tick. The tick fixture approves all
four movement intents, emits four feedback records, and applies zero
displacements.

### Outputs, Invariants, Metrics, Event

The scenario writes `alternate_local_hint_report.json`,
`alternate_local_hint_invariant_report.json`,
`alternate_local_hint_handoff.json`, `alternate_local_hint_decisions.json`,
`metrics.json`, and `events.ndjson`. Metrics use the `alternateLocalHint*`
prefix. The aggregate event is `lab_alternate_local_hint_recorded`.

### Boundary Confirmation

The fixture reports `policyReadCollision=false`, `policyWorldUsed=false`,
`tickReadCollision=false`, `tickWorldUsed=false`, `movementApplied=false`,
`memoryUpdated=false`, `goalChanged=false`, `pathfindingPerformed=false`,
`replanningPerformed=false`, `avoidancePerformed=false`,
`reservationRuntimeUsed=false`, `routeFollowingUsed=false`,
`worldMutated=false`, and `mutationPerformed=false`.

### Validation Commands

- `git status`
- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario alternate_local_hint_fixture_smoke --seed 42 --ticks 0 --out runs/check_alternate_local_hint_fixture`
- `swift run -c release PebbleLab -- --scenario multi_tick_closed_loop_approved_application_smoke --seed 42 --ticks 3 --out runs/check_multi_tick_approved_after_alternate_hint_fixture`
- `swift run -c release PebbleLab -- --scenario multi_tick_closed_loop_live_readonly_smoke --seed 42 --ticks 3 --out runs/check_multi_tick_live_readonly_after_alternate_hint_fixture`
- `swift run -c release PebbleLab -- --scenario multi_tick_closed_loop_hardening_smoke --seed 42 --ticks 3 --out runs/check_multi_tick_hardening_after_alternate_hint_fixture`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_to_tick_approved_application_smoke --seed 42 --ticks 5 --out runs/check_feedback_aware_approved_after_alternate_hint_fixture`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_policy_hardening_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_policy_hardening_after_alternate_hint_fixture`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_alternate_hint_fixture`
- `swift run -c release pebsmoke`
- `git diff --check`

### Results

- `swift build` passed.
- `swift build -c release --product Pebble` passed.
- `alternate_local_hint_fixture_smoke` passed with report and invariant success.
- Non-regressions passed.
- `swift run -c release pebsmoke` passed with 456 passed, 0 failed.
- `git diff --check` passed.

### Next Step

Phase 4.25C — Alternate Local Hint Hardening.

## 2026-06-30 — Phase 4.25C alternate local hint hardening

### Objective

Harden the deterministic bounded alternate local hint policy with fixture-only
cases that stress ordering, max alternate bounds, blocked feedback kinds,
empty/unknown/duplicate hints, repeatability, and tick fixture handoff.

### Starting Point

Phase 4.25B added `alternate_local_hint_fixture_smoke` with explicit opt-in v2
behavior. v0 and v1 remained unchanged, blocked east/west feedback could
produce bounded local alternatives, and the tick fixture accepted only normal
one-edge movement intents.

### Files Created/Modified

- Modified `Sources/PebbleLab/LabAgentAlternateLocalHint.swift`.
- Updated `Sources/PebbleLab/LabOptions.swift`, `LabScenarios.swift`,
  `LabOutput.swift`, `LabEvents.swift`, and `main.swift`.
- Updated `CHANGELOG.md`, `DEV_JOURNAL.md`, `ROADMAP.md`, and
  `PHASE_4_ALTERNATE_LOCAL_HINT_PLAN.md`.

### Why Hardening

The fixture smoke proved the happy path. This phase makes the v2 boundary
harder to accidentally widen: no global v0/v1 replacement, no route following,
no pathfinding, no replanning, no avoidance, no reservation runtime, no live
collision, no World, and no movement application.

### Cases

The hardening smoke validates 22 deterministic cases:

- baseline no-feedback, approved feedback, and moved feedback;
- blocked collision, agent conflict, source mismatch, divergence, stale intent,
  invalid edge, and max agents feedback;
- `maxAlternates` 0, 1, 2, and 3;
- empty and unknown hints;
- duplicate hint handling;
- multiple hint handling using the first attempted hint;
- repeatability with identical signatures across repeated runs;
- tick handoff with all distinct approved fixture intents;
- no-intent filtering before tick;
- stable ordering after shuffled inputs;
- failed-direction exclusion for all cardinal directions.

### Policy

v2 remains explicit opt-in through
`produceAgentIntentProposalWithAlternateLocalHintsV2`. v0 and v1 stay
available and unchanged. Candidate generation uses a fixed ordered table,
excludes the failed direction, caps candidates by `maxAlternates`, and selects
the first candidate when one is available.

### Outputs, Invariants, Metrics, Event

The scenario writes `alternate_local_hint_hardening_report.json`,
`alternate_local_hint_hardening_invariant_report.json`,
`alternate_local_hint_hardening_cases.json`,
`alternate_local_hint_hardening_decisions.json`,
`alternate_local_hint_hardening_handoff.json`, `metrics.json`, and
`events.ndjson`. Metrics use `alternateLocalHintHardening*`; the aggregate
event is `lab_alternate_local_hint_hardening_recorded`.

### Boundary Confirmation

The report confirms `policyReadCollision=false`, `policyWorldUsed=false`,
`tickReadCollision=false`, `tickWorldUsed=false`, `movementApplied=false`,
`memoryUpdated=false`, `goalChanged=false`, `pathfindingPerformed=false`,
`replanningPerformed=false`, `avoidancePerformed=false`,
`reservationRuntimeUsed=false`, `routeFollowingUsed=false`,
`worldMutated=false`, and `mutationPerformed=false`.

### Validation Commands

- `git status`
- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario alternate_local_hint_hardening_smoke --seed 42 --ticks 0 --out runs/check_alternate_local_hint_hardening`
- `swift run -c release PebbleLab -- --scenario alternate_local_hint_fixture_smoke --seed 42 --ticks 0 --out runs/check_alternate_local_hint_fixture_after_hardening`
- `swift run -c release PebbleLab -- --scenario multi_tick_closed_loop_approved_application_smoke --seed 42 --ticks 3 --out runs/check_multi_tick_approved_after_alternate_hint_hardening`
- `swift run -c release PebbleLab -- --scenario multi_tick_closed_loop_live_readonly_smoke --seed 42 --ticks 3 --out runs/check_multi_tick_live_readonly_after_alternate_hint_hardening`
- `swift run -c release PebbleLab -- --scenario multi_tick_closed_loop_hardening_smoke --seed 42 --ticks 3 --out runs/check_multi_tick_hardening_after_alternate_hint_hardening`
- `swift run -c release PebbleLab -- --scenario multi_tick_closed_loop_fixture_smoke --seed 42 --ticks 3 --out runs/check_multi_tick_fixture_after_alternate_hint_hardening`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_to_tick_approved_application_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_approved_after_alternate_hint_hardening`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_to_tick_live_readonly_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_live_readonly_after_alternate_hint_hardening`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_to_tick_fixture_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_intent_to_tick_fixture_after_alternate_hint_hardening`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_policy_hardening_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_policy_hardening_after_alternate_hint_hardening`
- `swift run -c release PebbleLab -- --scenario feedback_to_agent_intent_context_hardening_smoke --seed 42 --ticks 0 --out runs/check_feedback_to_context_hardening_after_alternate_hint_hardening`
- `swift run -c release PebbleLab -- --scenario agent_intent_production_fixture_smoke --seed 42 --ticks 0 --out runs/check_agent_intent_fixture_after_alternate_hint_hardening`
- `swift run -c release PebbleLab -- --scenario agent_intent_to_tick_fixture_smoke --seed 42 --ticks 0 --out runs/check_agent_intent_to_tick_fixture_after_alternate_hint_hardening`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_alternate_hint_hardening`
- `swift run -c release pebsmoke`
- `git diff --check`

### Results

- `swift build` passed.
- `alternate_local_hint_hardening_smoke` passed with 22 cases, 22 passed, 0
  failed.
- Hardening report and invariant report both reported `success=true`.
- Metrics and event were written with the expected hardening prefix/type.

### Next Step

Phase 4.25D — Alternate Local Hint Live Read-Only Smoke.

## 2026-06-30 — Phase 4.25D alternate local hint live read-only

### Objective

Connect the opt-in deterministic bounded alternate local hint v2 policy to the
tick live read-only collision contract without applying movement.

### Starting Point

Phase 4.25B introduced `alternate_local_hint_fixture_smoke`; Phase 4.25C
hardened v2 with 22 fixture-only cases. v0 and v1 remained unchanged, v2 stayed
explicit opt-in, known blocked feedback could produce bounded one-edge
alternates, and empty/unknown hints remained `noIntent`.

### Files Created/Modified

- Modified `Sources/PebbleLab/LabAgentAlternateLocalHint.swift`.
- Updated `Sources/PebbleLab/LabOptions.swift`, `LabScenarios.swift`,
  `LabOutput.swift`, `LabEvents.swift`, and `main.swift`.
- Updated `CHANGELOG.md`, `DEV_JOURNAL.md`, `ROADMAP.md`, and
  `PHASE_4_ALTERNATE_LOCAL_HINT_PLAN.md`.

### Why Live Read-Only

The fixture and hardening phases proved candidate generation and fixture tick
handoff. This phase proves the boundary with live collision evidence: the policy
still never reads World or collision, while the tick live read-only layer may
approve or deny the resulting movement intents.

### Policy And Contexts

The scenario uses six deliberately unordered contexts. One has no feedback and
keeps baseline, one has `approvedForMovement` and keeps baseline, two blocked
contexts select deterministic `move_north` alternates from the fixed table, one
blocked context has empty hints, and one blocked context has an unknown hint.
`maxAlternates` remains 2; four candidates are produced, two are selected, and
two noIntent proposals are filtered before tick.

### Live Read-Only Result

Four movement intents enter the tick live read-only contract. The tick approves
three occupable destinations and denies one non-occupable alternate with
`deniedCollision`. `tickReadCollision=true` and `tickWorldReadOnlyUsed=true`;
`policyReadCollision=false` and `policyWorldUsed=false`.

### Outputs, Invariants, Metrics, Event

The scenario writes `alternate_local_hint_live_readonly_report.json`,
`alternate_local_hint_live_readonly_invariant_report.json`,
`alternate_local_hint_live_readonly_decisions.json`,
`alternate_local_hint_live_readonly_handoff.json`, `metrics.json`, and
`events.ndjson`. Metrics use `alternateLocalHintLiveReadonly*`; the aggregate
event is `lab_alternate_local_hint_live_readonly_recorded`. The invariant report
records 75 checks passed and 0 failed.

### Boundary Confirmation

The report confirms `movementApplied=false`, `memoryUpdated=false`,
`goalChanged=false`, `pathfindingPerformed=false`, `replanningPerformed=false`,
`avoidancePerformed=false`, `reservationRuntimeUsed=false`,
`routeFollowingUsed=false`, `worldMutated=false`, and
`mutationPerformed=false`.

### Validation Commands

- `git status`
- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario alternate_local_hint_live_readonly_smoke --seed 42 --ticks 0 --out runs/check_alternate_local_hint_live_readonly`
- `swift run -c release PebbleLab -- --scenario alternate_local_hint_hardening_smoke --seed 42 --ticks 0 --out runs/check_alternate_local_hint_hardening_after_live_readonly`
- `swift run -c release PebbleLab -- --scenario alternate_local_hint_fixture_smoke --seed 42 --ticks 0 --out runs/check_alternate_local_hint_fixture_after_live_readonly`
- `swift run -c release PebbleLab -- --scenario multi_tick_closed_loop_approved_application_smoke --seed 42 --ticks 3 --out runs/check_multi_tick_closed_loop_approved_application_after_alternate_hint_live_readonly`
- `swift run -c release PebbleLab -- --scenario multi_tick_closed_loop_live_readonly_smoke --seed 42 --ticks 3 --out runs/check_multi_tick_closed_loop_live_readonly_after_alternate_hint_live_readonly`
- `swift run -c release PebbleLab -- --scenario multi_tick_closed_loop_hardening_smoke --seed 42 --ticks 3 --out runs/check_multi_tick_closed_loop_hardening_after_alternate_hint_live_readonly`
- `swift run -c release PebbleLab -- --scenario multi_tick_closed_loop_fixture_smoke --seed 42 --ticks 3 --out runs/check_multi_tick_closed_loop_fixture_after_alternate_hint_live_readonly`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_to_tick_approved_application_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_approved_application_after_alternate_hint_live_readonly`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_to_tick_live_readonly_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_live_readonly_after_alternate_hint_live_readonly`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_to_tick_fixture_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_intent_to_tick_fixture_after_alternate_hint_live_readonly`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_policy_hardening_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_policy_hardening_after_alternate_hint_live_readonly`
- `swift run -c release PebbleLab -- --scenario feedback_to_agent_intent_context_hardening_smoke --seed 42 --ticks 0 --out runs/check_feedback_to_context_hardening_after_alternate_hint_live_readonly`
- `swift run -c release PebbleLab -- --scenario agent_intent_production_fixture_smoke --seed 42 --ticks 0 --out runs/check_agent_intent_fixture_after_alternate_hint_live_readonly`
- `swift run -c release PebbleLab -- --scenario agent_intent_to_tick_live_readonly_smoke --seed 42 --ticks 0 --out runs/check_agent_intent_to_tick_live_readonly_after_alternate_hint_live_readonly`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_alternate_hint_live_readonly`
- `swift run -c release pebsmoke`
- `git diff --check`

### Results

- `swift build` passed.
- `alternate_local_hint_live_readonly_smoke` passed with report and invariant
  success.
- The smoke produced 6 contexts, 6 decisions, 4 movement intent inputs, 3 tick
  approvals, 1 tick collision denial, 3 occupable destinations, and 1
  non-occupable destination.
- Metrics and event were written with the expected live-readonly prefix/type.

### Next Step

Phase 4.25E — Alternate Local Hint Approved Application Smoke.

## 2026-06-30 — Phase 4.25E alternate local hint approved application

### Objective

Connect the explicit opt-in deterministic bounded alternate local hint v2 policy
to the tick approved application contract, applying only approved lab position
map movements while preserving denied and noIntent agents.

### Starting Point

Phase 4.25B introduced the v2 fixture handoff, Phase 4.25C hardened the v2
policy, and Phase 4.25D connected v2 movement intents to tick live read-only
collision evidence. v0 and v1 remained unchanged, v2 stayed opt-in, policy did
not read World/collision, and approved application was still out of scope.

### Files Created/Modified

- Modified `Sources/PebbleLab/LabAgentAlternateLocalHint.swift`.
- Updated `Sources/PebbleLab/LabOptions.swift`, `LabScenarios.swift`,
  `LabOutput.swift`, `LabEvents.swift`, and `main.swift`.
- Updated `CHANGELOG.md`, `DEV_JOURNAL.md`, `ROADMAP.md`, and
  `PHASE_4_ALTERNATE_LOCAL_HINT_PLAN.md`.

### Why Approved Application

The live read-only phase proved that selected alternates can be checked by the
tick collision layer. This phase proves the next boundary: tick-approved
alternate and baseline intents can update the lab abstract/physical position
maps, while collision-denied and noIntent agents remain preserved.

### Fixture Contexts And Policy

The scenario reuses six deliberately unordered alternate-hint contexts. One
agent has no feedback and keeps baseline, one has `approvedForMovement` and
keeps baseline, two blocked agents select deterministic `move_north`
alternates from the fixed table, one blocked agent has an empty hint, and one
blocked agent has an unknown hint. v0 and v1 remain unchanged; v2 is explicit
opt-in with `maxAlternates = 2`.

### Tick Approved Application Result

Four movement intents enter the approved application tick. The tick reads
collision read-only, approves three occupable destinations, denies one
non-occupable alternate by collision, applies three lab-map displacements, and
emits four feedback records. The collision-denied agent and both noIntent
agents keep their positions.

### Outputs, Invariants, Metrics, Event

The scenario writes `alternate_local_hint_approved_application_report.json`,
`alternate_local_hint_approved_application_invariant_report.json`,
`alternate_local_hint_approved_application_decisions.json`,
`alternate_local_hint_approved_application_handoff.json`,
`alternate_local_hint_approved_application_positions.json`, `metrics.json`,
and `events.ndjson`. Metrics use `alternateLocalHintApprovedApplication*`; the
aggregate event is `lab_alternate_local_hint_approved_application_recorded`.
The invariant report records 87 checks passed and 0 failed.

### Boundary Confirmation

The report confirms `policyReadCollision=false`, `policyWorldUsed=false`,
`tickReadCollision=true`, `tickWorldReadOnlyUsed=true`, `movementApplied=true`
for lab maps only, `memoryUpdated=false`, `goalChanged=false`,
`pathfindingPerformed=false`, `replanningPerformed=false`,
`avoidancePerformed=false`, `reservationRuntimeUsed=false`,
`routeFollowingUsed=false`, `worldMutated=false`, and
`mutationPerformed=false`.

### Validation Commands

- `git status`
- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario alternate_local_hint_approved_application_smoke --seed 42 --ticks 0 --out runs/check_alternate_local_hint_approved_application`
- `swift run -c release PebbleLab -- --scenario alternate_local_hint_live_readonly_smoke --seed 42 --ticks 0 --out runs/check_alternate_local_hint_live_readonly_after_approved_application`
- `swift run -c release PebbleLab -- --scenario alternate_local_hint_hardening_smoke --seed 42 --ticks 0 --out runs/check_alternate_local_hint_hardening_after_approved_application`
- `swift run -c release PebbleLab -- --scenario alternate_local_hint_fixture_smoke --seed 42 --ticks 0 --out runs/check_alternate_local_hint_fixture_after_approved_application`
- `swift run -c release PebbleLab -- --scenario multi_tick_closed_loop_approved_application_smoke --seed 42 --ticks 3 --out runs/check_multi_tick_closed_loop_approved_application_after_alternate_hint_approved_application`
- `swift run -c release PebbleLab -- --scenario multi_tick_closed_loop_live_readonly_smoke --seed 42 --ticks 3 --out runs/check_multi_tick_closed_loop_live_readonly_after_alternate_hint_approved_application`
- `swift run -c release PebbleLab -- --scenario multi_tick_closed_loop_hardening_smoke --seed 42 --ticks 3 --out runs/check_multi_tick_closed_loop_hardening_after_alternate_hint_approved_application`
- `swift run -c release PebbleLab -- --scenario multi_tick_closed_loop_fixture_smoke --seed 42 --ticks 3 --out runs/check_multi_tick_closed_loop_fixture_after_alternate_hint_approved_application`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_to_tick_approved_application_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_approved_application_after_alternate_hint_approved_application`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_to_tick_live_readonly_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_live_readonly_after_alternate_hint_approved_application`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_to_tick_fixture_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_intent_to_tick_fixture_after_alternate_hint_approved_application`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_policy_hardening_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_policy_hardening_after_alternate_hint_approved_application`
- `swift run -c release PebbleLab -- --scenario feedback_to_agent_intent_context_hardening_smoke --seed 42 --ticks 0 --out runs/check_feedback_to_context_hardening_after_alternate_hint_approved_application`
- `swift run -c release PebbleLab -- --scenario agent_intent_production_fixture_smoke --seed 42 --ticks 0 --out runs/check_agent_intent_fixture_after_alternate_hint_approved_application`
- `swift run -c release PebbleLab -- --scenario agent_intent_to_tick_approved_application_smoke --seed 42 --ticks 0 --out runs/check_agent_intent_to_tick_approved_application_after_alternate_hint_approved_application`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_alternate_hint_approved_application`
- `swift run -c release pebsmoke`
- `git diff --check`

### Results

- `swift build` passed.
- `alternate_local_hint_approved_application_smoke` passed with report and
  invariant success.
- The smoke produced 6 contexts, 6 decisions, 4 movement intent inputs, 3 tick
  approvals, 1 tick collision denial, 3 approved lab-map applications, 1 denied
  agent preserved, and 2 noIntent agents preserved.
- Metrics and event were written with the expected approved-application
  prefix/type.

### Next Step

Phase 4.25F — Alternate Local Hint Multi-Tick Regression/Replay.

## 2026-06-30 — Phase 4.25F alternate local hint multi-tick replay

### Objective

Add a deterministic multi-tick replay smoke for the explicit opt-in alternate
local hint v2 policy, proving stable feedback carryover, lab-map approved
application, replay digest repeatability, and preserved phase boundaries over
three fixed ticks.

### Starting Point

Phase 4.25E connected alternate local hint v2 decisions to tick approved
application. Approved movements updated only lab abstract/physical position
maps, denied and noIntent agents were preserved, policy did not read
World/collision, tick collision evidence stayed read-only, and no
terrain/world mutation occurred.

### Files Created/Modified

- Added `Sources/PebbleLab/LabAgentAlternateLocalHintMultiTickReplay.swift`.
- Modified `Sources/PebbleLab/LabAgentAlternateLocalHint.swift`.
- Updated `Sources/PebbleLab/LabOptions.swift`, `LabScenarios.swift`,
  `LabOutput.swift`, and `main.swift`.
- Updated `CHANGELOG.md`, `DEV_JOURNAL.md`, `ROADMAP.md`, and
  `PHASE_4_ALTERNATE_LOCAL_HINT_PLAN.md`.

### Why Multi-Tick Replay

The prior smokes validated single-tick fixture, hardening, live read-only, and
approved application behavior. This phase adds the regression/replay boundary:
feedback emitted at tick N is consumed only at tick N+1, deterministic v2
alternate decisions can repeat across ticks, and a second internal replay must
produce the same stable digest.

### Replay Fixture

The replay uses six agents over three fixed ticks:

- `agent_0_no_feedback_baseline_occupable`;
- `agent_1_approved_feedback_baseline_occupable`;
- `agent_2_blocked_east_alternate_occupable`;
- `agent_3_blocked_west_alternate_collision`;
- `agent_4_blocked_empty_hint_no_alternate`;
- `agent_5_blocked_unknown_hint_no_alternate`.

The initial tick has no feedback for agent 0, approved feedback for agent 1,
blocked feedback with known hints for agents 2 and 3, and blocked feedback with
empty/unknown hints for agents 4 and 5. Subsequent ticks consume only feedback
emitted by the previous tick.

### Replay And Digest Policy

The scenario runs the same deterministic replay twice. The digest includes
tick order, agent order, selected hints, movement intents, noIntent agents,
approved/denied agents, consumed/emitted feedback, positions, and tick
summaries. The replay succeeds only when both digests are identical.

### Feedback Carryover And Leak Checks

The report verifies:

- `sameTickFeedbackConsumedTotal = 0`;
- `futureFeedbackConsumedTotal = 0`;
- `crossAgentFeedbackLeaksTotal = 0`;
- tick 0 feedback is consumed at tick 1;
- tick 1 feedback is consumed at tick 2.

### Outputs, Invariants, Metrics, Event

The scenario writes `alternate_local_hint_multi_tick_replay_report.json`,
`alternate_local_hint_multi_tick_replay_invariant_report.json`,
`alternate_local_hint_multi_tick_replay_ticks.json`,
`alternate_local_hint_multi_tick_replay_feedback.json`,
`alternate_local_hint_multi_tick_replay_positions.json`,
`alternate_local_hint_multi_tick_replay_digest.json`, `metrics.json`, and
`events.ndjson`. Metrics use `alternateLocalHintMultiTickReplay*`; the aggregate
event is `lab_alternate_local_hint_multi_tick_replay_recorded`. The invariant
report records 93 checks passed and 0 failed.

### Results

The smoke executed three ticks with 18 contexts and 18 decisions, consumed 13
feedback records, carried 12 feedback records to the next tick, produced 10
alternate candidates, selected 5, sent 12 movement intents to tick, approved 8,
denied 4 by collision, emitted 12 feedback records, applied 8 lab-map
displacements, preserved 4 denied agents and 6 noIntent agents, and kept
abstract/physical divergence at zero.

### Boundary Confirmation

The report confirms v0 and v1 unchanged, v2 opt-in, policy
`policyReadCollision=false`, policy `policyWorldUsed=false`, tick
`tickReadCollision=true`, tick `tickWorldReadOnlyUsed=true`,
`movementApplied=true` for lab maps only, `memoryUpdated=false`,
`goalChanged=false`, `pathfindingPerformed=false`, `replanningPerformed=false`,
`avoidancePerformed=false`, `reservationRuntimeUsed=false`,
`routeFollowingUsed=false`, `worldMutated=false`, and `mutationPerformed=false`.

### Validation Commands

- `git status`
- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario alternate_local_hint_multi_tick_replay_smoke --seed 42 --ticks 3 --out runs/check_alternate_local_hint_multi_tick_replay`
- `swift run -c release PebbleLab -- --scenario alternate_local_hint_approved_application_smoke --seed 42 --ticks 0 --out runs/check_alternate_local_hint_approved_application_after_multi_tick_replay`
- `swift run -c release PebbleLab -- --scenario alternate_local_hint_live_readonly_smoke --seed 42 --ticks 0 --out runs/check_alternate_local_hint_live_readonly_after_multi_tick_replay`
- `swift run -c release PebbleLab -- --scenario alternate_local_hint_hardening_smoke --seed 42 --ticks 0 --out runs/check_alternate_local_hint_hardening_after_multi_tick_replay`
- `swift run -c release PebbleLab -- --scenario alternate_local_hint_fixture_smoke --seed 42 --ticks 0 --out runs/check_alternate_local_hint_fixture_after_multi_tick_replay`
- `swift run -c release PebbleLab -- --scenario multi_tick_closed_loop_approved_application_smoke --seed 42 --ticks 3 --out runs/check_multi_tick_closed_loop_approved_application_after_alternate_hint_replay`
- `swift run -c release PebbleLab -- --scenario multi_tick_closed_loop_live_readonly_smoke --seed 42 --ticks 3 --out runs/check_multi_tick_closed_loop_live_readonly_after_alternate_hint_replay`
- `swift run -c release PebbleLab -- --scenario multi_tick_closed_loop_hardening_smoke --seed 42 --ticks 3 --out runs/check_multi_tick_closed_loop_hardening_after_alternate_hint_replay`
- `swift run -c release PebbleLab -- --scenario multi_tick_closed_loop_fixture_smoke --seed 42 --ticks 3 --out runs/check_multi_tick_closed_loop_fixture_after_alternate_hint_replay`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_to_tick_approved_application_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_approved_application_after_alternate_hint_replay`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_to_tick_live_readonly_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_live_readonly_after_alternate_hint_replay`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_to_tick_fixture_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_intent_to_tick_fixture_after_alternate_hint_replay`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_policy_hardening_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_policy_hardening_after_alternate_hint_replay`
- `swift run -c release PebbleLab -- --scenario feedback_to_agent_intent_context_hardening_smoke --seed 42 --ticks 0 --out runs/check_feedback_to_context_hardening_after_alternate_hint_replay`
- `swift run -c release PebbleLab -- --scenario agent_intent_production_fixture_smoke --seed 42 --ticks 0 --out runs/check_agent_intent_fixture_after_alternate_hint_replay`
- `swift run -c release PebbleLab -- --scenario agent_intent_to_tick_approved_application_smoke --seed 42 --ticks 0 --out runs/check_agent_intent_to_tick_approved_application_after_alternate_hint_replay`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_alternate_hint_replay`
- `swift run -c release pebsmoke`
- `git diff --check`

### Results Summary

- `swift build` passed.
- `alternate_local_hint_multi_tick_replay_smoke` passed with report and
  invariant success.
- Metrics and event were written with the expected replay prefix/type.

### Next Step

Phase 4.26A — Agent Movement Policy Consolidation Plan Docs-Only.

## 2026-07-01 — Phase 4.26A agent movement policy consolidation planning docs-only

### Objective

Document the agent movement policy consolidation plan before adding any new
behavior or refactoring. The phase records the current v0/v1/v2 stack,
policy/tick/application boundaries, naming recommendations, report/metrics/event
consolidation direction, invariants, risks, and the recommended 4.26B contract.

### Validated Starting Point

The starting point includes agent intent production, feedback consumption,
feedback injection into `LabAgentIntentContext.lastFeedback`, feedback-aware v1,
alternate local hint v2, tick fixture arbitration, tick live read-only
collision evidence, tick approved application, multi-tick closed loop, and
alternate local hint replay/determinism. The latest validated scenario is
`alternate_local_hint_multi_tick_replay_smoke`.

### Why Docs-Only

The policy surface has accumulated cleanly, but it now has several versions,
scenario families, report shapes, metrics, events, and replay summaries. Before
adding path planning or broader movement intelligence, the boundary between
policy, feedback, tick arbitration, collision evidence, approved application,
and replay needs to be documented without changing runtime behavior.

### New Document

Created `docs/pebblelab/PHASE_4_AGENT_MOVEMENT_POLICY_CONSOLIDATION_PLAN.md`.

### Current Policy Stack

- v0: baseline deterministic intent proposal using context/local hints only.
- v1: explicit opt-in feedback-aware policy; no feedback, `moved`, and
  `approvedForMovement` keep baseline; blocked feedback becomes `noIntent`.
- v2: explicit opt-in alternate local hint policy; known blocked hints can
  produce bounded deterministic alternates, while empty/unknown hints become
  `noIntent`.

All three policies keep policy reads separate from World/collision, memory,
goals, route following, pathfinding, replanning, avoidance, reservation runtime,
and movement application.

### Layer Boundary

The plan separates:

- policy layer: context plus feedback plus local hints to proposal;
- intent production layer: deterministic proposal collection and filtering;
- tick layer: conflict arbitration, optional read-only collision evidence, and
  feedback;
- approved application layer: lab-map-only movement for approved resolutions;
- replay layer: previous-tick feedback carryover and digest repeatability.

### Consolidation Goals

The plan recommends clearer naming, standardized boundary flags, common report
sections, common summary fields, stable metrics/event conventions, digest-based
replay checks, and no behavior change to v0, v1, or v2.

### Non-Goals

4.26A explicitly excludes pathfinding, route planning, route following,
replanning, avoidance, reservation runtime, memory, goals, learning,
LLM/RL/Python, gameplay autonomy, physical entity movement, terrain mutation,
World mutation, and any behavior change to v0/v1/v2.

### Naming Plan

The plan proposes future names such as `LabAgentMovementPolicyVersion`,
`LabAgentMovementPolicyDecision`, `LabAgentMovementPolicyBoundary`, and
`LabAgentMovementTickBoundary`. These are documented only; no Swift types are
added in 4.26A.

### Report, Metrics, And Event Consolidation

The plan proposes common report sections for scenario, seed, requested/executed
ticks, policy mode, contexts, decisions, tick records, feedback ledger,
positions, replay digest, summary, boundary, and invariants. Metrics should use
stable family prefixes and common names for common totals. Events should remain
aggregate, include policy mode and boundary fields, and avoid hidden feature
activation.

### Invariants

The plan lists 108 future invariants covering policy version stability,
explicit opt-in behavior, no hidden activation, policy/tick/application
boundaries, feedback N-to-N+1 carryover, replay digest stability, no
pathfinding/replanning/avoidance/reservation/route following, no memory/goals,
no physical/core movement, no terrain/world mutation, and prior scenario
regressions.

### Risk Table

The risk table covers v2 replacing v1, v1/v0 drift, report and metrics drift,
policy World/collision reads, tick read-only modes applying movement,
approved application mutating World, replay becoming a gameplay loop,
alternate hints becoming pathfinding, consolidation becoming behavior refactor,
nondeterministic outputs, duplicate summary disagreement, and path planning
sneaking into consolidation.

### Future Phase Breakdown

- Phase 4.26B: Agent Movement Policy Consolidation Fixture Smoke.
- Phase 4.26C: Policy Boundary Hardening.
- Phase 4.26D: Consolidated Replay Regression.
- Phase 4.27A: Bounded Path Planning Plan Docs-Only.

### Recommended 4.26B Contract

4.26B should be a no-behavior-change fixture smoke. It may introduce a
consolidated report adapter, run representative v0/v1/v2 contexts, compare
signatures against direct policy outputs, prove no policy drift, and keep no
World/collision/pathfinding/replanning/avoidance/reservation/route following.

### Validation Commands

- `git status`
- `git diff --name-only`
- verify no Swift files changed
- `swift build`
- `swift run -c release pebsmoke`
- `git diff --check`
- `git status`

### Results

- Docs-only edits were made.
- No Swift files were modified.
- `swift build` passed.
- `swift run -c release pebsmoke` passed with 456 passed and 0 failed.
- `git diff --check` passed.

### Next Step

Phase 4.26B — Agent Movement Policy Consolidation Fixture Smoke.

## 2026-07-01 — Phase 4.26B agent movement policy consolidation fixture smoke

### Objective

Implement a fixture-only, no-behavior-change consolidation smoke for the agent
movement policy stack. The scenario compares direct v0, v1, and v2 policy calls
with an explicit consolidated adapter and fails if any stable signatures drift.

### Starting Point

4.26A documented the consolidation boundary after validated v0 baseline intent
production, opt-in feedback-aware v1, opt-in alternate local hint v2,
multi-tick replay, and lab-map-only approved application. The policy stack was
validated, but no unified adapter/report proved the direct policy outputs could
be represented without changing behavior.

### Why No-Behavior-Change

This phase intentionally adds a reporting adapter only. It does not change
`produceAgentIntentProposalV0`, `produceAgentIntentProposalFeedbackAwareV1`, or
`produceAgentIntentProposalWithAlternateLocalHintsV2`. It does not make v2
implicit, replace v0/v1 globally, call tick movement, read collision, read
World, or apply movement.

### Files Created/Modified

- `Sources/PebbleLab/LabAgentMovementPolicyConsolidation.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`
- `docs/pebblelab/PHASE_4_AGENT_MOVEMENT_POLICY_CONSOLIDATION_PLAN.md`

### Adapter And Signatures

The scenario `agent_movement_policy_consolidation_fixture_smoke` builds eight
deterministic contexts covering no feedback, unknown hints, approved feedback,
moved feedback, blocked conflicts, blocked collision, empty hints, and unknown
blocked hints. It runs three explicit policy versions for each context:

- v0 direct vs `.baselineV0` consolidated;
- v1 direct vs `.feedbackAwareV1` consolidated;
- v2 direct vs `.alternateLocalHintV2` consolidated.

Each comparison records direct and consolidated stable signatures containing
agent id, tick, decision, reason, intent edge, selected hint, and alternate
candidates where relevant.

### Expected Results

- contexts: 8;
- policy versions: 3;
- direct decisions: 24;
- consolidated decisions: 24;
- signatures compared: 24;
- signatures matched: 24;
- signature mismatches: 0;
- v0/v1/v2 signature mismatches: 0;
- v0 unchanged, v1 unchanged, v2 opt-in, v2 not global;
- hidden activation false;
- blocked v1 contexts become noIntent;
- blocked v2 known hints produce bounded alternates;
- empty/unknown hints remain noIntent;
- max alternates remains 2.

### Boundary Flags

The report asserts no World, no policy collision read, no tick collision read,
no tick live path, no movement application, no terrain/world mutation, no core
entity movement, no physical placeholder movement, no memory/goals, no
pathfinding, no replanning, no avoidance, no reservation runtime, no route
following, no learning, no LLM/RL/Python, no social behavior, and no
communication.

### Outputs, Metrics, And Event

The scenario writes:

- `agent_movement_policy_consolidation_report.json`;
- `agent_movement_policy_consolidation_invariant_report.json`;
- `agent_movement_policy_consolidation_decisions.json`;
- `agent_movement_policy_consolidation_signatures.json`;
- `agentMovementPolicyConsolidation*` metrics;
- one aggregate `lab_agent_movement_policy_consolidation_recorded` event.

### Validation Commands

- `git status`
- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario agent_movement_policy_consolidation_fixture_smoke --seed 42 --ticks 0 --out runs/check_agent_movement_policy_consolidation_fixture`
- required 4.26B non-regression PebbleLab scenarios
- `swift run -c release pebsmoke`
- `git diff --check`

### Results

Implementation added the no-behavior-change fixture, report, invariant report,
decisions/signatures JSON, metrics, and event. Validation results are recorded
in the 4.26B commit notes.

### Next Step

Phase 4.26C — Policy Boundary Hardening.

## 2026-07-01 — Phase 4.26C agent movement policy boundary hardening

### Objective

Add a fixture-only hardening scenario for the consolidated agent movement
policy boundary. The scenario expands the representative contexts from 4.26B
and verifies that direct v0, v1, and v2 calls still match the consolidated
adapter without changing behavior.

### Starting Point

4.26B added `agent_movement_policy_consolidation_fixture_smoke` with eight
contexts, three explicit policy versions, twenty-four signature comparisons,
zero mismatches, v0/v1 unchanged, v2 opt-in, and no World, collision, tick live,
movement application, memory/goals, pathfinding, replanning, reservation, route
following, or mutation.

### Why Hardening

The policy stack is now broad enough that negative and edge cases matter. 4.26C
keeps the adapter fixture-only and checks more contexts, more feedback kinds,
bounded `maxAlternates` values, duplicate/multiple/empty/unknown hints, and all
boundary flags before any future replay consolidation or path-planning planning.

### Files Created/Modified

- `Sources/PebbleLab/LabAgentMovementPolicyConsolidation.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`
- `docs/pebblelab/PHASE_4_AGENT_MOVEMENT_POLICY_CONSOLIDATION_PLAN.md`

### No-Behavior-Change

The hardening scenario does not modify `produceAgentIntentProposalV0`,
`produceAgentIntentProposalFeedbackAwareV1`, or
`produceAgentIntentProposalWithAlternateLocalHintsV2`. It calls direct and
consolidated policy paths for comparison only, and v2 remains explicit opt-in
and not global.

### Cases Covered

The scenario covers twenty-two contexts: four no-feedback cardinal movement
hints, no-feedback empty/unknown hints, approved and moved feedback baselines,
all seven blocked feedback kinds, blocked empty/unknown hints,
duplicate/multiple hints, and `maxAlternates` 0, 1, 2, and 3.

### Boundary Flags

All policy and tick/application boundary flags remain false: no World read, no
collision read, no tick live path, no movement application, no terrain/world
mutation, no core entity movement, no physical placeholder movement, no
memory/goals, no pathfinding, no replanning, no avoidance, no reservation
runtime, and no route following.

### Outputs, Metrics, And Event

The scenario writes:

- `agent_movement_policy_boundary_hardening_report.json`;
- `agent_movement_policy_boundary_hardening_invariant_report.json`;
- `agent_movement_policy_boundary_hardening_cases.json`;
- `agent_movement_policy_boundary_hardening_decisions.json`;
- `agent_movement_policy_boundary_hardening_signatures.json`;
- `agent_movement_policy_boundary_hardening_boundary.json`;
- `agentMovementPolicyBoundaryHardening*` metrics;
- one aggregate `lab_agent_movement_policy_boundary_hardening_recorded` event.

### Validation Commands

- `git status`
- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario agent_movement_policy_boundary_hardening_smoke --seed 42 --ticks 0 --out runs/check_agent_movement_policy_boundary_hardening`
- required 4.26C non-regression PebbleLab scenarios
- `swift run -c release pebsmoke`
- `git diff --check`

### Results

Implementation added the boundary hardening scenario, report, invariant report,
cases/decisions/signatures/boundary JSON, metrics, and event. Validation
results are recorded in the 4.26C commit notes.

### Next Step

Phase 4.26D — Consolidated Replay Regression.

## 2026-07-01 — Phase 4.26D agent movement policy consolidated replay regression

Branch: `lab/pebblelab-v1`

### Objective

Add a consolidated replay regression smoke that proves v0, v1, and v2 direct
policy signatures still match the consolidated adapter over a fixed multi-tick
fixture replay.

### Starting Point

Phase 4.26B added the no-behavior-change consolidated policy fixture smoke.
Phase 4.26C hardened the policy boundary across twenty-two contexts. The next
gap was deterministic replay coverage: feedback had to move from tick N to
tick N+1 without same-tick, future, or cross-agent leaks while signatures
remained identical.

### Files Modified

- `Sources/PebbleLab/LabAgentMovementPolicyConsolidation.swift`
- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`
- `docs/pebblelab/PHASE_4_AGENT_MOVEMENT_POLICY_CONSOLIDATION_PLAN.md`

### Replay Contract

The scenario uses fixture-only policy replay, not tick live execution. It runs
three fixed ticks over six deterministic agents and three explicit policy
versions. Each tick builds contexts from previous-tick feedback, evaluates
direct and consolidated policy decisions, compares signatures, emits synthetic
feedback for the next tick, and appends a deterministic digest line.

### Determinism And Boundaries

The replay checks deterministic tick, agent, policy, decision, and signature
ordering. It records two identical replay digests and zero signature
mismatches. v0 remains unchanged, v1 remains unchanged, and v2 stays opt-in and
not global. No hidden activation is allowed.

### Outputs, Metrics, And Event

The scenario writes report, invariant report, tick records, feedback ledger,
decisions, signatures, digest, boundary JSON, `agentMovementPolicyConsolidatedReplay*`
metrics, and one aggregate `lab_agent_movement_policy_consolidated_replay_recorded`
event.

### Guardrails

The fixture replay does not read World or collision, does not call tick live
collision, does not apply movement, does not move core entities or physical
placeholders, does not update memory or goals, does not perform pathfinding,
replanning, avoidance, reservation runtime, or route following, and does not
mutate terrain or World.

### Validation Commands

- `git status`
- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario agent_movement_policy_consolidated_replay_regression_smoke --seed 42 --ticks 3 --out runs/check_agent_movement_policy_consolidated_replay`
- required 4.26D non-regression PebbleLab scenarios
- `swift run -c release pebsmoke`
- `git diff --check`

### Results

The consolidated replay regression passed with three executed ticks, six
agents, three policy versions, fifty-four decisions/signatures compared, zero
mismatches, feedback carried only to the next tick, zero leaks, identical replay
digests, and all boundary flags clean.

### Next Step

Phase 4.27A — Bounded Path Planning Plan Docs-Only.

## 2026-07-01 — Phase 4.27A bounded path planning planning docs-only

Branch: `lab/pebblelab-v1`

### Objective

Create a docs-only bounded path planning plan before adding any planner,
scenario, runner, metric, or event runtime code.

### Validated Starting Point

PebbleLab already validates v0 baseline one-step intent proposals, v1
feedback-aware blocked-to-noIntent behavior, v2 deterministic alternate local
hints, policy consolidation, boundary hardening, consolidated replay
regression, feedback N to N+1, stable replay digests, and lab-map-only approved
application. Terrain and World mutation remain out of scope.

### Why Docs-Only

Path planning is the first feature that could accidentally become route
following, gameplay autonomy, memory/goals, reservation runtime, or live World
navigation. The phase locks the vocabulary, boundaries, invariants, and future
scenario sequence before implementation.

### New Document

`docs/pebblelab/PHASE_4_BOUNDED_PATH_PLANNING_PLAN.md`

### Definition Of Bounded Path Planning

Bounded path planning means producing a small abstract plan with fixed
`maxSteps` and fixed node limits in a fixture or abstract grid. It is
deterministic and does not execute movement, follow routes, read live World or
collision, mutate terrain/World, update memory/goals, or create autonomous
gameplay.

### Layer Placement

The future planner sits between policy and tick as an explicit opt-in planning
layer. Policy remains one-step and no-World/no-collision. Tick still owns
conflict and collision approval. Approved application applies only an approved
first step to lab maps. Replay proves deterministic plan output and digest
stability.

### v3 Proposal

The plan proposes a future v3 bounded path planning policy mode. v3 must be
explicit opt-in, fixture-first, bounded, deterministic, and must not replace
v0, v1, or v2 globally.

### Planning Context And Output Proposals

The plan documents future `LabAgentBoundedPathPlanningContext` and
`LabAgentBoundedPathPlan` shapes, including tick, agent, start, target/local
objective, `maxSteps`, abstract grid/occupancy, allowed/blocked directions,
selected first step, no-path reason, deterministic digest, and boundary flags.

### Algorithm Boundary

Allowed later: fixed-depth deterministic search or tiny BFS over a fixture grid
with fixed max steps, fixed max nodes, and stable tie-breaks. Forbidden:
unbounded A*, unbounded BFS, Dijkstra over live World, live World queries,
dynamic replanning, reservations, route following, mining/building, memory,
goals, RL, LLM, and Python.

### Safety And Scope Boundaries

The plan explicitly excludes gameplay autonomy, player-like bots,
mining/building, inventory, combat, social communication, economic behavior,
persistent goals, cross-tick route commitment in the first implementation, and
hidden activation by existing scenarios.

### Future Scenario Plan

- Phase 4.27B — Bounded Path Planning Fixture Smoke.
- Phase 4.27C — Bounded Path Planning Hardening.
- Phase 4.27D — Planning To Tick First-Step Handoff.
- Phase 4.27E — Planning Approved Application Lab-Map Only.
- Phase 4.27F — Planning Multi-Tick Replay Regression.

### Invariants

The plan records 110 future invariants covering v0/v1/v2 stability, future v3
opt-in, maxSteps/maxNodes bounds, deterministic ordering and tie-breaks,
first-step-only handoff, no route following, no persistent route commitment, no
World/collision reads from policy, no memory/goals, no reservation runtime, no
terrain/world mutation, feedback N to N+1, replay digest stability, and 4.26
regression coverage.

### Risk Table

The risk table covers bounded planning becoming unbounded pathfinding, fixture
grids drifting into live World scans, full-route execution, v3 replacing v2,
hidden activation, dynamic replanning, reservation runtime, memory/goals,
nondeterministic tie-breaks, digest instability, terrain mutation, physical
movement, and reports hiding boundary drift.

### Recommended 4.27B Contract

The first implementation should be fixture-only: no World, no collision, no
tick, no movement application, no lab position mutation, no route following, no
memory/goals, no reservation runtime, no terrain/world mutation, no v0/v1/v2
behavior change, explicit opt-in future v3, small abstract grid, fixed
`maxSteps`, fixed `maxNodes`, deterministic plans, and report/invariant/metrics
/event output.

### Validation Commands

- `git status`
- `git diff --name-only`
- verify no Swift files changed
- `swift build`
- `swift run -c release pebsmoke`
- `git diff --check`
- `git status`

### Results

Validation passed for docs-only changes. No Swift files, runtime scenarios,
runners, metrics/events, PebbleCore, renderer/shader/resource, registry,
save-load, or golden files were modified.

### Next Step

Phase 4.27B — Bounded Path Planning Fixture Smoke.

## 2026-07-01 — Phase 4.27B bounded path planning fixture smoke

### Objective

Add the first fixture-only bounded path planning smoke without introducing live
pathfinding, tick handoff, movement application, route following, memory/goals,
reservation runtime, or terrain/World mutation.

### Starting Point

Phase 4.27A documented bounded path planning as a future explicit v3 planning
mode. The validated baseline already includes v0/v1/v2 movement policies,
policy consolidation fixture coverage, boundary hardening, consolidated replay
regression, feedback N to N+1 replay semantics, lab-map-only approved
application, and deterministic digest checks.

### Why Fixture-Only

The first implementation keeps planning inside an abstract fixture grid so the
boundary is inspectable before any tick, live collision, approved application,
or replay integration. The planner produces plans, not movement execution.

### Planner

The fixture planner introduces bounded planning contexts and plans for a future
v3 opt-in mode. It uses a tiny deterministic fixed-bound BFS over supplied
fixture cells only. It does not inspect `World`, live collision, agents, memory,
goals, or terrain.

### Grid And Bounds

Cases use an abstract same-y grid with fixed `maxSteps` and fixed `maxNodes`.
The smoke verifies `maxStepsMax <= 4`, `maxNodesMax <= 32`, nodes visited within
the node bound, and step count within the step bound.

### Neighbor Order And Tie-Break

Neighbor order is fixed as `move_north`, `move_east`, `move_south`,
`move_west`. The context records a stable tie-break label, and the invariant
report verifies deterministic case order, neighbor order, and tie-break.

### Cases Covered

The fixture covers direct one-step planning, two-step planning, a deterministic
detour around a blocked cell, no path, max steps too short, max nodes too small,
start equals target, negative coordinates, and same-y-only behavior.

### Digest Repeatability

Each plan records a deterministic digest. The report repeats the same fixture
inputs and verifies the aggregate digest matches with zero repeatability
failures.

### v3 Opt-In And Hidden Activation

The smoke represents v3 as `boundedPathPlanningV3FixtureOptIn` only. v0, v1,
and v2 remain unchanged; v3 is not global; hidden activation is reported false.

### Outputs, Invariants, Metrics, Event

Outputs:

- `bounded_path_planning_fixture_report.json`;
- `bounded_path_planning_fixture_invariant_report.json`;
- `bounded_path_planning_fixture_cases.json`;
- `bounded_path_planning_fixture_plans.json`;
- `bounded_path_planning_fixture_digest.json`;
- `boundedPathPlanningFixture*` metrics;
- `lab_bounded_path_planning_fixture_recorded` event.

The invariant report records 74 checks, including max bounds, one-edge same-y
steps, deterministic ordering, digest repeatability, v0/v1/v2 stability, v3
opt-in/not-global status, and all boundary flags.

### Boundary Confirmation

The smoke confirms no World read, no collision read, no tick, no movement
application, no lab position map mutation, no route following, no live
pathfinding, no unbounded search, no dynamic replanning, no reservation runtime,
no memory update, no goal change, no core entity or physical placeholder
movement, and no terrain/World mutation.

### Validation Commands

- `git status`
- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario bounded_path_planning_fixture_smoke --seed 42 --ticks 0 --out runs/check_bounded_path_planning_fixture`
- `swift run -c release PebbleLab -- --scenario agent_movement_policy_consolidation_fixture_smoke --seed 42 --ticks 0 --out runs/check_policy_consolidation_fixture_after_bounded_path_fixture`
- `swift run -c release PebbleLab -- --scenario agent_movement_policy_boundary_hardening_smoke --seed 42 --ticks 0 --out runs/check_policy_boundary_hardening_after_bounded_path_fixture`
- `swift run -c release PebbleLab -- --scenario agent_movement_policy_consolidated_replay_regression_smoke --seed 42 --ticks 3 --out runs/check_policy_consolidated_replay_after_bounded_path_fixture`
- `swift run -c release PebbleLab -- --scenario alternate_local_hint_multi_tick_replay_smoke --seed 42 --ticks 3 --out runs/check_alternate_local_hint_multi_tick_replay_after_bounded_path_fixture`
- `swift run -c release PebbleLab -- --scenario multi_tick_closed_loop_approved_application_smoke --seed 42 --ticks 3 --out runs/check_multi_tick_closed_loop_approved_application_after_bounded_path_fixture`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_policy_hardening_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_policy_hardening_after_bounded_path_fixture`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_bounded_path_fixture`
- `swift run -c release pebsmoke`
- `git diff --check`

### Results

Validation passed. The scenario report and invariant report both show success
true, all fixture cases pass, digests match, and all boundary flags remain
false.

### Next Step

Phase 4.27C — Bounded Path Planning Hardening.

## 2026-07-01 — Phase 4.27C bounded path planning hardening

### Objective

Harden the fixture-only bounded path planner with edge cases around step bounds,
node bounds, blocked cells, blocked directions, duplicate inputs, deterministic
tie-breaks, and digest repeatability without adding any live behavior.

### Starting Point

Phase 4.27B added `bounded_path_planning_fixture_smoke`: a deterministic tiny
BFS over an abstract grid, max `maxSteps` 4, max `maxNodes` 32, fixed neighbor
order, nine passing cases, repeatable digest, v3 fixture opt-in, v3 not global,
and no World/collision/tick/movement/route following/memory/goals/reservation
runtime or terrain/World mutation.

### Why Hardening

The fixture smoke proved the happy path and core boundary. The hardening smoke
adds enough limit and malformed-layout pressure to make future planning
handoffs harder to accidentally turn into live pathfinding, route following, or
autonomous movement.

### Planner Fixture-Only

The scenario reuses the existing fixture planner and abstract grid context. It
does not introduce `World`, collision reads, tick handoff, approved
application, route following, memory/goals, reservation runtime, or mutation.

### Bounds Coverage

`maxSteps` values 0, 1, 2, 3, and 4 are covered. `maxNodes` values 1, 2, and
32 are covered. The report verifies all plans stay within both bounds.

### Blocked Inputs

The hardening cases cover start surrounded by blocked cells, target surrounded
by blocked cells, target listed as blocked, blocked direction `move_east`, an
only-north/south allowed direction subset, duplicate blocked cells, and a
blocked start cell. The blocked start case documents that the start is an
allowed initial node in the fixture planner.

### Duplicate And Coordinate Cases

Duplicate input cases produce identical digests. Duplicate blocked cells remain
stable after `Set` normalization. Negative-coordinate detours remain
deterministic.

### Same-Y And Tie-Break

The same-y-only case uses a vertical target that cannot be reached by the
planner, proving no y-changing escape is emitted. The equal-shortest-path case
selects `move_north` first, matching the fixed neighbor order.

### Digest Repeatability

The scenario runs the hardening fixtures twice and compares aggregate digests.
`digestsEqual` is true and repeatability failures remain zero.

### v3 Opt-In And Hidden Activation

v3 remains represented only as fixture opt-in. v0, v1, and v2 remain unchanged;
v3 is not global; hidden activation is false.

### Outputs, Invariants, Metrics, Event

Outputs:

- `bounded_path_planning_hardening_report.json`;
- `bounded_path_planning_hardening_invariant_report.json`;
- `bounded_path_planning_hardening_cases.json`;
- `bounded_path_planning_hardening_plans.json`;
- `bounded_path_planning_hardening_digest.json`;
- `bounded_path_planning_hardening_boundary.json`;
- `boundedPathPlanningHardening*` metrics;
- `lab_bounded_path_planning_hardening_recorded` event.

The invariant report records 92 checks for coverage, bounds, determinism,
repeatability, v0/v1/v2 stability, v3 opt-in/not-global status, and boundary
flags.

### Boundary Confirmation

The scenario confirms no World read, no collision read, no tick, no movement
application, no lab position map mutation, no route following, no live
pathfinding, no unbounded search, no dynamic replanning, no reservation runtime,
no memory update, no goal change, no terrain/World mutation, no core entity
movement, and no physical placeholder movement.

### Validation Commands

- `git status`
- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario bounded_path_planning_hardening_smoke --seed 42 --ticks 0 --out runs/check_bounded_path_planning_hardening`
- `swift run -c release PebbleLab -- --scenario bounded_path_planning_fixture_smoke --seed 42 --ticks 0 --out runs/check_bounded_path_fixture_after_hardening`
- `swift run -c release PebbleLab -- --scenario agent_movement_policy_consolidation_fixture_smoke --seed 42 --ticks 0 --out runs/check_policy_consolidation_fixture_after_bounded_path_hardening`
- `swift run -c release PebbleLab -- --scenario agent_movement_policy_boundary_hardening_smoke --seed 42 --ticks 0 --out runs/check_policy_boundary_hardening_after_bounded_path_hardening`
- `swift run -c release PebbleLab -- --scenario agent_movement_policy_consolidated_replay_regression_smoke --seed 42 --ticks 3 --out runs/check_policy_consolidated_replay_after_bounded_path_hardening`
- `swift run -c release PebbleLab -- --scenario alternate_local_hint_multi_tick_replay_smoke --seed 42 --ticks 3 --out runs/check_alternate_local_hint_multi_tick_replay_after_bounded_path_hardening`
- `swift run -c release PebbleLab -- --scenario multi_tick_closed_loop_approved_application_smoke --seed 42 --ticks 3 --out runs/check_multi_tick_closed_loop_approved_application_after_bounded_path_hardening`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_policy_hardening_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_policy_hardening_after_bounded_path_hardening`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_bounded_path_hardening`
- `swift run -c release pebsmoke`
- `git diff --check`

### Results

Validation passed. Hardening report and invariant report both show success true,
all hardening cases pass, digests match, and boundary flags remain false.

### Next Step

Phase 4.27D — Planning To Tick First-Step Handoff.

## 2026-07-01 — Phase 4.27D planning to tick first-step handoff

Objective: add the first handoff from bounded path planning to the existing
multi-agent movement tick fixture, while sending only the selected first step.

Starting point: Phase 4.27B introduced a fixture-only bounded planner over an
abstract grid. Phase 4.27C hardened it across max step/node bounds, blocked
inputs, duplicate inputs, negative coordinates, same-y-only constraints, and
deterministic tie-breaks. Neither phase used World, collision, tick movement,
movement application, route following, memory, goals, reservation runtime, or
mutation.

Files changed:

- `Sources/PebbleLab/LabBoundedPathPlanning.swift`
- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`
- `docs/pebblelab/PHASE_4_BOUNDED_PATH_PLANNING_PLAN.md`

Why first-step-only: bounded path planning must not become route following or
full-route execution. This phase proves that a plan can select a first step,
convert that one edge into `LabAgentMoveIntent`, and let the tick fixture own
approval, denial, and conflict arbitration. Remaining plan steps stay
advisory-only.

Planner fixture: the scenario reuses the deterministic abstract-grid planner
with `maxSteps <= 4`, `maxNodes <= 32`, one-edge same-y steps, and stable
neighbor order. v3 remains explicit opt-in and not global. v0, v1, and v2
remain unchanged.

Conversion: every plan with `selectedFirstStep` creates one movement intent
using the selected edge. No-path and zero-step plans create no movement intent.
Source mismatch and stale intent cases reuse existing tick fixture denial
behavior instead of inventing new tick semantics.

Tick fixture: the scenario calls the existing fixture tick only. It covers
approved movement intents, denied same-destination conflict, denied source
mismatch, and denied stale intent. Tick fixture output emits feedback, but no
feedback is consumed in this phase.

Approved/denied/conflict: approved and denied decisions come from the tick
fixture. Planning does not arbitrate same-destination conflicts. The conflict
case sends two first-step intents to the same destination and verifies that
tick deterministically approves one and denies one.

Advisory steps not sent: multi-step plans retain their remaining route steps in
the report, but those steps are not present in the tick input. This preserves
the boundary between path planning and route following.

Outputs, invariants, metrics, and event:

- `bounded_path_planning_to_tick_first_step_report.json`
- `bounded_path_planning_to_tick_first_step_invariant_report.json`
- `bounded_path_planning_to_tick_first_step_cases.json`
- `bounded_path_planning_to_tick_first_step_plans.json`
- `bounded_path_planning_to_tick_first_step_handoff.json`
- `bounded_path_planning_to_tick_first_step_tick.json`
- `bounded_path_planning_to_tick_first_step_digest.json`
- `bounded_path_planning_to_tick_first_step_boundary.json`
- `boundedPathPlanningToTickFirstStep*` metrics
- `lab_bounded_path_planning_to_tick_first_step_recorded`

Boundary confirmation: no live collision, no World read, no movement
application, no lab position map mutation, no route following, no full route
execution, no live pathfinding, no unbounded search, no dynamic replanning, no
reservation runtime, no memory update, no goal change, no terrain/World
mutation, no core entity movement, and no physical placeholder movement.

Validation commands:

- `git status`
- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario bounded_path_planning_to_tick_first_step_smoke --seed 42 --ticks 0 --out runs/check_bounded_path_planning_to_tick_first_step`
- `swift run -c release PebbleLab -- --scenario bounded_path_planning_fixture_smoke --seed 42 --ticks 0 --out runs/check_bounded_path_fixture_after_first_step_handoff`
- `swift run -c release PebbleLab -- --scenario bounded_path_planning_hardening_smoke --seed 42 --ticks 0 --out runs/check_bounded_path_hardening_after_first_step_handoff`
- `swift run -c release PebbleLab -- --scenario agent_movement_policy_consolidation_fixture_smoke --seed 42 --ticks 0 --out runs/check_policy_consolidation_fixture_after_first_step_handoff`
- `swift run -c release PebbleLab -- --scenario agent_movement_policy_boundary_hardening_smoke --seed 42 --ticks 0 --out runs/check_policy_boundary_hardening_after_first_step_handoff`
- `swift run -c release PebbleLab -- --scenario agent_movement_policy_consolidated_replay_regression_smoke --seed 42 --ticks 3 --out runs/check_policy_consolidated_replay_after_first_step_handoff`
- `swift run -c release PebbleLab -- --scenario alternate_local_hint_multi_tick_replay_smoke --seed 42 --ticks 3 --out runs/check_alternate_local_hint_multi_tick_replay_after_first_step_handoff`
- `swift run -c release PebbleLab -- --scenario multi_tick_closed_loop_approved_application_smoke --seed 42 --ticks 3 --out runs/check_multi_tick_closed_loop_approved_application_after_first_step_handoff`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_policy_hardening_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_policy_hardening_after_first_step_handoff`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_first_step_handoff`
- `swift run -c release pebsmoke`
- `git diff --check`

Results: validation passed. The first-step handoff report and invariant report
show success true, first-step-only handoff true, advisory steps not sent true,
tick fixture used true, live collision false, movement application false, and
digest repeatability true.

Next step: Phase 4.27E — Planning Approved Application Lab-Map Only.

## 2026-07-01 — Phase 4.27E planning approved application lab-map only

Objective: add the first bounded path planning approved-application smoke that
applies only tick-approved selected first steps to lab position maps.

Starting point: Phase 4.27B introduced fixture-only bounded plans, Phase 4.27C
hardened the planner, and Phase 4.27D handed only `selectedFirstStep` to the
existing tick fixture. At the start of this phase, no bounded path plan could
apply an approved first step to lab maps.

Files changed:

- `Sources/PebbleLab/LabBoundedPathPlanning.swift`
- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DEV_JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`
- `docs/pebblelab/PHASE_4_BOUNDED_PATH_PLANNING_PLAN.md`

Why lab-map-only: approved application must remain a controlled PebbleLab
artifact, not gameplay movement. The scenario updates only synthetic abstract
and physical position maps after tick approval. It does not move core entities,
physical placeholders, or terrain/World state.

Planner and handoff: the scenario reuses the bounded fixture planner with
`maxSteps <= 4`, `maxNodes <= 32`, one-edge same-y steps, deterministic neighbor
order, and explicit v3 opt-in. Only selected first steps become tick intents.
Advisory route steps remain in reports and are not sent to tick.

Tick fixture: the existing fixture tick remains responsible for approval,
denial, and same-destination conflict arbitration. It does not read live
collision or use `World`. Source mismatch and stale intent denials reuse the
existing tick contract.

Application semantics: approved first steps update both abstract and physical
lab maps to the selected first-step destination. Denied agents, no-path agents,
and zero-step agents are preserved. Abstract/physical divergence remains zero
before and after application.

Cases covered:

- direct one-step approved application;
- two-step plan with only step 0 applied;
- detour plan with only step 0 applied;
- no-path unchanged;
- zero-step unchanged;
- same-destination conflict denied and preserved;
- source mismatch denied and preserved;
- stale intent denied and preserved.

Outputs, invariants, metrics, and event:

- `bounded_path_planning_approved_application_report.json`
- `bounded_path_planning_approved_application_invariant_report.json`
- `bounded_path_planning_approved_application_cases.json`
- `bounded_path_planning_approved_application_plans.json`
- `bounded_path_planning_approved_application_handoff.json`
- `bounded_path_planning_approved_application_tick.json`
- `bounded_path_planning_approved_application_application.json`
- `bounded_path_planning_approved_application_positions.json`
- `bounded_path_planning_approved_application_digest.json`
- `bounded_path_planning_approved_application_boundary.json`
- `boundedPathPlanningApprovedApplication*` metrics
- `lab_bounded_path_planning_approved_application_recorded`

Boundary confirmation: no World read, no live collision read, no full-route
execution, no route following, no advisory step application, no second-step
auto-application, no memory/goals, no reservation runtime, no live pathfinding,
no unbounded search, no dynamic replanning, no core entity movement, no
physical placeholder movement, and no terrain/World mutation.

Validation commands:

- `git status`
- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario bounded_path_planning_approved_application_smoke --seed 42 --ticks 0 --out runs/check_bounded_path_planning_approved_application`
- `swift run -c release PebbleLab -- --scenario bounded_path_planning_fixture_smoke --seed 42 --ticks 0 --out runs/check_bounded_path_fixture_after_approved_application`
- `swift run -c release PebbleLab -- --scenario bounded_path_planning_hardening_smoke --seed 42 --ticks 0 --out runs/check_bounded_path_hardening_after_approved_application`
- `swift run -c release PebbleLab -- --scenario bounded_path_planning_to_tick_first_step_smoke --seed 42 --ticks 0 --out runs/check_bounded_path_to_tick_first_step_after_approved_application`
- `swift run -c release PebbleLab -- --scenario agent_movement_policy_consolidation_fixture_smoke --seed 42 --ticks 0 --out runs/check_policy_consolidation_fixture_after_bounded_path_approved_application`
- `swift run -c release PebbleLab -- --scenario agent_movement_policy_boundary_hardening_smoke --seed 42 --ticks 0 --out runs/check_policy_boundary_hardening_after_bounded_path_approved_application`
- `swift run -c release PebbleLab -- --scenario agent_movement_policy_consolidated_replay_regression_smoke --seed 42 --ticks 3 --out runs/check_policy_consolidated_replay_after_bounded_path_approved_application`
- `swift run -c release PebbleLab -- --scenario alternate_local_hint_multi_tick_replay_smoke --seed 42 --ticks 3 --out runs/check_alternate_local_hint_multi_tick_replay_after_bounded_path_approved_application`
- `swift run -c release PebbleLab -- --scenario multi_tick_closed_loop_approved_application_smoke --seed 42 --ticks 3 --out runs/check_multi_tick_closed_loop_approved_application_after_bounded_path_approved_application`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_policy_hardening_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_policy_hardening_after_bounded_path_approved_application`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_bounded_path_approved_application`
- `swift run -c release pebsmoke`
- `git diff --check`

Results: validation passed. The approved-application report and invariant
report show success true, first-step-only application true, advisory steps not
applied true, approved applications equal tick approvals, denied/no-path/zero
step agents preserved, abstract/physical divergence zero, and digest
repeatability true.

Next step: Phase 4.27F — Bounded Path Planning Multi-Tick Replay Regression.

## 2026-07-01 — Phase 4.27F bounded path planning multi-tick replay regression

Objective: add a deterministic bounded path planning replay over multiple
ticks while proving there is no persistent route following.

Starting point: 4.27B introduced fixture-only bounded planning, 4.27C hardened
the planner, 4.27D handed only selected first steps to tick fixture, and 4.27E
applied only approved first steps to lab abstract/physical maps. No prior
bounded planning scenario replayed the loop across ticks.

Why multi-tick replay: the next risk is accidentally treating a bounded plan as
a route to follow. This phase locks the opposite behavior: every tick rebuilds
contexts from current lab maps and replans from scratch. Advisory path steps
are recorded for inspection only and are not carried as executable state.

Implementation summary:

- added `bounded_path_planning_multi_tick_replay_smoke`;
- fixed replay length is three ticks;
- nine fixture agents cover direct progress, multi-step progress, detour,
  same-destination conflict, no path, zero step, source mismatch, and stale
  intent;
- contexts are rebuilt from current lab abstract positions each tick;
- planner v3 remains explicit fixture opt-in and not global;
- only current `selectedFirstStep` becomes a movement intent;
- tick fixture owns approval/denial/conflict/source/stale decisions;
- only approved first steps mutate lab abstract and physical maps;
- denied/no-path/zero-step/source/stale/conflict agents are preserved.

Feedback ledger: tick feedback is stored per emitting tick and consumed only by
the next tick. The report proves feedback from tick 0 is consumed at tick 1 and
feedback from tick 1 is consumed at tick 2. Same-tick feedback consumption,
future feedback consumption, and cross-agent feedback leaks are all zero.

Digest repeatability: the scenario runs the same replay twice and compares the
aggregate tick/context/plan/handoff/tick-decision/application/feedback digest.
The digests match and repeatability failures are zero.

Outputs, invariants, metrics, and event:

- `bounded_path_planning_multi_tick_replay_report.json`
- `bounded_path_planning_multi_tick_replay_invariant_report.json`
- `bounded_path_planning_multi_tick_replay_ticks.json`
- `bounded_path_planning_multi_tick_replay_feedback.json`
- `bounded_path_planning_multi_tick_replay_plans.json`
- `bounded_path_planning_multi_tick_replay_handoff.json`
- `bounded_path_planning_multi_tick_replay_tick.json`
- `bounded_path_planning_multi_tick_replay_application.json`
- `bounded_path_planning_multi_tick_replay_positions.json`
- `bounded_path_planning_multi_tick_replay_digest.json`
- `bounded_path_planning_multi_tick_replay_boundary.json`
- `boundedPathPlanningMultiTickReplay*` metrics
- `lab_bounded_path_planning_multi_tick_replay_recorded`

Boundary confirmation: no World read, no live collision read, no live tick, no
route following, no full-route execution, no persistent route commitment, no
advisory step application, no second-step auto-application, no memory/goals, no
reservation runtime, no live pathfinding, no unbounded search, no dynamic
replanning, no core entity movement, no physical placeholder movement, and no
terrain/World mutation.

Validation commands:

- `git status`
- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario bounded_path_planning_multi_tick_replay_smoke --seed 42 --ticks 3 --out runs/check_bounded_path_planning_multi_tick_replay`
- `swift run -c release PebbleLab -- --scenario bounded_path_planning_fixture_smoke --seed 42 --ticks 0 --out runs/check_bounded_path_fixture_after_multi_tick_replay`
- `swift run -c release PebbleLab -- --scenario bounded_path_planning_hardening_smoke --seed 42 --ticks 0 --out runs/check_bounded_path_hardening_after_multi_tick_replay`
- `swift run -c release PebbleLab -- --scenario bounded_path_planning_to_tick_first_step_smoke --seed 42 --ticks 0 --out runs/check_bounded_path_first_step_handoff_after_multi_tick_replay`
- `swift run -c release PebbleLab -- --scenario bounded_path_planning_approved_application_smoke --seed 42 --ticks 0 --out runs/check_bounded_path_approved_application_after_multi_tick_replay`
- `swift run -c release PebbleLab -- --scenario agent_movement_policy_consolidation_fixture_smoke --seed 42 --ticks 0 --out runs/check_policy_consolidation_fixture_after_bounded_path_multi_tick_replay`
- `swift run -c release PebbleLab -- --scenario agent_movement_policy_boundary_hardening_smoke --seed 42 --ticks 0 --out runs/check_policy_boundary_hardening_after_bounded_path_multi_tick_replay`
- `swift run -c release PebbleLab -- --scenario agent_movement_policy_consolidated_replay_regression_smoke --seed 42 --ticks 3 --out runs/check_policy_consolidated_replay_after_bounded_path_multi_tick_replay`
- `swift run -c release PebbleLab -- --scenario alternate_local_hint_multi_tick_replay_smoke --seed 42 --ticks 3 --out runs/check_alternate_local_hint_multi_tick_replay_after_bounded_path_multi_tick_replay`
- `swift run -c release PebbleLab -- --scenario multi_tick_closed_loop_approved_application_smoke --seed 42 --ticks 3 --out runs/check_multi_tick_closed_loop_approved_application_after_bounded_path_multi_tick_replay`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_policy_hardening_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_policy_hardening_after_bounded_path_multi_tick_replay`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_bounded_path_multi_tick_replay`
- `swift run -c release pebsmoke`
- `git diff --check`

Results: validation passed in the local debug toolchain. The replay report and
invariant report show success true, requested/executed ticks 3, feedback
N-to-N+1 with zero same/future/cross-agent leaks, first-step-only
handoff/application, abstract/physical divergence zero, and digest
repeatability true.

Next step: Phase 4.28A — Agent Movement Stack Consolidation Docs-Only.

## 2026-07-02 — Phase 4.28A agent movement stack consolidation plan

Objective: document the future AgentMovementStack consolidation boundary before
adding any new runtime adapter or behavior.

Docs-only scope: this phase created a plan document and updated the changelog,
dev journal, and roadmap only. No Swift, scenarios, runners, metrics, events,
PebbleCore, renderer, resources, registries, save/load, or goldens were
modified.

Starting point summary:

- 4.21 validated agent intent production, intent-to-tick fixture/live
  read-only, and approved lab-map application;
- 4.22 validated feedback consumption and injection into
  `LabAgentIntentContext.lastFeedback`;
- 4.23 added opt-in feedback-aware v1 policy while preserving v0;
- 4.24 validated multi-tick closed-loop feedback N to N+1 semantics;
- 4.25 added opt-in alternate local hint v2 and replay coverage;
- 4.26 consolidated movement policy signatures and boundary hardening;
- 4.27 added fixture-first bounded planning, first-step handoff,
  lab-map-only approved application, and multi-tick replay regression.

Target stack: the plan defines conceptual layers for agent snapshots, feedback
ledger, intent contexts, movement policy, bounded planning, first-step handoff,
tick arbitration, approved application, replay regression, boundary audit, and
metrics/events/reports.

Policy versions: v0 remains baseline local-hint intent production, v1 remains
feedback-aware blocked-to-noIntent filtering, v2 remains deterministic bounded
alternate local hints, and v3 remains bounded fixture planning. All modes must
remain opt-in. A future v4 is reserved and not implemented.

Feedback contract: feedback emitted at tick N may be consumed only at tick
N+1. Same-tick, future, and cross-agent feedback leaks remain forbidden.
Duplicate, malformed, and unknown feedback must stay deterministic and must
not mutate memory/goals.

Bounded planning contract: fixture planning remains bounded by current
`maxSteps <= 4` and `maxNodes <= 32`, one-edge, same-y, deterministic, and
first-step-only. Advisory steps must not be sent, applied, persisted, or used
as route-following state.

Application contract: only tick-approved first steps may mutate lab abstract
and physical position maps. Denied, noPath, zero-step, source mismatch, stale,
and conflict agents are preserved. World, terrain, Core entities, and live
physical placeholders remain untouched.

Boundary contract: flags such as `worldRead`, `collisionRead`,
`routeFollowingUsed`, `fullRouteExecutionUsed`,
`persistentRouteCommitmentUsed`, `advisoryStepsApplied`,
`secondStepAutoApplied`, `pathfindingLiveUsed`, `unboundedSearchUsed`,
`dynamicReplanningUsed`, `reservationRuntimeUsed`, `memoryUpdated`,
`goalChanged`, `terrainMutated`, `worldMutated`, `coreEntityMoved`,
`physicalPlaceholderMoved`, and `mutationPerformed` must remain false unless a
future phase explicitly documents an exception. Tick fixture use and lab-map
approved application are the only current allowed runtime exceptions.

Roadmap 4.28B-F:

- 4.28B Stack Contract Fixture Smoke;
- 4.28C Stack Contract Boundary Hardening;
- 4.28D Stack Replay Regression Adapter;
- 4.28E Stack Metrics/Event Compatibility Smoke;
- 4.28F Stack Consolidated Multi-Tick Replay Regression.

Future route following gate: route following remains out of scope. Before it
can be considered, the stack must be consolidated, replay deterministic,
feedback ledger stable, lab maps synchronized, first-step-only behavior proven,
and a separate docs-only route-following spec approved explicitly.

Validation commands:

- `git status`
- `git diff --stat`
- `git diff --name-only`
- `git diff --check`

Results: docs-only validation passed with documentation-only changes and
`git diff --check` clean.

Next step: Phase 4.28B — Stack Contract Fixture Smoke.

## 2026-07-02 — Phase 4.28B agent movement stack contract fixture smoke

Objective: add the first fixture-only AgentMovementStack contract smoke,
proving the stack can be represented as deterministic orchestration of existing
layers without changing v0/v1/v2/v3 behavior or introducing route following.

Starting point: 4.28A documented the conceptual stack layers, policy version
boundaries, feedback contract, bounded planning contract, application contract,
and boundary flags. Existing validated runtime evidence already covered policy
consolidation and bounded path planning multi-tick replay.

Relation to the 4.28A plan: this phase implements only the first fixture
contract adapter. It aggregates existing policy consolidation evidence and
bounded planning replay evidence into a stack-shaped report. It does not
replace existing scenarios and does not make any policy global.

Stack layers validated:

- `AgentSnapshotLayer`;
- `FeedbackLedgerLayer`;
- `IntentContextLayer`;
- `MovementPolicyLayer`;
- `BoundedPlanningLayer`;
- `FirstStepHandoffLayer`;
- `TickArbitrationLayer`;
- `ApprovedApplicationLayer`;
- `ReplayRegressionLayer`;
- `BoundaryAuditLayer`;
- `MetricsEventsReportsLayer`.

Policy versions: v0 baseline, v1 feedback-aware, v2 alternate local hint, and
v3 bounded planning are covered as opt-in evidence. v4 is present only as
reserved metadata with no runtime path, no global activation, and no hidden
activation.

First-step-only contract: bounded planning evidence remains first-step-only.
`selectedFirstStep` is the only handoff to tick, advisory steps are not sent,
and advisory steps are not applied.

Feedback contract: feedback is consumed from tick N to tick N+1 only. Same-tick
feedback consumption, future feedback consumption, and cross-agent feedback
leaks remain zero.

Lab-map-only application: approved applications mutate only lab abstract and
physical position maps. Abstract/physical divergence after application remains
zero. Core entities and live physical placeholders are not moved.

Boundary contract: no World read, no live collision read, no tick World
read-only use, no tick collision read, no route following, no full-route
execution, no persistent route commitment, no second-step auto-application, no
live pathfinding, no unbounded search, no dynamic replanning, no reservation
runtime, no memory/goals, no terrain/World mutation, and no
renderer/resource/registry/golden touch.

Outputs, invariants, metrics, and event:

- `agent_movement_stack_contract_report.json`;
- `agent_movement_stack_contract_invariant_report.json`;
- `agent_movement_stack_contract_layers.json`;
- `agent_movement_stack_contract_policies.json`;
- `agent_movement_stack_contract_replay.json`;
- `agent_movement_stack_contract_boundary.json`;
- `agent_movement_stack_contract_digest.json`;
- `agentMovementStackContract*` metrics;
- `lab_agent_movement_stack_contract_recorded` event.

Validation commands:

- `git status`
- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario agent_movement_stack_contract_fixture_smoke --seed 42 --ticks 3 --out runs/check_agent_movement_stack_contract_fixture`
- `swift run -c release PebbleLab -- --scenario bounded_path_planning_fixture_smoke --seed 42 --ticks 0 --out runs/check_bounded_path_fixture_after_stack_contract`
- `swift run -c release PebbleLab -- --scenario bounded_path_planning_hardening_smoke --seed 42 --ticks 0 --out runs/check_bounded_path_hardening_after_stack_contract`
- `swift run -c release PebbleLab -- --scenario bounded_path_planning_to_tick_first_step_smoke --seed 42 --ticks 0 --out runs/check_bounded_path_first_step_handoff_after_stack_contract`
- `swift run -c release PebbleLab -- --scenario bounded_path_planning_approved_application_smoke --seed 42 --ticks 0 --out runs/check_bounded_path_approved_application_after_stack_contract`
- `swift run -c release PebbleLab -- --scenario bounded_path_planning_multi_tick_replay_smoke --seed 42 --ticks 3 --out runs/check_bounded_path_multi_tick_replay_after_stack_contract`
- `swift run -c release PebbleLab -- --scenario agent_movement_policy_consolidation_fixture_smoke --seed 42 --ticks 0 --out runs/check_policy_consolidation_fixture_after_stack_contract`
- `swift run -c release PebbleLab -- --scenario agent_movement_policy_boundary_hardening_smoke --seed 42 --ticks 0 --out runs/check_policy_boundary_hardening_after_stack_contract`
- `swift run -c release PebbleLab -- --scenario agent_movement_policy_consolidated_replay_regression_smoke --seed 42 --ticks 3 --out runs/check_policy_consolidated_replay_after_stack_contract`
- `swift run -c release PebbleLab -- --scenario alternate_local_hint_multi_tick_replay_smoke --seed 42 --ticks 3 --out runs/check_alternate_local_hint_multi_tick_replay_after_stack_contract`
- `swift run -c release PebbleLab -- --scenario multi_tick_closed_loop_approved_application_smoke --seed 42 --ticks 3 --out runs/check_multi_tick_closed_loop_approved_application_after_stack_contract`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_policy_hardening_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_policy_hardening_after_stack_contract`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_stack_contract`
- `swift run -c release pebsmoke`
- `git diff --check`

Results: local debug validation passed. The stack contract report shows
success true, 11 layers enabled, 5 policy versions documented, 4 policy
versions executed, v4 reserved-only true, 9 agents, 27 contexts/plans, 18
handoff intents, 9 tick approvals, 9 tick denials, 9 approved applications, 13
feedback records consumed, equal digests, and all boundary-forbidden flags
false. The invariant report shows 97 passed and 0 failed.

Next step: Phase 4.28C — Stack Contract Boundary Hardening.

## 2026-07-02 — Phase 4.28C agent movement stack boundary hardening smoke

Objective: add `agent_movement_stack_contract_boundary_hardening_smoke`, a
fixture-only and audit-only hardening scenario for the 4.28B stack contract.
The scenario proves that malformed stack records and forbidden boundary flags
are rejected deterministically while the valid 4.28B baseline remains
accepted.

Starting point: 4.28B represented the conceptual AgentMovementStack with 11
layers, opt-in v0/v1/v2/v3 evidence, reserved-only v4 metadata, first-step-only
handoff, lab-map-only application, feedback N to N+1, and clean boundary
flags.

Hardening fixture-only/audit-only design: negative samples are synthetic data
records. They represent forbidden states such as World reads, route following,
or Core movement without executing those behaviors. The runtime boundary flags
therefore remain false for the scenario itself.

Negative samples covered:

- missing, duplicate, out-of-order, disabled, malformed, and dirty layers;
- missing v0/v3, duplicate policy version, global activation, hidden
  activation, v4 execution, and v4 no-longer-reserved states;
- same-tick, future, and cross-agent feedback leaks;
- advisory steps sent/applied, second-step auto-application, persistent route
  commitment, full-route execution, and route following;
- World/collision reads, tick World/collision reads, live pathfinding,
  unbounded search, dynamic replanning, reservation runtime, memory/goals,
  terrain/World mutation, Core entity movement, physical placeholder movement,
  renderer/resource/registry/golden touches.

Results: 42 cases ran, 42 passed, 0 failed. The scenario accepted 1 valid
baseline sample, rejected 41 negative samples, detected 41 expected violations,
missed 0 violations, and produced 0 false positives. Digest repeatability is
true and the baseline 4.28B stack contract remains green.

Outputs, invariants, metrics, and event:

- `agent_movement_stack_boundary_hardening_report.json`;
- `agent_movement_stack_boundary_hardening_invariant_report.json`;
- `agent_movement_stack_boundary_hardening_cases.json`;
- `agent_movement_stack_boundary_hardening_negative_samples.json`;
- `agent_movement_stack_boundary_hardening_audits.json`;
- `agent_movement_stack_boundary_hardening_boundary.json`;
- `agent_movement_stack_boundary_hardening_digest.json`;
- `agentMovementStackBoundaryHardening*` metrics;
- `lab_agent_movement_stack_boundary_hardening_recorded` event.

Boundary confirmations: no World/collision live read, no route following, no
full-route execution, no Core entity movement, no physical placeholder
movement, no memory/goals, no reservation runtime, no terrain/World mutation,
and no renderer/resource/registry/golden touch occurred at runtime.

Validation commands:

- `git status`
- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario agent_movement_stack_contract_boundary_hardening_smoke --seed 42 --ticks 0 --out runs/check_agent_movement_stack_boundary_hardening`
- `swift run -c release PebbleLab -- --scenario agent_movement_stack_contract_fixture_smoke --seed 42 --ticks 3 --out runs/check_stack_contract_fixture_after_boundary_hardening`
- `swift run -c release PebbleLab -- --scenario bounded_path_planning_fixture_smoke --seed 42 --ticks 0 --out runs/check_bounded_path_fixture_after_stack_boundary_hardening`
- `swift run -c release PebbleLab -- --scenario bounded_path_planning_multi_tick_replay_smoke --seed 42 --ticks 3 --out runs/check_bounded_path_multi_tick_replay_after_stack_boundary_hardening`
- `swift run -c release PebbleLab -- --scenario agent_movement_policy_consolidation_fixture_smoke --seed 42 --ticks 0 --out runs/check_policy_consolidation_fixture_after_stack_boundary_hardening`
- `swift run -c release PebbleLab -- --scenario agent_movement_policy_boundary_hardening_smoke --seed 42 --ticks 0 --out runs/check_policy_boundary_hardening_after_stack_boundary_hardening`
- `swift run -c release PebbleLab -- --scenario agent_movement_policy_consolidated_replay_regression_smoke --seed 42 --ticks 3 --out runs/check_policy_consolidated_replay_after_stack_boundary_hardening`
- `swift run -c release PebbleLab -- --scenario alternate_local_hint_multi_tick_replay_smoke --seed 42 --ticks 3 --out runs/check_alternate_local_hint_multi_tick_replay_after_stack_boundary_hardening`
- `swift run -c release PebbleLab -- --scenario multi_tick_closed_loop_approved_application_smoke --seed 42 --ticks 3 --out runs/check_multi_tick_closed_loop_approved_application_after_stack_boundary_hardening`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_policy_hardening_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_policy_hardening_after_stack_boundary_hardening`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_stack_boundary_hardening`
- `swift run -c release pebsmoke`
- `git diff --check`

Results: `swift build` passed. Local debug scenario validation passed with 116
invariant checks passed and 0 failed. Release validation remains best-effort in
this environment because production builds can stall without additional log
output.

Next step: Phase 4.28D — Stack Replay Regression Adapter.

## 2026-07-02 — Phase 4.28D agent movement stack replay regression adapter

Objective: add `agent_movement_stack_replay_regression_adapter_smoke`, a
fixture-only replay regression adapter that normalizes several existing stack,
policy, planning, hint, and closed-loop proofs into one common replay report.

Starting point: 4.28B introduced the valid stack contract fixture and 4.28C
hardened its boundary audit with synthetic negative samples. Both remain green
and are used as adapter inputs rather than rewritten.

Adapter normalized runs:

- `agent_movement_stack_contract_fixture_smoke`;
- `agent_movement_stack_contract_boundary_hardening_smoke`;
- `agent_movement_policy_consolidated_replay_regression_smoke`;
- `bounded_path_planning_multi_tick_replay_smoke`;
- `alternate_local_hint_multi_tick_replay_smoke`;
- `multi_tick_closed_loop_approved_application_smoke`.

Compatibility matrix: the adapter records required runs, normalized runs,
success/failure totals, missing runs, digest compatibility, boundary
compatibility, policy compatibility, and output schema compatibility. Optional
fields are used where a source scenario has no direct contexts, plans, handoff,
tick, application, feedback, policy, or layer count.

Digest compatibility: each source run must provide a digest and matching repeat
digest. The adapter also creates a deterministic aggregate digest from the
normalized run order and verifies the aggregate repeat digest matches.

Boundary compatibility: 4.28D itself does not read World/collision or execute
route following/full-route behavior. Source runs that legitimately perform
tick-layer read-only evidence or lab-map approved application remain normalized
as compatible when they preserve stack boundaries: no policy World/collision,
no route following, no full-route execution, no Core/placeholder movement, no
memory/goals/reservation runtime, and no terrain/World mutation.

Policy and output schema compatibility: the adapter records compatible policy
evidence for v0/v1/v2/v3 where available, preserves v4 as reserved through the
stack contract, and verifies all six normalized runs expose the common report
shape.

Aggregate totals from validation:

- required runs = 6;
- normalized runs = 6;
- successful runs = 6;
- failed runs = 0;
- missing required runs = 0;
- replay runs total = 10;
- digest compatible runs = 6;
- boundary compatible runs = 6;
- policy compatible runs = 6;
- output schema compatible runs = 6;
- contexts aggregate = 105;
- plans aggregate = 54;
- handoff intents aggregate = 70;
- tick approved aggregate = 32;
- tick denied aggregate = 26;
- approved applications aggregate = 32;
- feedback consumed aggregate = 57;
- invariant checks = 80 passed, 0 failed.

Outputs, invariants, metrics, and event:

- `agent_movement_stack_replay_adapter_report.json`;
- `agent_movement_stack_replay_adapter_invariant_report.json`;
- `agent_movement_stack_replay_adapter_runs.json`;
- `agent_movement_stack_replay_adapter_compatibility.json`;
- `agent_movement_stack_replay_adapter_boundary.json`;
- `agent_movement_stack_replay_adapter_digest.json`;
- `agentMovementStackReplayAdapter*` metrics;
- `lab_agent_movement_stack_replay_adapter_recorded` event.

Validation commands:

- `git status`
- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario agent_movement_stack_replay_regression_adapter_smoke --seed 42 --ticks 3 --out runs/check_agent_movement_stack_replay_adapter`
- `swift run -c release PebbleLab -- --scenario agent_movement_stack_contract_fixture_smoke --seed 42 --ticks 3 --out runs/check_stack_contract_fixture_after_replay_adapter`
- `swift run -c release PebbleLab -- --scenario agent_movement_stack_contract_boundary_hardening_smoke --seed 42 --ticks 0 --out runs/check_stack_boundary_hardening_after_replay_adapter`
- `swift run -c release PebbleLab -- --scenario agent_movement_policy_consolidated_replay_regression_smoke --seed 42 --ticks 3 --out runs/check_policy_consolidated_replay_after_stack_replay_adapter`
- `swift run -c release PebbleLab -- --scenario bounded_path_planning_multi_tick_replay_smoke --seed 42 --ticks 3 --out runs/check_bounded_path_multi_tick_replay_after_stack_replay_adapter`
- `swift run -c release PebbleLab -- --scenario alternate_local_hint_multi_tick_replay_smoke --seed 42 --ticks 3 --out runs/check_alternate_local_hint_multi_tick_replay_after_stack_replay_adapter`
- `swift run -c release PebbleLab -- --scenario multi_tick_closed_loop_approved_application_smoke --seed 42 --ticks 3 --out runs/check_multi_tick_closed_loop_approved_application_after_stack_replay_adapter`
- `swift run -c release PebbleLab -- --scenario feedback_aware_intent_policy_hardening_smoke --seed 42 --ticks 0 --out runs/check_feedback_aware_policy_hardening_after_stack_replay_adapter`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_stack_replay_adapter`
- `swift run -c release pebsmoke`
- `git diff --check`

Results: local debug scenario validation passed. `swift build` passes. Release
validation is still tracked separately because production `PebbleLab` runs can
stall in this environment, while `Pebble` and `pebsmoke` release products have
been validated in prior 4.28 work.

Next step: Phase 4.28E — Stack Metrics/Event Compatibility Smoke.

## 2026-07-02 — Phase 4.28E agent movement stack metrics/event compatibility smoke

Objective: add `agent_movement_stack_metrics_event_compatibility_smoke`, a
fixture-only audit that checks the stack metrics and events emitted by the
4.28B stack contract, 4.28C boundary hardening, and 4.28D replay adapter
families.

Starting point: 4.28B/C/D already prove the stack contract, boundary audit, and
replay adapter. Phase 4.28E does not change those source scenarios; it builds
their reports in memory and verifies their metrics/events are present, typed,
stable, unique, digestable, and consistent with summaries.

Source scenarios audited:

- `agent_movement_stack_contract_fixture_smoke`;
- `agent_movement_stack_contract_boundary_hardening_smoke`;
- `agent_movement_stack_replay_regression_adapter_smoke`.

Metric prefixes audited:

- `agentMovementStackContract*`;
- `agentMovementStackBoundaryHardening*`;
- `agentMovementStackReplayAdapter*`;
- `agentMovementStackMetricsEventCompatibility*`.

Events audited:

- `lab_agent_movement_stack_contract_recorded`;
- `lab_agent_movement_stack_boundary_hardening_recorded`;
- `lab_agent_movement_stack_replay_adapter_recorded`;
- `lab_agent_movement_stack_metrics_event_compatibility_recorded`.

Metrics inventory and event inventory:

- source scenarios present = 3;
- metric prefixes present = 4;
- events present = 4;
- metric records = 228;
- event records = 4;
- contract metric keys = 67;
- boundary hardening metric keys = 51;
- replay adapter metric keys = 58;
- compatibility metric keys = 52;
- metrics unique/typed/matching summaries = true;
- events unique/required fields present = true.

Compatibility matrix and ordering:

- metrics stable order = true;
- events stable order = true;
- deterministic metric order = true;
- deterministic event order = true;
- source digests stable = true;
- aggregate digest equals repeat digest = true;
- repeatability failures = 0.

Boundary confirmations: 4.28E does not read World or live collision, does not
execute route following or full-route execution, does not move Core entities or
physical placeholders, does not mutate memory/goals, does not use reservation
runtime, and does not mutate terrain/World. Renderer, resources, registries,
and goldens remain untouched.

Outputs, invariants, metrics, and event:

- `agent_movement_stack_metrics_event_compatibility_report.json`;
- `agent_movement_stack_metrics_event_compatibility_invariant_report.json`;
- `agent_movement_stack_metrics_event_compatibility_metrics_inventory.json`;
- `agent_movement_stack_metrics_event_compatibility_event_inventory.json`;
- `agent_movement_stack_metrics_event_compatibility_matrix.json`;
- `agent_movement_stack_metrics_event_compatibility_boundary.json`;
- `agent_movement_stack_metrics_event_compatibility_digest.json`;
- `agentMovementStackMetricsEventCompatibility*` metrics;
- `lab_agent_movement_stack_metrics_event_compatibility_recorded` event.

Validation commands:

- `git status`
- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario agent_movement_stack_metrics_event_compatibility_smoke --seed 42 --ticks 3 --out runs/check_agent_movement_stack_metrics_event_compatibility`
- `swift run -c release PebbleLab -- --scenario agent_movement_stack_contract_fixture_smoke --seed 42 --ticks 3 --out runs/check_stack_contract_fixture_after_metrics_event_compatibility`
- `swift run -c release PebbleLab -- --scenario agent_movement_stack_contract_boundary_hardening_smoke --seed 42 --ticks 0 --out runs/check_stack_boundary_hardening_after_metrics_event_compatibility`
- `swift run -c release PebbleLab -- --scenario agent_movement_stack_replay_regression_adapter_smoke --seed 42 --ticks 3 --out runs/check_stack_replay_adapter_after_metrics_event_compatibility`
- `swift run -c release PebbleLab -- --scenario bounded_path_planning_multi_tick_replay_smoke --seed 42 --ticks 3 --out runs/check_bounded_path_multi_tick_replay_after_metrics_event_compatibility`
- `swift run -c release PebbleLab -- --scenario agent_movement_policy_consolidated_replay_regression_smoke --seed 42 --ticks 3 --out runs/check_policy_consolidated_replay_after_metrics_event_compatibility`
- `swift run -c release PebbleLab -- --scenario alternate_local_hint_multi_tick_replay_smoke --seed 42 --ticks 3 --out runs/check_alternate_hint_replay_after_metrics_event_compatibility`
- `swift run -c release PebbleLab -- --scenario multi_tick_closed_loop_approved_application_smoke --seed 42 --ticks 3 --out runs/check_closed_loop_after_metrics_event_compatibility`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_metrics_event_compatibility`
- `swift run -c release pebsmoke`
- `git diff --check`

Results: local debug scenario validation passed with `success = true`, 228
metric records, 4 event records, 52 compatibility metrics, and 80 invariant
checks passed with 0 failed. Release validation remains best-effort in this
environment because production `PebbleLab` runs can stall, while normal
`swift build`, `Pebble` release, and `pebsmoke` release are still used as
structural validation.

Next step: Phase 4.28F — Stack Consolidated Multi-Tick Replay Regression.

## 2026-07-02 — Phase 4.28F agent movement stack consolidated multi-tick replay smoke

Objective: add
`agent_movement_stack_consolidated_multi_tick_replay_smoke`, a fixture-only
final consolidation replay that aggregates the 4.28B/C/D/E stack proofs and
the principal multi-tick movement replay scenarios into one boundary-clean
compatibility report.

Starting point: 4.28B proves the stack contract, 4.28C hardens the boundary
audit, 4.28D normalizes replay regression evidence, and 4.28E audits
metrics/events. Earlier 4.24-4.27 scenarios already prove multi-tick feedback,
alternate local hints, bounded planning, first-step handoff, and lab-map-only
approved application.

Why fixture-only: 4.28F is an audit and compatibility aggregator. It calls
existing report builders in memory and does not create a World, read live
collision, call route following, execute a full route, apply new movement, or
mutate terrain/World/Core/physical placeholders.

Required runs aggregated:

- `agent_movement_stack_contract_fixture_smoke`;
- `agent_movement_stack_contract_boundary_hardening_smoke`;
- `agent_movement_stack_replay_regression_adapter_smoke`;
- `agent_movement_stack_metrics_event_compatibility_smoke`;
- `bounded_path_planning_multi_tick_replay_smoke`;
- `alternate_local_hint_multi_tick_replay_smoke`;
- `multi_tick_closed_loop_approved_application_smoke`;
- `agent_movement_policy_consolidated_replay_regression_smoke`.

Compatibility matrix:

- required runs = 8;
- required runs present = 8;
- successful runs = 8;
- failed runs = 0;
- missing required runs = 0;
- multi-tick runs present >= 4;
- stack contract, boundary hardening, replay adapter, and metrics/event
  compatibility runs present;
- all required, digest, boundary, policy, metrics/events, output schema, and
  multi-tick compatibility checks pass.

Aggregate evidence:

- replay runs total >= 10;
- contexts aggregate > 0;
- plans aggregate > 0;
- selected first steps aggregate > 0;
- handoff intents aggregate > 0;
- tick approved aggregate > 0;
- tick denied aggregate > 0;
- approved applications aggregate > 0;
- feedback consumed aggregate > 0;
- deterministic run order = true;
- deterministic digest = true;
- aggregate digest equals repeat digest;
- repeatability failures = 0.

Boundary confirmations: the 4.28F aggregator itself does not read World or live
collision, does not use route following, full-route execution, persistent route
commitment, second-step auto-application, live pathfinding, unbounded search,
dynamic replanning, reservation runtime, memory, or goals. It does not move
Core entities or physical placeholders, does not mutate terrain/World, and does
not touch renderer, resources, registries, or goldens.

Outputs, invariants, metrics, and event:

- `agent_movement_stack_consolidated_replay_report.json`;
- `agent_movement_stack_consolidated_replay_invariant_report.json`;
- `agent_movement_stack_consolidated_replay_runs.json`;
- `agent_movement_stack_consolidated_replay_matrix.json`;
- `agent_movement_stack_consolidated_replay_boundary.json`;
- `agent_movement_stack_consolidated_replay_digest.json`;
- `agentMovementStackConsolidatedReplay*` metrics;
- `lab_agent_movement_stack_consolidated_replay_recorded` event.

Validation commands:

- `git status`
- `swift build`
- `swift build -c release --product Pebble`
- `swift run -c release PebbleLab -- --scenario agent_movement_stack_consolidated_multi_tick_replay_smoke --seed 42 --ticks 3 --out runs/check_agent_movement_stack_consolidated_multi_tick_replay`
- `swift run -c release PebbleLab -- --scenario agent_movement_stack_metrics_event_compatibility_smoke --seed 42 --ticks 3 --out runs/check_stack_metrics_event_after_consolidated_replay`
- `swift run -c release PebbleLab -- --scenario agent_movement_stack_replay_regression_adapter_smoke --seed 42 --ticks 3 --out runs/check_stack_replay_adapter_after_consolidated_replay`
- `swift run -c release PebbleLab -- --scenario agent_movement_stack_contract_boundary_hardening_smoke --seed 42 --ticks 0 --out runs/check_stack_boundary_hardening_after_consolidated_replay`
- `swift run -c release PebbleLab -- --scenario agent_movement_stack_contract_fixture_smoke --seed 42 --ticks 3 --out runs/check_stack_contract_fixture_after_consolidated_replay`
- `swift run -c release PebbleLab -- --scenario bounded_path_planning_multi_tick_replay_smoke --seed 42 --ticks 3 --out runs/check_bounded_path_multi_tick_replay_after_stack_consolidated_replay`
- `swift run -c release PebbleLab -- --scenario alternate_local_hint_multi_tick_replay_smoke --seed 42 --ticks 3 --out runs/check_alternate_hint_replay_after_stack_consolidated_replay`
- `swift run -c release PebbleLab -- --scenario multi_tick_closed_loop_approved_application_smoke --seed 42 --ticks 3 --out runs/check_closed_loop_after_stack_consolidated_replay`
- `swift run -c release PebbleLab -- --scenario agent_movement_policy_consolidated_replay_regression_smoke --seed 42 --ticks 3 --out runs/check_policy_consolidated_replay_after_stack_consolidated_replay`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_stack_consolidated_replay`
- `swift run -c release pebsmoke`
- `git diff --check`

Results: validation passed. The release 4.28F scenario produced `success =
true`, 8 required runs present, 8 successful runs, 0 failed runs, aggregate
contexts/plans/handoff/tick/application/feedback evidence, 56
`agentMovementStackConsolidatedReplay*` metrics, the
`lab_agent_movement_stack_consolidated_replay_recorded` event, and invariant
report success. `swift build`, `swift build -c release --product Pebble`,
listed release non-regressions, `swift run -c release pebsmoke`, and
`git diff --check` passed.

Next step: Phase 4.28G — Agent Movement Stack Closure And Roadmap Resync, or
return to the Phase 3 roadmap once the Phase 4 movement stack is considered
closed.

## 2026-07-02 — Phase 4.28G agent movement stack closure and roadmap resync

Objective: close Phase 4.28 as a docs-only roadmap resync after the 4.28F
consolidated replay, and point the next work back toward cognitive agents,
behavior loops, and society simulation.

Starting point: commit `a016846` (`Add PebbleLab agent movement stack
consolidated replay smoke`) is the visible head of the branch. Phase 4.28F
validated the final consolidated multi-tick replay over the stack contract,
boundary hardening, replay adapter, metrics/event compatibility, bounded path
planning replay, alternate local hint replay, multi-tick closed loop approved
application, and policy consolidated replay families.

Phase 4.28A-F recap:

- 4.28A documented the Agent Movement Stack consolidation plan;
- 4.28B added the stack contract fixture smoke;
- 4.28C hardened the boundary audit with negative samples;
- 4.28D normalized replay regression evidence;
- 4.28E audited metrics/event compatibility;
- 4.28F aggregated the final consolidated multi-tick replay.

What the stack now guarantees: policies v0/v1/v2/v3 remain explicit opt-in
modes, v4 remains reserved-only, feedback from tick N is consumed only at
N+1, same-tick/future/cross-agent feedback leaks are rejected, first-step-only
handoff is preserved, advisory steps are never applied, and approved movement
application remains lab-map-only. The stack also proves deterministic replay,
stable digests, stable metrics/events, green invariant reports, no global
activation, no hidden policy activation, no route following, no full-route
execution, no persistent route commitment, no World/terrain mutation, no Core
entity movement, and no physical placeholder movement.

What the stack does not guarantee: it is not a complete cognitive-agent
system. It does not own memory, needs, mood, goal selection runtime, social
behavior, communication, inventory gameplay, construction, mining, physical
gameplay autonomy, Python, LLM, RL, or society simulation. Movement intent,
policy, feedback, planning, arbitration, and replay are infrastructure for
future cognition, not proof that agents understand goals or remember outcomes.

Movement stack versus agent cognition: the consolidated stack can now serve as
a bounded sub-layer under future behavior. The cognitive loop still needs
explicit ownership over perception, memory, needs, mood, goals, intent, action
result handling, feedback interpretation, and memory updates.

Why not continue immediately into more movement: adding route following,
runtime movement expansion, full-route execution, dynamic replanning, live
pathfinding, or reservation runtime now would deepen infrastructure before the
agent model says why an agent moves. That risks coupling policy mechanics to
missing cognitive semantics and making replay coverage look like behavior.

Why return to cognition and society: PebbleLab's objective is usable AI agents
and simulation. The movement stack is now solid enough to stop treating
movement as the main frontier. The next important uncertainty is the agent
behavior loop: what the current model already represents, what memory and
goals own, how needs and mood influence decisions, how social perception feeds
future behavior, and where inventory state becomes meaningful.

Risk if infrastructure continues too long: the project may accumulate more
movement adapters, metrics, and compatibility reports while the agent remains
mostly reactive. It could also blur boundaries between planner output and
agent intention, or between feedback logs and actual memory.

Next recommended step: Phase 5.0A — Cognitive Agent Resync Planning. It should
be docs-only and audit current `LabAgent`, `LabGoal`, `LabMemoryEntry`, needs,
inventory, social perception, movement stack entry points, reports, preserved
scenarios, and the next concrete fixture after planning.

Files created or modified:

- `docs/pebblelab/CHANGELOG.md`;
- `docs/pebblelab/DEV_JOURNAL.md`;
- `docs/pebblelab/ROADMAP.md`;
- `docs/pebblelab/PHASE_4_AGENT_MOVEMENT_STACK_CONSOLIDATION_PLAN.md`;
- `docs/pebblelab/PHASE_5_COGNITIVE_AGENT_RESYNC_PLAN.md`.

Validation commands:

- `git status`;
- `swift build`;
- `swift build -c release --product Pebble`;
- `git diff --check`.

Expected validation result: docs-only changes should keep build products
unchanged. `pebsmoke` is optional for this phase because no core simulation,
scenario, runtime metric, runtime event, or Swift behavior changed.

Strategic closure: Phase 4.28 is closed. The official recommendation is not to
continue immediately toward route following/runtime movement, not to begin
Python/LLM/RL, and not to start mining/construction/inventory gameplay. Return
instead to cognitive agents, behavior loop ownership, social perception, needs,
goals, memory, inventory meaning, and later society simulation.

## 2026-07-02 — Phase 5.0A cognitive agent state audit and behavior loop resync

Objective: audit the real current PebbleLab agent cognition state after the
4.28G movement stack closure, then resync the roadmap toward a future behavior
loop contract without changing Swift runtime behavior.

Starting point: branch `lab/pebblelab-v1`, commit
`688c109ace7ddb92de1a39168a41c3726c516dc0`, with 4.28G complete and the
Agent Movement Stack officially closed as infrastructure. The movement stack
remains deterministic and boundary-clean, but it is not the cognitive agent
system.

Files audited:

- `Sources/PebbleLab/LabAgent.swift`;
- `Sources/PebbleLab/LabEvents.swift`;
- `Sources/PebbleLab/LabOptions.swift`;
- `Sources/PebbleLab/LabScenarios.swift`;
- `Sources/PebbleLab/LabOutput.swift`;
- `Sources/PebbleLab/main.swift`;
- `Sources/PebbleLab/LabPhysical.swift`;
- movement stack files by inventory, without modification;
- `docs/pebblelab/PHASE_5_COGNITIVE_AGENT_RESYNC_PLAN.md`.

Current `LabAgent` state: `LabAgent` already owns id, type, string state,
position, needs, health, fear, home position, inventory, optional World
observation, nearby-agent observations, current goal, last action, last action
effect, last abstract movement, append-only memory entries, creation/alive
ticks, and counters for observation, nearby perception, goals, actions,
effects, movement, distance, and return-home progress.

Current cognitive loop: scenario setup creates agents and optional initial
inventory/physical representation. Initial output records spawned memory,
World observation, nearby-agent observation, goal selection, and events.
Per tick, current agent scenarios run World tick, agent tick, World
observation, nearby-agent observation, goal selection, action selection,
action-effect application, abstract movement application, optional physical
placeholder sync, optional core entity sync, events, metrics, and snapshots.

What exists as true minimal cognition:

- needs: hunger, fatigue, curiosity, safety;
- health/fear/home position and distance-from-home reasoning;
- deterministic goal selection for idle, rest, seekSafety, explore, and
  observeOtherAgent;
- abstract action selection from the current goal;
- action effects that mutate fatigue, fear, curiosity, and state;
- append-only memory entries for spawn, observation, action, action effect, and
  movement;
- nearby-agent perception by relative offset and Manhattan distance;
- abstract inventory state;
- abstract movement records and counters;
- reports, metrics, and events around those concepts.

What does not exist yet: mood, emotional memory, relationship model, social
trust, communication, task board, community state, shared goals, long-term
planning, learning, memory retrieval, inventory gameplay, crafting, mining,
construction, goal persistence, a separate behavior-loop module, a clean
movement-stack adapter from cognition, Python, LLM, or RL.

Movement stack relationship: future cognition can produce a movement intent
that passes through the stack, receives approved/denied feedback, and later
updates memory. That bridge does not exist yet as a cognitive loop, and 5.0A
does not add it.

Relevant scenarios grouped in the audit:

- cognitive/abstract: `agent_smoke`, `agents_basic`, `seek_safety_smoke`,
  `long_run_smoke`, `regression_smoke`;
- physical/representation: `physical_placeholder_smoke`,
  `physical_sync_smoke`, `core_entity_smoke`, `physical_behavior_smoke`,
  `physical_behavior_multi_smoke`;
- movement stack: `agent_intent_*`, `feedback_*`,
  `multi_tick_closed_loop_*`, `alternate_local_hint_*`,
  `agent_movement_policy_*`, `bounded_path_planning_*`,
  `agent_movement_stack_*`;
- World observation: `world_observation_*`, `terrain_scan_*`,
  `terrain_column_scan_*`, `terrain_semantics_*`,
  `terrain_traversability_*`, `terrain_pathfinding_*`,
  `terrain_path_movement_*`, and terrain collision scenarios.

Static inventory notes: `main.swift` is about 9827 lines,
`LabAgentIntentProduction.swift` about 7642 lines, `LabMultiAgentMovement.swift`
about 5939 lines, `LabOutput.swift` about 5312 lines,
`LabBoundedPathPlanning.swift` about 5217 lines, and
`LabAgentMovementStackContract.swift` about 4860 lines. These files should be
watched before adding more orchestration or movement-stack scope.

Risks identified: continuing movement smokes without returning to agent
cognition, adding behavior runtime before the contract is named, wiring goals
directly to World mutation, confusing green reports with intelligence, making
`main.swift` or `LabAgentMovementStackContract.swift` larger, mixing cognition,
movement, World observation, and physical representation, treating inventory
as gameplay too soon, or treating nearby perception as social behavior before
relationships/communication exist.

Recommended next architecture: keep `LabAgent` as state, introduce future
`LabCognition` or equivalent for need/goal/action decisions, future
`LabBehaviorLoop` for orchestration, future `LabMovementStackAdapter` for the
movement bridge, future `LabMemorySystem` for memory ownership, and later
`LabSocialModel` and `LabCommunity`.

Files created or modified:

- `docs/pebblelab/PHASE_5_0A_COGNITIVE_AGENT_STATE_AUDIT.md`;
- `docs/pebblelab/CHANGELOG.md`;
- `docs/pebblelab/DEV_JOURNAL.md`;
- `docs/pebblelab/ROADMAP.md`;
- `docs/pebblelab/PHASE_5_COGNITIVE_AGENT_RESYNC_PLAN.md`.

Validation commands:

- `git status`;
- `git branch --show-current`;
- `git pull origin lab/pebblelab-v1`;
- `git log --oneline -12`;
- `swift build`;
- `swift build -c release --product Pebble`;
- `git diff --check`.

Expected result: docs/audit-only changes keep Swift behavior unchanged.
`pebsmoke` remains optional because no core simulation, runtime, scenario,
movement stack, renderer, resource, registry, save/load, or golden changed.

Results: `swift build`, `swift build -c release --product Pebble`, and
`git diff --check` passed. `pebsmoke` was not run.

Next step: Phase 5.1A — Behavior Loop Contract Planning.

## 2026-07-02 — Phase 5.1A behavior loop contract planning

Objective: define the future minimal cognitive behavior-loop contract before
adding runtime code, scenarios, metrics, events, or movement stack integration.

Starting point: branch `lab/pebblelab-v1`, commit
`b862cf9ed765fe06791b789e1152f9fe878406f1`, with Phase 5.0A complete. Phase
4.28G closed the Agent Movement Stack; Phase 5.0A confirmed that PebbleLab has
minimal abstract-agent cognition but no full behavior architecture.

Design focus: keep cognition, movement, World observation, and physical
representation separated. The behavior loop should become a small explicit
contract before any fixture runtime is added, and `main.swift` should remain a
runner/output dispatcher rather than the long-term owner of cognition.

Target loop documented:

```text
perceive
-> update needs
-> read memory
-> select goal
-> select intended action
-> optionally produce movement intent later
-> apply abstract result
-> consume feedback
-> write memory
-> emit metrics/events
```

Minimal v0 scope: consume bounded current `LabAgent` state, observation,
nearby agents, needs, current goal, last action effect, memory count/summary,
and tick. Produce a selected or confirmed goal, selected action, action effect,
optional abstract movement result, bounded memory writes, and a behavior-loop
decision record.

Proposed future types:

- `LabBehaviorLoopInput`;
- `LabBehaviorLoopDecision`;
- `LabBehaviorLoopResult`;
- `LabBehaviorLoopReport`.

Ownership boundaries:

- `LabAgent` remains agent state;
- `LabBehaviorLoop` owns cognitive orchestration;
- `LabGoal` owns current objective shape;
- `LabAction`/`LabAgentAction` represents abstract action;
- `LabMemory` or future memory system owns append-only v0 memory first;
- `LabMovementStackAdapter` is a later optional bridge;
- `main.swift` remains runner/output plumbing;
- movement stack remains a movement sub-layer, not the cognitive decider.

Movement stack relationship: future flow may be goal/action to movement intent
proposal, then movement stack, approved/denied feedback, and memory update.
This is not part of 5.1A and should probably not be part of the first 5.1B
fixture. The first implementation should prove a cognitive fixture without
movement stack usage.

Future metrics contract: reserve `behaviorLoop*`, including
`behaviorLoopSuccess`, agents, ticks, decisions, goals selected, goal changes,
actions selected, effects applied, memory entries written, movement intents
produced, movement stack used, mutation flags, movement/physical flags, and
repeatability failures.

Future events contract: reserve `lab_behavior_loop_decision_recorded` and
optionally `lab_behavior_loop_summary_recorded`, with fields for tick,
scenario, agent id, goal before/after, selected action, reason, urgency,
memory writes, movement intent produced, movement stack used, and success.

Future invariant contract: scenario name, agent count, ticks, decisions,
agent ids, selected actions, `goalAfter`, no World/terrain mutation, no Core
entity or physical placeholder movement, no route following, no full-route
execution, no v0 movement stack use, bounded memory writes, deterministic
order/digest, and zero repeatability failures.

Recommended next phase: Phase 5.1B — Behavior Loop Contract Fixture Smoke.
Likely scenario name: `behavior_loop_contract_fixture_smoke`. The fixture
should use two or three abstract agents, produce inputs/decisions/results,
apply abstract effects, write bounded memory entries, produce report,
invariant report, decisions, digest, metrics, and events, and avoid movement
stack, World mutation, terrain mutation, physical placeholder movement, and
Core entity movement.

Files created or modified:

- `docs/pebblelab/PHASE_5_1A_BEHAVIOR_LOOP_CONTRACT_PLAN.md`;
- `docs/pebblelab/CHANGELOG.md`;
- `docs/pebblelab/DEV_JOURNAL.md`;
- `docs/pebblelab/ROADMAP.md`;
- `docs/pebblelab/PHASE_5_COGNITIVE_AGENT_RESYNC_PLAN.md`.

Validation commands:

- `git status`;
- `git branch --show-current`;
- `git pull origin lab/pebblelab-v1`;
- `git log --oneline -12`;
- `swift build`;
- `swift build -c release --product Pebble`;
- `git diff --check`;
- `git diff --cached --check`.

Expected result: docs-only changes keep Swift behavior unchanged. `pebsmoke`
remains optional because no core simulation, runtime, scenario, movement stack,
renderer, resource, registry, save/load, or golden changed.

Results: `swift build`, `swift build -c release --product Pebble`, and
`git diff --check` passed. `pebsmoke` was not run.

Next step: Phase 5.1B — Behavior Loop Contract Fixture Smoke.

## 2026-07-02 — Phase 5.1B behavior loop contract fixture smoke

Objective: implement the first fixture-only cognitive behavior-loop contract
smoke, proving the Phase 5.1A loop contract can be represented with bounded
inputs, decisions, results, memory writes, reports, invariants, metrics, and
events without using the movement stack or mutating World.

Starting point: branch `lab/pebblelab-v1`, commit
`601bde1e94839b2dde52d8763530afc206bf7770`, with Phase 5.1A complete.
Phase 5.0A audited the current `LabAgent` cognition state; Phase 5.1A defined
the behavior-loop contract and reserved movement stack integration for later.

Scenario name: `behavior_loop_contract_fixture_smoke`.

Fixture agents:

- `agent_0`: safety/fear-driven, starts with `seekSafety`;
- `agent_1`: curiosity-driven, starts with `explore`;
- `agent_2`: nearby-agent-observation-driven, starts with
  `observeOtherAgent`.

Loop contract implemented:

- `LabBehaviorLoopInput`;
- `LabBehaviorLoopDecision`;
- `LabBehaviorLoopResult`;
- `LabBehaviorLoopReport`;
- `LabBehaviorLoopInvariantReport`;
- `LabBehaviorLoopDigest`;
- `LabBehaviorLoopMetrics`;
- `LabBehaviorLoopContractFixture`.

Loop behavior: the fixture runs 3 ticks over 3 abstract agents, builds one
input per agent per tick, records one decision per input, applies bounded
abstract effects, writes one bounded memory entry per result, and keeps
movement-intent production at zero.

Metrics: `metrics.json` emits the `behaviorLoop*` prefix, including success,
agents, ticks, decisions, goals selected, goal changes, actions selected,
effects applied, memory entries written, movement intents produced, movement
stack used, mutation flags, physical/Core movement flags, repeatability
failures, and digest equality.

Events:

- `lab_behavior_loop_decision_recorded`;
- `lab_behavior_loop_summary_recorded`.

Invariant report: `behavior_loop_contract_invariant_report.json` includes 39
checks. Validated debug run result: 39 passed, 0 failed.

Digest: `behavior_loop_contract_digest.json` records digest
`cf7de71959833d43`, repeat digest `cf7de71959833d43`, deterministicDigest
true, and digestsEqual true.

Boundary confirmations:

- movementStackUsed = false;
- worldMutated = false;
- terrainMutated = false;
- coreEntityMoved = false;
- physicalPlaceholderMoved = false;
- no route following;
- no full-route execution;
- no persistent route commitment;
- no physical placeholder or Core entity creation;
- no mood, relationships, trust, communication, community, task board,
  Python, LLM, or RL.

Outputs:

- `behavior_loop_contract_report.json`;
- `behavior_loop_contract_invariant_report.json`;
- `behavior_loop_contract_decisions.json`;
- `behavior_loop_contract_digest.json`;
- `metrics.json`;
- `events.ndjson`.

Validation commands:

- `git status`;
- `git branch --show-current`;
- `git pull origin lab/pebblelab-v1`;
- `git log --oneline -12`;
- `swift build`;
- `swift run PebbleLab -- --scenario behavior_loop_contract_fixture_smoke --seed 42 --ticks 3 --out runs/check_behavior_loop_contract_fixture`;
- `swift run PebbleLab -- --scenario agents_basic --seed 42 --agents 3 --ticks 3 --out runs/check_agents_basic_after_behavior_loop_contract`;
- `swift run PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_behavior_loop_contract`;
- `swift build -c release --product Pebble`;
- `swift run -c release pebsmoke`;
- `git diff --check`;
- `git diff --cached --check`.

Results:

- `swift build` passed;
- debug `behavior_loop_contract_fixture_smoke` passed with `success = true`;
- debug `agents_basic` non-regression passed;
- debug `regression_smoke` non-regression passed;
- `swift build -c release --product Pebble` passed;
- `swift run -c release pebsmoke` passed with 456 passed, 0 failed;
- release `PebbleLab` scenario validation was attempted, but production
  `PebbleLab` compilation stalled without further output and was interrupted;
- `git diff --check` passed before staging.

Next step: Phase 5.1C — Behavior Loop Hardening.

## 2026-07-02 — Phase 5.1C behavior loop hardening smoke

Objective: harden the Phase 5.1B behavior-loop contract fixture with
multiple deterministic cognitive v0 cases before any movement stack bridge,
memory retrieval, mood, relationships, communication, community state,
Python, LLM, or RL work.

Starting point: branch `lab/pebblelab-v1`, commit
`deb61d4c0e96af3e3543b9f86270202ebbbdceff`, with
`behavior_loop_contract_fixture_smoke` validated in debug and release core
smoke. Phase 5.1B proved a single contract-shaped fixture; Phase 5.1C checks
that the same loop remains bounded and deterministic across controlled edge
cases.

Scenario name: `behavior_loop_hardening_smoke`.

Hardening cases:

- `baseline_contract_compatible`;
- `seek_safety_priority`;
- `explore_curiosity_priority`;
- `observe_nearby_agent`;
- `idle_fallback`;
- `missing_goal_fallback`;
- `empty_nearby_agents`;
- `memory_already_present`;
- `empty_inventory`;
- `extreme_needs_bounded`;
- `deterministic_order`;
- `digest_repeatability`.

Decisions: the validated debug run produced 22 deterministic decisions over
12 cases. The decisions remain simple abstract actions: `seekSafety`,
`explore`, `observeAgent`, `rest`, and `idle`. Decision records include the
case name, case index, underlying behavior-loop decision, and bounded result.

Metrics: `metrics.json` emits `behaviorLoopHardening*`, including success,
cases, cases passed/failed, decisions, actions selected, effects applied,
memory entries written, movement intents produced, movement stack usage,
World/terrain mutation flags, Core/placeholder movement flags, deterministic
decision order, deterministic digest, digest equality, and repeatability
failures.

Events: `events.ndjson` records the aggregate
`lab_behavior_loop_hardening_recorded` event with success, case counts,
decision/effect/memory totals, movement and mutation flags, digest equality,
and repeatability failures.

Invariant report: `behavior_loop_hardening_invariant_report.json` includes 52
checks. Validated debug run result: 52 passed, 0 failed.

Digest: `behavior_loop_hardening_digest.json` records digest
`757ba317eefe5398`, repeat digest `757ba317eefe5398`, deterministicDigest
true, and digestsEqual true.

Boundary confirmations:

- movementStackUsed = false;
- movementIntentsProduced = 0;
- worldMutated = false;
- terrainMutated = false;
- coreEntityMoved = false;
- physicalPlaceholderMoved = false;
- no World is created for the scenario;
- no route following, full-route execution, pathfinding, reservation runtime,
  mood, relationship, trust, communication, community, task board, Python,
  LLM, or RL is added.

Outputs:

- `behavior_loop_hardening_report.json`;
- `behavior_loop_hardening_invariant_report.json`;
- `behavior_loop_hardening_cases.json`;
- `behavior_loop_hardening_decisions.json`;
- `behavior_loop_hardening_digest.json`;
- `metrics.json`;
- `events.ndjson`.

Validation commands:

- `git status`;
- `git branch --show-current`;
- `git pull origin lab/pebblelab-v1`;
- `git log --oneline -12`;
- `swift build`;
- `swift run PebbleLab -- --scenario behavior_loop_hardening_smoke --seed 42 --ticks 3 --out runs/check_behavior_loop_hardening`;
- `swift run PebbleLab -- --scenario behavior_loop_contract_fixture_smoke --seed 42 --ticks 3 --out runs/check_behavior_loop_contract_after_hardening`;
- `swift run PebbleLab -- --scenario agents_basic --seed 42 --agents 3 --ticks 3 --out runs/check_agents_basic_after_behavior_loop_hardening`;
- `swift run PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_behavior_loop_hardening`;
- `swift build -c release --product Pebble`;
- `swift run -c release pebsmoke`;
- `git diff --check`;
- `git diff --cached --check`.

Results:

- `swift build` passed;
- debug `behavior_loop_hardening_smoke` passed with `success = true`;
- debug `behavior_loop_contract_fixture_smoke` non-regression passed;
- debug `agents_basic` non-regression passed;
- debug `regression_smoke` non-regression passed;
- release `Pebble` build passed;
- release `pebsmoke` passed with 456 passed, 0 failed;
- release `PebbleLab` hardening validation was attempted with a short local
  time limit, reproduced the known silent production compilation stall after
  writing `swift-version--1AB21518FC5DEDBE.txt`, and was terminated rather
  than left running indefinitely;
- diff checks passed.

Next step: Phase 5.2A — Memory Update From Behavior Result Planning.

## 2026-07-02 — Phase 5.2A memory update from behavior result planning

Objective: define the docs-only contract for turning behavior-loop results
into deterministic, bounded memory update proposals before implementing any
new runtime memory system.

Starting point: branch `lab/pebblelab-v1`, commit
`b283a0d779e5efa60d6b0fd29ee89f0d6e05ef26`, with Phase 5.1B and Phase 5.1C
complete. Phase 5.1B proved the behavior-loop contract fixture; Phase 5.1C
hardened it across 12 deterministic cases. Both already report
`memoryEntriesWritten`, but memory does not yet have a dedicated proposal,
acceptance, rejection, write-budget, or retrieval boundary contract.

Current memory audit:

- `LabAgent` stores `memory: [LabMemoryEntry]`;
- `LabMemoryEntry` has `tick`, `type`, `summary`, and `importance`;
- `remember(tick:type:summary:importance:)` appends directly;
- encoded agent snapshots include `memoryCount` and the last 10 entries as
  `recentMemory`;
- current memory is append-only and has no retrieval, query, decay, emotional
  memory, relationship memory, social trust, LLM context, or movement-stack
  feedback bridge.

New planning document:

- `docs/pebblelab/PHASE_5_2A_MEMORY_UPDATE_FROM_BEHAVIOR_RESULT_PLAN.md`.

Contract summary:

- input: behavior-loop result plus tick, agent id, goal/action/effect,
  previous memory count, optional nearby/inventory summaries, and reason;
- output: memory update proposal, accepted/rejected state, rejection reason,
  appendable memory entry when accepted, bounded write count, and before/after
  memory counts;
- v0 write budget: max 1 accepted behavior memory per agent per tick;
- stable ordering: tick, agent id, memory type;
- summaries and importance must be deterministic and bounded.

Future types proposed:

- `LabMemoryUpdateInput`;
- `LabMemoryUpdateProposal`;
- `LabMemoryUpdateResult`;
- `LabMemoryUpdateReport`.

Future memory types v0:

- `behavior_action`;
- `goal_confirmed`;
- `goal_changed`;
- `effect_applied`;
- `nearby_agent_observed`;
- `safety_reaction`;
- `curiosity_reaction`;
- `idle_tick_summary`.

Future metrics/events:

- `memoryUpdate*` metrics;
- `lab_memory_update_recorded`;
- optional `lab_memory_update_summary_recorded`.

Explicit exclusions:

- no Swift runtime change;
- no scenario;
- no runtime metric or event;
- no `LabAgent` change;
- no `LabBehaviorLoop.swift` change;
- no `main.swift` change;
- no movement stack change;
- no memory retrieval;
- no emotional memory;
- no mood, relationships, trust, communication, community, Python, LLM, or RL;
- no World/terrain mutation;
- no Core entity or physical placeholder movement.

Validation commands:

- `git status`;
- `git branch --show-current`;
- `git pull origin lab/pebblelab-v1`;
- `git log --oneline -12`;
- `swift build`;
- `swift build -c release --product Pebble`;
- `git diff --check`;
- `git diff --cached --check`.

Expected result: docs-only changes keep Swift behavior unchanged. `pebsmoke`
is optional because this phase changes no runtime code, scenario, movement
stack, renderer, resources, registries, save/load, or goldens.

Results:

- `swift build` passed;
- `swift build -c release --product Pebble` passed;
- `git diff --check` passed;
- `git diff --cached --check` passed;
- `pebsmoke` was not run for this docs-only phase.

Next step: Phase 5.2B — Memory Update From Behavior Result Fixture Smoke.

## 2026-07-02 — Phase 5.2B memory update from behavior result fixture smoke

Objective: implement the first fixture-only memory update layer from
controlled behavior-loop results, proving result-to-proposal-to-bounded-write
ownership before any retrieval, mood, relationship, movement stack feedback,
communication, Python, LLM, or RL work.

Starting point: branch `lab/pebblelab-v1`, commit
`2de928d58b75d578497867eafb53158fdb777fb4`, with Phase 5.2A complete.
Phase 5.2A defined the v0 contract: behavior result to memory update input,
proposal, accepted/rejected decision, bounded append, before/after snapshot,
report, invariant, digest, metrics, and events.

Scenario name: `memory_update_from_behavior_result_fixture_smoke`.

Behavior results:

- `agent_0`: `seekSafety`, effect `fear -1`;
- `agent_1`: `explore`, effect `curiosity -0.005`;
- `agent_2`: `observeAgent`, effect `curiosity +0.01`.

Proposals:

- accepted `safety_reaction` for `agent_0`;
- rejected duplicate `safety_reaction` for `agent_0` with
  `duplicate_same_tick_agent_memory_type`;
- accepted `curiosity_reaction` for `agent_1`;
- accepted `nearby_agent_observed` for `agent_2`.

Accepted/rejected writes:

- proposals = 4;
- acceptedWrites = 3;
- rejectedWrites = 1;
- maxWritesPerAgentTick = 1;
- bounded = true.

Memory before/after:

- memoryCountBeforeTotal = 0;
- memoryCountAfterTotal = 3;
- each accepted write appends exactly one `LabMemoryEntry`;
- rejected proposal does not append memory.

Metrics: `metrics.json` emits `memoryUpdate*`, including success, agents,
ticks, behavior results, proposals, accepted/rejected writes, before/after
totals, max writes per agent tick, bounded, deterministic order, digest
equality, repeatability failures, mutation flags, movement stack usage, and
Core/placeholder movement flags.

Events:

- `lab_memory_update_recorded`;
- `lab_memory_update_summary_recorded`.

Invariant report: `memory_update_invariant_report.json` includes 40 checks.
Validated debug run result: 40 passed, 0 failed.

Digest: `memory_update_digest.json` records digest `f789a61fc3a3babe`, repeat
digest `f789a61fc3a3babe`, deterministicDigest true, and digestsEqual true.

Boundary confirmations:

- movementStackUsed = false;
- worldMutated = false;
- terrainMutated = false;
- coreEntityMoved = false;
- physicalPlaceholderMoved = false;
- no World is created for the scenario;
- no retrieval, emotional memory, mood, relationships, trust, communication,
  community, task board, route following, pathfinding, reservation runtime,
  Python, LLM, or RL is added.

Outputs:

- `memory_update_report.json`;
- `memory_update_invariant_report.json`;
- `memory_update_proposals.json`;
- `memory_update_agent_memory_snapshot.json`;
- `memory_update_digest.json`;
- `metrics.json`;
- `events.ndjson`.

Validation commands:

- `git status`;
- `git branch --show-current`;
- `git pull origin lab/pebblelab-v1`;
- `git log --oneline -12`;
- `swift build`;
- `swift run PebbleLab -- --scenario memory_update_from_behavior_result_fixture_smoke --seed 42 --ticks 3 --out runs/check_memory_update_from_behavior_result_fixture`;
- `swift run PebbleLab -- --scenario behavior_loop_contract_fixture_smoke --seed 42 --ticks 3 --out runs/check_behavior_loop_contract_after_memory_update`;
- `swift run PebbleLab -- --scenario behavior_loop_hardening_smoke --seed 42 --ticks 3 --out runs/check_behavior_loop_hardening_after_memory_update`;
- `swift run PebbleLab -- --scenario agents_basic --seed 42 --agents 3 --ticks 3 --out runs/check_agents_basic_after_memory_update`;
- `swift run PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_memory_update`;
- `swift build -c release --product Pebble`;
- `swift run -c release pebsmoke`;
- `git diff --check`;
- `git diff --cached --check`.

Results:

- the memory update fixture passed in debug with report success true, 3 agents,
  3 behavior results, 4 proposals, 3 accepted writes, 1 rejected duplicate
  write, memory count total `0 -> 3`, 40 invariant checks passed, stable digest
  `f789a61fc3a3babe`, and `memoryUpdate*` metrics/events written;
- behavior loop contract, behavior loop hardening, `agents_basic`, and
  `regression_smoke` non-regressions passed in debug;
- `swift build`, `swift build -c release --product Pebble`, and
  `swift run -c release pebsmoke` passed, with `pebsmoke` reporting
  456 passed, 0 failed;
- release `PebbleLab` scenario validation was attempted with a 90 second local
  limit, but production `PebbleLab` compilation stalled without further output
  and was interrupted as in prior phases.

Next step: Phase 5.2C — Memory Update Hardening.

## 2026-07-02 — Phase 5.2C memory update hardening smoke

Objective: harden the Phase 5.2B memory update layer with deterministic
fixture-only edge cases before any retrieval, emotional memory, relationship
memory, movement stack feedback, communication, Python, LLM, or RL work.

Starting point: branch `lab/pebblelab-v1`, commit
`ff069b20a509f56ff7828953bc9a995619851cfe`, with Phase 5.2B complete.
Phase 5.2B proved behavior result to memory proposal to bounded write for 3
agents, 4 proposals, 3 accepted writes, and 1 duplicate rejection.

Scenario name: `memory_update_hardening_smoke`.

Hardening cases:

- `baseline_fixture_compatible`;
- `accepted_safety_reaction`;
- `accepted_curiosity_reaction`;
- `accepted_nearby_agent_observed`;
- `duplicate_same_tick_agent_memory_type_rejected`;
- `max_one_write_per_agent_tick_enforced`;
- `invalid_memory_type_rejected`;
- `empty_summary_rejected`;
- `importance_below_bounds_rejected_or_clamped`;
- `importance_above_bounds_rejected_or_clamped`;
- `memory_count_before_after_consistent`;
- `deterministic_order`;
- `digest_repeatability`.

Proposals and writes:

- proposals = 21;
- acceptedWrites = 14;
- rejectedWrites = 7;
- rejected reasons cover duplicate same tick/agent/type, max one write per
  agent/tick, invalid memory type, empty summary, and out-of-bounds
  importance;
- Phase 5.2C chooses rejection, not clamping, for importance outside
  `0.0...1.0`.

Memory before/after:

- memoryCountBeforeTotal = 0;
- memoryCountAfterTotal = 14;
- rejected writes do not append memory;
- maxWritesPerAgentTick = 1;
- bounded = true by tick/agent, not by total agent history.

Metrics: `metrics.json` emits `memoryUpdateHardening*`, including success,
case counts, proposals, accepted/rejected writes, before/after totals, max
writes per agent tick, bounded, deterministic order, digest equality,
repeatability failures, mutation flags, movement stack usage, and
Core/placeholder movement flags.

Events:

- `lab_memory_update_hardening_recorded`.

Invariant report: `memory_update_hardening_invariant_report.json` includes 55
checks. Validated debug run result: 55 passed, 0 failed.

Digest: `memory_update_hardening_digest.json` records digest
`dd497b88e34002f9`, repeat digest `dd497b88e34002f9`, deterministicDigest
true, and digestsEqual true.

Boundary confirmations:

- movementStackUsed = false;
- worldMutated = false;
- terrainMutated = false;
- coreEntityMoved = false;
- physicalPlaceholderMoved = false;
- no World is created for the scenario;
- no retrieval, emotional memory, mood, relationships, trust, communication,
  community, task board, route following, pathfinding, reservation runtime,
  Python, LLM, or RL is added.

Outputs:

- `memory_update_hardening_report.json`;
- `memory_update_hardening_invariant_report.json`;
- `memory_update_hardening_cases.json`;
- `memory_update_hardening_proposals.json`;
- `memory_update_hardening_agent_memory_snapshot.json`;
- `memory_update_hardening_digest.json`;
- `metrics.json`;
- `events.ndjson`.

Validation commands:

- `git status`;
- `git branch --show-current`;
- `git pull origin lab/pebblelab-v1`;
- `git log --oneline -12`;
- `swift build`;
- `swift run PebbleLab -- --scenario memory_update_hardening_smoke --seed 42 --ticks 3 --out runs/check_memory_update_hardening`;
- `swift run PebbleLab -- --scenario memory_update_from_behavior_result_fixture_smoke --seed 42 --ticks 3 --out runs/check_memory_update_fixture_after_hardening`;
- `swift run PebbleLab -- --scenario behavior_loop_contract_fixture_smoke --seed 42 --ticks 3 --out runs/check_behavior_loop_contract_after_memory_hardening`;
- `swift run PebbleLab -- --scenario behavior_loop_hardening_smoke --seed 42 --ticks 3 --out runs/check_behavior_loop_hardening_after_memory_hardening`;
- `swift run PebbleLab -- --scenario agents_basic --seed 42 --agents 3 --ticks 3 --out runs/check_agents_basic_after_memory_hardening`;
- `swift run PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_memory_hardening`;
- `swift build -c release --product Pebble`;
- `swift run -c release pebsmoke`;
- `git diff --check`;
- `git diff --cached --check`.

Results: the memory update hardening fixture passed in debug with report
success true, 13 cases, 13 passed, 0 failed, 21 proposals, 14 accepted writes,
7 rejected writes, memory count total `0 -> 14`, 55 invariant checks passed,
stable digest `dd497b88e34002f9`, and `memoryUpdateHardening*` metrics/event
written. The memory update fixture, behavior loop contract fixture, behavior
loop hardening, `agents_basic`, and `regression_smoke` non-regressions passed
in debug. `swift build`, `swift build -c release --product Pebble`, and
`swift run -c release pebsmoke` passed, with `pebsmoke` reporting 456 passed,
0 failed. Release `PebbleLab` scenario validation was attempted with a 90
second local limit, but production `PebbleLab` compilation stalled without
further output and was interrupted as in prior phases.

Next step: Phase 5.3A — Memory Retrieval Planning.

## 2026-07-02 — Phase 5.3A memory retrieval planning

Objective: define the docs-only contract for bounded, deterministic memory
retrieval before any runtime retrieval fixture, behavior-loop integration,
mood, relationships, movement stack feedback, Python, LLM, embeddings, or RL.

Starting point: branch `lab/pebblelab-v1`, commit
`52b6fa6913a0919b1b08c5b2b3db88fa6b713fdd`, with Phase 5.2C complete.
Phase 5.2B added fixture-only memory update from behavior results, and Phase
5.2C hardened accepted/rejected writes, max one write per agent/tick, allowed
types, importance bounds, stable ordering, snapshots, digest, metrics, and
events.

Current memory write state:

- `LabAgent.memory` is `[LabMemoryEntry]`;
- `LabMemoryEntry` has `tick`, `type`, `summary`, and `importance`;
- `remember(tick:type:summary:importance:)` appends entries;
- encoded agent output includes `memoryCount` and `recentMemory`;
- memory update fixtures can now produce accepted/rejected proposals and
  before/after memory snapshots.

Memory retrieval v0 contract:

- input: agent id, tick, memory entries, query kind, optional type filter,
  max results, recency window, importance threshold, and deterministic sort
  config;
- output: ranked retrieved records, retrieval summary, empty-result support,
  and deterministic digest;
- read-only boundary: no memory writes and no memory mutation.

Proposed types:

- `LabMemoryRetrievalQuery`;
- `LabMemoryRetrievedRecord`;
- `LabMemoryRetrievalResult`;
- `LabMemoryRetrievalReport`.

Query kinds v0:

- `recent`;
- `important`;
- `by_type`;
- `safety_related`;
- `curiosity_related`;
- `nearby_agent_related`.

Scoring v0: deterministic score from bounded importance, bounded recency
bonus, and fixed type-match bonus. Stable tie-breaks should use score, tick,
memory index, memory type, and summary. No random values, embeddings, LLM
calls, or unordered-container iteration are allowed.

Bounded retrieval rules:

- maxResults bounded, recommended `1...5`;
- max considered memories bounded in the fixture;
- ranks contiguous;
- empty result covered;
- retrieval is read-only;
- no World, terrain, movement stack, Core entity, physical placeholder, save,
  load, renderer, resource, registry, or golden changes.

Future metrics/events:

- `memoryRetrieval*` metrics;
- `lab_memory_retrieval_recorded`;
- optional `lab_memory_retrieval_summary_recorded`.

Future invariant report: should cover scenario, seed, positive queries,
bounded considered/retrieved memory counts, empty result coverage, maxResults,
contiguous ranks, bounded scores, deterministic order, digest equality,
repeatability failures zero, memory not mutated, no World/terrain mutation, no
movement stack, outputs, metrics, events, and success contract.

Relationship notes:

- memory update owns accepted/rejected writes;
- retrieval only reads accepted memory entries or controlled snapshots;
- behavior loop may later receive retrieval summaries, but not in Phase 5.3A
  and probably not in the first 5.3B fixture;
- mood, emotional memory, relationships, trust, social memory, LLM context,
  Python, and RL remain later systems.

Validation commands:

- `git status`;
- `git branch --show-current`;
- `git pull origin lab/pebblelab-v1`;
- `git log --oneline -12`;
- `swift build`;
- `swift build -c release --product Pebble`;
- `git diff --check`;
- `git diff --cached --check`.

Expected result: docs-only changes keep Swift runtime behavior unchanged.
`pebsmoke` is optional and not required unless extra confidence is needed.

Results:

- `swift build` passed;
- `swift build -c release --product Pebble` passed;
- `git diff --check` passed;
- `git diff --cached --check` passed;
- no Swift, runtime, scenario, movement stack, renderer, resource, registry,
  save/load, golden, or PebbleCore files were modified;
- `pebsmoke` was not run for this docs-only phase.

Next step: Phase 5.3B — Memory Retrieval Fixture Smoke.

## 2026-07-02 — Phase 5.3B memory retrieval fixture smoke

Objective: implement the first fixture-only memory retrieval layer from
controlled memory snapshots, proving deterministic read-only query, scoring,
ranking, reporting, metrics, events, and digest behavior before retrieval can
influence goals, mood, relationships, movement stack feedback, Python, LLM,
embeddings, or RL.

Starting point: branch `lab/pebblelab-v1`, commit
`1923b23dc916af7a0fe8a7c1c4c0b7f7b629c877`, with Phase 5.3A complete.
Phase 5.3A defined the retrieval contract: memory entries to query, ranked
retrieved records, retrieval summary, bounded results, stable scoring,
read-only memory, and future `memoryRetrieval*` metrics/events.

Scenario name: `memory_retrieval_fixture_smoke`.

Memory snapshots:

- 3 agents;
- 8 total memories;
- `agent_0`: `safety_reaction`, `behavior_action`, `idle_tick_summary`;
- `agent_1`: `curiosity_reaction`, `effect_applied`, `goal_confirmed`;
- `agent_2`: `nearby_agent_observed`, `behavior_action`.

Query kinds:

- `recent`;
- `important`;
- `by_type`;
- `safety_related`;
- `curiosity_related`;
- `nearby_agent_related`.

Scoring:

- score = bounded importance + bounded recency bonus + fixed type-match bonus;
- no random values;
- no embeddings;
- no LLM summary;
- stable tie-breaks by score, age, memory index, memory type, and summary.

Retrieval results:

- queries = 7;
- availableMemories = 8;
- consideredMemories = 8;
- retrievedMemories = 7;
- maxResults = 2;
- ranks are contiguous;
- scores are bounded;
- deterministicOrder = true.

Empty result: one `by_type` query for `agent_2` requests `safety_reaction`
and returns no records, with `emptyResult = true`.

Metrics: `metrics.json` emits `memoryRetrieval*`, including success, agents,
queries, available/considered/retrieved memories, empty results, max results,
bounded, deterministic order, digest equality, repeatability failures, memory
mutation, mutation flags, and movement stack usage.

Events:

- `lab_memory_retrieval_recorded`;
- `lab_memory_retrieval_summary_recorded`.

Invariant report: `memory_retrieval_invariant_report.json` includes 39 checks.
Validated debug run result: 39 passed, 0 failed.

Digest: `memory_retrieval_digest.json` records digest
`a82037f649caf921`, repeat digest `a82037f649caf921`, deterministicDigest
true, and digestsEqual true.

Boundary confirmations:

- memoryMutated = false;
- movementStackUsed = false;
- worldMutated = false;
- terrainMutated = false;
- no World is created for the scenario;
- no memory write, mood, relationships, trust, communication, community, task
  board, route following, pathfinding, reservation runtime, embeddings,
  Python, LLM, or RL is added.

Outputs:

- `memory_retrieval_report.json`;
- `memory_retrieval_invariant_report.json`;
- `memory_retrieval_queries.json`;
- `memory_retrieval_results.json`;
- `memory_retrieval_digest.json`;
- `metrics.json`;
- `events.ndjson`.

Validation commands:

- `git status`;
- `git branch --show-current`;
- `git pull origin lab/pebblelab-v1`;
- `git log --oneline -12`;
- `swift build`;
- `swift run PebbleLab -- --scenario memory_retrieval_fixture_smoke --seed 42 --ticks 3 --out runs/check_memory_retrieval_fixture`;
- `swift run PebbleLab -- --scenario memory_update_from_behavior_result_fixture_smoke --seed 42 --ticks 3 --out runs/check_memory_update_fixture_after_retrieval`;
- `swift run PebbleLab -- --scenario memory_update_hardening_smoke --seed 42 --ticks 3 --out runs/check_memory_update_hardening_after_retrieval`;
- `swift run PebbleLab -- --scenario behavior_loop_contract_fixture_smoke --seed 42 --ticks 3 --out runs/check_behavior_loop_contract_after_memory_retrieval`;
- `swift run PebbleLab -- --scenario behavior_loop_hardening_smoke --seed 42 --ticks 3 --out runs/check_behavior_loop_hardening_after_memory_retrieval`;
- `swift run PebbleLab -- --scenario agents_basic --seed 42 --agents 3 --ticks 3 --out runs/check_agents_basic_after_memory_retrieval`;
- `swift run PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_memory_retrieval`;
- `swift build -c release --product Pebble`;
- `swift run -c release pebsmoke`;
- `git diff --check`;
- `git diff --cached --check`.

Results: the memory retrieval fixture passed in debug with report success
true, 3 agents, 7 queries, 8 available memories, 8 considered memories, 7
retrieved memories, 1 empty result, maxResults 2, memoryMutated false, 39
invariant checks passed, stable digest `a82037f649caf921`, and
`memoryRetrieval*` metrics/events written. The memory update fixture, memory
update hardening, behavior loop contract fixture, behavior loop hardening,
`agents_basic`, and `regression_smoke` non-regressions passed in debug.
`swift build`, `swift build -c release --product Pebble`, and
`swift run -c release pebsmoke` passed, with `pebsmoke` reporting 456 passed,
0 failed. Release `PebbleLab` scenario validation was attempted with a 90
second local limit, but production `PebbleLab` compilation stalled without
further output and was interrupted as in prior phases.

Next step: Phase 5.3C — Memory Retrieval Hardening.

## 2026-07-02 — Phase 5.3C memory retrieval hardening smoke

Objective: harden the fixture-only memory retrieval layer added in Phase 5.3B
with deterministic boundary cases before retrieved memories can influence goal
selection, mood, relationships, movement stack feedback, Python, LLM,
embeddings, or RL.

Starting point: branch `lab/pebblelab-v1`, commit
`36fa16247b0e25d9b0396545ebce4951f1406c23`, with Phase 5.3B complete.
Phase 5.3B proved read-only retrieval from controlled memory snapshots. Phase
5.3C keeps that model fixture-only and expands the boundary coverage.

Scenario name: `memory_retrieval_hardening_smoke`.

Hardening cases:

- `baseline_fixture_compatible`;
- `recent_query_orders_by_recency`;
- `important_query_orders_by_importance`;
- `by_type_filter_matches_only_allowed_type`;
- `safety_related_matches_safety_reaction`;
- `curiosity_related_matches_curiosity_reaction`;
- `nearby_agent_related_matches_nearby_agent_observed`;
- `empty_result_allowed`;
- `max_results_respected`;
- `max_results_out_of_bounds_clamped_or_rejected`;
- `min_importance_filter_respected`;
- `recency_window_filter_respected`;
- `scores_bounded`;
- `ranks_contiguous`;
- `deterministic_tie_break`;
- `unsorted_input_stable_output`;
- `invalid_query_kind_rejected`;
- `memory_not_mutated`;
- `digest_repeatability`.

Query kinds: `recent`, `important`, `by_type`, `safety_related`,
`curiosity_related`, `nearby_agent_related`, plus one intentionally invalid
query kind that is rejected with a failed query result inside an expected
passing hardening case.

Scoring remains v0 and deterministic:

- bounded importance component;
- bounded recency bonus;
- fixed type/query match bonus;
- stable tie-breaks by score, age, memory index, memory type, and summary;
- no random, embeddings, LLM summary, or semantic retrieval.

Retrieval results:

- cases = 19;
- casesPassed = 19;
- casesFailed = 0;
- queries = 23;
- availableMemories = 56;
- consideredMemories = 37;
- retrievedMemories = 34;
- emptyResults = 3;
- maxResults = 5;
- maxResults requests above 5 are clamped to 5;
- bounded = true;
- deterministicOrder = true.

Metrics: `metrics.json` emits `memoryRetrievalHardening*`, including success,
case counts, query counts, available/considered/retrieved memories, empty
results, max results, bounded, deterministic order, mutation flags, digest
equality, and repeatability failures.

Events: `events.ndjson` emits `lab_memory_retrieval_hardening_recorded`.

Invariant report: `memory_retrieval_hardening_invariant_report.json` includes
61 checks covering the scenario contract, every hardening case, query/result
bounds, empty results, max results, rank contiguity, score bounds, invalid
query rejection, deterministic order, read-only memory, no movement stack, no
World/terrain mutation, output files, metrics/events, docs, and success
contract.

Digest: `memory_retrieval_hardening_digest.json` records digest
`e72e89cc8c24a53e`, repeat digest `e72e89cc8c24a53e`,
deterministicDigest true, and digestsEqual true.

Boundary confirmations:

- memoryMutated = false;
- movementStackUsed = false;
- worldMutated = false;
- terrainMutated = false;
- no memory write;
- no World is created for the scenario;
- no route following, pathfinding, reservation runtime, mood, relationships,
  trust, communication, community state, task board, embeddings, Python, LLM,
  or RL is added.

Outputs:

- `memory_retrieval_hardening_report.json`;
- `memory_retrieval_hardening_invariant_report.json`;
- `memory_retrieval_hardening_cases.json`;
- `memory_retrieval_hardening_queries.json`;
- `memory_retrieval_hardening_results.json`;
- `memory_retrieval_hardening_digest.json`;
- `metrics.json`;
- `events.ndjson`.

Validation commands:

- `git status`;
- `git branch --show-current`;
- `git pull origin lab/pebblelab-v1`;
- `git log --oneline -12`;
- `swift build`;
- `swift build -c release --product Pebble`;
- `swift run PebbleLab -- --scenario memory_retrieval_hardening_smoke --seed 42 --ticks 3 --out runs/check_memory_retrieval_hardening`;
- `swift run PebbleLab -- --scenario memory_retrieval_fixture_smoke --seed 42 --ticks 3 --out runs/check_memory_retrieval_fixture_after_hardening`;
- `swift run PebbleLab -- --scenario memory_update_from_behavior_result_fixture_smoke --seed 42 --ticks 3 --out runs/check_memory_update_fixture_after_memory_retrieval_hardening`;
- `swift run PebbleLab -- --scenario memory_update_hardening_smoke --seed 42 --ticks 3 --out runs/check_memory_update_hardening_after_memory_retrieval_hardening`;
- `swift run PebbleLab -- --scenario behavior_loop_contract_fixture_smoke --seed 42 --ticks 3 --out runs/check_behavior_loop_contract_after_memory_retrieval_hardening`;
- `swift run PebbleLab -- --scenario behavior_loop_hardening_smoke --seed 42 --ticks 3 --out runs/check_behavior_loop_hardening_after_memory_retrieval_hardening`;
- `swift run PebbleLab -- --scenario agents_basic --seed 42 --agents 3 --ticks 3 --out runs/check_agents_basic_after_memory_retrieval_hardening`;
- `swift run PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_memory_retrieval_hardening`;
- `swift run -c release pebsmoke`;
- `git diff --check`;
- `git diff --cached --check`.

Results: the memory retrieval hardening fixture passed in debug with report
success true, 19 cases, 19 passed, 0 failed, 23 queries, 56 available memories,
37 considered memories, 34 retrieved memories, 3 empty results, maxResults 5,
memoryMutated false, 61 invariant checks passed, stable digest
`e72e89cc8c24a53e`, and `memoryRetrievalHardening*` metrics/events written.
The memory retrieval fixture, memory update fixture, memory update hardening,
behavior loop contract fixture, behavior loop hardening, `agents_basic`, and
`regression_smoke` non-regressions passed in debug. `swift build`,
`swift build -c release --product Pebble`, and `swift run -c release
pebsmoke` passed, with `pebsmoke` reporting 456 passed, 0 failed. Direct
release `PebbleLab` scenario validation was attempted with a 90 second local
limit, but production `PebbleLab` compilation stalled after planning/source
emission and was interrupted as in prior phases.

Next step: Phase 5.4A — Goal Selection From Retrieved Memory Planning.

## 2026-07-02 — Phase 5.4A goal selection from retrieved memory planning

Objective: define the docs-only contract for turning ranked retrieved memories
into bounded goal candidates and a selected goal proposal, without modifying
runtime behavior.

Starting point: branch `lab/pebblelab-v1`, commit
`7bb00a314837d6035da346b1bec5050af307a6fa`, with Phase 5.3C complete.
Phase 5.3C proved memory retrieval can be read-only, bounded, deterministic,
ranked, and auditable. Phase 5.4A prepares the next bridge:

```text
retrieved memories
-> goal candidates
-> ranked goal candidates
-> selected goal proposal
-> future behavior loop integration
```

Current goal state from code:

- `LabAgent.currentGoal: LabGoal`;
- `LabGoalKind`: `idle`, `rest`, `seekSafety`, `explore`,
  `observeOtherAgent`;
- `LabGoal`: `kind`, `reason`, `startedAtTick`, `urgency`;
- `LabAgent.selectGoal(tick:)` is deterministic and priority-ordered by
  health, fear, safety, fatigue, curiosity, nearby agents, and idle fallback;
- `selectGoal` currently does not read retrieved memories;
- behavior-loop fixtures use string goal decisions, but do not consume memory
  retrieval results.

Contract defined:

- `LabGoalSelectionFromMemoryInput`;
- `LabGoalCandidate`;
- `LabGoalSelectionFromMemoryDecision`;
- `LabGoalSelectionFromMemoryReport`.

Memory-to-goal mapping v0:

- `safety_reaction` -> `seekSafety`;
- `curiosity_reaction` -> `explore`;
- `nearby_agent_observed` -> `observeOtherAgent`;
- `idle_tick_summary` -> `idle`;
- `goal_confirmed` -> current or confirmed goal when explicitly known;
- `goal_changed` -> prior selected goal only when safely represented;
- `behavior_action` -> known v0 goal only for direct safe mappings;
- `effect_applied` -> known v0 goal only for direct safe mappings.

Scoring v0:

- bounded memory score component;
- need/fear component;
- currentGoal continuity component;
- source priority component;
- stable tie-break by score, priority, goal, source, and supporting memory
  types;
- no random, embeddings, LLM, semantic guessing, or unordered-container
  influence.

Bounded candidate rules:

- maxCandidates should be bounded, likely `1...5`;
- duplicate goals merged;
- selectedGoal always present;
- unchanged goal and empty retrieval allowed;
- no memory mutation;
- no behavior action execution;
- no movement stack;
- no World or terrain mutation.

Relationship to memory retrieval: goal selection consumes retrieval outputs and
does not rerun retrieval. Retrieval remains responsible for query/ranking;
goal selection owns candidate mapping/scoring.

Relationship to behavior loop: future behavior-loop input may receive a
selectedGoal, reason, memoryInfluenceSummary, currentGoal continuity decision,
and supporting memory counts. Phase 5.4B should remain fixture-only before
normal behavior-loop integration.

Relationship to mood/relations/LLM: goal selection from memory is a prerequisite
for mood, emotional memory, relationships, trust, social plans, and LLM context
building, but none of those systems are part of this phase or the immediate
fixture.

Future metrics prefix: `goalSelectionMemory*`.

Future events:

- `lab_goal_selection_memory_recorded`;
- optional `lab_goal_selection_memory_summary_recorded`.

Future invariant areas:

- scenario and seed;
- decisions and candidates;
- selected goal present and known;
- goal changes and unchanged goals;
- memory-influenced and empty-retrieval cases;
- maxCandidates;
- duplicate merge;
- bounded scores;
- deterministic ordering;
- digest equality;
- memory not mutated;
- no World/terrain mutation;
- no movement stack;
- no behavior action execution;
- outputs, metrics, and events written.

Outputs:

- `PHASE_5_4A_GOAL_SELECTION_FROM_RETRIEVED_MEMORY_PLAN.md`;
- updated changelog;
- updated dev journal;
- updated roadmap;
- updated Phase 5 cognitive resync plan;
- updated Phase 5.3A memory retrieval plan.

Validation commands:

- `git status`;
- `git branch --show-current`;
- `git pull origin lab/pebblelab-v1`;
- `git log --oneline -12`;
- `swift build`;
- `swift build -c release --product Pebble`;
- `git diff --check`;
- `git diff --cached --check`.

Results: docs-only phase. No Swift files were modified, no runtime behavior was
changed, no scenario was added, no metrics/events runtime were added, and no
movement stack, World, renderer, resource, registry, save/load, golden, or
PebbleCore files were modified. `swift build -c release --product Pebble`,
`git diff --check`, and `git diff --cached --check` passed. `swift build` was
attempted twice, compiled through the PebbleLab sources, then remained
silent after PebbleLab compile/link output and was interrupted to avoid leaving
a stuck local process. No Swift file was changed in this phase. `pebsmoke` was
not run because this phase is docs-only.

Next step: Phase 5.4B — Goal Selection From Retrieved Memory Fixture Smoke.

## 2026-07-02 — Phase 5.4B goal selection from retrieved memory fixture smoke

Objective: implement the first fixture-only runtime layer that turns
controlled retrieved memories into bounded goal candidates and selected goal
proposals, without executing behavior actions or integrating into normal
behavior runtime.

Starting point: branch `lab/pebblelab-v1`, commit
`b9605601cbaaaca1abafe1ebab25f32a6587456a`, with Phase 5.4A complete.
Phase 5.4A defined the contract for retrieved memories -> goal candidates ->
selected goal proposal. Phase 5.4B implements that contract as an isolated
fixture.

Scenario name: `goal_selection_from_memory_fixture_smoke`.

Memory-to-goal mapping:

- `safety_reaction` -> `seekSafety`;
- `curiosity_reaction` -> `explore`;
- `nearby_agent_observed` -> `observeOtherAgent`;
- `idle_tick_summary` -> `idle`;
- `goal_confirmed` / `goal_changed` remain limited to known current/confirmed
  goals;
- `behavior_action` / `effect_applied` only map through direct safe v0 matches
  in the fixture.

Candidates and decisions:

- 5 controlled agent inputs;
- 5 decisions;
- 9 candidates;
- selectedGoals = 5;
- goalChanges = 4;
- unchangedGoals = 1;
- memoryInfluencedDecisions = 4;
- emptyRetrievalDecisions = 1;
- duplicate `explore` candidates merge into one candidate with increased
  supportingMemoryCount.

Scoring:

- candidate score = memory score component + need/fear component +
  currentGoal continuity component + source priority component;
- score is bounded;
- safety/fear can outrank curiosity;
- currentGoal continuity is a bonus, not a hard lock;
- stable tie-break by score, priority, goal, source, and supporting memory
  types;
- no random, embeddings, LLM, or semantic guessing.

Empty retrieval: the empty retrieval fixture input keeps its current `explore`
goal, producing `goalChanged = false` and `memoryInfluenceApplied = false`.

Metrics: `metrics.json` emits `goalSelectionMemory*`, including success,
agent/decision/candidate counts, selected goals, goal changes, unchanged goals,
memory-influenced decisions, empty retrieval decisions, maxCandidates, bounded,
deterministic order, digest equality, repeatability failures, memory mutation,
World/terrain mutation, movement stack usage, and behavior action execution.

Events:

- `lab_goal_selection_memory_recorded`;
- `lab_goal_selection_memory_summary_recorded`.

Invariant report: `goal_selection_memory_invariant_report.json` includes 42
checks. Validated debug run result: 42 passed, 0 failed.

Digest: `goal_selection_memory_digest.json` records digest
`bad8ecf0fcfa0738`, repeat digest `bad8ecf0fcfa0738`, deterministicDigest
true, and digestsEqual true.

Boundary confirmations:

- behaviorActionExecuted = false;
- memoryMutated = false;
- movementStackUsed = false;
- worldMutated = false;
- terrainMutated = false;
- no World is created for the scenario;
- no retrieval rerun, behavior-loop integration, memory write, mood,
  relationships, trust, communication, community, task board, route following,
  pathfinding, reservation runtime, embeddings, Python, LLM, or RL is added.

Outputs:

- `goal_selection_memory_report.json`;
- `goal_selection_memory_invariant_report.json`;
- `goal_selection_memory_candidates.json`;
- `goal_selection_memory_decisions.json`;
- `goal_selection_memory_digest.json`;
- `metrics.json`;
- `events.ndjson`.

Validation commands:

- `git status`;
- `git branch --show-current`;
- `git pull origin lab/pebblelab-v1`;
- `git log --oneline -12`;
- `swift build`;
- `swift run PebbleLab -- --scenario goal_selection_from_memory_fixture_smoke --seed 42 --ticks 3 --out runs/check_goal_selection_memory_fixture`;
- `swift run PebbleLab -- --scenario memory_retrieval_fixture_smoke --seed 42 --ticks 3 --out runs/check_memory_retrieval_fixture_after_goal_selection_memory`;
- `swift run PebbleLab -- --scenario memory_retrieval_hardening_smoke --seed 42 --ticks 3 --out runs/check_memory_retrieval_hardening_after_goal_selection_memory`;
- `swift run PebbleLab -- --scenario memory_update_from_behavior_result_fixture_smoke --seed 42 --ticks 3 --out runs/check_memory_update_fixture_after_goal_selection_memory`;
- `swift run PebbleLab -- --scenario memory_update_hardening_smoke --seed 42 --ticks 3 --out runs/check_memory_update_hardening_after_goal_selection_memory`;
- `swift run PebbleLab -- --scenario behavior_loop_contract_fixture_smoke --seed 42 --ticks 3 --out runs/check_behavior_loop_contract_after_goal_selection_memory`;
- `swift run PebbleLab -- --scenario behavior_loop_hardening_smoke --seed 42 --ticks 3 --out runs/check_behavior_loop_hardening_after_goal_selection_memory`;
- `swift run PebbleLab -- --scenario agents_basic --seed 42 --agents 3 --ticks 3 --out runs/check_agents_basic_after_goal_selection_memory`;
- `swift run PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_goal_selection_memory`;
- `swift build -c release --product Pebble`;
- `swift run -c release pebsmoke`;
- `git diff --check`;
- `git diff --cached --check`.

Results: the goal selection from memory fixture passed in debug with report
success true, 5 agents, 5 decisions, 9 candidates, 5 selected goals, 4 goal
changes, 1 unchanged goal, 4 memory-influenced decisions, 1 empty retrieval
decision, maxCandidates 5, memoryMutated false, behaviorActionExecuted false,
42 invariant checks passed, stable digest `bad8ecf0fcfa0738`, and
`goalSelectionMemory*` metrics/events written. The memory retrieval fixture,
memory retrieval hardening, memory update fixture, memory update hardening,
behavior loop contract fixture, behavior loop hardening, `agents_basic`, and
`regression_smoke` non-regressions passed in debug. `swift build`,
`swift build -c release --product Pebble`, and `swift run -c release
pebsmoke` passed, with `pebsmoke` reporting 456 passed, 0 failed. Direct
release `PebbleLab` scenario validation was attempted with a 90 second local
limit, but production `PebbleLab` compilation stalled after planning/source
emission and was interrupted as in prior runtime fixture phases.

Next step: Phase 5.4C — Goal Selection From Retrieved Memory Hardening.

## 2026-07-02 — Phase 5.4C goal selection from retrieved memory hardening smoke

Objective: harden `LabGoalSelectionMemory` with a bounded fixture scenario
covering the main edge cases before any behavior-loop integration.

Starting point: branch `lab/pebblelab-v1`, commit
`32890bee02c47a4716766406453fbebcf68b8a8e`, with Phase 5.4B complete.
Phase 5.4B proved the first fixture-only bridge from provided retrieved
memories to goal candidates and selected goal proposals. Phase 5.4C keeps the
same boundary and expands coverage.

Scenario name: `goal_selection_from_memory_hardening_smoke`.

Hardening cases:

- baseline fixture compatibility with 5.4B;
- `safety_reaction` selects `seekSafety`;
- `curiosity_reaction` selects `explore`;
- `nearby_agent_observed` selects `observeOtherAgent`;
- `idle_tick_summary` selects `idle`;
- empty retrieval keeps currentGoal;
- currentGoal continuity bonus;
- duplicate candidate merge;
- maxCandidates respected;
- maxCandidates above the v0 limit is clamped to 5;
- scores bounded;
- deterministic tie-break;
- unsorted input stable output;
- conflicting safety and curiosity prioritizes safety when fear is high;
- low-confidence memory does not override stronger currentGoal pressure;
- unknown memory type ignored;
- unknown goal not selected;
- unchanged goal covered;
- memory influence reason required;
- behavior action not executed;
- memory not mutated;
- retrieval not rerun;
- digest repeatability.

Memory-to-goal mapping:

- `safety_reaction` -> `seekSafety`;
- `curiosity_reaction` -> `explore`;
- `nearby_agent_observed` -> `observeOtherAgent`;
- `idle_tick_summary` -> `idle`;
- `goal_confirmed` / `goal_changed` remain limited to known current goals;
- `behavior_action` / `effect_applied` only map through direct safe v0 string
  matches.

Candidates and decisions:

- 23 cases;
- 22 decisions;
- 43 candidates;
- selectedGoals = 22;
- goalChanges = 15;
- unchangedGoals = 7;
- memoryInfluencedDecisions = 15;
- emptyRetrievalDecisions = 3;
- duplicate goals are merged and supportingMemoryCount increases.

Scoring:

- candidate score = memory score component + need/fear component +
  currentGoal continuity component + source priority component;
- score is bounded to 0...3;
- safety/fear can outrank curiosity;
- currentGoal continuity is a bonus, not a hard lock;
- stable tie-break by score, priority, goal, source, and supporting memory
  types;
- no random, embeddings, LLM, or semantic guessing.

Conflict handling: a case with safety and curiosity memories plus high fear
selects `seekSafety`.

Unknown memory/goal handling: unknown memory types are ignored, and the
hardening fixture sanitizes unknown current goals to the known v0 fallback
`idle` so an unknown goal is never selected.

Metrics: `metrics.json` emits `goalSelectionMemoryHardening*`, including
success, case counts, decisions, candidates, selected goals, goal changes,
unchanged goals, influenced decisions, empty retrieval decisions,
maxCandidates, bounded, deterministic order, behavior action execution,
memory mutation, retrieval rerun, movement stack usage, World/terrain mutation,
digest equality, and repeatability failures.

Events:

- `lab_goal_selection_memory_hardening_recorded`.

Invariant report: `goal_selection_memory_hardening_invariant_report.json`
includes 70 checks. Validated debug run result: 70 passed, 0 failed.

Digest: `goal_selection_memory_hardening_digest.json` records digest
`d5001cc2acdd000a`, repeat digest `d5001cc2acdd000a`, deterministicDigest
true, and digestsEqual true.

Boundary confirmations:

- behaviorActionExecuted = false;
- memoryMutated = false;
- retrievalRerun = false;
- movementStackUsed = false;
- worldMutated = false;
- terrainMutated = false;
- no World is created for the scenario;
- no behavior-loop integration, memory write, mood, relationships, trust,
  communication, community, task board, route following, pathfinding,
  reservation runtime, embeddings, Python, LLM, or RL is added.

Outputs:

- `goal_selection_memory_hardening_report.json`;
- `goal_selection_memory_hardening_invariant_report.json`;
- `goal_selection_memory_hardening_cases.json`;
- `goal_selection_memory_hardening_candidates.json`;
- `goal_selection_memory_hardening_decisions.json`;
- `goal_selection_memory_hardening_digest.json`;
- `metrics.json`;
- `events.ndjson`.

Validation commands:

- `git status`;
- `git branch --show-current`;
- `git pull origin lab/pebblelab-v1`;
- `git log --oneline -12`;
- `swift build`;
- `swift run PebbleLab -- --scenario goal_selection_from_memory_hardening_smoke --seed 42 --ticks 3 --out runs/check_goal_selection_memory_hardening`;
- `swift run PebbleLab -- --scenario goal_selection_from_memory_fixture_smoke --seed 42 --ticks 3 --out runs/check_goal_selection_memory_fixture_after_hardening`;
- `swift run PebbleLab -- --scenario memory_retrieval_fixture_smoke --seed 42 --ticks 3 --out runs/check_memory_retrieval_fixture_after_goal_selection_memory_hardening`;
- `swift run PebbleLab -- --scenario memory_retrieval_hardening_smoke --seed 42 --ticks 3 --out runs/check_memory_retrieval_hardening_after_goal_selection_memory_hardening`;
- `swift run PebbleLab -- --scenario memory_update_from_behavior_result_fixture_smoke --seed 42 --ticks 3 --out runs/check_memory_update_fixture_after_goal_selection_memory_hardening`;
- `swift run PebbleLab -- --scenario memory_update_hardening_smoke --seed 42 --ticks 3 --out runs/check_memory_update_hardening_after_goal_selection_memory_hardening`;
- `swift run PebbleLab -- --scenario behavior_loop_contract_fixture_smoke --seed 42 --ticks 3 --out runs/check_behavior_loop_contract_after_goal_selection_memory_hardening`;
- `swift run PebbleLab -- --scenario behavior_loop_hardening_smoke --seed 42 --ticks 3 --out runs/check_behavior_loop_hardening_after_goal_selection_memory_hardening`;
- `swift run PebbleLab -- --scenario agents_basic --seed 42 --agents 3 --ticks 3 --out runs/check_agents_basic_after_goal_selection_memory_hardening`;
- `swift run PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_goal_selection_memory_hardening`;
- `swift build -c release --product Pebble`;
- `swift run -c release pebsmoke`;
- `git diff --check`;
- `git diff --cached --check`.

Results: the goal selection from memory hardening scenario passed in debug
with report success true, 23 cases, 23 cases passed, 0 cases failed, 22
decisions, 43 candidates, 22 selected goals, 15 goal changes, 7 unchanged
goals, 15 memory-influenced decisions, 3 empty retrieval decisions,
maxCandidates 4, behaviorActionExecuted false, memoryMutated false,
retrievalRerun false, movementStackUsed false, worldMutated false,
terrainMutated false, 70 invariant checks passed, stable digest
`d5001cc2acdd000a`, and `goalSelectionMemoryHardening*` metrics/events
written. Non-regression scenarios for goal selection fixture, memory
retrieval fixture/hardening, memory update fixture/hardening, behavior loop
contract/hardening, `agents_basic`, and `regression_smoke` passed in debug.
`swift build`, `swift build -c release --product Pebble`, and `swift run -c
release pebsmoke` passed, with `pebsmoke` reporting 456 passed, 0 failed.
Direct release `PebbleLab` scenario validation was attempted with a local
timeout, but production `PebbleLab` compilation again stalled silently and was
interrupted as in prior runtime fixture phases.

Next step: Phase 5.5A — Behavior Loop Memory-Goal Bridge Planning.

## 2026-07-02 — Phase 5.5A behavior loop memory-goal bridge planning

Objective: define the docs-only contract for a future bridge that lets the
behavior loop consume provided retrieved-memory goal-selection evidence and
produce a memory-informed selected goal, abstract action, and behavior result.

Starting point: branch `lab/pebblelab-v1`, commit
`00830b23cbe0515745c7a39542484b4a9d17e3ae`, with Phase 5.4C complete.
Phase 5.1B/5.1C created and hardened the behavior loop fixtures. Phase
5.2B/5.2C created and hardened memory update. Phase 5.3B/5.3C created and
hardened read-only retrieval. Phase 5.4B/5.4C created and hardened goal
selection from retrieved memory. These components are still isolated fixtures.

New document:

- `PHASE_5_5A_BEHAVIOR_LOOP_MEMORY_GOAL_BRIDGE_PLAN.md`.

Bridge contract v0:

- input: agent snapshot, behavior-loop input, optional retrieved memory result
  summary, optional goal selection memory decision, currentGoal,
  needs/fear/health summary, tick, maxCandidates, maxRetrievedMemories;
- output: bridge decision, goalBefore, memorySuggestedGoal,
  selectedGoalForBehaviorLoop, goalChangedByMemory, selectedAction,
  actionReason, behavior result summary, memory influence summary, empty
  retrieval marker, boundary flags, deterministic digest;
- no behavior action execution;
- no memory write or mutation;
- no retrieval rerun;
- no movement stack;
- no World/terrain mutation.

Proposed future types:

- `LabBehaviorLoopMemoryGoalBridgeInput`;
- `LabBehaviorLoopMemoryGoalBridgeDecision`;
- `LabBehaviorLoopMemoryGoalBridgeReport`.

Flow v0:

1. Build behavior-loop input.
2. Consume provided retrieval result summary.
3. Consume provided goal-selection-from-memory decision.
4. Decide `selectedGoalForBehaviorLoop`.
5. Select an abstract action using existing behavior-loop action rules.
6. Produce a bounded behavior result/effect summary.
7. Do not update memory.
8. Do not execute movement/action in World.
9. Emit report, invariants, metrics, events, and digest.

Goal override rules:

- safety/fear can override currentGoal;
- empty retrieval keeps currentGoal;
- weak or low-confidence memory does not override currentGoal;
- currentGoal continuity is allowed;
- memorySuggestedGoal must be a known v0 goal;
- selectedGoalForBehaviorLoop must always be present;
- goalChangedByMemory must be explicit;
- memory influence reason must be non-empty when influence is applied.

Action selection rules:

- `seekSafety` -> `seekSafety`;
- `explore` -> `explore`;
- `observeOtherAgent` -> `observeAgent`;
- `idle` -> `idle`;
- `rest` -> `rest` if the fixture preserves existing rest handling;
- action selection is abstract only and must not execute side effects.

Future metrics/events:

- metric prefix `behaviorLoopMemoryGoalBridge*`;
- primary future event `lab_behavior_loop_memory_goal_bridge_recorded`;
- optional summary event
  `lab_behavior_loop_memory_goal_bridge_summary_recorded`.

Future invariant contract:

- expected scenario name and seed;
- positive bridge decisions;
- selected goals and selected actions present;
- known v0 goals only;
- goal changes by memory covered;
- unchanged goals covered;
- memory influence and empty retrieval covered;
- behavior result present;
- behavior action not executed;
- memory not mutated;
- retrieval not rerun;
- movement stack not used;
- no World/terrain mutation;
- bounded deterministic order;
- digest repeatability;
- report/invariant/decisions/digest/metrics/events written.

Recommended next phase:

- Phase 5.5B — Behavior Loop Memory-Goal Bridge Fixture Smoke;
- probable scenario `behavior_loop_memory_goal_bridge_fixture_smoke`;
- fixture should cover safety, curiosity, nearby, empty retrieval, and
  low-confidence memory cases.

Out of scope:

- no `agents_basic` integration;
- no live behavior loop mutation;
- no behavior action execution;
- no memory write;
- no memory mutation;
- no retrieval rerun;
- no movement stack;
- no World or terrain mutation;
- no mood, emotional memory, relationships, trust, communication, community,
  task board, construction, mining, Python, LLM, embeddings, or RL.

Validation commands:

- `git status`;
- `git branch --show-current`;
- `git pull origin lab/pebblelab-v1`;
- `git log --oneline -12`;
- `swift build`;
- `swift build -c release --product Pebble`;
- `git diff --check`;
- `git diff --cached --check`.

Results: docs-only phase. No Swift files were modified, no runtime behavior was
changed, no scenario was added, no metrics/events runtime were added, and no
movement stack, World, renderer, resource, registry, save/load, golden, or
PebbleCore files were modified. `swift build`, `swift build -c release
--product Pebble`, `git diff --check`, and `git diff --cached --check` passed.
`pebsmoke` was not run because this phase is docs-only.

Next step: Phase 5.5B — Behavior Loop Memory-Goal Bridge Fixture Smoke.
