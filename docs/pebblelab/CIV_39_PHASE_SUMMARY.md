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
previous reviewed candidate: e2de172c5ac8b2a14c67341d4b3b6fa0147c2f00
Senior Review Correction 01 product/proof commit: 2c9dc3fb4d2124b184ea81709a1165adc1831964
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

## Senior Review Correction 01 — mortality composition

Senior review found one composition defect in reviewed candidate
`e2de172c5ac8b2a14c67341d4b3b6fa0147c2f00`. The published mortality
finalizer removed a deceased inhabitant from `populationRegistry.members`, the
legacy main-settlement projection and `statesById`, but did not compose the new
CIV-39 additional-settlement, current-fidelity or settlement-migration
authority.

The defect was reproduced before correction through normal starvation and
mortality transitions. Main-settlement, DORMANT, post-arrival and active
settlement-migration deaths all finalized, while the focused selector reported
**53 PASS / 5 FAIL**: current scale authority remained and schema-35 restore
failed closed rather than accepting it.

Commit `2c9dc3fb4d2124b184ea81709a1165adc1831964` keeps the existing mortality
transition as the sole lifecycle owner and extends its atomic candidate
publication to:

- terminate one active CIV-39 settlement migration as `failed/memberDied`,
  with a typed causal event, exact failure tick and event ID;
- remove the deceased from every current settlement resident/transit
  projection and from current fidelity records;
- preserve bounded terminal migration and fidelity-transition history without
  treating it as current membership;
- validate terminal history against retained or compacted mortality identity
  authority;
- preserve Gate D death/lifecycle evidence and Gate E verified terminal
  physical custody, ownership and provenance;
- reject a partial result before publication if any cross-domain invariant
  fails.

No second mortality API, lifecycle owner, World effect or schema beyond 35 was
introduced. The local candidate remains unpublished and awaits renewed senior
review.

## Bounded product result

The V1 adds two or more durable settlement records, real persistent residents,
deterministic `LIVE` / `NEAR` / `DORMANT` execution tiers, one-at-a-time
causal migration, schema-35 restart, Observer schema 13 and a reproducible
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
- mortality/population exit removes current membership from every settlement
  and current fidelity authority while preserving existing lifecycle and
  bounded terminal transition history;
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

Death remains owned by the existing mortality transaction at every fidelity.
If death occurs in transit, the migration becomes terminal `failed/memberDied`
exactly once, both origin/destination current projections are cleared and no
restart can later publish arrival. Death after arrival retains the bounded
historical `arrived` record but removes that person from current destination
membership.

## Persistence and restart

Checkpoint schema advances from 34 to 35 only when the population-scale state
is enabled. Legacy configurations continue encoding their established schema.
Schema 35 retains:

- all durable inhabitants and stable identities;
- all settlements and unique current memberships;
- fidelity configuration, records, scheduler offset and work counters;
- bounded fidelity-transition and migration histories plus eviction counters;
- in-flight migration route/cursor and causal IDs when applicable;
- terminal scaled-death migration failure reason/tick/event evidence;
- all existing Gate D lifecycle and Gate E material/economic state.

Restore validates the whole candidate before publication. It refuses duplicate
membership, duplicate or missing fidelity references, impossible current
migrations, invalid bounds and contradictory settlement projections. Exact
World probes remain under Pebble reconciliation: a fresh process reacquires
current World truth, restores or repositions only through verified physical
operations, and performs no duplicated civilization transition or economic
effect.

The original decisive rendered campaign restored schema 35 once with 12 exact
probes, nine absent probes restored, two positions reconciled, zero custody
duplicates and `restartDuplicateEffects=0`.

Correction 01 adds a separate two-process headless proof. Process one finalizes
death during an active migration and writes a 123,450-byte schema-35
checkpoint. A second OS process restores and advances eight ticks: the deceased
remains absent from active states, all settlement membership and current
fidelity; the migration remains terminal exactly once; death count remains one;
late arrivals, duplicate effects and physical anomalies remain zero.

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
now drives real mortality for main-settlement, DORMANT, post-arrival and active
migration inhabitants. Death history and demographic age/stage remain durable;
the lifecycle member and all current scale authority are removed atomically.
Fresh restore retains this history without a second death or arrival. No birth
or death is fabricated for the rendered proof.

The economic continuity proof gives the migrant founder an exact Material
Rights asset and live durable contract obligation. Tier rotations, migration
and restore leave the unique asset, ownership/custody distinction, production
provenance, obligation, current commitment and histories coherent. The four
published Gate E Blocker selectors and all production/barter/contracts/markets
regressions pass. Fidelity records never contain inventories, assets,
commitments, receipts or price rows and cannot overwrite newer LIVE physical
truth.

Correction 01 additionally kills an inhabitant holding one exact Material
Rights asset through the verified terminal custody path. The physical receipt
moves custody to one container while recognized ownership/provenance remain
singular; current settlement/fidelity state is removed; schema-35 restart is
byte exact. There is no physical loss, duplication, synthetic material,
duplicate commitment, receipt or settlement.

## Observer

Observer schema 13 is emitted when population scaling is enabled; older
configurations retain their established schema. The read-only projection adds:

- stable settlements with current resident/transit IDs;
- total population and `LIVE` / `NEAR` / `DORMANT` counts;
- each selected inhabitant's stable ID, current settlement and fidelity;
- bounded transition and migration evidence plus eviction/work counters;
- typed terminal migration failure reason, tick and causal event evidence;
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

Correction 01 refreshed the same six configurations after mortality
composition using:

```text
.build/debug/PebbleLab --seed 139 --ticks 16 \
  --scenario population_scaling_fidelity_smoke \
  --out /tmp/civ39-correction-01-scale.h25HPS
```

