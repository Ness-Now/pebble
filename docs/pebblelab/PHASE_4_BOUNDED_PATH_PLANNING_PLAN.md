# Phase 4 — Bounded Path Planning Plan

## Validated Starting Point

PebbleLab now has a deliberately layered movement stack:

- v0 baseline policy proposes one-step local intents from position, role, and
  local hints.
- v1 feedback-aware policy is opt-in, leaves no feedback, `moved`, and
  `approvedForMovement` at baseline, and converts blocked feedback to
  `noIntent`.
- v2 alternate local hint policy is opt-in, keeps v0/v1 unchanged, and can
  choose deterministic bounded local alternatives for blocked feedback.
- Feedback from tick N is consumed only at tick N+1.
- Approved movement application is lab-map-only.
- Consolidated policy fixtures compare direct and consolidated signatures.
- Boundary hardening keeps policy, tick, application, and replay responsibilities
  separate.
- Consolidated replay regression proves deterministic digest repeatability.
- Terrain and World mutation remain out of scope.

Recent validated scenarios:

- `agent_movement_policy_consolidation_fixture_smoke`
- `agent_movement_policy_boundary_hardening_smoke`
- `agent_movement_policy_consolidated_replay_regression_smoke`
- `alternate_local_hint_multi_tick_replay_smoke`
- `multi_tick_closed_loop_approved_application_smoke`
- `feedback_aware_intent_policy_hardening_smoke`

## Problem To Solve

Agents can propose a single local step, and v2 can choose a small deterministic
alternate local hint after blocked feedback. They cannot yet reason about a
short sequence of abstract steps.

Without guardrails, "path planning" can drift into global pathfinding, route
following, dynamic replanning, reservation runtime, memory/goals, or gameplay
autonomy. PebbleLab needs a minimal definition first: bounded, deterministic,
fixture-first, inspectable, and explicitly separate from execution.

## Definition Of Bounded Path Planning

Bounded path planning in PebbleLab means:

- produce a small abstract movement plan;
- use a fixed maximum length, for example 2 to 4 steps;
- operate first in a fixture world or abstract grid;
- remain deterministic;
- avoid unbounded global search;
- avoid live route following;
- avoid memory and goals;
- avoid reservation runtime;
- avoid mutation;
- avoid physical movement;
- avoid terrain and World mutation;
- avoid autonomous gameplay loops.

A bounded path plan is not movement execution.
A bounded path plan is not route following.
A bounded path plan is not navigation autonomy.
A bounded path plan is not a long-lived goal.

## Proposed Layer Placement

Policy layer:

- remains responsible for one-step intent proposals;
- still reads no World;
- still reads no live collision;
- still does not execute movement;
- remains versioned and opt-in.

Future planning layer:

- is optional and explicit opt-in;
- takes a fixture grid or abstract planning context;
- outputs a bounded list of one-edge steps;
- does not execute;
- does not mutate;
- does not reserve runtime cells;
- does not own feedback;
- does not own tick arbitration.

Tick layer:

- still owns conflict approval;
- still owns collision approval where live read-only modes allow collision;
- may consume only one proposed next step at first.

Approved application layer:

- still applies only an approved first step to lab position maps;
- does not blindly apply a whole route;
- preserves denied and `noIntent` agents.

Replay layer:

- must prove deterministic plan output;
- must prove stable digest output;
- must prove feedback N -> N+1 only;
- must prove no same-tick, future, or cross-agent leak.

## Policy Versioning Proposal

Future policy versions should remain explicit:

- v0: baseline one-step local hint.
- v1: feedback-aware `noIntent` on blocked feedback.
- v2: alternate local hint.
- future v3: bounded path planning proposal.

v3 must be:

- explicit opt-in;
- not global;
- not replacing v0, v1, or v2;
- fixture-first;
- bounded;
- deterministic;
- free of World/collision reads from policy;
- free of movement execution;
- free of hidden activation.

## Planning Context Proposal

Future docs-only type proposal:

`LabAgentBoundedPathPlanningContext`

Possible fields:

- `tick`
- `agentId`
- `start`
- `target` or `localObjective`
- `maxSteps`
- `localGrid` or `abstractOccupancy`
- `allowedDirections`
- `blockedDirections`
- `lastFeedback`
- `seed`
- `deterministicTieBreaker`
- boundary flags

