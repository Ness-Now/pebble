# Gate F Blocker 02 — Migration Destination Capacity and Durable Slot Authority

## Status

`V4-GATE-F-v1 Blocker 02: FIXED — LOCAL CORRECTION CANDIDATE — SENIOR REVIEW REQUIRED`

This is a targeted product correction rooted directly at published canonical
baseline `c60eda84210cc8ed32f910f6f36ec29c1f747a9b`. It preserves both Gate F
evaluations as immutable historical evidence. It does not publish the
correction, perform Evaluation 03, acquire Gate F, or start CIV-40 or CIV-41.

- Gate F Evaluation 01: `FAIL — HISTORICAL IMMUTABLE EVIDENCE`
- Gate F Blocker 01: `FIXED + PUBLISHED + REMOTE VERIFIED`
- Gate F Evaluation 02: `FAIL — HISTORICAL IMMUTABLE EVIDENCE`
- Gate F Blocker 02: `FIXED — LOCAL CORRECTION CANDIDATE — SENIOR REVIEW REQUIRED`
- Gate F: `PLANNED — NOT ACQUIRED`
- Gate F Evaluation 03: `NOT AUTHORIZED / NOT PERFORMED`
- CIV-40: `OPTIONAL TOOLING — NOT STARTED`
- CIV-41: `NOT STARTED`

## Git and historical evidence identity

```text
published correction baseline: c60eda84210cc8ed32f910f6f36ec29c1f747a9b
verified origin/lab/pebblelab-v1: c60eda84210cc8ed32f910f6f36ec29c1f747a9b
correction branch: codex/gate-f-blocker-02-migration-capacity
product/test/runtime-proof commit: 7ec342dce329b611d418562383956bad40c9023d
documentation candidate commit: 8cb127f77ed8c57636e1be82e211f6758267c31d
publication: NOT PERFORMED
independent remote verification of correction: NOT PERFORMED
```

Gate F Evaluation 02 identity remains:

```text
evaluated baseline: c60eda84210cc8ed32f910f6f36ec29c1f747a9b
evaluation harness commit: fcc85fd95ab7acb3ba194fd75a664c4dda6b065d
evaluation final evidence HEAD: 6d30677fef504c51cc9f5847289e6206941b1d6c
evaluation review ZIP SHA-256: 1e2f9f6da0fd8f05ae343393a51eddb0a2391b015f4db38afadf5f01ce7d27de
deterministic blocker digest: 3e6ac273c41315cd
verdict: FAIL — HISTORICAL IMMUTABLE EVIDENCE
```

Both Evaluation 02 ancestry checks return exit `1` from
`git merge-base --is-ancestor`. Neither evaluation commit is part of this
correction branch. No evaluation commit was merged or cherry-picked.

## Historical contradiction and root cause

Evaluation 02 validly initialized two settlements, placed one resident in a
destination with capacity one, then started ordinary scaled settlement
migration for a LIVE resident from the origin. Migration admission validated
identity, fidelity, route, concurrency and distinct settlements, but did not
establish destination-capacity authority.

After Pebble's normal cognition, movement coordination and verified physical
publication reached reception, arrival removed origin transit membership and
appended the migrant to destination `residentIDs`. The product therefore
published two residents at capacity one. It created schema 35, while fresh
restore correctly rejected the product-created state with
`AgentCheckpointError.invalidBound("population settlement")`.

The root cause was not Blocker 01's current-resident predicate. Blocker 01
correctly aligned initialization publication and restore for current
residents. The scaled migration lifecycle used a distinct durable admission
path and did not treat a nonterminal destination migration as a committed
incoming resident slot.

## Destination-capacity authority model

The correction introduces no persisted reservation field and no second
occupancy counter. `AgentPopulationRegistry` derives one committed-slot answer
from authority already persisted in schema 35:

```text
committed slots for settlement S =
    current residentIDs in S
  + active legacy migration records whose destination is S
  + active scaled settlement-migration records whose destination is S
  + proposed admissions to S in the candidate operation
```

Only `.admitted` / `.inTransit` legacy records and `.inTransit` scaled records
claim a slot. Arrived, failed and other terminal history has no current
capacity authority. The existing `hasResidentCapacity` predicate is retained
unchanged and remains the current-resident bound. The new committed predicate
calls it with the complete derived incoming claim set.

This model is deterministic, bounded and reconstructible after restart. The
active scaled migration record is simultaneously the migration authority and
the destination claim; there is no duplicate owner to reconcile.

## Admission, arrival and atomicity

