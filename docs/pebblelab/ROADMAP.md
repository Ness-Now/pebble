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

Status: implemented and validated.

Goal: validate bounded deterministic BFS over 12 synthetic traversability
fixtures with fixed north/east/south/west neighbor order, uniform cost, explicit
failure statuses, and dedicated fixture/invariant reports.

## Phase 4.12C - Pathfinding Fixture Hardening And Contract Cleanup

Status: implemented and validated.

Goal: harden the fixture-only BFS contract with missing inputs, unsupported
neighbor mode, non-positive limits, duplicate coordinates, cycles, vertical
separation, and complex equal-path tie-breaking. Twenty fixtures and 23
invariants now cover the bounded search contract.

## Phase 4.13A - Live Pathfinding Integration Planning

Status: done as a docs-only planning phase.

Goal: define a central-only adapter from nine captured column traversability
results into the existing bounded BFS while accepting coherent negative path
statuses and preserving the no-reread/no-movement contract.

## Phase 4.13B - Terrain Pathfinding Column Smoke

Status: implemented and validated.

Goal: map the nine captured central column traversability results to nine
abstract nodes, use fixed center/east start and goal keys, and call the existing
bounded BFS without rereading the world. Seed 42 produces a coherent
`invalidStart` because all nine supports are unsafe; this is accepted audit
evidence rather than hidden by terrain mutation.

## Phase 4.13C - Edge Live Column Pathfinding Smoke

Status: implemented and validated.

Goal: reuse the live column adapter and existing BFS at agent position
`x=16,z=16`, where nine captured columns cross four chunks. The edge run keeps
fixed center/east keys and accepts the coherent `invalidStart` produced by nine
unsafe nodes without modifying terrain or search behavior.

Next recommended step: Phase 4.14A - movement planning docs-only, or Phase
4.13D - positive live pathfinding planning docs-only. Movement, collision,
mutation, multi-agent pathfinding, and route following remain out of scope.

## Phase 4.13D - Positive Live Pathfinding Planning

Status: done as a docs-only planning phase.

Goal: define a bounded deterministic read-only discovery contract for a future
live `found` result without terrain mutation, movement, collision, or a second
BFS. The preferred approach evaluates a small fixed candidate list and audits
the first naturally traversable route.

Next recommended step: Phase 4.13E - positive live column pathfinding smoke.
Movement, collision, mutation, route following, and multi-agent pathfinding
remain out of scope.

## Phase 4.13E - Positive Live Column Pathfinding Smoke

Status: implemented and validated.

Goal: evaluate a fixed bounded candidate list, capture naturally generated
column traversability, and require the existing BFS to return `found`. Candidate
index zero, seed 99 at `(8,8)`, produces a two-node path with fixed center/east
offsets and no terrain mutation.

Next recommended step: Phase 4.14A - movement planning docs-only. Movement,
collision, mutation, route following, and multi-agent pathfinding remain out of
scope.

## Phase 4.14A - Movement Planning

Status: done as a docs-only planning phase.

Goal: separate path evidence, movement intent, abstract movement execution,
collision, and agent decisions before any live displacement. The first movement
phase remains fixture-only and consumes synthetic paths without `World` or real
agents.

Next recommended step: Phase 4.14B - terrain path movement fixture smoke. Live
movement, collision, mutation, route following, and multi-agent movement remain
out of scope.

## Phase 4.14B - Terrain Path Movement Fixture Smoke

Status: implemented and validated.

Goal: validate pure synthetic path movement with one horizontal path edge per
tick, explicit goal completion, stable post-goal ticks, and strict rejection of
empty, repeated, diagonal, vertical, non-neighbor, and misaligned paths.

Next recommended step: Phase 4.14C - movement fixture hardening and contract
cleanup, followed by Phase 4.15A - live movement integration planning docs-only.
Live movement, collision, mutation, and route following remain out of scope.

## Phase 4.14C - Movement Fixture Hardening And Contract Cleanup

Status: implemented and validated.

Goal: harden synthetic movement with manually constructed inconsistent states,
explicit denied-intent reasons, terminal-state stability, exact target-index
progression, partial progress, and direction-delta auditing. Twenty-two fixtures
and 25 invariants now cover the movement contract.

Next recommended step: Phase 4.15A - live movement integration planning
docs-only. Live movement, collision, mutation, route following, and multi-agent
movement remain out of scope.

## Phase 4.15A - Live Movement Integration Planning

Status: done as a docs-only planning phase.

Goal: connect positive live path provenance to the validated abstract movement
state machine without displacing a live agent, performing collision, mutating
the world, or introducing gameplay route following.

Next recommended step: Phase 4.15B - terrain path live movement smoke.
Collision, physical displacement, mutation, route following, and multi-agent
movement remain out of scope.

## Phase 4.15B - Terrain Path Live Movement Smoke

Status: implemented and validated.

Goal: consume the existing positive live path evidence in the hardened abstract
movement state machine. Candidate index zero, seed 99 at `(8,8)`, supplies the
two-node path `(8,64,8) -> (9,64,8)`; one value-state step reaches the goal
without displacing an agent, performing collision, or mutating the world.

Next recommended step: Phase 4.15C - live movement adapter hardening without
collision, or Phase 4.16A - collision planning docs-only. Collision, physical
displacement, mutation, gameplay route following, and multi-agent movement
remain out of scope.

## Phase 4.15C - Live Movement Adapter Hardening Without Collision

Status: implemented and validated.

Goal: audit positive-candidate provenance, exact selected-path consumption,
initial movement state, step and summary agreement, intent reasons, contractual
false safety flags, and rejection of absent or invalid positive evidence. The
live movement report now passes 28 checks without adding another scenario.

Next recommended step: Phase 4.16A - collision planning docs-only, or Phase
4.15D - live movement failure-case fixtures without collision. Collision,
physical displacement, mutation, gameplay route following, and multi-agent
movement remain out of scope.

## Phase 4.16A - Collision Planning Docs-Only

Status: done as a docs-only planning phase.

Goal: define the boundary between abstract traversability and physical body
occupancy, propose a conservative `0.6 x 1.8` LabHuman body, reserve `blocked`
for explicit collision evidence, and stage fixture/live read-only collision
validation before any real displacement.

Collision is not implemented. Physical displacement, route following,
mutation, physics integration, and multi-agent movement remain out of scope.

Next recommended step: Phase 4.16B - Collision Fixture Smoke.

## Phase 4.16B - Collision Fixture Smoke

Status: implemented and validated.

Goal: add a fixture-only terrain collision and occupancy contract for a
future `LabHuman` body without `World`, chunks, agents, movement runtime,
pathfinding, displacement, or mutation. Nineteen synthetic support/feet/head
fixtures cover occupable, blocked, unsupported, vertical-space occupied,
liquid unsupported, unknown, out-of-bounds, not-loaded, and not-ready results.

Live collision, physical displacement, route following, world mutation, physics
integration, and multi-agent movement remain out of scope.

Next recommended step: Phase 4.16C - Collision Live Read-Only Smoke.

## Phase 4.16C - Collision Live Read-Only Smoke

Status: implemented and validated.

Goal: read exactly one live candidate node in a bounded read-only pass, adapt
support/feet/head samples into the fixture collision evaluator, and produce a
deterministic occupancy result without movement, pathfinding, displacement,
route following, physics, or mutation.

The smoke samples node `(8,64,8)` with seed 42. Support is water, feet/head are
air, so collision v0 returns `liquidUnsupported` with reason `liquid_support`.
This is accepted because the phase proves read-only evidence and explicit
occupancy classification, not physical movement.

Physical displacement, route following, mutation, physics integration, and
multi-agent movement remain out of scope.

Next recommended step: Phase 4.17A - Physical Movement Integration Planning
Docs-Only.

## Phase 4.17A - Physical Movement Integration Planning Docs-Only

Status: done as a docs-only planning phase.

Goal: define the future boundary for one single-step physical displacement
decision that combines positive live path evidence, abstract movement intent,
and read-only live collision occupancy. The phase plans approval and denial
contracts, future snapshots, invariants, metrics, and events without modifying
Swift code or moving any agent, physical placeholder, or core entity.

The plan requires destination collision status `occupable` before any future
approved displacement. Non-occupable statuses such as `liquidUnsupported`,
`blocked`, `unknown`, `notLoaded`, `notReady`, `unsupported`,
`verticalSpaceOccupied`, and `outOfBounds` must deny physical movement while
leaving all positions unchanged.

Physical displacement, route following, mutation, physics integration,
multi-agent movement, avoidance, and reservation tables remain out of scope for
this phase. The first approved physical move should come only after an audited
denied smoke or after a reliable occupable destination is identified.

Next recommended step: Phase 4.17B1 - Denied Physical Movement Smoke.

## Phase 4.17B1 - Denied Physical Movement Smoke

Status: implemented and validated.

Goal: prove that physical movement integration refuses a single-step attempt
when live collision marks the destination non-occupable. The scenario attempts
`(7,64,8) -> (8,64,8)` and reuses live collision evidence for node `(8,64,8)`;
water support returns `liquidUnsupported`, so the integration status is
`collisionDenied` and `displacementApplied` remains false.

