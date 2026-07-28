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
CIV-00 through CIV-25: COMPLETE
post-Gate-B safe-bootstrap hardening: PUBLISHED
CIV-26: NOT STARTED; next eligible phase
```

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
