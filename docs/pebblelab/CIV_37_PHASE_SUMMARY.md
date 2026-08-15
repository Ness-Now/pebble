# CIV-37 — Physical Markets and Local Price Discovery V1

## Verdict

`CIV-37` is **IMPLEMENTED_LOCAL_REVIEW_CANDIDATE** in its bounded V1
contract. It is not published and has not been senior-review approved. The
exact starting baseline was:

```text
9f13ffee3f312caaaa68ddd6f2c2c27e5942474e
```

Product and proof commit:

```text
e279362e1d5b71ed82d20e2f17e492fa22579c37
```

Senior Review Correction 01:

```text
previous reviewed HEAD: f96f84a61b72e115de668966f470feef986de925
correction product/proof commit: 21ed1b550f9c54381e54c3c763d2ff494bda7d57
```

Correction 01A records that current seller/buyer market locality was not
revalidated at the decisive decision/settlement boundary, permitting
historical locality to authorize a potential remote physical settlement.
Correction 01B records that normal seller decision was unconditional
`accept=true`, and a completed trade could mark a quantity-bearing seller
need fulfilled despite receiving less than that need's quantity. The
correction requires fresh World evidence at seller decision and immediately
before settlement, replaces fixture-shaped acceptance with deterministic
term-aware seller cognition, and leaves an underfilled quantity-bearing need
active.

Canonical status after this candidate is:

```text
CIV-36: COMPLETE AND PUBLISHED
CIV-37: IMPLEMENTED_LOCAL_REVIEW_CANDIDATE
Gate E: PLANNED — NOT ACQUIRED
CIV-38: OPTIONAL — NOT STARTED
next: SENIOR REVIEW OF CIV-37
```

## Bounded result

The candidate implements one deterministic, local, physical market system:

```text
current local observation
→ verified physical deposit into a market container
→ listing of that exact deposited lot
→ explicit buyer terms
→ distinct seller decision and exact reservation
→ verified two-leg physical settlement
→ reconciled rights and completed local price observation
```

Depositing a good changes its verified holder to the market container but does
not make the market its owner. Listing and negotiation move no matter.
Cancellation or expiry releases the logical reservation but does not teleport
the good. An unsold lot returns only through a verified physical withdrawal.

The price model has no money or floating-point authority. Every observation
preserves explicit `baseItemKey`, `quoteItemKey`, `baseQuantity` and
`quoteQuantity`. The decisive first listing asks for one stone pickaxe against
three bread. The buyer first offers one bread, which normal seller cognition
rejects as economically insufficient, then independently offers two bread,
which the seller accepts under the same generic evaluation seam. Only the
completed physical trade creates the corresponding local price row.

## Reuse-first authority

PebbleCore remains the sole authority for World blocks, the market chest,
exact item stacks, inventory slots, capacity and physical mutation. No second
inventory, transfer, crafting, market-container or World-persistence engine was
added.

Pebble owns observation and execution. It reuses the existing material-custody
gateway and `PebbleCandidatePhysicalTransaction` to acquire current
asset-scoped authority, prevalidate endpoints, move the real stacks, verify
the result, register compensation and publish only after verification. A
market trade uses three physical endpoints:

```text
market container → buyer inventory
buyer inventory → seller inventory
verified final market-container state
```

CIV-26 Material Rights constrains who may deposit, sell, pay, receive and
withdraw. It records social holder, custodian and ownership consequences only
after physical verification; it never creates matter.

The sole `AgentSimulationSession` owns deterministic market cognition,
listing/reservation state, completed trade records and local price provenance.
`PebbleAgents` never reads or mutates a live World. Replay uses the same pure
transitions but never executes physical work. Observer derives a read-only
projection.

## Physical place, locality and capacity

A market record binds one stable market identity to one World position, one
container location, one container block fingerprint, one interaction radius
and one physical slot capacity. The rendered campaign establishes a real
nine-slot chest at `18,69,-21`.

Normal product discovery is bounded to current locally visible agents, their
current rights-tracked physical goods and active material reasons. It performs
no global inventory scan. Deposit observations and buyer observations carry a
current distance, chunk readiness and observation tick. Non-local deposit
discovery and a non-local buyer proposal both fail atomically without durable
mutation.

