# Phase 4.15A — Live Movement Integration Planning Docs-Only

## Context

PebbleLab now has two independently validated capabilities:

- live pathfinding can derive nodes from captured terrain columns and produce
  coherent negative or positive results;
- fixture-only movement can validate and consume synthetic paths one abstract
  edge at a time.

The positive pathfinding smoke selects naturally generated seed 99 at `(8,8)`
and produces the path `(8,64,8) -> (9,64,8)`. The movement fixture smoke now
contains 22 fixtures and 25 invariants covering path validation, target-index
progression, intent construction, terminal-state stability, and invalid-state
refusal.

No layer currently connects a live-derived path to the abstract movement state
machine. No real agent, physical placeholder, or core entity is displaced, and
no collision is performed. That integration boundary is the subject of this
plan.

## Fundamental Distinction

- **Live pathfinding** builds an abstract route from traversability captured by
  a real read-only column scan.
- **Movement fixture** proves pure stepping over a supplied path without engine
  dependencies.
- **Live movement adapter** transforms a selected live path into an auditable
  abstract movement state and records its steps.
- **Movement intent** describes one requested transition to the next path node.
- **Live agent synchronization** would later copy an approved abstract state to
  a real agent or placeholder.
- **Collision** would later validate physical occupancy and displacement.
- **Route following** would continuously execute a route in gameplay time.
- **Agent decision** would choose whether and why an agent should follow a
  route.

Phase 4.15B must not collapse these boundaries. It is not collision, complete
physics, gameplay route following, or agent behavior. It should prove only that
a path with live provenance can initialize and drive the already validated
abstract movement state machine.

## Future Phase 4.15B Objective

Phase 4.15B should add:

`terrain_path_live_movement_smoke`

The future scenario should:

1. reuse the positive live pathfinding pipeline or its selected path evidence;
2. require path status `found` and path length greater than one;
3. initialize `LabTerrainMovementState` with current equal to the first path
   node;
4. execute one abstract movement step per scenario tick or recorded step;
5. preserve path order and reach the final node;
6. write a dedicated snapshot and invariant report;
7. leave every live agent, physical placeholder, and core entity unchanged;
8. perform no collision query and no world mutation.

Recommendation: Phase 4.15B should implement **live path to abstract movement
state**, not live entity displacement. The path is live-derived; execution is
still isolated in PebbleLab value types.

## Recommended Architecture

The future integration should retain these layers:

1. `LabTerrainPathfindingPositive` selects a live `found` path.
2. `LabTerrainMovement` validates that supplied path and creates the initial
   movement state.
3. A future live movement adapter records the selected candidate and path
   provenance.
4. The adapter repeatedly calls the existing pure movement step function.
5. A dedicated snapshot captures initial state, every abstract step, and final
   state.
6. No result is copied into a `LabAgent`, `LabPhysicalAgentHandle`, or
   `LabCoreAgentEntity` in Phase 4.15B.

A future module may be named:

`Sources/PebbleLab/LabTerrainLiveMovement.swift`

It should contain only provenance/snapshot/report types and the adapter from
positive path evidence to movement state. It must not duplicate pathfinding or
movement stepping logic.

## Proposed Future Types

The exact design remains a Phase 4.15B decision, but the following shape keeps
the evidence explicit:

```swift
struct LabTerrainLiveMovementStepRecord: Codable {
    let tick: Int
    let stepIndex: Int
    let before: LabTerrainMovementState
    let intent: LabTerrainMovementIntent
    let after: LabTerrainMovementState
    let moved: Bool
}

struct LabTerrainLiveMovementSummary: Codable {
    let pathLength: Int
    let stepsExecuted: Int
    let reachedGoal: Bool
    let finalStatus: LabTerrainMovementStatus
    let liveAgentDisplaced: Bool
    let collisionPerformed: Bool
    let mutationPerformed: Bool
    let success: Bool
}

struct LabTerrainLiveMovementSnapshot: Codable {
    let scenario: String
    let seed: UInt32
    let selectedCandidateIndex: Int
    let selectedPath: [LabTerrainPathNodeKey]
    let initialMovementState: LabTerrainMovementState
    let movementSteps: [LabTerrainLiveMovementStepRecord]
    let finalMovementState: LabTerrainMovementState
    let summary: LabTerrainLiveMovementSummary
}
```

