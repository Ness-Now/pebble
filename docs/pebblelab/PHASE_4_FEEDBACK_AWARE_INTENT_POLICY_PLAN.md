# Phase 4 - Feedback-Aware Intent Policy Plan

## 1. Validated Starting Point

Phase 4.19 validated the multi-agent movement primitives: fixture arbitration,
fixture hardening, live read-only collision intent evidence, approved physical
movement, and live movement hardening.

Phase 4.20 validated the tick-level movement contract: fixture tick input and
output, live read-only tick evidence, approved tick application, tick hardening,
structured feedback, and the separation between arbitration, collision reads,
movement application, and feedback emission.

Phase 4.21 validated agent intent production: fixture production, hardening,
intent-to-tick fixture integration, intent-to-tick live read-only integration,
and intent-to-tick approved application. Agents can now produce candidate
`LabAgentMoveIntent` values through deterministic fixture policies, but those
policies still do not pathfind, replan, reserve, avoid, learn, mutate memory,
or mutate goals.

Phase 4.22A-E validated feedback consumption and injection. Feedback can be
observed, normalized, hardened, and carried into `LabAgentIntentContext` as
`lastFeedback`. The current policy v0 intentionally ignores `lastFeedback`.
`behaviorChangedByFeedback = false` and `feedbackUsedForDecision = false` are
part of the validated contract through Phase 4.22E.

## 2. Problem To Solve

Feedback is now visible to the agent intent layer, but visibility is not yet
behavior. The next problem is deciding how a future policy may react to
structured feedback without accidentally becoming a planner, scheduler,
collision system, memory system, learning loop, social behavior layer, or
multi-tick autonomy loop.

The first feedback-aware policy must be tiny, deterministic, inspectable, and
bounded. It should make explicit, reportable changes only for known feedback
kinds. It must be easy to compare against the current v0 baseline.

## 3. Policy Boundary

The future policy may:

- read `LabAgentIntentContext.lastFeedback`;
- read the existing position, role, and local hints;
- produce at most one proposal per agent;
- keep the baseline v0 decision;
- produce `noIntent`;
- choose a deterministic, bounded alternative from a fixed local hint list in
  later phases;
- process agents in stable `agentId` order;
- write reports, metrics, events, and decision JSON.

The future policy must not:

- read `World`;
- read live collision;
- apply movement;
- modify memory;
- modify goals;
- pathfind;
- replan;
- avoid;
- use reservation runtime;
- learn;
- update rewards;
- call LLM/RL/Python;
- create social behavior;
- communicate;
- run an autonomous multi-tick loop;
- mutate terrain or world state.

## 4. Feedback Reaction Table

| Feedback kind | Meaning | v1 allowed reaction | Forbidden reaction | First smoke expectation |
| --- | --- | --- | --- | --- |
| `moved` | The previous move was applied. | Keep normal v0 behavior or continue deterministic hint. | Reward learning, memory mutation, suppress all future movement. | Baseline behavior remains valid and does not break proposal production. |
| `approvedForMovement` | The move was approved at decision layer but not applied. | Treat as decision-layer success only. | Assume physical movement happened. | Continue baseline behavior. |
| `blockedByCollision` | Destination was non-occupable. | Bounded wait/noIntent, or later a deterministic next local hint from a fixed list. | Pathfinding, collision read, dynamic replanning. | Recommended 4.23A behavior: `noIntent`. |
| `blockedByAgentConflict` | Another agent won an arbitration conflict. | Bounded wait/noIntent. | Communication, negotiation, social model, reservation table. | `noIntent`. |
| `blockedBySourceMismatch` | Intent source did not match current position. | `noIntent` and surface stale state. | Memory repair, teleport/sync correction. | `noIntent`. |
| `blockedByDivergence` | Abstract and physical positions diverged. | `noIntent` and surface sync issue. | Self-repair loop, movement correction. | `noIntent`. |
| `blockedByStaleIntent` | Intent was outdated. | `noIntent`, or later regenerate once from current context if deterministic. | Autonomous retry loop. | `noIntent`. |
| `blockedByInvalidEdge` | Policy or hint produced an invalid edge. | `noIntent` and surface invalid hint. | Hide policy bug, learn around it. | `noIntent`. |
| `blockedByMaxAgents` | Tick capacity bound was exceeded. | `noIntent` or wait. | Scheduler, reservation runtime. | `noIntent`. |

## 5. Proposed Policy Name

The future policy should be named:

```swift
produceAgentIntentProposalFeedbackAwareV1
```

The existing v0 policy remains unchanged. Feedback-aware v1 is opt-in, used
only by explicit Phase 4.23 scenarios, and must not replace existing v0
fixture, hardening, or integration scenarios.

## 6. Proposed Future Types

```swift
enum LabAgentIntentFeedbackPolicyMode: String, Codable {
    case baselineV0
    case feedbackAwareV1
}

struct LabAgentIntentFeedbackPolicyDecision: Codable {
    let agentId: String
    let tick: Int
    let policyMode: LabAgentIntentFeedbackPolicyMode
    let lastFeedbackKind: LabMovementFeedbackKind?
    let baselineDecision: LabAgentIntentDecision
    let feedbackAwareDecision: LabAgentIntentDecision
    let feedbackReaction: String
    let behaviorChanged: Bool
    let reason: String
}

struct LabAgentIntentFeedbackAwarePolicySummary: Codable {
    let contexts: Int
    let contextsWithFeedback: Int
    let contextsWithoutFeedback: Int
    let proposals: Int
    let acceptedIntents: Int
    let rejectedProposals: Int
    let noIntent: Int
    let feedbackReactions: Int
    let behaviorChangedByFeedback: Bool
    let collisionRead: Bool
    let movementApplied: Bool
    let memoryUpdated: Bool
    let goalChanged: Bool
    let pathfindingPerformed: Bool
    let replanningPerformed: Bool
    let avoidancePerformed: Bool
    let reservationRuntimeUsed: Bool
    let worldUsed: Bool
    let mutationPerformed: Bool
    let success: Bool
}
```

These types are planning artifacts only in Phase 4.22F.

## 7. Proposed v1 Rules

Inputs:

- tick;
- agent id;
- position;
- role;
- local hints;
- optional `lastFeedback`.

Algorithm:

1. Compute the baseline v0 proposal first.
2. If no feedback exists, return the baseline.
3. If feedback is `moved`, return the baseline.
4. If feedback is `approvedForMovement`, return the baseline.
5. If feedback is `blockedByCollision`, return `noIntent` for 4.23A.
6. If feedback is `blockedByAgentConflict`, return `noIntent`.
7. If feedback is `blockedBySourceMismatch`, return `noIntent`.
8. If feedback is `blockedByDivergence`, return `noIntent`.
9. If feedback is `blockedByStaleIntent`, return `noIntent`.
10. If feedback is `blockedByInvalidEdge`, return `noIntent`.
11. If feedback is `blockedByMaxAgents`, return `noIntent`.
12. Never call collision, World, pathfinding, replanning, reservation runtime,
    memory mutation, or goal mutation.
13. Produce an explicit reason string for every feedback reaction.

Recommendation for Phase 4.23A: use the ultra-simple rule set where blocked
feedback becomes `noIntent`. Do not add alternative directional hints in
4.23A. Deterministic alternate direction experiments can come in 4.23B or
later.

## 8. Future Scenario Sequence

### Phase 4.23A - Bounded Feedback-Aware Intent Policy Fixture Smoke

- Opt-in v1 policy.
- `blockedByCollision` -> `noIntent`.
- `blockedByAgentConflict` -> `noIntent`.
- `moved` and `approvedForMovement` -> baseline unchanged.
- No World.
- No movement.
- No pathfinding or replanning.
- Compare against v0 baseline.
- Expect `behaviorChangedByFeedback = true` only for blocked cases.

### Phase 4.23B - Feedback-Aware Intent Policy Hardening

- All feedback kinds.
- Missing feedback.
- Malformed feedback.
- Duplicate feedback selection.
- Invalid edge feedback.
- Deterministic ordering.
- Repeatability.
- No World or movement.

### Phase 4.23C - Feedback-Aware Intent To Tick Fixture Smoke

- Feed v1 proposals into fixture tick.
- Still no live collision.
- Verify `noIntent` reduces conflicts in the fixture handoff.

### Phase 4.23D - Feedback-Aware Intent To Tick Live Read-Only Smoke

- Live collision read only at the tick layer.
- Policy still does not read World.
- No movement application.

### Phase 4.23E - Feedback-Aware Intent To Tick Approved Application Smoke

- Approved moves can apply.
- Policy only proposes.
- Tick handles collision and application.

### Phase 4.24A - Multi-Tick Closed Loop Planning Docs-Only

- Document the multi-tick closed loop before implementing it.

## 9. Future Outputs

