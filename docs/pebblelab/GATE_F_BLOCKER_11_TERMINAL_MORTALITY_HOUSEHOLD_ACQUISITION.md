# Gate F Blocker 11 — Terminal Mortality Household Acquisition

## Status

`V4-GATE-F-v1 Blocker 11: FIXED — LOCAL CORRECTION CANDIDATE — NOT PUBLISHED`

Gate F Evaluation 11 remains **FAIL — HISTORICAL IMMUTABLE EVIDENCE**. Gate F
remains **PLANNED — NOT ACQUIRED**. Evaluation 12 is **NOT AUTHORIZED — NOT
PERFORMED**. Senior review and manual publication are required before any new
evaluation campaign.

## Identity and topology

```text
mission: V4-GATE-F-v1-BLOCKER-11-CORRECTION
repository: Ness-Now/pebble
canonical branch: origin/lab/pebblelab-v1
evaluated and correction baseline: 35993c5652d79a8244f6a6e7f70709a2136a7939
independently fetched remote: 35993c5652d79a8244f6a6e7f70709a2136a7939
correction branch: codex/gate-f-blocker-11-terminal-mortality-household-acquisition
merge base: 35993c5652d79a8244f6a6e7f70709a2136a7939
product/test/runtime commit: 7d33d5f584089ad44ffcb0c64fcb00bb4d41779f
Evaluation 11 harness/fresh-process commit: 650b4930d1474584eb947ebc2ea531ca10e2a965 — NOT_ANCESTOR
Evaluation 11 final evidence/docs HEAD: 2df178d6524f0c89465fb4508c39e7dc2e362fbf — NOT_ANCESTOR
Evaluation 11 review archive SHA-256: a7802f7fa4141edd54d9b7ce67dd7962530253769ae570fe62001c2d5b1c9f3f
push attempted: NO
goldens regenerated: NO
```

The branch was created directly from the required published baseline. No
Evaluation 11 commit was merged, cherry-picked, rebased, squashed or inherited.

## Historical blocker

Evaluation 11 froze blocker kind
`terminalMortalityPendingHouseholdAcquisition`. At tick 4, the owning Mortality
aggregate had already published durable terminal authority for `agent_2`:

```text
t4/e58 mortalityMaterialExitPending agent_2
```

The pre-fix public singleton request then incorrectly accepted:

```text
t4/e67 householdCreated household_2
t4/e68 householdMembershipEnded agent_2 / household_1
t4/e69 householdMembershipStarted agent_2 / household_2
t4/e70 householdDissolved household_1
```

That transaction changed current residence authority from `household_1` at
`(4,64,0)` to `household_2` at `(8,64,0)` and consumed Household ordinal 2.
Later correct death cleanup could not retroactively legitimize this new current
authority after the terminal boundary.

## Corrected invariant and ownership

Once a persisted `AgentPendingMortalityTransition` exists for an existing
actor, that actor cannot acquire a **new** current Household/residence
authority. Mortality remains the sole owner of terminal-state truth.

The correction generalizes B10's Mortality-owned persisted-authority
prevalidator and applies it at the shared Household admission boundaries:

- initialization from existing residents;
- existing-member formation, including singleton and multi-member requests;
- move to an existing Household;
- root membership creation used by supported arrival/birth paths.

The predicate reads persisted pending Mortality transitions. It does not infer
terminality from `health == 0` or from a simulation tick. It runs before any
Household identity, event, membership, home or ordinal mutation.

Birth/bootstrap remains legitimate: a genuinely new actor cannot already own
an existing actor's pending Mortality transition. Mortality cleanup remains
allowed because it removes authority rather than acquiring it.

## Exact post-fix public result

The dedicated `gate-f-blocker-11` selector recreates the Evaluation 11 public
trajectory from canonical APIs. Its exact result is:

```text
t4/e58 mortalityMaterialExitPending agent_2
createSingletonHousehold(agent_2, (8,64,0), formedHousehold)
=> REFUSED ATOMICALLY

Household publications caused by request: 0
current Household: household_1 -> household_1
current home: (4,64,0) -> (4,64,0)
next Household ordinal: 2 -> 2
membership periods: 3 -> 3
next population ordinal: 3 -> 3
next fidelity transition ordinal: 4 -> 4
next migration ordinal: 1 -> 1
Mortality pending event: e58 -> e58
checkpoint bytes before/after refusal: IDENTICAL
durable-state bytes before/after refusal: IDENTICAL
```

No `householdCreated`, `householdMembershipEnded`,
`householdMembershipStarted` or `householdDissolved` event leaks. Navigation,
population residence, migration authority, fidelity owner, Family, care,
guardianship and Material Rights state remain unchanged. No death or Estate
identity is consumed.

