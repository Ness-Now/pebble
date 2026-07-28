# Pebble Civilization — Current state

This file is the compact canonical status. It records product state, not the
SHA of the documentation commit that contains it.

## Acquired

- Gate R — No Parallel Physical Engines: **ACQUIRED AND PUBLISHED**.
- Gate B — Bounded Embodied Local Autonomy:
  **ACQUIRED AND PUBLISHED** under contract `V4-GATE-B-v1`.
- `CIV-00` through `CIV-28`: **COMPLETE** in their bounded contracts.
- Post-Gate-B safe-bootstrap hardening: **PUBLISHED**.

Product implementation baseline reconciled by the `CIV-28` closure:

```text
57d7a57dec3956ba3d4bd30a837fa9417a29efb6
```

This baseline contains:

- the previously published safe-bootstrap hardening;
- `fc09d67` — the versioned, bounded and read-only Observer projection,
  structured reasons and ledger-backed Chronicle;
- `57d7a57` — the rendered Observer UI and a real two-process restart
  campaign.

The SHA above identifies the product commit preceding this status update. It
does not claim to be the SHA of the documentation commit that contains this
file. Always fetch Git to determine the published HEAD.

## Current program position

```text
active CIV phase: none
next authorized action: V4-GATE-C-v1 — independent gate evaluation
CIV-28 status: COMPLETE
V4-GATE-C-v1 status: READY FOR EVALUATION, NOT ACQUIRED
CIV-29 status: PLANNED, NOT ELIGIBLE
roadmap generation: V4
```

Closing `CIV-28` does not evaluate or acquire `V4-GATE-C-v1` and does not
start `CIV-29`.

## Last validation baseline

At the reconciled `CIV-28` product baseline:

```text
focused Observer and Chronicle: 17 passed, 0 failed
repository gate: 3340 passed, 0 failed
repository verification steps: 35/35
CIV-28 rendered two-process Observer campaign: PASS
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
- Observer V1 is a bounded local-session projection. It does not provide
  omniscient multi-settlement inspection, unbounded history, full-text search
  or simulation editing.
- Gate `V4-GATE-D-v1` requires proof of at least one genuinely renewable
  physical subsistence loop; Gate B did not claim this.

## Next authorized action

After senior review, manual publication and remote verification of this phase,
the next mission may independently evaluate `V4-GATE-C-v1` from the
then-current canonical HEAD. That mission must review the combined bounded
contracts of `CIV-26` through `CIV-28`; this closure does not pre-acquire the
gate. `CIV-29` remains ineligible until Gate C is acquired and published.
