# Phase 5.2A — Memory Update From Behavior Result Planning

## Purpose

Phase 5.2A defines the technical contract for updating agent memory from
behavior-loop results.

This phase prepares the transformation:

```text
behavior result
-> memory update proposal
-> bounded memory write
-> future memory retrieval
```

It does not implement runtime memory behavior. It adds no Swift code, scenario,
runtime metrics, runtime events, movement stack integration, World mutation,
terrain mutation, Core entity movement, physical placeholder movement, mood,
relationships, communication, Python, LLM, or RL.

## Starting Point

Phase 5.1B added `behavior_loop_contract_fixture_smoke`, the first runtime
fixture for the minimal behavior-loop contract. It produced 3 agents, 3 ticks,
9 decisions, deterministic actions/effects, `memoryEntriesWritten = 9`,
`behaviorLoop*` metrics, and `lab_behavior_loop_decision_recorded` events.

Phase 5.1C added `behavior_loop_hardening_smoke`. It covered 12 deterministic
cases, 22 decisions, 22 bounded memory writes, `behaviorLoopHardening*`
metrics, `lab_behavior_loop_hardening_recorded`, stable digest equality, and
green invariants.

The behavior-loop fixtures now prove that decisions and results can be
reported. Memory still needs its own ownership contract: result-to-memory
proposal, acceptance, rejection, bounded append, before/after counts, and
future retrieval boundaries.

## Current Memory State

Current `LabAgent` memory is real but intentionally simple.

`LabAgent` contains:

- `memory: [LabMemoryEntry]`;
- `remember(tick:type:summary:importance:)`;
- encoded `memoryCount`;
- encoded `recentMemory`, currently the last 10 entries.

`LabMemoryEntry` currently contains only:

- `tick`;
- `type`;
- `summary`;
- `importance`.

Current memory writes are direct appends through `remember(...)`. They happen
from existing agent methods such as observation, action choice, action effect,
and abstract movement. Phase 5.1B/5.1C behavior-loop fixtures also append
bounded `behavior_loop_decision` entries while reporting
`memoryEntriesWritten`.

Current limits:

- no dedicated memory update proposal type;
- no accepted/rejected write model;
- no semantic allowlist beyond string `type`;
- no per-agent/per-tick memory budget contract outside fixture-local checks;
- no memory retrieval;
- no memory query;
- no decay;
- no emotional memory;
- no relationship or social-trust memory;
- no connection to Python, LLM, or RL.

## Problem To Solve

A behavior loop without structured memory remains mechanical. It can choose an
action and apply an effect, but it cannot yet report what should become durable
agent-local experience.

Writing memory directly from every action path also risks unbounded growth.
Future behavior should not accidentally create one memory for every tiny
intermediate detail, duplicate same-tick records, or let summaries depend on
unstable dictionary/set ordering.

The next step needs to separate:

- behavior result: what happened;
- memory update proposal: what might be remembered;
- accepted memory write: what is appended;
- rejected proposal: what was intentionally skipped;
- memory retrieval: later read/query behavior, still out of scope.

This separation prepares future goals, mood, relationships, social memory, and
LLM context without introducing them too early.

## Memory Update Contract V0

Input:

- `LabBehaviorLoopResult`;
- tick;
- agent id;
- goal/action/effect summary;
- previous memory count;
- optional nearby/social context summary;
- optional inventory summary;
- deterministic reason string.

Output:

- `LabMemoryUpdateProposal`;
- accepted/rejected status;
- rejection reason when rejected;
- memory entry to append when accepted;
- bounded write count;
- before/after memory counts.

The v0 contract should be fixture-only first. It should prove that behavior
results can be converted into auditable memory proposals without changing
normal `agents_basic` runtime behavior.

## Proposed Types For Future Implementation

These are proposed for Phase 5.2B or later. They are not implemented in
Phase 5.2A.

### `LabMemoryUpdateInput`

Suggested fields:

- `tick`;
- `agentId`;
- `goal`;
- `selectedAction`;
- `actionEffect`;
- `resultSuccess`;
- `memoryCountBefore`;
- `nearbyAgentCount`;
- `inventorySummary`;
- `reason`.

