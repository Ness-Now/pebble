# PS01 — Core resident entity persistence conservation

This document records the Core resident entity persistence correction and its
qualification against baseline
`07a88bdc91d0fa15494b073674125f4de84354bc`, tree
`1b5372a7aecbf4410624b34339186674b7406723`. The correction does not supersede
or use the protected I09 and live-occupancy drafts or change their contracts.
Core remains the sole World/chunk/entity persistence owner. Git is the authority
for publication state.

## Invariant and identity contract

At a successful synchronous Core save barrier, every resident loaded chunk has
a durable representation sufficient to reconstruct its **current save-eligible
serialized entity set**, independently of block modification. Positive state,
latest state and empty replacement snapshots must all survive. Player has a
separate persistence owner. Asynchronous submission acceptance is not durable
barrier completion.

Ordinary `Entity.id` is a runtime incarnation ID. The supervisor explicitly
permits fresh numeric allocations and requires exact semantic state/cardinality
instead. No ordinary entity payload, durable identity system or schema changes.
Tests compare sorted serialized-record multisets, including equivalent duplicate
records, and verify fresh runtime uniqueness, World index agreement and the
persisted `nextEntityId` frontier.

## Accepted baseline observations

The accepted independent canonical seed-5/difficulty-2 proofs show:

- one ordinary Spider in a generated clean resident chunk, successful Save/Exit,
  no durable chunk row and zero Spiders in a fresh OS process;
- an older entity-only Spider record established through production unload,
  legitimate removal after readoption, a still-clean chunk and successful
  Save/Exit, followed by one resurrected Spider in a fresh OS process.

Neither proof uses agents, probes, checkpoints or external continuation.
The external baseline proofs are retained; they were not rerun on resumption.
The original pre-edit architecture audit was recorded externally before product
implementation. The final design below incorporates the supervisor's released
identity stop and the bounded reference audit.

## Owners and paths

A. Chunk.modified is set by World.setBlock, block entity insertion/removal and block entity mutations; mesh dirty/version is separate. Generation uses raw Chunk.set without marking block persistence dirty. Save submission resets modified after capturing. Existing failed-batch main callbacks conservatively mark resident chunks modified to force retry, even for entity-only records. It does not reliably track entity spawn, movement, state mutation or removal and cannot own general entity persistence.

B. Entity.shouldSaveToChunk defaults true and is independent of Mob.persistent (a despawn policy). LabCoreAgentEntity overrides false. chunkRecord additionally excludes Player and dead entities, and ordinary item/xp entities older than 4000 ticks unless ItemEntity has custody provenance. This policy must remain unchanged; a helper deciding persistence must use that complete policy.

C. A clean generated chunk with no prior full block authority can use VCK1's existing entity-only flag. Loader regenerates blocks/biomes from dimension and seed, resolves generated block entities, and uses saved.entities instead of worldgen entities. Empty saved.entities is meaningful, not equivalent to an absent record.

D/E. savedChunkKeys is loaded from DB at World entry and augmented on capture/submission before durability. Therefore it includes pending/unresolved writes as well as older durable rows. A resident previously captured key needs a new record even when its current eligible set is empty. putChunks replaces the entire row transactionally; saved.entities=[] suppresses old/worldgen entities on adoption. Deleting the row would permit seed spawns again and is unsuitable.

F. Chunk entity ownership derives from floor(position/16), with correct negative-coordinate floor division. World.entities is the sole live set. Movement has no independent chunk entity database. A new batch captures A empty and B with S and puts both in one SQLite transaction. Ordinary Entity.move and setPos update position; remove marks dead, World.removeEntity removes array/index authority, Mob.mobTick despawns through remove; Living death eventually removes via the normal death timer. No spawn-only dirty flag can cover these transitions.

G. Player is saved once by putPlayer including dimension; chunkRecord excludes isPlayer. LabCoreAgentEntity is unregistered, transient and shouldSaveToChunk=false. General unload can remove it from the live World but must not persist it. This mission must not change external continuation/checkpoint/probe lifecycle policy.

submitChunkSave currently filters resident chunks solely by modified. unloadChunk selects modified OR eligible resident non-player/non-dead entity OR savedChunkKeys. chunkRecord already serializes current eligible entity state and chooses full versus entity-only using modified/savedFullKeys. These selection paths disagree.

