# Gate F Blocker 09 — Estate causal successor authority

## Status

Gate F Evaluations 01–09: **FAIL — HISTORICAL IMMUTABLE EVIDENCE**

Gate F Blockers 01–08: **FIXED + PUBLISHED + REMOTE VERIFIED**

Gate F Blocker 09: **FIXED — LOCAL CORRECTION CANDIDATE**

Gate F: **PLANNED — NOT ACQUIRED**

Evaluation 10: **NOT AUTHORIZED / NOT PERFORMED**

`CIV-40`: **OPTIONAL TOOLING — NOT STARTED**

`CIV-41`: **NOT STARTED**

The product/test/runtime correction is
`0607d9b291f3ed7a28eaa9ad887f4a2e7927e2c5`. It is rooted directly in the
published canonical baseline
`b8f3d8cb05d0fa42cefc8d3f06d2e05fb7b0f8cb`. No Evaluation 09 commit is an
ancestor. This local candidate was not pushed, did not acquire Gate F, did not
start Evaluation 10 or another phase, and did not regenerate goldens.

## Immutable Evaluation 09 identity

Evaluation 09 remains frozen **FAIL — HISTORICAL IMMUTABLE EVIDENCE**.

| Identity | Value |
| --- | --- |
| evaluated baseline | `b8f3d8cb05d0fa42cefc8d3f06d2e05fb7b0f8cb` |
| harness | `8dd06f53289a6e66cc619ba5d45541d4dea4611e` |
| fresh-process evidence | `e779e58df9d2350f0179d0c20ef70722522564ef` |
| final evidence | `d200882d8e36f5f43eff0c52e163beb638f05cfc` |
| review ZIP SHA-256 | `79086413fd117a8c33a78a16430aafdd72b0c7492ec941c09399a615b1202816` |
| historical blocker kind | `postDeathSameTickSiblingEstateAuthority` |
| control digest | `12cdc25b917ce0908b0e2685fbedf4bad1162cd7f190f5fc0ab6bc8ef364f346` |
| attack digest | `328ff42c9d6b82555c8e950855a4a51caea93b4c0b932798cd7260599bb84d25` |

The bounded correction audit also found the supported correction-time
contradiction
`prePlanPendingSuccessorMortalityFinalizationRefusal`. Because both defects
were uncommitted contributors to immutable successor truth at the same
persisted `estate.successorPlanEventID` boundary, senior review broadened
Blocker 09 rather than creating a separate blocker.

## Causal contract and correction

For strict Estate schemas 28 through 35, the authoritative historical instant
is `estate.successorPlanEventID`. Plan creation predicts and verifies that exact
event sequence; later live validation and checkpoint restore use the persisted
sequence. Schema 27 retains its published legacy successor-plan revalidation
semantics. Unsupported future schemas still reject.

Parentage-derived parent, child and sibling authority participates only when
the durable Kinship `recordedEventID.sequence` is strictly less than the
successor-plan sequence. Current Kinship is unchanged: a relationship created
later remains current truth but cannot become historical Estate authority.

Mortality historical eligibility uses the first durable terminal mortality
authority. For embodied pending deaths this is
`mortalityMaterialExitPending`; a finalized record carries its
`pendingMaterialExitEventID`, or the `lethalHealthDepletion` event on immediate
death paths. New compacted summaries retain this optional terminal event ID.
Old summaries without it conservatively retain their published death-event
boundary and their original digest bytes.

Estate plan creation and strict validation call the same historical mortality
rule. They do not mutate immutable proofs when a candidate later dies, derive
history from current active membership, require retained causal event bodies,
or treat all same-tick transitions as simultaneous.

## Evaluation 09 correction matrix

The independent correction harness uses supported reproduction, mortality,
Estate and checkpoint APIs. It does not inject malformed state for the positive
trajectories.

| Order | Tick | Birth | Parentage | Lethal | Estate opened | Successor plan | Death finalized | Historical result |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| same-tick control | 4 | 119 | 121 | 129 | 131 | 132 | 138 | sibling included |
| same-tick attack-after-correction | 4 | 130 | 132 | 119 | 121 | 122 | 128 | later sibling excluded |

The exact historical Evaluation 09 ordering (birth 128, parentage 130 before
plan 141 in the control; plan 131, death finalization 137, later birth 139 and
parentage 141 in the attack) is preserved as immutable evidence. The independent
Blocker 09 fixture has different event identities because it was reimplemented
from canonical product truth. Its equivalent causal distinction is exact:
`121 < 132` in the control and `122 < 130 < 132` in the attack.

