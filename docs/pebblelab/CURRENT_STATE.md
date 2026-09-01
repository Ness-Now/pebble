# Pebble Civilization — Current state

This file is the compact canonical status. It records product state, not the
SHA of the documentation commit that contains it.

## Acquired

- Gate R — No Parallel Physical Engines: **ACQUIRED AND PUBLISHED**.
- Gate B — Bounded Embodied Local Autonomy:
  **ACQUIRED AND PUBLISHED** under contract `V4-GATE-B-v1`.
- Gate C — Durable Observable Local World:
  **ACQUIRED AND PUBLISHED** under contract `V4-GATE-C-v1`.
- Gate D — Generational Continuity:
  **ACQUIRED AND PUBLISHED** under contract `V4-GATE-D-v1`.
- Gate E — Local Material Economy:
  **ACQUIRED AND PUBLISHED** under contract `V4-GATE-E-v1`, independently
  remote verified at canonical HEAD
  `076a616a97a229e921a5c36eebdfd12f76744f83`.
- Gate F — Durable Scaled World:
  **ACQUIRED AND PUBLISHED** under contract `V4-GATE-F-v1`, independently
  remote verified at canonical HEAD
  `14475f4ad5dde9e1063a830ba7e38390cfb4d045`.
- `CIV-00` through `CIV-37`: **COMPLETE AND PUBLISHED** in their bounded
  contracts.
- `CIV-37 — Physical Markets and Local Price Discovery V1`:
  **COMPLETE AND PUBLISHED** after senior-review approval of the implementation
  and Senior Review Correction 01.
- `CIV-38 — Currency, Units of Account and Accounting V1`:
  **OPTIONAL — NOT STARTED**.
- `CIV-39 — Multi-Settlement, Population Scaling and Fidelity Tiers V1`:
  **COMPLETE AND PUBLISHED** at independently remote-verified canonical HEAD
  `0b0ec535cda62b70add182875c65eaee27bb5bb2`, implemented from exact published
  baseline `e567f9a5b283a71e42b5f8139c47f80f6562a5dc`.
  Senior Review Correction 01 composes mortality/population exit with current
  multi-settlement, fidelity and migration authority at product/proof commit
  `2c9dc3fb4d2124b184ea81709a1165adc1831964`. Senior Review Evidence
  Reconciliation 02 at harness commit
  `605afd9c5cae864519bc8ddcd2aefb46a2c3ae75` reconciles every current CIV-39
  rendered Observer assertion to schema 13 and supplies a fresh passing
  two-process/six-capture campaign; historical schema-12 captures remain
  historical only. Senior review approved the final candidate for manual
  fast-forward and remote publication is verified.
- `CIV-40 — Training and Evaluation Bridge V1`:
  **OPTIONAL TOOLING — NOT STARTED**.
- `CIV-41 — Structured Knowledge and Belief Graph V1`:
  **LOCAL IMPLEMENTATION/REVIEW CANDIDATE — NOT PUBLISHED** on branch
  `codex/civ-41-structured-knowledge-belief-graph-v1`, implemented from exact
  published baseline `96030494c9bed8e356faae16dbd3c66dc9b4b652`. Independent
  senior review and any publication remain external. This does not advance the
  published program beyond `CIV-39`.
- Post-Gate-B safe-bootstrap hardening: **PUBLISHED**.

Gate F correction history:

- Gate F Evaluation 01: **FAIL — HISTORICAL IMMUTABLE EVIDENCE** for exact
  evaluated published baseline
  `29c8a7328f06748817abba1545acdb259a4d192a`.
- V4-GATE-F-v1 Blocker 01: **FIXED + PUBLISHED + REMOTE VERIFIED** at
  product/test/runtime-proof commit
  `54c5f4e9d1acab06a0fc44b2cd96dc74c04c72ec` and published canonical blocker
  HEAD `690c431d47f2e9edf9b1a9a9e91c71876981d09c`. Senior review approved manual
  fast-forward, publication completed and independent remote verification
  passed. The final review archive SHA-256 is
  `1a94f86a0e43154d7b8d64fdbce0f7fe5ac303417eda4821231fcd6a91061065`.
- Gate F Evaluation 02: **FAIL — HISTORICAL IMMUTABLE EVIDENCE** for exact
  evaluated baseline `c60eda84210cc8ed32f910f6f36ec29c1f747a9b`, harness
  `fcc85fd95ab7acb3ba194fd75a664c4dda6b065d`, final evidence HEAD
  `6d30677fef504c51cc9f5847289e6206941b1d6c` and review archive SHA-256
  `1e2f9f6da0fd8f05ae343393a51eddb0a2391b015f4db38afadf5f01ce7d27de`.
- V4-GATE-F-v1 Blocker 02: **FIXED + PUBLISHED + REMOTE VERIFIED** at
  product/test/runtime commit `7ec342dce329b611d418562383956bad40c9023d`
  and published canonical blocker HEAD
  `40ae812205abe231317e0d1720b5db4cecf9f24d`.
  It derives durable incoming slot claims from active schema-35 migration
  authority, refuses full destinations before publication and preserves exact
  arrival/death/failure/restart/compaction semantics. Senior review approved
  manual fast-forward, publication completed and independent remote
  verification passed. The final review archive SHA-256 is
  `bebd3b6c32b16db499b1285bea216768d5654c432529c239af9bbca166e37c35`.
- Gate F Evaluation 03: **FAIL — HISTORICAL IMMUTABLE EVIDENCE** for exact
  evaluated baseline `0407e8290aa98bde154cb98389893bcc577f830e`, harness
  commit `6732b7c1dcb1ec5fc1a01b560d6149d3a04778d5`, final evidence HEAD
  `9e66af9b0c4ccc9edcfb399fdf287b5a00f25b5d` and review archive SHA-256
  `153dd4acd9829979442c3d45b4de41fee5eb4170750f43cf9ceb2dd2ac6cbb80`.
- V4-GATE-F-v1 Blocker 03: **FIXED + PUBLISHED + REMOTE VERIFIED** at
  product/test/runtime commit
  `8358811204c35a79a4be202e57a28dfad4fb3e0f`. The shared CIV-39 scale owner
  now composes every supported dynamic member with one deterministic fidelity
  authority while lifecycle and migration retain membership ownership. Senior
  review approved manual fast-forward, publication completed at canonical
  blocker HEAD `2c6fe63e81b20ee4a37315a6f5ad528a721c2355`, and independent remote
  verification passed. The final review archive SHA-256 is
  `26c2cfb0326623c276bed2d7c3838394792d7e6f590b2a5aee41ea3cbdeb2a6f`.
- Gate F Evaluation 04: **FAIL — HISTORICAL IMMUTABLE EVIDENCE** for exact
  evaluated baseline `9b261c2bc513e1abfc31cdcf0acb64cdf035508c`, harness
  commit `136b1ebed6a153166d0887722f8ca08adf2e9644`, final evidence HEAD
  `eb26347bbbdbd4954d8ed975e6ca30de97d14bd4`, review archive SHA-256
  `4bfcd1ac27c89be8688e89ce0c3ada99cb1de5c47be7a7752e09e25520159e60`
  and deterministic blocker digest
  `5401cad6b29ffa07ec20c388601efd26847eb28305c1006e53046967698f5095`.
- V4-GATE-F-v1 Blocker 04: **FIXED + PUBLISHED + REMOTE VERIFIED** at
  product/test/runtime-proof commit
  `f1be1830c2d5903a0765d028fd7a3a0e821afec7`. Verified scaled arrival now
  closes origin household membership and creates one settlement-aware
  destination singleton household; unsupported active care, guardianship and
  child relocation refuses before physical movement. Checkpoint schema 35 and
  Observer schema 13 are unchanged. Senior review approved manual fast-forward,
  publication completed at canonical blocker HEAD
  `d7fac42493b229ce36ece5c21c597284e5ad7cb5`, and independent remote
  verification passed. The final review archive SHA-256 is
  `242bdcadcd4fe8ea54c5bacd812dfaae4231c6c9110e30958c6be715595c1c8c`.
- Gate F Evaluation 05: **FAIL — HISTORICAL IMMUTABLE EVIDENCE** against
  baseline `937693d6030f8ba77f1363da7f4336647962ee9e`, evaluation harness
  `d4140fef049d0bc30a062019fccdd752ff802908`, final evidence
  `0658f52cb2bb4283ce931f2b5760ed5572549151` and review archive SHA-256
  `c9c558a3f1b6f1f73a2bfc0ed8decf3efb386f6427ccfabb9ac91a2abd857753`.
  Its blocker kind is `schema35FamilyValidationComposition`, focused digest is
  `ec0735992cc9fead47b19c7ddb758b7215c8a0e832b380b95198406fac61b203`
  and fresh-process digest is
  `b76b5c182851508604c3df30bf0e59fd4f26b47fd549cfd2256ab85751a30bbd`.
- V4-GATE-F-v1 Blocker 05: **FIXED + PUBLISHED + REMOTE VERIFIED** at product/
  test/runtime-proof commit
  `b1f3fad3ec4959c1ecf43e91eac0d291d6f9acf4`. One canonical history-based
  Family compatibility policy preserves schema-25 retained-cause fallbacks,
  applies strict durable semantics to schemas 26–35 and makes live validation
  use the exact effective checkpoint schema. Senior review approved manual
  fast-forward, publication completed at canonical blocker HEAD
  `df1c042c0f8d4f45ad8928c9fb7d0bbe5558af8b`, and independent remote
  verification passed. The final review archive SHA-256 is
  `b27904bceba21901e87cdf8d1e9aedea3db65e9828606db4c46d5d829be2f689`.
