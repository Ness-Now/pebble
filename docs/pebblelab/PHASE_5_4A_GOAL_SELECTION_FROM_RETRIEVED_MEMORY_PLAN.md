# Phase 5.4A — Goal Selection From Retrieved Memory Planning

## Purpose

Phase 5.4A defines the v0 technical contract for selecting or proposing goals
from retrieved memories.

The goal is to move from:

```text
retrieved memories
-> goal candidates
-> ranked goal candidates
-> selected goal proposal
-> future behavior loop integration
```

This phase does not implement runtime goal selection from memory. It adds no
Swift code, no scenario, no runtime metrics, no runtime events, no behavior
loop changes, no memory mutation, no movement stack integration, no World
access, no mood, no relationships, no communication, no Python, no LLM, and no
RL.

## Starting Point

Phase 5.1B added `behavior_loop_contract_fixture_smoke`, the first
fixture-only behavior loop contract. It created controlled inputs, decisions,
results, bounded memory write counts, reports, invariants, metrics, events,
and stable digests without movement stack or World mutation.

Phase 5.1C added `behavior_loop_hardening_smoke`, covering deterministic
behavior-loop boundary cases such as seekSafety, explore, observeOtherAgent,
idle fallback, missing goal fallback, empty nearby agents, existing memory,
empty inventory, extreme needs, deterministic ordering, and digest
repeatability.

Phase 5.2B added `memory_update_from_behavior_result_fixture_smoke`, the first
fixture-only memory update layer from controlled behavior-loop results.

Phase 5.2C added `memory_update_hardening_smoke`, hardening memory proposals,
accepted/rejected writes, allowed memory types, importance bounds, summaries,
write limits, deterministic ordering, and digest stability.

Phase 5.3B added `memory_retrieval_fixture_smoke`, the first read-only memory
retrieval fixture. It ranked memories from controlled snapshots across recent,
important, by-type, safety-related, curiosity-related, and nearby-agent-related
queries.

Phase 5.3C added `memory_retrieval_hardening_smoke`, hardening retrieval with
19 cases, 23 queries, bounded maxResults, minImportance, recency windows,
bounded scores, contiguous ranks, deterministic tie-breaks, invalid query
rejection, stable output from unsorted input, read-only memory, and stable
digests.

Retrieval is now fixture-proven as read-only, bounded, deterministic, and
auditable. The next question is how retrieved records can influence future goal
selection without allowing memories to override needs blindly.

## Current Goal State

Current `LabAgent` goal state is concrete but still simple:

- `LabAgent.currentGoal: LabGoal`;
- `LabAgent.goalSelectionCount`;
- `LabAgent.goalChangeCount`;
- `LabAgent.selectGoal(tick:)`;
- `LabGoalKind`;
- `LabGoal`;
- `LabGoalChange`.

Current `LabGoalKind` cases are:

- `idle`;
- `rest`;
- `seekSafety`;
- `explore`;
- `observeOtherAgent`.

Current `LabGoal` fields are:

- `kind`;
- `reason`;
- `startedAtTick`;
- `urgency`.

Current `LabAgent` initialization sets:

- `currentGoal = idle`;
- reason `initial goal`;
- `startedAtTick = 0`;
- `urgency = 0`.

Current goal selection in `LabAgent.selectGoal(tick:)` is deterministic and
priority-ordered:

1. `health <= 25` -> `seekSafety`, urgency `100`;
2. `fear >= 70` -> `seekSafety`, urgency `85`;
3. `needs.safety < 0.5` -> `seekSafety`, urgency `90`;
4. `needs.fatigue >= 0.02` -> `rest`, urgency `70`;
5. `needs.curiosity >= 0.8` -> `explore`, urgency `60`;
6. nearby agents present -> `observeOtherAgent`, urgency `50`;
7. `needs.curiosity >= 0.5` -> `explore`, urgency `40`;
8. otherwise -> `idle`, urgency `0`.

