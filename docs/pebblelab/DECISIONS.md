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

## 2026-06-17 - Abstract Position Updates

Decision: PebbleLab agents can update their abstract position from selected
actions.

This movement intentionally does not use PebbleCore physical entities,
pathfinding, collision, gravity, block checks, or world interaction. For v0,
movement is limited to X/Z steps with `dy = 0` and is used to validate the
observation/action/logging loop.

Reason: simulations need visible agent trajectories before introducing
physical bodies or real navigation.

## 2026-06-17 - Abstract seekSafety Movement Toward Home

Decision: PebbleLab `seekSafety` behavior moves agents abstractly toward
`homePosition`.

This remains separate from physical pathfinding, collision, world navigation,
PebbleCore entity movement, and world mutation. The v0 behavior takes one
deterministic X/Z step toward home and records distance reduction metrics.

Reason: agents need an inspectable safety loop before introducing richer
navigation, homes, settlements, or physical bodies.

## 2026-06-17 - Internal Metrics Separate From Event Volume

Decision: PebbleLab separates internal simulation metrics from emitted NDJSON
event volume.

`--event-rate` throttles frequent events such as `world_tick` and
`agent_observed_nearby_agent`, but it does not change agent state, world ticks,
goal selection, movement, or aggregate metrics. Critical lifecycle events stay
unthrottled.

Reason: longer runs need bounded log sizes without losing deterministic
simulation state or summary metrics.

## 2026-06-17 - Compact Regression Report Stays PebbleLab-Local

Decision: `regression_smoke` writes a compact PebbleLab regression report for
the current run instead of spawning multiple subprocesses or replacing
`pebsmoke`.

The report summarizes success criteria and key metrics for a deterministic
headless scenario. It is intentionally separate from PebbleCore golden tests
and does not modify registries, goldens, or game systems.

Reason: PebbleLab needs a quick health signal that is easier to inspect than
several raw JSON files, while `pebsmoke` remains the authoritative engine
regression suite.

## 2026-06-17 - Physical Agent Bridge Before Mob Changes

Decision: Phase 4 keeps `LabAgent` as the abstract cognitive state and plans
physical representation through an isolated bridge before modifying existing
mobs or adding full pathfinding.

The recommended path is to avoid changing existing mob behavior, avoid reusing
mob AI as the lab brain, and introduce a future physical placeholder with clear
id mapping, spawn/tick/snapshot logs, and drift metrics. A dedicated
experimental entity can be considered later, but registry changes must be
reviewed separately and must not reorder existing registrations.

Reason: PebbleCore entities bring registry, save/load, ticking, pathfinding,
rendering, and golden-test risks. A bridge-first plan preserves deterministic
PebbleLab scenarios while creating a controlled path toward physical agents.

## 2026-06-17 - Non-Invasive Physical Placeholder

Decision: Phase 4.1 introduces a PebbleLab-only physical placeholder for
`LabAgent` instead of registering a new PebbleCore mob.

The placeholder records a deterministic `agentId` to `physicalId` link, a
physical position, kind, spawn tick, tick count, metrics, NDJSON events, and a
dedicated `physical_snapshot.json`. It does not enter `World.entities`, does
not modify PebbleCore, and does not use pathfinding, collision, rendering,
save/load, item stacks, combat, or construction.

Reason: a non-invasive placeholder proves the bridge shape and output contract
without touching entity registries or golden-sensitive mob behavior. The next
step is placeholder synchronization with abstract movement; a real PebbleCore
entity remains a later registry-safe feasibility patch.
