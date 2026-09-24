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
- `CIV-41 — Structured Knowledge and Belief Graph V1` is **COMPLETE AND
  PUBLISHED — SENIOR REVIEW APPROVED — REMOTE VERIFIED** at canonical product
  HEAD `87190af6d7b51b57d600d6f39da4ccda71e3f162`. The initial candidate
  `1ce9506824775c1b59eaf5c358f0e8d4edd4eab7` did not pass unchanged; Senior
  Review Correction 01 composed current cognition with finalized mortality
  before approval and publication.
- `CIV-42 — Learned Language Foundations V1` is **COMPLETE AND PUBLISHED —
  SENIOR REVIEW APPROVED — REMOTE VERIFIED** at canonical product HEAD
  `c116b0780facc297dd3e0839ada505673e656189`. Senior Review Correction 01
  strengthened durable provenance but remained blocked; Senior Review
  Correction 02 returned historical belief authority to CIV-41 and anchored
  bounded proof sets through retained causal boundaries. Attacks A–G and the
  canonical repository gate passed. The final review archive SHA-256 is
  `4ac1130589c2f369bce6a4fa9213edb2040be84c936ef5e2728077f95ac3751d`.
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
  unstarted and is not a prerequisite.
- `CIV-43 — Oral Transmission and Distortion V1` is **COMPLETE AND PUBLISHED —
  SENIOR REVIEW APPROVED — REMOTE VERIFIED** at canonical product HEAD
  `9690538a5cfd2a871750ffa839a404f7d19818d5`. Its final accepted review archive
  SHA-256 is
  `1c22063677e95430bb6f220a95c75e07e0512d532d0273accf7c442a9b6fd54a`;
  manual publication completed and exact remote verification passed.
- `CIV-44 — Compositional and Long-Distance Communication V1` is **COMPLETE
  AND PUBLISHED — SENIOR REVIEW APPROVED — REMOTE VERIFIED** at canonical
  product HEAD `0c6a6e88ce838266897526a74d067532163cb06f`.
