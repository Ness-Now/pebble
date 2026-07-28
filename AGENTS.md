# PebbleLab — Codex instructions

## Start and scope

Read [`CODEX_START_HERE.md`](CODEX_START_HERE.md), then
[`CURRENT_STATE.md`](docs/pebblelab/CURRENT_STATE.md), before defining work.
Read this file and every nearer `AGENTS.md` for each touched path. Local rules
narrow responsibility; they do not override root safety rules.

Pebble Civilization extends Pebble into a deterministic, observable
civilization simulation. The canonical branch is `lab/pebblelab-v1`, but every
mission must verify the requested remote and exact starting HEAD rather than
trust documentation.

## Permanent ownership

- `PebbleCore`: physical truth — World, chunks, blocks, items, entities,
  physics, gameplay rules and World persistence.
- `Pebble`: live sensors, adapters and physical executors; it prevalidates,
  mutates, verifies and rolls back World operations.
- `PebbleAgents`: pure deterministic cognition and civilization. It never
  reads or mutates a live World directly.
- `AgentSimulationSession`: sole civilization aggregate root and shared
  transition owner. Never create a second agent kernel or cognitive owner.
- `PebbleLab`: deterministic headless scenarios, reports and evaluation.
- `pebsmoke`: invariants, regressions and fault injection.

## Engineering invariants

- Reuse Pebble systems first. Audit the owning PebbleCore surface before
  creating any physical mechanic; prefer an existing mechanic, a Pebble
  adapter or the smallest actor-neutral Core primitive.
- Never create parallel live farming, crafting, inventory, combat, animal,
  redstone, rail, World-persistence or general physical-pathfinding engines.
- Preserve deterministic ordering and registration order. Seed randomness,
  bound searches and collections, and define persistence/compaction where
  bounds are inappropriate.
- Simulate causes rather than imposing social outcomes. Information is local;
  matter, identity, obligations and provenance remain reconcilable.
- World mutations are bounded, prevalidated, transactional and owned by one
  adapter. Publish civilization state only after physical verification.
  Failed or lifecycle-ending mutations require verified rollback; unverifiable
  rollback is a hard failure.
- A future LLM remains optional, replaceable and subordinate. It never owns
  transactions, cognition or the World.
- Never use `PEBBLE_REGOLD`, regenerate a golden, or weaken an existing proof
  to make a change pass.

## Git and delivery

- Before editing, verify `pwd`, branch, HEAD, relevant remote ref and
  `git status --short`.
- Codex never pushes. The user owns publication.
- Do not autonomously rebase, hard reset, destructively clean or overwrite
  unrelated user changes.
- Keep commits coherent and reviewable. Choose their number from the work;
  there is no rigid maximum.
- Do not mix a product phase, an unrelated correction and roadmap
  canonization in one change.

## Validation

Apply validation proportionally to actual risk:

- docs/contracts: parse, link, consistency and diff checks;
- deterministic runtime: focused tests and the canonical repository gate;
- live/physical/visible work: applicable live proof plus the canonical
  [`Visual Game Smoke Policy V5`](docs/pebblelab/VISUAL_GAME_SMOKE_POLICY.md).

The canonical headless gate is `scripts/verify-pebblelab.sh`. The live launcher
is `scripts/verify-pebblelab-live.sh`; use its dry-run before an explicit live
campaign and follow the live runbook. Report exact commands, results, changed
files, commits, final Git state and `Push attempted: NO`.
