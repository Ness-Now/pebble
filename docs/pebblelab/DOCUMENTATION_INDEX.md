# Pebble Civilization — Documentation index

## Authority

Use each source only for the question it owns:

```text
published code, tests and Git HEAD
= implemented reality

AGENTS.md and applicable workflows
= mandatory work rules

vision
= durable product target

roadmap and manifest
= canonical program and status

gate reports and evidence
= verifiable history

old roadmaps, handoffs and summaries
= historical, non-directive context
```

A historical `FAIL` remains true for the campaign it records. It does not
override the current canonical gate status. A roadmap does not prove a feature
exists; code and tests do.

## Canonical

These documents form the minimal permanent memory of the project:

| Document | Role |
| --- | --- |
| [`CODEX_START_HERE.md`](../../CODEX_START_HERE.md) | Short entry point, authority map and mission-specific reading routes. |
| [`CURRENT_STATE.md`](CURRENT_STATE.md) | Compact acquired state, product baseline, debt and next eligible action. |
| [`PEBBLE_CIVILIZATION_VISION.md`](PEBBLE_CIVILIZATION_VISION.md) | Durable V4 product purpose and invariants. |
| [`PEBBLE_CIVILIZATION_ROADMAP.md`](PEBBLE_CIVILIZATION_ROADMAP.md) | Canonical human V4 program, required/optional phases, slices and versioned gates. |
| [`ROADMAP_MANIFEST.json`](ROADMAP_MANIFEST.json) | Deterministic machine projection of the V4 roadmap and status. |
| [`DOCUMENTATION_INDEX.md`](DOCUMENTATION_INDEX.md) | Classification and navigation for the documentation set. |
| [`CIV_36_PHASE_SUMMARY.md`](CIV_36_PHASE_SUMMARY.md) | Published architecture, contract semantics, correction history, physical proof, validation and non-claims for CIV-36. |
| [`CIV_37_PHASE_SUMMARY.md`](CIV_37_PHASE_SUMMARY.md) | Published architecture, correction history, physical-market proof, price causality, validation and non-claims for CIV-37. |
| [`GATE_E_BLOCKER_01_EXACT_PRODUCTION_PROVENANCE.md`](GATE_E_BLOCKER_01_EXACT_PRODUCTION_PROVENANCE.md) | Published Blocker 01 product-correction record; preserves Evaluation 01 FAIL and documents exact asset-bound production provenance. |
| [`GATE_E_BLOCKER_02_EVOLVED_PRODUCTION_IDENTITY.md`](GATE_E_BLOCKER_02_EVOLVED_PRODUCTION_IDENTITY.md) | Published Blocker 02 product-correction record; preserves Evaluation 02 FAIL and separates immutable production origin, durable current-identity continuity and exact current physical authority. |
| [`GATE_E_BLOCKER_03_TERMINAL_MARKET_RESERVATION_AUTHORITY.md`](GATE_E_BLOCKER_03_TERMINAL_MARKET_RESERVATION_AUTHORITY.md) | Published Blocker 03 product-correction record; preserves Evaluation 03 FAIL and separates terminal market history from coherent live reservation authority. |
| [`GATE_E_BLOCKER_04_COMPOSED_ASSET_COMMITMENT_AUTHORITY.md`](GATE_E_BLOCKER_04_COMPOSED_ASSET_COMMITMENT_AUTHORITY.md) | Local Blocker 04 product-correction review record; preserves Evaluation 04 FAIL and composes exact-asset commitment authority across barter, contracts and markets. |

Canonical status at the product baseline reconciled by this documentation:

```text
Gate R: ACQUIRED AND PUBLISHED
Gate B: ACQUIRED AND PUBLISHED under V4-GATE-B-v1
CIV-00 through CIV-37: COMPLETE AND PUBLISHED
post-Gate-B safe-bootstrap hardening: PUBLISHED
V4-GATE-C-v1: ACQUIRED AND PUBLISHED
V4-MILESTONE-RENEWABLE-SUBSISTENCE-v1: COMPLETE AND PUBLISHED
V4-GATE-D-v1: ACQUIRED AND PUBLISHED
Gate D Evaluation 01: EVALUATED_FAIL_NOT_ACQUIRED — HISTORICAL EVIDENCE
Gate D Blocker 01: BLOCKER_FIX_PUBLISHED
Gate D Evaluation 02: EVALUATED_FAIL_NOT_ACQUIRED — HISTORICAL EVIDENCE
Gate D Blocker 02: BLOCKER_FIX_PUBLISHED
Gate D Evaluation 03: EVALUATED_FAIL_NOT_ACQUIRED — HISTORICAL EVIDENCE
Gate D Blocker 03: BLOCKER_FIX_PUBLISHED
Gate D Evaluation 04: EVALUATED_FAIL_NOT_ACQUIRED — HISTORICAL EVIDENCE
Gate D Blocker 04: BLOCKER_FIX_PUBLISHED
Gate D Evaluation 05: EVALUATED_FAIL_NOT_ACQUIRED — HISTORICAL EVIDENCE
Gate D Blocker 05: BLOCKER_FIX_PUBLISHED
Gate D Evaluation 06: EVALUATED_FAIL_NOT_ACQUIRED — HISTORICAL EVIDENCE
Gate D Blocker 06: BLOCKER_FIX_PUBLISHED
Gate D Evaluation 07: EVALUATED_FAIL_NOT_ACQUIRED — HISTORICAL EVIDENCE
Gate D Blocker 07: BLOCKER_FIX_PUBLISHED
Gate D Evaluation 08: EVALUATED_FAIL_NOT_ACQUIRED — HISTORICAL EVIDENCE
Gate D Blocker 08: BLOCKER_FIX_PUBLISHED
Gate D Evaluation 09: EVALUATED_FAIL_NOT_ACQUIRED — HISTORICAL EVIDENCE
Gate D Blocker 09: BLOCKER_FIX_PUBLISHED
Gate D Evaluation 10: EVALUATED_FAIL_NOT_ACQUIRED — HISTORICAL EVIDENCE
Gate D Blocker 10: BLOCKER_FIX_PUBLISHED
Independent Gate D Evaluation 11: PASS — SENIOR REVIEW APPROVED — PUBLISHED EVIDENCE
CIV-34: COMPLETE AND PUBLISHED
CIV-35: COMPLETE AND PUBLISHED
CIV-36: COMPLETE AND PUBLISHED
CIV-37: COMPLETE AND PUBLISHED
CIV-38: OPTIONAL — NOT STARTED
V4-GATE-E-v1: PLANNED — NOT ACQUIRED
active phase: null
completed through: CIV-37
next eligible phase: null
Gate E Evaluation 01: FAIL — HISTORICAL IMMUTABLE EVIDENCE
V4-GATE-E-v1 Blocker 01: FIXED AND PUBLISHED
Gate E Evaluation 02: FAIL — HISTORICAL IMMUTABLE EVIDENCE
V4-GATE-E-v1 Blocker 02: FIXED AND PUBLISHED
Gate E Evaluation 03: FAIL — HISTORICAL IMMUTABLE EVIDENCE
V4-GATE-E-v1 Blocker 03: FIXED AND PUBLISHED
Gate E Evaluation 04: FAIL — HISTORICAL IMMUTABLE EVIDENCE
V4-GATE-E-v1 Blocker 04: IMPLEMENTED_LOCAL_REVIEW_CANDIDATE — NOT PUBLISHED
Gate E Evaluation 05: NOT_STARTED
next authorized action: SENIOR_REVIEW_V4_GATE_E_BLOCKER_04
```

