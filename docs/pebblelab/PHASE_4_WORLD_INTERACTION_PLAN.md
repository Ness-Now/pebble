# Phase 4 World Interaction Plan

Date: 2026-06-18

Branch: `lab/pebblelab-v1`

## Objective

Phase 4.7A identifies the smallest safe bridge between a synchronized
PebbleLab agent and PebbleCore's voxel world. This is a planning phase only: no
block, chunk, save, registry, renderer, or behavior code changes here.

The recommended first interaction is read-only block perception. Mutation,
mining, construction, inventory transfer, and navigation remain deferred.

## Current State

- `LabAgent.position` is the authoritative abstract position.
- `LabPhysicalAgentHandle` and the unregistered `LabCoreAgentEntity` follow it.
- Three physical behavior links run deterministically with zero final
  divergence.
- `LabAgent.observe(world:)` already records `blockBelow` and `blockAtFeet`
  through `World.getBlock` as part of general observation.
- No dedicated physical-world observation scenario, event, metrics, or
  snapshot exists yet.
- No PebbleLab agent mutates voxel state.

Some requested paths do not exist in this repository. Block definitions and
registration live under `Sources/PebbleCore/World/BlockDefs.swift` and
`BlockRegistry*.swift`, not `Sources/PebbleCore/Block/`. There is no dedicated
`World/BlockPos.swift`; block coordinates are passed as integer `x`, `y`, `z`
values, while ray hits use `RaycastHit`.

## World Read Paths

The primary read API is `World.getBlock(x, y, z) -> Int` in
`GameWorld.swift`. It locates the chunk with `floorDiv`, converts world
coordinates with `posMod`, and calls `Chunk.get`. A missing chunk or a Y value
outside the chunk returns cell `0`.

That fallback is deliberately ambiguous: cell `0` is air, so callers must not
interpret `getBlock == 0` as observed air without first checking chunk
availability.

Safe read sequence for Phase 4.7B:

1. derive block coordinates from the authoritative agent position;
2. compute chunk coordinates using `floorDiv(..., CHUNK_W)`;
3. require `World.isLoadedAt(x, z)` and `World.isChunkReady(cx, cz)`;
4. read the target with `World.getBlock`;
5. split the cell into `blockId = cell >> 4` and `meta = cell & 15`;
6. resolve a stable name through the already-registered `blockDefs[blockId]`;
7. record the coordinates, cell, ID, meta, name, and loaded/ready state.

Related read APIs:

- `World.getBlockId` and `World.getMeta` expose the packed cell components;
- `World.getChunk`, `getChunkAt`, `isLoadedAt`, and `isChunkReady` distinguish
  loaded data from the missing-chunk air fallback;
- `Chunk.get` is a lower-level local-coordinate read and should not be used by
  PebbleLab when `World.getBlock` is sufficient;
- `World.raycast` performs deterministic voxel traversal and returns a
  `RaycastHit`, but requires a meaningful direction/orientation contract that
  abstract agents do not yet have;
- `World.surfaceY` and `heightAt` are useful context but are not substitutes
  for observing the actual cell.

For the first smoke, observing the block directly below the synchronized
agent is safer than observing "ahead": it needs no new orientation model and
the spawn helper already places agents above generated terrain.

## World Mutation Paths

The central mutation API is `World.setBlock(x, y, z, cell, flags)`. Default
flags are `SET_DEFAULT` (`neighbors + light + remesh`). A successful change:

- writes through `Chunk.set`;
- sets `Chunk.modified = true`, making the edit eligible for chunk saving;
- tracks portal/sculk special blocks;
- may invalidate and remove a block entity;
- updates the heightmap;
- updates light through `LightEngine`;
- marks local and boundary sections dirty and calls `onSectionDirty`;
- notifies neighboring blocks and may schedule further ticks.

`SET_SILENT` suppresses propagation but still changes the cell and marks the
chunk modified. It is a world-generation tool, not a safe escape hatch for
PebbleLab experiments.

Higher-level mutation paths are broader still:

- `/setblock` and `/fill` call `World.setBlock` with default effects;
- `placeBlock` checks replaceability and entity collision, computes metadata,
  handles multiblock structures and block entities, consumes inventory, and
  emits placement effects;
