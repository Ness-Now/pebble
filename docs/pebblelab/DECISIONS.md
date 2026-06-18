# PebbleLab Decisions

## 2026-06-17 - Abstract Nearby-Agent Perception

Decision: social perception v0 remains an abstract PebbleLab-only observation.

PebbleLab agents can detect nearby abstract agents by relative position and
Manhattan distance, but this does not create communication, trust, friendship,
reputation, groups, physical entities, or any world mutation.

Reason: the project needs a deterministic perception signal before adding
agent-agent interaction or social state.

## 2026-06-17 - Deterministic Current Goal Before Action

Decision: PebbleLab agents choose a stable `currentGoal` before selecting an
abstract action.

The goal system remains abstract and deterministic. It does not introduce a
planner, LLM, physical entity, pathfinding, communication, or social
relationship system.

Reason: goals create a small explicit layer between observations/needs and
actions, making future behavior easier to inspect before adding more complex
planning.

## 2026-06-17 - Abstract Vital And Home State

Decision: PebbleLab agents track `health`, `fear`, and `homePosition` as
abstract agent state.

These fields do not imply physical movement, pathfinding, inventory,
world mutation, or social relationships. `homePosition` is assigned from the
spawn position for now, and fear/health only influence the deterministic goal
priority layer.

Reason: future survival and settlement behavior needs stable state anchors
before adding inventory, physical agents, homes, groups, or social systems.

## 2026-06-17 - Abstract String-Keyed Inventory

Decision: PebbleLab agents use an abstract `LabInventory` keyed by string item
identifiers.

This intentionally avoids PebbleCore `ItemStack`, registries, physical pickup,
crafting, storage, exchange, theft, sharing, or economy mechanics until
physical agents and world interactions are introduced.

Reason: future food, gathering, construction, and social behavior needs a small
deterministic inventory surface before coupling agents to the full item system.

## 2026-06-17 - Fixed Smoke Scenario And Configurable Agent Scenario

Decision: PebbleLab keeps `agent_smoke` as a fixed two-agent validation
scenario and adds `agents_basic` as the configurable multi-agent simulation
scenario.

`agents_basic` uses deterministic grid placement from the run seed and agent
index. It does not introduce movement, pathfinding, physical entities,
resource sharing, economy, or world mutation.

Reason: the project needs a stable tiny smoke scenario and a separate scalable
scenario for longer abstract simulations.

## 2026-06-17 - Abstract Position Updates

Decision: PebbleLab agents can update their abstract position from selected
actions.

This movement intentionally does not use PebbleCore physical entities,
pathfinding, collision, gravity, block checks, or world interaction. For v0,
movement is limited to X/Z steps with `dy = 0` and is used to validate the
observation/action/logging loop.

Reason: simulations need visible agent trajectories before introducing
physical bodies or real navigation.

## 2026-06-17 - Abstract seekSafety Movement Toward Home

Decision: PebbleLab `seekSafety` behavior moves agents abstractly toward
`homePosition`.

This remains separate from physical pathfinding, collision, world navigation,
PebbleCore entity movement, and world mutation. The v0 behavior takes one
deterministic X/Z step toward home and records distance reduction metrics.

Reason: agents need an inspectable safety loop before introducing richer
navigation, homes, settlements, or physical bodies.

## 2026-06-17 - Internal Metrics Separate From Event Volume

Decision: PebbleLab separates internal simulation metrics from emitted NDJSON
event volume.

`--event-rate` throttles frequent events such as `world_tick` and
`agent_observed_nearby_agent`, but it does not change agent state, world ticks,
goal selection, movement, or aggregate metrics. Critical lifecycle events stay
unthrottled.

Reason: longer runs need bounded log sizes without losing deterministic
simulation state or summary metrics.

## 2026-06-17 - Compact Regression Report Stays PebbleLab-Local

Decision: `regression_smoke` writes a compact PebbleLab regression report for
the current run instead of spawning multiple subprocesses or replacing
`pebsmoke`.

The report summarizes success criteria and key metrics for a deterministic
headless scenario. It is intentionally separate from PebbleCore golden tests
and does not modify registries, goldens, or game systems.

