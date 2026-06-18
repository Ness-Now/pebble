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

Next recommended step: validate the gated probe and wireframe marker together
in a disposable app world, including duplicate prevention, cleanup, and a
documented screenshot/manual verification workflow without changing gameplay
or persistence.