- `CIV-45 — Writing and Literacy V1` is **COMPLETE AND PUBLISHED — SENIOR
  REVIEW APPROVED — REMOTE VERIFIED** at canonical publication HEAD
  `f43c0a014efbb0123ec21647e326a84e0956cdd6`, from exact implementation baseline
  `9a2cfec10b4a0d1b6a5d2f46aac8f3c312ddbb0e`; local product commit
  `ac38675d88d4b709183e7b26f92a0a45b0e928c1` and initial candidate
  `89cffa47f1e9635e0f44a0fac246e92739501911` remain intact; initial senior
  review returned **CORRECTION REQUIRED**. Correction 01 product/test commit
  `b68a6aeff106f5a3791279d5bd62b8b2916c9a4c` and candidate
  `68bda3e5e7a28af50fed3d9680d2a9a0dfeea4e4` likewise remain intact;
  independent re-review also returned **CORRECTION REQUIRED**. Correction 02
  product/test commit `1e2753586e587a098f3908349d1c647d6b10d253`,
  pre-reconciliation documentation commit
  `9b5607a4c2713fdc94937b4855665ea52e83cb08` and reconciled candidate
  `b9fdccd7c8bef0c5bfc39d40d09e32920a3f4ac2` remain intact; its final senior
  re-review returned **CORRECTION REQUIRED** because physical authority could
  become stale before cognitive publication. Correction 03 product/test commit
  `b29faa532e3f1909e7955015a8f4067e47c21a40` and candidate
  `b502d272998834a6bc70a5c5fc0740924d03caa1` remain intact; its final senior
  re-review returned **CORRECTION REQUIRED** because persistence could capture
  a WRITE candidate before cognitive refusal rolled back and released its
  identity. Correction 04 product/test commit
  `ff68b1d60f7159fec17d0bb98433235f75e767d1` and candidate
  `2a83631ee642e2bc71f7da4c82b01172f35c7bdc` remain intact; its final review
  returned **CORRECTION REQUIRED** because late recovery of an older failed
  chunk snapshot could replace a newer pending snapshot. Correction 05
  product/test commit `01b9826afc4ca96efb0f07556c53073524cbbf97` and candidate
  `cf80aa1f789edd74417bf225ef34a5fad3eac588` remain intact; independent
  re-review returned **CORRECTION REQUIRED** because streaming could re-adopt
  older durable SQLite state after newer B left the pending map but remained
  in flight, and lifecycle recovery could be abandoned by World destruction.
  Correction 06 product/test commit
  `d551a5e9b9d57c64c9ae5bc408949fd8f7b2c0d5` retains the maximum unresolved
  physical capture across pending, queue and in-flight states, routes chunk
  materialization through that horizon, and makes exit, World replacement and
  AppKit termination fail closed until persistence resolves. Candidate
  `a8f153715cf02ec28225cd86e7ba045b715d9323` received **CORRECTION REQUIRED**:
  lifecycle cleanup could mutate physical state after the last barrier,
  cancelled AppKit termination could already have destroyed the civilization,
  and non-chunk write failures could be reported as success. Correction 07
  product/test commit `6890eab1f460a09b2fe01bf02d4a0fd248528ea9`
  moves idempotent physical custody preparation before a final barrier covering
  WorldRecord, Player, Advancements, chunks/index and unresolved persistence;
  irreversible runtime shutdown and World destruction/replacement occur only
  after success. Candidate `c7f497d679a4d0046de6e8ad28e6d9504e3166ff`
  received **CORRECTION REQUIRED** because production streaming could remove a
  non-persistent carried probe from World authority while its controller
  binding survived. Correction 08 product/test commit
  `fe168f72d31fdbc0a1f783b351c0974ec649b1bb` retains each currently incarnated
  probe chunk under normal `streamChunks`, without spill or identity allocation,
  keeps `unloadChunk` general, and makes lifecycle fail closed unless session,
  registry and World probe identities form one exact bijection. Candidate
  `54d9e4ba37340178927411b3bf5f3bd5cedae4c5` received **CORRECTION REQUIRED**
  because synthesized `Decodable` could restore an invalid population
  configuration, including `maximumActivePopulation = 513`, and publish it as
  session authority. Correction 09 product/test commit
  `3d1fdeea7c1e2f833a97b903c1357dd1d0acfe77` decodes all nine persisted
  population-configuration fields through the same validated constructor used
  by normal API construction; the restore registry defense reuses that contract.
  Independent senior re-review returned **PASS — SENIOR REVIEW APPROVED** with
  no blocker, major or minor finding. The senior-approved candidate
  `f43c0a014efbb0123ec21647e326a84e0956cdd6` was published to
  `lab/pebblelab-v1` and independently remote verified. Published progression
  is now complete through CIV-46. CIV-46 is **COMPLETE AND PUBLISHED — SENIOR
  REVIEW APPROVED — REMOTE VERIFIED** at canonical publication HEAD
  `dcdc6a5dc984f8144705bb601ec677f1df767b7f`, from product/test commit
  `1ada83ae248552924a4f729439654ad7ff8abfaa` and reviewed candidate
  `560e5d4a2b42bfd1519077fe6955ff6f9d99bc70`. CIV-47 is **COMPLETE AND
  PUBLISHED — SENIOR REVIEW APPROVED — REMOTE VERIFIED** at canonical
  publication HEAD `51169802ec76770b4c80850c7dee33cf94ee5524`, tree
  `28c2f6800b2a760337e20020f1337d376cecce3d`. Correction 01 was approved at
  reviewed candidate `874a844ba54b66210ac303912193038c9f4ee6e0`, tree
  `fec66e6423e594c568b700ced191fbafd87b5523`, after product/test commit
  `45701f56169218b70f2e698dc0dea67bb1d027c0`, from exact baseline
  `70cb245e089987bc829ac138b0988eb3fc825d57`. Original reviewed candidate
  `27806ac721e8e3570cc31f9e8cac2a001de4d4ca` remains historical **CORRECTION
  REQUIRED — P0 0 / P1 4** evidence; Correction 01 re-review returned **P0 0 /
  P1 0**. Published progression is complete through CIV-47. Gate G Evaluation
  01 remains immutable historical FAIL evidence; Blocker 01 is fixed,
  senior-review approved, published and remote verified; Evaluation 02 is
  senior-review-approved published PASS evidence with remote verification.
  Gate G is **ACQUIRED AND PUBLISHED — SENIOR REVIEW APPROVED — REMOTE
  PUBLICATION VERIFIED** at acquisition canonical HEAD
  `8d8e32b576b384eb9a060f87bde1d42bf15f58f7`.
