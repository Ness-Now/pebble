# Phase 4 Multi-Agent Movement Integration Plan

Phase 4.20A is a docs-only integration planning phase. It does not implement
runtime integration, create a scenario, alter runners, or change Swift code.

The purpose is to define how PebbleLab can move from isolated multi-agent
movement smokes to a future tick-level movement contract that can later be
called by agent/scenario loops without jumping directly to reservation
tables, avoidance, dynamic replanning, pathfinding, long-running navigation,
or gameplay movement.

## 1. Validated Starting State

Phase 4.19A documented the first multi-agent movement planning contract. It
established the distinction between single-agent route following and
multi-agent movement, named future conflict classes, proposed deterministic
arbitration, and kept reservation runtime, avoidance, pathfinding, physics,
world mutation, and gameplay movement out of scope.

Phase 4.19B added `multi_agent_movement_fixture_smoke`. It validated
fixture-only arbitration over 8 cases, with 8 passed, 0 failed, 3 approved
resolutions, and 8 denied resolutions. It proved stable `agentId` ordering,
same-destination conflict denial, occupied destination denial, swap denial,
source mismatch denial, stale intent denial, missing-agent denial, invalid
edge denial, no duplicate approved destination, and no approved swap. It did
not create or use `World`.

Phase 4.19C added `multi_agent_movement_fixture_hardening_smoke`. It
validated 10 fixture hardening cases, with 10 passed, 0 failed, 1 approved
resolution, and 20 denied resolutions. It covered duplicate intents, cycles,
chain dependencies, moving-away destinations, vertical invalid edges,
zero-length edges, all-denied mixed reasons, empty-intents no-op, and a
fixture-only max-agent bound.

Phase 4.19D added `multi_agent_live_collision_intent_smoke`. It validated
live read-only collision evidence for multi-agent intentions over 7 cases,
with 7 passed, 0 failed, 4 approved intent resolutions, 5 denied intent
resolutions, 5 occupable destinations, 1 non-occupable destination, and one
collision denial. Final positions remained equal to initial positions and no
displacement or physical movement was applied.

Phase 4.19E added `multi_agent_approved_physical_movement_smoke`. It
validated approved-only physical placeholder movement over 2 cases, with 2
passed, 0 failed, 4 approved resolutions, 0 denied resolutions, 4
displacements applied, 4 occupable live destinations, divergence before max
0, and divergence after max 0. Two agents moved exactly one 4-neighbor
same-y edge per case, and abstract final positions matched physical final
positions.

Phase 4.19F added `multi_agent_movement_hardening_smoke`. It validated 12
live hardening cases, with 12 passed, 0 failed, 4 approved resolutions, 18
denied resolutions, 4 displacements applied, 3 collision denials, 2 partial
approval cases, 1 same-destination conflict, 2 swap-conflict denials, 2
source mismatches, 1 stale intent, 2 invalid edges, 1 divergence denial, 1
stale collision denial, and a hardening-only max-agent bound of 4.

Across these phases, PebbleLab has repeatedly kept these systems out of
scope:

- route following as a live multi-agent loop;
- pathfinding inside arbitration;
- dynamic replanning;
- goal selection;
- avoidance;
- reservation table runtime;
- physics integration;
- terrain mutation;
- world mutation;
- save/load changes;
- renderer, shader, resource, and registry changes.

These smokes prove local contracts. They do not yet form an integrated
movement loop. The next step should integrate the shape of one movement tick
progressively before any richer navigation system is introduced.

## 2. Integration Problem

The next problem is not reservation table runtime, avoidance, swarm
movement, social movement, multi-agent pathfinding, or long gameplay
movement. Those are later concerns.

The immediate integration problem is ownership and sequencing:

- where movement intentions are produced;
- when tick intentions are collected;
- which layer stabilizes input ordering;
- which layer arbitrates conflicts;
- which layer reads live collision evidence;
- which layer applies approved displacements;
- how denied movements preserve abstract and physical state;
- how feedback returns to agents without triggering replanning yet;
- how future memory and metrics can observe refusals later;
- how reporting remains useful without becoming simulation logic;
- how the runner avoids becoming one monolithic movement function.

