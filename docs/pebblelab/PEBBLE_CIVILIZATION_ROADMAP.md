# Pebble Civilization — Roadmap V4

## Status and authority

This is the canonical human roadmap for the program after Gate B. It defines
delivery order, required and optional phases, gate contracts and intermediate
observable outcomes.

It does not override code reality. Code, tests and the published GitHub HEAD
remain authoritative for what is implemented. The durable product target is
defined by [`PEBBLE_CIVILIZATION_VISION.md`](PEBBLE_CIVILIZATION_VISION.md).
[`ROADMAP_MANIFEST.json`](ROADMAP_MANIFEST.json) is the machine-readable
projection of this document and must agree with it exactly.

Published product baseline evaluated by the independent Gate C campaign:

```text
3d70c67b69824133eb318391f8e7c385f8cabce8
```

This anchors the product behavior evaluated for Gate C. The containing
evidence/status commit is identified by Git rather than self-referenced by this
roadmap.

## Canonical position

```text
CIV-00 through CIV-30: COMPLETE
Gate R: ACQUIRED AND PUBLISHED
Gate B: ACQUIRED AND PUBLISHED
post-Gate-B safe-bootstrap hardening: PUBLISHED
active CIV phase: none
next authorized action: CIV-31
CIV-30: COMPLETE
V4-GATE-C-v1: ACQUIRED AND PUBLISHED
CIV-31: NOT STARTED — NEXT ELIGIBLE PHASE
V4-GATE-D-v1: PLANNED
V4-MILESTONE-RENEWABLE-SUBSISTENCE-v1: PLANNED
```

The `CIV-29` completion is published on the canonical branch at
`c1eda66dfacdd16911207b6fc8fd58df8581b99f`. The `CIV-30` completion in this
local tree remains a review candidate until senior review, manual push and
remote verification complete.

Gate B is acquired under `V4-GATE-B-v1`, the bounded checkpoint proved by the
published closure and subsequently hardened for normal-world bootstrap:

```text
bounded embodied local autonomy
+ local physical observation and execution
+ bounded failure and cooldown behavior
+ honest finite-world quiescence
+ material reactivation through normal boundaries
```

It does not claim an infinite renewable economy, multi-generational continuity,
a complete material economy, large populations, culture or medieval
institutions. Historical Gate B `FAIL` reports and the closure-candidate report
remain unchanged evidence for their own evaluations; they do not reopen the
acquired gate.

## Delivery doctrine

- Reuse existing Pebble mechanics before adding physical behavior.
- Deliver observable vertical slices at least every two or three required
  phases in long waves.
- Persistence follows rights before later durable social state accumulates.
- Observer V1 arrives before generations and economy make the system opaque.
- Currency and training tooling are optional capabilities.
- Gates depend only on required phases and explicitly named required
  milestones.
- A gate contract is versioned. Historical references must say `V3 Gate X` or
  name their exact contract; unqualified gate names refer to this V4 roadmap.
- Distant phases define outcomes and anti-goals, not frozen implementation.
- A gate is acquired only after evidence, senior review, manual publication
  and remote verification.

## Acquired foundation

The completed contracts are retained without reopening them:

| Phase | Status | Result |
| --- | --- | --- |
| `CIV-00` | completed | Documentation and Civilization Rebaseline |
| `CIV-01` | completed | Behavior-Preserving Runtime Modularization |
| `CIV-02` | completed | Stable Identity, Simulation Clock and Causal Ledger |
| `CIV-03` | completed | Social Information and Directed Trust V1 |
| `CIV-04` | completed | Physical Local Communication V1 |
| `CIV-05` | completed | Cooperative Material Tasks V1 |
| `CIV-06` | completed | Checkpoint, Restart and Replay V1 |
| `CIV-07` | completed | Population and Local Migration V1 |
| `CIV-08` | completed | Settlement Metrics V1 |
| `CIV-09` | completed | Local Ecology V1 |
| `CIV-10` | completed | Starvation Mortality V1 |
| `CIV-11` | completed | Age, Stages, Reproduction and Birth V1 |
| `CIV-12` | completed | Kinship, Households and Dependent Care V1 |
| `CIV-13` | completed | Practice-Based Skills and Task Matching V1 |
| `CIV-14` | completed | Reuse and Convergence Baseline |
| `CIV-15` | completed | Actor-Neutral Physical Action Gateway V1 |
| `CIV-16` | completed | Real Material Identity and Inventory Bridge V1 |
| `CIV-17` | completed | Harvest and Resource Convergence V1 |
| `CIV-18` | completed | Construction and Placement Convergence V1 |
| `CIV-19` | completed | Navigation and Embodiment Boundary Consolidation V1 |
| `CIV-20` | completed | Demonstration, Teaching and Apprenticeship V1 |
| `CIV-21` | completed | Ecological Observation and Civil Calendar V1 |
| `CIV-22` | completed | Agriculture and Managed Surplus V1 |
| `CIV-23` | completed | Fishing, Hunting and Wild Subsistence V1 |
| `CIV-24` | completed | Livestock and Animal Capital V1 |
| `CIV-25` | completed | Durable Work Commitments and Emergent Professions V1 |

Gate R (`V3-GATE-R-v1`) remains acquired. Its permanent result is the
demonstrated boundary between civilization intent and Pebble physical truth.

## Wave 1 — Durable local world

This completed wave retains only its outcomes and boundaries as canonical;
each later phase receives its own mission design after auditing the
then-current code.

### `CIV-26` — Possession, Custody, Claims and Use Rights V1

Status: **completed, required**.

Result: distinguish physical holder, custodian, recognized owner, claimant and
authorized user while real Pebble items and containers remain authoritative.
A stolen or loaned object continues to exist physically while social claims
may diverge.

Not opened by this phase: markets, currency, complete inheritance, land law,
tribunals or taxation.

Bounded proof:
[`CIV_26_PHASE_SUMMARY.md`](CIV_26_PHASE_SUMMARY.md). It covers local social
recognition, permissions, verified transfers, transgression, conflict,
rollback and checkpoint/replay. It does not claim restart reconciliation or a
universal per-unit physical item UUID.

### `CIV-27` — Durable World/Civilization Persistence and Reconciliation V1

Status: **completed, required**.

Result: save, stop, restore, reconcile and continue a World and its
civilization without duplicating people, goods, claims, obligations, causal
history or activity state. PebbleCore World persistence remains authoritative;
the civilization adds no second World save.

Bounded proof:
[`CIV_27_PHASE_SUMMARY.md`](CIV_27_PHASE_SUMMARY.md). It covers schema 20,
explicit World binding, bounded post-load physical reconciliation, interrupted
activity policy, idempotence, corruption refusal, exact replay and a real
two-process rendered-World restart. It does not claim a global item registry,
cross-store atomic save or arbitrary migration.

### `CIV-28` — Observer and Chronicle V1

Status: **completed, required**.

Result: a read-only inspector exposes individuals, needs, activity, custody,
households, relations, claims, causal timeline and explicit wait/failure
reasons. The UI reads authoritative projections and computes no business
truth.

Observable slices:

- after `CIV-26`: inspect a real transfer where holder and claim can diverge;
- after `CIV-27`: inspect the same identities before and after a real restart;
- after `CIV-28`: follow the cause of a current action or refusal in the
  rendered World.

Bounded proof:
[`CIV_28_PHASE_SUMMARY.md`](CIV_28_PHASE_SUMMARY.md). It covers one coherent
versioned snapshot, structured reasons, a ledger-backed Chronicle, explicit
bounds and truncation, read-only UI navigation, rights/custody divergence,
schema-20 restart continuity and a real two-process rendered-World campaign.
It does not claim an omniscient observer, unbounded history, an editing
surface or Gate C acquisition.

