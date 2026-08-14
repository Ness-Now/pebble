# CIV-36 — Debt, Promises and Durable Contracts V1

## Verdict

`CIV-36` is **IMPLEMENTED_LOCAL_REVIEW_CANDIDATE** in its bounded V1
contract. It was implemented directly from the exact published canonical
baseline:

```text
e47c2d1a4132dc756219ef0d2c1495b2769b8d35
```

Local product and proof commit:

```text
a910f938c0e943e37aa851c0f65dfecdb06698cc
```

This verdict is deliberately not a publication claim. CIV-35 remains complete
and published, CIV-37 remains not started, Gate E remains planned, and the next
authorized action is senior review of this CIV-36 candidate.

## Reuse-first architecture

PebbleCore remains the authority for exact item identity, inventory custody,
capacity, crafting and World mutation. No second production, inventory,
transfer or contract-fulfillment engine was added. Pebble reuses
`PebbleAgentMaterialCustodyGateway`, the CIV-34 production gateway and
`PebbleCandidatePhysicalTransaction` to prevalidate, mutate, verify and
compensate exact physical changes. CIV-26 Material Rights publishes social
custody and ownership consequences only after physical verification.

The sole `AgentSimulationSession` owns deterministic contract cognition and
durable civilization state:

```text
bounded local opportunity
→ explicit future promise proposal
→ distinct promisee acceptance or rejection
→ durable accepted obligation awaiting consideration
→ verified current consideration transfer
→ outstanding debt + debtor production need
→ normal CIV-34 production
→ verified exact performance transfer
→ fulfilled once
```

A promise is semantic future performance. It never asserts that promised
matter already exists. Replay reconstructs the social history and receipts but
never executes World mutations. Observer derives a read-only projection.

## Promise and acceptance semantics

V1 deliberately supports one narrow promise language: one complete future
delivery of one exact material identity and positive quantity. Terms bind a
named promisor, named promisee, current exact consideration asset, active local
reasons, proposal lifetime and deterministic due tick.

Proposal moves no matter and creates no obligation or debt. Only the named,
distinct promisee may accept. Rejection, expiration and pre-acceptance
withdrawal are terminal. After acceptance the promisor cannot withdraw
unilaterally. Acceptance creates a durable obligation in
`awaitingConsideration`; it does not by itself open debt or move custody.

The same two participants and causal need pair cannot immediately regenerate
as a reverse-direction promise after goods change hands. This deduplication is
owned by deterministic cognition and is covered by focused and live proof.

## Consideration, debt and due boundaries

Consideration must be a current exact CIV-26 rights-tracked asset held by the
promisee. Pebble revalidates current holder authority, exact material identity,
quantity and custody fingerprint, then executes one physical transfer. Only a
verified physical outcome publishes the rights transition and changes the
obligation to `outstanding`.

Opening debt raises one exact CIV-34 production need for the debtor. It does
not create the promised material. The normal production path later consumes
three real wheat and produces one real bread, with its existing recipe,
workshop, custody and causal receipt authority.

An outstanding obligation that passes its due tick becomes `overdue`. V1
retains the debt and exposes the state; it imposes no punishment, interest,
seizure or general enforcement. Participant death changes an active obligation
to `blockedParticipantDeath`; V1 defines no contract inheritance.

## Physical fulfillment and exactly-once publication

Fulfillment requires the complete promised identity and quantity in current
debtor custody. Missing goods, wrong identity, wrong quantity, stale custody,
unauthorized disposition and duplicate operation authority fail closed. A
partial delivery cannot reduce or close an obligation.

Pebble first prevalidates current CIV-26 authority and exact physical transfer,
then mutates and verifies the real inventory. The session publishes
`fulfilled` only after that verification. The obligation retains its exact
physical receipt and production provenance. Status plus bounded processed
operation retention prevents repeat fulfillment and double spending.

The decisive campaign injects a true fault after the real bread transfer but
before social closure. The candidate transaction compensates the transfer,
abandons candidate receipts, and leaves the published session and recorder
unchanged with the debt still outstanding. The next same-process tick retries
through normal arbitration and fulfills once.

Campaign accounting is exact:

```text
physicalLoss=0
physicalDuplication=0
syntheticMaterial=0
duplicateFulfillmentReceipts=0
duplicateReservations=0
observerMutationCount=0
proofFixtureDecisionAuthority=0
manualProductiveContractCommandsAfterBootstrap=0
```

