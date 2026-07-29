# Pebble Civilization — Current state

This file is the compact canonical status. It records product state, not the
SHA of the documentation commit that contains it.

## Acquired

- Gate R — No Parallel Physical Engines: **ACQUIRED AND PUBLISHED**.
- Gate B — Bounded Embodied Local Autonomy:
  **ACQUIRED AND PUBLISHED** under contract `V4-GATE-B-v1`.
- Gate C — Durable Observable Local World:
  **ACQUIRED** under contract `V4-GATE-C-v1`.
- `CIV-00` through `CIV-28`: **COMPLETE** in their bounded contracts.
- Post-Gate-B safe-bootstrap hardening: **PUBLISHED**.

Product baseline evaluated by the independent Gate C campaign:

```text
3d70c67b69824133eb318391f8e7c385f8cabce8
```

This is the published product tree independently evaluated for the combined
`CIV-26` through `CIV-28` contract. The Gate C evidence and this status update
intentionally do not self-reference their containing commit. Always use Git to
identify the exact reviewed or published HEAD.

The acquisition recorded here is a local publication candidate until senior
review, manual push and remote verification complete.

## Current program position

```text
active CIV phase: none
next authorized action: CIV-29 — Homeostasis, Health, Aging and Mortality V2
CIV-28 status: COMPLETE
V4-GATE-C-v1 status: ACQUIRED
CIV-29 status: NOT STARTED — NEXT ELIGIBLE PHASE
roadmap generation: V4
```

Acquiring Gate C makes `CIV-29` eligible; it does not start the phase.

## Last validation baseline

For the independent Gate C evaluation of the published product baseline:

```text
focused material rights: 21 passed, 0 failed
focused persistence/reconciliation: 18 passed, 0 failed
focused Observer and Chronicle: 20 passed, 0 failed
focused checkpoint/replay: 49 passed, 0 failed
focused Gate C matrix: 108 passed, 0 failed
repository gate: 3343 passed, 0 failed
repository verification steps: 35/35
Gate C rendered two-process missing-asset reconciliation campaign: PASS
representative before/after rendered-world captures: inspected
Observer mutation count: 0
duplication count: 0
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
- Gate `V4-GATE-D-v1` requires proof of at least one genuinely renewable
  physical subsistence loop; Gate B did not claim this.

## Next authorized action

After senior review, manual publication and remote verification of this Gate C
candidate, the next mission may start the bounded contract design and
implementation of `CIV-29`. `CIV-29` remains **not started**; this gate
evaluation implements no health, aging or mortality V2 behavior.
