# CIV-31 — Childhood, Guardianship and Social Development V2

## Verdict and baseline

`CIV-31` is complete in its bounded contract as a local review candidate. It
was implemented from the published canonical baseline:

```text
2cdf5d9c89e9e54e79dd6e9bf627a5cee2303851
```

The phase history and final validation correction are separated into these
reviewable commits:

```text
abe1d72  Implement durable childhood guardianship V2
49e05e9  Add rendered CIV-31 restart campaign
cb3f8f3  Bind guardianship to physiological availability
82f3e66  Close CIV-31 documentation
203922d  Enforce available caregivers and verified supervision
```

This report intentionally does not self-reference its containing documentation
commit. Gate R, Gate B and `V4-GATE-C-v1` remain acquired and published.
`V4-GATE-D-v1` and
`V4-MILESTONE-RENEWABLE-SUBSISTENCE-v1` remain planned. `CIV-32` is not
started and is the next eligible phase.

## Reused authorities

`CIV-31` extends the existing `AgentSimulationSession` aggregate and Dependent
Care V1. It adds no second care queue, kinship graph, household owner, trust
score, teaching system, skill system, health model or World persistence
engine.

The permanent distinctions remain:

```text
genetic progenitor
!= canonical kinship parent
!= household member
!= durable guardian
!= current caregiver
!= teacher
!= physical custodian
!= recognized owner
```

Lifecycle remains authoritative for age and stage. Kinship owns canonical
parentage. Households own membership. Dependent Care owns needs, assignments,
engagements and outcomes. Pebble verifies physical movement and nourishment.
Teaching and Skills remain the only learning and practice authorities.

## Guardianship contract

- Childhood V2 is explicitly enabled only after Dependent Care. Its live
  configuration bounds retained guardianships to 256, active dependents per
  guardian to 4, social profiles to 64, retained exposures to 512, exposures
  per child to 64 and transitions per tick to 64.
- Each dependent has at most one active primary guardian. The durable record
  carries the child, guardian, household, assignment basis, start/end ticks,
  causal events, status and end reason. Ended history is retained under the
  explicit bound and deterministic eviction counter.
- Allowed foundations are `canonicalParent`, `kinshipRelative`,
  `householdAdult`, `explicitReassignment` and
  `emergencyHouseholdFallback`.
- Automatic selection considers only living, physiologically available,
  mature, resident, same-household adults. It ranks canonical parents, then
  kin, then other household adults; equal candidates use current bounded
  guardian load and stable `AgentID` order. Genotype, phenotype, wealth,
  profession, skill and display names are not inputs.
- Birth applies that same physiological-availability predicate before any
  child authority publishes. A parent with positive health but CIV-29
  `incapacitated` or `dead` status is ineligible; the other canonical parent
  may be selected normally. If both parents are unavailable, the bounded
  birth contract refuses atomically rather than inventing a caregiver.
- Delegation changes the active care executor without rewriting guardian,
  parentage or household. Explicit guardian reassignment ends the previous
  responsibility and starts a causal same-household responsibility; it does
  not teleport the child.
- Tick-boundary, incapacity and death replacement receive the candidate care
  and childhood authorities plus projected loads explicitly. Once a
  replacement guardian exists in that candidate state, caregiver selection
  sees and prefers that exact guardian; it never falls back to the stale
  published `dependentCareState`.
- Guardian death, durable incapacity, household separation, explicit
  reassignment, child death and maturity end the active responsibility. A
  deterministic replacement is sought. If none exists, the child is
  explicitly at risk, care needs remain visible and no adult is invented.

Normal birth remains one candidate transaction. The child, population and
lifecycle records, canonical parentage, household membership, inherited
genotype, dependent-care assignment, guardian responsibility, initial social
profile and causal provenance either publish together or do not publish.

## Care, time and material truth

- Supervision reuses the existing care engagement. Its durable bounded
  progress records verified engaged ticks, the last evaluated and verified
  ticks, verified caregiver/dependent positions, interrupted ticks and the
  last interruption. One tick counts only when the matching need and
  assignment remain active, the caregiver remains physiologically available,
  caregiver and child are in bounded range, and the caregiver's current
  activity is `supervise_dependent`. A tick is evaluated at most once.
- The interruption policy is deterministic pause: distance, incompatible
  activity or unavailable care records an interrupted tick without increasing
  verified progress. Returning to valid supervision resumes from the
  persisted count. Completion requires the configured two verified ticks;
  elapsed wall or simulation time alone cannot resolve the need or advance
  social development.
- An active care engagement wins the existing urgent activity band and
  occupies the caregiver rather than running as a free parallel effect.
  Critical physiology can still interrupt it through existing availability
  rules.
