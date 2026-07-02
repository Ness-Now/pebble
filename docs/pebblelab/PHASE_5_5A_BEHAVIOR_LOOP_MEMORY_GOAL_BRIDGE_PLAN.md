# Phase 5.5A — Behavior Loop Memory-Goal Bridge Planning

## Purpose

Phase 5.5A defines the integration contract between:

- behavior loop;
- memory retrieval;
- goal selection from retrieved memory.

The objective is to move from isolated fixture components toward a controlled
cognitive chain:

```text
behavior loop input
-> retrieval summary
-> goal selection from memory
-> selected goal
-> action selection
-> behavior result
```

This phase does not implement runtime integration. It adds no Swift code, no
scenario, no runtime metric, no runtime event, no `LabAgent` behavior change,
no movement stack call, no World access, no memory mutation, no mood, no
relationships, no communication, no Python, no LLM, and no RL.

## Starting Point

Phase 5.1B added `behavior_loop_contract_fixture_smoke`, the first
fixture-only behavior loop contract. It builds bounded inputs, decisions,
results, reports, invariant reports, metrics, events, and stable digests.

Phase 5.1C added `behavior_loop_hardening_smoke`, covering deterministic
behavior-loop boundary cases such as seekSafety, explore, observeOtherAgent,
idle fallback, missing goal fallback, empty nearby agents, existing memory,
empty inventory, extreme needs, action/effect bounds, stable order, and digest
repeatability.

Phase 5.2B added `memory_update_from_behavior_result_fixture_smoke`, the first
fixture-only memory update layer from controlled behavior-loop results.

Phase 5.2C added `memory_update_hardening_smoke`, hardening memory update with
duplicate rejection, max one accepted write per agent/tick, allowed memory
types, importance bounds, non-empty summaries, deterministic ordering, and
stable digests.

Phase 5.3B added `memory_retrieval_fixture_smoke`, the first read-only memory
retrieval fixture. It ranks controlled memories across recent, important,
by-type, safety-related, curiosity-related, and nearby-agent-related queries.

Phase 5.3C added `memory_retrieval_hardening_smoke`, hardening retrieval with
invalid query rejection, bounded maxResults, minImportance, recency windows,
score bounds, rank contiguity, deterministic tie-breaks, unsorted input, no
memory mutation, and digest repeatability.

Phase 5.4B added `goal_selection_from_memory_fixture_smoke`, the first
fixture-only layer that turns controlled retrieved memories into goal
candidates and selected goal proposals.

Phase 5.4C added `goal_selection_from_memory_hardening_smoke`, hardening goal
selection from memory with 23 cases covering safety/curiosity conflicts,
low-confidence memory, unknown memory/goal handling, duplicate merges,
candidate bounds, no behavior action execution, no memory mutation, no
retrieval rerun, no movement stack, and stable digest.

All components remain isolated fixtures. Phase 5.5A prepares the bridge that
can later connect them without making `main.swift`, `LabAgent`, or the
movement stack own cognition.

## Current Behavior Loop State

The current behavior-loop fixture code is in `LabBehaviorLoop.swift`.

Current inputs are represented by `LabBehaviorLoopInput`:

- `tick`;
- `agentId`;
- `position`;
- `needsSummary`;
- `health`;
- `fear`;
- `homePosition`;
- `currentGoal`;
- `nearbyAgentCount`;
- `inventorySummary`;
- `lastActionEffectSummary`;
- `memoryCount`.

Current decisions are represented by `LabBehaviorLoopDecision`:

- `tick`;
- `agentId`;
- `goalBefore`;
- `goalAfter`;
- `selectedAction`;
- `reason`;
- `urgency`;
- `expectedEffect`;
- `movementIntentProduced`;
- `movementIntentKind`;
- `memoryWritesPlanned`.

Current results are represented by `LabBehaviorLoopResult`:

- `tick`;
- `agentId`;
- `decision`;
- `actionEffect`;
- `memoryEntriesWritten`;
- `movementApplied`;
- `movementStackUsed`;
- `success`.

