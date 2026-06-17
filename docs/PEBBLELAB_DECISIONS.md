# PebbleLab Decisions

This document records project decisions that should guide future PebbleLab work.

## Stay Swift And Mac-First

Pebble remains a Swift project. Pebble is still the macOS AppKit/Metal game and
visualizer. PebbleLab should grow inside the same SwiftPM package.

Reason: keep the prototype close to the deterministic engine and avoid a
premature platform split.

## Do Not Port Windows Now

No Windows port is planned for the current PebbleLab phase.

Reason: the immediate goal is a stable headless simulation path on the existing
Mac/Swift codebase.

## Use PebbleCore As The Deterministic Base

PebbleCore is the simulation base for worlds, chunks, blocks, entities, and
systems.

Reason: it already contains the deterministic engine. PebbleLab should reuse it
instead of recreating simulation logic.

## Keep PebbleLab Separate From Pebble

PebbleLab must not depend on the `Pebble` executable target and must not import
AppKit, Metal, MetalKit, or AVFoundation.

Reason: the runner should stay headless and usable without the game shell.

## Start With `World`, Not `GameCore`

The first runner uses `World(dim: .overworld, seed: ...)` and `world.tick()`
directly.

Reason: `GameCore` is closer to the complete game loop, but it carries a broad
`GameHost` boundary and encapsulated app-oriented orchestration. `World` direct
keeps early patches small.

## No Active Python At The Start

Python is deferred to later read-only analysis and possible offline training.

Reason: first stabilize Swift headless runs, scenario outputs, and logs.

## No RL, LLM Planner, Or Agents At The Start

PebbleLab begins with scenarios and observability, not learning or autonomy.

Reason: agents need stable worlds, logs, metrics, and scenario contracts first.

## Keep External AI Projects As Inspiration Only

MineRL, MineDojo, mineflayer, mineflayer-pathfinder, Voyager, Baritone, VPT,
MineCLIP, and STEVE-1 are references, not dependencies.

Reason: avoid importing a large non-Swift stack before PebbleLab has its own
stable headless foundation.

## Keep Local Outputs Out Of Git

`runs/` and `models/` are ignored.

Reason: run artifacts and future model files are local/generated data.

## `chunk_smoke` Does Not Force Chunk Generation Yet

The current `chunk_smoke` scenario probes public chunk access but does not
generate or load chunks.

Reason: no simple public generation API has been adopted for PebbleLab yet, and
PebbleCore should not be changed just to make the first scenario more active.
