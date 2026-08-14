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

Reviewed pre-correction candidate HEAD and Senior Review Correction 01
product/proof commit:

```text
reviewed pre-correction HEAD: 4c7af994fc52974f6f919765af682b209f6b84ca
Correction 01: 76adcba62ac901b01618bea58fba32e1d5dc0d02
```

This verdict is deliberately not a publication claim. CIV-35 remains complete
and published, CIV-37 remains not started, Gate E remains planned, and the next
authorized action is senior review of this CIV-36 candidate.

## Senior Review Correction 01

Senior review found and this candidate discloses two defects in the first
reviewed candidate:

```text
CIV-36 Senior Review Correction 01A:
the first candidate did not guarantee that every ordinary post-physical
publication failure escaped the autonomous blocked path and therefore could
bypass candidate rollback

CIV-36 Senior Review Correction 01B:
the first candidate reacquired asset-scoped physical authority but discarded
its current custody fingerprint in favor of the historical full-custody
fingerprint
```

Correction 01A now prospectively executes the complete fallible contract
publication against copied candidate state before World mutation. Predictable
capacity, causal, rights and contract-state refusal therefore moves no matter.
After a verified transfer, any error before complete publication is classified
by the candidate transaction's newly registered physical compensation, escapes
the autonomous blocked path, fails the enclosing candidate and executes exact
compensation. Correctness does not depend on a special injected error type.

Correction 01B retains the historical proposal observation as durable semantic
evidence only. At both consideration and fulfillment it reacquires the exact
current asset, validates unambiguous holder, identity, quantity and CIV-26
disposition, then uses the returned `currentCustodyFingerprint` as the
immediate gateway transfer precondition. Unrelated co-mingled slot drift no
longer creates false stale-source refusal, while drift of the tracked asset
still fails closed.

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
promisee. Pebble reacquires current asset-scoped authority, revalidates the
unambiguous holder, exact material identity, quantity and rights disposition,
and uses the returned current full-custody fingerprint immediately for one
physical transfer. Historical proposal observation is not current physical
authority. Only a verified physical outcome publishes the rights transition
and changes the obligation to `outstanding`.

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

Pebble first reacquires current asset-scoped authority and prevalidates the
complete prospective publication, then mutates and verifies the real
inventory. The session publishes `fulfilled` only after that verification.
Any post-transfer publication error fails the enclosing candidate and invokes
its registered compensation. The obligation retains its exact physical receipt
and production provenance. Status plus bounded processed operation retention
prevents repeat fulfillment and double spending.

The decisive campaign injects both the retained explicit fault and an ordinary
publication rejection after real transfers but before social closure. Each
candidate transaction compensates the transfer, abandons candidate receipts,
and leaves the published session and recorder unchanged with the debt still
outstanding. The next same-process tick retries through normal arbitration and
fulfills once. An independent ordinary consideration publication rejection
proves the same general policy on the first physical leg.

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

## Four-process live proof

The seed-46 disposable campaign uses four fresh Pebble processes. The first is
an isolated predictable-capacity refusal; the remaining three prove open-debt
and fulfilled restart continuity.

Process 1:

```text
legitimate production-need capacity is saturated
consideration publication prevalidation refuses
physicalMutation=0, candidateCompensationDelta=0
runtimeErrors=0
```

Process 2:

```text
agent_1 explicitly proposes future bread x1
agent_0 distinctly accepts
unrelated consideration slot drift preserves exact scoped authority
ordinary consideration publication rejection reaches real transfer
candidate rollback restores exact custody and unchanged publication
same-process retry transfers stone_pickaxe x1 and opens debt
obligation becomes outstanding
schema-33 checkpoint contract-open-v33 saved at tick 2
digest 94bfdfaacbde2cc0eb91605791e61c9ad2dab5a4d207a54ec257979cc7c765ec
runtimeErrors=1 (expected ordinary consideration rejection)
```

Process 3:

```text
open debt restores with exact custody and zero duplicates
normal CIV-34 path: wheat x3 → bread x1
unrelated fulfillment slot drift preserves exact scoped authority
explicit post-transfer fault reaches real mutation and rolls back exactly
ordinary fulfillment publication rejection independently reaches real mutation
second rollback restores bread and keeps debt outstanding
immediate normal retry transfers bread to agent_0 and fulfills once
schema-33 checkpoint contract-fulfilled-v33 saved at tick 4
digest ce93e8bc398b08220bdc2c18f366d7b61bad6fcb57be1b0e9f4dc8cb1f63cb5c
runtimeErrors=2 (expected explicit and ordinary fulfillment rejections)
```

Process 4:

```text
fulfilled checkpoint restores with exact custody and zero duplicates
normal tick creates no reverse proposal or duplicate fulfillment
contract proof PASS, active=0, debts=0, fulfilled=1
schema-33 checkpoint contract-final-v33 saved at tick 5
digest 5490a019e119111f17014ee2883bd2253a5957ecf23683a19f1ccb9818774d87
cleanup cells=exact, fulfilled custody retained
runtimeErrors=0
```

All twelve native captures were inspected. Capacity refusal, proposal, both
consideration and fulfillment publication rollbacks, open debt, restored open
debt, normal production, explicit rollback, fulfillment, fulfilled restore and
final cleanup are visually coherent with the structured trace. Retained
evidence:

```text
/var/folders/23/t4l5dv055dl3x1zqylcpl9wc0000gn/T/PebbleLab-live.enxSfL
```

## Validation

Focused CIV-36 validation:

```text
30 passed, 0 failed
```

Canonical repository validation:

```text
3892 passed, 0 failed
35/35 repository steps
checkpoint schema: 33
replay schema: 33
Observer schema: 10
golden regeneration: not attempted
```

The official live launcher result is:

```text
PASS: CIV-36 predictable prevalidation, current asset authority, ordinary and
explicit post-transfer rollback/retry, four-process durability, exact-once
fulfillment, and cleanup verified.
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
