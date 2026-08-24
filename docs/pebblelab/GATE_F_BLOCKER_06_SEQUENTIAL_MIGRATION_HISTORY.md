# Gate F Blocker 06 — Sequential Migration Historical-vs-Current Authority

- Status: **FIXED — LOCAL CORRECTION CANDIDATE**
- Gate F: **PLANNED — NOT ACQUIRED**
- Evaluation 07: **NOT AUTHORIZED / NOT PERFORMED**
- `CIV-40`: **OPTIONAL TOOLING — NOT STARTED**
- `CIV-41`: **NOT STARTED**

This record documents the targeted product correction for the deterministic
contradiction found by independent Gate F Evaluation 06. The correction does
not rewrite or import the evaluation, acquire Gate F, start a CIV phase, push,
or regenerate goldens.

## Git identity and immutable evaluation evidence

- repository: `Ness-Now/pebble`
- canonical branch: `lab/pebblelab-v1`
- exact independently fetched canonical baseline, branch root and merge base:
  `31f785ca9051be6b4f39ab97102f89410a776824`
- correction branch:
  `codex/gate-f-blocker-06-sequential-migration-history`
- product/test/runtime-proof commit:
  `647dade73afa4d8e044423f422292dbf0c08f43e`
- Evaluation 06 harness commit
  `21523064810d10c30f10315397508431e34bb12a` is not an ancestor
- Evaluation 06 final-evidence commit
  `60abe393aed274db84d1f07d23aae59bf7a032f2` is not an ancestor
- push attempted: **NO**

Gate F Evaluations 01–06 remain **FAIL — HISTORICAL IMMUTABLE EVIDENCE**.
Blockers 01–05 remain **FIXED + PUBLISHED + REMOTE VERIFIED**. Blocker 06 is
**FIXED — LOCAL CORRECTION CANDIDATE**.

Evaluation 06 immutable identifiers:

| Field | Value |
| --- | --- |
| evaluated baseline | `31f785ca9051be6b4f39ab97102f89410a776824` |
| evaluation harness | `21523064810d10c30f10315397508431e34bb12a` |
| final evidence | `60abe393aed274db84d1f07d23aae59bf7a032f2` |
| review ZIP SHA-256 | `441dbb02eb0589a90e2b75a06c1eee6dc254e5655350b2358df0b8a2bc92abb7` |
| blocker kind | `sequentialMigrationHistoricalArrivalValidation` |
| deterministic digest | `1795926d8b9452dc35284aa214c63f58c074c7febd165c7ab9865929d7d531d2` |

These identifiers describe the failed independent evaluation, not this
correction's passing proof.

## Root cause

Population-scale history compaction already treated terminal settlement
migrations as historical retention candidates. Restore validation did not.
It iterated every retained `.arrived` record and required the living member to
remain non-migrating, currently assigned to that record's destination, and
currently resident in that destination projection.

That assertion is valid only for the latest retained migration that still owns
current residence. Once a later supported migration begins, the earlier
arrival remains true history but no longer owns current settlement authority.
The product-created Evaluation 06 state was therefore coherent in memory and
checkpointable at schema 35, yet fresh restore rejected the first migration as
`invalidReference(settlement-migration-00000001)`.

## Historical/current migration authority model

The correction derives one deterministic per-agent retained migration chain.
Every row continues to validate its intrinsic route, settlement references,
identity, ordinal, event simulation, tick/event ordering and status-specific
terminal fields. Migration IDs must be unique, canonical, ordered and strictly
monotonic, and `nextSettlementMigrationOrdinal` must be exactly the last
retained ordinal plus one.

For adjacent retained rows of the same agent:

- the prior row must be an arrived terminal transition;
- its destination must equal the later row's origin;
- its arrival tick cannot follow the later start tick; and
- its arrival event must precede the later start event.

Only the latest retained row for a living member owns current authority. A
latest `.inTransit` row requires the member to be migrating at its origin, to
exist in that origin's transit projection, to have one LIVE fidelity record,
and to retain one valid destination claim with unset terminal fields. A latest
`.arrived` row requires the member to be resident at its destination. An
earlier arrived row remains immutable history and no longer competes for
current residence.

Failure/death remains strict: a `.failed` row must be the latest retained row
for a departed member, carry `memberDied`, preserve valid failure ordering and
contain no arrival fields. No multiple-current-migration permission was added.

## Compaction semantics

Compaction keeps the existing bound and evicts only eligible old terminal
history. Validation applies continuity among adjacent retained rows but does
not invent or require an evicted predecessor. The latest row remains the
current authority owner and survives while in transit. The focused below,
exact and N+1 matrix proves exact eviction count, monotonic next ordinal,
schema-35 restore and post-restore continuation after the first old row is no
longer retained.

## Dedicated Blocker 06 proof

`PEBBLELAB_SMOKE_ONLY=gate-f-blocker-06` runs 28 assertions in debug and
optimized builds. Their stdout is byte-identical.

The selector proves:

1. one supported main-to-east migration remains a passing control;
2. the exact Evaluation 06 sequence restores migration 1 as historical and
   migration 2 as the sole current in-transit authority with next ordinal 3;
3. migration 2 completes east-to-main, restores exactly, continues without
   replay, and a supported third same-agent main-to-east migration also
   checkpoints, restores and arrives;
4. one agent's terminal history does not interfere with another agent's
   current sequential migration;
5. below-bound, exact-bound and N+1 compaction preserve current authority and
   exact eviction/ordinal counters;
6. a contradictory adjacent retained chain, duplicate/reordered identity,
   wrong next ordinal, wrong current settlement, missing transit projection,
   broken destination claim and displaced latest arrival all reject;