## Control matrix

| Control | Result |
| --- | --- |
| pending Mortality before singleton acquisition | atomic refusal; zero publication; ordinal `2 -> 2` |
| pending Mortality before move to existing Household | atomic refusal; membership, home and durable bytes unchanged |
| healthy plus terminal member in one formation request | whole transaction refused; healthy actor untouched; no Household identity consumed |
| reason-specific `.formedHousehold`, `.birth`, `.migrationAdmission` requests for an existing terminal actor | all refused; no reason loophole |
| late Household initialization over an existing terminal actor | refused before publication |
| healthy singleton acquisition | accepted normally |
| Household before Mortality | accepted, then normal cleanup/finalization |
| existing care/guardianship and Household protections | preserved by owning suites |
| B10 pending before new migration | atomic refusal preserved |
| migration before Mortality | existing B10 inverse order preserved |
| finalized dead actor | cannot acquire Household authority through the public contract |
| unresolved pending across tick boundary | advancement refuses; Household acquisition remains refused |

The valid inverse control retains exact causal order:

```text
e36 householdMembershipStarted
e62 mortalityMaterialExitPending
e79 householdMembershipEnded
e82 agentDeathFinalized
```

One Estate and one death finalize. No dead current Household, population,
transit or fidelity authority remains.

## Household creation-path audit

| Path | Classification |
| --- | --- |
| `formHousehold(memberIDs:residenceAnchor:)` | SAME B11 INVARIANT — guarded at shared member prevalidation |
| `createSingletonHousehold(for:residenceAnchor:reason:)` | SAME B11 INVARIANT — funnels through guarded formation/root creation |
| `moveMembers(memberIDs:to:)` | SAME B11 INVARIANT — guarded before membership mutation |
| initialization for existing residents | SAME B11 INVARIANT — guarded before initial Household publication |
| root membership creation used by arrival/birth | guarded at shared acquisition boundary; genuine new-actor birth/bootstrap remains valid |
| migration admission and inter-settlement reconciliation | Household guard plus B10 Mortality-owned migration admission contract |
| Family/care-driven Household changes | guarded through the same Household admission boundary and owning actor-availability checks |
| mortality/death Household cleanup | TERMINAL CLEANUP — deliberately remains allowed |
| persistence/reconciliation | strict schema-35 validation; no authority minted by restore |

## Adjacent terminal-authority audit

The bounded audit found no separate reachable product contradiction:

| Domain | Classification |
| --- | --- |
| Family union, lineage and house acquisition | CORRECTLY GUARDED by healthy/physiologically-available actor contract |
| caregiver and guardianship acquisition | CORRECTLY GUARDED by the same availability contract |
| Household/current residence | SAME TERMINAL-AUTHORITY INVARIANT — fixed by B11 |
| settlement migration | SAME TERMINAL-AUTHORITY INVARIANT — already guarded by B10 persisted pending-Mortality authority |
| population/fidelity | CORRECTLY GUARDED by owning lifecycle-derived current authority |
| Material Rights | DOMAIN DELIBERATELY ALLOWS UNTIL FINALIZATION; active-actor operations and retained historical claims are distinct from physical custody |

Material Rights remains a historical/economic authority system, not a second
source of physical truth. No Observer, UI, LLM or God mutation authority was
introduced.

## Focused and fresh-process proof

Focused execution is deterministic:

| Configuration | Result |
| --- | ---: |
| debug | `27/27 PASS` |
| optimized | `27/27 PASS` |

Proof A uses three real OS processes: write a schema-35 checkpoint with pending
`e58`; freshly restore and atomically refuse the Household request, then run
normal Mortality cleanup/finalization; freshly restore the final checkpoint and
prove zero death, Estate or Household replay.

Proof B uses three real OS processes: create valid healthy Household authority
and checkpoint; freshly restore, reach pending Mortality and finalize cleanup;
freshly restore the final checkpoint and prove zero replay or Household
resurrection.

Both proof families ran in debug and optimized configurations: **12/12 process
phases PASS**. Their complete artifact trees are byte-identical.

