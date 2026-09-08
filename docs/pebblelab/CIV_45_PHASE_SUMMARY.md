# CIV-45 — Writing and Literacy V1

## Review status and baseline

`CIV-45` is a **CORRECTION 04 LOCAL REVIEW CANDIDATE — NOT PUBLISHED**. It was
implemented from exact published baseline
`9a2cfec10b4a0d1b6a5d2f46aac8f3c312ddbb0e` on local branch
`codex/civ-45-writing-literacy-v1`. The initial product, test and live-proof
commit is `ac38675d88d4b709183e7b26f92a0a45b0e928c1`; the initial reviewed candidate
is `89cffa47f1e9635e0f44a0fac246e92739501911`. Independent senior review
returned **CORRECTION REQUIRED** because material identity validation saw only
resident chunks. Correction 01 is product/test commit
`b68a6aeff106f5a3791279d5bd62b8b2916c9a4c`, with candidate
`68bda3e5e7a28af50fed3d9680d2a9a0dfeea4e4`. Its independent senior re-review
also returned **CORRECTION REQUIRED**: durable commit and catalogue advancement
were not linearized, a resident dirty chunk was unioned with rather than
replacing its durable representation, and normal World entry decoded every
persisted voxel payload. Correction 02 product/test commit is
`1e2753586e587a098f3908349d1c647d6b10d253`, its pre-reconciliation
documentation commit is `9b5607a4c2713fdc94937b4855665ea52e83cb08`, and its
reconciled candidate is `b9fdccd7c8bef0c5bfc39d40d09e32920a3f4ac2`.
Final independent senior re-review returned **CORRECTION REQUIRED** because a
physical authority receipt inspected at generation N could still publish
cognition after a conflicting physical commit advanced authority to N+1.
Correction 03 product/test commit is
`b29faa532e3f1909e7955015a8f4067e47c21a40`, with candidate
`b502d272998834a6bc70a5c5fc0740924d03caa1`. Its final independent senior
re-review returned **CORRECTION REQUIRED** because a save could capture a
candidate inscription and its advanced physical identity before a later
cognitive refusal rolled both back in the live World. Correction 04
product/test commit is `ff68b1d60f7159fec17d0bb98433235f75e767d1`; the
corrected review candidate is the local documentation HEAD containing this
summary. All four failed candidates remain intact, immutable historical
evidence and are not represented as approved.

```text
Initial CIV-45 candidate: CORRECTION REQUIRED
Correction 01 candidate: CORRECTION REQUIRED
Correction 02 candidate: CORRECTION REQUIRED
Correction 03 candidate: CORRECTION REQUIRED
Correction 04: LOCAL REVIEW CANDIDATE — NOT PUBLISHED
```

The published branch remains complete through CIV-44. Correction 04 has not
received independent senior re-review approval and CIV-45 has not been
published. CIV-46 and CIV-47 have not started. `V4-GATE-G-v1` remains
**PLANNED / UNEVALUATED**.

## Ownership and architecture

CIV-45 reuses the existing standing sign as its V1 material carrier. It does
not create an item, inventory, object, archive or physical engine in
PebbleAgents.

- PebbleCore owns the block, block entity, four physical lines, immutable
  inscription stamp and allocation of a material identity from the existing
  World-persisted physical identity counter.
- Pebble owns the transactional live adapter. It requires a real registered
  probe, a loaded supported sign within two Manhattan cells, an exact World
  identity and a freshly inspected Core inscription. It asks Core to own the
  physical candidate from identity allocation through the opaque Pebble
  publication-or-rollback closure. It prepares and commits the candidate
  civilization session inside that closure, verifies success and performs an
  exact rollback on synchronous failure.
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

Correction 02 makes the World `SaveDB` the durable owner of a compact
per-chunk inscription index. Chunk payload, monotonically advanced index
version, index digest and compact claim envelope are written in the same
SQLite transaction. One `SignInscriptionIdentityCatalog` is reconstructed from
those compact rows and shared by the three dimension Worlds. It remains a
physical-integrity authority derived and maintained by Core persistence, not a
civilization registry or a second save engine.

