# Phase 5.3A — Memory Retrieval Planning

## Purpose

Phase 5.3A defines the v0 technical contract for retrieving relevant memories
from an agent's existing memory entries.

The goal is to move from:

```text
memory entries stored
-> query
-> ranked retrieved memories
-> retrieval summary
-> future goal/mood/social influence
```

This phase does not implement runtime retrieval. It adds no Swift code, no
scenario, no runtime metrics, no runtime events, no memory mutation, no
behavior-loop integration, no movement stack integration, no World access, no
mood, no relationships, no communication, no Python, no LLM, and no RL.

## Starting Point

Phase 5.2B added `memory_update_from_behavior_result_fixture_smoke`, the
first fixture-only memory update layer. It converted controlled behavior-loop
results into memory update proposals, accepted three writes, rejected one
duplicate, wrote before/after memory snapshots, emitted `memoryUpdate*`
metrics, and recorded `lab_memory_update_recorded` events.

Phase 5.2C added `memory_update_hardening_smoke`. It covered 13 deterministic
cases, 21 proposals, 14 accepted writes, 7 rejected writes, memory count total
`0 -> 14`, duplicate/type/summary/importance/budget rejection, deterministic
proposal order, stable digest equality, `memoryUpdateHardening*` metrics, and
`lab_memory_update_hardening_recorded`.

Memory can now be proposed, accepted, rejected, appended, snapshotted, and
reported in fixture-only paths. There is still no memory retrieval system.
Agents cannot yet ask for recent, important, type-matched, safety-related,
curiosity-related, or nearby-agent-related memories through a dedicated
contract.

## Current Memory Write State

Current `LabAgent` memory is append-only:

- `LabAgent.memory: [LabMemoryEntry]`;
- `LabAgent.remember(tick:type:summary:importance:)`;
- encoded `memoryCount`;
- encoded `recentMemory`, currently `Array(memory.suffix(10))`.

Current `LabMemoryEntry` fields are:

- `tick`;
- `type`;
- `summary`;
- `importance`.

Phase 5.2B/5.2C introduced fixture-only memory update records around this
existing memory:

- `LabMemoryUpdateInput`;
- `LabMemoryUpdateProposal`;
- `LabMemoryUpdateResult`;
- `LabMemoryUpdateReport`;
- `LabMemoryUpdateAgentSnapshot`;
- hardening case/report/invariant/metrics types.

Allowed memory update v0 types currently documented and enforced for accepted
fixture writes are:

- `behavior_action`;
- `goal_confirmed`;
- `goal_changed`;
- `effect_applied`;
- `nearby_agent_observed`;
- `safety_reaction`;
- `curiosity_reaction`;
- `idle_tick_summary`.

Existing write rules from 5.2B/5.2C:

- max 1 accepted behavior memory per agent per tick;
- duplicate same tick/agent/type proposals are rejected;
- second accepted write for the same agent/tick is rejected;
- invalid memory type is rejected;
- empty summary is rejected;
- importance below `0.0` or above `1.0` is rejected, not clamped;
- accepted proposals append one `LabMemoryEntry`;
- rejected proposals do not append memory;
- proposal ordering and digest construction are deterministic.

Current limits:

- no retrieval query type;
- no retrieved record type;
- no ranking/scoring contract;
- no retrieval report;
- no retrieval metrics/events;
- no retrieval invariant report;
- no memory read budget beyond encoded recent memory;
- no relationship between retrieved memories and behavior-loop inputs;
- no mood, emotional memory, relations, trust, social memory, LLM context, or
  Python/RL integration.

## Problem To Solve

Writing memories is not enough. A future cognitive agent needs a bounded way to
find relevant past entries before those entries can influence goals, mood,
social behavior, or future LLM context.

The retrieval layer must be deliberately conservative:

- retrieval must be deterministic;
- retrieval must be bounded;
- retrieval must be read-only;
- retrieval must not become a semantic embedding or LLM search system;
- retrieval must not mutate `LabAgent.memory`;
- retrieval must not directly alter mood, relationships, goals, or behavior;
- retrieval must not scan unbounded memory without explicit limits;
- retrieval must not depend on `Dictionary` or `Set` iteration order;
- retrieval must not call World, terrain, movement stack, route following, or
  pathfinding.

The first implementation should prove the contract with synthetic memory
snapshots before integrating retrieval into normal behavior-loop scenarios.

## Memory Retrieval Contract V0

