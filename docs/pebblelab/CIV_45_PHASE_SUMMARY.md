# CIV-45 — Writing and Literacy V1

## Review status and baseline

`CIV-45` is a **LOCAL REVIEW CANDIDATE — NOT PUBLISHED** after Senior Review
Correction 01. It was implemented from exact published baseline
`9a2cfec10b4a0d1b6a5d2f46aac8f3c312ddbb0e` on local branch
`codex/civ-45-writing-literacy-v1`. The initial product, test and live-proof
commit is `ac38675d88d4b709183e7b26f92a0a45b0e928c1`; the initial reviewed candidate
is `89cffa47f1e9635e0f44a0fac246e92739501911`. Independent senior review
returned **CORRECTION REQUIRED** because material identity validation saw only
resident chunks. Correction 01 is product/test commit
`b68a6aeff106f5a3791279d5bd62b8b2916c9a4c`; the corrected candidate is the
local HEAD containing this summary and that commit. The initial candidate
remains intact in history and is not represented as approved.

The published branch remains complete through CIV-44. Correction 01 has not
received senior re-review approval and CIV-45 has not been published. CIV-46
and CIV-47 have not started. `V4-GATE-G-v1` remains **PLANNED / UNEVALUATED**.

## Ownership and architecture

CIV-45 reuses the existing standing sign as its V1 material carrier. It does
not create an item, inventory, object, archive or physical engine in
PebbleAgents.

- PebbleCore owns the block, block entity, four physical lines, immutable
  inscription stamp and allocation of a material identity from the existing
  World-persisted physical identity counter.
- Pebble owns the transactional live adapter. It requires a real registered
  probe, a loaded supported sign within two Manhattan cells, an exact World
  identity, and a freshly inspected Core inscription before publishing
  cognition. It verifies success and performs an exact rollback on synchronous
  failure.
- PebbleAgents owns the deterministic plan, literacy history and accepted
  historical inscription/read records. It receives physical receipts and
  never reads or mutates World.
- CIV-41 remains the sole owner of claims, understandings, beliefs, revisions
  and retained historical belief authorities.
- CIV-42 remains the owner of semantic content, Language Pack forms, sparse
  lexical associations and deterministic realization.
- `AgentSimulationSession` remains the sole civilization aggregate root.

Core's new `SignInscription` is deliberately semantically opaque. It stores
only the identity and physical integrity fields required to establish that the
same inscription still exists: `artifactID`, `materialID`, content digest,
World/dimension/cell, and the four exact lines. Truth, belief, literacy and
civilization provenance remain outside Core.

Correction 01 adds no second persisted identity store. `SaveDB`, still inside
PebbleCore, decodes every persistent chunk row for the World at entry and
derives one shared cross-dimension `SignInscriptionIdentityCatalog`. The three
live dimension Worlds receive that same catalogue. Successful durable chunk
batches replace the affected derived entries only after the SQLite transaction
commits; failed writes leave the catalogue unchanged and follow the existing
dirty/requeue retry path. The scan necessarily covers the persisted World
extent: bounding it by resident or recently accessed chunks would recreate the
review blocker.

## Material identity and lifecycle

The V1 physical identity is not a coordinate or a text hash. Creation claims
the exact next value of PebbleCore's existing `nextEntityId` physical identity
namespace; the counter was already persisted in `WorldRecord`. The artifact ID
binds the World identity and claimed material identity. Position, visible
lines and CIV-45 ordinal cannot recreate that allocation.

Normal sign-line mutation clears `signInscription` in `BlockEntityData`.
Normal block replacement removes the block entity. Retyping the old four lines
therefore leaves a sign with no inscription identity. A new inscription at the
same position, with the same content and a newly created civilization session
whose ordinal is again one, receives a different Core material identity and a
different artifact ID. Both current access and lesson/read operations resample
the real Core sign; a historical CIV-45 row cannot attest that an absent,
edited or replaced sign is currently readable.

Core access now combines the claims derived from every persistent chunk in
every dimension with the current resident state. A `materialID` is accepted
only when that World-global set contains exactly one physical location.
Therefore a duplicate in an unloaded chunk invalidates both copies regardless
of load order, unload/reload, restart, or which copy is inspected first.
Simultaneously resident duplicates retain the same fail-closed behavior.

