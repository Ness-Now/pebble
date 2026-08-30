# Gate F Evaluation 12 — Independent Falsification Report

## Verdict

`Gate F Evaluation 12: PASS — LOCAL CANDIDATE — SENIOR REVIEW REQUIRED`

Gate F remains **PLANNED — NOT ACQUIRED**. Evaluation 12 found no reachable
material product contradiction in the seven required primary attacks. It made
no product correction, did not start `CIV-40` or `CIV-41`, did not push, and
did not regenerate goldens.

This is local evaluation evidence, not Gate F acquisition and not
authorization for a later program phase. The next action is independent senior
review of this Evaluation 12 candidate.

## Independent identity

```text
mission: NEW-INDEPENDENT-V4-GATE-F-v1-EVALUATION-12
repository: Ness-Now/pebble
canonical branch: origin/lab/pebblelab-v1
required evaluated baseline: 8733517720487cd7832a57b6d1ddf4b82fe56102
independently fetched remote: 8733517720487cd7832a57b6d1ddf4b82fe56102
evaluation branch: codex/gate-f-evaluation-12
branch root: 8733517720487cd7832a57b6d1ddf4b82fe56102
merge base: 8733517720487cd7832a57b6d1ddf4b82fe56102
product correction made: NO
product-source changes: 0
push attempted: NO
goldens regenerated: NO
```

The fetched remote, branch, merge base, worktree, applicable instructions,
canonical reports, Gate F workflow, Evaluation 12 authorization, and Gate F
state were verified before evaluation work. The branch was created directly
from the required baseline. No historical evaluation commit was merged,
cherry-picked, rebased, squashed, or inherited.

The evidence/docs commit and final HEAD are `null` in the committed JSON report
because a Git commit cannot contain its own object ID. Their materialized value
is recorded in the review archive and final handoff.

## Evaluation 12 harness identities

| Scope | Immutable commit |
| --- | --- |
| Attack 01 initial independent harness | `8b5b4f4fd7db8f5574c04abf24dff748b74032b4` |
| Attack 01 corrected/stabilized harness | `c2ea886c842038efb3f2b9aedb85afb5821af660` |
| Attack 02 | `a100b8932eecccac8f8dd9e23ab76189fa838719` |
| Attack 03 | `5f3634ca5078a24a779ecc4cb09b5b80d57b31bf` |
| Attack 04 | `a7848808984e75d0de1fb4ca9f01660ef9a354ce` |
| Attack 05 | `1cee534f5e245d8b874135fd86759da473d8f788` |
| Attack 06 | `7f54e699381009ac2c0d8787623f861473af5c43` |
| Attack 07 | `2b4a10f8f4d9b4743b835b292526aa0da14071d2` |

All eight commits change only `Sources/pebsmoke` evaluation harness/routing.
There is no product-source change in committed Evaluation 12 history or the
final worktree.

## Historical evaluation independence

Every canonical Evaluation 01–11 harness, focused, special fresh-process, and
final-evidence identity was checked individually against Evaluation 12 HEAD.