The `CIV-33` completion is published on the canonical branch at
`7cd1bd3f65a4dc5943f8229b9444ac425c98c677`. The renewable-subsistence
milestone is published in baseline
`47104f70894b20e7d7db0042cb93f047540c336d`. Gate D Blocker 01 is fixed and
published in baseline `6d114abb98aee652e44fe9a81c3bab47b72ff698`; Blocker
02 is fixed and published in baseline
`d0d99f8a1d06cf809b14a68c107f961b58c09674`; Blocker 03 is fixed and
published in baseline `4b11c93abd36a1a1c61d491df1e5efa6607f6206`.
Independent Evaluation 04 remains historical FAIL evidence. The Blocker 04
correction is published at product-fix head
`cca372bb841846db4b1010d26456bcc245b07c3e`; it separates external World
progression from candidate effects and compensates verified candidate-owned
physical mutations before abandoning publication. Independent Evaluation 05
remains historical FAIL evidence for published
baseline `1fa033173609b8cc6ff8a3c4f09cb0e6b0ec8a9e`. The Blocker 05 exact
physical-custody restart correction is published at product-fix head
`d60e4f2dad11f02c184d8e7ae85b9bbdc9fe7712`. Independent Evaluation 06
remains historical FAIL evidence for baseline
`82a2e50da4db2fe861b88801e033788a2de16dd4`. Its targeted Blocker 06
estate-source physical-authority correction is published at product-fix head
`780ea9d7137b728d0fc4873152479f65ebe57d18`. Independent Evaluation 07 remains
historical FAIL evidence for baseline
`bbafcb51ef0d8387e95302a134ec038fbb8dffa6`. The targeted Blocker 07
post-physical reconciliation correction is published at product-fix head
`650b56b90381306c38d891dfdade9d89a1c45db5`. Independent Evaluation 08 remains
historical FAIL evidence for baseline
`02c7778769c8a6d971f4eb8bd73e5a3f7afc8c1e`. Its targeted Blocker 08
collective probe-restore correction is published at product-fix head
`a7f1fd7bf92a6d049d7601945209eb9c98d06058`. Independent Evaluation 09 remains
historical FAIL evidence for baseline
`4ea6fba4b615d72a96087bb98bf5bbca4b560e4b`. Its targeted evolved-material
checkpoint-save correction is published at product-fix head
`ee742afb41fda44c77d8b98f868fbe759934057e`. A new independent Evaluation 10
found that a committed physical action could remove canonical support beneath
another active no-gravity probe. Its targeted Blocker 10 correction is
published at product-fix head `6ec700640dfe806f32da62fe7d7315c64fdb8f74`.
Independent Evaluations 01 through 10 remain historical immutable FAIL
evidence and Blockers 01 through 10 remain fixed and published. Independent
Evaluation 11, evaluated against product baseline
`24c679581f7dfd93d26bffa2e9486a5340af0d9c`, is the first accepted whole-Gate
PASS and is senior-review approved. This commit is the Gate D acquisition and
publication evidence, now independently remote-verified at canonical head
`61fbf406713127b0993a7294020433e1e3c3fa39`.
`CIV-34 — Production, Tools and Workshops V1` is complete and published from
baseline `1bbf3df08ca8a05c79af61c888c424e52bb30801`. The accepted product
implementation is `73db4cd7fbf1aff86a23aacb8928ca460774696e`; senior review
approved reviewed evidence HEAD
`24f0f72aae7543177ca746e892c57482496dabef` and bundle SHA-256
`8a00bfef38c7d93dae0eff6867d58bc4d05bc872fb72b00f83616367dd682b6d`.
`CIV-35 — Barter and Local Exchange V1` is complete and published from exact
baseline `8b7faa4cd03e315dec5696f72ec1ad75e333c77f`. The original product commit
is `144bcaf162b37f92b151ec2180c0bd9be294adce`. Historical first-candidate HEAD
`b80b6bdda4345cd002ed34296dea92562cbb5fc1` was not independently approved.
Senior Review Correction 01 fixed proof-fixture-bound normal discovery and
permanent terminal-offer capacity exhaustion at
`43c6b6ba00fee879918125cb9cffd79e653c49fc`. Senior review approved corrected
evidence HEAD `1dbe84fdc9286b35e05a0aaaf8673ec0ce99718a` and review bundle
SHA-256 `c26a79fa7641e2da534f4bf18954bdbe50635d6bc9306be55a7b705af321e41d`.
The complete accepted evidence is indexed in
[`CIV_35_PHASE_SUMMARY.md`](CIV_35_PHASE_SUMMARY.md). `CIV-36 — Debt, Promises
and Durable Contracts V1` was implemented from exact baseline
`e47c2d1a4132dc756219ef0d2c1495b2769b8d35` at product/proof commit
`a910f938c0e943e37aa851c0f65dfecdb06698cc`. Senior Review Correction 01 at
`76adcba62ac901b01618bea58fba32e1d5dc0d02` corrects the initial candidate's
ordinary post-physical publication escape gap and its discard of reacquired
asset-scoped current fingerprints. The initial candidate documentation HEAD
`4c7af994fc52974f6f919765af682b209f6b84ca` was not independently approved.
Senior review approved corrected evidence/documentation HEAD
`3494abea0211a843ca54bb0748b1a6d9bdbddd3f` and final review bundle SHA-256
`7947b0ae2e1c86a551403d24f3d75769e8203baf43f8b0e5958a94d038d21951`
with 47/47 internal checksums and passing unzip validation. Its schema-33
open-debt restart, current
authority on both legs, predictable zero-mutation publication refusal,
ordinary and explicit verified rollback/retry, normal CIV-34 production,
exact-once fulfillment, Observer schema 10, 30/30 focused checks, 3892/3892
repository assertions and four-process live proof are indexed in
[`CIV_36_PHASE_SUMMARY.md`](CIV_36_PHASE_SUMMARY.md). CIV-36 is complete and
published. CIV-37 is complete and published from exact baseline
`9f13ffee3f312caaaa68ddd6f2c2c27e5942474e` at product/proof commit
`e279362e1d5b71ed82d20e2f17e492fa22579c37`; its bounded physical market,
schema-34 restart, exact rollback, local price history and four-process proof
are indexed in [`CIV_37_PHASE_SUMMARY.md`](CIV_37_PHASE_SUMMARY.md). Senior
Review Correction 01 starts from reviewed candidate HEAD
`f96f84a61b72e115de668966f470feef986de925` and is implemented at
`21ed1b550f9c54381e54c3c763d2ff494bda7d57`; correction documentation is
`68f878abb0408984571f802c10079001e70c9aa7`, and senior review approved corrected
HEAD `7a2a2b7e21fe773ca7583e6bfcefd20f2756c5d8`. Correction 01A records that the
initial candidate lacked current World locality revalidation at seller decision
and settlement; Correction 01B records its unconditional seller acceptance and
false underfilled-need fulfillment. Both are corrected. The accepted review
bundle SHA-256 is
`7a0b48bb69f67b541670bfb91f7720ee0c19cfb5a5ca922bf8ac16a4902796bd`, with
55/55 internal checksums and passing unzip validation. The accepted evidence has
31/31 focused checks, 3923/3923 repository assertions and 13 inspected captures.
CIV-38 is optional and not started. Independent Gate E Evaluation 01 evaluated
exact published baseline `5bc9d3088c2550fb042fe065235cb0154a226ff0` and
remains `FAIL — PRODUCT CORRECTION REQUIRED` at immutable evidence HEAD
`e75ab82981169baf1cdc67d9454e6d569e989167`. Its review bundle SHA-256 is
`9db1a5b478f1ed0ca9efcac5612efc29928b61143a92e198123285920444fc93`.
Senior review approved the V4-GATE-E-v1 Blocker 01 product correction at
`9a623d48f300245b0d348da0b7b72762043b93ff`, reviewed candidate HEAD
`534fd927483a692e26de7f929a361c34e77870a7` and review bundle SHA-256
`dbbdd076cf4c90a753b138e470583fd63b982f9ebe2c8f2440c08c227bc4a163`
with 47/47 internal checksums. Blocker 01 is fixed and published; it does not
acquire Gate E or rewrite Evaluation 01. Evaluation 02 remains immutable
`FAIL — HISTORICAL IMMUTABLE EVIDENCE` at evidence HEAD
`2f95826f474c9f2a366f4b06df90a8643beb7a98`; its bundle SHA-256 is
`4e10d129927af5c8443f9f8e26fec0d276f797cf82126b93792f32c26c646d57`.
Senior review approved V4-GATE-E-v1 Blocker 02 product correction
`a67665e87774a4af8fcc7930e05c8747da1f83fc`, reviewed candidate HEAD
`b8dbeef60865a4fd452ca5abaac4a005ded2e592` and review bundle SHA-256
`68ab04428582cbbe96c0e8bf046f45c22818a6dd9018ad6f808c87b9aea30c31`
with 59/59 internal checksums. Blocker 02 is fixed and published; it preserves
the exact production-origin identity while the current physical identity may
evolve only through the existing Material Rights continuity contract. Gate E
remains planned and not acquired. Evaluation 03 remains immutable `FAIL —
HISTORICAL IMMUTABLE EVIDENCE` for exact baseline
`bfb721d7f49f8af567c86580cdf4c106da977a25`, evidence HEAD
`56af9648da0155cfba25588320d2070d211a1cd7` and review-bundle SHA-256
`c3e203e507ff8fd28781b9a067317493fd348e839e6e0b8386d95d18251af883`.
Senior review approved V4-GATE-E-v1 Blocker 03 product correction
`301dfd58aacd3aa0af653fa460ad38484df1d762`, reviewed candidate HEAD
`27e8406edd20f13817d4b7e1684a00db56e361a7` and review bundle SHA-256
`8ec57b6bb8b58cab59be3024f7541693b145ae0527221e5e523b32538a2182a4`
with 87/87 internal checksums and passing ZIP integrity. Blocker 03 is fixed
and published; it derives reservation from the coherent live
proposal/listing/deposit triad so terminal accepted history cannot reserve
current matter. This containing commit does not claim remote publication
verification. Independent Evaluation 04 remains immutable `FAIL — HISTORICAL
IMMUTABLE EVIDENCE` for exact baseline
`e8bc2fc8add491c324f15478fcd1b82d77566d57`, falsifier commit
`54bb38c174d5f3241763926a7bda6b900d7dbc8a` and evidence HEAD
`07ded1e583b62137b5e8b6cc32d8a61ead73cc53`. V4-GATE-E-v1 Blocker 04 is an
implemented local review candidate at product commit
`0318133fe95949c441974871f2581f38c43c6128`. It derives one exact-asset
commitment projection from canonical barter, contract and market state while
retaining their physical gateways and same-operation continuations. It is not
published, Gate E is not acquired, Evaluation 05 is not started and CIV-38
remains optional and not started. The next authorized action is senior review
of the Blocker 04 candidate.

