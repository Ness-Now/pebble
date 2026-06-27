# Phase 4 - Agent Intent Production Plan

Phase 4.21A documents how PebbleLab can later move from synthetic movement
intentions created by scenarios toward agent-produced `LabAgentMoveIntent`
values. It is intentionally docs-only: no Swift code, no scenario, no runner,
and no behavior change are introduced here.

The key boundary is simple: agent policy may propose movement intent later,
but movement remains owned by the tick movement contract. An agent policy does
not move the agent, does not read collision, does not arbitrate, does not
pathfind, does not replan, and does not mutate memory or goals in this phase.

## 1. Validated Starting Point

Phase 4.19A through 4.19F validated the lower-level multi-agent movement
building blocks:

- fixture arbitration;
- fixture hardening;
- live read-only collision intent evidence;
- approved physical movement;
- live multi-agent movement hardening.

Those phases established deterministic arbitration, conflict handling,
same-destination denial, swap denial, source mismatch denial, stale intent
denial, invalid edge denial, divergence denial, stale collision denial,
max-agent bounds, approved physical movement, denied position preservation,
and abstract/physical synchronization for approved movement.

Phase 4.20A through 4.20E validated the integrated tick-level shape:

- 4.20A documented tick-level integration;
- 4.20B added fixture-only tick input/output and feedback;
- 4.20C added live read-only collision evidence at tick level;
- 4.20D added approved tick application with `moved` feedback;
- 4.20E hardened the tick contract with 12 cases, 12 passed, 0 failed,
  `approvedTotal = 4`, `deniedTotal = 18`, `displacementsApplied = 4`,
  and `feedbackCountTotal = 22`.

The current tick scenarios still use synthetic intentions. No agent decides
to move yet. No intention is produced by an agent policy. The next problem is
therefore intention production, not movement application.

## 2. Problem To Solve

PebbleLab currently follows this shape:

```text
fixture/scenario creates intents
```

Future phases should move toward this shape:

```text
agent policy proposes movement intent
```

That transition must stay narrow. The agent policy layer must not:

- move the agent;
- read live collision;
- arbitrate between agents;
- run pathfinding;
- repair routes;
- replan dynamically;
- avoid other agents;
- reserve future positions;
- mutate memory;
- mutate goals;
- mutate terrain or world state.

The first intent production contract should only answer whether an observed
agent context can produce zero or one candidate `LabAgentMoveIntent`.

## 3. Target Architecture

### Agent State Observation

The observation layer reads the abstract state needed by the future intent
policy:

- current agent id;
- current abstract position;
- optional role;
- optional future goal or need;
- last structured movement feedback;
- static local hints supplied by a fixture or scenario.

It does not mutate agent state, goals, memory, terrain, world state, physical
placeholders, or core entities.

### Intent Policy Layer

The policy layer decides whether an agent wants to attempt one edge of
movement:

- it may produce no intent;
- it may propose one `LabAgentMoveIntent`;
- it may reject an invalid context;
- it does not decide whether the move is possible;
- it does not read collision;
- it does not inspect other agents as conflict winners or losers;
- it does not choose global winners;
- it does not apply movement.

### Intent Validation Layer

The validation layer verifies the minimal shape of a proposal:

- `agentId` is present;
- `from` is present;
- `to` is present;
- the first v0 movement proposal is one edge;
- the first v0 proposal is same-y;
- the proposal is deterministic and bounded.

It does not read `World`, live collision, terrain mutation state, or physical
movement state.

### Tick Collection Layer

The collection layer gathers accepted intentions for one tick:

- it collects proposals from observed agents;
- it rejects duplicate proposals for one agent in v0;
- it stabilizes order by stable `agentId`;
- it forwards accepted intentions to the Phase 4.20 tick movement contract.

It does not arbitrate conflicts, choose winners, read collision, or apply
movement.

### Movement Tick Layer

The tick movement layer remains the owner of movement decisions:

- it uses the contracts validated in 4.20B through 4.20E;
- it arbitrates same-destination, swap, source mismatch, stale, invalid edge,
  divergence, collision, and max-agent cases according to the scenario;
- it reads live collision only in live read-only or application phases;
- it applies movement only in approved application or hardening phases;
- it produces resolutions and feedback.

### Feedback Consumption Future

Future feedback consumption receives `LabMovementFeedback` values:

- it can observe whether a move was applied or blocked;
- it can later help a policy wait, retry, or choose a different direction;
- it must not update memory, goals, or routes in the first production smoke.

Feedback is structured output for future phases, not learning, memory, social
communication, or replanning in 4.21A.

## 4. Future Types Proposed

These types are proposed only as documentation. They are not implemented in
4.21A.

```swift
struct LabAgentIntentContext: Codable {
    let tick: Int
    let agentId: String
    let position: LabTerrainPathNodeKey
    let lastFeedback: LabMovementFeedback?
    let role: String?
    let localHints: [String]
}

enum LabAgentIntentDecision: String, Codable {
    case noIntent
    case proposeMove
    case invalidContext
}

struct LabAgentIntentProposal: Codable {
    let agentId: String
    let tick: Int
    let decision: LabAgentIntentDecision
    let intent: LabAgentMoveIntent?
    let reason: String
}

struct LabAgentIntentProductionResult: Codable {
    let tick: Int
    let proposals: [LabAgentIntentProposal]
    let acceptedIntents: [LabAgentMoveIntent]
    let rejectedProposals: [LabAgentIntentProposal]
    let summary: LabAgentIntentProductionSummary
}

struct LabAgentIntentProductionSummary: Codable {
    let agentsObserved: Int
    let proposals: Int
    let acceptedIntents: Int
    let rejectedProposals: Int
    let noIntent: Int
    let invalidContext: Int
    let success: Bool
}
```

## 5. Proposed v0 Policy

The first policy should be deliberately small:

- deterministic;
- no randomness unless an explicit seed is part of the scenario contract;
- no pathfinding;
- no route planning;
- no route repair;
- no dynamic replanning;
- no avoidance;
- no reservation runtime;
- no goal selection;
- no memory update;
- no collision reads;
- no movement application;
- at most one edge;
- same-y only;
- deterministic candidate direction order;
- may use static local hints supplied by fixtures;
- may output `noIntent`;
- may output `proposeMove`;
- may output `invalidContext`;
- does not know whether the destination is occupable;
- does not check other agents;
- does not choose winners.

Example v0 behavior:

- role `wander_fixture` proposes east if a fixture hint allows east;
- role `idle` proposes `noIntent`;
- missing or invalid position produces `invalidContext`;
- the proposal source is always the observed position;
- the proposal destination is exactly one same-y edge away.

## 6. Relationship With Feedback

Feedback can later inform policies, but it is not consumed in 4.21A.

Future interpretation examples:

- `moved` may later reinforce that a direction succeeded;
- `blockedByCollision` may later discourage trying the same blocked
  direction immediately;
- `blockedByAgentConflict` may later encourage waiting;
- `blockedBySourceMismatch` indicates stale internal position state;
- `blockedByDivergence` indicates abstract/physical synchronization trouble;
- `blockedByStaleIntent` indicates an outdated proposal;
- `blockedByInvalidEdge` indicates a policy bug or invalid local hint;
- `blockedByMaxAgents` indicates the tick-level capacity bound blocked the
  agent.

Current limits:

- no memory update;
- no learning;
- no route repair;
- no replanning;
- no LLM/Python/RL;
- no goal change;
- no social communication;
- feedback is structured input for future policy phases only.

## 7. Future Scenario Sequence

### Phase 4.21B - Agent Intent Production Fixture Smoke

- no `World`;
- no live collision;
- no movement;
- a few synthetic agents;
- contexts include positions, roles, hints, and optional previous feedback;
- policy produces intent, `noIntent`, and `invalidContext`;
- writes an intent production report.

### Phase 4.21C - Agent Intent Production Hardening

- duplicate agent context;
- missing position;
- invalid context;
- `noIntent`;
- deterministic order;
- max proposals;
- invalid one-edge proposal rejected;
- no pathfinding, replanning, movement, or mutation.

### Phase 4.21D - Agent Intent To Tick Fixture Integration Smoke

- produced intentions feed the `multi_agent_movement_tick_fixture` contract;
- no `World`;
- no live collision;
- no movement;
- verifies that accepted produced intents become tick input.

### Phase 4.21E - Agent Intent To Tick Live Read-Only Smoke

- produced intentions feed the tick live read-only contract;
- `World` is used only for collision evidence;
- no movement;
- no terrain/world mutation.

