# Phase 4.13A — Live Pathfinding Integration Planning Docs-Only

## Context

PebbleLab now has:

- central and edge horizontal terrain scans;
- pure terrain semantic classification and fixture coverage;
- pure traversability classification over support/feet/head columns;
- central and edge live column scans with nine columns and 27 guarded cells;
- a hardened fixture-only bounded BFS with 20 fixtures and 23 invariants;
- no live graph, live path request, route consumer, or movement integration.

The next boundary is not a new search algorithm. It is a controlled adapter
from already-captured column traversability into the existing abstract BFS.
That adapter must preserve the read-only evidence chain and must not turn a
search result into movement or a collision claim.

## Fundamental Layer Distinctions

- **Column scan** is the only layer that reads support/feet/head cells from the
  world under loaded/ready and unchanged-chunk guards.
- **Semantics** purely classifies each captured raw cell.
- **Traversability** purely classifies each captured semantic column.
- **Live pathfinding integration** maps captured column results into a bounded
  abstract node grid and request.
- **Pathfinding** remains the existing fixture-proven BFS over that request.
- **Movement** is a future consumer and is not commanded by pathfinding.
- **Collision** remains PebbleCore physical truth and is not proven by a found
  abstract path.
- **Agent decision** is a future policy for selecting an objective; it is not
  part of scan adaptation or BFS.

Even in a live scenario, BFS must not receive `World`, reread blocks, load
chunks, mutate blocks, or command movement. A found path means only that the
captured nine-node abstraction contains a four-neighbor traversable route.

## Future Phase 4.13B Objective

Phase 4.13B should add:

`terrain_pathfinding_column_smoke`

The scenario should:

1. execute or reuse the central terrain column scan;
2. derive exactly nine nodes from its nine captured traversability results;
3. choose fixed start and goal keys in that grid;
4. construct a bounded `LabTerrainPathRequest`;
5. call the existing `findTerrainPath` implementation;
6. record the abstract result without movement, collision, or mutation.

Phase 4.13B must not introduce a second BFS or alter fixture behavior merely
to make a live result succeed.

## Recommended Phase 4.13B Scope

- central-only scenario `terrain_pathfinding_column_smoke`;
- seed `42` and five ticks;
- one synchronized agent at `(8, y, 8)`;
- fixed radius one;
- nine captured columns and nine path nodes;
- fixed neighbor mode `north_east_south_west`;
- `maxVisited = 9`;
- fixed start and goal offsets;
- one abstract pathfinding result;
- no edge, multi-agent, movement, or collision integration.

The raw column scan and derived traversability must succeed independently of
whether BFS finds a route.

## Seed 42 And Negative Results

Previous seed-42 column scans commonly observed water support. The current
traversability classifier conservatively labels those columns `.unsafe`.
Therefore a central live request may legitimately return `invalidStart`,
`invalidGoal`, or `notFound`.

Options considered:

- **Option A: accept a coherent negative result.** This proves the live adapter
  without falsifying terrain evidence.
- **Option B: search for a naturally traversable seed or position.** This adds
  test-selection policy and should be deferred until the adapter contract is
  stable.
- **Option C: remain fixture/live-hybrid longer.** Useful if column evidence is
  incomplete, but unnecessary if all nine live nodes map cleanly.

Recommendation: use Option A. A negative result is successful phase evidence
when it agrees with captured start/goal traversability and all integration
invariants pass. Do not place, remove, or alter blocks to manufacture a found
path. Do not change semantic or traversability rules to satisfy the smoke.

## Provisional Future Types

```swift
struct LabTerrainLivePathNodeSource: Codable {
    let dx: Int
    let dz: Int
    let x: Int
    let y: Int
    let z: Int
    let traversability: LabTerrainTraversabilityKind
    let sourceColumnIndex: Int
    let reason: String
}

struct LabTerrainLivePathfindingSummary: Codable {
    let nodes: Int
    let traversableNodes: Int
    let unsafeNodes: Int
    let unknownNodes: Int
    let startStatus: String
    let goalStatus: String
    let pathStatus: LabTerrainPathfindingStatus
    let pathLength: Int
    let visited: Int
    let success: Bool
}

struct LabTerrainLivePathfindingSnapshot: Codable {
    let scenario: String
    let seed: UInt32
    let agentId: String
    let radius: Int
    let nodeCount: Int
    let start: LabTerrainPathNodeKey
    let goal: LabTerrainPathNodeKey
    let request: LabTerrainPathRequest
    let result: LabTerrainPathResult
    let nodeSources: [LabTerrainLivePathNodeSource]
    let summary: LabTerrainLivePathfindingSummary
}
```

