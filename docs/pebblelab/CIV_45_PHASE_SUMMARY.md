# CIV-45 — Writing and Literacy V1

## Review status and baseline

`CIV-45` is a **LOCAL REVIEW CANDIDATE — NOT PUBLISHED**. It was implemented
from exact published baseline
`9a2cfec10b4a0d1b6a5d2f46aac8f3c312ddbb0e` on local branch
`codex/civ-45-writing-literacy-v1`. The local product, test and live-proof
commit is `ac38675d88d4b709183e7b26f92a0a45b0e928c1`.

The published branch remains complete through CIV-44. CIV-45 has received no
senior-review approval and has not been published. CIV-46 and CIV-47 have not
started. `V4-GATE-G-v1` remains **PLANNED / UNEVALUATED**.

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

Core access also fails closed if two loaded block entities contain the same
persisted `materialID`, even when each copied stamp is otherwise coherent with
its own cell. Invalid coordinates, unsupported dimensions, impossible counter
values, malformed digests, line divergence, non-sign blocks and legacy signs
without an inscription stamp are unavailable or invalid before cognitive
publication.

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
Build of product 'pebsmoke' complete! (10.32s)
105 passed, 0 failed

scripts/verify-pebblelab-civ45.sh
Build of product 'pebsmoke' complete! (367.83s)
105 passed, 0 failed
```

The 105 checks cover material replacement at the same location and content,
new-session ordinal reuse, external text editing, Core round trips and legacy
block entities, duplicate persisted material identity, literacy acquisition,
false assertion, no remote access, capacity refusal, mortality, CIV-41 and
CIV-42 compaction, schema-40 restore/replay, and hostile signed state.

## Live World and visual proof

The canonical live entry point is:

```bash
scripts/verify-pebblelab-live.sh --writing --dry-run
scripts/verify-pebblelab-live.sh --writing
```

The dry-run passed. The release campaign built Pebble in 158.27 seconds, then
ran two fresh real processes for each of seeds 46 and 73 under disposable
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
process. The campaign root is:

```text
/tmp/pebblelab-civ45-live.sAWYSa
```

A review bundle containing that complete campaign plus the final focused,
dry-run, live and repository-gate logs was integrity-tested at:

```text
/tmp/PebbleLab-CIV45-LocalReview-ac38675-v1.zip
SHA-256: 8d27efb2521da266e3bb5909986f071c53f4c8de8e4655ffa8722833610b0564
```

Seed 46 used World `wmtouuy89ie1`, material identity 288, artifact
`inscription-7586701966f1a4ad488695d3e550220a45e0bf4cd21e5d7554dc990a66569a1a`,
sign `(22,68,-21)` and real oak-log source `(19,66,-24)`. Seed 73 used World
`wmtouve9d6caf`, material identity 147, artifact
`inscription-6b303c6a36cef84aa00981d741e0ab6545f838149f4b730bbaa565ea50b4fd58`,
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
| 46 | `write.log` | `125ce4278bb6e13b6129255cef1aee785f47832d4b1f7b481df1efbe7b4a4895` |
| 46 | `read.log` | `91d50c91a868241c66e6967541ca5e392c34ebd1bfbeb51adc5909ee3d0cbbef` |
| 46 | `written-sign.json` / byte-identical `reloaded-sign.json` | `929840f774aaf16e3a89078928187360aafcde4b01af8256448a25690fbaf89f` |
| 46 | `writing-checkpoint.json` | `0b034c9469b6eeb56f38db167416b24fe1e10baa6d6ff0b360d21ee1037e5929` |
| 46 | `reading-checkpoint.json` | `283d20741d6ee11981a1bfb9dfac52611ba9a58a448ab057c4827d2169f0da67` |
| 46 | `written.png` | `d8e945e8bf1e7cedd2b6fd4ef96667e9e0c44e2ffc8b59b28013a3ca136b5704` |
| 46 | `read.png` | `bd9ee44026a8921f1c6fe65cc80173051ee7bedb8f01e9051b1d95f168e40daa` |
| 73 | `write.log` | `86c2d064adce0ea0bb331c9fa625a4ebe086d149635d6e624084639e1860e100` |
| 73 | `read.log` | `0110bd2a4bc9a59c5e0887284106af381afc0a30ebe3d1925e8d11a7df0ed233` |
| 73 | `written-sign.json` / byte-identical `reloaded-sign.json` | `0f5eec723f95a4481b6ebcd5c3f2ec50a8f7e1f5f341e17c3354654c3918bd4d` |
| 73 | `writing-checkpoint.json` | `2a3ed4ff408247b2876bd4e045a37db3de0fbac771c55bfa9c54d9e9037a64f8` |
| 73 | `reading-checkpoint.json` | `965025f4cdcb6b1522f5f64fc56b9f909fb5af4b3d15ae1a98b7cd3eb246da96` |
| 73 | `written.png` | `e088307940aebbf2a7503322c09bf344ac1c521218822e977ce064155a943b97` |
| 73 | `read.png` | `b3769f39d4ad0fc8af8bad07ac7e209b035485dc054a147b6c854495d9426f3a` |

## Canonical repository gate and intermediate failures

The final canonical command was:

```bash
scripts/verify-pebblelab.sh
```

It passed all 35 repository steps. The shared runtime reported `4644 passed,
0 failed`; deterministic scenario pairs and canonical output comparisons all
passed. Golden regeneration was not attempted.

Failures encountered and retained during development were corrected rather
than hidden:

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
