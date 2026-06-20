# Phase 4.14A — Movement Planning Docs-Only

## Context

PebbleLab now has the complete read-only evidence chain needed before movement
can be discussed:

- central and edge horizontal terrain scans;
- pure cell semantics;
- pure column traversability;
- central and edge support/feet/head column scans;
- a hardened fixture-only bounded BFS;
- coherent negative central and edge live pathfinding results;
- a positive live pathfinding result from naturally generated terrain.

The positive smoke selected seed 99 at `(8,8)` and produced the abstract path:

`(8,64,8) -> (9,64,8)`

Both nodes came from captured traversable columns. The existing BFS returned
`found` with path length two. No movement, collision, or world mutation was
performed.

This is sufficient path evidence, but it is not physical execution evidence. A
found route does not prove that PebbleCore collision, entity dimensions,
velocity, gravity, or other physical systems permit an entity to follow it.

## Fundamental Distinction

- **Pathfinding** produces an ordered abstract route between node keys.
- **Movement intent** requests one bounded transition toward the next path
  node.
- **Movement execution** applies an allowed intent to a controlled position or
  movement state.
- **Collision** determines whether physical occupancy and displacement are
  valid in the engine.
- **Agent decision** chooses whether and why an agent should follow a route.
- **World mutation** changes blocks or world state and is unrelated to basic
  path movement.

These concerns must remain separate:

- movement must not run pathfinding internally;
- movement must not pretend to implement collision;
- movement must not decide that an agent wants a destination;
- pathfinding must not command movement directly;
- the first movement smoke must consume a path that has already been validated;
- no movement layer may alter blocks to make a step possible.

## Future Phase 4.14B Objective

Phase 4.14B should add a fixture-only scenario:

`terrain_path_movement_fixture_smoke`

It should validate movement state and one-edge stepping over synthetic paths.
It must not use the live positive path, a real agent, `World`, chunks,
collision, or block mutation.

Fixture-first is important because the movement contract itself still needs to
prove:

- path validation;
- initial-state validation;
- one-step intent construction;
- bounded path-index progression;
- goal completion;
- stable post-goal behavior;
- explicit rejection of unsupported edges.

Only after these rules are independently auditable should movement consume live
path evidence.

## Recommended Layered Architecture

The existing and future layers should remain:

1. `LabTerrainPathfinding` produces `LabTerrainPathResult`.
2. A future `LabTerrainMovementPlan` holds an already validated list of node
   keys.
3. A future `LabTerrainMovementState` records current position, target index,
   and movement status.
4. A future `LabTerrainMovementIntent` describes exactly one requested edge.
5. A fixture movement executor applies that intent to an abstract position.
6. A later live adapter may connect an abstract step to an agent movement
   boundary.
7. Collision and physical execution remain separate later phases.

A future file may be named:

`Sources/PebbleLab/LabTerrainMovement.swift`

Phase 4.14A does not create this file.

## Proposed Future Types

The exact API remains a Phase 4.14B decision, but the following shape keeps the
boundaries explicit:

```swift
enum LabTerrainMovementStatus: String, Codable {
    case idle
    case moving
    case reachedGoal
    case invalidPath
    case blocked
    case failed
}

struct LabTerrainMovementState: Codable {
    let current: LabTerrainPathNodeKey
    let path: [LabTerrainPathNodeKey]
    let targetIndex: Int
    let status: LabTerrainMovementStatus
}

struct LabTerrainMovementIntent: Codable {
    let from: LabTerrainPathNodeKey
    let to: LabTerrainPathNodeKey
    let dx: Int
    let dy: Int
    let dz: Int
    let allowed: Bool
    let reason: String
}

struct LabTerrainMovementStepResult: Codable {
    let before: LabTerrainMovementState
    let intent: LabTerrainMovementIntent
    let after: LabTerrainMovementState
    let moved: Bool
}
```

`blocked` should remain reserved in v0. Without a collision or dynamic-obstacle
contract, fixture movement cannot honestly claim that a valid path edge became
physically blocked.

## Recommended Phase 4.14B Rules

The first fixture-only movement contract should enforce:

