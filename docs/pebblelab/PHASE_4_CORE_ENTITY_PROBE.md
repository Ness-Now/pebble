# Phase 4 Core Entity Probe

Date: 2026-06-18

Branch: `lab/pebblelab-v1`

Purpose: validate the smallest safe PebbleCore boundary crossing for
PebbleLab agents by constructing an unregistered `Entity` directly from a
headless PebbleLab scenario.

## Current Shape

Phase 4.3A adds `LabCoreAgentEntity`, a minimal PebbleCore `Entity` subclass
used only by PebbleLab smoke scenarios.

It is:

- constructed directly by PebbleLab;
- linked to `LabAgent.id` and `LabPhysicalAgentHandle.physicalId`;
- added to `World.entities` with `world.addEntity`;
- ticked explicitly by PebbleLab because direct `World.tick()` does not tick
  entities;
- synchronized from `LabAgent.position` after abstract movement.

It is not:

- registered in `EntityRegistry`;
- spawnable through vanilla mob helpers;
- loadable through `loadEntity`;
- saved by a PebbleLab run;
- visible in the Metal renderer;
- a `LivingEntity` or `Mob`;
- pathfinding, colliding, fighting, building, crafting, or holding real item
  stacks.

## Files

- `Sources/PebbleCore/Entity/LabCoreAgentEntity.swift`
- `Sources/PebbleLab/LabPhysical.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/main.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabOptions.swift`

## Scenario

`core_entity_smoke` creates:

- one abstract `LabAgent`;
- one PebbleLab-only physical placeholder;
- one unregistered `LabCoreAgentEntity`.

The agent receives high curiosity so it chooses abstract `explore` movement.
After each abstract move, PebbleLab synchronizes both the placeholder and the
core entity to the abstract position.

## Outputs

`core_entity_smoke` writes the existing run outputs plus:

- `core_entity_snapshot.json`
- `core_entity_invariant_report.json`

The snapshot records:

- `agentId`;
- `physicalId`;
- `coreEntityId`;
- entity kind;
- abstract position;
- core entity position;
- final divergence;
- `ticksAlive`.

## Metrics

Phase 4.3A adds:

- `coreEntitiesSpawned`;
- `coreEntitiesTicked`;
- `coreEntityLinks`;
- `coreEntitiesSynced`;
- `coreEntitySyncEvents`;
- `coreEntitySyncDistance`;
- `abstractCoreEntityDivergence`;
- `maxAbstractCoreEntityDivergence`;
- `worldEntitiesCount`.

The expected healthy smoke result is final divergence `0`.

## Invariant Report

Phase 4.3B adds eight checks for the probe contract:

- core entity count matches the abstract agent count;
- every core entity is present by identity in `World.entities` and
  `World.entityById`;
- every core entity has a matching `LabAgent`;
- every core entity has a matching physical placeholder identifier;
- every core entity uses `pebblelab:core_agent_probe`;
- final abstract/core divergence is zero;
- every core entity has recorded at least one explicit tick;
- the scenario retains its direct-construction, unregistered contract.

The final check is a documented scenario contract, not registry introspection.
The report does not call or mutate `EntityRegistry`.

## Events

Phase 4.3A adds:

- `lab_core_entity_spawned`;
- `lab_core_entity_synced`.

`lab_core_entity_synced` is emitted only when the entity position actually
differs from the abstract agent position.

## Validation

Required validation:

```sh
cd ~/Dev/pebble-lab
git checkout lab/pebblelab-v1
swift build
swift run -c release PebbleLab -- --scenario core_entity_smoke --seed 42 --ticks 5 --out runs/check_core_entity_smoke
swift run -c release PebbleLab -- --scenario physical_sync_smoke --seed 42 --ticks 5 --out runs/check_physical_sync_after_core_entity
swift run -c release PebbleLab -- --scenario physical_placeholder_smoke --seed 42 --ticks 3 --out runs/check_physical_placeholder_after_core_entity
swift run -c release PebbleLab -- --scenario agent_smoke --seed 42 --ticks 3 --out runs/check_agent_smoke_after_core_entity
swift run -c release PebbleLab -- --scenario agents_basic --seed 42 --agents 10 --ticks 20 --out runs/check_agents_basic_after_core_entity
swift run -c release PebbleLab -- --scenario seek_safety_smoke --seed 42 --ticks 10 --out runs/check_seek_safety_after_core_entity
swift run -c release PebbleLab -- --scenario long_run_smoke --seed 42 --agents 10 --ticks 1000 --event-rate 10 --out runs/check_long_run_after_core_entity
swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_core_entity
swift run -c release pebsmoke
git status
```

## Remaining Limits

- The probe has no registry entry and no save/load contract.
- The probe is not visible in Pebble.
- PebbleLab controls ticking explicitly; this is not yet integrated with
  `GameCore`.
- The probe uses no collision, navigation, mob AI, combat, sounds, drops, or
  real item inventory.
- Future registered work must be planned separately because `EntityRegistry`
  order and spawnable mob lists are golden-sensitive.

## Next Step

Recommended next phase: Phase 4.4A, plan debug visibility separately. Do not
register the entity until a dedicated registry-safe patch has explicit
validation criteria.