- Gate F Evaluation 06: **FAIL — HISTORICAL IMMUTABLE EVIDENCE** against
  baseline `31f785ca9051be6b4f39ab97102f89410a776824`, harness
  `21523064810d10c30f10315397508431e34bb12a`, final evidence
  `60abe393aed274db84d1f07d23aae59bf7a032f2` and review archive SHA-256
  `441dbb02eb0589a90e2b75a06c1eee6dc254e5655350b2358df0b8a2bc92abb7`.
  Its blocker kind is `sequentialMigrationHistoricalArrivalValidation` and
  deterministic digest is
  `1795926d8b9452dc35284aa214c63f58c074c7febd165c7ab9865929d7d531d2`.
- V4-GATE-F-v1 Blocker 06: **FIXED + PUBLISHED + REMOTE VERIFIED** at product/
  test/runtime-proof commit
  `647dade73afa4d8e044423f422292dbf0c08f43e`. Restore now validates each
  retained migration intrinsically, enforces adjacent retained per-agent chain
  continuity and grants current residence/migration authority only to the
  latest retained record. Schema 35 and Observer schema 13 are unchanged.
  Senior review approved manual fast-forward, publication completed at
  canonical blocker HEAD `fe5bca7074b8ac65c31e03299195c3d7cfe307b1`, and
  independent remote verification passed. The final review archive SHA-256 is
  `ab2c496aa84af59cd1f3d72906cee55f8f8c7e381720165a5052a2b8d1807f6c`.
- Gate F Evaluation 07: **FAIL — HISTORICAL IMMUTABLE EVIDENCE** against
  baseline `c95729fcc38dc9cf5d251601a52e875e2ac9d5d3`, harness
  `78f18936587a71a69b86f4726160e63396d7c62f`, final evidence
  `826c81bc309ff14609f911cbb8471814e39695aa` and review archive SHA-256
  `d430c62c574011591d17368b35a179a4bf2fd248fdde6ecc5b792c66a8a2a05e`.
  Its blocker kind is `postBirthSameTickFamilyHouseTemporalAuthority`.
- V4-GATE-F-v1 Blocker 07: **FIXED + PUBLISHED + REMOTE VERIFIED** at product/
  test/runtime-proof commit
  `61039c10763a478a55ea330ed4ad79881de0efb7`. Historical shared-parent house
  authority now uses the persisted population-born causal boundary and strict
  same-tick house/membership sequence ordering. Schema 35 and Observer schema
  13 are unchanged. Senior review approved manual fast-forward, publication
  completed at canonical blocker HEAD
  `279fb26bea8a817b767a0192d8f7b1cffdff1563`, and independent remote
  verification passed. The final review archive SHA-256 is
  `a5ba10ea140f4b2b6956519d1fc196709b1a5d100d77afcdbc32e7e86f42ad90`.
- Gate F Evaluation 08: **FAIL — HISTORICAL IMMUTABLE EVIDENCE** against
  baseline `414954dc936177f892252898e97e8bcf986cee4b`, focused harness
  `40c664499a2ea69ae86378a85a8566b3d49e5642`, fresh-process proof
  `fb87eefb8d0d9dae37d11e7f51974c07aedcb530`, final evidence
  `df56cf026bd75d6b28371e7b5948a77a97de2d35` and review archive SHA-256
  `dc86ee24d0eef1a34f8ae0373ea0f1250463b2cbbf22a9b252fe827d11642da1`.
  Its blocker kind is `schema35EstateValidationComposition`.
- V4-GATE-F-v1 Blocker 08: **FIXED + PUBLISHED + REMOTE VERIFIED** at
  product/test/runtime-proof commit
  `518aaf0dddfcc9f63e133290bf6dd915f9eaa73a`. Estate checkpoint validation
  now has one canonical schema policy: schema 27 retains intended legacy
  successor-plan revalidation, schemas 28–35 require strict durable proof and
  live validation uses the effective aggregate checkpoint schema. Senior review
  approved manual fast-forward, publication completed at canonical HEAD
  `4e3bd296203346e4716c0a186017aebc69dbe750`, and independent remote
  verification passed. The final review archive SHA-256 is
  `c11b2d267a1dad40f52ad1bfe327981eaea1aae3419db8c80b45ab033421926b`.
  Schema 35 and Observer schema 13 are unchanged.
- Gate F Evaluation 09: **FAIL — HISTORICAL IMMUTABLE EVIDENCE** against
  baseline `b8f3d8cb05d0fa42cefc8d3f06d2e05fb7b0f8cb`, harness
  `8dd06f53289a6e66cc619ba5d45541d4dea4611e`, fresh-process evidence
  `e779e58df9d2350f0179d0c20ef70722522564ef`, final evidence
  `d200882d8e36f5f43eff0c52e163beb638f05cfc` and review archive SHA-256
  `79086413fd117a8c33a78a16430aafdd72b0c7492ec941c09399a615b1202816`.
  Its blocker kind is `postDeathSameTickSiblingEstateAuthority`.
- V4-GATE-F-v1 Blocker 09: **FIXED + PUBLISHED + REMOTE VERIFIED**, including
  Senior Review Correction 01. The initial product commit is
  `0607d9b291f3ed7a28eaa9ad887f4a2e7927e2c5`; SRC01 product commit
  `6a5ee92e89d14e1aff38d17c28d4e526eb51eb5f` distinguishes immutable published
  successor-proof v1 semantics from causal v2 semantics emitted by new plans.
  Strict v2 truth uses `successorPlanEventID` for parentage and terminal
  Mortality eligibility. The bounded audit also corrected
  `prePlanPendingSuccessorMortalityFinalizationRefusal`. Five affected old
  schema-35 fixture classes restore exactly, legacy pending-death continuation
  succeeds, and Observer schema 13 is unchanged. Manual publication and
  independent remote verification completed at canonical HEAD
  `482adc6617e258a73967e73c9d53cf1466c94f64`; the final review archive SHA-256
  is `09136811d4e6680dc6373e2c728509b91e2557a34a0dd10a9eeb421bd1d446e9`.
- Gate F Evaluation 10: **FAIL — HISTORICAL IMMUTABLE EVIDENCE** against exact
  canonical baseline `32c75984c56158bf9fde4918f6428e46cc7c1fa4`. Its independent
  evidence commits are `0884ae7651853d94fae34f6cea0eae318c6709f7`,
  `36df11af2d535e15f091d0c2b7835785797eaf4f`,
  `b4792545dd0b585e3ad9739dcf2c950fa249d594`,
  `a8c9604c06a567d8b3921d6ce2031cbcc971d46b` and final evidence HEAD
  `626ca8785f4e54d0e1f9c5ae8aec56dff22f7ed9`. Its blocker kind is
  `terminalMortalityPendingMigrationAdmission`; review archive SHA-256 is
  `39104a2b01f2bbe393f3437faee1daa2892f81505827ad9911ab28a823430d49`.
- V4-GATE-F-v1 Blocker 10: **FIXED + PUBLISHED + REMOTE VERIFIED** at
  product/test/runtime commit `470223bae3af44da29fd8830169ed14371dd3403`
  and canonical HEAD `104c919c3017cb73739c8839b47e5a011616e007`. The central settlement-migration
  admission boundary now refuses new authority for a persisted
  `mortalityMaterialExitPending` actor without publication or identity/ordinal
  consumption, while migration-before-mortality remains supported. Checkpoint
  schema 35 and Observer schema 13 are unchanged. The final review archive
  SHA-256 is `3e214e0f9dc0bc1cd1c885d6ff178fa0fe67ffd103741d88bc0e9618ee2a218d`.
- Gate F Evaluation 11: **FAIL — HISTORICAL IMMUTABLE EVIDENCE** against exact
  canonical baseline `35993c5652d79a8244f6a6e7f70709a2136a7939`. Its independent
  harness/fresh-process commit is
  `650b4930d1474584eb947ebc2ea531ca10e2a965`, final evidence HEAD is
  `2df178d6524f0c89465fb4508c39e7dc2e362fbf`, blocker kind is
  `terminalMortalityPendingHouseholdAcquisition`, and review archive SHA-256 is
  `a7802f7fa4141edd54d9b7ce67dd7962530253769ae570fe62001c2d5b1c9f3f`.
- V4-GATE-F-v1 Blocker 11: **FIXED + PUBLISHED + REMOTE VERIFIED** at
  product/test/runtime commit `7d33d5f584089ad44ffcb0c64fcb00bb4d41779f`
  and canonical HEAD `ab3302ee0c1fdcd90a40ba12dee555f3f445b793`. Its
  final review archive SHA-256 is
  `024f8197be6a5ec4608e5e7deb02196083bf95e15912ceed6dec73bff057c094`.
  Persisted pending Mortality refuses new Household/current-residence
  acquisition atomically; the valid Household-before-Mortality cleanup order
  remains supported. Checkpoint schema 35 and Observer schema 13 are unchanged.