### Phase 4.21F - Agent Intent To Tick Approved Application Smoke

- produced intentions feed the tick approved application contract;
- two agents move one edge;
- `moved` feedback is produced;
- no repeated tick loop, pathfinding, replanning, avoidance, or reservation
  runtime.

### Phase 4.22A - Feedback Consumption Planning Docs-Only

- document how feedback may later update agent policy or memory;
- still no autonomous learning;
- still no LLM/RL;
- still no gameplay movement loop.

## 8. Future Outputs

Future agent intent production scenarios should write:

- `agent_intent_production_report.json`;
- `agent_intent_production_invariant_report.json`;
- `agent_intent_proposals.json`;
- `metrics.json`;
- `events.ndjson`.

Recommended report fields:

- `scenario`;
- `seed`;
- `tick`;
- `contexts`;
- `proposals`;
- `acceptedIntents`;
- `rejectedProposals`;
- `summary`;
- `outOfScopeFlags`.

## 9. Future Metrics

Recommended future metrics:

- `agentIntentProductionAgentsObserved`;
- `agentIntentProductionContexts`;
- `agentIntentProductionProposals`;
- `agentIntentProductionAcceptedIntents`;
- `agentIntentProductionRejectedProposals`;
- `agentIntentProductionNoIntent`;
- `agentIntentProductionInvalidContext`;
- `agentIntentProductionDeterministicOrdering`;
- `agentIntentProductionPathfindingPerformed`;
- `agentIntentProductionReplanningPerformed`;
- `agentIntentProductionAvoidancePerformed`;
- `agentIntentProductionReservationRuntimeUsed`;
- `agentIntentProductionMovementApplied`;
- `agentIntentProductionMutationPerformed`;
- `agentIntentProductionSuccess`.

## 10. Future Event

Recommended aggregate event:

`lab_agent_intent_production_recorded`

Recommended fields:

- `tick`;
- `agentsObserved`;
- `proposals`;
- `acceptedIntents`;
- `rejectedProposals`;
- `noIntent`;
- `invalidContext`;
- `success`.

Do not emit one event per agent at the beginning. Detailed per-agent
proposals belong in `agent_intent_proposals.json` and the report.

## 11. Future Invariants

Future invariant reports should include at least these checks:

1. `contexts_exist`
2. `proposals_exist`
3. `contexts_sorted_by_agent_id`
4. `proposals_sorted_by_agent_id`
5. `at_most_one_context_per_agent`
6. `at_most_one_proposal_per_agent`
7. `accepted_intents_sorted_by_agent_id`
8. `accepted_intents_have_agent_id`
9. `accepted_intents_have_source`
10. `accepted_intents_have_destination`
11. `accepted_intents_source_matches_context_position`
12. `accepted_intents_are_one_edge_same_y_for_v0`
13. `no_diagonal_intent_accepted`
14. `no_vertical_intent_accepted`
15. `no_zero_length_intent_accepted`
16. `invalid_contexts_rejected`
17. `missing_positions_rejected`
18. `no_intent_counted`
19. `propose_move_counted`
20. `rejected_proposals_counted`
21. `accepted_intent_count_matches_summary`
22. `rejected_proposal_count_matches_summary`
23. `deterministic_ordering_stable`
24. `no_pathfinding`
25. `no_replanning`
26. `no_avoidance`
27. `no_reservation_runtime`
28. `no_collision_read`
29. `no_movement_applied`
30. `no_world_used`
31. `no_terrain_mutation`
32. `no_world_mutation`
33. `no_memory_updated`
34. `no_goal_changed`
35. `no_llm_python_rl`
36. `no_communication`
37. `no_social_behavior`
38. `no_inventory_mining_construction`
39. `feedback_not_consumed_yet`
40. `report_written`
41. `proposals_written`
42. `metrics_written`
43. `event_written`
44. `tick_fixture_smoke_remains_green`
45. `tick_hardening_smoke_remains_green`
46. `success_contract_respected`

## 12. Explicitly Out Of Scope

The following are out of scope for Phase 4.21A:

- implementation in 4.21A;
- any Swift change;
- scenario creation;
- runner creation;
- autonomous movement;
- repeated tick loop;
- pathfinding;
- route planning;
- route repair;
- dynamic replanning;
- avoidance;
- reservation runtime;
- goal selection;
- memory update;
- feedback consumption;
- social behavior;
- communication;
- LLM/Python/RL;
- inventory;
- mining;
- construction;
- combat;
- animation;
- renderer changes;
- save/load;
- registries;
- terrain/world mutation.

