# Pebble Civilization — Current state

This file is the compact canonical status. It records product state, not the
SHA of the documentation commit that contains it.

## Acquired

- Gate R — No Parallel Physical Engines: **ACQUIRED AND PUBLISHED**.
- Gate B — Bounded Embodied Local Autonomy:
  **ACQUIRED AND PUBLISHED** under contract `V4-GATE-B-v1`.
- Gate C — Durable Observable Local World:
  **ACQUIRED AND PUBLISHED** under contract `V4-GATE-C-v1`.
- `CIV-00` through `CIV-32`: **COMPLETE** in their bounded contracts.
- Post-Gate-B safe-bootstrap hardening: **PUBLISHED**.

Published product baseline from which `CIV-32` was implemented:

```text
a5f06290e9596756e5690fd284f59aaa457d10d3
```

This document does not claim to record the SHA of the commit containing
`CIV-32`. Use Git to identify the exact reviewed or published phase HEAD.

The `CIV-31` completion is published on the canonical branch. The `CIV-32`
completion recorded here is a local review candidate until senior review,
manual push and remote verification complete.

## Current program position

```text
active CIV phase: none
next authorized action: CIV-33 — Estates, Inheritance and Succession V1
CIV-32 status: COMPLETE
V4-GATE-C-v1 status: ACQUIRED
CIV-33 status: NOT STARTED — NEXT ELIGIBLE PHASE
V4-GATE-D-v1 status: PLANNED
V4-MILESTONE-RENEWABLE-SUBSISTENCE-v1 status: PLANNED
roadmap generation: V4
```

Completing `CIV-32` makes `CIV-33` eligible; it does not start the phase.

## Last validation baseline

For the `CIV-32` local review candidate:

```text
focused unions/family/lineages/houses: 60 passed, 0 failed
focused lifecycle: 80 passed, 0 failed
focused childhood/guardianship/social development: 62 passed, 0 failed
focused dependent care: 55 passed, 0 failed
focused homeostasis/health: 30 passed, 0 failed
focused genetics/development/phenotype: 45 passed, 0 failed
focused checkpoint/replay: 49 passed, 0 failed
focused Observer: 20 passed, 0 failed
focused mortality: 93 passed, 0 failed
focused material rights: 21 passed, 0 failed
repository gate: 3543 passed, 0 failed
repository verification steps: 35/35
rendered two-process CIV-32 union/birth/restart/separation campaign: PASS
physical proposal and independent acceptance: YES
one canonical active union activation: YES
two explicit lineage roots: YES
one co-founded social house: YES
normal child, parentage, inherited genotype and guardian preserved: YES
child shared-parent-house membership count: 1
family relations and lineage memberships: deterministically derived
households remain separate after union and house foundation: YES
material rights unchanged: YES
schema-25 checkpoint/replay: byte exact
schema-25 manifest integrity digest: verified
Observer schema 3: read-only
Observer schema 4: read-only childhood projection
Observer schema 5: read-only family projection
persistent child probe restored from protected empty-custody attestation: YES
union activation count: 1
house foundation count: 1
child house membership count: 1
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
  exactly one active house; otherwise it adds none. Schema 25 persists the
  bounded social records while Observer schema 5 remains read-only.
- Gate `V4-GATE-D-v1` requires proof of at least one genuinely renewable
  physical subsistence loop; Gate B did not claim this.

## Next authorized action

After senior review, manual publication and remote verification of this
`CIV-32` candidate, the next mission may start the bounded contract design and
implementation of `CIV-33`. `CIV-33` remains **not started**. Gate D and the
renewable-subsistence milestone remain planned and unevaluated.
