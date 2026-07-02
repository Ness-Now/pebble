# Phase 5.6A — Cognitive Loop Integration Planning

## Purpose

Phase 5.6A defines the v0 technical contract for an integrated cognitive loop.

The objective is to move from isolated, fixture-proven components:

- behavior loop;
- memory update;
- memory retrieval;
- goal selection from retrieved memory;
- behavior loop memory-goal bridge;

to a controlled fixture-only chain:

```text
memory snapshot
-> retrieval
-> goal selection
-> bridge
-> behavior result
-> memory update
```

This phase does not implement runtime integration. It adds no Swift code, no
scenario, no runtime metrics, no runtime events, no `LabAgent` behavior
change, no `main.swift` orchestration change, no movement stack call, no World
access, no mood, no relationships, no communication, no Python, no LLM, no
embeddings, and no RL.

The goal is to make Phase 5.6B small, bounded, deterministic, and reviewable
before any integration touches normal `agents_basic` behavior.

## Starting Point

Phase 5.1B and Phase 5.1C created and hardened the behavior-loop contract. The
fixtures build bounded behavior-loop inputs, produce decisions, select abstract
actions, apply bounded abstract effects, record memory write counts, emit
reports/invariants/metrics/events, and keep World, terrain, movement stack,
Core entities, and physical placeholders out of scope.

Phase 5.2B and Phase 5.2C created and hardened memory update from behavior
result. The fixtures convert controlled behavior results into memory update
inputs, proposals, accepted/rejected writes, before/after snapshots, reports,
invariants, metrics, events, and stable digests. Accepted writes are bounded to
max 1 per agent/tick.

Phase 5.3B and Phase 5.3C created and hardened memory retrieval. The fixtures
read controlled memory snapshots, run bounded retrieval queries, rank memories,
cover empty results and invalid queries, keep memory read-only, and prove
deterministic ordering/digests.

Phase 5.4B and Phase 5.4C created and hardened goal selection from retrieved
memory. The fixtures map retrieved memories to bounded goal candidates, merge
duplicates, score candidates, handle conflicts and unknown memory/goal cases,
and produce selected goal decisions without executing behavior actions,
mutating memory, or rerunning retrieval.

Phase 5.5B and Phase 5.5C created and hardened the behavior-loop memory-goal
bridge. The fixtures consume controlled goal-selection decisions, produce
`selectedGoalForBehaviorLoop`, select an abstract action, produce a bounded
behavior result summary, and explicitly keep behavior action execution, memory
write/mutation, retrieval rerun, movement stack, World, and terrain out of
scope.

All systems are now tested as isolated fixtures. Phase 5.6A prepares the first
integrated fixture contract.

## Current Component Boundaries

`LabBehaviorLoop` owns bounded behavior-loop fixture evidence:

- `LabBehaviorLoopInput`;
- `LabBehaviorLoopDecision`;
- `LabBehaviorLoopResult`;
- behavior-loop reports, invariant reports, metrics, events, and digests;
- abstract selected goals/actions/effects;
- no movement stack or World mutation.

`LabMemoryUpdate` owns behavior-result-to-memory fixture evidence:

- `LabMemoryUpdateInput`;
- `LabMemoryUpdateProposal`;
- `LabMemoryUpdateResult`;
- `LabMemoryUpdateAgentSnapshot`;
- accepted/rejected write accounting;
- max 1 accepted write per agent/tick;
- no retrieval ownership.

`LabMemoryRetrieval` owns read-only memory lookup evidence:

- `LabMemoryRetrievalQuery`;
- `LabMemoryRetrievedRecord`;
- `LabMemoryRetrievalResult`;
- ranked retrieval records;
- empty result handling;
- no memory mutation or write.

`LabGoalSelectionMemory` owns retrieved-memory-to-goal evidence:

- `LabGoalSelectionFromMemoryInput`;
- `LabGoalCandidate`;
- `LabGoalSelectionFromMemoryDecision`;
- candidate scoring, duplicate merge, selected goal, and influence reason;
- no behavior action execution, memory mutation, or retrieval rerun.

`LabBehaviorLoopMemoryGoalBridge` owns memory-informed behavior-loop bridge
evidence:

- `LabBehaviorLoopMemoryGoalBridgeInput`;
- `LabBehaviorLoopMemoryGoalBridgeDecision`;
- selected goal for behavior loop;
- abstract selected action;
- behavior result summary;
- no action execution, memory write, retrieval rerun, movement stack, World,
  or terrain mutation.

The future integrated cognitive loop should orchestrate these components. It
should not merge their ownership into one large type, and it should not turn
`main.swift` into the cognitive owner.

## Problem To Solve

The existing components are reliable separately, but the project has not yet
proved their order, handoff shape, or integrated report contract.

Problems to solve before implementation:

- define the exact order of retrieval, goal selection, bridge, behavior result,
  and memory update;
- prevent a hidden write -> retrieve -> write feedback loop;
- keep retrieval read-only and before memory update in v0;
- keep memory writes owned only by `LabMemoryUpdate`;
- prove memory count before/after across the integrated chain;
- keep selectedGoal distinct from selectedAction;
- keep selectedAction distinct from executed action;
- prevent `main.swift` from becoming a cognitive monolith;
- keep `agents_basic` unchanged until the integrated fixture is proven;
- keep movement stack and World/terrain outside the cognitive integration
  fixture;
- keep deterministic ordering and digest evidence across all handoffs.

## Integrated Cognitive Loop V0

The target v0 sequence is:

1. Build a synthetic agent state and initial memory snapshot.
2. Build one bounded retrieval query plan.
3. Run memory retrieval read-only against the initial memory snapshot.
4. Run goal selection from retrieved memory.
5. Run behavior loop memory-goal bridge.
6. Produce a behavior result summary.
7. Run memory update from the behavior result.
8. Produce before/after memory snapshots.
9. Emit integrated report, invariant report, trace, decisions, memory
   snapshot, digest, metrics, and events.
10. Do not execute any action in World.
11. Do not call the movement stack or produce movement intents.
12. Do not modify `agents_basic`.

The fixture should be a proof of orchestration, not a new intelligence layer.
Each step should pass compact, explicit summaries to the next step and record
the handoff in an integrated trace.

## Proposed Types For Future Implementation

These types are proposed for Phase 5.6B or later. They are not implemented in
Phase 5.6A.

### `LabCognitiveLoopIntegrationInput`

Suggested fields:

- `tick`;
- `agentId`;
- `currentGoal`;
- `initialMemorySnapshot`;
- `needsSummary`;
- `fear`;
- `health`;
- `retrievalQueryPlan`;
- `maxRetrievedMemories`;
- `maxGoalCandidates`;
- `maxMemoryWritesPerTick`;
- `reason`.

Purpose: represent one bounded integrated-loop request for one agent/tick. It
should contain all state needed for the fixture without reading World, movement
stack, save/load, registries, or live `agents_basic`.

### `LabCognitiveLoopIntegrationStepTrace`

Suggested fields:

- `tick`;
- `agentId`;
- `retrievalResultSummary`;
- `goalSelectionDecisionSummary`;
- `bridgeDecisionSummary`;
- `behaviorResultSummary`;
- `memoryUpdateResultSummary`;
- `success`.

Purpose: provide a compact, ordered audit trail across the chain so the report
can show exactly which component produced each handoff.

### `LabCognitiveLoopIntegrationDecision`

Suggested fields:

- `tick`;
- `agentId`;
- `goalBefore`;
- `retrievedMemories`;
- `selectedGoal`;
- `selectedAction`;
- `behaviorResultSummary`;
- `memoryProposals`;
- `acceptedMemoryWrites`;
- `rejectedMemoryWrites`;
- `memoryCountBefore`;
- `memoryCountAfter`;
- `success`.