Purpose: capture the bounded source information used to decide whether one
behavior result should become memory. It should be constructed from behavior
loop results and explicit summaries, not by reading World or movement stack
state.

### `LabMemoryUpdateProposal`

Suggested fields:

- `tick`;
- `agentId`;
- `memoryType`;
- `summary`;
- `importance`;
- `source`;
- `accepted`;
- optional `rejectionReason`.

Purpose: represent a candidate memory write before mutation. It should be
stable, auditable, and deterministic whether accepted or rejected.

### `LabMemoryUpdateResult`

Suggested fields:

- `tick`;
- `agentId`;
- `proposals`;
- `acceptedWrites`;
- `rejectedWrites`;
- `memoryCountBefore`;
- `memoryCountAfter`;
- `bounded`;
- `success`.

Purpose: record how many proposals were produced, what was accepted, what was
rejected, and whether the per-agent/tick budget was respected.

### `LabMemoryUpdateReport`

Suggested fields:

- `scenario`;
- `seed`;
- `agents`;
- `ticks`;
- `behaviorResults`;
- `proposals`;
- `acceptedWrites`;
- `rejectedWrites`;
- `memoryCountBeforeTotal`;
- `memoryCountAfterTotal`;
- `maxWritesPerAgentTick`;
- `bounded`;
- `deterministicOrder`;
- `digest`;
- `digestRepeat`;
- `digestsEqual`;
- `repeatabilityFailures`;
- `success`.

Purpose: provide one compact report that proves memory updates are bounded,
deterministic, and separated from behavior-loop decision ownership.

## Memory Types V0

Allowed v0 memory types should be small and explicit:

- `behavior_action`;
- `goal_confirmed`;
- `goal_changed`;
- `effect_applied`;
- `nearby_agent_observed`;
- `safety_reaction`;
- `curiosity_reaction`;
- `idle_tick_summary`.

These are memory categories, not new behavior. They should map from bounded
behavior-loop results or explicit fixture inputs.

Not included in v0:

- emotional memory;
- relationship memory;
- social trust;
- communication memory;
- LLM-generated memory;
- community/task-board memory;
- movement-stack feedback memory.

## Bounded Memory Rules

Phase 5.2B should start with conservative rules:

- max 1 accepted behavior memory per agent per tick in v0;
- rejected proposals should be counted and reported;
- duplicate same tick/same agent/same memory type may be rejected;
- summaries must be deterministic;
- summaries must not depend on dictionary or set iteration order;
- `importance` must be bounded, for example `0.0...1.0`;
- no unbounded arrays in report records;
- stable ordering by tick, then agent id, then memory type;
- memory writes must be auditable through before/after counts;
- write budgets must be checked per agent/tick and in aggregate;
- generated reports must include explicit no-World/no-movement-stack boundary
  flags.

## Relationship With Behavior Loop

The intended flow is:

```text
behavior loop decision/action/effect
-> LabBehaviorLoopResult
-> memory update input
-> memory update proposals
-> accepted proposals append to agent memory
-> report records before/after counts
```

The behavior loop should not silently own memory semantics. It can produce
results and source context. The memory update layer should decide what becomes
an append-only memory entry.

Phase 5.2B should probably remain fixture-only. It should not automatically
change `agents_basic`, `long_run_smoke`, or normal agent runtime unless a later
phase explicitly decides that bridge.

## Relationship With Movement Stack

Movement stack feedback can later become a memory update source:

```text
movement feedback
-> memory update input
-> movement-related memory proposal
-> bounded accepted/rejected write
```

That bridge is not part of Phase 5.2A. It should probably not be part of
Phase 5.2B either. The first memory fixture should prove behavior
result-to-memory update before consuming movement stack feedback.

The movement stack remains a movement sub-layer, not a cognitive memory owner.

## Future Metrics Contract

Future metrics should use the `memoryUpdate*` prefix:

- `memoryUpdateSuccess`;
- `memoryUpdateAgents`;
- `memoryUpdateTicks`;
- `memoryUpdateBehaviorResults`;
- `memoryUpdateProposals`;
- `memoryUpdateAcceptedWrites`;
- `memoryUpdateRejectedWrites`;
- `memoryUpdateMemoryCountBeforeTotal`;
- `memoryUpdateMemoryCountAfterTotal`;
- `memoryUpdateMaxWritesPerAgentTick`;
- `memoryUpdateBounded`;
- `memoryUpdateDeterministicOrder`;
- `memoryUpdateDigestsEqual`;
- `memoryUpdateRepeatabilityFailures`;
- `memoryUpdateWorldMutated`;
- `memoryUpdateTerrainMutated`;
- `memoryUpdateMovementStackUsed`.

Metrics should summarize the fixture contract. They should not activate
runtime memory retrieval, movement stack use, social behavior, or LLM context.

## Future Events Contract

Primary future event:

- `lab_memory_update_recorded`.

Minimum fields:

- `success`;
- `agentId`;
- `tick`;
- `memoryType`;
- `accepted`;
- `rejectionReason`;
- `importance`;
- `memoryCountBefore`;
- `memoryCountAfter`.

Optional summary event:

- `lab_memory_update_summary_recorded`.

Suggested summary fields:

- `success`;
- `agents`;
- `ticks`;
- `proposals`;
- `acceptedWrites`;
- `rejectedWrites`;
- `bounded`;
- `digestsEqual`;
- `repeatabilityFailures`.

## Future Invariant Contract

Minimum checks for Phase 5.2B:

- scenario name expected;
- seed recorded;
- report success;
- agents expected;
- ticks expected;
- behavior results positive;
- proposals positive;
- accepted writes positive;
- rejected writes expected if duplicate/bounds are tested;
- memory count after >= before;
- max writes per agent tick respected;
- importance bounded;
- deterministic memory order;
- deterministic digest;
- digest repeat equals digest;
- repeatability failures zero;
- no World mutation;
- no terrain mutation;
- no movement stack;
- no Core entity movement;
- no physical placeholder movement;
- report written;
- invariant report written;
- proposals written;
- memory snapshot written;
- digest written;
- metrics written;
- event written.

Additional useful checks:

- each proposal has an agent id;
- each accepted proposal has a non-empty memory type;
- each accepted proposal has a deterministic summary;
- all memory types are in the v0 allowlist;
- rejected writes do not append to memory;
- before/after counts match accepted writes;
- ordering is stable by tick, agent id, memory type.

## Recommended Phase 5.2B

Recommended next phase:

`Phase 5.2B — Memory Update From Behavior Result Fixture Smoke`

Likely scenario name:

`memory_update_from_behavior_result_fixture_smoke`

Goal: create a fixture that takes controlled behavior-loop results and
produces memory update proposals, accepted writes, rejected writes, and memory
snapshots.

The fixture should:

- create 2 or 3 abstract agents;
- create synthetic behavior results or reuse controlled behavior-loop fixture
  outputs;
- produce memory update proposals;
- accept and reject proposals according to bounded rules;
- write before/after memory snapshots;
- produce report, invariant report, proposals, digest, metrics, and events;
- avoid movement stack usage;
- avoid World mutation;
- avoid terrain mutation;
- avoid physical placeholder movement;
- avoid Core entity movement;
- remain deterministic.

Future outputs:

- `memory_update_report.json`;
- `memory_update_invariant_report.json`;
- `memory_update_proposals.json`;
- `memory_update_agent_memory_snapshot.json`;
- `memory_update_digest.json`;
- `metrics.json`;
- `events.ndjson`.

## Risks

- Writing too many memories;
- confusing memory writes with memory retrieval;
- treating append-only memory as learning before retrieval exists;
- introducing emotional memory too early;
- introducing relationships or trust too early;
- writing non-deterministic summaries;
- depending on dictionary or set ordering;
- connecting movement stack feedback too early;
- modifying `agents_basic` too early;
- hiding memory semantics inside `main.swift`;
- using memory update metrics as runtime activation switches.

## Explicit Out Of Scope

- no memory retrieval;
- no emotional memory;
- no mood;
- no relationships;
- no trust;
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
- no runtime reservation table;
- no movement stack bridge;
- no save/load changes;
- no renderer changes;
- no resource changes;
- no registry changes;
- no golden changes.

## Definition Of Done For 5.2A

