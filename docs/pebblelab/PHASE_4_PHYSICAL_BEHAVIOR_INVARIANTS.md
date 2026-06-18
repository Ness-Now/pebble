# Phase 4 Physical Behavior Invariants

Date: 2026-06-18

Branch: `lab/pebblelab-v1`

## Purpose

Phase 4.6C makes the multi-agent physical behavior contract independently
auditable. It adds no behavior; it reports whether the existing three-agent
loop preserves ownership, identifier, movement, and divergence invariants.

## Artifact

`physical_behavior_multi_smoke` writes
`physical_behavior_invariant_report.json` with:

- scenario, seed, ticks, and overall success;
- a compact summary of counts, movement, distance, and divergence;
- ten named checks with expected and actual values;
- explicit scope notes.

The run also emits `physical_behavior_invariant_report_written`. Report failure
causes `physicalBehaviorSuccess` and the overall run to fail.

## Checks

1. `agent_count`
2. `each_agent_has_one_placeholder`
3. `each_agent_has_one_core_entity`
4. `physical_ids_unique`
5. `core_entity_ids_unique`
6. `physical_ids_match_core_entities`
7. `at_least_two_agents_moved`
8. `total_distance_positive`
9. `final_divergence_zero`
10. `max_divergence_zero`

## Validated Result

For seed `42` and 10 ticks, all ten checks pass. The report records three
agents, three placeholders, three core entities, three moving agents, 24 moves,
distance 24, and zero total and maximum final divergence.

## Boundaries

This phase changes only PebbleLab reporting and documentation. It adds no
movement rule, goal, pathfinding, collision, avoidance, block interaction,
inventory integration, combat, registration, save/load behavior, renderer
work, resource asset, or golden update.

## Validation

```sh
cd ~/Dev/pebble-lab
swift build
swift build -c release --product Pebble
swift run -c release PebbleLab -- --scenario physical_behavior_multi_smoke --seed 42 --ticks 10 --out runs/check_physical_behavior_multi_invariants
swift run -c release PebbleLab -- --scenario physical_behavior_smoke --seed 42 --ticks 10 --out runs/check_physical_behavior_single_after_invariants
swift run -c release PebbleLab -- --scenario core_entity_smoke --seed 42 --ticks 5 --out runs/check_core_entity_after_behavior_invariants
swift run -c release PebbleLab -- --scenario physical_sync_smoke --seed 42 --ticks 5 --out runs/check_physical_sync_after_behavior_invariants
swift run -c release PebbleLab -- --scenario long_run_smoke --seed 42 --agents 10 --ticks 1000 --event-rate 10 --out runs/check_long_run_after_behavior_invariants
swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_behavior_invariants
swift run -c release pebsmoke
```

## Next Step

Recommended: Phase 4.7A, first simple world interaction planning. Define a
small deterministic and initially non-destructive contract before implementing
any world mutation or physical navigation.
