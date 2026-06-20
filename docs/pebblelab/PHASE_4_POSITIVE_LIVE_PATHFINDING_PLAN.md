# Phase 4.13D — Positive Live Pathfinding Planning Docs-Only

## Context

PebbleLab now has a hardened fixture-only pathfinding contract and two live
column integrations:

- `terrain_pathfinding_fixture_smoke` validates the bounded deterministic BFS;
- `terrain_pathfinding_column_smoke` maps a central live column scan to nine
  nodes;
- `terrain_pathfinding_column_edge_smoke` maps an edge scan crossing four
  chunks to the same BFS;
- both live scenarios preserve fixed start `(0,0)`, goal `(1,0)`, nine nodes,
  `maxVisited = 9`, and `north_east_south_west` neighbor order;
- both live scenarios correctly return `invalidStart` for seed 42 because all
  nine captured columns have liquid support and classify as `unsafe`.

These negative results are successful evidence: the adapter and BFS reject
captured terrain that does not satisfy the traversability contract. No terrain,
semantic, traversability, or BFS rule was changed to manufacture a route.

What remains missing before movement planning is a positive live proof: a
captured column grid with traversable start and goal nodes for which the
existing BFS returns `found`.

## Fundamental Distinction

- **Negative live pathfinding** proves that unsafe, unknown, unsupported,
  blocked, occupied, or otherwise unavailable terrain is rejected coherently.
- **Positive live pathfinding** proves that the existing BFS can find an
  abstract route over nodes derived from genuinely traversable live columns.
- **Movement** is a future consumer of path evidence. It is not part of a
  positive pathfinding smoke.
- **Collision** remains PebbleCore's physical truth. A `found` path does not
  prove that an entity can physically execute it.
- **Mutation** must never be used to prepare or force a positive route.

A positive live path must remain an observation and computation artifact. It
must not move an agent, issue commands, alter goals, perform collision queries,
or modify blocks.

## Future Phase 4.13E Objective

A possible Phase 4.13E should add:

`terrain_pathfinding_column_positive_smoke`

The future scenario should:

1. obtain a bounded live radius-one column scan;
2. derive nine traversability results without rereading the world;
3. map those nine captured columns to nine path nodes;
4. select start and goal using a fixed, deterministic test rule;
5. call the existing `findTerrainPath` implementation;
6. require `status == found` and a path longer than one node;
7. write a snapshot, invariant report, metrics, and one aggregate event;
8. command no movement and perform no collision or mutation.

This phase does not implement that scenario.

## Current Terrain Problem

Seed 42 at both established positions produces only unsafe nodes:

- central position `(8,8)`: nine unsafe nodes;
- edge position `(16,16)`: nine unsafe nodes across four chunks;
- fixed start `(0,0)`: unsafe;
- fixed goal `(1,0)`: unsafe;
- BFS result: `invalidStart`.

A positive proof therefore probably needs a different seed, a different
position, a bounded read-only discovery policy, or a naturally generated solid
area already available through existing world generation. It must not use
`setBlock`, `fill`, placement, breaking, save edits, registry changes, or any
other mutation to make terrain convenient.

## Options

### Option A — Manually Found Fixed Seed And Position

Search a small number of seeds and positions during development, then encode
one known-good seed and coordinate pair in the future scenario contract.

Advantages:

- smallest runtime implementation;
- fixed start, goal, and expected result;
- easy snapshot and invariant auditing;
- no runtime candidate-selection behavior.

Risks:

- the fixture may be fragile if world generation changes;
- manual discovery may be difficult to reproduce unless recorded carefully;
- a single coordinate can accidentally encode an undocumented terrain
  assumption.

Required safeguards:

- document the exact seed, agent `x/z`, chunk set, node kinds, and path;
- preserve a strict read-only scenario;
- fail visibly if the known-good terrain changes.

Recommendation: acceptable as the smallest first implementation if a stable
candidate is found quickly and documented as generated-world evidence.

### Option B — Bounded Deterministic Read-Only Discovery

Give the future smoke a fixed ordered list of candidate seeds and/or positions.
For each candidate, prepare the world through existing generation, scan nine
columns, map nine nodes, run the existing BFS, and stop at the first `found`.

Advantages:

- more resilient than one hard-coded location;
- proves a positive case from live generated terrain;
- can audit every attempted candidate and the selected index;
- remains deterministic when candidate order and bounds are fixed.

Risks:

- introduces test-only candidate selection;
- can become slow if the list grows;
- can look like agent goal selection unless the boundary is explicit;
- careless implementation could repeatedly read or generate beyond its bound.

Required safeguards:

- fixed candidate list in a documented order;
- hard maximum such as 16 candidates initially, with 32 as an absolute review
  ceiling rather than a default;
- one bounded scan and one BFS request per candidate;
- no random search, unbounded loops, or adaptive expansion;
- candidate selection described as test harness discovery, never agent
  decision-making;
- report all attempts and stop deterministically at the first valid `found`.

Recommendation: preferred for Phase 4.13E if it can be implemented with a
small fixed list and acceptable runtime.

