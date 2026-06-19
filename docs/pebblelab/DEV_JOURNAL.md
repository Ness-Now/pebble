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