- Gate F Evaluation 12 is **PASS — SENIOR REVIEW APPROVED — PUBLISHED EVIDENCE**
  against exact baseline `8733517720487cd7832a57b6d1ddf4b82fe56102`.
  Its seven primary attacks, complete B11→B01 regression matrix, owning
  coverage, 35-stage verifier and canonical 24/64/128 scale campaign passed.
  Senior review approved the evidence published at canonical HEAD
  `b31a7e53cfcf7a5c3ab6419f3cb5c0c309f04112`; its accepted review archive
  SHA-256 is
  `ca7e70799220b58c3b090716a2adf19e8abb2609d465b7139d25f7f59988af4c`.
- Gate F is **ACQUIRED AND PUBLISHED — REMOTE VERIFIED** at acquisition
  canonical HEAD `14475f4ad5dde9e1063a830ba7e38390cfb4d045`.
- The next eligible required phase and authorized action is `CIV-41`; this
  reconciliation does not start it.

Published Gate E history:

- Gate E Evaluation 01: **FAIL — HISTORICAL IMMUTABLE EVIDENCE**.
- V4-GATE-E-v1 Blocker 01: **FIXED + PUBLISHED + REMOTE VERIFIED**.
- Gate E Evaluation 02: **FAIL — HISTORICAL IMMUTABLE EVIDENCE**.
- V4-GATE-E-v1 Blocker 02: **FIXED + PUBLISHED + REMOTE VERIFIED**.
- Gate E Evaluation 03: **FAIL — HISTORICAL IMMUTABLE EVIDENCE**.
- V4-GATE-E-v1 Blocker 03: **FIXED + PUBLISHED + REMOTE VERIFIED**.
- Gate E Evaluation 04: **FAIL — HISTORICAL IMMUTABLE EVIDENCE**.
- V4-GATE-E-v1 Blocker 04: **FIXED + PUBLISHED + REMOTE VERIFIED**.
- Gate E Evaluation 05:
  **PASS — SENIOR REVIEW APPROVED — PUBLISHED EVIDENCE**.

Evaluation 05 evaluated published product baseline
`9d841cc28dd4a43f70aff6265ead2e25fa6f160c`. Accepted evidence commits are:

```text
cccd531dbe2a640a80844482b8943f7cf2f32563
91b60d230f4ff314f44582e773d36d3366ebd927
d511ccd377be762444cf57ba0ef050f66c57a3b1
6332656566e507464e5322742dc0675d91067a57
```

The accepted final evidence HEAD is
`6332656566e507464e5322742dc0675d91067a57`; the senior-review archive SHA-256
is `9960f586cf7d2efca2ae235e2e878e5e2e289f0a095ae3161cb2aa5f61ebb5f4`
with archive integrity PASS and 205/205 internal checksums PASS.

The Gate E acquisition commit is published and independently remote verified
at canonical HEAD `076a616a97a229e921a5c36eebdfd12f76744f83`.

Blocker 01 binds exact production origin to an exact durable Material Rights
asset. It is product correction publication evidence, not Gate E acquisition
evidence.

Published canonical baseline evaluated by independent Gate D Evaluation 04
and affected by Gate D Blocker 04:

```text
4b11c93abd36a1a1c61d491df1e5efa6607f6206
```

Published Gate D Blocker 04 product-fix head:

```text
cca372bb841846db4b1010d26456bcc245b07c3e
```

Published baseline evaluated by independent Gate D Evaluation 05 and used as
the direct base for the published Blocker 05 correction:

```text
1fa033173609b8cc6ff8a3c4f09cb0e6b0ec8a9e
```

Published Gate D Blocker 05 product-fix head:

```text
d60e4f2dad11f02c184d8e7ae85b9bbdc9fe7712
```

Published baseline evaluated by independent Gate D Evaluation 06 and used as
the direct base for the published Blocker 06 correction:

```text
82a2e50da4db2fe861b88801e033788a2de16dd4
```

Published Gate D Blocker 06 product-fix head:

```text
780ea9d7137b728d0fc4873152479f65ebe57d18
```

Published baseline evaluated by independent Gate D Evaluation 07 and used as
the direct base for the published Blocker 07 correction:

```text
bbafcb51ef0d8387e95302a134ec038fbb8dffa6
```

Published Gate D Blocker 07 product-fix head:

```text
650b56b90381306c38d891dfdade9d89a1c45db5
```

Published baseline evaluated by independent Gate D Evaluation 08 and used as
the direct base for the published Blocker 08 correction:

```text
02c7778769c8a6d971f4eb8bd73e5a3f7afc8c1e
```

Published Gate D Blocker 08 product-fix head:

```text
a7f1fd7bf92a6d049d7601945209eb9c98d06058
```

Published baseline evaluated by independent Gate D Evaluation 09 and used as
the direct base for the published Blocker 09 correction:

```text
4ea6fba4b615d72a96087bb98bf5bbca4b560e4b
```

Published Gate D Blocker 09 product-fix head:

```text
ee742afb41fda44c77d8b98f868fbe759934057e
```

Published baseline evaluated by independent Gate D Evaluation 10 and used as
the direct base for the published Blocker 10 correction:

```text
55e513becac622e2f7f258f10ec406d26865eb6a
```

Published Gate D Blocker 10 product-fix head:

```text
6ec700640dfe806f32da62fe7d7315c64fdb8f74
```

Published product baseline evaluated by independent Gate D Evaluation 11:

```text
24c679581f7dfd93d26bffa2e9486a5340af0d9c
```

Accepted Evaluation 11 evidence commits:

```text
f55b64305027bee3fb67a2e27b422578124c4e00
39f6b8bc464319b4ee3879686bab3af5fcf63e83
```

The `CIV-33` completion, renewable-subsistence milestone and Gate D Blockers 01
through 10 are published on the canonical branch. Independent Gate D
Evaluations 01 through 10 remain immutable historical FAIL evidence for their
evaluated baselines. Evaluation 11 is the first accepted PASS and senior review
approved it as the complete whole-Gate evidence. Gate D acquisition is
published and independently remote-verified at canonical head
`61fbf406713127b0993a7294020433e1e3c3fa39`. `CIV-34` is complete and
published from baseline `1bbf3df08ca8a05c79af61c888c424e52bb30801`.
Its product implementation is
`73db4cd7fbf1aff86a23aacb8928ca460774696e`; senior review approved reviewed
evidence HEAD `24f0f72aae7543177ca746e892c57482496dabef` and bundle SHA-256
`8a00bfef38c7d93dae0eff6867d58bc4d05bc872fb72b00f83616367dd682b6d`.
The accepted CIV-34 proof covers canonical crafting, the transactional live
gateway, the normal autonomous path, schema-31 restart, Observer schema 8 and
downstream produced-tool use. `CIV-35 — Barter and Local Exchange V1` is
complete and published from exact baseline
`8b7faa4cd03e315dec5696f72ec1ad75e333c77f`. Its original product commit is
`144bcaf162b37f92b151ec2180c0bd9be294adce`. The first candidate documentation
HEAD `b80b6bdda4345cd002ed34296dea92562cbb5fc1` was not independently approved:
senior review found that normal barter discovery/negotiation was
proof-fixture-bound and terminal offers could permanently exhaust
`maximumOffers`. Senior Review Correction 01 fixed both defects at product
commit `43c6b6ba00fee879918125cb9cffd79e653c49fc`. Senior review then approved
corrected evidence HEAD `1dbe84fdc9286b35e05a0aaaf8673ec0ce99718a` and review
bundle SHA-256
`c26a79fa7641e2da534f4bf18954bdbe50635d6bc9306be55a7b705af321e41d`
with 37/37 internal checksums and passing unzip validation.

The corrected normal runtime derives explicitly bounded local physical pair
observations from current Pebble custody/proximity evidence, while the sole
session selects the offer and the named counterparty independently evaluates
its current need and local evidence. The disposable proof injects neither the
decisive opportunity nor either decision after bootstrap. Deterministic
oldest-terminal compaction keeps offer projections bounded without ever
evicting open or accepted authority; 24 attempts against an eight-offer focused
cap remain sustainable across schema-32 restart. The decisive route exchanges
agent_0's real CIV-34 stone pickaxe for two breads held by agent_1, compensates
a true post-first-transfer fault exactly, retries successfully, restores once
across a fresh process and uses the exact received pickaxe. Observer schema is
9.

`CIV-36 — Debt, Promises and Durable Contracts V1` is complete and published
from
exact published baseline `e47c2d1a4132dc756219ef0d2c1495b2769b8d35` at
product/proof commit `a910f938c0e943e37aa851c0f65dfecdb06698cc`. The sole
session owns explicit future promises, distinct acceptance, durable
obligations, due boundaries and bounded terminal-only compaction. A promise
creates no matter. Only verified current consideration opens debt; only a
later exact physical performance transfer closes it. Pebble reuses CIV-26
Material Rights, CIV-34 production, the material-custody gateway and the
candidate physical transaction. Schema 33 restores open debt and fulfilled
history; replay schema 33 moves no World matter; Observer schema 10 is
read-only. Senior review of pre-correction candidate HEAD
`4c7af994fc52974f6f919765af682b209f6b84ca` found two defects. Correction 01A
discloses that ordinary post-physical publication failures were not guaranteed
to escape autonomous blocked handling and could bypass candidate rollback.
Correction 01B discloses that current asset-scoped authority was reacquired but
its current custody fingerprint was discarded in favor of a historical
full-custody fingerprint. Product/proof commit
`76adcba62ac901b01618bea58fba32e1d5dc0d02` corrects both: complete predictable
publication is prevalidated before World mutation, every error after newly
registered candidate compensation escapes and rolls back, and both physical
legs use reacquired `currentCustodyFingerprint` immediately while preserving
exact tracked-asset and CIV-26 rights checks. Focused validation passes 30/30,
the repository gate passes 35/35 with 3892/3892 assertions, and an inspected
four-process campaign proves zero-mutation capacity refusal, unrelated-slot
drift tolerance, ordinary consideration rollback, explicit and ordinary
fulfillment rollbacks, open-debt restart, normal bread production, exact retry,
exact-once fulfillment and fulfilled restart. Senior review approved the
corrected reviewed evidence/documentation HEAD
`3494abea0211a843ca54bb0748b1a6d9bdbddd3f` and final review bundle SHA-256
`7947b0ae2e1c86a551403d24f3d75769e8203baf43f8b0e5958a94d038d21951`
with 47/47 internal checksums and passing unzip validation. The initial
candidate HEAD `4c7af994fc52974f6f919765af682b209f6b84ca` was not
independently approved.