## Operational

These documents prescribe how work and validation are performed:

| Document | Role |
| --- | --- |
| [`AGENTS.md`](../../AGENTS.md) | Stable repository-wide ownership, safety, Git and validation rules. |
| [`Sources/Pebble/AGENTS.md`](../../Sources/Pebble/AGENTS.md) | Live application/adapters rules. |
| [`Sources/PebbleAgents/AGENTS.md`](../../Sources/PebbleAgents/AGENTS.md) | Pure civilization runtime rules. |
| [`Sources/PebbleLab/AGENTS.md`](../../Sources/PebbleLab/AGENTS.md) | Headless runner rules. |
| [`Sources/pebsmoke/AGENTS.md`](../../Sources/pebsmoke/AGENTS.md) | Regression/evidence rules. |
| [`DEVELOPMENT_WORKFLOW.md`](DEVELOPMENT_WORKFLOW.md) | Preflight, delivery cycle, risk levels and reporting. |
| [`METHOD_CODEX_AUTONOMIE_GUIDEE.md`](METHOD_CODEX_AUTONOMIE_GUIDEE.md) | How to define and review autonomous Codex missions. |
| [`VISUAL_GAME_SMOKE_POLICY.md`](VISUAL_GAME_SMOKE_POLICY.md) | Canonical proportional Visual Game Smoke and adversarial playability policy, revision V5. |
| [`../pebblelab-3d-live-prototype.md`](../pebblelab-3d-live-prototype.md) | Disposable-world live launcher and runbook. |