- Physical nourishment remains:

  ```text
  open care need
  → PebbleAgents intent
  → real Pebble custody and proximity validation
  → exact PebbleCore item debit
  → verified receipt
  → physiological and care outcome publication
  ```

  A missing item produces no hunger change, receipt, skill credit or social
  exposure. A used receipt cannot resolve or expose twice.
- The existing movement and navigation boundaries own approach and
  return-home behavior. Household or guardian transitions never substitute a
  physical teleport.
- Newborn and juvenile stage policy is enforced across productive autonomous
  activities, agriculture and teaching. A newborn cannot collect, work,
  reproduce, teach productively or become a guardian. A juvenile retains
  bounded observation, local movement, return-home, communication and
  supervised learning, but cannot use those paths to cross an adult material
  gateway. Maturity closes active childhood dependency without deleting its
  history or inventing a profession.

## Social Development V2

The authoritative bounded projection contains six dimensions:

```text
guardianContinuity
stableCareExposure
supervisedInteraction
teachingExposure
successfulPracticeExposure
unmetCareExposure
```

Every dimension is clamped to the configured basis-point bound and each
retained exposure records its child, dimension, positive delta, resulting
value, tick, participant, source event and transition event. The source must
be a real matching guardianship, resolved care, teaching, guided-practice or
unmet-care event. Opening Observer or merely advancing a tick grants no
exposure.

Autonomy readiness is a read-only bounded projection of lifecycle stage and
these exposures. It cannot override a stage prohibition.

Social development is not genotype, phenotype, physiological development,
trust, knowledge, skill, personality or status. Care does not silently create
a trust edge. A teaching observation advances only teaching exposure; it does
not grant skill. A guided-practice exposure can exist only after the student's
real successful practice has passed through the existing Teaching and Skills
authorities.

## Atomicity, mortality and corruption refusal

Public guardian assignment, reassignment, delegation, timed supervision,
physical nourishment, social-development changes, household reconciliation,
death handling and maturity use candidate-session publication or the existing
Pebble physical rollback boundary.

Validation refuses, before publication:

- duplicate active guardians or guardian capacity overflow;
- a guardian equal to the dependent, absent from population, non-resident,
  physiologically incapacitated, dead, non-mature or in another household;
- a basis inconsistent with canonical parentage or kinship;
- an unknown social profile, duplicate dimension, out-of-range value,
  incoherent counter or exposure without its matching causal source;
- care engagements without the existing need and caregiver authority;
- supervision progress that is negative, unbounded, future-dated,
  double-counted or inconsistent with its verified/interrupted positions and
  ticks;
- an active engagement whose assignment ended or whose caregiver is no longer
  physiologically available;
- reused physical-care receipts;
- adult actions by a newborn or juvenile;
- social change after the child's causal death boundary.

Guardian death first terminates care and guardianship, then seeks an eligible
survivor while excluding every lethal agent in the same boundary. Child death
closes care and guardianship and preserves history. Physical material exit
remains owned by CIV-29; `CIV-31` creates no estate or inheritance.

## Persistence and observation

Checkpoint/replay schema 24 persists the complete childhood state, bounded
verified-supervision progress, and the typed enable, delegation,
guardian-reassignment and supervision-tick operations. Round-trip and replay
restore byte-identical guardian basis, care state, progress, social
dimensions, causal sequence and digest. No care outcome, food consumption,
exposure, assignment or supervision tick is duplicated.

Schema 23 remains readable. Because it did not carry protected verified
supervision progress, a legacy active supervision engagement decodes with
zero verified and interrupted ticks and receives no elapsed-time credit. It
must earn schema-24 progress through real post-load activity before
completion.

The schema-22 manifest-integrity and protected empty-probe rule remains in
force for schema 24. A persistent child absent from the three-founder
bootstrap can be recreated only from an intact, versioned manifest attesting
empty carried custody. The World, session and controller indexes validate
before publication.

Observer schema 4 adds bounded read-only childhood, guardianship, care and
social-development projections. The UI computes no selection, need, outcome
or readiness rule. Repeated observation preserves the tick, causal sequence
and durable digest exactly.

## Deterministic evidence

Commands executed after the final product change:

```text
PEBBLELAB_SMOKE_ONLY=childhood-guardianship swift run pebsmoke
62 passed, 0 failed

PEBBLELAB_SMOKE_ONLY=dependent-care swift run pebsmoke
55 passed, 0 failed

PEBBLELAB_SMOKE_ONLY=lifecycle swift run pebsmoke
80 passed, 0 failed

PEBBLELAB_SMOKE_ONLY=checkpoint-replay swift run pebsmoke
49 passed, 0 failed

PEBBLELAB_SMOKE_ONLY=homeostasis-health swift run pebsmoke
30 passed, 0 failed

PEBBLELAB_SMOKE_ONLY=observer swift run pebsmoke
20 passed, 0 failed

scripts/verify-pebblelab.sh
3483 passed, 0 failed
35/35 verification steps
exit status 0
```

