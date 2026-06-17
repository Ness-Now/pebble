# Phase 4 Real Entity Feasibility

Date: 2026-06-18

Branch: `lab/pebblelab-v1`

Purpose: plan the first safe move from PebbleLab-only physical placeholders
toward a future real PebbleCore entity without implementing that entity in this
phase.

## 1. Current State

PebbleLab currently uses two separate layers:

- `LabAgent` is the abstract cognitive state. It owns id, abstract position,
  needs, health, fear, home position, inventory, nearby-agent perception,
  current goal, abstract action, internal effects, movement, memory, metrics,
  and snapshots.
- `LabPhysicalAgentHandle` is a PebbleLab-only placeholder. It maps a
  `LabAgent.id` to a stable `physicalId`, stores a physical placeholder
  position, and has a tick count.
- `LabAgentPhysicalBridge` creates placeholders and synchronizes placeholder
  position from `LabAgent.position` after abstract movement.
- `physical_sync_smoke` proves that final abstract/physical divergence can be
  reduced to zero.

What does not exist yet:

- no `LabHuman`;
- no real PebbleCore lab entity;
- no placeholder in `World.entities`;
- no 3D visibility in Pebble;
- no entity registry modification;
- no save/load contract for a lab entity;
- no custom pathfinding, collision, combat, construction, or real inventory.

## 2. PebbleCore Entity Architecture

### Base Entity

`Sources/PebbleCore/Entity/Entity.swift` defines `open class Entity:
EntityRef`. It stores:

- integer `id`, allocated from a global deterministic sequence;
- `type`;
- position, previous position, velocity, yaw, pitch;
- width, height, bounding box, step height, ground/collision state;
- fluid, fire, freezing, gravity, riding, persistence, and arbitrary
  `EntityData`;
- an unowned `World` reference.

Important methods:

- `setPos`;
- `bb`;
- `baseTick`;
- `move`, which performs swept AABB collision and step-up behavior;
- `tick`, open and empty at the base level;
- `hurt`, `interact`;
- `save` and `load`.

Even the base class is not just a marker. It has physics state, world
references, fluid/fire/void handling, persistence hooks, and collision.

### LivingEntity

`Sources/PebbleCore/Entity/Living.swift` defines `LivingEntity: Entity`.
It adds:

- health and max health;
- effects;
- armor and held items;
- attack, death, knockback, drops, XP;
- movement intent;
- water/lava/ground travel physics;
- ambient/hurt/death sounds;
- entity pushing.

`baseLivingTick()` calls `baseTick()`, effects, drowning, body/head yaw, and
entity push logic. Subclassing `LivingEntity` immediately brings combat,
damage, drops, sounds, and physics expectations.

### Mob

`Sources/PebbleCore/Entity/AI.swift` defines `Mob: LivingEntity`.
It adds:

- `GoalSelector` for normal goals and target goals;
- `Navigation`;
- target tracking;
- breeding, leashing, sitting, category, attack damage, despawn rules;
- `mobTick()`.

`mobTick()` runs living tick logic, despawn checks, sunlight burning, baby/love
timers, target goals, normal goals, navigation, look control, leash physics,
travel, and ambient sounds. Reusing `Mob` is therefore behavior-rich, not a
neutral physical shell.

### Goals And Pathfinding

`AI.swift` also contains deterministic grid A*:

- `findPath`;
- `walkable`;
- `Navigation`;
- standard goals such as float, panic, stroll, look at player, target, breed,
  attack, avoid, tempt, follow, and others.

The pathfinder depends on world blocks, fluids, collision assumptions, and mob
movement. It should stay out of the first real-entity feasibility patch.

### World Entity Storage

`Sources/PebbleCore/World/GameWorld.swift` stores live entities in:

- `World.entities: [EntityRef]`;
- `World.entityById: [Int: EntityRef]`.

The public entity operations are:

- `addEntity`;
- `removeEntity`;
- `getEntitiesInBox`;
- `getEntitiesNear`.

`World.tick()` advances world time, weather, block ticks, random ticks, block
entities, and lighting. It does not tick entities directly.

### GameCore Entity Tick

`Sources/PebbleCore/Game/GameCore.swift` is the game orchestrator. In its tick
path it:

1. calls `w.tick()`;
2. iterates `w.entities`;
3. skips the player and dead entities;
4. applies simulation-distance filtering;
5. calls `ent.tick()`;
6. removes dead entities;
7. runs entity triggers, fangs, and natural spawning.

PebbleLab currently uses `World` directly, not `GameCore`, so a future
PebbleLab entity scenario would need either a tiny explicit entity tick loop or
a deliberate GameCore-based scenario.

### Spawning And Registries

`Sources/PebbleCore/Entity/EntityRegistry.swift` owns:

- `registerAllEntities`;
- `createEntity`;
- `entityTypes`;
- `spawnMob`;
- `loadEntity`;
- `naturalSpawnTick`;
- `spawnableMobs`.

Registration order feeds `entityTypes()`, `spawnableMobs()`, and `pebsmoke`
goldens. The registry is guarded by `entitiesRegistered`, so registration is
global and effectively append-only after startup.

`spawnMob` creates a registered entity, applies `SpawnOpts`, and calls
`world.addEntity`.

`loadEntity` requires a registered `type`. An unregistered entity can exist if
it is constructed directly and added to `World`, but it cannot be recreated by
`loadEntity`.

`Sources/PebbleCore/Entity/SpawnHooks.swift` exposes the late-bound
`spawnMobFn`, which existing mobs use for child mobs, conversions, and similar
events.

### Save And Load

`GameCore.chunkRecord` persists non-player, non-dead entities standing in a
chunk by calling `ent.save()`. Later, `adoptChunk` reloads saved entities
through `loadEntity`.

This matters for lab entities:

- a registered entity can round-trip through save/load if its type is in the
  registry and its `save`/`load` are correct;
- an unregistered entity should not be introduced into normal saved game flows
  until a persistence decision exists;
- PebbleLab direct `World` scenarios do not currently use GameCore autosave.

### Rendering

`Sources/Pebble/WorldRenderer.swift` draws entities by iterating
`game.world.entities`.

`modelNameFor(_:)` returns a model only if:

- the entity type has a model;
- the type is a known special case such as arrow, crystal, boat, or minecart;
- variant rules apply, such as sheep color or villager profession.

A future lab entity in `World.entities` will be simulated but invisible unless
the app has an entity model or a debug rendering path. That rendering work is
outside the first real-entity feasibility patch.

### Commands And Debug Tools

`Sources/Pebble/CommandsM.swift` implements `/summon` via `spawnableMobs()` and
`spawnMob`. A registered lab entity would appear in command behavior only if
it is included in `spawnableMobs()`. An unregistered lab entity would not be
summonable, which is safer for a first probe.

`/kill @e` removes all non-player entities. A real lab entity in
`World.entities` would be affected.

### Entity Tests

`Sources/pebsmoke/main.swift` validates:

- entity type count;
- entity registration order;
- spawnable mob list;
- zoo mob behavior over 200 ticks;
- combat;
- player physics;
- villager trades;
- A* paths;
- natural spawn count and hash.

Changing entity registration or vanilla mob behavior is golden-sensitive.
`PEBBLE_REGOLD` must not be used for PebbleLab work unless explicitly
requested.

## 3. Risk Map

| Risk | Severity | Probability | Mitigation | Recommended Decision |
| --- | --- | --- | --- | --- |
| Entity registry order changes | High | High if registering | Do not register in the first real-entity probe; if later needed, append only and review `pebsmoke` changes. | Avoid registry in Phase 4.3A. |
| Save compatibility | High | Medium | Keep first entity probe out of GameCore save/load; do not claim persistence. | No save/load in first probe. |
| Golden test drift | High | High if registry/mobs change | Run `pebsmoke`; avoid changing existing mobs, natural spawn, pathfinding, or registration order. | Touch no vanilla behavior. |
| 3D rendering invisibility | Medium | High | Document that simulation and visibility are separate; add rendering only in a later app-target phase. | Do not require visibility in first probe. |
| Tick order mismatch | Medium | Medium | Use an explicit PebbleLab tick order and log it; do not rely on GameCore tick until intentionally introduced. | PebbleLab owns first probe tick loop. |
| Determinism | High | Medium | Avoid global `gameRng`, nondeterministic constructors, and unordered collections in lab code. | Keep deterministic explicit initialization. |
| Collision and physics side effects | Medium | Medium | Use no custom collision; either do not move the entity or use `setPos` from the bridge. | No collision contract in first probe. |
| Pathfinding coupling | High | Medium | Do not subclass `Mob`; do not call `Navigation` or `findPath`. | No pathfinding in first probe. |
| Entity serialization | High | Medium | Do not register/load the type; keep scenario headless and non-saved. | Treat as transient. |
| Chunk loading | Medium | Medium | Generate/adopt chunks explicitly in PebbleLab scenarios before spawning. | Use existing chunk-smoke world setup. |
| Coupling with vanilla mobs | High | Medium | Do not wrap villager/player/animal mobs for lab cognition. | Avoid mob reuse. |
| Performance with many agents | Medium | Low for first probe | Start with one entity; measure before scaling. | One physical entity only. |
| Abstract/real divergence | High | Medium | Reuse the existing bridge divergence metrics and snapshots. | Keep `LabAgent` authoritative in v0. |