| Evaluation | Historical identities | Evaluation 12 ancestry |
| --- | --- | --- |
| 01 | `8f519d1ee9a8387117447057aa50b471b487143a`; `1cd056b6f74b4334cc6f63e969f3b629b3d79ae2` | both `NOT_ANCESTOR` |
| 02 | `fcc85fd95ab7acb3ba194fd75a664c4dda6b065d`; `6d30677fef504c51cc9f5847289e6206941b1d6c` | both `NOT_ANCESTOR` |
| 03 | `6732b7c1dcb1ec5fc1a01b560d6149d3a04778d5`; `9e66af9b0c4ccc9edcfb399fdf287b5a00f25b5d` | both `NOT_ANCESTOR` |
| 04 | `136b1ebed6a153166d0887722f8ca08adf2e9644`; `eb26347bbbdbd4954d8ed975e6ca30de97d14bd4` | both `NOT_ANCESTOR` |
| 05 | `d4140fef049d0bc30a062019fccdd752ff802908`; `0658f52cb2bb4283ce931f2b5760ed5572549151` | both `NOT_ANCESTOR` |
| 06 | `21523064810d10c30f10315397508431e34bb12a`; `60abe393aed274db84d1f07d23aae59bf7a032f2` | both `NOT_ANCESTOR` |
| 07 | `78f18936587a71a69b86f4726160e63396d7c62f`; `826c81bc309ff14609f911cbb8471814e39695aa` | both `NOT_ANCESTOR` |
| 08 | `40c664499a2ea69ae86378a85a8566b3d49e5642`; `fb87eefb8d0d9dae37d11e7f51974c07aedcb530`; `df56cf026bd75d6b28371e7b5948a77a97de2d35` | all three `NOT_ANCESTOR` |
| 09 | `8dd06f53289a6e66cc619ba5d45541d4dea4611e`; `e779e58df9d2350f0179d0c20ef70722522564ef`; `d200882d8e36f5f43eff0c52e163beb638f05cfc` | all three `NOT_ANCESTOR` |
| 10 | `0884ae7651853d94fae34f6cea0eae318c6709f7`; `36df11af2d535e15f091d0c2b7835785797eaf4f`; `b4792545dd0b585e3ad9739dcf2c950fa249d594`; `a8c9604c06a567d8b3921d6ce2031cbcc971d46b`; `626ca8785f4e54d0e1f9c5ae8aec56dff22f7ed9` | all five `NOT_ANCESTOR` |
| 11 | `650b4930d1474584eb947ebc2ea531ca10e2a965`; `2df178d6524f0c89465fb4508c39e7dc2e362fbf` | both `NOT_ANCESTOR` |

Checks: **27**; ancestors: **0**; not ancestors: **27**; result: **PASS**.

## Mandatory latest-blocker regressions

These ran before exploratory work against unchanged canonical product code.

| Regression | Debug | Optimized | Required contract retained |
| --- | ---: | ---: | --- |
| Blocker 11 | `27/27 PASS` | `27/27 PASS` | pending Mortality refuses singleton/move/mixed-member Household acquisition atomically; Household ordinal conserved; Household-before-Mortality cleanup supported |
| Blocker 10 | `20/20 PASS` | `20/20 PASS` | pending Mortality refuses new migration atomically; migration ordinal conserved; migration-before-Mortality inverse order supported |
| Blocker 09 | `32/32 PASS` | `32/32 PASS` | legacy Estate proof v1 compatibility and strict causal proof v2 semantics |
| Blocker 08 | `28/28 PASS` | `28/28 PASS` | strict Estate/schema-35 composition |
| Blocker 07 | `26/26 PASS` | `26/26 PASS` | exact birth/Family event-sequence authority |

After all primary attacks passed, the complete published Blocker 11→01 matrix
also passed in debug and optimized builds: B11 `27`, B10 `20`, B09 `32`, B08
`28`, B07 `26`, B06 `28`, B05 `27`, B04 `38`, B03 `29`, B02 `27`, and B01
`20` assertions per build. Total: **604/604**.

## Primary attacks

### Attack 01 — multi-history compaction × causal authority

Result: **PASS**. Focused debug and optimized: **21/21** each with equivalent
output. The supported composed history includes births, Household, Family,
lineage, guardianship, two migrations, Mortality, Estate v2, CIV-39 fidelity,
Material Rights, care, nourishment, and journey provisioning.

Critical sequence:

```text
e48 union activation
e53 Family house foundation
e101 first birth / e103 parentage
e111 migration out -> e209 arrival
e154 pre-plan sibling birth / e156 parentage / e161 guardian
e215 return migration start
e282 mortalityMaterialExitPending
e311 Estate successor plan v2
e318 death finalization
e323 post-plan material care / e325 later guardian
e329 post-plan birth refusal
e335 journey provisioning
e505 return arrival after fresh restore
```

The pre-plan full-sibling row remains historical; the later relationship does
not become retroactive. `guardianAtPlan=agent_1` remains exact while the current
guardian later becomes `agent_0`. The successor proof digest is stable across
both restores. Canonical compaction retains exactly `32/32` causal entries,
drops `336` at the first checkpoint (`496` after continuation), and retains
zero sensitive event bodies. No tick-only reconstruction occurs.

