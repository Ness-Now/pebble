# Phase 4 World Observation

Date: 2026-06-18

Branch: `lab/pebblelab-v1`

## Purpose

Phase 4.7B adds PebbleLab's first explicit read-only voxel-world interaction.
One synchronized agent observes the block immediately below its authoritative
abstract position without mutating blocks, chunks, saves, registries, or
rendering state.

## Scenario

`world_observation_smoke` creates:

- one stationary `LabAgent` at generated coordinates `(8, 64, 8)`;
- one `LabPhysicalAgentHandle`;
- one directly constructed, unregistered `LabCoreAgentEntity`.

After five normal ticks and physical synchronization, the scenario observes
target `(8, 63, 8)` with relation `below`.

## Read Contract

The observation performs this ordered sequence:

1. derive the below target from `LabAgent.position`;
2. calculate chunk coordinates with `floorDiv` and `CHUNK_W`;
3. evaluate `World.isLoadedAt` and `World.isChunkReady`;
4. call `World.getBlock` only when both guards pass;
5. decode `blockId = cell >> 4` and `meta = cell & 15`;
6. resolve `blockDefs[blockId].name` when the ID is valid;
7. confirm the placeholder/core link and zero abstract/core divergence;
8. confirm chunk `modified`, `version`, and `dirty` state did not change.

No mutation API is called.

## Outputs

`world_interaction_snapshot.json` records agent, physical and core IDs,
positions, target relation and coordinates, chunk guards, packed cell, block
ID, metadata, block name, divergence, unchanged chunk state, and success.

`metrics.json` includes:

- `worldInteractionAgents`;
- `worldInteractionObservations`;
- `worldInteractionLoadedObservations`;
- `worldInteractionReadyObservations`;
- `worldInteractionBlockId`;
- `worldInteractionMeta`;
- `worldInteractionSuccess`.

The run emits `lab_world_observation_recorded`. If links are unavailable, an
explicit failed observation event is emitted and the run fails.

## Validated Result

For seed `42` and five ticks:

- agents/observations: `1/1`;
- target: `(8, 63, 8)`, relation `below`;
- chunk: `(0, 0)`, loaded `true`, ready `true`;
- cell: `4672`;
- block ID/meta/name: `292 / 0 / water`;
- abstract/core divergence: `0`;
- chunk state unchanged: `true`;
- world interaction and run success: `true`.

## Boundaries

This phase does not call `World.setBlock`, `Chunk.set`, `/setblock`, `/fill`,
`placeBlock`, `finishBreaking`, or `breakBlockNaturally`. It adds no dirty
chunk, light, remesh, neighbor update, scheduled tick, block entity access,
save/load, real inventory, mining, construction, collision, pathfinding,
navigation, renderer, resource, registry, or golden change.

## Validation

```sh
cd ~/Dev/pebble-lab
swift build
swift build -c release --product Pebble
swift run -c release PebbleLab -- --scenario world_observation_smoke --seed 42 --ticks 5 --out runs/check_world_observation_smoke
swift run -c release PebbleLab -- --scenario physical_behavior_multi_smoke --seed 42 --ticks 10 --out runs/check_multi_behavior_after_world_observation
swift run -c release PebbleLab -- --scenario physical_behavior_smoke --seed 42 --ticks 10 --out runs/check_single_behavior_after_world_observation
swift run -c release PebbleLab -- --scenario core_entity_smoke --seed 42 --ticks 5 --out runs/check_core_entity_after_world_observation
swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_world_observation
swift run -c release pebsmoke
```

## Next Step

Recommended: Phase 4.7C, multi-agent read-only observation smoke. It should
preserve fixed observation ordering, loaded/ready guards, bounded output, and
the zero-mutation contract before any terrain scan is considered.

Phase 4.7C is now complete. Three agents reuse the same guarded observation
function and produce an ordered aggregate snapshot. See
`PHASE_4_MULTI_AGENT_WORLD_OBSERVATION.md`.
