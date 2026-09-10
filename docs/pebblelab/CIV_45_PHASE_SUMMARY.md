# CIV-45 — Writing and Literacy V1

## Review status and baseline

`CIV-45` is a **CORRECTION 09 SENIOR-APPROVED LOCAL PUBLICATION CANDIDATE —
NOT PUBLISHED**. It was
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
product/test commit is `ff68b1d60f7159fec17d0bb98433235f75e767d1`, with
candidate `2a83631ee642e2bc71f7da4c82b01172f35c7bdc`. Its final independent senior
re-review returned **CORRECTION REQUIRED** because a failed older chunk
snapshot could be reinserted after a newer unloaded snapshot and later win a
retry. Correction 05 product/test commit is
`01b9826afc4ca96efb0f07556c53073524cbbf97`, with candidate
`cf80aa1f789edd74417bf225ef34a5fad3eac588`. Its final independent senior
re-review returned **CORRECTION REQUIRED** because newer physical snapshot B
was forgotten by the streaming load path after pending submission but before
durable commit, allowing old SQLite A to become resident and receive a newer
capture sequence; synchronous lifecycle failure recovery could also remain
only in a main-queue callback that World destruction or process termination
could abandon. Correction 06 product/test commit is
`d551a5e9b9d57c64c9ae5bc408949fd8f7b2c0d5`; candidate
`a8f153715cf02ec28225cd86e7ba045b715d9323` received **CORRECTION REQUIRED**
because lifecycle cleanup could mutate persistent physical state after the
last successful barrier, AppKit cancellation could occur after irreversible
civilization shutdown, and non-chunk persistence failures were not included
in the lifecycle result. Correction 07 product/test commit is
`6890eab1f460a09b2fe01bf02d4a0fd248528ea9`; candidate
`c7f497d679a4d0046de6e8ad28e6d9504e3166ff` received **CORRECTION REQUIRED**
because normal streaming could evict a non-persistent probe while the
controller registry retained the same object and its material custody, letting
a successful lifecycle omit that custody. Correction 08 product/test commit is
`fe168f72d31fdbc0a1f783b351c0974ec649b1bb`; candidate
`54d9e4ba37340178927411b3bf5f3bd5cedae4c5` received **CORRECTION REQUIRED**
because synthesized `Decodable` reconstructed `AgentPopulationConfiguration`
without its validated initializer, allowing a coherent persisted maximum of
513 and eight other out-of-contract field values to reach restoration.
Correction 09 product/test commit is
`3d1fdeea7c1e2f833a97b903c1357dd1d0acfe77`; the corrected review candidate is
`f92dacb841a74a7512212eead20f6300531a63f7`. Independent senior re-review
returned **PASS — SENIOR REVIEW APPROVED**, with zero blocker/P0, zero
major/P1 and zero minor findings. All nine failed candidates remain intact,
immutable historical evidence and are not represented as approved.

```text
Initial CIV-45 candidate: CORRECTION REQUIRED
Correction 01 candidate: CORRECTION REQUIRED
Correction 02 candidate: CORRECTION REQUIRED
Correction 03 candidate: CORRECTION REQUIRED
Correction 04 candidate: CORRECTION REQUIRED
Correction 05 candidate: CORRECTION REQUIRED
Correction 06 candidate: CORRECTION REQUIRED
Correction 07 candidate: CORRECTION REQUIRED
Correction 08 candidate: CORRECTION REQUIRED
Correction 09: PASS — SENIOR REVIEW APPROVED — NOT PUBLISHED
```

The published branch remains complete through CIV-44. Correction 09 is the
senior-approved local publication candidate, but CIV-45 has not been published
and independent remote publication verification remains pending. The next
authorized action is protected manual publication of the senior-approved
CIV-45 candidate, then independent remote verification. CIV-46 and CIV-47 have
not started and remain unauthorized. `V4-GATE-G-v1` remains **PLANNED /
UNEVALUATED**.

