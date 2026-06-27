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
