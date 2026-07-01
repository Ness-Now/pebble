# Phase 4 — Agent Movement Policy Consolidation Plan

## Validated Starting Point

PebbleLab now has a broad but intentionally bounded agent movement policy stack.
The validated pieces are:

- intent production from synthetic agent contexts;
- hardening for invalid contexts, duplicate proposals, stale proposals, wrong
  source proposals, max proposal bounds, and deterministic ordering;
- intent-to-tick fixture handoff;
- intent-to-tick live read-only collision handoff;
- intent-to-tick approved application with lab-map-only movement;
- feedback consumption into bounded feedback contexts;
- feedback injection into `LabAgentIntentContext.lastFeedback`;
- feedback-aware v1 policy;
- alternate local hint v2 policy;
- tick fixture arbitration;
- tick live read-only collision evidence;
- tick approved application;
- multi-tick closed loop orchestration;
- alternate local hint replay and digest repeatability.

Validated scenario coverage includes:

- `agent_intent_production_fixture_smoke`;
- `agent_intent_production_hardening_smoke`;
- `agent_intent_to_tick_fixture_smoke`;
- `agent_intent_to_tick_live_readonly_smoke`;
- `agent_intent_to_tick_approved_application_smoke`;
- `feedback_consumption_fixture_smoke` family, implemented as
  `agent_feedback_consumption_fixture_smoke`;
- `feedback_consumption_hardening_smoke` family, implemented as
  `agent_feedback_consumption_hardening_smoke`;
- `feedback_to_agent_intent_context_fixture_smoke`;
- `feedback_to_agent_intent_context_hardening_smoke`;
- `feedback_aware_intent_policy_fixture_smoke`;
- `feedback_aware_intent_policy_hardening_smoke`;
- `feedback_aware_intent_to_tick_fixture_smoke`;
- `feedback_aware_intent_to_tick_live_readonly_smoke`;
- `feedback_aware_intent_to_tick_approved_application_smoke`;
- `multi_tick_closed_loop_fixture_smoke`;
- `multi_tick_closed_loop_hardening_smoke`;
- `multi_tick_closed_loop_live_readonly_smoke`;
- `multi_tick_closed_loop_approved_application_smoke`;
- `alternate_local_hint_fixture_smoke`;
- `alternate_local_hint_hardening_smoke`;
- `alternate_local_hint_live_readonly_smoke`;
- `alternate_local_hint_approved_application_smoke`;
- `alternate_local_hint_multi_tick_replay_smoke`.

The current state is intentionally conservative: policy versions are explicit,
tick arbitration remains separate, live collision evidence belongs to the tick
layer, approved application mutates only PebbleLab lab position maps, and
multi-tick replay proves deterministic feedback carryover.

## Problem To Solve

The movement policy stack has grown cleanly, but it now has many modes,
reports, summaries, metrics, events, and scenario families. Before adding path
planning, route following, memory, goals, or any larger autonomy, PebbleLab
needs a clear consolidation plan.

The main risk is mixing concerns that are currently separated:

- policy might start reading World or collision;
- feedback interpretation might become memory;
- alternate hints might drift into pathfinding;
- tick arbitration might leak into policy;
- approved application might mutate World;
- replay might become an autonomous gameplay loop;
- report or metric shape might hide behavior drift.

The consolidation must preserve existing behavior. It should make names,
boundaries, reports, metrics, events, and invariants easier to compare without
implicitly changing v0, v1, or v2.

## Current Policy Stack

### v0

`produceAgentIntentProposalV0` is the baseline deterministic intent proposal
policy.

Responsibilities:

- read `LabAgentIntentContext`;
- read position, role, and local hints;
- produce at most one proposal per agent;
- produce `noIntent` when the context has no supported hint;
- keep stable ordering by `agentId` at the production layer.

Forbidden:

- read feedback;
- read World;
- read collision;
- update memory;
- change goals;
- pathfind;
- replan;
- avoid;
- reserve;
- move agents.

### v1

`produceAgentIntentProposalFeedbackAwareV1` is an explicit opt-in
feedback-aware policy.

Responsibilities:

- compute the v0 baseline;
- keep baseline when there is no feedback;
- keep baseline for `moved`;
- keep baseline for `approvedForMovement`;
- convert `blockedBy*` feedback to `noIntent`;
- produce explicit decision reasons.

Forbidden:

- choose alternate hints;
- read World;
- read collision;
- mutate memory or goals;
- pathfind, replan, avoid, reserve, or route-follow;
- replace v0 globally.

