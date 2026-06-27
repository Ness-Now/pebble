# Phase 4 — Feedback Consumption Plan

## 1. Validated Starting Point

Phases 4.19A-F validated the local multi-agent movement primitives:

- fixture-only multi-agent arbitration;
- fixture hardening for duplicate intents, cycles, chain dependencies,
  invalid edges, stale state, and max-agent bounds;
- live read-only collision intent evidence;
- approved physical movement application;
- live movement hardening with approved, denied, and partial approval cases.

Phases 4.20A-E lifted those primitives into a tick-level movement contract:

- fixture tick input/output;
- live read-only tick collision evidence;
- approved tick application;
- tick hardening;
- structured `LabMovementFeedback`;
- `approvedForMovement`, `moved`, and `blockedBy*` feedback kinds;
- no route following, pathfinding, replanning, avoidance, reservation
  runtime, physics, or terrain/world mutation.

Phases 4.21A-F validated agent intent production and the handoff into tick
movement:

- 4.21A documented future agent intent production;
- 4.21B produced fixture-only agent move proposals;
- 4.21C hardened proposal validation;
- 4.21D fed produced intents into fixture tick arbitration;
- 4.21E fed produced intents into live read-only collision evidence;
- 4.21F fed produced intents into approved tick application.

The current system produces feedback, writes it to reports and events, and
uses it to prove movement contracts. Agents do not yet consume that feedback.
No feedback modifies memory, goals, policies, routes, or future movement.

## 2. Problem To Solve

The next design step is the transition from:

```text
tick produces LabMovementFeedback
```

to:

```text
agent observes feedback as bounded policy context
```

Feedback is a structured signal. It should not immediately become free-form
memory, learning, goal mutation, route repair, dynamic replanning, or an
autonomous retry trigger. The first consumption phase must be deterministic,
traceable, and small enough to audit.

The first runtime smoke after this plan should only prove that feedback can be
observed and normalized into explicit context. It should not change behavior.

## 3. Feedback Kinds Semantics

### `approvedForMovement`

The movement intent was authorized by the tick layer, but no displacement was
applied in that scenario. Future interpretation: the candidate succeeded at
the decision layer. It is not learning yet and should not imply that the
agent physically moved.

### `moved`

The approved movement was applied. Future interpretation: the previous action
completed. Later phases may expose this as a last-move observation, but there
is no reward learning, memory mutation, or goal update in the first feedback
consumption smoke.

### `blockedByCollision`

The destination was not occupable. Future interpretation: the attempted
direction was blocked. Later phases may allow deterministic wait/noIntent or
a bounded alternate hint, but there is no pathfinding or dynamic replanning
yet.

### `blockedByAgentConflict`

Another agent won a conflict, such as same-destination or swap arbitration.
Future interpretation: there may be coordination pressure. For now this is
only observation. There is no negotiation, communication, social behavior, or
reservation runtime.

### `blockedBySourceMismatch`

The intent source did not match the current position. Future interpretation:
the proposal was based on stale internal position state. The first smoke must
not repair memory or silently update agent state.

### `blockedByDivergence`

Abstract and physical positions did not match. Future interpretation: there
is a synchronization issue. The first smoke must not start a self-repair loop
or apply corrective movement.

### `blockedByStaleIntent`

The intent or collision evidence was too old. Future interpretation: the
policy output was outdated. No autonomous retry is introduced yet.

### `blockedByInvalidEdge`

The policy proposed an invalid movement edge. Future interpretation: this is
a policy bug or invalid fixture hint. The first smoke should surface it
clearly rather than learning around it.

### `blockedByMaxAgents`

The tick-level capacity bound was exceeded. Future interpretation: the agent
may need to wait or retry later. There is no scheduler or reservation table
runtime in the first consumption phases.

## 4. Target Architecture

### Feedback Observation Layer

Reads feedback emitted by the tick report or feedback JSON for a bounded tick.
It does not mutate agents, choose new moves, read collision, or apply
movement.

### Feedback Normalization Layer

Converts raw `LabMovementFeedback` into a stable observation form with a known
kind, tick, agent id, and optional movement details. It rejects unknown or
malformed feedback. It does not infer goals or repair state.

### Agent Feedback Context Layer

