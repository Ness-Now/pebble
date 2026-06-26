# Phase 4.17A - Physical Movement Integration Planning Docs-Only

## Purpose

Phase 4.17A defines the contract for a future physical movement integration
layer. It does not implement physical displacement. It does not create a
scenario, modify Swift code, alter gameplay, mutate the world, or change
PebbleCore.

The goal is to plan how PebbleLab can eventually combine:

- a positive live path;
- validated abstract movement state;
- validated read-only live collision/occupancy evidence;

to authorize or deny one real physical displacement of one agent across one
horizontal edge.

## Starting Point

PebbleLab already has independent evidence for the pieces that a future
physical displacement adapter will need:

- terrain traversability fixtures classify synthetic support/feet/head columns;
- terrain scan live smokes read bounded world cells;
- terrain column scan live smokes capture support/feet/head evidence;
- pathfinding fixtures validate deterministic bounded BFS;
- live pathfinding central and edge smokes prove coherent negative results;
- live positive pathfinding proves a short `found` path from captured terrain;
- terrain movement fixtures validate value-state stepping over synthetic paths;
- live path to abstract movement consumes a positive live path without
  displacement;
- collision fixtures validate pure body occupancy decisions;
- collision live read-only validates one live node without movement or mutation.

These proofs remain separate. Pathfinding proves a route. Movement proves
value-state progression. Collision proves whether a candidate node is
occupable. None of them moves a `LabAgent`, physical placeholder, or core
entity.

The current live movement evidence consumes the positive path
`(8,64,8) -> (9,64,8)` from seed 99 and reaches the abstract goal with
`liveAgentDisplaced = false`, `collisionPerformed = false`, and
`mutationPerformed = false`.

The current live collision read-only evidence samples node `(8,64,8)` with
seed 42. Support is water, feet/head are air, and collision v0 returns
`liquidUnsupported` with reason `liquid_support`. That node is not an approved
physical destination.

## Future Phase 4.17B Objective

Future Phase 4.17B is proposed as:

`Phase 4.17B - Single-Step Physical Displacement Smoke`

That future phase should prove one bounded physical displacement decision. It
should:

- choose one agent;
- choose one short positive live path;
- choose one edge `from -> to`;
- verify the movement intent for that edge;
- verify collision/occupancy for the destination node;
- approve or deny one physical displacement;
- if approved, synchronize exactly one displacement;
- write snapshot, invariant report, metrics, and one aggregate event;
- avoid route following;
- avoid multi-agent movement;
- avoid full physics integration.

Phase 4.17B must still be a smoke, not gameplay movement.

## Responsibility Boundaries

### Pathfinding

Pathfinding finds an abstract route. It does not move anything, does not query
physical collision, does not select gameplay goals during displacement, and
must not run again inside the displacement adapter.

### Movement Value-State

Movement value-state consumes a route and produces an intent or one abstract
step. It does not mutate a real agent, does not synchronize a physical
placeholder, and does not perform collision checks.

### Collision

Collision judges whether a candidate destination node is occupable for a body
contract. It does not choose paths, advance movement, displace entities, or
mutate the world.

### Physical Displacement Adapter

The future physical displacement adapter is the only layer allowed to apply a
real displacement, and only after path, movement, and collision evidence agree.
It must be audited separately and must report whether it approved or denied the
attempt.

### Core Entity And Physical Placeholder Sync

Any synchronization to a physical placeholder or core entity must be explicit.
No implicit position mirroring, hidden sync, or background route following is
allowed.

## Minimum Approval Conditions

A future approved displacement requires all of the following:

- path evidence exists;
- path status is `found`;
- path length is greater than 1;
- selected edge exists in the path;
- selected edge is horizontal and 4-neighbor;
- no diagonal edge;
- same-y edge only;
- movement intent is valid;
- expected movement result is coherent with the selected edge;
- live collision evidence exists for the destination;
- collision snapshot success is true;
- destination occupancy status is `occupable`;
- destination support/feet/head samples are loaded;
- destination support/feet/head samples are ready;
- chunk state is unchanged before the decision;
- no pathfinding runs during displacement;
- no replanning occurs during displacement;
- no goal selection occurs during displacement;
- source and target coordinates are preserved from evidence to adapter;
- physical handle exists;
- core entity link exists if the scenario requires one;
- pre-move abstract position matches the expected source;
- pre-move physical position matches the expected source if physical sync is
  being tested;
