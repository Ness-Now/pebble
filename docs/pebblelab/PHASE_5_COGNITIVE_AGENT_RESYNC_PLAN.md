# Phase 5 — Cognitive Agent Resync Plan

## Purpose

Return PebbleLab from movement-stack infrastructure work toward AI agents and
society simulation. Phase 4.28 closed the abstract movement/intention/feedback/
planning/arbitration/replay stack. Phase 5 should use that stack as a bounded
sub-layer while resynchronizing ownership of perception, memory, needs, mood,
goals, inventory meaning, behavior loops, and later social simulation.

This plan is documentation-only. It does not add Swift runtime behavior,
scenarios, metrics, events, World reads, World mutation, route following,
Python, LLM, or RL.

## Current confirmed foundation

PebbleLab already has:

- a headless executable target;
- deterministic runner options, scenario selection, seeded execution, and output
  directories;
- JSON reports, metrics, events, digests, and invariant reports;
- abstract agents with earlier history around nearby social perception, goals,
  health/fear/home state, inventory, and abstract movement;
- physical placeholder and unregistered Core entity probe history, kept
  carefully bounded and non-persistent;
- read-only terrain/world observation history;
- a consolidated movement stack covering intent production, feedback
  consumption, feedback-aware policy, alternate local hints, multi-tick closed
  loop, movement policy consolidation, bounded planning, first-step handoff,
  tick arbitration, approved lab-map-only application, replay regression,
  boundary hardening, and metrics/events compatibility;
- policy versions v0, v1, v2, and v3 as explicit opt-in modes;
- v4 reserved-only;
- Phase 4.28F consolidated replay proving the current stack evidence remains
  deterministic and boundary-clean.

## Important distinction

The movement stack is not a cognitive agent.

Movement intent, policy choice, prior feedback consumption, first-step planning,
tick arbitration, and replay proof are not memory, mood, social behavior, needs
management, long-term goal ownership, communication, or gameplay autonomy.

A route or first-step proof is not gameplay behavior. The current stack proves
that bounded abstract movement decisions can be proposed, arbitrated, applied
to lab maps where approved, audited, and replayed deterministically. It does
not prove that agents understand why they move, remember consequences, pursue
owned goals, coordinate socially, manipulate inventory meaningfully, mine,
build, or participate in a society.

## Cognitive loop target

The target behavior loop for future phases is:

```text
perception
-> memory
-> needs
-> mood
-> goal
-> intent
-> movement stack
-> action result
-> feedback
-> memory update
```

Ownership should remain explicit:

- perception captures bounded observations and social evidence;
- memory stores durable, deterministic agent-local facts or episodes;
- needs track internal pressures without selecting movement directly;
- mood summarizes short-term affective state from needs, memory, and feedback;
- goal selection chooses one bounded objective from agent state;
- intent turns the current goal into a proposed action;
- movement stack arbitrates only movement-relevant intent and feedback;
- action result records what happened;
- feedback reports approval, denial, movement, blockage, or other result;
- memory update decides what the agent learns from the result.

## Immediate audit questions

Before coding more behavior, Phase 5.0A should audit:

- current `LabAgent` fields and which are cognitive state versus movement or
  report state;
- current `LabGoal` fields and whether they represent durable ownership,
  per-tick selection, or scenario fixture data;
- current `LabMemoryEntry` fields and whether memory has clear write/read
  ownership;
- current needs, including health, fear, home, hunger-like future needs, and
  whether each is implemented or only implied;
- inventory status, including whether `LabInventory` is state, gameplay, report
  evidence, or future capability;
- social perception status, especially nearby-agent observations versus actual
  social behavior;
- movement stack entry points that a future behavior loop may call without
  taking over arbitration or application;
- reports needed to distinguish cognitive state changes from movement-stack
  outputs;
- scenarios to preserve as non-regression coverage before adding behavior-loop
  fixtures.

## Recommended next implementation phases

- Phase 5.0B - Cognitive Agent State Audit Smoke or Docs;
- Phase 5.1 - Behavior Loop Contract Fixture;
- Phase 5.2 - Memory Update From Movement Feedback Fixture;
- Phase 5.3 - Goal To Movement Intent Bridge Fixture;
- Phase 5.4 - agents_basic_behavior_loop_smoke;
- Phase 5.5 - Multi-Agent Social Perception Behavior Smoke.

