# Gate F Blocker 04 — Settlement Migration Household and Residence Authority

## Status

`V4-GATE-F-v1 Blocker 04: FIXED — LOCAL CORRECTION CANDIDATE`

This correction is rooted directly at independently remote-verified canonical
baseline `9b261c2bc513e1abfc31cdcf0acb64cdf035508c`. Its product, focused-proof
and two-process runtime commit is
`f1be1830c2d5903a0765d028fd7a3a0e821afec7`.

- Gate F Evaluation 01: `FAIL — HISTORICAL IMMUTABLE EVIDENCE`
- Gate F Blocker 01: `FIXED + PUBLISHED + REMOTE VERIFIED`
- Gate F Evaluation 02: `FAIL — HISTORICAL IMMUTABLE EVIDENCE`
- Gate F Blocker 02: `FIXED + PUBLISHED + REMOTE VERIFIED`
- Gate F Evaluation 03: `FAIL — HISTORICAL IMMUTABLE EVIDENCE`
- Gate F Blocker 03: `FIXED + PUBLISHED + REMOTE VERIFIED`
- Gate F Evaluation 04: `FAIL — HISTORICAL IMMUTABLE EVIDENCE`
- Gate F Blocker 04: `FIXED — LOCAL CORRECTION CANDIDATE`
- Gate F: `PLANNED — NOT ACQUIRED`
- Gate F Evaluation 05: `NOT AUTHORIZED / NOT PERFORMED`
- CIV-40: `OPTIONAL TOOLING — NOT STARTED`
- CIV-41: `NOT STARTED`

This local correction does not publish Blocker 04, acquire Gate F, perform
Evaluation 05, or start CIV-40 or CIV-41.

## Git and historical evidence identity

```text
canonical correction baseline: 9b261c2bc513e1abfc31cdcf0acb64cdf035508c
verified origin/lab/pebblelab-v1 at correction start: 9b261c2bc513e1abfc31cdcf0acb64cdf035508c
correction branch: codex/gate-f-blocker-04-household-migration-authority
product/test/runtime-proof commit: f1be1830c2d5903a0765d028fd7a3a0e821afec7
publication status: LOCAL ONLY — NOT PUBLISHED
```

Evaluation 04 remains immutable historical evidence:

```text
evaluated baseline: 9b261c2bc513e1abfc31cdcf0acb64cdf035508c
harness commit: 136b1ebed6a153166d0887722f8ca08adf2e9644
final evidence HEAD: eb26347bbbdbd4954d8ed975e6ca30de97d14bd4
review ZIP SHA-256: 4bfcd1ac27c89be8688e89ce0c3ada99cb1de5c47be7a7752e09e25520159e60
deterministic blocker digest: 5401cad6b29ffa07ec20c388601efd26847eb28305c1006e53046967698f5095
blocker kind: scaledMigrationHouseholdProjection
verdict: FAIL — HISTORICAL IMMUTABLE EVIDENCE
```

Both Evaluation 04 ancestry checks return exit `1` from
`git merge-base --is-ancestor`. Neither evaluation commit is an ancestor of
this correction branch; no Evaluation 04 harness or evidence commit was merged
or cherry-picked.

## Historical contradiction and root cause

The Evaluation 04 trajectory moved `agent_0` through ordinary cognition,
`AgentMovementCoordinator` and verified physical publication from the main
settlement to `settlement-east`. Scaled arrival correctly updated the
population member, settlement resident/in-transit projections, lifecycle
member and `AgentSessionAgentState.homePosition`. It did not transition the
agent's still-current origin household membership or residence authority.

The published product therefore exposed two contradictory current residence
claims. Population, lifecycle and home said destination; the current household
still said origin. The schema-35 restore validator and the next supported tick
correctly rejected that product-created state. The defect was in arrival
composition, not household validation.

The audit also found a hidden single-settlement assumption: household
initialization, new household creation, birth and legacy migration-admission
helpers wrote `populationRegistry.settlement`, the main settlement, instead of
the actual member settlement already represented by `AgentHouseholdRecord`.

## Chosen V1 household settlement model

A household record is current settlement-scoped residence authority. Its
`settlementID` identifies the settlement containing its current
`residenceAnchor`; every current member must have the same current population
settlement and home anchor. Closed membership periods and dissolved household
records remain history and never regain current settlement authority.

Scaled migration V1 moves one embodied adult, not an implicit social group. At
verified arrival the transaction:

1. closes the migrant's origin membership with reason
   `settlementMigration`;
2. retains a multi-member origin household for its remaining members;
3. dissolves a singleton origin household exactly once when it becomes empty;
4. creates one deterministic destination singleton household at the verified
   arrival anchor;
