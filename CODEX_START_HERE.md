# Pebble Civilization — Codex start here

This is the shortest reliable entry point for a new Codex task in
`Ness-Now/pebble`.

## Project

Pebble Civilization extends the open-source Pebble game into a deterministic,
observable civilization simulation. Pebble remains the game and physical
engine; PebbleLab provides deterministic scenarios and evidence around the
shared civilization runtime.

Canonical development branch:

```text
lab/pebblelab-v1
```

Never infer the published HEAD from documentation. Fetch the branch and verify
Git before every mission.

## Authority by question

| Question | Authority |
| --- | --- |
| What is actually implemented? | Code, tests and published GitHub HEAD. |
| How must work be performed? | Root and target-local `AGENTS.md`, then applicable workflows and runbooks. |
| What product are we building? | [`PEBBLE_CIVILIZATION_VISION.md`](docs/pebblelab/PEBBLE_CIVILIZATION_VISION.md). |
| What is the canonical program and status? | [`PEBBLE_CIVILIZATION_ROADMAP.md`](docs/pebblelab/PEBBLE_CIVILIZATION_ROADMAP.md) and [`ROADMAP_MANIFEST.json`](docs/pebblelab/ROADMAP_MANIFEST.json). |
| What is the concise present state? | [`CURRENT_STATE.md`](docs/pebblelab/CURRENT_STATE.md). |
| What happened in an earlier gate or mission? | Versioned evidence and reports. |
| Do old plans or handoffs direct new work? | No. Historical and superseded documents are context only. |

Authority is scoped: a roadmap cannot override code reality, and code reality
does not replace mandatory working rules.

## Current checkpoint

Read [`CURRENT_STATE.md`](docs/pebblelab/CURRENT_STATE.md), not old gate reports,
for the compact status. In particular:

- Gate R and Gate B are acquired and published.
- `CIV-00` through `CIV-26` are complete in their bounded contracts.
- post-Gate-B safe-bootstrap hardening is published.
- `CIV-27` is the next eligible product phase and is not started.

Historical Gate B `FAIL` reports and the closure-candidate report are preserved
as evidence of their own evaluations. They do not reopen Gate B.

## Read by mission type

For every mission:

1. this file;
2. root `AGENTS.md`;
3. every target-local `AGENTS.md` on a touched path;
4. [`CURRENT_STATE.md`](docs/pebblelab/CURRENT_STATE.md);
5. the relevant workflow or runbook.

Then add only what the mission needs:

- product direction or a new phase: vision, roadmap and manifest;
- implementation: [`DEVELOPMENT_WORKFLOW.md`](docs/pebblelab/DEVELOPMENT_WORKFLOW.md);
- mission design or supervision:
  [`METHOD_CODEX_AUTONOMIE_GUIDEE.md`](docs/pebblelab/METHOD_CODEX_AUTONOMIE_GUIDEE.md);
- physical, live, spatial or visible behavior:
  [`VISUAL_GAME_SMOKE_POLICY.md`](docs/pebblelab/VISUAL_GAME_SMOKE_POLICY.md)
  and the applicable live runbook;
- gate or regression review: the exact versioned evidence named by the roadmap
  or [`DOCUMENTATION_INDEX.md`](docs/pebblelab/DOCUMENTATION_INDEX.md).

Do not read the multi-thousand-line historical roadmap by default.

## Permanent operating rules

- Reuse Pebble systems before adding physical mechanics.
- `PebbleCore` owns physical truth.
- `Pebble` owns live sensors, adapters and physical executors.
- `PebbleAgents` owns deterministic cognition and civilization, never World
  mutation.
- `AgentSimulationSession` is the sole civilization aggregate root.
- Keep state deterministic, bounded and causally explainable.
- Validate proportionally to risk.
- Codex creates local reviewable commits when requested but never pushes.

The complete classification of canonical, operational, evidence, historical
and superseded documents is in
[`DOCUMENTATION_INDEX.md`](docs/pebblelab/DOCUMENTATION_INDEX.md).
