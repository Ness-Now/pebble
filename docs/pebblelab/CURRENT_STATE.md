# Pebble Civilization — Current state

This file is the compact canonical status. It records product state, not the
SHA of the documentation commit that contains it.

## Acquired

- Gate R — No Parallel Physical Engines: **ACQUIRED AND PUBLISHED**.
- Gate B — Bounded Embodied Local Autonomy:
  **ACQUIRED AND PUBLISHED** under contract `V4-GATE-B-v1`.
- Gate C — Durable Observable Local World:
  **ACQUIRED AND PUBLISHED** under contract `V4-GATE-C-v1`.
- `CIV-00` through `CIV-29`: **COMPLETE** in their bounded contracts.
- Post-Gate-B safe-bootstrap hardening: **PUBLISHED**.

Published product baseline from which `CIV-29` was implemented:

```text
3452bf92a0f324a2fb9bd9824fc729ec3b4b860c
```

This document does not claim to record the SHA of the commit containing
`CIV-29`. Use Git to identify the exact reviewed or published phase HEAD.

The `CIV-29` completion recorded here is a local publication candidate until
senior review, manual push and remote verification complete.

## Current program position

```text
active CIV phase: none
next authorized action: CIV-30 — Genetics, Development and Phenotype V1
CIV-29 status: COMPLETE
V4-GATE-C-v1 status: ACQUIRED
CIV-30 status: NOT STARTED — NEXT ELIGIBLE PHASE
roadmap generation: V4
```

Completing `CIV-29` makes `CIV-30` eligible; it does not start the phase.

## Last validation baseline

For the `CIV-29` local publication candidate:

```text
focused homeostasis/health/aging/mortality: 30 passed, 0 failed
repository gate: 3374 passed, 0 failed
repository verification steps: 35/35
rendered two-process CIV-29 mixed-inventory/restart campaign: PASS
representative pre-death/material-exit/post-restart captures: inspected
terminal physiology linked directly to lethal depletion: YES
tracked agent-held asset conserved through verified physical exit: 1→1
unregistered agent-held item conserved through verified physical exit: 3→3
whole-boundary late-failure rollback equality: verified
invented social record count: 0
social custody/ownership/claims/permissions changed by death: NO
asset duplication count: 0
physical loss count: 0
Observer mutation count: 0
death count: 1
resurrection count: 0
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
- Gate `V4-GATE-D-v1` requires proof of at least one genuinely renewable
  physical subsistence loop; Gate B did not claim this.

## Next authorized action

After senior review, manual publication and remote verification of this
`CIV-29` candidate, the next mission may start the bounded contract design and
implementation of `CIV-30`. `CIV-30` remains **not started**; this phase
implements no genotype, inheritable phenotype or genetic predisposition.