Root `README.md`, `ARCHITECTURE.md`, `CONTRIBUTING.md` and `SECURITY.md`
remain operational references for the base game and repository. They do not
control the Civilization roadmap.

## Evidence

Evidence documents are immutable records of bounded campaigns or completed
work. Their historical verdicts remain intact.

### Gate B history

- [`GATE_B_CANDIDATE_EVALUATION.md`](GATE_B_CANDIDATE_EVALUATION.md) records
  candidate evaluations and historical blockers.
- [`GATE_B_REEVALUATION_3_SUMMARY.json`](GATE_B_REEVALUATION_3_SUMMARY.json)
  and
  [`GATE_B_REEVALUATION_4_SUMMARY.json`](GATE_B_REEVALUATION_4_SUMMARY.json)
  preserve historical `FAIL` results.
- [`GATE_B_CONVERGENCE_01A_SUMMARY.md`](GATE_B_CONVERGENCE_01A_SUMMARY.md)
  records the recovered convergence foundation.
- [`GATE_B_CONVERGENCE_01B_SUMMARY.md`](GATE_B_CONVERGENCE_01B_SUMMARY.md) and
  [`GATE_B_CONVERGENCE_01B_SUMMARY.json`](GATE_B_CONVERGENCE_01B_SUMMARY.json)
  preserve the stopped progressive soak and its historical verdict.
- [`GATE_B_CLOSURE_01_SUMMARY.md`](GATE_B_CLOSURE_01_SUMMARY.md) and
  [`GATE_B_CLOSURE_01_SUMMARY.json`](GATE_B_CLOSURE_01_SUMMARY.json) preserve
  the local closure-candidate result produced before senior review and manual
  publication.

