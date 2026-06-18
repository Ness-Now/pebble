# Phase 4 Probe Cleanup Hardening

Date: 2026-06-18

Branch: `lab/pebblelab-v1`

## Purpose

Phase 4.5A centralizes removal of transient `LabCoreAgentEntity` probes and
applies it at clear lifecycle boundaries. This is debug hygiene only; it adds
no probe creation, behavior, persistence, or rendering changes.

## Cleanup Helper

PebbleCore exposes:

```swift
clearLabCoreAgentProbes(in world: World) -> Int
```

The helper snapshots only `LabCoreAgentEntity` instances from
`world.entities`, removes each through `World.removeEntity`, and returns the
number removed. It never mutates `World.entities` or `World.entityById`
directly, does not inspect environment variables, and returns zero when there
is nothing to remove.

`GameCore.clearLabCoreAgentProbes()` applies the helper to every dimension
world owned by the current game. `/labprobe clear` uses the same helper for the
active world.

## Transition Hooks

Cleanup runs at four clear boundaries:

1. `GameCore.exitToTitle`, before synchronous save and before worlds are
   discarded;
2. `GameCore.enterWorld`, before replacing any prior world set;
3. `GameCore.moveToDimension`, before moving the player between world
   instances;
4. `AppDelegate.applicationWillTerminate`, before the final synchronous save.

Dimension cleanup covers every world in the current GameCore, not only the
source world, so no stale probe remains in an inactive dimension.

No cleanup hook is added to chunk unload. Existing chunk unload already uses
`World.removeEntity`, and probes are excluded from chunk records through
`shouldSaveToChunk == false`.

## Tests

The existing 456-check `pebsmoke` entity contract now also:

- inserts two probes and one standard entity into a test `World`;
- verifies cleanup returns two;
- verifies a second cleanup returns zero;
- verifies only the standard entity remains in `entities` and `entityById`;
- verifies both probe IDs are absent from `entityById`;
- restores the global entity ID counter before subsequent golden checks.

This extends an existing check rather than changing the expected check count or
goldens.

## Boundaries

Phase 4.5A does not modify `EntityRegistry`, save/load formats,
`shouldSaveToChunk`, `persistent`, rendering, models, shaders, resources,
audio, packaging, or goldens. It introduces no new command and no gameplay
behavior.

## Validation

```sh
cd ~/Dev/pebble-lab
swift build
swift build -c release --product Pebble
swift run -c release PebbleLab -- --scenario core_entity_smoke --seed 42 --ticks 5 --out runs/check_core_entity_after_probe_cleanup
swift run -c release PebbleLab -- --scenario physical_sync_smoke --seed 42 --ticks 5 --out runs/check_physical_sync_after_probe_cleanup
swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_probe_cleanup
swift run -c release pebsmoke
```

## Remaining Limit

The transition behavior is covered by compilation and the helper's world-index
test, not by automated app UI navigation through portals and menus. The already
validated manual `/labprobe clear` path remains available.

## Next Step

Recommended: Phase 4.5B, scripted screenshot and command validation in a
disposable world. It should exercise the existing gates and cleanup contract
without introducing gameplay behavior.
