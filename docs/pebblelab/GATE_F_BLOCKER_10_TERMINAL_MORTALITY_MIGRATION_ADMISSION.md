# Gate F Blocker 10 — Terminal mortality migration admission

## Status and lineage

Gate F Evaluations 01–10 remain **FAIL — HISTORICAL IMMUTABLE
EVIDENCE**. Gate F Blockers 01–09 remain **FIXED + PUBLISHED + REMOTE
VERIFIED**. Gate F Blocker 10 is **FIXED — LOCAL CORRECTION CANDIDATE — NOT
PUBLISHED** at product/test/runtime commit
`470223bae3af44da29fd8830169ed14371dd3403`. Gate F remains **PLANNED — NOT
ACQUIRED**. Evaluation 11 is **NOT AUTHORIZED / NOT PERFORMED**. `CIV-40` is
**OPTIONAL TOOLING — NOT STARTED** and `CIV-41` is **NOT STARTED**.

The correction branch is rooted directly in published canonical baseline
`32c75984c56158bf9fde4918f6428e46cc7c1fa4`. Its merge base is that exact SHA.
No Evaluation 10 commit is an ancestor and no Evaluation 10 implementation or
harness commit was merged, rebased, cherry-picked or otherwise inherited.

Evaluation 10 remains immutable at these identities:

| Evidence | Commit |
| --- | --- |
| care/guardianship Attack 1 | `0884ae7651853d94fae34f6cea0eae318c6709f7` |
| mortality schema-35 Attack 2 | `36df11af2d535e15f091d0c2b7835785797eaf4f` |
| Attack 3 blocker | `b4792545dd0b585e3ad9739dcf2c950fa249d594` |
| authority and fresh-process evidence | `a8c9604c06a567d8b3921d6ce2031cbcc971d46b` |
| final evidence and report | `626ca8785f4e54d0e1f9c5ae8aec56dff22f7ed9` |

Its review archive
`PebbleLab-GateF-Evaluation10-Review-626ca87.zip` has SHA-256
`39104a2b01f2bbe393f3437faee1daa2892f81505827ad9911ab28a823430d49`.
Senior review independently accepted the archive and the blocker
classification `terminalMortalityPendingMigrationAdmission`.

## Defect and owning rule

Evaluation 10 reached the defect through supported public APIs at simulation
tick 4. Agent `agent_2` had health zero and persisted terminal Mortality
authority at `e74 mortalityMaterialExitPending`. The published product then
accepted a new public settlement migration at `e84
settlementMigrationStarted`, created
`settlement-migration-00000001`, advanced the migration ordinal from 1 to 2
and moved current authority from source residence to source `inTransit`.

The corrected rule is:

> When the owning Mortality state contains an
> `AgentPendingMortalityTransition` for an agent, that agent cannot acquire a
> new settlement-migration authority. A migration already started before the
> pending event remains valid and follows the existing mortality cleanup
> contract.

The rule is event/state based. It does not use health alone, tick equality or a
new clock. `AgentPendingMortalityTransition.pendingEventID` remains the exact
persisted causal boundary. The central
`beginSettlementMigrationInPlace` owner consults Mortality before capacity,
route, social, causal, identity or ordinal publication. Refusal uses the
existing `pendingMaterialExit` domain error, but the contract is the observable
atomic result rather than a new public error enum.

No checkpoint or Observer schema changed. Checkpoint schema remains 35,
Observer schema remains 13 and Estate successor-proof v1/v2 behavior is
untouched.

## Exact Evaluation 10 conversion

The fresh Blocker 10 fixture independently recreates the public Evaluation 10
trajectory without importing its harness commit. It reaches the same tick and
pending sequence:

| Fact | Corrected result |
| --- | --- |
| simulation tick | 4 |
| terminal event | `e74 mortalityMaterialExitPending` |
| agent / health | `agent_2` / 0 |
| attempted migration identity | `settlement-migration-00000001` |
| public admission | refused |
| `settlementMigrationStarted` after e74 | none |
| new migration record | none |
| next migration ordinal | 1 → 1 |
| source resident | retained |
| source `inTransit` | absent |
| destination resident / `inTransit` | absent / absent |
| durable bytes before/after refusal | byte-identical |
| checkpoint bytes before/after refusal | byte-identical |

Population ordinal 4, fidelity transition ordinal 5, household ordinal 2,
Family union/lineage/house ordinals 1/1/1, death count 0, Estate count 0 and
care/guardianship identities remain unchanged across refusal. Household,
Family, care, guardianship and fidelity authority are byte-exactly unchanged.
There is one population record, one current source residence, no current
migration and one fidelity owner for the agent. Observer inspection makes zero
mutations.

## Control matrix

| Control | Result |
| --- | --- |
| same-tick pending before admission | refused atomically; exact e74 fixture |
| previous-tick pending | not publicly reachable: `advanceTick` itself atomically refuses while terminal custody is unresolved; the subsequent same-tick migration request also refuses without mutation |
| healthy/non-terminal admission | accepted normally; one in-transit migration and ordinal 1 → 2 |
| migration before terminal pending | supported: migration e63, pending e76, `settlementMigrationFailed/memberDied` e93, death finalization e98 |
| care-protected guardian | existing refusal remains byte-atomic |
| finalized dead agent | structurally absent; public migration request refuses without mutation |
| immediate-death path | synchronous finalization leaves no public admission gap; later request refuses without mutation |

The inverse-order control starts while the agent is live with health 1. It
retains the existing migration until Mortality becomes authoritative, then
fails that migration with `memberDied` before one death and one Estate are
finalized. No current residence, migration or fidelity authority remains for
the dead agent.

