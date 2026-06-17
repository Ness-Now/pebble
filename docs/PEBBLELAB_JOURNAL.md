# PebbleLab Journal

This journal records the initial PebbleLab work so future contributors can
understand what changed without needing the original chat history.

## 2026-06-17 - Minimal PebbleLab Target

Summary: Added the first headless SwiftPM executable target, `PebbleLab`, that
depends only on `PebbleCore`.

Files touched:

- `Package.swift`
- `Sources/PebbleLab/main.swift`

Validation:

- `swift build`
- `swift run -c release PebbleLab`

Result: Build passed. The runner created `World(dim: .overworld, seed: 12345)`,
ticked 20 times, printed success, and exited.

Known limits: No CLI, no output files, no scenarios beyond the hardcoded run.

Decision: Start through `World` directly, not `GameCore`, to avoid the wide
`GameHost` surface and keep the first proof minimal.

## 2026-06-17 - Minimal CLI Parsing

Summary: Added direct parsing of `CommandLine.arguments`.

Files touched:

- `Sources/PebbleLab/main.swift`

Validation:

- `swift build`
- `swift run -c release PebbleLab -- --help`
- `swift run -c release PebbleLab -- --seed 42 --ticks 1000 --scenario empty`
- `swift run -c release PebbleLab -- --scenario unknown`

Result: CLI options worked. Unknown scenarios returned a readable non-zero
error.

Known limits: Parser is intentionally small and has no external dependency.

Decision: Keep scenario support restricted to `empty` until outputs and logging
are stable.

## 2026-06-17 - SwiftPM Separator Fix

Summary: Fixed parsing so a standalone `--` from `swift run ... -- ...` is
ignored while real long options are still parsed.

Files touched:

- `Sources/PebbleLab/main.swift`

Validation:

- `swift build`
- `swift run -c release PebbleLab -- --help`

Result: Help printed correctly when invoked through SwiftPM.

Known limits: No short options or advanced parser behavior.

Decision: Keep parsing explicit and local.

## 2026-06-17 - Run Outputs

Summary: Added optional local run output directory support via `--out <path>`.
PebbleLab writes `config.json` and `metrics.json` when `--out` is provided.

Files touched:

- `Sources/PebbleLab/main.swift`
- `.gitignore`

Validation:

- `swift build`
- `swift run -c release PebbleLab -- --seed 42 --ticks 10 --scenario empty`
- `swift run -c release PebbleLab -- --seed 42 --ticks 10 --scenario empty --out runs/smoke_empty`
- `cat runs/smoke_empty/config.json`
- `cat runs/smoke_empty/metrics.json`
- `git status --short`

Result: Output files were written only with `--out`. `runs/` and `models/` were
ignored by git.

Known limits: No event stream yet.

Decision: Write local run artifacts but keep them uncommitted.

## 2026-06-17 - Minimal Event Log

Summary: Added `events.ndjson` when `--out` is provided.

Files touched:

- `Sources/PebbleLab/main.swift`

Validation:

- `swift build`
- `swift run -c release PebbleLab -- --seed 42 --ticks 3 --scenario empty --out runs/smoke_events`
- `cat runs/smoke_events/config.json`
- `cat runs/smoke_events/metrics.json`
- `cat runs/smoke_events/events.ndjson`
- `git status --short`

Result: The event log contained `run_started`, one `world_tick` per tick, and
`run_finished`, with one JSON object per line.

Known limits: Event model is minimal and all in-memory before write.

Decision: Use NDJSON early because it is simple to inspect and easy for later
Python analysis.

## 2026-06-17 - Runner File Refactor

Summary: Split the single runner file into smaller files.

Files touched:

- `Sources/PebbleLab/main.swift`
- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabEvents.swift`

Validation:

- `swift build`
- `swift run -c release PebbleLab -- --help`
- `swift run -c release PebbleLab -- --seed 42 --ticks 3 --scenario empty`
- `swift run -c release PebbleLab -- --seed 42 --ticks 3 --scenario empty --out runs/smoke_refactor`
- `cat runs/smoke_refactor/config.json`
- `cat runs/smoke_refactor/metrics.json`
- `cat runs/smoke_refactor/events.ndjson`

Result: Behavior and output formats stayed equivalent.

Known limits: No heavy runner abstraction was introduced.

Decision: Separate readability concerns without changing architecture.

## 2026-06-17 - `chunk_smoke` Scenario

Summary: Added a second scenario name, `chunk_smoke`, plus a small scenario file.

Files touched:

- `Sources/PebbleLab/main.swift`
- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/LabScenarios.swift`

Validation:

- `swift build`
- `swift run -c release PebbleLab -- --help`
- `swift run -c release PebbleLab -- --seed 42 --ticks 3 --scenario empty --out runs/smoke_empty_after_scenario`
- `swift run -c release PebbleLab -- --seed 42 --ticks 3 --scenario chunk_smoke --out runs/smoke_chunk`
- `cat runs/smoke_chunk/config.json`
- `cat runs/smoke_chunk/metrics.json`
- `cat runs/smoke_chunk/events.ndjson`

Result: `empty` continued to work. `chunk_smoke` produced config, metrics, and
events with an additional `scenario_started` event.

Known limits: `chunk_smoke` only probes public chunk access and does not force
real chunk generation.

Decision: Do not modify PebbleCore just to make the first scenario more active.

## 2026-06-17 - `chunk_smoke` Origin Chunk Adoption

Summary: Improved `chunk_smoke` so it generates the origin chunk `(0,0)` through
public PebbleCore APIs, assembles a `Chunk`, adopts it into the direct
`World`, initializes lighting, and records chunk metrics.

Files touched:

- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/main.swift`
- `docs/PEBBLELAB_JOURNAL.md`
- `docs/PEBBLELAB_CHANGELOG.md`

Validation:

- `swift build`
- `swift run -c release PebbleLab -- --seed 42 --ticks 3 --scenario empty --out runs/smoke_empty_after_chunk_patch`
- `swift run -c release PebbleLab -- --seed 42 --ticks 3 --scenario chunk_smoke --out runs/smoke_chunk_adopted`
- `cat runs/smoke_chunk_adopted/config.json`
- `cat runs/smoke_chunk_adopted/metrics.json`
- `cat runs/smoke_chunk_adopted/events.ndjson`

Result: `empty` still worked. `chunk_smoke` adopted one generated chunk and
reported `chunksTouched`, `originChunkReady`, center height/surface, and
non-air block count.

Known limits: The scenario still does not resolve worldgen entity specs or block
entity specs, and it does not reproduce the full `GameCore` streaming path.

Decision: Use only public PebbleCore APIs from PebbleLab for this step and keep
the scope to a single chunk.

## 2026-06-17 - `chunk_smoke` Chunk Radius

Summary: Added `--chunk-radius <Int>` for `chunk_smoke`, with supported values
`0...1`. Radius `0` keeps the single origin chunk behavior; radius `1`
generates and adopts a 3x3 chunk area around the origin.

Files touched:

- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/main.swift`
- `docs/PEBBLELAB_JOURNAL.md`
- `docs/PEBBLELAB_CHANGELOG.md`

Validation:

- `swift build`
- `swift run -c release PebbleLab -- --help`
- `swift run -c release PebbleLab -- --seed 42 --ticks 3 --scenario empty --out runs/smoke_empty_after_radius`
- `swift run -c release PebbleLab -- --seed 42 --ticks 3 --scenario chunk_smoke --chunk-radius 0 --out runs/smoke_chunk_radius0`
- `swift run -c release PebbleLab -- --seed 42 --ticks 3 --scenario chunk_smoke --chunk-radius 1 --out runs/smoke_chunk_radius1`
- `swift run -c release PebbleLab -- --scenario chunk_smoke --chunk-radius 2`
- `swift run -c release PebbleLab -- --scenario chunk_smoke --chunk-radius -1`

Result: Radius `0` produced one ready chunk. Radius `1` produced nine ready
chunks and area summary metrics. Invalid radii failed with readable errors.

Known limits: Radius is intentionally capped at `1`, and PebbleLab still does
not resolve worldgen entity specs or block entity specs.

Decision: Keep chunk area generation small and explicit until scenario/log
contracts are more mature.

## 2026-06-17 - `chunk_smoke` World Snapshot

Summary: Added `world_snapshot.json` for `chunk_smoke` runs with `--out`. The
snapshot describes the generated chunk area in stable JSON, including global
run context, center terrain data, and one entry per generated chunk.

Files touched:

- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/main.swift`
- `docs/PEBBLELAB_JOURNAL.md`
- `docs/PEBBLELAB_CHANGELOG.md`

Validation:

- `swift build`
- `swift run -c release PebbleLab -- --seed 42 --ticks 3 --scenario empty --out runs/smoke_empty_snapshot`
- `swift run -c release PebbleLab -- --seed 42 --ticks 3 --scenario chunk_smoke --chunk-radius 0 --out runs/smoke_snapshot_radius0`
- `swift run -c release PebbleLab -- --seed 42 --ticks 3 --scenario chunk_smoke --chunk-radius 1 --out runs/smoke_snapshot_radius1`
- `cat runs/smoke_snapshot_radius0/world_snapshot.json`
- `cat runs/smoke_snapshot_radius1/world_snapshot.json`
- `cat runs/smoke_snapshot_radius1/metrics.json`
- `cat runs/smoke_snapshot_radius1/events.ndjson`

Result: `empty` still ran without a snapshot. `chunk_smoke` wrote
`world_snapshot.json`; radius `0` contained one chunk and radius `1` contained
nine sorted chunk entries.

Known limits: The snapshot is terrain/chunk oriented only. It does not include
entities, block entities, inventories, or pathfinding data.

Decision: Keep snapshots as simple read-only observability artifacts before
introducing agents.

## 2026-06-17 - `agent_smoke` Abstract Agent

Summary: Added the first PebbleLab-only abstract agent scenario, `agent_smoke`.
The scenario generates a chunk area like `chunk_smoke`, spawns one
`abstract_lab_agent` at the world center, ticks simple needs, logs agent events,
and writes `agent_snapshot.json`.

Files touched:

- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/LabAgent.swift`
- `Sources/PebbleLab/main.swift`
- `docs/PEBBLELAB_JOURNAL.md`
- `docs/PEBBLELAB_CHANGELOG.md`
- `docs/PEBBLELAB_NEXT.md`

Validation:

- `swift build`
- `swift run -c release PebbleLab -- --help`
- `swift run -c release PebbleLab -- --seed 42 --ticks 3 --scenario empty --out runs/smoke_empty_after_agent`
- `swift run -c release PebbleLab -- --seed 42 --ticks 3 --scenario chunk_smoke --chunk-radius 1 --out runs/smoke_chunk_after_agent`
- `swift run -c release PebbleLab -- --seed 42 --ticks 3 --scenario agent_smoke --out runs/smoke_agent`

Result: `empty` and `chunk_smoke` still worked. `agent_smoke` produced
`world_snapshot.json`, `agent_snapshot.json`, agent metrics, `agent_spawned`,
three `agent_tick` events for three ticks, and `agent_snapshot_written`.

Known limits: The agent is not a PebbleCore entity, does not move, has no
pathfinding, and has no AI policy. Needs are simple deterministic counters.

Decision: Introduce agents as PebbleLab-only abstract state before considering
physical entities or pathfinding.

## 2026-06-17 - Agent Observation V0

Summary: Added a first local deterministic observation for `agent_smoke`.
The abstract agent now observes its own position, current chunk, chunk
readiness, terrain height/surface, and raw cells below/at its feet.

Files touched:

- `Sources/PebbleLab/LabAgent.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/main.swift`
- `docs/PEBBLELAB_JOURNAL.md`
- `docs/PEBBLELAB_CHANGELOG.md`
- `docs/PEBBLELAB_NEXT.md`

Validation:

- `swift build`
- `swift run -c release PebbleLab -- --seed 42 --ticks 3 --scenario empty --out runs/smoke_empty_after_observation`
- `swift run -c release PebbleLab -- --seed 42 --ticks 3 --scenario chunk_smoke --chunk-radius 1 --out runs/smoke_chunk_after_observation`
- `swift run -c release PebbleLab -- --seed 42 --ticks 3 --scenario agent_smoke --out runs/smoke_agent_observation`

Result: `agent_snapshot.json` includes the final observation. `events.ndjson`
contains `agent_observed` events. Metrics include observation count and current
agent terrain/chunk data.

Known limits: Observation is local and raw. It does not include pathfinding,
semantic block names, inventory, nearby entities, or policy decisions.

Decision: Keep perception as PebbleLab-only read-only state before adding
abstract actions.

## 2026-06-17 - Agent Abstract Action V0

Summary: Added the first deterministic abstract action decision for
`agent_smoke`. The agent now updates needs, observes the local world, then
chooses one of `observe_area`, `wait`, or `rest` without moving or changing the
world.

Files touched:

- `Sources/PebbleLab/LabAgent.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/main.swift`
- `docs/PEBBLELAB_JOURNAL.md`
- `docs/PEBBLELAB_CHANGELOG.md`
- `docs/PEBBLELAB_NEXT.md`

Validation:

- `swift build`
- `swift run -c release PebbleLab -- --seed 42 --ticks 3 --scenario empty --out runs/smoke_empty_after_action`
- `swift run -c release PebbleLab -- --seed 42 --ticks 3 --scenario chunk_smoke --chunk-radius 1 --out runs/smoke_chunk_after_action`
- `swift run -c release PebbleLab -- --seed 42 --ticks 3 --scenario agent_smoke --out runs/smoke_agent_action`

