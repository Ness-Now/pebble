# PebbleLab development workflow

## Canonical direction

Read the current [`Pebble Civilization vision`](PEBBLE_CIVILIZATION_VISION.md),
[`prospective roadmap`](PEBBLE_CIVILIZATION_ROADMAP.md), and
[`documentation index`](DOCUMENTATION_INDEX.md) before defining a mission.
`PebbleLab Society V1` is the intermediate social milestone;
`Medieval Civilization V1` is the long-term product destination.

New missions use the `CIV-XX` convention. A mission must not produce only
documentary ceremony unless that work directly reduces a real delivery or
architecture risk, as `CIV-00` does by removing conflicting project direction.

## Read and scope

Read the repository `AGENTS.md` first, then every `AGENTS.md` from the repository root down to each file being changed. The target-local file narrows responsibility; it does not override root safety rules.

Work in one functional vertical at a time. State the allowed and forbidden surfaces before implementation, keep gates default-off, and stop if the requested Git path, branch, HEAD, or cleanliness invariant does not match.

Every new physical vertical begins with a targeted audit of the relevant
PebbleCore mechanics. Prefer reuse, a minimal actor-neutral extraction, or a
Pebble adapter before proposing any new physical implementation.

For live navigation, Civilization owns intent, destination and coarse
waypoints; PebbleCore pathfinding, collision and entity movement own the
physical route and resulting position. Validate identity and World ownership
through a Pebble embodiment adapter, then publish only verified physical
outcomes to `AgentSimulationSession`. Never use ordinary `setPos` as movement
or teleport fallback.

## Delivery cycle

1. ChatGPT defines the product vertical, boundaries, evidence, and Definition of Done.
2. Codex verifies Git state, reads the applicable rules, implements a small patch, and validates it locally.
3. Codex reports exact local commands, exit statuses, diff, commits, and remaining manual evidence. Codex never pushes.
4. The user reviews and pushes the local commits.
5. A GitHub audit checks the pushed SHA, remote diff, checks, and review evidence.

A local result reported by Codex is evidence about one workspace and one command execution. GitHub proof is evidence attached to the user-pushed remote SHA. Neither should be presented as the other.

The normal implementation sequence is preflight, targeted reuse audit,
implementation, focused tests, then one justified full gate at the end. Avoid
an audit of an audit, repeated full suites after micro-fixes, and live
validation when no live boundary changed. One vertical normally produces one
to three reviewable commits.

## Permanent validation

Run the complete headless gate once at the end of a runtime or tooling vertical
from the repository root:

```bash
scripts/verify-pebblelab.sh
```

It refuses any defined `PEBBLE_REGOLD`, builds all relevant products, runs `pebsmoke`, runs `agents_basic` twice with seed 42 and compares its canonical sorted outputs, runs the existing `regression_smoke` business checks, performs repository hygiene checks, and writes evidence only to a temporary directory outside the repository.

For a docs/contracts-only mission that touches no executable, configuration,
runtime, test baseline, or generated artifact, use targeted Markdown/JSON and
Git diff checks; do not run a Swift build merely because documentation changed
unless the mission explicitly requires the full gate.

There is no dedicated historical hash file for `agents_basic`. The retained mechanism deliberately uses the existing in-process `regression_smoke` report as the canonical business baseline and byte-compares deterministic `agents_basic` replays; it does not duplicate golden hashes.

For live work, inspect the plan before launching:

```bash
scripts/verify-pebblelab-live.sh --dry-run
scripts/verify-pebblelab-live.sh
```

The launcher isolates Pebble data, requires a `PebbleLab-*` disposable world with a fixed seed, reuses only existing command/capture hooks, and leaves visual and trace interpretation to the operator. It never opens or deletes a personal world. Follow the canonical [live runbook](../pebblelab-3d-live-prototype.md).

## Risk and commits

- Risk A — docs and rules with no executable or runtime behavior change:
  targeted format, manifest, link, and diff checks; normally one commit.
- Risk B — shared deterministic runtime or default-off app adapters: full gate plus focused scenario evidence and live dry-run when relevant; normally one or two commits.
- Risk C — World mutation, lifecycle/persistence boundaries, rendering/assets, registries, packaging, or golden-sensitive behavior: explicit authorization, bounded transaction and verified rollback evidence, full gate, and honest manual live proof where automation ends; normally one to three commits.

Never push from Codex. Never use autonomous rebase, destructive Git cleanup, or golden regeneration as a shortcut.
