# Phase 4.19A - Multi-Agent Movement Planning Docs-Only

## 1. Starting State

PebbleLab now has a controlled single-agent movement stack:

- the physical placeholder exists and remains the safest live movement handle;
- the core entity probe exists, but remains experimental, unregistered, and
  gated;
- fixture and live read-only collision checks exist;
- denied and approved single-step physical movement exist;
- single-step physical movement hardening exists;
- fixture-only route following exists;
- denied live route following exists;
- approved two-step live route following exists;
- live route following hardening exists;
- no multi-agent movement implementation exists yet.

The last validated phase, Phase 4.18E, hardened live route following through
`route_following_live_hardening_smoke`. It validated 8 cases, 8 passed cases,
0 failed cases, 1 completed case, 7 stopped cases, 9 attempted edges, 4
completed edges, 4 applied displacements, and 5 denied edges. It also wrote a
hardening report, invariant report, `routeFollowingLiveHardening*` metrics,
and one `lab_route_following_live_hardening_recorded` event.

That result is important but deliberately limited. A reliable single-agent
route follower is not enough to authorize several agents. Multiple agents add
global conflicts that a local follower cannot see:

- two agents may request the same destination;
- two agents may request opposite directions over the same edge;
- agents may create cycles or swap conflicts;
- movement needs a deterministic arbitration order;
- movement needs a clear distinction between intention, reservation, and
  application.

The current route follower remains bounded, deterministic, single-agent, and
free of pathfinding inside the follower, replanning, goal selection, physics,
terrain/world mutation, multi-agent movement, avoidance, and reservation
runtime behavior.

## 2. Multi-Agent Movement Definition In PebbleLab

In PebbleLab, future multi-agent movement means:

- several agents each have an abstract position;
- each agent may have a short route that was already validated elsewhere;
- each agent produces an intention for its next edge;
- no intention is applied immediately;
- an arbiter collects all intentions for the tick;
- the arbiter detects conflicts;
- the arbiter accepts or refuses individual movements;
- only accepted movements are applied through the existing single-step or
  route-following contract;
- refused movements preserve the agent's last valid position;
- the result is deterministic for the same scenario, seed, agent set, and
  intentions.

Multi-agent movement v0 is not:

- crowd simulation;
- steering;
- animation;
- physics;
- replanning;
- multi-agent pathfinding;
- social behavior;
- final gameplay movement.

## 3. Difference From Single-Agent Route Following

Single-agent route following has:

- one agent;
- one route;
- one `currentIndex`;
- one controlled edge per step;
- local destination collision;
- local stop conditions;
- no agent-agent conflict.

Multi-agent movement has:

- N agents;
- N intentions;
- node conflicts;
- edge conflicts;
- swaps;
- priority;
- partial refusals;
- simultaneous or ordered application semantics;
- global tick coherence;
- aggregate logs;
- global invariants.

The first multi-agent layer must not make `LabRouteFollowing` or
`LabRouteFollowingLive` responsible for global conflict resolution. A route
follower can propose a next edge. A separate arbiter decides whether the
proposed edge may be applied during the tick.

## 4. Responsibilities By Layer

### Agent Policy

Agent policy may choose a future goal or route. It is out of scope for
Phase 4.19A and should not resolve global movement conflicts.

### Pathfinding

Pathfinding supplies a route for one agent. In v0 it does not know about other
agents and does not repair routes during arbitration.

### Route Follower

The route follower produces the next edge intent for one agent. In a future
multi-agent mode it must not directly apply that edge. It remains ignorant of
global conflicts.

### Multi-Agent Movement Arbiter

The future arbiter collects intentions, checks conflicts, applies a
deterministic accept/refuse policy, and writes an aggregate report.

### Single-Step Movement

Single-step movement remains the only layer that actually applies an accepted
edge. It continues to verify destination collision and to refuse
non-occupable destinations.

### Collision

Collision verifies terrain/body occupancy. It does not decide priority between
agents.

### Future Reservation Table

A reservation table may be introduced later, after fixture arbitration is
stable. Phase 4.19A is planning only and introduces no reservation table
runtime implementation.

## 5. Conflicts To Plan For

1. Same destination conflict

   Two agents want to move into the same node during the same tick.

2. Edge swap conflict

   Agent A wants to move from X to Y while agent B wants to move from Y to X.

