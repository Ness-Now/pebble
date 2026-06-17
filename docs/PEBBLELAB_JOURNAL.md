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
