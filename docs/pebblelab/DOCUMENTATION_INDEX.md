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
V4-MILESTONE-RENEWABLE-SUBSISTENCE-v1: COMPLETE; LOCAL REVIEW CANDIDATE
V4-GATE-D-v1: NOT EVALUATED; NEXT ELIGIBLE GATE EVALUATION
CIV-34: NOT STARTED
```

The `CIV-33` completion is published on the canonical branch at
`7cd1bd3f65a4dc5943f8229b9444ac425c98c677`. The renewable-subsistence
milestone in this local tree is a review candidate until senior review, manual
push and remote verification complete.

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