Proposal distance is historical social evidence, never execution authority.
Before seller decision and again immediately before settlement, Pebble rebuilds
same-tick evidence from the current live World embodiment of both participants,
the current market position and container, both relevant chunks and current
alive state. Both current Manhattan distances must be within the market's
interaction radius. Failure moves no matter and publishes no trade or price
row. An accepted reservation remains retryable only until its existing bounded
listing expiry; returning before expiry permits one coherent retry.

Physical and logical capacity remain distinct:

```text
full physical container → deposit cannot start
full logical registry → deterministic bounded refusal or terminal reclamation
```

The live setup fills the real chest and observes `destinationFull` with no
market deposit or rights mutation, then restores the fixture before the
decisive path. Focused validation separately refuses an observation whose
occupied physical slots equal capacity, byte-for-byte without mutation.

If the container is absent, changed or stale, current gateway acquisition
fails and the market has no physical authority. The implementation does not
preserve imaginary custody or teleport a deposited lot.

## Deposit, ownership, listing and withdrawal

A deposit proposal references one exact `AgentMaterialAssetID`, material
identity, quantity, seller, current seller-held observation and physical
market endpoint. Pebble moves that stack into the real container and returns a
physical receipt. Only then does the session record deposited custody.

The campaign's first deposit is:

```text
deposit: deposit-2eaeb2a12c4b1fa4
asset: stone_pickaxe x1
holder after deposit: container:18,69,-21
owner after deposit: agent_0
receipt: market:deposit:deposit-2eaeb2a12c4b1fa4:physical
```

A listing references the deposited lot and its current material reason. V1
treats the verified local deposit as the seller's prior authorization for one
exact deterministic automatic listing; listing publication is not a later
remote seller action. Only the exact proposal recomputed from that deposit,
its still-current reason and same-market history may be published. It cannot
manufacture or substitute a good. Only one live listing/reservation chain may
control the lot. Buyer consideration is another exact current asset;
concurrent reservation or reuse of either side fails closed.

Expiry changes only listing authority and releases its reservation. The
campaign's unsold `oak_log x1` remains physically in the chest after expiry,
then returns to agent_2 through receipt
`market:withdraw:deposit-5fe33fa71515a352:physical`. Withdrawal revalidates
the market, seller, owner, exact current lot and destination capacity. A stale,
missing, changed, unauthorized or reserved lot cannot be withdrawn.

## Local price discovery and causality

Initial terms come from one seller's current material need. A current local
buyer independently proposes terms from its own current need. The named seller
then evaluates the requested item and quantity, initial and current listing
terms, its current quantity-bearing reason, current local evidence and
same-market price evidence. The generic deterministic seam rejects the
one-bread counteroffer and accepts the later two-bread counteroffer; no caller
supplies acceptance authority. The disposable proof injects no
decisive opportunity, listing decision, buyer decision or seller decision
after bootstrap:

```text
marketProofFixtureDecisionAuthority=0
manualProductiveMarketCommandsAfterBootstrap=0
normalMarketDiscovery=1
normalDepositDecision=1
normalListingDecision=1
normalBuyerDecision=1
sellerDecisionAuthority=normal-cognition
sellerUnconditionalAccept=0
normalSellerRejections=1
normalSellerAcceptances=1
```

Rejected terms, open proposals, accepted reservations, failed physical
attempts, rollbacks, expiry and withdrawal create no completed price row. A
price row is appended in the same verified session publication as a completed
trade and cites that trade's market, explicit oriented terms, completion tick,
two physical receipts and causal event.

Later listing cognition consults only completed rows with the same market ID,
base good and quote good. After fresh restart, agent_2's comparable stone
pickaxe seller reason independently requests three bread, while restored
same-market history selects two bread. The differing control values prove that
history causally changes the later terms rather than merely matching the
reason; a second physical trade completes on those terms. A focused two-market test
proves that this history neither appears automatically at a different market
nor passes validation when forged into a foreign-market listing.

Price-history compaction is bounded and causal. Evicting a completed trade
also removes its dependent price row; no irreversible global aggregate or
oracle survives without actual trade provenance.

## Physical settlement, rollback and retry

Before settlement, the session revalidates the accepted proposal, exact
listing/deposit reservation, participants, current reasons, explicit terms and
CIV-26 disposition. Before any gateway acquisition or transfer, Pebble also
rebuilds and validates current World locality for the market, seller and buyer.
The live adversarial path moves the accepted buyer's real probe to distance 13:
the attempted settlement reports zero physical mutations, trades and price
rows, then an exact locality restore permits retry. Pebble reacquires both
exact physical assets at execution;
historical whole-inventory fingerprints are not authority. Unrelated slot
drift is tolerated when each tracked asset still matches. Drift of either
tracked holder, identity or quantity fails closed.

