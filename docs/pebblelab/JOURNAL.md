# PebbleLab Journal

## 2026-06-17 - Phase 3.1 Nearby Agents Social Perception V0

Branch: `lab/pebblelab-v1`

Objective: add minimal abstract social perception so each `agent_smoke` agent
can detect other nearby abstract agents without interaction or communication.

Files modified:

- `Sources/PebbleLab/LabAgent.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DECISIONS.md`
- `docs/pebblelab/JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`

Behavior added:

- `LabNearbyAgentObservation` records nearby agent id, relative offset, and
  Manhattan distance.
- Each `LabAgent` now stores `nearbyAgents`.
- `agent_smoke` agents detect one another at the current distance of 4 blocks.
- `agent_snapshot.json` includes `nearbyAgents`.
- `events.ndjson` includes `agent_observed_nearby_agent`.
- `metrics.json` includes `nearbyAgentObservations` and
  `agentsWithNearbyAgents`.

Commands of validation:

- `swift build`
- `swift run -c release pebsmoke`
- `swift run -c release PebbleLab -- --scenario agent_smoke --seed 42 --ticks 3 --out runs/agent_smoke_nearby_v0`

Result: validation passed. `agent_0` observes `agent_1`, `agent_1` observes
`agent_0`, both observations report Manhattan distance `4`, and the smoke
suite remains green.

Next steps:

- Phase 3.2: `LabGoal/currentGoal v0`.

## 2026-06-17 - Phase 3.2 LabGoal CurrentGoal V0

Branch: `lab/pebblelab-v1`

Objective: add a minimal deterministic goal layer so abstract agents choose a
`currentGoal` after observations and before action selection.

Files modified:

- `Sources/PebbleLab/LabAgent.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DECISIONS.md`
- `docs/pebblelab/JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`

Behavior added:

- `LabGoalKind` and `LabGoal` model deterministic agent goals.
- Each `LabAgent` now stores a non-optional `currentGoal`.
- Goal selection runs after local/social observation and before action choice.
- `agent_smoke` agents choose `observeOtherAgent` when nearby agents are
  detected.
- `agent_snapshot.json` includes `currentGoal`.
- `events.ndjson` includes `agent_goal_changed`.
- `metrics.json` includes `agentGoalSelections`, `agentGoalChanges`, and
  `goalsByKind`.

Commands of validation:

- `swift build`
- `swift run -c release PebbleLab -- --scenario agent_smoke --seed 42 --ticks 3 --out runs/agent_smoke_goal_v0`
- `swift run -c release pebsmoke`

Result: validation passed. Both `agent_smoke` agents select
`observeOtherAgent` after nearby-agent perception, `agent_goal_changed` events
are emitted, metrics include goal selections/changes, and the smoke suite
remains green.

Next steps:

- Phase 3.3: `health/fear/homePosition v0`.

## 2026-06-17 - Phase 3.3 Health Fear HomePosition V0

Branch: `lab/pebblelab-v1`

Objective: add minimal survival and anchoring state to abstract agents without
physical entities, pathfinding, inventory, or social relationships.

Files modified:

- `Sources/PebbleLab/LabAgent.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DECISIONS.md`
- `docs/pebblelab/JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`

Behavior added:

- Each `LabAgent` now has `health`, `fear`, `isAlive`, and `homePosition`.
- `homePosition` is assigned from the spawn position in `agent_smoke`.
- Goal selection now prioritizes low health or high fear before fatigue,
  nearby agents, curiosity, and idle behavior.
- `agent_snapshot.json` includes the new agent state.
- `events.ndjson` includes `agent_home_assigned`.
- `metrics.json` includes `agentsAlive`, `averageHealth`, `averageFear`,
  `agentsWithHome`, `minHealth`, and `maxFear`.

Commands of validation:

- `swift build`
- `swift run -c release PebbleLab -- --scenario agent_smoke --seed 42 --ticks 3 --out runs/agent_smoke_health_fear_home_v0`
- `swift run -c release pebsmoke`

Result: validation passed. `agent_smoke` writes health, fear, alive state, and
home position for both agents; metrics report two living agents with homes; and
the smoke suite remains green.

Next steps:

- Phase 3.4: `LabInventory minimal v0`.

## 2026-06-17 - Phase 3.4 LabInventory Minimal V0

Branch: `lab/pebblelab-v1`

Objective: add a minimal deterministic abstract inventory to PebbleLab agents
without using PebbleCore `ItemStack`, crafting, shared storage, physical pickup,
or world interaction.