- `PLAYABLE SLICE 01 — Autonomous Emergence Baseline` is the required non-CIV
  integration milestone in progress. It is **REQUIRED — IN PROGRESS / NOT
  COMPLETE** and is not a gate. Increment 01 is **COMPLETE AND PUBLISHED —
  SENIOR REVIEW APPROVED — REMOTE VERIFIED** at canonical HEAD
  `a5bded01dcfc934dc5aed6aab0990fc61ffd30c7`; its accepted review ZIP SHA-256
  is `bff4786795c9f09239fe8a45e3acd2f8993eabdfb24d7e792d944ca0ea6a81b6`.
  Increment 02, Terminal Population Continuity, is **COMPLETE AND PUBLISHED —
  PASS — SENIOR REVIEW APPROVED — REMOTE VERIFIED** at canonical HEAD
  `056c6b625d7482581028cf149329bc292948d53d`, tree
  `24e92e7c8a1982a886146ba79187f2fcc8987d0f`; its accepted review ZIP SHA-256
  is `47a6fcdb48ede97412cfc5568171eb53086eb2cd1038351bb7580636592de92f`.
  Increment 03, Observer-Independent Physical Coverage, is **COMPLETE AND
  PUBLISHED — PASS — SENIOR REVIEW APPROVED — REMOTE VERIFIED** at canonical
  HEAD `0e7f36202debd088e4f1c84de96078be78b6b6fd`, tree
  `33a3675301a6fe088fde62b373f7e73505ba346d`; its accepted review ZIP SHA-256
  is `4183fedfb071f900afe349b317ecd58e215206efd5afb8427b004c2bcc3c6f04`.
  It establishes one derived PebbleCore coverage schedule for at most 30 roots,
  a one-chunk/3×3 halo and a 270-chunk worst bound, with explicit unavailable
  readiness and no false physical absence. It does not validate arbitrary
  population scale or whole-World camera invariance; future agent-relevant RNG
  consumers still require audit. Increment 04, Need-Driven Physical
  Subsistence, is **COMPLETE AND PUBLISHED — SENIOR REVIEW APPROVED — REMOTE
  VERIFIED** at canonical HEAD
  `b478fcfd75126fb5ab742916930eb8eb08c5f4f2`, tree
  `2d4ef2716412a4c121fc06e6d292418218cfb009`. Normal founders can turn hunger
  and fresh mature sweet-berry evidence into autonomous movement, canonical
  Core acquisition, exact physical custody and consumption without activation
  or provisioning commands. The supported measured founder range remains
  20–30; this is not a claim above 30. Long-run demographic admission/birth
  headroom remains unresolved. Increment 05, Temporal Physiology Coherence, is
  **COMPLETE AND PUBLISHED — SENIOR REVIEW APPROVED — REMOTE VERIFIED** at
  canonical HEAD `1614d181668b495d5321f2dfb5627c147b1e64d1`. Current schema
  44 derives passive biology from World time while schemas 1–43 preserve exact
  historical semantics. It keeps biology coherent across readiness rollback;
  path-readiness liveness itself remains unresolved. The next authorized
  action is the separate read-only
  `REVIEW-AND-SELECT-PLAYABLE-SLICE-01-INCREMENT-06` mission. It must compare at
  minimum `PATH-READINESS LIVENESS` and `RENEWABLE PHYSICAL SUBSISTENCE`, does
  not preselect either candidate, and authorizes no implementation.
- CIV-48 remains **NOT STARTED**, implementation is not authorized, and it is
  deferred until PLAYABLE SLICE 01 and the resulting evidence-driven roadmap
  recalibration are complete. Gate H remains planned. See
  [`CIV_45_PHASE_SUMMARY.md`](docs/pebblelab/CIV_45_PHASE_SUMMARY.md),
  [`CIV_46_PHASE_SUMMARY.md`](docs/pebblelab/CIV_46_PHASE_SUMMARY.md) and
  [`CIV_47_PHASE_SUMMARY.md`](docs/pebblelab/CIV_47_PHASE_SUMMARY.md), plus
  [`CIV_47_SENIOR_REVIEW_CORRECTION_01.md`](docs/pebblelab/CIV_47_SENIOR_REVIEW_CORRECTION_01.md).

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
