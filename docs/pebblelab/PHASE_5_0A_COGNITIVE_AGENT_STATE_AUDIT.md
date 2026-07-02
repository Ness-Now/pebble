# Phase 5.0A — Cognitive Agent State Audit And Behavior Loop Resync

## Purpose

Phase 5.0A resumes PebbleLab after the Phase 4.28 Agent Movement Stack closure
and prepares the project for a real cognitive agent behavior loop.

The goal is to record what exists today in code, what is only smoke/fixture
infrastructure, where the movement stack can later connect, and what must stay
out of scope until the behavior-loop contract is explicit.

This phase is docs/audit-only. It does not add runtime behavior, scenarios,
metrics, events, movement stack changes, World mutation, route following,
Python, LLM, or RL.

## Starting point

- Branch: `lab/pebblelab-v1`.
- Expected starting commit:
  `688c109ace7ddb92de1a39168a41c3726c516dc0`.
- Phase 4.28G is complete.
- Agent Movement Stack consolidation is closed.
- The project direction returns to agent cognition, behavior loops, and later
  society simulation.

The 4.28 stack provides deterministic intent, feedback, policy, planning,
handoff, arbitration, application, replay, metrics/events, and boundary audit
evidence. It does not complete the cognitive agent model.

## Current LabAgent state

`LabAgent` is the current abstract agent state container. It is implemented in
`Sources/PebbleLab/LabAgent.swift`.

Current fields:

- `id`: stable scenario agent id, for example `agent_0`;
- `type`: currently initialized as `abstract_lab_agent`;
- `state`: string state such as `idle`, `resting`, `observing`, `moving`, or
  `waiting`;
- `position`: `LabAgentPosition` with integer `x`, `y`, and `z`;
- `needs`: `LabAgentNeeds` with `hunger`, `fatigue`, `curiosity`, and
  `safety`;
- `health`: integer health, initialized to `100`;
- `fear`: integer fear, initialized to `10`;
- `homePosition`: spawn/home position used by `seekSafety`;
- `inventory`: `LabInventory`, a string-keyed count map;
- `observation`: optional `LabAgentObservation` from World read-only
  observation;
- `nearbyAgents`: array of `LabNearbyAgentObservation`;
- `currentGoal`: `LabGoal`;
- `lastAction`: optional `LabAgentAction`;
- `lastActionEffect`: optional `LabAgentActionEffect`;
- `lastMovement`: optional `LabAgentMovement`;
- `memory`: array of `LabMemoryEntry`;
- `tickCreated`: currently fixed at `0`;
- `ticksAlive`: incremented by `tick()`;
- counters for observations, nearby observations, goal selections, goal
  changes, actions, action effects, movement, distance moved, return-home
  moves, and distance reduced toward home.

Derived state:

- `isAlive` is `health > 0`;
- `distanceFromHome` is Manhattan distance from `position` to `homePosition`.

`LabAgent.tick()` increments hunger by `0.01`, fatigue by `0.005`, resets
`state` to `idle`, and increments `ticksAlive`.

`LabAgent.observe(world:tick:)` records the current position, chunk coordinates,
chunk readiness, surface and height values, block below, and block at feet. If
a tick is provided, it appends an `observed` memory entry.

`LabAgent.observeNearbyAgents` records nearby agents within a default radius of
8 Manhattan distance. It stores relative `dx`, `dy`, `dz`, and distance. This
is perception only, not social behavior.

`LabAgent.selectGoal` chooses one current goal from health, fear, safety,
fatigue, curiosity, and nearby-agent evidence. Goal kinds are `idle`, `rest`,
`seekSafety`, `explore`, and `observeOtherAgent`.

`LabAgent.decideAction` maps the current goal to an abstract action:

- `seekSafety` -> `move_abstract` toward home, or `wait` if already home;
- `rest` -> `rest`;
- `observeOtherAgent` -> `observe_area`;
- `explore` -> deterministic `move_abstract`;
- `idle` -> `wait`.