The smoke writes `physical_movement_integration_snapshot.json`,
`physical_movement_integration_invariant_report.json`, `physicalMovement*`
metrics, and one `lab_physical_movement_integration_recorded` event. Abstract
and physical placeholder positions remain unchanged, divergence stays zero,
and no core entity is created for this denied case to avoid world entity
mutation.

Route following, multi-agent movement, avoidance, reservation tables, physics
integration, gravity, velocity, jump, fall, swim, climb, mining, construction,
inventory behavior, world mutation, terrain mutation, and gameplay movement
remain out of scope.

Next recommended step: Phase 4.17B2A - Find Occupable Live Destination Smoke,
or Phase 4.17B2 - Approved Single-Step Physical Displacement Smoke once a
reliable occupable destination is identified.

## Phase 4.17B2A - Find Occupable Live Destination Smoke

Status: implemented and validated.

Goal: find a reliable live destination with collision status `occupable`
before attempting an approved physical displacement. The scenario evaluates a
small deterministic candidate list: seed 42 at `(8,64,8)` preserves the current
`liquidUnsupported` evidence, then seed 99 at `(8,64,8)` supplies the first
occupable destination with grass support and empty feet/head space.

The smoke writes `physical_movement_occupable_search_snapshot.json`,
`physical_movement_occupable_search_invariant_report.json`,
`physicalMovementOccupableSearch*` metrics, and one
`lab_physical_movement_occupable_search_recorded` event. It does not move any
agent, physical placeholder, or core entity; it does not call movement,
pathfinding, route following, physics, or mutation code.

Physical displacement, route following, multi-agent movement, physics
integration, mutation, avoidance, and reservation tables remain out of scope.

Next recommended step: Phase 4.17B2 - Approved Single-Step Physical
Displacement Smoke.

## Phase 4.17B2 - Approved Single-Step Physical Displacement Smoke

Status: implemented and validated.

Goal: apply exactly one approved physical displacement after live collision
evidence proves the destination is occupable. The scenario uses seed 99
collision evidence for destination `(8,64,8)`, attempts `(7,64,8) ->
(8,64,8)`, moves one local abstract `agent_0`, syncs one physical placeholder,
and verifies divergence remains zero.

The smoke writes `physical_movement_integration_snapshot.json`,
`physical_movement_integration_invariant_report.json`, `physicalMovement*`
metrics, and one `lab_physical_movement_integration_recorded` event. It does
not create a core entity for this first approved smoke, and it does not perform
pathfinding, route following, physics integration, terrain mutation, world
mutation, or multi-agent movement.

Route following, multi-agent movement, avoidance, reservation tables, physics
integration, terrain mutation, gameplay movement, mining, construction, and
inventory behavior remain out of scope.

Next recommended step: Phase 4.17C - Single-Step Displacement Hardening.

## Phase 4.17C - Single-Step Displacement Hardening

Status: implemented and validated.

Goal: harden the single-step physical displacement contract across approved
and denied cases before any route following. The scenario
`physical_movement_single_step_hardening_smoke` covers approved movement,
non-occupable denial, source mismatch, diagonal denial, vertical denial,
missing physical handle, divergence before move, and stale collision evidence.

The smoke writes `physical_movement_single_step_hardening_report.json`,
`physical_movement_single_step_hardening_invariant_report.json`,
`physicalMovementHardening*` metrics, and one
`lab_physical_movement_single_step_hardening_recorded` event. Exactly one case
applies displacement; all denied cases leave abstract and physical positions
unchanged.

Route following, dynamic replanning, multi-agent movement, avoidance,
reservation tables, physics integration, terrain mutation, world mutation, and
gameplay movement remain out of scope.

Next recommended step: Phase 4.18A - Route Following Planning Docs-Only.

## Phase 4.18A - Route Following Planning Docs-Only

Status: done as a docs-only planning phase.

Goal: define the future route following contract before any multi-step movement
is implemented. The plan keeps route following as an orchestration layer over
the existing single-step adapter: each route edge must be contiguous,
4-neighbor, same-y for v0, collision-checked, and applied only through the
single-step physical movement contract.

The plan proposes future route snapshots, per-edge records, invariant reports,
`routeFollowing*` metrics, and one aggregate
`lab_route_following_recorded` event. It also defines stop states for collision
denial, invalid edge, source mismatch, divergence, missing handles, stale path
or collision evidence, max steps, and unexpected mutation.

Route following is not implemented yet. Multi-step movement, dynamic
replanning, pathfinding inside a follower, goal selection, multi-agent
movement, avoidance, reservation tables, physics integration, terrain mutation,
world mutation, and gameplay route following remain out of scope.

Next recommended step: Phase 4.18B - Route Following Fixture Smoke.

## Phase 4.18B - Route Following Fixture Smoke

Status: implemented and validated.

Goal: add a fixture-only route following smoke over synthetic routes. The
scenario `route_following_fixture_smoke` validates route index progression,
no skipped nodes, stop-on-first-denied-edge, completed-only-at-last-node, and
displacement gates requiring occupable collision plus approved single-step
status.

The smoke writes `route_following_fixture_report.json`,
`route_following_fixture_invariant_report.json`, `routeFollowingFixture*`
metrics, and one `lab_route_following_fixture_recorded` event. It covers one
completed two-edge route and seven stopped routes: collision denial, diagonal
invalid edge, vertical invalid edge, source mismatch, divergence, max steps,
and stale collision evidence.

Live route following, approved live multi-step movement, dynamic replanning,
pathfinding inside a follower, multi-agent movement, avoidance, reservation
tables, physics integration, terrain mutation, world mutation, and gameplay
route following remain out of scope.

Next recommended step: Phase 4.18C - Route Following Denied Live Smoke.

## Phase 4.18C - Route Following Denied Live Smoke

Status: implemented and validated.

Goal: add the first live route following smoke as an expected collision-denied
stop. The scenario `route_following_denied_live_smoke` uses a short route
`(7,64,8) -> (8,64,8)` under seed 42. It checks live read-only collision for
the destination before displacement and stops immediately because the
destination is `liquidUnsupported` with reason `liquid_support`.

The smoke writes `route_following_live_snapshot.json`,
`route_following_live_invariant_report.json`, `routeFollowingLive*` metrics,
and one `lab_route_following_recorded` event. It attempts one edge, completes
zero edges, applies zero displacements, records one denied edge, preserves the
last valid abstract and physical positions, and keeps divergence at zero.

Approved live multi-step route following, long route following, dynamic
replanning, pathfinding inside a follower, goal selection, multi-agent
movement, avoidance, reservation tables, physics integration, terrain
mutation, world mutation, and gameplay route following remain out of scope.

Next recommended step: Phase 4.18D - Route Following Approved Two-Step Smoke.

## Phase 4.18D - Route Following Approved Two-Step Smoke

Status: implemented and validated.

Goal: add the first approved live route following smoke over exactly two
edges. The scenario `route_following_approved_two_step_smoke` uses seed 99
collision evidence for route `(7,64,8) -> (8,64,8) -> (9,64,8)`. Both
destinations are collision status `occupable` with reason
`full_cube_support_empty_body_volume`.

The smoke writes `route_following_live_snapshot.json`,
`route_following_live_invariant_report.json`, `routeFollowingLive*` metrics,
and one `lab_route_following_recorded` event. It attempts two edges, completes
two edges, applies two displacements, records zero denied edges, reaches
`(9,64,8)`, and keeps abstract/physical divergence at zero.

Long route following, gameplay route following, dynamic replanning,
pathfinding inside a follower, goal selection, multi-agent movement,
avoidance, reservation tables, physics integration, terrain mutation, and
world mutation remain out of scope.

Next recommended step: Phase 4.18E - Route Following Hardening.

## Phase 4.18E - Route Following Hardening

Status: implemented and validated.

Goal: harden live route following with a bounded set of completed and stopped
cases before any longer route or gameplay follower work. The scenario
`route_following_live_hardening_smoke` runs 8 cases: completed two-step,
collision denied first edge, invalid diagonal edge, invalid vertical edge,
source mismatch, divergence after the first edge, stale collision evidence,
and max steps.

The smoke writes `route_following_live_hardening_report.json`,
`route_following_live_hardening_invariant_report.json`,
`routeFollowingLiveHardening*` metrics, and one
`lab_route_following_live_hardening_recorded` event. It records 8 passed
cases, 0 failed cases, 1 completed case, 7 stopped cases, 9 attempted edges,
4 completed edges, 4 displacements applied, and 5 denied edges.

The hardening harness reuses the existing live route following and collision
snapshot types. Some stop cases are controlled near-live snapshots that inject
source mismatch, divergence, stale collision, invalid edge, or max-step
conditions without mutating terrain/world state and without creating a core
entity.

Long route following, gameplay route following, dynamic replanning,
pathfinding inside a follower, goal selection, multi-agent movement,
avoidance, reservation tables, physics integration, terrain mutation, world
mutation, save/load changes, and registry changes remain out of scope.

Next recommended step: Phase 4.19A - Multi-Agent Movement Planning Docs-Only.

## Phase 4.19A - Multi-Agent Movement Planning Docs-Only

Status: done as a docs-only planning phase.

Goal: define the future multi-agent movement planning contract before any
multi-agent movement implementation exists. The plan keeps single-agent route
following as an intent source, introduces a future deterministic arbiter
boundary, and documents same-destination, occupied-destination, swap, cycle,
source-mismatch, stale-intent, priority, and dependency conflicts.

