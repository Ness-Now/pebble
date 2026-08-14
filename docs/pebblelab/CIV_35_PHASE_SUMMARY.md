# CIV-35 — Barter and Local Exchange V1

## Verdict and publication record

`CIV-35` is **COMPLETE AND PUBLISHED** in its bounded V1 contract. Senior
review approved the corrected product implementation and final evidence. The
phase was implemented directly from the exact published canonical baseline:

```text
8b7faa4cd03e315dec5696f72ec1ad75e333c77f
```

Accepted implementation history:

```text
original CIV-35 product commit:
144bcaf162b37f92b151ec2180c0bd9be294adce

initial candidate documentation HEAD:
b80b6bdda4345cd002ed34296dea92562cbb5fc1

Senior Review Correction 01 product correction:
43c6b6ba00fee879918125cb9cffd79e653c49fc

corrected reviewed evidence HEAD:
1dbe84fdc9286b35e05a0aaaf8673ec0ce99718a

senior review: APPROVED
final review bundle SHA-256:
c26a79fa7641e2da534f4bf18954bdbe50635d6bc9306be55a7b705af321e41d
internal checksums: 37/37 PASS
unzip: PASS
```

The first candidate at `b80b6bdda4345cd002ed34296dea92562cbb5fc1`
was not independently approved. Senior review required and subsequently
approved this correction:

```text
CIV-35 Senior Review Correction 01A:
normal barter discovery/negotiation was proof-fixture-bound

CIV-35 Senior Review Correction 01B:
terminal offers could permanently exhaust maximumOffers
```

Both defects are corrected. This publication does not reopen CIV-34 or Gate D
and does not begin CIV-36.

## Corrected reuse-first architecture

The accepted physical exchange architecture is unchanged. PebbleCore remains
authoritative for item stacks, inventory extraction/insertion, capacity,
durability and World truth. Pebble still uses
`PebbleAgentMaterialCustodyGateway` for both physical legs, read-only
prevalidation for both destinations, and `PebbleCandidatePhysicalTransaction`
for reverse-order compensation. CIV-26 Material Rights publishes social
consequences only after physical verification. The sole
`AgentSimulationSession` owns cognition, offers, decisions and bounded durable
history. Observer remains read-only.

The corrected normal product seam is:

```text
Pebble:
bounded nearby embodiments + LOS/chunk/distance evidence
+ current exact rights-tracked custody/fingerprints
→ bounded physical pair observations

PebbleAgents:
current active needs + current rights decisions + stable ordering
→ opportunity → offeror proposal → named counterparty evaluation

Pebble:
current physical revalidation → two-sided verified execution/compensation
```

Production defaults bound discovery to 8 agents, 4 nearby counterparties per
agent, 4 current physical goods per agent, 32 physical pair candidates per
tick, 8 active needs per agent and 4 discoveries per tick. There is no
settlement-wide inventory query, all-World item scan, global market matcher,
price oracle, currency or second transfer engine.

The disposable barter fixture now creates only the World, real goods, rights,
needs and nearby embodiments. It no longer creates an
`AgentBarterOpportunityObservation`, offer or decision. Its live trace records
`barterProofFixtureDecisionAuthority=0` and
`manualProductiveBarterCommandsAfterBootstrap=0`.

## Spot-barter and offer lifecycle contract

An opportunity binds two distinct agents to two current stack-scoped assets,
exact material identities and quantities, full custody fingerprints, current
local evidence and one active reason for each received good. An offer reserves
both exact asset references socially but moves no matter. The named
counterparty independently rechecks its current need and current local
evidence; changed locality or a fulfilled/withdrawn need can produce refusal.
Acceptance still moves no matter.

At execution, Pebble rechecks both CIV-26 disposal decisions and both current
fingerprints, prevalidates both Core transfers, mutates and verifies both
legs, and only then publishes the exchange and rights transitions. Self-trade,
invalid quantities, duplicate participants, overlapping authority, expired or
withdrawn offers and duplicate operations fail closed.

The production configuration retains at most 32 offer projections with a
four-tick lifetime. On capacity pressure, only terminal projections are
eligible for deterministic eviction:

```text
completed, rejected, withdrawn, expired, stale, failed
```

The oldest terminal projection by causal decision sequence and then offer ID
is removed first. `open` and `accepted` offers are never evicted; if all slots
are pending, a new offer fails boundedly. Reservation authority is derived
only from retained pending offers, so every terminal transition releases its
reservation. Completed records, rights state, causal history and processed
operation retention keep their own existing bounded contracts and do not
depend on an evicted offer projection.

The focused lifecycle configuration uses `maximumOffers=8` and
`offerLifetimeTicks=2`. It performs 24 lifetime offer attempts, including 21
terminal churn attempts across rejection, expiration, withdrawal, stale and
failed states. Retained offers never exceed 8, two simultaneous pending offers
survive capacity reclamation, and a fresh schema-32 restore accepts another
offer after compaction. Pending offers accidentally evicted: zero.

