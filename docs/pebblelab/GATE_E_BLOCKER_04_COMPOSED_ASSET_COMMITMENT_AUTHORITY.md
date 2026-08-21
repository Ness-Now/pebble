# Gate E Blocker 04 — Composed Asset Commitment Authority

## Status

`V4-GATE-E-v1 Blocker 04: FIXED AND PUBLISHED`

This record publishes the senior-review-approved product correction for the
decisive failure found by independent Gate E Evaluation 04. It does not rewrite
that evaluation, acquire Gate E, begin Evaluation 05, or begin CIV-38. Remote
publication verification is not claimed by this containing commit.

- Gate E Evaluations 01 through 04: `FAIL — HISTORICAL IMMUTABLE EVIDENCE`
- Gate E Blockers 01 through 04: `FIXED AND PUBLISHED`
- Gate E: `PLANNED — NOT ACQUIRED`
- Gate E Evaluation 05: `NOT_STARTED`
- CIV-38: `OPTIONAL — NOT STARTED`

## Publication record

```text
affected published baseline: e8bc2fc8add491c324f15478fcd1b82d77566d57
product correction commit: 0318133fe95949c441974871f2581f38c43c6128
reviewed candidate HEAD: 54009009e436c913276e50c162cd30203d8931c3
review bundle SHA-256: f36ba77cc2c58e75b70748892043f72c4703668df1da4291c36f4e828a723b9f
archive integrity: PASS
internal checksums: 118/118 PASS
senior review: APPROVED
publication verified: NO
```

## Evaluation 04 identity

```text
evaluated baseline: e8bc2fc8add491c324f15478fcd1b82d77566d57
falsifier commit: 54bb38c174d5f3241763926a7bda6b900d7dbc8a
evidence HEAD: 07ded1e583b62137b5e8b6cc32d8a61ead73cc53
review bundle SHA-256: d51df031d8cf930316ad0a24f1c21daa2f773cdec576599d3549139cfce7559b
verdict: FAIL — PRODUCT CORRECTION REQUIRED
historical status: FAIL — HISTORICAL IMMUTABLE EVIDENCE
```

Evaluation 04 and its branch remain unchanged. Its evidence HEAD is not in the
ancestry of this correction candidate.

## Historical failure

Evaluation 04 used ordinary contract and market runtime paths to make one
exact durable pickaxe both accepted contract consideration and accepted market
consideration. Each subsystem's local check saw a valid use because no
aggregate authority composed commitments across contracts, markets and barter.

Schema-34 restart retained both commitments. Market settlement then moved the
pickaxe to its new exact current holder while the accepted contract obligation
survived with its stale pre-market custody fingerprint. One unit of matter had
therefore backed two incompatible live economic promises.

## Corrected authority model

`AgentSimulationSession`, the existing civilization aggregate root, now
derives a deterministic exact-asset commitment projection from canonical live
subsystem state:

1. Pending barter offers commit both offered and requested exact assets.
2. An open contract proposal commits its exact consideration asset.
3. An accepted contract commits the same consideration while its obligation is
   awaiting consideration.
4. A nonterminal market deposit commits its offered asset; coherent live
   proposed or accepted consideration commits its exact consideration asset.
5. A transition may continue the same logical operation's existing commitment,
   but any incompatible operation or subsystem is refused.
6. Completed, rejected, expired, cancelled, defaulted, withdrawn, sold or
   otherwise terminal state releases current commitment authority while
   retaining history.

The projection is derived rather than separately persisted. Checkpoint and
replay restore the canonical barter, contract and market states, then derive
the same commitments. State validation rejects incompatible cross-system
projections. Registration order remains deterministic and no second economic
kernel or physical engine was added.

## Physical and cognitive boundaries

Commitment authority is a precondition, not physical authority. Every transfer
still requires exact current Material Rights, holder, owner/custodian, item
identity, quantity, custody fingerprint and applicable locality through the
existing Pebble gateways. Prevalidation occurs before physical mutation and
the existing candidate transaction owns verification and rollback.

Autonomous barter, contract and market discovery and selection also exclude
assets committed to incompatible live operations. The market executor repeats
the composed check immediately before deposit or settlement. The contract and
barter executors likewise admit their own same-operation continuation while
rejecting cross-system reuse.