The review retained two **OBSERVATION / NON-BLOCKING** notes. The required C05
suite remains `23/23 PASS`, while its optional proof-hook continuation is not
claimed as PASS because it may synchronously re-enter save under
`saveCaptureLock`; no reachable ordinary production equivalent was identified.
The explicit `AgentPopulationConfiguration.CodingKeys` must also remain aligned
with any future persisted field; all nine current fields are present and there
is no current schema defect.

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
capture-order lock through queue submission prevents normal capture/enqueue
inversion. Correction 04 did not, however, carry a causal age with a failed
snapshot: late recovery of older A could overwrite pending newer B and obtain
a newer SQLite version on retry.

Correction 05 assigns a deterministic process-local `UInt64` capture sequence
under `saveCaptureLock`. The immutable sequence follows each chunk record
through capture, queue submission, pending unload storage and failed-save
recovery. `latestChunkSaveCaptureSequence` records the latest capture by
durable chunk key. Recovery of a nonresident record compares its sequence
before reinsertion; an older A is a no-op when newer B exists, so the pending
map retains the maximum sequence. Recovery against a resident chunk never
injects the old payload and only marks the current resident state dirty. The
counter fails closed before wrap and is neither clock-, UUID- nor
randomness-based. It is intentionally not persisted: pending records,
in-flight batches and callbacks cannot survive process termination, after
which SQLite and the compact inscription index are the sole durable authority.

Correction 06 extends that causal order with a Core-owned unresolved horizon.
For each true physical key (`World ID + dimension + chunk coordinates`),
`unresolvedChunkSaveCaptures` retains the maximum captured record while it is
pending, queued, in flight, committing or awaiting failed-save recovery. A
pending entry may be removed for submission without removing this record. Both
the asynchronous `requestChunk` path and the synchronous portal/respawn loader
prefer the horizon record to an older SQLite row. An asynchronous load also
rechecks the latest sequence before adoption and discards/reissues work if a
newer generation appeared. Thus durable A cannot be transformed into a fresh
resident capture while unresolved B exists; with B and C outstanding, C is
the only streaming authority.

The horizon stops owning a capture only after its exact sequence commits and
SQLite plus the compact catalogue have caught up, or when a newer capture
safely supersedes the retained record. Merely materializing it as resident does
not erase the unresolved horizon. Failed
batches synchronously retain and requeue their still-current capture on the
serial save worker; the main-queue callback only marks a matching current-World
resident dirty and cannot inject an old payload or touch a replacement World.
`saveAndFlush(synchronous: true)` is a queue barrier, observes earlier async
failure, retries once from the retained horizon and returns failure while any
capture for that World remains unresolved.

Lifecycle owners now consume that result. `exitToTitle` and World replacement
are refused with the World and horizon intact when persistence cannot resolve.
AppKit's `applicationShouldTerminate` likewise returns termination-cancel on
the first failed attempt; after retry commits, a second attempt returns
termination-now. `applicationWillTerminate` retains a fail-closed assertion as
a fallback rather than treating persistence failure as success. Correction 06
does not add a journal and does not promise recovery after a forced process
kill: it prevents normal lifecycle teardown from silently discarding the sole
in-memory recovery state.

Correction 07 closes the remaining lifecycle boundary with four ordered
phases. Phase 1 prepares the lifecycle-owned physical final state before the
last save: each carried probe stack is transferred into a real persistent
`ItemEntity`, its chunk is marked dirty, and the probe remains live with empty
custody. This preparation is idempotent, so repeated failed exits cannot spill
the same inventory twice. Session, bindings, focus, replay, gateways and the
rest of the controller runtime remain coherent while cancellation is still
possible. Active coupled construction, interaction or proof cleanup is refused
before mutation rather than partially torn down.