- a path must be non-empty;
- movement requires a path length greater than one;
- a one-node path represents an already reached goal;
- initial `current` must equal `path[0]`;
- initial target index for a moving path is one;
- one tick advances at most one path edge;
- a moved step must follow the next node in path order;
- nodes may never be skipped;
- every moved edge must have Manhattan distance one;
- diagonal movement is invalid;
- vertical movement is invalid in v0;
- no `World`, chunks, entities, or collision queries are available;
- no block or position outside fixture state is mutated;
- goal is reached after exactly `path.count - 1` successful steps;
- repeated ticks after reaching the goal remain `reachedGoal` and do not move;
- malformed paths return `invalidPath` and do not move;
- movement never invokes pathfinding;
- movement never chooses a different destination.

The fixture executor may update only the immutable-style movement state it
returns. It must not update a live `LabAgent` or physical/core entity.

## Recommended Phase 4.14B Fixtures

The future `terrain_path_movement_fixture_smoke` should include at least:

1. `single_step_reaches_goal`
   - path length two;
   - one step advances from start to goal;
   - final status is `reachedGoal`.
2. `multi_step_reaches_goal`
   - path length four;
   - three ordered steps reach the final node;
   - no intermediate node is skipped.
3. `idle_after_goal`
   - one or more ticks after completion do not move;
   - status remains `reachedGoal`.
4. `empty_path_invalid`
   - empty path is rejected as `invalidPath`;
   - no movement occurs.
5. `single_node_path_reached_goal`
   - current equals the only node;
   - status is immediately `reachedGoal`.
6. `diagonal_step_invalid`
   - an edge changing both x and z is rejected;
   - no movement occurs.
7. `vertical_step_invalid`
   - an edge changing y is rejected in v0;
   - no movement occurs.
8. `non_neighbor_step_invalid`
   - Manhattan distance greater than one is rejected;
   - no movement occurs.
9. `wrong_initial_position_invalid`
   - current does not equal `path[0]`;
   - state becomes `invalidPath` without movement.
10. `no_world_required`
    - the fixture constructs and executes movement with node keys only;
    - no world, chunk, entity, collision, or mutation dependency exists.

Useful optional hardening fixtures may later cover repeated nodes, an invalid
target index, an already-completed multi-node state, and an intent whose `from`
does not match the current state.

## Future Outputs

Phase 4.14B should write:

- `terrain_path_movement_fixture_report.json`;
- `terrain_path_movement_invariant_report.json`;
- `metrics.json`;
- `events.ndjson`.

Suggested metrics:

- `terrainMovementFixtureCases`;
- `terrainMovementFixturePassed`;
- `terrainMovementFixtureFailed`;
- `terrainMovementStepsPlanned`;
- `terrainMovementStepsExecuted`;
- `terrainMovementReachedGoals`;
- `terrainMovementInvalidPaths`;
- `terrainMovementSuccess`.

Suggested aggregate event:

`lab_terrain_movement_fixture_recorded`

Minimum event fields:

- fixtures;
- passed;
- failed;
- steps planned;
- steps executed;
- reached goals;
- invalid paths;
- success.

No event should be emitted per internal validation operation. Per-step events
may be considered only in a later live movement phase where timeline evidence
is necessary.

## Future Invariant Report

`terrain_path_movement_invariant_report.json` should check:

1. fixture inputs exist;
2. every fixture has a path or expects `invalidPath`;
3. valid paths begin at the initial position;
4. one tick advances at most one path edge;
5. every moved step follows path order;
6. no nodes are skipped;
7. no diagonal moves occur;
8. no vertical moves occur;
9. no non-neighbor moves occur;
10. `reachedGoal` occurs only at the final node;
11. post-goal ticks do not move;
12. invalid paths do not move;
13. no `World` access is required;
14. no mutation path is used;
15. no collision is performed;
16. no pathfinding is performed inside movement;
17. no agent decision is performed.

Report success must require every fixture and every invariant to pass.

## Relationship With Live Pathfinding

Phase 4.14B must remain fixture-only. It should not consume
`terrain_pathfinding_column_positive_smoke` output at runtime and should not
move the positive scenario's agent.

Recommended sequence:

- **Phase 4.14B** — terrain path movement fixture smoke;
- **Phase 4.14C** — movement fixture hardening and contract cleanup;
- **Phase 4.15A** — live movement integration planning docs-only;
- **Phase 4.15B** — live movement over a positive path smoke.

Phase 4.15A must define the adapter from abstract movement state to a live agent
boundary, the synchronization expectations, and the collision boundary before
any real position changes are implemented.

## Explicitly Out Of Scope

- live movement or physical entity displacement;
- route following in the real world;
- collision and terrain collision queries;
- gravity, jumping, falling, swimming, or climbing;
- step-height behavior;
- acceleration, velocity, friction, or animation;
- dynamic replanning;
- agent decisions and goal selection;
- multi-agent movement;
- avoidance and reservation tables;
- world mutation, mining, construction, or inventory behavior;
- A*, Dijkstra, diagonals, or weighted terrain costs;
- Python, ML, LLM, or reinforcement learning integration.

## Risks And Mitigations

| Risk | Consequence | Mitigation |
| --- | --- | --- |
| Abstract movement is confused with physics | Fixture success overclaims engine behavior | Name outputs and notes as abstract movement evidence; keep physical execution separate. |
| A found path is assumed executable | Collision and entity-shape constraints are ignored | Require a separate live movement and collision plan before agent displacement. |
| Work jumps directly to live movement | State and progression bugs become difficult to isolate | Validate fixture-only stepping and harden it first. |
| Collision logic appears without a contract | `blocked` becomes arbitrary | Reserve `blocked` and perform no collision in v0. |
| A real agent position is changed in fixture code | Fixture scope leaks into gameplay | Accept and return only synthetic node/state values. |
| Movement chooses a destination | Agent decision leaks into execution | Consume a supplied path exactly; never select or replace goals. |
| Movement calls pathfinding | Search and execution become coupled | Pass a completed path; add a code-review invariant forbidding pathfinding calls. |
| Diagonal or vertical steps slip into v0 | Unsupported motion semantics appear silently | Validate every edge as horizontal Manhattan distance one. |
| Existing pathfinding scenarios regress | Movement changes established evidence | Keep movement in a new PebbleLab module and rerun all fixture/live pathfinding smokes. |

## Future Phase 4.14B Definition Of Done

- `terrain_path_movement_fixture_smoke` exists;
- the scenario is fixture-only and has at least ten cases;
- no `World`, chunks, or real agents are used;
- no collision or mutation is performed;
- movement never invokes pathfinding;
- synthetic paths are validated before stepping;
- one abstract movement step advances at most one edge;
- goal completion and post-goal idling are explicit;
- invalid paths never move;
- fixture report, invariant report, metrics, and one aggregate event are
  written;
- pathfinding fixture, negative central/edge live, positive live, and column
  scan scenarios remain green;
- no PebbleCore, registry, save/load, renderer, resource, or golden change is
  made;
- `pebsmoke` reports `456 passed, 0 failed`.

## Future Validation Commands

cd ~/Dev/pebble-lab

git checkout lab/pebblelab-v1

swift build

swift run -c release PebbleLab -- --scenario terrain_path_movement_fixture_smoke --seed 42 --ticks 0 --out runs/check_terrain_path_movement_fixture

swift run -c release PebbleLab -- --scenario terrain_pathfinding_column_positive_smoke --seed 42 --ticks 5 --out runs/check_positive_path_before_movement

swift run -c release PebbleLab -- --scenario terrain_pathfinding_column_smoke --seed 42 --ticks 5 --out runs/check_negative_central_before_movement

swift run -c release PebbleLab -- --scenario terrain_pathfinding_column_edge_smoke --seed 42 --ticks 5 --out runs/check_negative_edge_before_movement

swift run -c release PebbleLab -- --scenario terrain_pathfinding_fixture_smoke --seed 42 --ticks 0 --out runs/check_pathfinding_fixture_before_movement

swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_before_movement

swift run -c release pebsmoke

git status

## Recommendation

Proceed with **Phase 4.14B — terrain path movement fixture smoke**. Build a
small pure state machine that consumes synthetic validated paths and advances
at most one horizontal four-neighbor edge per tick. Keep `World`, real agents,
collision, pathfinding, goal selection, and mutation entirely outside the
movement module.