The integration boundary must preserve the 4.19 contracts while creating a
single tick-level shape that future scenarios can call.

## 3. Future Target Architecture

### Agent Decision Layer

The agent decision layer may eventually produce a `LabAgentMoveIntent` for
the current tick.

Responsibilities:

- choose whether an agent wants to move;
- emit at most one next-edge intent for early tick movement phases;
- include source and destination nodes explicitly;
- include optional route metadata when a higher layer provides it.

Non-responsibilities:

- do not mutate agent position;
- do not read live collision directly;
- do not resolve conflicts;
- do not choose winners;
- do not replan or pathfind inside the tick integration contract.

### Intent Collection Layer

The intent collection layer gathers all movement intentions for one tick.

Responsibilities:

- collect intentions from active agents or a fixture input;
- filter missing, absent, or inactive agents according to the scenario
  contract;
- stabilize ordering by `agentId`;
- preserve enough source information for stale-intent checks;
- produce a bounded tick input object.

Non-responsibilities:

- do not decide conflicts;
- do not read live collision;
- do not apply movement;
- do not create alternative intents.

### Arbitration Layer

The arbitration layer applies the 4.19B/4.19C fixture arbitration contract
and the 4.19F hardening rules.

Responsibilities:

- reject missing agents;
- reject stale or source-mismatched intents;
- reject invalid edges;
- reject duplicate intents when applicable;
- detect same-destination conflicts;
- detect swap conflicts;
- detect cycles, chain dependencies, and moving-away dependencies when a
  scenario enables those checks;
- apply deterministic stable ordering;
- produce resolutions.

Non-responsibilities:

- do not call pathfinding;
- do not do dynamic replanning;
- do not perform avoidance;
- do not implement reservation runtime;
- do not mutate world or terrain;
- do not apply displacement.

### Collision Evidence Layer

The collision evidence layer reads live occupancy evidence for destination
nodes that survived early validation.

Responsibilities:

- read live collision only for valid collision-required intents;
- keep reads read-only;
- attach evidence to the exact destination node;
- mark stale or mismatched evidence as invalid;
- provide collision status and reason to arbitration/application reports.

Non-responsibilities:

- do not choose winners;
- do not apply movement;
- do not mutate chunks or blocks;
- do not infer alternative destinations.

### Application Layer

The application layer applies only approved resolutions.

Responsibilities:

- use the existing single-step movement contract;
- move at most one edge per approved agent per tick in early phases;
- verify abstract/physical divergence before movement;
- synchronize approved physical placeholders;
- preserve denied abstract positions;
- preserve denied physical positions;
- verify final abstract and physical positions match for approved moves.

Non-responsibilities:

- do not re-arbitrate;
- do not invent movement;
- do not repair routes;
- do not trigger replanning;
- do not mutate terrain/world.

### Feedback Layer

The feedback layer converts movement resolutions into structured feedback
records for future agent-facing phases.

Responsibilities:

- create one feedback record per resolution;
- map decisions to stable feedback kinds;
- keep denial reasons explicit;
- make feedback usable by future memory, goal, or reporting work.

Non-responsibilities:

- do not update memory yet;
- do not communicate between agents;
- do not change goals;
- do not call LLM, Python, or RL;
- do not trigger replanning.

### Reporting Layer

The reporting layer writes outputs after the tick contract finishes.

Responsibilities:

- write tick report;
- write invariant report;
- write feedback JSON;
- write metrics;
- write one aggregate event;
- record out-of-scope flags.

Non-responsibilities:

- do not decide gameplay;
- do not change simulation state;
- do not influence arbitration.

## 4. Future Types Proposed

These types are proposed only. Phase 4.20A does not add Swift code.