If the selected kind is unchanged, `selectGoal` returns nil and does not update
`currentGoal`. If the kind changes, it writes the new `LabGoal`, increments
`goalChangeCount`, and returns `LabGoalChange`.

Current action selection is tied to `currentGoal.kind`:

- `seekSafety` -> abstract movement toward home or wait at home;
- `rest` -> `rest`;
- `observeOtherAgent` -> `observe_area`;
- `explore` -> deterministic abstract movement direction;
- `idle` -> `wait`.

Current memory does not influence `LabAgent.selectGoal`. Current retrieval does
not feed `LabBehaviorLoopInput`. Existing behavior-loop fixtures use string
goals derived from current fixture agent state and simple deterministic rules,
but they do not consume retrieved memories either.

Limits:

- no retrieved memory input to goal selection;
- no candidate goal type;
- no goal candidate scoring;
- no memory influence summary;
- no merge policy for duplicate goal candidates;
- no currentGoal continuity policy beyond existing kind equality in
  `selectGoal`;
- no report proving memory-influenced goal decisions;
- no mood, relationships, social trust, communication, LLM, Python, or RL.

## Problem To Solve

Retrieving a memory is not enough. A future cognitive agent needs a controlled
bridge from ranked memory records to goal candidates.

Problems to solve before implementation:

- a retrieved memory must influence goals only through an explicit contract;
- needs and safety must remain able to dominate memory influence;
- important memories must not always overwrite `currentGoal`;
- goal candidates must be bounded;
- duplicate candidates must be merged deterministically;
- scoring must be explainable and deterministic;
- current goal continuity must be represented explicitly;
- empty retrieval must be valid;
- selected goal is not the same thing as executed action;
- goal selection must not mutate memory, World, terrain, movement stack, Core
  entities, or physical placeholders;
- mood, relationships, trust, social planning, LLM context, and semantic
  guessing must stay out of v0.

## Goal Selection From Memory Contract V0

Input:

- `agentId`;
- `tick`;
- current goal;
- needs summary;
- fear;
- health;
- home-position availability summary;
- retrieved memory results;
- optional current action/effect context;
- `maxCandidates`;
- deterministic scoring policy.

Output:

- goal candidates;
- candidate scores;
- selected goal;
- selection reason;
- memory influence summary;
- unchanged goal allowed;
- empty retrieval decision allowed;
- deterministic digest.

The v0 contract consumes retrieval results. It should not rerun retrieval
internally. It should not mutate memory. It should not execute behavior actions
or call movement stack.

## Proposed Types For Future Implementation

These types are proposed for Phase 5.4B or later. They are not implemented in
Phase 5.4A.

### `LabGoalSelectionFromMemoryInput`

Suggested fields:

- `tick`;
- `agentId`;
- `currentGoal`;
- `needsSummary`;
- `fear`;
- `health`;
- `homePositionKnown`;
- `retrievedMemories`;
- `maxCandidates`;
- `reason`.

Purpose: represent one bounded goal-selection request with enough agent state
to keep needs/fear/currentGoal arbitration explicit.

### `LabGoalCandidate`

Suggested fields:

- `goal`;
- `source`;
- `score`;
- `priority`;
- `supportingMemoryTypes`;
- `supportingMemoryCount`;
- `reason`;
- `wouldChangeCurrentGoal`.

Purpose: capture one candidate goal and the evidence supporting it. Candidates
should be merged by goal before final ranking.

### `LabGoalSelectionFromMemoryDecision`

Suggested fields:

- `tick`;
- `agentId`;
- `goalBefore`;
- `selectedGoal`;
- `goalChanged`;
- `selectedCandidate`;
- `candidates`;
- `memoryInfluenceApplied`;
- `memoryInfluenceReason`;
- `deterministicOrder`;
- `success`.

Purpose: provide a per-agent decision record that can be inspected without
executing an action or changing normal runtime behavior.

### `LabGoalSelectionFromMemoryReport`

