# CIV-35 — Barter and Local Exchange V1

## Verdict and baseline

`CIV-35` is **IMPLEMENTED_LOCAL_REVIEW_CANDIDATE** in its bounded contract.
It was implemented directly from the exact published canonical baseline:

```text
8b7faa4cd03e315dec5696f72ec1ad75e333c77f
```

The work is local and has not been published. `CIV-34` remains complete and
published, `CIV-36` remains not started, and the next authorized action is
senior review of CIV-35. Gate D remains acquired and published.

## Reuse-first architecture

The implementation adds no parallel inventory, recipe, transfer, market,
price, currency or obligation engine.

- PebbleCore remains authoritative for item stacks, inventory extraction,
  insertion, capacity, durability and World truth.
- Pebble reuses `PebbleAgentMaterialCustodyGateway` for both physical legs.
  Its new read-only barter prevalidation simulates both canonical Core
  transfers before mutation. The existing
  `PebbleCandidatePhysicalTransaction` owns reverse-order compensation.
- PebbleAgents retains only bounded local observations, value reasons, exact
  offers, decisions and verified exchange history in the sole
  `AgentSimulationSession`.
- CIV-26 Material Rights remains the social authority. Holder, recognized
  owner, custodian, claim and permission stay distinct; physical truth is
  never inferred from the rights record.
- CIV-34 production receipts bind the offered pickaxe to its real inputs,
  output identity and current physical custody.
- The existing local physical-signal adapter supplies bounded distance,
  line-of-sight and chunk readiness. There is no settlement inventory scan,
  global price oracle or long-distance economic channel.

The permanent distinctions remain explicit:

```text
physical custody
!= possession
!= recognized ownership
!= claim
!= permission/use right
!= offer
!= accepted exchange
!= obligation
```

## Bounded spot-barter contract

An opportunity names two distinct local agents, two current stack-scoped
assets, exact material identities and quantities, full holder fingerprints,
and one causal active need for each received good. An offer reserves both
asset references socially but moves no matter. Only the named counterparty
can independently accept or reject it. Acceptance still moves no matter.

Execution rechecks both CIV-26 disposal decisions and both current physical
fingerprints, prevalidates both Core transfers, performs both exact legs,
verifies both destination observations and only then publishes one completed
exchange and two rights transitions. Self-trade, empty/invalid quantities,
duplicate participants, overlapping asset authority, expired or withdrawn
offers and duplicate operations fail closed. Offers, records, processed
operations, candidate goods, local distance and causal history are explicitly
bounded and deterministically ordered.

CIV-35 is immediate spot barter only. No pending physical authority is
restart-safe: checkpoint readiness refuses an open or accepted offer. Only
terminal exchange history is durable. A completed exchange is replayed as
social history and never re-executes either World transfer.

## Decisive product campaign

The two-process disposable-world campaign uses the normal autonomous
civilization activity path:

```text
producer / offeror: agent_0
counterparty: agent_1
local Manhattan distance: 1

CIV-34 inputs -> output:
3 cobblestone + 2 sticks -> stone_pickaxe x1

before:
agent_0 holds stone_pickaxe x1
agent_1 holds bread x2 from two real CIV-34 productions

reasons:
agent_0 physicalFoodNeed for bread x2
agent_1 missingUsefulTool for stone_pickaxe x1

offer: civ35-primary, explicit by agent_0
decision: explicit acceptance by agent_1 using current local evidence
physical receipts:
barter:civ35-primary:offered
barter:civ35-primary:requested

after:
agent_0 holds bread x2
agent_1 holds the exact produced stone_pickaxe x1
```

The completed rights publication recognizes agent_1 as holder, custodian and
owner of the pickaxe with a received claim, and agent_0 equivalently for the
bread. This coherence is a social publication after physical verification;
it is not the authority that moved either stack.

The focused variation proves an independent rejection with no mutation or
receipt, followed by an alternative accepted offer. This avoids a compulsory
or one-outcome special case without introducing a market.

## Atomicity and adversarial authority

