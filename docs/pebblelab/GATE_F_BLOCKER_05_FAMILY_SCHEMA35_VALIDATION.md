# Gate F Blocker 05 — Family V1 × Durable Schema-35 Validation

- Status: **FIXED + PUBLISHED + REMOTE VERIFIED**
- Gate F: **PLANNED — NOT ACQUIRED**
- Evaluation 06: **NOT PERFORMED**
- `CIV-40`: **OPTIONAL TOOLING — NOT STARTED**
- `CIV-41`: **NOT STARTED**

This record documents the targeted product correction for independent Gate F
Evaluation 05 and its subsequent publication reconciliation. The original
correction mission did not alter the evaluation, acquire Gate F, start a CIV
phase, push or regenerate goldens. Senior review later approved manual
fast-forward, publication completed and independent remote verification
passed.

## Git identity and immutable history

- repository: `Ness-Now/pebble`
- canonical branch: `lab/pebblelab-v1`
- exact fetched canonical baseline:
  `937693d6030f8ba77f1363da7f4336647962ee9e`
- correction branch:
  `codex/gate-f-blocker-05-family-schema35-validation`
- branch root and merge base:
  `937693d6030f8ba77f1363da7f4336647962ee9e`
- product/test/runtime-proof commit:
  `b1f3fad3ec4959c1ecf43e91eac0d291d6f9acf4`
- published canonical blocker HEAD:
  `df1c042c0f8d4f45ad8928c9fb7d0bbe5558af8b`
- final correction review archive SHA-256:
  `b27904bceba21901e87cdf8d1e9aedea3db65e9828606db4c46d5d829be2f689`
- senior review: **APPROVED FOR MANUAL FAST-FORWARD**
- manual publication: **COMPLETED**
- independent remote verification: **PASS**
- Evaluation 05 harness commit
  `d4140fef049d0bc30a062019fccdd752ff802908` is not an ancestor
- Evaluation 05 final evidence commit
  `0658f52cb2bb4283ce931f2b5760ed5572549151` is not an ancestor
- push attempted: **NO**

Gate F Evaluations 01–05 remain **FAIL — HISTORICAL IMMUTABLE EVIDENCE**.
Blockers 01–05 are **FIXED + PUBLISHED + REMOTE VERIFIED**.

Evaluation 05 immutable identifiers:

| Field | Value |
| --- | --- |
| evaluated baseline | `937693d6030f8ba77f1363da7f4336647962ee9e` |
| evaluation harness | `d4140fef049d0bc30a062019fccdd752ff802908` |
| final evidence | `0658f52cb2bb4283ce931f2b5760ed5572549151` |
| review ZIP SHA-256 | `c9c558a3f1b6f1f73a2bfc0ed8decf3efb386f6427ccfabb9ac91a2abd857753` |
| focused digest | `ec0735992cc9fead47b19c7ddb758b7215c8a0e832b380b95198406fac61b203` |
| fresh-process digest | `b76b5c182851508604c3df30bf0e59fd4f26b47fd549cfd2256ab85751a30bbd` |
| blocker kind | `schema35FamilyValidationComposition` |

These identifiers describe the failed historical evaluation, not the
published correction's new passing digests.

## Root cause

`AgentSessionDurableState` correctly selected checkpoint schema 35 whenever
population scale was enabled. A valid aggregate could therefore combine
population, lifecycle, kinship, households, dependent care, Childhood V2,
Family V1 and CIV-39 scale, run successfully and publish a checkpoint.

Family restore validation independently carried an explicit schema allowlist
ending at schema 34. Fresh restore passed the checkpoint-level schema boundary
and then failed inside `validateFamilyState` with
`AgentFamilyError.invalidState("bounds, ordering or counters")`.

The same code also had a live/durable blind spot. In-process Family
cross-domain validation interpreted a live aggregate as schema 25 or 26 from
the legacy override, even when `makeCheckpoint()` would emit a later effective
schema such as 35. A live transition could consequently validate under legacy
or schema-26 interpretation and publish bytes that fresh restore interpreted
under another version.

## Correction design

`AgentCheckpointSchema.familyValidationSemantics(for:)` is the one canonical,
history-based Family compatibility policy:

- schema 25 uses `legacyCausalProofFallback`;
- schemas 26–35 use `strictDurableConsent`;
- every other integer returns no Family compatibility and is rejected at the
  appropriate checkpoint or Family boundary.