Phase 2 is the final durable barrier. Its result is the conjunction of the
actual WorldRecord, Player, Advancements and chunk/index write results plus an
empty unresolved-persistence condition. These writes are not claimed to form
one global SQLite transaction; the lifecycle advances only after all required
surfaces have converged successfully. A failed WorldRecord, Player or
Advancements write therefore returns failure even when the chunk record count
is zero or `putChunks([])` succeeds. Mixed partial success remains explicit and
an idempotent retry converges every required surface.

On failure, `exitToTitle`, World load/create replacement and AppKit termination
retain the old World and the usable civilization. On success only, phase 3
performs irreversible controller/session shutdown and removes the now-empty
transient probes; phase 4 destroys, replaces or terminates the World. Thus no
inventory spill, `ItemEntity` creation, identity allocation or chunk dirtying
occurs after the final successful barrier. The normal AppKit proof exercised
two `.terminateCancel` replies with the same simulation, focus, follow mode,
probe identities and advancing ticks, then repaired persistence and observed
shutdown followed by `.terminateNow` on the third attempt.

Correction 08 closes the streamed-probe custody gap without making camera
distance a civilization event. `World.entities` and `entityById` remain the
physical incarnation authority; `probesByAgentId` remains only a binding
registry for those same objects, never persistence or an unincarnated-agent
store. During normal `streamChunks`, a chunk containing a live
`LabCoreAgentEntity` is retained. The general low-level `unloadChunk` primitive
is unchanged and remains directly usable by existing persistence proofs.
Walking away therefore causes no spill, custody transfer, `ItemEntity`
creation, identity allocation or cognitive event: the same probe object,
binding and carried inventory remain authoritative through out/in cycles.

Lifecycle preparation additionally requires exact equality between the
session agent IDs, registry IDs and World probe IDs, resolves every binding to
the identical object in `entityById`, and rechecks the condition after physical
preparation. An abnormal low-level detachment therefore fails closed rather
than allowing a successful lifecycle to forget custody. The pre-fix production
trace exercised `frame → tick → streamChunks → unloadChunk` and observed
`beforeWorld=YES afterWorld=NO registry=YES custody=7 lifecycle=PASS restart=0`.
After Correction 08, ordinary streaming conserves carried quantity exactly,
while the already-owned Correction 07 lifecycle materializes that custody once
at its semantic persistence boundary.

Retention is bounded by the number of simultaneously incarnated probes: the
normal population is at most 8, the scale application target at most 24, and
the configuration hard maximum is 512. One probe can retain at most its own
chunk, so the production scale target adds at most 24 resident chunks (about
9.6 MiB at the measured 400 KiB per chunk); 512 chunks (about 200 MiB) is only
a theoretical configuration maximum, not permanent consumption. There is no
historical retained set: every streaming pass derives retention from current
World entities. Mortality, stop and normal semantic probe removal remove the
incarnation and binding, after which the chunk is normally evictable.

Correction 09 closes the persisted premise of that bound without redesigning
Correction 08. Before C09, normal construction called the validated
`AgentPopulationConfiguration` initializer, but synthesized `Decodable`
assigned its stored properties directly. A self-consistent checkpoint with
`maximumActivePopulation = 513` and matching settlement capacity therefore
decoded, validated and produced a restorable candidate. The same bypass
covered the complete serialized constructor contract:

```text
maximumActivePopulation      3...512
maximumMigrationRecords      1...64
maximumConcurrentMigrations  == 1
maximumMigrationDistance     1...64
maximumEntryCandidates       1...16
maximumRouteLength           1...32
maximumMigrationTicks        1...256
maximumMigrationReplans      0...3
arrivalDistance              == 0
```

C09 preserves the same nine `CodingKeys`, field names and `Int` types. Its
custom decode reads those fields and delegates construction to the same
validated initializer used by the normal API; valid decoded configuration is
therefore equivalent to valid normal construction for the serialized
contract. `validatePopulationRegistry` invokes that same canonical validation
as a secondary in-memory restore defense and does not maintain a divergent
limit list. There is no schema bump, migration, clamp or fallback.

