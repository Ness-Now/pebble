# PebbleLab Roadmap

## Phase 3.1 - Nearby Agents Social Perception V0

Status: done and validated.

Goal: abstract agents can observe nearby abstract agents by relative position
and Manhattan distance. This is perception only, not interaction.

## Phase 3.2 - LabGoal/currentGoal V0

Status: done and validated.

Goal: abstract agents choose a deterministic `currentGoal` before selecting an
action. This is not a planner and does not mutate the world.

## Phase 3.3 - health/fear/homePosition V0

Status: done and validated.

Goal: abstract agents track health, fear, and home position without pathfinding,
physical entities, inventory, or social relationships.

## Phase 3.4 - LabInventory Minimal V0

Status: done and validated.

Goal: abstract agents carry a small deterministic string-keyed inventory
without item registries, physical pickup, block interaction, crafting, or
sharing.

## Phase 3.5 - agents_basic Scenario And --agents N

Status: done and validated.

Goal: keep `agent_smoke` as a fixed two-agent validation scenario while adding
`agents_basic` as a configurable deterministic multi-agent simulation scenario.

## Phase 3.6 - Abstract Movement V0

Status: done and validated.

Goal: agents can update abstract positions from selected actions without
pathfinding, PebbleCore entities, collision, gravity, or world mutation.

## Phase 3.7 - Abstract ReturnHome / seekSafety Movement

Status: done and validated.

Goal: agents with `seekSafety` move one abstract X/Z step toward their
`homePosition`, still without pathfinding, collision, physical entities, or
world mutation.

## Phase 3.8 - long_run_smoke And Event Rate Controls

Status: done and validated.

Goal: run longer deterministic abstract-agent simulations while throttling
frequent NDJSON events without changing internal simulation metrics.

## Phase 3.9 - Scenario Success Criteria And Regression Report

Status: done and validated.

Goal: provide a compact `regression_smoke` report with scenario criteria,
key metrics, and pass/fail checks for quick PebbleLab health validation.

## Phase 4.0 - Physical Agent Spike Planning

Status: done and validated.

Goal: plan the first physical-agent spike without implementing entities yet,
including ownership boundaries, PebbleCore risks, integration options, and
required test coverage.

## Phase 4.1 - Physical Agent Placeholder Spawn

Status: done and validated.

Goal: add one opt-in physical-agent placeholder smoke that keeps `LabAgent` as
the abstract cognitive state and introduces physical representation
incrementally through a non-invasive PebbleLab bridge.

## Phase 4.2A - Physical Placeholder Synchronization

Status: done and validated.

Goal: synchronize the PebbleLab-only physical placeholder with abstract
movement after agent actions, still without creating a real PebbleCore entity,
touching registries, modifying existing mobs, or introducing pathfinding.

## Phase 4.2B - Real PebbleCore Entity Feasibility Patch

Status: done and validated as a docs-only feasibility phase.

Goal: evaluate the safest path from PebbleLab-only physical placeholders to a
future real PebbleCore entity without implementing that entity or touching
registries.

## Phase 4.3A - Unregistered LabCoreAgentEntity Probe

Status: done and validated.

Goal: add a minimal unregistered PebbleCore `Entity` subclass that is
constructed directly by PebbleLab, linked to `LabAgent`, added to
`World.entities`, ticked explicitly, and validated headlessly without modifying
`EntityRegistry`, rendering, save/load, or goldens.

## Phase 4.3B - Core Entity Bridge Hardening and Invariant Report

Status: done and validated.

Goal: validate the unregistered core entity probe with a compact report covering
agent and placeholder links, membership in `World.entities`, probe kind, entity
ticks, final divergence, and the direct-construction registry contract.

## Phase 4.4A - Debug Visibility Planning

Status: done and validated as a docs-only phase.

Goal: define a disabled-by-default, renderer-only wireframe marker for
`LabCoreAgentEntity` without model mappings, resource assets, registration, or
simulation changes.

## Phase 4.4B - Renderer-Gated Debug Marker