The plan proposes future movement intent and resolution records,
`multi_agent_movement_*` reports, `multiAgentMovement*` metrics, one aggregate
`lab_multi_agent_movement_recorded` event, and global invariants for
deterministic ordering, partial approval, no duplicate approved destination,
no approved swaps, no pathfinding inside arbitration, no replanning, no
physics, and no world or terrain mutation.

Multi-agent movement is not implemented yet. Reservation table runtime,
avoidance, dynamic replanning, pathfinding during arbitration, multi-agent
pathfinding, gameplay movement, physics integration, renderer changes,
save/load changes, registry changes, Python, LLM, and RL remain out of scope.

Next recommended step: Phase 4.19B - Multi-Agent Movement Fixture Smoke.

## Phase 4.19B - Multi-Agent Movement Fixture Smoke

Status: implemented and validated.

Goal: add the first fixture-only multi-agent movement arbitration smoke over
synthetic agents, synthetic positions, and synthetic next-edge intentions. The
scenario `multi_agent_movement_fixture_smoke` validates deterministic
stable-`agentId` arbitration without creating or using `World`.

The smoke covers two agents approved to different destinations,
same-destination conflict, occupied static destination, swap conflict, source
mismatch, stale intent, missing agent, and invalid edge. It writes
`multi_agent_movement_fixture_report.json`,
`multi_agent_movement_fixture_invariant_report.json`,
`multiAgentMovementFixture*` metrics, and one aggregate
`lab_multi_agent_movement_fixture_recorded` event.

Live collision, live physical movement, route following live, reservation
table runtime, avoidance, dynamic replanning, route repair, physics,
save/load changes, and gameplay movement remain out of scope.

Next recommended step: Phase 4.19C - Multi-Agent Movement Fixture Hardening.

## Phase 4.19C - Multi-Agent Movement Fixture Hardening

Status: implemented and validated.

Goal: harden the fixture-only multi-agent movement arbiter with more
adversarial synthetic intent sets before any live collision, physical
movement, reservation runtime, avoidance, replanning, or gameplay movement.

The scenario `multi_agent_movement_fixture_hardening_smoke` covers unordered
same-destination intents, duplicate intents for one agent, a three-agent
cycle, chain dependency, moving-away destination, vertical invalid edge,
zero-length edge, all-denied mixed reasons, empty-intents no-op, and a
fixture-only max-agent bound. It writes
`multi_agent_movement_fixture_hardening_report.json`,
`multi_agent_movement_fixture_hardening_invariant_report.json`,
`multiAgentMovementFixtureHardening*` metrics, and one aggregate
`lab_multi_agent_movement_fixture_hardening_recorded` event.

Live collision, live physical movement, reservation table runtime, avoidance,
dynamic replanning, route repair, physics, save/load, social behavior, and
gameplay movement remain out of scope.

Next recommended step: Phase 4.19D - Multi-Agent Live Read-Only Collision
Intent Smoke.

## Phase 4.19D - Multi-Agent Live Read-Only Collision Intent Smoke

Status: implemented and validated.

Goal: bridge fixture-only multi-agent arbitration to future live physical
multi-agent movement by reading live collision evidence for synthetic
multi-agent edge intentions without applying any displacement.

The scenario `multi_agent_live_collision_intent_smoke` covers an occupable
destination approval intent, two non-conflicting occupable destination
approval intents, a non-occupable destination denied by live collision, a
same-destination conflict after occupable collision evidence, source mismatch
skipping collision, invalid edge skipping collision, and stale intent skipping
collision. It writes `multi_agent_live_collision_intent_report.json`,
`multi_agent_live_collision_intent_invariant_report.json`,
`multiAgentLiveCollisionIntent*` metrics, and one aggregate
`lab_multi_agent_live_collision_intent_recorded` event.

Live physical movement application, physical placeholder movement, core
entity movement, route following live, single-step physical movement apply,
reservation table runtime, avoidance, dynamic replanning, route repair,
physics, save/load, social behavior, communication, and gameplay movement
remain out of scope.

Next recommended step: Phase 4.19E - Multi-Agent Approved Physical Movement
Smoke.

## Phase 4.19E - Multi-Agent Approved Physical Movement Smoke

Status: implemented and validated.

Goal: apply the first controlled multi-agent physical placeholder movement
after fixture arbitration and live read-only collision intent evidence. The
phase is approved-only: two agents, two distinct occupable destinations, one
edge per agent, no conflicts, and no denied live movement.

The scenario `multi_agent_approved_physical_movement_smoke` covers a nominal
two-agent approved single-step case and an unordered-input deterministic case.
Both cases use seed 99 live collision evidence, move `agent_0` from
`(7,64,8)` to `(8,64,8)`, move `agent_1` from `(9,64,7)` to `(9,64,8)`,
sync the physical placeholders to the abstract positions, and keep
divergence at zero. It writes
`multi_agent_approved_physical_movement_report.json`,
`multi_agent_approved_physical_movement_invariant_report.json`,
`multiAgentApprovedPhysicalMovement*` metrics, and one aggregate
`lab_multi_agent_approved_physical_movement_recorded` event.

Denied live multi-agent movement, live conflict hardening, reservation table
runtime, avoidance, dynamic replanning, route repair, physics, save/load,
social behavior, communication, and gameplay movement remain out of scope.

Next recommended step: Phase 4.19F - Multi-Agent Movement Hardening.

## Phase 4.19F - Multi-Agent Movement Hardening

Status: implemented and validated.

Goal: harden live multi-agent physical movement beyond the approved-only
smoke by covering controlled refusals, partial approval, and live conflict
cases without turning the harness into gameplay movement.

The scenario `multi_agent_movement_hardening_smoke` covers approved two-agent
movement, live collision denial, partial approval, same-destination live
conflict, swap conflict, source mismatch, stale intent, invalid edge,
divergence before movement, stale collision evidence, all-denied mixed
reasons, and a hardening-only max-agent bound. It writes
`multi_agent_movement_hardening_report.json`,
`multi_agent_movement_hardening_invariant_report.json`,
`multiAgentMovementHardening*` metrics, and one aggregate
`lab_multi_agent_movement_hardening_recorded` event.

The hardening scenario records 12 cases, 12 passed, 0 failed, 4 approved
resolutions, 18 denied resolutions, 4 displacements applied, 3 collision
denials, 1 same-destination conflict, 2 swap denials, 1 stale collision
denial, and 5 max-agent denials. Denied abstract and physical positions are
preserved. Approved abstract and physical positions move exactly one
4-neighbor same-y edge and finish synchronized.

Reservation table runtime, avoidance, dynamic replanning, route repair,
physics, save/load, social behavior, gameplay movement, and long-running
multi-agent navigation remain out of scope.

Next recommended step: Phase 4.20A - Multi-Agent Movement Integration
Planning Docs-Only.

## Phase 4.20A - Multi-Agent Movement Integration Planning Docs-Only

Status: done as a docs-only planning phase.

Goal: define the future integration boundary that will connect the validated
4.19 multi-agent movement smokes into one tick-level movement contract
without yet implementing runtime integration.

The plan creates
`docs/pebblelab/PHASE_4_MULTI_AGENT_MOVEMENT_INTEGRATION_PLAN.md`. It
summarizes the validated 4.19A-F contracts, identifies the integration
problem, and proposes layered ownership for agent decision, intent
collection, arbitration, live collision evidence, movement application,
feedback, and reporting.

The proposed future tick contract includes `LabMultiAgentMovementTickInput`,
`LabMultiAgentMovementTickOutput`, `LabMultiAgentMovementTickSummary`, and
`LabMovementFeedback` shapes. It also defines boundary rules, a feedback
policy, future `multi_agent_movement_tick_*` outputs,
`multiAgentMovementTick*` metrics, one aggregate
`lab_multi_agent_movement_tick_recorded` event, and tick-level invariants.

Runtime integration is not implemented yet. Autonomous agent movement,
repeated tick loops, long-running navigation, reservation table runtime,
avoidance, steering, dynamic replanning, pathfinding, route repair, route
following long, goal selection, memory updates, social behavior,
communication, physics, terrain/world mutation, save/load changes, registry
changes, and gameplay movement remain out of scope.

Next recommended step: Phase 4.20B - Multi-Agent Movement Tick Fixture
Smoke.

## Phase 4.20B - Multi-Agent Movement Tick Fixture Smoke

Status: implemented and validated.

Goal: instantiate the first integrated multi-agent movement tick contract as
a fixture-only scenario, with synthetic abstract positions, synthetic
physical positions, unordered movement intentions, deterministic
arbitration, tick output, structured feedback, reports, metrics, and one
aggregate event.

The scenario `multi_agent_movement_tick_fixture_smoke` builds one tick with
four agents and four intentionally unordered intents. It approves `agent_0`
and `agent_2`, denies `agent_1` for the same-destination conflict, and
denies `agent_3` for an invalid vertical edge. The resolutions are sorted by
stable `agentId`, feedback is produced for every resolution, and positions
remain unchanged because no movement is applied in this fixture phase.