### v2

`produceAgentIntentProposalWithAlternateLocalHintsV2` is an explicit opt-in
deterministic bounded alternate local hint policy.

Responsibilities:

- compute v0 and v1-compatible baseline behavior;
- keep baseline for no feedback, `moved`, and `approvedForMovement`;
- for blocked feedback with a known original local hint, select deterministic
  bounded alternate hints;
- for blocked feedback with empty or unknown hints, produce `noIntent`;
- enforce `maxAlternates`;
- exclude the failed direction;
- keep alternate hints one-edge and same-y;
- produce deterministic candidate and decision order.

Forbidden:

- read World;
- read collision;
- inspect other agents directly;
- reserve cells;
- pathfind;
- replan;
- avoid;
- route-follow;
- mutate memory or goals;
- replace v0 or v1 globally.

## Layer Boundary

### Policy Layer

The policy layer transforms context, feedback, and local hints into a proposal.

Allowed:

- inspect the provided context;
- inspect the provided last feedback;
- inspect fixed local hint tables;
- choose noIntent or a one-edge proposal;
- record boundary flags.

Forbidden:

- read World;
- read collision;
- mutate terrain or World;
- move abstract, physical, placeholder, or core entities;
- reserve cells;
- plan routes;
- pathfind;
- replan;
- avoid;
- keep durable memory;
- change goals.

### Intent Production Layer

The intent production layer collects proposals and produces accepted movement
intents plus rejected proposals.

Allowed:

- sort contexts and proposals deterministically;
- validate one-edge same-y movement intents;
- filter `noIntent`;
- count accepted and rejected proposals;
- write reports.

Forbidden:

- arbitrate same-destination conflicts;
- read collision;
- apply movement;
- mutate memory/goals;
- plan routes.

### Tick Layer

The tick layer owns arbitration and final movement approval or denial.

Allowed:

- arbitrate conflicts;
- check source positions;
- in live read-only mode, read World/collision;
- produce approved and denied resolutions;
- produce structured feedback.

Forbidden:

- pathfind for agents;
- dynamically replan;
- alter policy outputs;
- mutate terrain or World;
- perform route following.

### Approved Application Layer

Approved application applies only approved tick resolutions to PebbleLab lab
maps.

Allowed:

- update lab abstract positions for approved moves;
- update lab physical-position maps for approved moves;
- preserve denied agents;
- preserve noIntent agents;
- verify abstract/physical divergence remains bounded.

Forbidden:

- mutate terrain;
- mutate World;
- move core entities;
- move physical placeholders;
- route-follow;
- pathfind;
- update memory/goals.

### Replay Layer

The replay layer proves deterministic multi-tick behavior.

Allowed:

- replay fixed ticks;
- carry feedback from tick N to tick N+1;
- compare stable digests;
- aggregate per-tick reports.

Forbidden:

- consume same-tick feedback;
- consume future feedback;
- leak feedback across agents;
- become an unbounded gameplay loop;
- hide nondeterminism.

## Consolidation Goals

Future consolidation should:

- clarify naming across v0, v1, and v2;
- standardize policy mode reporting;
- make boundary flags uniform;
- reduce duplicate summary shape drift;
- standardize output sections;
- standardize metrics prefixes and field names;
- standardize aggregate event fields;
- make replay and digest checks reusable;
- keep all existing scenarios green;
- preserve v0, v1, and v2 behavior exactly;
- avoid introducing new behavior;
- prepare a later docs-only path planning phase without implementing planning.

## Non-Goals

This is not pathfinding.
This is not route planning.
This is not route following.
This is not replanning.
This is not avoidance.
This is not reservation runtime.
This is not memory.
This is not goals.
This is not learning.
This is not LLM/RL/Python.
This is not gameplay autonomy.
This is not physical entity movement.
This is not terrain mutation.
This is not World mutation.
This is not a behavior change to v0/v1/v2.

## Proposed Consolidated Naming

Future consolidation can introduce names like these without changing behavior.

`LabAgentMovementPolicyVersion`

- `.baselineV0`;
- `.feedbackAwareV1`;
- `.alternateLocalHintV2`.

`LabAgentMovementPolicyDecision`

- `agentId`;
- `tick`;
- `policyVersion`;
- `baselineProposal`;
- `feedbackInterpretation`;
- `alternateCandidates`;
- `selectedHint`;
- `finalProposal`;
- `behaviorChanged`;
- `reason`;
- `boundary`.