3. Crossing edge conflict

   Two edge paths cross without sharing endpoints. This may matter later, but
   is probably out of scope for v0 if movement is limited to a 4-neighbor grid.

4. Occupied destination conflict

   An agent wants to move into a node occupied by another agent that is not
   moving away.

5. Moving-away destination

   An agent wants to move into a node currently occupied by another agent that
   intends to leave during the same tick. This needs explicit policy because
   it creates dependencies between approvals.

6. Chain dependency

   Agent A wants B's node, B wants C's node, and so on. A conservative v0 can
   deny the dependent moves instead of proving the full chain safe.

7. Cycle

   Agent A wants B's position, B wants C's position, and C wants A's position.
   Cycles should be denied in v0 unless a later phase proves deterministic
   simultaneous cycle application.

8. Route denial conflict

   One agent is accepted on edge 0 while another is refused, causing their
   future route states to diverge. The first implementation must define how a
   refused route state is preserved or stopped.

9. Priority conflict

   Two agents want the same destination but have different priority values or
   stable order positions.

10. Stale intention

   The intention was computed from a source node that no longer matches the
   agent's current position.

## 6. Recommended Deterministic V0 Policy

The first implementation should be deliberately conservative:

- collect all intentions for the tick;
- sort agents by stable `agentId`;
- deny any intention whose source does not match the current position;
- deny any destination that is not occupable;
- deny same-destination conflicts except for the first agent in stable order;
- deny swaps in v0;
- deny cycles in v0;
- apply at most one edge per agent per tick;
- do not replan;
- do not search for an alternative;
- do not push another agent;
- do not move two agents into the same destination;
- log every denial with an explicit reason.

This policy is intentionally conservative. It prefers a stable stopped result
over a clever movement that hides coupling between route state, collision
evidence, and future physics.

## 7. Proposed Future Types

These names are planning sketches only. Phase 4.19A does not add Swift code.

```swift
enum LabMultiAgentMovementStatus: String, Codable {
    case notStarted
    case collectedIntentions
    case resolved
    case applied
    case partiallyApplied
    case stopped
    case failedInvariant
}

enum LabMultiAgentMoveDecision: String, Codable {
    case approved
    case deniedSourceMismatch
    case deniedCollision
    case deniedSameDestinationConflict
    case deniedOccupiedDestination
    case deniedSwapConflict
    case deniedCycleConflict
    case deniedStaleIntent
    case deniedMissingAgent
    case deniedMissingPhysicalHandle
    case deniedDivergence
}

struct LabAgentMoveIntent: Codable {
    let agentId: String
    let routeId: String?
    let from: LabTerrainPathNodeKey
    let to: LabTerrainPathNodeKey
    let routeIndex: Int?
    let reason: String
}

struct LabAgentMoveResolution: Codable {
    let agentId: String
    let intent: LabAgentMoveIntent
    let decision: LabMultiAgentMoveDecision
    let approved: Bool
    let reason: String
}

struct LabMultiAgentMovementSnapshot: Codable {
    let scenario: String
    let seed: UInt32
    let tick: Int
    let agentCount: Int
    let intents: [LabAgentMoveIntent]
    let resolutions: [LabAgentMoveResolution]
    let approvedCount: Int
    let deniedCount: Int
    let finalPositions: [String: LabTerrainPathNodeKey]
    let success: Bool
}
```

## 8. Recommended Future Scenario Split

### Phase 4.19B - Multi-Agent Movement Fixture Planning/Contract Smoke

- fixture-only;
- no `World`;
- no live collision;
- synthetic agents;
- synthetic intentions;
- validate arbiter rules only.

### Phase 4.19C - Multi-Agent Movement Fixture Hardening

Recommended cases:

- two agents with different destinations approved;
- same destination conflict;
- occupied destination;
- swap conflict;
- source mismatch;
- stale intent;
- missing physical handle;
- partial approval;
- all denied;
- deterministic ordering.

### Phase 4.19D - Multi-Agent Live Read-Only Collision Intent Smoke

- use live collision snapshots;
- no movement application;
- collect candidate intentions;
- verify collision evidence before future movement.

### Phase 4.19E - Multi-Agent Approved Physical Movement Smoke

- two or three agents maximum;
- one edge each;
- no conflicts;
- approved destinations;
- apply using the existing single-step contract;
- no replanning;
- no route continuation beyond one step.

### Phase 4.19F - Multi-Agent Movement Hardening