Normal World entry is now `O(persisted chunks + inscription claims)` in compact
metadata and does not decode voxel arrays for CIV-45. A save created before the
index has version-zero chunk rows; its first open performs a one-shot payload
decode and atomically writes the compact index. Subsequent opens use only the
index. The measured 24-chunk fixture decodes exactly
`24 × 16 × 16 × 384` voxel cells during migration and zero on both indexed
steady-state opens.

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

The current authority view has an explicit replacement order. It starts from
the durable compact index, replaces affected keys with staged records for
dirty chunks that were unloaded before their save completed, then replaces
those keys with the current state of every resident chunk across all three
dimensions. Resident physical state is therefore current truth for its chunk;
it is never added to a stale durable copy of the same chunk. A `materialID` is
accepted only when this complete World-global view contains exactly one
physical location. A duplicate in an unloaded chunk invalidates both copies
regardless of load order, unload/reload, restart or inspection order, while a
current resident removal or replacement supersedes its older durable row both
before and after autosave.

Each compact claim is checked against World/dimension/chunk/cell bounds,
material identity bounds, index version and SHA-256 digest. Missing, extra,
mismatched or undecodable index rows invalidate the entire persistent source;
resident state cannot mask that failure. During one-shot migration, an
unreadable row or malformed serialized inscription fails closed. An unrelated
malformed block-entity array containing no serialized `signInscription` field
follows the existing loader policy and contributes no claim, avoiding global
denial for corruption that cannot conceal a CIV-45 identity. Legacy text-only
signs migrate to empty index entries and never acquire material authority.
Valid multi-chunk Worlds with distinct identities remain accessible, and two
different World saves may independently reuse the same numeric identity.

The adapter transaction still prevalidates the World-global authority, then
calls `World.withCandidateSignInscriptionAuthority`. Core takes its recursive
physical-authority lock before claiming the expected identity and mutating the
sign, and keeps it while Pebble stages cognition, revalidates the sign, commits
the sole `AgentSimulationSession`, or rolls the physical candidate back. A
synchronous exact failure restores the block entity, lines, identity counter
and previous dirty state. A refused duplicate or corrupt source is rejected
before allocation.

For persistence, `SaveDB.putChunks` prepares immutable chunk/index snapshots,
takes the catalogue lock, starts `BEGIN IMMEDIATE`, advances the persisted
World physical counter if necessary, writes every payload and index row, and
commits. Still under the same catalogue lock, it applies the complete
multi-chunk state dictionary in one generation. Correction 02 made inspection
itself linearizable, but its returned result could outlive that generation and
was the Correction 03 blocker. A reader already validating
finishes before the database transaction begins, while a reader arriving in
the post-commit/pre-advancement seam blocks until the full authority batch is
visible. Failed transactions roll back and follow the existing dirty/requeue
path. Crash before commit restores the old durable batch; crash immediately
after commit reconstructs the complete new batch and advanced identity counter
on restart.

Correction 04 also serializes the earlier persistence-capture boundary.
`GameCore.saveAndFlush` now holds a save-capture ordering lock while it acquires
the same catalogue authority, snapshots `WorldRecord.nextEntityId`, deep-copies
all modified resident chunks, merges pending unloaded records, clears the
captured dirty bits and submits the immutable batch to the serial save queue.
Unload staging and periodic pending-batch submission use the same lock and
authority. Thus capture and candidate publication/rollback have one order: a
save captures the pre-candidate World, or it waits and captures the final
post-decision World; it cannot capture the transient candidate. Holding the
capture-order lock through queue submission also prevents an older snapshot of
one chunk from committing after a newer compensating snapshot.

Correction 03 keeps `authorityGeneration` exclusively in Core. A detachable
`SignInscriptionAuthorityObservation` is an opaque, World/catalogue-bound test
token, not a durable PebbleAgents receipt. Production read, notation practice
and final writing publication instead call
`World.withCurrentSignInscriptionAuthority`: Core takes the catalogue's
recursive lock, reconstructs and validates current physical authority, and
holds that same critical section while an opaque Pebble closure assigns the
already prepared candidate `AgentSimulationSession`. This closure execution is
the physical-authority-to-cognitive-publication linearization point. Core never
interprets the closure, and PebbleAgents receives neither World access nor an
authority generation. The explicit token finalizer exists for deterministic
hostile testing: an observation from generation N is rejected before its
closure runs after authority advances to N+1.