Live Family validation now asks `durableState()` for the exact effective schema
that checkpoint publication would choose and passes that version to the same
validator used by restore. Population-scale activation validates household,
dependent-care, Family and Estate composition on its copy candidate before
publication, so promotion from a legacy Family state to strict schema 35 fails
atomically when durable proofs are absent.

No checkpoint version was added or downgraded. `AgentCheckpointSchema.supports`
was not weakened. Checkpoint schema remains 35 and Observer schema remains 13.
Strict proof/consent rules, malformed-state rejection and unsupported-future-
schema rejection remain fail-closed.

## Family compatibility matrix

The matrix is based on feature history, not `version >= 26` arithmetic.

| Schema | Historical owner | Family semantics |
| --- | --- | --- |
| 1–24 | pre-Family schemas | not a supported Family carrier |
| 25 | Family V1 | legacy retained-cause fallback for historical co-founding and explicit adult-join proof shapes |
| 26 | Durable House Consent | current strict durable co-founding proof and adult-join consent |
| 27 | legacy Estate | strict Family; legitimate historical Estate compatibility remains bounded by Estate validation |
| 28 | current Estate | strict Family |
| 29 | renewable subsistence | strict Family |
| 30 | independent ecological receipt | strict Family |
| 31 | production | strict Family |
| 32 | barter | strict Family |
| 33 | contracts | strict Family |
| 34 | markets | strict Family |
| 35 | population scale | strict Family |
| 36 and future | unsupported | rejected |

The dedicated selector uses live builders for the minimized Family control,
scale control, Durable House Consent, current Estate, Gate E 31–34 and
schema-35 carriers. Historical schema-25 shapes are derived from real Family
operations with their exact retained causal events; no impossible synthetic
old checkpoint is invented. The policy explicitly covers legitimate 27–30
history without relaxing the owning Estate, renewable or ecological validators.

## Dedicated Blocker 05 proof

`PEBBLELAB_SMOKE_ONLY=gate-f-blocker-05` runs 27 assertions in both debug and
optimized builds. Debug and optimized stdout are byte-identical.

The selector proves:

1. the minimized Evaluation 05 Family-plus-scale aggregate restores at schema
   35 and its restored durable bytes exactly equal pre-checkpoint bytes;
2. Family without scale restores exactly at schema 26;
3. scale without Family restores exactly at schema 35;
4. a migrated secondary-settlement adult has coherent population, lifecycle,
   home, household, fidelity and Family authority after schema-35 restore;
5. supported continuation and a second schema-35 checkpoint/restore are exact;
6. schema 25 retains only its legitimate retained-cause co-founding and adult-
   join fallbacks;
7. schemas 26–35 use strict durable semantics, with live current-Estate and
   Gate E 31–34 carriers restored byte-exact;
8. valid schema 35 accepts strict Family proofs;
9. schema 35 rejects missing co-founding proof, missing adult-join consent and
   malformed Family counters;
10. unsupported schema 36 rejects at the checkpoint boundary;
11. live promotion uses effective schema 35 and atomically refuses a legacy
    state lacking durable proof;
12. Observer schema 13 is read-only;
13. debug/optimized deterministic outputs and digests are equal.

Passing summary:

```text
GATE_F_BLOCKER_05_PASS checkpointSchema=35 observerSchema=13 compatibility=25:legacy,26-35:strict minimizedDigest=82ceae428101dc22aea94eb8c37f660b4fe51361b337cd49731fb4e105f1e406 migratedDigest=4ecdd83817ab8f3d684f9d1cc5fb009b06291566d3802ac5230543959df8766c duplicateAuthority=0 restartDuplicateEffects=0
27 passed, 0 failed
```

## Fresh-process runtime proof

Four fresh processes were run: process 1 and process 2 under debug, then the
same pair under optimized code. The two eight-file artifact trees are exactly
equal.

Process 1 built three adults with population, lifecycle, kinship, households,
dependent care, Childhood V2, one Family union, one co-founded house and
population scale. It completed the existing verified physical migration of
`agent_0` to `settlement-east`, advanced to tick 5, proved current authority,
observed read-only schema 13, wrote a schema-35 checkpoint and exited.

Process 2 freshly decoded and restored that checkpoint, proved exact equality
with the 82,228 pre-checkpoint durable bytes, revalidated Family, scale and the
secondary-settlement authorities, advanced tick 5 to tick 6, proved no replayed
arrival/Family/household effect, wrote a second schema-35 checkpoint and
restored it exactly.

