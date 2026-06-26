# Phase 4.18A — Route Following Planning Docs-Only

## Context

PebbleLab now has a layered movement stack with each responsibility proven
separately:

- traversability fixtures classify synthetic support/feet/head evidence;
- live terrain scan and live column scan capture read-only terrain evidence;
- fixture pathfinding validates the bounded deterministic BFS;
- live pathfinding validates coherent negative results and a positive found
  path;
- movement fixtures validate abstract value-state stepping;
- live path to abstract movement validates consuming a live path without live
  displacement;
- collision fixtures validate synthetic occupancy;
- live collision read-only validates one support/feet/head occupancy query;
- denied physical movement validates refusal over non-occupable collision;
- occupable destination search finds a reliable live destination;
- approved single-step physical movement applies exactly one displacement;
- single-step displacement hardening validates approved and denied one-step
  edge cases.

These proofs deliberately stop short of route following. Pathfinding finds an
abstract route. Movement value-state consumes one edge. Collision validates a
destination. Physical movement applies one approved step. Route following must
orchestrate multiple single-steps without blending those responsibilities.

## Route Following Definition

A route is an ordered list of `LabTerrainPathNodeKey` nodes. Route following is
the future process of attempting successive edges from that list:

```text
route[0] -> route[1] -> route[2] -> ... -> route[n]
```

Every edge must pass through the same single-step contract proven in Phase
4.17B2 and hardened in Phase 4.17C. No edge may be applied unless the
destination has explicit live collision evidence with status `occupable`.

A route follower must not become:

- a pathfinder;
- a physics engine;
- a behavior tree;
- a goal selector;
- a dynamic replanner;
- a multi-agent movement coordinator.

It is only an orchestration layer over already validated single-step decisions.

## Responsibility Boundaries

### Pathfinding

Pathfinding produces a route. It does not move an agent, perform physical
collision, follow the route, or apply displacement.

### Movement Value-State

Movement value-state produces an abstract intent or step record. It does not
perform hidden live displacement and does not query collision.

### Collision

Collision verifies whether a destination node is occupable. It refuses
non-occupable destinations. It does not choose routes, perform pathfinding, or
move anything.

### Single-Step Physical Adapter

The single-step adapter applies at most one edge. It is the atomic unit for any
future physical movement. It must remain independently auditable.

### Route Follower

The future route follower orchestrates multiple single-step attempts. It calls
the single-step unit per edge, never skips nodes, stops on the first refusal,
and writes a full audit of every attempted edge.

## Future Route Following Contract

A future route may be followed only when all of these conditions hold:

- route exists;
- path status is `found`;
- route length is greater than 1;
- every edge is 4-neighbor;
- no diagonal edge exists;
- every edge is same-y in v0;
- initial route index is 0;
- current node matches the physical position;
- next node is exactly `route[index + 1]`;
- destination collision is `occupable` before each edge;
- the single-step physical contract is respected for each edge;
- no replanning occurs;
- no pathfinding occurs inside the follower;
- no goal selection occurs;
- no multi-agent movement occurs;
- no avoidance or reservation table is used;
- no physics integration occurs;
- no terrain or world mutation occurs;
- the follower stops on any denied edge;
- final success is true only when the last route node is reached.

## Stopping And Failure Modes

Future route following should distinguish these states:

- `completed`;
- `stoppedCollisionDenied`;
- `stoppedInvalidEdge`;
- `stoppedSourceMismatch`;
- `stoppedDivergence`;
- `stoppedMissingPhysicalHandle`;
- `stoppedStalePath`;
- `stoppedStaleCollision`;
- `stoppedMaxSteps`;
- `stoppedUnexpectedMutation`.

When the follower stops, it must:

- not continue to later edges;
- not skip to another node;
- not search for another route;
- not mutate terrain;
- preserve the last valid position;
- write an explicit reason;
- allow invariant report success when the stop is expected and fully audited.

## Future Status Model

The future implementation may use names like these, adapted to the local Swift
style when implemented:

```swift
enum LabRouteFollowingStatus {
    case completed
    case stoppedCollisionDenied
    case stoppedInvalidEdge
    case stoppedSourceMismatch
    case stoppedDivergence
    case stoppedMissingPhysicalHandle
    case stoppedStalePath
    case stoppedStaleCollision
    case stoppedMaxSteps
    case stoppedUnexpectedMutation
}
```

## Future Snapshot Design

Recommended output:

```text
route_following_snapshot.json
```

Recommended fields:

- `scenario`;
- `seed`;
- `ticksCompleted`;
- `agentId`;
- `physicalId`;
- `coreEntityId`;
- `route`;
- `startNode`;
- `finalNode`;
- `currentIndex`;
- `targetIndex`;
- `attemptedEdges`;
- `completedEdges`;
- `stoppedAtIndex`;
- `status`;
- `reason`;
- `perEdgeRecords`;
- `finalAbstractPosition`;
- `finalPhysicalPosition`;
- `finalCoreEntityPosition`;
- `divergenceBefore`;
- `divergenceAfter`;
- `pathfindingPerformedInsideFollower`;
- `replanningPerformed`;
- `routeFollowingPerformed`;
- `physicsPerformed`;
- `mutationPerformed`;
- `success`.

Recommended per-edge record:

- `edgeIndex`;
- `from`;
- `to`;
- `collisionStatus`;
- `collisionReason`;
- `singleStepStatus`;
- `displacementApplied`;
- `preAbstractPosition`;
- `postAbstractPosition`;
- `prePhysicalPosition`;
- `postPhysicalPosition`;
- `divergenceBefore`;
- `divergenceAfter`;
- `success`.

## Future Invariant Report

Recommended output:

```text
route_following_invariant_report.json
```

Minimum checks:

1. `route_exists`
2. `route_length_greater_than_one`
3. `route_edges_are_contiguous`
4. `all_edges_4_neighbor`
5. `no_diagonal_edges`
6. `same_y_edges_only_v0`
7. `start_position_matches_route_first`
8. `each_edge_uses_single_step_adapter`
9. `collision_checked_before_each_edge`
10. `displacement_requires_occupable_per_edge`
11. `no_skipped_nodes`
12. `route_index_advances_by_one`
13. `stops_on_first_denied_edge`
14. `no_pathfinding_inside_follower`
15. `no_dynamic_replanning`
16. `no_goal_selection`
17. `no_multi_agent_movement`
18. `no_avoidance_or_reservation`
19. `no_physics_integration`
20. `no_world_mutation`
21. `no_terrain_mutation`
22. `divergence_zero_after_each_approved_edge`
23. `final_position_matches_last_completed_node`
24. `completed_status_requires_last_node`
25. `stopped_status_preserves_last_valid_node`
26. `event_written`
27. `snapshot_written`
28. `metrics_written`
29. `success_contract_respected`
30. `single_step_hardening_remains_green`

## Future Metrics

Proposed metrics:

- `routeFollowingAttempted`;
- `routeFollowingCompleted`;
- `routeFollowingStopped`;
- `routeFollowingStatus`;
- `routeFollowingReason`;
- `routeFollowingRouteLength`;
- `routeFollowingAttemptedEdges`;
- `routeFollowingCompletedEdges`;
- `routeFollowingStoppedAtIndex`;
- `routeFollowingDisplacementsApplied`;
- `routeFollowingDeniedEdges`;
- `routeFollowingCollisionDenied`;
- `routeFollowingInvalidEdges`;
- `routeFollowingSourceMismatch`;
- `routeFollowingDivergence`;
- `routeFollowingPathfindingInsideFollower`;
- `routeFollowingReplanningPerformed`;
- `routeFollowingPhysicsPerformed`;
- `routeFollowingMutationPerformed`;
- `routeFollowingSuccess`.

## Future Event

Proposed aggregate event:

```text
lab_route_following_recorded
```

Minimum fields:

- `agentId`;
- `physicalId`;
- `routeLength`;
- `attemptedEdges`;
- `completedEdges`;
- `status`;
- `reason`;
- `stoppedAtIndex`;
- `displacementsApplied`;
- `deniedEdges`;
- `pathfindingInsideFollower`;
- `replanningPerformed`;
- `physicsPerformed`;
- `mutationPerformed`;
- `success`.

Phase 4 route following v0 should not emit one event per edge. The snapshot
contains detailed per-edge records.

## Recommended Future Phase Progression

### Phase 4.18A — Route Following Planning Docs-Only

This phase. It creates the contract and does not modify Swift.

### Phase 4.18B — Route Following Fixture Smoke

Fixture-only. Uses a synthetic route, no `World`, no live agent, and no live
collision. It validates index progression, stops, and no skipped nodes.

### Phase 4.18C — Route Following Denied Live Smoke

Uses a short route with at least one edge denied by collision. Success means a
clean stop with preserved last valid position and explicit reason.

### Phase 4.18D — Route Following Approved Two-Step Smoke

Uses at most two edges with occupable destinations. Applies two approved
single-steps and still avoids long-route gameplay behavior.

### Phase 4.18E — Route Following Hardening

Exercises stale path evidence, stale collision evidence, source mismatch,
mid-route divergence, max steps, and aborted route behavior.

### Phase 4.19A — Multi-Agent Movement Planning Docs-Only

Begins only after the single-agent route follower is reliable and auditable.

## Explicitly Out Of Scope

- gameplay route following;
- long routes;
- continuous movement loops;
- dynamic replanning;
- goal selection;
- behavior trees;
- multi-agent movement;
- avoidance or reservation tables;
- full physics integration;
- jump, fall, swim, or climb;
- velocity, friction, or acceleration;
- combat;
- mining;
- construction;
- inventory;
- animation;
- renderer changes;
- save/load changes;
- registry changes;
- Python, LLM, ML, or RL integration.

## Risks And Mitigations

| Risk | Consequence | Mitigation |
| --- | --- | --- |
| Follower calls pathfinding | Route following becomes dynamic replanning | Require `pathfindingPerformedInsideFollower = false` and invariant coverage. |
| Follower skips nodes | Physical position diverges from route evidence | Require per-edge records and `route_index_advances_by_one`. |
| Non-occupable collision is ignored | Agent moves into blocked, liquid, unknown, or unloaded space | Gate every edge on collision status `occupable`. |
| Route following becomes a gameplay loop | The smoke stops being auditable | Keep 4.18B fixture-only and 4.18D two-step maximum. |
| Dynamic replanning is added too early | Goal/path responsibilities blur | Explicitly record `replanningPerformed = false`. |
| Divergence is not detected | Abstract and physical positions drift silently | Record divergence before/after each edge and require zero after approved edges. |
| Multi-agent concerns enter too early | Avoidance/reservation obscures single-agent correctness | Keep 4.18 single-agent only and defer multi-agent planning to 4.19A. |
| Hidden terrain/world mutation appears | Following a route changes the world unexpectedly | Track mutation flags and prohibit mutation APIs in invariants. |
| Long route is not auditable | Output becomes too large or unclear | Start with fixture route and two-step live smoke only. |
| Expected stop is treated as failure | Denied route cases cannot be used as positive evidence | Let stopped statuses be success when the stop is explicit and audited. |

## Validation For This Docs-Only Phase

Required validation:

```text
git status
swift build
swift run -c release pebsmoke
git diff --check
git status
```

Success for Phase 4.18A means this document exists, the changelog, developer
journal, and roadmap are updated, no Swift files are modified, and the build
and smoke suite remain green.