Scaled migration start now checks complete committed occupancy before the
first causal append, navigation update, origin projection change, migration
ordinal consumption or fidelity-relevant publication. A full destination
throws `AgentSessionError.population(.capacityReached)` through the existing
copy-candidate transaction, leaving authoritative bytes, events, settlement
projections, migration history, ordinal and fidelity state exact.

An accepted start removes the inhabitant from origin current residents, adds
it once to origin transit, and appends one active migration record. That record
claims exactly one destination slot. Origin occupancy therefore remains
released according to the published migration semantics without making the
inhabitant resident in two settlements.

Verified arrival revalidates all of the following before its causal event:

- the exact current inhabitant and active migration exist;
- the member remains migrating from the recorded origin;
- origin transit contains that inhabitant;
- exact navigation state reports physical arrival at the destination target;
- the complete committed-slot predicate remains valid;
- destination residents do not already contain the migrant.

Arrival then atomically converts one active claim into one current resident.
If an unexpected late conflict ever reaches this boundary, the candidate
session refuses publication. Pebble's existing movement executor invokes this
publication inside its post-apply validation and restores the verified
physical state on rejection. No fake arrival, teleport, hidden World mutation
or second movement engine is introduced.

## Intervening occupancy audit

V1 permits exactly one active scaled settlement migration. A second scaled
migration therefore cannot compete for the last slot; it fails atomically at
the existing concurrency boundary while the first persisted claim remains
current.

Legacy external migrants and local births target only the main settlement.
The main settlement capacity is exactly the independent global
`maximumActivePopulation` bound. A scaled inter-settlement claimant is already
an active population member, so a birth or external migrant admitted under the
global bound cannot make main current-plus-claimed occupancy exceed that same
bound. Both admission paths nevertheless apply the common committed predicate,
and legacy active records are included during restart validation.

No public V1 operation adds a current resident directly to an additional
settlement after scale initialization. Initialization applies the committed
predicate to its complete sorted batch, so Blocker 01 remains fixed even if a
legacy main-settlement claim already exists.

## Terminalization, mortality and compaction

The supported scaled terminal-failure reason is `memberDied`. Mortality remains
the sole death/lifecycle transaction. It changes the active migration to one
typed `failed/memberDied` record, removes all current resident/transit and
fidelity authority, removes the active member, and publishes one death. Because
terminal history is excluded from the derived claim set, capacity is released
exactly once. No later movement or arrival can occur for the dead identity.

A death among current destination residents removes that resident occurrence
and genuinely frees one slot. The focused proof then retries migration with
the still-unused ordinal and consumes that slot once. Gate D lifecycle/death
history and Gate E terminal physical custody remain under their published
owners and pass their owning regressions.

Migration-history compaction evicts only terminal records. Start now compacts
terminal history after appending the new active record, ensuring a checkpoint
at the configured history bound contains the active claim rather than a
temporary `limit + 1` history. Active capacity authority is never removed;
terminal history never keeps a slot.

## Persistence

Checkpoint schema remains `35`; no durable shape changes. Restore retains both
the unchanged current-resident check and the committed-slot check. A checkpoint
with an in-flight migration therefore reconstructs one destination claim from
the migration record itself. An impossible overcommitted checkpoint fails
closed with `invalidBound("population settlement")`.

Fresh restart proves:

- byte-exact in-flight state and one active destination claim;
- the same settlement and AgentIDs;
- verified two-step continuation;
- one arrival and no replay;
- destination finishing at exactly `2/2`, never above capacity;
- one membership and durable identity per inhabitant;
- completed-arrival schema-35 restore exactness;
- Observer schema 13 with no mutation.

## Dedicated focused proof

The selector is:

```text
PEBBLELAB_SMOKE_ONLY=gate-f-blocker-02 .build/debug/pebsmoke
PEBBLELAB_SMOKE_ONLY=gate-f-blocker-02 .build/release/pebsmoke
```

Both configurations pass `27/27` with semantic digest
`352bdb01a6f0bb1e`. The matrix proves:

- capacity-one/full refusal;
- exact durable/event/projection/history/ordinal/fidelity atomicity;
- exact-full normal checkpoint restore;
- death freeing the destination and a no-gap retry;
- exact-capacity successful arrival and restore;
- one free slot producing one durable in-flight claim;
- competing migration refusal with byte equality;
- schema-35 in-flight restore and exactly one continuation;
- completed-arrival restore with no replay;
- singular inhabitant, identity and membership projections;
- active-migrant death, one terminal failure and released capacity;
- subsequent legitimate use of the released slot;
- terminal-history compaction retaining only current active authority;
- deterministic bytes and scale digest.

The historical full-destination sequence now refuses before migration start;
it cannot reach physical movement or publish the Evaluation 02 contradiction.