`CIV-37 — Physical Markets and Local Price Discovery V1` is **complete and
published** from exact baseline
`9f13ffee3f312caaaa68ddd6f2c2c27e5942474e` at product/proof commit
`e279362e1d5b71ed82d20e2f17e492fa22579c37`. Senior Review Correction 01
starts from reviewed candidate HEAD
`f96f84a61b72e115de668966f470feef986de925` and is implemented at
`21ed1b550f9c54381e54c3c763d2ff494bda7d57`; correction documentation is
`68f878abb0408984571f802c10079001e70c9aa7`, and the corrected reviewed HEAD is
`7a2a2b7e21fe773ca7583e6bfcefd20f2756c5d8`. Correction 01A records that the
initial candidate did not revalidate current seller/buyer World locality at
the decisive seller-decision and settlement boundaries, so historical
locality could potentially authorize remote settlement. Correction 01B
records that the initial seller decision was unconditional `accept=true` and
a quantity-bearing seller need could be marked fulfilled despite receiving
less than its required quantity. Both are corrected and senior-review
approved. The accepted review bundle SHA-256 is
`7a0b48bb69f67b541670bfb91f7720ee0c19cfb5a5ca922bf8ac16a4902796bd` with
55/55 internal checksums and passing unzip validation. One real nine-slot
chest at `18,69,-21` anchors local discovery, verified physical deposits,
listings, negotiation, three-endpoint settlement and physical withdrawal. The
seller keeps ownership while deposited matter is in market custody. Exact
oriented integer barter terms create market-local price rows only after both
real legs and civilization publication succeed. Open custody, completed
trades and price provenance survive schema-34 fresh-process restart; replay
schema 34 executes no World matter and Observer schema 11 is read-only.
Terminal-only compaction preserves active authority.

The corrected runtime rebuilds current market/container, alive embodiment,
distance and chunk evidence for both participants before normal seller
decision and immediately before settlement. A remote buyer after reservation
moves zero matter and publishes zero trades and prices; returning before the
bounded expiry permits coherent retry. Verified local deposit is the explicit
V1 authority for one exact automatic listing. Generic deterministic seller
cognition rejects the one-bread counteroffer and later accepts two bread. A
seller needing three bread and receiving two remains active; the buyer needing
one pickaxe and receiving one is fulfilled. Restored same-market price history
selects two bread against a current seller reason of three, while foreign
history remains unable to influence the decision.

The four-process rendered campaign also proves both exact candidate rollbacks
after real settlement mutations, an immediate successful retry, a later
history-informed one-pickaxe/two-bread quote and second trade, expired unsold
oak-log withdrawal, final restart without reexecution and exact disposable-cell
cleanup. The fixture seeds ordinary,
physically real, rights-tracked goods; it does not claim that those goods were
actually produced through CIV-34. Focused validation passes 31/31 and the
canonical gate passes 35/35 with 3923/3923 assertions. At that CIV-37
publication boundary, CIV-38 remained optional and not started, and Gate E
remained planned and not acquired; its independent composition evaluation was
not part of that publication.

Gate E Evaluation 01 evaluated exact published baseline
`5bc9d3088c2550fb042fe065235cb0154a226ff0` and remains immutable **FAIL —
PRODUCT CORRECTION REQUIRED** evidence at HEAD
`e75ab82981169baf1cdc67d9454e6d569e989167`; its bundle SHA-256 is
`9db1a5b478f1ed0ca9efcac5612efc29928b61143a92e198123285920444fc93`.
Senior review approved the exact produced-asset provenance correction at
product commit `9a623d48f300245b0d348da0b7b72762043b93ff`, reviewed candidate HEAD
`534fd927483a692e26de7f929a361c34e77870a7` and review bundle SHA-256
`dbbdd076cf4c90a753b138e470583fd63b982f9ebe2c8f2440c08c227bc4a163`
with 47/47 internal checksums.

The published correction binds production origin once to the exact durable
`AgentMaterialAssetID` while authoritative production evidence is available.
CIV-35 and CIV-36 consume only that asset-bound provenance, while current
physical holder, identity, quantity and custody fingerprint remain separate
mutation authority. The decisive three-bread case attributes only P3 and
quantity one, fails ambiguity closed, preserves origin across transfer and
restart, refuses fulfillment while the exact asset is displaced, and fulfills
once after the same asset returns. Focused Blocker 01 checks pass 27/27, owning
regressions pass 270/270, and the repository gate passes 35/35 with 3950/3950
assertions. The two-process live proof has nine inspected captures and zero
unexpected runtime errors, physical loss, physical duplication, synthetic
material or Observer mutation. Goldens were not regenerated.

Gate E Evaluation 02 evaluated exact published baseline
`9ede5d73229c3c9284d163ed17cc76bcf92ebe0e` and remains immutable **FAIL —
PRODUCT CORRECTION REQUIRED** evidence at HEAD
`2f95826f474c9f2a366f4b06df90a8643beb7a98`; its bundle SHA-256 is
`4e10d129927af5c8443f9f8e26fec0d276f797cf82126b93792f32c26c646d57`.
Senior review approved the evolved produced-asset identity correction at
product commit `a67665e87774a4af8fcc7930e05c8747da1f83fc`, reviewed candidate HEAD
`b8dbeef60865a4fd452ca5abaac4a005ded2e592` and review bundle SHA-256
`68ab04428582cbbe96c0e8bf046f45c22818a6dd9018ad6f808c87b9aea30c31`
with 59/59 internal checksums.

The published correction preserves immutable production origin while current
identity evolves only through the existing durable Material Rights continuity
contract. Current holder, exact identity, quantity and custody fingerprint
remain separate physical authority. Focused Blocker 02 checks pass 33/33,
owning regressions pass 301/301, the dedicated Blocker 01 regression remains
green, and the repository gate passes 35/35 with 3983/3983 assertions. The
two-process live proof has eight inspected captures and zero physical loss,
physical duplication, synthetic material, duplicate receipts or Observer
mutation. Goldens were not regenerated. At that Blocker 02 publication
boundary, its containing commit did not claim future remote verification.

Gate E Evaluation 03 evaluated exact published baseline
`bfb721d7f49f8af567c86580cdf4c106da977a25` and remains immutable **FAIL —
PRODUCT CORRECTION REQUIRED** evidence at HEAD
`56af9648da0155cfba25588320d2070d211a1cd7`; its bundle SHA-256 is
`c3e203e507ff8fd28781b9a067317493fd348e839e6e0b8386d95d18251af883`.
The historical result is permanently recorded as **FAIL — HISTORICAL
IMMUTABLE EVIDENCE** and is not in the correction ancestry.

Senior review approved the terminal market reservation authority correction at
product commit `301dfd58aacd3aa0af653fa460ad38484df1d762`, reviewed candidate
HEAD `27e8406edd20f13817d4b7e1684a00db56e361a7` and review bundle SHA-256
`8ec57b6bb8b58cab59be3024f7541693b145ae0527221e5e523b32538a2182a4`
with 87/87 internal checksums and passing ZIP integrity.

The published Blocker 03 correction derives current market reservation authority
from coherent live proposal, listing and deposit state. Proposed/open/listed
and accepted/reserved/reserved triads reserve strictly; an accepted proposal
retained with completed/sold terminal history does not. Current physical
holder, ownership/custody, exact identity, quantity, fingerprint and locality
remain separate mutation authority. Focused Blocker 03 checks pass 25/25,
owning regressions pass 301/301, Blocker 01 and 02 focused checks pass 27/27
and 33/33, and the repository gate passes 35/35 with 3983/3983 assertions.
The four-process rendered campaign has 16 inspected captures, schema-34
restart and schema-11 Observer evidence, and zero physical loss, physical
duplication, synthetic material, duplicate deposits, duplicate reservations,
duplicate receipts or settlements, Observer mutation or unexpected runtime
errors. Goldens were not regenerated. At that Blocker 03 publication boundary,
its containing commit did not claim future remote verification.

Gate E Evaluation 04 evaluated exact published baseline
`e8bc2fc8add491c324f15478fcd1b82d77566d57` and remains immutable **FAIL —
PRODUCT CORRECTION REQUIRED** evidence at HEAD
`07ded1e583b62137b5e8b6cc32d8a61ead73cc53`; its review archive SHA-256 is
`d51df031d8cf930316ad0a24f1c21daa2f773cdec576599d3549139cfce7559b`.
Its decisive counterexample made
one exact durable pickaxe simultaneous accepted contract and market
consideration, retained both commitments across restart, then let market
settlement move exact current authority while the contract retained stale
custody evidence. The historical result is permanently **FAIL — HISTORICAL
IMMUTABLE EVIDENCE** and is not in the correction ancestry.