Reason: PebbleLab needs a quick health signal that is easier to inspect than
several raw JSON files, while `pebsmoke` remains the authoritative engine
regression suite.

## 2026-06-17 - Physical Agent Bridge Before Mob Changes

Decision: Phase 4 keeps `LabAgent` as the abstract cognitive state and plans
physical representation through an isolated bridge before modifying existing
mobs or adding full pathfinding.

The recommended path is to avoid changing existing mob behavior, avoid reusing
mob AI as the lab brain, and introduce a future physical placeholder with clear
id mapping, spawn/tick/snapshot logs, and drift metrics. A dedicated
experimental entity can be considered later, but registry changes must be
reviewed separately and must not reorder existing registrations.

Reason: PebbleCore entities bring registry, save/load, ticking, pathfinding,
rendering, and golden-test risks. A bridge-first plan preserves deterministic
PebbleLab scenarios while creating a controlled path toward physical agents.

## 2026-06-17 - Non-Invasive Physical Placeholder

Decision: Phase 4.1 introduces a PebbleLab-only physical placeholder for
`LabAgent` instead of registering a new PebbleCore mob.

The placeholder records a deterministic `agentId` to `physicalId` link, a
physical position, kind, spawn tick, tick count, metrics, NDJSON events, and a
dedicated `physical_snapshot.json`. It does not enter `World.entities`, does
not modify PebbleCore, and does not use pathfinding, collision, rendering,
save/load, item stacks, combat, or construction.

Reason: a non-invasive placeholder proves the bridge shape and output contract
without touching entity registries or golden-sensitive mob behavior. The next
step is placeholder synchronization with abstract movement; a real PebbleCore
entity remains a later registry-safe feasibility patch.

## 2026-06-18 - Physical Placeholder Syncs From Abstract Movement

Decision: Phase 4.2A synchronizes PebbleLab physical placeholders from abstract
`LabAgent` positions after abstract movement has been applied.

The bridge remains PebbleLab-only and deterministic. It compares each
placeholder position with the matching `LabAgent.position`, updates only when
there is divergence, records sync metrics, and writes
`lab_physical_agent_synced` events. It does not create a PebbleCore entity,
does not enter `World.entities`, and does not use registries, collision,
pathfinding, rendering, save/load, item stacks, combat, or construction.

Reason: the project needs a stable bridge contract and measurable drift before
planning any registry-safe real entity feasibility patch.

## 2026-06-18 - Probe Real Entities Before Registry Changes

Decision: the next real-entity step should be an unregistered PebbleCore
`Entity` probe constructed directly by PebbleLab, not a registered entity and
not a wrapper around an existing mob.

The recommended Phase 4.3A path is to add a minimal `LabCoreAgentEntity` that
can be inserted into a PebbleLab `World.entities` scenario, linked to a
`LabAgent`, ticked explicitly, and measured through snapshots and metrics. It
must not modify `EntityRegistry`, `spawnableMobs`, renderer model mapping,
save/load contracts, vanilla mob behavior, pathfinding, collision, combat, or
goldens.

Reason: `EntityRegistry` order, entity type count, spawnable mob lists, natural
spawning, and vanilla mob behavior are golden-sensitive. A direct unregistered
probe is the smallest real PebbleCore boundary crossing that preserves the
existing deterministic bridge contract.

## 2026-06-18 - Unregistered Core Entity Probe Before Registration

Decision: Phase 4.3A introduces `LabCoreAgentEntity` as an unregistered
PebbleCore `Entity` probe constructed directly by PebbleLab.

The probe inherits from `Entity` only. It is added to `World.entities` by the
`core_entity_smoke` scenario, ticked explicitly by PebbleLab, synchronized from
`LabAgent.position`, and measured through metrics, events, and
`core_entity_snapshot.json`. It does not touch `EntityRegistry`,
`spawnableMobs`, `registerAllEntities`, `loadEntity`, renderer model mapping,
save/load, vanilla mobs, pathfinding, collision, combat, sounds, or goldens.

Reason: this is the smallest real PebbleCore entity presence that can validate
the bridge contract while avoiding registry and rendering risk. Registered
entity work remains a separate later phase.

