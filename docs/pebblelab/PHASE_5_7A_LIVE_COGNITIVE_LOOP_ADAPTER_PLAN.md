# Phase 5.7A — Live Cognitive Loop Adapter Planning

## Purpose

Phase 5.7A defines the v0 contract for a live/dry-run adapter between:

- `LabAgent` live state;
- cognitive loop integration;
- a future application plan.

The objective is to move from the integrated fixture chain toward an adapter
that can read real PebbleLab agents, without applying decisions yet:

```text
live agent state
-> adapter snapshot
-> cognitive loop input
-> cognitive loop output
-> safe application plan
-> no live mutation yet
```

This phase is planning-only. It adds no Swift runtime, no scenario, no runtime
metrics, no runtime events, no `LabAgent` mutation path, no `agents_basic`
integration, no movement stack call, no World mutation, no terrain mutation, no
mood, no relationships, no communication, no Python, no LLM, no embeddings,
and no RL.

## Starting Point

Phase 5.6B implemented `cognitive_loop_integration_fixture_smoke`, the first
fixture-only integrated cognitive loop. It reads synthetic memory snapshots,
runs retrieval, selects goals from retrieved memories, bridges the selected
goal into an abstract selected action, produces a behavior result summary, runs
bounded memory update, and writes before/after memory snapshots.

Phase 5.6C hardened that integrated chain with
`cognitive_loop_integration_hardening_smoke`. It covers safety, curiosity,
nearby-agent observation, empty retrieval, low-confidence/no override,
duplicate rejected writes, retrieval before update, no retrieval rerun after
update, max one accepted write per agent/tick, deterministic ordering, and
stable digests.

The integrated loop is now proven in fixtures, but it still uses synthetic
inputs. It does not yet read a live `LabAgent`, write to a live `LabAgent`, or
produce a live-safe application plan. Phase 5.7A prepares that adapter
contract before any runtime implementation.

## Current Live Agent State

`LabAgent` currently lives in `Sources/PebbleLab/LabAgent.swift`.

Current top-level fields:

- `id`: scenario-local stable id;
- `type`: initialized as `abstract_lab_agent`;
- `state`: string state such as `idle`, `resting`, `observing`, `moving`, or
  `waiting`;
- `position`: `LabAgentPosition` with integer `x`, `y`, and `z`;
- `needs`: `LabAgentNeeds` with `hunger`, `fatigue`, `curiosity`, and
  `safety`;
- `health`: integer health;
- `fear`: integer fear;
- `homePosition`: home/spawn position used by `seekSafety`;
- `inventory`: `LabInventory`, a deterministic string-to-count map;
- `observation`: optional `LabAgentObservation` from read-only World
  observation;
- `nearbyAgents`: `[LabNearbyAgentObservation]`;
- `currentGoal`: `LabGoal`;
- `lastAction`: optional `LabAgentAction`;
- `lastActionEffect`: optional `LabAgentActionEffect`;
- `lastMovement`: optional `LabAgentMovement`;
- `memory`: `[LabMemoryEntry]`;
- `tickCreated` and `ticksAlive`;
- counters for observations, nearby observations, goal selections, goal
  changes, actions, action effects, movement, total distance, return-home
  movement, and distance reduced toward home.

Derived live state:

- `isAlive` is `health > 0`;
- `distanceFromHome` is Manhattan distance from `position` to `homePosition`.

Current live methods mutate agent state:

- `tick()` increments hunger/fatigue, sets state to `idle`, and increments
  `ticksAlive`;
- `observe(world:tick:)` reads World state and may append an `observed`
  memory when a tick is provided;
- `observeNearbyAgents` replaces nearby-agent observations;
- `selectGoal(tick:)` may mutate `currentGoal` and goal counters;
- `decideAction(tick:)` may set `lastAction`, increment action count, and
  append memory;
