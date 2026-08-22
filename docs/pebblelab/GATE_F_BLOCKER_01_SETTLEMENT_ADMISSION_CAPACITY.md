# Gate F Blocker 01 — Per-Settlement Admission Capacity Publication Integrity

## Status

`V4-GATE-F-v1 Blocker 01: LOCAL BLOCKER-CORRECTION CANDIDATE`

This record documents the local product correction for the deterministic
publication/persistence split found by independent Gate F Evaluation 01. It
does not rewrite or supersede that evaluation, claim publication, authorize
Evaluation 02, acquire Gate F, or begin CIV-40 or CIV-41.

- Gate F Evaluation 01: `FAIL — HISTORICAL IMMUTABLE EVIDENCE`
- Gate F Blocker 01: `LOCAL BLOCKER-CORRECTION CANDIDATE`
- Gate F: `PLANNED — NOT ACQUIRED`
- Gate F Evaluation 02: `NOT AUTHORIZED / NOT PERFORMED`
- CIV-40: `OPTIONAL TOOLING — NOT STARTED`
- CIV-41: `NOT STARTED`

## Git and evaluation identity

```text
evaluated published baseline: 29c8a7328f06748817abba1545acdb259a4d192a
correction branch: codex/gate-f-blocker-01-settlement-capacity
product/test/runtime-proof commit: 54c5f4e9d1acab06a0fc44b2cd96dc74c04c72ec
evaluation branch: codex/gate-f-evaluation-01
evaluation harness commit: 8f519d1ee9a8387117447057aa50b471b487143a
evaluation final evidence HEAD: 1cd056b6f74b4334cc6f63e969f3b629b3d79ae2
evaluation review archive SHA-256: 107d10073892a85fc2200f34158ad7adf9ecfcb23bbae218ff54db64d067be7a
evaluation verdict: FAIL — HISTORICAL IMMUTABLE EVIDENCE
evaluation commits in correction ancestry: NO
publication verified: NO
```

Both evaluation ancestry checks return exit `1` from
`git merge-base --is-ancestor`. The correction descends directly from the
evaluated published baseline and does not contain the evaluation harness or
evidence commits.

## Historical failure

The public `initializePopulationScaling` boundary validated settlement IDs,
positive capacities, empty new membership projections, unique new identities,
target existence and the global active-population maximum. It did not compare
the complete batch of admissions for each destination with that settlement's
declared capacity.

It then appended every admitted identity to the destination's `residentIDs`.
The product could therefore publish and checkpoint two residents in a new
settlement whose capacity was one. Schema-35 checkpoint creation succeeded,
but fresh restore correctly rejected that product-created state with
`AgentCheckpointError.invalidBound("population settlement")`.

The minimized historical diagnostic was:

```text
GATE_F_EVALUATION_01_BLOCKER_REPRO
kind=settlementCapacityPublication
capacity=1
publishedResidents=2
initializationAccepted=1
authoritativeStateMutated=1
checkpointCreated=1
restoreRejected=1
restoreError=invalidBound(population_settlement)
deterministicDigest=a73b4ad8124effd4
```

## Corrected publication authority

`AgentPopulationRegistry` now owns one shared current-resident capacity
predicate. It evaluates every registered settlement, including the existing
main settlement, against:

```text
authoritative current resident count
+ complete proposed admission count for that settlement
<= declared settlement capacity
```

`initializePopulationScaling` constructs only a local capacity candidate that
contains the sorted additional settlements, then applies this predicate to the
complete sorted admission batch before causal-capacity prevalidation or any
candidate event, settlement, state, member, resident, fidelity or ordinal
publication. The schema-35 registry validator applies the same predicate with
zero proposed admissions. This keeps publication-time and restore-time
resident-capacity authority aligned without a second capacity owner.

The independent global `maximumActivePopulation` check remains in place and is
performed separately. Settlement capacities are neither increased nor
reinterpreted. In-transit membership retains its existing migration authority;
the unchanged durable invariant bounds current `residentIDs`.

## Atomic refusal and determinism

The public copy-candidate/self-assignment transaction remains unchanged. A
local-capacity failure occurs before the first candidate causal append. The
dedicated regression proves exact pre-call equality for:

- authoritative durable bytes;
- `AgentSessionAgentState` inhabitants and durable identities;
- population member records and settlement resident/transit projections;
- scale state and fidelity records;
- causal events;
- `nextPopulationOrdinal`.

One over-capacity destination rejects the whole multi-settlement batch. No
synthetic rollback event is emitted because no candidate publication begins.
A subsequent valid retry is byte-identical to the same valid request on a
fresh equivalent session, proving no ordinal or event gap. Admission input is
sorted by stable `AgentID`, and reversed caller order produces identical
durable bytes.

