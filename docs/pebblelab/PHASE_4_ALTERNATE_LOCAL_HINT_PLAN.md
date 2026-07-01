# Phase 4 - Deterministic Bounded Alternate Local Hint Plan

## Validated Starting Point

PebbleLab now has a validated feedback-aware movement chain up to bounded
multi-tick approved application:

- Phase 4.23 added the opt-in feedback-aware v1 policy while keeping v0
  unchanged. In v1, no feedback, `moved`, and `approvedForMovement` keep the
  baseline decision; `blockedBy*` feedback becomes `noIntent`.
- Phase 4.24 added the bounded multi-tick closed loop plan, fixture smoke,
  hardening, live read-only smoke, and approved application smoke.
- Feedback emitted at tick `N` is consumed only at tick `N+1`.
- Same-tick, future, and cross-agent feedback leaks are rejected by the
  contract.
- The policy never reads collision or World.
- The tick layer remains responsible for arbitration and, in live modes,
  read-only collision/World evidence.
- Approved application can update only PebbleLab abstract and physical
  position maps.
- Denied and `noIntent` agents are preserved.
- No terrain or World mutation is performed.
- No pathfinding, replanning, avoidance, reservation runtime, route following,
  memory mutation, or goal mutation is in scope.

The current safe behavior for blocked feedback is intentionally conservative:
blocked feedback causes `noIntent` in v1.

## Problem To Solve

The current `blockedBy* -> noIntent` rule is safe, deterministic, and easy to
audit. It also means an agent that repeatedly receives blocking feedback can
pause frequently, sometimes every other tick, even when a tiny local alternate
hint would be enough to continue testing the pipeline.

The next possible step is not a planner. The next possible step is a bounded,
deterministic, inspectable local hint mechanism:

- given the previous tick feedback;
- given the current local context;
- try a tiny fixed number of one-edge local alternatives;
- keep the tick layer responsible for final arbitration and collision.

The key problem is to define that boundary before implementation so alternate
hints do not quietly become pathfinding, replanning, avoidance, route
following, memory, or gameplay autonomy.

## Non-Goal Statement

This is not pathfinding.

This is not replanning.

This is not avoidance.

This is not reservation runtime.

This is not long route following.

This is not gameplay autonomy.

This is not learning.

This is not social behavior.

This is not LLM/RL/Python.

This is not World mutation.

This is not terrain mutation.

## Alternate Local Hint Boundary

Allowed future behavior:

- read an agent context and previous-tick feedback;
- recognize blocked feedback as a bounded local hint opportunity;
- produce at most `N` local hint candidates;
- keep `N` small and fixed, such as 2 or 3;
- emit only local one-edge hints;
- derive candidates from a fixed ordered table;
- keep candidate ordering deterministic;
- avoid reading World from policy code;
- avoid reading collision from policy code;
- avoid directly inspecting other agents from policy code;
- avoid reserving cells;
- avoid remembering history beyond `lastFeedback`;
- avoid updating goals;
- avoid updating memory;
- pass selected local hints into the existing intent production, policy, and
  tick pipeline;
- let the tick layer arbitrate conflicts;
- let the tick layer read collision only in modes that already allow it;
- let approved application update only lab abstract/physical maps.

Forbidden future behavior:

- BFS, A*, Dijkstra, or any graph search;
- heuristic pathfinding;
- dynamic replanning;
- obstacle avoidance systems;
- reservation tables or reservation runtime;
- route following;
- terrain probing from policy code;
- World reads from policy code;
- collision reads from policy code;
- multi-step routes;
- agent negotiation;
- social coordination;
- learning or reward updates;
- memory mutation;
- goal mutation;
- direct movement application by policy code;
- terrain mutation;
- World mutation.

## Proposed Deterministic Rule

This is a future rule proposal only. It is not implemented in Phase 4.25A.

For blocked feedback:

1. Read the original local hint from the baseline context.
2. Choose alternates from a fixed ordered table based on the attempted
   direction.
3. Exclude the exact failed direction.
4. Emit at most two alternate hints for the first implementation.
5. Preserve deterministic order.
6. If the original hint is unknown or empty, emit no alternate hint.
7. Do not read World.
8. Do not read collision.
9. Do not guarantee success.
10. Let the tick layer arbitrate and deny if needed.