### Option C — Fixture/Live Hybrid

Record previously captured column snapshots and replay them as stable inputs to
the adapter and BFS.

Advantages:

- deterministic and fast;
- useful for adapter regression tests;
- independent from future generation drift.

Risks:

- replayed data is no longer a live world observation;
- duplicates coverage already supplied by fixture-only pathfinding;
- cannot satisfy the primary positive-live evidence goal by itself.

Recommendation: useful only as supplementary regression coverage, not as the
Phase 4.13E proof.

### Option D — Naturally Prepared Scenario Terrain Without Mutation

Choose a known naturally solid area produced by existing world generation and
place the test agent there through scenario setup.

Advantages:

- remains a live read-only proof;
- avoids runtime discovery when the area is stable;
- reuses the same scan, semantic, traversability, adapter, and BFS layers.

Risks:

- discovering and maintaining the area still resembles Option A;
- the guarantee may depend on undocumented generation details;
- scenario preparation must not drift into block placement or bespoke world
  construction.

Required safeguards:

- use only naturally generated chunks;
- document the seed, position, and expected terrain evidence;
- prohibit all placement, fill, break, and save-edit paths.

Recommendation: acceptable when it is simply a well-documented form of Option
A, not a custom terrain-building mechanism.

## Recommended Strategy

Phase 4.13E should prefer **Option B: bounded deterministic read-only
discovery**, provided a fixed list of at most 16 candidates is sufficient and
runtime remains small. This gives stronger live evidence than replayed fixtures
and is less brittle than one undocumented coordinate.

If development inspection identifies a single especially stable naturally
generated candidate, Option A is a valid smaller fallback. The selected
approach and candidate evidence must be recorded in the report.

The recommendation does not authorize automatic world exploration, dynamic
goal selection, or agent intelligence. Discovery belongs solely to the smoke
test harness.

## Future Discovery Contract

The future `terrain_pathfinding_column_positive_smoke` may use:

- an ordered constant list of seed/position candidates;
- a recommended maximum of 16 candidates;
- one isolated world/scenario preparation per candidate;
- existing loaded/ready and unchanged-chunk checks;
- `scanTerrainColumns` for exactly nine columns and 27 raw cells;
- the existing pure semantic and traversability transforms;
- the existing column-to-node adapter;
- the existing `findTerrainPath` BFS;
- deterministic stop at the first coherent `found` result;
- explicit failure with a complete attempt report if no candidate succeeds.

Discovery must not generate or load chunks during pathfinding. Scenario setup
may prepare only the bounded chunks required by each documented candidate,
using the same mechanism as existing PebbleLab scenarios.

## Start And Goal Strategies

### Strategy 1 — Fixed Start And Goal

- start: offset `(0,0)`;
- goal: offset `(1,0)`;
- directly comparable with central and edge negative scenarios;
- has the smallest policy surface;
- may reject many otherwise useful natural candidate grids.

This remains preferred when a stable candidate naturally makes both offsets
traversable and connected.

### Strategy 2 — Deterministic Selection Among Traversable Nodes

- start: first traversable column in `dz_then_dx` order;
- goal: first orthogonal traversable neighbor in a fixed neighbor order;
- increases the chance of finding natural positive evidence;
- adds a limited test-harness selection policy.

If used, the report must record candidate order, selected start/goal offsets,
and why the pair was selected. It must not search for distant goals, optimize a
route, score terrain, or expose the rule as agent decision-making.

Recommendation: try fixed `(0,0)` to `(1,0)` first. If the bounded candidate
list cannot provide a stable case, use Strategy 2 as a simple audited test
mechanism. Do not call it agent goal selection.

## Future Outputs

Phase 4.13E may write dedicated files:

- `terrain_pathfinding_column_positive_snapshot.json`;
- `terrain_pathfinding_column_positive_invariant_report.json`;
- `metrics.json`;
- `events.ndjson`.

Alternatively, it may reuse the existing column pathfinding snapshot and report
names inside a dedicated output directory, provided positive discovery metadata
and checks remain explicit.

Suggested metrics:

- `terrainPathfindingColumnPositiveCandidates`;
- `terrainPathfindingColumnPositiveCandidateIndex`;
- `terrainPathfindingColumnPositiveFound`;
- `terrainPathfindingColumnPositivePathLength`;
- `terrainPathfindingColumnPositiveVisited`;
- `terrainPathfindingColumnPositiveSuccess`.

Suggested aggregate event:

`lab_terrain_pathfinding_column_positive_recorded`

Minimum event fields:

- candidates attempted;
- selected candidate index;
- selected seed;
- agent `x/z`;
- node and traversable-node counts;
- path status, length, and visited count;
- success.

No per-candidate, per-node, or per-expansion event is required unless a compact
attempt summary cannot otherwise be audited.

## Future Positive Invariants

A future positive report should check:

1. candidate list exists;
2. candidate count is within the documented bound;
3. selected candidate index is valid;
4. selected candidate column scan succeeded;
5. selected candidate has exactly nine columns;
6. selected candidate maps to exactly nine nodes;
7. start key exists;
8. goal key exists;
9. start is traversable;
10. goal is traversable;
11. path status is `found`;
12. path length is greater than one;
13. path begins at start;
14. path ends at goal;
15. all path nodes are traversable;
16. consecutive path nodes are four-neighbors;
17. no diagonal steps occur;
18. no vertical steps occur;
19. the BFS request uses only mapped column nodes;
20. no mutation was used to create traversable terrain;
21. BFS performed no world reread;
22. no movement was commanded;
23. no collision was performed.

Report success must require all positive checks. Unlike central and edge
negative scenarios, `invalidStart`, `invalidGoal`, and `notFound` are not
successful evidence for this dedicated positive smoke.

## Explicitly Out Of Scope

- movement and actual entity displacement;
- collision queries or guarantees;
- route following;
- agent decisions or intelligent goal selection;
- terrain mutation, `setBlock`, `fill`, placement, or breaking;
- mining, construction, and inventory behavior;
- multi-agent or edge-positive pathfinding;
- dynamic replanning;
- A*, Dijkstra, diagonal neighbors, heuristics, or weighted costs;
- Python, ML, LLM, or reinforcement learning integration.

## Risks And Mitigations

| Risk | Consequence | Mitigation |
| --- | --- | --- |
| Terrain is mutated to force success | The smoke no longer proves generated-world integration | Prohibit every block mutation path and audit unchanged chunks. |
| Test selection becomes agent goal selection | Policy leaks into runtime behavior | Keep selection local to the smoke harness, fixed, simple, and documented. |
| Candidate search is nondeterministic | Results cannot be reproduced | Use a constant ordered candidate list and first-match selection. |
| Too many seeds or positions are searched | Validation and `pebsmoke` become slow | Start with at most 16 candidates and report attempts. |
| World generation changes | A formerly positive candidate becomes negative | Fail with evidence; keep bounded fallback candidates or update the documented contract deliberately. |
| BFS rereads the world | Audited scan evidence is bypassed | Pass only captured nodes to the existing BFS; never pass `World`. |
| Movement begins immediately after `found` | Search evidence is mistaken for an action | Produce JSON evidence only; keep movement in a later planned phase. |
| `found` is treated as collision proof | Abstract route overclaims engine physics | State explicitly that collision and execution remain unproven. |

## Future Phase 4.13E Definition Of Done

- `terrain_pathfinding_column_positive_smoke` exists;
- discovery, if used, is bounded, deterministic, and read-only;
- selected live column scan succeeds;
- exactly nine columns map to nine nodes;
- start and goal are traversable;
- existing `findTerrainPath` returns `found`;
- path length is greater than one;
- every path node maps to captured traversable evidence;
- snapshot, invariant report, metrics, and one aggregate event are written;
- no second BFS is added;
- no movement, collision, route following, or mutation is added;
- central and edge negative live scenarios remain green;
- fixture pathfinding and column scan scenarios remain green;
- no PebbleCore, registry, save/load, renderer, resource, or golden change is
  made;
- `pebsmoke` reports `456 passed, 0 failed`.

## Relationship With Phase 4.14A

Movement planning should begin only after three pieces of evidence exist:

1. central negative live pathfinding rejects unsafe terrain;
2. edge negative live pathfinding rejects unsafe terrain across chunk
   boundaries;
3. positive live pathfinding finds a route over captured traversable nodes.

Phase 4.14A may be written in parallel as docs-only work, but implementation of
movement should preferably wait until Phase 4.13E validates positive live path
evidence. A found route will still require a separate movement contract and a
separate collision boundary.

## Future Validation Commands

cd ~/Dev/pebble-lab

git checkout lab/pebblelab-v1

swift build

swift run -c release PebbleLab -- --scenario terrain_pathfinding_column_positive_smoke --seed 42 --ticks 5 --out runs/check_terrain_pathfinding_column_positive

swift run -c release PebbleLab -- --scenario terrain_pathfinding_column_smoke --seed 42 --ticks 5 --out runs/check_terrain_pathfinding_column_after_positive_plan

swift run -c release PebbleLab -- --scenario terrain_pathfinding_column_edge_smoke --seed 42 --ticks 5 --out runs/check_terrain_pathfinding_column_edge_after_positive_plan

swift run -c release PebbleLab -- --scenario terrain_pathfinding_fixture_smoke --seed 42 --ticks 0 --out runs/check_pathfinding_fixture_after_positive_plan

swift run -c release PebbleLab -- --scenario terrain_column_scan_smoke --seed 42 --ticks 5 --out runs/check_column_scan_after_positive_plan

swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_positive_plan

swift run -c release pebsmoke

git status

## Recommendation

Proceed with **Phase 4.13E — positive live column pathfinding smoke** using a
small bounded deterministic read-only candidate list if practical. Prefer fixed
start `(0,0)` and goal `(1,0)` when a stable candidate supports them; otherwise
use the first traversable node and its first traversable orthogonal neighbor as
an explicitly test-only, audited selection rule. Require `found`, but do not
move the agent or claim collision safety.
