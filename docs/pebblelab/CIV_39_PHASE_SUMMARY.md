# CIV-39 — Multi-Settlement, Population Scaling and Fidelity Tiers V1

## Candidate verdict

`CIV-39` is **IMPLEMENTED LOCALLY — AWAITING SENIOR REVIEW AND
PUBLICATION** in its bounded V1 contract. This is candidate evidence, not a
publication or Gate F acquisition claim.

Exact published starting baseline and independently fetched canonical remote:

```text
repository: Ness-Now/pebble
canonical branch: origin/lab/pebblelab-v1
baseline: e567f9a5b283a71e42b5f8139c47f80f6562a5dc
remote verification: exact match before editing
candidate branch: codex/civ-39-multi-settlement-fidelity
implementation/proof commit: 3052dca3959ef1131081b6839f84b0860f531144
checked-tick integration correction: c06bcda12f2c56ab4cefea7cca200bb2d547f379
```

Program status represented by this candidate is:

```text
CIV-00 through CIV-37: COMPLETE AND PUBLISHED
CIV-38: OPTIONAL — NOT STARTED
CIV-39: IMPLEMENTED LOCALLY — AWAITING SENIOR REVIEW AND PUBLICATION
CIV-40: OPTIONAL TOOLING — NOT STARTED
Gate F: PLANNED — NOT ACQUIRED
Gate F evaluation performed: NO
```

## Bounded product result

The V1 adds two or more durable settlement records, real persistent residents,
deterministic `LIVE` / `NEAR` / `DORMANT` execution tiers, one-at-a-time
causal migration, schema-35 restart, Observer schema 12 and a reproducible
scaling harness. It does not add cities, factions, political allegiance,
culture, citizenship or another physical/cognitive authority.

Every resident remains one `AgentSessionAgentState` owned by the sole
`AgentSimulationSession`. Settlement membership and fidelity records contain
stable `AgentID` references; neither contains a copied person. Existing durable
identity, generation/lifecycle state, needs, memories, relationships, Material
Rights, production provenance, barter, contract, market and commitment state
remain on their existing canonical owners.

## Authority and settlement model

`PebbleCore` remains physical truth and supplies observed/preflighted navigation
and exact World movement. `Pebble` remains the sensor, physical executor,
verification, reconciliation and rollback boundary. `PebbleAgents` owns pure
deterministic settlement membership, fidelity scheduling and causal migration
state. `AgentSimulationSession` remains the only civilization aggregate root.
Observer and PebbleLab remain read-only projection and evidence owners.

The existing population registry is extended rather than replaced:

- one ordered collection holds the primary and additional settlements;
- each settlement has a stable `AgentSettlementID`, anchor, reception position,
  capacity, resident IDs and in-transit IDs;
- each population member has exactly one current settlement and membership
  status;
- validation requires every active inhabitant to occur exactly once across
  settlement resident/transit projections;
- historical migration records do not become current residence authority;
- removal/death removes current settlement membership while preserving existing
  lifecycle history;
- the V1 supports neither settlement removal nor merge, so it cannot silently
  erase people, matter or obligations through those operations.

Residence is locality only. It grants no political ownership, loyalty,
nationality, faction or culture.

## Fidelity contract and deterministic scheduling

Fidelity is execution cadence, not person type:

- `LIVE`: eligible for the ordinary full perception, cognition, action and
  verified physical execution path;
- `NEAR`: retains the exact durable inhabitant and performs bounded maintenance
  accounting every configured near cadence; it creates no exact physical
  result;
- `DORMANT`: retains the same durable inhabitant and performs only the more
  widely spaced bounded maintenance accounting; it creates no exact physical
  result.

Given the population registration ordinal and tick, the scheduler uses a
deterministic rotating window with configured maximum LIVE and NEAR counts.
The V1 defaults are four LIVE, twelve NEAR, near cadence four ticks, dormant
cadence sixteen ticks and rotation every eight ticks. An active migrant is
pinned LIVE until terminal arrival/failure so a lower-fidelity label cannot
complete physical travel. Observation, camera position, UI selection and
Observer inspection are not transition causes.

Transitions cite one of the bounded explainable causes `initialPolicy`,
`scheduledRotation`, `activeMigration` or `migrationCompleted`. A transition
updates only the reference record; `AgentID`, lifecycle identity, needs,
memory, relations, ownership, provenance, obligations, commitments and market
history are untouched. Validation refuses missing, duplicate or foreign
fidelity identities.

## Causal migration and physical authority

Only one settlement migration may be in flight in V1. Starting a migration:

1. validates the unique alive/resident inhabitant, distinct existing origin and
   destination, destination capacity and a bounded observed route;
2. creates one stable migration ID and causal start event;
3. moves the same membership from origin residents to origin transit;
4. pins that same `AgentID` LIVE and installs the existing navigation goal.

Pebble then reuses current World observation, Core navigation/preflight and the
existing movement executor. The executor handles a horizontal step followed by
the permitted one-block descent in the same candidate physical transaction and
rollback boundary. Settlement arrival is published only after exact World-side
position verification at the current migration target. Replanning may replace
a stale earlier route, so an exact verified destination is authority while a
historical route cursor is diagnostic only.

