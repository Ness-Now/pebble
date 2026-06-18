# Phase 4 App Probe Lifecycle

Date: 2026-06-18

Branch: `lab/pebblelab-v1`

## Purpose

Phase 4.4E exposes a minimal app-side lifecycle for the unregistered
`LabCoreAgentEntity` debug probe. It does not inject probes automatically or
turn them into gameplay entities.

## Independent Gates

- `PEBBLELAB_APP_PROBES=1` enables probe creation.
- `PEBBLELAB_DEBUG_ENTITIES=1` enables the existing wireframe renderer marker.

The gates are independent. Creation does not enable rendering, and rendering
does not create an entity. The exact value `1` is required.

## Commands

### `/labprobe status`

Reports whether creation is enabled, the number of probes in the current
world, and each probe's entity ID and position. Status is read-only and works
when creation is disabled.

### `/labprobe spawn`

Requires the app-probe gate. It refuses to create a second probe when one is
already present. The command constructs `LabCoreAgentEntity` directly with the
stable debug identities `app_probe` and `physical_app_probe`, verifies
`shouldSaveToChunk == false`, initializes it one block beside the player, and
calls `World.addEntity`.

It does not use `EntityRegistry`, `spawnMob`, `loadEntity`, natural spawning,
or a PebbleLab simulation bridge.

### `/labprobe clear`

Removes every `LabCoreAgentEntity` from the current world through
`World.removeEntity`. It remains available when creation is disabled so stale
debug state always has a safe cleanup path. The command never edits
`World.entities` or `World.entityById` directly.

## Persistence Contract

The probe remains unregistered and overrides `shouldSaveToChunk` to `false`.
Phase 4.4D already made chunk collection and entity-only unload records honor
that policy. Phase 4.4E does not change the save format, `persistent`, or the
load path.

## Validation

Automated validation:

```sh
cd ~/Dev/pebble-lab
swift build
swift build -c release --product Pebble
swift run -c release PebbleLab -- --scenario core_entity_smoke --seed 42 --ticks 5 --out runs/check_core_entity_after_app_probe_lifecycle
swift run -c release PebbleLab -- --scenario physical_sync_smoke --seed 42 --ticks 5 --out runs/check_physical_sync_after_app_probe_lifecycle
swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_app_probe_lifecycle
swift run -c release pebsmoke
```

Manual disposable-world workflow:

```sh
cd ~/Dev/pebble-lab
PEBBLELAB_APP_PROBES=1 PEBBLELAB_DEBUG_ENTITIES=1 swift run -c release Pebble
```

Then run:

```text
/labprobe status
/labprobe spawn
/labprobe status
/labprobe clear
/labprobe status
```

The app is not launched automatically in this phase. Command behavior and the
wireframe marker require a manual UI session.

## Boundaries

Phase 4.4E adds no registry entry, app startup injection, GameCore change,
renderer change, save/load change, model, texture, shader, resource-pack,
audio, packaging, or golden update.

## Visual Validation

The complete operator workflow, expected results, safety checklist, and cleanup
steps are documented in `PHASE_4_VISUAL_APP_VALIDATION.md`.

Automated builds and headless validation pass, but the macOS UI was not
launched or observed during Phase 4.4F. Visual confirmation remains a manual
disposable-world task.

## Next Step

Phase 4.5A should harden cleanup across world and dimension transitions before
scripted screenshot automation or broader app integration.
