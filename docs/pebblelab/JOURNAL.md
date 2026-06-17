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

## 2026-06-17 - Phase 4.0 Physical Agent Spike Planning

Branch: `lab/pebblelab-v1`

Objective: inspect PebbleCore entity architecture and document the safest path
from abstract PebbleLab agents toward a future physical representation, without
implementing an entity or modifying gameplay code.

Files inspected:

- `Sources/PebbleCore/Entity/Entity.swift`
- `Sources/PebbleCore/Entity/Living.swift`
- `Sources/PebbleCore/Entity/AI.swift`
- `Sources/PebbleCore/Entity/EntityRegistry.swift`
- `Sources/PebbleCore/Entity/SpawnHooks.swift`
- `Sources/PebbleCore/Entity/Player.swift`
- `Sources/PebbleCore/Entity/Villagers.swift`
- `Sources/PebbleCore/Entity/Animals.swift`
- `Sources/PebbleCore/World/GameWorld.swift`
- `Sources/PebbleCore/Game/GameCore.swift`
- `Sources/pebsmoke/main.swift`
- `Sources/PebbleLab/LabAgent.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/main.swift`

Files modified:

- `docs/pebblelab/PHASE_4_PHYSICAL_AGENT_SPIKE.md`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DECISIONS.md`
- `docs/pebblelab/JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`

Conclusions:

- `World` stores entities, but `GameCore` is the main orchestrator that ticks
  entities in loaded simulation range.
- Existing mobs are behavior-rich and should not be modified or reused as the
  long-term PebbleLab brain.
- Entity registration is order-sensitive and must be changed only in a focused,
  reviewed future patch.
- The recommended path is to keep `LabAgent` as the abstract cognitive state
  and add a future isolated bridge to a physical placeholder.

Commands of validation:

- `swift build`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/regression_after_phase4_planning`
- `swift run -c release pebsmoke`

Result: validation passed. The phase produced documentation only; no gameplay
code, registries, renderer, audio, resource packs, packaging, or goldens were
modified.

Next steps:

- Phase 4.1: `physical agent placeholder spawn`.

## 2026-06-17 - Phase 4.1 Physical Agent Placeholder Spawn

Branch: `lab/pebblelab-v1`

Objective: add a deterministic non-invasive physical placeholder linked to a
PebbleLab abstract agent, without creating a PebbleCore entity or modifying
registries.

Files modified:

- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabPhysical.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DECISIONS.md`
- `docs/pebblelab/JOURNAL.md`
- `docs/pebblelab/PHASE_4_PHYSICAL_AGENT_SPIKE.md`
- `docs/pebblelab/ROADMAP.md`

Behavior added:

- `physical_placeholder_smoke` creates one abstract `LabAgent`.
- `LabAgentPhysicalBridge` creates one PebbleLab-only physical placeholder.
- The placeholder has stable id `physical_agent_0`, kind
  `lab_physical_placeholder`, spawn tick, position, and tick count.
- `events.ndjson` includes `lab_physical_agent_spawned`.
- `metrics.json` includes physical placeholder metrics.
- `physical_snapshot.json` records the abstract-to-physical link.

Commands of validation:

- `swift build`
- `swift run -c release PebbleLab -- --scenario physical_placeholder_smoke --seed 42 --ticks 3 --out runs/physical_placeholder_smoke_v0`
- `swift run -c release PebbleLab -- --scenario agent_smoke --seed 42 --ticks 3 --out runs/agent_smoke_after_physical_placeholder`
- `swift run -c release PebbleLab -- --scenario agents_basic --seed 42 --agents 10 --ticks 20 --out runs/agents_basic_after_physical_placeholder`
- `swift run -c release PebbleLab -- --scenario seek_safety_smoke --seed 42 --ticks 10 --out runs/seek_safety_after_physical_placeholder`
- `swift run -c release PebbleLab -- --scenario long_run_smoke --seed 42 --agents 10 --ticks 1000 --event-rate 10 --out runs/long_run_after_physical_placeholder`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/regression_after_physical_placeholder`
- `swift run -c release pebsmoke`