```swift
struct LabMultiAgentMovementTickInput: Codable {
    let tick: Int
    let agents: [String: LabTerrainPathNodeKey]
    let physicalPositions: [String: LabTerrainPathNodeKey]
    let intents: [LabAgentMoveIntent]
    let maxAgents: Int?
}

struct LabMultiAgentMovementTickOutput: Codable {
    let tick: Int
    let resolutions: [LabMultiAgentMovementResolution]
    let abstractPositionsBefore: [String: LabTerrainPathNodeKey]
    let abstractPositionsAfter: [String: LabTerrainPathNodeKey]
    let physicalPositionsBefore: [String: LabTerrainPathNodeKey]
    let physicalPositionsAfter: [String: LabTerrainPathNodeKey]
    let summary: LabMultiAgentMovementTickSummary
}

struct LabMultiAgentMovementTickSummary: Codable {
    let intents: Int
    let approved: Int
    let denied: Int
    let displacementsApplied: Int
    let collisionDenied: Int
    let conflictDenied: Int
    let divergenceDenied: Int
    let maxDivergenceBefore: Int
    let maxDivergenceAfter: Int
    let success: Bool
}

enum LabMovementFeedbackKind: String, Codable {
    case moved
    case blockedByCollision
    case blockedByAgentConflict
    case blockedBySourceMismatch
    case blockedByDivergence
    case blockedByStaleIntent
    case blockedByInvalidEdge
    case blockedByMaxAgents
}

struct LabMovementFeedback: Codable {
    let agentId: String
    let tick: Int
    let kind: LabMovementFeedbackKind
    let from: LabTerrainPathNodeKey?
    let to: LabTerrainPathNodeKey?
    let reason: String
}
```

`LabMultiAgentMovementResolution` should either wrap the existing
hardening-resolution shape or be defined as the stable shared resolution
record when the tick-level scenario is implemented. It should not be created
in 4.20A.

## 5. Boundary Rules

- Agent does not mutate position directly.
- Agent decision layer emits intent only.
- Intent collector does not apply movement.
- Intent collector does not resolve conflicts.
- Arbiter does not call pathfinding.
- Arbiter does not replan.
- Arbiter does not mutate world.
- Arbiter does not mutate terrain.
- Collision layer does not choose winners.
- Collision layer does not mutate blocks or chunks.
- Collision evidence is tied to one explicit destination.
- Application layer does not re-arbitrate.
- Application layer applies only approved resolutions.
- Application layer preserves denied abstract and physical positions.
- Feedback layer does not invent movement.
- Feedback layer does not update memory yet.
- Feedback layer does not change goals yet.
- Reporting layer does not affect simulation.
- Reporting layer does not decide gameplay.

## 6. Future Scenario Sequence

### Phase 4.20B - Multi-Agent Movement Tick Fixture Smoke

- no `World`;
- one synthetic tick;
- explicit input/output object;
- verifies integration shape;
- no live collision;
- no physical movement;
- no runtime reservation table;
- no avoidance;
- no replanning.

### Phase 4.20C - Multi-Agent Movement Tick Live Read-Only Smoke

- `World` used only for collision evidence;
- no movement application;
- validates tick input/output with live evidence;
- verifies stale evidence denial;
- keeps final positions equal to initial positions.

### Phase 4.20D - Multi-Agent Movement Tick Approved Application Smoke

- one tick;
- two agents;
- approved movement only;
- applies through the existing single-step contract;
- writes tick report and feedback;
- no denied hardening beyond the minimal success path.

### Phase 4.20E - Multi-Agent Movement Tick Hardening

- denied collision;
- same-destination conflict;
- partial approval;
- divergence denial;
- stale intent;
- stale collision evidence;
- max agents;
- no replanning;
- no avoidance;
- no reservation runtime.

### Phase 4.21A - Agent Intent Production Planning Docs-Only

- document how agents will produce movement intents from goals;
- define the boundary between goal selection and movement intention;
- still no autonomous movement loop.

### Phase 4.21B - Agent Intent Production Fixture Smoke

- abstract agents produce intents;
- no physical movement yet;
- no live collision yet unless explicitly planned by 4.21A;
- verifies that intent production can feed tick-level collection.

## 7. Future Outputs

Future tick-level scenarios should write:

- `multi_agent_movement_tick_report.json`;
- `multi_agent_movement_tick_invariant_report.json`;
- `multi_agent_movement_tick_feedback.json`;
- `metrics.json`;
- `events.ndjson`.