The exact names and optional fields remain Phase 4.13B decisions. The snapshot
must retain source offsets and column indices so every node can be audited
against the column scan.

## Column Scan To Node Mapping

For every column, in existing `dz_then_dx` order:

- create exactly one node source;
- use the column candidate position `x/y/z` as its node key;
- copy `column.traversability.kind` without reclassification;
- copy the traversability reason for audit;
- preserve the source column index and `dx/dz`;
- pass the resulting `LabTerrainPathNode` list to BFS.

Only `.traversable` nodes are passable. `.unsafe`, `.unknown`, `.unsupported`,
`.occupiedVerticalSpace`, `.blocked`, and `.other` remain present in the
request but are rejected by the existing BFS contract.

Start and goal must be existing keys among the nine mapped columns. If either
is non-traversable, the existing BFS must return `invalidStart` or
`invalidGoal`; the adapter must not silently replace it with another node.

## Recommended Start And Goal

Use fixed offsets:

- start: `(dx: 0, dz: 0)`, the agent's center column;
- goal: `(dx: 1, dz: 0)`, the orthogonal east neighbor.

This rule is deterministic, easy to audit, and exercises direct adjacency
without adding objective selection. If start or goal is unsafe or otherwise
non-traversable, accept and audit the corresponding negative result.

A future phase may consider the first traversable neighbor, but only with a
fixed documented selection order. Phase 4.13B should not introduce that
intelligence.

## Future Outputs

Phase 4.13B should write:

- `terrain_pathfinding_column_snapshot.json`
- `terrain_pathfinding_column_invariant_report.json`
- `metrics.json`
- `events.ndjson`

Recommended metrics:

- `terrainPathfindingColumnNodes`
- `terrainPathfindingColumnTraversableNodes`
- `terrainPathfindingColumnUnsafeNodes`
- `terrainPathfindingColumnUnknownNodes`
- `terrainPathfindingColumnPathFound`
- `terrainPathfindingColumnPathLength`
- `terrainPathfindingColumnVisited`
- `terrainPathfindingColumnSuccess`

Recommended aggregate event:

`lab_terrain_pathfinding_column_recorded`

Minimum fields:

- `agentId`
- `nodes`
- `traversableNodes`
- `unsafeNodes`
- `unknownNodes`
- `startStatus`
- `goalStatus`
- `pathStatus`
- `pathLength`
- `visited`
- `success`

Do not emit one event per node or visited expansion.

## Future Invariant Report

`terrain_pathfinding_column_invariant_report.json` should check:

- column scan exists;
- column scan success is true;
- node count equals column count;
- every node maps to exactly one source column;
- node order matches column order;
- node coordinates and traversability match their source columns;
- start key exists;
- goal key exists;
- BFS request contains only mapped column nodes;
- neighbor mode is `north_east_south_west`;
- `maxVisited` equals nine or another explicitly documented node bound;
- result status agrees with start and goal traversability;
- a found path begins at start;
- a found path ends at goal;
- every found path node maps to a traversable column;
- consecutive found path nodes are four-neighbors;
- no diagonal steps occur;
- no vertical steps occur;
- visited count remains within the request bound;
- pathfinding performs no world access;
- no mutation path is used;
- no movement is commanded;
- no collision is performed.

Report success must accept coherent negative statuses. It must not require
`found` unless a later scenario contract explicitly supplies traversable start
and goal evidence.

## Reuse Of Phase 4.12B

Phase 4.13B must call `findTerrainPath`. It must not copy its queue, neighbor
expansion, visited tracking, reconstruction, status rules, or limits.

The only new pathfinding-related responsibility is a pure adapter from
`LabTerrainColumnScan` values to `LabTerrainPathRequest`, plus reporting and
invariants. BFS fixture tests remain the authority for search behavior.

## Explicitly Out Of Scope

- edge live pathfinding;
- multi-agent pathfinding;
- movement, route following, or agent commands;
- collision checks or guarantees;
- intelligent goal selection or behavior trees;
- dynamic replanning or changing-world invalidation;
- chunk loading or generation for pathfinding;
- world rereads or mutation;
- A*, Dijkstra, diagonals, heuristics, or weighted terrain costs;
- jumping, falling, swimming, climbing, and step-height logic;
- mining, construction, and inventory behavior;
- avoidance, reservations, and social navigation;
- Python, ML, LLM, or reinforcement learning integration.