After the attack birth, current `siblingRelation` is `halfSibling`; the later
sibling has zero historical Estate rows. The immutable successor proof is
unchanged, schema-35 checkpoint creation and restore pass exactly, and
continuation succeeds. Previous-tick, same-tick-before, same-tick-after and
later-tick half-sibling cases, plus equivalent full-sibling before/after cases,
all pass.

The exact Evaluation 09 identity/ordinal expectations remain conserved:
decedent `agent_3` / population ordinal 3, later child `agent_4` / ordinal 4,
next population ordinal 5, next fidelity transition ordinal 6, next migration
ordinal 1, next household ordinal 3, next Family union ordinal 1 and next
Family house ordinal 1.

## Mortality eligibility matrix

| Supported case | Causal order | Result |
| --- | --- | --- |
| pending before plan | pending 98 < plan 121 | candidate ineligible; `secondaryParents`; beneficiary `agent_1` |
| finalized before plan | death finalization 128 < plan 133 | candidate ineligible |
| later-tick mortality after plan | plan 122 < pending 135 < death finalization 155 | historically eligible at plan; no retroactive change |

In the original adjacent failure, the pre-plan pending parent was recorded
eligible and its later finalization refused with `successor mortality
eligibility`. After correction, the proof records that parent ineligible,
physical custody resolves at sequence 128, lethal publication occurs at 129,
death finalization succeeds at 140, exactly two deaths and two Estates exist,
and the earlier Estate proof remains immutable.

A same-tick post-plan transition into `mortalityMaterialExitPending` is not a
public ordering: `applyMortalitySurvivalBoundary` stages terminal pending state
at tick advancement before manual death finalization and Estate planning for
that tick. A post-plan canonical child is likewise unreachable through public
reproduction: death finalization cancels active plans involving the decedent,
and a dead parent cannot execute a supported birth.

## Strict negatives and compaction

Strict schemas reject a proof that includes post-boundary parentage, omits a
pre-boundary relationship, uses the wrong relationship basis, or has an
incorrect beneficiary tier/list or foreign successor-plan identity. They also
reject a pre-plan mortality-ineligible successor marked eligible, a genuinely
eligible-at-plan successor marked ineligible, an incorrect life stage, foreign
pending causal identity and impossible pending sequence ordering. Kinship and
Mortality retain ownership of their malformed causal records.

Event-body compaction does not change the result. Parentage uses durable
`recordedEventID`; mortality uses pending/final durable IDs and the optional
compacted terminal-eligibility ID. Relationships before the plan remain
recognized, relationships and mortality transitions after it remain
non-retroactive, and exact schema-35 restore succeeds without unbounded causal
history.

## Focused and fresh-process proof

The dedicated `gate-f-blocker-09` selector passes **31/31** in both debug and
optimized builds. Stdout is byte-identical with SHA-256
`6585a363f705868c4183b3587436e7ab9e375ad61e87cd434c9fd251a1924ac0`.

Twelve fresh OS processes pass: parentage and mortality each use a three-process
write / fresh restore-and-transition / fresh restore-and-continue chain in
debug and optimized configurations. Debug and optimized artifact trees are
byte-identical where required.

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| parentage pre-birth checkpoint | 119,009 | `e8fd4672f5d3e34be60c680b5274c679462226b9eb220e204cac4486e264e53b` |
| parentage pre-birth durable | 118,785 | `089a073b7f39b69b204526caf2a5d3128958f767935f29e23d234a67a2660392` |
| parentage post-birth checkpoint | 131,165 | `644e4b04f5bb068800bdc96ecbf7cd03be7b596fa10fc405a173a5c0a8b47cbc` |
| parentage post-birth durable | 130,941 | `1aecd1636c4ea0119018b56b544e334ace06b921685ce5d260bb21e523351556` |
| mortality pending checkpoint | 124,795 | `f96a084f7c8cb0df08628f67f283926534c7a7cd9da6ab4feed2ccd8e75107e7` |
| mortality pending durable | 124,561 | `16c99f431a3eacdce4f11b2e23f379c9c14fa9a8a99253eda7f1dd86ab3fa23d` |
| mortality finalized checkpoint | 135,234 | `9ff4d55c5916fdf7050a1ccb2b5995f0cb10a330cb2d76bec18310636a7e6d42` |
| mortality finalized durable | 135,000 | `eac99e897e7bd18a816a60043ade25062b4252d4bad3e6878fc18a5778fa927b` |