Status: done and validated.

Goal: render existing `LabCoreAgentEntity` instances as cyan wireframe AABBs
when `PEBBLELAB_DEBUG_ENTITIES=1`, using only `WorldRenderer`'s existing line
pipeline and leaving simulation behavior unchanged.

## Phase 4.4C - App-Side Transient Probe Lifecycle Planning

Status: done and validated as a docs-only phase.

Goal: define how a future app-side probe is explicitly excluded from chunk
saves, gated, and removed from both world entity indexes without registration.

## Phase 4.4D - Explicit Core Entity Save-Exclusion Contract

Status: done and validated.

Goal: keep every existing entity saveable by default while allowing
`LabCoreAgentEntity` to opt out explicitly. Both chunk entity-presence checks
and chunk serialization honor the policy without changing `persistent`.

## Phase 4.4E - Gated App-Side Probe Command and Lifecycle

Status: done and validated.

Goal: provide hidden app-side `status`, gated `spawn`, and unconditional safe
`clear` operations for one transient `LabCoreAgentEntity`. Creation requires
`PEBBLELAB_APP_PROBES=1`; rendering remains independently gated by
`PEBBLELAB_DEBUG_ENTITIES=1`.

## Phase 4.4F - Visual App Validation Workflow

Status: done and manually validated in a disposable world.

Goal: validate the gated probe and wireframe marker together in a disposable
app world, including duplicate prevention, explicit cleanup, and honest
operator-observed results without changing gameplay or persistence.

Observed: both gates enabled, initial count zero, probe `id=715` spawned,
wireframe visible, duplicate rejected, one probe cleared, and final count zero.

## Phase 4.5A - Cleanup Hardening On World Transitions

Status: done and validated.

Goal: centralize probe cleanup through `World.removeEntity` and invoke it when
returning to title, replacing a world, changing dimension, or terminating the
app. Preserve the default-off, unregistered, unsaved probe contract.

## Phase 4.5B - Scripted Screenshot Validation

Status: done and visually validated from an automated app capture.

Goal: use existing autoload, fresh-world, command, capture, and termination
hooks to generate a disposable-world PNG containing the cyan probe marker.

## Phase 4.6A - First Simple Physical Behavior Loop Planning

Status: done and validated.

Goal: close one deterministic headless loop from abstract goal/action and
movement through placeholder and unregistered core-entity synchronization,
with explicit behavior metrics and zero final divergence.

## Phase 4.6B - Multi-Agent Physical Behavior Hardening

Status: done and validated.

Goal: run three deterministic abstract agents with one placeholder and one
unregistered core entity each, then validate link ownership, aggregate
movement metrics, and zero total/max final divergence.

## Phase 4.6C - Multi-Agent Physical Behavior Report And Invariants

Status: done and validated.

Goal: expose the multi-agent ownership, identifier, movement, distance, and
divergence contract in `physical_behavior_invariant_report.json`, and make a
failed report fail the scenario.

## Phase 4.7A - First Simple World Interaction Planning

Status: done and validated as a docs-only phase.

Goal: map PebbleCore's block read and mutation paths, compare six candidate
interactions, and select a loaded, perception-only block observation as the
first safe voxel-world contract.

## Phase 4.7B - Perception-Only Block Observation Smoke

Status: done and validated.

Goal: observe one loaded and ready block below a synchronized agent, decode its
cell deterministically, and prove zero abstract/core divergence and unchanged
chunk state without invoking mutation APIs.

## Phase 4.7C - Multi-Agent Read-Only Observation Smoke

Status: done and validated.

Goal: observe one guarded below-cell for each of three synchronized agents,
aggregate loaded/ready, chunk and block-ID counts, and preserve zero divergence
and unchanged chunk state.

## Phase 4.7D - World Observation Invariant Report

Status: done and validated.

Goal: expose links, guards, relation, block validity, divergence, unchanged
chunk state, and block-ID diversity in a dedicated report that gates scenario
success.

## Phase 4.8A - Terrain Scan Planning