Current reports count decisions, selected goals, goal changes, selected
actions, applied effects, memory entries written, movement intents produced,
movement stack usage, World/terrain mutation, Core entity movement, physical
placeholder movement, digest equality, and repeatability failures.

Current limits:

- behavior-loop fixtures do not consume retrieved memories;
- behavior-loop fixtures do not consume `LabGoalSelectionFromMemoryDecision`;
- `goalAfter` is still selected inside the fixture behavior-loop logic;
- `memoryEntriesWritten` is a bounded fixture counter, not the dedicated
  `LabMemoryUpdate` system;
- movementIntentProduced remains false in these cognitive fixtures;
- movementStackUsed remains false;
- behavior-loop fixtures do not mutate World, terrain, Core entities, or
  physical placeholders.

## Current Memory/Goal State

Memory update exists as a fixture-only layer:

- behavior result -> memory update input;
- proposal;
- accept/reject;
- bounded append;
- before/after memory snapshot;
- report/invariants/metrics/events/digest.

Memory retrieval exists as a read-only fixture-only layer:

- memory entries;
- retrieval query;
- considered memories;
- ranked retrieved records;
- retrieval result;
- report/invariants/metrics/events/digest.

Goal selection from retrieved memory exists as a fixture-only layer:

- retrieved memories;
- goal selection input;
- goal candidates;
- candidate scoring;
- selected goal;
- decision;
- report/invariants/metrics/events/digest.

No current runtime path connects these layers into `agents_basic` or the
normal `LabAgent` loop. No current behavior-loop fixture takes a
memory-informed goal decision as an input.

## Problem To Solve

The current components are still islands. A cognitive chain needs a safe bridge
from memory-informed goal proposals into behavior-loop decision/result
production.

Problems to solve before implementation:

- the behavior loop must receive memory context explicitly;
- goal selection from memory must remain a bounded input, not hidden global
  behavior;
- retrieved memories must not be fetched implicitly by every behavior step;
- the bridge must not execute actions;
- the bridge must not write memory;
- the bridge must not mutate World, terrain, Core entities, or placeholders;
- selectedGoal must not be confused with selectedAction;
- selectedAction must remain abstract and auditable;
- needs/fear must still be able to override memory;
- weak memories must not always overwrite currentGoal;
- the bridge must remain deterministic and reportable;
- `main.swift` must remain the runner/output dispatcher, not the cognitive
  owner.

## Bridge Contract V0

Input:

- agent state snapshot;
- behavior loop input;
- optional retrieved memory results;
- optional goal selection memory decision;
- currentGoal;
- needs/fear/health summary;
- tick;
- maxCandidates;
- maxRetrievedMemories;
- deterministic ordering policy.

Output:

- bridge decision;
- goalBefore;
- memorySuggestedGoal;
- selectedGoalForBehaviorLoop;
- goalChangedByMemory;
- selectedAction;
- actionReason;
- behavior result/effect summary;
- memory influence summary;
- empty retrieval marker;
- side-effect boundary flags;
- deterministic digest.

The v0 bridge is an orchestrated fixture. It consumes already-provided
retrieval/goal-selection evidence and produces a behavior-loop-facing decision.
It should not rerun retrieval, mutate memory, write memory, execute actions,
create movement intents, call the movement stack, or touch World/terrain.

## Proposed Types For Future Implementation

These types are proposed for Phase 5.5B or later. They are not implemented in
Phase 5.5A.

### `LabBehaviorLoopMemoryGoalBridgeInput`

Suggested fields:

- `tick`;
- `agentId`;
- `currentGoal`;
- `behaviorLoopInputSummary`;
- `retrievedMemoryResultSummary`;
- `goalSelectionDecision`;
- `needsSummary`;
- `fear`;
- `health`;
- `maxCandidates`;
- `reason`.

Purpose: represent one bounded bridge request from agent/behavior-loop state
plus already-provided memory/goal-selection evidence.

### `LabBehaviorLoopMemoryGoalBridgeDecision`

Suggested fields:

- `tick`;
- `agentId`;
- `goalBefore`;
- `memorySuggestedGoal`;
- `selectedGoalForBehaviorLoop`;
- `goalChangedByMemory`;
- `selectedAction`;
- `actionReason`;
- `memoryInfluenceApplied`;
- `memoryInfluenceReason`;
- `emptyRetrieval`;
- `behaviorResultSummary`;
- `success`.

Purpose: record how the bridge selected the goal/action pair that a future
behavior loop would consume, without executing the action.

### `LabBehaviorLoopMemoryGoalBridgeReport`

Suggested fields:

- `scenario`;
- `seed`;
- `agents`;
- `ticks`;
- `bridgeDecisions`;
- `memorySuggestedGoals`;
- `selectedGoals`;
- `goalChangesByMemory`;
- `unchangedGoals`;
- `selectedActions`;
- `behaviorResults`;
- `memoryInfluencedDecisions`;
- `emptyRetrievalDecisions`;
- `behaviorActionExecuted`;
- `memoryMutated`;
- `retrievalRerun`;
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

Purpose: keep the bridge auditable as a separate cognitive boundary before it
is allowed to affect any normal runtime scenario.

## Bridge Flow V0

The target bridge sequence is:

1. Build a behavior-loop input from controlled agent state.
2. Consume a provided retrieval result summary.
3. Consume a provided goal-selection-from-memory decision.
4. Decide `selectedGoalForBehaviorLoop`.
5. Select an abstract action using existing behavior-loop action rules.
6. Produce a bounded behavior result/effect summary.
7. Do not update memory.
8. Do not execute movement or action in the World.
9. Emit report, invariants, metrics, events, and digest.

Phase 5.5B should likely use synthetic snapshots and existing fixture-output
shapes. It should not directly wire this bridge into `agents_basic`.

## Goal Override Rules V0

Rules:

- safety/fear can override currentGoal;
- empty retrieval keeps currentGoal;
- weak or low-confidence memory does not override currentGoal;
- currentGoal continuity is allowed;
- memorySuggestedGoal must be a known v0 goal;
- selectedGoalForBehaviorLoop must always be present;
- goalChangedByMemory must be explicit;
- memoryInfluenceReason must be non-empty when memory influence is applied;
- needs/fear arbitration must be explainable in the decision record;
- no random tie-breaks.

Known v0 goals should remain:

- `seekSafety`;
- `explore`;
- `observeOtherAgent`;
- `idle`;
- `rest` only if the bridge deliberately preserves existing behavior-loop
  rest handling.

## Action Selection Rules V0

The bridge may select an abstract action corresponding to
`selectedGoalForBehaviorLoop`:

- `seekSafety` -> `seekSafety`;
- `explore` -> `explore`;
- `observeOtherAgent` -> `observeAgent`;
- `idle` -> `idle`;
- `rest` -> `rest`, if rest is represented in the fixture.

The bridge must not execute the action. It should only produce a selected
action string and a bounded behavior result/effect fixture summary.

The action rule should remain deterministic and table-driven. It must not
call pathfinding, movement stack, route following, World collision, terrain
mutation, Core entity movement, or physical placeholder movement.

## Relationship With Memory Update

The bridge output can later feed memory update:

```text
selectedGoalForBehaviorLoop
-> selectedAction
-> behavior result
-> memory update input
-> memory update proposal
```

Phase 5.5B should not attempt a complete write -> retrieve -> goal -> action
-> write loop if that makes the fixture too large. The first bridge fixture
should prove that memory-informed selected goals can influence abstract action
selection and behavior results while memory remains unchanged.

## Relationship With Movement Stack

The movement stack remains out of scope.

Even if `selectedGoalForBehaviorLoop` implies movement, Phase 5.5A and the
recommended Phase 5.5B should not produce movement intents, call the movement
stack, do route following, perform pathfinding, reserve positions, move Core
entities, move physical placeholders, or mutate World/terrain.

Movement intent can be planned later only after the memory-goal bridge is
validated as a cognitive fixture.

## Relationship With Mood / Relations / LLM