All fallible civilization publication is prospectively validated before World
mutation. The rendered campaign then proves both important post-mutation
boundaries:

```text
fault 1: after market-to-buyer mutation
registered compensation count: 1
candidate rollback: EXACT
published session: unchanged
published recorder: unchanged
price rows: 0

fault 2: ordinary failure after both physical mutations
registered compensation count: 2
candidate rollback: EXACT, reverse order
published session: unchanged
published recorder: unchanged
price rows: 0
```

Both errors escape autonomous blocked handling and fail the enclosing
candidate. The next same-process normal tick reacquires current authority and
completes trade `trade-7e86c0771465f13f` exactly once. The later comparable
trade is `trade-e9e26594772c67f7`.

Focused validation also supplies an externally changed deposited-source
observation with the wrong quantity and fingerprint. Settlement refuses it
without changing durable bytes or price history. This is deterministic
product-equivalent authority validation; the rendered rollback campaign is
the authoritative proof of real World mutation and compensation.

## Rights, participant death and conservation

On completion, the offered asset is physically held and socially owned by the
buyer, while the consideration asset is physically held and socially owned by
the seller. The received claims cite the completed market trade. The deposited
lot cannot be sold again, and duplicate completion cannot append another
receipt, rights transition or price row.

Quantity-bearing motives close only after a verified receipt satisfies the
requested item and quantity. V1 does not invent partial-need accounting: the
seller requests three bread and physically receives two, so that need remains
`active`. The buyer requests one stone pickaxe and receives one, so the buyer
need becomes `fulfilled`. Underfilled receipt is advancement, not fulfillment.

Participant death creates no market inheritance. Normal market activity
requires a current active agent state, current material reason, local evidence,
current rights and current physical custody. If a seller or buyer is no longer
active during a settlement, those checks fail closed. No listing is
automatically transferred to an heir. Any unresolved physical custody remains
subordinate to the existing mortality, estate and Material Rights authorities;
the market layer does not invent a successor or move matter.

The final live accounting is:

```text
physicalLoss=0
physicalDuplication=0
syntheticTradeMaterial=0
duplicateReservations=0
duplicateDeposits=0
duplicateMarketTradeReceipts=0
observerMutationCount=0
```

The proof fixture seeds four ordinary, physically real, rights-tracked goods:
two stone pickaxes, two bread and one oak log. It does not claim those fixture
goods were actually produced through the CIV-34 production path. The market
contract applies equally to ordinary rights-tracked goods and does not require
invented production provenance.

## Persistence, replay, Observer and corruption policy

Checkpoint schema 34 is the first market schema. It persists registered
markets, deposit opportunities, current deposits, listings, proposals,
completed trade records, local price rows, withdrawals, exact receipts,
processed operation authority and counters. The World-side manifest remains
the authority for physical probe/custody continuity. A checkpoint is refused
while an unverifiable physical mutation is in flight.

The live campaign preserves three states across actual process boundaries:

```text
market-open-v34
tick: 3
digest: f94c547b7066d3e7bd9fc6f3ad9b56bcff91d843ff8899d5ada852c8454c59e4

market-traded-v34
tick: 6
digest: b13051996e88e9d482da497fbcea97126708d9b27df8d8caec9f2f55dcaa6ddf

market-final-v34
tick: 22
digest: 205236a985dca926d3fab118e02716dd4f8197180a23579ddf6d8f65f13314f5
```

Every fresh load first acquires exact physical position/custody and reports
`custodyDuplicates=0`. Open deposited custody and its listing survive the
first restart. Completed rights and price history survive the next restart.
The final restart reports exactly two trades, two price rows and one withdrawal;
one further tick executes none of them again.

Replay schema 34 records typed pure market transitions and verifies exact
durable continuation. Replay never mutates the World or treats historical
physical receipts as permission to repeat a transfer.

Observer schema 11 exposes bounded market place, deposit, listing, proposal,
trade, price and withdrawal provenance. A durable-byte comparison proves the
projection is read-only. Checkpoint validation refuses corrupt bytes, price
rows without matching completed trades, mismatched market/terms/causal
evidence, duplicate identities, inconsistent reservations and collection
overflow. Earlier compatible schemas remain readable with market state absent;
unknown or incoherent market state fails closed.