## 4. Candidate Approaches

### Approach A - Continue With PebbleLab-Only Placeholder

Files touched:

- `Sources/PebbleLab/*`
- `docs/pebblelab/*`

Advantages:

- Lowest risk.
- No PebbleCore, registry, save/load, rendering, or golden impact.
- Already validated by `physical_placeholder_smoke` and `physical_sync_smoke`.
- Scales well for abstract simulation.

Disadvantages:

- Not visible in Pebble.
- Not present in `World.entities`.
- Cannot exercise real entity tick or entity queries.

Risks:

- The longer this remains the only representation, the larger the future gap
  between abstract and physical systems may become.

Difficulty: low.

Roadmap compatibility: good for Phase 3 and bridge work, insufficient for
physical-agent milestones.

Recommendation: keep as baseline and regression layer, but do not stop here.

### Approach B - Create A Minimal Unregistered PebbleCore Entity

Description: add a new public PebbleCore entity class, construct it directly
from PebbleLab, add it to `World.entities`, and keep it out of
`EntityRegistry`.

Files likely touched in the future phase:

- `Sources/PebbleCore/Entity/LabCoreAgentEntity.swift` or similar new file;
- `Sources/PebbleLab/LabPhysical.swift`;
- `Sources/PebbleLab/LabScenarios.swift`;
- `Sources/PebbleLab/main.swift`;
- `Sources/PebbleLab/LabOutput.swift`;
- `Sources/PebbleLab/LabEvents.swift`;
- docs.

Advantages:

- Creates a real `Entity` instance without registry changes.
- Can be added to `World.entities` in a headless PebbleLab scenario.
- Can prove entity id, position, tick count, and bridge sync against
  PebbleCore entity storage.
- Avoids entity type count/order goldens.
- Avoids `/summon` and vanilla spawn lists.

Disadvantages:

- Not loadable by `loadEntity`.
- Not summonable.
- Probably invisible without renderer/model work.
- Must stay out of GameCore save/load scenarios until persistence is designed.

Risks:

- If accidentally used in normal GameCore saved worlds, `save()` may emit a
  type that cannot be loaded.
- Subclassing even `Entity` brings physics and world hooks that should be
  treated carefully.

Difficulty: medium.

Roadmap compatibility: strong. It is the cleanest bridge from placeholder to
real entity without registry risk.

Recommendation: yes, as Phase 4.3A, with explicit transient/no-save limits.

### Approach C - Create A Registered PebbleCore Entity

Description: add a new entity type to `EntityRegistry`, make it creatable by
`spawnMob`/`loadEntity`, and eventually support save/load and perhaps
rendering.

Files likely touched:

- new PebbleCore entity file;
- `Sources/PebbleCore/Entity/EntityRegistry.swift`;
- possibly renderer model mapping/assets later;
- tests/goldens if entity count/order or spawnable list changes;
- docs.

Advantages:

- Full engine integration path.
- Can be saved and loaded once implemented.
- Could become summonable/debuggable.
- Natural place for later renderer support.

Disadvantages:

- Direct registry and golden risk.
- Requires clear ordering and test strategy.
- Save/load contract must be correct.
- If included in `spawnableMobs`, command behavior changes.

Risks:

- `pebsmoke` entity type count/order and spawnable hash failures.
- Accidental exposure to vanilla spawning/commands.
- Compatibility issues in saved chunks.