Recommended report fields:

- `scenario`;
- `seed`;
- `tick`;
- `input`;
- `output`;
- `success`;
- `summary`;
- `resolutions`;
- `feedback`;
- `outOfScopeFlags`.

The feedback JSON should contain structured feedback records separate from
the aggregate event. This avoids early event spam and keeps agent-level
details inspectable in the report artifacts.

## 8. Future Metrics

Recommended metrics:

- `multiAgentMovementTickInputs`;
- `multiAgentMovementTickAgents`;
- `multiAgentMovementTickIntents`;
- `multiAgentMovementTickApproved`;
- `multiAgentMovementTickDenied`;
- `multiAgentMovementTickDisplacementsApplied`;
- `multiAgentMovementTickCollisionDenied`;
- `multiAgentMovementTickConflictDenied`;
- `multiAgentMovementTickDivergenceDenied`;
- `multiAgentMovementTickFeedbackProduced`;
- `multiAgentMovementTickDivergenceBeforeMax`;
- `multiAgentMovementTickDivergenceAfterMax`;
- `multiAgentMovementTickPathfindingPerformed`;
- `multiAgentMovementTickReplanningPerformed`;
- `multiAgentMovementTickAvoidancePerformed`;
- `multiAgentMovementTickReservationRuntimeUsed`;
- `multiAgentMovementTickPhysicsPerformed`;
- `multiAgentMovementTickMutationPerformed`;
- `multiAgentMovementTickSuccess`.

Metrics should be derived from input, output, resolutions, and feedback. They
should not drive arbitration or movement application.

## 9. Future Event

Recommended aggregate event:

```text
lab_multi_agent_movement_tick_recorded
```

Fields:

- `tick`;
- `agentCount`;
- `intentCount`;
- `approved`;
- `denied`;
- `displacementsApplied`;
- `collisionDenied`;
- `conflictDenied`;
- `divergenceDenied`;
- `feedbackProduced`;
- `divergenceBeforeMax`;
- `divergenceAfterMax`;
- `success`.

Do not emit one event per agent or per edge in the first tick-level smoke.
Detailed per-agent feedback belongs in `multi_agent_movement_tick_feedback.json`
and in the report.

## 10. Future Invariants

Future tick-level invariant reports should include at least these checks:

1. `tick_input_exists`
2. `tick_output_exists`
3. `agent_positions_present`
4. `physical_positions_present_when_application_enabled`
5. `intents_exist_when_required_by_scenario`
6. `intents_sorted_deterministically`
7. `every_intent_has_agent_id`
8. `every_intent_has_explicit_source`
9. `every_intent_has_explicit_destination`
10. `sources_match_current_positions_or_denied`
11. `valid_edges_are_4_neighbor_same_y`
12. `invalid_edges_denied`
13. `collision_evidence_attached_only_to_valid_collision_required_intents`
14. `source_mismatch_skips_collision`
15. `stale_intents_skip_collision`
16. `stale_evidence_denied`
17. `non_occupable_destinations_denied`
18. `same_destination_conflicts_resolve_deterministically`
19. `no_duplicate_approved_destination`
20. `swap_conflicts_denied_or_absent`
21. `no_approved_swap`
22. `denied_abstract_positions_preserved`
23. `denied_physical_positions_preserved`
24. `approved_abstract_positions_move_one_edge`
25. `approved_physical_positions_move_one_edge`
26. `abstract_physical_final_positions_match`
27. `divergence_before_bounded`
28. `divergence_after_bounded`
29. `feedback_produced_for_every_resolution`
30. `feedback_kind_matches_decision`
31. `feedback_does_not_mutate_memory`
32. `metrics_match_resolutions`
33. `event_written`
34. `report_written`
35. `feedback_written`
36. `pathfinding_not_performed`
37. `replanning_not_performed`
38. `avoidance_not_performed`
39. `reservation_runtime_not_used`
40. `route_following_long_not_performed`
41. `goal_selection_not_performed`
42. `physics_not_performed`
43. `terrain_mutation_not_performed`
44. `world_mutation_not_performed`
45. `fixture_arbitration_still_green`
46. `fixture_hardening_still_green`
47. `live_collision_intent_still_green`
48. `approved_movement_smoke_still_green`
49. `movement_hardening_still_green`
50. `success_contract_respected`

