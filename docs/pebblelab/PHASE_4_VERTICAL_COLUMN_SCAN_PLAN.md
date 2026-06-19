# Phase 4.11A — Vertical Column Scan Planning Docs-Only

## Context

PebbleLab now has four proven read-only layers of terrain evidence:

- `terrain_scan_smoke` reads a central radius-1, `3x3` support layer;
- `terrain_scan_edge_smoke` applies the same support-layer scan across four
  preloaded chunks;
- terrain semantics v0 classifies captured cells without rereading the world,
  and 21 synthetic fixtures cover its rules;
- `terrain_traversability_fixture_smoke` classifies 15 synthetic
  support/feet/head columns without world access.

The missing link is a real, bounded vertical observation. The current
`around_below` scan captures only the support layer at `agent.y - 1`; it does
not observe feet space at `agent.y` or head space at `agent.y + 1`. Therefore
live traversability cannot yet be evaluated responsibly.

## Future Phase 4.11B Objective

Phase 4.11B should add a central-only read-only scenario:

`terrain_column_scan_smoke`

For each horizontal offset in the fixed radius-1 `3x3` area, the scenario
should capture exactly three roles around a candidate base position:

- support: `baseY - 1`;
- feet: `baseY`;
- head: `baseY + 1`.

The initial scenario should use one synchronized agent at `(8, y, 8)`, seed
`42`, five ticks, nine columns, and exactly 27 planned cells. No implementation
belongs in Phase 4.11A.

## Layer Boundaries

The future pipeline must keep these responsibilities distinct:

1. **Horizontal terrain scan** reads below-layer cells around the agent. Its
   existing snapshots and contracts remain unchanged.
2. **Vertical column scan** reads raw support/feet/head cells for each candidate
   horizontal position. It owns loaded/ready guards and chunk-state auditing.
3. **Terrain semantics** purely transforms each captured raw cell. It must not
   reread the world.
4. **Traversability** purely transforms a complete semantic column into a
   conservative occupancy candidate.
5. **Pathfinding** is a future graph-search layer and is not part of 4.11B.
6. **Collision** remains PebbleCore's physical runtime truth and is not proven
   by a read-only snapshot.
7. **Agent movement/action** is a future consumer and must not be triggered by
   the scan.

Phase 4.11B must not create neighbors, routes, costs, movement commands, or
goal changes. Its primary success contract is raw vertical observation. Pure
semantic derivation may be included as a separately audited layer. Live
traversability output should remain separately gated and may be deferred until
the raw 27-cell contract is stable.

## Proposed Read Contract

The fixed horizontal order remains `dz_then_dx`:

1. iterate `dz` from `-1...1`;
2. iterate `dx` from `-1...1`;
3. for each offset, read roles in `support_feet_head` order.

For every role cell:

1. derive target `x`, `y`, and `z` from the candidate base position and role;
2. compute `cx = floorDiv(x, CHUNK_W)` and
   `cz = floorDiv(z, CHUNK_W)`;
3. evaluate `world.isLoadedAt(x, z)`;
4. evaluate `world.isChunkReady(cx, cz)`;
5. call `world.getBlock(x, y, z)` only when loaded and ready;
6. decode `blockId`, `meta`, and `blockName` only when a packed cell exists;
7. compare chunk `modified`, `version`, and `dirty` before and after the read;
8. record failure without decoding when loaded/ready guards fail.

A missing or unavailable role must remain missing/unknown evidence. It must
never be represented as air. The scan must not load or generate a chunk in
order to satisfy a role.

## Provisional Future Types

The precise Swift design belongs to Phase 4.11B, but the data model should
remain small and explicit:

```swift
enum LabTerrainColumnCellRole: String, Codable {
    case support
    case feet
    case head
}

struct LabTerrainColumnScanCell: Codable {
    let role: LabTerrainColumnCellRole
    let dx: Int
    let dz: Int
    let x: Int
    let y: Int
    let z: Int
    let chunk: LabWorldInteractionChunk
    let cell: Int?
    let blockId: Int?
    let meta: Int?
    let blockName: String?
    let chunkStateUnchanged: Bool
    let success: Bool
}

struct LabTerrainColumnScan: Codable {
    let dx: Int
    let dz: Int
    let x: Int
    let y: Int
    let z: Int
    let support: LabTerrainColumnScanCell
    let feet: LabTerrainColumnScanCell
    let head: LabTerrainColumnScanCell
    let semanticColumn: LabTerrainColumnSemantic?
    let traversability: LabTerrainTraversabilityCell?
}

struct LabTerrainColumnScanSnapshot: Codable {
    let scenario: String
    let seed: UInt32
    let agentId: String
    let radius: Int
    let relation: String
    let horizontalOrder: String
    let verticalOrder: String
    let columns: [LabTerrainColumnScan]
    let summary: LabTerrainColumnScanSummary
}
```