The snapshot should also preserve the selected candidate seed and position when
that helps trace the live path source. Those fields describe evidence
provenance; they must not become agent goal-selection inputs.

## Recommended Phase 4.15B Rules

- the selected live pathfinding snapshot must exist;
- its result status must be `found`;
- path length must be greater than one;
- every path node must come from mapped traversable column evidence;
- movement initial current must equal `path[0]`;
- movement must not invoke pathfinding;
- movement must not select or replace a goal;
- exactly one movement edge may execute per recorded tick;
- every step must follow path order;
- no path node may be skipped;
- no diagonal step may occur;
- no vertical step may occur in v0;
- final current must equal `path.last`;
- final status must be `reachedGoal`;
- steps executed must equal `path.count - 1`;
- `liveAgentDisplaced` must be false;
- `collisionPerformed` must be false;
- `mutationPerformed` must be false;
- all output descriptions must call the result abstract live movement
  evidence, not physical movement.

The first integration should finish the selected path in its isolated movement
state. It should not update the candidate world's agent position, bridge
positions, entity coordinates, or chunk data.

## Future Outputs

Phase 4.15B should write:

- `terrain_path_live_movement_snapshot.json`;
- `terrain_path_live_movement_invariant_report.json`;
- `metrics.json`;
- `events.ndjson`.

Suggested metrics:

- `terrainLiveMovementPathLength`;
- `terrainLiveMovementStepsExecuted`;
- `terrainLiveMovementReachedGoal`;
- `terrainLiveMovementFinalStatus`;
- `terrainLiveMovementLiveAgentDisplaced`;
- `terrainLiveMovementCollisionPerformed`;
- `terrainLiveMovementMutationPerformed`;
- `terrainLiveMovementSuccess`.

Suggested aggregate event:

`lab_terrain_live_movement_recorded`

Minimum event fields:

- selected candidate index;
- path length;
- steps executed;
- reached goal;
- final status;
- live-agent-displaced flag;
- collision-performed flag;
- mutation-performed flag;
- success.

One aggregate event is sufficient in Phase 4.15B because the snapshot already
contains every step record. Per-step NDJSON events can be considered only when
live timeline behavior exists.

## Future Invariant Report

`terrain_path_live_movement_invariant_report.json` should check:

1. positive pathfinding snapshot exists;
2. selected path status is `found`;
3. selected path length is greater than one;
4. movement initial current equals the first path node;
5. movement final current equals the last path node;
6. movement final status is `reachedGoal`;
7. executed steps equal `path.count - 1`;
8. every step follows path order;
9. no nodes are skipped;
10. no diagonal steps occur;
11. no vertical steps occur;
12. movement does not invoke pathfinding;
13. no goal selection is performed;
14. no live agent displacement occurs in Phase 4.15B;
15. no collision is performed;
16. no mutation is performed;
17. positive pathfinding evidence remains successful;
18. fixture movement evidence remains successful.

Report success must require every check. A final abstract `reachedGoal` does not
authorize position synchronization or claim physical reachability.

## Relationship With Future Collision

Collision must not be introduced in Phase 4.15B. A collision contract requires
its own investigation of:

- physical occupancy queries;
- entity width, height, and bounding boxes;
- block collision shapes;
- step height and ledges;
- gravity and falling;
- water and swimming behavior;
- dynamic obstacles;
- transitions into reserved `blocked` status.

Reasonable follow-up choices after abstract live movement are:

- **Phase 4.15C** — live movement adapter hardening without collision;
- **Phase 4.16A** — collision planning docs-only.

Neither follow-up should silently turn abstract movement evidence into gameplay
movement.

## Explicitly Out Of Scope

- physical entity displacement;
- real agent position mutation;
- placeholder or core-entity synchronization;
- collision and terrain collision queries;
- gravity, jumping, falling, swimming, or climbing;
- step height;
- acceleration, velocity, friction, or animation;
- gameplay route following;
- dynamic replanning;
- agent decisions and goal selection;
- multi-agent movement;
- avoidance and reservation tables;
- world mutation, mining, construction, or inventory behavior;
- Python, ML, LLM, or reinforcement learning integration.

## Risks And Mitigations

