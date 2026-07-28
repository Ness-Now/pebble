# Pebble Civilization — Current state

This file is the compact canonical status. It records product state, not the
SHA of the documentation commit that contains it.

## Acquired

- Gate R — No Parallel Physical Engines: **ACQUIRED AND PUBLISHED**.
- Gate B — Bounded Embodied Local Autonomy:
  **ACQUIRED AND PUBLISHED** under contract `V4-GATE-B-v1`.
- `CIV-00` through `CIV-27`: **COMPLETE** in their bounded contracts.
- Post-Gate-B safe-bootstrap hardening: **PUBLISHED**.

Product implementation baseline reconciled by the `CIV-27` closure:

```text
eb63a62a6d5e6851bd11b98926591db3be608f5d
```

This baseline contains:

- the previously published safe-bootstrap hardening;
- `eb63a62` — bounded World/civilization persistence and reconciliation,
  checkpoint/replay schema 20, and a real two-process rendered-World restart
  campaign.

The SHA above identifies the product commit preceding this status update. It
does not claim to be the SHA of the documentation commit that contains this
file. Always fetch Git to determine the published HEAD.

## Current program position

```text
active CIV phase: none
next eligible phase: CIV-28 — Observer and Chronicle V1
CIV-27 status: COMPLETE
CIV-28 status: NOT STARTED
roadmap generation: V4
```

Preparing or publishing this documentation does not start `CIV-28`.

## Last validation baseline

At the reconciled `CIV-27` product baseline:

```text
focused persistence reconciliation: 18 passed, 0 failed
focused material rights regression: 21 passed, 0 failed
focused checkpoint/replay regression: 49 passed, 0 failed
repository gate: 3323 passed, 0 failed
repository verification steps: 35/35
CIV-27 real two-process restart campaign: PASS
representative before/after rendered-world captures: inspected
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
- Gate `V4-GATE-D-v1` requires proof of at least one genuinely renewable
  physical subsistence loop; Gate B did not claim this.

## Next authorized action

After senior review, manual publication and remote verification of this phase,
a new mission may open `CIV-28` from the then-current canonical HEAD.
`CIV-28` may expose read-only authoritative projections and causal history; it
must not compute business truth in the UI, reopen Gate C, or begin markets,
currency, inheritance, land law or tribunals.