Suggested fields:

- `scenario`;
- `seed`;
- `agents`;
- `decisions`;
- `candidates`;
- `selectedGoals`;
- `goalChanges`;
- `unchangedGoals`;
- `memoryInfluencedDecisions`;
- `emptyRetrievalDecisions`;
- `maxCandidates`;
- `bounded`;
- `deterministicOrder`;
- `digest`;
- `digestRepeat`;
- `digestsEqual`;
- `repeatabilityFailures`;
- `worldMutated`;
- `terrainMutated`;
- `movementStackUsed`;
- `memoryMutated`;
- `success`.

Purpose: provide one compact proof that goal selection from memory is bounded,
deterministic, read-only, and isolated from runtime movement/World behavior.

## Memory-To-Goal Mapping V0

The first mapping should be explicit, table-driven, and auditable:

- `safety_reaction` -> `seekSafety`;
- `curiosity_reaction` -> `explore`;
- `nearby_agent_observed` -> `observeOtherAgent`;
- `idle_tick_summary` -> `idle`;
- `goal_confirmed` -> current or confirmed goal if the summary/result carries
  a known goal;
- `goal_changed` -> prior selected goal if the fixture/result carries it
  safely;
- `behavior_action` -> a candidate based on selected action only when the
  action maps directly to a known v0 goal;
- `effect_applied` -> a candidate based on effect category only when the
  effect maps directly to a known v0 goal.

No semantic guessing is allowed in v0. Unknown memory types, unknown summaries,
or unsupported actions should produce no memory-derived candidate or a rejected
candidate record, depending on the future fixture contract.

No LLM, embeddings, natural-language inference, relationship recall, or mood
interpretation should participate in this mapping.

## Scoring V0

Goal candidate scoring should be deterministic, bounded, and explainable.

Suggested formula:

```text
candidateScore =
    memory score component
  + need/fear component
  + currentGoal continuity component
  + source priority component
```

Suggested components:

- memory score component: based on retrieved record score/importance, bounded;
- need/fear component: safety and health can strongly support `seekSafety`,
  fatigue can support `rest`, curiosity can support `explore`;
- currentGoal continuity component: small bonus for keeping the current goal
  when no stronger need/memory candidate exists;
- source priority component: fixed bonus for explicit safety/need sources over
  weaker generic memory sources.

Rules:

- scores must be bounded;
- no random values;
- no embeddings;
- no LLM;
- no unordered container iteration;
- safety/fear can outrank curiosity;
- severe health/fear/safety should be able to override memory recall;
- empty retrieval can preserve `currentGoal` or select `idle` depending on the
  fixture contract.

Recommended tie-break:

1. higher score;
2. higher priority;
3. lexicographic `goal`;
4. lexicographic `source`;
5. lexicographic joined `supportingMemoryTypes`.

## Bounded Candidate Rules

Phase 5.4B should start with strict bounds:

- `maxCandidates` must be bounded, for example `1...5`;
- out-of-bounds maxCandidates should be clamped or rejected by a documented
  rule;
- candidates must be sorted deterministically;
- duplicate goals must be merged before final ranking;
- selectedGoal must always be present;
- unchanged goal is valid and must be covered;
- empty retrieval is valid and must be covered;
- retrieved memories must not be mutated;
- agent memory must not be written;
- goal selection must not execute behavior actions;
- goal selection must not call movement stack;
- goal selection must not create or mutate World/terrain;
- goal selection must not move Core entities or physical placeholders;
- mood, relationships, trust, communication, community, LLM, embeddings, and
  Python/RL must remain out of scope.

## Relationship With Memory Retrieval

The intended relationship is:

```text
memory retrieval produces ranked records
-> goal selection reads retrieved records
-> explicit mapping produces goal candidates
-> bounded scoring selects a goal proposal
```

Goal selection from memory consumes retrieval outputs. It does not own
retrieval query execution, retrieval scoring, retrieval reports, memory writes,
or memory mutation.

