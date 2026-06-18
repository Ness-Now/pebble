# Phase 4 World Observation Invariants

Date: 2026-06-18

Branch: `lab/pebblelab-v1`

## Purpose

Phase 4.7D makes the multi-agent read-only world observation contract
independently auditable. It adds no new observation, scan, or world behavior.

## Artifact

`world_observation_multi_smoke` writes
`world_observation_invariant_report.json`. The report contains scenario
identity, an aggregate summary, ten named checks, and explicit scope notes.

Its success participates directly in both `worldInteractionSuccess` and the
overall run success. A failed invariant therefore fails the scenario rather
than producing a passive warning.

## Checks

1. `agent_count`
2. `observation_count`
3. `all_observations_loaded`
4. `all_observations_ready`
5. `all_observations_successful`
6. `all_divergences_zero`
7. `all_chunks_unchanged`
8. `all_blocks_valid`
9. `all_relations_below`
10. `block_id_diversity_accounted`

The observation-count check also requires valid, unique `agentId`,
`physicalId`, and `coreEntityId` triplets. Block validity requires a present
cell, registered ID, metadata in `0...15`, exact packed-cell reconstruction,
and a matching registered block name.

## Validated Result

For seed `42` and five ticks:

- checks passed/failed: `10/0`;
- agents/observations/linked observations: `3/3/3`;
- loaded/ready/successful observations: `3/3/3`;
- zero-divergence observations: `3`;
- unchanged-chunk observations: `3`;
- valid-block observations: `3`;
- unique chunks/distinct block IDs: `1/1`;
- report and run success: `true`.

## Event

`world_observation_invariant_report_written` records the path and report
success once per multi-agent run.

## Boundaries

This phase changes only PebbleLab reporting and documentation. It does not add
terrain scanning, raycasts, pathfinding, collision, navigation, mining,
construction, inventory, block mutation, save/load, registry, renderer,
resource, or golden changes.

## Validation

```sh
cd ~/Dev/pebble-lab
swift build
swift build -c release --product Pebble
swift run -c release PebbleLab -- --scenario world_observation_multi_smoke --seed 42 --ticks 5 --out runs/check_world_observation_multi_invariants
swift run -c release PebbleLab -- --scenario world_observation_smoke --seed 42 --ticks 5 --out runs/check_world_observation_single_after_invariants
swift run -c release PebbleLab -- --scenario physical_behavior_multi_smoke --seed 42 --ticks 10 --out runs/check_multi_behavior_after_world_observation_invariants
swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_world_observation_invariants
swift run -c release pebsmoke
```

## Next Step

Recommended: Phase 4.8A, terrain scan planning. Define a fixed, bounded,
read-only coordinate order, chunk-boundary behavior, output limits, and
success contract before implementing a multi-cell scan.

Phase 4.8A is complete. The resulting contract fixes the future scan at one
agent, radius `1`, nine cells, one Y layer, and deterministic `dz_then_dx`
order with per-cell loaded/ready guards. See `PHASE_4_TERRAIN_SCAN_PLAN.md`.
