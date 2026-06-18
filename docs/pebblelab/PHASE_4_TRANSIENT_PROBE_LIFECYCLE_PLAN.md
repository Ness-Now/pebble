# Phase 4 Transient Probe Lifecycle Plan

Date: 2026-06-18

Branch: `lab/pebblelab-v1`

## 1. Current State

`LabCoreAgentEntity` is a real PebbleCore `Entity` subclass used as an
experimental probe. It is constructed directly by PebbleLab's
`core_entity_smoke`, inserted into `World.entities` and `World.entityById`,
ticked explicitly, and synchronized from the abstract `LabAgent`.

The probe remains unregistered. `EntityRegistry` has no factory for
`pebblelab:core_agent_probe`, and `loadEntity` cannot reconstruct it.

`WorldRenderer` now has a default-off wireframe path gated by
`PEBBLELAB_DEBUG_ENTITIES=1`. It can display a live `LabCoreAgentEntity` already
present in an app world, but the app does not create one. There is no
`/labprobe` command, startup injection, transient manager, or save-safe app
lifecycle.

A naive command is unsafe because normal GameCore chunk serialization would
include the unregistered probe in a save record.

## 2. Save/Load Architecture Summary

### Entity serialization

`Entity.save()` returns a dictionary containing:

- `type`;
- position and velocity;
- yaw and pitch;
- age and fire state;
- the `persistent` value;
- the generic entity data bag.

`LabCoreAgentEntity` does not override `save()`. If serialized, its type is
`pebblelab:core_agent_probe`. Its Lab-specific identifiers are not currently
part of the saved dictionary, but the unknown type alone is enough to make the
record non-loadable.

`persistent == false` does not mean "exclude from chunk save". It is stored as
data and participates in mob lifecycle behavior, but `GameCore.chunkRecord`
does not consult it when deciding which entities to serialize.

### Chunk record creation

`GameCore.chunkRecord` iterates `World.entities` and currently filters only:

- values that are not `Entity`;
- players;
- dead entities;
- entities outside the chunk;
- old item and XP-orb entities after an age threshold.

Every other matching entity is serialized with `ent.save()`.

`saveAndFlush` creates records for modified loaded chunks and includes pending
records produced during unload. Autosave runs every 1200 ticks. The app also
calls synchronous save when returning to the title and when terminating.

### Chunk unload

`GameCore.unloadChunk` first checks whether any live non-player entity occupies
the chunk. A probe satisfies that test, so even an otherwise unmodified chunk
can receive an entity-only record. `chunkRecord` captures the probe, then
`unloadChunk` removes all live non-player entities in the chunk through
`World.removeEntity`.

`World.removeEntity` removes the same object from both `World.entities` and
`World.entityById`. A future lifecycle manager must use this API rather than
editing either collection independently.

### Storage and reload

`Sources/PebbleCore/Game/Saves.swift` encodes `ChunkRecord.entities` into the
chunk container JSON tail. On load, `requestChunk` obtains the record and
`adoptChunk` loops over saved entity dictionaries.

`loadEntity` reads the saved `type`, asks the private registry factory table to
create that type, then calls `load`. Because the probe is unregistered,
`createEntity("pebblelab:core_agent_probe", world)` returns `nil`; the probe is
silently dropped.

The impact is wider than losing the probe. Any saved record, including an
entity-only record, overrides fresh worldgen entity specs for that chunk. A
contaminated record can therefore suppress generated entities while still
failing to restore the debug probe.

### Existing test coverage

`pebsmoke` freezes:

- entity type count;
- entity registration order;
- spawnable mob list;
- deterministic mob simulation, combat, spawning, and pathfinding.

It exercises entity `persistent` state in simulation, but it does not currently
contain a focused assertion that `GameCore.chunkRecord` excludes a transient
unregistered entity. The next phase needs an explicit save-policy test.

### Safe future exclusion point

The narrowest reusable design is an entity-level chunk-save policy:

```swift
open var shouldSaveToChunk: Bool { true }
```

`LabCoreAgentEntity` should override it to `false`. `GameCore` should consult
the property in two places:

1. the `unloadChunk` `hasEntities` decision;
2. the `chunkRecord` entity serialization loop.

This keeps vanilla behavior unchanged and avoids misusing `persistent`, whose
existing semantics are broader than save inclusion.

## 3. App-Side Probe Creation Options

### Option A - Never create an app-side probe

Files touched: none.

Advantages:

- zero save, registry, or lifecycle risk;
- headless snapshots and invariant reports remain sufficient for simulation.

Disadvantages:

- the renderer marker cannot be visually exercised;
- no app-side bridge debugging.

Complexity: none. Roadmap compatibility: safe baseline, but does not complete
visual validation.