- `feedback_aware_intent_policy_report.json`;
- `feedback_aware_intent_policy_invariant_report.json`;
- `feedback_aware_intent_policy_decisions.json`;
- `metrics.json`;
- `events.ndjson`.

## 10. Future Metrics

- `feedbackAwareIntentPolicyContexts`;
- `feedbackAwareIntentPolicyContextsWithFeedback`;
- `feedbackAwareIntentPolicyContextsWithoutFeedback`;
- `feedbackAwareIntentPolicyProposals`;
- `feedbackAwareIntentPolicyAcceptedIntents`;
- `feedbackAwareIntentPolicyRejectedProposals`;
- `feedbackAwareIntentPolicyNoIntent`;
- `feedbackAwareIntentPolicyFeedbackReactions`;
- `feedbackAwareIntentPolicyBehaviorChangedByFeedback`;
- `feedbackAwareIntentPolicyMovedBaselineKept`;
- `feedbackAwareIntentPolicyApprovedForMovementBaselineKept`;
- `feedbackAwareIntentPolicyBlockedByCollisionNoIntent`;
- `feedbackAwareIntentPolicyBlockedByAgentConflictNoIntent`;
- `feedbackAwareIntentPolicyBlockedBySourceMismatchNoIntent`;
- `feedbackAwareIntentPolicyBlockedByDivergenceNoIntent`;
- `feedbackAwareIntentPolicyBlockedByStaleIntentNoIntent`;
- `feedbackAwareIntentPolicyBlockedByInvalidEdgeNoIntent`;
- `feedbackAwareIntentPolicyBlockedByMaxAgentsNoIntent`;
- `feedbackAwareIntentPolicyCollisionRead`;
- `feedbackAwareIntentPolicyMovementApplied`;
- `feedbackAwareIntentPolicyMemoryUpdated`;
- `feedbackAwareIntentPolicyGoalChanged`;
- `feedbackAwareIntentPolicyPathfindingPerformed`;
- `feedbackAwareIntentPolicyReplanningPerformed`;
- `feedbackAwareIntentPolicyAvoidancePerformed`;
- `feedbackAwareIntentPolicyReservationRuntimeUsed`;
- `feedbackAwareIntentPolicyWorldUsed`;
- `feedbackAwareIntentPolicyMutationPerformed`;
- `feedbackAwareIntentPolicySuccess`.

## 11. Future Event

Event name:

```text
lab_feedback_aware_intent_policy_recorded
```

Fields:

- tick;
- policyMode;
- contexts;
- contextsWithFeedback;
- contextsWithoutFeedback;
- proposals;
- acceptedIntents;
- rejectedProposals;
- noIntent;
- feedbackReactions;
- behaviorChangedByFeedback;
- movedBaselineKept;
- approvedForMovementBaselineKept;
- blockedByCollisionNoIntent;
- blockedByAgentConflictNoIntent;
- blockedBySourceMismatchNoIntent;
- blockedByDivergenceNoIntent;
- blockedByStaleIntentNoIntent;
- blockedByInvalidEdgeNoIntent;
- blockedByMaxAgentsNoIntent;
- collisionRead;
- movementApplied;
- memoryUpdated;
- goalChanged;
- pathfindingPerformed;
- replanningPerformed;
- avoidancePerformed;
- reservationRuntimeUsed;
- worldUsed;
- mutationPerformed;
- success.

## 12. Future Invariants

