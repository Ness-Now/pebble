# Gate D Blocker 07 — Reconciliation after physical restore

## Status and scope

```text
Gate D Evaluation 07: EVALUATED_FAIL_NOT_ACQUIRED — HISTORICAL EVIDENCE
Gate D Blocker 07: BLOCKER_FIX_PUBLISHED
Gate D: EVALUATED_FAIL_NOT_ACQUIRED
Independent Gate D Evaluation 08: NOT_STARTED — NEXT AUTHORIZED ACTION
CIV-34: NOT_STARTED
```

This targeted correction starts directly from published baseline
`bbafcb51ef0d8387e95302a134ec038fbb8dffa6`. It does not incorporate an
Evaluation 07 commit, reevaluate or acquire Gate D, start Evaluation 08, or
start `CIV-34`. The published product-fix head is
`650b56b90381306c38d891dfdade9d89a1c45db5`.

## Root cause

The published checkpoint loader decoded and validated the durable checkpoint,
then ran Material Rights persistence reconciliation before restoring the
checkpoint's probes, positions, and protected physical custody. A fresh
bootstrap probe for `agent_1` therefore appeared empty while the checkpoint
social state already named it as holder of the inherited pickaxe. That
transient bootstrap observation produced a durable current result of
`missing`.

The same load then restored the checkpoint-bound escrow exactly. PebbleCore
held one inherited pickaxe at `agent_1`, with zero physical loss or
duplication, but the earlier `missing` result remained in the published
session. Normal inherited use consequently failed closed as
`physicalAssetUnresolved`. Repeating the use without a new mutation produced
the same refusal.

## Ordered checkpoint boundary

The loader now treats physical restoration and current reconciliation as one
ordered candidate boundary:

1. decode and validate the checkpoint, manifest, World binding and custody
   evidence;
2. stage the civilization session and adapter state without publication;
3. retire bootstrap probes absent from the checkpoint;
4. reposition reusable probes and create only authorized missing probes;
5. adopt the exact checkpoint-bound physical custody escrow;
6. verify the complete active probe population, dead-probe retirement,
   positions, custody, non-probe World entities and uniqueness;
7. declare the complete physical checkpoint boundary acquired;
8. run one current Material Rights reconciliation against that acquired
   PebbleCore state and validate the estate cross-domain candidate;
9. publish the session, controller state and current reconciliation together.

No successful load publishes a pre-restore reconciliation. The ordering is
generic across the complete checkpoint population and all bounded Material
Rights records; it does not special-case the Evaluation 07 asset ID.

## Durable history and current truth

Material Rights remains a constraint and verified projection, never physical
authority. A matched current observation is retained in the new reconciliation
run as evidence that the durable holder, exact material identity, quantity and
custody fingerprint agree with the restored physical truth. It does not
rewrite the earlier durable physical receipt merely because the load performed
a fresh read of the same state. A genuinely changed but reconcilable physical
fact continues to update the durable current projection under the existing
policy.

This preserves historical settlement evidence while publishing a current
`matched` reconciliation result. Missing, changed, wrong-holder and ambiguous
physical states remain fail-closed; social ownership cannot create an item.

## Atomic failure and rollback

A dedicated proof seam runs after the post-physical Material Rights candidate
is complete but before any session publication. Injecting there restores the
fresh bootstrap World exactly:

- checkpoint-created probes are removed;
- reusable and retired probes return to their prior state;
- adopted custody spills return to the World;
- source chunks recover their prior modification state;
- controller/session/handoff state is unchanged;
- the candidate reconciliation and causal event are discarded;
- recorder/replay publication remains unchanged.

The immediate same-process load retry succeeds without manual reconciliation,
another restart, or debug repair. It publishes exactly one current
reconciliation run. The failed candidate contributes zero published runs.

## First inherited use

The dedicated live proof performs a normal Material Rights decision and a real
Pebble physical block break with the inherited `iron_pickaxe`. The first
attempt after fresh load is allowed as `recognizedOwner`, changes tool damage
from 0 to 1, removes the target block, acquires its real drop and publishes one
verified use operation.

That physical use legitimately changes the current tool observation. The
transferred estate entry now advances only its current destination observation
with the verified Material Rights projection; its immutable settlement
observation and settlement receipt remain unchanged. Checkpoint round-trip
tests preserve both truths exactly.

## Dedicated and adversarial proof

The executable runner is
`scripts/verify-pebblelab-gate-d-reconciliation-after-physical-restore-fix.sh`.
It runs two independent two-process campaigns:

- normal settlement, protected checkpoint, fresh load, one matched current
  reconciliation and first-attempt inherited use;
- the same history with a post-reconciliation-candidate load fault, exact
  rollback, immediate same-process load retry and first-attempt inherited use.

The published baseline-red trace records `outcomes=missing` before the same
load reports one restored custody stack and before physical inspection proves
the pickaxe exists once at `agent_1`. The corrected trace records physical
boundary acquisition first, then `phase=postPhysicalBoundary published=0`,
then one coherent checkpoint publication with `outcomes=matched`.

Existing persistence-reconciliation smoke covers missing, wrong identity,
wrong quantity, conflicting holder and ambiguous matching observations. The
Blocker 05 campaign separately proves that stale handoff, corrupt custody
evidence and manifest-only missing escrow cannot recreate matter. The Blocker
06 campaign proves co-mingled estate settlement, real post-mutation late fault,
exact rollback and immediate retry.

## Validation result

```text
baseline-red premature reconciliation: reproduced (outcomes=missing)
post-restore current reconciliation: PASS (outcomes=matched)
successful-load committed reconciliation runs: 1
failed-load published reconciliation runs: 0
post-candidate load rollback: exact
immediate same-process load retry: PASS
first inherited use: allowed on first attempt
inherited physical mutation: PASS (pickaxe damage 0>1, block removed)
physical loss / duplication / synthetic material: 0 / 0 / 0
repository shared smoke: 3764 passed, 0 failed
repository verification steps: 35/35
Gate D Blockers 01 through 06: PASS
checkpoint schema / Observer schema: 30 / 7 (unchanged)
golden regeneration: NOT ATTEMPTED
```

## Limits

The correction does not make a civilization record authority to restore
physical material. Protected non-empty custody still requires Blocker 05's
exact checkpoint-bound escrow. Unsupported abrupt loss remains fail-closed.
The supported idempotence boundary is one successful publication per load;
failed candidates publish nothing and may be retried. Reusing consumed escrow
or bypassing freshness evidence is not supported. This correction does not
redesign Material Rights, change a durable schema, or acquire Gate D.