Input:

- `agentId`;
- `tick`;
- memory entries;
- query kind;
- optional memory type filter;
- optional `maxResults`;
- optional recency window;
- optional importance threshold;
- deterministic sort configuration.

Output:

- retrieved memory records;
- ranked order;
- retrieval summary;
- empty result allowed;
- deterministic digest.

The v0 contract is read-only. It must never append, rewrite, delete, compact,
or otherwise mutate memory entries.

## Proposed Types For Future Implementation

These types are proposed for Phase 5.3B or later. They are not implemented in
Phase 5.3A.

### `LabMemoryRetrievalQuery`

Suggested fields:

- `tick`;
- `agentId`;
- `queryKind`;
- `allowedTypes`;
- `maxResults`;
- `minImportance`;
- `recencyWindowTicks`;
- `reason`.

Purpose: capture one bounded memory lookup request. It should be explicit
enough that a report can explain why a memory was considered or ignored.

### `LabMemoryRetrievedRecord`

Suggested fields:

- `tick`;
- `agentId`;
- `memoryIndex`;
- `memoryType`;
- `summary`;
- `importance`;
- `ageTicks`;
- `score`;
- `rank`;
- `reasonMatched`.

Purpose: represent one selected memory with enough information to audit score,
rank, recency, type match, and deterministic tie-break behavior.

### `LabMemoryRetrievalResult`

Suggested fields:

- `tick`;
- `agentId`;
- `query`;
- `availableMemories`;
- `consideredMemories`;
- `retrievedMemories`;
- `topMemoryType`;
- `emptyResult`;
- `deterministicOrder`;
- `success`.

Purpose: summarize one query and its ranked retrieval records.

### `LabMemoryRetrievalReport`

Suggested fields:

- `scenario`;
- `seed`;
- `agents`;
- `queries`;
- `availableMemories`;
- `consideredMemories`;
- `retrievedMemories`;
- `emptyResults`;
- `maxResults`;
- `deterministicOrder`;
- `bounded`;
- `digest`;
- `digestRepeat`;
- `digestsEqual`;
- `repeatabilityFailures`;
- `worldMutated`;
- `terrainMutated`;
- `movementStackUsed`;
- `memoryMutated`;
- `success`.

Purpose: provide one compact proof that retrieval is bounded, deterministic,
read-only, and isolated from movement/World/runtime behavior.

## Query Kinds V0

Initial query kinds should stay small and explicit:

- `recent`;
- `important`;
- `by_type`;
- `safety_related`;
- `curiosity_related`;
- `nearby_agent_related`.

Not included in v0:

- semantic embedding;
- natural language query;
- LLM summary;
- emotional recall;
- relationship recall;
- trust recall;
- social graph recall.

## Scoring V0

Scoring should be deterministic, explainable, and auditable.

Suggested formula:

```text
score = importance component + recency component + type match component
```

Suggested components:

- importance component: use `importance` bounded to `0.0...1.0`;
- recency component: bounded bonus based on `ageTicks`, for example newer
  entries receive a fixed small bonus within the recency window;
- type match component: fixed bonus when `memoryType` matches query
  allowlist/query kind;
- empty or disallowed entries receive no match bonus and may be filtered.

Tie-break order must be stable. Recommended tie-break:

1. higher score;
2. newer `tick`;
3. lower original `memoryIndex`;
4. lexicographic `memoryType`;
5. lexicographic `summary`.

No random values, embeddings, LLM calls, floating nondeterminism, or
unordered-container iteration should influence scoring.

## Bounded Retrieval Rules

Phase 5.3B should start with strict bounds:

- `maxResults` must be bounded, for example `1...5`;
- max considered memories must be bounded in the fixture;
- results must be sorted deterministically;
- ranks must be contiguous starting at 1;
- empty results are valid and must be covered;
- retrieval must not mutate memory entries;
- retrieval must not write new memory entries;
- retrieval must not call World;
- retrieval must not call movement stack;
- retrieval must not move Core entities or physical placeholders;
- retrieval must not depend on dictionary/set iteration order;
- report records must contain enough data to reproduce score/rank decisions.

## Relationship With Memory Update

The intended relationship is:

```text
memory update accepts and appends memories
-> retrieval reads those memories
-> retrieval produces ranked records
-> retrieval summary becomes available to future cognition
```

