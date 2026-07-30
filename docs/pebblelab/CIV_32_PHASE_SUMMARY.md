# CIV-32 — Unions, Family Relations, Lineages and Houses V1

## Verdict and baseline

`CIV-32` is complete in its bounded contract as a local review candidate. It
was implemented from the published canonical baseline:

```text
a5f06290e9596756e5690fd284f59aaa457d10d3
```

The product and rendered proof are separated into these reviewable commits:

```text
5b7cc5b  Implement bounded unions family lineages and houses
25dadfd  Add rendered CIV-32 restart campaign
```

This report intentionally does not self-reference its containing documentation
commit. Gate R, Gate B and `V4-GATE-C-v1` remain acquired and published.
`V4-GATE-D-v1` and
`V4-MILESTONE-RENEWABLE-SUBSISTENCE-v1` remain planned. `CIV-33` is not
started and is the next eligible phase.

## Reused authorities

`CIV-32` extends the sole existing `AgentSimulationSession` aggregate. It adds
no second population, lifecycle, reproduction, kinship, household, care,
childhood, genetics, mortality, Material Rights or World-persistence engine.

The permanent distinctions include:

```text
genetic progenitor
!= canonical kinship parent
!= union partner
!= household member
!= guardian
!= caregiver
!= lineage root or derived descendant
!= house member
!= physical holder
!= recognized owner
!= estate beneficiary
```

Population owns resident and migration truth. Lifecycle owns age, stage,
birth and death. Kinship owns canonical parentage. Households own co-residence.
Childhood and Dependent Care own guardianship and care. Material Rights owns
social claims over real matter. PebbleCore and Pebble remain the only physical
World and probe authorities.

## Union contract and physical consent

- Family V1 is explicitly enabled only after population, lifecycle, kinship,
  households and childhood. Its default live configuration bounds pending
  proposals to 64, union history to 256, active unions per person to one,
  transitions per tick to 64 and interaction distance to three blocks.
- An eligible partner is alive, physiologically available, mature, resident
  and not migrating. Selection never reads genotype, phenotype, wealth,
  profession, skill, house, household rank or display name.
- A proposal is one explicit social act grounded in a Pebble receipt that
  verifies both live probes, World positions, bounded proximity and
  communication. It creates only a pending proposal.
- Acceptance is a second physical act by the named counterparty and cannot
  reuse the proposal receipt. The canonical union activates only after both
  acts. Partner IDs and resulting IDs use stable deterministic ordering.
- Self-unions, parent/child unions, full- and half-sibling unions, unavailable
  people, third-party acceptance, receipt reuse and a second active union are
  refused before publication.
- Either actual partner may end an active union through an explicit unilateral
  separation receipt. Partner death ends it through the canonical mortality
  cause. Both paths publish exactly one bounded termination reason and retain
  former-partner history.
- A union does not merge households, create parentage, select a guardian,
  transfer custody or property, change trust, authorize reproduction, found a
  lineage or create a house automatically.

The causal validator binds the retained chain:

```text
physical proposal receipt
→ unionProposed
→ physical acceptance receipt
→ unionAccepted
→ unionActivated
```

Separation identifies the actual initiating partner. Death-driven termination
identifies the deceased partner and the retained lethal cause. If an honest
old causal prefix has been evicted from the bounded ledger, the same historical
reference policy already used by kinship applies; retained contradictory
events still fail closed.

## Derived family and lineage truth

Family relations are projections, not independently editable durable edges.
The bounded projection derives:

```text
parent / child
full sibling / half sibling
grandparent / grandchild
ancestor / descendant
active union partner / former union partner
co-parent
```

Canonical parentage is the only ancestry source. Union state is the only
partner source. A shared canonical child is the only co-parent source.
Projection order is stable and input/dictionary order does not change output.
The default projection exposes at most 256 relations per person, traverses at
most four ancestry generations and reports the total count and truncation
instead of silently claiming completeness.

A lineage persists only one explicit real root and its foundation cause.
Family V1 permits at most one lineage foundation per person and bounds the
live lineage set to 512. Descendant membership is always re-derived from full
canonical ancestry under the same visible depth and row limits; no durable
membership list can drift from kinship. Root death preserves the historical
root and derived descendants without inventing succession.

## Social houses

- A house is a bounded social affiliation, not a household, physical place,
  asset holder, estate, office, clan government or care authority.
- The default live bounds are 256 houses, one or two founders per house, 256
  active members per house and 1,024 retained membership periods.
- One mature eligible person can found a house explicitly. Two active
  partners can co-found one only after two separately grounded co-foundation
  acts. Founders receive explicit membership records.
- Another mature eligible adult joins through a grounded request and
  acceptance and may leave explicitly. Membership history is retained.
- Same-house membership never merges distinct households. Conversely,
  same-household residents may remain in different houses.
- A child joins automatically only when its two canonical progenitors share
  exactly one active house. The basis is
  `sharedParentHouseAtBirth`. Different parental houses, no common house or an
  ambiguous common set produces no invented membership.
- Union separation preserves house membership. Member death ends only that
  membership; the house remains without leader selection, succession or asset
  transfer.

## Atomic birth and death integration

Normal birth remains one candidate transaction. When the parents share
exactly one house, these authorities either publish together or remain
unchanged:

```text
child population identity and lifecycle birth
+ inherited genotype and per-locus provenance
+ canonical parentage
+ household membership
+ shared-parent house membership
+ dependent-care assignment
+ guardian responsibility
+ initial social development
+ causal ledger
```

A late family failure leaves no child, genotype, parentage, household,
guardianship, care or house-membership orphan and leaves World/probe indexes
unchanged.