Files modified:

- `Sources/PebbleLab/LabAgent.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DECISIONS.md`
- `docs/pebblelab/JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`

Behavior added:

- `LabInventory` stores positive integer item counts keyed by string ids.
- Each `LabAgent` now owns an inventory.
- `agent_smoke` gives `agent_0` one `food` and `agent_1` two `wood`.
- `agent_snapshot.json` includes each inventory.
- `events.ndjson` includes `agent_inventory_assigned` for initial items.
- `metrics.json` includes `agentsWithInventory`, `totalInventoryItems`, and
  `inventoryItemsByKind`.

Commands of validation:

- `swift build`
- `swift run -c release PebbleLab -- --scenario agent_smoke --seed 42 --ticks 3 --out runs/agent_smoke_inventory_v0`
- `swift run -c release pebsmoke`

Result: validation passed. `agent_smoke` writes inventory snapshots for both
agents, emits `agent_inventory_assigned`, reports three total abstract items,
and the smoke suite remains green.

Next steps:

- Phase 3.5: `agents_basic scenario + --agents N`.

## 2026-06-17 - Phase 3.5 agents_basic Scenario And Agents CLI

Branch: `lab/pebblelab-v1`

Objective: keep `agent_smoke` as a fixed two-agent smoke test and add a
deterministic configurable multi-agent scenario for longer abstract runs.

Files modified:

- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DECISIONS.md`
- `docs/pebblelab/JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`

Behavior added:

- CLI option `--agents <Int>` with default `2` and supported range `1...100`.
- Scenario `agents_basic` creates deterministic abstract agents with stable
  ids `agent_0`, `agent_1`, `agent_2`, and so on.
- `agents_basic` places agents on a compact seed/index-derived grid around the
  world center, keeping nearby-agent perception useful.
- `agent_smoke` remains a fixed two-agent validation scenario.
- `agent_snapshot.json`, metrics, and NDJSON agent events are emitted for
  `agents_basic`.

Commands of validation:

- `swift build`
- `swift run -c release PebbleLab -- --scenario agent_smoke --seed 42 --ticks 3 --out runs/agent_smoke_after_agents_basic`
- `swift run -c release PebbleLab -- --scenario agents_basic --seed 42 --agents 10 --ticks 20 --out runs/agents_basic_v0`
- `swift run -c release pebsmoke`

Result: validation passed. `agent_smoke` remains a fixed two-agent scenario,
`agents_basic --agents 10` creates ten living abstract agents with homes and
nearby-agent perception, and the smoke suite remains green.

Next steps:

- Phase 3.6: `abstract movement v0`.

## 2026-06-17 - Phase 3.6 Abstract Movement V0

Branch: `lab/pebblelab-v1`

Objective: let abstract agents update their own position from selected actions
without physical entities, pathfinding, collision, gravity, or world mutation.

Files modified:

- `Sources/PebbleLab/LabAgent.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DECISIONS.md`
- `docs/pebblelab/JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`

Behavior added:

- `explore` can choose `move_abstract` with deterministic `dx`, `dy`, `dz`.
- Abstract movement changes only the agent position; `dy` stays `0`.
- `agents_basic` gives a subset of agents high initial curiosity so movement
  is visible in short validation runs.
- `agent_snapshot.json` includes final positions and `lastMovement`.
- `events.ndjson` includes `agent_moved_abstract`.
- `metrics.json` includes `agentMoves`, `agentsMoved`, and
  `totalManhattanDistanceMoved`.

Commands of validation:

- `swift build`
- `swift run -c release PebbleLab -- --scenario agent_smoke --seed 42 --ticks 3 --out runs/agent_smoke_after_movement`
- `swift run -c release PebbleLab -- --scenario agents_basic --seed 42 --agents 10 --ticks 20 --out runs/agents_basic_movement_v0`
- `swift run -c release pebsmoke`

Result: validation passed. `agent_smoke` remains stable with no movement,
`agents_basic` records abstract movement events and movement metrics, and the
smoke suite remains green.

Next steps:

- Phase 3.7: `abstract returnHome / seekSafety movement`.

## 2026-06-17 - Phase 3.7 Abstract ReturnHome / seekSafety Movement

Branch: `lab/pebblelab-v1`

Objective: make `seekSafety` move abstract agents toward `homePosition` without
physical entities, pathfinding, collision, gravity, or world mutation.

Files modified:

- `Sources/PebbleLab/LabAgent.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DECISIONS.md`
- `docs/pebblelab/JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`

Behavior added:

- `seekSafety` now selects `move_abstract` toward home when away from home.
- The return-home step moves only on X/Z with `dy = 0`.
- `seek_safety_smoke` starts an agent away from home with high fear and proves
  distance reduction.
- Movement events include home coordinates and distance-from-home before/after.
- Metrics include return-home moves, agents moved toward home, distance reduced,
  and agents at/near home.

Commands of validation:

- `swift build`
- `swift run -c release PebbleLab -- --scenario agent_smoke --seed 42 --ticks 3 --out runs/agent_smoke_after_seek_safety`
- `swift run -c release PebbleLab -- --scenario agents_basic --seed 42 --agents 10 --ticks 20 --out runs/agents_basic_after_seek_safety`
- `swift run -c release PebbleLab -- --scenario seek_safety_smoke --seed 42 --ticks 10 --out runs/seek_safety_smoke_v0`
- `swift run -c release pebsmoke`

Result: validation passed. Existing `agent_smoke` and `agents_basic` still run,
and `seek_safety_smoke` reduces distance to home through abstract movement.

Next steps:

- Phase 3.8: `long_run_smoke + event rate controls`.

## 2026-06-17 - Phase 3.8 long_run_smoke And Event Rate Controls

Branch: `lab/pebblelab-v1`

Objective: prepare PebbleLab for longer abstract-agent runs by adding a
long-running smoke scenario and basic controls for high-volume events.

Files modified:

- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DECISIONS.md`
- `docs/pebblelab/JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`

