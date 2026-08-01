# CIV-33 — Estates, Inheritance and Succession V1

## Verdict and baseline

`CIV-33` is complete in its bounded contract as a local review candidate. It
was implemented from the published canonical baseline:

```text
dcfbafbff92e9c0c849f7234875476d0d49a25a9
```

The product and rendered proof are separated into these reviewable commits:

```text
28b1f6f  Implement bounded mortality estates V1
e37529c  Add rendered CIV-33 restart campaign
adf6ff2  Capture published CIV-33 estate states
ffd2d29  Expose CIV-33 rights in rendered proof
b5f7e6c  Harden durable estate integrity
```

This report intentionally does not self-reference its containing documentation
commit. Gate R, Gate B and `V4-GATE-C-v1` remain acquired and published.
All required CIV phases for `V4-GATE-D-v1` are now complete, but Gate D is not
evaluated: its required
`V4-MILESTONE-RENEWABLE-SUBSISTENCE-v1` remains not started and is the next
eligible milestone. `CIV-34` is not started.

## Reused authorities

`CIV-33` extends the sole existing `AgentSimulationSession` aggregate. It adds
no second mortality, physical custody, inventory, Material Rights, family,
care, World-persistence or replay engine. PebbleCore remains authoritative for
World matter, stacks, containers and physical custody. Pebble observes and
executes the physical boundary. CIV-29 owns physiological death and verified
material exit. CIV-26 Material Rights remains the only social authority for
holder observations, custody, recognized ownership, claims and use
permissions.

The permanent distinctions include:

```text
physical holder
!= material custodian
!= recognized owner
!= claimant
!= authorized user
!= estate administrator
!= beneficiary
!= successor
!= guardian
!= union partner
!= household member
!= house member
```

An estate is a durable social settlement boundary. It is not a person, probe,
World entity, container, household, house, lineage, physical holder, invented
owner or cognitive authority.

## Explicit prospective activation and bounded state

- Estates require the causal ledger, lifecycle, kinship, households,
  Childhood V2, Family V1, Material Rights and mortality configured to require
  terminal physical-custody verification.
- Activation is explicit and records its tick plus the canonical mortality
  count at activation. Historical deaths are not assigned reconstructed
  estates.
- Every newly finalized death after activation must correspond to exactly one
  estate. Disabling the authority after durable activation is refused.
- Stable estate and asset-entry identities derive from canonical simulation,
  death and asset identities; neither wall-clock time nor dictionary order is
  an input.
- The live configuration bounds retained estates to 32, open estates to 32,
  assets per estate to 16, obligations per estate to 16, beneficiaries per
  estate to 32, administration periods per estate to 16, settlement attempts
  per asset to 16, processed operations to 512 and transitions per tick to
  128.
- Mortality and estate retention are coordinated. An open, administered,
  partially settled, blocked or dormant estate pins its matching death record.
  Only the exact oldest terminal estate/death pair may compact atomically, and
  a new death is refused without partial publication when no coherent pair is
  evictable.

The durable statuses are:

```text
openUnadministered
openAdministered
partiallySettled
blocked
settled
dormantNoSuccessor
```

A single canonical recomputation derives operational status from terminal
assets, absence of successors, mixed terminal/nonterminal assets, blocked
assets, pending assets and an active administrator, in that precedence. A
settled estate cannot reopen; administrator death, incapacity or absence
cannot erase `blocked`, `partiallySettled` or `dormantNoSuccessor` truth.
Duplicate operation IDs, counter corruption, capacity overflow and
contradictory terminal state fail closed.

## Atomic mortality opening

Estate opening is part of the existing candidate mortality transaction. Its
causal and physical order is:

```text
terminal physiology
→ pending mortality transition
→ live probe and carried-matter inspection
→ verified empty probe or exact transfer to a safe container
→ mortality material-exit receipt
→ rights and obligation classification
→ estate opening and successor plan
→ personal commitment termination
→ population/lifecycle/family/care death publication
→ probe retirement
```

The estate is never opened before physical custody resolution. An enabled
session cannot publish the death without the matching estate, death identity,
tick, physical resolution and causal chain. A late error restores mortality,
estate, family, childhood, care, commitments, Material Rights, World,
container, probe and indexes exactly.

Death does not create or delete matter. A physically carried stack is moved
once through the existing Pebble mortality exit into a verified safe
container. The estate records that receipt and holder observation; it never
pretends to carry the item itself.

## Rights, claims, permissions and obligations

Each registered Material Rights record relevant to the deceased is classified
against its exact physical identity and quantity:

- recognized ownership, custody, claims and permissions remain distinct;
- a decedent-owned asset with verified post-mortality custody may enter
  succession;
- third-party claims block automatic transfer rather than being erased;
- third-party ownership prevents the item from being inherited by the
  decedent's successors;
- the deceased's personal use permissions and strictly personal commitments
  end through explicit causal transitions;
- permissions belonging to living third parties remain unchanged;
- current V1 obligation entries are explicitly classified as personal-ended
  or non-transferable rather than reassigned by assumption;
