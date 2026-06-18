# Phase 4 Physical Behavior Loop

Date: 2026-06-18

Branch: `lab/pebblelab-v1`

## Purpose

Phase 4.6A closes the first deterministic behavior loop across all three
PebbleLab representations:

```text
LabAgent goal/action -> abstract movement -> physical placeholder sync
-> unregistered LabCoreAgentEntity sync
```

It remains a headless experiment. The core entity does not choose actions or
move independently.

## Scenario

`physical_behavior_smoke` creates:

- one curious `LabAgent` at the generated center;
- one `LabPhysicalAgentHandle` linked by `physical_agent_0`;
- one unregistered `LabCoreAgentEntity` added to `World.entities`.

Each tick reuses the existing stable order:

1. tick and observe the abstract agent;
2. select its goal and action;
3. apply the internal action effect;
4. apply existing `move_abstract` movement;
5. tick and synchronize the placeholder;
6. tick and synchronize the core entity.

Curiosity starts at `0.9`, ensuring the existing deterministic explore rule
produces movement during a short run.

## Outputs

`metrics.json` adds scenario-specific aliases:

- `physicalBehaviorTicks`;
- `physicalBehaviorMoves`;
- `physicalBehaviorCoreSyncs`;
- `physicalBehaviorTotalDistance`;
- `physicalBehaviorFinalDivergence`;
- `physicalBehaviorSuccess`.

`physical_behavior_snapshot.json` records start position, final abstract and
core positions, IDs, move count, total distance, divergence, and success.

The run emits `lab_physical_behavior_started` and
`lab_physical_behavior_completed`. Existing movement and sync events remain the
detailed per-step record.

## Success Contract

The scenario succeeds only when:

- all requested ticks complete;
- the expected agent is present and ticked;
- at least one abstract move occurs;
- at least one effective core sync occurs;
- final abstract/core Manhattan divergence is zero.

## Validated Result

For seed `42` and 10 ticks:

- start: `(8, 64, 8)`;
- final abstract: `(5, 64, 9)`;
- final core entity: `(5, 64, 9)`;
- moves: `8`;
- core syncs: `8`;
- total distance: `8`;
- final divergence: `0`;
- success: `true`.

## Boundaries

Phase 4.6A adds no pathfinding, collision query, gravity, block interaction,
real inventory, combat, registry entry, save/load behavior, renderer change,
resource asset, or golden update. The core entity position is set directly
from the authoritative abstract position after movement.

## Validation

```sh
cd ~/Dev/pebble-lab
swift build
swift build -c release --product Pebble
swift run -c release PebbleLab -- --scenario physical_behavior_smoke --seed 42 --ticks 10 --out runs/check_physical_behavior_smoke
swift run -c release PebbleLab -- --scenario core_entity_smoke --seed 42 --ticks 5 --out runs/check_core_entity_after_physical_behavior
swift run -c release PebbleLab -- --scenario physical_sync_smoke --seed 42 --ticks 5 --out runs/check_physical_sync_after_physical_behavior
swift run -c release PebbleLab -- --scenario long_run_smoke --seed 42 --agents 10 --ticks 1000 --event-rate 10 --out runs/check_long_run_after_physical_behavior
swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_physical_behavior
swift run -c release pebsmoke
```

## Next Step

Recommended: Phase 4.6B, behavior-loop hardening and multi-agent physical
behavior. It should first define ownership, ordering, and aggregate invariants
for multiple core entities without adding pathfinding or world interaction.
