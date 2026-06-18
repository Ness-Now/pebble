# Phase 4 Multi-Agent World Observation

Date: 2026-06-18

Branch: `lab/pebblelab-v1`

## Purpose

Phase 4.7C extends the guarded, read-only block observation contract from one
synchronized agent to three. It remains a one-cell observation per agent and
does not introduce terrain scanning or world mutation.

## Scenario

`world_observation_multi_smoke` creates three stationary agents at distinct
positions. Each owns exactly one physical placeholder and one directly
constructed, unregistered core entity.

After five ticks and physical synchronization, the runner maps the existing
`observeBlockBelow` function over agents in stable ID order. Every observation
checks loaded and ready state before calling `World.getBlock`.

## Aggregate Contract

The scenario succeeds only when:

- exactly three agents, placeholders, and core entities exist;
- exactly three observations are produced;
- all target chunks are loaded and ready;
- every observation succeeds;
- every abstract/core divergence is zero;
- every observed chunk retains unchanged `modified`, `version`, and `dirty`
  state.

## Outputs

`world_interaction_snapshot.json` contains an ordered `observations` list and
a summary with agents, observations, loaded/ready counts, unique chunk count,
distinct block ID count, and success.

`metrics.json` adds aggregate aliases:

- `worldInteractionUniqueChunks`;
- `worldInteractionDistinctBlockIds`.

Existing `worldInteractionAgents`, observation counts, and success metrics are
shared with the single-agent scenario. `worldInteractionBlockId` and
`worldInteractionMeta` remain single-observation-only and are omitted from the
multi-agent JSON.

The run emits `lab_world_observation_multi_recorded` once, avoiding per-tick
or per-agent event volume.

Phase 4.7D also writes `world_observation_invariant_report.json`. Its ten
checks cover counts and unique links, loaded/ready/success state, zero
divergence, unchanged chunks, valid packed block data, `below` relations, and
reported block-ID diversity. Report success gates scenario success.

## Validated Result

For seed `42` and five ticks:

- agents/observations: `3/3`;
- loaded/ready observations: `3/3`;
- unique chunks: `1`;
- distinct block IDs: `1`;
- all three cells: `4672` (`water`, block ID `292`, meta `0`);
- every divergence: `0`;
- every chunk state unchanged: `true`;
- aggregate success: `true`.

## Boundaries

No block mutation API is called. This phase adds no scan radius, pathfinding,
collision, navigation, block entities, inventory, mining, construction,
save/load, registry, renderer, resource, or golden change.

## Validation

```sh
cd ~/Dev/pebble-lab
swift build
swift build -c release --product Pebble
swift run -c release PebbleLab -- --scenario world_observation_multi_smoke --seed 42 --ticks 5 --out runs/check_world_observation_multi_smoke
swift run -c release PebbleLab -- --scenario world_observation_smoke --seed 42 --ticks 5 --out runs/check_world_observation_single_after_multi
swift run -c release PebbleLab -- --scenario physical_behavior_multi_smoke --seed 42 --ticks 10 --out runs/check_multi_behavior_after_world_observation_multi
swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_world_observation_multi
swift run -c release pebsmoke
```

## Next Step

Recommended: Phase 4.7D, world observation invariant report. Make the link,
guard, count, divergence, and unchanged-chunk checks independently readable
before planning any bounded terrain scan.

Phase 4.7D is complete with 10 passed checks and no failures for the validated
seed-42 run. The next recommended phase is 4.8A, terrain scan planning.
