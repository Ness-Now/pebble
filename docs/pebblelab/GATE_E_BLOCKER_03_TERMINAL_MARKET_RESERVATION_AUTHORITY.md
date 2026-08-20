# Gate E Blocker 03 — Terminal Market Reservation Authority

## Status

`V4-GATE-E-v1 Blocker 03: IMPLEMENTED_LOCAL_REVIEW_CANDIDATE — NOT PUBLISHED`

This is a product-correction review candidate. It does not rewrite Evaluation
03, acquire Gate E, begin Evaluation 04, begin CIV-38, or claim publication.

- Gate E Evaluation 01: `FAIL — HISTORICAL IMMUTABLE EVIDENCE`
- Gate E Blocker 01: `FIXED AND PUBLISHED`
- Gate E Evaluation 02: `FAIL — HISTORICAL IMMUTABLE EVIDENCE`
- Gate E Blocker 02: `FIXED AND PUBLISHED`
- Gate E Evaluation 03: `FAIL — HISTORICAL IMMUTABLE EVIDENCE`
- Gate E Blocker 03:
  `IMPLEMENTED_LOCAL_REVIEW_CANDIDATE — NOT PUBLISHED`
- Gate E: `PLANNED — NOT ACQUIRED`
- Gate E Evaluation 04: `NOT_STARTED`
- CIV-38: `OPTIONAL — NOT STARTED`

## Evaluation 03 identity

```text
evaluated baseline: bfb721d7f49f8af567c86580cdf4c106da977a25
evidence commit 1: e77af9ffc2c13c9cc1c209153f9cf64722ea0797
evidence commit 2 / evidence HEAD: 56af9648da0155cfba25588320d2070d211a1cd7
review bundle SHA-256: c3e203e507ff8fd28781b9a067317493fd348e839e6e0b8386d95d18251af883
verdict: FAIL — PRODUCT CORRECTION REQUIRED
historical status: FAIL — HISTORICAL IMMUTABLE EVIDENCE
```

Evaluation 03 and its branch remain unchanged. Its evidence HEAD is not in the
ancestry of this correction candidate.

## Historical failure

Evaluation 03 used ordinary market runtime paths to complete two physical
trades, preserve two exact local-price rows and restore checkpoint schema 34.
The decisive proposals remained `accepted`, their listings became `completed`
and their deposits became `sold`. The same durable bread consideration asset
was then in exact current agent custody with no live deposit or listing.

`AgentMarketProposalStatus.isPending` included `accepted`, and
`AgentMaterialAssetID.isReservedInMarket` treated the consideration asset as
reserved from that status alone. It did not require the proposal's listing and
deposit to remain live. Ordinary deposit discovery found a valid current
opportunity, but autonomous selection returned none. Historical terminal
records had retained present disposition authority across restart.

## Corrected authority model

Reservation is derived from the complete live market state, not from proposal
history in isolation:

1. A nonterminal deposit reserves its offered asset.
2. A `proposed` consideration reserves its exact asset only while its listing
   is `open` and its deposit is `listed`.
3. An `accepted` consideration reserves its exact asset only while its listing
   and deposit are both `reserved`.
4. `accepted` + `completed` + `sold` is retained as historical settlement
   evidence but grants no current reservation authority.

The accepting transition also marks sibling live proposals stale. State
validation admits only coherent accepted/live or accepted/completed triads.
The physical executor independently checks the same reservation predicate
before mutation, and autonomous deposit selection skips genuinely reserved
assets.

This does not make historical provenance current authority. A released asset
still requires exact current holder, recognized owner/custodian, item identity,
quantity, custody fingerprint and locality through the normal physical path.

No durable shape changed. Checkpoint/replay remains schema `34`; Observer
remains schema `11` and read-only.

## Product correction

The product correction is committed at:

```text
301dfd58aacd3aa0af653fa460ad38484df1d762
```

It changes the shared market reservation boundary, executor precondition,
autonomous selection guard and state-machine validation. It adds focused
Blocker 03 regression coverage and a gated fresh live proof. It does not
rewrite proposal, trade or price history and does not add a second physical or
economic authority.

## Focused regression

The dedicated `gate-e-blocker-03` suite passes `25/25`. It proves:

- proposed/open/listed and accepted/reserved/reserved triads reserve strictly;
- incompatible concurrent use remains refused;
- completed/accepted/sold history releases the exact consideration asset;
- restart and replay preserve history and release without moving matter;
- wrong holder, quantity, item and stale physical authority fail closed;
- an unrelated terminal proposal cannot reserve another asset;
- compaction cannot recreate terminal authority or release live authority;
- sibling proposal state cannot retain a second live reservation;
- trade receipts and local-price provenance remain exact; and
- Observer schema 11 stays read-only.

Owning regressions pass `301/301`: production 36, barter 54, contracts 30,
markets 31, material-rights 23, candidate-physical-atomicity 3,
checkpoint-replay 49, persistence-reconciliation 19, Observer 20 and
autonomous-civilization 36. Blocker 01 focused passes `27/27`; Blocker 02
focused passes `33/33`. The canonical repository gate passes `35/35` steps
with `3983/3983` assertions. Goldens were not regenerated.

## Fresh four-process live proof

The disposable proof uses double gates:

```text
PEBBLELAB_GATE_E_BLOCKER_03=1
PEBBLELAB_DISPOSABLE_WORLD_PROOF=1
```

They are inert outside the disposable proof boundary. Four fresh processes
perform ordinary deposit, listing, proposal, decision, settlement, withdrawal
and autonomous re-entry paths across three schema-34 restart boundaries.

Before the first settlement, the accepted proposal has a reserved listing and
reserved deposit. The trace reports `liveAccepted=1`, `targetReserved=1` and
refuses incompatible reuse. After verified settlement, the exact proposal,
trade and price row remain, while `terminalAccepted=1`, `targetReserved=0` and
`terminalOnlyReleased=1`.

The campaign completes a second physical trade and preserves two accepted
proposals, two completed listings and two local-price rows. A fresh fourth
process restores exact current bread x2 custody for `agent_2` with no
nonterminal target deposit or listing. Normal discovery and autonomous
selection then perform a real deposit of that same durable asset:

```text
normalDepositDecision=1
depositPhysicalMutation=1
ordinaryAutonomousSelection=1
reservationAuthorityBefore=0
duplicateDeposits=0
```

Normal listing follows, then bounded expiry and physical withdrawal return the
asset to exact agent custody. Checkpoint `market-blocker03-reentered-v34`
persists that continued ordinary market path. All 16 fresh captures were
inspected.

## Conservation, replay and cleanup

```text
physicalLoss=0
physicalDuplication=0
syntheticMaterial=0
duplicateDeposits=0
duplicateReservations=0
duplicateTradeReceipts=0
duplicateSettlements=0
observerMutationCount=0
unexpectedRuntimeErrors=0
checkpointSchema=34
observerSchema=11
```

Replay verifies causal state without executing World effects. Disposable
fixture cells return exactly to their prior state, every process removes all
three probes, and no residual live process remains.

## Non-claims

- This candidate is not published.
- Gate E is not acquired.
- Evaluation 03 is not rewritten.
- Evaluation 04 is not started.
- CIV-38 remains optional and not started.
- No push was attempted.

