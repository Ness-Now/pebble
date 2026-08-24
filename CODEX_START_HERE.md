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

- Gates R, B, C, D and E are acquired and published.
- `CIV-00` through `CIV-37` are complete and published in their bounded
  contracts.
- post-Gate-B safe-bootstrap hardening is published.
- `CIV-38` is optional and not started.
- `CIV-39` is complete and published at independently remote-verified
  canonical HEAD `0b0ec535cda62b70add182875c65eaee27bb5bb2`.
- Gate F Evaluation 01 is `FAIL — HISTORICAL IMMUTABLE EVIDENCE`.
- Gate F Blocker 01 is **FIXED + PUBLISHED + REMOTE VERIFIED** at canonical
  HEAD `690c431d47f2e9edf9b1a9a9e91c71876981d09c`.
- Gate F Evaluation 02 is `FAIL — HISTORICAL IMMUTABLE EVIDENCE`.
- Gate F Blocker 02 is **FIXED + PUBLISHED + REMOTE VERIFIED** at canonical
  HEAD `40ae812205abe231317e0d1720b5db4cecf9f24d`.
- Gate F Evaluation 03 is `FAIL — HISTORICAL IMMUTABLE EVIDENCE`.
- Gate F Blocker 03 is **FIXED + PUBLISHED + REMOTE VERIFIED** at canonical
  HEAD `2c6fe63e81b20ee4a37315a6f5ad528a721c2355`.
- Gate F Evaluation 04 is `FAIL — HISTORICAL IMMUTABLE EVIDENCE`.
- Gate F Blocker 04 is **FIXED + PUBLISHED + REMOTE VERIFIED** at canonical
  HEAD `d7fac42493b229ce36ece5c21c597284e5ad7cb5`.
- Gate F Evaluation 05 is `FAIL — HISTORICAL IMMUTABLE EVIDENCE` against
  baseline `937693d6030f8ba77f1363da7f4336647962ee9e`.
- Gate F Blocker 05 is **FIXED + PUBLISHED + REMOTE VERIFIED** at product/test/
  runtime commit `b1f3fad3ec4959c1ecf43e91eac0d291d6f9acf4` and canonical HEAD
  `df1c042c0f8d4f45ad8928c9fb7d0bbe5558af8b`.
- Gate F Evaluation 06 is `FAIL — HISTORICAL IMMUTABLE EVIDENCE` against
  baseline `31f785ca9051be6b4f39ab97102f89410a776824`.
- Gate F Blocker 06 is **FIXED + PUBLISHED + REMOTE VERIFIED** at product/test/
  runtime commit `647dade73afa4d8e044423f422292dbf0c08f43e` and canonical HEAD
  `fe5bca7074b8ac65c31e03299195c3d7cfe307b1`.
- `CIV-40` is optional tooling and not started.
- `CIV-41` is not started.
- Gate F remains planned and not acquired; Evaluation 07 has not been
  performed.
- The next authorized action is
  `NEW-INDEPENDENT-V4-GATE-F-v1-EVALUATION-07`. Do not infer that optional
  `CIV-40` is a prerequisite.

Historical Gate B `FAIL` reports and the closure-candidate report are preserved
as evidence of their own evaluations. They do not reopen Gate B.

Gate E acquisition is published and independently remote verified at canonical
HEAD `076a616a97a229e921a5c36eebdfd12f76744f83`. Use Git to verify the current
published branch before every mission.

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
