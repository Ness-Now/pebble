# Gate F Blocker 09 — Estate causal successor authority

## Status and history

Gate F Evaluations 01–09 remain **FAIL — HISTORICAL IMMUTABLE EVIDENCE**.
Gate F Blockers 01–08 remain **FIXED + PUBLISHED + REMOTE VERIFIED**.
Gate F Blocker 09 is **FIXED + PUBLISHED + REMOTE VERIFIED**, including Senior
Review Correction 01. Gate F remains **PLANNED — NOT ACQUIRED**. Evaluation 10
is **NOT PERFORMED**. `CIV-40` is
**OPTIONAL TOOLING — NOT STARTED** and `CIV-41` is **NOT STARTED**.

The first reviewed candidate is preserved at product/test/runtime commit
`0607d9b291f3ed7a28eaa9ad887f4a2e7927e2c5` and documentation commit
`7f9a8ace5b5ddedf0f4ec96d6c654e9037e63169`. Its review ZIP SHA-256 is
`aa7a6eabb8a74ca6fb61b388c44706cf95cb5868fd689db274a41405caff6672`.
Senior Review Correction 01 product/test/runtime commit is
`6a5ee92e89d14e1aff38d17c28d4e526eb51eb5f`; its evidence-reconciliation
commit is recorded by the final Git history. The candidate is rooted directly
in published canonical baseline
`b8f3d8cb05d0fa42cefc8d3f06d2e05fb7b0f8cb`; no Evaluation 09 commit is an
ancestor. During correction, Codex did not push, acquire Gate F, start
Evaluation 10 or another phase, or regenerate goldens; publication was the
subsequent manual action recorded below.

Manual publication completed at final Blocker 09 HEAD
`482adc6617e258a73967e73c9d53cf1466c94f64`. Independent GitHub verification
confirmed `lab/pebblelab-v1` identical to that HEAD with ahead/behind `0/0` and
the same merge base. The final Senior Review archive is
`PebbleLab-GateF-Blocker09-SeniorReviewCorrection01-Review-482adc6.zip`, SHA-256
`09136811d4e6680dc6373e2c728509b91e2557a34a0dd10a9eeb421bd1d446e9`,
with 280/280 internal checksums, ZIP integrity and fresh extraction PASS.

## Immutable Evaluation 09 identity

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

The bounded correction audit also found
`prePlanPendingSuccessorMortalityFinalizationRefusal`. Both defects contribute
to immutable successor truth at the persisted `estate.successorPlanEventID`
boundary, so they were corrected together under Blocker 09.

## Causal contract

For strict Estate schemas 28 through 35, the authoritative instant is
`estate.successorPlanEventID`. Parentage-derived authority participates when
Kinship `recordedEventID.sequence < successorPlanEventID.sequence`. Current
Kinship remains current truth even when a later relationship is excluded from
historical Estate truth.

Mortality uses the first durable terminal authority. Embodied pending deaths
use `mortalityMaterialExitPending`; finalized records carry
`pendingMaterialExitEventID`, with `lethalHealthDepletion` as the immediate-
death fallback. New compacted summaries retain the optional terminal event ID.
Plan creation and validation use the same historical rule and do not depend on
retained causal event bodies. Schema 27 retains its published legacy Estate
revalidation policy; unsupported future schemas reject.

## Senior Review Correction 01

Senior review correctly found that the original three-fixture compatibility
matrix contained no live pending mortality transition. The exact published
trajectory was reproduced through public APIs at tick 4:

| Fact | Value |
| --- | --- |
| `mortalityMaterialExitPending` | sequence 98 |
| Estate successor plan | sequence 121 |
| stored successor row | `eligibleAtDeath = true` |
| checkpoint | schema 35, 124,934 bytes, `1384b5fcdef05c607270015071917b0d92831277abfb05670bacd7e47dca4e41` |
| durable state | 124,700 bytes, `9e552af00c8a88f7159c16fe20b0ea172e040a814c2147773953e0bd7868883e` |
| published reader | PASS exact |
| pre-SRC01 candidate | REJECT: `invalid estate state: successor mortality eligibility` |

The existing domain marker `AgentEstateSuccessorPlanProof.version` now makes
the semantic distinction explicit:

- version 1 is the published legacy successor-plan representation. Genuine v1
  proofs remain immutable and validate with published plan-time mortality
  semantics;
- version 2 is Blocker 09 causal successor authority. Every new runtime plan
  emits v2. Parentage, terminal mortality and guardianship are reconstructed at
  the successor-plan event boundary, and malformed v2 state remains rejected.