Behavior added:

- `long_run_smoke` runs deterministic abstract agents for longer simulations.
- `--event-rate` throttles frequent NDJSON events while preserving internal
  metrics.
- `--log-world-ticks` controls whether `world_tick` events are emitted.
- Log-volume metrics track written and suppressed events.
- `successCriteria` records basic scenario completion checks.

Commands of validation:

- `swift build`
- `swift run -c release PebbleLab -- --scenario agent_smoke --seed 42 --ticks 3 --out runs/agent_smoke_after_long_run`
- `swift run -c release PebbleLab -- --scenario agents_basic --seed 42 --agents 10 --ticks 20 --out runs/agents_basic_after_long_run`
- `swift run -c release PebbleLab -- --scenario seek_safety_smoke --seed 42 --ticks 10 --out runs/seek_safety_after_long_run`
- `swift run -c release PebbleLab -- --scenario long_run_smoke --seed 42 --agents 10 --ticks 1000 --event-rate 10 --out runs/long_run_smoke_v0`
- `swift run -c release pebsmoke`

Result: validation passed. Existing scenarios still run, and
`long_run_smoke` completes 1000 ticks with throttled frequent events and
success metrics.

Next steps:

- Phase 3.9: `scenario success criteria + regression report`.

## 2026-06-17 - Phase 3.9 Scenario Success Criteria And Regression Report

Branch: `lab/pebblelab-v1`

Objective: add a compact PebbleLab regression scenario that reports pass/fail
checks and key metrics without manually inspecting every output file.

Files modified:

- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DECISIONS.md`
- `docs/pebblelab/JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`

Behavior added:

- `regression_smoke` runs a compact deterministic abstract-agent scenario.
- `regression_report.json` summarizes checks, expected values, actual values,
  and key metrics.
- Success criteria remain in `metrics.json` and are reflected in the report.
- The report is PebbleLab-local and does not replace `pebsmoke`.

Commands of validation:

- `swift build`
- `swift run -c release PebbleLab -- --scenario agent_smoke --seed 42 --ticks 3 --out runs/agent_smoke_after_regression`
- `swift run -c release PebbleLab -- --scenario agents_basic --seed 42 --agents 10 --ticks 20 --out runs/agents_basic_after_regression`
- `swift run -c release PebbleLab -- --scenario seek_safety_smoke --seed 42 --ticks 10 --out runs/seek_safety_after_regression`
- `swift run -c release PebbleLab -- --scenario long_run_smoke --seed 42 --agents 10 --ticks 1000 --event-rate 10 --out runs/long_run_after_regression`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/regression_smoke_v0`
- `swift run -c release pebsmoke`

Result: validation passed. Existing scenarios still run, `regression_smoke`
writes a compact passing report, and `pebsmoke` remains green.

Next steps:

- Phase 4.0: physical agent spike planning.