`LabAgentMovementPolicyBoundary`

- `policyReadCollision`;
- `policyWorldUsed`;
- `pathfindingPerformed`;
- `replanningPerformed`;
- `avoidancePerformed`;
- `reservationRuntimeUsed`;
- `routeFollowingUsed`;
- `memoryUpdated`;
- `goalChanged`;
- `mutationPerformed`.

`LabAgentMovementTickBoundary`

- `tickReadCollision`;
- `tickWorldReadOnlyUsed`;
- `movementApplied`;
- `worldMutated`;
- `terrainMutated`;
- `coreEntityMoved`;
- `physicalPlaceholderMoved`.

## Report Consolidation Plan

Future reports can share common sections:

- `scenario`;
- `seed`;
- `requestedTicks`;
- `executedTicks`;
- `policyMode`;
- `contexts`;
- `decisions`;
- `tickRecords`;
- `feedbackLedger`;
- `positions`;
- `replayDigest`;
- `summary`;
- `boundary`;
- `invariants`.

Common summary fields should include:

- `contextsTotal`;
- `decisionsTotal`;
- `feedbackConsumedTotal`;
- `candidatesProducedTotal`;
- `movementIntentInputsTotal`;
- `tickApprovedTotal`;
- `tickDeniedTotal`;
- `approvedApplicationsTotal`;
- `deniedAgentsPreservedTotal`;
- `noIntentAgentsPreservedTotal`;
- `displacementsAppliedTotal`;
- `divergenceBeforeMax`;
- `divergenceAfterMax`;
- policy boundary flags;
- tick boundary flags;
- application boundary flags;
- replay boundary flags;
- `success`.

The consolidation should not rewrite existing scenario outputs in 4.26A. Any
future adapter should compare old and new signatures before replacing report
consumers.

## Metrics Consolidation Plan

Future metrics should use:

- a stable prefix per scenario family;
- common names for common totals;
- explicit policy version metrics;
- explicit boundary metrics;
- explicit replay metrics;
- explicit no-hidden-behavior metrics.

Recommended common metric families:

- `agentMovementPolicy*`;
- `agentMovementPolicyBoundary*`;
- `agentMovementTickBoundary*`;
- `agentMovementReplay*`.

No runtime metrics are changed in 4.26A.

## Event Consolidation Plan

Future events should:

- emit one aggregate event per scenario family;
- include `policyMode`;
- include requested/executed tick counts when relevant;
- include aggregate decision and tick totals;
- include boundary fields consistently;
- include replay digest status when relevant;
- avoid per-agent event spam unless a future diagnostic scenario explicitly
  asks for it;
- avoid silently activating v1 or v2.

No runtime events are changed in 4.26A.

## Invariant Consolidation Plan

Future consolidation should preserve or add these invariants:

1. `v0_policy_remains_available`
2. `v0_policy_behavior_unchanged`
3. `v1_policy_remains_available`
4. `v1_policy_behavior_unchanged`
5. `v2_policy_remains_available`
6. `v2_policy_behavior_unchanged`
7. `v1_is_opt_in`
8. `v2_is_opt_in`
9. `no_global_policy_replacement`
10. `no_hidden_policy_activation`
11. `policy_mode_recorded`
12. `policy_version_recorded`
13. `contexts_exist`
14. `contexts_sorted_by_agent_id`
15. `decisions_exist`
16. `decisions_sorted_by_agent_id`
17. `proposals_exist`
18. `proposals_sorted_by_agent_id`
19. `baseline_v0_signature_recorded`
20. `v1_signature_matches_expected`
21. `v2_signature_matches_expected`
22. `no_feedback_keeps_baseline`
23. `moved_feedback_keeps_baseline`
24. `approved_for_movement_keeps_baseline`
25. `blocked_feedback_v1_no_intent`
26. `blocked_feedback_v2_bounded_alternate_or_no_intent`
27. `empty_hint_produces_no_alternate`
28. `unknown_hint_produces_no_alternate`
29. `failed_direction_excluded`
30. `alternate_candidates_bounded`
31. `max_alternates_respected`
32. `alternate_candidate_order_deterministic`
33. `alternate_decision_order_deterministic`
34. `alternate_hints_one_edge`
35. `alternate_hints_same_y`
36. `no_multi_step_route`
37. `policy_does_not_read_world`
38. `policy_does_not_read_collision`
39. `policy_does_not_apply_movement`
40. `policy_does_not_reserve_cells`
41. `policy_does_not_pathfind`
42. `policy_does_not_replan`
43. `policy_does_not_avoid`
44. `policy_does_not_route_follow`
45. `policy_does_not_update_memory`
46. `policy_does_not_change_goals`
47. `intent_production_filters_no_intent`
48. `intent_production_validates_one_edge`
49. `intent_production_does_not_arbitrate_conflicts`
50. `tick_owns_conflict_arbitration`
51. `tick_owns_collision_evidence`
52. `fixture_tick_does_not_read_collision`
53. `live_readonly_tick_reads_collision_only_at_tick_layer`
54. `tick_resolutions_sorted_by_agent_id`
55. `tick_feedback_sorted_by_agent_id`
56. `approved_application_lab_map_only`
57. `approved_application_preserves_denied_agents`
58. `approved_application_preserves_no_intent_agents`
59. `approved_application_does_not_mutate_world`
60. `approved_application_does_not_mutate_terrain`
61. `approved_application_does_not_move_core_entities`
62. `approved_application_does_not_move_physical_placeholders`
63. `abstract_physical_divergence_before_bounded`
64. `abstract_physical_divergence_after_bounded`
65. `abstract_physical_divergence_zero_when_required`
66. `feedback_exists_when_expected`
67. `feedback_kind_recorded`
68. `feedback_consumption_is_deterministic`
69. `feedback_consumed_only_from_previous_tick`
70. `same_tick_feedback_not_consumed`
71. `future_feedback_not_consumed`
72. `cross_agent_feedback_not_consumed`
73. `missing_feedback_allowed`
74. `duplicate_feedback_handled_deterministically`
75. `stale_feedback_ignored_or_rejected`
76. `feedback_ledger_written`
77. `tick_records_written`
78. `positions_written`
79. `replay_digest_written`
80. `replay_digest_repeat_written`
81. `replay_digests_equal`
82. `replay_repeatability_failures_zero`
83. `deterministic_json_output`
84. `report_contains_boundary`
85. `summary_contains_boundary_flags`
86. `metrics_prefix_expected`
87. `metrics_boundary_fields_present`
88. `event_type_expected`
89. `event_policy_mode_present`
90. `event_boundary_fields_present`
91. `no_learning_performed`
92. `no_llm_rl_python_used`
93. `no_social_behavior_used`
94. `no_communication_used`
95. `no_physics_performed`
96. `no_mining_construction_inventory`
97. `renderer_not_modified`
98. `resources_not_modified`
99. `registries_not_modified`
100. `save_load_not_modified`
101. `goldens_not_modified`
102. `prior_agent_intent_scenarios_remain_green`
103. `prior_feedback_consumption_scenarios_remain_green`
104. `prior_feedback_aware_scenarios_remain_green`
105. `prior_multi_tick_closed_loop_scenarios_remain_green`
106. `prior_alternate_hint_scenarios_remain_green`
107. `pebsmoke_remains_green`
108. `success_contract_respected`

## Risk Table

| Risk | Why it matters | Mitigation |
| --- | --- | --- |
| v2 accidentally replaces v1 | Existing v1 noIntent behavior would drift silently. | Keep policy version explicit and compare v1/v2 signatures. |
| v1 behavior drift | Feedback-aware blocked behavior is a stable contract. | Keep v1 regression scenarios green. |
| v0 behavior drift | v0 is the baseline for all later comparisons. | Preserve direct v0 fixture and hardening checks. |
| Reports diverge | Consumers may compare mismatched totals. | Define common report sections before adapters. |
| Metrics hide behavior drift | Optional fields can make failures invisible. | Add explicit boundary and policy-version metrics. |
| Policy starts reading World | This would collapse policy/tick separation. | Keep `policyWorldUsed=false` invariants. |
| Policy starts reading collision | Collision must stay in tick layer. | Keep `policyReadCollision=false` invariants. |
| Tick starts applying movement in read-only modes | Read-only scenarios would no longer be evidence-only. | Separate tick read-only and approved application reports. |
| Approved application mutates World | Lab-map-only movement would become gameplay mutation. | Assert terrain/world mutation flags. |
| Replay becomes gameplay loop | Fixed smokes could become autonomous behavior. | Keep fixed tick count and no unbounded loop checks. |
| Alternate hints become pathfinding | Local bounded hints could become search. | Assert no route, no graph search, and one-edge alternates. |
| Consolidation becomes behavior refactor | The phase could accidentally change policy semantics. | Make 4.26B signature comparison no-behavior-change. |
| Scenario outputs become nondeterministic | Replay and reports would stop being regression tools. | Compare stable digests. |
| Duplicate summaries disagree | Multiple summary structs can drift over time. | Plan adapters with explicit equivalence checks. |
| Path planning sneaks into consolidation | The next behavior step is tempting but out of scope. | Keep 4.27A docs-only and after consolidation. |