The closure report correctly says it did not itself acquire Gate B. The
canonical acquisition is the later published program decision recorded in
`CURRENT_STATE.md`, the V4 roadmap and the manifest. Do not rewrite the report
to make it say something it did not claim at execution time.

### Phase and physical-boundary evidence

[`CIV_26_PHASE_SUMMARY.md`](CIV_26_PHASE_SUMMARY.md) records the bounded
material-rights contract, deterministic and live validation, exact cleanup and
explicit limits of `CIV-26`.

[`CIV_27_PHASE_SUMMARY.md`](CIV_27_PHASE_SUMMARY.md) records the bounded
World/civilization save, restart and reconciliation protocol, deterministic
and two-process live evidence, exact cleanup and explicit V1 limits.

[`CIV_28_PHASE_SUMMARY.md`](CIV_28_PHASE_SUMMARY.md) records the bounded
read-only Observer projection, structured reasons, ledger-backed Chronicle,
rendered two-process restart evidence, exact cleanup and explicit V1 limits.

[`CIV_29_PHASE_SUMMARY.md`](CIV_29_PHASE_SUMMARY.md) records the bounded
homeostasis, health, aging and causal mortality V2 contract, schema-21
checkpoint/replay, rendered two-process progression and exact cleanup.

[`CIV_30_PHASE_SUMMARY.md`](CIV_30_PHASE_SUMMARY.md) records the closed
four-locus diploid model, deterministic founder and inheritance protocol,
bounded development and phenotype, schema-22 checkpoint/replay, Observer
schema 3, rendered normal birth and safe persistent-child restart.

[`CIV_31_PHASE_SUMMARY.md`](CIV_31_PHASE_SUMMARY.md) records durable bounded
guardianship, shared physiological availability, candidate-state care
selection, verified multi-tick supervision and physical nourishment, causal
social development, schema-24 checkpoint/replay, Observer schema 4, and the
rendered two-process child/guardian restart proof.

[`CIV_32_PHASE_SUMMARY.md`](CIV_32_PHASE_SUMMARY.md) records physically
grounded proposal and acceptance, bounded unions, derived family and lineage
projections, social houses independent from households and property, atomic
birth/death integration, exact-one parental-house affiliation, durable
two-act house consent, schema-26 checkpoint/replay, Observer schema 5, and
the rendered two-process family restart proof.

[`CIV_33_PHASE_SUMMARY.md`](CIV_33_PHASE_SUMMARY.md) records the bounded
prospective estate model, mortality and physical-exit atomicity, canonical
successor tiers, explicit administration, minor-owner custody separation,
whole-asset physical settlement, operational-status recomputation,
coordinated mortality/estate retention, durable schema-28 successor proof,
bounded compacted-death evidence for exact historical eligibility,
restrictive schema-27 compatibility, Observer schema 6 and the rendered
two-process death/estate/restart/settlement proof.

[`CIV_34_PHASE_SUMMARY.md`](CIV_34_PHASE_SUMMARY.md) records canonical
PebbleCore recipe reuse, the transactional live production gateway, bounded
needs and opportunities, normal autonomous stone-pickaxe and bread production,
exact late rollback and retry, schema-31 checkpoint/replay, Observer schema 8,
fresh-process physical custody restore and downstream real pickaxe use.

[`CIV_35_PHASE_SUMMARY.md`](CIV_35_PHASE_SUMMARY.md) records bounded local
spot barter, distinct offer and counterparty consent, exact stack-scoped
authority, CIV-34 produced-good provenance, two-sided physical transfer,
post-first-leg rollback and immediate retry, CIV-26 ownership/custody
publication, schema-32 restart/replay, Observer schema 9 and fresh-process use
of the exact exchanged pickaxe.

[`RENEWABLE_SUBSISTENCE_MILESTONE_SUMMARY.md`](RENEWABLE_SUBSISTENCE_MILESTONE_SUMMARY.md)
records the bounded physical carrot loop, exact input/output and food debit,
source-harvest renewal provenance, schema-29 restart, Observer schema 7,
two-process rendered proof and explicit limits of
`V4-MILESTONE-RENEWABLE-SUBSISTENCE-v1`.

