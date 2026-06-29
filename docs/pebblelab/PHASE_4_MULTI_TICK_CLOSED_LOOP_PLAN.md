# Phase 4 - Multi-Tick Closed Loop Plan

## Validated Starting Point

Phase 4.19 validated the multi-agent movement primitives: fixture
arbitration, live read-only collision evidence, approved physical movement,
and live movement hardening. These phases established that movement decisions
can be separated from collision evidence and application.

Phase 4.20 validated the tick-level movement contract. The lab now has tick
fixture input/output, tick live read-only evidence, approved tick application,
and structured feedback. The responsibilities are split across arbitration,
collision read, movement application, and feedback emission.

Phase 4.21 validated agent intent production. Fixture production, hardening,
intent-to-tick fixture handoff, intent-to-tick live read-only handoff, and
intent-to-tick approved application prove that agent-produced movement intents
can feed tick contracts without route following, pathfinding, replanning,
avoidance, reservation runtime, or terrain/world mutation.

Phase 4.22 validated feedback consumption and injection. Structured feedback
can be consumed into bounded feedback contexts, then injected into
`LabAgentIntentContext.lastFeedback` without changing behavior.

Phase 4.23 validated the opt-in feedback-aware v1 policy and its handoff to
tick layers. `produceAgentIntentProposalFeedbackAwareV1` keeps baseline
behavior for no feedback, `moved`, and `approvedForMovement`, converts
`blockedBy*` feedback to `noIntent`, feeds tick fixture and live read-only
contracts, and applies approved lab position map movement in the approved
application smoke. v0 remains unchanged. The policy does not read
collision/World. The tick layer reads collision read-only. Denied and
`noIntent` agents are preserved, and terrain/world mutation remains forbidden.

Current state: the single-tick components are validated, but there is no
autonomous multi-tick closed loop yet. Feedback is produced, consumed, injected
into policy context, and used by v1 in isolated scenarios, but the lab does not
yet iterate that chain over multiple ticks.

## Problem To Solve

Today each scenario is single-tick or fixture-controlled. Feedback can be
produced by tick movement, and feedback can be consumed by the agent side, but
there is no bounded orchestrator that carries feedback from tick `N` into
agent policy context at tick `N+1`.

The next problem is to orchestrate:

`feedback-aware intent -> tick -> approved application -> feedback`

into:

`feedback from tick N -> consumed at tick N+1 -> injected into context -> feedback-aware policy proposes next intent -> tick -> approved application -> feedback`

This must not become full gameplay autonomy. The first loop must be
deterministic, small, inspectable, bounded by explicit tick count, and still
memoryless except for carrying the previous tick feedback as input.

## Closed Loop Boundary

Allowed:

- iterate over a fixed small tick count;
- consume previous tick feedback;
- inject `lastFeedback` into agent intent contexts;
- call the opt-in feedback-aware policy v1;
- filter `noIntent` proposals before tick input;
- call tick fixture, tick live read-only, or tick approved application
  depending on the future phase;
- apply approved lab position map movement only in approved application
  phases;
- emit structured feedback for the next tick;
- write per-tick and aggregate reports;
- write metrics and aggregate events;
- maintain deterministic tick, agent, feedback, proposal, and resolution
  ordering.

Forbidden:

- pathfinding;
- dynamic replanning;
- avoidance;
- reservation runtime;
- long route following;
- gameplay movement autonomy;
- memory mutation;
- goal mutation;
- learning or reward update;
- RL, Python, or LLM calls;
- social behavior;
- communication;
- terrain mutation;
- World mutation;
- mining, construction, or inventory behavior;
- physics, gravity, velocity, jump, fall, swim, or climb integration;
- renderer, resource, or shader changes;
- replacing v0 globally.

## Proposed Loop Contract

Text contract for future implementation:

1. Initialize agents and lab position maps.
2. Initialize the feedback store as empty at tick `0`.
3. For each tick in a fixed bounded range:
   - read previous feedback by stable `agentId`;
   - consume feedback using Phase 4.22 semantics;
   - build `LabAgentIntentContext` values;
   - inject consumed feedback as `lastFeedback`;
   - call `produceAgentIntentProposalFeedbackAwareV1`;
   - collect proposals in stable `agentId` order;
   - filter `noIntent` proposals before tick input;
   - send movement intents to the selected tick layer;
   - let tick arbitration handle conflicts;
   - let tick live read-only read collision only in live read-only modes;
   - in approved application modes, update only approved lab position maps;
   - emit structured feedback;
   - store emitted feedback for tick `N+1`;
   - append a per-tick report.
4. End after the fixed tick count.
5. Write aggregate report, invariant report, tick details, feedback details,
   metrics, and one aggregate event.

No feedback emitted during tick `N` may be consumed during that same tick. The
only allowed feedback input to tick `N` is feedback emitted by earlier ticks
and selected deterministically for that agent.

## Future Scenario Sequence

### Phase 4.24B - Multi-Tick Closed Loop Fixture Smoke

- fixture-only;
- no live collision;
- no World;
- prefer no movement application in the first smoke unless the existing
  fixture-approved contract requires safe lab map application;
- fixed 2 or 3 ticks;
- feedback from tick `0` affects tick `1`;
- blocked feedback becomes `noIntent` on the next tick;
- reports prove no same-tick feedback consumption and no cross-agent feedback
  leak.

### Phase 4.24C - Multi-Tick Closed Loop Hardening

- missing feedback;
- duplicate feedback;
- stale tick feedback;
- malformed feedback;
- deterministic ordering;
- repeatability;
- max tick bound;
- no feedback leak across agents;
- bounded memoryless behavior.

### Phase 4.24D - Multi-Tick Closed Loop Live Read-Only Smoke

- tick reads collision read-only;
- policy does not read collision or World;
- no movement application;
- feedback carries collision result to the next tick.

### Phase 4.24E - Multi-Tick Closed Loop Approved Application Smoke

- approved lab position map movements across multiple ticks;
- denied and `noIntent` agents preserved;
- feedback affects the next tick;
- no terrain/world mutation.

### Phase 4.25A - Deterministic Bounded Alternate Local Hint Planning Docs-Only

- only after the multi-tick loop is stable;
- plan deterministic local alternate hints;
- still no pathfinding, replanning, avoidance, or reservation runtime.

## Proposed Reports

Future outputs:

- `multi_tick_closed_loop_report.json`;
- `multi_tick_closed_loop_invariant_report.json`;
- `multi_tick_closed_loop_ticks.json`;
- `multi_tick_closed_loop_feedback.json`;
- `metrics.json`;
- `events.ndjson`.

## Proposed Metrics

Future metrics use the prefix `multiTickClosedLoop*`:

- `multiTickClosedLoopTicks`;
- `multiTickClosedLoopAgents`;
- `multiTickClosedLoopContextsTotal`;
- `multiTickClosedLoopFeedbackConsumedTotal`;
- `multiTickClosedLoopFeedbackCarriedToNextTickTotal`;
- `multiTickClosedLoopContextsWithFeedbackTotal`;
- `multiTickClosedLoopContextsWithoutFeedbackTotal`;
- `multiTickClosedLoopProposalsTotal`;
- `multiTickClosedLoopAcceptedIntentsTotal`;
- `multiTickClosedLoopNoIntentTotal`;
- `multiTickClosedLoopNoIntentFromBlockedFeedbackTotal`;
- `multiTickClosedLoopMovementIntentInputsTotal`;
- `multiTickClosedLoopTickApprovedTotal`;
- `multiTickClosedLoopTickDeniedTotal`;
- `multiTickClosedLoopTickDeniedConflictTotal`;
- `multiTickClosedLoopTickDeniedCollisionTotal`;
- `multiTickClosedLoopFeedbackEmittedTotal`;
- `multiTickClosedLoopApprovedApplicationsTotal`;
- `multiTickClosedLoopDeniedPreservedTotal`;
- `multiTickClosedLoopNoIntentPreservedTotal`;
- `multiTickClosedLoopPolicyReadCollision`;
- `multiTickClosedLoopTickReadCollision`;
- `multiTickClosedLoopPolicyWorldUsed`;
- `multiTickClosedLoopTickWorldReadOnlyUsed`;
- `multiTickClosedLoopMovementApplied`;
- `multiTickClosedLoopMemoryUpdated`;
- `multiTickClosedLoopGoalChanged`;
- `multiTickClosedLoopPathfindingPerformed`;
- `multiTickClosedLoopReplanningPerformed`;
- `multiTickClosedLoopAvoidancePerformed`;
- `multiTickClosedLoopReservationRuntimeUsed`;
- `multiTickClosedLoopRouteFollowingUsed`;
- `multiTickClosedLoopWorldMutated`;
- `multiTickClosedLoopMutationPerformed`;
- `multiTickClosedLoopSuccess`.