Builds a small per-agent context from normalized feedback. In v0 it should
accept at most one feedback item per agent and preserve the feedback kind
verbatim. It does not write memory.

### Policy Input Augmentation Layer

Later, this layer may pass the feedback context into
`LabAgentIntentContext.lastFeedback`. In 4.22B it should only prove shape and
ordering, not behavior change.

### Future Decision Policy Layer

Later phases may read feedback context to make deterministic choices. The
first planning boundary forbids retry loops, pathfinding, avoidance,
reservation runtime, learning, and goal selection.

### Reporting Boundary

Reports, metrics, and events describe what was observed and accepted. They do
not affect simulation, choose actions, or mutate state.

### Future Memory/Learning Boundary

Memory updates, goal changes, reinforcement learning, reward updates, and LLM
reasoning remain outside 4.22A-E. They require a separate plan before any
implementation.

## 5. Future Types Proposed

These types are proposed for future Swift implementation. They are not
implemented by this docs-only phase.

```swift
struct LabAgentFeedbackObservation: Codable {
    let tick: Int
    let agentId: String
    let feedbackKind: LabMovementFeedbackKind
    let decision: LabMultiAgentMoveDecision?
    let reason: String
    let from: LabTerrainPathNodeKey?
    let to: LabTerrainPathNodeKey?
    let displacementApplied: Bool
    let collisionRead: Bool
    let abstractBefore: LabTerrainPathNodeKey?
    let abstractAfter: LabTerrainPathNodeKey?
    let physicalBefore: LabTerrainPathNodeKey?
    let physicalAfter: LabTerrainPathNodeKey?
}

struct LabAgentFeedbackContext: Codable {
    let tick: Int
    let agentId: String
    let lastFeedback: LabAgentFeedbackObservation?
    let lastMoveSucceeded: Bool
    let lastMoveBlocked: Bool
    let lastBlockReason: LabMovementFeedbackKind?
    let lastKnownPosition: LabTerrainPathNodeKey?
    let localHints: [String]
    let role: String?
}

enum LabAgentFeedbackConsumptionDecision: String, Codable {
    case ignored
    case observed
    case acceptedAsContext
    case invalidFeedback
}

struct LabAgentFeedbackConsumptionResult: Codable {
    let tick: Int
    let observations: [LabAgentFeedbackObservation]
    let acceptedContexts: [LabAgentFeedbackContext]
    let ignoredFeedback: [LabMovementFeedback]
    let invalidFeedback: [LabMovementFeedback]
    let summary: LabAgentFeedbackConsumptionSummary
}

struct LabAgentFeedbackConsumptionSummary: Codable {
    let agentsObserved: Int
    let feedbackObserved: Int
    let feedbackAccepted: Int
    let feedbackIgnored: Int
    let invalidFeedback: Int
    let moved: Int
    let approvedForMovement: Int
    let blockedByCollision: Int
    let blockedByAgentConflict: Int
    let blockedBySourceMismatch: Int
    let blockedByDivergence: Int
    let blockedByStaleIntent: Int
    let blockedByInvalidEdge: Int
    let blockedByMaxAgents: Int
    let memoryUpdated: Bool
    let goalChanged: Bool
    let replanningPerformed: Bool
    let pathfindingPerformed: Bool
    let movementApplied: Bool
    let success: Bool
}
```

## 6. Proposed v0 Consumption Policy

Feedback consumption v0 should be deliberately small:

- deterministic;
- observe only;
- at most one feedback item consumed per agent in the first smoke;
- accepts known feedback kinds;
- rejects unknown or malformed feedback;
- does not mutate memory;
- does not mutate goals;
- does not retry;
- does not replan;
- does not pathfind;
- does not avoid;
- does not reserve;
- does not apply movement;
- does not read collision;
- does not call LLM, RL, or Python;
- does not emit a new movement intent.

Feedback consumption v0 is not learning. It is not memory. It is not goal
selection. It is not behavior adaptation. It only produces structured context
for later policy phases.

## 7. Relationship With Agent Intent Production

Future phases can connect:

```text
LabMovementFeedback
```

to:

```text
LabAgentIntentContext.lastFeedback
```