The historical pre-fix checkpoint had a valid outer digest, checkpoint ID,
manifest and matching settlement capacity, yet reported
`decodedMaximum=513 settlementCapacity=513 validation=PASS
restoreCandidate=PASS status=REPRODUCED`. Post-fix, direct decode, checkpoint
restore and replay decode reject 513 deterministically before candidate
publication, registry publication, probe planning/spawn, World or custody
mutation. Boundary 512 remains valid, and a real 512-member population refuses
admission 513 without consuming an identity or mutating state. Consequently:

```text
restored active population <= maximumActivePopulation <= 512
incarnated probes <= active population
probe-retained chunks <= incarnated probes <= 512
```

The final 512 value is a theoretical simultaneous-incarnation ceiling, not a
permanent resident-chunk allocation; normal scale remains 24 and retention is
recomputed from current World entities on every streaming pass.

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
consumed. Failed save batches restore the current resident dirty bit or requeue
an unloaded record only when its capture sequence is still current. A stale
recovery cannot modify pending state or catalogue staging.

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
Correction 09 Debug campaign at exact product commit 3d1fdeea7c1e2f833a97b903c1357dd1d0acfe77
42 passed, 0 failed # C09 full restored population contract
49 passed, 0 failed # checkpoint/replay
19 passed, 0 failed # persistence reconciliation
66 passed, 0 failed # population/migration
69 passed, 0 failed # scale/restoration
6 passed, 0 failed # streaming retention, custody, replacement, multi-probe and cycles
AppKit two terminateCancel attempts then terminateNow: PASS
fresh-process restart custody: 1 passed, 0 failed
8 passed, 0 failed + AppKit PASS # Correction 07
24 passed, 0 failed # Correction 06, including direct unload and restart
23 passed, 0 failed # Correction 05 required suite
Correction 04 two-process proof PASS
11 passed, 0 failed # Correction 03
56 passed, 0 failed + 4/4 crash boundaries # Correction 02
26 passed, 0 failed # persistent identity
105 passed, 0 failed # CIV-45
93 passed, 0 failed # mortality

Correction 09 Release/Optimized campaign at the same exact product commit
42 passed, 0 failed # C09 full restored population contract
49 passed, 0 failed # checkpoint/replay
19 passed, 0 failed # persistence reconciliation
66 passed, 0 failed # population/migration
69 passed, 0 failed # scale/restoration
6 passed, 0 failed # Correction 08 focused
AppKit lifecycle and fresh restart PASS
8 passed, 0 failed + AppKit PASS # true Release Correction 07
24 passed, 0 failed # Correction 06
23 passed, 0 failed # Correction 05 required suite
Correction 04 two-process proof PASS
11 passed, 0 failed # Correction 03
56 passed, 0 failed + 4/4 crash boundaries # Correction 02
26 passed, 0 failed # persistent identity
105 passed, 0 failed # CIV-45
93 passed, 0 failed # mortality

C09 focused outcomes in both Debug and Release
18 invalid configurations rejected with API/decode parity
maximumActivePopulation 513 direct decode rejected
maximumActivePopulation 512 accepted and round-trip byte exact
valid outer checkpoint + matching settlement capacity 513 rejected
replay operation carrying 513 rejected before application
candidate publication NO; physical mutation ZERO; no clamp or fallback
512 members then normal admission 513 REFUSED without identity consumption

scripts/verify-pebblelab-civ45-correction07-phase1.sh
8 passed, 0 failed # lifecycle Core Debug
AppKit attempts 1/2 terminateCancel with active civilization; attempt 3 terminateNow