This bridge is a prerequisite for richer cognition:

- mood;
- emotional memory;
- relationships;
- social trust;
- social plans;
- LLM context building.

None of those systems should be implemented in Phase 5.5A or Phase 5.5B. The
bridge should remain deterministic, fixture-only, bounded, and explainable.

## Future Metrics Contract

Prefix: `behaviorLoopMemoryGoalBridge*`

Proposed metrics:

- `behaviorLoopMemoryGoalBridgeSuccess`;
- `behaviorLoopMemoryGoalBridgeAgents`;
- `behaviorLoopMemoryGoalBridgeTicks`;
- `behaviorLoopMemoryGoalBridgeDecisions`;
- `behaviorLoopMemoryGoalBridgeMemorySuggestedGoals`;
- `behaviorLoopMemoryGoalBridgeSelectedGoals`;
- `behaviorLoopMemoryGoalBridgeGoalChangesByMemory`;
- `behaviorLoopMemoryGoalBridgeUnchangedGoals`;
- `behaviorLoopMemoryGoalBridgeSelectedActions`;
- `behaviorLoopMemoryGoalBridgeBehaviorResults`;
- `behaviorLoopMemoryGoalBridgeInfluencedDecisions`;
- `behaviorLoopMemoryGoalBridgeEmptyRetrievalDecisions`;
- `behaviorLoopMemoryGoalBridgeBehaviorActionExecuted`;
- `behaviorLoopMemoryGoalBridgeMemoryMutated`;
- `behaviorLoopMemoryGoalBridgeRetrievalRerun`;
- `behaviorLoopMemoryGoalBridgeMovementStackUsed`;
- `behaviorLoopMemoryGoalBridgeWorldMutated`;
- `behaviorLoopMemoryGoalBridgeTerrainMutated`;
- `behaviorLoopMemoryGoalBridgeBounded`;
- `behaviorLoopMemoryGoalBridgeDeterministicOrder`;
- `behaviorLoopMemoryGoalBridgeDigestsEqual`;
- `behaviorLoopMemoryGoalBridgeRepeatabilityFailures`.

## Future Events Contract

Main future event:

`lab_behavior_loop_memory_goal_bridge_recorded`

Minimum fields:

- `success`;
- `agentId`;
- `tick`;
- `goalBefore`;
- `memorySuggestedGoal`;
- `selectedGoalForBehaviorLoop`;
- `goalChangedByMemory`;
- `selectedAction`;
- `memoryInfluenceApplied`;
- `memoryInfluenceReason`;
- `emptyRetrieval`;
- `behaviorActionExecuted`.

Optional summary event:

`lab_behavior_loop_memory_goal_bridge_summary_recorded`

Suggested fields:

- `success`;
- `agents`;
- `ticks`;
- `decisions`;
- `selectedGoals`;
- `goalChangesByMemory`;
- `selectedActions`;
- `behaviorResults`;
- `influencedDecisions`;
- `emptyRetrievalDecisions`;
- `bounded`;
- `digestsEqual`;
- `repeatabilityFailures`.

## Future Invariant Contract

Minimum checks for Phase 5.5B:

- scenario name expected;
- seed recorded;
- report success;
- agents expected;
- ticks expected;
- bridge decisions positive;
- selected goal present;
- known v0 goals only;
- selected action present;
- goal changes by memory covered;
- unchanged goal covered;
- memory influence covered;
- empty retrieval covered;
- behavior result present;
- behavior action not executed;
- memory not mutated;
- retrieval not rerun;
- movement stack not used;
- no World mutation;
- no terrain mutation;
- bounded true;
- deterministic order;
- digest written;
- digest repeat written;
- digest repeat equals digest;
- repeatability failures zero;
- report written;
- invariant report written;
- decisions written;
- digest written;
- metrics written;
- event written;
- success contract respected.

## Recommended Phase 5.5B

`Phase 5.5B — Behavior Loop Memory-Goal Bridge Fixture Smoke`

Probable scenario:

`behavior_loop_memory_goal_bridge_fixture_smoke`