| Risk | Consequence | Mitigation |
| --- | --- | --- |
| A real agent is displaced too early | Integration becomes unplanned gameplay movement | Keep movement entirely in value-state snapshots and assert `liveAgentDisplaced == false`. |
| Abstract movement is presented as physical | Reports overclaim what was proven | Name outputs abstract evidence and retain explicit collision/displacement flags. |
| Collision logic is hidden in movement | `blocked` gains undefined semantics | Perform no collision query and reserve blocked transitions for a dedicated phase. |
| Movement calls pathfinding again | Search and execution become coupled | Consume the selected path exactly and add a code-review invariant. |
| Goal selection appears in the adapter | Agent policy leaks into integration | Use the already selected positive path without substitution. |
| Live position mutation is not audited | Abstract and live states silently diverge | Do not write live positions in Phase 4.15B; snapshot false displacement explicitly. |
| Positive pathfinding regresses | Movement hides or changes its input evidence | Reuse positive outputs unchanged and rerun the positive smoke separately. |
| Movement depends only on seed 99 behavior | Integration becomes confused with candidate discovery | Treat the selected path as generic input; keep candidate provenance separate from stepping. |
| Gameplay begins before snapshots exist | Failures cannot be reconstructed | Require complete initial/step/final JSON evidence before live execution work. |

## Future Phase 4.15B Definition Of Done

- `terrain_path_live_movement_smoke` exists;
- a positive live pathfinding result supplies the selected path;
- path status is `found` and path length is greater than one;
- a movement state is built from that path;
- abstract steps execute in order and reach the goal;
- final status is `reachedGoal`;
- no live agent, placeholder, or core entity is displaced;
- no collision or mutation is performed;
- movement does not invoke pathfinding or goal selection;
- snapshot, invariant report, metrics, and one aggregate event are written;
- movement fixtures remain green;
- positive and negative live pathfinding scenarios remain green;
- no PebbleCore, registry, save/load, renderer, resource, or golden change is
  made;
- `pebsmoke` reports `456 passed, 0 failed`.

## Future Validation Commands

cd ~/Dev/pebble-lab

git checkout lab/pebblelab-v1

swift build

swift run -c release PebbleLab -- --scenario terrain_path_live_movement_smoke --seed 42 --ticks 5 --out runs/check_terrain_path_live_movement

swift run -c release PebbleLab -- --scenario terrain_path_movement_fixture_smoke --seed 42 --ticks 0 --out runs/check_movement_fixture_before_live_movement

swift run -c release PebbleLab -- --scenario terrain_pathfinding_column_positive_smoke --seed 42 --ticks 5 --out runs/check_positive_path_before_live_movement

swift run -c release PebbleLab -- --scenario terrain_pathfinding_column_smoke --seed 42 --ticks 5 --out runs/check_negative_central_before_live_movement

swift run -c release PebbleLab -- --scenario terrain_pathfinding_column_edge_smoke --seed 42 --ticks 5 --out runs/check_negative_edge_before_live_movement

swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_before_live_movement

swift run -c release pebsmoke

git status

## Recommendation

Proceed with **Phase 4.15B — terrain path live movement smoke** as a provenance
integration only. Reuse the positive live path, feed it into the existing pure
movement state machine, record every abstract step, and require
`reachedGoal`. Keep all live positions unchanged and make no collision or
mutation claim.

## Phase 4.15B Implementation Status

Phase 4.15B implemented and validated `terrain_path_live_movement_smoke`.
The scenario reuses positive pathfinding evidence and the existing movement
validation and stepping functions; it contains no second pathfinder and no
independent movement state machine.

The selected evidence is candidate index zero, seed 99 at `(8,8)`, with path
`(8,64,8) -> (9,64,8)`. One abstract eastward step reaches `reachedGoal`.
The dedicated snapshot reports `liveAgentDisplaced = false`,
`collisionPerformed = false`, and `mutationPerformed = false`. Its invariant
report passes all 18 checks. Physical displacement, collision, route following,
mutation, and multi-agent movement remain outside the implemented scope.

## Phase 4.15C Hardening Status

Phase 4.15C hardened the existing adapter and scenario without adding collision,
physical synchronization, a second scenario, or new output formats. The
invariant report now passes 28 checks.

The added checks audit selected-candidate metadata and its exact match with the
positive summary, byte-for-structure selected-path consumption, initial
`moving` state and target index, path/step/summary agreement, successful intent
reasons, and the contractual false displacement/collision/mutation flags. A
pure synthetic guard also proves that absent or invalid positive evidence
cannot create a movement snapshot or any abstract steps. Metrics and the
aggregate event remain populated directly from the snapshot summary and are
audited at runner validation time.