## Freshness and failures

Captures have monotonically assigned process-local sequences under saveCaptureLock. pendingChunkSaves retains unloaded/failed captures, unresolvedChunkSaveCaptures retains the freshest captured payload across queue/in-flight/recovery, and latestChunkSaveCaptureSequence rejects failed older payload recovery. Main capture supersedes same-key pending records with current resident state, submits in key order, and the serial save queue preserves submission order. Streaming consults unresolved captures before SQLite, and rejects/requeues generation calculated against a superseded save sequence.

putChunks encodes immutable captures, writes rows plus inscription index in one SQLite transaction, and reports failure on preparation/BEGIN/write/COMMIT refusal. Failure retains retry authority synchronously before its diagnostic main callback. savePhysicalAndFlush(synchronous:true) waits for older queue work, retries once when needed and returns false if required non-chunk writes fail or unresolved chunk saves remain. prepareForTermination/exitToTitle fail closed. Default asynchronous save returns queue acceptance, not durable completion. Autosave submits every 1200 ticks; pending unload retries are batched every 20 ticks.

The 20-tick retry currently refreshes a resident pending payload only when resident.modified. That condition also omits entity-only changes before delayed failure marking; it must use the same semantic persistence rule.

savedFullKeys preserves full block authority across rewrites. Async generation inserts loaded full keys before adoption. Synchronous ensureChunksLoaded relies on saved blockEntities setting modified during adoption rather than explicitly inserting savedFullKeys; legacy full records with nil blockEntities require examination before a broader resident refresh can be safe.

## Selected design

One shared resident predicate in [GameCore.swift](../../Sources/PebbleCore/Game/GameCore.swift)
selects block-modified chunks, current eligible entity sets, previously
saved/captured keys, and resident seed-generated entity snapshots. The same
entity eligibility policy is used for record serialization. Save submission,
unload and the periodic pending retry use that common contract.

The seed term is necessary: when an initially generated animal leaves before
its first save, no older SQLite key exists. An absent row would regenerate it.
A derived resident-only key set is established at adoption, removed on unload
and cleared at World replacement. Existing empty-record semantics then suppress
regeneration. This does not change worldgen, add an entity database, track every
mutation, or use `modified` as an entity-dirty bit.

Current resident captures supersede older pending entity state regardless of
block dirtiness. Failed entity-only writes retain key/pending/unresolved retry
authority without making terrain block-modified. Failed full writes retain the
existing resident block retry marking. Capture sequences, serial queue ordering,
stale recovery rejection and the unresolved streaming horizon remain unchanged.

Both loading paths remember valid full-record authority at shared adoption,
including historical full records without block entities. A subsequent clean
entity refresh cannot replace their terrain with an entity-only record.
VCK1, SQLite transactions and historical decoding are reused unchanged.

The simple rule deliberately refreshes stable older resident rows at autosave.
Cost is measured for 9/81/270 resident entity-only and full-record fixtures before
considering an optimization. Resident selection and the existing serialization
scan are bounded by loaded chunks and live entities; the seed-key set is bounded
by resident chunks. No speculative dirty subsystem is introduced.

## Qualification

The owning [focused suite](../../Sources/pebsmoke/PebbleCoreResidentEntityPersistenceSmoke.swift)
uses genuine generated terrain for conservation and independent OS processes
for restore. It covers A–J, removal/death/despawn, exact multisets and runtime
allocation, legacy full records, a seed-snapshot emptied before its first save,
repeated write refusal, old in-flight failure after a newer capture, production
20-tick retry, and the ordinary 1,200-tick autosave boundary.

Run it with `PEBBLELAB_SMOKE_ONLY=core-resident-entities`; the controlled storage
cost characterization uses `PEBBLELAB_SMOKE_ONLY=core-resident-performance`.
The normal full smoke includes the focused conservation suite. All prior checks
remain present; no golden or comparator is changed. All exact commands, results,
limits, live/VGS evidence and candidate identity belong to the external review
archive and final qualification report.