Arrival atomically changes the one current membership from origin transit to
destination resident, writes one terminal causal record and applies the normal
fidelity policy. Repeating arrival or restoring an already-arrived checkpoint
does not move or publish the person again. A lower-fidelity record cannot grant
inventory, crafting, production, market, combat or travel-completion authority.

## Persistence and restart

Checkpoint schema advances from 34 to 35 only when the population-scale state
is enabled. Legacy configurations continue encoding their established schema.
Schema 35 retains:

- all durable inhabitants and stable identities;
- all settlements and unique current memberships;
- fidelity configuration, records, scheduler offset and work counters;
- bounded fidelity-transition and migration histories plus eviction counters;
- in-flight migration route/cursor and causal IDs when applicable;
- all existing Gate D lifecycle and Gate E material/economic state.

Restore validates the whole candidate before publication. It refuses duplicate
membership, duplicate or missing fidelity references, impossible current
migrations, invalid bounds and contradictory settlement projections. Exact
World probes remain under Pebble reconciliation: a fresh process reacquires
current World truth, restores or repositions only through verified physical
operations, and performs no duplicated civilization transition or economic
effect.

The decisive fresh-process campaign restored schema 35 once with 12 exact
probes, nine absent probes restored, two positions reconciled, zero custody
duplicates and `restartDuplicateEffects=0`.

## Determinism and bounds

The active-population configuration bound increases from 8 to 512; the focused
and measured proofs use 24, 64 and 128. Settlement configuration is bounded to
2...8. Ordinary tier assignment sorts once by durable population ordinal and
uses bounded window membership rather than pairwise population scans.

The default transition-history cap is 128, migration-history cap is 64,
concurrent-migration cap is exactly one and route length is at most 32 (hard
configuration maximum 64). Terminal histories compact oldest-first and retain
explicit eviction counts. Active migration authority cannot be evicted.
Settlement resident/transit projections are bounded by settlement and population
capacity. The 128-resident tiered proof retained 128 transition rows, evicted
96 older rows and restored byte-for-byte with deterministic digest
`6549c1168c52cffb`.

## Gate D and Gate E continuity

Scaled inhabitants are full session inhabitants, not anonymous statistics. The
focused selector preserves a founder's heterogeneous age/memory context and
tests existing lifecycle removal against settlement/fidelity cleanup. It also
tests checkpoint/restart while population, identity and lifecycle semantics
remain coherent. No birth or death is fabricated for the live proof.

The economic continuity proof gives the migrant founder an exact Material
Rights asset and live durable contract obligation. Tier rotations, migration
and restore leave the unique asset, ownership/custody distinction, production
provenance, obligation, current commitment and histories coherent. The four
published Gate E Blocker selectors and all production/barter/contracts/markets
regressions pass. Fidelity records never contain inventories, assets,
commitments, receipts or price rows and cannot overwrite newer LIVE physical
truth.

## Observer

Observer schema 12 is emitted when population scaling is enabled; older
configurations retain their established schema. The read-only projection adds:

- stable settlements with current resident/transit IDs;
- total population and `LIVE` / `NEAR` / `DORMANT` counts;
- each selected inhabitant's stable ID, current settlement and fidelity;
- bounded transition and migration evidence plus eviction/work counters;
- a deterministic population-scale digest.

Observer cannot select tiers, start migration, change residence or mutate the
session. Focused byte comparisons and the decisive campaign both report zero
Observer mutations.

## Measured scale baseline

Command:

```text
/usr/bin/time -l .build/debug/PebbleLab \
  --scenario population_scaling_fidelity_smoke \
  --seed 139 --ticks 64 \
  --out /tmp/pebble-civ39-scale-final-v2
```

Environment: macOS 26.5.2 (Build 25F84), 8 logical CPUs, 16 GiB RAM,
SwiftPM debug build, monotonic `DispatchTime`, seed 139. Each configuration
retains two settlements, exact population count, schema 35 and an exact
fresh-session restore. Times are a reproducible local baseline, not universal
performance guarantees.

| population | mode | LIVE/NEAR/DORMANT | tick wall | CPU user/system | checkpoint | restore | representative peak RSS |
| ---: | --- | --- | ---: | ---: | ---: | ---: | ---: |
| 24 | full | 24/0/0 | 929,912,166 ns | 775,742 / 16,697 us | 2,314,115 B | 344,802,500 ns | 63,504,384 B |
| 24 | tiered | 4/12/8 | 64,959,375 ns | 63,963 / 845 us | 604,954 B | 88,877,750 ns | 65,830,912 B |
| 64 | full | 64/0/0 | 4,799,033,500 ns | 4,726,800 / 50,680 us | 6,170,730 B | 898,405,000 ns | 115,277,824 B |
| 64 | tiered | 4/12/48 | 90,911,167 ns | 89,964 / 564 us | 720,591 B | 104,888,959 ns | 115,884,032 B |
| 128 | full | 128/0/0 | 18,843,901,209 ns | 18,466,941 / 256,577 us | 12,471,087 B | 1,786,679,750 ns | 194,985,984 B |
| 128 | tiered | 4/12/112 | 130,089,708 ns | 128,029 / 1,575 us | 897,553 B | 129,098,375 ns | 195,444,736 B |