| Debug/optimized-identical artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| pending initial checkpoint v35 | `65,345` | `2a0f510c255cbd8ff2316745b047cf09d71f8864fb7b0116c7e3ecf0c5dbb615` |
| pending initial durable state | `65,113` | `7d1f8906485545f81d1c4a62474ce50df5605b55446f8406ff80553989ebc0ec` |
| pending final checkpoint v35 | `75,073` | `7ee7d8f6fd48b3f7dafaafb4039f29b73291b9fac763f4c1a3d4c3f28343d370` |
| pending final durable state | `74,841` | `927c54902003e6c57e581765428752a19c97a8b72d55572ae7e2446aef6f4eda` |
| inverse initial checkpoint v35 | `44,620` | `e4018d4724513982ee3aca358ecef923defc5accb5d24d03d192f39f76b88a04` |
| inverse initial durable state | `44,388` | `01f253a5bb015fb724e10a3736abaa4c2ed73a90f62dc92cd5f0050213c6f580` |
| inverse final checkpoint v35 | `78,853` | `c8700c3ac90a14c811b91d91f1e74a7549f27af5d75a8bb2fed13dd315f57891` |
| inverse final durable state | `78,621` | `f2370f81b74db77bba7cb04627a786f8eb9f63a8ef6eecc28821fe2a38b9ba67` |

All 14 artifacts per configuration total `535,710` bytes. Debug and optimized
trees compare with zero differences.

## Persistence, replay and compatibility

- checkpoint schema remains **35**;
- Observer schema remains **13** and read-only;
- no persistence-format change was made;
- final fresh restores report death replay `0`, Estate replay `0` and Household
  resurrection `0`;
- B09 Estate proof v1 compatibility and strict causal v2 authority are
  unchanged;
- B10 pending-before-migration refusal and migration-before-Mortality cleanup
  are unchanged;
- no golden was regenerated.

## Published Gate F blocker regressions

Every published blocker selector ran in debug and optimized configurations:

| Blocker | Debug | Optimized |
| --- | ---: | ---: |
| B10 | `20/20 PASS` | `20/20 PASS` |
| B09 | `32/32 PASS` | `32/32 PASS` |
| B08 | `28/28 PASS` | `28/28 PASS` |
| B07 | `26/26 PASS` | `26/26 PASS` |
| B06 | `28/28 PASS` | `28/28 PASS` |
| B05 | `27/27 PASS` | `27/27 PASS` |
| B04 | `38/38 PASS` | `38/38 PASS` |
| B03 | `29/29 PASS` | `29/29 PASS` |
| B02 | `27/27 PASS` | `27/27 PASS` |
| B01 | `20/20 PASS` | `20/20 PASS` |

## Owning suites

Optimized owning coverage passed with zero failures:

| Selector | Assertions |
| --- | ---: |
| households | 71 |
| mortality | 93 |
| lifecycle | 80 |
| reproduction | 80 |
| dependent-care | 55 |
| childhood-guardianship | 62 |
| unions-family-lineages-houses | 83 |
| population-migration | 66 |
| civ-39 | 69 |
| checkpoint-replay | 49 |
| persistence-reconciliation | 19 |
| observer | 20 |
| estates-inheritance-succession | 88 |
| material-rights | 23 |
| homeostasis-health | 30 |
| Gate E Blockers 01–04 and Evaluation 05 | 27, 33, 25, 28 and 21 |
| candidate-physical-atomicity | 3 |
| physical-actions | 38 |
| embodiment | 756 |
| autonomous-civilization | 36 |

This covers Household, Mortality, Lifecycle, reproduction, Family,
dependent-care/guardianship, migration/CIV-39, population fidelity, checkpoint,
persistence/reconciliation, Observer, Estate v1/v2, Material Rights, Gate E,
physical atomicity, Pebble/PebbleCore embodiment and autonomous civilization.

## Canonical repository verification

The canonical verifier ran from stage 1 and completed normally:

```text
scripts/verify-pebblelab.sh
PASS: all 35 PebbleLab verification steps succeeded.
4274 passed, 0 failed
```

The earlier Codex quota interruption did not terminate the verifier and is not
a test failure. Its complete retained log proves the normal terminal PASS.

## Program state and non-claims

- Gate F Evaluations 01–11: **FAIL — HISTORICAL IMMUTABLE EVIDENCE**.
- Gate F Blockers 01–10: **FIXED + PUBLISHED + REMOTE VERIFIED**.
- Gate F Blocker 11: **FIXED — LOCAL CORRECTION CANDIDATE — NOT PUBLISHED**.
- Gate F: **PLANNED — NOT ACQUIRED**.
- Evaluation 12: **NOT AUTHORIZED — NOT PERFORMED**.
- `CIV-38`: **OPTIONAL — NOT STARTED**.
- `CIV-39`: **COMPLETE + PUBLISHED**.
- `CIV-40`: **OPTIONAL TOOLING — NOT STARTED**.
- `CIV-41`: **NOT STARTED**.
- `ROADMAP_MANIFEST.schemaVersion`: **3**.

This local correction does not publish itself, acquire Gate F or authorize
Evaluation 12. The next action is **SENIOR REVIEW + MANUAL PUBLICATION OF
BLOCKER11**.