The published Blocker 04 correction adds one deterministic, derived exact-asset
commitment authority to the existing `AgentSimulationSession`. It composes live
barter, contract and market state, allows only the same logical operation to
continue its commitment, and releases terminal state without erasing history.
Physical gateways and exact current Material Rights remain independently
mandatory. Verified economic receipts fulfill the exact motivating production
need once. No durable projection was added: checkpoint/replay remains schema
34 and Observer remains schema 11 and read-only.

Senior review approved implementation commit
`0318133fe95949c441974871f2581f38c43c6128`, reviewed candidate HEAD
`54009009e436c913276e50c162cd30203d8931c3` and review archive SHA-256
`f36ba77cc2c58e75b70748892043f72c4703668df1da4291c36f4e828a723b9f`.
Archive integrity and all 118/118 internal checksums pass. Focused Blocker 04
checks pass 28/28, owning regressions pass 305/305, Blocker 01 through 03
focused checks pass 27/27, 33/33 and 25/25, and the repository gate passes
35/35 steps with 4015/4015 assertions. The fresh four-process live campaign
has 13 inspected captures; auxiliary live regressions add eight processes and
33 captures. Checkpoint schema 34, Observer schema 11, exact cleanup and zero
physical loss, physical duplication, synthetic material, duplicate live
commitments, deposits, reservations, receipts, settlements, Observer mutations
or unexpected runtime errors are preserved. Goldens were not regenerated.
Currency remains outside the Gate E dependency and CIV-38 remains optional.
The earlier Blocker 04 containing commit did not itself claim future remote
publication verification; that historical boundary is preserved.

Independent Gate E Evaluation 05 is the first accepted complete Gate E PASS.
Senior review approved its 21/21 focused assertions, 305/305 owning assertions,
Blocker focused/live reruns, 35/35 repository steps with 4015/4015 assertions,
17-process/54-capture decisive live campaign and 8-process/33-capture auxiliary
campaign. All 87 final captures were inspected. Checkpoint/replay schema 34 and
Observer schema 11 remain unchanged. Physical loss, physical duplication,
synthetic material, duplicate live commitments, deposits, reservations,
receipts, settlements, Observer mutations and unexpected runtime errors are
all zero; cleanup is exact. No product correction or golden regeneration was
performed. Evaluations 01–04 remain immutable historical FAIL evidence and
Blockers 01–04 remain fixed, published and remote verified. Evaluation 05 and
the Gate E acquisition are now published and independently remote verified.

## Current program position

```text
active CIV phase: CIV-41 — LOCAL IMPLEMENTATION/REVIEW CANDIDATE — NOT PUBLISHED
completed and published through: CIV-39 (CIV-38 remains optional and unstarted)
next eligible action: independent senior review of CIV-41 local candidate
next authorized action: CIV-41 independent senior review / publication decision
CIV-33 status: COMPLETE AND PUBLISHED
V4-GATE-C-v1 status: ACQUIRED
V4-MILESTONE-RENEWABLE-SUBSISTENCE-v1 status: COMPLETE AND PUBLISHED
V4-GATE-D-v1 status: ACQUIRED AND PUBLISHED
Gate D Evaluation 01 status: EVALUATED_FAIL_NOT_ACQUIRED — HISTORICAL EVIDENCE
Gate D Blocker 01 status: BLOCKER_FIX_PUBLISHED
Gate D Evaluation 02 status: EVALUATED_FAIL_NOT_ACQUIRED — HISTORICAL EVIDENCE
Gate D Blocker 02 status: BLOCKER_FIX_PUBLISHED
Gate D Evaluation 03 status: EVALUATED_FAIL_NOT_ACQUIRED — HISTORICAL EVIDENCE
Gate D Blocker 03 status: BLOCKER_FIX_PUBLISHED
Gate D Evaluation 04 status: EVALUATED_FAIL_NOT_ACQUIRED — HISTORICAL EVIDENCE
Gate D Blocker 04 status: BLOCKER_FIX_PUBLISHED
Gate D Evaluation 05 status: EVALUATED_FAIL_NOT_ACQUIRED — HISTORICAL EVIDENCE
Gate D Blocker 05 status: BLOCKER_FIX_PUBLISHED
Gate D Evaluation 06 status: EVALUATED_FAIL_NOT_ACQUIRED — HISTORICAL EVIDENCE
Gate D Blocker 06 status: BLOCKER_FIX_PUBLISHED
Gate D Evaluation 07 status: EVALUATED_FAIL_NOT_ACQUIRED — HISTORICAL EVIDENCE
Gate D Blocker 07 status: BLOCKER_FIX_PUBLISHED
Gate D Evaluation 08 status: EVALUATED_FAIL_NOT_ACQUIRED — HISTORICAL EVIDENCE
Gate D Blocker 08 status: BLOCKER_FIX_PUBLISHED
Gate D Evaluation 09 status: EVALUATED_FAIL_NOT_ACQUIRED — HISTORICAL EVIDENCE
Gate D Blocker 09 status: BLOCKER_FIX_PUBLISHED
Gate D Evaluation 10 status: EVALUATED_FAIL_NOT_ACQUIRED — HISTORICAL EVIDENCE
Gate D Blocker 10 status: BLOCKER_FIX_PUBLISHED
Independent Gate D Evaluation 11 status: PASS — SENIOR REVIEW APPROVED — PUBLISHED EVIDENCE
CIV-34 status: COMPLETE AND PUBLISHED
CIV-35 status: COMPLETE AND PUBLISHED
CIV-36 status: COMPLETE AND PUBLISHED
CIV-37 status: COMPLETE AND PUBLISHED
CIV-38 status: OPTIONAL — NOT STARTED
Gate E Evaluation 01 status: FAIL — HISTORICAL IMMUTABLE EVIDENCE
V4-GATE-E-v1 Blocker 01 status: FIXED + PUBLISHED + REMOTE VERIFIED
Gate E Evaluation 02 status: FAIL — HISTORICAL IMMUTABLE EVIDENCE
V4-GATE-E-v1 Blocker 02 status: FIXED + PUBLISHED + REMOTE VERIFIED
Gate E Evaluation 03 status: FAIL — HISTORICAL IMMUTABLE EVIDENCE
V4-GATE-E-v1 Blocker 03 status: FIXED + PUBLISHED + REMOTE VERIFIED
Gate E Evaluation 04 status: FAIL — HISTORICAL IMMUTABLE EVIDENCE
V4-GATE-E-v1 Blocker 04 status: FIXED + PUBLISHED + REMOTE VERIFIED
Gate E Evaluation 05 status: PASS — SENIOR REVIEW APPROVED — PUBLISHED EVIDENCE
V4-GATE-E-v1 status: ACQUIRED AND PUBLISHED
V4-GATE-E-v1 acquisition published canonical HEAD: 076a616a97a229e921a5c36eebdfd12f76744f83
CIV-39 status: COMPLETE AND PUBLISHED
CIV-39 published canonical HEAD: 0b0ec535cda62b70add182875c65eaee27bb5bb2
V4-GATE-F-v1 status: ACQUIRED AND PUBLISHED — REMOTE VERIFIED
V4-GATE-F-v1 acquisition published canonical HEAD: 14475f4ad5dde9e1063a830ba7e38390cfb4d045
Gate F Evaluation 01 status: FAIL — HISTORICAL IMMUTABLE EVIDENCE
V4-GATE-F-v1 Blocker 01 status: FIXED + PUBLISHED + REMOTE VERIFIED
Gate F Evaluation 02 status: FAIL — HISTORICAL IMMUTABLE EVIDENCE
V4-GATE-F-v1 Blocker 02 status: FIXED + PUBLISHED + REMOTE VERIFIED
Gate F Evaluation 03 status: FAIL — HISTORICAL IMMUTABLE EVIDENCE
V4-GATE-F-v1 Blocker 03 status: FIXED + PUBLISHED + REMOTE VERIFIED
Gate F Evaluation 04 status: FAIL — HISTORICAL IMMUTABLE EVIDENCE
V4-GATE-F-v1 Blocker 04 status: FIXED + PUBLISHED + REMOTE VERIFIED
Gate F Evaluation 05 status: FAIL — HISTORICAL IMMUTABLE EVIDENCE
V4-GATE-F-v1 Blocker 05 status: FIXED + PUBLISHED + REMOTE VERIFIED
Gate F Evaluation 06 status: FAIL — HISTORICAL IMMUTABLE EVIDENCE
V4-GATE-F-v1 Blocker 06 status: FIXED + PUBLISHED + REMOTE VERIFIED
Gate F Evaluation 07 status: FAIL — HISTORICAL IMMUTABLE EVIDENCE
V4-GATE-F-v1 Blocker 07 status: FIXED + PUBLISHED + REMOTE VERIFIED
Gate F Evaluation 08 status: FAIL — HISTORICAL IMMUTABLE EVIDENCE
V4-GATE-F-v1 Blocker 08 status: FIXED + PUBLISHED + REMOTE VERIFIED
Gate F Evaluation 09 status: FAIL — HISTORICAL IMMUTABLE EVIDENCE
V4-GATE-F-v1 Blocker 09 status: FIXED + PUBLISHED + REMOTE VERIFIED
Gate F Evaluation 10 status: FAIL — HISTORICAL IMMUTABLE EVIDENCE
V4-GATE-F-v1 Blocker 10 status: FIXED + PUBLISHED + REMOTE VERIFIED
Gate F Evaluation 11 status: FAIL — HISTORICAL IMMUTABLE EVIDENCE
V4-GATE-F-v1 Blocker 11 status: FIXED + PUBLISHED + REMOTE VERIFIED
Gate F Evaluation 12 status: PASS — SENIOR REVIEW APPROVED — PUBLISHED EVIDENCE
CIV-40 status: OPTIONAL TOOLING — NOT STARTED
CIV-41 status: LOCAL IMPLEMENTATION/REVIEW CANDIDATE — NOT PUBLISHED
CIV-42 status: NOT STARTED
V4-GATE-G-v1 status: PLANNED
roadmap generation: V4
```