A narrowly named live adapter seam records fresh, gateway-verified current
barter observation after restart. It does not make a retained fingerprint
current: ordinary discovery continues to reject stale physical evidence.

Verified barter, contract and market receipts now fulfill the exact production
need that motivated the acquired asset. Full satisfaction closes that need
exactly once; partial satisfaction keeps it active. This prevents a fulfilled
need from repeatedly offering the same acquired matter without imposing a
social outcome.

No durable shape changed. Checkpoint/replay remains schema `34`; Observer
remains schema `11` and read-only.

Currency remains outside the Gate E dependency. `CIV-38` is an optional
capability, not a prerequisite for this correction or a future evaluation.

## Focused and regression validation

The dedicated `gate-e-blocker-04` suite passes `28/28`. It proves:

- incompatible contract/market, contract/barter and barter/market use fails
  before physical mutation;
- offered and requested barter legs are both protected;
- same-operation contract, barter and market continuations remain possible;
- terminal state releases only the authority it actually owned;
- restart, replay and compaction preserve live exclusion and terminal release;
- wrong holder, owner/custodian, identity, quantity, fingerprint or locality
  still fails closed;
- verified economic acquisition fulfills the exact motivating need once;
- aggregate validation rejects duplicate cross-system commitments; and
- Observer schema 11 stays derived and read-only.

Owning regressions pass `305/305`: production 36, barter 56, contracts 32,
markets 31, material-rights 23, candidate-physical-atomicity 3,
checkpoint-replay 49, persistence-reconciliation 19, Observer 20 and
autonomous-civilization 36. Published Blocker 01, 02 and 03 focused checks pass
`27/27`, `33/33` and `25/25`. The canonical repository gate passes all `35/35`
steps with `4015/4015` assertions. Goldens were not regenerated.

Senior review accepted the complete archive with `118/118` internal checksums
and passing archive integrity.

## Fresh four-process live proof

The disposable proof uses double gates:

```text
PEBBLELAB_GATE_E_BLOCKER_04=1
PEBBLELAB_DISPOSABLE_WORLD_PROOF=1
```

They are inert outside the disposable proof boundary. Four fresh processes
exercise ordinary contract, barter and market paths across three schema-34
restart boundaries.

The first process establishes exact current matter and an open contract. The
ordinary market path observes the same physical opportunity but selects no
target because the contract owns the live commitment. After restart, the
contract's own acceptance and consideration transfer continue normally; the
terminal consideration commitment is released without erasing contract
history.

A later ordinary barter offer commits that same exact asset and blocks market
reuse. Its own verified two-leg completion remains allowed, moves real matter
and fulfills the motivating need. After a second restart the completed barter
history grants no present authority. Normal autonomous market selection,
physical deposit and automatic listing then reuse the released asset. Bounded
expiry and physical withdrawal return it to exact agent custody.

All 13 fresh Blocker 04 captures were inspected. Fresh inherited live
regressions also pass for Blocker 01 (two processes, nine captures), Blocker 02
(two processes, eight captures) and Blocker 03 (four processes, 16 captures).

## Conservation, replay and cleanup

```text
crossSystemDuplicateLiveCommitments=0
physicalLoss=0
physicalDuplication=0
syntheticMaterial=0
duplicateDeposits=0
duplicateReservations=0
duplicateReceipts=0
duplicateSettlements=0
observerMutationCount=0
unexpectedRuntimeErrors=0
checkpointSchema=34
observerSchema=11
```

Replay verifies causal state without executing World effects. Disposable
fixture cells return exactly to their prior state, all four processes remove
all three probes, and no residual live process remains.

## Non-claims

- Gate E is not acquired.
- Evaluation 04 is not rewritten.
- Evaluation 05 is not started.
- CIV-38 remains optional and not started.
- This containing documentation commit does not claim push, remote publication
  or remote publication verification.

Only after manual publication and independent remote SHA verification, the
next authorized action is
`NEW-INDEPENDENT-V4-GATE-E-v1-EVALUATION-05`. Evaluation 05 remains unstarted.