For the 128 tiered run, 64 ticks produced 256 LIVE cognition executions, 192
NEAR and 448 DORMANT maintenance executions, skipped 7,936 full-cognition
executions and retained all 128 inhabitants. The corresponding full run
performed 8,192 LIVE cognition executions. The complete six-configuration
process took 31.27 s real, 30.48 s user and 0.45 s system; `/usr/bin/time`
reported maximum RSS 195,444,736 bytes and peak memory footprint 116,146,920
bytes. RSS is process-cumulative and restore uses an explicit 32 MiB worker
thread, so it is representative rather than a per-configuration isolated peak.

## Focused and owning validation

The dedicated selector is:

```text
PEBBLELAB_SMOKE_ONLY=civ-39 .build/debug/pebsmoke
```

Result: **49/49 PASS**. It covers positive multi-settlement/tier behavior,
determinism, restart, active migration, Core replanning, stale/duplicate
authority, invalid/dead participant refusal, economic/lifecycle continuity,
Observer immutability, history compaction and work bounding.

Owning regression results:

| selector | result |
| --- | ---: |
| autonomous-civilization | 36/36 PASS |
| lifecycle | 80/80 PASS |
| material-rights | 23/23 PASS |
| production | 36/36 PASS |
| barter | 56/56 PASS |
| contracts | 32/32 PASS |
| markets | 31/31 PASS |
| checkpoint-replay | 49/49 PASS |
| persistence-reconciliation | 19/19 PASS |
| observer | 20/20 PASS |
| candidate-physical-atomicity | 3/3 PASS |
| embodiment | 756/756 PASS |
| gate-e-blocker-01 | 27/27 PASS |
| gate-e-blocker-02 | 33/33 PASS |
| gate-e-blocker-03 | 25/25 PASS |
| gate-e-blocker-04 | 28/28 PASS |

The corrected candidate passes the canonical `scripts/verify-pebblelab.sh`:
**35/35 steps and 4,064/4,064 smoke assertions PASS**. This includes debug and
optimized product builds, deterministic scenario pairs, canonical output/replay
comparisons and repository hygiene. No golden is regenerated and no proof is
weakened.

The first canonical-gate attempt exposed an optimized-build arithmetic trap in
the legacy `Int.max` clock-overflow regression: initial scale scheduling used
an unchecked `tick + 1` before the existing checked clock transition. Commit
`c06bcda12f2c56ab4cefea7cca200bb2d547f379` moves tier scheduling behind
`clock.nextTick()`. The full debug suite then passed 4,064/4,064 and the
optimized gate rerun passed all 35 steps from the corrected candidate; the
failed attempt is retained as diagnostic evidence rather than counted as a
PASS.

## Fresh live/visual proof

The canonical launcher dry-run and fresh disposable campaign use:

```text
scripts/verify-pebblelab-live.sh --civ39 --dry-run
scripts/verify-pebblelab-live.sh --civ39
```

The decisive campaign uses world seed 46, disabled dynamics, two fresh
processes and six inspected captures. Normal product code performs the migration
after prepared bootstrap. The proof visibly shows two settlements, 12 exact
physical inhabitants, 4/4/4 tiers, stable `agent_0` identity, a verified
settlement-main to settlement-east migration, tier change, checkpoint, fresh
restore, global Observer inspection and exact cleanup.

```text
CIV39_LIVE_PROOF_PASS settlements=2 population=12 live=4 near=4 dormant=4
migration=arrived identity=agent_0 identityStable=1 checkpointSchema=35
observerSchema=12 observerMutations=0 restartCount=1
restartDuplicateEffects=0 duplicateInhabitants=0
duplicateDurableIdentities=0 duplicateEconomicCommitments=0
duplicateReceipts=0 physicalLoss=0 physicalDuplication=0
syntheticMaterial=0 unexpectedRuntimeErrors=0 probes=12
```

All decisive harnesses exit successfully. Captures inspected are setup,
transition, pre-restart, restored, proof and cleanup. Cleanup stops the session,
removes exactly 12 probes and leaves no residual process.

## Limitations and non-claims

- V1 proves infrastructure with two settlements; it does not infer a city,
  kingdom, faction, culture, citizenship, government, law or territorial
  ownership.
- Coarse tiers currently perform bounded cadence work only. They do not invent
  exact production, inventory, market settlement, crafting, combat or travel.
- V1 supports one active settlement migration and a short bounded route; it is
  not a general long-distance transport, logistics or inter-settlement economy.
- Settlement removal/merge and full lifecycle-aware bulk admission are not V1
  operations. Additional residents are admitted before lifecycle/social domain
  authorities are enabled; existing inhabitants retain those authorities
  through the no-addition continuity path.
- The scale results describe one debug build on one machine. They establish a
  factual baseline and demonstrate bounded work/state, not a service-level or
  cross-platform guarantee.
- CIV-38 remains optional and unstarted. CIV-40 is not implemented. Gate F is
  not evaluated or acquired by this phase candidate.