### `V4-GATE-C-v1` — Durable Observable Local World

Required phases: `CIV-26`, `CIV-27`, `CIV-28`.

Status: **acquired**.

The gate proves coherent rights/custody, real restart and reconciliation,
material non-duplication, inspectable causal history and a local scenario that
can be understood before and after restart.

Independent proof:
[`GATE_C_EVALUATION_01_SUMMARY.md`](GATE_C_EVALUATION_01_SUMMARY.md) and
[`GATE_C_EVALUATION_01_SUMMARY.json`](GATE_C_EVALUATION_01_SUMMARY.json).
The evaluated product baseline passed 108 focused adversarial checks, the
3343-check repository gate and a rendered two-process restart with real
missing-asset reconciliation, zero duplication and read-only observation.

Gate C remains acquired and published. `CIV-29` and `CIV-30` do not reevaluate
it.

## Wave 2 — Generational continuity

Current entry status: `CIV-30` is **complete** and `CIV-31` is
**not started — next eligible phase**.

| Phase | Requirement | Outcome |
| --- | --- | --- |
| `CIV-29` | required | Homeostasis, Health, Aging and Mortality V2 |
| `CIV-30` | required | Genetics, Development and Phenotype V1 |
| `CIV-31` | required | Childhood, Guardianship and Social Development V2 |
| `CIV-32` | required | Unions, Family Relations, Lineages and Houses V1 |
| `CIV-33` | required | Estates, Inheritance and Succession V1 |

### `CIV-29` — Homeostasis, Health, Aging and Mortality V2

Status: **completed, required**.

Result: existing needs, the canonical health reserve, lifecycle age and
mortality V1 now drive one bounded physiological trajectory. Real food and
normal rest can support gradual recovery; prolonged compounded deprivation can
progress through strain, impairment, critical state and incapacity before one
causally finalized death. Later life changes bounded vulnerability and
recovery capacity without assigning a predetermined death tick.

Bounded proof:
[`CIV_29_PHASE_SUMMARY.md`](CIV_29_PHASE_SUMMARY.md). It covers schema 21,
deterministic checkpoint/replay, read-only Observer physiology, preservation
of material claims, verified exit of all physically carried inventory
independently of social registration, whole-boundary rollback, a real
two-process rendered restart during degradation, single causal mortality, no
resurrection and exact cleanup. It does not claim disease catalogs, medicine,
complex injury, long-term impairment mechanics, genetics, corpses,
inheritance or renewable subsistence.

### `CIV-30` — Genetics, Development and Phenotype V1

Status: **completed, required**.

Result: every active person receives one immutable genotype in a closed,
four-locus diploid model. Founders are initialized explicitly and
deterministically; normal births inherit one recorded contribution per locus
from each canonical progenitor with no general mutation. Development is a
bounded life-course projection of lifecycle age/stage and accumulated
physiological exposure. Phenotype is derived authoritatively from genotype and
development, and can modify only the existing CIV-29 physiology within
explicit bounds.

Bounded proof:
[`CIV_30_PHASE_SUMMARY.md`](CIV_30_PHASE_SUMMARY.md). It covers deterministic
founder and sibling variation, parent-order neutrality, mutation-free
inheritance with per-locus provenance, atomic child/parentage/household/genotype
publication, migration, post-mortem development stop, schema-22
checkpoint/replay, read-only Observer schema 3, bounded ecological
deduplication and fail-closed restoration of a persistent child probe only
when carried custody was attested empty by a sorted, bounded attestation
protected by the schema-22 manifest integrity digest. Inherited genotypes are
also validated against exactly one canonical birth, its ordered progenitors,
birth tick and retained causal chain. A real rendered two-process campaign,
plus an isolated corrupt-manifest refusal process, proves normal birth, the
same child and genotype after restart, continued newborn-to-juvenile
development, pre-mutation rejection, zero duplication and exact cleanup.