Candidate table:

| Failed hint | Alternate hints |
| --- | --- |
| `move_east` | `[move_north, move_south]` |
| `move_west` | `[move_north, move_south]` |
| `move_north` | `[move_east, move_west]` |
| `move_south` | `[move_east, move_west]` |
| unknown or empty | `[]` |

The table intentionally does not consult terrain, occupancy, other agents, or
longer routes. It only offers bounded local alternatives to the normal
policy/tick chain.

## Policy Integration Options

### Option A - Pre-Policy Hint Adapter

A pre-policy adapter could build `LabAgentIntentContext` with alternate hints
before calling the current policy.

Benefits:

- keeps the policy implementation small;
- makes the alternate hint handoff visible in context construction.

Risks:

- blurs context construction and policy responsibility;
- can make it harder to tell whether v1 behavior changed;
- risks making alternate hints feel implicit.

### Option B - Explicit v2 Policy

A future opt-in `produceAgentIntentProposalFeedbackAwareV2` could handle the
bounded alternate hint rule explicitly.

Benefits:

- v0 remains unchanged;
- v1 remains unchanged;
- v2 is clearly opt-in;
- behavior changes are visible in reports and metrics;
- policy mode is explicit in every decision.

Risks:

- adds another policy mode to maintain;
- requires hardening to prove v0/v1 remain stable.

Recommendation: use explicit v2 opt-in in future phases. The v2 path preserves
the established PebbleLab habit of adding behavior behind named scenarios and
explicit policy modes rather than changing existing contracts globally.

## Future Data Model

Proposed docs-only type names:

- `LabAgentAlternateLocalHintContext`
- `LabAgentAlternateLocalHintCandidate`
- `LabAgentAlternateLocalHintDecision`
- `LabAgentAlternateLocalHintPolicyMode`
- `LabAgentAlternateLocalHintReport`
- `LabAgentAlternateLocalHintInvariantReport`
- `LabAgentAlternateLocalHintHandoff`

Fields to consider:

- `agentId`
- `tick`
- `originalHint`
- `blockedFeedbackKind`
- `blockedFrom`
- `blockedTo`
- `alternateHints`
- `maxAlternates`
- `selectedHint`
- `reason`
- `policyVersion`
- `usedWorld`
- `readCollision`
- `pathfindingPerformed`
- `replanningPerformed`
- `avoidancePerformed`
- `reservationRuntimeUsed`
- `memoryUpdated`
- `goalChanged`
- `success`

The model should keep raw candidates, filtered candidates, selected hint, and
rejection reason separately so reports can prove bounded behavior.

## Future Scenario Sequence

### Phase 4.25B - Alternate Local Hint Fixture Smoke

- fixture-only;
- blocked feedback produces a deterministic alternate hint;
- the alternate hint feeds intent production;
- tick fixture arbitrates;
- no World;
- no collision read;
- no movement application.

### Phase 4.25C - Alternate Local Hint Hardening

- unknown hint;
- empty hint;
- duplicate hints;
- max alternates bound;
- all blocked feedback kinds;
- no feedback;
- moved and approved feedback;
- repeatability;
- no World or collision read from policy.

### Phase 4.25D - Alternate Local Hint Live Read-Only Smoke

- tick reads collision read-only;
- policy does not read World or collision;
- alternate hint can still be denied by collision;
- no movement application.

### Phase 4.25E - Alternate Local Hint Approved Application Smoke

- approved alternate movement applies only to lab maps;
- denied and `noIntent` agents are preserved;
- no terrain or World mutation.

### Phase 4.25F - Alternate Local Hint Multi-Tick Regression/Replay

- stable replay;
- deterministic per-tick trace;
- no nondeterministic candidate ordering;
- no nondeterministic event or metrics drift.

## Proposed Reports

Future outputs:

- `alternate_local_hint_report.json`
- `alternate_local_hint_invariant_report.json`
- `alternate_local_hint_handoff.json`
- `alternate_local_hint_decisions.json`
- `metrics.json`
- `events.ndjson`

## Proposed Metrics