Status: done and validated as a docs-only phase.

Goal: define a single-agent, radius-1, `3x3` read-only scan around the below
cell, with deterministic `dz_then_dx` ordering, per-cell loaded/ready guards,
bounded output, aggregate metrics, and an invariant report contract.

## Phase 4.8B - Bounded Read-Only Terrain Scan Smoke

Status: done and validated.

Goal: scan exactly nine loaded and ready cells around one synchronized agent's
below-cell origin, preserve deterministic `dz_then_dx` order, and gate success
with a dedicated 15-check invariant report.

## Phase 4.8C - Terrain Scan Edge And Invariant Hardening

Status: done and validated.

Goal: reuse the fixed radius-1 scan at agent position `(16,64,16)`, prove the
nine cells cross exactly four preloaded chunks, and add edge-specific boundary
invariants without adding a second scan implementation.

## Phase 4.8D - Terrain Scan Contract Cleanup And Shared Invariant Hardening

Status: done and validated.

Goal: centralize both terrain-scan scenario positions, fixed scan constants,
count expectations, and edge requirements in a small shared contract while
preserving all existing outputs and invariant coverage.

## Phase 4.9A - Read-Only Terrain Semantics Planning

Status: done as a docs-only planning phase.

Goal: define a minimal, deterministic, pure classification contract for
already-observed terrain cells without rereading or mutating the world.

## Phase 4.9B - Terrain Cell Semantic Classification V0

Status: implemented and validated.

Goal: classify the existing nine scan cells into conservative `unknown`,
`air`, `solid`, `liquid`, `plantLike`, or `other` results while preserving raw
scan evidence and deterministic ordering.

## Phase 4.9C - Terrain Semantics Fixture Hardening

Status: implemented and validated.

Goal: cover all semantic classification branches with 21 deterministic,
world-free fixtures and verify both expected kind and reason.

## Phase 4.10A - Terrain Traversability Planning

Status: done as a docs-only planning phase.

Goal: define the support/feet/head evidence and conservative result contract
needed before traversability can be implemented without conflating it with
semantics, pathfinding, collision, or agent actions.

## Phase 4.10B - Terrain Traversability Fixture Smoke

Status: implemented and validated.

Goal: validate the conservative support/feet/head rules with 15 pure synthetic
semantic columns and dedicated fixture/invariant reports.

## Phase 4.11A - Vertical Column Scan Planning

Status: done as a docs-only planning phase.

Goal: define the central-only support/feet/head observation contract, fixed
ordering, 27-cell bounds, layered derivation, outputs, and invariants.

## Phase 4.11B - Terrain Column Scan Smoke

Status: implemented and validated.

Goal: capture nine central support/feet/head columns as 27 guarded read-only
cells, preserve deterministic horizontal and vertical ordering, and audit the
raw evidence with dedicated snapshot, metrics, event, and invariant report.
Semantic and traversability values are derived purely from captured cells and
do not drive agent behavior.

## Phase 4.11C - Terrain Column Scan Edge Smoke

Status: implemented and validated.

Goal: reuse the fixed 9-column/27-cell scan at `(16, y, 16)` and prove guarded
support/feet/head reads across chunks `(0,0)`, `(1,0)`, `(0,1)`, and `(1,1)`.
The edge report extends the shared 18 checks with two boundary-specific checks.

## Phase 4.11D - Terrain Column Scan Contract Cleanup

Status: deferred as optional cleanup; the shared central/edge contract is
already stable enough for fixture-only pathfinding planning.

## Phase 4.12A - Pathfinding Planning

Status: done as a docs-only planning phase.

Goal: define a deterministic, bounded, world-free pathfinding contract while
keeping traversability, search, movement, collision, and agent decisions as
separate layers.

## Phase 4.12B - Terrain Pathfinding Fixture Smoke

Next recommended step: validate bounded BFS over synthetic traversability
grids with fixed north/east/south/west neighbor order. Live pathfinding,
collision, mutation, route following, and agent movement remain out of scope.
