# Phase 4 Core Entity Hardening

Date: 2026-06-18

Branch: `lab/pebblelab-v1`

## Purpose

Phase 4.3B hardens the transient, unregistered `LabCoreAgentEntity` probe with
a deterministic invariant report. It does not expand the probe into a
registered, rendered, persisted, or autonomous entity.

## Report

`core_entity_smoke` writes `core_entity_invariant_report.json` after simulation
and synchronization. The report includes:

- scenario, seed, completed ticks, and overall success;
- passed and failed check counts;
- abstract agent, physical placeholder, core entity, and world entity counts;
- final abstract/core divergence;
- individual expected/actual check results;
- explicit scope notes.

## Checked Contract

The report verifies:

1. core entity count matches abstract agent count;
2. each probe is present by identity in `World.entities` and
   `World.entityById`;
3. each probe has a matching abstract agent;
4. each probe has a matching physical placeholder identifier;
5. each probe uses `pebblelab:core_agent_probe`;
6. final abstract/core divergence is zero;
7. each probe recorded an explicit tick;
8. the scenario retains its unregistered direct-construction contract.

The eighth check is not runtime registry introspection. It records the audited
scenario contract: `core_entity_smoke` constructs the probe directly and does
not use `EntityRegistry`, `registerAllEntities`, `spawnMob`, or `loadEntity` for
the Lab entity.

## Failure Semantics

The invariant report succeeds only when every check passes. For
`core_entity_smoke`, report failure also makes the run-level `success` false.

## Boundaries

Phase 4.3B adds no:

- entity registration or registry reordering;
- save/load support;
- renderer or model mapping;
- `GameCore` entity tick integration;
- navigation, collision, combat, or real inventory;
- audio, resource pack, packaging, or golden changes.

## Validation

```sh
cd ~/Dev/pebble-lab
swift build
swift run -c release PebbleLab -- --scenario core_entity_smoke --seed 42 --ticks 5 --out runs/check_core_entity_hardening
swift run -c release PebbleLab -- --scenario physical_sync_smoke --seed 42 --ticks 5 --out runs/check_physical_sync_after_core_entity_hardening
swift run -c release PebbleLab -- --scenario physical_placeholder_smoke --seed 42 --ticks 3 --out runs/check_physical_placeholder_after_core_entity_hardening
swift run -c release PebbleLab -- --scenario agent_smoke --seed 42 --ticks 3 --out runs/check_agent_smoke_after_core_entity_hardening
swift run -c release PebbleLab -- --scenario agents_basic --seed 42 --agents 10 --ticks 20 --out runs/check_agents_basic_after_core_entity_hardening
swift run -c release PebbleLab -- --scenario seek_safety_smoke --seed 42 --ticks 10 --out runs/check_seek_safety_after_core_entity_hardening
swift run -c release PebbleLab -- --scenario long_run_smoke --seed 42 --agents 10 --ticks 1000 --event-rate 10 --out runs/check_long_run_after_core_entity_hardening
swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_core_entity_hardening
swift run -c release pebsmoke
```

## Next Step

Recommended next phase: Phase 4.4A, debug visibility planning. Keep visibility
separate from registry, save/load, and simulation behavior changes.
