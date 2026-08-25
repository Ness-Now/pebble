# Gate F Blocker 08 — Estate effective schema-35 validation composition

Status: **FIXED — LOCAL CORRECTION CANDIDATE**  
Gate F: **PLANNED — NOT ACQUIRED**  
Evaluation 09: **NOT AUTHORIZED / NOT PERFORMED**

## Immutable Evaluation 08 evidence

Evaluation 08 remains frozen **FAIL — HISTORICAL IMMUTABLE EVIDENCE**. None of
its commits is an ancestor of this correction.

- evaluated published baseline:
  `414954dc936177f892252898e97e8bcf986cee4b`
- focused harness: `40c664499a2ea69ae86378a85a8566b3d49e5642`
- fresh-process proof: `fb87eefb8d0d9dae37d11e7f51974c07aedcb530`
- final evidence: `df56cf026bd75d6b28371e7b5948a77a97de2d35`
- review ZIP SHA-256:
  `dc86ee24d0eef1a34f8ae0373ea0f1250463b2cbbf22a9b252fe827d11642da1`
- blocker kind: `schema35EstateValidationComposition`
- focused blocker digest:
  `28c20440c2da88bd4c1a62980689e3ffebf78d72d783a27cbe7f2bebdfa443da`
- focused control digest:
  `ac96a6dfc715a1438276fd8c7b4082ad2ebaf472dd9803ff51ce2589d44fb8e9`

The correction branch is
`codex/gate-f-blocker-08-estate-schema35-validation`; its root and merge base
are the exact evaluated published baseline. The published remote was fetched
and independently verified at the same SHA before work began.

## Contradiction and root cause

The public Estate-only control produced schema 28 and restored exactly. The
same valid live Estate authority composed with public CIV-39 population-scale
activation produced schema 35, but the baseline Estate validator rejected the
fresh restore with `AgentEstateError.invalidState("checkpoint schema")`.

`AgentSessionDurableState.init(session:)` correctly selects schema 35 whenever
population scale is enabled. Baseline Estate restore validation had a parallel
explicit schema list covering 27 through 34 but omitted 35. Live Estate
validation independently guessed schema 27 or 28 from Estate-local proof
presence, so live and durable validation did not share one effective aggregate
contract.

## Correction

Product/test/runtime commit:
`518aaf0dddfcc9f63e133290bf6dd915f9eaa73a`.

The correction introduces one bounded Estate checkpoint-validation semantics
policy beside the existing Family policy:

- schema 27: `legacySuccessorPlanRevalidation`;
- schemas 28–35: `strictDurableSuccessorPlan`;
- unsupported future versions: rejected.

Every live Estate cross-domain validation now uses
`durableState().schemaVersion`, the same feature-selection authority used by
checkpoint creation. Estate activation validates the completed candidate
before publication. Population-scale activation already operates on a
candidate copy and its existing Estate revalidation now sees effective schema
35. Both refusal directions are therefore byte-exact and consume no durable
ordinal.

There is no schema bump. Checkpoint schema remains 35 and Observer schema
remains 13. Schema 35 gains no legacy or weakened Estate behavior.

## Focused proof

The independently implemented `gate-f-blocker-08` selector passes **28/28** in
both debug and optimized builds with byte-identical stdout.

- Estate only: public activation, schema 28, exact restore PASS.
- Estate first / scale second: live validation PASS, unchanged Estate
  authority, schema 35, exact restore PASS.
- scale first / Estate second: public activation PASS, schema 35, exact
  restore PASS.
- non-empty Estate: one actual post-activation starvation death, one physical
  material-rights exit, one Estate, one strict successor-plan proof and the
  exact active-partner beneficiary; schema-35 restore PASS.
- continuation: zero replayed deaths and zero replayed Estates.
- schema-35 strict negatives reject missing proof, malformed proof identity,
  wrong death linkage, wrong beneficiary list, duplicate Estate identity and
  malformed mortality history.
- schema 27 restores its intended retained-cause legacy form.
- promoting that legitimate legacy state to effective schema 35 refuses
  atomically because it lacks strict durable proof.
- invalid Estate activation after scale refuses byte-exactly.
- unsupported schema 36 rejects.

Focused deterministic semantic digests:

- Estate-only schema-28 control:
  `ff8f52215699f53823afd307aa98c59b26456564e1166fdb16ae497229ad8f65`
