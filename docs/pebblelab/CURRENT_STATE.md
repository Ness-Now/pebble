# Pebble Civilization — Current state

This file is the compact canonical status. It records product state, not the
SHA of the documentation commit that contains it.

## Acquired

- Gate R — No Parallel Physical Engines: **ACQUIRED AND PUBLISHED**.
- Gate B — Bounded Embodied Local Autonomy:
  **ACQUIRED AND PUBLISHED** under contract `V4-GATE-B-v1`.
- Gate C — Durable Observable Local World:
  **ACQUIRED AND PUBLISHED** under contract `V4-GATE-C-v1`.
- `CIV-00` through `CIV-33`: **COMPLETE AND PUBLISHED** in their bounded
  contracts.
- Post-Gate-B safe-bootstrap hardening: **PUBLISHED**.

Published product baseline evaluated by independent Gate D Evaluation 03 and
affected by Gate D Blocker 03:

```text
d0d99f8a1d06cf809b14a68c107f961b58c09674
```

The `CIV-33` completion, renewable-subsistence milestone and Gate D Blockers 01
and 02 are published on the canonical branch. Independent Gate D Evaluations
01, 02 and 03 remain immutable FAIL evidence for their evaluated baselines.
Evaluation 03 found that a fresh mature observation from an earlier planting
cycle could be selected for a stage-0 replanting at the same physical site.

## Current program position

```text
active CIV phase: none
next authorized action: senior review and manual publication of Gate D Blocker 03 fix
CIV-33 status: COMPLETE AND PUBLISHED
V4-GATE-C-v1 status: ACQUIRED
V4-MILESTONE-RENEWABLE-SUBSISTENCE-v1 status: COMPLETE AND PUBLISHED
V4-GATE-D-v1 status: NOT EVALUATED
Gate D Blocker 03 status: FIXED — LOCAL REVIEW CANDIDATE
CIV-34 status: NOT STARTED
roadmap generation: V4
```

The published Blocker 01 correction preserves verified physical position
restart. The published Blocker 02 correction validates ecological observations
across retained mortality boundaries and binds their physical content to
bounded receipts in the World `SaveDB`, outside the civilization checkpoint.
The targeted Blocker 03 correction now selects crop maturity evidence only
after proving the exact current-cycle plant action, causal event and physical
receipt. A current non-mature row permits the tick to continue; retained mature
rows from prior cycles remain historical and cannot mature a replanting. Schema
30 and Observer schema 7 remain unchanged. This work does not evaluate or
acquire Gate D. After senior review, manual publication and remote
verification, the next authorized action is independent `V4-GATE-D-v1`
Evaluation 04.

## Last validation baseline

For the Gate D Blocker 03 cycle-scoped agricultural-observation correction:

```text
focused ecological observation: 68 passed, 0 failed
focused agriculture: 75 passed, 0 failed
focused renewable subsistence: 19 passed, 0 failed
focused physical actions: 38 passed, 0 failed
focused physical food survival: 50 passed, 0 failed
focused lifecycle: 80 passed, 0 failed
focused mortality: 93 passed, 0 failed
focused estates/inheritance/succession: 84 passed, 0 failed
focused checkpoint/replay: 49 passed, 0 failed
focused persistence/reconciliation: 18 passed, 0 failed
focused Material Rights: 21 passed, 0 failed
focused Observer: 20 passed, 0 failed
focused total: 615 passed, 0 failed
repository gate: 3746 passed, 0 failed
repository verification steps: 35/35
rendered two-process blocker campaign: PASS
World/session: wmscvvl4oglk7 / live-103-14-62--21
checkpoint schema / Observer schema: 30 / 7
plot/cell/cycles: plot-955b8014709cd734 / 0 / 1→2
civilization ticks: 1→2 before restart; 2→4 after restart; mature at 5
cycle-1 retained mature receipt: eco-bf1bab840c7132f5f99d84f8a62cf630a9265fa5
cycle-2 stage-0 selection: currentCycleNonMature
cycle-2 maturity receipt: eco-3cc0b63db49597e9fa1b0f0e990d2f408736f300
cycle-2 maturity action: auto-maturity:5:plot-955b8014709cd734:cycle-2:0
second harvest receipt/output: agriculture-live:renewable-cycle2-harvest / 5
World receipts / leaks: 27 / 0
duplicate actions / receipts: 0 / 0
Observer mutation count: 0
runtime errors: 0
cleanup: exact
rendered captures inspected at native resolution: 4
Gate D Blocker 01 regression: PASS
Gate D Blocker 02 regression: PASS
```