## Future Phase Breakdown

### Phase 4.26B — Agent Movement Policy Consolidation Fixture Docs/Adapters Smoke

Goal: add a minimal no-behavior-change adapter or report consolidation smoke.
It should run representative v0, v1, and v2 contexts and compare consolidated
signatures with existing direct policy outputs.

### Phase 4.26C — Policy Boundary Hardening

Goal: assert common policy boundary flags across v0, v1, and v2, including no
World, no collision read, no route following, no pathfinding, no replanning, no
avoidance, no reservation runtime, no memory, no goals, and no mutation.

### Phase 4.26D — Consolidated Replay Regression

Goal: produce one consolidated replay report that proves equivalence with
existing scenario digests without changing behavior.

### Phase 4.27A — Bounded Path Planning Plan Docs-Only

Goal: document a future path planning boundary after policy consolidation. This
phase should still implement no path planning.

## Recommended 4.26B Contract

`Phase 4.26B — Agent Movement Policy Consolidation Fixture Smoke`

Recommended contract:

- no behavior change;
- introduce consolidated docs/report adapter only if needed;
- run representative v0 contexts;
- run representative v1 contexts;
- run representative v2 contexts;
- compare signatures to existing direct policy outputs;
- prove no policy drift;
- prove v0/v1/v2 remain explicit and unchanged;
- no World read;
- no collision read;
- no tick mutation;
- no movement application unless comparing existing outputs read-only;
- write `agent_movement_policy_consolidation_report.json` if an adapter is
  introduced;
- no pathfinding;
- no replanning;
- no avoidance;
- no reservation runtime;
- no route following.

## Out Of Scope

- pathfinding;
- route planning;
- route following;
- replanning;
- avoidance;
- reservation runtime;
- memory;
- goals;
- learning/RL;
- LLM/Python;
- social/communication;
- physics;
- mining/construction/inventory;
- terrain mutation;
- World mutation;
- renderer/resources/shaders;
- registries/save-load/goldens;
- core entity movement;
- physical placeholder movement;
- autonomous gameplay loop.

## Phase 4.26B Implementation Status

Phase 4.26B implemented the first consolidation fixture smoke without changing
policy behavior.

Validated status:

- added `agent_movement_policy_consolidation_fixture_smoke`;
- added a fixture-only consolidated adapter/report layer;
- compared direct v0 policy output with `.baselineV0` consolidated output;
- compared direct v1 policy output with `.feedbackAwareV1` consolidated
  output;
- compared direct v2 policy output with `.alternateLocalHintV2` consolidated
  output;
- used eight deterministic contexts and three explicit policy versions;
- compared twenty-four direct signatures with twenty-four consolidated
  signatures;
- observed zero signature mismatches;
- preserved v0 behavior;
- preserved v1 behavior;
- kept v2 explicit opt-in and not global;
- detected no hidden activation;
- kept `maxAlternates = 2`;
- kept bounded alternate candidates deterministic;
- kept empty and unknown hints as noIntent;
- kept policy World/collision reads false;
- did not invoke tick live paths;
- did not apply movement;
- did not update memory or goals;
- did not perform pathfinding, replanning, avoidance, reservation runtime, or
  route following;
- did not mutate terrain or World.

Outputs produced:

- `agent_movement_policy_consolidation_report.json`;
- `agent_movement_policy_consolidation_invariant_report.json`;
- `agent_movement_policy_consolidation_decisions.json`;
- `agent_movement_policy_consolidation_signatures.json`;
- `agentMovementPolicyConsolidation*` metrics;
- `lab_agent_movement_policy_consolidation_recorded` event.

Limits:

- the scenario is a fixture-only adapter/report smoke;
- it does not consolidate runtime behavior;
- it does not introduce pathfinding, planning, route following, memory, goals,
  collision reads, World reads, movement application, or mutation.

Next step: Phase 4.26C — Policy Boundary Hardening.

## Phase 4.26C Implementation Status

Phase 4.26C implemented fixture-only hardening for the consolidated policy
boundary without changing v0, v1, or v2 behavior.