- same destination;
- swap;
- partial approval;
- collision denied;
- source mismatch;
- divergence;
- stale collision;
- max agents/tick bound.

## 9. Future Outputs

Recommended files:

- `multi_agent_movement_report.json`;
- `multi_agent_movement_invariant_report.json`;
- `multi_agent_movement_snapshot.json`;
- `metrics.json`;
- `events.ndjson`.

Recommended report fields:

- `scenario`;
- `seed`;
- `ticksCompleted`;
- `success`;
- `agentCount`;
- `intents`;
- `resolutions`;
- `approved`;
- `denied`;
- `conflictSummary`;
- `finalPositions`;
- `divergenceSummary`;
- `outOfScopeFlags`.

## 10. Future Metrics

Recommended metrics:

- `multiAgentMovementAttempted`;
- `multiAgentMovementAgentCount`;
- `multiAgentMovementIntentCount`;
- `multiAgentMovementApproved`;
- `multiAgentMovementDenied`;
- `multiAgentMovementSameDestinationConflicts`;
- `multiAgentMovementSwapConflicts`;
- `multiAgentMovementOccupiedDestinationConflicts`;
- `multiAgentMovementSourceMismatch`;
- `multiAgentMovementCollisionDenied`;
- `multiAgentMovementDivergence`;
- `multiAgentMovementMaxDivergence`;
- `multiAgentMovementPathfindingPerformed`;
- `multiAgentMovementReplanningPerformed`;
- `multiAgentMovementPhysicsPerformed`;
- `multiAgentMovementMutationPerformed`;
- `multiAgentMovementSuccess`.

## 11. Future Event

Recommended aggregate event:

```text
lab_multi_agent_movement_recorded
```

Recommended fields:

- `agentCount`;
- `intentCount`;
- `approved`;
- `denied`;
- `sameDestinationConflicts`;
- `swapConflicts`;
- `collisionDenied`;
- `sourceMismatch`;
- `divergence`;
- `success`.

The first smoke should not emit one event per agent or per edge. Per-agent and
per-edge evidence belongs in the dedicated report.

## 12. Future Invariants

Recommended invariant checks:

1. `agents_exist`
2. `agent_count_matches_report`
3. `intents_exist`
4. `every_intent_has_agent_id`
5. `every_intent_has_explicit_source`
6. `every_intent_has_explicit_destination`
7. `every_intent_edge_is_4_neighbor`
8. `no_diagonal_edge`
9. `same_y_only_v0`
10. `sources_match_current_positions`
11. `stale_intents_denied`
12. `missing_agents_denied`
13. `missing_physical_handles_denied_when_live_movement_is_used`
14. `collision_checked_before_approval_when_live_collision_is_used`
15. `non_occupable_destination_denied`
16. `occupied_static_destination_denied`
17. `same_destination_conflict_detected`
18. `same_destination_conflict_resolves_deterministically`
19. `no_duplicate_approved_destination`
20. `swap_conflict_detected`
21. `no_approved_swap_conflict`
22. `cycle_conflict_detected_or_explicitly_out_of_scope`
23. `cycles_denied_in_v0`
24. `agent_ordering_is_stable`
25. `priority_policy_is_explicit`
26. `denied_movement_preserves_position`
27. `approved_movement_changes_position_by_exactly_one_edge`
28. `no_skipped_nodes`
29. `one_edge_per_agent_per_tick`
30. `partial_approval_summary_coherent`
31. `approved_count_matches_resolutions`
32. `denied_count_matches_resolutions`
33. `final_positions_coherent`
34. `divergence_summary_coherent`
35. `max_divergence_bounded`
36. `single_step_contract_remains_owner_of_displacement`
37. `displacement_requires_occupable_when_live_movement_is_used`
38. `no_pathfinding_inside_arbiter`
39. `no_dynamic_replanning`
40. `no_goal_selection`
41. `no_avoidance_implementation`
42. `no_reservation_table_implementation_in_first_fixture_smoke`
43. `no_physics`
44. `no_world_mutation`
45. `no_terrain_mutation`
46. `report_written`
47. `snapshot_written`
48. `metrics_written`
49. `event_written`
50. `success_contract_respected`

## 13. Interaction With Route Following

Single-agent route following remains valid and should not be modified by the
first multi-agent movement phase. The future integration should treat the route
follower as an intent producer:

- route following can produce a future "next edge intent";
- the arbiter decides whether that intent can be applied;
- if the intent is refused, route follower state must either remain unchanged
  or stop according to a future explicit contract;
- no replanning occurs in v0;
- no route repair occurs in v0;
- long route following remains out of scope.

The multi-agent arbiter must not call pathfinding inside arbitration and must
not make the route follower responsible for agent-agent conflict resolution.

## 14. Interaction With Core Entity

Current live route following can remain placeholder-based. Core entity
synchronization exists, but should not be expanded during this docs-only phase.

Future multi-agent movement should probably be placeholder-first:

- validate fixture arbitration before live movement;
- validate live read-only collision intentions before displacement;
- apply only accepted edges through the existing single-step contract;
- defer core entity multi-agent movement to a separate later phase;
- keep save/load out of scope.

## 15. Explicitly Out Of Scope

The following remain out of scope for Phase 4.19A:

- implementation of multi-agent movement;
- reservation table runtime;
- avoidance;
- dynamic replanning;
- pathfinding during arbitration;
- multi-agent pathfinding;
- swarm behavior;
- flocking;
- steering;
- physics;
- gravity;
- velocity;
- jump;
- fall;
- swim;
- climb;
- route repair;
- long route following;
- goal selection;
- social behavior;
- communication;
- combat;
- mining;
- construction;
- inventory;
- animation;
- renderer changes;
- shader changes;
- resource changes;
- save/load changes;
- registries;
- Python;
- LLM;
- RL.

## 16. Risks And Mitigations

| Risk | Mitigation |
| --- | --- |
| Arbiter accidentally becomes pathfinder. | Add explicit `no_pathfinding_inside_arbiter` metrics and invariants, and feed only prebuilt synthetic intentions in the first fixture smoke. |
| Route follower starts moving without arbitration. | Keep route follower as an intent producer in multi-agent mode and require all movement application to pass through resolutions. |
| Same destination conflict silently allowed. | Add fixture cases with two agents targeting the same node and require no duplicate approved destination. |
| Swap conflict silently allowed. | Add explicit opposite-edge fixture cases and deny swaps in v0. |
| Deterministic ordering is not stable. | Sort by stable `agentId` and assert emitted resolution order. |
| Partial approvals break route state. | Define refused-route state preservation or stop semantics before live route continuation. |
| Denied agent moves anyway. | Assert denied pre/post positions are identical and displacement count excludes denied resolutions. |
| Stale intent is applied. | Deny any intent whose source does not match the agent's current position. |
| Collision evidence is reused incorrectly. | Attach collision evidence to the destination and tick, then assert source/destination coherence in live phases. |
| Report claims no mutation without checking. | Carry explicit out-of-scope flags and use live unchanged-world checks where a live scenario touches `World`. |
| Reservation table is implemented too early. | Keep Phase 4.19B fixture-only with no runtime reservation table type. |
| Multi-agent movement grows into gameplay movement. | Limit early phases to synthetic intentions, short routes, and at most one edge per agent per tick. |
| Future live scenario becomes too long. | Cap agents and ticks; start with two or three agents and one edge each. |
| Logs become too verbose. | Emit one aggregate event and put per-agent detail in JSON reports. |
| Core entity or save behavior leaks in too early. | Keep placeholder-first live movement and defer core entity multi-agent movement and save/load to separate phases. |

## 17. Documentation To Update

Phase 4.19A creates this plan and updates only:

- `docs/pebblelab/CHANGELOG.md`;
- `docs/pebblelab/DEV_JOURNAL.md`;
- `docs/pebblelab/ROADMAP.md`.

No Swift file, PebbleCore file, renderer/shader/resource file, registry,
save/load path, golden, runner, or scenario is modified by this phase.

## Phase 4.19B Implementation Status

Phase 4.19B added the first fixture-only multi-agent movement arbitration
smoke:

```text
multi_agent_movement_fixture_smoke
```

Validated cases:

- `two_agents_different_destinations_approved`;
- `same_destination_conflict`;
- `occupied_destination_conflict`;
- `swap_conflict`;
- `source_mismatch`;
- `stale_intent_duplicate_source_or_route_index`;
- `missing_agent`;
- `invalid_edge_diagonal_or_vertical`.

Outputs produced:

- `multi_agent_movement_fixture_report.json`;
- `multi_agent_movement_fixture_invariant_report.json`;
- `metrics.json` with `multiAgentMovementFixture*` fields;
- `events.ndjson` with one aggregate
  `lab_multi_agent_movement_fixture_recorded` event.

Validated summary:

- 8 cases;
- 8 passed;
- 0 failed;
- 3 approved movements;
- 8 denied movements;
- 1 same-destination denial;
- 1 occupied static destination denial;
- 2 swap denials;
- 1 source mismatch;
- 1 stale intent;
- 1 missing agent;
- 1 invalid edge;
- 47 invariant checks passed.

Limits:

- fixture-only;
- no `World` creation or use;
- no live collision;
- no live physical movement;
- no route following live;
- no pathfinding;
- no replanning;
- no goal selection;
- no avoidance;
- no reservation table runtime;
- no physics;
- no terrain/world mutation.

Next recommended step: Phase 4.19C, fixture hardening for broader edge cases
and stronger arbitration contracts before any live collision intent smoke.

## Phase 4.19C Implementation Status

Phase 4.19C added fixture-only hardening for multi-agent movement arbitration:

```text
multi_agent_movement_fixture_hardening_smoke
```

Validated hardening cases:

- `unordered_intents_still_resolve_by_agent_id`;
- `duplicate_intents_same_agent_denied`;
- `three_agent_cycle_denied`;
- `chain_dependency_denied`;
- `moving_away_destination_denied`;
- `invalid_vertical_edge`;
- `zero_length_edge_denied`;
- `all_denied_mixed_reasons`;
- `empty_intents_noop_success`;
- `max_agents_bound_exceeded`.

Outputs produced:

- `multi_agent_movement_fixture_hardening_report.json`;
- `multi_agent_movement_fixture_hardening_invariant_report.json`;
- `metrics.json` with `multiAgentMovementFixtureHardening*` fields;
- `events.ndjson` with one aggregate
  `lab_multi_agent_movement_fixture_hardening_recorded` event.

Validated summary:

- 10 cases;
- 10 passed;
- 0 failed;
- 1 approved movement;
- 20 denied movements;
- 2 duplicate-intent denials;
- 3 cycle denials;
- 2 chain-dependency denials;
- 2 moving-away destination denials;
- 2 vertical invalid-edge denials;
- 1 zero-length edge denial;
- 8 all-denied cases;
- 1 empty-intents no-op case;
- 5 max-agent bound denials;
- 43 invariant checks passed.

Limits:

- fixture-only;
- no `World` creation or use;
- no live collision;
- no live physical movement;
- no route following live;
- no pathfinding;
- no replanning;
- no goal selection;
- no avoidance;
- no reservation table runtime;
- no physics;
- no terrain/world mutation.

Next recommended step: Phase 4.19D, live read-only collision intent smoke.
That phase should collect multi-agent candidate intentions against live
collision evidence, but still avoid movement application, reservation runtime,
avoidance, replanning, physics, and mutation.

## Phase 4.19D Implementation Status

Phase 4.19D added the first multi-agent live read-only collision intent smoke:

```text
multi_agent_live_collision_intent_smoke
```

Validated live collision intent cases:

- `occupable_destination_intent_approved_readonly`;
- `two_occupable_destinations_non_conflicting_readonly`;
- `non_occupable_destination_denied_readonly`;
- `same_destination_conflict_after_occupable_collision`;
- `source_mismatch_skips_collision`;
- `invalid_edge_skips_collision`;
- `stale_intent_skips_collision`.

Outputs produced:

- `multi_agent_live_collision_intent_report.json`;
- `multi_agent_live_collision_intent_invariant_report.json`;
- `metrics.json` with `multiAgentLiveCollisionIntent*` fields;
- `events.ndjson` with one aggregate
  `lab_multi_agent_live_collision_intent_recorded` event.

Validated summary:

- 7 cases;
- 7 passed;
- 0 failed;
- 4 approved intent resolutions;
- 5 denied intent resolutions;
- 5 occupable live destinations observed;
- 1 non-occupable live destination observed;
- 1 collision denial;
- 1 same-destination conflict after occupable collision evidence;
- 1 source mismatch;
- 1 invalid edge;
- 1 stale intent;
- 38 invariant checks passed.

Limits:

- live collision is read only as destination evidence;
- approved resolutions do not apply displacement;
- final positions remain equal to initial positions;
- no physical placeholder is created or moved;
- no core entity is created or moved;
- no route following live;
- no single-step physical movement application;
- no pathfinding;
- no replanning;
- no goal selection;
- no avoidance;
- no reservation table runtime;
- no physics;
- no terrain/world mutation.

Next recommended step: Phase 4.19E, multi-agent approved physical movement
smoke. That phase should remain tiny, bounded, and no-replanning while
introducing the first explicit application of approved multi-agent movement.

## Phase 4.19E Implementation Status

Phase 4.19E added the first approved multi-agent physical movement smoke:

```text
multi_agent_approved_physical_movement_smoke
```

Validated approved physical movement cases:

- `two_agents_two_approved_single_step_moves`;
- `deterministic_order_two_approved_moves`.

Outputs produced:

- `multi_agent_approved_physical_movement_report.json`;
- `multi_agent_approved_physical_movement_invariant_report.json`;
- `metrics.json` with `multiAgentApprovedPhysicalMovement*` fields;
- `events.ndjson` with one aggregate
  `lab_multi_agent_approved_physical_movement_recorded` event.

Validated summary:

- 2 cases;
- 2 passed;
- 0 failed;
- 4 approved resolutions across the two cases;
- 0 denied resolutions;
- 4 displacements applied;
- 4 occupable live destinations observed;
- 0 non-occupable live destinations observed;
- divergence before max 0;
- divergence after max 0;
- 42 invariant checks passed.

Limits:

- approved-only smoke;
- two agents per case;
- one edge per agent;
- no same-destination conflict;
- no swap conflict;
- no denied live multi-agent movement;
- no route following live;
- no pathfinding;
- no replanning;
- no goal selection;
- no avoidance;
- no reservation table runtime;
- no physics;
- no terrain/world mutation;
- no gameplay movement.

Next recommended step: Phase 4.19F, multi-agent movement hardening. That
phase should add denied live movement and conflict coverage around the
approved physical movement path without adding avoidance, reservation runtime,
replanning, physics, or gameplay movement.

## Phase 4.19F Implementation Status

Phase 4.19F added live multi-agent movement hardening:

```text
multi_agent_movement_hardening_smoke
```

Validated hardening cases:

- `approved_two_agents_remains_green`;
- `collision_denied_preserves_position`;
- `partial_approval_one_approved_one_collision_denied`;
- `same_destination_live_conflict_denies_loser`;
- `swap_conflict_live_denies_both`;
- `source_mismatch_live_denied_before_collision`;
- `stale_intent_live_denied_before_collision`;
- `invalid_edge_live_denied_before_collision`;
- `divergence_before_movement_denied`;
- `stale_collision_evidence_denied`;
- `all_denied_live_mixed_reasons`;
- `max_agents_live_bound_exceeded`.

Outputs produced:

- `multi_agent_movement_hardening_report.json`;
- `multi_agent_movement_hardening_invariant_report.json`;
- `metrics.json` with `multiAgentMovementHardening*` fields;
- `events.ndjson` with one aggregate
  `lab_multi_agent_movement_hardening_recorded` event.

Validated summary:

- 12 cases;
- 12 passed;
- 0 failed;
- 4 approved resolutions;
- 18 denied resolutions;
- 4 displacements applied;
- 6 occupable live destinations observed;
- 3 non-occupable live destinations observed;
- 3 collision denials;
- 1 same-destination conflict;
- 2 swap-conflict denials;
- 2 source-mismatch denials;
- 1 stale-intent denial;
- 2 invalid-edge denials;
- 1 divergence-before denial;
- 1 stale-collision denial;
- 5 max-agent denials;
- divergence before max 1;
- divergence after max 1, only in the intentionally divergent denied case;
- 55 invariant checks passed.

Limits:

- hardening smoke, not gameplay movement;
- 2 to 5 synthetic agents per case;
- approved moves are exactly one edge;
- denied moves preserve abstract and physical positions;
- no route following live;
- no pathfinding;
- no replanning;
- no goal selection;
- no avoidance;
- no reservation table runtime;
- no physics;
- no terrain/world mutation;
- no save/load or registry changes.

Next recommended step: Phase 4.20A, multi-agent movement integration
planning docs-only. That phase should define how the hardened smoke contract
connects to future integration work before adding reservation runtime,
avoidance, replanning, route repair, physics, or long-running multi-agent
navigation.
