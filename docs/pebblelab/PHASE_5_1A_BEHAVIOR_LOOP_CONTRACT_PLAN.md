# Phase 5.1A — Behavior Loop Contract Planning

## Purpose

Phase 5.1A defines the technical contract for a future minimal cognitive
behavior loop before any runtime implementation.

This phase exists to prevent:

- mixing cognition, movement, and World interaction;
- adding society simulation before individual behavior ownership is clear;
- connecting goals directly to World mutation;
- duplicating more cognitive orchestration inside `main.swift`;
- treating the Agent Movement Stack as the cognitive agent.

Phase 5.1A is documentation-only. It adds no Swift code, scenario, runtime
metric, runtime event, movement stack behavior, World mutation, route following,
Python, LLM, or RL.

## Starting Point

Phase 4.28G closed the Agent Movement Stack consolidation chapter. The stack is
a deterministic movement sub-layer, not a completed cognitive system.

Phase 5.0A audited PebbleLab's current cognition state. `LabAgent` already has
abstract state, needs, health, fear, home, inventory, observation,
nearby-agent perception, `currentGoal`, last action/effect/movement,
append-only memory, and counters. Current agent scenarios already run a
minimal monolithic loop through `main.swift` and `LabAgent` methods.

Phase 5.1A now defines the behavior-loop contract that Phase 5.1B can
implement as a small fixture. The goal is to name inputs, outputs, ownership,
reports, metrics, events, invariants, and boundaries before adding code.

## Behavior Loop Definition

The target cognitive loop is:

1. perceive;
2. update needs;
3. read memory;
4. select goal;
5. select intended action;
6. optionally produce movement intent later;
7. apply abstract result;
8. consume feedback;
9. write memory;
10. emit metrics/events.

This is the long-term shape, not the immediate implementation. Phase 5.1B
should begin smaller: a fixture-only loop that builds explicit inputs,
produces deterministic decisions, applies abstract effects, writes bounded
memory entries, and reports invariants. It should not use the movement stack in
v0.

## Minimal v0 Loop Scope

Inputs:

- current `LabAgent` state;
- current observation, if present;
- `nearbyAgents`;
- `needs`;
- `currentGoal`;
- `lastActionEffect`;
- memory count or bounded memory summary;
- tick.

Outputs:

- selected goal or confirmed current goal;
- selected action;
- action effect;
- optional abstract movement result;
- memory entries appended;
- `behaviorLoopDecision` record.

Explicit v0 exclusions:

- no World mutation;
- no terrain mutation;
- no route following;
- no full-route execution;
- no persistent route commitment;
- no movement stack call;
- no social relation model;
- no mood model;
- no communication;
- no Python, LLM, or RL.

The fixture may use synthetic observations. If it uses existing World
observation, it must be read-only and must preserve the already established
World-observation boundaries.

## Proposed Types For Future Implementation

These types are proposed for Phase 5.1B or later. They are not implemented in
Phase 5.1A.

### `LabBehaviorLoopInput`

Suggested fields:

- `tick`;
- `agentId`;
- `position`;
- `needs`;
- `health`;
- `fear`;
- `homePosition`;
- `currentGoal`;
- `nearbyAgents`;
- `inventorySummary`;
- `lastActionEffectSummary`;
- `memorySummary`.

Purpose: capture the bounded cognitive inputs for one agent and one tick. It
should not read World, collision, registries, save/load, or movement stack
state.

### `LabBehaviorLoopDecision`

Suggested fields:

- `tick`;
- `agentId`;
- `goalBefore`;
- `goalAfter`;
- `selectedAction`;
- `reason`;
- `urgency`;
- `expectedEffect`;
- optional `movementIntentKind`;
- `memoryWritesPlanned`.

Purpose: record the cognitive choice before application. The decision may say
that movement intent would be useful, but v0 should not call the movement
stack.

### `LabBehaviorLoopResult`

Suggested fields:

- `tick`;
- `agentId`;
- `decision`;
- `actionEffect`;
- `movementApplied`;
- `feedbackConsumed`;
- `memoryEntriesWritten`;
- `success`.

Purpose: record what the fixture applied after the decision. For v0,
`feedbackConsumed` can be zero/false unless a synthetic fixture feedback input
is explicitly planned.

### `LabBehaviorLoopReport`

Suggested fields:

- `scenario`;
- `seed`;
- `ticks`;
- `agents`;
- `decisions`;
- `goalsSelected`;
- `actionsSelected`;
- `effectsApplied`;
- `memoriesWritten`;
- `movementIntentsProduced`;
- `movementStackUsed`;
- `worldMutated`;
- `success`.

Purpose: provide one compact report that distinguishes cognitive-loop evidence
from movement-stack evidence.

## Ownership Boundaries

`LabAgent` owns agent state. It may continue to store position, needs, health,
fear, home, inventory, observation, nearby agents, current goal, last
action/effect/movement, memory, and counters.

`LabBehaviorLoop` should own cognitive orchestration. It should turn bounded
inputs into decisions and results. It should not be hidden inside `main.swift`.

`LabGoal` owns the current objective shape: kind, reason, start tick, and
urgency. Future changes should keep goal selection explainable.

`LabAction` or the existing `LabAgentAction` shape should represent abstract
actions, not World mutations.

`LabMemory` or a future memory system should own append-only v0 memory writes
first. Retrieval, decay, emotional memory, and relationships are later work.

`LabMovementStackAdapter` should later bridge cognitive movement intent to the
movement stack. It should not own goal selection or memory meaning.

`main.swift` should remain the runner and output dispatcher. It should not gain
more cognitive decision ownership.

The movement stack remains a movement sub-layer. It is not the cognitive
decider and must not become globally active through the behavior loop.

## Relationship With Movement Stack

Future bridge:

```text
goal/action
-> movement intent proposal
-> movement stack
-> approved/denied
-> feedback
-> memory update
```

This bridge is not part of Phase 5.1A. It should probably not be part of Phase
5.1B either. The first implementation should prove a cognitive fixture without
movement stack usage, then a later phase can introduce a controlled adapter.

When the bridge is eventually added, it must preserve:

- explicit opt-in stack policy selection;
- no hidden movement stack activation;
- first-step-only handoff;
- feedback N to N+1 timing where applicable;
- no route following;
- no full-route execution;
- no persistent route commitment;
- no World/terrain mutation;
- no Core entity or physical placeholder movement unless a later phase
  explicitly plans it.

## Metrics Future Contract

Future Phase 5.1B metrics should use the prefix `behaviorLoop*`.

Candidate metrics:

- `behaviorLoopSuccess`;
- `behaviorLoopAgents`;
- `behaviorLoopTicks`;
- `behaviorLoopDecisions`;
- `behaviorLoopGoalsSelected`;
- `behaviorLoopGoalChanges`;
- `behaviorLoopActionsSelected`;
- `behaviorLoopEffectsApplied`;
- `behaviorLoopMemoryEntriesWritten`;
- `behaviorLoopMovementIntentsProduced`;
- `behaviorLoopMovementStackUsed`;
- `behaviorLoopWorldMutated`;
- `behaviorLoopTerrainMutated`;
- `behaviorLoopCoreEntityMoved`;
- `behaviorLoopPhysicalPlaceholderMoved`;
- `behaviorLoopRepeatabilityFailures`.

Metrics should summarize fixture evidence only. They must not activate runtime
behavior.

## Events Future Contract

Future Phase 5.1B events:

- `lab_behavior_loop_decision_recorded`;
- optionally `lab_behavior_loop_summary_recorded`.

Minimal event fields:

- `tick`;
- `scenario`;
- `agentId`;
- `goalBefore`;
- `goalAfter`;
- `selectedAction`;
- `reason`;
- `urgency`;
- `memoryWrites`;
- `movementIntentProduced`;
- `movementStackUsed`;
- `success`.