It writes `multi_agent_movement_tick_fixture_report.json`,
`multi_agent_movement_tick_fixture_invariant_report.json`,
`multi_agent_movement_tick_fixture_feedback.json`,
`multiAgentMovementTickFixture*` metrics, and one aggregate
`lab_multi_agent_movement_tick_fixture_recorded` event.

Live collision, physical application, reservation runtime, avoidance,
dynamic replanning, route repair, pathfinding, route following, physics,
save/load, social behavior, communication, gameplay movement, and
terrain/world mutation remain out of scope.

Next recommended step: Phase 4.20C - Multi-Agent Movement Tick Live
Read-Only Smoke.

## Phase 4.20C - Multi-Agent Movement Tick Live Read-Only Smoke

Status: implemented and validated.

Goal: add live read-only collision evidence to the tick-level multi-agent
movement contract without applying movement. The scenario keeps synthetic
abstract and physical positions, unordered intents, stable `agentId`
resolution ordering, structured feedback, and unchanged positions.

The scenario `multi_agent_movement_tick_live_readonly_smoke` creates one
tick with five agents and five intentionally unordered intents. Two intents
read occupable live collision evidence and are approved for movement without
displacement. One intent reads non-occupable live evidence and is denied by
collision. One source mismatch and one invalid vertical edge are denied
before collision is read.

It writes `multi_agent_movement_tick_live_readonly_report.json`,
`multi_agent_movement_tick_live_readonly_invariant_report.json`,
`multi_agent_movement_tick_live_readonly_feedback.json`,
`multiAgentMovementTickLiveReadonly*` metrics, and one aggregate
`lab_multi_agent_movement_tick_live_readonly_recorded` event.

Physical application in the tick loop, reservation runtime, avoidance,
dynamic replanning, route repair, route following, pathfinding, physics,
save/load, social behavior, communication, gameplay movement, and
terrain/world mutation remain out of scope.

Next recommended step: Phase 4.20D - Multi-Agent Movement Tick Approved
Application Smoke.

## Phase 4.20D - Multi-Agent Movement Tick Approved Application Smoke

Status: implemented and validated.

Goal: apply the first integrated tick-level approved multi-agent movement in a
controlled two-agent case. The scenario keeps unordered intents, stable
`agentId` resolution ordering, live occupable collision evidence, one edge per
agent, synchronized abstract/physical final positions, and `moved` feedback.

The scenario `multi_agent_movement_tick_approved_application_smoke` creates
one tick with two agents and two intentionally unordered intents. Both
destinations are live occupable, both intents are approved, both movements are
applied, and `displacementsApplied` is 2. Divergence before and after remains
0.

It writes `multi_agent_movement_tick_approved_application_report.json`,
`multi_agent_movement_tick_approved_application_invariant_report.json`,
`multi_agent_movement_tick_approved_application_feedback.json`,
`multiAgentMovementTickApprovedApplication*` metrics, and one aggregate
`lab_multi_agent_movement_tick_approved_application_recorded` event.

Denied tick application, partial approval tick hardening, reservation runtime,
avoidance, dynamic replanning, route repair, route following, pathfinding,
physics, save/load, social behavior, communication, gameplay movement, and
terrain/world mutation remain out of scope.

Next recommended step: Phase 4.20E - Multi-Agent Movement Tick Hardening.

## Phase 4.20E - Multi-Agent Movement Tick Hardening

Status: implemented and validated.

Goal: harden the integrated tick-level multi-agent movement contract by
bringing approved movement, denied collision, partial approval,
same-destination conflicts, swap conflicts, source mismatch, stale intent,
invalid edges, divergence denial, stale collision evidence, all-denied mixed
reasons, and the max-agent bound into one tick-level report shape.

The scenario `multi_agent_movement_tick_hardening_smoke` reuses the validated
multi-agent hardening movement semantics and wraps each case in tick
input/output, resolution, and feedback records. It preserves stable `agentId`
ordering, produces feedback for every resolution, applies only approved
movements, preserves denied abstract/physical positions, and keeps approved
abstract/physical final positions synchronized.

It writes `multi_agent_movement_tick_hardening_report.json`,
`multi_agent_movement_tick_hardening_invariant_report.json`,
`multi_agent_movement_tick_hardening_feedback.json`,
`multiAgentMovementTickHardening*` metrics, and one aggregate
`lab_multi_agent_movement_tick_hardening_recorded` event.

Autonomous intent production, repeated tick loops, reservation runtime,
avoidance, dynamic replanning, route repair, route following, pathfinding,
physics, save/load, social behavior, communication, gameplay movement, and
terrain/world mutation remain out of scope.

Next recommended step: Phase 4.21A - Agent Intent Production Planning
Docs-Only.

## Phase 4.21A - Agent Intent Production Planning Docs-Only

Status: implemented and validated.

Goal: document how PebbleLab can later move from scenario-created synthetic
movement intentions to agent-produced `LabAgentMoveIntent` values while
keeping movement, collision, arbitration, feedback, and reporting ownership
separate.

The document `PHASE_4_AGENT_INTENT_PRODUCTION_PLAN.md` defines the future
agent observation layer, intent policy layer, intent validation layer, tick
collection layer, movement tick layer, and feedback consumption boundary. It
also proposes future context/proposal/result types, a conservative v0 policy,
future outputs, metrics, event, invariants, scenario sequence, and risks.

The agent intent runtime is not implemented yet. Autonomous movement, goal
selection, pathfinding, route planning, replanning, avoidance, reservation
runtime, feedback consumption, memory updates, repeated tick loops, physics,
save/load, social behavior, communication, LLM/Python/RL, gameplay behavior,
and terrain/world mutation remain out of scope.

Next recommended step: Phase 4.21B - Agent Intent Production Fixture Smoke.

## Phase 4.21B - Agent Intent Production Fixture Smoke

Status: implemented and validated.

Goal: add the first fixture-only production path from agent contexts to
policy proposals to accepted `LabAgentMoveIntent` values, without invoking
tick movement, live collision, movement application, feedback consumption, or
agent memory/goal mutation.

The scenario `agent_intent_production_fixture_smoke` creates five synthetic
contexts in intentionally unordered input order. The deterministic v0 policy
produces five sorted proposals: two accepted `wander_fixture` one-edge same-y
move intents, one `idle` `noIntent`, one missing-position `invalidContext`,
and one invalid vertical proposal rejected by validation. The two accepted
intents intentionally target the same destination and are left for later tick
arbitration.

It writes `agent_intent_production_fixture_report.json`,
`agent_intent_production_fixture_invariant_report.json`,
`agent_intent_proposals.json`, `agentIntentProductionFixture*` metrics, and
one aggregate `lab_agent_intent_production_fixture_recorded` event.

Tick integration, live collision, movement application, feedback
consumption, memory update, goal selection, pathfinding, replanning,
avoidance, reservation runtime, physics, save/load, social behavior,
communication, gameplay movement, and terrain/world mutation remain out of
scope.

Next recommended step: Phase 4.21C - Agent Intent Production Hardening.

## Phase 4.21C - Agent Intent Production Hardening

Status: implemented and validated.

Goal: harden fixture-only agent intent production without feeding produced
intents into the tick movement contract. The scenario keeps policy,
validation, proposals, accepted intents, rejected proposals, reports,
metrics, and events in the intent-production layer.

The scenario `agent_intent_production_hardening_smoke` covers 10 cases:
baseline fixture compatibility, duplicate agent contexts, duplicate
proposals, invalid diagonal proposals, zero-length proposals, stale
proposals, wrong-source proposals, max proposal bounds, deterministic hint
ordering, and unknown role `noIntent`.

It writes `agent_intent_production_hardening_report.json`,
`agent_intent_production_hardening_invariant_report.json`,
`agent_intent_proposals.json`, `agentIntentProductionHardening*` metrics, and
one aggregate `lab_agent_intent_production_hardening_recorded` event.

Tick integration, live collision, movement application, feedback
consumption, memory update, goal selection, pathfinding, replanning,
avoidance, reservation runtime, physics, save/load, social behavior,
communication, gameplay movement, and terrain/world mutation remain out of
scope.

Next recommended step: Phase 4.21D - Agent Intent To Tick Fixture
Integration Smoke.

## Phase 4.21D - Agent Intent To Tick Fixture Integration Smoke

Status: implemented and validated.

Goal: connect fixture-only agent intent production to the fixture-only
multi-agent movement tick contract without live collision, movement
application, feedback consumption, memory updates, goals, pathfinding,
replanning, avoidance, reservation runtime, physics, or terrain/world
mutation.

The scenario `agent_intent_to_tick_fixture_smoke` produces four sorted
policy proposals from intentionally unordered contexts. Two valid
`wander_fixture` proposals become accepted intents and intentionally target
the same destination. The production layer leaves that conflict unresolved,
then the tick fixture layer receives the accepted intents, approves
`agent_0`, denies `agent_1` with `deniedSameDestinationConflict`, and emits
`approvedForMovement` / `blockedByAgentConflict` feedback with positions
unchanged and zero displacements.

It writes `agent_intent_to_tick_fixture_report.json`,
`agent_intent_to_tick_fixture_invariant_report.json`,
`agent_intent_to_tick_fixture_proposals.json`,
`agentIntentToTickFixture*` metrics, and one aggregate
`lab_agent_intent_to_tick_fixture_recorded` event.