`LabAgent.applyLastActionEffect` mutates needs, fear, and state according to
the last action. It records the before/after values in `LabAgentActionEffect`.

`LabAgent.applyAbstractMovement` applies only a `move_abstract` action to the
agent's abstract position. It records `LabAgentMovement`, movement counters,
return-home counters, and a memory entry.

`LabInventory` is real abstract state with `add`, `remove`, `has`, and `count`
operations. It is not yet gameplay pickup, crafting, sharing, or item registry
integration.

`LabMemoryEntry` contains only `tick`, `type`, `summary`, and `importance`.
Memory is append-only in current agent methods and is surfaced as recent
memory in agent snapshots. There is no memory retrieval, emotional memory,
relationship memory, decay, query, or planning integration yet.

## Current cognitive loop

The current loop is implemented mostly in `main.swift`, with behavior methods
on `LabAgent`.

Initial output setup for agent scenarios:

```text
scenario preparation
-> make LabAgent values
-> optional inventory assignment
-> optional physical placeholder/core entity setup
-> run_started event
-> spawned memory
-> World observation
-> nearby-agent observation
-> goal selection
-> spawn/home/inventory/observation/nearby/goal/memory events
```

Per-tick loop for current abstract agent scenarios:

```text
World.tick
-> LabAgent.tick
-> World observation
-> nearby-agent observation
-> goal selection
-> action selection
-> action effect application
-> abstract movement application
-> optional physical placeholder sync
-> optional core entity sync
-> optional world_tick event
-> snapshots, metrics, events, and reports
```

When no output path is provided, the same agent methods are called without
event encoding. For movement-stack fixture/audit scenarios, `main.swift`
usually does not create a World and sets `ticksCompleted` from options while
specialized report builders produce the outputs.

The loop is real but still monolithic: `main.swift` owns orchestration, event
encoding, scenario branching, movement-stack report dispatch, and output
writing. There is no separate `LabBehaviorLoop` or `LabCognition` module yet.

## What is truly cognitive today

Current real cognition-adjacent features:

- needs state: hunger, fatigue, curiosity, and safety;
- health and fear state;
- home position and distance-from-home reasoning;
- deterministic goal selection from health, fear, safety, fatigue, curiosity,
  and nearby-agent observations;
- abstract action selection from goals;
- action effects that change fatigue, fear, curiosity, and state;
- append-only memory entries for spawn, observation, action choice, action
  effect, and abstract movement;
- nearby-agent perception with relative offsets and Manhattan distance;
- abstract inventory state with deterministic string counts;
- abstract movement for `move_abstract`;
- metrics and events for observations, nearby agents, goals, memory, action
  effects, movement, inventory, fear, and home state.

This is enough to call PebbleLab's current agents minimal abstract agents, but
not enough to call them complete cognitive or social agents.

## What is not cognitive yet

Missing or not yet owned by a cognitive architecture:

- mood;
- emotional memory;
- relationship model;
- social trust;
- friendship, hostility, or group membership;
- communication;
- task board;
- community state;
- shared goals;
- long-term planning;
- learning;
- memory retrieval or memory-driven decisions;
- inventory gameplay;
- crafting, mining, construction, or resource use;
- goal persistence beyond current deterministic selection;
- behavior-loop module boundaries;
- movement-stack adapter from cognitive goals;
- Python integration;
- LLM integration;
- RL integration.

## Movement stack relationship

The movement stack should become a sub-layer below cognition, not a replacement
for cognition.

Future bridge shape:

```text
cognitive goal
-> intended abstract action
-> optional movement intent
-> movement stack
-> approved or denied movement
-> feedback
-> future memory update
```

Current status:

- `LabAgent.decideAction` can choose `move_abstract` directly from goals;
- movement-stack scenarios separately prove intent production, feedback
  consumption, policy modes, bounded planning, first-step handoff, arbitration,
  approved application, replay, metrics/events, and boundary reports;