- `applyLastActionEffect(tick:)` mutates needs/fear/state, sets
  `lastActionEffect`, and appends memory;
- `applyAbstractMovement(tick:)` mutates abstract position, movement counters,
  `lastMovement`, and memory;
- `remember(...)` appends a `LabMemoryEntry`.

Supporting types:

- `LabGoalKind`: `idle`, `rest`, `seekSafety`, `explore`,
  `observeOtherAgent`;
- `LabGoal`: kind, reason, started tick, urgency;
- `LabMemoryEntry`: tick, type, summary, importance;
- `LabInventory`: deterministic item counts with add/remove operations;
- observations and movement records are encodable, but not cognitive adapter
  ownership.

The adapter must treat this live state as read-only in v0. It must not call the
mutating methods above when building an adapter snapshot.

## Problem To Solve

The cognitive loop fixtures use synthetic snapshots. Live `LabAgent` has more
state and more ways to mutate accidentally.

Problems to solve before runtime implementation:

- extract a bounded read-only snapshot from a live agent;
- avoid calling live mutating methods while adapting;
- convert live state into cognitive-loop input without reading World or
  movement stack;
- distinguish computed decisions from applied decisions;
- produce a dry-run application plan instead of mutating the agent;
- keep `agents_basic` unchanged;
- prevent selected goals/actions from being applied too early;
- prevent live memory writes in the adapter;
- prevent retrieval/update reruns or iterative loops;
- keep deterministic ordering and digest evidence;
- keep movement stack, World mutation, terrain mutation, mood, relationships,
  and LLM systems out of scope.

## Adapter Contract V0

Input:

- live agent read-only view;
- tick;
- scenario options;
- cognitive loop config;
- initial memory view;
- `dryRun` forced to `true`;
- `maxRetrievedMemories`;
- `maxGoalCandidates`;
- `maxMemoryWritesPerTick`.

Output:

- adapter snapshot;
- cognitive loop input;
- cognitive loop decision;
- application plan;
- `wouldChangeGoal`;
- `wouldWriteMemory`;
- `wouldSelectAction`;
- applied flags all `false`;
- safety boundary flags;
- deterministic digest.

The adapter may compute what it would do, but it must not apply anything in
v0.

## Proposed Types For Future Implementation

These are proposed for Phase 5.7B or later. They are not implemented in Phase
5.7A.

### `LabLiveCognitiveLoopAdapterInput`

Suggested fields:

- `tick`;
- `agentId`;
- `liveAgentSummary`;
- `currentGoal`;
- `needsSummary`;
- `fear`;
- `health`;
- `memorySummary`;
- `observationSummary`;
- `dryRun`;
- `maxRetrievedMemories`;
- `maxGoalCandidates`;
- `maxMemoryWritesPerTick`;
- `reason`.

Purpose: represent one dry-run adapter request built from live-like agent
state.

### `LabLiveCognitiveLoopAdapterSnapshot`

Suggested fields:

- `tick`;
- `agentId`;
- `agentType`;
- `positionSummary`;
- `currentGoal`;
- `needsSummary`;
- `fear`;
- `health`;
- `memoryCount`;
- `nearbyAgentCount`;
- `observationAvailable`;
- `snapshotReadOnly`;
- `success`.

Purpose: capture the bounded live-agent read-only view before cognitive loop
conversion.

### `LabLiveCognitiveLoopApplicationPlan`

Suggested fields:

- `tick`;
- `agentId`;
- `computedSelectedGoal`;
- `computedSelectedAction`;
- `computedBehaviorResult`;
- `proposedMemoryWrites`;
- `wouldChangeGoal`;
- `wouldSelectAction`;
- `wouldWriteMemory`;
- `appliedGoalChange`;
- `appliedAction`;
- `appliedMemoryWrite`;
- `dryRun`;
- `reason`.

Purpose: make the distinction between computed and applied explicit.

### `LabLiveCognitiveLoopAdapterDecision`