Metrics should use the `alternateLocalHint*` prefix:

- `alternateLocalHintContexts`
- `alternateLocalHintContextsWithBlockedFeedback`
- `alternateLocalHintContextsWithoutFeedback`
- `alternateLocalHintCandidatesProduced`
- `alternateLocalHintCandidatesSelected`
- `alternateLocalHintCandidatesFiltered`
- `alternateLocalHintMaxAlternates`
- `alternateLocalHintBounded`
- `alternateLocalHintNoFeedbackBaseline`
- `alternateLocalHintApprovedFeedbackBaseline`
- `alternateLocalHintMovedFeedbackBaseline`
- `alternateLocalHintBlockedFeedbackUsed`
- `alternateLocalHintUnknownHintNoAlternate`
- `alternateLocalHintEmptyHintNoAlternate`
- `alternateLocalHintPolicyVersion`
- `alternateLocalHintV0Unchanged`
- `alternateLocalHintV1Unchanged`
- `alternateLocalHintV2OptIn`
- `alternateLocalHintPolicyReadCollision`
- `alternateLocalHintPolicyWorldUsed`
- `alternateLocalHintPathfindingPerformed`
- `alternateLocalHintReplanningPerformed`
- `alternateLocalHintAvoidancePerformed`
- `alternateLocalHintReservationRuntimeUsed`
- `alternateLocalHintRouteFollowingUsed`
- `alternateLocalHintMemoryUpdated`
- `alternateLocalHintGoalChanged`
- `alternateLocalHintWorldMutated`
- `alternateLocalHintMutationPerformed`
- `alternateLocalHintSuccess`

## Proposed Event

Future event:

`lab_alternate_local_hint_recorded`

Fields:

- `contexts`
- `contextsWithBlockedFeedback`
- `candidatesProduced`
- `candidatesSelected`
- `candidatesFiltered`
- `maxAlternates`
- `bounded`
- `noFeedbackBaseline`
- `approvedFeedbackBaseline`
- `movedFeedbackBaseline`
- `blockedFeedbackUsed`
- `unknownHintNoAlternate`
- `emptyHintNoAlternate`
- `v0Unchanged`
- `v1Unchanged`
- `v2OptIn`
- `policyReadCollision`
- `policyWorldUsed`
- `pathfindingPerformed`
- `replanningPerformed`
- `avoidancePerformed`
- `reservationRuntimeUsed`
- `routeFollowingUsed`
- `memoryUpdated`
- `goalChanged`
- `worldMutated`
- `mutationPerformed`
- `success`

The event should be aggregate-only. Per-agent candidate details belong in the
handoff and decisions JSON.

## Future Invariants

Future alternate local hint scenarios should validate at least these
invariants:

1. `v0_policy_unchanged`
2. `v1_policy_unchanged`
3. `v2_policy_opt_in`
4. `no_global_policy_replacement`
5. `contexts_exist`
6. `contexts_sorted_by_agent_id`
7. `feedback_sorted_by_agent_id`
8. `decisions_sorted_by_agent_id`
9. `candidates_sorted_deterministically`
10. `max_alternate_hints_bounded`
11. `max_alternate_hints_fixed`
12. `candidate_count_never_exceeds_bound`
13. `duplicate_candidates_removed`
14. `original_failed_direction_excluded`
15. `unknown_hint_produces_no_alternate`
16. `empty_hint_produces_no_alternate`
17. `missing_feedback_keeps_baseline`
18. `moved_feedback_keeps_baseline`
19. `approved_for_movement_feedback_keeps_baseline`
20. `blocked_collision_feedback_may_produce_alternate`
21. `blocked_agent_conflict_feedback_may_produce_alternate`
22. `blocked_source_mismatch_feedback_may_produce_alternate_or_no_intent`
23. `blocked_divergence_feedback_may_produce_alternate_or_no_intent`
24. `blocked_stale_intent_feedback_may_produce_alternate_or_no_intent`
25. `blocked_invalid_edge_feedback_may_produce_alternate_or_no_intent`
26. `blocked_max_agents_feedback_may_produce_alternate_or_no_intent`
27. `alternate_hints_are_local`
28. `alternate_hints_are_one_edge`
29. `alternate_hints_are_cardinal_only`
30. `alternate_hints_are_same_y`
31. `no_multi_step_route`
32. `no_route_object_created`
33. `no_bfs`
34. `no_astar`
35. `no_dijkstra`
36. `no_graph_search`
37. `no_heuristic_pathfinding`
38. `pathfinding_not_performed`
39. `replanning_not_performed`
40. `avoidance_not_performed`
41. `reservation_runtime_not_used`
42. `route_following_not_used`
43. `memory_not_updated`
44. `goal_not_changed`
45. `learning_not_performed`
46. `llm_rl_python_not_used`
47. `social_behavior_not_used`
48. `communication_not_used`
49. `policy_does_not_read_world`
50. `policy_does_not_read_collision`
51. `policy_does_not_inspect_other_agents_directly`
52. `tick_remains_responsible_for_arbitration`
53. `tick_remains_responsible_for_collision`
54. `fixture_tick_collision_read_false`
55. `live_tick_collision_read_only`
56. `approved_application_lab_map_only`
57. `direct_policy_movement_not_applied`
58. `denied_agents_preserved`
59. `no_intent_agents_preserved`
60. `abstract_physical_maps_remain_synchronized`
61. `terrain_mutation_not_performed`
62. `world_mutation_not_performed`
63. `physical_placeholder_not_moved`
64. `core_entity_not_moved`
65. `renderer_not_modified`
66. `resources_not_modified`
67. `registries_not_modified`
68. `save_load_not_modified`
69. `goldens_not_modified`
70. `deterministic_report_written`
71. `deterministic_handoff_written`
72. `deterministic_decisions_written`
73. `metrics_written`
74. `event_written`
75. `repeatability_verified`
76. `metrics_match_report`
77. `event_matches_report`
78. `compatible_with_4_24_fixture_loop`
79. `compatible_with_4_24_hardening_loop`
80. `compatible_with_4_24_live_readonly_loop`
81. `compatible_with_4_24_approved_application_loop`
82. `success_contract_respected`

## Risk Table

| Risk | Why it matters | Mitigation |
| --- | --- | --- |
| Alternate hints become pathfinding | A local fallback could quietly turn into search. | Fixed table, no graph structures, invariant checks for no BFS/A*/Dijkstra. |
| Alternate hints become replanning | Replanning implies broader autonomy than this phase allows. | v2 emits only one bounded local hint decision per tick. |
| Policy starts reading World | That violates the established policy/tick boundary. | `policyWorldUsed=false` metrics and invariants. |
| Policy starts reading collision | Collision belongs to the tick layer. | `policyReadCollision=false` metrics and invariants. |
| Candidates become unbounded | Unbounded candidates create hidden search. | Fixed `maxAlternates`, candidate count checks. |
| Route following sneaks in | Route following changes the movement model. | No route object, no route following helper, explicit invariant. |
| Reservation runtime sneaks in | Reservations would create a new coordination subsystem. | No reservation table/runtime, explicit metrics. |
| Memory or goals mutate | Alternate hints must remain context-local. | `memoryUpdated=false`, `goalChanged=false`. |
| v2 replaces v1 globally | Existing scenarios would silently change behavior. | v2 opt-in only, v1/v0 regression checks. |
| v1 behavior changes accidentally | 4.23 and 4.24 contracts depend on v1. | Keep v1 unchanged and run existing scenarios. |
| Alternates hide blocked feedback | Reports need to show why a hint changed. | Preserve blocked feedback kind and original failed hint in decisions JSON. |
| Nondeterministic candidate order | Replay and test stability would suffer. | Fixed ordered table and repeatability checks. |
| Local hints create oscillation | Bounded hints can still bounce between cells. | Report per-tick traces, keep first smoke fixed and small. |
| Approved application becomes gameplay movement | Lab maps are not world/entity movement. | Approved application remains lab-map-only. |
| Live collision read mutates World | Read-only evidence must stay read-only. | Tick read-only invariants and no mutation checks. |
| Metrics hide policy boundary violations | Green summaries can mask wrong responsibility. | Metrics must mirror report and event boundary flags. |

## Recommended 4.25B Contract

