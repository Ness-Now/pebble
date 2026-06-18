# Phase 4 Debug Visibility Plan

Date: 2026-06-18

Branch: `lab/pebblelab-v1`

## 1. Current State

`LabAgent` remains PebbleLab's abstract cognitive state.
`LabPhysicalAgentHandle` remains a PebbleLab-only placeholder.
`LabCoreAgentEntity` is a minimal PebbleCore `Entity` subclass constructed
directly by `core_entity_smoke`.

The core probe:

- is inserted into `World.entities` and `World.entityById`;
- is linked to an abstract agent and physical identifier;
- is explicitly ticked and synchronized by PebbleLab;
- is not registered in `EntityRegistry`;
- has no model, renderer mapping, resource asset, or save/load contract;
- is not visible in the Pebble app.

`core_entity_invariant_report.json` verifies eight headless invariants,
including world membership, links, ticks, kind, and zero final divergence.

## 2. Rendering Architecture Summary

### Targets and ownership

`Package.swift` keeps `PebbleCore`, `Pebble`, and `PebbleLab` separate.
`Pebble` depends on `PebbleCore`; `PebbleLab` also depends only on
`PebbleCore`. Renderer code belongs to the `Pebble` executable target.

The app entry point is `Sources/Pebble/main.swift`. `AppDelegate` creates
`GameCore`, `WorldRenderer`, the HUD, UI, and Metal view. Existing diagnostic
hooks already use `ProcessInfo.processInfo.environment`, including
`PEBBLE_CMD`, `PEBBLE_SHOT`, `PEBBLE_PACKDEBUG`, and `PEBBLE_GEOM_DEBUG`.

### Main entity path

`WorldRenderer` renders the opaque and cutout world layers, then calls:

1. `drawEntities`;
2. `drawSprites`;
3. `drawCubes`;
4. crack and selection overlays;
5. particles.

`drawEntities` iterates `game.world.entities`, skips dead entities, casts each
reference to `Entity`, hides the first-person player, applies distance culling,
and calls `modelNameFor`.

`modelNameFor` resolves:

- colored sheep variants when a matching model exists;
- villager profession variants when a matching model exists;
- the entity type itself when `hasModel(type)` is true;
- `arrow_model` for arrows and tridents;
- `end_crystal_model` for end crystals;
- `boat_model` for boats;
- `minecart_model` for minecarts.

If no model name is found, it returns `nil`. `drawEntities` then continues to
the next entity without drawing anything. Because
`pebblelab:core_agent_probe` has no model, the current probe is skipped safely.

`EntityRendererM` receives only resolved model names. Its internal pig fallback
is not reached for an unknown entity because `modelNameFor` filters it first.
Models and procedural skins live under `Sources/PebbleCore/Render`, while
resource-pack images may replace compatible skins in `EntityRendererM`.

### Special rendering paths

- Dropped items, XP orbs, and several projectiles use `drawSprites`.
- Falling blocks, primed TNT, and crystal bases use `drawCubes`.
- End crystal beams and lightning use the line overlay helper from the entity
  path.
- Block selection uses `drawBoxOutline` with the existing `linePipeline`.
- F3 toggles a 2D HUD debug overlay, but it currently shows aggregate entity
  count rather than per-entity labels.

### Natural insertion point

The safest marker insertion point is a dedicated
`drawLabCoreAgentDebugMarkers` call next to `drawEntities`, before sprites and
other overlays. It can iterate `World.entities`, select only
`LabCoreAgentEntity`, interpolate `prev` and current coordinates, apply the
normal entity-distance limit, and draw a colored wireframe AABB through
`drawBoxOutline`.

This path avoids model resolution, geometry caches, textures, resource packs,
and new Metal pipelines.

## 3. Visibility Options

### Option A - Remain headless only

Files touched: none.

Advantages:

- zero rendering, registry, save, and performance risk;
- existing snapshots and invariant reports remain authoritative.

Disadvantages:

- no spatial inspection in Pebble;
- visual drift or camera-relative mistakes cannot be observed.

Complexity: none. Golden compatibility: complete.

Recommendation: retain as the default behavior, but not as the only long-term
debug path.

### Option B - Renderer-only wireframe marker

Files touched in the future patch: `Sources/Pebble/WorldRenderer.swift` only.

Advantages:

- reuses `linePipeline` and `drawBoxOutline`;
- needs no model, texture, shader, resource pack, or registry entry;
- can be selected with an exact `LabCoreAgentEntity` type check;
- easy to remove and visually distinct from gameplay entities.

Disadvantages:

- proves visibility only when such an entity already exists in the app world;
- adds one debug iteration over entities when enabled;
- does not display identity text.

Complexity: low. Golden compatibility: expected high because the path is app
only and disabled by default.

Recommendation: yes. This is the Phase 4.4B implementation target.

### Option C - Map the probe to an existing model

Files touched: `WorldRenderer.swift`, or model tables under
`Sources/PebbleCore/Render`; possibly resource-pack mappings.

Advantages:

- immediately produces a recognizable solid entity;
- reuses animation, lighting, fog, and distance culling.

Disadvantages:

- visually misrepresents a debug probe as a gameplay mob;
- couples the experimental type to model tables and skin behavior;
- risks geometry/model golden changes if a new mapping is registered;
- the internal pig fallback would hide missing mapping errors.

Complexity: low to medium. Golden compatibility: lower than Option B.

Recommendation: no for the first debug phase.

### Option D - 2D label or debug overlay

Files touched: `WorldRenderer.swift`, `HudM.swift`, UI projection helpers, and
possibly `main.swift` for data plumbing.

Advantages:

- can show `labAgentId`, entity ID, divergence, and state;
- useful once many probes exist.

Disadvantages:

- requires world-to-screen projection and label overlap handling;
- couples renderer and HUD state;
- more visual and maintenance complexity than a marker;
- F3 currently provides aggregate diagnostics, not per-entity overlays.

Complexity: medium. Golden compatibility: likely acceptable when gated, but
the implementation surface is larger.

Recommendation: later, after the wireframe marker is stable.

### Option E - Explicit debug mode or command

Files touched: potentially `main.swift`, `CommandsM.swift`, and
`WorldRenderer.swift`.

Advantages:

- explicit operator control;
- compatible with existing environment and `PEBBLE_CMD` test hooks;
- could support scripted screenshots.

Disadvantages:

- a `/labprobe` command would need to construct an unregistered entity in a
  normal `GameCore` world;
- `GameCore.chunkRecord` serializes non-player entities in loaded chunks and
  does not generally exclude `persistent == false` entities;
- a command-created probe could therefore leak into a save record even though
  it cannot be loaded through `EntityRegistry`.

Complexity: medium when lifecycle and cleanup are handled safely. Golden
compatibility: likely, but save compatibility risk is real.

Recommendation: use an environment variable only to gate drawing in Phase
4.4B. Defer app-side probe spawning to a separate transient-lifecycle phase.

### Option F - Dedicated model and resource assets

Files touched: model tables, `EntityRendererM`, resource-pack mapping, textures,
and possibly shaders or pack documentation.

Advantages:

- best eventual presentation;
- could visually distinguish agent roles and states.

Disadvantages:

- crosses several protected boundaries;
- introduces asset, pack, model, and golden maintenance;
- premature while the entity is unregistered and transient.

Complexity: high. Golden compatibility: requires dedicated review.

Recommendation: no until physical entity semantics are stable.

## 4. Implemented Patch

Implemented phase:

`Phase 4.4B - renderer-gated debug marker for LabCoreAgentEntity`

Phase 4.4B is implemented as a small renderer-only patch.

Modify only:

- `Sources/Pebble/WorldRenderer.swift`;
- PebbleLab tracking documents.

Implementation:

- read `PEBBLELAB_DEBUG_ENTITIES` once and enable only when its value is `1`;
- keep the default disabled;
- add `drawLabCoreAgentDebugMarkers` beside the existing entity draw calls;
- select `LabCoreAgentEntity` instances by Swift type, not registry name;
- interpolate `prevX/Y/Z` to current coordinates with `partial`;
- use the entity width and height for a camera-relative wireframe AABB;
- reuse `linePipeline`, `depthRead`, and `drawBoxOutline`;
- use a fixed, conspicuous debug color;
- apply entity-distance culling;
- do not alter `modelNameFor`, model tables, textures, shaders, or packs;
- add no simulation metrics, snapshots, or NDJSON events.

No spawn command was added. The marker is a pure view of
entities already present. App-side probe injection requires a later contract
that prevents an unregistered probe from entering chunk saves.

No new headless scenario is needed. Preserve `core_entity_smoke` as the
authoritative simulation and bridge validation.

## 5. Debug Visibility Contract

Future debug visibility must satisfy all of these conditions:

- disabled by default;
- activated only by `PEBBLELAB_DEBUG_ENTITIES=1`;
- no simulation state or tick-order changes;
- no entity registration or registry lookup;
- no save/load changes;
- no model or resource-pack requirement;
- no shader or Metal pipeline change;
- no PebbleLab dependency from the `Pebble` target;
- no metrics, event, or snapshot semantic changes;
- exact selection of `LabCoreAgentEntity`;
- simple wireframe AABB, clearly diagnostic rather than gameplay art;
- removable without affecting entity or simulation code.