This phase does not claim general mutation, genetic disease, sex or gender,
detailed appearance, genetically assigned intelligence or personality,
guardianship, unions, lineages, houses, inheritance, renewable subsistence or
Gate D.

`CIV-31` is the next eligible phase but remains not started.

This wave must preserve the distinction between genotype, development,
education, knowledge, skill and status. Care consumes real time and resources.
Death leaves physical goods, claims and obligations to a durable estate rather
than deleting them administratively.

Required milestone `V4-MILESTONE-RENEWABLE-SUBSISTENCE-v1`:

> Before Gate D evaluation, at least one physical subsistence loop must
> complete and renew through normal Pebble mechanics across the relevant
> lifecycle and restart boundary.

The proof may use agriculture, livestock or another honest physical loop, but
must include real replenishment and a new productive cycle. Initial-world
exhaustion plus external test injection is not sufficient. The detailed
implementation belongs to a future mission, not this roadmap.

Observable slices:

- after `CIV-29`: visible health, aging and causal mortality;
- after `CIV-30`: inspect founder variation, inherited per-locus provenance
  and bounded phenotype across a real restart;
- after `CIV-31`: dependent childhood, care and guardianship over time;
- after `CIV-33`: a death, durable estate and succession across restart.

### `V4-GATE-D-v1` — Generational Continuity

Required phases: `CIV-29` through `CIV-33`.

Required milestone: `V4-MILESTONE-RENEWABLE-SUBSISTENCE-v1`.

The gate proves several possible generations, development shaped by childhood,
causal aging and death, durable family distinctions, and survival of goods and
obligations across people and restart.

## Wave 3 — Local material economy

| Phase | Requirement | Outcome |
| --- | --- | --- |
| `CIV-34` | required | Production, Tools and Workshops V1 |
| `CIV-35` | required | Barter and Local Exchange V1 |
| `CIV-36` | required | Debt, Promises and Durable Contracts V1 |
| `CIV-37` | required | Physical Markets and Local Price Discovery V1 |
| `CIV-38` | **optional capability** | Currency, Units of Account and Accounting V1 |

Production uses real recipes, tools, durability, workstations and rights.
Exchange moves physical goods atomically. Obligations are fulfilled by real
events. Markets are physical places with capacity, custody and local price
memory.

Currency is not required for progression or Gate E. A society may remain with
barter, obligations or commodity exchange.

Observable slices:

- after `CIV-35`: a real produced object is offered and exchanged;
- after `CIV-37`: a physical market shows deposits, withdrawals and local
  price history;
- `CIV-38`, if chosen: compare monetary and non-monetary trajectories.

### `V4-GATE-E-v1` — Local Material Economy

Required phases: `CIV-34` through `CIV-37`.

Optional capability: `CIV-38`.

The gate proves production, tools, exchange, obligations, physical markets,
conservation, logistics and multiple economic trajectories. Currency is not a
gate dependency.

## Wave 4 — Scale and settlements

| Phase | Requirement | Outcome |
| --- | --- | --- |
| `CIV-39` | required | Multi-Settlement, Population Scaling and Fidelity Tiers V1 |
| `CIV-40` | **optional tooling** | Training and Evaluation Bridge V1 |

`CIV-39` introduces measured population growth and `LIVE`/`NEAR`/`DORMANT`
fidelity while preserving identity, matter and obligations. `CIV-40` may
compare policies or export trajectories, but no external policy becomes
runtime authority.

Observable slice: two persistent settlements can be inspected while agents
move between fidelity tiers without duplication or identity loss.

### `V4-GATE-F-v1` — Durable Scaled World

Required phase: `CIV-39`.

Optional tooling: `CIV-40`.

The gate proves persistent multi-settlement scale, bounded fidelity
transitions, measured CPU/RAM/disk costs, causal migration and continued
observability. Training tooling is not a dependency.

## Wave 5 — Knowledge, language and culture

