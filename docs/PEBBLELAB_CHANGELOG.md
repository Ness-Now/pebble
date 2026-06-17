# PebbleLab Changelog

## Added

- `PebbleLab` SwiftPM executable target.
- Minimal headless run using `World(dim: .overworld, seed: 12345)`.
- CLI options: `--help`, `--seed`, `--ticks`, `--scenario`, and `--out`.
- Local run outputs: `config.json`, `metrics.json`, and `events.ndjson`.
- NDJSON events: `run_started`, `world_tick`, `run_finished`, and scenario
  events where needed.
- Split runner files:
  - `LabOptions.swift`
  - `LabOutput.swift`
  - `LabEvents.swift`
  - `LabScenarios.swift`
- Supported scenarios:
  - `empty`
  - `chunk_smoke`
- `chunk_smoke` now generates and adopts the origin chunk `(0,0)` using public
  PebbleCore APIs.
- Additional `chunk_smoke` metrics: `originChunkReady`, `centerHeight`,
  `centerSurfaceY`, and `nonAirBlocks`.
- `chunk_smoke_chunk_adopted` event in `events.ndjson`.
- CLI option `--chunk-radius <Int>` for `chunk_smoke`, currently limited to
  `0...1`.
- `chunk_smoke` can now generate a 3x3 area around origin when
  `--chunk-radius 1` is used.
- Area metrics: `expectedChunks`, `readyChunks`, and `nonAirBlocksTotal`.
- `chunk_smoke_area_ready` summary event in `events.ndjson`.
- `world_snapshot.json` for `chunk_smoke` runs with `--out`, including center
  terrain data and sorted per-chunk summaries.
- `world_snapshot_written` event when a snapshot is emitted.
- `agent_smoke` scenario with one PebbleLab-only abstract agent.
- `LabAgent` v0 with simple deterministic needs: hunger, fatigue, curiosity,
  and safety.
- `agent_snapshot.json` for `agent_smoke` runs.
- Agent events: `agent_spawned`, `agent_tick`, and `agent_snapshot_written`.
- Agent metrics: `agentCount`, `agentsSpawned`, and `agentTicks`.
- Agent observation v0 for `agent_smoke`, including current position, chunk,
  terrain height/surface, and raw cells below/at feet.
- `agent_observed` events.
- Agent observation metrics: `agentObservations`, `agentCurrentChunkReady`,
  `agentSurfaceY`, and `agentHeight`.

## Changed

- PebbleLab runner code was split into smaller files without changing behavior.
- Help text now lists both supported scenarios.
- `metrics.json` can include optional scenario metrics such as `chunksTouched`
  and `chunkRadius`.
- `chunk_smoke` metrics now reflect an adopted origin chunk instead of a passive
  chunk lookup.
- `chunk_smoke` emits one `chunk_smoke_chunk_adopted` event per adopted chunk.
- `chunk_smoke` run outputs now include a stable terrain snapshot for generated
  chunk areas.
- Help text now lists `agent_smoke`.
- `agent_snapshot.json` now includes the final observation for `agent_smoke`.

## Fixed

- Standalone SwiftPM argument separator `--` is ignored by PebbleLab parsing.

## Known Limitations

- `chunk_smoke` generates one chunk only; it does not resolve worldgen entities
  or block entities.
- `--chunk-radius` is capped at `1` for now.
- `world_snapshot.json` does not include entities, block entities, or pathing
  data yet.
- `agent_smoke` agents are abstract PebbleLab records, not PebbleCore entities.
- `agent_smoke` has no movement, pathfinding, or AI policy yet.
- Agent observations are local and raw; they do not include semantic block names
  or navigation data yet.
- No agents, needs, memory, roles, tasks, pathfinding, or social behavior.
- No Python analysis or training pipeline yet.
- No visual replay or Pebble viewer integration yet.
- Event logging is intentionally minimal.
- PebbleLab currently uses `World` directly rather than `GameCore`.