Live collision, movement application, feedback consumption, memory update,
goal selection, pathfinding, replanning, avoidance, reservation runtime,
physics, save/load, social behavior, communication, gameplay movement, and
terrain/world mutation remain out of scope.

Next recommended step: Phase 4.21E - Agent Intent To Tick Live Read-Only
Smoke.

## Phase 4.21E - Agent Intent To Tick Live Read-Only Smoke

Status: implemented and validated.

Goal: connect agent intent production to tick live read-only collision
evidence without applying movement, consuming feedback, updating memory or
goals, pathfinding, replanning, avoidance, reservation runtime, physics, or
terrain/world mutation.

The scenario `agent_intent_to_tick_live_readonly_smoke` creates five
contexts, produces three accepted one-edge same-y intents, rejects one idle
proposal and one invalid vertical proposal, then feeds the accepted intents
into the tick live read-only contract. Production remains collision-blind.
The tick layer reads controlled live collision evidence, approves two
occupable destinations, denies one non-occupable destination with
`deniedCollision`, emits `approvedForMovement` / `blockedByCollision`
feedback, and preserves all positions with zero displacements.

It writes `agent_intent_to_tick_live_readonly_report.json`,
`agent_intent_to_tick_live_readonly_invariant_report.json`,
`agent_intent_to_tick_live_readonly_proposals.json`,
`agentIntentToTickLiveReadonly*` metrics, and one aggregate
`lab_agent_intent_to_tick_live_readonly_recorded` event.

Movement application, feedback consumption, memory update, goal selection,
pathfinding, replanning, avoidance, reservation runtime, physics, save/load,
social behavior, communication, gameplay movement, and terrain/world
mutation remain out of scope.

Next recommended step: Phase 4.21F - Agent Intent To Tick Approved
Application Smoke.

## Phase 4.21F - Agent Intent To Tick Approved Application Smoke

Status: implemented and validated.

Goal: connect agent intent production to tick approved application so
agent-produced intents can be approved by live collision evidence and applied
through the controlled one-edge movement contract.

The scenario `agent_intent_to_tick_approved_application_smoke` creates five
contexts, produces three accepted one-edge same-y intents, rejects one idle
proposal and one invalid vertical proposal, then feeds the accepted intents
into the tick approved application contract. Production remains
collision-blind and does not apply movement. The tick layer reads controlled
live collision evidence, approves two occupable destinations, denies one
non-occupable destination with `deniedCollision`, applies exactly two
approved moves, emits `moved` / `blockedByCollision` feedback, preserves the
denied agent position, and keeps abstract/physical divergence at zero.

It writes `agent_intent_to_tick_approved_application_report.json`,
`agent_intent_to_tick_approved_application_invariant_report.json`,
`agent_intent_to_tick_approved_application_proposals.json`,
`agentIntentToTickApprovedApplication*` metrics, and one aggregate
`lab_agent_intent_to_tick_approved_application_recorded` event.

Feedback consumption, memory update, goal selection, pathfinding,
replanning, avoidance, reservation runtime, route following, physics,
save/load, social behavior, communication, gameplay movement, and
terrain/world mutation remain out of scope.

Next recommended step: Phase 4.22A - Feedback Consumption Planning
Docs-Only.

## Phase 4.22A - Feedback Consumption Planning Docs-Only

Status: implemented and validated.

Goal: document how PebbleLab will later consume structured movement feedback
as bounded agent policy context without implementing runtime feedback
consumption yet.

The document `PHASE_4_FEEDBACK_CONSUMPTION_PLAN.md` summarizes the validated
4.19 movement primitives, 4.20 tick movement contract, and 4.21 agent intent
production chain. It defines semantics for `approvedForMovement`, `moved`,
and every `blockedBy*` feedback kind; proposes future observation/context
types; defines an observe-only deterministic v0 policy; and lays out future
fixture, hardening, and integration phases.

The plan also defines future outputs, `agentFeedbackConsumption*` metrics, the
aggregate `lab_agent_feedback_consumption_recorded` event, 50 future
invariants, explicit out-of-scope boundaries, and a risk table for keeping
feedback from becoming memory, learning, replanning, pathfinding, social
behavior, or reservation runtime too early.

Runtime feedback consumption is not implemented. Memory updates, goal
changes, learning, LLM/RL/Python, pathfinding, replanning, avoidance,
reservation runtime, movement application, collision reads, route following,
physics, gameplay movement, and terrain/world mutation remain out of scope.

Next recommended step: Phase 4.22B - Feedback Consumption Fixture Smoke.

## Phase 4.22B - Feedback Consumption Fixture Smoke

Status: implemented and validated.

Goal: add the first fixture-only feedback consumption smoke so synthetic
movement feedback can be observed, normalized, and converted into bounded
agent feedback contexts without invoking intent production or movement ticks.

The scenario `agent_feedback_consumption_fixture_smoke` consumes six
intentionally unordered fixture feedback inputs. Four known feedback kinds are
accepted (`moved`, `approvedForMovement`, `blockedByCollision`, and
`blockedByAgentConflict`), one duplicate `agent_0` feedback is ignored and
counted, and one malformed feedback is rejected. The accepted observations and
contexts are sorted by stable `agentId`, and v0 accepts at most one feedback
item per agent.

It writes `agent_feedback_consumption_fixture_report.json`,
`agent_feedback_consumption_fixture_invariant_report.json`,
`agent_feedback_contexts.json`, `agentFeedbackConsumptionFixture*` metrics,
and one aggregate `lab_agent_feedback_consumption_fixture_recorded` event.

Intent production integration, behavior adaptation, memory update, goal
selection, pathfinding, replanning, avoidance, reservation runtime, route
following, movement application, collision reads, physics, gameplay movement,
and terrain/world mutation remain out of scope.

Next recommended step: Phase 4.22C - Feedback Consumption Hardening.

## Phase 4.22C - Feedback Consumption Hardening

Status: implemented and validated.

Goal: harden the fixture-only feedback consumption v0 contract without
integrating agent intent production, tick movement, live collision, memory, or
goal updates.

The scenario `agent_feedback_consumption_hardening_smoke` runs 12 hardening
cases:

- `baseline_fixture_remains_green`;
- `duplicate_feedback_denied`;
- `malformed_missing_agent_denied`;
- `malformed_missing_kind_denied`;
- `malformed_missing_required_fields_denied`;
- `deterministic_ordering_by_agent_id`;
- `one_feedback_per_agent_bound`;
- `all_known_kinds_observed`;
- `historical_collision_evidence_does_not_read_collision`;
- `max_feedback_bound_exceeded`;
- `tick_mismatch_denied`;
- `stable_repeatability`.

All 12 cases pass. The aggregate summary records `feedbackObservedTotal = 36`,
`feedbackAcceptedTotal = 26`, `feedbackIgnoredTotal = 5`,
`invalidFeedbackTotal = 5`, `contextsProducedTotal = 26`,
`duplicateFeedbackTotal = 4`, `maxFeedbackExceededTotal = 1`, and
`tickMismatchFeedbackTotal = 1`. Every known feedback kind is observed at
least once, observations and contexts remain sorted by stable `agentId`, and
v0 accepts at most one feedback item per agent.

It writes `agent_feedback_consumption_hardening_report.json`,
`agent_feedback_consumption_hardening_invariant_report.json`,
`agent_feedback_consumption_hardening_cases.json`,
`agentFeedbackConsumptionHardening*` metrics, and one aggregate
`lab_agent_feedback_consumption_hardening_recorded` event.

Behavior adaptation, memory update, goal selection, pathfinding, replanning,
avoidance, reservation runtime, route following, movement application,
collision reads, physics, gameplay movement, and terrain/world mutation remain
out of scope.

Next recommended step: Phase 4.22D - Feedback To Agent Intent Context Fixture
Smoke.

## Phase 4.22D - Feedback To Agent Intent Context Fixture Smoke

Status: implemented and validated.

Goal: connect accepted `LabAgentFeedbackContext` records to
`LabAgentIntentContext.lastFeedback` without introducing feedback-aware
behavior.

The scenario `feedback_to_agent_intent_context_fixture_smoke` consumes six
fixture feedback inputs, accepts four, ignores one duplicate, rejects one
malformed input, and then builds five agent intent contexts. Four contexts
carry preserved `lastFeedback` values:

- `agent_0`: `moved`;
- `agent_1`: `approvedForMovement`;
- `agent_2`: `blockedByCollision`;
- `agent_3`: `blockedByAgentConflict`.

`agent_4` has no feedback. The existing policy v0 is then run against the
feedback-bearing contexts and a nil-feedback baseline. Both produce the same
proposal signatures, proving `behaviorChangedByFeedback = false` and
`feedbackUsedForDecision = false`.

The fixture writes `feedback_to_agent_intent_context_fixture_report.json`,
`feedback_to_agent_intent_context_fixture_invariant_report.json`,
`feedback_to_agent_intent_contexts.json`,
`feedbackToAgentIntentContextFixture*` metrics, and one aggregate
`lab_feedback_to_agent_intent_context_fixture_recorded` event.

Behavior adaptation, memory update, goal selection, pathfinding, replanning,
avoidance, reservation runtime, route following, movement application,
collision reads, physics, gameplay movement, and terrain/world mutation remain
out of scope.