The published Blocker 01 correction preserves verified physical position
restart. The published Blocker 02 correction validates ecological observations
across retained mortality boundaries and binds their physical content to
bounded receipts in the World `SaveDB`, outside the civilization checkpoint.
The published Blocker 03 correction grants automatic crop-maturity
authority only to an ecological receipt staged by the open candidate-tick
World-receipt transaction, after also proving the exact current-cycle plant
action and causal boundary. Retained observations are historical evidence. A
current staged non-mature row permits the tick to continue; missing exact-cell
evidence also permits progress without an agricultural transition. Causal
ordering remains a consistency defense, not the sole proof of currentness.

The published Blocker 04 correction separates external `World.tick()` crop
progression from the later civilization candidate and gives the controller one
bounded, reverse-order journal for verified compensations owned by the physical
adapters. Failed candidates abandon receipts, recorder and session together;
verified movement restores all captured entity fields directly in PebbleCore.
A non-verifiable compensation produces an observable hard failure that pauses
the session and refuses normal ticks, checkpoint operations and restart. Schema
30 and Observer schema 7 remain unchanged. Senior review correction 01 also
rejects unavailable shearing before tool/RNG mutation, closes nested
child/parent registration failures for shearing, custody, physical action,
fishing and hunting, and makes closed-transaction registration refusal a
primitive invariant. Senior review correction 02 routes the remaining
productive post-mutation registrations—agriculture navigation, movement, wild
approach, livestock feed, birth, mortality and the renewable fixture—through
the same `registerOrCompensate` fail-stop policy. Exact local restoration leaves
no token; an unverifiable restoration remains journal-owned and necessarily
arms candidate physical hard failure. No direct productive physical
`.register(` call remains. This work does not alter Evaluation 04 or acquire Gate D.
Senior review is approved, the published product-fix head is
`cca372bb841846db4b1010d26456bcc245b07c3e`. Evaluation 05 remains historical
FAIL evidence. Evaluations 06 through 08 are immutable historical FAIL evidence.
The published Blocker 06 and Blocker 07 corrections do not
reevaluate either campaign or acquire Gate D.

The published Blocker 05 correction adds manifest-v2 exact physical-custody
restart evidence only for non-empty nonpersistent Lab probes. Pebble captures and
round-trips every material `ItemStack` field, while PebbleAgents retains only
opaque protected evidence. Graceful shutdown represents the same stacks once
as protected real `ItemEntity` escrow through the existing World chunk save,
but only after revalidating checkpoint/session identity and tick, causal
boundary, World binding, exact probe population/identity/position, complete
custody and fingerprints. Escrow provenance is bound to checkpoint ID and the
manifest-v2 integrity digest. Fresh load adopts only that complete exact
escrow set. Absence of escrow is not authority to recreate manifest matter;
abrupt loss without persisted escrow is unsupported and fails closed before
mutation. Ordinary current spills dirty their World chunk and therefore
survive a stale handoff refusal. Prevalidation, complete-set reconciliation
and exact rollback remain adapter-owned. Material Rights constrains
holder/material/quantity but never creates matter. Session schema 30 and
Observer schema 7 are unchanged; empty custody preserves manifest v1 and the
Blocker 01 path.

The published Blocker 06 correction separates durable estate-asset authority from
an immediate full-endpoint transaction precondition. A pending asset retains
its durable holder, exact material identity and quantity constraints. At
settlement, Pebble reacquires a current physical observation at that holder,
requires exactly one unambiguous matching stack, and passes the resulting
current custody fingerprint to the existing atomic Material Custody Gateway.
Unrelated co-mingled slots may change; removal, quantity or identity change,
wrong holder and indistinguishable duplicate stacks fail closed before
mutation. The settlement still transfers only the tracked stack and publishes
estate and Material Rights state only after verified physical success.

The estate rollback proof now has an explicit post-mutation seam. It can emit
`lateFailure=verified` only after the real transfer and post-mutation
source/destination verification occur. Any earlier failure reports that the
seam was not reached and claims no rollback. A real late fault restores source,
destination, estate, Material Rights, session, replay and receipts exactly; an
immediate same-process retry then succeeds. No durable schema changes, no
Observer schema changes and no new material identity were introduced.

The published Blocker 07 correction moves current Material Rights reconciliation
inside the checkpoint-load candidate and after the complete physical boundary
has been restored and verified. Probe retirement/restoration, exact positions,
checkpoint-bound custody and complete population are acquired first. One
reconciliation is then staged against that PebbleCore truth and published only
with the final session. A fault after the reconciliation candidate restores the
bootstrap World, custody escrow, controller and session exactly, publishes no
candidate run, and permits an immediate same-process load retry.

The first inherited use after successful fresh load now succeeds directly. It
performs a real physical block break with the inherited pickaxe and advances
the transferred estate entry's current destination observation while retaining
its historical settlement observation and receipt. Missing, wrong, ambiguous
or unprotected physical material remains fail-closed. Schema 30 and Observer
schema 7 are unchanged.

The published Blocker 08 correction makes the complete checkpoint probe target set
the bounded placement authority for that load candidate. PebbleCore validates
terrain, foreign World entities and every target AABB collectively. Current
probes and checkpoint escrow owned by the same transaction may be excluded
only from their transient World positions; true target overlap and foreign
collisions still fail before mutation. Missing probes reuse that exact
authority instead of rebuilding an isolated placement context.

The decisive mixed load composes one reused probe, one repositioned probe, two
restored missing probes and one retired dead bootstrap probe. Normal and
reversed creation orders acquire the same exact physical boundary. A fault
after the first missing creation rolls back every partial probe and custody
effect; the existing post-reconciliation fault also remains exact. Successful
load commits one current reconciliation and first inherited use performs a
real pickaxe mutation. Schema 30 and Observer schema 7 remain unchanged.

The published Blocker 09 correction preserves the immutable Material Rights asset
reference and historical estate settlement while validating checkpoint custody
against the exact current verified material observation. The same canonical
identity-evolution predicate now governs both Material Rights state validation
and checkpoint custody validation. PebbleCore remains physical authority: the
current holder, exact current identity and quantity, current observation
boundary and non-overlapping reservation must all be proven at save time.

The targeted campaign evolves the same inherited pickaxe from damage 0 to 1,
saves and fresh-restores damage 1 through exact protected custody, then performs
a second real use, saves and fresh-restores damage 2. Registration and
settlement identity remain damage 0, the asset ID and single settlement receipt
remain stable, and only the current verified holder observation advances.
Missing current material, stale registration identity substitution, an
unverified future identity, wrong holder, wrong quantity, ambiguity and
duplicate reservation all fail closed. Schema 30 and Observer schema 7 remain
unchanged.

The published Blocker 10 correction captures every active Lab probe that is
canonically placeable before a candidate block mutation, then reuses
PebbleCore `assessEntityPlacement` before any Civilization publication. A
break, till or placement that would remove support, obstruct the body or
otherwise invalidate one of those probes is compensated through the existing
physical-action transaction. The World block, tool state, drops, custody,
Material Rights, estate projection, session and recorder remain exact. No
probe is moved, no alternative position is invented, and checkpoint save
continues to reject `incompatibleSupport`.

The positive control still performs a real nearby break with tool wear and
physical drop acquisition. The decisive continuation performs inherited
pickaxe damage 1 to 2 on a safe target, saves checkpoint C, fresh-restores the
exact damage-2 custody with one current reconciliation, then performs another
real damage 2 to 3 use. Durable registration remains damage 0 and the one
historical settlement receipt remains unchanged. Schema 30 and Observer
schema 7 are unchanged.

## Last validation baseline

For the senior-review-approved Gate D Evaluation 11 whole-Gate campaign:

```text
Evaluation 11 verdict / senior review: PASS / APPROVED
evaluated product baseline: 24c679581f7dfd93d26bffa2e9486a5340af0d9c
G0>G1>G2 / births / deaths / active agents: PASS / 2 / 1 / 4
childhood>durable development / renewable subsistence: PASS / PASS
checkpoint A two non-empty holders / exact fresh restore: PASS / PASS
mixed collective probe restore / load rollback seams: PASS / PASS
estate succession / true late fault / retry: PASS / exact / PASS
support-destructive break / till / place: exact rollback / exact rollback / exact rollback
safe physical break after refusal: PASS (real wear, block removal and acquired drop)
damage progression / checkpoints B and C: 0>1>2>3 / exact / exact
successful important load reconciliation publications: exactly 1
failed candidate reconciliation publications: 0
historical durable identity / settlement receipt: damage 0 / unchanged one
checkpoint schema / Observer schema: 30 / 7
physical loss / duplication / synthetic material: 0 / 0 / 0
duplicate probes / assets / receipts / settlements: 0 / 0 / 0 / 0
Observer mutation count: 0
Gate D Blockers 01 through 07 dedicated regressions: PASS
Gate D Blocker 08 dedicated runner: INCONCLUSIVE (signed historical session fixture unavailable)
Gate D Blocker 08 integrated current semantics: PASS
Gate D Blockers 09 and 10 integrated current semantics: PASS
repository shared smoke: 3772 passed, 0 failed
repository verification steps: 35/35
golden regeneration: NOT ATTEMPTED
```