The authority generation is World-global, so an unrelated physical catalogue
advance conservatively stales an explicit observation token. Production does
not loop on such tokens: it obtains and publishes within one current-authority
closure, so autosave either completes before the fresh validation or waits
behind publication; there is no retry livelock. On a failed write, the adapter
restores the candidate physical state only when that state is still exactly the
operation-owned state. Because persistence capture cannot enter during that
candidate interval, an exact rollback may safely return the last identity to
the allocator. It never overwrites a later external mutation; if exact rollback
is no longer provable, the operation fails closed and the identity remains
consumed. Failed save batches restore either the current resident dirty bit or
the exact pending unloaded record under the capture-order lock before the next
batch can supersede them.

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
PEBBLELAB_CIV45_BUILD_CONFIGURATION=debug scripts/verify-pebblelab-civ45-correction04.sh
8/8 in-process capture/rollback/save checks passed
3/3 separate-process restart checks passed

PEBBLELAB_CIV45_BUILD_CONFIGURATION=debug scripts/verify-pebblelab-civ45.sh
56 passed, 0 failed # Correction 02 dirty/index/migration/concurrency
4/4 crash boundaries passed across fresh processes
26 passed, 0 failed # exact persistent P0 regression
11 passed, 0 failed # Correction 03 stale read/practice/write/finalization
105 passed, 0 failed

PEBBLELAB_CIV45_BUILD_CONFIGURATION=release scripts/verify-pebblelab-civ45.sh
56 passed, 0 failed # Correction 02 dirty/index/migration/concurrency
4/4 crash boundaries passed across fresh processes
26 passed, 0 failed # exact persistent P0 regression
11 passed, 0 failed # Correction 03 stale read/practice/write/finalization
105 passed, 0 failed

PEBBLELAB_CIV45_BUILD_CONFIGURATION=release scripts/verify-pebblelab-civ45-correction04.sh
8/8 in-process capture/rollback/save checks passed
3/3 separate-process restart checks passed
```

The deterministic pre-fix reproduction used the real production WRITE adapter
and `testingSignInscriptionPersistenceHook(.prepared)` with semaphores and no
sleep. It forced `T1 inscribe X → T2 capture/prepare X → T1 cognitive refusal
and rollback → T2 commit`, then observed resident blank state and reusable
`X = 503` while SQLite and the compact index retained `material-503`; a fresh
GameCore reload resurrected that ghost. This confirms the Correction 03 P0
rather than merely modeling it. The retained trace is
`/tmp/pebblelab-civ45-c04-prefix-final.Zfbu1h/prefix-final.log`.

The Correction 04 proof now forces `T2` to attempt capture while `T1` owns the
candidate authority. The observed order is `capture-attempt →
cognitive-refusal → prepared-after-rollback → committed-after-rollback`, and
the prepared record is blank. Exact rollback may reuse that uncaptured
identity immediately; restart contains exactly that legitimate allocation and
no ghost. A prepared save that subsequently aborts restores its dirty retry
state. A committed save cannot precede failure while containing the candidate,
because capture is blocked until the decision. The external-mutation variant
fails rollback closed, preserves only the external edit in the captured and
durable state, and burns its material identity. Two queued snapshots of one
chunk commit in capture order, so the newer state wins after restart.
The final Debug and Optimized two-process evidence roots are respectively
`/tmp/pebblelab-civ45-correction04.u0XcKO` and
`/tmp/pebblelab-civ45-correction04.39Ynku`.

The Correction 03 suite forces the exact deterministic order `T1 observe N →
T2 commit N+1 → T1 finalize N`. Stale read, notation practice and final
writing publication all return `staleAuthority`; their finalization closures
do not execute, and byte-for-byte serialized cognitive state remains unchanged.
The tests additionally prove no claim, understanding, revision, belief,
historical read, lesson, guided-use count, literacy grant or ordinal is
consumed. A fresh observation under N+1 then follows the legitimate path.

The new 56-check Correction 02 suite proves dirty removal, replacement and new
duplicate addition before/after autosave; resident and staged chunk-key
replacement; cross-dimension uniqueness; cross-World isolation; relevant and
unrelated corruption policy; corrupt-index fail-closed behavior even with a
resident chunk; text-only legacy migration; exact one-shot/steady-state decode
counts; and both reader/save linearization orders. Four additional fresh
writer/reader process pairs terminate before transaction, after all writes but
before commit, immediately after commit and after normal return. Their
two-chunk batch is always observed as either both old or both new, and restart
never reuses either allocated identity.

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
scripts/verify-pebblelab-live.sh --dry-run --writing
scripts/verify-pebblelab-live.sh --writing
```