The optional derived fields should not weaken or redefine raw scan success.
An implementation may place semantics and traversability in separate parallel
arrays instead if that makes layer ownership clearer.

## Relation To Terrain Semantics

Each successful raw vertical cell can be classified by the existing pure
semantic rules. Phase 4.11B should either:

- adapt `LabTerrainColumnScanCell` into `LabTerrainScanCell` and call the
  existing classifier; or
- extract a small shared immutable raw-cell protocol/value if that removes
  genuine duplication.

The first option is preferred for the initial patch because it is smaller.
Classification must consume captured values only. It must not call
`World.getBlock`, inspect a chunk, or resolve a second block identity.

Missing/unready raw roles must become `unknown` semantics through the existing
conservative contract.

## Relation To Traversability

After all three role semantics exist, they can form
`LabTerrainColumnSemantic`, which the already-tested pure function transforms
into `LabTerrainTraversabilityCell`.

This transformation still does not prove physical movement. In Phase 4.11B:

- no neighbor graph may be created;
- no pathfinding or route may be computed;
- no cost may be assigned;
- no agent may move or choose a goal;
- no collision claim may be made.

Recommended sequencing inside 4.11B is raw scan first, semantic mapping second,
and optional traversability third. Each layer needs independent success and
invariant fields. A raw scan failure must not be hidden by a derived result.

## Proposed Outputs

Required future outputs:

- `terrain_column_scan_snapshot.json`
- `terrain_column_scan_invariant_report.json`

Optional derived reports, only if included cleanly:

- `terrain_column_semantics_invariant_report.json`
- `terrain_column_traversability_invariant_report.json`

Proposed metrics:

- `terrainColumnScanColumns`
- `terrainColumnScanCellsPlanned`
- `terrainColumnScanCellsObserved`
- `terrainColumnScanLoadedCells`
- `terrainColumnScanReadyCells`
- `terrainColumnScanUniqueChunks`
- `terrainColumnScanSuccess`
- `terrainColumnSemanticCells`
- `terrainColumnTraversabilityCells`
- `terrainColumnTraversableCells`
- `terrainColumnUnsafeCells`
- `terrainColumnUnknownCells`
- `terrainColumnTraversabilitySuccess`

The required aggregate event is `lab_terrain_column_scan_recorded` with:

- `agentId`
- `radius`
- `columns`
- `cellsPlanned`
- `cellsObserved`
- `loadedCells`
- `readyCells`
- `uniqueChunks`
- `success`

If live traversability is included later, emit a separate
`lab_terrain_column_traversability_recorded` event. Do not overload raw scan
success with derived classification success.

## Proposed Raw Scan Invariants

`terrain_column_scan_invariant_report.json` should check:

1. agent exists;
2. physical/core links are coherent;
3. radius equals one;
4. horizontal order is `dz_then_dx`;
5. vertical order is `support_feet_head`;
6. planned columns equal nine;
7. planned cells equal 27;
8. observed cells equal 27 when all targets are loaded and ready;
9. every decoded cell passed loaded/ready guards;
10. every column contains exactly one support, feet, and head role;
11. target coordinates are unique per role;
12. all observed chunk states remain unchanged;
13. all decoded packed cells are valid;
14. world access occurs only inside the bounded scan path;
15. no mutation path is used;
16. no pathfinding is performed.

Derived semantic or traversability reports must not replace these raw checks.

## Scenario Scope

Phase 4.11B should implement only:

- `terrain_column_scan_smoke`;
- one agent at `x = 8`, `z = 8`;
- seed `42` and five ticks;
- fixed radius `1`;
- nine columns and 27 cells;
- central preloaded chunks using the existing scenario preparation pattern.

A later `terrain_column_scan_edge_smoke` may place the agent at `(16, y, 16)`
and prove multi-chunk vertical scanning. It must not be bundled into the first
implementation.

## Recommended Architecture

Use a layered PebbleLab design:

1. raw vertical scan: world access, guards, packed cells, chunk audit;
2. semantic transform: pure raw-cell classification;
3. traversability transform: pure semantic-column classification;
4. future pathfinding: graph/search, not yet implemented;
5. future movement/action: simulation decisions, not yet implemented.

