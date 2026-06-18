# Phase 4 Save Exclusion

Date: 2026-06-18

Branch: `lab/pebblelab-v1`

## Purpose

Phase 4.4D gives transient entities an explicit chunk-save opt-out before any
app-side probe injection is introduced.

## Contract

`Entity` now exposes:

```swift
open var shouldSaveToChunk: Bool { true }
```

The default preserves all existing entity behavior.
`LabCoreAgentEntity` overrides the property to return `false`.

This policy is intentionally separate from `persistent`. Existing code stores
and uses `persistent` for entity lifecycle semantics; Phase 4.4D does not alter
that behavior or the save schema.

## GameCore Integration

The policy is checked in two places:

1. `chunkRecord` excludes false-policy entities before position and age filters
   lead to `Entity.save()`;
2. `unloadChunk` excludes false-policy entities from `hasEntities`, preventing
   a transient probe alone from creating an entity-only chunk record.

The unload cleanup loop is unchanged. It still removes all live non-player
entities in the chunk through `World.removeEntity`, keeping `World.entities`
and `World.entityById` synchronized.

## Test Strategy

`pebsmoke` verifies in its existing entity contract check that:

- a base `Entity` is saveable by default;
- `LabCoreAgentEntity` is not saveable;
- applying the collector policy to one of each retains only the base entity.

The test snapshots and restores the global entity ID counter, so later golden
entity IDs remain unchanged. It augments an existing check to keep the expected
summary at 456 checks.

`chunkRecord` and `unloadChunk` remain private. They were not exposed merely to
support tests; source integration and compilation prove both use the tested
public policy. A future higher-level GameCore save integration test may add
stronger black-box coverage without changing this API.

## Boundaries

Phase 4.4D adds no:

- app-side probe creation or `/labprobe` command;
- registry entry, spawnable mob, or load factory;
- save format field or migration;
- renderer, model, shader, texture, resource pack, audio, or packaging change;
- golden update.

## Validation

```sh
cd ~/Dev/pebble-lab
swift build
swift run -c release PebbleLab -- --scenario core_entity_smoke --seed 42 --ticks 5 --out runs/check_core_entity_after_save_exclusion
swift run -c release PebbleLab -- --scenario physical_sync_smoke --seed 42 --ticks 5 --out runs/check_physical_sync_after_save_exclusion
swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_save_exclusion
swift run -c release pebsmoke
```

## Next Step

Recommended next phase: Phase 4.4E, a gated app-side probe lifecycle. It should
provide idempotent spawn and clear operations, use `World.removeEntity` for
cleanup, remain absent by default, and validate against a disposable world.
