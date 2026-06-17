# PebbleLab Overview

PebbleLab is the headless simulation laboratory for Pebble. Its job is to run
small, deterministic scenarios on top of PebbleCore without starting the macOS
game, renderer, UI, audio, resource packs, or packaging flow.

## What PebbleLab Is

- A SwiftPM executable target named `PebbleLab`.
- A headless runner that depends on `PebbleCore` only.
- A place to develop reproducible simulation scenarios, metrics, and logs.
- The future entry point for abstract agents, needs, memory, roles, tasks,
  construction experiments, and social behavior simulations.

## What PebbleLab Is Not Yet

- Not a visualizer.
- Not an agent framework.
- Not a reinforcement learning environment.
- Not a Python integration point yet.
- Not a MineRL, MineDojo, mineflayer, Voyager, Baritone, VPT, MineCLIP, or
  STEVE-1 integration.
- Not a replacement for the existing Pebble macOS game.

## Current Architecture

- `PebbleCore`: deterministic engine layer for world state, blocks, chunks,
  entities, systems, and core simulation APIs.
- `Pebble`: existing macOS AppKit/Metal/UI/audio game and visualizer.
- `PebbleLab`: headless SwiftPM executable for scenario runs and local outputs.

PebbleLab must not depend on the `Pebble` target. It imports `Foundation` and
`PebbleCore`, and currently creates a `World` directly rather than going through
`GameCore`.

## Current CLI

```sh
swift run -c release PebbleLab -- --seed 42 --ticks 100 --scenario empty
swift run -c release PebbleLab -- --seed 42 --ticks 100 --scenario chunk_smoke --out runs/example
```

Supported options:

- `--help`
- `--seed <UInt32>`; default `12345`
- `--ticks <Int>`; default `20`
- `--scenario <String>`; currently `empty` or `chunk_smoke`
- `--out <path>`; optional run output directory

## Current Output Files

When `--out <path>` is provided, PebbleLab writes:

- `config.json`: requested scenario, seed, tick count, and output path.
- `metrics.json`: run result summary, including requested/completed ticks,
  world time, success, and optional scenario metrics.
- `events.ndjson`: one JSON object per line, currently including
  `run_started`, optional scenario events, per-tick `world_tick`, and
  `run_finished`.

When `--out` is omitted, PebbleLab runs without creating files.

## Current Scenarios

- `empty`: creates an overworld `World`, ticks it, and records base metrics.
- `chunk_smoke`: keeps the scenario distinct and probes public chunk access, but
  does not force real chunk generation yet.

## Known Limits

- `chunk_smoke` currently reports `chunksTouched = 0` because no confirmed
  public PebbleCore API is used to force chunk generation.
- PebbleLab does not yet create entities, agents, tasks, or structures.
- Run outputs are local artifacts and should stay out of git.
- Python analysis and training are intentionally deferred.