Phase 5.0B may remain docs-only if the audit shows current types need a clear
contract before code. If it becomes a smoke, it should be fixture-first and
report-only, with no new movement runtime, no World mutation, and no route
following.

## Safe integration boundaries

The movement stack may be used as a sub-layer only after a cognitive loop owns
why an agent wants to move. The stack should continue to own movement
arbitration evidence, first-step-only handoff, feedback timing, lab-map-only
approved application, and replay invariants.

The cognitive loop should not read live World or collision through movement
policy. It should consume bounded perception results through explicit inputs.
It should not treat planner advisory steps as commitments, future route state,
or behavior memory unless a later docs-only phase creates that contract.

Memory and goal updates should be deterministic, agent-local unless explicitly
shared, and reportable. Feedback from movement can inform memory, needs, or
mood only through a future explicit bridge fixture.

## Next scenarios

The next concrete scenario after planning should be small and contract-shaped.
Good candidates:

- a fixture-only cognitive state audit report;
- a behavior-loop contract fixture with synthetic perception and feedback;
- a memory-update-from-feedback fixture that records one bounded memory entry;
- a goal-to-movement-intent bridge fixture that proves ownership boundaries
  without route following.

Avoid starting with a live World scenario, social group dynamics, construction,
mining, inventory gameplay, or Python/LLM/RL integration.

## Out of scope

- World mutation;
- construction;
- mining;
- Python;
- LLM;
- RL;
- complex society;
- uncontrolled route following;
- unbounded pathfinding;
- dynamic replanning;
- reservation runtime;
- save/load changes;
- renderer changes;
- resource changes;
- registry changes;
- goldens changes;
- physical Core entity movement;
- physical placeholder movement;
- communication runtime;
- social behavior runtime beyond planned bounded fixtures.

## Definition of done for Phase 5.0A

- Docs updated;
- roadmap resynced;
- Phase 4.28 closure recorded;
- Phase 5 cognitive direction recorded;
- no Swift runtime changes;
- no new scenario;
- no runtime metrics or events;
- no tests required beyond build/docs sanity;
- next prompt can start from Phase 5.0B.

## Phase 5.0A Status

Phase 5.0A is implemented as
`PHASE_5_0A_COGNITIVE_AGENT_STATE_AUDIT.md`.

The audit confirms that PebbleLab already has a minimal abstract-agent
cognitive loop with needs, goal selection, action choice, action effects,
memory entries, nearby-agent perception, inventory state, home/safety/fear
state, abstract movement, and reporting. It also confirms that this loop is
not yet a full behavior architecture: mood, emotional memory, relationship
modeling, social trust, communication, task boards, community state, long-term
planning, learning, Python, LLM, and RL remain out of scope.

The recommended next phase has been resynced to Phase 5.1A - Behavior Loop
Contract Planning.

## Phase 5.1A Status

Phase 5.1A is implemented as
`PHASE_5_1A_BEHAVIOR_LOOP_CONTRACT_PLAN.md`.

The plan defines the future minimal behavior loop contract, proposed
implementation types, ownership boundaries, future `behaviorLoop*` metrics,
future behavior-loop events, invariants, and the next fixture-only scenario.
It keeps movement stack integration as a later bridge and does not implement
runtime behavior.

The recommended next phase is Phase 5.1B - Behavior Loop Contract Fixture
Smoke.

## Phase 5.1B Status

Phase 5.1B implemented `behavior_loop_contract_fixture_smoke`, the first
fixture-only cognitive behavior-loop contract smoke.

The fixture creates three abstract agents for three ticks, builds
behavior-loop inputs, records decisions, applies bounded abstract effects,
writes bounded memory entries, emits `behaviorLoop*` metrics, writes behavior
loop reports/digests/invariants, and records
`lab_behavior_loop_decision_recorded` events. It does not create a World, call
the movement stack, mutate terrain, move Core entities, move physical
placeholders, add social behavior, add communication, or connect Python, LLM,
or RL.

The recommended next phase is Phase 5.1C - Behavior Loop Hardening.

## Phase 5.1C Status

Phase 5.1C implemented `behavior_loop_hardening_smoke`, a fixture-only
hardening smoke for the minimal cognitive behavior-loop contract.