Phase 5.4B should probably use synthetic retrieval results or deterministic
retrieval outputs modeled after 5.3B/5.3C. It should not alter `agents_basic`,
normal behavior-loop runtime, or retrieval scenarios unless that later becomes
explicitly planned.

## Relationship With Behavior Loop

Future behavior-loop input may eventually include:

- selected goal from memory-informed goal selection;
- selected goal reason;
- memory influence summary;
- currentGoal continuity decision;
- counts by supporting memory type;
- top supporting retrieved memory type.

Phase 5.4A does not implement that bridge. Phase 5.4B should likely remain an
isolated fixture before goal selection from memory is integrated into normal
behavior-loop inputs.

The future integration point should be before action selection:

```text
perception/needs/currentGoal
-> retrieval summary
-> goal selection from memory
-> behavior loop selectedGoal
-> intended action
```

The selected goal is still not an executed action.

## Relationship With Mood / Relations / LLM

Goal selection from memory is a prerequisite for later:

- mood;
- emotional memory;
- relationships;
- trust;
- social memory;
- social plans;
- LLM context building;
- Python/RL experiments.

None of those systems are part of Phase 5.4A. They should not be implemented
in Phase 5.4B either unless a separate planning phase defines ownership,
inputs, outputs, reports, and invariants.

## Future Metrics Contract

Future metrics should use the `goalSelectionMemory*` prefix:

- `goalSelectionMemorySuccess`;
- `goalSelectionMemoryAgents`;
- `goalSelectionMemoryDecisions`;
- `goalSelectionMemoryCandidates`;
- `goalSelectionMemorySelectedGoals`;
- `goalSelectionMemoryGoalChanges`;
- `goalSelectionMemoryUnchangedGoals`;
- `goalSelectionMemoryInfluencedDecisions`;
- `goalSelectionMemoryEmptyRetrievalDecisions`;
- `goalSelectionMemoryMaxCandidates`;
- `goalSelectionMemoryBounded`;
- `goalSelectionMemoryDeterministicOrder`;
- `goalSelectionMemoryDigestsEqual`;
- `goalSelectionMemoryRepeatabilityFailures`;
- `goalSelectionMemoryMemoryMutated`;
- `goalSelectionMemoryWorldMutated`;
- `goalSelectionMemoryTerrainMutated`;
- `goalSelectionMemoryMovementStackUsed`.

## Future Events Contract

Primary future event:

`lab_goal_selection_memory_recorded`

Suggested fields:

- `success`;
- `agentId`;
- `tick`;
- `goalBefore`;
- `selectedGoal`;
- `goalChanged`;
- `candidates`;
- `memoryInfluenceApplied`;
- `memoryInfluenceReason`;
- `emptyRetrieval`.

Optional summary event:

`lab_goal_selection_memory_summary_recorded`

Suggested fields:

- `success`;
- `agents`;
- `decisions`;
- `candidates`;
- `selectedGoals`;
- `goalChanges`;
- `unchangedGoals`;
- `influencedDecisions`;
- `emptyRetrievalDecisions`;
- `bounded`;
- `digestsEqual`;
- `repeatabilityFailures`.

## Future Invariant Contract

Minimum checks for Phase 5.4B:

- scenario name expected;
- seed recorded;
- report success;
- agents expected;
- decisions positive;
- candidates positive;
- selected goal present;
- selected goal is a known v0 `LabGoalKind`;
- goal changes covered;
- unchanged goal covered;
- memory-influenced decision covered;
- empty retrieval case covered;
- maxCandidates respected;
- duplicate goals merged;
- scores bounded;
- deterministic candidate order;
- deterministic decision order;
- digest written;
- digest repeat written;
- digest repeat equals digest;
- repeatability failures zero;
- memory not mutated;
- no World mutation;
- no terrain mutation;
- no movement stack;
- no behavior action execution;
- report written;
- invariant report written;
- candidates written;
- decisions written;
- digest written;
- metrics written;
- event written.