Suggested fields:

- `tick`;
- `agentId`;
- `snapshot`;
- `cognitiveLoopDecisionSummary`;
- `applicationPlan`;
- `boundaryFlags`;
- `success`.

Purpose: record one end-to-end dry-run decision for one agent/tick.

### `LabLiveCognitiveLoopAdapterReport`

Suggested fields:

- `scenario`;
- `seed`;
- `agents`;
- `ticks`;
- `snapshots`;
- `decisions`;
- `applicationPlans`;
- `wouldChangeGoals`;
- `wouldSelectActions`;
- `wouldWriteMemories`;
- `appliedGoalChanges`;
- `appliedActions`;
- `appliedMemoryWrites`;
- `dryRun`;
- `liveAgentMutated`;
- `memoryMutated`;
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

Purpose: provide one compact proof that the adapter computes dry-run plans
without mutating live state.

## Adapter Flow V0

Target sequence:

1. Read live `LabAgent` state into adapter snapshot.
2. Freeze snapshot as read-only.
3. Convert snapshot to cognitive loop input.
4. Run or simulate cognitive loop integration using the snapshot.
5. Produce application plan.
6. Do not apply the plan.
7. Emit report, invariants, metrics, and events.
8. Keep `agents_basic` unchanged.

Phase 5.7B should probably use a dedicated scenario:

```text
live_cognitive_loop_adapter_fixture_smoke
```

That scenario may use synthetic `LabAgent` values or live-like snapshots, but
it should represent the future adapter boundary rather than modify normal
agent runtime.

## Dry-Run Rules V0

Rules:

- `dryRun` must be `true`;
- `appliedGoalChange = false`;
- `appliedAction = false`;
- `appliedMemoryWrite = false`;
- `liveAgentMutated = false`;
- `memoryMutated = false`, except for a separate simulated memory output that
  is explicitly marked non-live;
- `movementStackUsed = false`;
- `worldMutated = false`;
- `terrainMutated = false`.

The adapter may report `would*` values, but every `applied*` value must remain
false in v0.

## Application Plan Rules V0

The application plan may say:

- `wouldChangeGoal = true/false`;
- `wouldSelectAction = true/false`;
- `wouldWriteMemory = true/false`.

It must not apply those changes.

The plan must contain:

- `computedSelectedGoal`;
- `computedSelectedAction`;
- `computedBehaviorResult`;
- `proposedMemoryWrites`;
- a non-empty reason.

The plan should be auditable enough that a later phase can decide which subset
is safe to apply. That later phase must be explicit; 5.7B should remain
dry-run.

## Relationship With Cognitive Loop Integration

The adapter does not replace `LabCognitiveLoopIntegration`.

It wraps it:

```text
live state
-> adapter snapshot
-> cognitive-loop-compatible input
-> cognitive output
-> dry-run application plan
```

The integrated cognitive loop remains the owner of retrieval, goal selection,
bridge, behavior result, and memory update fixture evidence. The adapter owns
the live-state boundary and the computed-vs-applied distinction.

## Relationship With `agents_basic`

`agents_basic` remains unchanged.

Phase 5.7B must use a dedicated scenario. It must not alter the existing
per-tick live agent flow, and it must not call live `selectGoal`,
`decideAction`, `applyLastActionEffect`, `applyAbstractMovement`, or
`remember` as part of adapter application.

No behavior change should reach `agents_basic` before a later phase explicitly
dedicated to live application.

## Relationship With Movement Stack

The movement stack remains out of scope.

Even if a computed selected action implies movement, Phase 5.7A and Phase 5.7B
must not produce:

- movement intents;
- route following;
- reservations;
- pathfinding;
- first-step handoff;
- physical movement;
- Core entity movement;
- physical placeholder movement.

Movement can only appear as a string in a dry-run application plan, not as a
runtime call.

## Relationship With Mood / Relations / LLM

The adapter prepares future integration, but it must not add:

- mood;
- emotional memory;
- relationships;
- trust;
- communication;
- community state;
- LLM context;
- Python integration;
- RL;
- embeddings.

Those systems require their own contracts after the live adapter boundary is
proven dry-run and deterministic.

## Future Metrics Contract

Prefix:

```text
liveCognitiveLoopAdapter*
```

Proposed metrics:

- `liveCognitiveLoopAdapterSuccess`;
- `liveCognitiveLoopAdapterAgents`;
- `liveCognitiveLoopAdapterTicks`;
- `liveCognitiveLoopAdapterSnapshots`;
- `liveCognitiveLoopAdapterDecisions`;
- `liveCognitiveLoopAdapterApplicationPlans`;
- `liveCognitiveLoopAdapterWouldChangeGoals`;
- `liveCognitiveLoopAdapterWouldSelectActions`;
- `liveCognitiveLoopAdapterWouldWriteMemories`;
- `liveCognitiveLoopAdapterAppliedGoalChanges`;
- `liveCognitiveLoopAdapterAppliedActions`;
- `liveCognitiveLoopAdapterAppliedMemoryWrites`;
- `liveCognitiveLoopAdapterDryRun`;
- `liveCognitiveLoopAdapterLiveAgentMutated`;
- `liveCognitiveLoopAdapterMemoryMutated`;
- `liveCognitiveLoopAdapterMovementStackUsed`;
- `liveCognitiveLoopAdapterWorldMutated`;
- `liveCognitiveLoopAdapterTerrainMutated`;
- `liveCognitiveLoopAdapterBounded`;
- `liveCognitiveLoopAdapterDeterministicOrder`;
- `liveCognitiveLoopAdapterDigestsEqual`;
- `liveCognitiveLoopAdapterRepeatabilityFailures`.

## Future Events Contract

Primary future event:

```text
lab_live_cognitive_loop_adapter_recorded
```

Minimum fields:

- `success`;
- `agentId`;
- `tick`;
- `currentGoal`;
- `computedSelectedGoal`;
- `computedSelectedAction`;
- `wouldChangeGoal`;
- `wouldSelectAction`;
- `wouldWriteMemory`;
- `appliedGoalChange`;
- `appliedAction`;
- `appliedMemoryWrite`;
- `dryRun`;
- `liveAgentMutated`;
- `movementStackUsed`.

Optional summary event:

```text
lab_live_cognitive_loop_adapter_summary_recorded
```

Fields:

- `success`;
- `agents`;
- `ticks`;
- `snapshots`;
- `decisions`;
- `applicationPlans`;
- `wouldChangeGoals`;
- `wouldSelectActions`;
- `wouldWriteMemories`;
- `appliedGoalChanges`;
- `appliedActions`;
- `appliedMemoryWrites`;
- `dryRun`;
- `bounded`;
- `digestsEqual`;
- `repeatabilityFailures`.

## Future Invariant Contract

Minimum checks for Phase 5.7B:

- scenario name expected;
- seed recorded;
- report success;
- agents expected;
- ticks expected;
- snapshots positive;
- decisions positive;
- application plans positive;
- dryRun true;
- applied goal changes zero;
- applied actions zero;
- applied memory writes zero;
- would change goal covered;
- would select action covered;
- would write memory covered;
- live agent not mutated;
- memory not mutated live;
- movement stack not used;
- no World mutation;
- no terrain mutation;
- bounded true;
- deterministic order;
- digest repeat equals digest;
- repeatability failures zero;
- report written;
- invariant report written;
- snapshots written;
- application plans written;
- digest written;
- metrics written;
- event written.

## Recommended Phase 5.7B

Recommended implementation:

```text
Phase 5.7B — Live Cognitive Loop Adapter Fixture Smoke
```

Probable scenario:

```text
live_cognitive_loop_adapter_fixture_smoke
```