Environment remained macOS 26.5.2 (Build 25F84), 8 logical CPUs, 16 GiB RAM,
SwiftPM debug, monotonic `DispatchTime` and Darwin `getrusage`. All assertions,
schema-35 restores and deterministic byte/digest comparisons passed.

| population | mode | LIVE/NEAR/DORMANT | tick wall | CPU user/system | checkpoint | restore | representative peak RSS |
| ---: | --- | --- | ---: | ---: | ---: | ---: | ---: |
| 24 | full | 24/0/0 | 90,510,500 ns | 89,097 / 978 us | 726,122 B | 147,415,500 ns | 34,111,488 B |
| 24 | tiered | 4/12/8 | 12,440,291 ns | 12,278 / 102 us | 208,478 B | 30,966,709 ns | 35,127,296 B |
| 64 | full | 64/0/0 | 463,179,250 ns | 457,034 / 3,916 us | 1,966,354 B | 271,252,042 ns | 58,081,280 B |
| 64 | tiered | 4/12/48 | 18,727,958 ns | 18,475 / 147 us | 322,084 B | 48,077,375 ns | 59,932,672 B |
| 128 | full | 128/0/0 | 1,647,300,333 ns | 1,618,610 / 21,809 us | 3,999,871 B | 545,528,083 ns | 94,781,440 B |
| 128 | tiered | 4/12/112 | 29,041,791 ns | 28,539 / 420 us | 502,942 B | 73,574,250 ns | 94,928,896 B |

At population 128, the tiered run performed 64 LIVE cognition executions,
skipped 1,984 full-cognition executions, retained 128 inhabitants and a bounded
128 transition rows, and evicted 24 older rows. These are one-machine facts,
not universal performance guarantees.

## Focused and owning validation

The dedicated selector is:

```text
PEBBLELAB_SMOKE_ONLY=civ-39 .build/debug/pebsmoke
```

Correction 01 result: **69/69 PASS**. The pre-correction reproduction was
**53 PASS / 5 FAIL** and is retained as diagnostic evidence. The corrected
selector covers positive multi-settlement/tier behavior,
determinism, restart, active migration, Core replanning, stale/duplicate
authority, invalid/dead participant refusal, economic/lifecycle continuity,
Observer immutability, history compaction and work bounding. The 20 added
assertions cover main/additional/DORMANT death, active migration failure,
post-death rotation, schema-35 restart, Observer 13, Gate D history and Gate E
terminal custody.

Owning regression results:

| selector | result |
| --- | ---: |
| autonomous-civilization | 36/36 PASS |
| homeostasis-health | 30/30 PASS |
| genetics-development | 46/46 PASS |
| childhood-guardianship | 62/62 PASS |
| unions-family-lineages-houses | 83/83 PASS |
| lifecycle | 80/80 PASS |
| mortality | 93/93 PASS |
| estates-inheritance-succession | 88/88 PASS |
| dependent-care | 55/55 PASS |
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

Correction 01 ran 23 owning selectors for **1,711/1,711 PASS**. The corrected
candidate passes the canonical `scripts/verify-pebblelab.sh`: **35/35 steps and
4,084/4,084 smoke assertions PASS**. This includes debug and
optimized product builds, deterministic scenario pairs, canonical output/replay
comparisons and repository hygiene. No golden is regenerated and no proof is
weakened.

The first canonical-gate attempt exposed an optimized-build arithmetic trap in
the legacy `Int.max` clock-overflow regression: initial scale scheduling used
an unchecked `tick + 1` before the existing checked clock transition. Commit
`c06bcda12f2c56ab4cefea7cca200bb2d547f379` moves tier scheduling behind
`clock.nextTick()`. The original candidate's full debug suite then passed
4,064/4,064 and its optimized gate rerun passed all 35 steps; the
failed attempt is retained as diagnostic evidence rather than counted as a
PASS.

## Fresh live/visual and Correction 01 runtime proof

The canonical launcher dry-run and fresh disposable campaign use:

```text
scripts/verify-pebblelab-live.sh --civ39 --dry-run
scripts/verify-pebblelab-live.sh --civ39
```

The original candidate's decisive campaign used world seed 46, disabled dynamics, two fresh
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

Correction 01 dry-ran the updated canonical launcher successfully and updated
its governed expectation to Observer schema 13. The current CIV-39 rendered
mode explicitly has `PEBBLELAB_APP_AGENTS_MORTALITY=0`; it cannot exercise the
corrected mortality path. No rendered mortality success or fresh capture is
claimed.

The strongest supported decisive Correction 01 proof is therefore the fresh
two-process headless runtime pair:

```text
.build/debug/PebbleLab --seed 139 --ticks 16 \
  --scenario population_scale_mortality_exit_smoke --out <fresh-dir>
.build/debug/PebbleLab --seed 139 --ticks 16 \
  --scenario population_scale_mortality_restore_smoke --out <same-dir>
```

Both final processes exit zero. Machine reports record two settlements,
population 24 before/23 after, one real mortality transition, one terminal
`memberDied` migration and one failure event. After fresh-process restore and
eight further ticks: `LIVE/NEAR/DORMANT=4/8/11`, late arrivals 0, duplicate
inhabitants 0, duplicate memberships 0, Observer mutations 0, physical loss 0,
physical duplication 0 and synthetic material 0. Decisive Correction 01 proof:
**2 processes, 0 captures**.

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
- The existing rendered CIV-39 mode cannot enable mortality together with its
  prepared scale fixture; Correction 01 therefore uses a deterministic
  two-process headless proof and claims no fresh mortality capture.
- CIV-38 remains optional and unstarted. CIV-40 is not implemented. Gate F is
  not evaluated or acquired by this phase candidate.
