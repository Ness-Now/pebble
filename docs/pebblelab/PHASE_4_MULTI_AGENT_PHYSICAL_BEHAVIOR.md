# Phase 4 Multi-Agent Physical Behavior

Date: 2026-06-18

Branch: `lab/pebblelab-v1`

## Purpose

Phase 4.6B hardens the existing physical behavior loop by running several
independent links at once:

```text
LabAgent -> LabPhysicalAgentHandle -> LabCoreAgentEntity
```

`LabAgent.position` remains authoritative. No physical representation chooses
behavior independently.

## Scenario

`physical_behavior_multi_smoke` creates three agents at distinct positions.
Each starts with high curiosity and owns exactly one placeholder and one
directly constructed, unregistered core entity. The existing tick order is
unchanged: abstract observation, goal, action and movement happen before both
physical bridges tick and synchronize.

## Link Contract

The scenario succeeds only when:

- each abstract agent has exactly one placeholder;
- each abstract agent has exactly one core entity;
- the placeholder and core entity share the same `physicalId`;
- physical IDs and core entity IDs are unique;
- at least two agents move;
- at least one effective core sync occurs;
- total and maximum final abstract/core divergence are zero.

## Outputs

`metrics.json` exposes:

- `physicalBehaviorTicks`;
- `physicalBehaviorAgents`;
- `physicalBehaviorAgentsMoved`;
- `physicalBehaviorMoves`;
- `physicalBehaviorCoreSyncs`;
- `physicalBehaviorTotalDistance`;
- `physicalBehaviorFinalDivergence`;
- `physicalBehaviorMaxDivergence`;
- `physicalBehaviorSuccess`.

`physical_behavior_snapshot.json` contains one entry per agent with start,
final abstract and core positions, IDs, movement count, distance, and final
divergence. Aggregate totals appear beside the list.

The run emits `lab_physical_behavior_multi_started` and
`lab_physical_behavior_multi_completed`; existing movement and sync events
remain the detailed trace.

## Validated Result

For seed `42` and 10 ticks:

- physical agents: `3`;
- agents moved: `3`;
- moves: `24`;
- core syncs: `24`;
- total distance: `24`;
- total final divergence: `0`;
- maximum final divergence: `0`;
- success: `true`.

## Boundaries

This phase changes only PebbleLab and documentation. It adds no pathfinding,
collision, avoidance, block interaction, real inventory, combat, registration,
save/load behavior, renderer work, resource assets, or golden updates.

## Validation

```sh
cd ~/Dev/pebble-lab
swift build
swift build -c release --product Pebble
swift run -c release PebbleLab -- --scenario physical_behavior_multi_smoke --seed 42 --ticks 10 --out runs/check_physical_behavior_multi_smoke
swift run -c release PebbleLab -- --scenario physical_behavior_smoke --seed 42 --ticks 10 --out runs/check_physical_behavior_single_after_multi
swift run -c release PebbleLab -- --scenario core_entity_smoke --seed 42 --ticks 5 --out runs/check_core_entity_after_multi_behavior
swift run -c release PebbleLab -- --scenario physical_sync_smoke --seed 42 --ticks 5 --out runs/check_physical_sync_after_multi_behavior
swift run -c release PebbleLab -- --scenario long_run_smoke --seed 42 --agents 10 --ticks 1000 --event-rate 10 --out runs/check_long_run_after_multi_behavior
swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_multi_behavior
swift run -c release pebsmoke
```

## Next Step

Recommended: Phase 4.6C, a compact multi-agent physical behavior invariant
report that makes ownership and divergence regressions easier to diagnose.
