# PebbleLab Development Journal

## 2026-06-19 - Phase 4.8B Terrain Scan Smoke

Branch: `lab/pebblelab-v1`

### Objective

Implement the fixed radius-1 read-only terrain scan specified by Phase 4.8A
for one synchronized PebbleLab agent.

### Files Modified

- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/LabWorldInteraction.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/ROADMAP.md`
- `docs/pebblelab/PHASE_4_TERRAIN_SCAN_PLAN.md`
- `docs/pebblelab/DEV_JOURNAL.md`

### Technical Decisions

- The radius remains a scenario constant equal to `1`.
- The scan uses one fixed Y layer at `agent.position.y - 1`.
- Cells are emitted in nested `dz`, then `dx`, order.
- Each target independently checks loaded and ready state before `getBlock`.
- Missing/unready targets retain absent cell data and fail the smoke; they are
  never decoded as air.
- Per-cell chunk `modified`, `version`, and `dirty` state is compared around
  the guarded read.
- One aggregate event avoids per-cell event volume.
- A 15-check report gates scenario success; its no-mutation check is explicitly
  a code-review contract backed by runtime unchanged-chunk checks.

### Read-Only Guardrails

The implementation does not call block mutation, chunk generation, raycast,
pathfinding, collision, mining, construction, inventory, renderer, registry,
or save/load paths. It remains single-agent and has no configurable radius.

### Validation Commands

The local managed environment required SwiftPM's internal sandbox to be
disabled and module caches redirected under `.build`; the underlying build and
run products are unchanged.

- `swift build --disable-sandbox`
- `swift build --disable-sandbox -c release --product PebbleLab -j 4`
- `swift build --disable-sandbox -c release --product Pebble -j 4`
- `swift run --disable-sandbox -c release PebbleLab -- --scenario terrain_scan_smoke --seed 42 --ticks 5 --out runs/check_terrain_scan_smoke`
- `swift run --disable-sandbox -c release PebbleLab -- --scenario world_observation_multi_smoke --seed 42 --ticks 5 --out runs/check_world_observation_after_terrain_scan`
- `swift run --disable-sandbox -c release PebbleLab -- --scenario regression_smoke --seed 42 --out runs/check_regression_after_terrain_scan`
- `swift run --disable-sandbox -c release pebsmoke`

### Results

- Terrain scan planned/observed/loaded/ready: `9/9/9/9`.
- Radius/order/relation: `1 / dz_then_dx / around_below`.
- Unique chunks/distinct block IDs: `1/1`.
- Chunk state unchanged and final divergence zero.
- Invariant report: `15 passed, 0 failed`.
- Existing world-observation and regression scenarios passed.
- `pebsmoke`: `456 passed, 0 failed`.

### Next Step

Phase 4.8C: terrain scan edge and invariant hardening, followed later by
read-only terrain semantics/traversability planning. Terrain mutation remains
deferred.