## Focused product proof

The dedicated selector is:

```text
PEBBLELAB_SMOKE_ONLY=gate-f-blocker-01 .build/debug/pebsmoke
PEBBLELAB_SMOKE_ONLY=gate-f-blocker-01 .build/release/pebsmoke
```

Both debug and optimized executions pass `20/20`. The proof covers:

- capacity one with exactly one admission;
- the historical capacity-one/two-admission refusal;
- capacity N with N and N+1 admissions;
- multiple independently fitting settlements;
- mixed main/additional-settlement admission;
- one over-capacity destination causing whole-batch refusal;
- the global maximum rejecting a batch whose local destinations fit;
- duplicate identity and invalid destination behavior remaining unchanged;
- deterministic caller-order independence;
- exact durable, causal and ordinal atomicity;
- valid retry without gaps;
- schema-35 checkpoint and exact fresh restore.

The existing main settlement's capacity equals the population configuration's
global maximum in the current model. The mixed-batch proof reaches four of
eight residents there, and the shared predicate evaluates it alongside every
additional destination. A separate global-bound case shows that the global
limit can still refuse even when main and both additional local counts fit.

## Persistence and two-process runtime proof

The durable shape is unchanged. Checkpoint schema remains `35`; Observer
schema remains `13` and read-only.

Two separate PebbleLab processes run:

```text
.build/debug/PebbleLab --seed 601 --ticks 0 \
  --scenario gate_f_blocker_01_capacity_exit_smoke --out <fresh-dir>
.build/debug/PebbleLab --seed 601 --ticks 0 \
  --scenario gate_f_blocker_01_capacity_restore_smoke --out <same-dir>
```

Process one creates a controlled three-founder registry, refuses the
capacity-one/two-admission batch with byte/event/ordinal equality, accepts one
valid retry and writes a schema-35 checkpoint. Process two loads that artifact
in a fresh OS process. Both reports carry authoritative digest
`fa9975402afd9f3d`.

```text
processes=2
checkpointSchema=35
observerSchema=13
settlements=2
population=4
duplicateInhabitants=0
duplicateDurableIdentities=0
duplicateMemberships=0
restartDuplicateEffects=0
observerMutations=0
physicalLoss=0
physicalDuplication=0
syntheticMaterial=0
unexpectedRuntimeErrors=0
```

The restored additional settlement contains exactly one resident at capacity
one. Inhabitants, population members, fidelity records and memberships are
singular and reference the same identity set. Observer inspection changes no
authoritative byte, and restore emits no causal transition effect.

## Regression evidence

Fresh focused and owning results:

| Surface | Result |
| --- | ---: |
| Gate F Blocker 01 debug | 20/20 PASS |
| Gate F Blocker 01 optimized | 20/20 PASS |
| CIV-39 | 69/69 PASS |
| population migration | 66/66 PASS |
| Gate D owning continuity | 1329/1329 PASS |
| Gate E owning continuity | 305/305 PASS |
| all 23 owning selectors | 1711/1711 PASS |
| Gate E Blocker 01 | 27/27 PASS |
| Gate E Blocker 02 | 33/33 PASS |
| Gate E Blocker 03 | 25/25 PASS |
| Gate E Blocker 04 | 28/28 PASS |
| canonical repository verification | 35/35 steps; 4104/4104 assertions PASS |

The owning total includes embodiment/Core descent, autonomous civilization,
lifecycle, mortality, estates/inheritance/succession, homeostasis, genetics,
childhood, unions/family/lineages/houses, dependent care, material rights,
production, barter, contracts, markets, checkpoint/replay,
persistence/reconciliation, Observer and candidate physical atomicity.

Canonical `scripts/verify-pebblelab.sh` verification passes all `35/35` steps
with `4104/4104` smoke assertions. No golden is regenerated.

## Limitations and non-claims

- This is a local candidate, not a published correction.
- Gate F Evaluation 01 remains immutable historical FAIL evidence.
- Gate F is not acquired.
- Evaluation 02 is not performed or authorized by this candidate. It can be
  considered only after manual publication and independent remote SHA
  verification of the blocker correction.
- CIV-40 and CIV-41 are not started.
- No rendered campaign is claimed. This validation-only initialization and
  persistence authority defect is proven by deterministic headless and
  fresh-process evidence.
- No schema, settlement-removal, merge, lifecycle bulk-admission or migration
  semantics are added.
- Goldens are not regenerated and no historical evidence is modified.

The next authorized action is senior review of this local blocker-correction
candidate. Publication, independent remote verification and any later
Evaluation 02 require separate decisions.