This is only a documentation proposal. No Swift type is introduced in 4.27A.

## Planning Output Proposal

Future docs-only type proposal:

`LabAgentBoundedPathPlan`

Possible fields:

- `agentId`
- `tick`
- `start`
- `target`
- `maxSteps`
- `steps`
- `selectedFirstStep`
- `exhausted`
- `truncated`
- `noPathReason`
- `deterministicDigest`
- boundary flags

Constraints:

- steps are one-edge;
- steps are same-y initially;
- `steps.count <= maxSteps`;
- only the first step may be sent to tick;
- remaining steps are advisory only;
- there is no automatic following.

## Algorithm Boundary

Allowed later:

- fixed-depth deterministic search;
- tiny BFS over a fixture grid;
- fixed maximum node count;
- fixed maximum step count;
- deterministic tie-breakers;
- stable neighbor ordering;
- no heap nondeterminism;
- no global map scan;
- no chunk or World scan.

Forbidden:

- unbounded A*;
- unbounded BFS;
- Dijkstra over live World;
- live World queries;
- dynamic replanning;
- reservation table runtime;
- long-route following;
- navigation meshes;
- physics-aware navigation;
- terrain mutation;
- mining or building to make a path;
- memory or goals;
- RL, LLM, or Python.

## Safety And Scope Boundaries

Bounded path planning must not become:

- gameplay autonomy;
- a player-like bot;
- mining or building;
- inventory use;
- combat;
- social behavior or communication;
- economic behavior;
- persistent goals;
- cross-tick route commitment in the first implementation;
- hidden activation by existing scenarios.

## Future Scenario Plan

### Phase 4.27B — Bounded Path Planning Fixture Smoke

- docs-backed first fixture;
- abstract grid only;
- fixed `maxSteps`;
- deterministic path plan;
- no World;
- no collision;
- no tick;
- no approved application.

### Phase 4.27C — Bounded Path Planning Hardening

- blocked cases;
- empty cases;
- no-path cases;
- duplicate target cases;
- `maxSteps` 0, 1, 2, 3, and 4;
- deterministic tie-break;
- bounded node count.

### Phase 4.27D — Planning To Tick First-Step Handoff

- only first step sent to existing tick;
- no route following;
- tick still approves or denies one step;
- remaining steps are advisory.

### Phase 4.27E — Planning Approved Application Lab-Map Only

- approved first step only;
- route remains advisory;
- movement application remains lab-map-only;
- denied and `noIntent` agents are preserved.

### Phase 4.27F — Planning Multi-Tick Replay Regression

- deterministic replan each tick from current context;
- no persistent route following;
- feedback N -> N+1;
- digest repeatability.

## Future Invariants