The Correction 04 dry-run passed. The release campaign used the Correction 04
Pebble build, then ran two fresh real processes for each of seeds 46 and 73
under disposable `CFFIXED_USER_HOME` roots. Process one created an ordinary blank oak sign on a
natural supported site, observed a real oak log, wrote the false `stone`
assertion, performed and rolled back an injected late failure, completed one
local notation lesson, saved World and wrote a schema-40 checkpoint, then
terminated. Process two loaded that same World, restored the exact checkpoint,
proved the Core sign bytes identical, completed the second local lesson, read
through CIV-42 and CIV-41, proved World remained wood, edited and replaced the
sign, refused the old artifact without cognitive mutation, restored the
fixture and stopped.

All four processes exited zero with zero runtime errors and no residual Pebble
process. Read, practice and writing in that live binary route through
`withCurrentSignInscriptionAuthority`, the same Correction 03 finalization
primitive covered by the deterministic stale tests. The live campaign proves
the legitimate current-authority path; it does not substitute for the hostile
N→N+1 or Correction 04 capture-order proofs. The final Correction 04 campaign
root is:

```text
/tmp/pebblelab-civ45-live.QEUb4H
```

Seed 46 used material identity 288, artifact
`inscription-0d45bd0d3b7bb9c470c9ac4290a842d1e0ae21cbccf2132ee4428b888221137d`,
sign `(22,68,-21)` and real oak-log source `(19,66,-24)`. Seed 73 used
material identity 147, artifact
`inscription-37fb76d4ff53009d818b137ff45c6a20205cea70018858f3780a88ea03bb9246`,
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
| 46 | `write.log` | `d5012798391524313c08f51a28dbd59527d4d4eb132c2b2ff64879bd40566f46` |
| 46 | `read.log` | `e5353c5e485c01b51fa803b9c276e17cb41da2342ff4d21441bb4d1dc78872ba` |
| 46 | `written-sign.json` / byte-identical `reloaded-sign.json` | `2d7cac9db0189b3f5b55b61d27b49f647d7b831436ddae1cfbcf3261a831ffb2` |
| 46 | `writing-checkpoint.json` | `88ad427311a3ce2eb80f590a006fcb71765ef151689cc14176465a2fb496780b` |
| 46 | `reading-checkpoint.json` | `01ee577c43a94c7ad9a4cf4964b2591f78ca64d3fceba4c841558dd0d5f3e187` |
| 46 | `written.png` | `135b082f8cccd3027f31ffd8951f8fb83b93cc0402c7a202708ecfc4518994e9` |
| 46 | `read.png` | `73bd2508a26415e6eaee73f1d8d9ea1c9159d6697a2ae8e95860e30a3e4de314` |
| 73 | `write.log` | `fd7523a114cc7771cde40d65a10696a8dfbb3b578218ab646647ae5b6b2e18bb` |
| 73 | `read.log` | `155be2dd879a98fb6b501ce6a999c97f3d88c7934623c0ba1a516e8048dba914` |
| 73 | `written-sign.json` / byte-identical `reloaded-sign.json` | `5fcd580be3fbcdc0d4a6901d3b3e0a5664c629c4b2103989b144933bc078bdeb` |
| 73 | `writing-checkpoint.json` | `17b5313414368a137b128e6396b66432a0968264e68d2541a8afe064cfc82b68` |
| 73 | `reading-checkpoint.json` | `3559e30ce504c81014256d3394702b182bbe999d8da8676876c2ae4f50cef7e1` |
| 73 | `written.png` | `462ed317e571817c547f008c4958b1e0b99e3a658e6316a3bb192d3882749fb7` |
| 73 | `read.png` | `724ad54527f3b3bcf315ac35719e87ec1f8031d61d80c2b21b5a1ae4ed95110e` |