Objective: create a fixture that takes live-like agents or snapshots, produces
a cognitive decision, and then emits a dry-run application plan.

The fixture should:

- create 3 to 5 agents or live-like snapshots;
- extract read-only snapshots;
- build cognitive loop inputs;
- produce application plans;
- cover `wouldChangeGoal`;
- cover `wouldSelectAction`;
- cover `wouldWriteMemory`;
- keep `appliedGoalChange=false`;
- keep `appliedAction=false`;
- keep `appliedMemoryWrite=false`;
- verify `liveAgentMutated=false`;
- not modify `agents_basic`;
- not call the movement stack;
- not mutate World;
- remain deterministic.

Future outputs:

- `live_cognitive_loop_adapter_report.json`;
- `live_cognitive_loop_adapter_invariant_report.json`;
- `live_cognitive_loop_adapter_snapshots.json`;
- `live_cognitive_loop_adapter_application_plans.json`;
- `live_cognitive_loop_adapter_digest.json`;
- `metrics.json`;
- `events.ndjson`.

## Risks

- branching `agents_basic` too early;
- writing directly into `LabAgent`;
- confusing computed decisions with applied decisions;
- triggering action or movement by accident;
- performing live memory update too early;
- turning the adapter into a monolith;
- depending on non-deterministic dictionary or set order;
- hiding mutations behind copied structs;
- forgetting that `dryRun` must be true in v0.

## Explicit Out Of Scope

- no `agents_basic` integration;
- no live agent mutation;
- no applied goal changes;
- no applied actions;
- no applied memory writes;
- no live memory update;
- no World mutation;
- no movement stack;
- no route following;
- no iterative cognitive loop;
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

## Definition Of Done For 5.7A

- document created;
- changelog updated;
- dev journal updated;
- roadmap updated;
- cognitive resync plan updated;
- 5.6A cognitive integration plan updated;
- no Swift files changed;
- no runtime behavior changed;
- no scenarios added;
- `swift build` passes if possible;
- `swift build -c release --product Pebble` passes;
- `git diff --check` passes;
- next phase 5.7B is clearly specified.

## Phase 5.7B Implementation Status

Phase 5.7B implemented the adapter-only dry-run scenario
`live_cognitive_loop_adapter_fixture_smoke`.

Snapshots:

- five live-like adapter agents are represented;
- each produces a read-only adapter snapshot;
- snapshots include agent id/type, position summary, current goal, needs
  summary, fear, health, memory count, nearby-agent count, observation
  availability, and `snapshotReadOnly=true`.

Application plans:

- safety dry-run computes `seekSafety` / `seekSafety`;
- curiosity dry-run computes `explore` / `explore`;
- nearby-agent dry-run computes `observeOtherAgent` / `observeAgent`;
- unchanged-goal dry-run keeps `explore`;
- no-write dry-run keeps `idle` and proposes zero memory writes.

Dry-run rules:

- `dryRun=true`;
- `appliedGoalChange=false`;
- `appliedAction=false`;
- `appliedMemoryWrite=false`;
- `liveAgentMutated=false`;
- `memoryMutated=false`;
- `movementStackUsed=false`;
- `worldMutated=false`;
- `terrainMutated=false`.

Report:

- agents: 5;
- snapshots: 5;
- decisions: 5;
- application plans: 5;
- `wouldChangeGoals`: 3;
- `wouldSelectActions`: 5;
- `wouldWriteMemories`: 4;
- applied goal/action/memory counts: 0/0/0.

Outputs:

- `live_cognitive_loop_adapter_report.json`;
- `live_cognitive_loop_adapter_invariant_report.json`;
- `live_cognitive_loop_adapter_snapshots.json`;
- `live_cognitive_loop_adapter_application_plans.json`;
- `live_cognitive_loop_adapter_digest.json`;
- `metrics.json`;
- `events.ndjson`.

Metrics/events:

- metrics use the `liveCognitiveLoopAdapter*` prefix;
- the primary event is `lab_live_cognitive_loop_adapter_recorded`;
- a summary event `lab_live_cognitive_loop_adapter_summary_recorded` is also
  emitted.

Limitations:

- no live `agents_basic` integration;
- no live agent mutation;
- no live memory write or mutation;
- no applied goal changes;
- no applied actions;
- no movement stack;
- no World or terrain mutation;
- no mood, relationships, communication, social memory, Python, LLM,
  embeddings, or RL.

Next phase: Phase 5.7C - Live Cognitive Loop Adapter Hardening.

## Phase 5.7C Implementation Status

Phase 5.7C implemented the adapter-only dry-run hardening scenario
`live_cognitive_loop_adapter_hardening_smoke`.

Cases:

- 23 hardening cases;
- baseline compatibility with the 5.7B fixture;
- read-only snapshots;
- `wouldChangeGoal` true and false;
- `wouldSelectAction`;
- `wouldWriteMemory` true and false;
- all applied flags zero;
- forced `dryRun=true`;
- no live agent mutation;
- no memory mutation;
- no movement stack;
- no World or terrain mutation;
- unknown computed goal handling;
- missing computed action handling;
- no-write application plan;
- unchanged current goal;
- deterministic order;
- bounded output;
- digest repeatability;
- explicit boundary flags.

Snapshots:

- seven live-like adapter snapshots are emitted;
- all snapshots are read-only;
- no snapshot is used to mutate a live agent.

Application plans:

- safety, curiosity, nearby-agent observation, unchanged-goal, and no-write
  baseline plans remain covered;
- unknown computed goals are sanitized to `idle` and never applied;
- missing computed actions use an `idle` fallback and are never applied;
- all plans remain dry-run;
- `appliedGoalChange=false`, `appliedAction=false`, and
  `appliedMemoryWrite=false`.

Report:

- `live_cognitive_loop_adapter_hardening_report.json`;
- `live_cognitive_loop_adapter_hardening_invariant_report.json`;
- `live_cognitive_loop_adapter_hardening_cases.json`;
- `live_cognitive_loop_adapter_hardening_snapshots.json`;
- `live_cognitive_loop_adapter_hardening_application_plans.json`;
- `live_cognitive_loop_adapter_hardening_digest.json`.

Invariant:

- validates the 23 cases;
- validates positive snapshots/decisions/application plans;
- validates all applied counts are zero;
- validates read-only snapshots, no-write coverage, unchanged-goal coverage,
  deterministic order, bounded output, explicit boundary flags, and digest
  repeatability.

Digest:

- deterministic digest is written;
- digest repeat equals digest;
- repeatability failures remain zero.

Metrics/events:

- metrics use the `liveCognitiveLoopAdapterHardening*` prefix;
- the primary event is `lab_live_cognitive_loop_adapter_hardening_recorded`.

Limitations:

- no live `agents_basic` integration;
- no applied goal changes;
- no applied actions;
- no applied memory writes;
- no live memory mutation;
- no movement stack;
- no World or terrain mutation;
- no mood, relationships, communication, social memory, Python, LLM,
  embeddings, or RL.

Next phase: Phase 5.8A - Live Cognitive Loop Controlled Application Planning.

## Phase 5.8A Planning Link

Phase 5.8A is documented in
`PHASE_5_8A_LIVE_COGNITIVE_LOOP_CONTROLLED_APPLICATION_PLAN.md`.

It prepares the next boundary after the live cognitive loop adapter: a
controlled application safety gate that consumes dry-run application plans and
produces eligibility, rejection, or deferred decisions.

The controlled application plan keeps Phase 5.8B fixture-only and dry-run-like:

- no applied goal changes;
- no applied actions;
- no applied memory writes;
- no live agent mutation;
- no live memory mutation;
- no movement stack;
- no World or terrain mutation;
- no `agents_basic` integration.