Final focused qualification passes 69 parent assertions and 60 assertions in
14 independent reader processes, including a release runner linked only to
PebbleCore. The directly owning persistence/freshness/continuation suites pass
174 assertions. The unchanged canonical verifier reports 5,885 passed and the
three accepted historical failures (zoo bit identity, combat lockstep and eight
A* paths). Supplemental stages 6–35 pass all 30 stages with their original
comparisons. No regold or comparison weakening occurred.

The controlled storage fixtures pass 24 cost checks at 9/81/270 residents. An
external copy of that fixture additionally measures 361/1,225/1,521 residents
and asynchronous submission (36 checks). Once historical chunks become clean
and empty, the old modified-only selection would select zero; the correction
selects every prior row to preserve empty snapshots. At 270 full rows this is
53,512,650 VCK1 payload bytes per barrier, with stable wall times of about
103–104 ms after the first clearing write. At 1,521 full rows it is 301,454,595
bytes, about 0.96–1.00 s for later stable synchronous barriers, with a 2.55 s
first clearing write. Asynchronous submission takes 7.51 ms in the empty full
fixture; encoding/SQLite writes run on the existing serial save queue. Entity-
only empty rows cost 24 bytes each. These are local storage measurements,
excluding SQLite/WAL overhead, rather than arbitrary-world timing guarantees.

The ordinary camera request square is 361 chunks at default distance 8 and
1,225 at the configured maximum 16; its maximum retention square is 1,521.
Coverage/probe retention and temporary dimensions can add residents. Work is
proportional to actual residency and the existing live-entity scans, not all
historical explored chunks. Repeated full writes are a disclosed cost (about
5 MB/s averaged over 60 seconds in the all-full maximum camera fixture), but
the measured submission time and queue workload do not justify a second dirty
subsystem for this correction. The rule remains deliberately simple.

The live/VGS campaign uses the real release Pebble client in unmodified natural
seed-5 forest canopy and seed-14 shore/slope terrain. An ordinary command spawns
one Spider; normal lifecycle saving and a distinct restarted client conserve
it. Four rendered captures were inspected. Independent Core reads after each
client exit prove exact durable/restored semantic state, unique runtime IDs
and the allocation frontier. A bounded 20-tick restart warm-up accounts for
ordinary age/physics changes before rendering. Both disposable Worlds and all
mission processes were cleaned up. This is bounded evidence for those two
Worlds; it makes no universal arbitrary-world claim.

## Bounded cross-entity reference audit

Search scope: all ordinary Entity subclasses, EntityData, factory/load paths and all Core uses of ownerId/loveCause. Classification follows the supervisor's A–D categories.

| Field/reference | Class | Evidence and qualification |
|---|---|---|
| Mob.ownerId (tamable pets/horse owner) | C | Saved and loaded numerically by Mob.save/load; tame interaction compares to Player.id and FollowOwner/defense goals look up World.entityById. Player is freshly allocated after restart and no remap exists. This is a separate existing relationship persistence risk: retained tame state can lose a valid owner. It is not fixed by this correction and does not invalidate Spider serialized-state conservation. |
| EntityData.loveCause | B | Codable origin metadata assigned by tryFeed(actorEntityID:); all Core searches find no consuming reader. Numeric historical value survives as best-effort metadata, without a durable actor identity guarantee. No inference of deliberate relational durability is made. |
| Mob.target; Living.lastAttacker/lastDeathDropItemEntityIDs; projectile owner/targetId; XP followTarget; Player.fishingBobberId; vehicle/passengers; effect-cloud affected map | A | Runtime references/indices are absent from ordinary save payloads. Runtime transaction rollback snapshots are not World persistence. |
| ItemEntity.custodyProvenance | D | Existing bounded durable provenance string; distinct from ordinary runtime ID. Its existing age exemption is preserved. |
| Lab agent/physical IDs and inscription identities | D (separate owners) | Existing controller/catalog identities; transient Lab bodies do not become chunk persistent. No ordinary durable Entity.id is introduced. |

The scan found no additional persisted actor/target numeric field beyond ownerId and loveCause in the ordinary save payloads. Item/block registry IDs, coordinate beamTarget and potion/effect identifiers are not ordinary runtime entity references.

Historical execution evidence: Push attempted: NO