## Recommended Phase 5.4B

`Phase 5.4B — Goal Selection From Retrieved Memory Fixture Smoke`

Probable scenario:

`goal_selection_from_memory_fixture_smoke`

Goal: create a fixture that consumes controlled retrieval results and produces
goal candidates plus selected goal decisions without integrating into normal
behavior runtime.

The fixture should:

- create 3 agents or agent snapshots;
- create synthetic retrieval results or reuse deterministic outputs modeled
  after 5.3B/5.3C;
- cover `safety_reaction` -> `seekSafety`;
- cover `curiosity_reaction` -> `explore`;
- cover `nearby_agent_observed` -> `observeOtherAgent`;
- cover empty retrieval -> unchanged current goal or `idle`;
- cover currentGoal continuity;
- cover duplicate candidate merge;
- cover maxCandidates bounds;
- use deterministic scoring;
- write report/invariant/candidates/decisions/digest/metrics/events;
- not mutate memory;
- not execute behavior actions;
- not call movement stack;
- not create or mutate World.

Future outputs:

- `goal_selection_memory_report.json`;
- `goal_selection_memory_invariant_report.json`;
- `goal_selection_memory_candidates.json`;
- `goal_selection_memory_decisions.json`;
- `goal_selection_memory_digest.json`;
- `metrics.json`;
- `events.ndjson`.

## Risks

Key risks:

- allowing memory to always override needs;
- creating pseudo-intelligence before the contract is observable;
- confusing selected goal with executed action;
- integrating with the behavior loop too early;
- mutating memory during goal selection;
- making scoring non-deterministic;
- depending on `Dictionary` or `Set` iteration order;
- introducing mood, relationships, social trust, communication, or LLM context
  too early;
- growing `main.swift` instead of isolating future fixture logic.

## Explicit Out Of Scope

- no behavior action execution;
- no behavior loop integration;
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
- no renderer changes.

## Definition Of Done For 5.4A

- document created;
- changelog updated;
- dev journal updated;
- roadmap updated;
- cognitive resync plan updated;
- memory retrieval plan updated;
- no Swift files changed;
- no runtime behavior changed;
- no scenarios added;
- `swift build` passes;
- `swift build -c release --product Pebble` passes;
- `git diff --check` passes;
- next phase 5.4B is clearly specified.

## Phase 5.4B Implementation Status

Phase 5.4B added `goal_selection_from_memory_fixture_smoke`, a fixture-only
smoke that consumes controlled retrieved memories and produces bounded goal
candidates plus selected goal decisions.

Scenario:

- `goal_selection_from_memory_fixture_smoke`;
- fixture-only, no World created;
- no behavior action execution;
- no memory write;
- no memory mutation;
- no retrieval rerun;
- no movement stack.

Memory-to-goal mapping:

- `safety_reaction` -> `seekSafety`;
- `curiosity_reaction` -> `explore`;
- `nearby_agent_observed` -> `observeOtherAgent`;
- `idle_tick_summary` -> `idle`;
- `goal_confirmed` and `goal_changed` stay limited to known current/confirmed
  goals;
- `behavior_action` and `effect_applied` only map through direct, safe v0
  string matches in the fixture.

Candidates:

- `goal_selection_memory_candidates.json`;
- 9 candidates in the validated debug run;
- duplicate `explore` candidates are merged for the duplicate-memory fixture
  case;
- candidates carry goal, source, score, priority, supporting memory types,
  supporting memory count, reason, and whether they would change currentGoal.

Decisions:

- `goal_selection_memory_decisions.json`;
- 5 decisions in the validated debug run;
- selected goals cover `seekSafety`, `explore`, and `observeOtherAgent`;
- empty retrieval keeps the current `explore` goal;
- selectedGoals = decisions;
- goalChanges = 4;
- unchangedGoals = 1;
- memoryInfluencedDecisions = 4;
- emptyRetrievalDecisions = 1.