Fresh-process proof: writer, restore/arrive, and final reader in both builds,
**6/6 process phases PASS**. Seven decisive artifacts are byte-identical
between builds. The compacted checkpoint/durable hashes are
`be815f56169be9b59504907aabf0c05b87aaab3803ed7137860e8db12a15e6c5` /
`64a4b4b5f8314d393db5d94032ec730226fdd32c70e652f65586c3f635bfadd4`.
Population/fidelity/migration/Household/union/lineage/Family-house ordinals are
`5/6/3/4/2/3/2`; deaths and Estates are `1/1`. Replayed births, deaths, and
Estates are all zero. The B09 selector supplies the proportional genuine
legacy-v1 compatibility control; this attack did not fabricate a v1 proof.

Harness-development issues were correctly classified and retained as
non-product evidence: a wrong `unknownPerson` expectation; an unsupported
post-Mortality survival toggle; legitimate terminal custody of underfed
actors; over-assumed forage yield; nourishment boundary; occupied route cells;
and a forage patch made non-adjacent by a detour. The final trajectory uses
public care, nourishment, ecology, and physical navigation paths.

### Attack 02 — birth × death × migration × scale

Result: **PASS**. Focused debug and optimized: **11/11** each. Fresh writer,
finalizer, and final reader in both builds: **6/6 process phases PASS**; seven
artifacts are byte-identical.

```text
e48 migration start
e62 planned-birth refusal
e82 mortalityMaterialExitPending
e94 unrelated birth
e96 parentage
e100 guardianship
e115 memberDied migration cleanup
e120 death finalization
```

Birth-first guardian migration refusal is durable-byte atomic and leaves the
migration ordinal `1 -> 1`. Migration-first planned birth cancels without a
new identity. The unrelated newborn is published exactly once with one
resident, fidelity, Household, and guardian authority. Before finalization the
terminal migrant retains only pre-existing Household/in-transit authority
allowed by the owning cleanup contracts; finalization removes both. Final
ordinals are population/fidelity/migration/Household `4/5/2/3`; births,
deaths, and Estates replay zero times.

Harness-development issues were non-product: the canonical registry has the
three required founders `agent_0...agent_2`, and ecology frame order
legitimately changes whether starvation pressure makes a planned birth
admissible.

### Attack 03 — Gate E Material Rights × migration × restart

Result: **PASS**. Focused debug and optimized: **8/8** each. Three fresh
processes per build: **6/6 process phases PASS**; seven artifacts are
byte-identical.

```text
e40 asset registration -> e41 claim -> e42 recognized owner
e43 migration -> e44 use grant
e89 mortalityMaterialExitPending
e101 ACTIVE terminal-pending use revoke
e102 physical material exit
e107 Estate plan v2
e111 memberDied migration cleanup
e117 death -> e121 Estate settlement
```

Material Rights tracks actor/asset authority, not settlement custody. The
in-transit owner has zero resident and one transit authority without duplicate
settlement control. The domain-supported terminal-pending ACTIVE operation is
accepted; physical exit occurs once; Estate transfers the asset once to
`agent_1`; duplicate settlement mutates zero state; the third process sees no
death or Estate replay. Migration ordinal remains `2` and the singular claim
and rights record remain coherent. Earlier duplicated argument/closing-token
edits were harness transcription issues only.

### Attack 04 — physical arrival × civilization refusal atomicity

Result: **PASS**. Focused debug and optimized: **18/18** each. Three fresh
processes per build: **6/6 process phases PASS**; seven artifacts are
byte-identical.

Both public architectural cases were proved. The public prevalidation path can
refuse civilization admission before any physical candidate becomes
authoritative, consuming no event, identity, or ordinal. A real late refusal
is also reachable: a canonical Pebble/PebbleCore movement candidate is reached
inside a complete 3×3 ready-chunk envelope, civilization rejects arrival for
historical Household capacity, and Pebble restores the exact physical state.