- post-move physical position matches the expected target if approved;
- post-move core entity position matches the expected target if core sync is
  being tested;
- no unexpected divergence appears after the attempt.

If collision returns `liquidUnsupported`, `blocked`, `unknown`, `notLoaded`,
`notReady`, `unsupported`, `verticalSpaceOccupied`, or `outOfBounds`, the
future displacement must be denied.

## Refusal Path

Denied displacement is a valid outcome when the evidence says the target cannot
be occupied. A denied attempt must:

- leave the `LabAgent` position unchanged;
- leave the physical placeholder unchanged;
- leave the core entity unchanged;
- leave the world unchanged;
- write decision status `denied` or a more specific denial status;
- preserve an explicit reason;
- emit one aggregate event;
- allow the invariant report to succeed when the refusal is expected and fully
  audited.

Examples of denial reasons:

- destination non-occupable;
- target not loaded;
- target not ready;
- support liquid;
- feet blocked;
- head blocked;
- source mismatch;
- stale path;
- stale collision evidence;
- missing physical handle;
- missing core entity link;
- divergence before move.

## Future Status Model

The future implementation can use a status model like this, adapted to the
project style at implementation time:

```swift
enum LabPhysicalMovementStatus {
    case approved
    case denied
    case sourceMismatch
    case collisionDenied
    case missingPhysicalHandle
    case missingCoreEntity
    case divergenceBeforeMove
    case divergenceAfterMove
    case mutationDetected
}
```

The status must describe the physical displacement decision, not pathfinding,
movement fixture execution, or collision classification by itself.

## Future Snapshot Design

Future Phase 4.17B should write:

`physical_movement_integration_snapshot.json`

Recommended fields:

- `scenario`;
- `seed`;
- `ticksCompleted`;
- `agentId`;
- `physicalId`;
- `coreEntityId`;
- `from`;
- `to`;
- `selectedPath`;
- `movementIntent`;
- `movementBefore`;
- `movementAfter`;
- `collisionSnapshot`;
- `collisionStatus`;
- `decision`;
- `displacementApplied`;
- `preAbstractPosition`;
- `postAbstractPosition`;
- `prePhysicalPosition`;
- `postPhysicalPosition`;
- `preCoreEntityPosition`;
- `postCoreEntityPosition`;
- `divergenceBefore`;
- `divergenceAfter`;
- `mutationPerformed`;
- `pathfindingPerformed`;
- `routeFollowingPerformed`;
- `physicsPerformed`;
- `success`.

The snapshot should make denial just as auditable as approval.

## Future Invariant Report

Future Phase 4.17B should write:

`physical_movement_integration_invariant_report.json`

Minimum checks:

1. `path_evidence_exists`
2. `selected_edge_exists`
3. `selected_edge_is_4_neighbor`
4. `no_diagonal_edge`
5. `same_y_edge`
6. `movement_intent_matches_edge`
7. `collision_evidence_exists`
8. `collision_status_explicit`
9. `collision_reason_explicit`
10. `displacement_requires_occupable`
11. `denied_if_non_occupable`
12. `no_pathfinding_during_displacement`
13. `no_route_following`
14. `no_goal_selection`
15. `no_multi_agent_movement`
16. `no_physics_integration`
17. `no_world_mutation`
18. `source_position_matches_before_move`
19. `target_position_matches_after_move_if_approved`
20. `no_position_change_if_denied`
21. `physical_handle_exists_if_approved`
22. `core_entity_link_exists_if_required`
23. `divergence_zero_after_approved_move`
24. `divergence_preserved_after_denied_move`
25. `event_written`
26. `snapshot_written`
27. `metrics_written`
28. `success_contract_respected`

## Future Metrics

Recommended metrics:

- `physicalMovementAttempted`;
- `physicalMovementApproved`;
- `physicalMovementDenied`;
- `physicalMovementStatus`;
- `physicalMovementReason`;
- `physicalMovementFromX`;
- `physicalMovementFromY`;
- `physicalMovementFromZ`;
- `physicalMovementToX`;
- `physicalMovementToY`;
- `physicalMovementToZ`;
- `physicalMovementCollisionStatus`;
- `physicalMovementDisplacementApplied`;
- `physicalMovementPathfindingPerformed`;
- `physicalMovementRouteFollowingPerformed`;
- `physicalMovementPhysicsPerformed`;
- `physicalMovementMutationPerformed`;
- `physicalMovementDivergenceBefore`;
- `physicalMovementDivergenceAfter`;
- `physicalMovementSuccess`.

## Future Event

Future Phase 4.17B should emit one aggregate event:

`lab_physical_movement_integration_recorded`

Minimum fields:

- `agentId`;
- `physicalId`;
- `coreEntityId`;
- `from`;
- `to`;
- `status`;
- `reason`;
- `collisionStatus`;
- `displacementApplied`;
- `pathfindingPerformed`;
- `routeFollowingPerformed`;
- `physicsPerformed`;
- `mutationPerformed`;
- `divergenceBefore`;
- `divergenceAfter`;
- `success`.

Phase 4.17B should not emit one event per micro-step.

## Future Scenario

Proposed scenario name:

`physical_movement_single_step_smoke`

Scope:

- one agent;
- one selected path edge;
- one attempted step;
- same-y only;
- no diagonal;
- no route following;
- no replanning;
- no multi-agent movement;
- no full physics;
- no world mutation;
- no mining, construction, or inventory behavior.

## Relation To Current `liquidUnsupported` Evidence

The current Phase 4.16C live collision node is `(8,64,8)`. Its support sample is
water and the collision result is `liquidUnsupported` with reason
`liquid_support`.

That node must not be treated as an approved physical destination.

For Phase 4.17B, PebbleLab should either:

- find or choose a live destination node with occupancy `occupable`;
- begin with an expected denied physical movement smoke over non-occupable live
  collision evidence;
- split the work into one denied smoke and one approved smoke.

The recommended subdivision is:

- Phase 4.17B1 - Denied Physical Movement Smoke;
- Phase 4.17B2 - Approved Single-Step Physical Displacement Smoke.

This avoids forcing an approved displacement before the denial path is
auditable.

## Recommended Future Phases

### Phase 4.17A - Physical Movement Integration Planning Docs-Only

This phase. It creates the contract and does not modify Swift code.

### Phase 4.17B1 - Denied Physical Movement Smoke

Attempt one movement onto a non-occupable live collision target. Collision
denies the attempt. No agent, placeholder, or core entity moves. The scenario
succeeds only if denial is explicit and fully audited.

### Phase 4.17B2 - Approved Single-Step Physical Displacement Smoke

Use a destination with live occupancy `occupable`. Apply exactly one physical
displacement and synchronize abstract, physical, and core positions. Verify
zero divergence. Do not introduce route following.

### Phase 4.17C - Single-Step Displacement Hardening

Cover source mismatch, stale path evidence, stale collision evidence, missing
handles, missing links, and divergence before or after the attempt.

### Phase 4.18A - Route Following Planning Docs-Only

Plan multi-step route consumption only after single-step displacement is
reliable.

## Phase 4.17B1 Implementation Status

Phase 4.17B1 implements the denied physical movement smoke described here. The
scenario is `physical_movement_denied_smoke`.

The smoke uses the current non-occupable live collision evidence for node
`(8,64,8)`: support is water, feet/head are air, and collision v0 returns
`liquidUnsupported` with reason `liquid_support`. It prepares a single-step
attempt from `(7,64,8)` to `(8,64,8)` and correctly refuses the move with
status `collisionDenied` and reason
`collision_denied_liquid_support_non_occupable`.

No displacement is applied. The audited positions remain:

- abstract: `(7,64,8) -> (7,64,8)`;
- physical placeholder: `(7,64,8) -> (7,64,8)`;
- core entity: absent for this denied smoke.