The environment variable controls drawing only. It must not create entities.

## 6. Risk Map

| Risk | Severity | Probability | Mitigation | Decision |
| --- | --- | --- | --- | --- |
| Renderer crash from missing model | High | Low with wireframe | Bypass `modelNameFor` and `EntityRendererM`; use existing line helper. | Use Option B. |
| Missing or incorrect model fallback | Medium | High with fake mapping | Do not map the probe to an existing model. | Reject Option C. |
| Shader or pipeline regression | High | Low | Reuse `linePipeline`; add no shader or pipeline. | Keep marker renderer-only. |
| Debug draw performance | Medium | Low initially | Gate by environment, distance-cull, and batch marker boxes into one helper call. | Default off. |
| Golden or screenshot drift | High | Low | App-only path, default off, no model tables or goldens changed. | Never enable in baseline runs. |
| Pebble/PebbleLab coupling | High | Medium | Type-check the PebbleCore probe only; never import PebbleLab into Pebble. | Keep targets separated. |
| Accidental activation | Medium | Low | Require exact environment value `1`; no persisted setting. | Prefer env gate. |
| Marker mistaken for gameplay entity | Medium | Medium | Use conspicuous wireframe color and document debug-only semantics. | No solid model. |
| Unregistered entity incompatibility | High | Medium if app-spawned | Renderer may observe it, but Phase 4.4B must not create or persist it. | Separate injection phase. |
| Save contamination | High | Medium with a spawn command | Do not add `/labprobe`; design transient exclusion before app injection. | Explicitly deferred. |
| Long-term maintenance | Medium | Low | One isolated helper and one startup gate; no resources. | Keep patch removable. |

## 7. Validation

Headless and regression validation for Phase 4.4B:

```sh
cd ~/Dev/pebble-lab
git checkout lab/pebblelab-v1
swift build
swift run -c release PebbleLab -- --scenario core_entity_smoke --seed 42 --ticks 5 --out runs/check_core_entity_after_debug_marker
swift run -c release PebbleLab -- --scenario physical_sync_smoke --seed 42 --ticks 5 --out runs/check_physical_sync_after_debug_marker
swift run -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_debug_marker
swift run -c release PebbleLab -- --scenario agent_smoke --seed 42 --ticks 3 --out runs/check_agent_smoke_after_debug_marker
swift run -c release pebsmoke
git status
```

The normal build compiles the app target. It can also be built explicitly:

```sh
cd ~/Dev/pebble-lab
swift build -c release --product Pebble
```

A realistic visual workflow, after a separate safe app-side probe
injection mechanism exists, would be:

```sh
cd ~/Dev/pebble-lab
PEBBLELAB_DEBUG_ENTITIES=1 PEBBLE_AUTOLOAD=1 PEBBLE_SHOT=/tmp/pebblelab-debug.png@180 swift run -c release Pebble
```

Do not use that workflow until the world is guaranteed disposable
or the probe is excluded from persistence. Visual inspection should confirm a
wireframe box at the probe position and no marker when the environment variable
is absent.

Phase 4.4B Definition of Done:

- marker disabled by default;
- exact env gate works;
- no model, shader, texture, pack, registry, or save changes;
- headless scenarios and `pebsmoke` remain green;
- Pebble app product builds;
- marker helper uses the existing line pipeline;
- no app-side probe spawning is introduced.

Result: complete. `swift build`, all requested PebbleLab scenarios, and all
456 `pebsmoke` checks pass. Visual capture remains deferred because the app has
no safe probe injection lifecycle.

Phase 4.4C documents that lifecycle separately. Its recommendation is to add
and validate explicit chunk-save exclusion before any app-side probe command or
injection is implemented.

## 8. Definition of Done for This Docs-Only Phase

Phase 4.4A is complete when:

- this plan exists;
- `WorldRenderer`, entity model resolution, special render paths, app entry,
  commands, HUD diagnostics, and save behavior have been inspected;
- at least five visibility options are compared;
- Phase 4.4B has a precise implementation and validation contract;
- no renderer, PebbleCore, registry, shader, texture, model, resource pack,
  audio, packaging, save/load, or golden file is modified;
- `swift build` passes;
- `core_entity_smoke`, `physical_sync_smoke`, and `regression_smoke` pass;
- `pebsmoke` reports 456 passed and 0 failed;
- only PebbleLab documentation files are committed and pushed.