- `finishBreaking` handles sounds, particles, vibrations, block entities,
  drops, tools, statistics, multiblock cleanup, and entity spawning;
- `breakBlockNaturally` mutates the cell and emits particles;
- fluid, redstone, farming, block-entity, and neighbor handlers can cascade
  from a mutation.

`GameCore.saveAndFlush` serializes modified chunks through `chunkRecord`.
`unloadChunk` also records a modified chunk. Therefore even a one-cell test can
cross chunk, save, light, mesh, scheduled-tick, and block-entity boundaries.

## Technical Risks

| Risk | Severity | Why | Mitigation |
| --- | --- | --- | --- |
| Missing chunk reads as air | High | `getBlock` returns `0` for missing chunks | Check loaded and ready state before reading |
| Registry order coupling | High | Cell IDs depend on frozen block registration | Read only; never register or reorder blocks |
| Save contamination | High | `setBlock` marks `Chunk.modified` | No mutation in Phase 4.7B |
| Light/remesh propagation | High | Default mutation flags trigger both systems | Avoid `setBlock`, including silent mode |
| Neighbor/tick cascades | High | Redstone, fluids, gravity, farming can react | Keep observation side-effect free |
| Block entity invalidation | High | Type replacement may remove live data | Do not mutate block cells |
| Ambiguous "ahead" direction | Medium | `LabAgent` has no physical yaw contract | Observe below first; plan facing separately |
| Nondeterministic scan ordering | Medium | Unordered collections could reorder output | Fixed coordinate order for any later scan |
| Large scan cost/log volume | Medium | Per-agent regions multiply quickly | Start with one cell and one agent |
| Packed cell misinterpretation | Low | Cell includes ID and four metadata bits | Record cell, ID, meta, and stable block name |

## Options Compared

### Option A - Perception-Only Block Below The Agent

Files in a future patch: PebbleLab scenario, output/event types, and runner.

Complexity: low. Read a single cell after verifying the chunk is loaded and
ready. The current `LabAgent.observe` implementation proves the underlying API
is already usable.

Risks: mainly missing-chunk ambiguity and coordinate semantics. Both are easy
to expose in the snapshot.

Testability: excellent in a deterministic generated chunk. The smoke can
assert a loaded observation, repeatable packed cell, valid block ID, and no
world mutation.

Roadmap compatibility: direct continuation of the synchronized physical loop.

Recommendation: **yes; preferred Phase 4.7B**.

### Option B - Small Terrain Scan Around The Agent

Files in a future patch: similar to Option A, with a scan result model.

Complexity: low to medium. It needs fixed traversal order, boundary handling,
result size limits, and clearer success semantics.

Risks: accidental reads across unloaded chunk boundaries, larger snapshots,
event volume, and premature coupling to navigation concepts.

Testability: good, but broader than needed to prove the first interaction.

Roadmap compatibility: useful after a single-cell observation contract exists.

Recommendation: **not yet; candidate after Phase 4.7B**.

### Option C - PebbleLab-Only Marker Without World Mutation

Files in a future patch: PebbleLab snapshot/event code only.

Complexity: low, but it reports a synthetic marker rather than reading voxel
state.

Risks: can look like world interaction while proving none.

Testability: excellent, but semantically redundant with existing placeholders
and snapshots.

Roadmap compatibility: weak for the stated goal.

Recommendation: **no as the first world interaction**.

### Option D - Simple `setBlock` In A Loaded Chunk

Files in a future patch: PebbleLab plus potentially save/cleanup test support.

Complexity: deceptively medium to high because `setBlock` marks the chunk
modified and defaults to neighbor, light, and remesh propagation.

Risks: persistent chunk edits, boundary remesh, light changes, scheduled ticks,
block entity invalidation, and cleanup failures. `SET_SILENT` does not avoid
the modified/save contract.

Testability: possible in an isolated world, but requires restoration and proof
that save state and secondary systems remain coherent.

Roadmap compatibility: premature before read-only observation.

Recommendation: **no for Phase 4.7B**.

### Option E - Real Block Breaking Or Mining

Files in a future patch: PebbleCore interaction context, player/tool/inventory
semantics, drops, statistics, effects, and PebbleLab integration.