## Two-process runtime proof

Two fresh PebbleLab processes run:

```text
.build/debug/PebbleLab --seed 402 \
  --scenario gate_f_blocker_02_migration_exit_smoke --out <fresh-dir>
.build/debug/PebbleLab --seed 402 \
  --scenario gate_f_blocker_02_migration_restore_smoke --out <same-dir>
```

Process one proves full-destination refusal with exact bytes/events, starts one
independently valid migration into the only free slot of a capacity-two
destination, checks Observer immutability and writes schema 35 at that in-flight
boundary. It separately finalizes death during active migration, observes one
`failed/memberDied`, and proves another inhabitant can use the released slot.

Process two is a new OS process. It restores the in-flight bytes exactly,
reconstructs one claim, publishes two verified movement outcomes through the
existing physical-publication seam, arrives once at `2/2`, writes/restores a
completed schema-35 checkpoint, inspects Observer 13 and records exact cleanup.

```text
processes=2
in-flight digest=f3471c4eaa201aee
completed-arrival digest=f2cf49cd7f6e8603
death/failure-release digest=185e33166265b6b2
checkpointSchema=35
observerSchema=13
settlements=2
population=4
verified movement publications=2
arrival count=1
duplicate inhabitants=0
duplicate durable identities=0
duplicate memberships=0
duplicate arrivals=0
duplicate deaths=0
restart duplicate effects=0
observer mutations=0
physical loss=0
physical duplication=0
synthetic material=0
unexpected runtime errors=0
```

The validation-only runtime does not claim a new rendered campaign. Existing
CIV-39 and candidate-physical-atomicity regressions retain the real Pebble/Core
movement, compensation and rollback evidence.

## Regression evidence

Fresh results at the local correction candidate:

| Surface | Result |
| --- | ---: |
| Gate F Blocker 02 debug | 27/27 PASS |
| Gate F Blocker 02 optimized | 27/27 PASS |
| Gate F Blocker 01 debug | 20/20 PASS |
| Gate F Blocker 01 optimized | 20/20 PASS |
| CIV-39 | 69/69 PASS |
| population migration | 66/66 PASS |
| Gate D owning continuity | 498/498 PASS |
| Gate E owning continuity, including E01–E04 | 291/291 PASS |
| migration/embodiment/persistence/Observer/atomicity | 949/949 PASS |
| all listed owning selectors | 1738/1738 PASS |
| canonical repository verification | 35/35 steps; 4104/4104 assertions PASS |

Gate D includes homeostasis/health, lifecycle, mortality,
estates/inheritance/succession, unions/family/lineages/houses, dependent care
and CIV-39 composition. Gate E includes material rights, production, barter,
contracts, markets and Gate E Blockers 01–04. The physical/persistence group
includes population migration, embodiment/Core descent, autonomous
civilization, checkpoint/replay, persistence/reconciliation, Observer and
candidate physical atomicity.

Canonical `scripts/verify-pebblelab.sh` passes all `35/35` steps with
`4104/4104` assertions. It rebuilds debug Pebble, release Pebble, release
PebbleLab and release pebsmoke; runs the read-only golden/shared-runtime suite;
then proves deterministic canonical outputs for agents, settlement metrics,
ecology, mortality, lifecycle, kinship, households, dependent care and skills.
No golden is regenerated and no test is weakened.

## Changed product and proof surfaces

Product:

- `Sources/PebbleAgents/AgentPopulation.swift`
- `Sources/PebbleAgents/AgentSimulationSession+Population.swift`
- `Sources/PebbleAgents/AgentSimulationSession+PopulationScale.swift`
- `Sources/PebbleAgents/AgentSimulationSession+Lifecycle.swift`

Focused and runtime proof:

- `Sources/pebsmoke/PebbleAgentsGateFBlocker02Smoke.swift`
- `Sources/pebsmoke/main.swift`
- `Sources/PebbleLab/LabGateFBlocker02MigrationCapacityScenario.swift`
- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/main.swift`

## Limitations and non-claims

- This is a local correction candidate, not a published correction.
- Senior review, manual publication and independent remote verification remain
  required before Evaluation 03 can be authorized.
- Evaluations 01 and 02 remain immutable historical FAIL evidence.
- Gate F remains planned and is not acquired.
- Evaluation 03 is not performed.
- CIV-40 and CIV-41 are not started.
- Schema remains 35 and Observer remains 13.
- Settlement capacity, global population capacity and migration concurrency are
  not increased.
- No currency, new movement engine, second civilization authority or rendered
  proof is claimed.
- Goldens are not regenerated.
- Push attempted: NO.
