# Gate D Blocker 06 — Estate source physical authority

## Status and scope

```text
Gate D Evaluation 06: EVALUATED_FAIL_NOT_ACQUIRED — HISTORICAL EVIDENCE
Gate D Blocker 06: BLOCKER_FIX_PUBLISHED
Gate D: EVALUATED_FAIL_NOT_ACQUIRED
CIV-34: NOT_STARTED
Independent Gate D Evaluation 07: NOT_STARTED — NEXT AUTHORIZED ACTION
```

This targeted correction starts directly from published baseline
`82a2e50da4db2fe861b88801e033788a2de16dd4`. It does not incorporate an
Evaluation 06 commit, rerun that evaluation, acquire Gate D, start Evaluation
07 or start `CIV-34`. The published product-fix head is
`780ea9d7137b728d0fc4873152479f65ebe57d18`.

## Root cause

A durable estate entry for one `iron_pickaxe ×1` retained the complete custody
fingerprint observed when the estate opened. Normal mortality later transferred
one unrelated, socially unregistered `iron_hoe ×1` into the same durable
container. PebbleCore still held the exact pickaxe at the exact holder, but the
full-container fingerprint changed. Settlement treated that fingerprint as
the durable identity of the asset and refused `stale estate source` before any
physical mutation.

The existing rollback proof accepted every thrown settlement error. It could
therefore classify that pre-mutation stale-source refusal as
`lateFailure=verified`, despite never reaching the physical transfer or the
late-fault injection seam. Fresh-process reconciliation appeared to cure the
first problem only because it reacquired the current exact holder observation
and fingerprint; restart was accidentally acting as an authority refresh.

## Physical authority boundary

The correction preserves the existing durable material identity. It does not
introduce per-item UUIDs, a second inventory model or social material creation.
An estate entry remains bound to:

- the durable estate and entry identities;
- the expected physical holder;
- the exact existing material identity, including item state;
- the exact expected quantity;
- the existing estate, successor and Material Rights constraints.

Immediately before settlement, Pebble inspects the current real endpoint. The
tracked material must appear as exactly one unambiguous stack with the exact
identity and quantity. Only then is the current complete endpoint fingerprint
acquired and passed to the existing Material Custody Gateway as the immediate
atomic mutation precondition.

An unrelated stack added, removed or moved outside the tracked identity does
not invalidate the pickaxe. A removed pickaxe, changed damage/state, changed
quantity, wrong holder or more than one indistinguishable matching stack is
refused before mutation. The system never accepts “whatever is currently in
the container.”

## Co-mingled settlement and publication

The gateway transfers only the exact tracked pickaxe. Its existing custody
transaction rechecks the current source and destination fingerprints, applies
the physical extraction/insertion, verifies conservation and owns exact
compensation. Post-mutation verification requires one exact destination stack
of the expected quantity and no remaining matching source stack. The unrelated
hoe and every unrelated slot remain untouched.

Estate, Material Rights, replay and receipt candidates are staged only after
physical verification. Successful publication changes the physical holder,
custodian and owner projection to the intended successor, marks the one estate
entry transferred and records one settlement receipt. Material Rights remains
a constraint and verified projection, never a source of matter.

## True late-fault proof

The rollback proof now uses a dedicated injection closure inside the gateway's
post-mutation verifier. Its order is:

1. durable estate and rights validation;
2. current asset-scoped source observation;
3. current full source and destination transaction fingerprints;
4. successful physical transfer;
5. exact source and destination post-mutation verification;
6. explicit injected failure;
7. gateway rollback and exact rollback verification;
8. no candidate session, estate, rights, receipt or replay publication.

Only the dedicated injected-failure sentinel can produce
`lateFailure=verified`. Any stale source, missing source, ambiguous source or
other pre-mutation error reports `seamReached=0`,
`physicalMutationOccurred=0`, `lateFailureVerified=0` and
`rollbackClaim=none`.

After a genuine late failure, the proof compares source, destination, session,
estate, Material Rights and replay state byte-for-byte with their pre-action
snapshots. The same normal settlement is then retried immediately in the same
process, without restart, reconciliation or manual refresh, and succeeds.

## Dedicated proof

The executable runner is
`scripts/verify-pebblelab-gate-d-estate-source-physical-authority-fix.sh`.
It has a historical-red mode and a default green campaign. The green campaign
uses four real application processes:

- no-fault process A constructs normal mortality with the co-mingled holder,
  proves adversarial source classification and settles immediately;
- no-fault fresh process B restores the settled material and estate truth,
  advances productively and cleans up exactly;
- late-fault process A proves pre-mutation refusal classification, reaches the
  real post-mutation seam, rolls back exactly and retries immediately;
- late-fault fresh process B restores the retry result, advances productively
  and cleans up exactly.

The baseline-red mode reproduced `stale estate source` on the exact published
baseline after mortality added the hoe, with no settlement mutation. The green
campaign proves one pickaxe transferred, one hoe retained, physical loss 0,
physical duplication 0, synthetic material 0, one estate receipt and zero
duplicate receipts. Six native rendered captures were inspected at original
resolution.

## Regression result

Focused suites all pass:

| Scope | Passed | Failed |
| --- | ---: | ---: |
| estates / inheritance / succession | 84 | 0 |
| mortality / physical exit | 93 | 0 |
| homeostasis / health | 30 | 0 |
| material custody | 35 | 0 |
| Material Rights | 21 | 0 |
| checkpoint / replay | 49 | 0 |
| persistence / reconciliation | 18 | 0 |

The published Blocker 01, 02, 03, 04 and 05 runners all pass. The canonical
repository gate passes all 35 steps; its shared smoke suite reports 3761
passed and 0 failed. No golden was regenerated. Session schema 30 and Observer
schema 7 are unchanged.

## Limits

The durable reference continues to identify one bounded physical stack, not
an individual unit within a merged stack. If current physical state cannot
distinguish one exact tracked stack from multiple identical candidates, the
operation deliberately fails closed. This correction does not redesign
Material Rights, add divisible estate shares, or claim Gate D acquisition.
