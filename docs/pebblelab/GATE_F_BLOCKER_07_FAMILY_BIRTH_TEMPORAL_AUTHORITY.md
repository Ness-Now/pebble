# Gate F Blocker 07 — Same-tick birth / Family house temporal authority

## Status

Gate F Evaluations 01–07: **FAIL — HISTORICAL IMMUTABLE EVIDENCE**

Gate F Blockers 01–07: **FIXED + PUBLISHED + REMOTE VERIFIED**

Gate F Blocker 07: **FIXED + PUBLISHED + REMOTE VERIFIED**

Gate F: **PLANNED — NOT ACQUIRED**

Evaluation 08: **NOT PERFORMED**

`CIV-40`: **OPTIONAL TOOLING — NOT STARTED**

`CIV-41`: **NOT STARTED**

The correction did not merge or rewrite Evaluation 07, acquire Gate F, start
another evaluation or phase, push, or regenerate goldens. Senior review
approved manual fast-forward, publication completed, and independent remote
verification passed.

| Publication identity | Value |
| --- | --- |
| product/test/runtime-proof commit | `61039c10763a478a55ea330ed4ad79881de0efb7` |
| published canonical blocker HEAD | `279fb26bea8a817b767a0192d8f7b1cffdff1563` |
| final review archive SHA-256 | `a5ba10ea140f4b2b6956519d1fc196709b1a5d100d77afcdbc32e7e86f42ad90` |
| senior review | **APPROVED FOR MANUAL FAST-FORWARD** |
| manual publication | **COMPLETED** |
| independent remote verification | **PASS** |

## Immutable Evaluation 07 identity

| Identity | Value |
| --- | --- |
| evaluated baseline | `c95729fcc38dc9cf5d251601a52e875e2ac9d5d3` |
| harness | `78f18936587a71a69b86f4726160e63396d7c62f` |
| final evidence | `826c81bc309ff14609f911cbb8471814e39695aa` |
| review ZIP SHA-256 | `d430c62c574011591d17368b35a179a4bf2fd248fdde6ecc5b792c66a8a2a05e` |
| blocker kind | `postBirthSameTickFamilyHouseTemporalAuthority` |
| focused blocker digest | `dca61d3a78dc2dcfab91e25eafa02c53bd2d95ae43e5a5673d5ce46646283706` |
| focused control digest | `eb527b2182f52484119211e0f34da6147ae4e99dc0c8d1df2df1603ab09bf840` |
| fresh-process blocker digest | `4a18ec846387c511b1eeb3464abd31a33a45e695e5a1858ef8d6f4f43b882229` |
| fresh-process control digest | `c89bad3e597cfa81085eabdafbfdc6dc26f88490175531921a6389b59c879a89` |

The correction branch is rooted at that published baseline. Both Evaluation
07 commits are explicitly absent from its ancestry.

## Root cause and authoritative boundary

`sharedParentalHouseAtBirth` reconstructed past Family authority from ticks
alone. It therefore treated a house founded after a birth during the same tick
as already present at birth.

The authoritative birth boundary is the parentage record's persisted
`sourcePopulationBornEventID`. It identifies the actual
`populationMemberBorn` publication. It is earlier than
`kinshipParentageRecorded`, household/Family/care registration and
`birthFinalized`. Using `recordedEventID` would make later bookkeeping rather
than population birth the historical boundary. Schema 35 already persists
both event IDs, so no schema field or new time model is needed.

## Canonical temporal policy

Historical Family questions now use one causal-boundary policy:

- a house founded on an earlier tick exists; one founded on a later tick does
  not; on the boundary tick its foundation sequence must be strictly earlier
  than the boundary sequence;
- a membership joined on an earlier tick exists; one joined on a later tick
  does not; on the boundary tick its join sequence must be strictly earlier;
- a membership with no exit is active; a later-tick exit is still active and
  an earlier-tick exit is inactive; on the boundary tick an exit earlier than
  the boundary is inactive while an exit later than the boundary is active;
- a nil boundary intentionally means current state through all transitions at
  the queried tick.

The strict comparisons match the existing `familyUnion(...beforeEventID:)`
policy. Durable event IDs remain sufficient even when their causal bodies have
been evicted from the bounded ledger.

## Audited surfaces

| Surface | Result |
| --- | --- |
| lifecycle birth transaction | passes `populationMemberBorn.eventID` as the authoritative boundary |
| `registerFamilyBirth` | selects the shared house and counts capacity at the birth boundary |
| `familyBirthEventCount` | intentionally queries current pre-birth state because it runs before publication |
| `.sharedParentHouseAtBirth` validation | recomputes against `sourcePopulationBornEventID` |
| expected membership for every parentage record | uses the same boundary helper |
| explicit adult join validation | accepting member is evaluated immediately before the join event |
| live cross-domain validation | uses the same `validateFamilyState` implementation as restore |
| schema-35 restore | uses identical strict semantics and remains byte exact |
| Family schema 25 | retained-cause compatibility is unchanged |
| Family schemas 26–35 | strict durable semantics are unchanged except for corrected causal ordering |
| unsupported schemas | still reject |
| current Family projections | remain based on open current membership, not historical inference |
| household/Estate tick queries | audited as separate household authority, not Family house reconstruction; unchanged |