## Proposed Event

Future event: `lab_multi_tick_closed_loop_recorded`.

Fields:

- `ticks`;
- `agents`;
- `contextsTotal`;
- `feedbackConsumedTotal`;
- `feedbackCarriedToNextTickTotal`;
- `proposalsTotal`;
- `acceptedIntentsTotal`;
- `noIntentTotal`;
- `movementIntentInputsTotal`;
- `tickApprovedTotal`;
- `tickDeniedTotal`;
- `tickDeniedConflictTotal`;
- `tickDeniedCollisionTotal`;
- `feedbackEmittedTotal`;
- `approvedApplicationsTotal`;
- `deniedPreservedTotal`;
- `noIntentPreservedTotal`;
- `policyReadCollision`;
- `tickReadCollision`;
- `policyWorldUsed`;
- `tickWorldReadOnlyUsed`;
- `movementApplied`;
- `memoryUpdated`;
- `goalChanged`;
- `pathfindingPerformed`;
- `replanningPerformed`;
- `avoidancePerformed`;
- `reservationRuntimeUsed`;
- `routeFollowingUsed`;
- `worldMutated`;
- `mutationPerformed`;
- `success`.

## Future Invariants

Future invariant reports should include at least:

1. `fixed_tick_count`;
2. `tick_count_nonzero_and_bounded`;
3. `no_unbounded_loop`;
4. `deterministic_tick_order`;
5. `deterministic_agent_order`;
6. `deterministic_feedback_order`;
7. `deterministic_context_order`;
8. `deterministic_proposal_order`;
9. `deterministic_tick_input_order`;
10. `deterministic_resolution_order`;
11. `feedback_from_tick_n_consumed_only_at_tick_n_plus_one`;
12. `feedback_not_consumed_in_same_tick`;
13. `no_future_feedback_leak`;
14. `no_cross_agent_feedback_leak`;
15. `feedback_store_initialized_empty`;
16. `missing_feedback_allowed`;
17. `duplicate_feedback_handled_deterministically`;
18. `stale_feedback_rejected_or_ignored`;
19. `malformed_feedback_ignored`;
20. `unknown_feedback_rejected_or_ignored`;
21. `at_most_one_consumed_feedback_per_agent_per_tick`;
22. `feedback_contexts_produced_for_accepted_feedback`;
23. `feedback_context_agent_ids_match_agents`;
24. `last_feedback_injected_into_matching_agent_context`;
25. `policy_v1_opt_in`;
26. `v0_remains_available`;
27. `no_feedback_keeps_baseline`;
28. `moved_keeps_baseline`;
29. `approved_for_movement_keeps_baseline`;
30. `blocked_collision_feedback_becomes_no_intent`;
31. `blocked_agent_conflict_feedback_becomes_no_intent`;
32. `blocked_source_mismatch_feedback_becomes_no_intent`;
33. `blocked_divergence_feedback_becomes_no_intent`;
34. `blocked_stale_intent_feedback_becomes_no_intent`;
35. `blocked_invalid_edge_feedback_becomes_no_intent`;
36. `blocked_max_agents_feedback_becomes_no_intent`;
37. `feedback_behavior_changes_counted`;
38. `no_intent_filtered_before_tick`;
39. `tick_receives_only_accepted_movement_intents`;
40. `tick_input_agents_cover_intent_sources`;
41. `fixture_tick_does_not_read_collision`;
42. `live_readonly_tick_reads_collision_only_at_tick_layer`;
43. `policy_does_not_read_collision`;
44. `policy_does_not_use_world`;
45. `tick_world_readonly_used_only_when_expected`;
46. `tick_arbitrates_conflicts`;
47. `policy_does_not_arbitrate_conflicts`;
48. `approved_application_moves_only_approved_lab_positions`;
49. `denied_agents_preserved`;
50. `no_intent_agents_preserved`;
51. `feedback_emitted_for_tick_resolutions`;
52. `feedback_carried_to_next_tick`;
53. `feedback_totals_match_per_tick_reports`;
54. `contexts_total_matches_per_tick_reports`;
55. `proposals_total_matches_per_tick_reports`;
56. `movement_intent_inputs_total_matches_per_tick_reports`;
57. `approved_total_matches_per_tick_reports`;
58. `denied_total_matches_per_tick_reports`;
59. `conflict_denied_total_matches_per_tick_reports`;
60. `collision_denied_total_matches_per_tick_reports`;
61. `abstract_physical_divergence_bounded`;
62. `abstract_physical_divergence_reported_per_tick`;
63. `no_world_mutation`;
64. `no_terrain_mutation`;
65. `no_memory_mutation`;
66. `no_goal_mutation`;
67. `pathfinding_not_performed`;
68. `replanning_not_performed`;
69. `avoidance_not_performed`;
70. `reservation_runtime_not_used`;
71. `route_following_not_used`;
72. `learning_not_performed`;
73. `llm_rl_python_not_used`;
74. `social_behavior_not_used`;
75. `communication_not_used`;
76. `physics_not_performed`;
77. `inventory_mining_construction_not_performed`;
78. `report_written`;
79. `ticks_json_written`;
80. `feedback_json_written`;
81. `metrics_written`;
82. `event_written`;
83. `repeatability_same_input_same_output`;
84. `prior_feedback_aware_approved_application_smoke_remains_green`;
85. `success_contract_respected`.

