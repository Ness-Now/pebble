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

## Changed

- PebbleLab runner code was split into smaller files without changing behavior.
- Help text now lists both supported scenarios.
- `metrics.json` can include optional scenario metrics such as `chunksTouched`
  and `chunkRadius`.
- `chunk_smoke` metrics now reflect an adopted origin chunk instead of a passive
  chunk lookup.
- `chunk_smoke` emits one `chunk_smoke_chunk_adopted` event per adopted chunk.

## Fixed

- Standalone SwiftPM argument separator `--` is ignored by PebbleLab parsing.

## Known Limitations

- `chunk_smoke` generates one chunk only; it does not resolve worldgen entities
  or block entities.
- `--chunk-radius` is capped at `1` for now.
- No agents, needs, memory, roles, tasks, pathfinding, or social behavior.
- No Python analysis or training pipeline yet.
- No visual replay or Pebble viewer integration yet.
- Event logging is intentionally minimal.
- PebbleLab currently uses `World` directly rather than `GameCore`.