Recommendation: retain as default behavior, not as the final debug workflow.

### Option B - Simple `/labprobe` command without save exclusion

Files touched: `Sources/Pebble/CommandsM.swift`.

Advantages:

- small and immediately testable;
- directly creates the type the renderer recognizes.

Disadvantages and risks:

- can create an entity-only chunk record;
- can serialize an unknown type that `loadEntity` drops;
- can suppress worldgen entity specs for the contaminated chunk;
- cleanup on exit or chunk unload is not guaranteed before persistence.

Complexity: low. Roadmap compatibility: unsafe.

Recommendation: no.

### Option C - `/labprobe` after explicit save exclusion

Files touched across two ordered phases:

- first: `Entity.swift`, `LabCoreAgentEntity.swift`, `GameCore.swift`, and
  `pebsmoke/main.swift` for save policy;
- later: `CommandsM.swift` for gated spawn/clear operations.

Advantages:

- exercises the real world entity and existing renderer marker;
- allows explicit spawn and cleanup;
- save exclusion protects modified, unloaded, autosaved, and exit-saved chunks.

Disadvantages:

- requires a carefully tested PebbleCore save-policy change first;
- command lifecycle still needs idempotency and dimension/world-change cleanup;
- debug behavior can be confused with gameplay if not strongly gated.

Complexity: medium. Roadmap compatibility: good when split into separate
phases.

Recommendation: yes later, only after Phase 4.4D.

### Option D - Boot-only environment injection in a disposable world

Files touched: `Sources/Pebble/main.swift`, possibly a small app-side lifecycle
helper.

Advantages:

- deterministic startup and screenshot automation;
- no chat command exposed;
- naturally paired with `PEBBLELAB_DEBUG_ENTITIES=1`.

Disadvantages:

- "disposable" is a convention, not a persistence guarantee;
- autosave, chunk unload, title exit, and app termination still run;
- selecting or deleting the correct disposable world adds operational risk.

Complexity: medium. Roadmap compatibility: acceptable only after save
exclusion.

Recommendation: not before Phase 4.4D; consider after the command lifecycle is
specified.

### Option E - Separate transient layer outside `World.entities`

Files touched: app-side transient storage, `WorldRenderer`, and lifecycle
plumbing.

Advantages:

- cannot enter entity chunk saves;
- naturally debug-only.

Disadvantages:

- no longer validates a real PebbleCore entity in `World.entities`;
- bypasses entity queries and the Phase 4.3 bridge contract;
- adds a parallel render-state system and new coupling.

Complexity: medium to high. Roadmap compatibility: weak for physical entity
work.

Recommendation: no for this project direction.

### Option F - Fully registered, persisted entity

Files touched: registry, entity save/load, models or renderer mapping, tests,
and potentially goldens.

Advantages:

- normal spawn and load path;
- persistent gameplay identity.

Disadvantages:

- registry ordering and golden risk;
- premature save schema and migration commitment;
- much larger behavior and compatibility surface.

Complexity: high. Roadmap compatibility: eventual, not current.

Recommendation: no until transient physical behavior is stable.

## 4. Recommended Next Patch

Recommended phase:

`Phase 4.4D - explicit save-exclusion contract for LabCoreAgentEntity`

This should be a small code patch. It should not remain docs-only, because the
unsafe serialization behavior is now identified precisely and can be isolated.

Modify only:

- `Sources/PebbleCore/Entity/Entity.swift`;
- `Sources/PebbleCore/Entity/LabCoreAgentEntity.swift`;
- `Sources/PebbleCore/Game/GameCore.swift`;
- `Sources/pebsmoke/main.swift`;
- PebbleLab tracking documents.

Implementation contract:

- add a default-true entity property such as `shouldSaveToChunk`;
- override it to `false` only for `LabCoreAgentEntity`;
- exclude false-policy entities from `chunkRecord` serialization;
- exclude false-policy entities from `unloadChunk.hasEntities` so a probe alone
  does not create an entity-only record;
- continue removing all entities in an unloaded chunk with
  `World.removeEntity`;
- do not change `persistent` semantics;
- do not change registry factories or loading;
- do not add a command, environment injection, renderer change, or save schema;
- add focused `pebsmoke` assertions for default vanilla policy and probe policy.

Files that must not change include `EntityRegistry.swift`, `WorldRenderer.swift`,
`CommandsM.swift`, app startup, model/resource paths, shaders, audio, packaging,
and goldens.

`/labprobe` remains forbidden in Phase 4.4D. It becomes eligible for a later
Phase 4.4E only after save exclusion is validated.

## 5. Safe Transient Lifecycle Contract

A future app-side probe is allowed only when all of these are true:

- creation requires an explicit debug gate;
- the feature is inactive by default;
- the probe has an explicit false chunk-save policy;
- unload and save code never serializes it;
- it is never registered and never passed through `spawnMob` or `loadEntity`;
- it never appears in natural spawn lists;
- no `/labprobe` command exists before save exclusion is merged;
- disposable test worlds are preferred even after exclusion;
- creation is idempotent for a given debug identity;
- cleanup calls `World.removeEntity`, removing both `entities` and `entityById`;
- cleanup runs on explicit clear, world exit, dimension transition, and debug
  session shutdown;
- dead or unloaded probes leave no app-side bridge references;
- debug logs or HUD state clearly label the entity as transient;
- renderer activation remains separately gated by
  `PEBBLELAB_DEBUG_ENTITIES=1`;
- no gameplay state depends on the probe.

Once Phase 4.4D exists, a later command may be acceptable if it is gated,
supports both `spawn` and `clear`, refuses duplicates, and reports its transient
status. It must still not be listed as a normal summonable mob.

## 6. Risk Map

| Risk | Severity | Probability | Mitigation | Decision |
| --- | --- | --- | --- | --- |
| Save contamination | Critical | High without exclusion | Add explicit entity save policy and apply it in both unload presence and serialization. | Phase 4.4D first. |
| Probe dropped on load | High | Certain if serialized | Prevent serialization; do not register merely to hide the problem. | No app injection yet. |
| Worldgen entities suppressed by stale record | High | Medium | Ensure a probe alone cannot create an entity-only record. | Filter `hasEntities`. |
| Orphan in `entityById` | High | Medium with manual cleanup | Always use `World.removeEntity`; never mutate arrays directly. | Lifecycle contract requirement. |
| Memory or bridge leak | Medium | Medium | Clear bridge references when probe is removed or world changes. | Test spawn/clear later. |
| Debug/gameplay confusion | Medium | Medium | Exact env gate, debug naming, wireframe only, no summon registry. | Default off. |
| Accidental activation | Medium | Low | Require explicit env value and later gated command. | No persisted setting. |
| `pebsmoke` incompatibility | High | Low with default-true policy | Preserve all vanilla defaults and test representative entities. | Run all 456 checks. |
| GameCore/PebbleLab coupling | Medium | Medium | Generic save-policy property on `Entity`; only probe override mentions Lab. | Avoid Lab checks in generic policy API. |
| Renderer/simulation mixing | Medium | Low | Keep renderer gate read-only and lifecycle outside `WorldRenderer`. | Separate phases. |
| Future registered-type conflict | High | Low now | Revisit save policy explicitly before registration; do not silently flip behavior. | Document migration requirement. |

## 7. Validation Plan for Future Phase

Required validation for Phase 4.4D:

```sh
cd ~/Dev/pebble-lab
git checkout lab/pebblelab-v1
swift build
swift run -c release PebbleLab -- --scenario core_entity_smoke --seed 42 --ticks 5 --out runs/check_core_entity_before_transient_probe
swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_before_transient_probe
swift run -c release pebsmoke
git status
```

Add focused `pebsmoke` checks that prove:

- a normal `Entity` is saveable by default;
- `LabCoreAgentEntity` is not saveable to chunks;
- entity registry count/order and spawnable list remain unchanged.

Future app-side validation belongs to Phase 4.4E, after exclusion exists. A
realistic eventual workflow would use a disposable world and explicit gate:

```sh
cd ~/Dev/pebble-lab
PEBBLELAB_DEBUG_ENTITIES=1 PEBBLE_AUTOLOAD=1 swift run -c release Pebble
```

That later workflow must verify spawn, visible marker, clear, world exit, and
reload without a saved `pebblelab:core_agent_probe` record. It is not
implemented or run in Phase 4.4C.

Phase 4.4D Definition of Done:

- save policy defaults to true for existing entities;
- the Lab probe overrides it to false;
- chunk serialization and unload presence checks honor the policy;
- no command or app injection is added;
- registry, renderer, save schema, and goldens are unchanged;
- targeted policy checks and all existing `pebsmoke` checks pass;
- PebbleLab core and regression smokes remain green.

## 8. Definition of Done for This Docs-Only Phase

Phase 4.4C is complete when:

- this plan exists;
- `chunkRecord`, unload, storage encoding, registry loading, autosave, title
  exit, app termination, and world index removal paths have been inspected;
- six lifecycle approaches are compared;
- Phase 4.4D has a precise implementation and validation contract;
- no Swift, GameCore, World, renderer, registry, save/load, model, shader,
  texture, resource pack, audio, packaging, or golden file is modified;
- `swift build` passes;
- `core_entity_smoke` and `regression_smoke` pass;
- `pebsmoke` reports 456 passed and 0 failed;
- only PebbleLab documentation files are committed and pushed.