## Durability, replay, bounds and corruption defense

Checkpoint schema 33 persists open proposals, accepted obligations, open debt,
fulfilled outcomes, exact receipts, production provenance, processed operation
authority and CIV-26 rights. An open debt is checkpoint-safe because no
physical mutation is in flight. Loading the checkpoint restores the same open
obligation; load never fulfills it or creates promised goods.

Replay schema 33 records typed opportunity, proposal, decision, consideration
and fulfillment operations. It reproduces deterministic civilization state
without executing physical fulfillment. Corrupt checkpoint bytes, invalid
status/evidence combinations, duplicate reservations, missing active proposal
authority and incoherent material outcomes are refused.

Production defaults retain at most 32 opportunity projections, 32 proposal
projections, 64 obligations and 512 processed contract operations. Capacity
reclamation is deterministic and terminal-only. Open proposals and active
`awaitingConsideration`, `outstanding` or `overdue` obligations are never
evicted. A five-contract focused churn campaign against a two-obligation and
two-proposal cap remains productive, preserves active authority and restores
byte-exactly after compaction.

Observer schema 10 exposes bounded proposals, exact terms, obligation status,
due tick, consideration and fulfillment receipts, participant identities and
current rights without mutating durable state.

## Three-process live proof

The seed-46 disposable campaign uses three fresh Pebble processes.

Process 1:

```text
agent_1 explicitly proposes future bread x1
agent_0 distinctly accepts
agent_0 physically transfers stone_pickaxe x1 consideration
obligation becomes outstanding
schema-33 checkpoint contract-open-v33 saved at tick 2
digest 2828bf4d5eacbfd1f57828d7c8214334038a4f4d18d4b3b1ac5c5e3d7a0a5198
```

Process 2:

```text
open debt restores with exact custody and zero duplicates
normal CIV-34 path: wheat x3 → bread x1
post-transfer fulfillment fault reaches real mutation
rollback restores bread to agent_1 and keeps debt outstanding
immediate normal retry transfers bread to agent_0 and fulfills once
schema-33 checkpoint contract-fulfilled-v33 saved at tick 4
digest 4519b71f30400b239bbc31b78b074704a3178c92046727e3f9e17d580ffeb717
```

Process 3:

```text
fulfilled checkpoint restores with exact custody and zero duplicates
normal tick creates no reverse proposal or duplicate fulfillment
contract proof PASS, active=0, debts=0, fulfilled=1
schema-33 checkpoint contract-final-v33 saved at tick 5
digest 3a505618634d4a3e2d66955cd90cb85568d3cd05d9a2e2a30f4776a03befccad
cleanup cells=exact, fulfilled custody retained
```

All nine native captures were inspected. Proposal, open debt, restored open
debt, normal production, rollback, fulfillment, fulfilled restore and final
cleanup are visually coherent with the structured trace. Retained evidence:

```text
/var/folders/23/t4l5dv055dl3x1zqylcpl9wc0000gn/T/PebbleLab-live.IqtoNt
```

## Validation

Focused CIV-36 validation:

```text
24 passed, 0 failed
```

Canonical repository validation:

```text
3886 passed, 0 failed
35/35 repository steps
checkpoint schema: 33
replay schema: 33
Observer schema: 10
golden regeneration: not attempted
```

The official live launcher result is:

```text
PASS: CIV-36 open debt, normal production, exact rollback/retry,
three-process durability, exact-once fulfillment, and cleanup verified.
```

## Explicit non-claims

CIV-36 does not claim markets, price discovery, currency, interest, banking,
bankruptcy, general legal enforcement, courts, contract inheritance, merchant
organizations, taxation or large-scale finance. It also adds no loans,
collateral, divisible claims, wages, firms, order books, general settlement,
public treasury or global logistics. Physical markets and local price
discovery remain CIV-37 work.

## Local program state

```text
CIV-35: COMPLETE AND PUBLISHED
CIV-36: IMPLEMENTED_LOCAL_REVIEW_CANDIDATE
CIV-37: NOT_STARTED
Gate E: PLANNED — NOT ACQUIRED
completed published through: CIV-35
next: SENIOR REVIEW OF CIV-36
push: NOT_ATTEMPTED
```