The smoke covers 12 deterministic cases: baseline compatibility, seek safety,
exploration, observing a nearby agent, idle fallback, missing goal fallback,
empty nearby agents, existing memory, empty inventory, extreme needs,
deterministic decision ordering, and digest repeatability. The validated debug
run produced 22 decisions, 22 bounded effects, 22 bounded memory writes, 12
cases passed, 0 cases failed, 52 invariant checks passed, 0 invariant checks
failed, and matching digest/repeat digest values.

The scenario does not create a World, call the movement stack, mutate terrain,
move Core entities, move physical placeholders, add route following,
pathfinding, reservation runtime, mood, relationships, trust, communication,
community state, Python, LLM, or RL.

The recommended next phase is Phase 5.2A - Memory Update From Behavior Result
Planning.

## Phase 5.2A Status

Phase 5.2A is implemented as
`PHASE_5_2A_MEMORY_UPDATE_FROM_BEHAVIOR_RESULT_PLAN.md`.

The plan defines how future behavior-loop results should become deterministic,
bounded memory update proposals before any runtime implementation. It separates
behavior results from memory proposal/acceptance/rejection, keeps v0 memory
writes bounded to max 1 accepted behavior memory per agent per tick, defines
allowed v0 memory types, proposes `memoryUpdate*` metrics and
`lab_memory_update_recorded` events, and keeps memory retrieval, emotional
memory, mood, relationships, trust, communication, movement stack feedback,
Python, LLM, and RL out of scope.

The recommended next phase is Phase 5.2B - Memory Update From Behavior Result
Fixture Smoke.

## Phase 5.2B Status

Phase 5.2B implemented
`memory_update_from_behavior_result_fixture_smoke`, the first fixture-only
memory update layer from controlled behavior-loop results.

The fixture creates three controlled behavior results, turns them into four
memory update proposals, accepts three writes, rejects one duplicate same
tick/agent/type proposal, writes before/after memory snapshots, emits
`memoryUpdate*` metrics, records `lab_memory_update_recorded` events, and
validates a stable digest. The validated debug run produced 3 accepted writes,
1 rejected write, memory count total 0 -> 3, 40 invariant checks passed, and
0 invariant checks failed.

The scenario does not create a World, call the movement stack, mutate terrain,
move Core entities, move physical placeholders, add retrieval, emotional
memory, mood, relationships, trust, communication, community state,
movement-stack feedback, Python, LLM, or RL.

The recommended next phase is Phase 5.2C - Memory Update Hardening.

## Phase 5.2C Status

Phase 5.2C implemented `memory_update_hardening_smoke`, a fixture-only
hardening smoke for the memory update layer.

The smoke covers 13 deterministic cases: baseline compatibility, accepted
safety reaction, accepted curiosity reaction, accepted nearby-agent
observation, duplicate rejection, max one accepted write per agent/tick,
invalid memory type rejection, empty summary rejection, low/high importance
rejection, memory count consistency, deterministic proposal ordering, and
digest repeatability. The validated debug run produced 21 proposals, 14
accepted writes, 7 rejected writes, memory count total 0 -> 14, 13 cases
passed, 0 cases failed, 55 invariant checks passed, 0 invariant checks failed,
and matching digest/repeat digest values.

The scenario does not create a World, call the movement stack, mutate terrain,
move Core entities, move physical placeholders, add retrieval, emotional
memory, mood, relationships, trust, communication, community state,
movement-stack feedback, Python, LLM, or RL.

The recommended next phase is Phase 5.3A - Memory Retrieval Planning.

## Phase 5.3A Status

Phase 5.3A is implemented as
`PHASE_5_3A_MEMORY_RETRIEVAL_PLAN.md`.

The plan defines the future v0 retrieval contract for reading accepted memory
entries through bounded queries, ranked retrieved records, deterministic
scoring, stable ordering, retrieval summaries, reports, invariants, metrics,
and events. It keeps retrieval read-only: no memory write, no memory mutation,
no World, no movement stack, no behavior-loop goal influence, no mood, no
relationships, no trust, no communication, no Python, no LLM, no embeddings,
and no RL.

The recommended next phase is Phase 5.3B - Memory Retrieval Fixture Smoke.

## Phase 5.3B Status