[`GATE_D_BLOCKER_01_POSITION_RESTORE_FIX.md`](GATE_D_BLOCKER_01_POSITION_RESTORE_FIX.md)
records the preserved independent Gate D FAIL, the bootstrap-position root
cause, save-time physical-position validation, deterministic load
classification, empty-custody policy, exact rollback and the targeted
two-process correction campaign. It is product-correction evidence, not a Gate
D PASS or acquisition report.

[`GATE_D_BLOCKER_02_ECOLOGICAL_OBSERVER_HISTORY_FIX.md`](GATE_D_BLOCKER_02_ECOLOGICAL_OBSERVER_HISTORY_FIX.md)
records Evaluation 02's preserved FAIL, the active-versus-historical observer
root cause, exact registration/observation/death ordering, coordinated
observation/death compaction, schema-29 compatibility, fully re-signed
corruptions and the rendered two-process restart proof. It is product-correction
evidence, not a Gate D PASS or acquisition report.

[`GATE_D_BLOCKER_03_AGRICULTURE_CYCLE_OBSERVATION_FIX.md`](GATE_D_BLOCKER_03_AGRICULTURE_CYCLE_OBSERVATION_FIX.md)
records Evaluation 03's preserved FAIL, the freshness-versus-cycle root cause,
the exact current-planting boundary, deterministic multi-actor evidence
selection, non-mature and fail-closed mature semantics, cycle-scoped action
identity, schema-30 restart, rollback injections and the real two-process
second-harvest proof. It is product-correction evidence, not a Gate D PASS or
acquisition report.

[`GATE_D_BLOCKER_04_CANDIDATE_PHYSICAL_ATOMICITY_FIX.md`](GATE_D_BLOCKER_04_CANDIDATE_PHYSICAL_ATOMICITY_FIX.md)
records Evaluation 04's preserved FAIL, the complete candidate-mutation
inventory, external World-progression boundary, bounded compensation journal,
full movement state, hard-failure policy, priority fault campaigns and
checkpoint/restart evidence. It is product-correction evidence, not a Gate D
PASS or acquisition report.

[`GATE_D_BLOCKER_05_RESTART_PHYSICAL_CARE_CUSTODY_CONTINUITY.md`](GATE_D_BLOCKER_05_RESTART_PHYSICAL_CARE_CUSTODY_CONTINUITY.md)
records Evaluation 05's preserved FAIL, the exact nonpersistent-probe custody
boundary, manifest-v2 protected `ItemStack` evidence, real World escrow,
transactional load/rollback and continued normal physical care. It is a
published product correction, not a Gate D PASS or acquisition report.

[`GATE_D_BLOCKER_06_ESTATE_SOURCE_PHYSICAL_AUTHORITY.md`](GATE_D_BLOCKER_06_ESTATE_SOURCE_PHYSICAL_AUTHORITY.md)
records Evaluation 06's preserved FAIL, asset-scoped estate source authority,
co-mingled custody, current transaction fingerprints, true post-mutation fault
injection, exact rollback and immediate same-process retry. It is a published
product correction, not a Gate D PASS or acquisition report.

[`GATE_D_BLOCKER_07_RECONCILIATION_AFTER_PHYSICAL_RESTORE.md`](GATE_D_BLOCKER_07_RECONCILIATION_AFTER_PHYSICAL_RESTORE.md)
records Evaluation 07's preserved FAIL, complete checkpoint physical-boundary
acquisition before current Material Rights reconciliation, atomic load
rollback and first-attempt inherited physical use. It is a published product
correction, not a Gate D PASS or acquisition report.

[`GATE_D_BLOCKER_08_COLLECTIVE_PROBE_RESTORE_PLACEMENT.md`](GATE_D_BLOCKER_08_COLLECTIVE_PROBE_RESTORE_PLACEMENT.md)
records Evaluation 08's preserved FAIL, bounded collective checkpoint
placement authority, exact mixed-plan restore, true collision refusals,
partial-creation rollback and decisive inherited-use continuation. It is a
published product correction, not a Gate D PASS or acquisition report.

[`GATE_D_BLOCKER_09_EVOLVED_MATERIAL_IDENTITY_CHECKPOINT_SAVE.md`](GATE_D_BLOCKER_09_EVOLVED_MATERIAL_IDENTITY_CHECKPOINT_SAVE.md)
records Evaluation 09's preserved FAIL, immutable durable asset history versus
the exact current verified observation, current-identity checkpoint custody
validation, repeated evolved-identity protected restarts and fail-closed stale,
future, wrong-holder, wrong-quantity, ambiguous and duplicate-reservation
cases. It is a published product correction, not a Gate D PASS or
acquisition report.