## Focused correction proof

The dedicated `gate-f-blocker-07` selector runs 26 assertions in debug and
optimized configurations with byte-identical textual output.

### Exact post-birth same-tick trajectory

At tick 2 the authoritative birth sequence is 58 and parentage recording is
sequence 60. The union activates at 72, the co-founded house is published at
75, and founder memberships join at 76 and 77. Co-foundation succeeds. The
child has zero `sharedParentHouseAtBirth` memberships before checkpoint,
after schema-35 restore and after continuation.

A deliberately invalid co-foundation immediately before the valid retry is
atomic. Durable bytes and the next house ordinal remain exact; the successful
retry consumes `house-00000001` once.

### Same-tick pre-birth positive control

At tick 2 the union activates at sequence 60, the house is founded at 63 and
founder memberships join at 64 and 65. Birth publishes at 68 and parentage is
recorded at 70. The child receives exactly one
`sharedParentHouseAtBirth` membership and retains it exactly after restore.

### Remaining temporal matrix

| Case | Result |
| --- | --- |
| house on a previous tick | exactly one child birth membership |
| parent joins before birth in the same tick | counts at birth; exactly one child membership |
| parent joins after birth in the same tick | does not count; zero child memberships permanently |
| parent leaves before birth in the same tick | inactive at birth; zero child memberships |
| parent leaves after birth in the same tick | active at birth; exactly one historical child membership |
| required child membership removed | schema-35 restore rejects |
| unexpected post-birth child membership injected | schema-35 restore rejects |
| child membership changed to a wrong house | schema-35 restore rejects |
| same-tick event sequence manipulated | schema-35 restore rejects |
| birth/foundation/join event bodies evicted | durable IDs preserve exact truth and restore succeeds |

Every living scaled inhabitant retains one agent state, population membership,
settlement authority, lifecycle identity, fidelity record and current
household membership. Family periods contain no duplicate current authority.

## Fresh-process proof

Two fixtures each run as a writer process and a fresh restore/continuation
process in debug and optimized builds: eight OS processes total.

| Fixture | Child birth membership | Durable digest |
| --- | ---: | --- |
| post-birth same-tick house | 0 | `44c2e46d99f4193e92ed501261981462f9e518118628e9e897f28876cd2349ee` |
| same-tick pre-birth house | 1 | `5dfa1722379427d40757a65b18eae5c9bbb404091449b7c35d813fd101981b59` |

Debug and optimized artifact trees are byte-identical. Each restore matches
the exact saved durable bytes, Observer remains read-only schema 13, one
continuation tick succeeds, and replay counters for birth, house foundation
and child membership are all zero.

## Regression results

| Proof | Debug | Optimized |
| --- | ---: | ---: |
| Blocker 07 | 26/26 | 26/26 |
| Blocker 06 | 28/28 | 28/28 |
| Blocker 05 | 27/27 | 27/27 |
| Blocker 04 | 38/38 | 38/38 |
| Blocker 03 | 29/29 | 29/29 |
| Blocker 02 | 27/27 | 27/27 |
| Blocker 01 | 20/20 | 20/20 |

Fresh owning debug selectors:

| Domain | Result |
| --- | ---: |
| Family | 83/83 |
| lifecycle / reproduction | 80/80 |
| kinship | 79/79 |
| household | 71/71 |
| dependent care | 55/55 |
| Childhood | 62/62 |
| Estate | 88/88 |
| mortality | 93/93 |
| genetics | 46/46 |
| homeostasis | 30/30 |
| CIV-39 | 69/69 |
| population migration | 66/66 |
| embodiment / Core descent | 756/756 |
| physical food survival | 50/50 |
| autonomous civilization | 36/36 |
| material rights | 23/23 |
| renewable subsistence | 19/19 |
| ecological receipt/observation | 68/68 |
| production | 36/36 |
| barter | 56/56 |
| contracts | 32/32 |
| markets | 31/31 |
| Gate E E01 / E02 / E03 / E04 | 27/27 / 33/33 / 25/25 / 28/28 |
| Gate E evaluation continuity | 21/21 |
| checkpoint/replay | 49/49 |
| persistence/reconciliation | 19/19 |
| Observer | 20/20 |
| physical candidate atomicity | 3/3 |

Repository verification: **PASS — all 35 canonical steps, 4214/4214 smoke
assertions**. The gate used the checked-in goldens read-only.

## Compatibility and state

- checkpoint schema: **35**, unchanged;
- Observer schema: **13**, unchanged and read-only;
- `ROADMAP_MANIFEST.schemaVersion`: **3**, unchanged;
- goldens regenerated: **NO**;
- product correction: **YES**;
- Gate F acquired: **NO**;
- Evaluation 08 performed: **NO**;
- `CIV-40`/`CIV-41` started: **NO / NO**;
- push attempted: **NO**.

`currentState` and `gates.F` duplicate the same Evaluation 01–07, Blocker
01–07, Gate F acquisition/status and next-action state. The machine check must
remain green before review delivery.

The next authorized action after this reconciliation is reviewed, published
and remotely verified is `NEW-INDEPENDENT-V4-GATE-F-v1-EVALUATION-08`.