## Risk Table

| Risk | Why it matters | Mitigation |
| --- | --- | --- |
| Unbounded loop accidentally introduced | A smoke could become an autonomous runtime loop. | Require fixed tick count and invariant `no_unbounded_loop`. |
| Feedback leaks across agents | One agent could react to another agent's private tick outcome. | Store feedback by stable `agentId` and assert matching context ids. |
| Feedback from current tick consumed in same tick | This creates causality bugs and nondeterminism. | Only read the previous tick feedback store. |
| v1 replaces v0 globally | Existing fixture contracts could silently change. | Keep v1 opt-in and run v0 non-regressions. |
| Policy starts reading collision | The responsibility boundary would collapse. | Assert `policyReadCollision = false` in every loop mode. |
| Policy starts using World | Agent policy would become live-environment coupled too early. | Assert `policyWorldUsed = false`. |
| Blocked feedback becomes pathfinding | A tiny feedback reaction could become a planner. | Keep v1 blocked feedback reaction as `noIntent`. |
| Approved application becomes gameplay movement | Lab map movement could leak into real entities or route following. | Apply only lab position maps and assert route following/core movement are unused. |
| Route following sneaks in | The loop could become long-route autonomy. | Explicit route-following metrics and invariant false. |
| Terrain/world mutation sneaks in | Read-only/live evidence phases must preserve world state. | Assert terrain/world mutation false and avoid block APIs. |
| Memory/goals mutate | Feedback context could become hidden state. | Keep 4.24 memoryless and assert false. |
| Nondeterministic ordering | Reports become flaky and policy outcomes drift. | Sort by tick and stable `agentId`. |
| Metrics hide per-tick failures | Aggregate success could mask a broken tick. | Write per-tick JSON and aggregate totals. |
| Repeated collision causes permanent freeze | `noIntent` reaction can suppress motion forever. | Document this as acceptable for first smoke and plan alternatives later. |
| noIntent suppresses all movement forever | First v1 behavior is intentionally conservative but limited. | Limit to blocked feedback and inspect per-agent counters. |
| Future alternate hints become replanning | Local hints can drift into route search. | Defer alternate hints to 4.25A planning docs-only. |
| Live read-only helper mutates accidentally | Collision evidence must remain read-only. | Reuse existing read-only helpers and assert mutation false. |

## Recommended 4.24B Contract