1. `v0_remains_unchanged`;
2. `v1_is_opt_in`;
3. `contexts_exist`;
4. `contexts_sorted_by_agent_id`;
5. `proposals_exist`;
6. `proposals_sorted_by_agent_id`;
7. `baseline_computed`;
8. `no_feedback_returns_baseline`;
9. `moved_returns_baseline`;
10. `approved_for_movement_returns_baseline`;
11. `blocked_by_collision_produces_no_intent_in_4_23a`;
12. `blocked_by_agent_conflict_produces_no_intent`;
13. `blocked_by_source_mismatch_produces_no_intent`;
14. `blocked_by_divergence_produces_no_intent`;
15. `blocked_by_stale_intent_produces_no_intent`;
16. `blocked_by_invalid_edge_produces_no_intent`;
17. `blocked_by_max_agents_produces_no_intent`;
18. `feedback_reactions_counted`;
19. `behavior_changed_by_feedback_only_for_intended_blocked_cases`;
20. `feedback_used_for_decision_only_in_v1_scenarios`;
21. `moved_baseline_kept_counted`;
22. `approved_for_movement_baseline_kept_counted`;
23. `blocked_by_collision_no_intent_counted`;
24. `blocked_by_agent_conflict_no_intent_counted`;
25. `blocked_by_source_mismatch_no_intent_counted`;
26. `blocked_by_divergence_no_intent_counted`;
27. `blocked_by_stale_intent_no_intent_counted`;
28. `blocked_by_invalid_edge_no_intent_counted`;
29. `blocked_by_max_agents_no_intent_counted`;
30. `no_collision_read`;
31. `no_world_used`;
32. `no_movement_application`;
33. `no_memory_update`;
34. `no_goal_change`;
35. `no_pathfinding`;
36. `no_replanning`;
37. `no_avoidance`;
38. `no_reservation_runtime`;
39. `no_learning`;
40. `no_reward_update`;
41. `no_llm_rl_python`;
42. `no_social_behavior`;
43. `no_communication`;
44. `no_terrain_mutation`;
45. `no_world_mutation`;
46. `no_tick_movement_invoked_in_pure_policy_smoke`;
47. `prior_v0_fixture_remains_green`;
48. `feedback_to_context_hardening_remains_green`;
49. `feedback_consumption_hardening_remains_green`;
50. `report_written`;
51. `decisions_json_written`;
52. `metrics_written`;
53. `event_written`;
54. `success_contract_respected`.

## 13. Explicit Out Of Scope

- pathfinding;
- dynamic replanning;
- avoidance;
- reservation runtime;
- social coordination;
- communication;
- learning;
- reward updates;
- RL;
- LLM/Python;
- memory mutation;
- goal mutation;
- live collision reads;
- movement application;
- World access;
- terrain/world mutation;
- inventory, mining, or construction;
- autonomous multi-tick loop;
- replacing v0 globally.

## 14. Risk Table

| Risk | Why it matters | Mitigation |
| --- | --- | --- |
| v1 silently replaces v0 | Existing v0 fixture contracts would lose their baseline meaning. | Make v1 opt-in and keep v0 scenarios unchanged. |
| Feedback policy becomes pathfinding | It would skip the planned pathfinding boundary. | 4.23A only allows baseline or `noIntent`. |
| `blockedByCollision` causes hidden collision reads | Policy would invade tick collision ownership. | Invariants require no collision read and no World. |
| `blockedByAgentConflict` becomes social behavior | Coordination is a separate future domain. | Allow only bounded wait/noIntent. |
| `moved` suppresses all future motion | It could accidentally freeze agents. | Require moved to keep baseline in the first smoke. |
| Invalid edge feedback hides policy bugs | Invalid policy output should remain visible. | Count invalid feedback reactions and keep reports explicit. |
| Max agents becomes scheduler/reservation | Scheduling and reservation runtime are out of scope. | Map `blockedByMaxAgents` to noIntent only. |
| Source mismatch/divergence causes repair loop | Repair is not a policy decision. | Surface issue with noIntent, no memory/position mutation. |
| Nondeterministic alternate choice | Results would be hard to debug. | Delay alternates; later use fixed hint order only. |
| Metrics drift | Behavior changes could be hidden. | Require decisions JSON and explicit reaction counters. |
| Reports hide behavior changes | Silent adaptation undermines reviewability. | Compare v1 against v0 baseline in every scenario. |

## 15. Recommended 4.23A Contract

Phase 4.23A should implement:

- opt-in `produceAgentIntentProposalFeedbackAwareV1`;
- unchanged v0 policy;
- no feedback -> baseline;
- `moved` -> baseline;
- `approvedForMovement` -> baseline;
- `blockedByCollision` -> `noIntent`;
- `blockedByAgentConflict` -> `noIntent`;
- `blockedBySourceMismatch` -> `noIntent`;
- `blockedByDivergence` -> `noIntent`;
- `blockedByStaleIntent` -> `noIntent`;
- `blockedByInvalidEdge` -> `noIntent`;
- `blockedByMaxAgents` -> `noIntent`;
- comparison with v0 baseline;
- `behaviorChangedByFeedback = true` only for blocked feedback cases;
- no World, collision read, movement, memory update, goal change,
  pathfinding, replanning, avoidance, reservation runtime, terrain mutation,
  or world mutation;
- report, invariant report, decisions JSON, metrics, and aggregate event.

## 16. Success Definition

Phase 4.22F succeeds when:

- `PHASE_4_FEEDBACK_AWARE_INTENT_POLICY_PLAN.md` exists;
- `CHANGELOG.md` is updated;
- `DEV_JOURNAL.md` is updated;
- `ROADMAP.md` is updated;
- `PHASE_4_FEEDBACK_CONSUMPTION_PLAN.md` cross-links this plan;
- no Swift files are modified;
- no PebbleCore, renderer, shader, resource, registry, save/load, or golden
  files are modified;
- `swift build` passes;
- `swift run -c release pebsmoke` passes;
- `git diff --check` passes;
- a single documentation commit is created.

## Phase 4.23A Implementation Status

Status: implemented and validated.

Phase 4.23A adds the opt-in `produceAgentIntentProposalFeedbackAwareV1` policy
and the fixture-only scenario `feedback_aware_intent_policy_fixture_smoke`.
The original v0 policy remains unchanged and is still used by existing v0
smokes.

The fixture computes baseline v0 proposals first, then applies v1. No
feedback, `moved`, and `approvedForMovement` return the baseline proposal.
`blockedByCollision`, `blockedByAgentConflict`, `blockedBySourceMismatch`,
`blockedByDivergence`, `blockedByStaleIntent`, `blockedByInvalidEdge`, and
`blockedByMaxAgents` return explicit `noIntent` proposals. The
`blockedByInvalidEdge` reaction keeps an explicit
`feedback_blocked_by_invalid_edge_no_intent` reason.

Validated totals:

- `contexts = 10`;
- `contextsWithFeedback = 9`;
- `contextsWithoutFeedback = 1`;
- `baselineProposals = 10`;
- `feedbackAwareProposals = 10`;
- `acceptedIntents = 3`;
- `rejectedProposals = 7`;
- `noIntent = 7`;
- `invalidOneEdgeProposals = 0`;
- `feedbackReactions = 10`;
- `behaviorChangedByFeedback = true`;
- `behaviorChangedCount = 7`.

Outputs produced:

- `feedback_aware_intent_policy_fixture_report.json`;
- `feedback_aware_intent_policy_fixture_invariant_report.json`;
- `feedback_aware_intent_policy_decisions.json`;
- `feedbackAwareIntentPolicyFixture*` metrics;
- aggregate event `lab_feedback_aware_intent_policy_fixture_recorded`.

Limits remain explicit: no tick movement, no live collision, no World, no
movement application, no memory update, no goal change, no pathfinding, no
replanning, no avoidance, no reservation runtime, no learning, no social
behavior, no communication, and no terrain/world mutation.

Next recommended step: Phase 4.23B - Feedback-Aware Intent Policy Hardening.

## Phase 4.23B Implementation Status

Status: implemented and validated.

Phase 4.23B adds `feedback_aware_intent_policy_hardening_smoke`, a
fixture-only hardening scenario for the opt-in feedback-aware v1 policy. The
v0 policy remains unchanged and is not replaced globally.

Validated hardening cases:

- baseline fixture remains green;
- no feedback returns baseline;
- `moved` returns baseline;
- `approvedForMovement` returns baseline;
- `blockedByCollision` returns `noIntent`;
- `blockedByAgentConflict` returns `noIntent`;
- `blockedBySourceMismatch` returns `noIntent`;
- `blockedByDivergence` returns `noIntent`;
- `blockedByStaleIntent` returns `noIntent`;
- `blockedByInvalidEdge` returns `noIntent` with an explicit reason;
- `blockedByMaxAgents` returns `noIntent`;
- blocked feedback over a baseline `noIntent` preserves the baseline
  signature;
- blocked feedback over a baseline invalid proposal becomes `noIntent`;
- all blocked kinds are counted once;
- deterministic output ordering by stable `agentId`;
- stable repeatability.

The scenario records baseline proposals, feedback-aware proposals, decisions,
expected and actual summaries, and repeatability evidence per case. It writes:

- `feedback_aware_intent_policy_hardening_report.json`;
- `feedback_aware_intent_policy_hardening_invariant_report.json`;
- `feedback_aware_intent_policy_hardening_cases.json`;
- `feedbackAwareIntentPolicyHardening*` metrics;
- aggregate event `lab_feedback_aware_intent_policy_hardening_recorded`.

The validated contract remains intentionally narrow: no tick movement, no live
collision read, no World access, no movement application, no memory update, no
goal change, no pathfinding, no replanning, no avoidance, no reservation
runtime, no learning, no social behavior, no communication, and no
terrain/world mutation.

Next recommended step: Phase 4.23C - Feedback-Aware Intent To Tick Fixture
Smoke.