- there is not yet a clean `LabMovementStackAdapter` owned by a cognitive
  behavior loop;
- movement feedback is not yet converted into durable cognitive memory, mood,
  needs, or relationships.

The next bridge should be fixture-first. It should not introduce route
following, full-route execution, persistent route commitment, World mutation,
live pathfinding, reservation runtime, or hidden movement-policy activation.

## Existing scenarios relevant to cognition

Cognitive / abstract agent scenarios:

- `agent_smoke`;
- `agents_basic`;
- `seek_safety_smoke`;
- `long_run_smoke`;
- `regression_smoke`.

Physical / representation scenarios:

- `physical_placeholder_smoke`;
- `physical_sync_smoke`;
- `core_entity_smoke`;
- `physical_behavior_smoke`;
- `physical_behavior_multi_smoke`.

Movement stack scenarios:

- `agent_intent_production_fixture_smoke`;
- `agent_intent_production_hardening_smoke`;
- `agent_intent_to_tick_fixture_smoke`;
- `agent_intent_to_tick_live_readonly_smoke`;
- `agent_intent_to_tick_approved_application_smoke`;
- `agent_feedback_consumption_fixture_smoke`;
- `agent_feedback_consumption_hardening_smoke`;
- `feedback_to_agent_intent_context_fixture_smoke`;
- `feedback_to_agent_intent_context_hardening_smoke`;
- `feedback_aware_intent_policy_fixture_smoke`;
- `feedback_aware_intent_policy_hardening_smoke`;
- `feedback_aware_intent_to_tick_fixture_smoke`;
- `feedback_aware_intent_to_tick_live_readonly_smoke`;
- `feedback_aware_intent_to_tick_approved_application_smoke`;
- `multi_tick_closed_loop_fixture_smoke`;
- `multi_tick_closed_loop_hardening_smoke`;
- `multi_tick_closed_loop_live_readonly_smoke`;
- `multi_tick_closed_loop_approved_application_smoke`;
- `alternate_local_hint_fixture_smoke`;
- `alternate_local_hint_hardening_smoke`;
- `alternate_local_hint_live_readonly_smoke`;
- `alternate_local_hint_approved_application_smoke`;
- `alternate_local_hint_multi_tick_replay_smoke`;
- `agent_movement_policy_consolidation_fixture_smoke`;
- `agent_movement_policy_boundary_hardening_smoke`;
- `agent_movement_policy_consolidated_replay_regression_smoke`;
- `bounded_path_planning_fixture_smoke`;
- `bounded_path_planning_hardening_smoke`;
- `bounded_path_planning_to_tick_first_step_smoke`;
- `bounded_path_planning_approved_application_smoke`;
- `bounded_path_planning_multi_tick_replay_smoke`;
- `agent_movement_stack_contract_fixture_smoke`;
- `agent_movement_stack_contract_boundary_hardening_smoke`;
- `agent_movement_stack_replay_regression_adapter_smoke`;
- `agent_movement_stack_metrics_event_compatibility_smoke`;
- `agent_movement_stack_consolidated_multi_tick_replay_smoke`.

World observation scenarios:

- `world_observation_smoke`;
- `world_observation_multi_smoke`;
- `terrain_scan_smoke`;
- `terrain_scan_edge_smoke`;
- `terrain_column_scan_smoke`;
- `terrain_column_scan_edge_smoke`;
- `terrain_semantics_fixture_smoke`;
- `terrain_traversability_fixture_smoke`;
- `terrain_pathfinding_fixture_smoke`;
- `terrain_pathfinding_column_smoke`;
- `terrain_pathfinding_column_edge_smoke`;
- `terrain_pathfinding_column_positive_smoke`;
- `terrain_path_movement_fixture_smoke`;
- `terrain_path_live_movement_smoke`;
- `terrain_collision_fixture_smoke`;
- `terrain_collision_live_readonly_smoke`.

