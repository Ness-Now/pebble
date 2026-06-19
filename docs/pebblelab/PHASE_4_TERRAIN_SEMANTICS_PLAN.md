# Phase 4.9A — Read-Only Terrain Semantics Planning

## Context

PebbleLab now has two bounded terrain-scan scenarios:

- `terrain_scan_smoke` reads a radius-1, `3x3` area around the below-cell of
  a synchronized agent at the center of a chunk;
- `terrain_scan_edge_smoke` applies the same scan at a chunk corner and reads
  across four preloaded chunks;
- both scenarios use the shared contract in `LabTerrainScanContract.swift`;
- both produce deterministic snapshots, metrics, events, and invariant
  reports;
- all reads are guarded by loaded/ready checks and preserve chunk state.

Neither scenario mutates the world. The scan produces facts about packed
cells; it does not yet assign meaning to those facts.

## Future Phase 4.9B Objective

Phase 4.9B should classify the nine cells already present in a terrain-scan
snapshot. It must not reread the world. The classifier should consume only the
immutable facts already carried by `LabTerrainScanCell` and produce one
semantic result for each input cell.

The first vocabulary should remain deliberately small:

- `unknown`
- `air`
- `solid`
- `liquid`
- `plantLike`
- `other`

`hazardLike` and `resourceLike` are deferred. They imply gameplay meaning that
the current scan does not establish.

## Pure Transformation Contract

The fundamental boundary is:

`LabTerrainScanCell -> LabTerrainCellSemantic`

Classification must be a pure, deterministic transformation. It must not:

- call `World.getBlock` or otherwise access `World`;
- access or generate chunks;
- mutate chunk state;
- consult entity state beyond identifiers already captured in the snapshot;
- infer navigation, pathfinding, collision, or agent decisions.

Given the same scan cell, the classifier must always return the same semantic
value, confidence, and reason. Input ordering must be preserved exactly.

## Proposed Types

The exact API may evolve during Phase 4.9B, but a small shape is sufficient:

```swift
enum LabTerrainCellKind: String, Codable {
    case unknown
    case air
    case solid
    case liquid
    case plantLike
    case other
}

struct LabTerrainCellSemantic: Codable {
    let dx: Int
    let dz: Int
    let x: Int
    let y: Int
    let z: Int
    let blockId: Int?
    let blockName: String?
    let kind: LabTerrainCellKind
    let confidence: Double
    let reason: String
}
```

Coordinates and block identity are repeated intentionally so each semantic
cell can be audited against exactly one raw scan cell without relying on array
position alone.

## Minimal Classification V0

The first implementation should favor false negatives over confident but
incorrect claims.

1. If a cell is not loaded, not ready, unsuccessful, lacks a packed cell,
   lacks a valid block ID, or has inconsistent packed values, classify it as
   `unknown`.
2. Classify exact air identities (`air`, `cave_air`, and `void_air`) as `air`.
   Block ID `0` may support this decision only when it agrees with the captured
   identity; it must not override missing loaded/ready evidence.
3. Classify exact `water` and `lava` identities as `liquid`. Avoid broad
   substring matching.
4. Classify plants with a small reviewed set of exact names and unambiguous
   suffixes such as `_leaves` and `_sapling`. Broad checks such as
   `contains("grass")` or `contains("flower")` are unsafe because names such as
   `grass_block` and `flower_pot` are not equivalent to plants.
5. Emit `solid` only for identities covered by an explicit, reviewed rule.
   The current scan cell does not contain PebbleCore's `BlockDef.solid` fact,
   so an unmatched valid block must not be called solid by assumption.
6. Classify other valid, unmatched cells as `other`.

Recommended confidence policy:

- `1.0` for exact air and liquid identities;
- a lower fixed value for reviewed plant or solid rules;
- `0.5` for `other`;
- `0.0` for `unknown`.

The reason string must identify the rule used, for example
`exact_block_name:water`, `reviewed_suffix:_leaves`, or
`fallback:valid_unclassified_cell`.

Most importantly, semantic kinds are descriptive, not navigational:

- `solid` does not prove a complete pathfinding obstacle;
- `liquid` does not prove danger or swimming behavior;
- `air` does not prove a safe or navigable destination;
- `plantLike` does not imply replaceability, harvestability, or inventory
  value.

## Recommended Output

Add a separate top-level `semanticCells` array to
`terrain_scan_snapshot.json`, rather than modifying the raw `cells` entries.
This preserves the Phase 4.8 evidence and makes the one-to-one transformation
auditable. `semanticCells` must have the same count and deterministic
`dz_then_dx` order as `cells`.