- Document created;
- changelog updated;
- development journal updated;
- roadmap updated;
- cognitive resync plan updated;
- behavior-loop contract plan updated;
- no Swift files changed;
- no runtime behavior changed;
- no scenarios added;
- `swift build` passes;
- `swift build -c release --product Pebble` passes;
- `git diff --check` passes;
- `git diff --cached --check` passes;
- next phase 5.2B is clearly specified.

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

Expected result: docs-only changes keep Swift runtime behavior unchanged.
`pebsmoke` remains optional because this phase changes no Swift, runtime
behavior, scenario, movement stack code, Core simulation behavior, renderer,
resources, registries, save/load, or goldens.

Results:

- `swift build` passed;
- `swift build -c release --product Pebble` passed;
- `git diff --check` passed;
- `git diff --cached --check` passed.

`pebsmoke` was not run for this docs-only phase.

## Phase 5.2B Implementation Status

Phase 5.2B added `memory_update_from_behavior_result_fixture_smoke`, a
fixture-only smoke that turns controlled behavior-loop results into memory
update proposals and bounded memory writes.

Scenario:

- `memory_update_from_behavior_result_fixture_smoke`;
- fixture-only, no World created;
- fixed validation ticks: `3`;
- agents: `agent_0`, `agent_1`, `agent_2`;
- controlled behavior results: `seekSafety`, `explore`, and `observeAgent`.

Report:

- `memory_update_report.json`;
- success true in validated debug run;
- agents = 3;
- behaviorResults = 3;
- proposals = 4;
- acceptedWrites = 3;
- rejectedWrites = 1;
- memoryCountBeforeTotal = 0;
- memoryCountAfterTotal = 3;
- maxWritesPerAgentTick = 1;
- bounded = true;
- deterministicOrder = true;
- movementStackUsed = false;
- worldMutated = false;
- terrainMutated = false;
- coreEntityMoved = false;
- physicalPlaceholderMoved = false.

Invariant:

- `memory_update_invariant_report.json`;
- 40 checks passed;
- 0 checks failed;
- covers scenario, seed, agent/tick expectations, behavior results, proposals,
  accepted/rejected writes, before/after counts, max write budget, bounded
  importance, allowed memory types, non-empty summaries, deterministic order,
  no movement stack, no World/terrain mutation, no Core/placeholder movement,
  digest equality, output writing, metrics/events expectations, and docs
  update expectations.

Proposals:

- `memory_update_proposals.json`;
- accepted `safety_reaction` for `agent_0`;
- rejected duplicate `safety_reaction` for `agent_0`;
- accepted `curiosity_reaction` for `agent_1`;
- accepted `nearby_agent_observed` for `agent_2`.

Memory snapshot:

- `memory_update_agent_memory_snapshot.json`;
- each agent records before/after memory counts;
- accepted proposals append one `LabMemoryEntry`;
- rejected proposals do not append memory.

Digest:

- `memory_update_digest.json`;
- digest `f789a61fc3a3babe`;
- repeat digest `f789a61fc3a3babe`;
- repeatabilityFailures = 0.

Validation:

- debug `memory_update_from_behavior_result_fixture_smoke` passed;
- debug behavior-loop contract, behavior-loop hardening, `agents_basic`, and
  `regression_smoke` non-regressions passed;
- `swift build`, `swift build -c release --product Pebble`, and
  `swift run -c release pebsmoke` passed;
- direct release `PebbleLab` scenario validation was attempted with a short
  local limit and interrupted after production compilation stalled without
  further output.

Metrics:

- `metrics.json`;
- emits `memoryUpdate*` metrics including success, agents, ticks, behavior
  results, proposals, accepted writes, rejected writes, before/after memory
  counts, max writes per agent tick, bounded, deterministic order, digest
  equality, repeatability failures, mutation flags, movement stack usage, and
  Core/placeholder movement flags.

Events:

- `lab_memory_update_recorded`;
- `lab_memory_update_summary_recorded`.

Limitations:

- no memory retrieval;
- no emotional memory;
- no mood, relationships, trust, communication, community, or task board;
- no movement stack feedback source;
- no World or terrain mutation;
- no physical placeholder or Core entity creation/movement;
- no route following, full-route execution, pathfinding, reservation runtime,
  Python, LLM, or RL.

Next phase: Phase 5.2C - Memory Update Hardening.