- Estate-plus-scale schema-35 correction trajectory:
  `d9f25f0b855924ad4cfa2146b93e3f0f111e114f536f8a74a7d61affa53bc1af`

## Fresh-process proof

Eight OS processes were used: two fixtures, each with a writer and a fresh
reader, in debug and optimized modes. Debug and optimized artifact trees are
byte-identical.

| Fixture | Tick | Checkpoint bytes | Durable bytes | Durable SHA-256 | Estates / deaths / proofs |
|---|---:|---:|---:|---|---:|
| Estate enabled, empty | 0 | 35,733 | 35,503 | `f685ae97893c802f44cae394468624398e995522b200dccdcc433e6139afd020` | 0 / 0 / 0 |
| Scale + non-empty Estate | 14 | 128,280 | 128,045 | `0c4c95cb2ded4de9358c0100d2dc0da283a105b51aa379abf9bf99390cb57388` | 1 / 1 / 1 |

Checkpoint-file SHA-256 values are respectively
`c1e25dfc1d94195c6db3f4656f981fd3d1d0ea1aae21a6cb4e92e3dec493928e`
and
`1f5868ab17175466c8179e5ecbf6d7e0134f7be2107c1c2c9cf6a202e9c5fc51`.
Both fresh readers decoded the exact checkpoint bytes, reproduced the exact
durable bytes before restore publication, restored schema 35, observed schema
13 without mutation and continued one tick. Duplicate current authority,
Observer mutations, replayed Estate/death effects, physical loss, physical
duplication and synthetic material were all zero.

## Regression evidence

Fresh debug and optimized Blocker selectors:

- Blocker 07: 26/26 PASS in each mode;
- Blocker 06: 28/28 PASS in each mode;
- Blocker 05: 27/27 PASS in each mode;
- Blocker 04: 38/38 PASS in each mode;
- Blocker 03: 29/29 PASS in each mode;
- Blocker 02: 27/27 PASS in each mode;
- Blocker 01: 20/20 PASS in each mode.

Fresh owning and composition selectors:

- Estate 88/88; Family 83/83; mortality 93/93;
- lifecycle 80/80; reproduction 80/80; kinship 79/79;
- households 71/71; dependent care 55/55; Childhood 62/62;
- Material Rights 23/23; CIV-39 population scaling/fidelity 69/69;
- population migration 66/66;
- checkpoint/replay 49/49; persistence/reconciliation 19/19;
- Observer 20/20; candidate physical atomicity 3/3;
- Gate E Blockers/E01–E04: 27/27, 33/33, 25/25 and 28/28.

The canonical repository verification was run after documentation and manifest
closure; its final result is recorded in the review archive. Goldens were not
regenerated.

## Bounded parallel schema-list audit

The audit covered checkpoint schema selection and durable-state validation,
Family and Estate schema-semantic validators, mortality historical evidence,
population scale/fidelity validation, replay compatibility and every current
cross-domain validator accepting a checkpoint schema argument.

- Family already uses the Blocker 05 canonical policy and explicitly supports
  strict schemas 26–35.
- Estate now uses the canonical policy described above and supports effective
  schema 35 strictly.
- Other durable-state presence guards route current later schemas through the
  existing `latestSchema` authority, which includes population scale 35.
- Mortality has an older explicit history-presence list that stops at 34, but
  current schema-35 Estate validation independently requires the same strict
  historical evidence and the focused mutation matrix proves rejection. No
  supported public opposite-order contradiction was established from that
  static shape, so it was not opportunistically changed.
- No other cross-domain validator accepts schema-dependent semantics, and no
  second reachable product contradiction was found.

## Program status and non-actions

- Evaluations 01–08: **FAIL — HISTORICAL IMMUTABLE EVIDENCE**.
- Blockers 01–07: **FIXED + PUBLISHED + REMOTE VERIFIED**.
- Blocker 08: **FIXED — LOCAL CORRECTION CANDIDATE**.
- Gate F: **PLANNED — NOT ACQUIRED**.
- next authorized action: senior review/publication of Blocker 08; Evaluation
  09 remains unauthorized until that lifecycle is explicitly completed.
- CIV-40: **OPTIONAL TOOLING — NOT STARTED**.
- CIV-41: **NOT STARTED**.

No Evaluation 08 commit was merged or cherry-picked. Evaluation 09 was not
performed. Gate F was not acquired. CIV-40 and CIV-41 were not started. No
golden was regenerated and Codex did not push.
