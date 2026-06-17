# PebbleLab Decisions

## 2026-06-17 - Abstract Nearby-Agent Perception

Decision: social perception v0 remains an abstract PebbleLab-only observation.

PebbleLab agents can detect nearby abstract agents by relative position and
Manhattan distance, but this does not create communication, trust, friendship,
reputation, groups, physical entities, or any world mutation.

Reason: the project needs a deterministic perception signal before adding
agent-agent interaction or social state.

## 2026-06-17 - Deterministic Current Goal Before Action

Decision: PebbleLab agents choose a stable `currentGoal` before selecting an
abstract action.

The goal system remains abstract and deterministic. It does not introduce a
planner, LLM, physical entity, pathfinding, communication, or social
relationship system.

Reason: goals create a small explicit layer between observations/needs and
actions, making future behavior easier to inspect before adding more complex
planning.

## 2026-06-17 - Abstract Vital And Home State

Decision: PebbleLab agents track `health`, `fear`, and `homePosition` as
abstract agent state.

These fields do not imply physical movement, pathfinding, inventory,
world mutation, or social relationships. `homePosition` is assigned from the
spawn position for now, and fear/health only influence the deterministic goal
priority layer.

Reason: future survival and settlement behavior needs stable state anchors
before adding inventory, physical agents, homes, groups, or social systems.

## 2026-06-17 - Abstract String-Keyed Inventory

Decision: PebbleLab agents use an abstract `LabInventory` keyed by string item
identifiers.

This intentionally avoids PebbleCore `ItemStack`, registries, physical pickup,
crafting, storage, exchange, theft, sharing, or economy mechanics until
physical agents and world interactions are introduced.

Reason: future food, gathering, construction, and social behavior needs a small
deterministic inventory surface before coupling agents to the full item system.

## 2026-06-17 - Fixed Smoke Scenario And Configurable Agent Scenario

Decision: PebbleLab keeps `agent_smoke` as a fixed two-agent validation
scenario and adds `agents_basic` as the configurable multi-agent simulation
scenario.

`agents_basic` uses deterministic grid placement from the run seed and agent
index. It does not introduce movement, pathfinding, physical entities,
resource sharing, economy, or world mutation.

Reason: the project needs a stable tiny smoke scenario and a separate scalable
scenario for longer abstract simulations.
