# PebbleLab Development Journal

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