Phase 4.24B - Multi-Tick Closed Loop Fixture Smoke.

Recommended first smoke:

- fixed 3 ticks;
- 4 agents;
- fixture-only;
- no live collision;
- no World;
- no movement application, unless a safe fixture-approved map-only helper is
  explicitly required later;
- tick `0`: `agent_0` and `agent_1` produce movement intents that conflict,
  and tick emits feedback;
- tick `1`: the losing agent receives `blockedByAgentConflict` as
  `lastFeedback`, v1 converts that agent to `noIntent`, and the conflict is
  reduced;
- tick `2`: verify deterministic feedback carryover and no cross-agent
  feedback leak;
- feedback from tick `0` is consumed at tick `1`;
- no feedback is consumed in the same tick that emits it;
- v1 behavior changes only from previous tick feedback;
- no World, collision read, movement application, mutation, memory update,
  goal change, pathfinding, replanning, avoidance, reservation runtime, or
  route following;
- write per-tick and aggregate reports.

## Out Of Scope

- pathfinding;
- replanning;
- avoidance;
- reservation runtime;
- route following;
- terrain/world mutation;
- core entity movement;
- physical placeholder movement;
- renderer changes;
- resource changes;
- shader changes;
- save/load changes;
- registry changes;
- golden updates;
- mining, construction, or inventory behavior;
- physics integration;
- learning or RL;
- LLM or Python execution;
- social behavior;
- communication;
- autonomous gameplay loop beyond fixed smoke ticks.

## Phase 4.24B Implementation Status

Status: implemented and validated.

Phase 4.24B added the fixture-only scenario
`multi_tick_closed_loop_fixture_smoke`.

The scenario executes exactly three ticks over four synthetic agents:

- tick `0`: no previous feedback exists; two agents conflict on the same
  destination and the fixture tick emits feedback;
- tick `1`: tick `0` feedback is consumed; the losing agent observes
  `blockedByAgentConflict`, v1 converts it to `noIntent`, and the conflict is
  reduced;
- tick `2`: only tick `1` feedback is consumed; the losing agent has no
  previous-tick feedback, returns to baseline, and the same conflict appears
  again.

Validated aggregate totals:

- `requestedTicks = 3`;
- `executedTicks = 3`;
- `agents = 4`;
- `contextsTotal = 12`;
- `contextsWithFeedbackTotal = 5`;
- `contextsWithoutFeedbackTotal = 7`;
- `feedbackConsumedTotal = 5`;
- `feedbackCarriedToNextTickTotal = 8`;
- `proposalsTotal = 12`;
- `acceptedIntentsTotal = 8`;
- `noIntentTotal = 4`;
- `noIntentFromBlockedFeedbackTotal = 1`;
- `movementIntentInputsTotal = 8`;
- `tickApprovedTotal = 6`;
- `tickDeniedTotal = 2`;
- `tickDeniedConflictTotal = 2`;
- `tickDeniedCollisionTotal = 0`;
- `feedbackEmittedTotal = 8`;
- `sameTickFeedbackConsumedTotal = 0`;
- `crossAgentFeedbackLeaksTotal = 0`;
- `futureFeedbackConsumedTotal = 0`.

The scenario writes:

- `multi_tick_closed_loop_report.json`;
- `multi_tick_closed_loop_invariant_report.json`;
- `multi_tick_closed_loop_ticks.json`;
- `multi_tick_closed_loop_feedback.json`;
- `metrics.json`;
- `events.ndjson`.

The invariant report contains 87 checks and validates fixed tick count,
deterministic tick/agent ordering, previous-tick-only feedback consumption,
no same-tick/future/cross-agent feedback consumption, tick `1` conflict
reduction, tick `2` memoryless return to conflict, fixture tick conflict
arbitration, and artifact writing.

The fixture keeps the strict 4.24 boundary:

- no World;
- no live collision read;
- no movement application;
- no approved lab position map movement;
- no memory update;
- no goal change;
- no pathfinding;
- no replanning;
- no avoidance;
- no reservation runtime;
- no route following;
- no physics;
- no terrain/world mutation.

Next recommended step: Phase 4.24C - Multi-Tick Closed Loop Hardening.