[`GATE_D_BLOCKER_10_ACTIVE_PROBE_SUPPORT_PHYSICAL_ACTION_SAFETY.md`](GATE_D_BLOCKER_10_ACTIVE_PROBE_SUPPORT_PHYSICAL_ACTION_SAFETY.md)
records Evaluation 10's preserved FAIL, the mismatch between successful block
actions and canonical active-probe placement validity, the shared PebbleCore
post-mutation safety boundary, exact transaction rollback, safe positive
control and evolved-tool checkpoint-C continuation. It is a published product
correction, not a Gate D PASS or acquisition report.

[`GATE_D_EVALUATION_11_REPORT.md`](GATE_D_EVALUATION_11_REPORT.md) records the
first accepted independent whole-Gate PASS, its exact evaluated product
baseline and evidence commits, senior-review approval, current B08/B09/B10
composition proof, five-checkpoint isolation, conservation, wrapper
limitations and repository validation. It is the durable Gate D acquisition
evidence; the review ZIP checksum identifies the reviewed external bundle
without making a machine-local path authoritative.

[`GATE_C_EVALUATION_01_SUMMARY.md`](GATE_C_EVALUATION_01_SUMMARY.md) and
[`GATE_C_EVALUATION_01_SUMMARY.json`](GATE_C_EVALUATION_01_SUMMARY.json)
record the independent combined evaluation of real material rights, a
two-process restart, nontrivial physical reconciliation, zero duplication,
causal continuity and read-only rendered observation.

The `PHASE_4_*.md`, `PHASE_5_*.md` and
`PHASE_A0_SHARED_AGENT_RUNTIME_AUDIT.md` documents record completed audits,
spikes, plans and validation of earlier physical/cognitive work. They are
evidence or historical engineering context, not the future roadmap.

## Historical

These documents are retained for chronology and forensic context:

- [`PEBBLE_CIVILIZATION_ROADMAP_V3_REUSE_FIRST.md`](PEBBLE_CIVILIZATION_ROADMAP_V3_REUSE_FIRST.md)
  — exact human roadmap replaced by V4;
- [`ROADMAP_MANIFEST_V3.json`](ROADMAP_MANIFEST_V3.json)
  — exact machine manifest replaced by V4;
- [`ROADMAP.md`](ROADMAP.md) — multi-thousand-line detailed historical phase
  journal;
- `CHANGELOG.md`, `DECISIONS.md`, `DEV_JOURNAL.md` and `JOURNAL.md` in this
  directory;
- the older `PEBBLELAB_*` changelogs, journals and decisions in `docs/`;
- external-research and compatibility notes under `docs/AI_*`;
- general repository changelogs.

Historical documents may contain once-correct branch names, SHAs, statuses,
next steps or local paths. They are not instructions for a new mission.

## Superseded

The following files remain available but no longer direct work:

- [`../PEBBLELAB_CODEX_RULES.md`](../PEBBLELAB_CODEX_RULES.md), replaced by
  `AGENTS.md`, the workflow and the guided-autonomy method;
- [`../PEBBLELAB_OVERVIEW.md`](../PEBBLELAB_OVERVIEW.md) and
  `PEBBLELAB_SOCIAL_AGENTS.md`, early product framing replaced by the V4
  vision;
- [`../PEBBLELAB_NEXT.md`](../PEBBLELAB_NEXT.md) and
  [`../NEXT_STEPS_FOR_PEBBLELAB.md`](../NEXT_STEPS_FOR_PEBBLELAB.md), obsolete
  next-step lists;
- the archived V3 roadmap and manifest named explicitly above;
- old phase plans whose implementation has completed or whose direction was
  replaced.

Do not copy a superseded document into a new prompt as current authority.

## Document placement rules

- Durable purpose or invariant → vision.
- Current acquired status, baseline or immediate debt → current state.
- Delivery order, dependencies or gate contract → roadmap and manifest.
- Mandatory working behavior → `AGENTS.md`, workflow or named policy.
- Reproducible procedure → operational runbook.
- Completed campaign or decision at a bounded SHA → evidence.
- Superseded plan, summary or chronology → historical.

Prefer updating the owning canonical file over creating another overlapping
document. Never maintain two documents that both claim to be the current
roadmap, manifest or status.