## 13. Risks And Mitigations

| Risk | Mitigation |
| --- | --- |
| Policy starts moving agents directly. | Keep movement exclusively in the tick movement layer. |
| Policy starts reading collision. | Require collision evidence to remain in live tick layers only. |
| Policy starts pathfinding. | Limit v0 to fixture hints and one-edge proposals. |
| Policy owns arbitration. | Keep conflict resolution in the arbitration/tick movement contract. |
| Feedback consumption is introduced too early. | Treat feedback as read-only input and report data until a later planning phase. |
| Agent memory mutation leaks in. | Include explicit no-memory-update invariants. |
| Goal selection sneaks in. | Keep role/hints fixture-scoped and do not select goals. |
| Scenario runner becomes monolithic. | Separate observation, policy, validation, collection, movement tick, feedback, and reporting. |
| Accepted intents are not deterministic. | Sort contexts, proposals, and accepted intents by stable `agentId`. |
| Invalid contexts produce unsafe intents. | Reject invalid contexts before accepted intent collection. |
| Policy emits multiple intents per agent. | Deny duplicates in validation and invariant reports. |
| Source mismatch due to stale context. | Require accepted intent source to match observed context position. |
| Future feedback loop oscillates. | Defer feedback consumption and document policy separately. |
| Future repeated tick loop accumulates divergence. | Keep 4.21B single-tick/no-movement and defer loops to later contracts. |

## 14. Documentation Updates

Phase 4.21A updates only:

- `docs/pebblelab/CHANGELOG.md`;
- `docs/pebblelab/DEV_JOURNAL.md`;
- `docs/pebblelab/ROADMAP.md`;
- `docs/pebblelab/PHASE_4_AGENT_INTENT_PRODUCTION_PLAN.md`.

No Swift files, `PebbleCore`, renderer, shaders, resources, registries,
save/load files, or goldens are modified.

## Phase 4.21B Implementation Status

Phase 4.21B implements the first fixture-only agent intent production smoke:
`agent_intent_production_fixture_smoke`.

Validated contexts:

- `agent_2`: `idle`, position `(10,64,0)`, produces `noIntent`;
- `agent_0`: `wander_fixture`, position `(0,64,0)`, hint `move_east`,
  produces accepted intent `(0,64,0) -> (1,64,0)`;
- `agent_1`: `wander_fixture`, position `(2,64,0)`, hint `move_west`,
  produces accepted intent `(2,64,0) -> (1,64,0)`;
- `agent_3`: missing position, produces `invalidContext`;
- `agent_4`: `bad_fixture_invalid_vertical`, position `(20,64,0)`,
  produces a vertical proposal rejected by validation.

Validated proposal policy:

- contexts are intentionally unordered;
- proposals are sorted by stable `agentId`;
- accepted intents are sorted by stable `agentId`;
- valid `proposeMove` proposals become accepted intents;
- `noIntent`, `invalidContext`, and invalid vertical proposals are rejected;
- accepted intents are one-edge same-y;
- accepted same-destination intents are allowed because production does not
  arbitrate conflicts.

Outputs produced:

- `agent_intent_production_fixture_report.json`;
- `agent_intent_production_fixture_invariant_report.json`;
- `agent_intent_proposals.json`;
- `metrics.json`;
- `events.ndjson`.

Validated limits:

- no `World`;
- no collision read;
- no movement application;
- no tick movement invocation;
- no feedback consumption;
- no memory update;
- no goal change;
- no pathfinding;
- no replanning;
- no avoidance;
- no reservation runtime;
- no physics;
- no terrain/world mutation.

Next recommended step: Phase 4.21C - Agent Intent Production Hardening. It
should cover duplicate contexts, duplicate proposals, malformed moves,
missing data, unknown roles, deterministic ordering, max proposal bounds, and
invalid proposal rejection without adding tick integration, live collision,
movement application, feedback consumption, memory updates, goal selection,
pathfinding, replanning, avoidance, reservation runtime, physics, or
terrain/world mutation.

## Phase 4.21C Implementation Status

Phase 4.21C implements the fixture-only hardening smoke:
`agent_intent_production_hardening_smoke`.

