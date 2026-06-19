# Phase 4 Terrain Scan Plan

Date: 2026-06-18

Branch: `lab/pebblelab-v1`

## Objective

Phase 4.8A defines the exact contract for PebbleLab's first bounded terrain
scan before any implementation. The future scan remains a read-only perception
operation over already loaded and ready chunk data. It does not add navigation,
collision, pathfinding, mining, construction, inventory, or block mutation.

The recommended implementation phase is **Phase 4.8B - bounded read-only
terrain scan smoke**.

## Current Foundation

The existing world-observation scenarios already establish the required
single-cell safety rules:

- `LabAgent.position` is authoritative and the core entity has zero divergence;
- the below-cell origin is `(agent.x, agent.y - 1, agent.z)`;
- `World.isLoadedAt(x, z)` and `World.isChunkReady(cx, cz)` are checked before
  `World.getBlock`;
- a missing chunk's fallback cell `0` is never decoded as observed air;
- packed cells are decoded as `blockId = cell >> 4` and `meta = cell & 15`;
- block names come from the existing `blockDefs` table;
- chunk `modified`, `version`, and `dirty` state is compared before and after
  observation;
- dedicated snapshots and invariant reports participate in scenario success.

Phase 4.8B should extend these rules to nine coordinates without adding a new
PebbleCore API.

## Proposed Scenario

Name: `terrain_scan_smoke`

Run contract:

- one `LabAgent`;
- one `LabPhysicalAgentHandle`;
- one unregistered `LabCoreAgentEntity`;
- five ticks by default for the validation command;
- zero abstract/core divergence before scanning;
- relation `around_below`;
- origin `(agent.x, agent.y - 1, agent.z)`;
- horizontal radius `1` at the origin's fixed Y;
- exactly `3 x 3 = 9` planned cells;
- no movement, orientation, raycast, or vertical search is required.

## Coordinate And Ordering Contract

The future implementation should enumerate offsets in deterministic row-major
order with `dz` as the outer loop and `dx` as the inner loop:

```text
for dz in -1...1
  for dx in -1...1
    target = (origin.x + dx, origin.y, origin.z + dz)
```

The resulting offset order is:

```text
(-1,-1), (0,-1), (1,-1),
(-1, 0), (0, 0), (1, 0),
(-1, 1), (0, 1), (1, 1)
```

This is described as `dz_then_dx`, from northwest to southeast for reporting
purposes. It is a coordinate-order convention only and does not introduce an
agent-facing direction.

The radius must be a fixed scenario constant, not a new CLI option in Phase
4.8B. Nine cells are the hard output and read limit.

## Chunk Guard Contract

Every target is guarded independently, because even a radius-1 scan can cross
a chunk boundary when the origin lies on a chunk edge.

For each coordinate:

1. compute `cx = floorDiv(x, CHUNK_W)` and `cz = floorDiv(z, CHUNK_W)`;
2. evaluate `World.isLoadedAt(x, z)`;
3. evaluate `World.isChunkReady(cx, cz)`;
4. call `World.getBlock` only when both values are true;
5. decode cell, block ID, metadata, and name only after that guarded read.

An unavailable target is an explicit failed scan cell with `cell`, `blockId`,
`meta`, and `blockName` absent. It must never become synthetic air. The initial
smoke should fail unless all nine cells are loaded and ready; it must not load
or generate chunks to satisfy the scan.

Unique chunks should be derived from the nine target chunk coordinates, not
from dictionary iteration. Results retain scan order regardless of chunk.

## Proposed Snapshot

Artifact: `terrain_scan_snapshot.json`

```json
{
  "scenario": "terrain_scan_smoke",
  "seed": 42,
  "ticksCompleted": 5,
  "agentId": "agent_0",
  "physicalId": "physical_agent_0",
  "coreEntityId": 1,
  "origin": { "x": 8, "y": 63, "z": 8 },
  "radius": 1,
  "relation": "around_below",
  "order": "dz_then_dx",
  "cells": [
    {
      "dx": -1,
      "dz": -1,
      "x": 7,
      "y": 63,
      "z": 7,
      "chunk": { "cx": 0, "cz": 0, "loaded": true, "ready": true },
      "cell": 4672,
      "blockId": 292,
      "meta": 0,
      "blockName": "water",
      "success": true
    }
  ],
  "summary": {
    "cellsPlanned": 9,
    "cellsObserved": 9,
    "loadedCells": 9,
    "readyCells": 9,
    "distinctBlockIds": 2,
    "uniqueChunks": 1,
    "chunkStateUnchanged": true,
    "success": true
  }
}
```

The values above are illustrative. The implemented snapshot must record all
nine cells in scan order and use the generated world's actual values.

## Proposed Metrics

`metrics.json` should add:

- `terrainScanAgents` - exactly `1`;
- `terrainScanRadius` - exactly `1`;
- `terrainScanCellsPlanned` - exactly `9`;
- `terrainScanCellsObserved` - guarded, decoded observations;
- `terrainScanLoadedCells` - targets whose chunks exist;
- `terrainScanReadyCells` - targets whose chunks are ready;
- `terrainScanDistinctBlockIds` - unique IDs among successful observations;
- `terrainScanUniqueChunks` - unique target chunks;
- `terrainScanSuccess` - aggregate contract result.