The snapshot summary may add semantic counts, but the existing terrain-scan
summary and success value must retain their current meaning.

Proposed metrics:

- `terrainSemanticCells`
- `terrainSemanticUnknownCells`
- `terrainSemanticAirCells`
- `terrainSemanticSolidCells`
- `terrainSemanticLiquidCells`
- `terrainSemanticPlantLikeCells`
- `terrainSemanticOtherCells`
- `terrainSemanticSuccess`

## Proposed Event

Emit one `lab_terrain_semantics_recorded` event after classification with:

- `agentId`
- `radius`
- `cellsClassified`
- `unknownCells`
- `airCells`
- `solidCells`
- `liquidCells`
- `plantLikeCells`
- `otherCells`
- `success`

No per-cell event is needed for the fixed nine-cell smoke.

## Proposed Invariant Report

Write `terrain_semantics_invariant_report.json` and make report success part of
the future scenario success contract. Proposed checks:

1. terrain scan exists;
2. semantic cell count matches scan cell count;
3. every semantic cell maps to exactly one scan cell;
4. unloaded or unready cells classify as `unknown`;
5. packed block values remain unchanged;
6. semantics do not alter terrain-scan success;
7. semantic counts match the summary;
8. classification requires no world access;
9. no mutation path is used;
10. output order matches the scan's `dz_then_dx` order.

The no-world-access and no-mutation checks are code-review contracts, like the
existing terrain-scan mutation invariant. Runtime checks should cover the
observable one-to-one mapping, counts, ordering, and unchanged raw values.

## Out Of Scope

- traversability and walkability;
- pathfinding and route selection;
- collision, fall safety, and jumpability;
- swimming and liquid danger;
- mining, placing, construction, or any world mutation;
- inventory and resource valuation;
- agent decision-making and goal selection;
- vertical or multi-layer scans;
- raycasts and orientation/ahead scans;
- multi-agent scans;
- machine learning, LLMs, and reinforcement learning.

## Risks And Mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Block names are imprecise or evolve | A rule silently changes meaning | Prefer exact reviewed identities, expose the reason, and cover rules with deterministic fixtures. |
| Block ID `0` is treated as air without evidence | Missing/unready data becomes false air | Require loaded/ready/success and a captured identity before classification. |
| Liquid detection by substring is too broad | Non-liquid blocks are mislabeled | Use exact `water` and `lava` identities in v0. |
| Plant detection by substring is too broad | Blocks such as `grass_block` or `flower_pot` become plants | Use a reviewed exact-name/suffix set and fall back to `other`. |
| Semantic kind is confused with traversability | Classification becomes premature navigation logic | State the non-navigational contract in types, docs, reasons, and invariants. |
| Pathfinding is introduced during classification | Scope and determinism expand sharply | Keep 4.9B as a pure cell transform with no agent action output. |
| The classifier rereads the world | Results can diverge from the audited scan | Accept only `LabTerrainScanCell`; do not pass `World` into the classifier. |
| Rules over-generalize unknown blocks | Confidence exceeds evidence | Preserve `unknown` and `other`; require explicit rules for stronger labels. |

## Future Phase 4.9B Success Contract

Phase 4.9B is complete only when:

- central `terrain_scan_smoke` still passes;
- edge `terrain_scan_edge_smoke` still passes with four unique chunks;
- exactly nine semantic cells are produced for each scan;
- semantic output preserves raw scan order and one-to-one identity;
- the semantic invariant report has `success = true` and zero failed checks;
- raw packed values and terrain-scan success remain unchanged;
- classification performs no world reads, chunk loads, or mutations;
- no PebbleCore, registry, save/load, renderer, resource, or golden file is
  changed;
- `pebsmoke` reports `456 passed, 0 failed`.

## Future Validation Commands

cd ~/Dev/pebble-lab

git checkout lab/pebblelab-v1

swift build

swift run -c release PebbleLab -- --scenario terrain_scan_smoke --seed 42 --ticks 5 --out runs/check_terrain_semantics_central

swift run -c release PebbleLab -- --scenario terrain_scan_edge_smoke --seed 42 --ticks 5 --out runs/check_terrain_semantics_edge

swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_terrain_semantics

swift run -c release pebsmoke

git status

## Recommendation

Proceed with **Phase 4.9B — terrain cell semantic classification v0**. Keep the
implementation inside PebbleLab, transform the existing scan cells once, and
defer traversability, pathfinding, collision, and all mutation until the
semantic output is independently auditable.