Result: validation passed. Existing Phase 3 scenarios remain stable, the new
placeholder smoke reports one physical placeholder, and no PebbleCore entity,
registry, renderer, audio, resource pack, packaging, or golden file was
modified.

Next steps:

- Phase 4.2A: `physical placeholder synchronization with abstract movement`.

## 2026-06-18 - Phase 4.1 Reconciliation For GitHub Publish

Branch: `lab/pebblelab-v1`

Objective: reconcile the local Phase 4.1 implementation with the project
journal before publishing the branch to GitHub.

Files checked:

- `Sources/PebbleLab/LabPhysical.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DECISIONS.md`
- `docs/pebblelab/JOURNAL.md`
- `docs/pebblelab/PHASE_4_PHYSICAL_AGENT_SPIKE.md`
- `docs/pebblelab/ROADMAP.md`

Conclusion:

- Phase 4.1 was already present locally.
- The implementation remains non-invasive and PebbleLab-only.
- No PebbleCore entity, registry, renderer, audio, resource pack, packaging, or
  golden file is modified.
- The recommended next phase is Phase 4.2A: synchronize the physical
  placeholder with abstract movement before considering a real PebbleCore
  entity.

Commands of validation:

- `swift build`
- `swift run -c release PebbleLab -- --scenario agent_smoke --seed 42 --ticks 3 --out runs/check_agent_smoke`
- `swift run -c release PebbleLab -- --scenario agents_basic --seed 42 --agents 10 --ticks 20 --out runs/check_agents_basic`
- `swift run -c release PebbleLab -- --scenario seek_safety_smoke --seed 42 --ticks 10 --out runs/check_seek_safety`
- `swift run -c release PebbleLab -- --scenario long_run_smoke --seed 42 --agents 10 --ticks 1000 --event-rate 10 --out runs/check_long_run`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression`
- `swift run -c release PebbleLab -- --scenario physical_placeholder_smoke --seed 42 --ticks 3 --out runs/check_physical_placeholder`
- `swift run -c release pebsmoke`

Result: validation passed, then the Phase 4.1 changes were committed and
pushed to `origin/lab/pebblelab-v1`.

Next steps:

- Phase 4.2A: `physical placeholder synchronization with abstract movement`.

## 2026-06-18 - Phase 4.2A Physical Placeholder Synchronization

Branch: `lab/pebblelab-v1`

Objective: synchronize the PebbleLab-only physical placeholder with abstract
`LabAgent` movement while keeping the bridge non-invasive.

Files modified:

- `Sources/PebbleLab/LabPhysical.swift`
- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DECISIONS.md`
- `docs/pebblelab/JOURNAL.md`
- `docs/pebblelab/PHASE_4_PHYSICAL_SYNC.md`
- `docs/pebblelab/ROADMAP.md`

Behavior added:

- `physical_sync_smoke` creates one abstract `LabAgent` and one PebbleLab-only
  physical placeholder.
- The agent uses deterministic abstract `explore` movement.
- `LabAgentPhysicalBridge` syncs placeholder position after abstract movement.
- `events.ndjson` includes `lab_physical_agent_synced` only when the
  placeholder actually catches up to a changed abstract position.
- `metrics.json` includes physical sync counts, sync distance, and final
  abstract/physical divergence metrics.
- `physical_snapshot.json` records abstract position, physical position, final
  divergence, and placeholder tick count.

Commands of validation:

- `swift build`
- `swift run -c release PebbleLab -- --scenario agent_smoke --seed 42 --ticks 3 --out runs/check_agent_smoke_after_physical_sync`
- `swift run -c release PebbleLab -- --scenario agents_basic --seed 42 --agents 10 --ticks 20 --out runs/check_agents_basic_after_physical_sync`
- `swift run -c release PebbleLab -- --scenario seek_safety_smoke --seed 42 --ticks 10 --out runs/check_seek_safety_after_physical_sync`
- `swift run -c release PebbleLab -- --scenario long_run_smoke --seed 42 --agents 10 --ticks 1000 --event-rate 10 --out runs/check_long_run_after_physical_sync`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_physical_sync`
- `swift run -c release PebbleLab -- --scenario physical_placeholder_smoke --seed 42 --ticks 3 --out runs/check_physical_placeholder_after_sync`
- `swift run -c release PebbleLab -- --scenario physical_sync_smoke --seed 42 --ticks 5 --out runs/check_physical_sync`
- `swift run -c release pebsmoke`

Result: validation passed. `physical_sync_smoke` ends with zero final
abstract/physical divergence, Phase 3 scenarios remain stable, and no
PebbleCore, registry, renderer, audio, resource pack, packaging, or golden file
was modified.

Next steps:

- Phase 4.2B: real PebbleCore entity feasibility patch, registry-safe and
  planned separately.

## 2026-06-18 - Phase 4.2B Real Entity Feasibility Planning

Branch: `lab/pebblelab-v1`

Objective: plan the safest path from PebbleLab-only physical placeholders to a
future real PebbleCore entity without implementing the entity or touching
registries.

Files inspected:

- `AGENTS.md`
- `Package.swift`
- `Sources/PebbleLab/LabAgent.swift`
- `Sources/PebbleLab/LabPhysical.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/main.swift`
- `Sources/PebbleCore/Entity/Entity.swift`
- `Sources/PebbleCore/Entity/Living.swift`
- `Sources/PebbleCore/Entity/AI.swift`
- `Sources/PebbleCore/Entity/EntityRegistry.swift`
- `Sources/PebbleCore/Entity/SpawnHooks.swift`
- `Sources/PebbleCore/Entity/Player.swift`
- `Sources/PebbleCore/Entity/Villagers.swift`
- `Sources/PebbleCore/Entity/Animals.swift`
- `Sources/PebbleCore/World/GameWorld.swift`
- `Sources/PebbleCore/Game/GameCore.swift`
- `Sources/Pebble/WorldRenderer.swift`
- `Sources/Pebble/CommandsM.swift`
- `Sources/pebsmoke/main.swift`
- `docs/pebblelab/PHASE_4_PHYSICAL_AGENT_SPIKE.md`
- `docs/pebblelab/PHASE_4_PHYSICAL_SYNC.md`
- `docs/pebblelab/JOURNAL.md`
- `docs/pebblelab/DECISIONS.md`
- `docs/pebblelab/ROADMAP.md`
- `docs/pebblelab/CHANGELOG.md`

Files modified:

- `docs/pebblelab/PHASE_4_REAL_ENTITY_FEASIBILITY.md`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DECISIONS.md`
- `docs/pebblelab/JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`

Conclusions:

- `LabAgent` remains the abstract brain, and the Phase 4.2A placeholder bridge
  is PebbleLab-only.
- `World` stores entities but does not tick them by itself; `GameCore` owns the
  normal entity tick loop.
- `EntityRegistry` order, entity type count, and spawnable mob list are
  covered by `pebsmoke` goldens.
- Existing mobs are not good lab shells because `Mob` brings goals,
  navigation, despawn, sounds, interactions, and vanilla behavior.
- Rendering is separate from simulation: a real entity in `World.entities` is
  not visible unless `WorldRenderer` can resolve a model or debug path.
- The recommended next phase is an unregistered PebbleCore `Entity` probe
  constructed directly by PebbleLab, not a registry patch.

Commands of validation:

- `swift build`
- `swift run -c release PebbleLab -- --scenario physical_sync_smoke --seed 42 --ticks 5 --out runs/check_physical_sync_after_feasibility_docs`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_feasibility_docs`
- `swift run -c release pebsmoke`

Result: validation passed. This phase is documentation-only; no PebbleCore,
registry, renderer, audio, resource pack, packaging, or golden file was
modified.

Next steps:

- Phase 4.3A: unregistered `LabCoreAgentEntity` probe, constructed directly by
  PebbleLab and validated headlessly before any registry work.

## 2026-06-18 - Phase 4.3A Unregistered LabCoreAgentEntity Probe

Branch: `lab/pebblelab-v1`

Objective: create the first true PebbleCore entity presence for a PebbleLab
agent while avoiding `EntityRegistry`, save/load, renderer, and mob behavior.

Files inspected:

- `AGENTS.md`
- `docs/pebblelab/PHASE_4_REAL_ENTITY_FEASIBILITY.md`
- `Sources/PebbleCore/Entity/Entity.swift`
- `Sources/PebbleCore/Entity/EntityRegistry.swift`
- `Sources/PebbleCore/World/GameWorld.swift`
- `Sources/PebbleCore/Game/GameCore.swift`
- `Sources/PebbleLab/LabPhysical.swift`
- `Sources/PebbleLab/LabAgent.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/main.swift`
- `Sources/pebsmoke/main.swift`

Files modified:

- `Sources/PebbleCore/Entity/LabCoreAgentEntity.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabPhysical.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DECISIONS.md`
- `docs/pebblelab/JOURNAL.md`
- `docs/pebblelab/PHASE_4_CORE_ENTITY_PROBE.md`
- `docs/pebblelab/ROADMAP.md`

Behavior added:

- `LabCoreAgentEntity` is a minimal unregistered PebbleCore `Entity` subclass.
- `core_entity_smoke` creates one abstract `LabAgent`, one PebbleLab physical
  placeholder, and one direct core entity probe.
- The probe is added to `World.entities` with `world.addEntity`.
- PebbleLab ticks the probe explicitly because direct `World.tick()` does not
  tick entities.
- PebbleLab synchronizes the probe from `LabAgent.position` after abstract
  movement.
- `events.ndjson` includes `lab_core_entity_spawned` and
  `lab_core_entity_synced`.
- `metrics.json` includes core entity counts, sync counts, sync distance,
  final abstract/core divergence, and `worldEntitiesCount`.
- `core_entity_snapshot.json` records the final abstract/core position pair.

Commands of validation:

- `swift build`
- `swift run -c release PebbleLab -- --scenario core_entity_smoke --seed 42 --ticks 5 --out runs/check_core_entity_smoke`
- `swift run -c release PebbleLab -- --scenario physical_sync_smoke --seed 42 --ticks 5 --out runs/check_physical_sync_after_core_entity`
- `swift run -c release PebbleLab -- --scenario physical_placeholder_smoke --seed 42 --ticks 3 --out runs/check_physical_placeholder_after_core_entity`
- `swift run -c release PebbleLab -- --scenario agent_smoke --seed 42 --ticks 3 --out runs/check_agent_smoke_after_core_entity`
- `swift run -c release PebbleLab -- --scenario agents_basic --seed 42 --agents 10 --ticks 20 --out runs/check_agents_basic_after_core_entity`
- `swift run -c release PebbleLab -- --scenario seek_safety_smoke --seed 42 --ticks 10 --out runs/check_seek_safety_after_core_entity`
- `swift run -c release PebbleLab -- --scenario long_run_smoke --seed 42 --agents 10 --ticks 1000 --event-rate 10 --out runs/check_long_run_after_core_entity`
- `swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_core_entity`
- `swift run -c release pebsmoke`

Result: validation passed. `core_entity_smoke` ends with
`abstractCoreEntityDivergence = 0`, `maxAbstractCoreEntityDivergence = 0`, and
`worldEntitiesCount = 1`. Existing Phase 3 and Phase 4 placeholder scenarios
remain stable, and no registry, renderer, audio, resource pack, packaging, or
golden file was modified.

Next steps:

- Phase 4.3B: core entity bridge hardening or registry-safe visibility
  planning, kept separate from the unregistered probe.