## 2026-06-18 - Harden the Probe Contract Before Visibility or Registration

Decision: Phase 4.3B adds invariant reporting around the unregistered core
entity probe before any renderer, `GameCore`, save/load, or registry integration.

The report checks the actual `core_entity_smoke` object graph: every probe has a
matching abstract agent and physical identifier, is present by identity in both
`World.entities` and `World.entityById`, uses the experimental probe kind, has
recorded ticks, and ends with zero abstract/core divergence.

The unregistered check is deliberately documented as a scenario contract. The
scenario constructs `LabCoreAgentEntity` directly and does not call
`EntityRegistry`, `registerAllEntities`, `spawnMob`, or `loadEntity` for it. No
runtime registry introspection or mutation is introduced.

## 2026-06-18 - Use a Renderer-Only Wireframe Marker for Debug Visibility

Decision: the first visibility patch should add a disabled-by-default
wireframe marker for `LabCoreAgentEntity` in `WorldRenderer`, gated by
`PEBBLELAB_DEBUG_ENTITIES=1`.

The marker should reuse the existing line pipeline and `drawBoxOutline`, select
entities by `LabCoreAgentEntity` type, and avoid `modelNameFor`, entity model
tables, resource-pack textures, shaders, registries, save/load, and simulation
state. It should emit no PebbleLab metrics or events because visibility is an
app-side diagnostic only.

Do not add a `/labprobe` spawn command in the same patch. `GameCore.chunkRecord`
currently serializes non-player entities in loaded chunks without filtering on
`persistent`, so an app-spawned unregistered probe could enter a save record.
App-side probe injection requires a separate transient-lifecycle decision.

## 2026-06-18 - Keep Debug Visibility Purely Renderer-Side

Decision: Phase 4.4B implements the planned marker entirely in
`WorldRenderer`. The renderer reads `PEBBLELAB_DEBUG_ENTITIES` once, enables
the path only for the exact value `1`, selects only `LabCoreAgentEntity`, and
draws interpolated cyan wireframe AABBs through the existing line pipeline.

The patch does not change `modelNameFor`, create entities, add commands, alter
simulation state, register types, or touch save/load, models, textures,
shaders, resource packs, metrics, events, or snapshots. App-side probe
creation remains deferred to Phase 4.4C because it needs a safe transient
lifecycle and persistence exclusion contract.

## 2026-06-18 - Establish Save Exclusion Before App-Side Probe Injection

Decision: no app-side `LabCoreAgentEntity` may be created until PebbleCore has
an explicit chunk-save policy that excludes the probe.

The next code phase should add a default-true property such as
`shouldSaveToChunk` on `Entity`, override it to `false` on
`LabCoreAgentEntity`, and use it in both `GameCore.unloadChunk` entity-presence
decisions and `GameCore.chunkRecord` serialization. This policy must remain
separate from the existing `persistent` flag, which is serialized and affects
mob lifecycle but currently does not control chunk-save inclusion.

Phase 4.4D must not add `/labprobe` or any app injection. A later phase may add
explicitly gated creation and cleanup only after save exclusion is validated.

## 2026-06-18 - Separate Chunk Save Policy From Persistent Lifecycle State

Decision: Phase 4.4D adds `Entity.shouldSaveToChunk`, defaulting to `true`,
rather than reusing `persistent`.

`LabCoreAgentEntity` overrides the policy to `false`. `GameCore.chunkRecord`
uses it before serialization, and `GameCore.unloadChunk` uses it when deciding
whether live entities alone require an entity-only record. The later unload
cleanup still removes every live non-player entity through `World.removeEntity`.

This preserves all existing entity defaults, save format, registry behavior,
and `persistent` semantics while giving transient probes an explicit opt-out.

## 2026-06-18 - Gate App Probe Creation Separately From Rendering

Decision: Phase 4.4E adds app-side `/labprobe status`, `/labprobe spawn`, and
`/labprobe clear` operations in `CommandsM.swift` only.

Probe creation requires the exact environment value
`PEBBLELAB_APP_PROBES=1`. Rendering remains separately controlled by
`PEBBLELAB_DEBUG_ENTITIES=1`; neither gate implies the other. Spawn constructs
one unregistered `LabCoreAgentEntity` directly, verifies its
`shouldSaveToChunk == false` contract, and inserts it through
`World.addEntity`. Duplicate probes are rejected.