## Risks And Mitigations

| Risk | Consequence | Mitigation |
| --- | --- | --- |
| Integration reaches into `World` | Search evidence diverges from the audited scan | Build nodes only from captured column values; do not pass `World` to the adapter or BFS. |
| Pathfinding rereads blocks | Loaded/ready and unchanged-chunk guarantees are bypassed | Keep all reads inside `scanTerrainColumns`; adaptation is pure. |
| Terrain is mutated to force `found` | Smoke proves an artificial route | Accept coherent negative results; prohibit block mutation. |
| `invalidStart` is treated as phase failure | Honest unsafe terrain looks broken | Define success as status/evidence coherence, not route discovery. |
| Found path is treated as executable movement | Abstract evidence overclaims physics | Produce snapshot only; no movement callback or entity reference. |
| Fixture BFS is changed for live convenience | Proven search behavior regresses | Reuse `findTerrainPath` unchanged and keep fixture smoke green. |
| Start/goal selection becomes clever | Goal policy leaks into integration | Fix offsets `(0,0)` and `(1,0)` in v0. |
| Edge or multi-agent scope appears early | Boundary and coordination risks multiply | Keep Phase 4.13B central-only and single-agent evidence. |

## Future Phase 4.13B Definition Of Done

- central-only `terrain_pathfinding_column_smoke` exists;
- one synchronized agent produces nine successful column observations;
- exactly nine node sources and nine request nodes are derived;
- start is fixed at offset `(0,0)` and goal at `(1,0)`;
- `maxVisited` is bounded to nine;
- existing `scanTerrainColumns` evidence is reused;
- existing `findTerrainPath` is reused without a second BFS;
- snapshot, invariant report, metrics, and one aggregate event are written;
- `found` or a coherent negative result is accepted;
- pathfinding performs no world read;
- no movement, collision, or mutation is added;
- existing pathfinding fixtures and central/edge column scans remain green;
- no PebbleCore, registry, save/load, renderer, resource, or golden change is
  made;
- `pebsmoke` reports `456 passed, 0 failed`.

## Future Validation Commands

cd ~/Dev/pebble-lab

git checkout lab/pebblelab-v1

swift build

swift run -c release PebbleLab -- --scenario terrain_pathfinding_column_smoke --seed 42 --ticks 5 --out runs/check_terrain_pathfinding_column

swift run -c release PebbleLab -- --scenario terrain_pathfinding_fixture_smoke --seed 42 --ticks 0 --out runs/check_pathfinding_fixture_after_live_plan

swift run -c release PebbleLab -- --scenario terrain_column_scan_smoke --seed 42 --ticks 5 --out runs/check_column_scan_after_live_plan

swift run -c release PebbleLab -- --scenario terrain_column_scan_edge_smoke --seed 42 --ticks 5 --out runs/check_column_scan_edge_after_live_plan

swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_live_plan

swift run -c release pebsmoke

git status

## Recommendation

Proceed with **Phase 4.13B — terrain pathfinding column smoke** as a
central-only adapter validation. Reuse the existing column scan and BFS, keep
start/goal fixed, and treat a coherent negative path result as valid evidence
rather than altering terrain or search rules to force success.

## Phase 4.13B Implementation Result

Phase 4.13B implemented `terrain_pathfinding_column_smoke` as the planned
central-only adapter. It reuses `scanTerrainColumns` to capture nine columns,
maps those captured traversability results to nine path nodes in column order,
and calls the existing `findTerrainPath` BFS with fixed offsets `(0,0)` and
`(1,0)`, `maxVisited = 9`, and neighbor mode
`north_east_south_west`.

For seed 42, all nine column results are `unsafe`. The fixed start and goal are
therefore both unsafe, and BFS correctly returns `invalidStart` with no visited
nodes and no path. The scenario succeeds because the negative result is
coherent with captured evidence. It does not alter terrain, choose a substitute
goal, reread the world during adaptation, command movement, or perform
collision checks.

The run writes `terrain_pathfinding_column_snapshot.json`, a dedicated
26-check invariant report, aggregate `terrainPathfindingColumn*` metrics, and
one `lab_terrain_pathfinding_column_recorded` event. Existing column scan
outputs remain available and authoritative for the raw read-only observation.