Phase 4.25B - Alternate Local Hint Fixture Smoke should implement the smallest
possible fixture-only proof:

- no World;
- no live collision;
- no movement application;
- v2 opt-in;
- v0 unchanged;
- v1 unchanged;
- fixed `maxAlternates`, recommended value `2`;
- four contexts:
  - no feedback -> baseline;
  - `moved` or `approvedForMovement` feedback -> baseline;
  - blocked feedback with original `move_east` -> `[move_north]` or
    `[move_north, move_south]`;
  - blocked feedback with unknown or empty hint -> no alternate or `noIntent`;
- handoff/report/invariant/metrics/event outputs;
- tick fixture validates alternate hints enter the normal movement-intent path;
- no pathfinding;
- no replanning;
- no avoidance;
- no reservation runtime;
- no route following;
- no memory or goal mutation;
- no terrain or World mutation.

The first smoke should prefer the explicit v2 policy mode rather than a
pre-policy adapter.

## Out Of Scope

- pathfinding;
- replanning;
- avoidance;
- reservation runtime;
- route following;
- multi-step routes;
- terrain mutation;
- World mutation;
- core entity movement;
- physical placeholder movement;
- renderer changes;
- resource changes;
- shader changes;
- save/load changes;
- registry changes;
- golden updates;
- mining;
- construction;
- inventory;
- physics;
- learning;
- reinforcement learning;
- LLM/Python integration;
- social behavior;
- communication;
- autonomous gameplay loops beyond fixed smoke ticks.

## Phase 4.25B Implementation Status

Status: implemented and validated.

Phase 4.25B added `alternate_local_hint_fixture_smoke`, the first
fixture-only implementation of the deterministic bounded alternate local hint
contract.

Validated implementation:

- v0 remains unchanged;
- v1 remains unchanged;
- v2 is explicit opt-in via the alternate local hint fixture;
- six fixture contexts produce six deterministic decisions;
- no feedback keeps baseline;
- `approvedForMovement` keeps baseline;
- blocked east and west feedback use the fixed ordered alternate table;
- failed directions are excluded;
- `maxAlternates = 2`;
- four candidates are produced and two are selected;
- empty and unknown hints produce no alternate and become `noIntent`;
- alternates are one-edge same-y movement intents;
- noIntent proposals are filtered before tick;
- four movement intents enter the tick fixture;
- tick fixture approves all four movement intents;
- no live collision is read;
- no World is used;
- no movement is applied;
- no memory/goals, pathfinding, replanning, avoidance, reservation runtime,
  route following, or terrain/world mutation occur.

Produced outputs:

- `alternate_local_hint_report.json`;
- `alternate_local_hint_invariant_report.json`;
- `alternate_local_hint_handoff.json`;
- `alternate_local_hint_decisions.json`;
- `metrics.json` with `alternateLocalHint*`;
- `events.ndjson` with `lab_alternate_local_hint_recorded`.

Limits:

- fixture-only;
- no live read-only collision;
- no approved application;
- no multi-tick alternate replay;
- no alternate hardening yet;
- no v2 global replacement.

Next recommended step: Phase 4.25C - Alternate Local Hint Hardening.

## Phase 4.25C Implementation Status

Status: implemented and validated.

Phase 4.25C added `alternate_local_hint_hardening_smoke`, a fixture-only
hardening scenario for deterministic bounded alternate local hints.

Validated hardening:

- 22 cases;
- 22 passed;
- 0 failed;
- v0 remains unchanged;
- v1 remains unchanged;
- v2 remains explicit opt-in;
- all seven blocked feedback kinds are covered;
- `maxAlternates` bounds cover 0, 1, 2, and 3;
- candidate order is deterministic;
- duplicate hints are handled deterministically;
- empty and unknown hints produce no alternate;
- failed directions are excluded;
- alternates remain one-edge same-y intents;
- repeatability is verified with 0 failures;
- noIntent outcomes are filtered before fixture tick;
- movement intents sent to tick are regular accepted intents;
- fixture tick approves the hardening handoff;
- no live collision is read;
- no World is used;
- no movement is applied;
- no route following, pathfinding, replanning, avoidance, reservation runtime,
  memory/goals, or terrain/world mutation occurs.