The compatibility path is not a v2 bypass. A v2 proof with pending sequence 98
before plan sequence 121 and `eligible=true` rejects; the corresponding v2
positive with `eligible=false` passes. A v2 proof containing post-plan
parentage also rejects. No new runtime path emits v1.

Checkpoint canonical JSON, schema/domain-version checks and digests continue to
provide deterministic integrity and semantic validation; they are not keyed
authenticity against an actor who arbitrarily rewrites a complete checkpoint
and recomputes every digest. Reconstructing a self-consistent legacy v1 archive
is outside that established persistence-integrity threat model, so SRC01 adds
no unrelated cryptographic anti-downgrade system.

## Legacy continuation and compatibility

The exact old v1 pending checkpoint restores and re-encodes byte-exact under
SRC01. Its pending custody resolves and mortality finalizes exactly once. The
old Estate proof remains immutable v1; the newly created Estate is v2. The
continued checkpoint SHA-256 is
`40f334513d161563b9a1e171afc87ab4059c17afbc76cddecca7e21ec0c5cfdc`.
A second fresh restore and continuation yields
`7d7e6c404c8e01190a1b5950c5d5185bbe8cfbb650a963cd7eb33b76fd6b6a8e`,
with zero death/Estate replay and singular current authority.

Five published-canonical schema-35 fixture classes pass with both corrected
debug and optimized readers:

| Old canonical fixture | Checkpoint SHA-256 | Corrected result |
| --- | --- | --- |
| mortality enabled, empty history | `c1e25dfc1d94195c6db3f4656f981fd3d1d0ea1aae21a6cb4e92e3dec493928e` | exact restore/re-encode/continue |
| retained death + Estate + CIV-39 | `1f5868ab17175466c8179e5ecbf6d7e0134f7be2107c1c2c9cf6a202e9c5fc51` | exact restore/re-encode/continue |
| compacted mortality + retained Estates | `0814b54770bd4103fb3ed083e280bed52a5525dbcfa882ac82b6e5724da54336` | exact restore/re-encode/continue |
| pending before plan, legacy eligible | `1384b5fcdef05c607270015071917b0d92831277abfb05670bacd7e47dca4e41` | exact restore plus successful finalization |
| post-plan sibling, immutable pre-birth proof | `644e4b04f5bb068800bdc96ecbf7cd03be7b596fa10fc405a173a5c0a8b47cbc` | exact; current `halfSibling`, zero historical rows |

Old compacted summaries lacking `terminalEligibilityEventID` remain byte-exact
and use their published death-event boundary. The more specific affected
pending-before-plan compacted legacy shape is not publicly constructible: on
the published baseline, finalizing that pending transition refuses on
`successor mortality eligibility`, so it cannot reach finalized or compacted
history. No causal sequence is fabricated.

## Evaluation 09 and mortality matrices

| Order | Tick | Birth | Parentage | Lethal | Estate opened | Plan | Death finalized | Historical result |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| same-tick control | 4 | 119 | 121 | 129 | 131 | 132 | 138 | sibling included |
| same-tick attack | 4 | 130 | 132 | 119 | 121 | 122 | 128 | later sibling excluded |

The exact Evaluation 09 historical events remain birth/parentage 128/130 before
plan 141 in the control, and plan 131, death finalization 137, later birth 139
and parentage 141 in the attack. The independent fixture uses different IDs but
the same public causal contract. Current `siblingRelation` is `halfSibling`, the
later sibling has zero historical Estate rows, and the immutable proof does not
change.

| Mortality case | Causal order | Historical result |
| --- | --- | --- |
| pending before plan | pending 98 < plan 121 | ineligible; `secondaryParents`; beneficiary `agent_1` |
| finalized before plan | finalization 128 < plan 133 | ineligible |
| later-tick mortality | plan 122 < pending 135 < finalization 155 | eligible at plan; no retroactive change |

Same-tick post-plan `mortalityMaterialExitPending` is not publicly reachable:
`applyMortalitySurvivalBoundary` stages terminal pending state during tick
advancement before manual death finalization and Estate planning for that tick.
A post-plan canonical child is also unreachable because death finalization
cancels active reproduction plans involving the decedent.

## Focused, fresh-process and compaction proof

The authoritative SRC01 selector passes **32/32** in debug and optimized.
Stdout is byte-identical with SHA-256
`c3fee0f27a48ca5aaa8966500674fe142b13cbed5a1065f7fd67fd9608bb1731`.
The pre-SRC01 31/31 result remains historical evidence only.