## Known important debt

- There is no GitHub CI status check for the canonical branch; published
  verification still relies on reviewed local evidence.
- Historical Gate B closure tooling and raw temporary artifacts are tied to
  their historical evaluation context; the reports remain evidence, not a
  current all-purpose gate runner.
- `CIV-26` binds a bounded social asset reference to verified Pebble stack
  identity and quantity. It does not claim a universal per-unit item UUID.
- `CIV-27` reconciles only bounded candidate holders known at save time:
  civilization agents and known material-rights holders. It does not scan the
  World globally or discover an item moved into an otherwise unknown
  container; that case remains explicitly unresolved instead of guessed.
- The World and civilization saves do not claim a cross-store atomic
  transaction. Schema 20 binds the expected World, causal boundary and
  physical references, then fails closed or records reconciliation outcomes
  after the real World loads.
- Observer V1 is a bounded local-session projection. It does not provide
  omniscient multi-settlement inspection, unbounded history, full-text search
  or simulation editing.
- Homeostasis V2 is a bounded needs-driven physiological projection. It does
  not add contagion, medicine, complex wounds, long-term impairment mechanics,
  genetic predisposition, corpses or inheritance. Existing `AgentNeeds`,
  lifecycle age, health reserve and mortality remain the underlying
  authorities. Every embodied finalization waits for bounded verification that
  the probe is empty or for verified physical exit of every carried stack into
  an existing safe real container, independently of Material Rights. Failure
  rolls the complete mortality boundary back and remains retryable rather than
  inventing a holder, social record or losing matter.
- Genetics V1 is a closed four-locus diploid model with deterministic founder
  initialization and mutation-free inheritance. Phenotype is derived from
  immutable genotype, lifecycle development and bounded homeostasis exposure;
  it does not encode sex, gender, detailed appearance, intelligence,
  personality, genetic disease or automatic social outcomes.
- A checkpoint may recreate a persistent active probe absent from the fresh
  bootstrap only when the schema-22 live manifest carries a valid canonical
  integrity digest protecting its sorted, unique empty-custody attestation,
  the identity remains present in population and lifecycle, and no Material
  Rights record resolves to that agent as physical holder. The manifest is
  verified before any World mutation; older unprotected manifests and
  non-empty custody cannot authorize empty-probe recreation and remain
  fail-closed on the existing CIV-27 reconciliation path.
- Childhood V2 extends the existing Dependent Care authority with one bounded,
  durable active guardian, explicit reassignment or at-risk state, and causal
  social-development exposure. Birth, replacement and active engagement share
  one physiological-availability predicate. Candidate guardian and caregiver
  selection reads the same transactional care authority. Supervision advances
  only on unique ticks with an active matching assignment and need, an
  available caregiver, compatible care activity and verified proximity;
  elapsed or interrupted time grants no credit. Schema 24 persists that
  bounded progress, while schema 23 decodes it with zero historical
  elapsed-time credit. Childhood V2 does not make a guardian a genetic or
  kinship parent, household owner, teacher, material custodian or legal actor.
  Social development grants no trust, knowledge, skill, profession,
  ownership, reproductive capability or status by itself.
- Family V1 adds bounded durable union proposals and records, explicit lineage
  roots, social houses and house-membership periods to the existing
  `AgentSimulationSession`. A union requires two separately verified physical
  acts, permits at most one active union per person and can end unilaterally or
  by death. Parent, child, sibling, ancestor, descendant, partner, former
  partner and co-parent relations are deterministic projections of canonical
  kinship and union records, not a second stored kinship graph. Lineage
  membership is similarly derived from canonical ancestry with visible depth
  and row truncation. A house is neither a household nor a property, care,
  custody, leadership or inheritance authority. Birth may add one
  shared-parent-house membership only when both canonical progenitors share
  exactly one active house; zero or multiple common houses add none and do not
  abort an otherwise valid birth. Explicit adult join persists distinct,
  reciprocal request and acceptance proofs, exact roles, operation IDs,
  maturity and family grounding. Two-founder houses require a matching union
  active at the foundation tick and two reciprocal co-foundation acts.
  Schema 26 persists those durable consent proofs while Observer schema 5
  remains read-only. Schema 25 is readable only when its retained causal
  events can reconstruct the complete proof; an honestly evicted but
  incomplete legacy proof fails closed.
- Estates V1 activates explicitly and prospectively over canonical mortality.
  One death can open at most one bounded estate only after complete physical
  custody resolution. Successor tiers derive from the active partner at the
  death tick and canonical kinship; a house, household, lineage, trust, skill,
  phenotype or wealth score has no succession authority. Administration
  requires explicit mature acceptance and is distinct from beneficiary,
  owner, holder and custodian roles. A physical asset remains owned by the
  decedent while settlement is pending, then changes Material Rights only
  after an exact Pebble transfer receipt; third-party claims and permissions
  follow their documented bounded policy. Minor ownership remains separate
  from guardian custody. Estate operational status is recomputed from
  terminal, dormant, partial, blocked, pending and active-administration
  truth, so administrator loss cannot reopen or erase material state.
  Mortality and estate retention are coordinated: a retained nonterminal
  estate pins its death record, while a terminal estate/death pair may compact
  atomically. Every compacted operational death first creates one bounded,
  independently digested historical mortality summary from the true death
  record; capacity failure refuses the candidate transaction before proof is
  lost. Retained records, compacted summaries and active lifecycle state form
  the fail-closed historical authority used to rederive eligibility, life
  stage and minor guardianship at the estate death boundary. Schema 28
  persists that evidence and a bounded, digested successor proof covering the
  exact tier, complete canonical eligibility rows, life stage, minor guardian,
  active union and causal plan event. Schema 27 remains readable only when
  retained causes permit exact reconstruction; incomplete legacy proof fails
  closed. Physical settlement prevalidates one shared
  operation/receipt identity. Blocked custody can be causally revalidated
  after a real guardian or availability change without rewriting allocation,
  claims or permissions. Observer schema 6 projects estate authority
  read-only. The model does not implement wills, taxation,
  valuation, divisible shares, house leadership, public treasury, land law or
  general contract inheritance.
- Renewable Subsistence V1, now published, proves one bounded real carrot loop through existing
  PebbleCore crop growth, Pebble physical agriculture, physical food debit and
  a new plant/harvest cycle across restart. One initialization carrot becomes
  a first harvest of five; one is eaten, three are stored and one is replanted;
  the stage-0 second crop survives restart and yields three. Schema 29 retains
  exact source-action provenance and fails closed when the first-cycle receipts
  needed to authorize renewal cannot be retained. Observer schema 7 derives a
  read-only view from agriculture and physical-food authorities. This proof is
  not a general food economy, market, land-rights system, irrigation or season
  model, crop genetics, or industrial production system.

## Next authorized action