Divergence remains `0 -> 0`. The scenario writes
`physical_movement_integration_snapshot.json`,
`physical_movement_integration_invariant_report.json`, `metrics.json`, and
`events.ndjson`. The invariant report validates 22 checks and the metrics use
the `physicalMovement*` prefix.

The denied smoke intentionally does not create a core entity, because
constructing one through the existing bridge adds a live world entity. Keeping
the core fields absent preserves the no-world-mutation boundary while still
auditing that no core entity position changes.

Phase 4.17B2 should not approve a displacement until a reliable destination
with collision status `occupable` is identified.

## Phase 4.17B2A Implementation Status

Phase 4.17B2A implements a bounded read-only search for a future approved
physical movement destination. The scenario is
`physical_movement_find_occupable_smoke`.

The search is deterministic and intentionally small:

- candidate 0: seed 42, node `(8,64,8)`;
- candidate 1: seed 99, node `(8,64,8)`;
- candidate 2: seed 99, node `(9,64,8)`.

Candidate 0 preserves the currently audited non-occupable evidence from the
denied smoke: support is water and collision returns `liquidUnsupported` with
reason `liquid_support`. Candidate 1 is the first occupable destination:
support is `grass_block`, feet/head are `air`, and collision returns
`occupable` with reason `full_cube_support_empty_body_volume`.

The phase writes `physical_movement_occupable_search_snapshot.json`,
`physical_movement_occupable_search_invariant_report.json`, `metrics.json`,
and `events.ndjson`. The invariant report validates 22 checks covering bounded
candidate order, explicit status/reason, first-occupable selection, preserved
coordinates, live read-only collision reuse, and no movement, displacement,
pathfinding, route following, physics, or mutation.

This phase still applies no physical displacement. It only identifies that
seed 99 node `(8,64,8)` can feed Phase 4.17B2 as a destination candidate.

## Explicitly Out Of Scope

- route following;
- multiple physical steps;
- dynamic replanning;
- multi-agent movement;
- avoidance or reservation tables;
- combat;
- mining;
- construction;
- inventory behavior;
- full physics integration;
- jump, fall, swim, or climb;
- velocity, friction, or acceleration;
- animation;
- rendering changes;
- save/load changes;
- registry changes;
- Python, LLM, ML, or RL integration.

## Risks And Mitigations

| Risk | Consequence | Mitigation |
| --- | --- | --- |
| Abstract `reachedGoal` is treated as physical displacement | A value-state proof silently becomes a real move | Require separate physical snapshot fields and displacement flags. |
| Non-occupable collision evidence is ignored | Agents can move into liquid, blocked, unknown, or unloaded space | Gate approval on destination status `occupable` only. |
| Hidden movement enters this planning phase | Docs-only boundary is broken | Do not modify Swift code in Phase 4.17A. |
| Route following is added too early | One-step proof turns into gameplay movement | Restrict Phase 4.17B to a single selected edge. |
| Approved move lacks a physical handle or core link | Snapshot cannot prove what moved | Require handles before approval and deny when missing. |
| Divergence appears after move | Abstract, physical, and core positions disagree | Record pre/post positions and assert divergence zero after approved moves. |
| Stale path or collision evidence is reused | Approval is based on outdated data | Preserve source snapshots and invalidate mismatched coordinates or statuses. |
| Mutation is accidentally added | Displacement smoke changes terrain or world state | Track `mutationPerformed = false` and audit no mutation APIs. |
| Current non-occupable node is mistakenly approved | The `liquidUnsupported` evidence is misread as safe | Explicitly deny all non-occupable statuses. |
| Multi-agent concerns leak too early | Avoidance and reservations obscure the single-agent contract | Keep Phase 4.17B one agent only. |

## Validation For This Docs-Only Phase

Required validation:

```text
git status
swift build
swift run -c release pebsmoke
git status
```

Success for Phase 4.17A means this document exists, the changelog, developer
journal, and roadmap are updated, no Swift files are modified, and the standard
build and smoke suite remain green.
