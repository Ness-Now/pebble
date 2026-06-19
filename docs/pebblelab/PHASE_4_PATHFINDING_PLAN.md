# Phase 4.12A — Pathfinding Planning Docs-Only

## Context

PebbleLab now has:

- central and edge read-only horizontal terrain scans;
- deterministic terrain semantic classification and semantic fixtures;
- conservative traversability fixtures over synthetic support/feet/head
  columns;
- central and edge vertical column scans with nine columns and 27 guarded
  cells;
- pure traversability results derived from captured columns;
- no graph, route, path execution, or movement integration.

Moving from a traversable candidate to a path is a new contract boundary. It
requires explicit neighbors, costs, search bounds, failure states, loop
prevention, and deterministic tie-breaking. It must remain separate from the
engine's collision truth and from any agent decision or movement command.

## Fundamental Layer Distinctions

- **Scan** reads raw world evidence under loaded/ready guards.
- **Semantics** describes one captured cell without world access.
- **Traversability** conservatively evaluates whether a semantic column is an
  abstract occupancy candidate.
- **Pathfinding** searches an abstract set of candidate positions and returns
  found, not-found, invalid, limited, or unknown evidence.
- **Movement** executes a requested displacement and is not part of
  pathfinding.
- **Collision** is the physical engine truth and is not proven by an abstract
  path.
- **Agent decision** chooses whether and where an agent wants to go; it does
  not belong in the path search.

Pathfinding must never command movement directly, claim collision safety, read
or mutate the world, or convert a result into an agent action. Its only output
is an abstract result: a path was found, was not found, or could not be
determined under the contract.

## Future Phase 4.12B Objective

Phase 4.12B should add a fixture-only scenario:

`terrain_pathfinding_fixture_smoke`

It should use a small synthetic traversability grid with no `World`, chunks,
live scans, or real agents. Fixtures should define start, goal, traversable or
rejected cells, four-directional neighbors, expected short routes, expected
failures, and mandatory search bounds.

Phase 4.12B must not consume `terrain_column_scan_smoke` or
`terrain_column_scan_edge_smoke`. Live integration belongs to a later planning
phase after fixture behavior and invariants are stable.

## Recommended Architecture

Add a focused future PebbleLab module such as
`Sources/PebbleLab/LabTerrainPathfinding.swift` with:

- input: a synthetic `LabTerrainPathfindingGrid` or node list;
- nodes based on synthetic traversability results;
- a deterministic, bounded search function;
- output: a `LabTerrainPathResult` only;
- no `World`, chunk, entity, movement, collision, or mutation dependency.

Keep scenario orchestration and output writing in `main.swift`; keep graph
construction, validation, and search in the focused module.

## Provisional Future Types

```swift
enum LabTerrainPathfindingStatus: String, Codable {
    case found
    case notFound
    case invalidStart
    case invalidGoal
    case searchLimitReached
    case unknown
}

struct LabTerrainPathNode: Codable {
    let x: Int
    let y: Int
    let z: Int
    let traversability: LabTerrainTraversabilityKind
}

struct LabTerrainPathRequest: Codable {
    let start: LabTerrainPathNode
    let goal: LabTerrainPathNode
    let nodes: [LabTerrainPathNode]
    let maxVisited: Int
    let neighborMode: String
}

struct LabTerrainPathResult: Codable {
    let status: LabTerrainPathfindingStatus
    let path: [LabTerrainPathNode]
    let visited: Int
    let reason: String
}
```

The exact design remains a Phase 4.12B decision. Coordinates should be unique,
requests should reject duplicate or inconsistent nodes, and result paths
should preserve enough evidence for independent audit.

## Proposed V0 Search Rules

- Start must be `.traversable`; otherwise return `invalidStart`.
- Goal must be `.traversable`; otherwise return `invalidGoal`.
- Only `.traversable` nodes may appear in a path.
- `.unknown`, `.unsafe`, `.blocked`, `.unsupported`,
  `.occupiedVerticalSpace`, and `.other` are non-passable in v0.