Scoring:

- bounded memory score component;
- need/fear component;
- currentGoal continuity component;
- source priority component;
- stable tie-break by score, priority, goal, source, and supporting memory
  types;
- no random, embeddings, LLM, semantic guessing, or unordered-container
  influence.

Report:

- `goal_selection_memory_report.json`;
- success true in validated debug run;
- agents = 5;
- decisions = 5;
- candidates = 9;
- selectedGoals = 5;
- goalChanges = 4;
- unchangedGoals = 1;
- memoryInfluencedDecisions = 4;
- emptyRetrievalDecisions = 1;
- maxCandidates = 5;
- bounded = true;
- deterministicOrder = true;
- memoryMutated = false;
- behaviorActionExecuted = false;
- movementStackUsed = false;
- worldMutated = false;
- terrainMutated = false.

Invariant:

- `goal_selection_memory_invariant_report.json`;
- 42 checks passed;
- 0 checks failed;
- covers scenario, seed, decisions/candidates, selected goal presence, known
  goals, goal changes, unchanged goals, memory-influenced decisions, empty
  retrieval, maxCandidates, duplicate merge, bounded scores, deterministic
  order, selected candidate membership, memory influence reasons, boundary
  flags, digest equality, outputs, metrics/events, docs, and success contract.

Digest:

- `goal_selection_memory_digest.json`;
- digest `bad8ecf0fcfa0738`;
- repeat digest `bad8ecf0fcfa0738`;
- repeatabilityFailures = 0.

Metrics:

- `metrics.json`;
- emits `goalSelectionMemory*` metrics including success, agents, decisions,
  candidates, selected goals, goal changes, unchanged goals, influenced
  decisions, empty retrieval decisions, max candidates, bounded,
  deterministic order, digest equality, repeatability failures, memory
  mutation, World/terrain mutation, movement stack usage, and behavior action
  execution.

Events:

- `lab_goal_selection_memory_recorded`;
- `lab_goal_selection_memory_summary_recorded`.

Limitations:

- no behavior-loop integration;
- no behavior action execution;
- no memory write or mutation;
- no retrieval rerun;
- no mood, emotional memory, relationships, trust, communication, community,
  social memory, or task board;
- no movement stack feedback source;
- no World or terrain mutation;
- no physical placeholder or Core entity creation/movement;
- no route following, full-route execution, pathfinding, reservation runtime,
  embeddings, Python, LLM, or RL.

Next phase: Phase 5.4C - Goal Selection From Retrieved Memory Hardening.

## Phase 5.4C Implementation Status

Phase 5.4C added `goal_selection_from_memory_hardening_smoke`, a fixture-only
hardening scenario for the goal-selection-from-retrieved-memory contract.

Scenario:

- `goal_selection_from_memory_hardening_smoke`;
- fixture-only, no World created;
- consumes provided retrieved-memory records;
- does not rerun retrieval;
- does not execute behavior actions;
- does not write or mutate memory;
- does not call the movement stack.

Cases:

- baseline compatible with Phase 5.4B;
- safety memory selects `seekSafety`;
- curiosity memory selects `explore`;
- nearby memory selects `observeOtherAgent`;
- idle memory selects `idle`;
- empty retrieval keeps currentGoal;
- currentGoal continuity bonus;
- duplicate candidate merge;
- maxCandidates respected;
- maxCandidates above the v0 limit is clamped to 5;
- scores remain bounded;
- deterministic tie-break;
- unsorted input produces stable output;
- conflicting safety and curiosity prioritizes safety when fear is high;
- low-confidence memory does not override stronger currentGoal pressure;
- unknown memory type is ignored;
- unknown goal is not selected;
- unchanged goal is covered;
- memory influence reason is required;
- behavior action execution remains false;
- memory mutation remains false;
- retrieval rerun remains false;
- digest repeatability is stable.