Status is read-only. Clear remains available even when creation is disabled so
an existing transient probe always has a safe cleanup path, and removes probes
only through `World.removeEntity` to keep `entities` and `entityById`
consistent. The command remains absent from normal `/help` output unless the
creation gate is active.

## 2026-06-18 - Keep Visual Validation Explicit And Disposable

Decision: Phase 4.4F keeps app visual validation as an explicit
disposable-world workflow before any automatic lifecycle hardening.

Automated builds and headless scenarios validate compilation and simulation
contracts, but they do not prove that the macOS UI displayed the cyan marker or
accepted chat commands. Visual success must be recorded only after an operator
launches Pebble with both exact-value gates, executes the documented command
sequence, rejects a duplicate spawn, clears the probe, and observes count zero.

Important saves remain out of scope. The next code phase should harden cleanup
across world and dimension transitions before scripted screenshot automation.

## 2026-06-18 - Accept Manual Visual Validation For Phase 4.4F

Decision: manual visual validation is accepted as completed for Phase 4.4F
because the operator confirmed spawn, cyan wireframe visibility, duplicate
rejection, explicit clear, and final count zero in a new disposable world.

User-provided screenshots support the recorded observations but are not
committed. The validation does not claim unreported results such as automatic
world-transition cleanup. Phase 4.5A remains responsible for that hardening.

## 2026-06-18 - Centralize Probe Cleanup Through World APIs

Decision: Phase 4.5A centralizes `LabCoreAgentEntity` cleanup through
`World.removeEntity` and uses it for explicit and transition cleanup. It does
not alter save/load, registry, or rendering behavior.

The reusable world helper is independent of environment gates and idempotent.
GameCore applies it across all dimension worlds before title exit, world
replacement, and dimension transfer; the app invokes the same GameCore cleanup
before termination. `/labprobe clear` delegates to the helper for the active
world. Direct mutation of `entities` or `entityById` remains forbidden.

## 2026-06-18 - Keep Screenshot Validation Outside Simulation

Decision: Phase 4.5B keeps scripted screenshot validation separate from
simulation and persistence changes. Any screenshot workflow must use disposable
worlds and explicit gates.

The existing `PEBBLE_AUTOLOAD`, `PEBBLE_NEWWORLD`, `PEBBLE_CMD`, and
`PEBBLE_SHOT` hooks already guarantee command execution before capture and
normal termination afterward. Camera orientation is supplied through the
existing `/tp` command rather than a new probe or renderer API. No script,
gameplay command, renderer change, or screenshot-specific simulation state is
introduced.

## 2026-06-18 - Keep Physical Behavior Abstract And Synchronized

Decision: Phase 4.6A keeps physical behavior as deterministic abstract movement
synchronized into the core entity. It intentionally avoids pathfinding,
collision, block interaction, registry, and save/load changes.

`LabAgent.position` remains authoritative. The placeholder and unregistered
`LabCoreAgentEntity` are synchronized after the existing abstract movement
step. Scenario success requires at least one movement and core sync plus zero
final abstract/core divergence; it does not imply realistic locomotion.

## 2026-06-18 - Extend Physical Behavior Through One-To-One Links

Decision: Phase 4.6B extends the physical behavior loop to multiple agents
while preserving deterministic abstract movement and avoiding pathfinding,
collision, block interaction, registry, and save/load changes.

Each `LabAgent` owns exactly one distinct `physicalId` and one unregistered
core entity in the smoke scenario. Success requires complete one-to-one links,
at least two moving agents, effective core synchronization, and zero total and
maximum final abstract/core divergence.

## 2026-06-18 - Report Multi-Agent Physical Invariants Explicitly

Decision: Phase 4.6C adds a dedicated invariant report for multi-agent physical
behavior before introducing any pathfinding, collision, block interaction, or
world manipulation.

The report is part of scenario success rather than a passive artifact. It
audits one-to-one ownership, identifier uniqueness, cross-bridge `physicalId`
agreement, movement, positive distance, and zero total/max final divergence.