Correction 07 Release/Optimized campaign at exact product commit 6890eab1f460a09b2fe01bf02d4a0fd248528ea9
8 passed, 0 failed # lifecycle Core
24 passed, 0 failed # Correction 06 unresolved horizon
23 passed, 0 failed # Correction 05 stale recovery freshness
11 passed, 0 failed # Correction 03 stale physical authority
56 passed, 0 failed # Correction 02 identity/index/concurrency
4/4 crash boundaries passed
26 passed, 0 failed # persistent identity
105 passed, 0 failed # CIV-45
Correction 04 two-process proof PASS

PEBBLELAB_CIV45_BUILD_CONFIGURATION=debug scripts/verify-pebblelab-civ45-correction06.sh
24 passed, 0 failed # unresolved streaming/lifecycle Core
accepted WRITE B / separate-process restart B / AppKit termination passed

PEBBLELAB_CIV45_BUILD_CONFIGURATION=debug scripts/verify-pebblelab-civ45-correction04.sh
8/8 in-process capture/rollback/save checks passed
3/3 separate-process restart checks passed

PEBBLELAB_CIV45_BUILD_CONFIGURATION=debug scripts/verify-pebblelab-civ45.sh
56 passed, 0 failed # Correction 02 dirty/index/migration/concurrency
4/4 crash boundaries passed across fresh processes
26 passed, 0 failed # exact persistent P0 regression
11 passed, 0 failed # Correction 03 stale read/practice/write/finalization
23 passed, 0 failed # Correction 05 stale recovery freshness
24 passed, 0 failed # Correction 06 unresolved streaming/lifecycle freshness
105 passed, 0 failed

PEBBLELAB_CIV45_BUILD_CONFIGURATION=release scripts/verify-pebblelab-civ45.sh
56 passed, 0 failed # Correction 02 dirty/index/migration/concurrency
4/4 crash boundaries passed across fresh processes
26 passed, 0 failed # exact persistent P0 regression
11 passed, 0 failed # Correction 03 stale read/practice/write/finalization
23 passed, 0 failed # Correction 05 stale recovery freshness
24 passed, 0 failed # Correction 06 unresolved streaming/lifecycle freshness
105 passed, 0 failed

PEBBLELAB_CIV45_BUILD_CONFIGURATION=release scripts/verify-pebblelab-civ45-correction06.sh
24 passed, 0 failed # unresolved streaming/lifecycle Core
accepted WRITE B / separate-process restart B / AppKit termination passed

PEBBLELAB_CIV45_BUILD_CONFIGURATION=release scripts/verify-pebblelab-civ45-correction05.sh
23 passed, 0 failed # stale recovery freshness
accepted WRITE B / separate-process restart B passed