| Measure | Result |
| --- | --- |
| configurations | debug and optimized |
| processes | 4 total |
| population / settlements / arrived migrations | 3 / 2 / 1 |
| Family unions / houses / memberships | 1 / 1 / 2 |
| checkpoint schema / Observer schema | 35 / 13 |
| checkpoint bytes / durable-state bytes | 82,458 / 82,228 |
| initial tick / continuation tick | 5 / 6 |
| semantic digest | `d94c2aeb84c5fd31b70a0ccc1008ed0669c0d2a2365e1fcf62e2b26fecb358ec` |
| continuation digest | `b20f367f242df882297e349b292d5b7f753d27468b3a78aa5acbfe94cd9bd870` |
| duplicate agent/population/lifecycle/fidelity/household/resident/arrival authorities | all zero |
| restart duplicate effects | zero |
| Observer mutations | zero |
| unexpected errors / physical loss / physical duplication / synthetic material | all zero |
| debug/optimized semantics, reports and artifacts | exact equality |

## Focused and owning validation

Every command below exited 0. Gate F Blockers 01–05 were run in debug and
optimized configurations; the remaining owning selectors were run fresh in
debug. `lifecycle` and its explicit `reproduction` alias exercise the same
80-assertion owner.

| Selector | Result |
| --- | ---: |
| Gate F Blocker 05 debug / optimized | 27/27 / 27/27 |
| Gate F Blocker 04 debug / optimized | 38/38 / 38/38 |
| Gate F Blocker 03 debug / optimized | 29/29 / 29/29 |
| Gate F Blocker 02 debug / optimized | 27/27 / 27/27 |
| Gate F Blocker 01 debug / optimized | 20/20 / 20/20 |
| CIV-39 population scale | 69/69 |
| population migration | 66/66 |
| lifecycle / reproduction | 80/80 / 80/80 |
| mortality | 93/93 |
| genetics and development | 46/46 |
| kinship | 79/79 |
| households | 71/71 |
| dependent care | 55/55 |
| Childhood V2 | 62/62 |
| Family V1 | 83/83 |
| Estate/inheritance/succession | 88/88 |
| homeostasis/health | 30/30 |
| embodiment and Core descent | 756/756 |
| autonomous civilization | 36/36 |
| renewable subsistence | 19/19 |
| ecological receipt/observation | 68/68 |
| material rights | 23/23 |
| production | 36/36 |
| barter | 56/56 |
| contracts | 32/32 |
| markets | 31/31 |
| Gate E Blockers E01 / E02 / E03 / E04 | 27/27 / 33/33 / 25/25 / 28/28 |
| checkpoint/replay | 49/49 |
| persistence/reconciliation | 19/19 |
| Observer | 20/20 |
| physical candidate atomicity | 3/3 |

`scripts/verify-pebblelab.sh` exited 0 with **4,160 passed, 0 failed** and
**all 35 repository verification steps succeeded**. `PEBBLE_REGOLD` was not
set and no golden was changed.

Environment: macOS 26.5.2 arm64, Apple Swift 6.3.2 and Git 2.54.0.

## Exact changed surfaces

Product:

- `Sources/PebbleAgents/AgentCheckpoint.swift`
- `Sources/PebbleAgents/AgentSimulationSession+Family.swift`
- `Sources/PebbleAgents/AgentSimulationSession+PopulationScale.swift`

Focused proof and runtime:

- `Sources/pebsmoke/PebbleAgentsGateFBlocker05Smoke.swift`
- `Sources/pebsmoke/main.swift`
- `Sources/PebbleLab/LabGateFBlocker05FamilySchemaScenario.swift`
- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/main.swift`

Documentation/status surfaces are this report, `CODEX_START_HERE.md`,
`CURRENT_STATE.md`, `DOCUMENTATION_INDEX.md`,
`PEBBLE_CIVILIZATION_ROADMAP.md` and `ROADMAP_MANIFEST.json` only.

## Boundary and non-claims

- Gate F Evaluation 05 remains immutable FAIL evidence.
- Blocker 05 is fixed, published and independently remote verified at canonical
  blocker HEAD `df1c042c0f8d4f45ad8928c9fb7d0bbe5558af8b`.
- Evaluation 06 was not performed. The next authorized action after this
  reconciliation is reviewed, published and remote verified is
  `NEW-INDEPENDENT-V4-GATE-F-v1-EVALUATION-06`.
- Gate F remains planned and was not acquired.
- `CIV-40` and `CIV-41` were not started.
- Schema 35 and Observer schema 13 are unchanged.
- Unsupported secondary-settlement reproduction was not broadened.
- No rendering, audio, resources, registries, World persistence, save/load or
  packaging surface changed.
- No push, rebase, history rewrite or golden regeneration occurred.