- Use only four horizontal neighbors: north, east, south, west.
- Do not use diagonals.
- Do not jump, fall, swim, climb, or change vertical level.
- Use uniform edge cost one; do not introduce terrain costs.
- Require a positive `maxVisited` search bound.
- Return `notFound` when the complete bounded fixture graph cannot reach the
  goal.
- Return `searchLimitReached` when another expansion would exceed the bound
  before the graph is exhausted.
- Track visited coordinates so cycles cannot expand indefinitely.
- A found path includes both start and goal.

These rules describe fixture graph search only. They do not imply that a real
entity can physically follow the result.

## Recommended V0 Algorithm: BFS

Phase 4.12B should use breadth-first search rather than A*.

BFS is recommended because it is small, deterministic, requires no heuristic,
finds a shortest path under uniform cost, and is easy to audit on fixture
grids. It avoids introducing diagonal policy, terrain weighting, heuristic
admissibility, or priority-queue tie-breaking before the base contract is
proven.

A* may be evaluated later. It is explicitly out of scope for Phase 4.12B.

## Deterministic Neighbor Order

Use this fixed order:

1. north (`z - 1`)
2. east (`x + 1`)
3. south (`z + 1`)
4. west (`x - 1`)

Equivalent shortest paths can differ solely because of neighbor order. The
order must therefore be encoded in the fixture contract, reported in outputs,
and checked by an invariant. No dictionary or set iteration order may choose a
route.

## Recommended Phase 4.12B Fixtures

1. `straight_line_path_found`: a traversable 1x3 line; path contains three
   nodes from left to right.
2. `simple_turn_path_found`: a 3x3 corridor requiring one turn.
3. `blocked_goal_not_found`: blocked goal returns `invalidGoal` under the
   recommended contract.
4. `blocked_start_invalid`: blocked start returns `invalidStart`.
5. `wall_blocks_path`: a complete blocked wall returns `notFound`.
6. `unknown_cells_are_not_used`: unknown cells never appear in a found path.
7. `unsafe_cells_are_not_used`: unsafe cells never appear in a found path.
8. `no_diagonal_shortcut`: diagonally adjacent start and goal require a valid
   orthogonal route or return `notFound`.
9. `search_limit_reached`: a deliberately low bound returns
   `searchLimitReached`.
10. `deterministic_neighbor_order`: equal-length alternatives select the route
    implied by north/east/south/west order.

Useful additional fixtures may cover identical start/goal, disconnected node
sets, duplicate coordinates, missing start/goal coordinates, zero limits, and
small cycles. They should not broaden the v0 movement model.

## Future Outputs

Phase 4.12B should write:

- `terrain_pathfinding_fixture_report.json`
- `terrain_pathfinding_invariant_report.json`
- `metrics.json`
- `events.ndjson`

Recommended metrics:

- `terrainPathfindingFixtureCases`
- `terrainPathfindingFixturePassed`
- `terrainPathfindingFixtureFailed`
- `terrainPathfindingPathsFound`
- `terrainPathfindingPathsNotFound`
- `terrainPathfindingInvalidStarts`
- `terrainPathfindingInvalidGoals`
- `terrainPathfindingSearchLimitReached`
- `terrainPathfindingSuccess`

Recommended aggregate event:

`lab_terrain_pathfinding_fixture_recorded`

Minimum event fields:

- `fixtures`
- `passed`
- `failed`
- `pathsFound`
- `pathsNotFound`
- `invalidStarts`
- `invalidGoals`
- `searchLimitReached`
- `success`

Do not emit one event per visited node.

## Future Invariant Report

`terrain_pathfinding_invariant_report.json` should check:

- fixture inputs exist;
- every fixture has start and goal evidence;
- start and goal status agrees with traversability;
- only traversable nodes appear in found paths;
- every found path begins at start;
- every found path ends at goal;
- consecutive path nodes are four-neighbors;
- no path contains diagonal steps;
- visited count does not exceed `maxVisited`;
- deterministic neighbor order is preserved;
- result and summary counts agree;
- no world access is required;
- no mutation path is used;
- no movement is commanded;
- no collision is performed.