Goal: create a fixture that consumes controlled goal-selection-from-memory
decisions and produces memory-informed behavior-loop decisions/results.

The fixture should:

- create 3 to 5 agent snapshots;
- include safety -> `seekSafety` -> selectedAction `seekSafety`;
- include curiosity -> `explore` -> selectedAction `explore`;
- include nearby -> `observeOtherAgent` -> selectedAction `observeAgent`;
- include empty retrieval -> currentGoal unchanged;
- include low-confidence memory -> currentGoal unchanged;
- produce bridge decisions;
- produce behavior results;
- avoid memory writes;
- avoid retrieval reruns;
- avoid behavior action execution;
- avoid movement stack usage;
- avoid World/terrain mutation;
- remain deterministic.

Future outputs:

- `behavior_loop_memory_goal_bridge_report.json`;
- `behavior_loop_memory_goal_bridge_invariant_report.json`;
- `behavior_loop_memory_goal_bridge_decisions.json`;
- `behavior_loop_memory_goal_bridge_digest.json`;
- `metrics.json`;
- `events.ndjson`.

## Risks

- turning `main.swift` into a cognitive orchestrator;
- wiring the bridge into `agents_basic` too early;
- producing real side effects too early;
- confusing selectedGoal with executed action;
- writing memory inside the bridge;
- rerunning retrieval inside the bridge;
- letting memory always override needs/fear;
- calling movement stack too early;
- adding mood or relationships too early;
- using non-deterministic scoring or unordered container iteration;
- growing existing fixture files without a future separation plan.

## Explicit Out Of Scope

- no `agents_basic` integration;
- no live behavior loop mutation;
- no behavior action execution;
- no memory write;
- no memory mutation;
- no retrieval rerun;
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
- no World mutation;
- no movement stack;
- no route following expansion;
- no full-route execution;
- no runtime reservation table;
- no save/load changes;
- no renderer changes.

## Definition Of Done For 5.5A

- document created;
- changelog updated;
- dev journal updated;
- roadmap updated;
- cognitive resync plan updated;
- goal selection memory plan updated;
- no Swift files changed;
- no runtime behavior changed;
- no scenarios added;
- `swift build` passes;
- `swift build -c release --product Pebble` passes if launched;
- `git diff --check` passes;
- next phase 5.5B is clearly specified.

## Phase 5.5B Implementation Status

Phase 5.5B implemented the fixture-only scenario
`behavior_loop_memory_goal_bridge_fixture_smoke`.

Bridge flow:

- consume controlled memory retrieval and goal-selection summaries;
- choose `selectedGoalForBehaviorLoop`;
- map that goal to an abstract `selectedAction`;
- produce a bounded `behaviorResultSummary`;
- write report, invariant, decisions, digest, metrics, and events.

Selected goals and actions:

- `seekSafety` -> `seekSafety`;
- `explore` -> `explore`;
- `observeOtherAgent` -> `observeAgent`;
- empty retrieval keeps the current goal;
- low-confidence memory keeps currentGoal continuity.

Outputs:

- `behavior_loop_memory_goal_bridge_report.json`;
- `behavior_loop_memory_goal_bridge_invariant_report.json`;
- `behavior_loop_memory_goal_bridge_decisions.json`;
- `behavior_loop_memory_goal_bridge_digest.json`;
- `metrics.json`;
- `events.ndjson`.

Metrics/events:

- metrics use the `behaviorLoopMemoryGoalBridge*` prefix;
- the primary event is `lab_behavior_loop_memory_goal_bridge_recorded`;
- a summary event `lab_behavior_loop_memory_goal_bridge_summary_recorded` is
  also emitted.

Limitations:

- no behavior action execution;
- no memory write or mutation;
- no retrieval rerun;
- no movement intent or movement stack;
- no World or terrain mutation;
- no live `agents_basic` integration;
- no mood, relationships, communication, social memory, Python, LLM,
  embeddings, or RL.

Next phase: Phase 5.5C - Behavior Loop Memory-Goal Bridge Hardening.
