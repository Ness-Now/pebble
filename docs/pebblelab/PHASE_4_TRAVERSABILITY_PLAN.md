# Phase 4.10A — Terrain Traversability Planning Docs-Only

## Context

PebbleLab now provides a stable, read-only terrain perception chain:

- `terrain_scan_smoke` reads a deterministic radius-1, `3x3` area around one
  synchronized agent;
- `terrain_scan_edge_smoke` applies the same scan across four preloaded chunks;
- `LabTerrainScanContract` centralizes the two fixed scan contracts;
- terrain semantics v0 classifies captured cells as `unknown`, `air`, `solid`,
  `liquid`, `plantLike`, or `other` without rereading the world;
- `terrain_semantics_fixture_smoke` covers all semantic rules with 21 pure
  synthetic fixtures;
- scan and semantic invariant reports prove ordering, counts, read-only state,
  and pure transformation boundaries.

This evidence is still insufficient to decide whether an entity could occupy
a position. The current `around_below` scan observes only one horizontal layer
at `agent.y - 1`. It does not describe the feet or head spaces above each
support cell.

## Fundamental Distinction

Four layers must remain separate:

1. **Semantic kind** describes one captured cell. It states what PebbleLab's
   conservative classifier recognizes locally; it does not state movement
   feasibility.
2. **Traversability** is a cautious read-only assessment of whether a complete
   position column has enough evidence to be considered occupiable or clearly
   unusable.
3. **Pathfinding** searches among positions and assigns connectivity or costs.
   It consumes traversability-like evidence but is not part of classification.
4. **Collision** is the engine's physical constraint during actual motion. A
   read-only assessment cannot replace collision resolution.

An **agent action** is a fifth, later concern: choosing to move must not occur
inside semantics or traversability classification.

Phase 4.10B must not implement pathfinding, collision, or agent movement. Its
only proposed output is one of these descriptive assessment states:

- `unknown`
- `traversable`
- `blocked`
- `unsupported`
- `unsafe`
- `occupiedVerticalSpace`
- `other`

Even `traversable` means only "candidate supported and clear under the v0
fixture contract." It is not a promise that PebbleCore physics can move an
entity there.

## Central Problem: A Column Is Required

One below-cell cannot establish traversability. A minimal standing column
probably requires:

- **support** at `y - 1`;
- **feet** at `y`;
- **head** at `y + 1`.

The existing terrain scan supplies support-layer semantics only. It cannot
prove that feet or head space is clear. Therefore Phase 4.10B must not attach
traversability results to the live terrain scan.

Three approaches were considered:

### Option A — Continue Contract-Only Documentation

Safest, but it leaves the proposed rules unexercised and offers no executable
evidence that missing data is handled conservatively.

### Option B — Decide From Existing Below Cells

Rejected. It would label positions without feet/head evidence and encourage
the exact semantic/traversability confusion this phase is intended to prevent.

### Option C — Pure Synthetic Column Fixtures

Recommended. Phase 4.10B should add
`terrain_traversability_fixture_smoke`, using synthetic support/feet/head
semantics and no world access. This validates the decision contract before a
future Phase 4.10C considers a bounded vertical read-only scan.

## Provisional Future Types

The exact Swift design remains a Phase 4.10B decision, but the intended data
boundary is:

```swift
enum LabTerrainTraversabilityKind: String, Codable {
    case unknown
    case traversable
    case blocked
    case unsupported
    case unsafe
    case occupiedVerticalSpace
    case other
}

struct LabTerrainColumnSemantic: Codable {
    let x: Int
    let y: Int
    let z: Int
    let support: LabTerrainCellSemantic?
    let feet: LabTerrainCellSemantic?
    let head: LabTerrainCellSemantic?
}

struct LabTerrainTraversabilityCell: Codable {
    let x: Int
    let y: Int
    let z: Int
    let kind: LabTerrainTraversabilityKind
    let confidence: Double
    let reason: String
}
```

The future classifier should have a pure boundary such as:

`LabTerrainColumnSemantic -> LabTerrainTraversabilityCell`

It must not accept `World`, block registries, entities, movement goals, or
collision state.

## Proposed Conservative Rules

These rules are conceptual and must not be implemented in Phase 4.10A:

1. Missing support, feet, or head data returns `unknown`.
2. `unknown` in any required column position returns `unknown`.
3. `solid` feet or head returns `occupiedVerticalSpace`, never traversable.
4. `air` support returns `unsupported`.
5. `unknown` or `other` support returns `unknown`.
6. `liquid` support returns `unsafe` in v0, never traversable.
7. `liquid` feet or head returns `unsafe` in v0. Swimming is out of scope.
8. `solid` support plus `air` feet plus `air` head returns a
   `traversable` candidate.
9. `plantLike` in feet or head returns `unknown` in v0. PebbleLab lacks enough
   evidence about collision shape and replaceability to call it clear.
10. A single below semantic cell never produces `traversable`.

`blocked` is reserved for future explicit obstruction rules that are not
better described as occupied vertical space. Phase 4.10B does not need to emit
every enum case if the fixtures do not establish a sound rule.

No semantic kind becomes a pathfinding cost, neighbor relation, or movement
instruction.

## Recommended Phase 4.10B Fixtures

The future `terrain_traversability_fixture_smoke` should begin with pure
synthetic columns:

1. solid support + air feet + air head -> `traversable`;
2. air support + air feet + air head -> `unsupported`;
3. solid support + solid feet + air head -> `occupiedVerticalSpace`;
4. solid support + air feet + solid head -> `occupiedVerticalSpace`;
5. liquid support + air feet + air head -> `unsafe`;
6. unknown support + air feet + air head -> `unknown`;
7. solid support + unknown feet + air head -> `unknown`;
8. solid support + plant-like feet + air head -> `unknown` in v0;
9. missing head -> `unknown`;
10. missing support -> `unknown`;
11. other support + air feet + air head -> `unknown`.

Additional fixtures may cover liquid feet/head and solid support with missing
feet, but Phase 4.10B should remain small. Fixtures must use synthetic semantic
values, not real block IDs or world reads.

## Future Outputs

Phase 4.10B should produce:

- `terrain_traversability_fixture_report.json`, containing each synthetic
  column, expected/actual kind and reason, and pass/fail state;
- `metrics.json` fields:
  - `terrainTraversabilityCells`
  - `terrainTraversabilityTraversableCells`
  - `terrainTraversabilityBlockedCells`
  - `terrainTraversabilityUnknownCells`
  - `terrainTraversabilityUnsupportedCells`
  - `terrainTraversabilityUnsafeCells`
  - `terrainTraversabilityOccupiedVerticalSpaceCells`
  - `terrainTraversabilitySuccess`
- one `lab_terrain_traversability_recorded` event with:
  - `cellsEvaluated`
  - `traversableCells`
  - `blockedCells`
  - `unknownCells`
  - `unsupportedCells`
  - `unsafeCells`
  - `occupiedVerticalSpaceCells`
  - `success`

Only a later vertical-scan phase may consider
`terrain_traversability_snapshot.json`. Traversability must not be inserted
into `terrain_scan_snapshot.json` while that snapshot contains only the below
layer.

## Future Invariant Report

Phase 4.10B should write
`terrain_traversability_invariant_report.json` with checks that:

1. input semantic columns exist;
2. every traversability result maps to exactly one input column;
3. missing column data returns `unknown`;
4. solid feet or head is never traversable;
5. air support is never traversable;
6. liquid support is never traversable in v0;
7. category counts match the summary;
8. output order matches fixture order;
9. classification requires no world access;
10. no mutation path is used;
11. no pathfinding is performed.

Report success must require every runtime fixture and every code-review
contract to pass.

## Out Of Scope

- pathfinding, A*, and Dijkstra;
- navigation meshes, route selection, costs, and neighbor expansion;
- real collision and entity physics;
- jump, fall, swim, climb, crouch, or step-height logic;
- agent movement decisions and goal selection;
- mining, placing, construction, and world mutation;
- inventory and resource decisions;
- multi-agent navigation and social behavior;
- live vertical scanning in Phase 4.10B;
- machine learning, LLMs, and reinforcement learning;
- performance optimization.

## Risks And Mitigations

| Risk | Consequence | Mitigation |
| --- | --- | --- |
| Semantic kind is treated as traversability | A local label becomes an unsafe movement claim | Require a complete synthetic column and separate traversability types/reasons. |
| Pathfinding is introduced too early | Scope expands into graph search and behavior | Prohibit neighbors, costs, routes, and agent actions in 4.10B. |
| Below-only data is called traversable | Feet/head obstructions are ignored | Do not connect 4.10B to current live scans; use column fixtures first. |
| Liquid, plant-like, or other is overinterpreted | Unproven collision or hazard behavior is asserted | Return `unsafe` or `unknown` conservatively and document why. |
| Classifier rereads the world | Fixture results no longer prove a pure contract | Accept only `LabTerrainColumnSemantic`; never pass `World`. |
| Accidental mutation enters the classifier | A read-only audit changes simulation state | Keep fixture-only code in PebbleLab and add no-mutation review invariants. |
| Fixtures depend on real block IDs | Registry changes leak into contract tests | Build fixtures directly from synthetic semantic kinds and reasons. |
| Collision behavior is inferred without physics | Abstract result disagrees with the engine | State that v0 traversability is a candidate assessment, not collision truth. |

## Future Phase 4.10B Success Contract

Phase 4.10B is complete only when:

- `terrain_traversability_fixture_smoke` is a pure synthetic scenario;
- no `World.getBlock` call exists in the traversability path;
- no `World` is passed to traversability functions;
- at least ten deterministic column fixtures run;
- every fixture records expected/actual kind, reason, and pass state;
- `terrain_traversability_fixture_report.json` reports success;
- metrics and one aggregate event expose coherent category counts;
- the invariant report passes with no failures;
- no Swift change occurs outside PebbleLab;
- no PebbleCore, registry, save/load, renderer, resource, or golden changes
  occur;
- no mutation, pathfinding, collision, or agent behavior is added;
- terrain scan and semantic fixture scenarios still pass;
- `pebsmoke` reports `456 passed, 0 failed`.

## Future Validation Commands

cd ~/Dev/pebble-lab

git checkout lab/pebblelab-v1

swift build

swift run -c release PebbleLab -- --scenario terrain_semantics_fixture_smoke --seed 42 --ticks 0 --out runs/check_terrain_semantics_fixture_before_traversability

swift run -c release PebbleLab -- --scenario terrain_scan_smoke --seed 42 --ticks 5 --out runs/check_terrain_scan_before_traversability

swift run -c release PebbleLab -- --scenario terrain_scan_edge_smoke --seed 42 --ticks 5 --out runs/check_terrain_scan_edge_before_traversability

swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_before_traversability

swift run -c release pebsmoke

git status

## Recommendation

Proceed with **Phase 4.10B — terrain traversability fixture smoke** as a pure
PebbleLab fixture scenario over synthetic support/feet/head columns. Do not
connect the classifier to a real world scan until a later Phase 4.10C defines
and validates a bounded vertical read-only observation contract.