The first connection should be plumbing only. In 4.22D/4.22E, feedback context
may appear inside `LabAgentIntentContext`, but the v0 movement policy should
still behave exactly as before. No alternate move selection, retry loop, or
dynamic policy mutation should happen until a later feedback-aware policy
phase.

## 8. Future Scenario Sequence

### Phase 4.22B — Feedback Consumption Fixture Smoke

- consume synthetic feedback;
- produce feedback context;
- no movement;
- no intent production integration;
- no memory or goal mutation.

### Phase 4.22C — Feedback Consumption Hardening

- duplicate feedback;
- unknown agent;
- unknown feedback kind;
- stale tick;
- source mismatch feedback;
- divergence feedback;
- max feedback bound;
- deterministic ordering.

### Phase 4.22D — Feedback To Agent Intent Context Fixture Smoke

- feedback context becomes `lastFeedback` in `LabAgentIntentContext`;
- policy still does not change behavior;
- verify plumbing only.

### Phase 4.22E — Feedback To Agent Intent Context Hardening

- invalid or missing feedback context;
- no feedback;
- multiple feedback inputs;
- deterministic selection.

### Phase 4.22F — Feedback-Aware Intent Policy Planning Docs-Only

- document later behavior adaptation;
- still no implementation.

### Phase 4.23A — Bounded Feedback-Aware Intent Policy Fixture Smoke

- first deterministic tiny behavior adaptation;
- likely wait/noIntent after blocked collision;
- no pathfinding, replanning, learning, reservation runtime, or autonomous
  loop.

## 9. Future Outputs

Future feedback consumption scenarios should write:

- `agent_feedback_consumption_report.json`;
- `agent_feedback_consumption_invariant_report.json`;
- `agent_feedback_contexts.json`;
- `metrics.json`;
- `events.ndjson`.

## 10. Future Metrics

Proposed metrics:

- `agentFeedbackConsumptionAgentsObserved`;
- `agentFeedbackConsumptionFeedbackObserved`;
- `agentFeedbackConsumptionFeedbackAccepted`;
- `agentFeedbackConsumptionFeedbackIgnored`;
- `agentFeedbackConsumptionInvalidFeedback`;
- `agentFeedbackConsumptionMoved`;
- `agentFeedbackConsumptionApprovedForMovement`;
- `agentFeedbackConsumptionBlockedByCollision`;
- `agentFeedbackConsumptionBlockedByAgentConflict`;
- `agentFeedbackConsumptionBlockedBySourceMismatch`;
- `agentFeedbackConsumptionBlockedByDivergence`;
- `agentFeedbackConsumptionBlockedByStaleIntent`;
- `agentFeedbackConsumptionBlockedByInvalidEdge`;
- `agentFeedbackConsumptionBlockedByMaxAgents`;
- `agentFeedbackConsumptionMemoryUpdated`;
- `agentFeedbackConsumptionGoalChanged`;
- `agentFeedbackConsumptionPathfindingPerformed`;
- `agentFeedbackConsumptionReplanningPerformed`;
- `agentFeedbackConsumptionMovementApplied`;
- `agentFeedbackConsumptionSuccess`.

## 11. Future Event

Proposed aggregate event:

`lab_agent_feedback_consumption_recorded`

Fields:

- `tick`;
- `agentsObserved`;
- `feedbackObserved`;
- `feedbackAccepted`;
- `feedbackIgnored`;
- `invalidFeedback`;
- `moved`;
- `approvedForMovement`;
- `blockedByCollision`;
- `blockedByAgentConflict`;
- `blockedBySourceMismatch`;
- `blockedByDivergence`;
- `blockedByStaleIntent`;
- `blockedByInvalidEdge`;
- `blockedByMaxAgents`;
- `memoryUpdated`;
- `goalChanged`;
- `pathfindingPerformed`;
- `replanningPerformed`;
- `movementApplied`;
- `success`.

Do not emit an event per feedback item in the first smoke. Detailed feedback
belongs in the report and context JSON.

## 12. Future Invariants

Future feedback consumption invariant reports should include at least:

1. `feedback_exists`
2. `feedback_sorted_by_stable_agent_id`
3. `at_most_one_feedback_consumed_per_agent_v0`
4. `known_feedback_kinds_accepted`
5. `unknown_feedback_rejected`
6. `malformed_feedback_rejected`
7. `moved_feedback_observed`
8. `approved_for_movement_feedback_observed`
9. `blocked_by_collision_observed`
10. `blocked_by_agent_conflict_observed`
11. `blocked_by_source_mismatch_observed`
12. `blocked_by_divergence_observed`
13. `blocked_by_stale_intent_observed`
14. `blocked_by_invalid_edge_observed`
15. `blocked_by_max_agents_observed`
16. `feedback_context_produced`
17. `feedback_context_contains_agent_id`
18. `feedback_context_contains_tick`
19. `feedback_context_preserves_last_feedback_kind`
20. `feedback_context_preserves_reason`
21. `feedback_context_preserves_from_to`
22. `feedback_context_preserves_displacement_applied`
23. `feedback_context_preserves_collision_read`
24. `feedback_context_preserves_position_snapshots`
25. `invalid_feedback_not_contextualized`
26. `ignored_feedback_counted`
27. `metrics_match_observations`
28. `event_matches_summary`
29. `no_memory_update`
30. `no_goal_change`
31. `no_movement_applied`
32. `no_collision_read`
33. `no_pathfinding`
34. `no_replanning`
35. `no_avoidance`
36. `no_reservation_runtime`
37. `no_learning`
38. `no_llm_rl_python`
39. `no_social_behavior`
40. `no_communication`
41. `no_terrain_mutation`
42. `no_world_mutation`
43. `no_tick_movement_invoked`
44. `no_agent_intent_produced_yet_in_4_22b`
45. `report_written`
46. `context_json_written`
47. `metrics_written`
48. `event_written`
49. `prior_4_21f_smoke_remains_green`
50. `success_contract_respected`

## 13. Explicit Out Of Scope

Feedback consumption planning does not include:

- memory updates;
- goal changes;
- learning;
- reinforcement learning;
- reward updates;
- LLM reasoning;
- Python integration;
- social communication;
- negotiation;
- pathfinding;
- replanning;
- avoidance;
- reservation runtime;
- movement application;
- collision reads;
- terrain/world mutation;
- inventory, mining, or construction;
- autonomous loops.

## 14. Risks and Mitigations

| Risk | Why it matters | Mitigation |
| --- | --- | --- |
| Feedback accidentally becomes memory | It would create hidden state before the memory contract exists. | Keep v0 observe-only and report `memoryUpdated = false`. |
| Feedback changes policy too early | Behavior changes would blur plumbing with adaptation. | Keep policy output unchanged through 4.22D/4.22E. |
| Feedback triggers retry or replanning | Retries can become an implicit autonomous loop. | Forbid retries and require `replanningPerformed = false`. |
| Collision denied becomes pathfinding | Blocked movement may tempt route search. | Keep collision feedback as context only; no path search. |
| `blockedByAgentConflict` becomes social behavior too early | Coordination needs its own contract. | Treat it as observation only. |
| Divergence feedback becomes repair loop too early | Auto-repair can mutate position or hide bugs. | Surface divergence and defer repair planning. |
| Invalid edge feedback hides policy bug | Learning around invalid output can mask bad fixtures. | Reject invalid feedback/proposals explicitly and count them. |
| Max agents feedback becomes scheduler/reservation too early | Scheduling is a separate runtime system. | Keep `blockedByMaxAgents` as observation only. |
| Nondeterministic feedback order | It would make future policy context unstable. | Sort by stable `agentId`, then deterministic tie-breakers. |
| Report metrics drift | Mismatched metrics reduce trust in smokes. | Add invariants comparing observations, metrics, and events. |

## 15. Success Definition

Phase 4.22A succeeds when:

- this plan document exists;
- no Swift files are modified;
- no `PebbleCore` files are modified;
- no renderer, shader, resource, registry, save/load, or golden files are
  modified;
- `CHANGELOG.md` is updated;
- `DEV_JOURNAL.md` is updated;
- `ROADMAP.md` is updated;
- the plan covers starting point, problem, types, v0 policy, future phases,
  outputs, metrics, event, invariants, out-of-scope boundaries, and risks;
- `swift build` passes;
- `swift run -c release pebsmoke` passes;
- `git diff --check` passes;
- the final commit contains only documentation changes.
