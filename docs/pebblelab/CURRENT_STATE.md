# Pebble Civilization — Current state

This file is the compact canonical status. It records product state, not the
SHA of the documentation commit that contains it.

## Acquired

- Gate R — No Parallel Physical Engines: **ACQUIRED AND PUBLISHED**.
- Gate B — Bounded Embodied Local Autonomy:
  **ACQUIRED AND PUBLISHED** under contract `V4-GATE-B-v1`.
- Gate C — Durable Observable Local World:
  **ACQUIRED AND PUBLISHED** under contract `V4-GATE-C-v1`.
- `CIV-00` through `CIV-33`: **COMPLETE** in their bounded contracts.
- Post-Gate-B safe-bootstrap hardening: **PUBLISHED**.

Published product baseline from which `CIV-33` was implemented:

```text
dcfbafbff92e9c0c849f7234875476d0d49a25a9
```

This document does not claim to record the SHA of the commit containing
`CIV-33`. Use Git to identify the exact reviewed or published phase HEAD.

The `CIV-32` completion is published on the canonical branch. The `CIV-33`
completion recorded here is a local review candidate until senior review,
manual push and remote verification complete.

## Current program position

```text
active CIV phase: none
next authorized action: V4-MILESTONE-RENEWABLE-SUBSISTENCE-v1
CIV-33 status: COMPLETE — LOCAL REVIEW CANDIDATE
V4-GATE-C-v1 status: ACQUIRED
V4-MILESTONE-RENEWABLE-SUBSISTENCE-v1 status: NOT STARTED — NEXT ELIGIBLE MILESTONE
V4-GATE-D-v1 status: NOT EVALUATED — BLOCKED ON REQUIRED MILESTONE
CIV-34 status: NOT STARTED
roadmap generation: V4
```

Completing `CIV-33` completes every required CIV phase for Gate D. It does not
complete the required renewable-subsistence milestone and does not evaluate
or acquire Gate D.

## Last validation baseline

For the `CIV-33` local review candidate:

```text
focused estates/inheritance/succession: 84 passed, 0 failed
focused unions/family/lineages/houses: 83 passed, 0 failed
focused lifecycle: 80 passed, 0 failed
focused childhood/guardianship/social development: 62 passed, 0 failed
focused dependent care: 55 passed, 0 failed
focused homeostasis/health: 30 passed, 0 failed
focused checkpoint/replay: 49 passed, 0 failed
focused Observer: 20 passed, 0 failed
focused mortality: 93 passed, 0 failed
focused material rights: 21 passed, 0 failed
repository gate: 3650 passed, 0 failed
repository verification steps: 35/35
rendered two-process CIV-33 death/estate/restart/settlement campaign: PASS
normal birth before death: YES
verified physical exit before estate opening: YES
successor tier: primary active partner at death + canonical child
administrator acceptance count: 1
estate opening count: 1
asset settlement count: 1
estate settlement count: 1
physical quantity before/exit/restart/settlement: 1/1/1/1
claims and permissions conserved under bounded policy: YES
late physical settlement rollback: exact
schema-28 checkpoint/replay and durable successor proof: byte exact
schema-28 compacted-death historical evidence: bounded, digested and byte exact
pre-boundary compacted death eligibility/stage/guardian corruption: refused after complete re-signing
post-boundary death eligibility: exactly preserved
schema-27 exact-proof compatibility: verified; incomplete proof refused
schema-28 manifest integrity digest: verified
estate operational status recomputation: verified
coordinated mortality/estate retention: verified at capacity 2
settlement operation/physical receipt identity: exact and prevalidated
blocked-asset custodian retry: causal, bounded and restart-stable
Observer schema 6: read-only estate projection
persistent child probe restored from protected empty-custody attestation: YES
duplication count: 0
Observer mutation count: 0
runtime errors: 0
cleanup: exact
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
  active union and causal plan event. Schema 27 remains readable
  only when retained causes permit exact reconstruction; incomplete legacy
  proof fails closed. Because schema 28 is still unpublished, incomplete older
  schema-28 candidates are refused instead of introducing schema 29. Physical
  settlement prevalidates one shared
  operation/receipt identity. Blocked custody can be causally revalidated
  after a real guardian or availability change without rewriting allocation,
  claims or permissions. Observer schema 6 projects estate authority
  read-only. The model does not implement wills, taxation,
  valuation, divisible shares, house leadership, public treasury, land law or
  general contract inheritance.
- Gate `V4-GATE-D-v1` requires proof of at least one genuinely renewable
  physical subsistence loop; Gate B did not claim this.

## Next authorized action

After senior review, manual publication and remote verification of this
`CIV-33` candidate, the next eligible work is the separately bounded
`V4-MILESTONE-RENEWABLE-SUBSISTENCE-v1`. It remains **not started**. Gate D is
**not evaluated** and blocked on that required milestone. `CIV-34` is not
started and remains downstream of Gate D.
