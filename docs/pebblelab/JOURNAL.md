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