Validated hardening cases:

- `baseline_fixture_remains_green`;
- `duplicate_agent_context_denied`;
- `duplicate_proposal_denied`;
- `invalid_diagonal_proposal_rejected`;
- `zero_length_proposal_rejected`;
- `stale_proposal_rejected`;
- `wrong_source_proposal_rejected`;
- `max_proposals_bound_exceeded`;
- `deterministic_hint_ordering`;
- `unknown_role_no_intent`.

Accepted/rejected policy:

- proposals are sorted by stable `agentId`;
- accepted intents are sorted by stable `agentId`;
- only valid `proposeMove` proposals with matching source, one-edge
  Manhattan distance, and same-y destinations are accepted;
- `noIntent`, missing-position `invalidContext`, invalid diagonal,
  zero-length, stale, wrong-source, duplicate, and max-bound proposals are
  rejected;
- same-destination accepted intents remain allowed because production does
  not arbitrate conflicts.

Duplicate, max, stale, and wrong-source policy:

- duplicate contexts are counted and only one accepted intent per agent is
  allowed;
- duplicate proposals are rejected deterministically;
- stale proposals are rejected before acceptance;
- wrong-source proposals are rejected when intent source differs from the
  stable context position;
- max proposal bounds reject deterministic excess proposals after stable
  ordering.

Outputs produced:

- `agent_intent_production_hardening_report.json`;
- `agent_intent_production_hardening_invariant_report.json`;
- `agent_intent_proposals.json`;
- `metrics.json`;
- `events.ndjson`.

Validated limits:

- no tick movement contract call;
- no `World`;
- no collision read;
- no movement application;
- no feedback consumption;
- no memory update;
- no goal change;
- no pathfinding;
- no replanning;
- no avoidance;
- no reservation runtime;
- no physics;
- no terrain/world mutation.

Next recommended step: Phase 4.21D - Agent Intent To Tick Fixture
Integration Smoke. It should feed accepted produced intents into the
fixture-only tick movement contract while keeping live collision, physical
movement application, feedback consumption, memory updates, goal selection,
pathfinding, replanning, avoidance, reservation runtime, physics, and
terrain/world mutation out of scope.

## Phase 4.21D Implementation Status

Phase 4.21D implements the first fixture-only production-to-tick handoff:
`agent_intent_to_tick_fixture_smoke`.

Production-to-tick handoff validated:

- four intentionally unordered `LabAgentIntentContext` values are created;
- the v0 policy produces four proposals sorted by stable `agentId`;
- two valid `wander_fixture` proposals become accepted intents;
- one `idle` context produces `noIntent`;
- one invalid vertical proposal is rejected;
- accepted intents are sorted by stable `agentId`;
- accepted intents are one-edge same-y;
- accepted intents are copied into a `LabMultiAgentMovementTickInput`;
- synthetic physical positions mirror abstract positions;
- no `World` is created.

Same-destination policy:

- production accepts both `agent_0` and `agent_1` intents to `(1,64,0)`;
- production does not arbitrate the conflict;
- the tick fixture layer resolves the conflict deterministically;
- `agent_0` is approved by stable `agentId` ordering;
- `agent_1` is denied with `deniedSameDestinationConflict`;
- feedback is `approvedForMovement` for `agent_0` and
  `blockedByAgentConflict` for `agent_1`.

Outputs produced:

- `agent_intent_to_tick_fixture_report.json`;
- `agent_intent_to_tick_fixture_invariant_report.json`;
- `agent_intent_to_tick_fixture_proposals.json`;
- `metrics.json`;
- `events.ndjson`.

Validated limits:

- no live collision;
- no movement application;
- no physical placeholder or core entity movement;
- no feedback consumption;
- no memory update;
- no goal change;
- no pathfinding;
- no replanning;
- no avoidance;
- no reservation runtime;
- no physics;
- no terrain/world mutation;
- no multi-tick loop.

Next recommended step: Phase 4.21E - Agent Intent To Tick Live Read-Only
Smoke. It should feed produced intents into the tick live read-only contract
with `World` used only for collision evidence, while keeping movement
application, feedback consumption, memory updates, goal selection,
pathfinding, replanning, avoidance, reservation runtime, physics, and
terrain/world mutation out of scope.

## Phase 4.21E Implementation Status