## Known important debt

- There is no GitHub CI status check for the canonical branch; published
  verification still relies on reviewed local evidence.
- Historical Gate B closure tooling and raw temporary artifacts are tied to
  their historical evaluation context; the reports remain evidence, not a
  current all-purpose gate runner.
- `CIV-26` binds a bounded social asset reference to verified Pebble stack
  identity and quantity. It does not claim a universal per-unit item UUID.
- `CIV-27` reconciles only bounded candidate holders known at save time:
  civilization agents and known material-rights holders. It does not scan the
  World globally or discover an item moved into an otherwise unknown
  container; that case remains explicitly unresolved instead of guessed.
- The World and civilization saves do not claim a cross-store atomic
  transaction. Schema 20 binds the expected World, causal boundary and
  physical references, then fails closed or records reconciliation outcomes
  after the real World loads.
- Observer V1 is a bounded local-session projection. It does not provide
  omniscient multi-settlement inspection, unbounded history, full-text search
  or simulation editing.
- Homeostasis V2 is a bounded needs-driven physiological projection. It does
  not add contagion, medicine, complex wounds, long-term impairment mechanics,
  genetic predisposition, corpses or inheritance. Existing `AgentNeeds`,
  lifecycle age, health reserve and mortality remain the underlying
  authorities. Every embodied finalization waits for bounded verification that
  the probe is empty or for verified physical exit of every carried stack into
  an existing safe real container, independently of Material Rights. Failure
  rolls the complete mortality boundary back and remains retryable rather than
  inventing a holder, social record or losing matter.
- Genetics V1 is a closed four-locus diploid model with deterministic founder
  initialization and mutation-free inheritance. Phenotype is derived from
  immutable genotype, lifecycle development and bounded homeostasis exposure;
  it does not encode sex, gender, detailed appearance, intelligence,
  personality, genetic disease or automatic social outcomes.
- A checkpoint may recreate a persistent active probe absent from the fresh
  bootstrap only when the schema-22 live manifest carries a valid canonical
  integrity digest protecting its sorted, unique empty-custody attestation,
  the identity remains present in population and lifecycle, and no Material
  Rights record resolves to that agent as physical holder. The manifest is
  verified before any World mutation; older unprotected manifests and
  non-empty custody cannot authorize empty-probe recreation and remain
  fail-closed on the existing CIV-27 reconciliation path.
- Childhood V2 extends the existing Dependent Care authority with one bounded,
  durable active guardian, explicit reassignment or at-risk state, and causal
  social-development exposure. Birth, replacement and active engagement share
  one physiological-availability predicate. Candidate guardian and caregiver
  selection reads the same transactional care authority. Supervision advances
  only on unique ticks with an active matching assignment and need, an
  available caregiver, compatible care activity and verified proximity;
  elapsed or interrupted time grants no credit. Schema 24 persists that
  bounded progress, while schema 23 decodes it with zero historical
  elapsed-time credit. Childhood V2 does not make a guardian a genetic or
  kinship parent, household owner, teacher, material custodian or legal actor.
  Social development grants no trust, knowledge, skill, profession,
  ownership, reproductive capability or status by itself.