| Phase | Requirement | Outcome |
| --- | --- | --- |
| `CIV-41` | required | Structured Knowledge and Belief Graph V1 |
| `CIV-42` | required | Learned Proto-Language V1 |
| `CIV-43` | required | Oral Transmission and Distortion V1 |
| `CIV-44` | required | Compositional and Long-Distance Communication V1 |
| `CIV-45` | required | Writing and Literacy V1 |
| `CIV-46` | required | Books, Manuscripts, Archives and Libraries V1 |
| `CIV-47` | required | Distributed Culture, Norms and Ritual Practices V1 |

Truth, claims, understanding, belief, tradition and utterance remain distinct.
Language is learned from physical signals. Long-distance information requires
a carrier. Written knowledge is material and destructible. Culture remains
distributed across individuals.

Observable slices:

- after `CIV-43`: one claim changes across an oral transmission chain;
- after `CIV-46`: a physical text preserves information, then loss of its
  copies removes access;
- after `CIV-47`: two settlements exhibit causally traceable cultural
  divergence.

### `V4-GATE-G-v1` — Cumulative Culture

Required phases: `CIV-41` through `CIV-47`.

The gate proves multi-person and multi-generation transmission, dialect
divergence, survivable and losable traditions, material written preservation
and reconstructible cultural history.

## Wave 6 — Organizations, land and law

| Phase | Requirement | Outcome |
| --- | --- | --- |
| `CIV-48` | required | Generic Organization Kernel V1 |
| `CIV-49` | required | Guilds and Professional Institutions V1 |
| `CIV-50` | required | Heraldry and Visible Identity V1 |
| `CIV-51` | required | Settlements, Territory, Land and Obligations V1 |
| `CIV-52` | required | Governance, Charters, Law and Justice V1 |

Organizations share one generic lifecycle instead of separate guild, religion
or polity engines. Membership and loyalty remain distinct. Land, control,
ownership, claims and use rights may overlap. Rules have operational,
enforceable and fallible effects.

Observable slices:

- after `CIV-50`: an organization’s material assets, membership and symbols
  are visible without symbols creating loyalty;
- after `CIV-52`: a rule is proposed, imperfectly enforced and causally
  inspected.

### `V4-GATE-H-v1` — Local Medieval Institutions

Required phases: `CIV-48` through `CIV-52`.

The gate proves organizations born from needs, multiple memberships, material
institutional assets, distinct land rights, operational rules and the ability
of institutions to split or disappear.

## Wave 7 — Beliefs, diplomacy, conflict and polities

| Phase | Requirement | Outcome |
| --- | --- | --- |
| `CIV-53` | required | Beliefs, Myths and Emergent Religion V1 |
| `CIV-54` | required | Diplomacy, Treaties and Dynastic Alliances V1 |
| `CIV-55` | required | Conflict, Defense, Raids and War Logistics V1 |
| `CIV-56` | required | Emergent Polities and Alternative Feudalities V1 |

Religions emerge from interpreted events and transmission. Diplomacy uses
physical communication and structured clauses. PebbleCore owns damage and
combat; civilization owns causes, mobilization, logistics and consequences.
Political labels are derived descriptions.

Observable slices:

- after `CIV-54`: inspect competing interpretations and a negotiated treaty;
- after `CIV-56`: compare at least two causally different polity trajectories.

### `V4-GATE-I-v1` — Medieval World

Required phases: `CIV-53` through `CIV-56`.

The gate proves historically grounded belief, diplomacy and costly conflict,
divergent loyalty and membership, and polities that can emerge, split and
disappear.

## Wave 8 — Innovation and infrastructure

| Phase | Requirement | Outcome |
| --- | --- | --- |
| `CIV-57` | required | Technology, Crafting Knowledge and Innovation V1 |
| `CIV-58` | required | Redstone, Rails and Infrastructure V1 |