CIV-34 provenance is retained when exact current production records reconcile
the observed stack, but it is not a universal eligibility condition. A focused
ordinary `oak_log ↔ cobblestone` opportunity with exact rights and needs is
discoverable without production IDs. The decisive campaign still exchanges a
real CIV-34-produced good.

## Corrected decisive live campaign

The two-process seed-46 campaign takes the corrected normal route:

```text
producer / offeror: agent_0
counterparty: agent_1
local Manhattan distance: 1

CIV-34 inputs → output:
3 cobblestone + 2 sticks → stone_pickaxe x1

before:
agent_0 holds stone_pickaxe x1
agent_1 holds bread x2

reasons:
agent_0 physicalFoodNeed for bread x2
agent_1 missingUsefulTool for stone_pickaxe x1

runtime discovery: normalOpportunityDiscovery=1
offer: barter-2f8d7877e8728aab, selected by normal cognition
decision: independently accepted by agent_1 from current need/locality
physical receipts:
barter:barter-2f8d7877e8728aab:offered
barter:barter-2f8d7877e8728aab:requested

after:
agent_0 holds bread x2
agent_1 holds the exact produced stone_pickaxe x1
```

The fixture injects no decisive opportunity after bootstrap, and no productive
barter command is issued after bootstrap. The completed rights publication
recognizes agent_1 as holder, custodian and owner of the pickaxe with a
received claim, and agent_0 equivalently for the bread. Rights publication is
not physical transfer authority.

## Atomicity, refusal and stale authority

The corrected live route reaches a first real pickaxe transfer, then fires the
deterministic post-mutation fault before the bread transfer or social
publication. The candidate transaction reverses the registered first transfer,
retains no receipt and leaves the session and recorder unchanged. The next
same-process tick rediscovers current authority, repeats the counterparty
evaluation and completes exactly once.

Focused and live evidence preserves:

```text
offer does not move matter: PASS
acceptance does not move matter: PASS
counterparty refusal: rejected, no receipt
missing good: insufficientQuantity
wrong quantity: invalidRequest
stale/external source: staleSource, no substitute
unauthorized holder disposition: noUseRight
destination capacity: destinationFull
concurrent double-spend: second reservation refused
withdrawal/expiration: later authority refused/released
true mid-exchange mutation: reached
rollback: exact
immediate retry: PASS
```

Campaign accounting remains:

```text
physicalLoss=0
physicalDuplication=0
syntheticMaterial=0
duplicateExchangeReceipts=0
duplicateReservations=0
observerMutationCount=0
```

## Restart, replay, downstream use and Observer

Checkpoint/replay schema remains 32 and Observer schema remains 9; no schema
bump was needed for the correction. Pending physical authority is not
checkpoint-safe. Terminal compacted offer projections and completed records
round-trip byte-exactly, and a restored session can create a further offer
without resurrecting a terminal reservation.

The corrected live process saves `barter-v32` with digest
`2458759f4bef4b8ab0743fb79eca199906dadd50870c9f92658270b7c842568a`.
A fresh Pebble process acquires the checkpoint-bound physical boundary,
restores two protected stacks with quantity three and reports
`custodyDuplicates=0`. No completed exchange re-executes.

Agent_1 then uses the exact exchanged CIV-34 pickaxe through the existing
physical block-break path:

```text
stone_pickaxe damage 0 → 1
World stone → air
downstreamUse=PASS
```

The final schema-32 checkpoint digest is
`763297299ca84a6c6de3b81196806a6aa51ad0be51af62a3724f9cb2718b83d4`.
Typed replay reconstructs civilization history without moving World goods.
Observer schema 9 exposes retained completed records and current rights even
when old terminal offer projections have been compacted; snapshot construction
mutates nothing.

## Verification

Focused CIV-35 validation:

```text
54 passed, 0 failed
```

Canonical validation:

```text
3862 passed, 0 failed
35/35 repository steps
checkpoint schema: 32
Observer schema: 9
golden regeneration: not attempted
```

The corrected rendered live campaign passed in two Pebble processes. Phase 1
contains one expected injected runtime error and phase 2 contains zero runtime
errors. Six native captures were inspected: pre-exchange, open offer,
post-exchange, fresh restore, produced-tool use and final cleanup. Evidence is
retained under
`/var/folders/23/t4l5dv055dl3x1zqylcpl9wc0000gn/T/PebbleLab-live.kmlede`.
Disposable cells were restored exactly while exchanged goods remained in
verified custody.

## Explicit non-claims

CIV-35 does not prove debt, future promises, durable contracts, credit,
markets, market price discovery, currency, accounting, merchant organizations,
large-scale trade or global logistics. It adds no loans, interest, default,
contract enforcement, order books, matching engines, market stalls as
economic authority, supply/demand curves, taxation, wages, firms, shops,
guilds or trade law. CIV-36, CIV-37 and CIV-38 remain outside this correction.

## Published program state

```text
CIV-34: COMPLETE AND PUBLISHED
CIV-35: COMPLETE AND PUBLISHED
CIV-36: NOT_STARTED — NEXT ELIGIBLE PHASE
Gate D: ACQUIRED AND PUBLISHED
active phase: none
completed through: CIV-35
next: CIV-36
```