Next recommended step: Phase 4.22E - Feedback To Agent Intent Context
Hardening.

## Phase 4.22E - Feedback To Agent Intent Context Hardening

Status: implemented and validated.

Goal: harden the fixture-only plumbing from accepted feedback contexts to
`LabAgentIntentContext.lastFeedback` while keeping policy v0 behavior
unchanged.

The scenario `feedback_to_agent_intent_context_hardening_smoke` validates 14
cases covering the baseline fixture, missing feedback, partial feedback, all
known feedback kinds, blocked collision, moved, agent conflict, invalid edge,
duplicate selection, malformed feedback, tick mismatch, max feedback bounds,
deterministic ordering, and stable repeatability.

All 14 cases pass. Aggregate totals include `feedbackObservedTotal = 34`,
`feedbackAcceptedTotal = 28`, `feedbackIgnoredTotal = 3`,
`invalidFeedbackTotal = 3`, `contextsProducedTotal = 28`,
`intentContextsTotal = 40`, `contextsWithFeedbackTotal = 28`,
`contextsWithoutFeedbackTotal = 12`, `proposalsTotal = 40`,
`acceptedIntentsTotal = 33`, and `rejectedProposalsTotal = 7`.

Every case compares proposal signatures against a nil-feedback baseline.
`behaviorChangedByFeedback = false` and `feedbackUsedForDecision = false`,
including blocked collision, moved, conflict, and invalid-edge feedback cases.

The scenario writes `feedback_to_agent_intent_context_hardening_report.json`,
`feedback_to_agent_intent_context_hardening_invariant_report.json`,
`feedback_to_agent_intent_context_hardening_cases.json`,
`feedbackToAgentIntentContextHardening*` metrics, and one aggregate
`lab_feedback_to_agent_intent_context_hardening_recorded` event.

Behavior adaptation, memory update, goal selection, pathfinding, replanning,
avoidance, reservation runtime, route following, movement application,
collision reads, physics, gameplay movement, and terrain/world mutation remain
out of scope.

Next recommended step: Phase 4.22F - Feedback-Aware Intent Policy Planning
Docs-Only.

## Phase 4.22F - Feedback-Aware Intent Policy Planning Docs-Only

Status: implemented and validated.

Goal: document the future opt-in feedback-aware intent policy before adding
behavior.

The document `PHASE_4_FEEDBACK_AWARE_INTENT_POLICY_PLAN.md` defines how a
future `produceAgentIntentProposalFeedbackAwareV1` policy may use
`LabAgentIntentContext.lastFeedback` while staying deterministic, bounded, and
inspectable. It keeps v0 unchanged and opt-in, recommends baseline behavior
for no feedback, `moved`, and `approvedForMovement`, and recommends `noIntent`
for blocked feedback kinds in the first v1 smoke.

The plan defines the policy boundary, feedback reaction table, proposed future
types, v1 rules, future scenario sequence, outputs, metrics, aggregate event,
54 future invariants, explicit out-of-scope boundaries, a risk table, and the
recommended Phase 4.23A contract.

No runtime feedback-aware policy is implemented. Behavior adaptation, memory
update, goal selection, pathfinding, replanning, avoidance, reservation
runtime, route following, movement application, collision reads, physics,
gameplay movement, autonomous multi-tick loops, replacing v0 globally, and
terrain/world mutation remain out of scope.

Next recommended step: Phase 4.23A - Bounded Feedback-Aware Intent Policy
Fixture Smoke.

## Phase 4.23A - Bounded Feedback-Aware Intent Policy Fixture Smoke

Status: implemented and validated.

Goal: add the first opt-in feedback-aware intent policy fixture while keeping
the original v0 policy unchanged and globally unmodified.

The scenario `feedback_aware_intent_policy_fixture_smoke` introduces
`produceAgentIntentProposalFeedbackAwareV1` as an explicit opt-in policy. It
computes the baseline v0 proposal first, compares every v1 decision to that
baseline, and records per-agent feedback reactions.

The fixture uses 10 deliberately unordered contexts. One has no feedback, one
has `moved`, one has `approvedForMovement`, and seven cover the blocking
feedback kinds: `blockedByCollision`, `blockedByAgentConflict`,
`blockedBySourceMismatch`, `blockedByDivergence`, `blockedByStaleIntent`,
`blockedByInvalidEdge`, and `blockedByMaxAgents`.

No feedback, `moved`, and `approvedForMovement` keep the baseline v0 behavior.
Every blocking feedback kind returns `noIntent`. The invalid-edge feedback case
uses an explicit `feedback_blocked_by_invalid_edge_no_intent` reason so the
policy bug signal is visible rather than silently hidden.

Validated totals: `contexts = 10`, `contextsWithFeedback = 9`,
`contextsWithoutFeedback = 1`, `baselineProposals = 10`,
`feedbackAwareProposals = 10`, `acceptedIntents = 3`,
`rejectedProposals = 7`, `noIntent = 7`, `invalidOneEdgeProposals = 0`,
`feedbackReactions = 10`, and `behaviorChangedCount = 7`.

The scenario writes `feedback_aware_intent_policy_fixture_report.json`,
`feedback_aware_intent_policy_fixture_invariant_report.json`,
`feedback_aware_intent_policy_decisions.json`,
`feedbackAwareIntentPolicyFixture*` metrics, and one aggregate
`lab_feedback_aware_intent_policy_fixture_recorded` event.

Alternative direction selection, pathfinding, replanning, avoidance,
reservation runtime, route following, movement application, collision reads,
World access, memory update, goal change, learning, social behavior,
communication, gameplay movement, and terrain/world mutation remain out of
scope.

Next recommended step: Phase 4.23B - Feedback-Aware Intent Policy Hardening.

## Phase 4.23B - Feedback-Aware Intent Policy Hardening

Status: implemented and validated.

Goal: harden the opt-in feedback-aware v1 policy while keeping v0 unchanged
and while avoiding tick movement, World access, collision reads, movement
application, memory updates, goal changes, pathfinding, replanning, avoidance,
reservation runtime, learning, social behavior, communication, and terrain or
world mutation.

The scenario `feedback_aware_intent_policy_hardening_smoke` runs 16 fixture
cases covering the 4.23A baseline fixture, no-feedback baseline retention,
`moved` and `approvedForMovement` baseline retention, every blocked feedback
kind mapping to `noIntent`, blocked feedback on an existing v0 `noIntent`,
blocked feedback over an invalid v0 proposal, all blocked kinds counted once,
deterministic ordering by stable `agentId`, and stable repeatability.

The hardening report records baseline proposals, feedback-aware proposals,
per-context decisions, expected summaries, actual summaries, and repeatability
evidence per case. The invariant report covers opt-in v1 behavior, unchanged
v0, baseline-first evaluation, sorted outputs, reaction counters, intended
behavior changes only, and all no-World/no-collision/no-movement boundaries.

The scenario writes `feedback_aware_intent_policy_hardening_report.json`,
`feedback_aware_intent_policy_hardening_invariant_report.json`,
`feedback_aware_intent_policy_hardening_cases.json`,
`feedbackAwareIntentPolicyHardening*` metrics, and one aggregate
`lab_feedback_aware_intent_policy_hardening_recorded` event.

Alternative direction selection, tick integration, live collision, movement
application, route following, memory update, goal selection, pathfinding,
replanning, avoidance, reservation runtime, learning, social behavior,
communication, gameplay movement, and terrain/world mutation remain out of
scope.

Next recommended step: Phase 4.23C - Feedback-Aware Intent To Tick Fixture
Smoke.

## Phase 4.23C - Feedback-Aware Intent To Tick Fixture Smoke

Status: implemented and validated.

Goal: connect the opt-in feedback-aware v1 intent policy to the existing
multi-agent movement tick fixture contract without live collision, World
access, or movement application.

The scenario `feedback_aware_intent_to_tick_fixture_smoke` uses six deliberately
unordered intent contexts. Three contexts keep baseline movement proposals
(`no feedback`, `moved`, and `approvedForMovement`). Three blocked feedback
contexts become `noIntent` (`blockedByCollision`, `blockedByAgentConflict`,
and `blockedByInvalidEdge`) and are filtered before tick input.

The report compares the v0 baseline handoff with the feedback-aware v1 handoff.
Baseline would send five valid movement intents to the tick; v1 sends three.
The two filtered movement attempts prove the first bounded feedback-aware
reduction while keeping v0 unchanged and v1 opt-in.

The remaining `agent_0_no_feedback` and `agent_1_moved` same-destination
conflict is intentionally not arbitrated by policy. It is resolved by the tick
fixture layer: `agent_0_no_feedback` is approved, `agent_1_moved` is denied
same-destination conflict, and `agent_4_approved` is approved.

The scenario writes `feedback_aware_intent_to_tick_fixture_report.json`,
`feedback_aware_intent_to_tick_fixture_invariant_report.json`,
`feedback_aware_intent_to_tick_handoff.json`,
`feedbackAwareIntentToTickFixture*` metrics, and one aggregate
`lab_feedback_aware_intent_to_tick_fixture_recorded` event.

Live collision reads by policy, live collision reads by tick, movement
application, route following, memory update, goal selection, pathfinding,
replanning, avoidance, reservation runtime, gameplay movement, World access,
and terrain/world mutation remain out of scope.