Complexity: high. `finishBreaking` is player-oriented and includes drops,
block entities, multiblock cleanup, vibrations, sounds, particles, and tool
rules.

Risks: gameplay coupling, entity/item spawning, inventory requirements, save
mutation, and golden-sensitive behavior.

Testability: broad existing `pebsmoke` coverage exists, but a Lab agent mining
contract would be a new subsystem rather than a small extension.

Roadmap compatibility: much later.

Recommendation: **explicitly avoid now**.

### Option F - Real Block Placement Or Construction

Files in a future patch: interaction context, placement metadata, collision,
inventory, block entities, multiblock structures, effects, and PebbleLab.

Complexity: high. `placeBlock` consumes a real `ItemStack`, checks living-entity
collision, and handles many block-specific cases.

Risks: all mutation risks plus real inventory coupling and structural partial
failure.

Testability: requires a much larger contract than first observation.

Roadmap compatibility: later construction phase only.

Recommendation: **explicitly avoid now**.

## Recommendation

Proceed with **Phase 4.7B - perception-only block observation smoke**.

The first target should be the block below one synchronized physical agent.
The future implementation should reuse `World.isLoadedAt`,
`World.isChunkReady`, and `World.getBlock`; it should not add a PebbleCore API.
The existing general `blockBelow` field can remain compatible, while the new
scenario adds a dedicated, auditable physical-world observation artifact.

Proposed scenario: `world_observation_smoke`.

Proposed outputs:

- `world_interaction_snapshot.json`;
- `lab_world_observation_recorded` NDJSON event;
- `worldInteractionObservations` metric;
- `worldInteractionAgents` metric;
- `worldInteractionSuccess` metric.

Suggested snapshot fields:

- scenario, seed, and tick;
- agent, physical, and core entity IDs;
- abstract/core positions and divergence;
- target coordinates and relation (`below`);
- chunk coordinates, loaded state, and ready state;
- packed cell, block ID, metadata, and block name;
- success.

Success contract:

- exactly one expected agent/placeholder/core link exists;
- abstract/core divergence is zero before observation;
- the target chunk is loaded and ready;
- exactly one observation is recorded;
- the block ID indexes a registered `BlockDef`;
- repeated runs with seed 42 produce the same target and cell;
- no chunk's `modified`, `dirty`, `version`, block-entity, or block arrays are
  changed by the observation;
- overall run success is true.

## Future Phase Guardrails

Phase 4.7B must not:

- call `setBlock`, `Chunk.set`, `placeBlock`, `finishBreaking`, or
  `breakBlockNaturally`;
- mark chunks modified or dirty;
- trigger light updates, mesh rebuild hooks, neighbor updates, or scheduled
  block ticks;
- read or modify block entities;
- invoke save/load;
- consume or create real inventory items;
- add mining, construction, collision, pathfinding, or navigation;
- modify block/entity registries or renderer code.

## Validation Plan For Phase 4.7B

```sh
cd ~/Dev/pebble-lab
git checkout lab/pebblelab-v1
swift build
swift build -c release --product Pebble
swift run -c release PebbleLab -- --scenario world_observation_smoke --seed 42 --ticks 3 --out runs/world_observation_smoke_v0
swift run -c release PebbleLab -- --scenario physical_behavior_multi_smoke --seed 42 --ticks 10 --out runs/check_multi_behavior_after_world_observation
swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_world_observation
swift run -c release pebsmoke
git status
```

## Planning Conclusion

Reading one loaded cell below an agent is the smallest real voxel interaction
with a clean determinism and safety story. Terrain scans can follow after that
contract is stable. Block mutation, mining, and construction should remain out
of scope until separate plans cover restoration, saves, block entities, light,
mesh, neighbor updates, and inventory semantics.

## Phase 4.7B Outcome

The recommended `world_observation_smoke` is now implemented. For seed `42`,
it observes water below the synchronized agent in a loaded and ready chunk,
records cell `4672` (`blockId=292`, `meta=0`), preserves zero abstract/core
divergence, and confirms chunk mutation state is unchanged. See
`PHASE_4_WORLD_OBSERVATION.md`.