## Bounds and sustainable churn

Production defaults are:

```text
markets: 4
deposit opportunities: 32
deposits: 32
listings: 32
proposals: 64
completed trade records: 128
price rows: 64
withdrawals: 128
processed market operations: 512
listing lifetime: 4 ticks
maximum local distance: 8
```

Discovery additionally caps agents, physical goods per agent, discoveries per
tick and buyer observations per tick. All iteration and eviction order is
deterministic.

Compaction removes terminal authority only. A deposited or listed lot, open
listing, pending/accepted proposal and its reservations cannot be evicted to
make room. Dependent terminal listing/proposal rows compact with their terminal
deposit. Completed trade eviction removes the associated price row. A focused
campaign creates three deposits over its lifetime against two-deposit,
two-listing and two-proposal caps, then starts later activity successfully
while preserving two coherent completed price rows.

## Four-process rendered proof

The authoritative seed-46 campaign ran with:

```bash
scripts/verify-pebblelab-live.sh --markets
```

Corrected retained evidence root:

```text
/var/folders/23/t4l5dv055dl3x1zqylcpl9wc0000gn/T/PebbleLab-live.pFXJvL
```

Process 1 establishes the real chest, proves full-capacity refusal, deposits
agent_0's stone pickaxe through normal runtime, creates the initial ask and
saves `market-open-v34`. Runtime errors: 0.

Process 2 freshly restores the open listing, proves exact market custody and
seller ownership, exercises normal rejection and later acceptance, then moves
the accepted buyer's real probe outside the market. The remote attempt is
refused before mutation or publication and exact locality is restored. It then
reaches both real rollback seams, retries successfully, creates the first
price row and saves `market-traded-v34`. Runtime errors: 3, one expected
locality refusal and two expected injected post-mutation failures; unexpected
runtime errors: 0.

Process 3 freshly restores the completed trade and price history without
reexecution. Agent_2's current reason requests three bread, but restored
same-market history selects a one-pickaxe/two-bread listing and the second
trade completes. It
then deposits an oak log, lets the listing expire without movement, physically
withdraws the unsold lot and saves `market-final-v34`. Runtime errors: 0.

Process 4 freshly restores the final state with zero duplicate custody, runs
one tick without repeating a trade, deposit or withdrawal, then restores the
disposable market cell exactly while preserving completed economic custody.
Runtime errors: 0.

Thirteen native captures were individually inspected:

```text
market-established.png
market-deposited.png
market-open-listing.png
market-restored-open.png
market-remote-buyer-refusal.png
market-mid-settlement-rollback.png
market-post-mutation-rollback.png
market-completed-trade.png
market-restored-history.png
market-history-informed-trade.png
market-unsold-withdrawal.png
market-final-restored.png
market-final-cleanup.png
```

Structured traces are authoritative. The captures visibly agree with their
corresponding market/custody overlays and rollback or restart state.

## Validation

Focused validation:

```bash
PEBBLELAB_SMOKE_ONLY=markets swift run -c debug pebsmoke

31 passed, 0 failed
```

Canonical repository gate:

```bash
scripts/verify-pebblelab.sh

3923 passed, 0 failed
PASS: all 35 PebbleLab verification steps succeeded.
```

Release `Pebble`, `PebbleLab` and `pebsmoke` builds pass. Existing unrelated
renderer warnings remain warnings. Goldens were read-only and
`PEBBLE_REGOLD` was never used.

## Cleanup

The proof removes its three disposable probes through normal live teardown and
restores the temporary chest cell to the exact pre-campaign air state after
the final restart. It intentionally does not return successfully traded goods
to their original owners. Completed ownership and custody consequences remain
true through final accounting.

## Explicit non-claims

CIV-37 does not claim:

- currency;
- a unit of account;
- banking;
- general accounting;
- a credit market;
- interest;
- loans;
- securities;
- derivatives;
- market regulation;
- merchant guilds;
- taxation;
- courts;
- global markets;
- inter-settlement price transmission;
- general firms;
- an automated market maker;
- global equilibrium.

It also does not acquire Gate E. Gate E requires CIV-37 senior review and
publication followed by its own independent composition evaluation.
