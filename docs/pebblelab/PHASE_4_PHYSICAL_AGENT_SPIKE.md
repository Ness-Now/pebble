# Phase 4 Physical Agent Spike

Date: 2026-06-17

Branch: `lab/pebblelab-v1`

Purpose: plan the first safe path from abstract PebbleLab agents toward a
future physical PebbleCore representation without implementing that entity yet.

## 1. Current PebbleLab State

PebbleLab is a SwiftPM executable target that depends on `PebbleCore` only. It
creates headless `World` instances, runs deterministic scenarios, and writes
local run outputs under ignored `runs/` directories.

Current scenarios include:

- `empty`
- `chunk_smoke`
- `agent_smoke`
- `agents_basic`
- `seek_safety_smoke`
- `long_run_smoke`
- `regression_smoke`

Current abstract agents are PebbleLab-local structs, not PebbleCore entities.
They have stable ids, abstract position, needs, health, fear, home position,
inventory, local terrain observation, nearby-agent perception, current goal,
abstract action, internal action effects, abstract X/Z movement, memory,
snapshots, metrics, and NDJSON events.

The important boundary is that `LabAgent` does not mutate blocks, does not use
PebbleCore pathfinding, does not register entity types, and does not appear in
the macOS renderer. PebbleLab currently proves behavior through
`agent_snapshot.json`, `world_snapshot.json`, `metrics.json`,
`events.ndjson`, and `regression_report.json`.

## 2. Relevant PebbleCore Entity Architecture

Inspected files:

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

### Entity

`Entity` is the base class for physical world objects. It stores identity,
type, position, velocity, rotation, size, collision flags, age, fire/fluid
state, persistence, arbitrary `EntityData`, and a `world` reference. It exposes
`setPos`, `bb`, `eyeY`, `move`, `tick`, `save`, and `load`.

`Entity.move` performs swept AABB collision, step-up behavior, ground detection,
velocity reset on collision, and fall-distance handling. This is already much
more than PebbleLab abstract movement and should not be duplicated in
PebbleLab.

### LivingEntity

`LivingEntity` extends `Entity` with health, effects, armor, held items,
movement intent, jumping/sprinting/sneaking state, limb animation, attacker
tracking, deterministic `RandomX`, death handling, drops, effects, healing,
damage, and `baseLivingTick`.

It is the right family for a future embodied humanoid, but it brings combat,
damage, item, death, sound, and physics expectations that are not needed for
the first placeholder.

### Mob

`Mob` extends `LivingEntity` with `GoalSelector`, `Navigation`, targeting,
breeding state, category, attack damage, follow range, sunlight burning,
leash/owner/sitting state, and `mobTick`.

`mobTick` runs `baseLivingTick`, despawn rules, sunlight burning, baby/love
timers, target goals, normal goals, navigation, look control, leash physics,
travel, and ambient sounds. Existing mobs are therefore behavior-rich and not a
neutral shell for a lab agent.

### Goal Selectors

`GoalSelector` stores goals in stable priority order and maintains an
insertion-ordered active list. Standard goals include floating, panic,
strolling, looking at players, melee attack, target selection, avoiding
entities, tempting, breeding, following parents/owners, and many more.

This system is useful later, but Phase 4.1 should not wire PebbleLab goals into
the full mob goal system yet. The first bridge should keep `LabAgent` as the
source of cognitive state and only synchronize minimal physical state.

### Pathfinding

`AI.swift` contains a deterministic grid A* pathfinder:

- `findPath(world:sx:sy:sz:tx:ty:tz:range:avoidWater:maxNodes:)`
- `walkable`
- `Navigation`

`Navigation.tick` drives mob movement toward path nodes using mob speed and
`moveForward`. This depends on world walkability, collision, chunks, fluids,
and mob travel. It should stay out of Phase 4.1.

### Spawn And Registry

`EntityRegistry.swift` owns entity registration:

- `registerAllEntities()`
- `createEntity(_ type: String, _ world: World) -> Entity?`
- `entityTypes() -> [String]`
- `spawnMob(_ world: World, _ type: String, _ x: Double, _ y: Double, _ z: Double, _ data: SpawnOpts?)`
- `loadEntity(_ world: World, _ d: [String: Any]) -> Entity?`

Registration order is explicitly baseline-sensitive. Adding a new registered
entity later must be done deliberately, preferably appended, and validated
against `pebsmoke`. The planning phase must not modify registries.

`SpawnHooks.swift` exposes `spawnMobFn`, which existing systems use for
late-bound mob spawning. This should not be repurposed for LabAgent v0.

### World Entity Storage

`World` owns:

- `entities: [EntityRef]`
- `entityById: [Int: EntityRef]`
- `addEntity`
- `removeEntity`
- `getEntitiesInBox`
- `getEntitiesNear`

`World.tick()` does not tick entities directly. It advances world time,
weather, scheduled block ticks, random ticks, block entities, and lighting.

### GameCore Tick And Streaming

`GameCore` is the main game simulation orchestrator. Its per-tick path calls
`w.tick()`, then ticks entities in `world.entities` within simulation distance,
skipping dead entities and removing them afterward. It also runs entity
triggers, fangs, and natural spawning.

`GameCore.adoptChunk` resolves saved or worldgen entity specs into live
entities. `unloadChunk` persists non-player entities standing in an unloaded
chunk and removes them from the live world.

This means a future physical lab entity must define where it lives:

- in full `GameCore` streaming/tick/save behavior; or
- in a PebbleLab-local headless entity tick loop that explicitly mirrors only
  the tiny subset needed for the spike.

## 3. Integration Options

### Option A - Reuse An Existing Mob As Experimental Support

Description: spawn an existing entity type such as `villager`, `player`, or a
passive mob and associate it with a `LabAgent`.

Advantages:

- Fastest way to get a physical object into `World.entities`.
- Uses existing registry, save/load, tick, collision, and renderer behavior.
- Avoids adding a new entity type in the first experiment.

Risks:

- Existing mobs bring unwanted goals, sounds, drops, despawn rules, trading,
  breeding, panic, targeting, or player-specific systems.
- Reusing `Player` pulls in hunger, inventory, pickup, sleeping, game mode,
  input, and host-facing behavior.
- Behavior can affect goldens and make lab tests depend on unrelated mob
  implementation details.
- It blurs the meaning of `LabAgent` versus vanilla mob.

Files likely impacted:

- `Sources/PebbleLab/*`
- possibly `Sources/PebbleCore/Entity/EntityRegistry.swift` only if a new
  alias or spawn helper is added later
- validation in `Sources/pebsmoke/main.swift` if a dedicated smoke is added

Complexity: low initially, high hidden coupling.

Recommendation: not preferred. Useful only as a temporary manual visual probe,
not as the long-term PebbleLab physical-agent base.

### Option B - Create A New Experimental `LabHuman` Entity

Description: add a new PebbleCore entity type dedicated to PebbleLab physical
agents.

Advantages:

- Clear ownership and semantics.
- Avoids mutating existing mobs.
- Can start inert and deterministic.
- Can keep AI/pathfinding disabled until explicitly added.
- Provides a real future hook for renderer, save/load, snapshots, and bridging.

Risks:

- Requires registry work and therefore careful ordering.
- May affect `entityTypes()` baselines or golden tests.
- Needs save/load decisions.
- Needs renderer/model behavior eventually if visible in the app.
- If subclassing `Mob`, default mob systems may be too much; if subclassing
  `LivingEntity` or `Entity`, more basics must be handled explicitly.

Files likely impacted later:

- `Sources/PebbleCore/Entity/LabHuman.swift` or equivalent new file
- `Sources/PebbleCore/Entity/EntityRegistry.swift`
- possible renderer model mapping in the app target later
- `Sources/PebbleLab/*` bridge/snapshot code
- `Sources/pebsmoke/main.swift` if a focused engine smoke is added

Complexity: medium, but clean if scoped narrowly.

Recommendation: good long-term entity path, but not the first code change
unless Phase 4.1 explicitly accepts registry and test impact.

### Option C - Keep `LabAgent` Abstract And Add A Physical Proxy Later

Description: keep PebbleLab agents as the source of cognitive state and plan a
bridge that can optionally synchronize a physical representation.

Advantages:

- Safest continuation from Phase 3.
- Avoids registry and rendering changes for planning.
- Preserves deterministic abstract scenarios and regression report.
- Makes the bridge boundary explicit before physical behavior exists.
- Lets the first physical spike measure drift between abstract and physical
  state instead of replacing the abstract agent immediately.

Risks:

- Physical visibility is delayed.
- A bridge layer can become a parallel simulation if not kept small.
- Requires clear ownership rules to avoid divergent positions/actions.

Files likely impacted later:

- new `Sources/PebbleLab/LabAgentPhysicalBridge.swift` or equivalent
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/LabOutput.swift`
- a later isolated PebbleCore entity file if Option B is adopted

Complexity: low for planning, medium for the first physical bridge.

Recommendation: preferred Phase 4 strategy.

## 4. Recommended Path

Use Option C as the Phase 4 architecture path:

- keep `LabAgent` as the abstract cognitive state;
- do not modify existing mobs;
- do not reuse existing mob behavior as the long-term lab body;
- introduce physical representation incrementally through an isolated bridge;
- only add a new PebbleCore experimental entity when the bridge contract is
  clear;
- start with spawn, tick presence, id mapping, and snapshot/log output;
- postpone full pathfinding, collisions-as-decisions, inventory integration,
  combat, construction, and social behavior.

Recommended future boundary:

- `LabAgent`: needs, memory, goals, abstract actions, social perception,
  inventory, snapshots.
- physical entity: position, body size, world presence, save/load identity,
  optional renderer visibility later.
- `LabAgentPhysicalBridge`: maps `LabAgent.id` to `Entity.id`, syncs initial
  spawn, records physical position, detects abstract/physical drift, writes
  metrics/events.

The bridge should not call existing mob goals in Phase 4.1. It should not
install pathfinding. It should not copy `GameCore` streaming logic.

## 5. Minimal Phase 4.1 Scope

Recommended next codable phase:

`Phase 4.1 - physical agent placeholder spawn`

Minimal scope:

- add one opt-in PebbleLab scenario, for example `physical_agent_smoke`;
- keep all Phase 3 scenarios unchanged;
- create exactly one physical placeholder associated with `agent_0`;
- use public PebbleCore APIs only where possible;
- no custom pathfinding;
- no custom collision;
- no construction;
- no combat;
- no real inventory integration;
- no social relationship system;
- no renderer change unless a pre-existing entity can be visualized safely;
- log `lab_physical_agent_spawned`;
- write metrics such as `physicalAgentsSpawned`, `physicalAgentEntityIds`,
  `physicalAgentPresent`, and optional position drift;
- keep `LabAgent` as the source of goal/action/memory state;
- validate `regression_smoke` and `pebsmoke`.

Two acceptable implementation tracks for Phase 4.1:

1. Bridge-first placeholder: add PebbleLab bridge data and a physical-presence
   smoke using an existing inert-enough entity only if the risk is explicitly
   accepted.
2. New-entity placeholder: add an isolated inert PebbleCore entity appended to
   the registry, with no goals and minimal save/load, accepting that this is a
   registry-touching phase requiring extra review.

The safer default is bridge-first planning followed by a deliberately reviewed
new-entity patch.

## 6. Risks

Registry order:

- `registerAllEntities()` feeds `entityTypes()` and is baseline-sensitive.
- Adding an entity must not reorder existing registrations.

Save/load:

- `Entity.save/load` and `loadEntity` depend on the registered `type`.
- Chunk unload persists non-player entities standing in a chunk.

Determinism:

- Entity ids are global and tick order follows insertion order.
- Some existing player/mob sounds use `Double.random`, so reusing those paths
  can introduce unwanted nondeterminism in lab validation.

Golden tests:

- `pebsmoke` covers entity zoo, combat, physics, spawning, and persistence
  behavior. Physical-agent changes can trip unrelated baselines.

Rendering:

- A new entity type is not automatically renderable by the app target.
- Renderer changes are out of scope for early Phase 4 work.

Chunk loading:

- Physical entities interact with loaded chunks, surface data, collision, and
  unload persistence.
- PebbleLab currently generates a small controlled chunk area.

Position divergence:

- Abstract `LabAgent.position` can diverge from physical `Entity.x/y/z`.
- The bridge must define source-of-truth rules and drift metrics.

Mob behavior coupling:

- Existing mobs bring goals, navigation, sounds, drops, despawn, and other
  gameplay systems.
- Reusing them can hide lab behavior behind vanilla behavior.

## 7. Validation Plan

For Phase 4.1, validation should include:

```sh
cd ~/Dev/pebble-lab && git checkout lab/pebblelab-v1
cd ~/Dev/pebble-lab && swift build
cd ~/Dev/pebble-lab && swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/regression_after_physical_placeholder
cd ~/Dev/pebble-lab && swift run -c release PebbleLab -- --scenario physical_agent_smoke --seed 42 --ticks 3 --out runs/physical_agent_smoke_v0
cd ~/Dev/pebble-lab && swift run -c release pebsmoke
cd ~/Dev/pebble-lab && git status
```

Expected Phase 4.1 checks:

- existing Phase 3 scenarios still pass through `regression_smoke`;
- one physical placeholder is spawned or represented;
- output contains `lab_physical_agent_spawned`;
- metrics include `physicalAgentsSpawned = 1`;
- snapshots identify both the abstract agent id and physical entity id if an
  entity exists;
- no existing mob behavior is modified;
- no renderer, audio, packaging, resource pack, or golden update is required.