Events should be deterministic, bounded, and scenario-owned. They should not
replace the existing agent action, memory, goal, or movement events until a
later compatibility phase explicitly plans that migration.

## Invariants Future Contract

Minimum invariants for Phase 5.1B:

- scenario name expected;
- agent count expected;
- ticks expected;
- decisions > 0;
- each decision has `agentId`;
- each decision has `selectedAction`;
- `goalAfter` present;
- no World mutation;
- no terrain mutation;
- no Core entity movement;
- no physical placeholder movement;
- no route following;
- no full-route execution;
- no movement stack use for v0 unless explicitly planned;
- memory writes bounded;
- deterministic order;
- deterministic digest;
- `repeatabilityFailures = 0`.

Additional recommended invariants:

- every decision has a reason;
- every result references exactly one decision;
- memory writes match the report count;
- movement intent count is zero for v0 unless the scenario name and plan say
  otherwise;
- `behaviorLoopMovementStackUsed = false` for v0;
- all forbidden mutation flags remain false.

## Recommended Phase 5.1B

Phase 5.1B — Behavior Loop Contract Fixture Smoke.

Probable scenario name: `behavior_loop_contract_fixture_smoke`.

Goal: create a fixture with two or three abstract agents, no live World if
possible, or read-only World observation only if existing `LabAgent`
observation requires it.

The fixture should:

- create abstract agents;
- construct loop inputs;
- produce decisions;
- apply abstract effects;
- write bounded memory entries;
- produce report, invariant report, metrics, and event output;
- avoid movement stack usage;
- avoid World mutation;
- avoid terrain mutation;
- avoid physical placeholder movement;
- avoid Core entity movement;
- remain deterministic.

Future outputs:

- `behavior_loop_contract_report.json`;
- `behavior_loop_contract_invariant_report.json`;
- `behavior_loop_contract_decisions.json`;
- `behavior_loop_contract_digest.json`;
- `metrics.json`;
- `events.ndjson`.

## Risks

- Rebuilding a large behavior class inside `main.swift`;
- mixing behavior loop and movement stack ownership;
- making agents appear "intelligent" without reportable decisions;
- writing too many memory entries;
- using World when a fixture is enough;
- starting society simulation before the individual behavior loop is stable;
- connecting Python or LLMs before deterministic local contracts exist;
- making behavior metrics activate runtime behavior;
- treating movement-intent production as route following.

## Explicit Out Of Scope

- no mood;
- no relationships;
- no communication;
- no community;
- no construction;
- no mining;
- no Python;
- no LLM;
- no RL;
- no World mutation;
- no terrain mutation;
- no route following expansion;
- no full-route execution;
- no persistent route commitment;
- no runtime reservation table;
- no save/load changes;
- no renderer changes;
- no resource changes;
- no registry changes;
- no golden changes;
- no Swift runtime change in Phase 5.1A.

## Definition Of Done For 5.1A

- Document created;
- changelog updated;
- development journal updated;
- roadmap updated;
- cognitive resync plan updated;
- no Swift files changed;
- no runtime behavior changed;
- no scenarios added;
- `swift build` passes;
- `swift build -c release --product Pebble` passes;
- `git diff --check` passes;
- `git diff --cached --check` passes;
- next phase 5.1B is clearly specified.

## Validation

Commands for this docs-only phase:

- `git status`;
- `git branch --show-current`;
- `git pull origin lab/pebblelab-v1`;
- `git log --oneline -12`;
- `swift build`;
- `swift build -c release --product Pebble`;
- `git diff --check`;
- `git diff --cached --check`.

Results:

- `swift build` passed;
- `swift build -c release --product Pebble` passed;
- `git diff --check` passed.

`pebsmoke` is optional because this phase changes no Swift, runtime behavior,
scenario, movement stack code, Core simulation behavior, renderer, resources,
registries, save/load, or goldens.
