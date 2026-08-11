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

Canonical status at the product baseline reconciled by this documentation:

```text
Gate R: ACQUIRED AND PUBLISHED
Gate B: ACQUIRED AND PUBLISHED under V4-GATE-B-v1
CIV-00 through CIV-33: COMPLETE AND PUBLISHED
post-Gate-B safe-bootstrap hardening: PUBLISHED
V4-GATE-C-v1: ACQUIRED AND PUBLISHED
V4-MILESTONE-RENEWABLE-SUBSISTENCE-v1: COMPLETE AND PUBLISHED
V4-GATE-D-v1: EVALUATED_FAIL_NOT_ACQUIRED
Gate D Blocker 03: BLOCKER_FIX_PUBLISHED
Gate D Evaluation 04: EVALUATED_FAIL_NOT_ACQUIRED
Gate D Blocker 04: BLOCKER_FIX_PUBLISHED
Gate D Evaluation 05: EVALUATED_FAIL_NOT_ACQUIRED
Gate D Blocker 05: BLOCKER_FIX_PUBLISHED
Gate D Evaluation 06: EVALUATED_FAIL_NOT_ACQUIRED — HISTORICAL EVIDENCE
Gate D Blocker 06: BLOCKER_FIX_PUBLISHED
Independent Gate D Evaluation 07: NOT_STARTED — NEXT AUTHORIZED ACTION
CIV-34: NOT_STARTED
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
`780ea9d7137b728d0fc4873152479f65ebe57d18`. The next authorized action is a
new independent `V4-GATE-D-v1` Evaluation 07, which is not started. Gate D
remains evaluated and not acquired.

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