Report success should require all fixture expectations and all invariants to
pass.

## Relationship To Live Scans

Phase 4.12B is fixture-only. It must not read column-scan snapshots, build a
graph from live world data, or attach paths to agents.

A cautious sequence after 4.12B is:

- Phase 4.12C: pathfinding contract cleanup and fixture hardening;
- Phase 4.13A: live pathfinding integration planning, docs-only;
- a later bounded live pathfinding smoke over captured column evidence;
- still later, a separately planned movement consumer.

This sequence keeps search correctness independent from world sampling and
physical execution.

## Explicitly Out Of Scope

- live pathfinding over the real world;
- A*, heuristics, Dijkstra, priority queues, and weighted costs;
- diagonals and vertical neighbors;
- jumping, falling, swimming, climbing, and step-height policy;
- collision checks or collision claims;
- agent movement, route following, goal selection, or behavior trees;
- mining, construction, inventory, or world mutation;
- multi-agent pathfinding, avoidance, reservations, or social navigation;
- performance optimization, caching, or large graphs;
- Python, ML, LLM, or reinforcement learning integration.

## Risks And Mitigations

| Risk | Consequence | Mitigation |
| --- | --- | --- |
| Path result is treated as a movement command | Search leaks into behavior | Return immutable abstract evidence only; no agent reference or callback. |
| Traversable is treated as collision-safe | Fixture labels overclaim engine truth | Document that collision remains a separate PebbleCore concern. |
| Unknown or unsafe nodes become passable | Unsafe routes look valid | Permit only exact `.traversable` nodes in v0. |
| A* is introduced too early | Heuristic and tie-breaking complexity obscure the contract | Use bounded BFS for fixtures. |
| Live world integration happens early | Search errors mix with scan errors | Keep Phase 4.12B completely world-free. |
| Search reads or mutates the world | Determinism and safety regress | Do not accept `World`; use synthetic node values only. |
| Equivalent routes vary between runs | Fixtures become flaky | Fix north/east/south/west expansion order. |
| Cycles loop forever | Unbounded run | Track visited coordinates before enqueueing. |
| Graph size explodes | Excessive time or memory | Require and enforce `maxVisited`. |
| Costs become complex before fixtures | Policy becomes unauditable | Uniform cost one; no weights in v0. |

## Future Phase 4.12B Definition Of Done

- `terrain_pathfinding_fixture_smoke` exists and is fixture-only;
- at least ten deterministic fixtures pass;
- bounded BFS and neighbor order are documented and audited;
- no `World`, chunk, live agent, or movement dependency exists;
- no world read or mutation is performed;
- no collision logic or claim is added;
- fixture and invariant reports are written;
- metrics and one aggregate event are written;
- existing terrain scan, semantic, traversability, and column-scan scenarios
  remain green;
- no PebbleCore, registry, save/load, renderer, resource, or golden change is
  made;
- `pebsmoke` reports `456 passed, 0 failed`.

## Future Validation Commands

cd ~/Dev/pebble-lab

git checkout lab/pebblelab-v1

swift build

swift run -c release PebbleLab -- --scenario terrain_pathfinding_fixture_smoke --seed 42 --ticks 0 --out runs/check_terrain_pathfinding_fixture

swift run -c release PebbleLab -- --scenario terrain_column_scan_smoke --seed 42 --ticks 5 --out runs/check_column_scan_before_pathfinding

swift run -c release PebbleLab -- --scenario terrain_column_scan_edge_smoke --seed 42 --ticks 5 --out runs/check_column_scan_edge_before_pathfinding

swift run -c release PebbleLab -- --scenario terrain_traversability_fixture_smoke --seed 42 --ticks 0 --out runs/check_traversability_fixture_before_pathfinding

swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_before_pathfinding

swift run -c release pebsmoke

git status

## Recommendation

Proceed with **Phase 4.12B — terrain pathfinding fixture smoke** using bounded,
deterministic BFS over small synthetic traversability grids. Stabilize search
statuses, four-neighbor paths, limits, and invariants before planning any live
world integration or movement consumer.