- physically present but socially unregistered matter remains visible and
  blocked; it is not granted an invented owner.

The settlement changes the existing Material Rights record only after the
physical transfer verifies. It replaces the deceased ownership and claim with
the named beneficiary's received claim and recognized ownership. It preserves
unrelated claims and permissions and never creates a parallel property record.

## Canonical successors and administration

Successors are derived deterministically from durable state at the death tick:

```text
primary: active union partner at death + canonical children
secondary: canonical parents
tertiary: full and half siblings
otherwise: no successor
```

Only the first non-empty tier is used. IDs are canonicalized, duplicates are
removed and each beneficiary has equal unit weight. A partner whose union is
ended by that same death remains discoverable through the union that was
active immediately before death; a former partner separated before death is
not eligible. Parentage, sibling basis, life stage and guardian-at-plan are
durably revalidated. Schema 28 persists the complete canonical eligibility
rows, selected tier, death boundary, active-union-at-death evidence, causal
plan event and a versioned digest, so unrelated mortality or causal-ledger
eviction never makes exact plan validation permissive.

Asset allocation uses sorted stable asset entries and beneficiaries with
deterministic round-robin assignment. V1 does not estimate value, split
stacks, apply primogeniture, prefer a house or elect a leader.

Administration is not automatic ownership or custody. A deterministic mature,
living, physiologically available, resident and non-migrating candidate is
nominated from the bounded bases:

```text
active partner at death
→ mature canonical child
→ mature canonical parent
→ mature sibling
→ mature household adult
```

The nominee becomes active only through one explicit accepted operation and
causal event. Acceptance is idempotently protected. Death, incapacity,
migration, unavailability or final settlement ends that administration; any
replacement is another explicit durable period. An administrator cannot
transfer an asset to themself unless the successor plan independently names
them as beneficiary.

## Physical settlement and minor custody

Pebble prevalidates the source holder, physical identity, quantity, destination
probe or safe container, beneficiary, intended custodian and active
administrator. It then transfers the exact stack through PebbleCore, observes
both postconditions, stages the matching estate and Material Rights transition,
validates the entire candidate session and publishes only after success.

For a mature beneficiary:

```text
beneficiary = recognized owner
beneficiary probe = physical holder
current custodian = none
intended custodian = beneficiary
```

For a minor beneficiary:

```text
minor = recognized owner
active guardian = intended material custodian
guardian probe or verified custody destination = physical holder
```

The guardian does not become owner merely by holding the item. Missing or
invalid guardianship blocks the transfer without losing matter.

Each asset records at most one successful settlement receipt and transition.
The aggregate rejects an outcome or replay record unless the settlement
operation ID and physical receipt ID are exactly the same, before any session
or World-facing mutation.
Partial settlement persists completed entries and leaves unresolved entries
explicitly pending or blocked. A restart does not redistribute a transferred
entry. Any failure after the physical move but before social publication
performs and verifies the inverse physical transfer; unverifiable rollback is
a hard failure.

When a real guardian or physiological-availability change affects a blocked
beneficiary, the candidate transaction revalidates the intended custodian
through a bounded causal transition. It preserves successor allocation,
claim tier and permissions, records a structured unavailability reason when
necessary, and remains restart-stable.

## Persistence, replay and observation

Checkpoint/replay schema 28 persists:

```text
estate configuration and activation boundary
estate, death and asset identities
beneficiary tier and complete canonical eligibility rows
life stage and minor guardian at the death boundary
active-union-at-death evidence and successor-plan digest
successor-plan causal event identity
administration periods and accepted operations
physical exit observations and receipts
rights/claim/permission classifications
obligation dispositions
asset assignments, intended custodians, causal revalidation and outcomes
partial/final settlement state
bounded counters and rolling digest
```

Restore validates the complete cross-domain model before publication:
activation coverage, coordinated death/estate retention, exactly-one
post-activation estate per death, exact first non-empty successor tier and
beneficiary list, partner-at-death history, kinship bases, historical life
stage and guardian, administrator availability and acceptance, operational
status, asset identity/quantity, current Material Rights, custody retry,
single settlement identity, receipts, causal events, state counters and
terminal consistency.

Schema 26 remains readable only with estates disabled and empty. It never
retroactively invents an estate. Schema 27 remains readable only when its
retained mortality and causal evidence reconstruct the exact successor plan;
an incomplete legacy proof fails closed. Schema 28 replay restores the same
durable bytes and digest without reopening, reaccepting, retransferring or
resettling.

The versioned manifest-integrity digest and protected empty-custody
attestation remain mandatory. The rendered restart restores the persistent
child probe only from that intact attestation. Missing holders or unresolved
Material Rights still fail closed under CIV-27 physical reconciliation.

Observer schema 6 adds a bounded read-only estate projection covering status,
decedent, death, tier, beneficiaries, administration, asset classification,
holder, custodian, owner, claims, permissions, settlement receipts and causal
events. Repeated observation preserves tick, causal sequence and durable
digest.

## Deterministic evidence

Commands executed after the final product change:

```text
PEBBLELAB_SMOKE_ONLY=estates-inheritance-succession swift run --disable-sandbox pebsmoke
70 passed, 0 failed

PEBBLELAB_SMOKE_ONLY=mortality swift run --disable-sandbox pebsmoke
93 passed, 0 failed

PEBBLELAB_SMOKE_ONLY=material-rights swift run --disable-sandbox pebsmoke
21 passed, 0 failed

PEBBLELAB_SMOKE_ONLY=unions-family-lineages-houses swift run --disable-sandbox pebsmoke
83 passed, 0 failed

PEBBLELAB_SMOKE_ONLY=childhood-guardianship swift run --disable-sandbox pebsmoke
62 passed, 0 failed

PEBBLELAB_SMOKE_ONLY=checkpoint-replay swift run --disable-sandbox pebsmoke
49 passed, 0 failed

PEBBLELAB_SMOKE_ONLY=observer swift run --disable-sandbox pebsmoke
20 passed, 0 failed

scripts/verify-pebblelab.sh
3636 passed, 0 failed
35/35 verification steps
exit status 0
```

Focused coverage includes explicit prospective activation, no retroactive
estate, deterministic IDs and successor ordering, partner-at-death lookup,
former-partner exclusion, primary/secondary/tertiary tiers, no-successor
dormancy, administrator acceptance and replacement, third-party claim and
permission preservation, unregistered or missing material refusal, adult and
minor custody, partial settlement, exact late-failure rollback, no duplicate
settlement, bounded compaction, candidate mortality atomicity, schema-27
exact-proof compatibility and incomplete-proof refusal, schema-28 exact
successor proof after eviction, estate-status recomputation, coordinated
mortality/estate retention at capacity two, operation/receipt identity,
blocked-custody revalidation, schema-26 restrictive compatibility and
Observer immutability.

## Rendered two-process campaign

The final native rendered campaign used disposable World
`PebbleLab-Disposable-CIV33-46`, World identity `wms9zxldtfa0y`, seed 46 and
session `live-46-14-66--21`.

Process 1 verified:

```text
normal birth birth-00000001 → agent_3
canonical progenitors agent_0 + agent_1
inherited genotype genotype-agent_3-v1-7eb9e1b0ffbd955e
asset asset:civ27:live-pickaxe / iron_pickaxe:1
physical holder agent_0 / recognized owner agent_0
material custodian agent_1
compounded homeostatic failure death of agent_0 at tick 23
verified mortality exit to container 19,69,-21
estate estate-47e162a3d3b54385 opened once
successor tier primaryPartnerAndChildren
beneficiaries agent_1 active partner + agent_3 canonical child
successor proof v1 / digest fc016079e408e2c9 / 2 canonical rows
administrator agent_1 accepted once
late settlement fault rolled back exactly
schema-28 save
manifest integrity v1 / 77dfd50bc382a7fc45e433ae9e8363e4ffc048b4c75e27cf5a4cc5a209978703
complete process termination
```

Process 2 loaded the same World and session. It restored `agent_3` only from
the intact protected empty-custody attestation, retired the dead `agent_0`
probe, matched physical reconciliation and reproduced the same estate,
beneficiaries, schema-28 successor proof and digest, administrator, asset
identity, quantity, rights and causal history. It then transferred the one
iron pickaxe exactly once to the mature
beneficiary `agent_1` and settled the estate once.

```text
physical quantity before death: 1
physical quantity after mortality exit: 1
physical quantity after restart: 1
physical quantity after settlement: 1
estate opening count: 1
administrator acceptance count: 1
asset settlement count: 1
estate settlement count: 1
duplication count: 0
Observer mutation count: 0
runtime errors: 0
cleanup: probesRemoved=3 per process; asset, fixture container and checkpoints deleted; exact
```

The four native-resolution `3024×1898` captures were individually inspected:

```text
civ33-predeath-physical-asset.png
civ33-open-estate.png
civ33-same-estate-after-restart.png
civ33-settled-inheritance.png
```

They show the pre-death physical/social rights, the administered open estate
with its pending container-held asset, the same estate and reconciliation
after true process termination and restart, and the final exact holder/owner
transfer with settlement causes. No visual corruption or contradictory
authority was found.

## Limits

`CIV-33` does not prove or introduce:

- wills, testamentary choice, probate courts, judges, legal disputes, taxes,
  debts, creditors or an unbounded law of inheritance;
- item valuation, currency, equal-value partition, stack splitting, auctions
  or a general economy;
- land titles, building ownership, house treasuries, corporate persons or an
  estate as a physical or cognitive entity;
- primogeniture, surnames, titles, offices, house leadership, dynastic
  succession, political succession or status inheritance;
- inheritance of genotype, phenotype, personality, trust, guardianship,
  caregiver role, profession, skill, union, household or house membership;
- automatic transfer of third-party claims, permissions, unsafe physical
  matter or obligations whose survival has not been explicitly modelled;
- renewable subsistence, `V4-GATE-D-v1` acquisition or the production economy
  of `CIV-34`.

All required CIV phases for Gate D are complete, but the gate remains
unevaluated and blocked on its separate renewable-subsistence milestone.