Next recommended step: Phase 4.23D - Feedback-Aware Intent To Tick Live
Read-Only Smoke.

## Phase 4.23D - Feedback-Aware Intent To Tick Live Read-Only Smoke

Status: implemented and validated.

Goal: connect the opt-in feedback-aware v1 intent policy to the live
read-only movement tick contract while keeping collision and World access
strictly inside the tick layer.

The scenario `feedback_aware_intent_to_tick_live_readonly_smoke` uses seven
deliberately unordered intent contexts. Four contexts keep baseline movement
proposals (`no feedback`, `moved`, `approvedForMovement`, and a no-feedback
live-collision candidate). Three blocked feedback contexts become `noIntent`
(`blockedByCollision`, `blockedByAgentConflict`, and `blockedByInvalidEdge`)
and are filtered before tick input.

The v0 baseline would send six movement intents. The feedback-aware v1 handoff
sends four movement intents, producing a movement-input reduction of two while
keeping v0 unchanged and v1 opt-in. The remaining same-destination conflict is
not arbitrated by policy; the live read-only tick layer resolves it.

The tick live read-only layer reads collision evidence only at tick level. It
approves `agent_0_no_feedback` and `agent_4_approved`, denies `agent_1_moved`
for the same-destination conflict, and denies `agent_6_live_collision` for a
non-occupable destination. No movement is applied and positions remain
unchanged.

The scenario writes `feedback_aware_intent_to_tick_live_readonly_report.json`,
`feedback_aware_intent_to_tick_live_readonly_invariant_report.json`,
`feedback_aware_intent_to_tick_live_readonly_handoff.json`,
`feedbackAwareIntentToTickLiveReadonly*` metrics, and one aggregate
`lab_feedback_aware_intent_to_tick_live_readonly_recorded` event.

Live collision reads by policy, pathfinding, replanning, avoidance,
reservation runtime, route following, autonomous gameplay movement, movement
application, memory update, goal selection, and terrain/world mutation remain
out of scope.

Next recommended step: Phase 4.23E - Feedback-Aware Intent To Tick Approved
Application Smoke.

## Phase 4.23E - Feedback-Aware Intent To Tick Approved Application Smoke

Status: implemented and validated.

Goal: connect the opt-in feedback-aware v1 policy to live read-only tick
arbitration, then apply only approved movements to lab abstract/physical
position maps without mutating terrain or World.

The scenario `feedback_aware_intent_to_tick_approved_application_smoke` uses
the seven-context 4.23D fixture. V1 keeps baseline moves for no feedback,
`moved`, and `approvedForMovement`, while blocked feedback contexts become
`noIntent` and are filtered before tick input.

The v0 baseline would send six movement intents. The feedback-aware v1 handoff
sends four movement intents, producing a movement-input reduction of two while
keeping v0 unchanged and v1 opt-in.

The tick layer reads live collision evidence and arbitrates the remaining
same-destination conflict. It approves `agent_0_no_feedback` and
`agent_4_approved`, denies `agent_1_moved` by same-destination conflict, and
denies `agent_6_live_collision` by collision.

Approved application moves only the two approved lab positions:

- `agent_0_no_feedback`: `(0,64,0) -> (1,64,0)`;
- `agent_4_approved`: `(9,64,7) -> (9,64,8)`.

Denied and noIntent agents remain unchanged, `displacementsApplied = 2`,
abstract/physical divergence remains zero, and no terrain or World mutation is
performed.

The scenario writes
`feedback_aware_intent_to_tick_approved_application_report.json`,
`feedback_aware_intent_to_tick_approved_application_invariant_report.json`,
`feedback_aware_intent_to_tick_approved_application_handoff.json`,
`feedbackAwareIntentToTickApprovedApplication*` metrics, and one aggregate
`lab_feedback_aware_intent_to_tick_approved_application_recorded` event.

Pathfinding, replanning, avoidance, reservation runtime, route following live,
autonomous gameplay movement, memory/goals, and world mutation remain out of
scope.

Next recommended step: Phase 4.24A - Multi-Tick Closed Loop Planning
Docs-Only.

## Phase 4.24A - Multi-Tick Closed Loop Planning Docs-Only

Status: implemented and validated.

Goal: document the future bounded multi-tick closed loop before adding any
loop runner, executable scenario, runtime metrics, or runtime event code.

The plan `PHASE_4_MULTI_TICK_CLOSED_LOOP_PLAN.md` defines how PebbleLab should
later connect feedback-aware intent production, tick arbitration/live
read-only collision, approved lab position map application, structured
feedback emission, feedback consumption, and `lastFeedback` injection across
multiple fixed ticks.

The central causality rule is explicit: feedback emitted at tick `N` may only
be consumed at tick `N+1`. The plan also preserves v1 as opt-in and keeps v0
available.

The future sequence is:

- Phase 4.24B - Multi-Tick Closed Loop Fixture Smoke;
- Phase 4.24C - Multi-Tick Closed Loop Hardening;
- Phase 4.24D - Multi-Tick Closed Loop Live Read-Only Smoke;
- Phase 4.24E - Multi-Tick Closed Loop Approved Application Smoke;
- Phase 4.25A - Deterministic Bounded Alternate Local Hint Planning Docs-Only.

Pathfinding, replanning, avoidance, reservation runtime, route following,
autonomous gameplay movement, memory/goals, learning, social/communication,
physics, and terrain/world mutation remain out of scope.

Next recommended step: Phase 4.24B - Multi-Tick Closed Loop Fixture Smoke.

## Phase 4.24B - Multi-Tick Closed Loop Fixture Smoke

Status: implemented and validated.

Goal: validate the first bounded fixture-only closed loop across three ticks,
where feedback emitted by tick `N` is consumed only at tick `N+1` and injected
into opt-in feedback-aware v1 intent contexts.

The scenario `multi_tick_closed_loop_fixture_smoke` runs four synthetic agents
for three fixed ticks. Tick `0` creates a same-destination conflict, tick `1`
uses the previous `blockedByAgentConflict` feedback to convert the losing agent
to `noIntent`, and tick `2` proves the loop is memoryless beyond previous-tick
feedback by allowing the same conflict to return.

Validated totals:

- `requestedTicks = 3`;
- `executedTicks = 3`;
- `contextsTotal = 12`;
- `feedbackConsumedTotal = 5`;
- `feedbackCarriedToNextTickTotal = 8`;
- `movementIntentInputsTotal = 8`;
- `tickApprovedTotal = 6`;
- `tickDeniedTotal = 2`;
- `tickDeniedConflictTotal = 2`;
- `feedbackEmittedTotal = 8`;
- `sameTickFeedbackConsumedTotal = 0`;
- `crossAgentFeedbackLeaksTotal = 0`;
- `futureFeedbackConsumedTotal = 0`.

The scenario writes `multi_tick_closed_loop_report.json`,
`multi_tick_closed_loop_invariant_report.json`,
`multi_tick_closed_loop_ticks.json`, `multi_tick_closed_loop_feedback.json`,
`multiTickClosedLoop*` metrics, and one aggregate
`lab_multi_tick_closed_loop_recorded` event.

Live collision, World access, movement application, approved lab map movement,
memory updates, goal changes, pathfinding, replanning, avoidance, reservation
runtime, route following, physics, terrain/world mutation, and autonomous
gameplay movement remain out of scope.

Next recommended step: Phase 4.24C - Multi-Tick Closed Loop Hardening.

## Phase 4.24C - Multi-Tick Closed Loop Hardening

Status: implemented and validated.

Goal: harden the bounded fixture-only multi-tick closed loop before adding
live read-only collision or approved application closed-loop variants.

The scenario `multi_tick_closed_loop_hardening_smoke` runs 13 deterministic
cases covering baseline memoryless behavior, missing feedback, duplicate
feedback, stale feedback, future feedback, same-tick feedback, cross-agent
feedback, unknown-agent feedback, malformed feedback, owner-only blocked
feedback, all-missing-feedback baseline behavior, repeatability, and max tick
bound enforcement.

Validated hardening behavior:

- feedback can be consumed only from exactly the previous tick;
- missing feedback keeps baseline behavior;
- duplicate eligible feedback is deduped deterministically;
- stale, future, same-tick, cross-agent, unknown-agent, and malformed feedback
  are ignored and counted;
- cross-agent feedback leak attempts never inject `lastFeedback`;
- same-tick and future feedback are never consumed;
- blocked feedback affects only the owning agent;
- fixture tick arbitration remains responsible for movement conflicts;
- repeatability checks pass with stable ordering.

The scenario writes `multi_tick_closed_loop_hardening_report.json`,
`multi_tick_closed_loop_hardening_invariant_report.json`,
`multi_tick_closed_loop_hardening_cases.json`,
`multi_tick_closed_loop_hardening_feedback.json`,
`multiTickClosedLoopHardening*` metrics, and one aggregate
`lab_multi_tick_closed_loop_hardening_recorded` event.

Live collision, World access, movement application, approved lab map movement,
memory updates, goal changes, pathfinding, replanning, avoidance, reservation
runtime, route following, physics, terrain/world mutation, and autonomous
gameplay movement remain out of scope.