Phase 4.21E implements the first production-to-live-readonly-tick handoff:
`agent_intent_to_tick_live_readonly_smoke`.

Validated production-to-live-readonly-tick handoff:

- five intentionally unordered `LabAgentIntentContext` values are created;
- the v0 policy produces five proposals sorted by stable `agentId`;
- three valid `wander_fixture` proposals become accepted intents;
- one idle context produces `noIntent`;
- one invalid vertical proposal is rejected;
- accepted intents are sorted by stable `agentId`;
- accepted intents are one-edge same-y;
- accepted intents are copied into a `LabMultiAgentMovementTickInput`;
- synthetic physical positions mirror abstract positions;
- the tick live read-only layer reads collision evidence.

Production responsibility:

- production does not read collision;
- production does not decide occupability;
- production does not apply movement;
- production does not consume feedback;
- production does not modify memory or goals.

Tick responsibility:

- tick live read-only uses controlled collision evidence seeds;
- `agent_0` and `agent_1` use seed 99 and are approved by occupable
  destinations;
- `agent_2` uses seed 42 and is denied by non-occupable collision evidence;
- approved feedback is `approvedForMovement`;
- collision-denied feedback is `blockedByCollision`;
- positions remain unchanged;
- `displacementsApplied` remains zero.

Outputs produced:

- `agent_intent_to_tick_live_readonly_report.json`;
- `agent_intent_to_tick_live_readonly_invariant_report.json`;
- `agent_intent_to_tick_live_readonly_proposals.json`;
- `metrics.json`;
- `events.ndjson`.

Validated limits:

- no movement application;
- no physical placeholder or core entity movement;
- no feedback consumption;
- no memory update;
- no goal change;
- no pathfinding;
- no replanning;
- no avoidance;
- no reservation runtime;
- no physics;
- no terrain/world mutation;
- no multi-tick loop.

Next recommended step: Phase 4.21F - Agent Intent To Tick Approved
Application Smoke. It should feed produced intents into the tick approved
application contract and apply only controlled approved movements while
keeping denied hardening, feedback consumption, memory updates, goal
selection, pathfinding, replanning, avoidance, reservation runtime, physics,
and terrain/world mutation out of scope.

## Phase 4.21F Implementation Status

Phase 4.21F implements the first production-to-approved-application handoff:
`agent_intent_to_tick_approved_application_smoke`.

Validated production-to-approved-application handoff:

- five intentionally unordered `LabAgentIntentContext` values are created;
- the v0 policy produces five proposals sorted by stable `agentId`;
- three valid `wander_fixture` proposals become accepted intents;
- one idle context produces `noIntent`;
- one invalid vertical proposal is rejected;
- accepted intents are sorted by stable `agentId`;
- accepted intents are one-edge same-y;
- accepted intents are copied into a `LabMultiAgentMovementTickInput`;
- synthetic physical positions mirror abstract positions before movement;
- the tick approved application layer reads collision evidence;
- approved moves are applied;
- denied collision moves are preserved.

Production responsibility:

- production does not read collision;
- production does not decide occupability;
- production does not apply movement;
- production does not consume feedback;
- production does not modify memory or goals.

Tick responsibility:

- tick approved application uses controlled collision evidence seeds;
- `agent_0` and `agent_1` use seed 99 and move to occupable destinations;
- `agent_2` uses seed 42 and is denied by non-occupable collision evidence;
- approved feedback is `moved`;
- collision-denied feedback is `blockedByCollision`;
- abstract and physical positions stay synchronized before and after;
- divergence before and after remains zero.

Outputs produced:

- `agent_intent_to_tick_approved_application_report.json`;
- `agent_intent_to_tick_approved_application_invariant_report.json`;
- `agent_intent_to_tick_approved_application_proposals.json`;
- `metrics.json`;
- `events.ndjson`.

Validated limits:

- no feedback consumption;
- no memory update;
- no goal change;
- no route following;
- no pathfinding;
- no replanning;
- no avoidance;
- no reservation runtime;
- no physics;
- no terrain/world mutation;
- no multi-tick autonomous loop.

Next recommended step: Phase 4.22A - Feedback Consumption Planning
Docs-Only. It should document how `LabMovementFeedback` may later influence
agent policy or memory, without implementing feedback consumption, memory
updates, goal changes, replanning, pathfinding, avoidance, reservation
runtime, route following, physics, or gameplay movement.
