# CIV-34 — Production, Tools and Workshops V1

## Verdict and baseline

`CIV-34` is complete and published in its bounded contract. It was implemented
from the exact published canonical baseline:

```text
1bbf3df08ca8a05c79af61c888c424e52bb30801
```

Senior review approved the exact implementation and evidence identities:

```text
published product implementation: 73db4cd7fbf1aff86a23aacb8928ca460774696e
senior-review candidate/evidence HEAD: 24f0f72aae7543177ca746e892c57482496dabef
review bundle SHA-256: 8a00bfef38c7d93dae0eff6867d58bc4d05bc872fb72b00f83616367dd682b6d
internal bundle checksums: 34/34 PASS
senior review: APPROVED
```

This report intentionally does not self-reference its containing publication
commit. Gate R, Gate B, Gate C and Gate D remain acquired and published.
`CIV-35` is not started and is the next eligible phase and authorized action.

## Reuse-first architecture

The implementation adds no parallel recipe, inventory, tool, block-break,
World-persistence, physical-custody or cognitive engine.

- PebbleCore remains the physical authority. A canonical crafting preview
  resolves the registered recipe set, delegates shaped/tag matching to the
  existing crafting implementation, consumes the exact real input slots and
  applies the existing inventory insertion and container-return rules.
- Pebble is the only live World boundary. Its bounded production sensor reads
  the real crafting table and actor inventory. Its gateway prevalidates an
  exact source fingerprint, performs the canonical inventory transformation,
  verifies the physical result and registers a reverse-order compensation in
  the existing candidate transaction.
- PebbleAgents retains only deterministic needs, observations, opportunities,
  verified outcomes, product provenance and subsequent-use history in the
  sole `AgentSimulationSession`. It imports no PebbleCore or World authority.
- Normal autonomous arbitration selects the production domain. The rendered
  proof does not call a proof-only success operation; `/lab step` selects and
  completes both products through the normal civilization activity path.
- Crafting practice is credited only after the corresponding verified
  physical production receipt. No intent, observation, refusal or rollback
  grants practice or material output.

The durable distinctions remain explicit:

```text
physical item stack
!= production record
!= recipe identity
!= workshop observation
!= social need
!= opportunity
!= skill credit
!= Material Rights claim
```

## Bounded production contract

Production V1 is explicitly gated, deterministically ordered and bounded by
configuration. One active need identifies the required canonical output and
reason. One current opportunity binds that need to an observed physical actor,
workshop, recipe, exact input slots and source fingerprint. A successful
outcome must repeat the operation identity and physical result exactly before
the session can publish a production record.

The live proof exercises two existing canonical crafting recipes:

```text
actor: agent_2
workshop: crafting_table@16,70,-17
3 cobblestone + 2 sticks at crafting_table -> 1 stone_pickaxe
3 wheat at crafting_table                 -> 1 bread
normal autonomous product path: PASS
manual productive trigger: 0
second production variation: PASS
```

The crafting table is the real registered `crafting_table` block at
`16,70,-17` in the disposable World. The focused actor is `agent_2`. Before
production its protected physical input custody is three cobblestone, two
sticks and three wheat. After both recipes those eight inputs are absent and
the same real custody contains exactly one stone pickaxe and one bread. The
checkpoint records two protected stacks with total quantity two; there is no
coarse inventory credit or reconstructed social material.

Missing input, wrong quantity, wrong material identity, a missing or changed
workshop, an externally changed source fingerprint, ambiguous reserved input
and a concurrent claim all fail closed before publication. Stable operation
identities prevent one observed source from being spent or credited twice.

## Atomicity, rollback and rights

The live gateway copies the precise actor inventory and verifies the source
again immediately before mutation. A successful mutation must produce the
canonical post-inventory and output identity. Publication occurs only after
that physical verification.

The adversarial live campaign reaches a fault after the real inventory
mutation. Candidate compensation restores the exact prior inventory and
workshop state, the session and recorder remain byte-identical, and an
immediate retry succeeds without restart. The proof reports:

```text
lateMutationReached=1
rollback=exact
immediateRetry=PASS
physicalLoss=0
physicalDuplication=0
syntheticMaterial=0
duplicateProductionReceipts=0
duplicateReservations=0
observerMutationCount=0
```

Material Rights remains subordinate to physical truth. Any matching input
stack protected by another durable right is conservatively refused, and an
ambiguous same-holder match is never guessed. Production does not assign
ownership, workshop title or a new claim merely because an actor manufactures
an item.

## Tools and downstream physical use

The first output is the existing canonical `stone_pickaxe`, including its real
durability fields and the ordinary PebbleCore tool requirement. After a fresh
process restart the exact produced item breaks a real reachable `stone` block
through the existing actor-neutral block-break executor. The proof observes:

```text
item identity: stone_pickaxe -> stone_pickaxe
damage: 0 -> 1
World cell: stone -> air
canonical drop custody acquired: cobblestone x1
wrong tool attempt: FAIL_CLOSED
```

The use event cites the original production receipt and preserves the same
durable produced-good identity while allowing canonical current-item
evolution. The final checkpoint therefore protects three stacks with total
quantity three: damaged pickaxe, bread and acquired cobblestone.

## Restart, replay, Observer and causality

Production advances the shared checkpoint and replay schema from 30 to 31 and
Observer schema from 7 to 8. The schema-31 checkpoint retains needs,
opportunities, exact recipe/workshop/input/output facts, production receipts,
subsequent-use records and crafting practice. Replay uses typed production
operations and verifies exact continuation; it does not recreate World matter.

The rendered campaign terminates the first Pebble process, handing off the two
protected real stacks as exact World escrow. A fresh process loads the same
World and checkpoint, repositions the actor to the checkpoint boundary,
adopts exactly two physical spills and restores the same digest:

```text
checkpoint digest: f40d2c18a699190afef96f48beb423044e30bf56556eb6f4ab75c5fa472bd1b7
custodyRestoredStacks=2
custodyRestoredQuantity=2
custodyDuplicates=0
physicalBoundary=acquired
freshRestore=exact
```

No published production repeats after restart. The produced-good use adds one
causal event linked to the original `productionCompleted` event. Observer
projects the bounded structured production state without ticking, mutating,
appending causality or changing custody; `observerMutationCount` is zero.

## Verification

Focused production validation passed `36 passed, 0 failed`: 12 PebbleCore
canonical-crafting checks and 24 PebbleAgents production, autonomous,
checkpoint, replay and Observer checks.

The canonical repository gate passed all 35 phases with:

```text
3808 passed, 0 failed
checkpoint schema: 31
Observer schema: 8
golden regeneration: not attempted
```

The two-process disposable-world campaign passed with seed 46, zero runtime
errors, six inspected native-resolution captures and exact cleanup of the
workshop and downstream target. Cognition and protected output custody remain
intentionally retained after fixture cleanup.

## Explicit non-claims

`CIV-34` does not prove barter, markets, prices, currency, debt, general
contracts, guilds, large-scale industry, technology trees, a full logistics
economy, land/workshop property law or general organizations. It does not add
machine timing or fuel because the two V1 products use the existing immediate
crafting-table authority; any future furnace or machine production must reuse
the real Core timing, fuel and block-entity rules. It does not claim workshop
ownership, production multipliers, automated logistics, omniscient material
search, arbitrary recipes or an unbounded industrial economy.
`CIV-35` owns barter and local exchange; CIV-34 does not start or implement
that phase.

## Canonical program state

```text
CIV-34: COMPLETE AND PUBLISHED
Gate D: ACQUIRED AND PUBLISHED
CIV-35: NOT_STARTED — NEXT ELIGIBLE PHASE
active CIV phase: none
completed through: CIV-34
next eligible phase: CIV-35
next authorized action: CIV-35
```