Do not place all column scanning and output construction in `main.swift`.
Create a focused future file such as `LabTerrainColumnScan.swift` or
`LabTerrainVerticalScan.swift`; keep `main.swift` responsible only for scenario
orchestration and output wiring.

Reuse the fixed terrain-scan contract where it is truly shared, but do not
force vertical role rules into `LabTerrainScanContract` if a small dedicated
column contract is clearer.

## Out Of Scope

- pathfinding, A*, Dijkstra, routes, costs, and neighbor expansion;
- collision and physical movement guarantees;
- agent movement, actions, and goal selection;
- mining, construction, inventory, and world mutation;
- edge-position column scanning in Phase 4.11B;
- multi-agent scanning or navigation;
- configurable radius or vertical depth;
- jumping, falling, swimming, climbing, and step-height rules;
- Python, machine learning, LLMs, and reinforcement learning.

## Risks And Mitigations

| Risk | Consequence | Mitigation |
| --- | --- | --- |
| Unloaded data is interpreted as air | False clear vertical space | Require loaded/ready before every read and preserve nil/unknown otherwise. |
| Semantics or traversability rereads the world | Derived evidence diverges from the snapshot | Transform captured raw cells only; never pass `World` to pure layers. |
| Terrain-scan read logic is duplicated | Guard and audit behavior diverges | Reuse a small guarded raw-cell helper or adapt existing values without a broad refactor. |
| Scan, semantics, and traversability become one large block | Layer success and failures become opaque | Use a dedicated column-scan module and separate summaries/reports. |
| Pathfinding appears during integration | Observation expands into navigation behavior | Prohibit neighbors, routes, costs, and movement in types and invariants. |
| Collision or movement behavior is inferred | Abstract candidate is mistaken for engine truth | Keep traversal labels descriptive and do not move entities. |
| Existing terrain snapshots are changed | Stable 4.8/4.9 contracts regress | Write dedicated column outputs; leave `terrain_scan_snapshot.json` unchanged. |
| PebbleCore or registries are modified | Experimental scope leaks into engine contracts | Implement only in PebbleLab using existing read APIs. |
| Radius becomes configurable too early | Output size and boundary cases expand | Keep radius fixed at one and vertical depth fixed at three roles. |
| Outputs multiply without audit | Results become hard to trust | Require a raw invariant report and separate optional derived reports. |

## Future Phase 4.11B Success Contract

Phase 4.11B is complete only when:

- central-only `terrain_column_scan_smoke` exists;
- exactly one synchronized agent, placeholder, and core entity exist;
- radius remains fixed at one;
- exactly nine columns and 27 cells are planned;
- horizontal order is `dz_then_dx` and vertical order is
  `support_feet_head`;
- every read checks loaded and ready first;
- `World.getBlock` is called only for loaded/ready cells inside the scan path;
- unavailable cells are never decoded as air;
- all observed chunks preserve modified/version/dirty state;
- `terrain_column_scan_snapshot.json` is written;
- `terrain_column_scan_invariant_report.json` succeeds;
- metrics and one aggregate event are written;
- existing terrain scan, semantic fixture, and traversability fixture
  scenarios still pass;
- no pathfinding, collision, mutation, or agent movement is added;
- no PebbleCore, registry, save/load, renderer, resource, or golden change is
  made;
- `pebsmoke` reports `456 passed, 0 failed`.

## Future Validation Commands

cd ~/Dev/pebble-lab

git checkout lab/pebblelab-v1

swift build

swift run -c release PebbleLab -- --scenario terrain_column_scan_smoke --seed 42 --ticks 5 --out runs/check_terrain_column_scan

swift run -c release PebbleLab -- --scenario terrain_traversability_fixture_smoke --seed 42 --ticks 0 --out runs/check_terrain_traversability_fixture_after_column_plan

swift run -c release PebbleLab -- --scenario terrain_semantics_fixture_smoke --seed 42 --ticks 0 --out runs/check_terrain_semantics_fixture_after_column_plan

swift run -c release PebbleLab -- --scenario terrain_scan_smoke --seed 42 --ticks 5 --out runs/check_terrain_scan_after_column_plan

swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_column_plan

swift run -c release pebsmoke

git status

## Recommendation

Proceed with **Phase 4.11B — terrain column scan smoke** as a central-only,
fixed radius-1, read-only raw observation. Stabilize its 27-cell evidence and
invariants before adding an edge scenario or consuming live traversability in
any navigation or movement system.