Focused coverage includes normal and non-parent guardian selection,
birth-time physiological exclusion and recovery, candidate-state
guardian/caregiver equality after incapacity and death, delegation,
reassignment, at-risk behavior, verified supervision, interruption and
duplicate-tick refusal, orphan-engagement rejection, exact physical food
publication, load and activity bounds, adult-gateway refusal, maturity,
mortality, Observer immutability, schema-24 restore/replay, fail-closed
schema-23 compatibility and adversarial corruption.

## Rendered two-process restart evidence

Command:

```text
scripts/verify-pebblelab-civ31.sh
```

Result: **PASS**, exit status 0.

The campaign used a disposable World, seed 46 and two
separate Pebble processes:

```text
process 1:
  normal reproduction and birth of agent_3
  → canonical parents agent_0 and agent_1 remain unchanged
  → agent_0 becomes guardian by canonicalParent basis
  → supervision earns exactly one verified tick at tick 5
  → physical separation at tick 6 records one interruption and no progress
  → no supervision exposure publishes before the verified minimum
  → schema-24 checkpoint persists verified=1 and interrupted=1
  → protected empty-child attestation is integrity-bound
  → process terminates and removes four transient probes

process 2:
  same SaveDB World and schema-24 checkpoint load
  → manifest integrity v1 verifies
  → missing agent_3 probe is restored only from protected empty custody
  → same session, child, guardian, household, genotype, childhood digest
    and verified/interrupted progress
  → return-home and nourishment activities add interrupted ticks, not
    supervision progress
  → one real bread item is debited 1 → 0
  → supervision resumes at tick 10 and reaches verified=2 exactly
  → the engagement resolves once and one supervision exposure publishes
  → normal household separation ends the guardian and caregiver
  → no eligible replacement leaves agent_3 explicitly at risk
  → parentage, genotype and child position remain unchanged
  → maturity closes dependency and retains history
  → both proof checkpoints are deleted and four probes are removed
```

Compact facts:

```text
World identity: wms7c0ey53nzo
session identity: live-46-14-66--21
parents: agent_0, agent_1
child: agent_3
guardian before separation: agent_0 / canonicalParent / household_0
current caregiver before separation: agent_0
child genotype: genotype-agent_3-v1-7eb9e1b0ffbd955e
child stage: newborn → juvenile → mature
supervision at save: elapsed 1 / verified 1 / interrupted 1
supervision at completion: elapsed 5 / verified 2 / interrupted 4
supervision completion count: 1
supervised-interaction exposure count: 1
physical food: bread 1 → 0
physical receipt: physical-care:live-46-14-66--21:agent_0:agent_3:160
social at restart: guardian 100, supervision 0, stable care 0
social after verified completion: supervision 140
childhood digest at restart: f98aa76af32c0584, exact
manifest integrity: v1 / 85dabc4d7a11088e2d57d04cbd0d17f5a19385b54797a50210df01c3ae7690cf / verified
restored child probe: restored_verified:agent_3
separation: householdSeparated → no replacement → atRisk
unmet-care exposure after separation: 150
trust edges: 0 → 0
teaching exposures: 0 → 0
caregiving skill: one unit from the real care action only
care outcome count: 3 → 3
physical consumption count: 1 → 1
duplication count: 0
Observer mutation count: 0
runtime errors: 0
cleanup: exact
```

The four native-resolution captures were individually inspected:

```text
civ31-parental-guardian-active-need.png
civ31-real-care-social-development.png
civ31-same-child-after-restart.png
civ31-verified-supervision-complete.png
```

They show a coherent rendered World and readable Observer schema-4 state for
the active parental guardian, interrupted care, the exact restarted child and
the single verified-supervision completion. No visual corruption or
contradictory authority was found.

## Limits

`CIV-31` does not prove or introduce:

- legal adoption, a general legal guardianship system or child-protection
  institutions;
- personality, intelligence, trauma, mental illness or genetic social traits;
- general schooling, a complete education system or skill without practice;
- automatic trust, profession, ownership, status or reproductive authority;
- unions, marriage, family relations V1, surnames, lineages, clans, dynasties
  or houses (`CIV-32`);
- estates, inheritance, succession or parent-to-child material transfer
  (`CIV-33`);
- renewable subsistence or `V4-GATE-D-v1`.

Gate D and its required renewable-subsistence milestone remain planned and
unevaluated.