## Public migration-admission audit

The bounded audit classified each product path that can establish population
or migration authority:

| Path | Classification |
| --- | --- |
| public `beginSettlementMigration` | **SAME B10 INVARIANT — FIXED** at its single in-place owner |
| Pebble CIV-39 physical route command | **CORRECTLY GUARDED**; it calls the same public session API on a candidate before publication |
| settlement-migration advance/arrival | **CORRECTLY GUARDED**; progresses an existing record and cannot create a new migration identity |
| checkpoint restore | **CORRECTLY GUARDED**; validates persisted authority and cannot admit a migration |
| external `admitMigration` | **NOT PUBLICLY REACHABLE — CONTRACT VERIFIED** for B10: it creates a new healthy outside migrant and cannot relocate an existing terminal actor |
| scaled-resident initialization | **NOT PUBLICLY REACHABLE — CONTRACT VERIFIED** with Mortality: additions are explicitly refused once Mortality, lifecycle or social authorities are active |
| dependent/household migration | **CORRECTLY GUARDED**; no separate migration creator exists and both policies prevalidate the central path |
| forced or scale-driven migration | **NOT PUBLICLY REACHABLE — CONTRACT VERIFIED**; no separate authority-creating API exists |
| immediate finalization | **CORRECTLY GUARDED**; the agent is removed synchronously before a later public request |

No separate reachable contradiction was found in terminal lifecycle,
dependent care, household, Family, destination capacity, fidelity scaling,
physical candidate publication, Material Rights or Estate adjacency.

## Fresh-process proof

Two independent three-process chains ran in debug and optimized. The complete
debug and optimized artifact trees are byte-identical.

### Pending before admission

Process 1 writes a legitimate pre-admission schema-35 checkpoint at tick 4,
pending sequence 74, source resident authority and next migration ordinal 1.
Process 2 restores byte-exactly, observes schema 13 read-only, refuses the
public migration with durable bytes and all tracked ordinals unchanged, then
resolves physical custody and finalizes one death and one Estate. Process 3
restores the final checkpoint byte-exactly with zero death replay, zero Estate
replay and no migration resurrection.

| Artifact | SHA-256 |
| --- | --- |
| pending pre-admission checkpoint | `a02563407c3cbbfd4c0346d81b2b5ed783d9f0efc2a781d3f7635b6dff478218` |
| pending pre-admission durable state | `ddcf309336764f858ca5d296e5c507707e24c37cc368ad091367e5a6972c6712` |
| pending post-finalization checkpoint | `569d442547dcf840a42552bffab8ab4c86f4409c7aae376e11895bb208d934e0` |
| pending post-finalization durable state | `ca40835afdba47160a508a1ed78ae3f083d3d4750c4e16da5696f5353c904cda` |

Finalization publishes `agentDeathFinalized` at e96. No migration-start or
migration-failure event exists because no migration was admitted.

### Migration before mortality

Process 1 begins migration at e63 while health is 1 and writes schema 35.
Process 2 restores byte-exactly, reaches pending e76, preserves the inverse
ordering, resolves custody, publishes `memberDied` failure e93 and death
finalization e98, then writes schema 35. Process 3 restores byte-exactly with
zero replay and no migration resurrection.

| Artifact | SHA-256 |
| --- | --- |
| inverse pre-mortality checkpoint | `c5d89638f47e65904c7855d90ca664173612cfa89950f48188d2eebc1d0c69de` |
| inverse pre-mortality durable state | `2ef4428074d468fb88018fa8f244090203240a3f97b693d8e59e451345314d87` |
| inverse post-finalization checkpoint | `a68149c4260e6dd13ed5793069afe23c4cf39ac0e071046bcce39001b1842ffd` |
| inverse post-finalization durable state | `7c00c7ca2d4cb690d620b4284b0f82f62b38c69c3d8e8c6da6e8153abe6490bd` |

## Validation

The dedicated Blocker 10 selector passes **20/20** in debug and optimized.
Each of the 12 fresh-process invocations passes 1/1. Published blocker
selectors pass in both configurations:

| Selector | Debug | Optimized |
| --- | ---: | ---: |
| B09 | 32/32 | 32/32 |
| B08 | 28/28 | 28/28 |
| B07 | 26/26 | 26/26 |
| B06 | 28/28 | 28/28 |
| B05 | 27/27 | 27/27 |
| B04 | 38/38 | 38/38 |
| B03 | 29/29 | 29/29 |
| B02 | 27/27 | 27/27 |
| B01 | 20/20 | 20/20 |

Owning selectors also pass in debug and optimized: population migration 66,
CIV-39 69, Mortality 93, lifecycle/reproduction 80, household 71, Family 83,
dependent care 55, childhood/guardianship 62, checkpoint/replay 49,
persistence/reconciliation 19, Observer 20, candidate physical atomicity 3,
Pebble/PebbleCore embodiment 756, Material Rights 23, Estate 88, Gate E
Blockers 01–04 at 27/33/25/28 and Gate E Evaluation 05 at 21 assertions.

`scripts/verify-pebblelab.sh` passes all **35/35** stages from stage 1 with
**4274 passed, 0 failed** in the shared smoke suite and deterministic canonical
scenario comparisons. Goldens were read-only and were not regenerated.

## Non-claims and next action

This local correction does not publish Blocker 10, acquire Gate F, authorize or
perform Evaluation 11, start `CIV-40` or `CIV-41`, change checkpoint schema 35
or Observer schema 13, change Estate proof semantics, or regenerate goldens.
The next action is **senior review + manual publication of Blocker 10**.
