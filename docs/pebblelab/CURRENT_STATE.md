# Pebble Civilization — Current state

This file is the compact canonical status. It records product state, not the
SHA of the documentation commit that contains it.

## Acquired

- Gate R — No Parallel Physical Engines: **ACQUIRED AND PUBLISHED**.
- Gate B — Bounded Embodied Local Autonomy:
  **ACQUIRED AND PUBLISHED** under contract `V4-GATE-B-v1`.
- Gate C — Durable Observable Local World:
  **ACQUIRED AND PUBLISHED** under contract `V4-GATE-C-v1`.
- `CIV-00` through `CIV-30`: **COMPLETE** in their bounded contracts.
- Post-Gate-B safe-bootstrap hardening: **PUBLISHED**.

Published product baseline from which `CIV-30` was implemented:

```text
c1eda66dfacdd16911207b6fc8fd58df8581b99f
```

This document does not claim to record the SHA of the commit containing
`CIV-30`. Use Git to identify the exact reviewed or published phase HEAD.

The `CIV-29` completion is published on the canonical branch. The `CIV-30`
completion recorded here is a local review candidate until senior review,
manual push and remote verification complete.

## Current program position

```text
active CIV phase: none
next authorized action: CIV-31 — Childhood, Guardianship and Social Development V2
CIV-30 status: COMPLETE
V4-GATE-C-v1 status: ACQUIRED
CIV-31 status: NOT STARTED — NEXT ELIGIBLE PHASE
V4-GATE-D-v1 status: PLANNED
V4-MILESTONE-RENEWABLE-SUBSISTENCE-v1 status: PLANNED
roadmap generation: V4
```

Completing `CIV-30` makes `CIV-31` eligible; it does not start the phase.

## Last validation baseline

For the `CIV-30` local review candidate:

```text
focused genetics/development/phenotype: 31 passed, 0 failed
focused lifecycle: 80 passed, 0 failed
focused homeostasis/health: 30 passed, 0 failed
focused checkpoint/replay: 49 passed, 0 failed
focused Observer: 20 passed, 0 failed
repository gate: 3405 passed, 0 failed
repository verification steps: 35/35
rendered two-process CIV-30 birth/restart/development campaign: PASS
founder/second-founder/child/post-restart captures: inspected
normal inherited birth: YES
parental locus provenance: YES
schema-22 checkpoint/replay: byte exact
Observer schema 3: read-only
persistent child probe restored from empty-custody attestation: YES
child genotype changed across restart: NO
genotype assignment count: 1
asset duplication count: 0
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
  bootstrap only when the schema-22 live manifest attests empty carried
  custody, the identity remains present in population and lifecycle, and no
  Material Rights record resolves to that agent as physical holder. Non-empty
  custody remains fail-closed and depends on the existing CIV-27
  reconciliation path.
- Gate `V4-GATE-D-v1` requires proof of at least one genuinely renewable
  physical subsistence loop; Gate B did not claim this.

## Next authorized action

After senior review, manual publication and remote verification of this
`CIV-30` candidate, the next mission may start the bounded contract design and
implementation of `CIV-31`. `CIV-31` remains **not started**. Gate D and the
renewable-subsistence milestone remain planned and unevaluated.