Difficulty: high.

Roadmap compatibility: important later, but premature before an unregistered
probe.

Recommendation: no for the immediate next patch. Revisit after Approach B.

### Approach D - Reuse Villager/Mob As A Wrapper

Description: spawn a vanilla `Villager`, `Mob`, or other existing entity and
associate it with a `LabAgent`.

Files touched:

- mostly PebbleLab, possibly no PebbleCore.

Advantages:

- Immediate `World.entities` presence.
- Existing renderer/model behavior.
- Existing collision, tick, and save/load behavior.

Disadvantages:

- Brings vanilla AI, trades, sounds, drops, despawn, breeding, targeting, and
  interactions.
- Blurs lab semantics with vanilla behavior.
- Hard to keep deterministic and isolated.

Risks:

- Hidden behavior changes over time.
- Golden-sensitive if existing mobs are altered.
- Lab cognition and vanilla AI may conflict.

Difficulty: low initially, high long-term coupling.

Roadmap compatibility: poor as a foundation.

Recommendation: no, except as a throwaway manual visualization probe outside
the main roadmap.

### Approach E - Visual Marker / Debug-Only Rendering Without Real Entity

Description: keep PebbleLab placeholder state and later add a renderer-side
debug marker or overlay without putting a simulated entity in `World.entities`.

Files likely touched later:

- `Sources/Pebble/*`;
- possibly debug UI/settings;
- docs.

Advantages:

- Useful for visual inspection.
- Avoids registry and save/load risk.
- Can show abstract/placeholder positions without physical simulation.

Disadvantages:

- Touches renderer/app target.
- Not a real entity feasibility step.
- Does not validate PebbleCore entity storage or tick.

Risks:

- Renderer-specific work can distract from deterministic headless simulation.
- Requires careful feature gating.

Difficulty: medium.

Roadmap compatibility: useful later for observation, not next for physical
entity feasibility.

Recommendation: not next. Consider after a headless real-entity probe exists.

## 5. Recommended Next Patch

Recommended next phase:

`Phase 4.3A - unregistered LabCoreAgentEntity probe`

This should be a code phase, but still non-invasive and registry-free.

Rationale:

- Phase 4.2A already proves bridge synchronization.
- A registered entity is too risky as the next step because entity count/order
  goldens and save/load behavior are sensitive.
- A minimal unregistered PebbleCore `Entity` subclass can prove the next real
  engine boundary without changing registries.

Files to modify:

- add `Sources/PebbleCore/Entity/LabCoreAgentEntity.swift`;
- update `Sources/PebbleLab/LabPhysical.swift`;
- update `Sources/PebbleLab/LabScenarios.swift`;
- update `Sources/PebbleLab/main.swift`;
- update `Sources/PebbleLab/LabOutput.swift`;
- update `Sources/PebbleLab/LabEvents.swift` only if fields are missing;
- update `docs/pebblelab/*`.

Files not to modify:

- `Sources/PebbleCore/Entity/EntityRegistry.swift`;
- existing mob files;
- renderer;
- audio;
- resource packs;
- packaging;
- goldens.

Scenario to add:

- `core_entity_smoke`

Suggested behavior:

- create one `LabAgent`;
- create one unregistered `LabCoreAgentEntity`;
- add the entity to `world.entities`;
- link it through the existing bridge;
- tick a few times;
- synchronize entity position from the abstract agent or from the bridge;
- record final divergence.

Events to add:

- `lab_core_entity_spawned`;
- `lab_core_entity_synced`;
- optionally `lab_core_entity_ticked`.

Metrics to add:

- `coreEntitiesSpawned`;
- `coreEntitiesTicked`;
- `agentsWithCoreEntity`;
- `coreEntityBridgeLinks`;
- `coreEntitySyncEvents`;
- `abstractCoreEntityDivergence`;
- `maxAbstractCoreEntityDivergence`.

Smoke validation:

- `core_entity_smoke` succeeds;
- `world.entities` contains the lab entity during the run;
- final abstract/core divergence is zero;
- `EntityRegistry` is unchanged;
- `pebsmoke` still passes.

Definition of Done for Phase 4.3A:

- `swift build` passes;
- `core_entity_smoke` passes;
- `physical_sync_smoke` still passes;
- `regression_smoke` still passes;
- `pebsmoke` passes;
- no registry/golden/renderer/audio/resource-pack changes;
- docs updated;
- branch pushed.

## 6. Minimal Implementation Contract For A Future Entity

Proposed name:

- `LabCoreAgentEntity`

Rejected for now:

- `LabHumanEntity`, because it implies humanoid/visual/social behavior too
  early;
- `LabPhysicalEntity`, because it is less specific about agent ownership.

Suggested class:

- `public final class LabCoreAgentEntity: Entity`

Suggested fields:

- `public let labAgentId: String`;
- optional `public let physicalId: String`;
- `public private(set) var labTicksAlive: Int`;
- optional `public var syncedFromLab = true`.

Relationship to `LabAgent.id`:

- one `LabAgent.id` maps to one `LabCoreAgentEntity.labAgentId`;
- bridge id remains stable, for example `agent_0 -> physical_agent_0`;
- the entity should not own cognition.

Initial position:

- same x/y/z as `LabAgent.position`;
- use `setPos(Double(x) + 0.5, Double(y), Double(z) + 0.5)` only if the
  contract chooses block-center physical coordinates;
- document any block-int to Double conversion explicitly.

Tick minimal:

- override `tick()` to increment `age`/internal counter deterministically;
- either call `baseTick()` only if fluid/fire/void behavior is desired, or
  avoid it in v0 and document that the entity is inert.

No own AI:

- no goals;
- no `Mob`;
- no pathfinding;
- no navigation;
- no target selection;
- no item pickup;
- no block interaction.

No custom physics:

- no custom collision;
- no gravity contract in v0;
- no pathfinding;
- movement is set from `LabAgent` or bridge sync only.

No save/load in v0:

- do not register the type;
- do not claim persistence;
- do not run it through GameCore saved-world flows;
- if a `save()` override is added, document that it is not loadable until a
  registry-safe persistence phase.

Bridge integration:

- `LabAgentPhysicalBridge` remains the owner of lab mapping;
- it may store an optional core entity id/reference summary;
- sync should continue to measure divergence between abstract and physical
  positions.

Metrics and snapshots:

- add a core entity section to `physical_snapshot.json` or a new
  `core_entity_snapshot.json`;
- include entity id, entity type, lab agent id, abstract position, entity
  position, divergence, and tick count.

Registry safety:

- do not edit `EntityRegistry` in Phase 4.3A;
- do not expose the type through `/summon`;
- do not alter `entityTypes()`;
- do not alter `spawnableMobs()`.

## 7. Validation Plan

Baseline validation before a future real-entity patch:

```bash
cd ~/Dev/pebble-lab
git checkout lab/pebblelab-v1
swift build
swift run -c release PebbleLab -- --scenario physical_sync_smoke --seed 42 --ticks 5 --out runs/check_physical_sync_before_real_entity
swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_before_real_entity
swift run -c release pebsmoke
git status
```

Future Phase 4.3A scenario command:

```bash
cd ~/Dev/pebble-lab
swift run -c release PebbleLab -- --scenario core_entity_smoke --seed 42 --ticks 3 --out runs/core_entity_smoke_v0
```

Future full validation should include:

```bash
cd ~/Dev/pebble-lab
swift build
swift run -c release PebbleLab -- --scenario physical_sync_smoke --seed 42 --ticks 5 --out runs/check_physical_sync_after_core_entity
swift run -c release PebbleLab -- --scenario core_entity_smoke --seed 42 --ticks 3 --out runs/check_core_entity_smoke
swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_core_entity
swift run -c release pebsmoke
git status
```

## 8. DoD For This Docs-Only Phase

This docs-only phase is done when:

- `PHASE_4_REAL_ENTITY_FEASIBILITY.md` exists;
- PebbleCore entity files were inspected;
- PebbleLab bridge files were inspected;
- candidate approaches are compared;
- the recommendation is clear;
- the future phase is defined;
- no PebbleCore file is modified;
- no registry is modified;
- no renderer, audio, resource pack, packaging, or golden file is modified;
- `swift build` passes;
- `physical_sync_smoke` passes;
- `regression_smoke` passes;
- `pebsmoke` passes;
- docs are updated;
- commit is created;
- branch is pushed.