Purpose: represent the integrated outcome for one agent/tick without claiming
that a real action was executed.

### `LabCognitiveLoopIntegrationReport`

Suggested fields:

- `scenario`;
- `seed`;
- `agents`;
- `ticks`;
- `decisions`;
- `retrievedMemories`;
- `selectedGoals`;
- `selectedActions`;
- `behaviorResults`;
- `memoryProposals`;
- `acceptedMemoryWrites`;
- `rejectedMemoryWrites`;
- `memoryCountBeforeTotal`;
- `memoryCountAfterTotal`;
- `goalChanges`;
- `unchangedGoals`;
- `emptyRetrievalDecisions`;
- `behaviorActionExecuted`;
- `memoryMutatedOutsideUpdate`;
- `retrievalRerunUnexpected`;
- `movementStackUsed`;
- `worldMutated`;
- `terrainMutated`;
- `bounded`;
- `deterministicOrder`;
- `digest`;
- `digestRepeat`;
- `digestsEqual`;
- `repeatabilityFailures`;
- `success`.

Purpose: prove that the integrated fixture is bounded, deterministic,
side-effect clean, and explicit about which component owns memory mutation.

## Ownership Boundaries

The likely Phase 5.6B implementation should create a new file:

```text
Sources/PebbleLab/LabCognitiveLoopIntegration.swift
```

That file should orchestrate the chain. It should not absorb all behavior,
retrieval, goal selection, bridge, and memory update logic. It should reuse or
call existing fixture helpers where that is practical, and it may build small
synthetic summaries when direct reuse would create a larger refactor.

`main.swift` should remain the runner/output dispatcher:

- detect `cognitive_loop_integration_fixture_smoke`;
- call the builder;
- write report/invariant/trace/decisions/memory snapshot/digest;
- inject metrics/events;
- define `runSuccess`.

`LabAgent` should remain the state container. Phase 5.6B should not add fields
or change normal agent behavior.

`LabMemoryUpdate` should remain the only owner of memory append behavior in the
fixture chain. Integrated code should not mutate memory outside the memory
update step.

`LabMemoryRetrieval` should remain read-only. It should not read after memory
update in v0.

The movement stack remains out of scope.

## Memory Update Rules V0

The integrated fixture should enforce:

- max 1 accepted write per agent/tick;
- rejected writes allowed and auditable;
- `memoryCountAfter >= memoryCountBefore`;
- retrieval reads the initial memory snapshot;
- memory update writes only after behavior result production;
- memory mutation outside `LabMemoryUpdate` is forbidden;
- no retrieval rerun after memory update in v0;
- no iterative write -> retrieve -> write loop;
- memory summaries remain deterministic;
- accepted and rejected writes are included in reports and traces.

In Phase 5.6B, it is acceptable to use synthetic behavior results that match
the bridge output shape if that keeps the first integration fixture small.

## Goal/Action Rules V0

The integrated fixture should enforce:

- retrieved memories may influence selectedGoal only through goal selection;
- selectedGoal enters the bridge explicitly;
- selectedGoal determines abstract selectedAction;
- selectedAction produces a behavior result summary;
- selectedAction is not executed;
- selectedAction does not produce movement intent;
- empty retrieval keeps currentGoal;
- currentGoal continuity remains allowed;
- safety/fear priority can preserve or force `seekSafety`;
- selectedGoal and selectedAction must always be present for successful
  decisions.

The v0 action mapping should stay consistent with the bridge:

- `seekSafety` -> `seekSafety`;
- `explore` -> `explore`;
- `observeOtherAgent` -> `observeAgent`;
- `idle` -> `idle`;
- `rest` -> `rest` when needed by a fixture case.

## Determinism Rules V0

The integrated fixture should enforce:

- stable agent order;
- stable memory order;
- stable query order;
- stable retrieved-record order;
- stable candidate order;
- stable decision order;
- stable memory proposal order;
- stable before/after snapshot order;
- stable digest and repeat digest;
- no random values;
- no `Dictionary` or `Set` iteration order dependency in emitted outputs;
- `repeatabilityFailures = 0`.

If dictionaries are used for inventory or summaries, emitted output should sort
keys before digest/report construction.

## Future Metrics Contract

Metrics prefix:

```text
cognitiveLoopIntegration*
```

Future metrics:

- `cognitiveLoopIntegrationSuccess`;
- `cognitiveLoopIntegrationAgents`;
- `cognitiveLoopIntegrationTicks`;
- `cognitiveLoopIntegrationDecisions`;
- `cognitiveLoopIntegrationRetrievedMemories`;
- `cognitiveLoopIntegrationSelectedGoals`;
- `cognitiveLoopIntegrationSelectedActions`;
- `cognitiveLoopIntegrationBehaviorResults`;
- `cognitiveLoopIntegrationMemoryProposals`;
- `cognitiveLoopIntegrationAcceptedMemoryWrites`;
- `cognitiveLoopIntegrationRejectedMemoryWrites`;
- `cognitiveLoopIntegrationMemoryCountBeforeTotal`;
- `cognitiveLoopIntegrationMemoryCountAfterTotal`;
- `cognitiveLoopIntegrationGoalChanges`;
- `cognitiveLoopIntegrationUnchangedGoals`;
- `cognitiveLoopIntegrationEmptyRetrievalDecisions`;
- `cognitiveLoopIntegrationBehaviorActionExecuted`;
- `cognitiveLoopIntegrationMemoryMutatedOutsideUpdate`;
- `cognitiveLoopIntegrationRetrievalRerunUnexpected`;
- `cognitiveLoopIntegrationMovementStackUsed`;
- `cognitiveLoopIntegrationWorldMutated`;
- `cognitiveLoopIntegrationTerrainMutated`;
- `cognitiveLoopIntegrationBounded`;
- `cognitiveLoopIntegrationDeterministicOrder`;
- `cognitiveLoopIntegrationDigestsEqual`;
- `cognitiveLoopIntegrationRepeatabilityFailures`.

## Future Events Contract

Primary future event:

```text
lab_cognitive_loop_integration_recorded
```

Minimum fields:

- `success`;
- `agentId`;
- `tick`;
- `goalBefore`;
- `selectedGoal`;
- `selectedAction`;
- `retrievedMemories`;
- `behaviorResultSummary`;
- `acceptedMemoryWrites`;
- `rejectedMemoryWrites`;
- `memoryCountBefore`;
- `memoryCountAfter`;
- `behaviorActionExecuted`;
- `movementStackUsed`.

Optional summary event:

```text
lab_cognitive_loop_integration_summary_recorded
```

Suggested fields:

- `success`;
- `agents`;
- `ticks`;
- `decisions`;
- `selectedGoals`;
- `selectedActions`;
- `behaviorResults`;
- `acceptedMemoryWrites`;
- `rejectedMemoryWrites`;
- `bounded`;
- `digestsEqual`;
- `repeatabilityFailures`.

## Future Invariant Contract

Minimum checks for Phase 5.6B:

- `scenario_name_expected`;
- `seed_recorded`;
- `report_success`;
- `agents_expected`;
- `ticks_expected`;
- `decisions_positive`;
- `retrieved_memories_positive`;
- `selected_goal_present`;
- `selected_action_present`;
- `behavior_result_present`;
- `memory_proposals_positive`;
- `accepted_writes_positive`;
- `rejected_writes_covered`;
- `memory_count_after_gte_before`;
- `max_writes_per_agent_tick_respected`;
- `retrieval_before_update`;
- `no_retrieval_rerun_after_update`;
- `behavior_action_not_executed`;
- `memory_mutation_only_through_memory_update`;
- `movement_stack_not_used`;
- `world_not_mutated`;
- `terrain_not_mutated`;
- `bounded_true`;
- `deterministic_order`;
- `digest_written`;
- `digest_repeat_written`;
- `digests_equal`;
- `repeatability_failures_zero`;
- `report_written`;
- `invariant_report_written`;
- `decisions_written`;
- `trace_written`;
- `memory_snapshot_written`;
- `digest_output_written`;
- `metrics_written`;
- `event_written`;
- `metrics_prefix_expected`;
- `event_name_expected`;
- `changelog_updated`;
- `dev_journal_updated`;
- `roadmap_updated`;
- `phase_plan_updated`;
- `success_contract_respected`.

## Recommended Phase 5.6B

`Phase 5.6B — Cognitive Loop Integration Fixture Smoke`

Probable new scenario:

```text
cognitive_loop_integration_fixture_smoke
```

Objective: create a fixture that orchestrates the existing cognitive components
for 3 to 5 synthetic agents without touching normal `agents_basic`.

The fixture should:

- create synthetic agent state and memory snapshots;
- run retrieval;
- run goal selection from retrieved memory;
- run the memory-goal bridge;
- produce behavior result summaries;
- run memory update from those behavior results;
- produce before/after memory snapshots;
- emit integrated report/invariant/trace/decisions/digest/metrics/events;
- cover safety, explore, observe, empty retrieval, and low-confidence
  continuity;
- include accepted and rejected memory writes;
- keep `behaviorActionExecuted = false`;
- keep `memoryMutatedOutsideUpdate = false`;
- keep `retrievalRerunUnexpected = false`;
- keep `movementStackUsed = false`;
- keep `worldMutated = false`;
- keep `terrainMutated = false`;
- leave `agents_basic` unchanged.

Future outputs:

- `cognitive_loop_integration_report.json`;
- `cognitive_loop_integration_invariant_report.json`;
- `cognitive_loop_integration_trace.json`;
- `cognitive_loop_integration_decisions.json`;
- `cognitive_loop_integration_memory_snapshot.json`;
- `cognitive_loop_integration_digest.json`;
- `metrics.json`;
- `events.ndjson`.

## Risks

- Creating a giant integration orchestrator instead of a small fixture builder.
- Duplicating existing component logic instead of reusing helpers or summaries.
- Turning `main.swift` into cognitive runtime ownership.
- Branching `agents_basic` into the new cognitive loop too early.
- Creating an infinite write -> retrieve -> write loop.
- Mutating memory outside `LabMemoryUpdate`.
- Executing actions instead of producing abstract results.
- Producing movement intent or calling the movement stack too early.
- Depending on `Dictionary` or `Set` iteration order.
- Expanding into mood, relationships, society, LLM, embeddings, Python, or RL
  before the integrated loop is proven.

## Explicit Out Of Scope

- no `agents_basic` integration;
- no live agent behavior mutation;
- no real behavior action execution;
- no World mutation;
- no terrain mutation;
- no movement stack;
- no movement intent;
- no route following;
- no pathfinding;
- no memory retrieval after update in v0;
- no iterative cognitive loop;
- no memory mutation outside `LabMemoryUpdate`;
- no mood;
- no emotional memory;
- no relationships;
- no trust;
- no communication;
- no community;
- no construction;
- no mining;
- no Python;
- no LLM;
- no embeddings;
- no RL;
- no save/load changes;
- no renderer changes;
- no resource changes;
- no registry changes;
- no golden changes.

## Definition Of Done For 5.6A

- document created;
- changelog updated;
- dev journal updated;
- roadmap updated;
- cognitive resync plan updated;
- 5.5A bridge plan updated;
- no Swift files changed;
- no runtime behavior changed;
- no scenarios added;
- `swift build` passes if possible;
- `swift build -c release --product Pebble` passes;
- `git diff --check` passes;
- next phase 5.6B is clearly specified.