## 11. Feedback Policy

Movement feedback should be a structured transformation of resolutions, not
a behavior system.

Recommended mapping:

- `approved` with `displacementApplied == true` -> `moved`;
- `deniedCollision` -> `blockedByCollision`;
- `deniedSameDestinationConflict` -> `blockedByAgentConflict`;
- `deniedSwapConflict` -> `blockedByAgentConflict`;
- `deniedCycleConflict` -> `blockedByAgentConflict`;
- `deniedChainDependency` -> `blockedByAgentConflict`;
- `deniedMovingAwayDestination` -> `blockedByAgentConflict`;
- `deniedSourceMismatch` -> `blockedBySourceMismatch`;
- `deniedDivergence` -> `blockedByDivergence`;
- `deniedStaleIntent` -> `blockedByStaleIntent`;
- `deniedStaleCollision` -> `blockedByStaleIntent`;
- `deniedInvalidEdge` -> `blockedByInvalidEdge`;
- `deniedZeroLengthEdge` -> `blockedByInvalidEdge`;
- `deniedMaxAgents` -> `blockedByMaxAgents`.

Feedback does not yet:

- update memory;
- change goals;
- trigger replanning;
- communicate with other agents;
- call LLM, Python, or RL;
- generate alternative movement.

In early phases, feedback is structured output for future agent integration.

## 12. Relationship With Existing Smokes

Existing smokes remain lower-level proofs:

- 4.19B proves fixture arbitration;
- 4.19C proves fixture arbitration hardening;
- 4.19D proves live collision evidence for intents;
- 4.19E proves approved physical application;
- 4.19F proves live hardening for approvals and denials.

Phase 4.20 should integrate these into one tick-level contract. It should not
replace the lower-level smokes. Instead, the integration invariant report
should keep checking that those smokes remain green.

## 13. Explicitly Out Of Scope

The following are out of scope for Phase 4.20A:

- implementation in 4.20A;
- any Swift changes;
- any scenario creation;
- runner changes;
- behavior changes;
- autonomous agent movement;
- repeated tick loop;
- long-running navigation;
- reservation table runtime;
- avoidance;
- steering;
- flocking;
- dynamic replanning;
- pathfinding;
- `findTerrainPath`;
- BFS, A*, or Dijkstra;
- route repair;
- route following long;
- goal selection;
- memory update;
- social behavior;
- communication;
- combat;
- mining;
- construction;
- inventory;
- animation;
- renderer changes;
- save/load;
- registries;
- Python, LLM, or RL;
- terrain mutation;
- world mutation.

## 14. Risks And Mitigations

| Risk | Mitigation |
| --- | --- |
| Integration layer becomes monolithic | Split future code into tick input, collection, arbitration, collision evidence, application, feedback, and reporting helpers. |
| Feedback mutates agent state too early | Keep feedback as serialized output only until a dedicated agent feedback phase exists. |
| Arbiter starts pathfinding | Add invariants for no pathfinding and keep route/path production outside arbitration. |
| Denied movement accidentally mutates physical position | Require denied abstract and physical preservation checks in every tick-level invariant report. |
| Collision evidence reused stale | Tie evidence to an explicit destination node and deny mismatched evidence. |
| Report claims success while lower-level smoke fails | Include lower-level smoke green checks in tick-level invariant reports. |
| Reservation table introduced too early | Keep reservation runtime as an out-of-scope flag and metric until a dedicated planning phase. |
| Avoidance leaks in | Deny alternatives in early tick phases and track `multiAgentMovementTickAvoidancePerformed`. |
| Route following becomes long gameplay movement | Limit early scenarios to one tick and one edge per approved agent. |
| Event spam | Emit one aggregate event and place per-agent feedback in report/feedback JSON. |
| Unclear ownership between route follower and arbiter | Document route follower as a possible intent producer only; arbiter owns approval. |
| Abstract and physical positions mismatch | Check divergence before and after, and gate application on divergence policy. |
| Future repeated tick loop accumulates divergence | Add bounded divergence metrics before any repeated tick scenario. |
| Reporting starts influencing simulation | Keep report generation after movement output is complete and read-only. |
| Goal selection sneaks into movement tick | Keep goal selection out of 4.20 and defer agent intent production to 4.21 planning. |

