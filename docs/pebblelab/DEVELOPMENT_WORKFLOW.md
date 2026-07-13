# PebbleLab development workflow

## Read and scope

Read the repository `AGENTS.md` first, then every `AGENTS.md` from the repository root down to each file being changed. The target-local file narrows responsibility; it does not override root safety rules.

Work in one functional vertical at a time. State the allowed and forbidden surfaces before implementation, keep gates default-off, and stop if the requested Git path, branch, HEAD, or cleanliness invariant does not match.

## Delivery cycle

1. ChatGPT defines the product vertical, boundaries, evidence, and Definition of Done.
2. Codex verifies Git state, reads the applicable rules, implements a small patch, and validates it locally.
3. Codex reports exact local commands, exit statuses, diff, commits, and remaining manual evidence. Codex never pushes.
4. The user reviews and pushes the local commits.
5. A GitHub audit checks the pushed SHA, remote diff, checks, and review evidence.

A local result reported by Codex is evidence about one workspace and one command execution. GitHub proof is evidence attached to the user-pushed remote SHA. Neither should be presented as the other.

## Permanent validation

Run the complete headless gate from the repository root:

```bash
scripts/verify-pebblelab.sh
```

It refuses any defined `PEBBLE_REGOLD`, builds all relevant products, runs `pebsmoke`, runs `agents_basic` twice with seed 42 and compares its canonical sorted outputs, runs the existing `regression_smoke` business checks, performs repository hygiene checks, and writes evidence only to a temporary directory outside the repository.

There is no dedicated historical hash file for `agents_basic`. The retained mechanism deliberately uses the existing in-process `regression_smoke` report as the canonical business baseline and byte-compares deterministic `agents_basic` replays; it does not duplicate golden hashes.

For live work, inspect the plan before launching:

```bash
scripts/verify-pebblelab-live.sh --dry-run
scripts/verify-pebblelab-live.sh
```

The launcher isolates Pebble data, requires a `PebbleLab-*` disposable world with a fixed seed, reuses only existing command/capture hooks, and leaves visual and trace interpretation to the operator. It never opens or deletes a personal world. Follow the canonical [live runbook](../pebblelab-3d-live-prototype.md).

## Risk and commits

- Risk A — docs, rules, and local validation tooling with no runtime behavior change: full headless gate; normally one commit.
- Risk B — shared deterministic runtime or default-off app adapters: full gate plus focused scenario evidence and live dry-run when relevant; normally one or two commits.
- Risk C — World mutation, lifecycle/persistence boundaries, rendering/assets, registries, packaging, or golden-sensitive behavior: explicit authorization, bounded transaction and verified rollback evidence, full gate, and honest manual live proof where automation ends; normally one to three commits.

Never push from Codex. Never use autonomous rebase, destructive Git cleanup, or golden regeneration as a shortcut.