5. opens one destination membership with the same explicit reason;
6. makes household settlement, population settlement, lifecycle settlement and
   home anchor agree before the candidate is published.

The product does not silently move co-members, auto-join an unrelated
destination household, invent consent, or fabricate coupled family movement.
Destination household reuse is therefore not a supported V1 operation.

## Unsupported social relocation fails closed

V1 has no coupled physical/social transaction for moving a dependent with a
caregiver or guardian. Settlement migration therefore requires the existing
`voluntaryMigration` lifecycle capability and refuses before the route starts
when the migrant participates in an active dependent-care assignment,
engagement or guardianship. A child or newborn fails the lifecycle capability
check. Existing care, guardianship, kinship and family authority remains
unchanged on refusal.

Kinship and family identity are durable relationships, not a second residence
owner, so an otherwise independent mature adult may relocate without rewriting
that history. Existing reproduction planning remains scoped to its current V1
main-settlement doctrine. A parent who migrates after planning makes the plan
explicitly unavailable; the correction does not silently broaden remote-parent
birth semantics.

## Causal and atomic arrival design

Migration initiation prevalidates lifecycle capability, dependent-care
relocation constraints, current household membership, destination settlement,
historical-household capacity, membership-period capacity, active-household
capacity, transition capacity and household ordinal bounds before migration
publication or physical movement.

Arrival revalidates those authorities inside the existing copy-candidate
transaction. Only after the verified movement produces the canonical
`settlementMigrationArrived` event does the candidate close the old membership
and create/join the destination household. Household creation and both
membership events causally reference the verified arrival event and the prior
membership authority. Ordering and ordinals remain deterministic.

If a social bound becomes unavailable in flight, candidate publication throws.
The existing verified-physical movement transaction performs its established
compensation/reconciliation, while the civilization session remains
byte-identical with the durable destination claim still active. No synthetic
rollback event or second physical owner was introduced.

## Settlement-aware household audit

The correction removes the hidden main-settlement assumption from:

- initialization, which now groups by `(settlementID, homePosition)`;
- household creation and singleton creation, which derive the members' one
  actual current settlement;
- legacy migration admission, which uses the admitted member settlement;
- birth registration, which receives and validates the lifecycle plan's
  explicit settlement;
- household payloads and records, which retain their actual settlement;
- `moveMembers`, which refuses a cross-settlement household move;
- validation, which accepts known settlements but requires every current
  member's population settlement and home anchor to equal its current
  household.

`AgentHouseholdRecord` already persisted `settlementID`, so no persisted shape
or schema migration was needed. Checkpoint schema remains 35 and strict stale
projection rejection remains enabled.

## Focused proof

The dedicated selector is:

```text
PEBBLELAB_SMOKE_ONLY=gate-f-blocker-04 .build/debug/pebsmoke
PEBBLELAB_SMOKE_ONLY=gate-f-blocker-04 .build/release/pebsmoke
```

Both configurations pass `38/38`. The matrix proves:

- the exact historical multi-member origin shape now reaches coherent arrival,
  restores schema 35 exactly and advances the next tick;
- in-flight authority remains at origin with one durable destination claim;
- the destination current membership and household are singular;
- origin multi-member retention and singleton dissolution are exact;
- household creation and membership events causally reference arrival;
- population, lifecycle, home, household and settlement projections agree;
- the exact active-household boundary succeeds and active, historical,
  membership-period and per-tick transition N+1 cases refuse atomically;
- a late arrival-bound refusal preserves candidate bytes and retries once;
- a real death releases social capacity for one no-gap retry;
- equivalent founder caller order produces byte-identical durable state;
- caregiver, child and guardianship relocation refuse before movement;
- birth-then-unrelated-adult-migration and supported migration-then-birth remain
  coherent without widening reproduction;
- pre-arrival and post-arrival migrant death close claims and memberships once;
- terminal arrival releases the LIVE pin and later rotation rebalances once;
- malformed schema-35 state with a stale household settlement remains rejected;
- AgentID, population, lifecycle, fidelity, household and settlement membership
  remain singular.

## Two-process runtime proof

Two fresh PebbleLab processes run against one explicit artifact directory in
both debug and optimized configurations:

```text
.build/<configuration>/PebbleLab --seed 604 \
  --scenario gate_f_blocker_04_household_exit_smoke --out <fresh-dir>
.build/<configuration>/PebbleLab --seed 604 \
  --scenario gate_f_blocker_04_household_restore_smoke --out <same-dir>
```

