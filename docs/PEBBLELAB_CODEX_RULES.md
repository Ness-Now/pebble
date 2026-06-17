# PebbleLab Codex Rules

These rules are for Codex-assisted work on PebbleLab.

## Working Style

- Keep every patch small and reviewable.
- Read the relevant project docs before changing architecture, scenarios, logs,
  outputs, or decisions.
- Always list files that are allowed and files that are forbidden for a task.
- Include a Definition of Done for non-trivial changes.
- Report every command executed and its result.
- Do not commit or push unless explicitly asked.

## Project Boundaries

- Do not touch `Sources/Pebble` unless explicitly asked.
- Do not touch rendering, Metal, AppKit, UI, audio, resource packs, or packaging
  unless explicitly asked.
- Do not make PebbleLab depend on the `Pebble` target.
- Do not import AppKit, Metal, MetalKit, or AVFoundation in PebbleLab.
- Prefer PebbleLab-side additions before modifying PebbleCore.

## Determinism And Baselines

- Do not touch registries unless explicitly asked.
- Do not reorder block, item, entity, or biome registrations.
- Never use `PEBBLE_REGOLD` unless explicitly instructed.
- Do not modify goldens to make tests pass.
- Keep PebbleCore deterministic.

## Patch Discipline

- Do not mix refactor and feature work unless explicitly requested.
- Do not introduce heavy abstractions before there is real duplication.
- Do not create agents, LabHuman, Python integration, RL loops, LLM planners, or
  model code before the scenario/log foundation is stable.
- Keep output formats stable unless the task explicitly changes them.

## Validation

- Run `swift build` after structural changes.
- Run `swift run -c release PebbleLab -- --help` after CLI changes when allowed.
- Run a small scenario with `--out` after output/log changes when allowed.
- Run `swift run -c release pebsmoke` after PebbleCore simulation changes.

## Documentation Updates

Update the PebbleLab docs when a patch changes:

- architecture
- scenario behavior
- output files or formats
- CLI options
- project decisions
- known limits
- recommended next steps