Result: `agent_snapshot.json` includes `lastAction` and `actionCount`.
`events.ndjson` includes `agent_action_chosen` events, and metrics include
`agentActions` and `agentLastAction`.

Known limits: Actions are abstract decisions only. They do not execute physical
movement, pathfinding, block changes, memory updates, communication, or social
interaction.

Decision: Keep the loop order stable as needs tick, observation, then abstract
decision.

## 2026-06-17 - Agent Memory V0

Summary: Added a first deterministic in-memory memory list to the
PebbleLab-only `LabAgent`. The agent records local memories for spawn,
observation, and abstract action choices.

Files touched:

- `Sources/PebbleLab/LabAgent.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/main.swift`
- `docs/PEBBLELAB_JOURNAL.md`
- `docs/PEBBLELAB_CHANGELOG.md`
- `docs/PEBBLELAB_NEXT.md`
- `docs/PEBBLELAB_SOCIAL_AGENTS.md`

Validation:

- `swift build`
- `swift run -c release PebbleLab -- --seed 42 --ticks 3 --scenario empty --out runs/smoke_empty_after_memory`
- `swift run -c release PebbleLab -- --seed 42 --ticks 3 --scenario chunk_smoke --chunk-radius 1 --out runs/smoke_chunk_after_memory`
- `swift run -c release PebbleLab -- --seed 42 --ticks 3 --scenario agent_smoke --out runs/smoke_agent_memory`

Result: `agent_snapshot.json` includes `memoryCount` and `recentMemory`.
`events.ndjson` includes `agent_memory_recorded`, and metrics include
`agentMemoryEntries` and `agentLastMemoryType`.

Known limits: Memory is local, in RAM, and only persisted through the agent
snapshot. It is not social memory, does not connect agents, and does not affect
action decisions yet.

Decision: Keep memory as a simple PebbleLab-only record before adding
multi-agent interaction or communication.

## 2026-06-17 - Agent Internal Action Effects V0

Summary: Added deterministic internal effects for abstract `agent_smoke`
actions. Effects update only the PebbleLab agent's needs/state and do not
change world blocks, chunks, entities, or PebbleCore.

Files touched:

- `Sources/PebbleLab/LabAgent.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/main.swift`
- `docs/PEBBLELAB_JOURNAL.md`
- `docs/PEBBLELAB_CHANGELOG.md`
- `docs/PEBBLELAB_NEXT.md`

Validation:

- `swift build`
- `swift run -c release PebbleLab -- --seed 42 --ticks 3 --scenario empty --out runs/smoke_empty_after_action_effect`
- `swift run -c release PebbleLab -- --seed 42 --ticks 3 --scenario chunk_smoke --chunk-radius 1 --out runs/smoke_chunk_after_action_effect`
- `swift run -c release PebbleLab -- --seed 42 --ticks 3 --scenario agent_smoke --out runs/smoke_agent_action_effect`

Result: `agent_snapshot.json` includes `lastActionEffect` and
`actionEffectCount`. `events.ndjson` includes
`agent_action_effect_applied`, and metrics include `agentActionEffects` and
`agentLastActionEffect`.

Known limits: Effects are internal only. There is still no movement,
pathfinding, world modification, second agent, communication, or social
relationship.

Decision: Keep the loop order stable as needs tick, observation, action
decision, then internal effect application.

## 2026-06-17 - Passive Multi-Agent V0

Summary: Updated `agent_smoke` to spawn two PebbleLab-only abstract agents,
`agent_0` and `agent_1`. Both agents run the same internal loop independently:
needs tick, observation, action decision, action effect, and memory recording.

Files touched:

- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/main.swift`
- `docs/PEBBLELAB_JOURNAL.md`
- `docs/PEBBLELAB_CHANGELOG.md`
- `docs/PEBBLELAB_NEXT.md`

Validation:

- `swift build`
- `swift run -c release PebbleLab -- --seed 42 --ticks 3 --scenario empty --out runs/smoke_empty_after_second_agent`
- `swift run -c release PebbleLab -- --seed 42 --ticks 3 --scenario chunk_smoke --chunk-radius 1 --out runs/smoke_chunk_after_second_agent`
- `swift run -c release PebbleLab -- --seed 42 --ticks 3 --scenario agent_smoke --out runs/smoke_agent_second`

Result: `agent_snapshot.json` contains both agents. Agent events include
`agentId`, so events remain separable. Metrics such as ticks, observations,
actions, action effects, and memory entries are now totals across both agents.

Known limits: The agents do not interact. There is no communication, social
relationship, pathfinding, movement, or world effect.

Decision: Introduce passive multi-agent handling before adding any
agent-agent interaction.