Process one creates a three-founder world with a two-member origin household,
two settlements and CIV-39 scaling. It verifies pre-migration and in-flight
schema-35 restores, completes ordinary coordinated movement, publishes the
destination household, inspects Observer 13 read-only and writes an immediate
arrival checkpoint. A separate deterministic active-household-bound case
refuses with exact bytes, no migration record, no destination resident and no
population ordinal change.

Process two is a new OS process. It restores exact durable bytes, proves the
origin membership is history rather than current authority, advances one
supported tick without replay, writes and restores another schema-35
checkpoint, and inspects Observer 13 without mutation.

```text
processes per configuration: 2
checkpoint schema: 35
Observer schema: 13
arrival tick: 4
post-restore tick: 5
arrival semantic digest: 92d531f2b9a016bd327aef1ef7cdca2e4987d8114fbf7eaf3d23e101b0528534
post-tick semantic digest: 1b0460f07ca8e63689f88ceb16b80f6c8b4c0d3e6c6f18bbef2a6821dca48b53
household digest before/after restart tick: ae06f5e253ab6aef
arrival scale digest: 47b89f472baf9471
post-tick scale digest: 62dbac7cb5145611
population/lifecycle/household settlement: settlement-east
household/home anchor: 0,64,4
membership history/current: 2/1
duplicate agents: 0
duplicate population/lifecycle/fidelity/current-household memberships: 0
duplicate settlement residents: 0
duplicate arrivals: 0
duplicate household transitions: 0
restart duplicate effects: 0
physical loss: 0
physical duplication: 0
synthetic material: 0
Observer mutations: 0
unexpected runtime errors: 0
cleanup: exact PASS
```

## Validation

| Surface | Result |
| --- | ---: |
| Gate F Blocker 04 debug / optimized | 38/38 each PASS |
| Gate F Blocker 03 debug / optimized | 29/29 each PASS |
| Gate F Blocker 02 debug / optimized | 27/27 each PASS |
| Gate F Blocker 01 debug / optimized | 20/20 each PASS |
| CIV-39 | 69/69 PASS |
| population migration | 66/66 PASS |
| Gate D lifecycle/care/family/estate continuity | 537/537 PASS |
| Gate E continuity, including E01–E04 | 291/291 PASS |
| migration/embodiment/persistence/Observer/atomicity | 949/949 PASS |
| physical-action and material Core continuity | 73/73 PASS |
| all listed owning selectors | 1919/1919 PASS |
| focused Blockers 01–04 plus owning selectors | 2033/2033 PASS |
| canonical repository verification | 35/35 steps; 4133/4133 assertions PASS |

Gate D includes lifecycle/reproduction, mortality, homeostasis/health,
genetics, childhood/guardianship, unions/family/lineages/houses, dependent care
and estates/inheritance/succession. Gate E includes material rights,
production, barter, contracts, markets and Gate E Blockers 01–04. The
physical/persistence group includes population migration, embodiment/Core
descent, autonomous civilization, checkpoint/replay,
persistence/reconciliation, Observer and candidate physical atomicity.

No golden was regenerated and no assertion or validator was weakened.

## Changed product and proof surfaces

Product:

- `Sources/PebbleAgents/AgentHousehold.swift`
- `Sources/PebbleAgents/AgentSimulationSession+DependentCare.swift`
- `Sources/PebbleAgents/AgentSimulationSession+Household.swift`
- `Sources/PebbleAgents/AgentSimulationSession+Lifecycle.swift`
- `Sources/PebbleAgents/AgentSimulationSession+PopulationScale.swift`

Focused and runtime proof:

- `Sources/pebsmoke/PebbleAgentsGateFBlocker04Smoke.swift`
- `Sources/pebsmoke/main.swift`
- `Sources/PebbleLab/LabGateFBlocker04HouseholdMigrationScenario.swift`
- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/main.swift`

## Limitations and non-claims

- This is local Blocker 04 correction evidence, not publication or Gate F
  acquisition evidence.
- Evaluations 01–04 remain immutable historical FAIL evidence.
- Blockers 01–03 remain fixed, published and independently remote verified.
- Evaluation 05 is not authorized and was not performed.
- Gate F remains planned and is not acquired.
- CIV-40 remains optional tooling and is not started; CIV-41 is not started.
- Checkpoint schema remains 35 and Observer schema remains 13.
- Individual migration does not imply household, caregiver, dependent,
  guardianship or family-group migration.
- Existing V1 reproduction scope is not broadened.
- No settlement, population, household, causal or fidelity bound is increased.
- No second civilization authority, physical engine, currency or rendered proof
  is introduced.
- Goldens regenerated: NO.
- Push attempted: NO.