Phase 5.3B implemented `memory_retrieval_fixture_smoke`, the first
fixture-only memory retrieval smoke.

The fixture creates controlled memory snapshots for three agents, executes
seven bounded retrieval queries across recent, important, by-type,
safety-related, curiosity-related, and nearby-agent-related query kinds,
produces ranked retrieval records, covers one empty result, emits
`memoryRetrieval*` metrics, records `lab_memory_retrieval_recorded` events,
and validates a stable digest. The validated debug run produced 8 available
memories, 8 considered memories, 7 retrieved memories, 1 empty result, 39
invariant checks passed, 0 invariant checks failed, and matching
digest/repeat digest values.

The scenario does not mutate memory, create a World, call the movement stack,
mutate terrain, move Core entities, move physical placeholders, add goal
influence, mood, emotional memory, relationships, trust, communication,
community state, movement-stack feedback, embeddings, Python, LLM, or RL.

The recommended next phase is Phase 5.3C - Memory Retrieval Hardening.

## Phase 5.3C Status

Phase 5.3C implemented `memory_retrieval_hardening_smoke`, a fixture-only
hardening scenario for memory retrieval v0.

The scenario validates 19 cases covering baseline compatibility, query kinds,
empty results, maxResults bounds, out-of-bounds maxResults clamping to 5,
minImportance, recency windows, score bounds, rank contiguity, deterministic
tie-breaks, unsorted input, invalid query rejection, memory read-only behavior,
and digest repeatability. The validated debug run produced 23 queries, 56
available memories, 37 considered memories, 34 retrieved memories, 3 empty
results, 61 invariant checks passed, 0 invariant checks failed, and matching
digest/repeat digest values.

The scenario does not write or mutate memory, create a World, call the movement
stack, mutate terrain, move Core entities, move physical placeholders, add goal
influence, mood, emotional memory, relationships, trust, communication,
community state, movement-stack feedback, embeddings, Python, LLM, or RL.

The recommended next phase is Phase 5.4A - Goal Selection From Retrieved
Memory Planning.

## Phase 5.4A Status

Phase 5.4A is implemented as
`PHASE_5_4A_GOAL_SELECTION_FROM_RETRIEVED_MEMORY_PLAN.md`.

The plan defines how retrieved memories may later become bounded goal
candidates and a selected goal proposal. It documents the current real
`LabGoal`/`currentGoal` state, the existing priority order in
`LabAgent.selectGoal`, a v0 memory-to-goal mapping, deterministic candidate
scoring, maxCandidates bounds, duplicate candidate merging, unchanged-goal and
empty-retrieval cases, future `goalSelectionMemory*` metrics, future
`lab_goal_selection_memory_recorded` events, and invariant expectations for a
fixture-only Phase 5.4B.

The plan keeps behavior action execution, behavior-loop integration, memory
write/mutation, World access, movement stack, mood, emotional memory,
relationships, trust, communication, community state, embeddings, Python, LLM,
and RL out of scope.

The recommended next phase is Phase 5.4B - Goal Selection From Retrieved
Memory Fixture Smoke.

## Phase 5.4B Status

Phase 5.4B implemented `goal_selection_from_memory_fixture_smoke`, the first
fixture-only runtime layer that turns controlled retrieved memories into goal
candidates and selected goal proposals.

The fixture validates safety, curiosity, nearby-agent, empty retrieval, and
duplicate-merge cases. The validated debug run produced 5 agent inputs, 5
decisions, 9 candidates, 4 goal changes, 1 unchanged goal, 4
memory-influenced decisions, 1 empty retrieval decision, 42 invariant checks
passed, 0 invariant checks failed, and matching digest/repeat digest values.

The scenario does not execute behavior actions, write or mutate memory, rerun
retrieval, create a World, call the movement stack, mutate terrain, move Core
entities, move physical placeholders, add behavior-loop integration, mood,
emotional memory, relationships, trust, communication, community state,
movement-stack feedback, embeddings, Python, LLM, or RL.

The recommended next phase is Phase 5.4C - Goal Selection From Retrieved
Memory Hardening.

## Phase 5.4C Status

Phase 5.4C implemented `goal_selection_from_memory_hardening_smoke`, a
fixture-only hardening scenario for goal selection from retrieved memory.