Every checkpoint is schema 35. Observer is read-only schema 13 with zero
mutations. Duplicate current authority, replayed deaths and replayed Estates
are all zero. Continuation succeeds and identities and next ordinals are exact.

## Published schema-35 backward compatibility

A disposable detached worktree rooted exactly at published canonical
`b8f3d8cb05d0fa42cefc8d3f06d2e05fb7b0f8cb` wrote three representative old
schema-35 checkpoints. The corrected reader decoded, strictly restored and
re-encoded the exact bytes, then continued without replay or duplicate current
authority.

| Old canonical fixture | Checkpoint bytes | Checkpoint SHA-256 | Result |
| --- | ---: | --- | --- |
| mortality enabled, no deaths | 35,733 | `c1e25dfc1d94195c6db3f4656f981fd3d1d0ea1aae21a6cb4e92e3dec493928e` | exact |
| retained death + Estate + CIV-39 scale | 128,280 | `1f5868ab17175466c8179e5ecbf6d7e0134f7be2107c1c2c9cf6a202e9c5fc51` | exact |
| two compacted deaths + three retained Estates | 238,258 | `0814b54770bd4103fb3ed083e280bed52a5525dbcfa882ac82b6e5724da54336` | exact |

The new compacted-summary field is optional on decode. Its absence neither
fabricates a causal sequence nor changes an old digest. Checkpoint schema
therefore remains 35; Observer remains 13.

## Bounded adjacent audit

| Contributor | Classification | Contract evidence |
| --- | --- | --- |
| parentage child/sibling | event-causal and verified | `recordedEventID < successorPlanEventID` |
| mortality eligibility | event-causal and verified | first durable terminal mortality event compared with plan |
| guardian at plan | event-causal and verified | start/end event sequences already compared with plan |
| `lifeStageAtPlan` | intentionally tick-boundary granular | lifecycle transitions publish at tick boundary before Estate planning |
| active union / spouse | same-transaction exception verified | partner-death Family termination follows the immutable plan within mortality finalization; proof retains activation evidence and termination reason/tick validates the transaction |

No further reachable Estate historical-authority contradiction was found.

## Regression and repository verification

| Selector | Debug | Optimized |
| --- | ---: | ---: |
| Blocker 09 | 31/31 | 31/31 |
| Blocker 08 | 28/28 | 28/28 |
| Blocker 07 | 26/26 | 26/26 |
| Blocker 06 | 28/28 | 28/28 |
| Blocker 05 | 27/27 | 27/27 |
| Blocker 04 | 38/38 | 38/38 |
| Blocker 03 | 29/29 | 29/29 |
| Blocker 02 | 27/27 | 27/27 |
| Blocker 01 | 20/20 | 20/20 |

Fresh owning selectors pass: Estate 88/88, Mortality 93/93, Kinship 79/79,
lifecycle 80/80, reproduction 80/80, Family 83/83, households 71/71,
dependent care 55/55, Childhood 62/62, CIV-39 69/69, population migration
66/66, checkpoint/replay 49/49, persistence/reconciliation 19/19, Observer
20/20, Material Rights 23/23, Gate E Blockers/E01–E04 27/27, 33/33, 25/25
and 28/28, and candidate physical atomicity 3/3.

The first repository verifier attempt was interrupted by the accidental machine
shutdown at approximately stage 3 and is not counted. After crash-state and
stale-process inspection, `scripts/verify-pebblelab.sh` was rerun from stage 1.
The authoritative run passes **all 35 stages, 4273/4273 assertions**. Goldens
were read-only and were not regenerated.

## Compatibility and program state

- checkpoint schema: **35**, unchanged and backward compatible;
- Observer schema: **13**, unchanged and read-only;
- `ROADMAP_MANIFEST.schemaVersion`: **3**, unchanged;
- product correction: **YES**;
- Gate F acquired: **NO**;
- Evaluation 10 performed: **NO**;
- `CIV-40` / `CIV-41` started: **NO / NO**;
- goldens regenerated: **NO**;
- push attempted: **NO**.

`currentState` and `gates.F` carry semantically identical Evaluation 09,
Blocker 09, Gate F acquisition/status and next-action state. The next authorized
action is senior review and a manual publication decision for Blocker 09.