Phase 5.3B should probably use synthetic memory snapshots or deterministic
snapshots modeled after 5.2B/5.2C outputs. It should not alter
`agents_basic`, normal behavior-loop runtime, or memory update scenarios unless
that later becomes explicitly planned.

Retrieval consumes memory entries. It does not own memory writing,
accept/reject policy, or memory mutation.

## Relationship With Behavior Loop

Future behavior-loop input may eventually include:

- retrieved memory summary;
- top relevant memory;
- counts by type;
- last safety reaction;
- last curiosity reaction;
- last nearby-agent observation.

Phase 5.3A does not implement that bridge. Phase 5.3B should likely remain an
isolated retrieval fixture before retrieval is added to behavior-loop inputs.

## Relationship With Mood / Relations / LLM

Memory retrieval is a prerequisite for later:

- mood;
- emotional memory;
- relationships;
- trust;
- social memory;
- LLM context building;
- Python/RL experiments.

None of those systems are part of Phase 5.3A. They should not be implemented
in Phase 5.3B either unless a separate planning phase defines their ownership,
inputs, outputs, reports, and invariants.

## Future Metrics Contract

Future metrics should use the `memoryRetrieval*` prefix:

- `memoryRetrievalSuccess`;
- `memoryRetrievalAgents`;
- `memoryRetrievalQueries`;
- `memoryRetrievalAvailableMemories`;
- `memoryRetrievalConsideredMemories`;
- `memoryRetrievalRetrievedMemories`;
- `memoryRetrievalEmptyResults`;
- `memoryRetrievalMaxResults`;
- `memoryRetrievalBounded`;
- `memoryRetrievalDeterministicOrder`;
- `memoryRetrievalDigestsEqual`;
- `memoryRetrievalRepeatabilityFailures`;
- `memoryRetrievalMemoryMutated`;
- `memoryRetrievalWorldMutated`;
- `memoryRetrievalTerrainMutated`;
- `memoryRetrievalMovementStackUsed`.

## Future Events Contract

Primary future event:

`lab_memory_retrieval_recorded`

Minimum fields:

- `success`;
- `agentId`;
- `tick`;
- `queryKind`;
- `consideredMemories`;
- `retrievedMemories`;
- `topMemoryType`;
- `emptyResult`;
- `deterministicOrder`.

Optional summary event:

`lab_memory_retrieval_summary_recorded`

Suggested fields:

- `success`;
- `agents`;
- `queries`;
- `availableMemories`;
- `consideredMemories`;
- `retrievedMemories`;
- `emptyResults`;
- `bounded`;
- `digestsEqual`;
- `repeatabilityFailures`.

## Future Invariant Contract

Minimum checks for Phase 5.3B:

- `scenario_name_expected`;
- `seed_recorded`;
- `report_success`;
- `agents_expected`;
- `queries_positive`;
- `available_memories_positive`;
- `considered_memories_bounded`;
- `retrieved_memories_bounded`;
- `empty_result_case_covered`;
- `max_results_respected`;
- `ranks_contiguous`;
- `scores_bounded`;
- `deterministic_order`;
- `digest_written`;
- `digest_repeat_written`;
- `digests_equal`;
- `repeatability_failures_zero`;
- `memory_not_mutated`;
- `world_not_mutated`;
- `terrain_not_mutated`;
- `movement_stack_not_used`;
- `report_written`;
- `invariant_report_written`;
- `queries_written`;
- `results_written`;
- `digest_output_written`;
- `metrics_written`;
- `event_written`;
- `success_contract_respected`.

## Recommended Phase 5.3B

Recommended next implementation:

`Phase 5.3B — Memory Retrieval Fixture Smoke`

Probable new scenario:

`memory_retrieval_fixture_smoke`

Goal: create a fixture that takes controlled memory snapshots, executes
several retrieval queries, produces ranked records, covers an empty result,
and writes report/invariant/results/digest/metrics/events.

The fixture should:

- create 2 or 3 agents;
- create synthetic memory snapshots;
- include several v0 memory types;
- execute `recent`, `important`, `by_type`, `safety_related`,
  `curiosity_related`, and `nearby_agent_related` queries;
- produce sorted retrieval results;
- respect `maxResults`;
- cover empty result;
- avoid memory mutation;
- avoid movement stack;
- avoid World mutation;
- remain deterministic.

Future outputs:

- `memory_retrieval_report.json`;
- `memory_retrieval_invariant_report.json`;
- `memory_retrieval_queries.json`;
- `memory_retrieval_results.json`;
- `memory_retrieval_digest.json`;
- `metrics.json`;
- `events.ndjson`.

## Risks

- making retrieval too intelligent too early;
- adding semantic or LLM retrieval too early;
- mixing retrieval with memory update ownership;
- mutating memories during retrieval;
- non-deterministic scoring;
- relying on `Dictionary` or `Set` iteration order;
- failing to bound `maxResults`;
- letting retrieval influence goals before it has fixture coverage;
- growing `main.swift` instead of isolating retrieval logic in a future
  `LabMemoryRetrieval.swift`;
- confusing green retrieval reports with actual agent intelligence.

## Explicit Out Of Scope

- no memory write;
- no memory mutation;
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
- no renderer changes;
- no resource changes;
- no registry changes;
- no golden changes.

## Definition Of Done For 5.3A

- Document created;
- changelog updated;
- dev journal updated;
- roadmap updated;
- cognitive resync plan updated if useful;
- memory update plan updated if useful;
- no Swift files changed;
- no runtime behavior changed;
- no scenarios added;
- `swift build` passes;
- `swift build -c release --product Pebble` passes if launched;
- `git diff --check` passes;
- `git diff --cached --check` passes;
- next phase 5.3B is clearly specified.

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
`pebsmoke` is optional because this phase changes no Swift, runtime behavior,
scenario, movement stack code, renderer, resources, registries, save/load, or
goldens.

Results:

- `swift build` passed;
- `swift build -c release --product Pebble` passed;
- `git diff --check` passed;
- `git diff --cached --check` passed.

`pebsmoke` was not run for this docs-only phase.

## Phase 5.3B Implementation Status

Phase 5.3B added `memory_retrieval_fixture_smoke`, a fixture-only smoke that
retrieves ranked memories from controlled memory snapshots.

Scenario:

- `memory_retrieval_fixture_smoke`;
- fixture-only, no World created;
- fixed validation ticks: `3`;
- agents: `agent_0`, `agent_1`, `agent_2`.

Query kinds:

- `recent`;
- `important`;
- `by_type`;
- `safety_related`;
- `curiosity_related`;
- `nearby_agent_related`.

Report:

- `memory_retrieval_report.json`;
- success true in validated debug run;
- agents = 3;
- queries = 7;
- availableMemories = 8;
- consideredMemories = 8;
- retrievedMemories = 7;
- emptyResults = 1;
- maxResults = 2;
- bounded = true;
- deterministicOrder = true;
- memoryMutated = false;
- movementStackUsed = false;
- worldMutated = false;
- terrainMutated = false.

Invariant:

- `memory_retrieval_invariant_report.json`;
- 39 checks passed;
- 0 checks failed;
- covers scenario, seed, agent/query expectations, available/considered/
  retrieved memory counts, empty result coverage, max results, ranks,
  bounded scores, allowed query kinds, deterministic order, read-only memory,
  no movement stack, no World/terrain mutation, digest equality, output
  writing, metrics/events expectations, and docs update expectations.

Queries:

- `memory_retrieval_queries.json`;
- includes recent, important, by-type, safety, curiosity, nearby-agent, and
  empty-result queries;
- maxResults is bounded to `2` in the fixture.

Results:

- `memory_retrieval_results.json`;
- retrieved records include memory index, type, summary, importance, age,
  score, rank, and reasonMatched;
- ranks are contiguous from 1;
- scores are bounded and deterministic;
- one query returns an explicit empty result.

Digest:

- `memory_retrieval_digest.json`;
- digest `a82037f649caf921`;
- repeat digest `a82037f649caf921`;
- repeatabilityFailures = 0.

Validation:

- debug `memory_retrieval_fixture_smoke` passed;
- debug memory update fixture, memory update hardening, behavior-loop
  contract, behavior-loop hardening, `agents_basic`, and `regression_smoke`
  non-regressions passed;
- `swift build`, `swift build -c release --product Pebble`, and
  `swift run -c release pebsmoke` passed;
- direct release `PebbleLab` scenario validation was attempted with a short
  local limit and interrupted after production compilation stalled without
  further output.

Metrics:

- `metrics.json`;
- emits `memoryRetrieval*` metrics including success, agents, queries,
  available/considered/retrieved memories, empty results, max results,
  bounded, deterministic order, digest equality, repeatability failures,
  memory mutation flag, World/terrain mutation flags, and movement stack
  usage.