1. v0 behavior remains unchanged.
2. v1 behavior remains unchanged.
3. v2 behavior remains unchanged.
4. v3 is explicit opt-in.
5. v3 is never enabled by default.
6. v3 does not replace v0 globally.
7. v3 does not replace v1 globally.
8. v3 does not replace v2 globally.
9. Hidden policy activation is false.
10. Policy mode is recorded in reports.
11. Policy mode is recorded in metrics.
12. Policy mode is recorded in events.
13. Planning contexts exist.
14. Planning contexts are sorted by stable `agentId`.
15. Planning contexts contain `tick`.
16. Planning contexts contain `agentId`.
17. Planning contexts contain `start`.
18. Planning contexts contain `maxSteps`.
19. `maxSteps` is bounded.
20. `maxSteps` never exceeds the scenario contract.
21. `maxNodes` is bounded.
22. `maxNodes` never exceeds the scenario contract.
23. Neighbor order is deterministic.
24. Tie-break order is deterministic.
25. Repeated inputs produce the same plan.
26. Repeated inputs produce the same digest.
27. Plans are sorted by stable `agentId`.
28. Plan steps are one-edge.
29. Plan steps are same-y initially.
30. Plan length is less than or equal to `maxSteps`.
31. Empty plan is represented explicitly.
32. No-path reason is represented explicitly.
33. Truncated plan is represented explicitly.
34. Exhausted search is represented explicitly.
35. First step is represented explicitly.
36. First-step handoff is the only tick handoff in 4.27D.
37. Remaining steps are advisory only.
38. Remaining steps are not auto-executed.
39. No path execution occurs in 4.27B.
40. No tick invocation occurs in 4.27B.
41. No collision read occurs in 4.27B.
42. No World read occurs in 4.27B.
43. No live World read occurs from policy.
44. No collision read occurs from policy.
45. No chunk scan occurs from policy.
46. No global map scan occurs from policy.
47. No unbounded BFS occurs.
48. No unbounded A* occurs.
49. No Dijkstra over live World occurs.
50. No navigation mesh is used.
51. No physics-aware navigation is used.
52. No dynamic replanning occurs.
53. No reservation runtime occurs.
54. No reservation table is created.
55. No route following occurs.
56. No persistent route commitment occurs.
57. No long route is stored.
58. No memory is updated.
59. No goals are updated.
60. No learning occurs.
61. No reward update occurs.
62. No RL is called.
63. No LLM is called.
64. No Python planner is called.
65. No social behavior is introduced.
66. No communication is introduced.
67. No combat behavior is introduced.
68. No inventory behavior is introduced.
69. No mining behavior is introduced.
70. No building behavior is introduced.
71. No terrain mutation occurs.
72. No World mutation occurs.
73. No `World.setBlock` call occurs.
74. No `Chunk.set` call occurs.
75. No physical placeholder movement occurs.
76. No core entity movement occurs.
77. No gameplay movement autonomy occurs.
78. Approved application applies only the approved first step.
79. Approved application remains lab-map-only.
80. Denied agents are preserved.
81. `noIntent` agents are preserved.
82. Tick owns conflict arbitration.
83. Tick owns live collision read where allowed.
84. Planner does not arbitrate multi-agent conflicts.
85. Planner does not read other agents directly in the first smoke.
86. Planner does not consume feedback directly.
87. Feedback N is consumed only at N+1.
88. Same-tick feedback leak count is zero.
89. Future feedback leak count is zero.
90. Cross-agent feedback leak count is zero.
91. Replay tick order is deterministic.
92. Replay agent order is deterministic.
93. Replay plan order is deterministic.
94. Replay event order is deterministic.
95. Replay digest is stable.
96. Report is written.
97. Invariant report is written.
98. Cases JSON is written.
99. Plans JSON is written.
100. Digest JSON is written.
101. Metrics are written.
102. Event is written.
103. 4.26 consolidation fixture remains green.
104. 4.26 boundary hardening remains green.
105. 4.26 consolidated replay remains green.
106. Alternate local hint replay remains green.
107. Multi-tick approved application remains green.
108. Feedback-aware policy hardening remains green.
109. Success contract is explicit.
110. Success contract fails on any boundary violation.

## Risk Table

| Risk | Why it matters | Mitigation |
| --- | --- | --- |
| Bounded planning becomes unbounded pathfinding | It would change the scope and cost model. | Fixed `maxSteps`, fixed `maxNodes`, and invariant checks. |
| Fixture grid becomes live World scan | Policy would cross the World boundary. | Fixture-first context and no World-read boundary flags. |
| Path plan becomes route following | Planning would become execution. | First-step-only handoff and advisory remaining steps. |
| First-step handoff becomes full-route execution | Tick/application would be bypassed. | Tick consumes only one step in early phases. |
| v3 replaces v2 | Existing scenarios could drift silently. | Explicit opt-in and v0/v1/v2 regression checks. |
| Hidden activation in existing scenarios | Users could get new behavior accidentally. | Policy mode must be explicit in reports, metrics, and events. |
| Dynamic replanning sneaks in | Multi-tick autonomy would arrive too early. | Replan only through explicit future replay contracts. |
| Reservation runtime sneaks in | Planning could become multi-agent scheduling. | Reservation boundary flags stay false. |
| Planning becomes memory/goals | It would create persistent autonomy. | No memory/goals invariants and report fields. |
| Nondeterministic tie-break | Replay digests would drift. | Fixed neighbor order and deterministic tie-breaker. |
| Digest instability | Regression evidence becomes weak. | Repeatability checks compare identical inputs. |
| Path planning mutates terrain | It would violate lab-map-only boundaries. | No terrain/World mutation checks. |
| Path planning creates physical movement | It would bypass approved application. | No physical/core movement checks. |
| Future reports hide boundary drift | A passing scenario could mask behavior changes. | Boundary fields must be first-class report/metrics/event data. |

## Recommended 4.27B Contract

`Phase 4.27B — Bounded Path Planning Fixture Smoke`

Contract:

- fixture-only;
- no World;
- no collision;
- no tick;
- no movement application;
- no lab position mutation;
- no route following;
- no memory/goals;
- no reservation runtime;
- no terrain/world mutation;
- no v0/v1/v2 behavior change;
- optional future v3 planner must be explicit opt-in;
- small abstract grid;
- fixed `maxSteps`;
- fixed `maxNodes`;
- deterministic output;
- report, invariant report, metrics, and event;
- no replay yet.

Recommended outputs for 4.27B:

- `bounded_path_planning_fixture_report.json`
- `bounded_path_planning_fixture_invariant_report.json`
- `bounded_path_planning_fixture_cases.json`
- `bounded_path_planning_fixture_plans.json`
- `bounded_path_planning_fixture_digest.json`
- `metrics.json`
- `events.ndjson`

## Out Of Scope

- live world navigation;
- route following;
- physical movement;
- core entity movement;
- terrain mutation;
- mining/building;
- inventory;
- combat;
- social behavior;
- goals;
- memory;
- RL/LLM/Python;
- unbounded pathfinding;
- reservations;
- dynamic replanning;
- performance optimization;
- renderer/shaders/resources;
- save/load/goldens.

## Phase 4.27B Implementation Status

Status: implemented and validated.

Phase 4.27B added `bounded_path_planning_fixture_smoke` as the first
fixture-only bounded path planning scenario. The implementation uses an
abstract grid supplied by fixture contexts, fixed `maxSteps`, fixed `maxNodes`,
and a tiny deterministic bounded search. It does not read `World`, read live
collision, invoke tick movement, call approved application, apply movement,
mutate lab position maps, or perform route following.

The planner records neighbor order as `move_north`, `move_east`, `move_south`,
`move_west` and records a stable tie-break label. Cases cover direct one-step
planning, two-step planning, deterministic detour, no path, max steps too
short, max nodes too small, start equals target, negative coordinates, and
same-y-only behavior.

Digest repeatability is validated by running the same fixture inputs twice and
comparing aggregate digests. v0, v1, and v2 remain unchanged; v3 is represented
only as `boundedPathPlanningV3FixtureOptIn`; v3 is not global; hidden activation
is false.

Outputs produced:

- `bounded_path_planning_fixture_report.json`
- `bounded_path_planning_fixture_invariant_report.json`
- `bounded_path_planning_fixture_cases.json`
- `bounded_path_planning_fixture_plans.json`
- `bounded_path_planning_fixture_digest.json`
- `metrics.json`
- `events.ndjson`

Limits remain explicit: no World/collision/tick/movement/application, no route
following, no memory/goals, no reservation runtime, no live pathfinding, no
unbounded search, and no terrain/World mutation.

Next step: Phase 4.27C — Bounded Path Planning Hardening.

## Phase 4.27C Implementation Status

Status: implemented and validated.

Phase 4.27C added `bounded_path_planning_hardening_smoke` as a fixture-only
hardening scenario for the bounded planner. It reuses the abstract grid planner
from 4.27B and does not add live behavior.

Coverage:

- `maxSteps` 0, 1, 2, 3, and 4;
- `maxNodes` 1, 2, and 32;
- start surrounded by blocked cells;
- target surrounded by blocked cells;
- blocked target cell;
- blocked direction `move_east`;
- allowed direction subset via north/south-only context;
- duplicate blocked cells;
- duplicate identical inputs with equal digests;
- negative-coordinate detour;
- same-y-only vertical escape rejection;
- equal-shortest-path deterministic tie-break.

The hardening report verifies all plans remain within `maxSteps` and `maxNodes`,
all emitted steps are one-edge and same-y, blocked directions are not used, and
abstract blocked cells are not stepped into. Digest repeatability is checked by
repeating the same fixtures and comparing aggregate digests.

v3 remains fixture opt-in and not global. v0, v1, and v2 remain unchanged.
Hidden activation is false.

No World/collision/tick/movement/application behavior is introduced. No route
following, memory/goals, reservation runtime, live pathfinding, unbounded
search, dynamic replanning, core entity movement, physical placeholder movement,
terrain mutation, or World mutation is used.

Outputs produced:

- `bounded_path_planning_hardening_report.json`
- `bounded_path_planning_hardening_invariant_report.json`
- `bounded_path_planning_hardening_cases.json`
- `bounded_path_planning_hardening_plans.json`
- `bounded_path_planning_hardening_digest.json`
- `bounded_path_planning_hardening_boundary.json`
- `metrics.json`
- `events.ndjson`

Limits remain explicit: route following and live execution stay out of scope.

Next step: Phase 4.27D — Planning To Tick First-Step Handoff.

## Phase 4.27D Implementation Status

Status: implemented and validated.

Phase 4.27D added `bounded_path_planning_to_tick_first_step_smoke` as the
first bridge from bounded fixture planning into the existing movement tick
fixture. The bridge is intentionally first-step-only: `selectedFirstStep` is
converted into a `LabAgentMoveIntent`, while any remaining plan steps stay
advisory-only and are not sent to tick.

The scenario covers:

- direct one-step handoff approved by tick fixture;
- two-step plan where only step 0 is sent;
- detour plan where only the deterministic first step is sent;
- no-path plan with no movement intent;
- start-equals-target zero-step plan with no movement intent;
- same-destination conflict resolved by tick fixture;
- source mismatch denied by existing tick fixture behavior;
- stale intent denied by existing tick fixture behavior.

The tick layer remains responsible for one-edge arbitration. Planning does not
arbitrate conflicts, does not read World, does not read collision, does not
apply movement, and does not mutate lab maps. Tick mode is fixture-only:
`tickReadCollision` and `tickWorldReadOnlyUsed` are false.

Outputs produced:

- `bounded_path_planning_to_tick_first_step_report.json`
- `bounded_path_planning_to_tick_first_step_invariant_report.json`
- `bounded_path_planning_to_tick_first_step_cases.json`
- `bounded_path_planning_to_tick_first_step_plans.json`
- `bounded_path_planning_to_tick_first_step_handoff.json`
- `bounded_path_planning_to_tick_first_step_tick.json`
- `bounded_path_planning_to_tick_first_step_digest.json`
- `bounded_path_planning_to_tick_first_step_boundary.json`
- `metrics.json`
- `events.ndjson`

Limits remain explicit: no live collision, no World use, no route following,
no full-route execution, no movement application, no lab position map mutation,
no memory/goals, no reservation runtime, and no terrain/World mutation.

Next step: Phase 4.27E — Planning Approved Application Lab-Map Only.

## Phase 4.27E Implementation Status

Status: implemented and validated.

Phase 4.27E added `bounded_path_planning_approved_application_smoke` as the
first lab-map-only approved application scenario for bounded path planning. It
builds on 4.27D: bounded fixture plans produce selected first-step handoffs,
the existing tick fixture approves or denies those one-edge intents, and the
application layer mutates only lab abstract and physical position maps for
approved first steps.

The scenario covers:

- direct one-step approved application;
- two-step plan where only the first step is applied;
- detour plan where only the first step is applied;
- no-path plan preserved unchanged;
- start-equals-target zero-step plan preserved unchanged;
- same-destination conflict denied by tick and preserved;
- source mismatch denied by tick and preserved;
- stale intent denied by tick and preserved.

Boundary rules remain explicit. Advisory path steps are not sent to tick and
are not applied. There is no full-route execution, no route following, no live
collision read, no `World` use, no core entity movement, no physical
placeholder movement, no memory/goals, no reservation runtime, and no
terrain/World mutation. The only mutation is the controlled lab position map
update for tick-approved first steps, with abstract and physical maps kept in
sync.

Outputs produced:

- `bounded_path_planning_approved_application_report.json`
- `bounded_path_planning_approved_application_invariant_report.json`
- `bounded_path_planning_approved_application_cases.json`
- `bounded_path_planning_approved_application_plans.json`
- `bounded_path_planning_approved_application_handoff.json`
- `bounded_path_planning_approved_application_tick.json`
- `bounded_path_planning_approved_application_application.json`
- `bounded_path_planning_approved_application_positions.json`
- `bounded_path_planning_approved_application_digest.json`
- `bounded_path_planning_approved_application_boundary.json`
- `metrics.json`
- `events.ndjson`

Digest repeatability is checked by repeating the same fixture inputs and
comparing aggregate planning, tick, application, and position-map signatures.
v0, v1, and v2 remain unchanged. v3 remains fixture opt-in and not global.
Hidden activation is false.

Next step: Phase 4.27F — Bounded Path Planning Multi-Tick Replay Regression.
