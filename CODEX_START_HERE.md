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
- Gate F Evaluation 07 is `FAIL — HISTORICAL IMMUTABLE EVIDENCE` against
  baseline `c95729fcc38dc9cf5d251601a52e875e2ac9d5d3`.
- Gate F Blocker 07 is **FIXED + PUBLISHED + REMOTE VERIFIED** at product/test/
  runtime-proof commit `61039c10763a478a55ea330ed4ad79881de0efb7` and published
  canonical HEAD `279fb26bea8a817b767a0192d8f7b1cffdff1563`.
- Gate F Evaluation 08 is `FAIL — HISTORICAL IMMUTABLE EVIDENCE` against
  baseline `414954dc936177f892252898e97e8bcf986cee4b`.
- Gate F Blocker 08 is **FIXED + PUBLISHED + REMOTE VERIFIED** at product/test/
  runtime commit `518aaf0dddfcc9f63e133290bf6dd915f9eaa73a` and published
  canonical HEAD `4e3bd296203346e4716c0a186017aebc69dbe750`.
- `CIV-40` is optional tooling and not started.
- `CIV-41` is not started.
- Gate F Evaluation 09 is frozen **FAIL — HISTORICAL IMMUTABLE EVIDENCE**.
- Gate F Blocker 09 is **FIXED + PUBLISHED + REMOTE VERIFIED**, including
  Senior Review Correction 01, at canonical HEAD
  `482adc6617e258a73967e73c9d53cf1466c94f64`. The final review archive SHA-256
  is `09136811d4e6680dc6373e2c728509b91e2557a34a0dd10a9eeb421bd1d446e9`.
- Gate F Evaluation 10 is **FAIL — HISTORICAL IMMUTABLE EVIDENCE** against
  exact baseline `32c75984c56158bf9fde4918f6428e46cc7c1fa4`. Its final evidence
  HEAD is `626ca8785f4e54d0e1f9c5ae8aec56dff22f7ed9`, blocker kind is
  `terminalMortalityPendingMigrationAdmission`, and review archive SHA-256 is
  `39104a2b01f2bbe393f3437faee1daa2892f81505827ad9911ab28a823430d49`.
- Gate F Blocker 10 is **FIXED + PUBLISHED + REMOTE VERIFIED** at product/test/
  runtime commit `470223bae3af44da29fd8830169ed14371dd3403` and canonical HEAD
  `104c919c3017cb73739c8839b47e5a011616e007`. Its final review archive SHA-256
  is `3e214e0f9dc0bc1cd1c885d6ff178fa0fe67ffd103741d88bc0e9618ee2a218d`.
- Gate F Evaluation 11 is **FAIL — HISTORICAL IMMUTABLE EVIDENCE** against
  exact baseline `35993c5652d79a8244f6a6e7f70709a2136a7939`. Its independent
  harness/fresh-process commit is
  `650b4930d1474584eb947ebc2ea531ca10e2a965`, final evidence HEAD is
  `2df178d6524f0c89465fb4508c39e7dc2e362fbf`, blocker kind is
  `terminalMortalityPendingHouseholdAcquisition`, and review archive SHA-256 is
  `a7802f7fa4141edd54d9b7ce67dd7962530253769ae570fe62001c2d5b1c9f3f`.
- Gate F Blocker 11 is **FIXED + PUBLISHED + REMOTE VERIFIED** at product/test/
  runtime commit `7d33d5f584089ad44ffcb0c64fcb00bb4d41779f` and canonical HEAD
  `ab3302ee0c1fdcd90a40ba12dee555f3f445b793`. Its final review archive SHA-256
  is `024f8197be6a5ec4608e5e7deb02196083bf95e15912ceed6dec73bff057c094`.
  The persisted Mortality owner refuses incompatible new Household/current-
  residence authority before publication or identity consumption while
  Household-before-Mortality cleanup remains supported.
- Gate F Evaluation 12 is **PASS — SENIOR REVIEW APPROVED — PUBLISHED EVIDENCE**
  against exact baseline `8733517720487cd7832a57b6d1ddf4b82fe56102`.
  All seven primary attacks, the full Blocker 11→01 matrix, owning coverage,
  the 35-stage verifier and the canonical 24/64/128 scale campaign passed.
  Senior review approved its evidence published at canonical HEAD
  `b31a7e53cfcf7a5c3ab6419f3cb5c0c309f04112`; the accepted archive SHA-256 is
  `ca7e70799220b58c3b090716a2adf19e8abb2609d465b7139d25f7f59988af4c`.
- Gate F is **ACQUIRED AND PUBLISHED — REMOTE VERIFIED** at canonical HEAD
  `14475f4ad5dde9e1063a830ba7e38390cfb4d045`. Optional `CIV-40` remains
  unstarted and is not a prerequisite. `CIV-41` is not started and is the next
  eligible required phase and authorized action; Gate G remains planned.

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