Techniques are learned, practiced, guarded, copied, lost and rediscovered.
Infrastructure uses real Pebble mechanics, materials and maintenance.

Observable slice: build, operate, maintain and lose one useful infrastructure
whose knowledge and material costs are inspectable.

### `V4-GATE-J-v1` — Alternative Renaissance

Required phases: `CIV-57`, `CIV-58`.

The gate proves cumulative but reversible innovation and useful, materially
maintained infrastructure under PebbleCore authority.

## Wave 9 — God world and final acceptance

| Phase | Requirement | Outcome |
| --- | --- | --- |
| `CIV-59` | required | God Observer, Historiography and Time Control V2 |
| `CIV-60` | required | Divine Interventions, Revelations and Prophets V1 |
| `CIV-61` | **optional capability** | LLM Provider Abstraction and Deterministic Mock V1 |
| `CIV-62` | **optional capability** | Local LLM Prototype and Benchmark |
| `CIV-63` | required | Grounded Dialogue, Autobiography and Player Contact V1 |
| `CIV-64` | **optional capability** | Dynamic Cognitive Budget and Large-Scale Inference V1 |
| `CIV-65` | required | Genesis Presets and Canonical Founder World |
| `CIV-66` | required | Long-Duration Civilization Acceptance |
| `CIV-67` | required | Incarnation and God World Final |

Dialogue remains grounded in authoritative memory, belief, language and
situation. It must have a deterministic/provider-off path. LLM integration,
local models and inference budgeting are optional capabilities and never gate
the world’s ability to live.

Observable slices:

- after `CIV-60`: observe a real intervention and divergent interpretations;
- after `CIV-63`: inspect a grounded, provider-off conversation;
- after `CIV-65`: run a Founder World without hidden final institutions;
- after `CIV-67`: leave and return through incarnation to verifiable
  generational consequences.

### `V4-GATE-K-v1` — God World

Required phases: `CIV-59`, `CIV-60`, `CIV-63`, `CIV-65`, `CIV-66`, `CIV-67`.

Optional capabilities: `CIV-61`, `CIV-62`, `CIV-64`.

The gate proves a world that lives without the player or an LLM, can be
understood and accelerated, records interventions, supports grounded contact,
keeps incarnation physical and produces verifiable long-duration history.

## Canonical gate summary

| Contract | Status | Required phases or milestones |
| --- | --- | --- |
| `V3-GATE-R-v1` | acquired | `CIV-19` |
| `V4-GATE-B-v1` | acquired | `CIV-25`; bounded embodied autonomy contract |
| `V4-GATE-C-v1` | acquired | `CIV-26`–`CIV-28` |
| `V4-GATE-D-v1` | planned | `CIV-29`–`CIV-33`; renewable subsistence milestone |
| `V4-GATE-E-v1` | planned | `CIV-34`–`CIV-37`; `CIV-38` optional |
| `V4-GATE-F-v1` | planned | `CIV-39`; `CIV-40` optional |
| `V4-GATE-G-v1` | planned | `CIV-41`–`CIV-47` |
| `V4-GATE-H-v1` | planned | `CIV-48`–`CIV-52` |
| `V4-GATE-I-v1` | planned | `CIV-53`–`CIV-56` |
| `V4-GATE-J-v1` | planned | `CIV-57`–`CIV-58` |
| `V4-GATE-K-v1` | planned | required provider-independent phases through `CIV-67` |

## Permanent cross-cutting work

Every wave preserves:

- deterministic ordering, seeded randomness and replayable external inputs;
- Reuse-First ownership;
- material conservation;
- local information and provenance;
- durable histories with bounds, indexing and compaction;
- read-only observability without a second truth;
- measured CPU, RAM, disk and collection budgets;
- provider-off operation;
- proportional headless, live, adversarial and visual validation;
- honest gate contracts that never depend on later or optional capability.

The roadmap is rolling. After each acquired gate, reconcile the published code
and evidence, then detail only the next wave enough to define safe missions.