Events:

- `lab_memory_retrieval_recorded`;
- `lab_memory_retrieval_summary_recorded`.

Limitations:

- no memory write;
- no memory mutation;
- no behavior-loop goal influence;
- no mood, emotional memory, relationships, trust, communication, community,
  or task board;
- no movement stack feedback source;
- no World or terrain mutation;
- no physical placeholder or Core entity creation/movement;
- no route following, full-route execution, pathfinding, reservation runtime,
  embeddings, Python, LLM, or RL.

Next phase: Phase 5.3C - Memory Retrieval Hardening.

## Phase 5.3C Implementation Status

Phase 5.3C added `memory_retrieval_hardening_smoke`, a fixture-only hardening
scenario for the memory retrieval v0 contract.

Scenario:

- `memory_retrieval_hardening_smoke`;
- fixture-only, no World created;
- no memory write;
- no memory mutation;
- no movement stack;
- no World or terrain mutation.

Cases:

- baseline compatibility with 5.3B;
- recent query ordering;
- important query ordering;
- by-type filtering;
- safety, curiosity, and nearby-agent related queries;
- valid empty result;
- maxResults bound;
- out-of-bounds maxResults clamped to the v0 limit of 5;
- minImportance filter;
- recency window filter;
- bounded scores;
- contiguous ranks;
- deterministic tie-break;
- unsorted input with stable output;
- invalid query kind rejection;
- memory read-only proof;
- digest repeatability.

Query kinds:

- `recent`;
- `important`;
- `by_type`;
- `safety_related`;
- `curiosity_related`;
- `nearby_agent_related`;
- one intentionally invalid query kind, rejected as an expected hardening case.

Scoring:

- bounded importance component;
- bounded recency bonus;
- fixed type/query match bonus;
- stable tie-break by score, age, memory index, memory type, and summary;
- no random, embeddings, LLM summary, or semantic retrieval.

Report:

- `memory_retrieval_hardening_report.json`;
- success true in validated debug run;
- cases = 19;
- casesPassed = 19;
- casesFailed = 0;
- queries = 23;
- availableMemories = 56;
- consideredMemories = 37;
- retrievedMemories = 34;
- emptyResults = 3;
- maxResults = 5;
- bounded = true;
- deterministicOrder = true;
- memoryMutated = false;
- movementStackUsed = false;
- worldMutated = false;
- terrainMutated = false.

Validation note: direct release `PebbleLab` scenario validation was attempted
with a 90 second local limit, but production `PebbleLab` compilation stalled
after planning/source emission and was interrupted. Debug `PebbleLab` scenario
validation, release `Pebble` build, and release `pebsmoke` passed.

Invariant:

- `memory_retrieval_hardening_invariant_report.json`;
- 61 checks passed;
- 0 checks failed;
- covers scenario, seed, case expectations, query/result counts, empty result,
  max results, rank contiguity, score bounds, invalid query rejection,
  deterministic order, read-only memory, no movement stack, no World/terrain
  mutation, digest equality, output files, metrics/events, docs, and success
  contract.

Queries and results:

- `memory_retrieval_hardening_queries.json`;
- `memory_retrieval_hardening_results.json`;
- retrieved records retain memory index, type, summary, importance, age, score,
  rank, and reasonMatched;
- invalid query returns no considered memories, no retrieved memories, and a
  failed query result while the expected hardening case passes.

Digest:

- `memory_retrieval_hardening_digest.json`;
- digest `e72e89cc8c24a53e`;
- repeat digest `e72e89cc8c24a53e`;
- repeatabilityFailures = 0.

Metrics:

- `metrics.json`;
- emits `memoryRetrievalHardening*` metrics including success, cases, queries,
  available/considered/retrieved memories, empty results, max results,
  bounded, deterministic order, mutation flags, digest equality, and
  repeatability failures.

Events:

- `lab_memory_retrieval_hardening_recorded`.

Limitations:

- no goal selection influence yet;
- no mood, emotional memory, relationships, trust, communication, community,
  social memory, or task board;
- no memory write or memory mutation;
- no movement stack feedback source;
- no World or terrain mutation;
- no physical placeholder or Core entity creation/movement;
- no route following, full-route execution, pathfinding, reservation runtime,
  embeddings, Python, LLM, or RL.

Next phase: Phase 5.4A - Goal Selection From Retrieved Memory Planning.