```text
e23 migration start
e24 Household-capacity consumption setup
physical candidate reached
arrival refusal: household(historical household capacity reached)
arrival event: none
positive control arrival: e36
```

Before/after World entity IDs are exactly `agent_0,agent_1,agent_2`; physical
position is exactly restored to `(0.5,64.0,0.5)`; civilization checkpoint and
durable hashes remain
`79d66d9d2b4d118e8b79840208a91fe16dcbb045c24fa96ded1ba3d32732419c` /
`df2db212040eb58f686f3887bd2dca954b25e2e9de48a09faa923055b98278b6`.
Arrival and movement counts remain zero, migration remains in transit, and
Household/migration ordinals remain `4/2`. The third process observes no
arrival or movement replay. The initial one-chunk navigation fixture was a
harness setup deficiency, not a product contradiction.

### Attack 05 — evolved Family × Estate × scale after restart

Result: **PASS**. Focused debug and optimized: **15/15** each with byte-identical
output. Three fresh processes per build: **6/6 process phases PASS**; seven
artifacts are byte-identical.

```text
e311 Estate plan v2
e515 return migration arrival
e602 later half-sibling parentage
e753 grandchild parentage
```

Current full- and half-sibling truth is exact, the grandchild is present, two
lineages remain rooted at `agent_0` and `agent_1`, and one Family house remains
coherent. The historical Estate proof rows remain exactly
`agent_0,agent_1,agent_4`; later Family truth does not become retroactive.
Population/fidelity/migration/Household/union/death/Estate ordinals or counts
are `7/8/3/5/4/1/1`. Six live population IDs exactly equal the fidelity-owner
set. Replayed births, deaths, and Estates are zero.

### Attack 06 — high-contention same-tick causal interleaving

Result: **PASS**. Focused debug and optimized: **31/31** each with byte-identical
output. Writer/reader in both builds: **4/4 process phases PASS**; seven
artifacts are byte-identical. All sensitive events occur at tick `4`, but
persisted sequence—not tick equality—controls Estate history.

```text
control: pending e100 -> household e119 -> birth e122 -> parentage e124
         -> guardian e132 -> custody e136 -> lethal e137 -> plan e140
         -> death e146 -> migration e147

attack:  pending e100 -> custody e118 -> lethal e119 -> plan e122
         -> death e128 -> household e130 -> birth e133 -> parentage e135
         -> guardian e143 -> migration e147
```

The current relationship is `halfSibling` in both orders. The later sibling is
included in the historical proof only in the control order and excluded in the
plan-before-birth order. Each order has one death, one Estate, one migration,
one active care assignment, one guardianship, no dead current authority, and
zero replay.

### Attack 07 — cross-restart terminal authority composition

Result: **PASS**. Focused debug and optimized: **19/19** each with byte-identical
output. Forward and inverse writer/finalizer/final-reader chains in both builds:
**12/12 process phases PASS**; fourteen artifacts are byte-identical.

```text
forward: Household e22 -> pending e58 -> physical custody e67
         -> Estate plan e71 -> Household cleanup e75 -> death e78
         new migration refusal: true
         new Household refusal: true
         refusal mutations: 0

inverse: Household e36 -> migration e38 -> pending e63 -> custody e72
         -> Estate plan e76 -> memberDied migration cleanup e79
         -> Household cleanup e81 -> death e84
```

After restart, B10 and B11 refuse independently without stale in-memory
authority and consume no identity or ordinal. Inverse-order owning cleanup
removes population, fidelity, residence, migration, Household, and Mortality
current authority and finalizes exactly one death and Estate. Replay counters
remain zero.

## Current authority and identity accounting

Every reached attack uses one `AgentSimulationSession`. Applicable checks prove
unique population identities, one current settlement or one live migration,
one fidelity owner, at most one current Household, coherent Family/care,
singular Mortality/Estate outcomes, no dead current physical/civilization
authority, and read-only Observer projection. Refusals consume no population,
fidelity, migration, Household, Family, care, Mortality, Estate, or Material
Rights identity/ordinal. Compaction and restart do not permit reuse.

Across all final attack reports:

```text
duplicate population IDs: 0
duplicate current authority: 0
refusal mutations: 0
replayed births: 0
replayed deaths: 0
replayed Estates: 0
replayed arrivals/movements: 0
Observer mutations: 0
checkpoint schema: 35
Observer schema: 13
```

## Owning coverage and canonical verifier

The optimized owning matrix passed **1855/1855** assertions across 24
selectors: Household, Mortality, Lifecycle, Reproduction, Family,
Dependent Care, Childhood/Guardianship, Migration, CIV-39 scale/fidelity,
Checkpoint, Persistence/Reconciliation, Observer, Estate, Material Rights,
Gate E Evaluation/Blockers, physical atomicity/actions, Pebble/PebbleCore
embodiment, homeostasis, and autonomous civilization.

`scripts/verify-pebblelab.sh` was run from stage 1 and passed all **35/35**
stages and **4274/4274** assertions. The golden policy remained read-only and
refused `PEBBLE_REGOLD`.

## Scale campaign

The canonical `population_scaling_fidelity_smoke` scenario ran in debug and
optimized builds with seed `139`, `64` ticks, and the documented `24,64,128`
matrix. Both runs passed all six full/tiered configurations, exact restores,
schema 35, two settlements, exact population retention, bounded work, bounded
transition history, and internal durable-byte/tier-digest determinism.

At population 128, full mode performed `8192` live cognition executions.
Tiered mode performed `256` live, `192` near, and `448` dormant executions,
skipped `7936` full executions, retained all `128` agents and `128` transition
rows, and evicted `96` old rows. Debug/optimized determinism reports,
largest-tiered checkpoint, and scale state are byte-identical. Deterministic
digest: `6549c1168c52cffb`; checkpoint SHA-256:
`ff5fbee2a415f4fa3b32d36b1f7cf2964162ee5842e73e9db9ac4f2c7d45e105`.

The documented scaled-mortality exit/restore pair also ran in both builds:
**4/4 OS processes PASS**. Population is `23`, the terminal migration fails
once, late arrivals are zero, and all five durable artifacts are byte-identical
across builds. Checkpoint SHA-256:
`30b7e1781b6ce87766fc3a56ab5f99bce1e9ee78648f4d35a5dadac7b6a423c7`.
This supplies the scale-level B10/B11 terminal cleanup and restart control;
the dedicated B09/B10/B11 regressions remain independently green.

Rendered evidence was not run. It is supplementary; all evaluation judgments
here come from authoritative headless state, public physical paths, durable
bytes, and fresh OS-process restoration.

## Harness/scenario development classification

No development failure was reclassified as a product failure. In addition to
the Attack 01 and 02 issues listed above, later development encountered API
name transcription, depleted/non-adjacent forage, off-route in-transit forage,
care distance, shared Family-house assumptions, a future-guardian query,
Swift exclusivity, a missing route start, and an assumed plan-after-death order.
Attack 03 had a duplicated argument/delimiter; Attack 04 initially lacked the
canonical 3×3 ready-chunk envelope. Each was corrected only in evaluation
harness/setup and revalidated from scratch. Product semantics were unchanged.

## Program state

- Gate F Evaluations 01–11: **FAIL — HISTORICAL IMMUTABLE EVIDENCE**.
- Gate F Blockers 01–11: **FIXED + PUBLISHED + REMOTE VERIFIED**.
- Gate F Evaluation 12: **PASS — LOCAL CANDIDATE — SENIOR REVIEW REQUIRED**.
- Gate F: **PLANNED — NOT ACQUIRED**.
- `CIV-38`: **OPTIONAL — NOT STARTED**.
- `CIV-39`: **COMPLETE + PUBLISHED**.
- `CIV-40`: **OPTIONAL TOOLING — NOT STARTED**.
- `CIV-41`: **NOT STARTED**.
- checkpoint schema: **35**.
- Observer schema: **13**, read-only.
- `ROADMAP_MANIFEST.schemaVersion`: **3**.

No later phase is authorized by this local candidate. The required next action
is senior review of Evaluation 12; only an explicit senior decision may change
Gate F or program authorization.