The metrics are aggregate only. Per-cell detail belongs in the snapshot, not
in dynamic metric keys.

## Proposed Event

Emit one compact event after scanning:

`lab_terrain_scan_recorded`

Minimum fields:

- `agentId`, `physicalId`, `coreEntityId`;
- `radius`;
- `cellsPlanned`, `cellsObserved`;
- `loadedCells`, `readyCells`;
- `distinctBlockIds`, `uniqueChunks`;
- `success`.

Do not emit one event per cell in Phase 4.8B.

## Proposed Invariant Report

Artifact: `terrain_scan_invariant_report.json`

The report should gate scenario success and include at least these checks:

1. the expected agent exists;
2. physical and core links are coherent and unique;
3. abstract/core divergence is zero;
4. radius equals `1` and relation equals `around_below`;
5. planned cell count equals `9`;
6. observed cell count equals `9`;
7. every decoded cell was loaded and ready before reading;
8. chunk `modified`, `version`, and `dirty` state remained unchanged;
9. offsets and output follow exact `dz_then_dx` order with no duplicates;
10. distinct block-ID count matches the successful cells and is at least one;
11. all packed cells, IDs, metadata, and names are valid;
12. the implementation uses no mutation path.

The final item is a scenario contract and code-review invariant, not a fragile
runtime registry or call-stack inspection.

## Success Contract For Phase 4.8B

`terrain_scan_smoke` succeeds only when:

- exactly one agent, placeholder, and core entity are linked;
- final abstract/core divergence is zero;
- radius, relation, origin, and traversal order match this plan;
- nine coordinates are planned and nine are successfully observed;
- every target is loaded and ready before `getBlock`;
- every decoded block value is valid;
- at least one distinct block ID is recorded;
- all involved chunk-state snapshots remain unchanged;
- the invariant report has zero failures;
- overall run success is true.

## Risks And Mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Radius crosses a chunk boundary | A missing chunk can masquerade as air | Guard loaded/ready per cell and fail without decoding |
| Snapshot growth | Larger radii grow quadratically | Fix radius to 1 and cap output at 9 cells |
| Multi-agent cost multiplication | Reads and JSON scale by agents times area | Keep Phase 4.8B single-agent |
| Nondeterministic output order | Reports become unstable | Use nested `dz`, then `dx`, loops and preserve array order |
| Ambiguous direction | `ahead` requires an orientation contract | Scan horizontally around the below origin only |
| Vertical ambiguity | Height policy can mix layers | Keep one fixed Y: `agent.y - 1` |
| Read interpreted as navigation | Consumers may infer traversability | State that block presence is perception, not pathfinding |
| Hidden world side effects | A helper could trigger mutation or generation | Reuse guarded `getBlock`; never load, generate, or set cells |
| Remesh/save activation | Mutation would dirty chunks | Compare chunk state and forbid all mutation APIs |
| Block-ID assumptions | Registry changes would destabilize output | Resolve existing IDs/names only; never register or reorder |

## Explicitly Out Of Scope

Phase 4.8B must not:

- call `World.setBlock`, `Chunk.set`, `/setblock`, `/fill`, `placeBlock`,
  `finishBreaking`, or `breakBlockNaturally`;
- load or generate a chunk as a side effect of scanning;
- mark chunks modified or dirty, rebuild meshes, update lighting, notify
  neighbors, schedule block ticks, or access block entities;
- scan vertically, scan ahead, raycast, or use orientation;
- add pathfinding, collision, traversability, avoidance, mining,
  construction, real inventory, combat, or world manipulation;
- change registries, save/load, renderer, resources, packaging, or goldens;
- add multi-agent terrain scanning or a configurable radius.

## Validation Plan For Phase 4.8B

```sh
cd ~/Dev/pebble-lab
git checkout lab/pebblelab-v1
swift build
swift build -c release --product Pebble
swift run -c release PebbleLab -- --scenario terrain_scan_smoke --seed 42 --ticks 5 --out runs/check_terrain_scan_smoke
swift run -c release PebbleLab -- --scenario world_observation_multi_smoke --seed 42 --ticks 5 --out runs/check_world_observation_after_terrain_scan
swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_terrain_scan
swift run -c release pebsmoke
git status
```

## Recommendation

Proceed to **Phase 4.8B - bounded read-only terrain scan smoke**. Implement the
single-agent, radius-1, nine-cell contract exactly as specified before
considering larger radii, multiple agents, vertical layers, orientation, or
any world mutation.

## Phase 4.8B Outcome

The planned scenario is implemented and validated for seed `42` and five
ticks:

- one agent, placeholder, and unregistered core entity;
- origin `(8, 63, 8)`, radius `1`, relation `around_below`;
- exact `dz_then_dx` offset order;
- planned/observed/loaded/ready cells: `9/9/9/9`;
- one unique chunk and one distinct block ID (`water`, ID `292`);
- all chunk states unchanged;
- terrain scan and run success: `true`;
- invariant checks passed/failed: `15/0`;
- `pebsmoke`: `456 passed, 0 failed`.

The next recommended phase is **Phase 4.8C - terrain scan edge and invariant
hardening**. It should exercise an origin near a loaded chunk edge without
adding radius configuration, multi-agent scans, terrain semantics, or
mutation.
