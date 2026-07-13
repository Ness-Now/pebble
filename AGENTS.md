# PebbleLab — Codex instructions

## Objective and architecture

PebbleLab Society V1 builds a deterministic, observable society simulation while preserving the original Pebble game.

The package has five targets:

- `PebbleCore`: deterministic game engine and `World` implementation.
- `PebbleAgents`: pure shared agent runtime; `AgentSimulationSession` is the cognitive state and transition source of truth.
- `Pebble`: macOS/Metal game plus live adapters and physical executors.
- `PebbleLab`: deterministic headless runner, reports, and fixtures.
- `pebsmoke`: frozen-baseline and shared-runtime regression harness.

Read this file first, then the nearest target-local `AGENTS.md` for every file in scope. Never create a second agent kernel or a second owner of cognitive state.

## Git and change discipline

- Laboratory work uses branch `lab/pebblelab-v1`.
- Before editing, run `pwd`, `git branch --show-current`, `git rev-parse HEAD`, and `git status --short`; honor any task-specific path, HEAD, and cleanliness requirements.
- Codex must never push. The user owns pushes and remote publication.
- Do not autonomously run `git rebase`, `git reset --hard`, or `git clean -fd`.
- Keep one functional vertical per change: contract, implementation, focused evidence, regression evidence, and documentation belong together. Do not mix unrelated refactors.
- Prefer small additions over rewrites. The normal range is 1–3 reviewable commits unless the task sets a stricter limit.

## Runtime safeguards

- Preserve PebbleCore determinism and registration order for blocks, items, entities, and biomes.
- Gates for laboratory behavior remain disabled by default and require explicit opt-in.
- World mutations must be bounded, prevalidated, transactional, and owned by one adapter. Publish shared state only after the World mutation is verified.
- Every failed or lifecycle-ending World mutation must run a verified rollback. A rollback that cannot be verified is a hard failure, never a warning.
- Never set or use `PEBBLE_REGOLD`, regenerate goldens, or change a golden to make a test pass.
- Do not change rendering, audio, resource packs, registries, save/load, or packaging unless the task explicitly authorizes that surface.

## Permanent validation and reporting

- Run `scripts/verify-pebblelab.sh` for the full local headless gate.
- Use `scripts/verify-pebblelab-live.sh --dry-run` before any explicit live validation, then follow `docs/pebblelab-3d-live-prototype.md`.
- Report at minimum: initial/final Git state, commits and changed files, behavior and boundary confirmation, every validation command with exact result/exit status, final diff, and whether a push was attempted.