Mortality candidate state closes an active union and the deceased member's
house periods in the same boundary while retaining lineages and family
history. A late failure restores mortality, family, childhood, care, material,
World and probe state exactly. Family V1 never moves or destroys physical
matter.

## Persistence, replay and observation

Checkpoint/replay schema 25 persists the bounded family configuration,
proposal and union history, lineage roots, houses, membership periods, exact
identity counters and typed family operations. Restore validates identities,
canonical ordering, one-active-union limits, participant eligibility where
active, proposal/union correspondence, house foundations and memberships,
birth-derived child membership, death reasons and retained causal payloads
before publication.

Schema 24 remains readable with Family V1 disabled and empty; it cannot invent
new family state. Schema 25 round-trip and replay restore the same bytes and
digest without reactivating a union, refounding a house or duplicating a
membership.

The versioned manifest-integrity and protected empty-custody rule remains in
force. The rendered restart recreates the persistent child probe only because
the intact schema-25 manifest attests its empty carried inventory. Manifest,
World binding, session candidate and probe indexes validate before
publication.

Observer schema 5 adds bounded read-only union, former-partner, family
relation, lineage, house and membership projections. It exposes truncation and
the separate household, care, guardian and Material Rights authorities.
Repeated observation preserves tick, causal sequence and durable digest.

## Deterministic evidence

Commands executed after the final product change:

```text
PEBBLELAB_SMOKE_ONLY=unions-family-lineages-houses swift run pebsmoke
60 passed, 0 failed

PEBBLELAB_SMOKE_ONLY=lifecycle swift run pebsmoke
80 passed, 0 failed

PEBBLELAB_SMOKE_ONLY=childhood-guardianship swift run pebsmoke
62 passed, 0 failed

PEBBLELAB_SMOKE_ONLY=dependent-care swift run pebsmoke
55 passed, 0 failed

PEBBLELAB_SMOKE_ONLY=homeostasis-health swift run pebsmoke
30 passed, 0 failed

PEBBLELAB_SMOKE_ONLY=genetics-development swift run pebsmoke
45 passed, 0 failed

PEBBLELAB_SMOKE_ONLY=checkpoint-replay swift run pebsmoke
49 passed, 0 failed

PEBBLELAB_SMOKE_ONLY=observer swift run pebsmoke
20 passed, 0 failed

PEBBLELAB_SMOKE_ONLY=mortality swift run pebsmoke
93 passed, 0 failed

PEBBLELAB_SMOKE_ONLY=material-rights swift run pebsmoke
21 passed, 0 failed

scripts/verify-pebblelab.sh
3543 passed, 0 failed
35/35 verification steps
exit status 0
```

Focused coverage includes input-order neutrality, eligibility and close-kin
refusal, two-act physical consent, one-active-union enforcement, relation
truncation, full/half sibling derivation, lineage ancestry, house/household
independence, normal birth with and without a shared parental house,
unilateral separation, partner/root death, exact causal actors and payloads,
counter corruption, schema-25 restore/replay and Observer immutability.

## Rendered two-process campaign

The final native rendered campaign used disposable World
`PebbleLab-Disposable-CIV32-46`, World identity `wms7kt7xac2v1`, seed 46 and
session `live-46-14-66--21`.

Process 1 verified:

```text
agent_0 physical proposal → pending proposal
agent_1 independent physical acceptance → union-00000001 active
lineage-00000001 root agent_0
lineage-00000002 root agent_1
house-00000001 co-founded by agent_0 + agent_1
distinct household_0 and household_1 preserved
normal birth birth-00000001 → agent_3
canonical progenitors agent_0 + agent_1
genotype genotype-agent_3-v1-7eb9e1b0ffbd955e
guardian agent_0 / canonicalParent
one house membership / sharedParentHouseAtBirth
schema-25 save
manifest integrity v1 / cdce3ce62ab8ebf79131cdb1c88bab4cd7cca5bff66093858aeefd59a43c9ce4
complete process termination
```

Process 2 loaded the same World and session, restored the physical `agent_3`
probe from the intact empty-custody attestation, and reproduced the same
union, child, genotype, parentage, guardian, lineages, house and membership.
It then ended the union once by `agent_0` unilateral separation. Parentage,
care, lineage, house, household and Material Rights state remained unchanged.

```text
union activation count: 1
union termination count: 1
house foundation count: 1
child house membership count: 1
duplication count: 0
Observer mutation count: 0
runtime errors: 0
cleanup: probesRemoved=4; checkpoints deleted; exact
```

The four native-resolution captures were individually inspected:

```text
civ32-physical-union-proposal.png
civ32-active-union-founded-house.png
civ32-same-family-after-restart.png
civ32-ended-union-preserved-family.png
```

They show the physical proposal and causal Chronicle, the active union with
separate lineage/house/household authorities, the same child and derived
family after the true restart, and former-partner history with family and
house state preserved after separation. No visual corruption or contradictory
authority was found.

## Limits

`CIV-32` does not prove or introduce:

- marriage, divorce law, civil status, sex or gender roles, sexuality or
  fertility policy;
- adoption, legal guardianship, surnames or naming inheritance;
- unbounded ancestry, genealogy search, clans, dynasties, heraldry or
  automatic social prestige;
- household merger, co-residence, guardianship, care, trust or reproduction
  caused by union or house membership;
- house land, buildings, treasuries, ownership, leadership, office, voting or
  succession;
- estates, wills, inheritance, succession or transfer of physical goods and
  obligations (`CIV-33`);
- renewable subsistence or `V4-GATE-D-v1`.

Gate D and its required renewable-subsistence milestone remain planned and
unevaluated.