## Canonical repository gate and intermediate failures

The final canonical command was:

```bash
scripts/verify-pebblelab.sh
```

The final Correction 04 run passed all 35 repository steps against exact
product/test commit `ff68b1d60f7159fec17d0bb98433235f75e767d1`. The shared
runtime reported `4644 passed, 0 failed`; deterministic scenario pairs and
canonical output comparisons all passed. Evidence is retained at
`/var/folders/23/t4l5dv055dl3x1zqylcpl9wc0000gn/T/PebbleLab-verify.rvITSM`,
with the captured console log at
`/tmp/pebblelab-civ45-c04-repository-gate.pYo1Vb/repository-gate.log`.
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
- Correction 02 first reached `47/48`: corrupt compact-index bytes were
  detected, but a later assignment accidentally reset the source-valid flag,
  allowing a resident chunk to mask the corruption. A second `47/48` rerun
  isolated that overwrite. Source invalidity is now monotone for the load and
  the permanent regression passes within the final `56/56` suite.
- an early multi-process crash fixture assumed material identity 1 remained
  available after `GameCore.loadWorld`; the loaded player had legitimately
  consumed it. All four writers therefore exited 2 at fixture setup. The
  fixture now allocates through the actual counter and additionally mutates
  two chunks atomically; this was a test defect, not a product failure.
- one ad hoc Correction 02 run reused the developer SaveDB and crashed its
  forced fixture unwrap after prior rows polluted the named World. Every
  durable runner now uses a fresh `CFFIXED_USER_HOME`; the hermetic rerun
  passed `56/56`.
- two shell commands were rejected before execution because they included
  inline cleanup forms; reruns without those command forms passed. A
  `swift test list` discovery was also stopped after confirming that the empty
  `Tests` directory defines no test target; it had only begun redundant builds.
- the first Correction 03 canonical-gate evidence stream ended during
  PebbleLab Release compilation when the Codex quota interrupted the task. It
  contained no compiler diagnostic and no final gate result; on resumption no
  Swift or verifier process remained, so that incomplete log was retained and
  only the canonical gate was rerun. The rerun passed `35/35`. This was an
  orchestration interruption, not a product/test failure.
- the first Correction 04 proof used a wrong disposable World name and was
  refused by the existing proof guard before the concurrency scenario;
- an intermediate pre-fix harness used a second save as a completion barrier,
  which legitimately lowered its synthetic `WorldRecord` and invalidated the
  catalogue. The retained final reproduction waits for the intended save
  directly and reproduces the P0 without that extra capture;
- the first Correction 04 compile referenced a nonexistent convenience field
  on the plan; the proof now compares the explicit physical fields;
- one proof harness attempted to wait for a main-queue recovery callback by
  running a non-reentrant run loop and stalled. Stack inspection identified the
  harness issue; the final deterministic callback seam avoids that wait and
  proves dirty recovery;
- the first Correction 02 rerun reached `54/56` because its old test assumed
  `saveAndFlush` returned before capture. The test was synchronized at the new
  capture seam and the unchanged behavioral assertions then passed `56/56`.
  These were test-orchestration failures, not hidden product results.

## Deliberate V1 limits and non-claims

CIV-45 provides one immutable inscription on an existing standing sign. It
does not implement books, manuscripts, loose carried pages, copying,
inventories of texts, archives, libraries, cognitive catalogues, general
content indexes, institutional conservation, global retrieval or
historiography. The compact SaveDB index is only physical identity-integrity
metadata. CIV-45 does not implement
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
CIV-45: CORRECTION 04 LOCAL REVIEW CANDIDATE — NOT PUBLISHED
CIV-46: PLANNED — NOT STARTED / NOT AUTHORIZED
CIV-47: PLANNED — NOT STARTED / NOT AUTHORIZED
V4-GATE-G-v1: PLANNED / UNEVALUATED
next action: CIV-45 INDEPENDENT SENIOR RE-REVIEW
```