Gate E Evaluation 05 is
**PASS — SENIOR REVIEW APPROVED — PUBLISHED EVIDENCE**. Evaluations 01–04
remain **FAIL — HISTORICAL IMMUTABLE EVIDENCE**, and Blockers 01–04 remain
**FIXED + PUBLISHED + REMOTE VERIFIED**. Gate E is **ACQUIRED AND PUBLISHED**
at independently remote-verified canonical HEAD
`076a616a97a229e921a5c36eebdfd12f76744f83`.
`CIV-39 — Multi-Settlement, Population Scaling and Fidelity Tiers V1` is
**COMPLETE AND PUBLISHED** at independently remote-verified canonical HEAD
`0b0ec535cda62b70add182875c65eaee27bb5bb2`; its durable published record is
[`CIV_39_PHASE_SUMMARY.md`](CIV_39_PHASE_SUMMARY.md). Senior review approved
manual fast-forward publication after Correction 01 and Evidence
Reconciliation 02. Independent Gate F Evaluation 01 subsequently failed
against published baseline `29c8a7328f06748817abba1545acdb259a4d192a`;
its final evidence HEAD `1cd056b6f74b4334cc6f63e969f3b629b3d79ae2`
remains **FAIL — HISTORICAL IMMUTABLE EVIDENCE**. The targeted
per-settlement admission-capacity correction is **FIXED + PUBLISHED + REMOTE
VERIFIED** at product commit
`54c5f4e9d1acab06a0fc44b2cd96dc74c04c72ec` and published canonical blocker
HEAD `690c431d47f2e9edf9b1a9a9e91c71876981d09c`, documented in
[`GATE_F_BLOCKER_01_SETTLEMENT_ADMISSION_CAPACITY.md`](GATE_F_BLOCKER_01_SETTLEMENT_ADMISSION_CAPACITY.md).
Senior review approved manual fast-forward, publication completed and
independent remote verification passed. Evaluation 02 then failed on immutable
historical evidence against baseline
`c60eda84210cc8ed32f910f6f36ec29c1f747a9b`. Blocker 02 is **FIXED +
PUBLISHED + REMOTE VERIFIED** at product commit
`7ec342dce329b611d418562383956bad40c9023d` and published canonical blocker
HEAD `40ae812205abe231317e0d1720b5db4cecf9f24d`. Evaluation 03 then failed
against baseline `0407e8290aa98bde154cb98389893bcc577f830e`; its final evidence
HEAD `9e66af9b0c4ccc9edcfb399fdf287b5a00f25b5d` remains **FAIL — HISTORICAL
IMMUTABLE EVIDENCE**. Blocker 03 is **FIXED + PUBLISHED + REMOTE VERIFIED** at
product/test/runtime commit `8358811204c35a79a4be202e57a28dfad4fb3e0f`,
documented in
[`GATE_F_BLOCKER_03_DYNAMIC_FIDELITY_AUTHORITY.md`](GATE_F_BLOCKER_03_DYNAMIC_FIDELITY_AUTHORITY.md).
Senior review approved manual fast-forward, publication completed at canonical
blocker HEAD `2c6fe63e81b20ee4a37315a6f5ad528a721c2355`, and independent remote
verification passed. Evaluation 04 then failed against baseline
`9b261c2bc513e1abfc31cdcf0acb64cdf035508c`; harness
`136b1ebed6a153166d0887722f8ca08adf2e9644` and final evidence HEAD
`eb26347bbbdbd4954d8ed975e6ca30de97d14bd4` remain **FAIL — HISTORICAL
IMMUTABLE EVIDENCE**. Blocker 04 is **FIXED + PUBLISHED + REMOTE VERIFIED** at
product/test/runtime-proof commit
`f1be1830c2d5903a0765d028fd7a3a0e821afec7`, documented in
[`GATE_F_BLOCKER_04_HOUSEHOLD_MIGRATION_AUTHORITY.md`](GATE_F_BLOCKER_04_HOUSEHOLD_MIGRATION_AUTHORITY.md).
It composes verified settlement arrival with current household and residence
authority without weakening restore validation. Senior review approved manual
fast-forward, publication completed at canonical blocker HEAD
`d7fac42493b229ce36ece5c21c597284e5ad7cb5`, and independent remote
verification passed. The final review archive SHA-256 is
`242bdcadcd4fe8ea54c5bacd812dfaae4231c6c9110e30958c6be715595c1c8c`.
Gate F remains **PLANNED — NOT ACQUIRED**. Evaluation 05 remains **FAIL —
HISTORICAL IMMUTABLE EVIDENCE**. Its schema-35 Family-validation Blocker 05 is
**FIXED + PUBLISHED + REMOTE VERIFIED** at product/test/runtime-proof commit
`b1f3fad3ec4959c1ecf43e91eac0d291d6f9acf4`, documented in
[`GATE_F_BLOCKER_05_FAMILY_SCHEMA35_VALIDATION.md`](GATE_F_BLOCKER_05_FAMILY_SCHEMA35_VALIDATION.md).
Senior review approved manual fast-forward, publication completed at canonical
blocker HEAD `df1c042c0f8d4f45ad8928c9fb7d0bbe5558af8b`, and independent remote
verification passed. The final review archive SHA-256 is
`b27904bceba21901e87cdf8d1e9aedea3db65e9828606db4c46d5d829be2f689`.
Evaluation 06 remains **FAIL — HISTORICAL IMMUTABLE EVIDENCE** against baseline
`31f785ca9051be6b4f39ab97102f89410a776824`. Its sequential-migration
historical/current-authority Blocker 06 is **FIXED + PUBLISHED + REMOTE
VERIFIED** at product/test/runtime-proof commit
`647dade73afa4d8e044423f422292dbf0c08f43e`, documented in
[`GATE_F_BLOCKER_06_SEQUENTIAL_MIGRATION_HISTORY.md`](GATE_F_BLOCKER_06_SEQUENTIAL_MIGRATION_HISTORY.md).
Senior review approved manual fast-forward, publication completed at canonical
blocker HEAD `fe5bca7074b8ac65c31e03299195c3d7cfe307b1`, and independent
remote verification passed. The final review archive SHA-256 is
`ab2c496aa84af59cd1f3d72906cee55f8f8c7e381720165a5052a2b8d1807f6c`.
Evaluation 07 is **FAIL — HISTORICAL IMMUTABLE EVIDENCE**. Its Blocker 07 is
**FIXED + PUBLISHED + REMOTE VERIFIED** at product/test/runtime-proof commit
`61039c10763a478a55ea330ed4ad79881de0efb7` and published canonical blocker
HEAD `279fb26bea8a817b767a0192d8f7b1cffdff1563`; senior review approved manual
fast-forward, publication completed, and independent remote verification
passed. The final review archive SHA-256 is
`a5ba10ea140f4b2b6956519d1fc196709b1a5d100d77afcdbc32e7e86f42ad90`.
Evaluation 08 is **FAIL — HISTORICAL IMMUTABLE EVIDENCE**. Blocker 08 is
**FIXED + PUBLISHED + REMOTE VERIFIED** at product/test/runtime-proof commit
`518aaf0dddfcc9f63e133290bf6dd915f9eaa73a` and published canonical HEAD
`4e3bd296203346e4716c0a186017aebc69dbe750`, documented in
[`GATE_F_BLOCKER_08_ESTATE_SCHEMA35_VALIDATION.md`](GATE_F_BLOCKER_08_ESTATE_SCHEMA35_VALIDATION.md).
Senior review approved manual fast-forward, publication completed, independent
remote verification passed, and the final review archive SHA-256 is
`c11b2d267a1dad40f52ad1bfe327981eaea1aae3419db8c80b45ab033421926b`.
Evaluation 09 is **FAIL — HISTORICAL IMMUTABLE EVIDENCE**. Blocker 09 is
**FIXED + PUBLISHED + REMOTE VERIFIED**, including Senior Review Correction 01,
at initial product commit
`0607d9b291f3ed7a28eaa9ad887f4a2e7927e2c5` plus SRC01 product commit
`6a5ee92e89d14e1aff38d17c28d4e526eb51eb5f` and published canonical HEAD
`482adc6617e258a73967e73c9d53cf1466c94f64`, documented in
[`GATE_F_BLOCKER_09_ESTATE_CAUSAL_SUCCESSOR_AUTHORITY.md`](GATE_F_BLOCKER_09_ESTATE_CAUSAL_SUCCESSOR_AUTHORITY.md).
Evaluation 10 is **FAIL — HISTORICAL IMMUTABLE EVIDENCE**. Its
`terminalMortalityPendingMigrationAdmission` Blocker 10 is **FIXED + PUBLISHED
+ REMOTE VERIFIED** at product/test/runtime commit
`470223bae3af44da29fd8830169ed14371dd3403` and canonical HEAD
`104c919c3017cb73739c8839b47e5a011616e007`, documented in
[`GATE_F_BLOCKER_10_TERMINAL_MORTALITY_MIGRATION_ADMISSION.md`](GATE_F_BLOCKER_10_TERMINAL_MORTALITY_MIGRATION_ADMISSION.md).
The final review archive SHA-256 is
`3e214e0f9dc0bc1cd1c885d6ff178fa0fe67ffd103741d88bc0e9618ee2a218d`.
Evaluation 11 is **FAIL — HISTORICAL IMMUTABLE EVIDENCE** against baseline
`35993c5652d79a8244f6a6e7f70709a2136a7939`. Its
`terminalMortalityPendingHouseholdAcquisition` Blocker 11 is **FIXED +
PUBLISHED + REMOTE VERIFIED** at product/test/runtime commit
`7d33d5f584089ad44ffcb0c64fcb00bb4d41779f` and canonical HEAD
`ab3302ee0c1fdcd90a40ba12dee555f3f445b793`, documented in
[`GATE_F_BLOCKER_11_TERMINAL_MORTALITY_HOUSEHOLD_ACQUISITION.md`](GATE_F_BLOCKER_11_TERMINAL_MORTALITY_HOUSEHOLD_ACQUISITION.md).
Its final review archive SHA-256 is
`024f8197be6a5ec4608e5e7deb02196083bf95e15912ceed6dec73bff057c094`.
Gate F Evaluation 12 is **PASS — SENIOR REVIEW APPROVED — PUBLISHED EVIDENCE**
against baseline `8733517720487cd7832a57b6d1ddf4b82fe56102`, as recorded in
[`GATE_F_EVALUATION_12_REPORT.md`](GATE_F_EVALUATION_12_REPORT.md) and its JSON
companion. The accepted published evidence HEAD is
`b31a7e53cfcf7a5c3ab6419f3cb5c0c309f04112`, with review archive SHA-256
`ca7e70799220b58c3b090716a2adf19e8abb2609d465b7139d25f7f59988af4c`.
Gate F is **ACQUIRED AND PUBLISHED — REMOTE VERIFIED** at acquisition
canonical HEAD `14475f4ad5dde9e1063a830ba7e38390cfb4d045`. `CIV-41` now has a
**LOCAL IMPLEMENTATION/REVIEW CANDIDATE — NOT PUBLISHED** from exact canonical
baseline `96030494c9bed8e356faae16dbd3c66dc9b4b652`; independent senior review
and any publication remain external. `CIV-42` is not started and Gate G remains
planned.
`CIV-38` remains **OPTIONAL — NOT STARTED** and is not a prerequisite.
`CIV-40` remains **OPTIONAL TOOLING — NOT STARTED**. Currency is not a Gate E
or CIV-39 prerequisite.