Each persisted stamped block entity is checked against its World, dimension,
chunk, cell, block shape, lines, digest and persisted `nextEntityId`. An
unreadable persistent chunk row, an undecodable block-entity array, or a
decodable malformed stamp invalidates the catalogue. CIV-45 then refuses
current access and new inscription before allocation or cognitive publication,
while the historical general chunk-loader recovery policy is unchanged.
Legacy Worlds and signs without CIV-45 stamps form an empty valid catalogue
and require no migration; valid multi-chunk CIV-45 Worlds with distinct
identities remain accessible.

The existing adapter transaction ordering is unchanged: prevalidate the
World-global catalogue, claim exactly the expected Core identity, mutate and
verify the physical sign, stage cognition, verify the sign again, then commit
the sole `AgentSimulationSession`. Synchronous failure restores the original
block entity, lines, identity counter and dirty state before any cognitive
publication. A refused duplicate or corrupt catalogue is rejected before the
counter claim. World metadata remains saved before the chunk batch in the
existing save path; the catalogue advances only after durable chunk commit.
A failed batch therefore cannot make its new chunk snapshot part of the
persistent uniqueness authority, cannot overwrite an unrelated World record,
and leaves its records dirty/requeued for retry.

## Content, assertion and truth

A writing plan begins with an accepted, current CIV-41 belief actually held by
the author. This source supplies information access and provenance; an
uninformed author cannot invent that source. The inscription may report that
belief or deliberately assert one supported V1 alternative (`absent`, `wood`
or `stone` without a fabricated physical fingerprint). Choosing a counter
assertion creates no evidence, understanding, private author belief or World
fact.

The decisive scenario has:

```text
World/Core source block: oak_log / wood
author's accepted belief: wood
written assertion: stone
reader's post-reading belief: stone
World/Core source block after writing and reading: unchanged oak_log / wood
```

The deterministic marker is:

```text
CIV45_DECISIVE artifact=inscription-220c8d1b1bcfafe7464c98cc3adb68b20da1cce443f1cfefd89c34db37b1f568 assertion=stone world=wood authorBelief=wood readerBelief=stone schema=40 dropped=1084
```

Reading produces a written-source claim, understanding and belief through
CIV-41. It adds no evidence and grants no physical skill, right, custody,
language association, literacy or World mutation. A remote agent gains no
cognition merely because the artifact exists.

## Literacy and language

CIV-42 lexical knowledge alone does not permit reading or writing. CIV-45 adds
one small, sparse capability for its four-line sign notation. Feature
activation grants it to nobody.

An author may receive an explicit, causally recorded educational prior. A new
learner needs two local guided uses on distinct ticks with a currently literate
teacher. Both participants require fresh access to the same real sign and the
necessary CIV-42 form/sense associations. One lesson, a repeated same-tick
lesson, oral vocabulary without notation, or notation without the reader's
lexical associations is insufficient. Lessons create no beliefs. Mortality
removes current capability because capability requires a living session
participant; retained educational rows remain historical proof and never
resurrect cognition.

## Persistence, replay and compaction

Checkpoint and replay schema advance from 39 to 40 only when writing state is
initialized. Pre-writing schema-37 and predecessor states remain readable
without implicit literacy or writing. Schema 40 requires coherent CIV-41,
CIV-42 and CIV-45 state; a version-40 replay envelope can promote an older base
only through an explicit first writing-activation operation. Replay applies
the accepted plan, realization and physical receipt exactly. It never invokes
a provider or rerolls historical content.

Accepted artifacts, readings and literacy records are bounded. Default caps
are 256 artifacts, 512 readings and 512 literacy records; configuration allows
only 1 through 4096. Admission refuses atomically at capacity rather than
evicting an accepted material history. Tests with capacity one prove successful
admission at the limit, deterministic refusal, unchanged ordinals and
byte-exact restart while saturated.

Writing has a refreshable causal-retention boundary over its exact retained
state. CIV-41 historical belief authorities required by accepted artifacts and
readings are pinned by CIV-41's existing owner. CIV-42 written-use receipts
retain exact association identities and acquisition/boundary causes while
current lexical state remains owned and compactable by CIV-42. Ordinary
communication compaction, causal FIFO eviction and terminal-belief compaction
therefore create neither dangling references nor revived current competence.

Author death leaves the real artifact and accepted historical provenance
readable to a qualified living reader. Reader death terminates current belief,
language and notation capability under their existing owners while preserving
accepted history. Tests force departed-belief and causal compaction, then
restore and replay byte-exactly without resurrecting either agent.

Re-signed but semantically invalid checkpoints are rejected for duplicate
artifact, reading or literacy identities; impossible ordinals; missing writing
boundaries; missing retained CIV-41 authority; substituted author, artifact or
authority IDs; fabricated lines; inconsistent language receipts; and terminal
history corruption. Core separately rejects malformed or duplicated material
stamps before they can authorize a fresh reading.