The scenario validates 23 cases covering baseline compatibility, safety,
curiosity, nearby-agent, and idle mappings, empty retrieval, currentGoal
continuity, duplicate candidate merge, maxCandidates bounds and clamping,
bounded scores, deterministic tie-breaks, unsorted input, conflicting
safety/curiosity memories, low-confidence memory, unknown memory types,
unknown goals, unchanged goals, memory influence reasons, no behavior action
execution, no memory mutation, no retrieval rerun, and digest repeatability.
The validated debug run produced 22 decisions, 43 candidates, 15 goal changes,
7 unchanged goals, 15 memory-influenced decisions, 3 empty retrieval decisions,
70 invariant checks passed, 0 invariant checks failed, and matching
digest/repeat digest values.

The scenario does not execute behavior actions, write or mutate memory, rerun
retrieval, create a World, call the movement stack, mutate terrain, move Core
entities, move physical placeholders, add behavior-loop integration, mood,
emotional memory, relationships, trust, communication, community state,
movement-stack feedback, embeddings, Python, LLM, or RL.

The recommended next phase is Phase 5.5A - Behavior Loop Memory-Goal Bridge
Planning.

## Phase 5.5A Status

Phase 5.5A is implemented as
`PHASE_5_5A_BEHAVIOR_LOOP_MEMORY_GOAL_BRIDGE_PLAN.md`.

The plan defines the future bridge from behavior-loop input plus provided
retrieval/goal-selection evidence to a selected goal for behavior-loop action
selection. It proposes bridge input, decision, and report types, defines v0
flow, goal override rules, action selection rules, future
`behaviorLoopMemoryGoalBridge*` metrics, future
`lab_behavior_loop_memory_goal_bridge_recorded` events, and invariant
expectations for a fixture-only Phase 5.5B.

The plan keeps `agents_basic` integration, live behavior-loop mutation,
behavior action execution, memory writes, memory mutation, retrieval reruns,
movement stack usage, World/terrain mutation, mood, emotional memory,
relationships, trust, communication, community state, embeddings, Python, LLM,
and RL out of scope.

The recommended next phase is Phase 5.5B - Behavior Loop Memory-Goal Bridge
Fixture Smoke.

## Phase 5.5B Status

Phase 5.5B implemented `behavior_loop_memory_goal_bridge_fixture_smoke`, a
fixture-only bridge from controlled goal-selection-from-memory decisions into
abstract behavior-loop goal/action/result summaries.

The fixture uses five synthetic agent snapshots:

- safety memory selects `seekSafety` and abstract action `seekSafety`;
- curiosity memory selects `explore` and abstract action `explore`;
- nearby-agent memory selects `observeOtherAgent` and abstract action
  `observeAgent`;
- empty retrieval preserves the current goal;
- low-confidence memory preserves current `seekSafety` continuity.

The scenario writes report, invariant, decisions, digest, metrics, and events.
It does not execute behavior actions, write or mutate memory, rerun retrieval,
use the movement stack, create or mutate a World, mutate terrain, move Core
entities, move physical placeholders, add mood, add relationships, add
communication, or connect Python, LLM, embeddings, or RL.

The recommended next phase is Phase 5.5C - Behavior Loop Memory-Goal Bridge
Hardening.

## Phase 5.5C Status

Phase 5.5C implemented `behavior_loop_memory_goal_bridge_hardening_smoke`, a
fixture-only hardening scenario for the behavior-loop memory-goal bridge.

The scenario validates 23 cases covering baseline compatibility, safety,
curiosity, nearby-agent observation, idle mapping, empty retrieval,
low-confidence memory, currentGoal continuity, unknown suggested goals,
missing suggested goals, selected action/result presence, deterministic action
mapping, safety/fear priority over curiosity, known v0 goals, deterministic
order, boundary flags, and digest repeatability.

Unknown suggested goals are sanitized to the current known goal or the idle
fallback. Safety/fear priority is enforced before memory suggestions can
override the selected goal.

The scenario does not execute behavior actions, write or mutate memory, rerun
retrieval, use the movement stack, create or mutate a World, mutate terrain,
move Core entities, move physical placeholders, add mood, add relationships,
add communication, or connect Python, LLM, embeddings, or RL.

The recommended next phase is Phase 5.6A - Cognitive Loop Integration
Planning.