## Phase 4.20B Implementation Status

Phase 4.20B implements the first fixture-only tick-level contract:
`multi_agent_movement_tick_fixture_smoke`.

Validated tick input/output:

- one synthetic tick, `tick = 0`;
- four abstract agent positions;
- four matching synthetic physical positions;
- four deliberately unordered intentions;
- deterministic resolution order by stable `agentId`;
- two approved intentions;
- one same-destination conflict denial;
- one invalid vertical edge denial;
- no position changes in this fixture-only phase.

The scenario writes:

- `multi_agent_movement_tick_fixture_report.json`;
- `multi_agent_movement_tick_fixture_invariant_report.json`;
- `multi_agent_movement_tick_fixture_feedback.json`;
- `metrics.json`;
- `events.ndjson`.

The feedback JSON records one feedback entry per resolution. Approved
fixture-only resolutions use `approvedForMovement` because no displacement
is applied; `moved` remains reserved for future application phases.

Validated limits:

- no `World`;
- no live collision read;
- no physical movement application;
- no route following;
- no pathfinding;
- no replanning;
- no goal selection;
- no avoidance;
- no reservation runtime;
- no physics;
- no terrain/world mutation;
- no repeated tick loop.

Next recommended step: Phase 4.20C - Multi-Agent Movement Tick Live
Read-Only Smoke. It should attach live collision evidence to the same
tick-level input/output contract while still avoiding movement application.

## Phase 4.20C Implementation Status

Phase 4.20C implements the first tick-level live read-only collision
contract: `multi_agent_movement_tick_live_readonly_smoke`.

Validated tick live read-only input/output:

- one synthetic tick, `tick = 0`;
- five abstract agent positions;
- five matching synthetic physical positions;
- five deliberately unordered intentions;
- deterministic resolution order by stable `agentId`;
- two approved read-only intentions with occupable evidence;
- one collision denial with non-occupable evidence;
- one source mismatch denial before collision;
- one invalid vertical edge denial before collision;
- no abstract position changes;
- no physical position changes;
- no displacement application.

Collision evidence policy:

- valid collision-required intentions read live collision evidence;
- source mismatch, stale intent if present, and invalid edges skip collision;
- controlled per-intent evidence seeds allow the smoke to cover both
  occupable and non-occupable destinations in one aggregate tick report;
- evidence remains read-only and does not trigger movement, replanning,
  avoidance, reservation, or route following.

The scenario writes:

- `multi_agent_movement_tick_live_readonly_report.json`;
- `multi_agent_movement_tick_live_readonly_invariant_report.json`;
- `multi_agent_movement_tick_live_readonly_feedback.json`;
- `metrics.json`;
- `events.ndjson`.

The feedback JSON records one feedback entry per resolution. Approved
read-only resolutions use `approvedForMovement`; collision denial uses
`blockedByCollision`; source mismatch uses `blockedBySourceMismatch`; invalid
edge uses `blockedByInvalidEdge`.

Validated limits:

- no physical movement application;
- no route following;
- no pathfinding;
- no replanning;
- no goal selection;
- no avoidance;
- no reservation runtime;
- no physics;
- no terrain/world mutation;
- no autonomous movement loop.

Next recommended step: Phase 4.20D - Multi-Agent Movement Tick Approved
Application Smoke. It should apply approved tick resolutions in a tightly
controlled case and keep denied/conflict hardening for later phases.

## 15. Documentation Updates

Phase 4.20A should update:

- `docs/pebblelab/CHANGELOG.md`;
- `docs/pebblelab/DEV_JOURNAL.md`;
- `docs/pebblelab/ROADMAP.md`;
- this plan document.

No Swift files, runners, scenarios, registries, save/load files, renderer
files, shader files, resources, or goldens should be modified.