Memory-to-goal mapping remains the explicit v0 table:

- `safety_reaction` -> `seekSafety`;
- `curiosity_reaction` -> `explore`;
- `nearby_agent_observed` -> `observeOtherAgent`;
- `idle_tick_summary` -> `idle`;
- `goal_confirmed` and `goal_changed` remain limited to known current goals;
- `behavior_action` and `effect_applied` only use direct safe v0 matches.

Candidates and decisions:

- `goal_selection_memory_hardening_candidates.json`;
- `goal_selection_memory_hardening_decisions.json`;
- 22 decisions in the validated debug run;
- 43 candidates;
- selectedGoals = 22;
- goalChanges = 15;
- unchangedGoals = 7;
- memoryInfluencedDecisions = 15;
- emptyRetrievalDecisions = 3.

Scoring:

- memory score component;
- need/fear component;
- currentGoal continuity component;
- source priority component;
- scores bounded to 0...3;
- stable tie-break by score, priority, goal, source, and supporting memory
  types;
- no random, embeddings, LLM, semantic guessing, or unordered-container
  influence.

Report:

- `goal_selection_memory_hardening_report.json`;
- success true in validated debug run;
- cases = 23;
- casesPassed = 23;
- casesFailed = 0;
- decisions = 22;
- candidates = 43;
- maxCandidates = 4;
- bounded = true;
- deterministicOrder = true;
- behaviorActionExecuted = false;
- memoryMutated = false;
- retrievalRerun = false;
- movementStackUsed = false;
- worldMutated = false;
- terrainMutated = false.

Invariant:

- `goal_selection_memory_hardening_invariant_report.json`;
- 70 checks passed;
- 0 checks failed;
- covers scenario, seed, all required cases, selected goal presence, known v0
  goals, goal changes, unchanged goals, memory influence, empty retrieval,
  maxCandidates, duplicate merges, score bounds, deterministic order, selected
  candidate membership, influence reasons, boundary flags, digest equality,
  outputs, metrics/events, docs, and success contract.

Digest:

- `goal_selection_memory_hardening_digest.json`;
- digest `d5001cc2acdd000a`;
- repeat digest `d5001cc2acdd000a`;
- repeatabilityFailures = 0.

Metrics:

- `metrics.json`;
- emits `goalSelectionMemoryHardening*` metrics for success, cases, decisions,
  candidates, selected goals, goal changes, unchanged goals, influenced
  decisions, empty retrieval decisions, maxCandidates, bounded,
  deterministic order, behavior action execution, memory mutation, retrieval
  rerun, movement stack usage, World/terrain mutation, digest equality, and
  repeatability failures.

Events:

- `lab_goal_selection_memory_hardening_recorded`.

Limitations:

- no behavior-loop integration;
- no behavior action execution;
- no memory write or mutation;
- no retrieval rerun;
- no mood, emotional memory, relationships, trust, communication, community,
  social memory, or task board;
- no movement stack feedback source;
- no World or terrain mutation;
- no physical placeholder or Core entity creation/movement;
- no route following, full-route execution, pathfinding, reservation runtime,
  embeddings, Python, LLM, or RL.

Next phase: Phase 5.5A - Behavior Loop Memory-Goal Bridge Planning.

## Phase 5.5A Planning Status

Phase 5.5A is implemented as
`PHASE_5_5A_BEHAVIOR_LOOP_MEMORY_GOAL_BRIDGE_PLAN.md`.

It defines the future contract for consuming
`LabGoalSelectionFromMemoryDecision`-style evidence inside a behavior-loop
bridge. The bridge remains fixture-only in the next implementation phase: it
may choose a selected goal for behavior-loop action selection, but it must not
execute actions, write or mutate memory, rerun retrieval, call the movement
stack, mutate World/terrain, or integrate directly into `agents_basic`.

Next phase: Phase 5.5B - Behavior Loop Memory-Goal Bridge Fixture Smoke.