Validated status:

- added `agent_movement_policy_boundary_hardening_smoke`;
- reused the explicit consolidated adapter from 4.26B;
- compared direct v0 policy output with `.baselineV0` consolidated output;
- compared direct v1 policy output with `.feedbackAwareV1` consolidated
  output;
- compared direct v2 policy output with `.alternateLocalHintV2` consolidated
  output;
- used twenty-two deterministic hardening contexts;
- covered no feedback, approved feedback, moved feedback, all blocked feedback
  kinds, duplicate hints, multiple hints, empty hints, unknown hints, and
  `maxAlternates` 0, 1, 2, and 3;
- compared sixty-six direct signatures with sixty-six consolidated signatures;
- observed zero signature mismatches;
- preserved v0 behavior;
- preserved v1 behavior;
- kept v2 explicit opt-in and not global;
- detected no hidden activation;
- kept alternate candidates bounded, deterministic, and one-edge same-y;
- kept failed directions excluded;
- kept empty and unknown hints as noIntent;
- kept policy World/collision reads false;
- did not invoke tick live paths;
- did not apply movement or approved application;
- did not update memory or goals;
- did not perform pathfinding, replanning, avoidance, reservation runtime, or
  route following;
- did not mutate terrain or World.

Outputs produced:

- `agent_movement_policy_boundary_hardening_report.json`;
- `agent_movement_policy_boundary_hardening_invariant_report.json`;
- `agent_movement_policy_boundary_hardening_cases.json`;
- `agent_movement_policy_boundary_hardening_decisions.json`;
- `agent_movement_policy_boundary_hardening_signatures.json`;
- `agent_movement_policy_boundary_hardening_boundary.json`;
- `agentMovementPolicyBoundaryHardening*` metrics;
- `lab_agent_movement_policy_boundary_hardening_recorded` event.

Limits:

- the scenario is fixture-only;
- it does not consolidate runtime execution;
- it does not introduce pathfinding, planning, route following, memory, goals,
  collision reads, World reads, movement application, approved application, or
  mutation.

Next step: Phase 4.26D — Consolidated Replay Regression.

## Phase 4.26D Implementation Status

Phase 4.26D implemented a fixture-only consolidated replay regression for the
agent movement policy adapter. It keeps the replay at the policy/report layer:
no live tick collision, no approved application, and no movement mutation are
invoked.

Validated status:

- added `agent_movement_policy_consolidated_replay_regression_smoke`;
- ran three fixed replay ticks over six deterministic agents;
- evaluated three explicit policy versions on every tick;
- compared direct v0/v1/v2 signatures against consolidated signatures;
- compared fifty-four signatures with zero mismatches;
- preserved v0 behavior;
- preserved v1 behavior;
- kept v2 explicit opt-in and not global;
- detected no hidden activation;
- consumed feedback from tick N only at tick N+1;
- detected zero same-tick feedback consumption;
- detected zero future feedback consumption;
- detected zero cross-agent feedback leaks;
- ran two replay passes and produced identical digests;
- verified deterministic tick, agent, policy, decision, and signature ordering;
- kept policy World/collision reads false;
- kept fixture tick World/collision reads false;
- did not invoke tick live paths;
- did not apply movement or approved application;
- did not move core entities or physical placeholders;
- did not update memory or goals;
- did not perform pathfinding, replanning, avoidance, reservation runtime, or
  route following;
- did not mutate terrain or World.

Outputs produced:

- `agent_movement_policy_consolidated_replay_report.json`;
- `agent_movement_policy_consolidated_replay_invariant_report.json`;
- `agent_movement_policy_consolidated_replay_ticks.json`;
- `agent_movement_policy_consolidated_replay_feedback.json`;
- `agent_movement_policy_consolidated_replay_decisions.json`;
- `agent_movement_policy_consolidated_replay_signatures.json`;
- `agent_movement_policy_consolidated_replay_digest.json`;
- `agent_movement_policy_consolidated_replay_boundary.json`;
- `agentMovementPolicyConsolidatedReplay*` metrics;
- `lab_agent_movement_policy_consolidated_replay_recorded` event.

Limits:

- the replay is fixture-only and does not exercise live collision;
- it intentionally does not apply approved movements;
- it does not consolidate gameplay autonomy;
- it does not introduce pathfinding, route planning, route following, memory,
  goals, reservation runtime, or mutation.

Next step: Phase 4.27A — Bounded Path Planning Plan Docs-Only.