## Focused validation

The focused wrapper is:

```bash
scripts/verify-pebblelab-civ45.sh
```

Commands and final results:

```text
PEBBLELAB_CIV45_BUILD_CONFIGURATION=debug scripts/verify-pebblelab-civ45.sh
26 passed, 0 failed # exact persistent P0 regression
105 passed, 0 failed

scripts/verify-pebblelab-civ45.sh
Build of product 'pebsmoke' complete! (377.46s)
26 passed, 0 failed # exact persistent P0 regression
105 passed, 0 failed
```

The new 26-check Core/persistence regression writes two real VCK1/SQLite chunk
records at `(0,0)` and `(20,0)` with physical signs `(1,64,1)` and
`(321,64,1)`, both carrying `materialID = 400`. It proves A-only then restarted
B-only refusal, the reverse order, unload/reload, simultaneous residency, save
after refusal, no identity consumption, valid distinct multi-chunk identities,
old-save compatibility, normal edit/replacement and fail-closed malformed
persistent identity state. The existing 105 checks cover material replacement
at the same location and content,
new-session ordinal reuse, external text editing, Core round trips and legacy
block entities, duplicate persisted material identity, literacy acquisition,
false assertion, no remote access, capacity refusal, mortality, CIV-41 and
CIV-42 compaction, schema-40 restore/replay, and hostile signed state.

## Live World and visual proof

The canonical live entry point is:

```bash
scripts/verify-pebblelab-civ45-live.sh --dry-run
scripts/verify-pebblelab-civ45-live.sh
```

The Correction 01 dry-run passed. The release campaign used the corrected
Pebble build, then ran two fresh real processes for each of seeds 46 and 73 under disposable
`CFFIXED_USER_HOME` roots. Process one created an ordinary blank oak sign on a
natural supported site, observed a real oak log, wrote the false `stone`
assertion, performed and rolled back an injected late failure, completed one
local notation lesson, saved World and wrote a schema-40 checkpoint, then
terminated. Process two loaded that same World, restored the exact checkpoint,
proved the Core sign bytes identical, completed the second local lesson, read
through CIV-42 and CIV-41, proved World remained wood, edited and replaced the
sign, refused the old artifact without cognitive mutation, restored the
fixture and stopped.

All four processes exited zero with zero runtime errors and no residual Pebble
process. The final Correction 01 campaign root is:

```text
/tmp/pebblelab-civ45-live.AKQmHG
```

Seed 46 used material identity 288, artifact
`inscription-7c1083910049dfebd9972697cca2ad87f1fb3eb851c8c53d1e07cfc68920d91e`,
sign `(22,68,-21)` and real oak-log source `(19,66,-24)`. Seed 73 used
material identity 148, artifact
`inscription-cb4df5db5d18a4b170f448dfdb7a7afd0353fd605e375c0861b8561dc106dba0`,
sign `(15,64,-8)` and real oak-log source `(12,64,-7)`.

The four 3024×1898 captures were individually inspected. Each visibly shows
the standing sign in the real terrain, centered under the observer reticle;
the read captures display the restarted local-reading result. Pebble's current
World renderer does not visibly draw the four stored glyph lines on the sign
face, so the captures prove the material support and observation geometry,
while the byte-identical Core JSON and structured traces prove exact content
and identity. No pixel-level text-rendering claim is made.

Key evidence SHA-256 values:

| Seed | Artifact | SHA-256 |
| --- | --- | --- |
| 46 | `write.log` | `4a919f298f6475a5ee0b2abae0e73f5089b85fa9f476f0e8d142d307d1517819` |
| 46 | `read.log` | `956ca17cc29f37d1dee8eee630daf8e046782340b7d687dc7102f7641d5f0606` |
| 46 | `written-sign.json` / byte-identical `reloaded-sign.json` | `7c3743310d2669d7d65adf10e80b04936076f563bb8314c4fca8ccd9d1fb92b3` |
| 46 | `writing-checkpoint.json` | `a82f83b4f007ec30f8c73efeda5cf90366fbacedd52b8868cc1b09d2d17d5bbd` |
| 46 | `reading-checkpoint.json` | `bd095fac7316035819acccd2c5f744a45da55a6a9713c7546ec65395afa2bb61` |
| 46 | `written.png` | `77c12244c03c253ee22b94466baf658562493939d3c01bd0998b09f04261d434` |
| 46 | `read.png` | `32c5a5e9f74cb26f4b90d1d89b313d80e5b3e62e06473452eaec4df4d21dd6a9` |
| 73 | `write.log` | `999f5d11bee219afa74b666c35080fec41d5dd4f95f23c127f55e80a74f47c4b` |
| 73 | `read.log` | `d5dd756a36e715ba312cbc921875bfad4fd82b63642c2f41e0955cc0ac55427a` |
| 73 | `written-sign.json` / byte-identical `reloaded-sign.json` | `bfd2a6a59bf3b5ab9d7df5fbdee6bae3951a68963026f18a8286289b5d6d68c6` |
| 73 | `writing-checkpoint.json` | `3e6c7a56fc4c86492d7d9278d7c62508e8d7455cefe1d2625ce77c8b12531645` |
| 73 | `reading-checkpoint.json` | `c60af63964684d2060f1cb1f45424b71af0025fd70d8bf4d4dfd423f19b3d50f` |
| 73 | `written.png` | `d5699b2caecf817ef9e7cb64eb02da621b31f5f4f54a862c49d7ea9221b1560f` |
| 73 | `read.png` | `ab11c05bec3c0ace7e66ff5a8a7edf53670fa7c6fd6ff8558deb72054b653170` |

## Canonical repository gate and intermediate failures

The final canonical command was:

```bash
scripts/verify-pebblelab.sh
```

The final Correction 01 rerun passed all 35 repository steps. The shared
runtime reported `4644 passed, 0 failed`; deterministic scenario pairs and
canonical output comparisons all passed. Evidence is retained at
`/var/folders/23/t4l5dv055dl3x1zqylcpl9wc0000gn/T/PebbleLab-verify.hxNxoC`.
Golden regeneration was not attempted.

Failures encountered and retained during development were corrected rather
than hidden:

- before Correction 01, the exact two-real-chunk regression reproduced the
  senior blocker in both orders: six checks accepted A-only/B-only across
  restart even though both `materialID = 400` copies remained persisted;
- the first Correction 01 Optimized regression reached `25 passed, 1 failed`
  because the byte-comparison helper used nondeterministic JSON key order; the
  helper now uses sorted keys and both underlying physical values were
  unchanged;
- a chained live command passed the unsupported `--writing` argument to the
  CIV-45-specific launcher and exited 2 without running Pebble; its documented
  `--dry-run` and zero-argument interfaces then passed separately;

- the first live attempt could not find a natural supported local site;
  `/tmp/pebblelab-civ45-live.J5VHYq/46/write.log`, SHA-256
  `3cd37b8f06e98daf6212717f2136b6587c306cd9aa5c75132c6826d6181496ba`;
- the second live attempt used a hand-derived observation direction and failed
  the existing perception authority;
  `/tmp/pebblelab-civ45-live.MeCVbb/46/write.log`, SHA-256
  `1f25bcaeb2a46d9c2643085e5cb11f27486d68ecf1db521c7778a405d88584f8`;
- the first resumed focused run reached `82 passed, 1 failed` because a new
  coexistence test tried to enable CIV-43 after deliberately saturating CIV-42
  communication capacity; the independent coexistence fixture fixed the test
  without bypassing the precondition;
- the first complete repository gate reached `4641 passed, 3 failed` because
  three Gate-F compatibility sentinels still treated new valid schema 40 as
  future; they now cover strict schema 40 and reject schema 41. The affected
  focused suites then passed `27/27`, `28/28` and `32/32` before the complete
  gate rerun.

## Deliberate V1 limits and non-claims

CIV-45 provides one immutable inscription on an existing standing sign. It
does not implement books, manuscripts, loose carried pages, copying,
inventories of texts, archives, libraries, catalogues, indexes, institutional
conservation, global retrieval or historiography. It does not implement
general free-form semantic generation: the provider-off V1 path writes the
small existing resource-presence semantic family and a bounded explicit
counter assertion. It creates no culture, norm, ritual, organization, law,
religion, technology or policy.

The artifact is fixed in the World; CIV-44 remains the owner of embodied
long-distance communication. Reading still requires current local physical
access, living agency, learned notation and CIV-42 lexical competence. A
stored sentence has no physical, legal, skill, semantic or truth authority by
its existence alone.

## Program state

```text
published progression: COMPLETE THROUGH CIV-44
CIV-45: LOCAL REVIEW CANDIDATE — NOT PUBLISHED
CIV-46: PLANNED — NOT STARTED / NOT AUTHORIZED
CIV-47: PLANNED — NOT STARTED / NOT AUTHORIZED
V4-GATE-G-v1: PLANNED / UNEVALUATED
```