7. death after migration 1 and death while migration 2 is in transit preserve
   strict terminal semantics and prevent later arrival;
8. household settlement, current membership, home/residence anchor, fidelity,
   destination capacity and current population projections remain singular;
9. Observer schema 13 is read-only; and
10. checkpoint schema 35 and debug/optimized deterministic output are unchanged.

Passing summary:

```text
GATE_F_BLOCKER_06_PASS checkpointSchema=35 observerSchema=13 migrations=3 nextMigrationOrdinal=4 evictedCompaction=1 duplicateAuthority=0 restartDuplicateEffects=0 deterministicDigest=685aeaaeb78a577d4de435c0ecc6106d470f5d2187bc0d5068ee71cac9b586dc
28 passed, 0 failed
```

## Fresh-process schema-35 proof

Four OS processes were run: writer and reader under debug, then the same pair
under optimized code. Process 1 completed main-to-east migration 1, performed
an internal control restore, began east-to-main migration 2, proved migration
1 historical and migration 2 current, observed schema 13 read-only, wrote a
schema-35 checkpoint plus exact pre-checkpoint durable bytes and exited.

Process 2 first rejected a malformed schema-35 retained chain, then freshly
decoded and restored the valid checkpoint byte-exact. It completed migration 2
once, proved current settlement/household/fidelity authority, advanced from
tick 5 to tick 10 without replayed arrival, wrote a second checkpoint and
restored it exactly. The debug and optimized nine-file artifact trees are
byte-identical.

| Measure | Result |
| --- | --- |
| configurations / OS processes | debug and optimized / 4 total |
| population / settlements | 3 / 2 |
| checkpoint / durable-state bytes | 75,422 / 75,192 |
| initial / continuation tick | 5 / 10 |
| second-in-transit durable digest | `204ef0b5659beb36036a9bb3dadf414b802529652bf5e0e11349f867926a9f81` |
| continuation durable digest | `2a27feb5ac9ce90d3c44a176206d66d11bd8508992d20ac0882ef724c165dc83` |
| process 1 / process 2 scale digest | `e9be532c7358534f` / `e1abe24b426f38fb` |
| checkpoint / Observer schema | 35 / 13 |
| duplicate agent/population/lifecycle/fidelity/household/resident/transit/arrival authorities | all zero |
| restart duplicate effects / Observer mutations | zero / zero |
| unexpected errors / physical loss / duplication / synthetic material | all zero |
| debug/optimized reports and artifacts | byte-identical |

## Focused and owning validation

Every command below exited 0. Blockers 01–06 ran in debug and optimized; the
remaining current owning selectors ran fresh in debug.

| Selector | Result |
| --- | ---: |
| Gate F Blocker 06 debug / optimized | 28/28 / 28/28 |
| Gate F Blocker 05 debug / optimized | 27/27 / 27/27 |
| Gate F Blocker 04 debug / optimized | 38/38 / 38/38 |
| Gate F Blocker 03 debug / optimized | 29/29 / 29/29 |
| Gate F Blocker 02 debug / optimized | 27/27 / 27/27 |
| Gate F Blocker 01 debug / optimized | 20/20 / 20/20 |
| CIV-39 population scale / population migration | 69/69 / 66/66 |
| lifecycle / reproduction / mortality | 80/80 / 80/80 / 93/93 |
| genetics / kinship / households | 46/46 / 79/79 / 71/71 |
| dependent care / Childhood / Family / Estate | 55/55 / 62/62 / 83/83 / 88/88 |
| homeostasis / embodiment-Core descent / autonomous civilization | 30/30 / 756/756 / 36/36 |
| renewable / ecological receipt / material rights | 19/19 / 68/68 / 23/23 |
| production / barter / contracts / markets | 36/36 / 56/56 / 32/32 / 31/31 |
| Gate E E01 / E02 / E03 / E04 | 27/27 / 33/33 / 25/25 / 28/28 |
| checkpoint-replay / persistence-reconciliation | 49/49 / 19/19 |
| Observer / physical candidate atomicity | 20/20 / 3/3 |

`scripts/verify-pebblelab.sh` exited 0 with **4,188 passed, 0 failed** and
**all 35 repository verification steps succeeded**. `PEBBLE_REGOLD` was not
set and no golden changed.

Environment: macOS 26.5.2 arm64, Apple Swift 6.3.2 and Git 2.54.0.

## Exact changed surfaces

Product:

- `Sources/PebbleAgents/AgentSimulationSession+PopulationScale.swift`

Focused proof and runtime:

- `Sources/pebsmoke/PebbleAgentsGateFBlocker06Smoke.swift`
- `Sources/pebsmoke/main.swift`
- `Sources/PebbleLab/LabGateFBlocker06SequentialMigrationScenario.swift`
- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/main.swift`

Documentation/status surfaces are this report, `CODEX_START_HERE.md`,
`CURRENT_STATE.md`, `DOCUMENTATION_INDEX.md`,
`PEBBLE_CIVILIZATION_ROADMAP.md` and `ROADMAP_MANIFEST.json` only.

## Boundary and non-claims

- Gate F Evaluations 01–06 remain immutable historical FAIL evidence.
- Gate F Blockers 01–05 remain fixed, published and remote verified.
- Blocker 06 is a local correction candidate only; it is not published or
  remotely verified.
- Evaluation 07 was not authorized or performed.
- Gate F remains planned and was not acquired.
- `CIV-40` and `CIV-41` were not started.
- Checkpoint schema 35 and Observer schema 13 are unchanged.
- No renderer, live visual campaign, resource, registry or World-persistence
  semantic changed; the correction is headless validation and proof only.
- No push, rebase, history rewrite or golden regeneration occurred.