The live deterministic seam fires after the first real pickaxe transfer and
before the bread transfer or any civilization publication. The existing
candidate transaction reports the registered and completed compensation,
restores the exact inventories and gateway receipts, and leaves the published
session and recorder unchanged. The immediately following same-process tick
re-evaluates acceptance and completes the exchange once.

The focused and live matrix proves:

```text
missing good: insufficientQuantity, no mutation
wrong quantity: invalidRequest for an impossible two-unit tool stack, no mutation
stale offer/fingerprint: staleSource, no substitution
counterparty refusal: terminal rejected, no receipt
withdrawn offer: later acceptance refused
unauthorized holder disposition: noUseRight, no mutation
destination capacity: destinationFull, no mutation
concurrent double-spend: second reservation refused
external custody change: current fingerprint wins; accepted history is stale
true mid-exchange mutation: reached
rollback: exact
immediate retry: PASS
```

Campaign accounting is exact:

```text
physicalLoss=0
physicalDuplication=0
syntheticMaterial=0
duplicateExchangeReceipts=0
duplicateReservations=0
observerMutationCount=0
```

## Restart, downstream use, replay and Observer

CIV-35 advances the shared checkpoint and replay schema from 31 to 32 and
Observer schema from 8 to 9. Schema 32 persists bounded barter state only when
all offers are terminal, validates round-trip integrity, refuses corrupt
state, and retains the one completed exchange and both current rights records.
Legacy schemas remain supported under their existing compatibility policies.

The first process saves `barter-v32` with digest
`aa1b7804f60a04f6fa820db8eadbb2a9bca6e30b2aa704b26a9ffb71632f3650`.
A fresh process acquires the checkpoint-bound physical boundary, restores two
protected stacks with total quantity three and reports `custodyDuplicates=0`.
No `barter completed` event occurs in the continuation process.

Agent_1 then uses the exact exchanged CIV-34 pickaxe in the existing physical
block-break path:

```text
same item: stone_pickaxe
durability: damage 0 -> 1
World: stone -> air
downstream use: PASS
```

The use cites both original production provenance and completed barter. Its
existing CIV-26 `useAttempt` transition reconciles the evolved damage-1
identity before the final schema-32 checkpoint, whose digest is
`350209fd19b1853627e7538e38b884f7dbc119642bd71a137e7b8bb013052e3d`.

Observer schema 9 exposes bounded offeror/counterparty identities, exact
goods and quantities, local reasons, offer decisions, completion receipts,
post-exchange holders and rights. Snapshot construction is read-only.

## Verification

Focused CIV-35 validation passed:

```text
22 passed, 0 failed
```

The complete smoke suite and canonical repository gate passed:

```text
3830 passed, 0 failed
35/35 repository steps
checkpoint schema: 32
Observer schema: 9
golden regeneration: not attempted
```

The rendered seed-46 live campaign passed in two Pebble processes. Phase 1
contains one expected injected runtime error and phase 2 contains zero runtime
errors. Six native-resolution captures were inspected: pre-exchange, open
offer, post-exchange, fresh restore, produced-tool use and final cleanup. The
isolated evidence is retained under
`/var/folders/23/t4l5dv055dl3x1zqylcpl9wc0000gn/T/PebbleLab-live.05BFyO`.
The disposable workshop and target cells were restored while exchanged goods
remained in their verified custody.

## Explicit non-claims

CIV-35 does not prove debt, future promises, durable contracts, credit,
markets, market price discovery, currency, accounting, merchant
organizations, large-scale trade or global logistics. It also does not add
loans, interest, default, contract enforcement, order books, matching engines,
market stalls as economic authority, supply/demand curves, taxation, wages,
firms, shops, guilds or trade law. Those semantics remain outside CIV-35;
CIV-36, CIV-37 and CIV-38 are not started by this work.

## Local candidate program state

```text
CIV-34: COMPLETE AND PUBLISHED
CIV-35: IMPLEMENTED_LOCAL_REVIEW_CANDIDATE
CIV-36: NOT_STARTED
Gate D: ACQUIRED AND PUBLISHED
next: SENIOR REVIEW OF CIV-35
push: NOT_ATTEMPTED
```