Produced outputs:

- `alternate_local_hint_hardening_report.json`;
- `alternate_local_hint_hardening_invariant_report.json`;
- `alternate_local_hint_hardening_cases.json`;
- `alternate_local_hint_hardening_decisions.json`;
- `alternate_local_hint_hardening_handoff.json`;
- `metrics.json` with `alternateLocalHintHardening*`;
- `events.ndjson` with `lab_alternate_local_hint_hardening_recorded`.

Limits:

- fixture-only;
- no live read-only collision;
- no approved application;
- no multi-tick alternate replay;
- no v2 global replacement;
- no alternate route, search, reservation, or avoidance behavior.

Next recommended step: Phase 4.25D - Alternate Local Hint Live Read-Only Smoke.

## Phase 4.25D Implementation Status

Status: implemented and validated.

Phase 4.25D added `alternate_local_hint_live_readonly_smoke`, the first
live-read-only tick handoff for deterministic bounded alternate local hints.

Validated implementation:

- v0 remains unchanged;
- v1 remains unchanged;
- v2 remains explicit opt-in;
- six contexts produce six deterministic decisions;
- one no-feedback context keeps baseline;
- one `approvedForMovement` context keeps baseline;
- two blocked contexts select deterministic alternates from the fixed table;
- empty and unknown blocked hints produce no alternate and become `noIntent`;
- `maxAlternates = 2`;
- four candidates are produced and two are selected;
- failed directions are excluded;
- selected alternates are one-edge same-y intents;
- two noIntent proposals are filtered before tick;
- four movement intents enter the tick live read-only contract;
- tick live read-only approves three occupable destinations;
- tick live read-only denies one non-occupable destination by collision;
- collision denial comes from tick evidence, not policy;
- policy reads no World and no collision;
- tick reads World/collision read-only;
- no movement is applied;
- no lab position maps are mutated;
- no memory/goals, pathfinding, replanning, avoidance, reservation runtime,
  route following, or terrain/world mutation occur.

Produced outputs:

- `alternate_local_hint_live_readonly_report.json`;
- `alternate_local_hint_live_readonly_invariant_report.json`;
- `alternate_local_hint_live_readonly_decisions.json`;
- `alternate_local_hint_live_readonly_handoff.json`;
- `metrics.json` with `alternateLocalHintLiveReadonly*`;
- `events.ndjson` with `lab_alternate_local_hint_live_readonly_recorded`.

Limits:

- live read-only only;
- no approved application;
- no movement application;
- no route following;
- no pathfinding, replanning, avoidance, or reservation runtime;
- no memory/goals;
- no terrain/world mutation;
- no v2 global replacement.

Next recommended step: Phase 4.25E - Alternate Local Hint Approved Application
Smoke.

## Phase 4.25E Implementation Status

Status: implemented and validated.

Phase 4.25E added `alternate_local_hint_approved_application_smoke`, connecting
explicit opt-in alternate local hint v2 decisions to the tick approved
application contract.

Validated implementation:

- v0 remains unchanged;
- v1 remains unchanged;
- v2 remains explicit opt-in;
- six contexts produce six deterministic decisions;
- one no-feedback context keeps baseline;
- one `approvedForMovement` context keeps baseline;
- two blocked contexts select deterministic alternates from the fixed table;
- empty and unknown blocked hints produce no alternate and become `noIntent`;
- `maxAlternates = 2`;
- four candidates are produced and two are selected;
- failed directions are excluded;
- selected alternates are one-edge same-y intents;
- two noIntent proposals are filtered before tick;
- four movement intents enter the tick approved application contract;
- tick collision evidence approves three occupable destinations;
- tick collision evidence denies one non-occupable destination by collision;
- approved moves update only lab abstract/physical position maps;
- three approved agents move;
- one collision-denied agent is preserved;
- two noIntent agents are preserved;
- abstract/physical divergence remains zero before and after application;
- policy reads no World and no collision;
- tick reads World/collision read-only;
- no memory/goals, pathfinding, replanning, avoidance, reservation runtime,
  route following, or terrain/world mutation occur.

Produced outputs:

- `alternate_local_hint_approved_application_report.json`;
- `alternate_local_hint_approved_application_invariant_report.json`;
- `alternate_local_hint_approved_application_decisions.json`;
- `alternate_local_hint_approved_application_handoff.json`;
- `alternate_local_hint_approved_application_positions.json`;
- `metrics.json` with `alternateLocalHintApprovedApplication*`;
- `events.ndjson` with
  `lab_alternate_local_hint_approved_application_recorded`.

Limits:

- approved application is limited to lab position maps;
- no core entity movement;
- no physical placeholder live movement;
- no route following;
- no pathfinding, replanning, avoidance, or reservation runtime;
- no memory/goals;
- no terrain/world mutation;
- no v2 global replacement.

Next recommended step: Phase 4.25F - Alternate Local Hint Multi-Tick
Regression/Replay.

## Phase 4.25F Implementation Status

Status: implemented and validated.

Phase 4.25F added `alternate_local_hint_multi_tick_replay_smoke`, a
deterministic three-tick replay for explicit opt-in alternate local hint v2
policy decisions feeding tick approved application.

Validated implementation:

- v0 remains unchanged;
- v1 remains unchanged;
- v2 remains explicit opt-in;
- three fixed ticks execute regardless of requested run-loop autonomy;
- six agents produce eighteen contexts and eighteen decisions;
- feedback emitted at tick N is consumed only at tick N+1;
- same-tick feedback consumption is zero;
- future feedback consumption is zero;
- cross-agent feedback leaks are zero;
- tick 0 feedback is consumed at tick 1;
- tick 1 feedback is consumed at tick 2;
- blocked feedback with known local hints produces bounded alternates;
- empty and unknown blocked hints produce no alternate;
- ten candidates are produced and five are selected across the replay;
- failed directions are excluded;
- alternates are one-edge same-y intents;
- twelve movement intents enter tick approved application;
- tick collision evidence approves eight intents and denies four by collision;
- approved moves update only lab abstract/physical position maps;
- four denied agents are preserved;
- six noIntent agents are preserved;
- abstract/physical divergence remains zero before and after each tick;
- replay runs twice and the stable digests match;
- deterministic agent, candidate, decision, and JSON-output ordering are
  verified;
- policy reads no World and no collision;
- tick reads World/collision read-only;
- no route following, pathfinding, replanning, avoidance, reservation runtime,
  memory/goals, or terrain/world mutation occurs.

Produced outputs:

- `alternate_local_hint_multi_tick_replay_report.json`;
- `alternate_local_hint_multi_tick_replay_invariant_report.json`;
- `alternate_local_hint_multi_tick_replay_ticks.json`;
- `alternate_local_hint_multi_tick_replay_feedback.json`;
- `alternate_local_hint_multi_tick_replay_positions.json`;
- `alternate_local_hint_multi_tick_replay_digest.json`;
- `metrics.json` with `alternateLocalHintMultiTickReplay*`;
- `events.ndjson` with `lab_alternate_local_hint_multi_tick_replay_recorded`.

Limits:

- approved application remains lab-map-only;
- no core entity movement;
- no physical placeholder live movement;
- no route following;
- no pathfinding, replanning, avoidance, or reservation runtime;
- no memory/goals;
- no terrain/world mutation;
- no v2 global replacement.

Next recommended step: Phase 4.26A - Agent Movement Policy Consolidation Plan
Docs-Only.

## Transition To Policy Consolidation

Phase 4.25 completed deterministic bounded alternate local hints through
fixture, hardening, live read-only, approved application, and multi-tick replay.
The validated v2 policy remains explicit opt-in, v0 and v1 remain unchanged,
and replay proves deterministic feedback carryover with stable digests.

Phase 4.26A documents agent movement policy consolidation before any new
behavior or path planning work. The dedicated plan is
`docs/pebblelab/PHASE_4_AGENT_MOVEMENT_POLICY_CONSOLIDATION_PLAN.md`.

The consolidation boundary remains:

- v2 opt-in only;
- no pathfinding;
- no route planning;
- no route following;
- no replanning;
- no avoidance;
- no reservation runtime;
- no memory/goals;
- no terrain/world mutation.