Twelve fresh OS processes pass: parentage and mortality each use a three-
process chain in debug and optimized, and corresponding artifact trees are
byte-identical.

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| parentage pre-birth checkpoint | 119,009 | `2f029c0fa179de7ac5d1739d80d8ac0da7c8ffa562c06c93e909fbdccb4cd662` |
| parentage pre-birth durable | 118,785 | `36fbfeb987051cffbfc9f4b039f56d16dc326754396c6ae0e472c1c63553c21f` |
| parentage post-birth checkpoint | 131,165 | `f5690d3ee1a077a0ef9ea251fb6635776d49b70b1e3bb3462dd5e7137cdcab25` |
| parentage post-birth durable | 130,941 | `6354bd4788de0b669ed142fb82babacc7fc5c1ec587ef01165a14d073e12a2d5` |
| mortality pending checkpoint | 124,795 | `be7689f945aced70cccea5226e4624a72e64684c6f4c1ed0b2bafa6433a55217` |
| mortality pending durable | 124,561 | `985ea16488ece5e05e6a692e9d26859f3241679325b319b40f7043771799a1bf` |
| mortality finalized checkpoint | 135,234 | `904d843ee6f1f3fb29477961f263fdfb44c3232aab963e4316a4004247da0bd1` |
| mortality finalized durable | 135,000 | `c40d02249c3ae739837f27cfe86ba4473a8a19164eab0aab92e5253d6b07a63e` |

All checkpoints are schema 35. Observer is schema 13 and read-only. Event-body
compaction preserves parentage ordering through `recordedEventID` and mortality
ordering through pending/final durable IDs and the optional compacted terminal
ID. Replay, duplicate authority and ordinal reuse counters are zero.

## Bounded adjacent audit

| Contributor | Classification | Contract evidence |
| --- | --- | --- |
| parentage child/sibling | EVENT-CAUSAL AND VERIFIED | recorded event precedes plan |
| mortality eligibility | EVENT-CAUSAL AND VERIFIED | first durable terminal event compared with plan |
| guardian at plan | EVENT-CAUSAL AND VERIFIED | start/end event sequences already compared with plan |
| `lifeStageAtPlan` | INTENTIONALLY TICK-GRANULAR | lifecycle publishes at tick boundary before Estate planning |
| active union / spouse | SAME-TRANSACTION EXCEPTION — VERIFIED | partner-death Family termination follows immutable plan creation in the same mortality finalization transaction |

No further reachable Estate historical-authority contradiction was found.

## Validation

| Selector | Debug | Optimized |
| --- | ---: | ---: |
| Blocker 09 SRC01 | 32/32 | 32/32 |
| Blocker 08 | 28/28 | 28/28 |
| Blocker 07 | 26/26 | 26/26 |
| Blocker 06 | 28/28 | 28/28 |
| Blocker 05 | 27/27 | 27/27 |
| Blocker 04 | 38/38 | 38/38 |
| Blocker 03 | 29/29 | 29/29 |
| Blocker 02 | 27/27 | 27/27 |
| Blocker 01 | 20/20 | 20/20 |

Owning selectors pass: Estate 88/88, Mortality 93/93, Kinship 79/79,
lifecycle 80/80, reproduction 80/80, Family 83/83, households 71/71, care
55/55, Childhood 62/62, CIV-39 69/69, migration 66/66, checkpoint/replay
49/49, persistence/reconciliation 19/19, Observer 20/20, Material Rights
23/23, Gate E Blockers 01–04 27/27, 33/33, 25/25 and 28/28, and physical
candidate atomicity 3/3.

The quota-interrupted verifier invocation continued independently and produced
a complete authoritative log with a normal terminal PASS. It was therefore
preserved rather than rerun. `scripts/verify-pebblelab.sh` passes **35/35
stages and 4274/4274 assertions**. No partial run is counted. Goldens were
read-only and were not regenerated.

## Final compatibility state

- checkpoint schema: **35**, unchanged;
- Observer schema: **13**, unchanged and read-only;
- `ROADMAP_MANIFEST.schemaVersion`: **3**, unchanged;
- product correction: **YES**;
- published and independently remote verified: **YES**;
- Gate F acquired: **NO**;
- Evaluation 10 performed: **NO**;
- `CIV-40` / `CIV-41` started: **NO / NO**;
- goldens regenerated: **NO**;
- push attempted: **NO**.

`currentState` and `gates.F` carry semantically identical Evaluation 09,
Blocker 09, Gate F and next-action state. The next authorized action is
`NEW-INDEPENDENT-V4-GATE-F-v1-EVALUATION-10`.
