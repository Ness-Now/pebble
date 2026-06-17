# PebbleLab Overview

PebbleLab is a headless simulation runner built on top of PebbleCore. Its purpose is to make Pebble usable as a deterministic voxel simulation laboratory without changing the original macOS game.

PebbleLab is not the game renderer, not a Metal/AppKit application, not an audio layer, and not a Python or ML runtime. It is a small SwiftPM executable that creates PebbleCore worlds, runs scenarios, and writes local run outputs for inspection.

## Current Architecture

- `PebbleCore`: deterministic engine layer for worlds, chunks, blocks, entities, systems, and generation APIs.
- `Pebble`: existing macOS/Metal game and visualizer.
- `PebbleLab`: headless SwiftPM executable that depends on `PebbleCore` only.

PebbleLab must remain separate from `Pebble`. It must not import AppKit, Metal, MetalKit, AVFoundation, or depend on the game target.

## Current CLI

PebbleLab currently supports:

- `--help`
- `--seed <UInt32>`
- `--ticks <Int>`
- `--scenario <String>`
- `--out <path>`
- `--chunk-radius <Int>`

Supported scenarios:

- `empty`
- `chunk_smoke`
- `agent_smoke`

`--chunk-radius` is currently limited to `0...1`. For `chunk_smoke`, radius `0` generates the origin chunk and radius `1` generates a 3x3 area around the origin. For `agent_smoke`, the default radius is `1` unless explicitly overridden.

## Current Scenarios

### empty

Creates an overworld `World`, ticks it, and exits. It is the smallest smoke test for the PebbleLab executable path.

### chunk_smoke

Initializes the minimal block and biome registries, generates chunks around the origin with public PebbleCore APIs, adopts them into the world, initializes chunk lighting, ticks the world, and records chunk metrics.

### agent_smoke

Generates a small world area, creates one abstract PebbleLab-only agent named `agent_0`, ticks simple needs, observes the local environment, and writes agent output. The agent is not a PebbleCore entity, does not move, does not pathfind, and does not use AI.

## Current Output Files

When `--out <path>` is provided, PebbleLab writes local run files.

- `config.json`: run configuration such as scenario, seed, ticks, output path, and chunk radius.
- `metrics.json`: run metrics such as ticks completed, world time, chunk readiness, agent counts, and observation fields when available.
- `events.ndjson`: newline-delimited run events, one JSON object per line.
- `world_snapshot.json`: generated world-area snapshot for scenarios that create observable chunks.
- `agent_snapshot.json`: abstract agent snapshot for `agent_smoke`.

`world_snapshot.json` is currently produced for `chunk_smoke` and `agent_smoke`. `agent_snapshot.json` is currently produced for `agent_smoke`.

## Current Agent Observation

`agent_smoke` records a local deterministic observation for the abstract agent:

- position
- current chunk coordinates
- current chunk readiness
- `surfaceY`
- `height`
- raw block below the agent
- raw block at the agent feet

Raw block values are intentionally acceptable at this stage. PebbleLab does not yet require human-readable block names for agent perception.

## Known Limits

- Agents are abstract PebbleLab structs, not PebbleCore entities.
- No movement.
- No pathfinding.
- No AI planner.
- No LLM planner.
- No reinforcement learning.
- No Python runtime integration.
- No communication between agents.
- No memory system.
- No roles or tasks.
- No social relationships.
- No public/private messages.
- No trust, friendship, betrayal, reputation, or group mechanics.
- `--chunk-radius` is intentionally capped at `1`.
- PebbleLab does not reproduce the full game streaming pipeline.
- PebbleLab must not modify registries, goldens, rendering, audio, resource packs, or packaging unless explicitly requested.

## Direction

The near-term goal is to keep PebbleLab small, deterministic, and inspectable:

1. stable headless world runs;
2. reproducible scenarios;
3. reliable metrics and logs;
4. observable generated areas;
5. abstract agents;
6. local perception;
7. simple abstract actions;
8. memory and interaction;
9. social communication later;
10. offline analysis and training only after the simulation/logging foundation is stable.