- Family V1 adds bounded durable union proposals and records, explicit lineage
  roots, social houses and house-membership periods to the existing
  `AgentSimulationSession`. A union requires two separately verified physical
  acts, permits at most one active union per person and can end unilaterally or
  by death. Parent, child, sibling, ancestor, descendant, partner, former
  partner and co-parent relations are deterministic projections of canonical
  kinship and union records, not a second stored kinship graph. Lineage
  membership is similarly derived from canonical ancestry with visible depth
  and row truncation. A house is neither a household nor a property, care,
  custody, leadership or inheritance authority. Birth may add one
  shared-parent-house membership only when both canonical progenitors share
  exactly one active house; zero or multiple common houses add none and do not
  abort an otherwise valid birth. Explicit adult join persists distinct,
  reciprocal request and acceptance proofs, exact roles, operation IDs,
  maturity and family grounding. Two-founder houses require a matching union
  active at the foundation tick and two reciprocal co-foundation acts.
  Schema 26 persists those durable consent proofs while Observer schema 5
  remains read-only. Schema 25 is readable only when its retained causal
  events can reconstruct the complete proof; an honestly evicted but
  incomplete legacy proof fails closed.
- Estates V1 activates explicitly and prospectively over canonical mortality.
  One death can open at most one bounded estate only after complete physical
  custody resolution. Successor tiers derive from the active partner at the
  death tick and canonical kinship; a house, household, lineage, trust, skill,
  phenotype or wealth score has no succession authority. Administration
  requires explicit mature acceptance and is distinct from beneficiary,
  owner, holder and custodian roles. A physical asset remains owned by the
  decedent while settlement is pending, then changes Material Rights only
  after an exact Pebble transfer receipt; third-party claims and permissions
  follow their documented bounded policy. Minor ownership remains separate
  from guardian custody. Estate operational status is recomputed from
  terminal, dormant, partial, blocked, pending and active-administration
  truth, so administrator loss cannot reopen or erase material state.
  Mortality and estate retention are coordinated: a retained nonterminal
  estate pins its death record, while a terminal estate/death pair may compact
  atomically. Every compacted operational death first creates one bounded,
  independently digested historical mortality summary from the true death
  record; capacity failure refuses the candidate transaction before proof is
  lost. Retained records, compacted summaries and active lifecycle state form
  the fail-closed historical authority used to rederive eligibility, life
  stage and minor guardianship at the estate death boundary. Schema 28
  persists that evidence and a bounded, digested successor proof covering the
  exact tier, complete canonical eligibility rows, life stage, minor guardian,
  active union and causal plan event. Schema 27 remains readable only when
  retained causes permit exact reconstruction; incomplete legacy proof fails
  closed. Physical settlement prevalidates one shared
  operation/receipt identity. Blocked custody can be causally revalidated
  after a real guardian or availability change without rewriting allocation,
  claims or permissions. Observer schema 6 projects estate authority
  read-only. The model does not implement wills, taxation,
  valuation, divisible shares, house leadership, public treasury, land law or
  general contract inheritance.
- Renewable Subsistence V1, now published, proves one bounded real carrot loop through existing
  PebbleCore crop growth, Pebble physical agriculture, physical food debit and
  a new plant/harvest cycle across restart. One initialization carrot becomes
  a first harvest of five; one is eaten, three are stored and one is replanted;
  the stage-0 second crop survives restart and yields three. Schema 29 retains
  exact source-action provenance and fails closed when the first-cycle receipts
  needed to authorize renewal cannot be retained. Observer schema 7 derives a
  read-only view from agriculture and physical-food authorities. This proof is
  not a general food economy, market, land-rights system, irrigation or season
  model, crop genetics, or industrial production system.

## Next authorized action

After senior review, manual publication and remote verification of the Gate D
Blocker 03 correction, the next eligible work is a new independent
`V4-GATE-D-v1` Evaluation 04. Gate D remains **not evaluated** and is not
acquired by this correction. `CIV-34` is not started and remains downstream of
a future published Gate D PASS.