Note: the terrain pathfinding and terrain movement scenarios are world
observation/movement-infrastructure history, not cognitive behavior ownership.

## Static code inventory

Largest PebbleLab Swift files from the audit:

- `main.swift`: 9827 lines;
- `LabAgentIntentProduction.swift`: 7642 lines;
- `LabMultiAgentMovement.swift`: 5939 lines;
- `LabOutput.swift`: 5312 lines;
- `LabBoundedPathPlanning.swift`: 5217 lines;
- `LabAgentMovementStackContract.swift`: 4860 lines;
- `LabAgentFeedbackConsumption.swift`: 2819 lines;
- `LabAgentAlternateLocalHint.swift`: 2473 lines;
- `LabAgentMovementPolicyConsolidation.swift`: 2092 lines;
- `LabEvents.swift`: 1500 lines.

Files to watch:

- `main.swift` is doing scenario dispatch, loop orchestration, event encoding,
  report dispatch, and output writing;
- `LabAgentMovementStackContract.swift` is large and should not be split during
  the cognitive resync;
- movement, World observation, physical representation, and behavior concerns
  are distributed across several scenario-specific files.

## Risks

- Continuing to stack movement smokes without returning to the agent model;
- creating behavior runtime before the behavior-loop contract is named;
- connecting goals directly to World mutation;
- confusing green reports with agent intelligence;
- making `main.swift` larger as the default orchestration surface;
- making `LabAgentMovementStackContract.swift` larger or broader during Phase
  5;
- mixing cognition, movement, World observation, and physical representation in
  the same files;
- letting inventory become gameplay without a separate contract;
- treating nearby-agent perception as social behavior before relationships or
  communication exist;
- treating memory entries as learning before read/query/update ownership
  exists.

## Recommended next architecture

Future code should move toward explicit ownership:

- `LabAgent`: agent state only;
- `LabCognition` or equivalent: needs, goal, action, and memory-facing
  decisions;
- `LabBehaviorLoop`: per-tick cognitive orchestration;
- `LabMovementStackAdapter`: bridge from cognitive movement intent to the
  movement stack;
- `LabMemorySystem`: memory write/read/query/update ownership;
- `LabSocialModel`: later relationship and social perception interpretation;
- `LabCommunity`: later shared tasks, group state, and society simulation.

Do not implement these modules in Phase 5.0A. Use them to shape Phase 5.1A and
later fixtures.

## Recommended next phase

Phase 5.1A — Behavior Loop Contract Planning.

Goal: define a minimal fixture-only behavior-loop contract:

```text
needs
-> goal
-> intended abstract action
-> optional movement intent
-> movement stack adapter later
-> result
-> feedback
-> memory update
```

Phase 5.1A should define ownership and reports before adding runtime behavior.
It should not add World mutation, LLM, Python, RL, route following, mining,
construction, communication, or society runtime.

## Explicit out of scope

- no World mutation;
- no terrain mutation;
- no route following expansion;
- no full-route execution;
- no persistent route commitment;
- no Python;
- no LLM;
- no RL;
- no mining;
- no construction;
- no communication;
- no society runtime;
- no save/load changes;
- no renderer changes;
- no resource changes;
- no registry changes;
- no golden changes;
- no behavior runtime change;
- no movement stack change.

## Validation

Commands for this docs/audit-only phase:

- `git status`;
- `git branch --show-current`;
- `git pull origin lab/pebblelab-v1`;
- `git log --oneline -12`;
- `swift build`;
- `swift build -c release --product Pebble`;
- `git diff --check`.

Results:

- `swift build` passed;
- `swift build -c release --product Pebble` passed;
- `git diff --check` passed.

`pebsmoke` is optional because this phase changes no Swift, runtime behavior,
scenario, movement stack code, Core simulation behavior, renderer, resources,
registries, save/load, or goldens.