Next recommended step: Phase 4.24D - Multi-Tick Closed Loop Live Read-Only
Smoke.

## Phase 4.24D - Multi-Tick Closed Loop Live Read-Only Smoke

Status: implemented and validated.

Goal: connect the bounded three-tick closed loop to the live read-only tick
collision layer while keeping the feedback-aware policy away from collision,
World access, movement application, memory, goals, pathfinding, replanning,
avoidance, reservation runtime, route following, and mutation.

The scenario `multi_tick_closed_loop_live_readonly_smoke` runs five fixed
agents across three ticks. Tick `0` emits same-destination conflict feedback
for `agent_1_loser` and collision feedback for `agent_3_collision`. Tick `1`
consumes only tick `0` feedback, converts those two blocked agents to
`noIntent`, filters them before tick input, and reduces both conflict and
collision. Tick `2` consumes only tick `1` feedback, documents memoryless
previous-tick-only behavior, and allows the conflict/collision pattern to
return.

Validated totals:

- `requestedTicks = 3`;
- `executedTicks = 3`;
- `agents = 5`;
- `contextsTotal = 15`;
- `contextsWithFeedbackTotal = 6`;
- `contextsWithoutFeedbackTotal = 9`;
- `movementIntentInputsTotal = 10`;
- `tickApprovedTotal = 6`;
- `tickDeniedTotal = 4`;
- `tickDeniedConflictTotal = 2`;
- `tickDeniedCollisionTotal = 2`;
- `feedbackConsumedTotal = 6`;
- `feedbackCarriedToNextTickTotal = 10`;
- `tickReadCollision = true`;
- `tickWorldReadOnlyUsed = true`;
- `policyReadCollision = false`;
- `policyWorldUsed = false`;
- `movementApplied = false`.

The scenario writes `multi_tick_closed_loop_live_readonly_report.json`,
`multi_tick_closed_loop_live_readonly_invariant_report.json`,
`multi_tick_closed_loop_live_readonly_ticks.json`,
`multi_tick_closed_loop_live_readonly_feedback.json`,
`multiTickClosedLoopLiveReadonly*` metrics, and one aggregate
`lab_multi_tick_closed_loop_live_readonly_recorded` event.

Approved application, pathfinding, replanning, avoidance, reservation runtime,
route following, memory/goals, alternate hints, autonomous gameplay movement,
and terrain/world mutation remain out of scope.

Next recommended step: Phase 4.24E - Multi-Tick Closed Loop Approved
Application Smoke.

## Phase 4.24E - Multi-Tick Closed Loop Approved Application Smoke

Status: implemented and validated.

Goal: connect the bounded three-tick closed loop to the approved application
tick layer so approved outputs update only lab abstract/physical position maps
and feedback from those ticks drives the next tick.

The scenario `multi_tick_closed_loop_approved_application_smoke` runs five
fixed agents across three ticks. Tick `0` emits conflict and collision
feedback and applies only approved lab-map movements. Tick `1` consumes only
tick `0` feedback, converts the blocked agents to `noIntent`, filters those
before tick input, and applies the surviving approved movements. Tick `2`
consumes only tick `1` feedback, uses the updated lab positions for contexts,
and preserves denied/noIntent agents.

Validated totals:

- `requestedTicks = 3`;
- `executedTicks = 3`;
- `agents = 5`;
- `contextsTotal = 15`;
- `contextsWithFeedbackTotal = 6`;
- `contextsWithoutFeedbackTotal = 9`;
- `movementIntentInputsTotal = 10`;
- `tickApprovedTotal = 6`;
- `tickDeniedTotal = 4`;
- `tickDeniedConflictTotal = 2`;
- `tickDeniedCollisionTotal = 2`;
- `tickFeedbackEmittedTotal = 10`;
- `feedbackConsumedTotal = 6`;
- `feedbackCarriedToNextTickTotal = 10`;
- `approvedApplicationsTotal = 6`;
- `approvedAgentsMovedTotal = 6`;
- `deniedAgentsPreservedTotal = 4`;
- `noIntentAgentsPreservedTotal = 5`;
- `displacementsAppliedTotal = 6`;
- `abstractPhysicalDivergenceAfterMax = 0`;
- `sameTickFeedbackConsumedTotal = 0`;
- `crossAgentFeedbackLeaksTotal = 0`;
- `futureFeedbackConsumedTotal = 0`.

The scenario writes `multi_tick_closed_loop_approved_application_report.json`,
`multi_tick_closed_loop_approved_application_invariant_report.json`,
`multi_tick_closed_loop_approved_application_ticks.json`,
`multi_tick_closed_loop_approved_application_feedback.json`,
`multiTickClosedLoopApprovedApplication*` metrics, and one aggregate
`lab_multi_tick_closed_loop_approved_application_recorded` event.

Policy live collision reads, policy World access, pathfinding, replanning,
avoidance, reservation runtime, route following, memory/goals, alternate hints,
autonomous gameplay movement, physical placeholder movement, core entity
movement, and terrain/world mutation remain out of scope.

Next recommended step: Phase 4.25A - Deterministic Bounded Alternate Local
Hint Planning Docs-Only.

## Phase 4.25A - Deterministic Bounded Alternate Local Hint Planning Docs-Only

Status: implemented and validated.

Goal: document the future deterministic bounded alternate local hint mechanism
before implementation. The plan preserves the Phase 4.24 boundary: feedback
from tick `N` is consumed only at tick `N+1`, the policy does not read
collision or World, tick remains responsible for arbitration/collision, and
approved application remains lab-map-only.

The new document `PHASE_4_ALTERNATE_LOCAL_HINT_PLAN.md` defines:

- why `blockedBy* -> noIntent` is safe but can pause agents frequently;
- a non-goal statement separating local hints from pathfinding, replanning,
  avoidance, reservation runtime, route following, gameplay autonomy, learning,
  social behavior, LLM/RL/Python, and terrain/World mutation;
- the allowed and forbidden alternate local hint boundary;
- a fixed deterministic candidate table that excludes the failed direction;
- the recommendation to add a future opt-in v2 policy instead of changing v0
  or v1;
- future reports, metrics, events, and 82 invariants;
- the recommended Phase 4.25B fixture smoke contract.

No Swift, runtime scenario, runner, metric/event implementation, renderer,
resources, registries, save/load, or goldens were modified.

Next recommended step: Phase 4.25B - Alternate Local Hint Fixture Smoke.

## Phase 4.25B - Alternate Local Hint Fixture Smoke

Status: implemented and validated.

Goal: add the first fixture-only alternate local hint proof with an explicit
opt-in v2 policy while leaving v0 and v1 unchanged. Known blocked east/west
feedback is converted into deterministic bounded local north/south candidates;
empty and unknown hints produce no alternate and remain `noIntent`.

Validated scope:

- `alternate_local_hint_fixture_smoke`;
- `maxAlternates = 2`;
- six contexts and six decisions;
- four blocked-feedback contexts;
- four candidates produced and two selected;
- two noIntent proposals filtered before tick;
- four movement intents sent to fixture tick;
- four tick approvals, zero denials, four feedback records;
- zero displacements applied;
- no policy or tick collision read;
- no World usage;
- no movement application;
- no memory/goals;
- no pathfinding, replanning, avoidance, reservation runtime, or route
  following;
- no terrain/world mutation.

Outputs:

- `alternate_local_hint_report.json`;
- `alternate_local_hint_invariant_report.json`;
- `alternate_local_hint_handoff.json`;
- `alternate_local_hint_decisions.json`;
- `alternateLocalHint*` metrics;
- `lab_alternate_local_hint_recorded` event.

Next recommended step: Phase 4.25C - Alternate Local Hint Hardening.

## Phase 4.25C - Alternate Local Hint Hardening

Status: implemented and validated.

Goal: harden the opt-in alternate local hint v2 policy without changing v0 or
v1 and without introducing live collision, World access, movement application,
route following, pathfinding, replanning, avoidance, reservation runtime,
memory/goals, or terrain/world mutation.

Validated scope:

- `alternate_local_hint_hardening_smoke`;
- 22 hardening cases;
- 22 passed, 0 failed;
- baseline no-feedback, approved feedback, and moved feedback remain baseline;
- all seven blocked feedback kinds are covered;
- `maxAlternates` 0, 1, 2, and 3 are covered;
- empty and unknown hints produce no alternate;
- duplicate hints are handled deterministically;
- failed directions are excluded;
- one-edge alternate intents are preserved;
- repeatability has 1 check and 0 failures;
- 18 movement intent inputs reach fixture tick;
- tick fixture approves 18, denies 0, emits 18 feedback records;
- policy and tick collision reads are false;
- policy and tick World usage are false;
- no movement, memory/goals, pathfinding, replanning, avoidance, reservation
  runtime, route following, or terrain/world mutation occurs.

Outputs:

- `alternate_local_hint_hardening_report.json`;
- `alternate_local_hint_hardening_invariant_report.json`;
- `alternate_local_hint_hardening_cases.json`;
- `alternate_local_hint_hardening_decisions.json`;
- `alternate_local_hint_hardening_handoff.json`;
- `alternateLocalHintHardening*` metrics;
- `lab_alternate_local_hint_hardening_recorded` event.

Next recommended step: Phase 4.25D - Alternate Local Hint Live Read-Only Smoke.