PEBBLELAB_CIV45_BUILD_CONFIGURATION=release scripts/verify-pebblelab-civ45-correction04.sh
8/8 in-process capture/rollback/save checks passed
3/3 separate-process restart checks passed
```

Correction 09's retained pre-fix reproduction is
`/tmp/pebblelab-civ45-c09-phase1/prefix-513-reproduction.log`. It constructs a
self-consistent stored checkpoint and reports `decodedMaximum=513`,
`settlementCapacity=513`, `validation=PASS`, `restoreCandidate=PASS` and
`status=REPRODUCED`. The final C09 Debug logs remain under
`/tmp/pebblelab-civ45-c09-phase1/`; the resumed Phase 2 Release, gate and live
logs remain under
`/tmp/pebblelab-civ45-correction09-phase2.pvtRfi/`. The required C05 suite is
`23/23 PASS`; its optional continuation is not claimed as PASS because a
pre-existing proof hook may synchronously re-enter save while holding
`saveCaptureLock`. No equivalent product path was identified, so this remains
a non-blocking harness observation and was not changed by C09.

Correction 08's retained pre-fix log is
`/tmp/pebblelab-civ45-c08-prefx.0ggurJ/prefx.log`. It uses the production
`frame → tick → streamChunks → unloadChunk` path and reports
`beforeWorld=YES afterWorld=NO registry=YES custody=7 lifecycle=PASS restart=0
status=REPRODUCED`. The final Debug evidence root is
`/tmp/pebblelab-civ45-correction08-phase1.XATReV`; the final combined Optimized
log is `/tmp/pebblelab-civ45-c08-optimized.6PIKlh/optimized-all.log`, with the
separately confirmed true Release Correction 07 proof at
`/tmp/pebblelab-civ45-c07-optimized.NNtv68`. These proofs cover ordinary
streaming retention without spill or identity allocation, exact custody
conservation, repeated out/in, multiple and mixed probes, empty custody,
fail-closed detached bindings, exit retry, two AppKit cancellations followed by
success, World replacement, fresh restart and mortality release.

Correction 07 pre-fix evidence deterministically reproduced all three senior
findings: cleanup dirtied a chunk after a successful barrier and the spill was
absent after restart; the real AppKit callback returned `.terminateCancel`
after shutdown had removed the active session; and a failed WorldRecord write
with zero chunk records still produced a true lifecycle result. Post-fix tests
cover exit failure/retention/success, load and create replacement, two
consecutive AppKit cancellations, later successful termination, separate
WorldRecord/Player/Advancements failures, empty chunks, mixed partial failure,
retry/restart convergence and absence of duplicate spill. Debug evidence is
`/tmp/pebblelab-civ45-correction07-phase1.c0rpD6`; the Phase 2 Optimized log is
`/tmp/pebblelab-civ45-correction07-phase2-6890eab/optimized/optimized-full.log`.

The retained Correction 06 pre-fix reproduction uses deterministic semaphores
around the production unload, queue and streaming path. With SQLite A durable,
it captures B through legitimate unload, submits B so the pending map is empty
while the worker is unresolved, returns the player and observes `requestChunk`
adopt A. That A is then recaptured with a sequence newer than B and wins both
durability and fresh-GameCore restart: `resident=A durable=A restart=A
status=REPRODUCED`. The immutable pre-fix log is
`/tmp/pebblelab-civ45-c06-prefix.bpULwp/pre-fix.log`.

The final 24-check Core suite proves return-before-commit, B success and B
failure after return, pending-empty/in-flight authority, deletion, external
edit, maximum B/C generation, true World isolation, exit refusal, synchronous
termination refusal and safe World-switch callbacks. Debug focused evidence is
`/tmp/pebblelab-civ45-correction06.arTtjn`; Optimized focused evidence is
`/tmp/pebblelab-civ45-correction06.Ak3QY5`. The real application proof accepts
WRITE B from blank durable A, unloads through production streaming, returns
while B is unresolved, materializes B, injects failure, retries B and restores
the same material identity and cognition in a second OS process. The real
AppKit callback reports `firstReply=cancel WorldRetained=YES retry=COMMITTED
status=PASS`; only the second termination attempt proceeds.

The retained pre-fix Correction 05 reproduction forced old capture A to fail
only after newer unload capture B was pending. Before the fix it observed
`pendingBefore=B → pendingAfter=A → durable=A → restart=A`, status
`REPRODUCED`; its log is
`/tmp/pebblelab-civ45-correction05-prefix.Cg79dn/pre-fix.log`. The final Core
suite forces A/B, inscription/deletion, inscription/external-edit, three
generations A/B/C, newer resident B, asynchronous save, synchronous flush and
periodic pending flush. It observes strict capture ordering and proves that
late A/B callbacks cannot displace maximum-sequence C.

The final real-app proof starts from blank capture A, accepts CIV-45 WRITE B,
moves the player outside the chunk keep radius, enters the production unload
path, then releases A's late persistence failure. The authoritative bundled
final raw run reports `captureA=112`, `captureB=113`, pending B before and
after recovery, stale A rejected as `112/113`, durable B, restart B and
cognition B. Absolute process-local values are not contractual. A second OS
process opens the same SQLite store, restores the explicit cognition
checkpoint byte-exactly and verifies resident B, durable B, material identity,
compact index and `WorldRecord`. Release evidence is retained at
`/tmp/pebblelab-civ45-correction05.ofTxxv`. The older raw run at
`/tmp/pebblelab-civ45-correction05-live-release.aGwvsv` remains unchanged and
is not the final bundled run.

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

The Correction 09 dry-run passed. The release campaign used exact Correction 09
product/test commit `3d1fdeea7c1e2f833a97b903c1357dd1d0acfe77`, then ran two
fresh real processes for each of seeds 46 and 73
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
N→N+1, Correction 04 capture-order or Correction 06 unresolved-horizon proofs.
The final Correction 09 campaign
root is:

```text
/tmp/pebblelab-civ45-live.7jo0Tb
```

Seed 46 used material identity 288, artifact
`inscription-c5dee809d9a5cb29ffbb1338af594e33c3527d9a0e80ff349fb490cf2cae46d7`,
sign `(22,68,-21)` and real oak-log source `(19,66,-24)`. Seed 73 used
material identity 147, artifact
`inscription-7b1cdbfa25a4c848a6118f8c33103a051a901abd54882e1f1be605f91a46f59e`,
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
| 46 | `write.log` | `b355742668dc6827c3aced824d97db0da2eb79c1945853d41da416d31c1ee6f8` |
| 46 | `read.log` | `e0aaeda62e85698c34893be3143097d5b6e88216f7f745feb311f5132f7cb689` |
| 46 | `written-sign.json` / byte-identical `reloaded-sign.json` | `097dfd207aa98dad6ceb48ac940c9045d6e623e7b01829ef77ab61fcccabab68` |
| 46 | `writing-checkpoint.json` | `2bb1c1c4fdceec0446d77ab3ab050ae122725804f26a658cd2e79b9dc3b5953e` |
| 46 | `reading-checkpoint.json` | `dae53d5d4dcfac472a1853fda05a212322b70a041dc9f1b06630846d2f7dff03` |
| 46 | `written.png` | `e117d4f8ed0f3aaddb072156f4f8f4eca2b51477f919845803e1d7c1567cd1f2` |
| 46 | `read.png` | `9391b64b2f82754b4214dafe44b01f3061eb0e7bbd4e40e2e262dfc614099a18` |
| 73 | `write.log` | `5bcf9e93b87724b68b9967b8d93f62e76d7194f44aa00575ef086ea8e8f1fd7e` |
| 73 | `read.log` | `4f0fd10f453e2066b014bf136a035f555d326497cc1502010fe51c6d7658319e` |
| 73 | `written-sign.json` / byte-identical `reloaded-sign.json` | `3515a6197625c26852de0f8cafa1eddfc9de1f15de2b3d47cd2e892ecd4fccb8` |
| 73 | `writing-checkpoint.json` | `96bb9820e9159e161097055e8611625e67edab3c6d69422a945037ef69243757` |
| 73 | `reading-checkpoint.json` | `ee4f9f6261a30ac7ead5f2e64253a7b5f812b9f4accc46cbeef653e8b57993e8` |
| 73 | `written.png` | `8f60552a00aff830ee44b2a92707935f6a48761537fba505f665baa75a7e00ea` |
| 73 | `read.png` | `0fe0c36d1caf24296559b319ead68cce1f0d82021b0cab5c3f0c110684eab191` |

## Canonical repository gate and intermediate failures

The final canonical command was:

```bash
scripts/verify-pebblelab.sh
```

The final Correction 09 run passed all 35 repository steps against exact
product/test commit `3d1fdeea7c1e2f833a97b903c1357dd1d0acfe77`. The shared
runtime reported `4644 passed, 0 failed`; deterministic scenario pairs and
canonical output comparisons all passed. Evidence is retained at
`/var/folders/23/t4l5dv055dl3x1zqylcpl9wc0000gn/T/PebbleLab-verify.Lfy7E7`,
with the captured console log at
`/tmp/pebblelab-civ45-correction09-phase2.pvtRfi/repository-gate.log`.
Golden regeneration was not attempted.

Failures encountered and retained during development were corrected rather
than hidden:

- Correction 08 pre-fix reproduced the real streaming/custody loss with
  `beforeWorld=YES afterWorld=NO registry=YES custody=7 lifecycle=PASS
  restart=0`. Its raw log is
  `/tmp/pebblelab-civ45-c08-prefx.0ggurJ/prefx.log`;
- the Correction 05 wrapper reached its required `23/23`, then its optional
  application continuation deadlocked in a pre-existing proof hook that
  deliberately invokes a synchronous save while `saveCaptureLock` is already
  held. No equivalent reachable product path was identified, C08 did not
  change that hook or lock order, and the event is retained as a non-blocking
  proof-harness observation rather than silently represented as PASS;

- Correction 07 pre-fix reproduced `cleanupDirty=YES restartSpill=0`, real
  AppKit `.terminateCancel` with `sessionAfter=nil updateSession=nil`, and
  `putWorld=FAILED` with `chunkRecords=0` but `lifecycleBarrier=true`. The raw
  historical logs remain under
  `/tmp/pebblelab-civ45-c07-prefx.CcavwR`;

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
- the first Correction 05 app harness waited synchronously for main-queue
  recovery from a main-queue callback; the final proof uses a separate command
  batch after the deterministic callback completes;
- an intermediate harness tried to validate cognition through a probe that had
  deliberately been removed by unload. Cognition is checked before cleanup and
  from the explicit checkpoint in the second process;
- an intermediate unload kept the player on the target chunk, permitting the
  streamer to reload the old database record. The final proof moves the player
  beyond the real keep radius before invoking the production unload path;
- the second-process proof initially assumed the controller session itself was
  World-persistent. The final harness explicitly writes and restores the
  schema-40 cognition checkpoint, byte-exactly;
- one release compile used a negative default in a `UInt64` diagnostic and was
  corrected to a type-correct zero default. One Core assertion also required a
  nonempty compact index after deletion even though an empty claim index is
  valid; the final test instead checks identity, migration and zero voxel
  decode. Neither intermediate issue changed product behavior.
- three intermediate Correction 06 application-proof runs failed before the
  final assertion because the proof asked the saturated Debug generation queue
  to service an asynchronous target load while the deterministic save worker
  was blocked. Their evidence roots are
  `/tmp/pebblelab-civ45-correction06.bBYgtM`,
  `/tmp/pebblelab-civ45-correction06.671Ltk` and
  `/tmp/pebblelab-civ45-correction06.73HzRq`. The application proof now invokes
  the existing synchronous production portal/respawn chunk loader; the async
  `requestChunk` path remains independently covered by the 24-check Core suite.
  Debug and Optimized affected proofs then passed, including separate-process
  restart and the real AppKit termination callback.
- the final Correction 06 repository gate was still compiling PebbleLab Release
  when the Codex quota interrupted the conversation. The verifier process
  continued independently and completed the same log with `35/35` and
  `4644/0`; on resumption no verifier, Swift or PebbleLab process remained.
  Because the log was complete and the worktree still pointed exactly at
  `d551a5e9b9d57c64c9ae5bc408949fd8f7b2c0d5`, it was retained rather than
  redundantly rerun.

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
CIV-45: CORRECTION 09 SENIOR-APPROVED LOCAL PUBLICATION CANDIDATE — NOT PUBLISHED
CIV-46: PLANNED — NOT STARTED / NOT AUTHORIZED
CIV-47: PLANNED — NOT STARTED / NOT AUTHORIZED
V4-GATE-G-v1: PLANNED / UNEVALUATED
next action: PROTECTED MANUAL PUBLICATION, THEN INDEPENDENT REMOTE SHA VERIFICATION
```
