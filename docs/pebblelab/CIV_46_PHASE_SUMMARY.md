# CIV-46 — Books, Manuscripts, Archives and Libraries V1

## Local review status

`CIV-46` is **IMPLEMENTED AND TESTED LOCALLY — EXTERNAL SENIOR REVIEW
PENDING — NOT PUBLISHED**.

```text
Exact baseline: f78f0d3c282282d75cc3d27418135246de2975b7
Branch: codex/civ-46-books-manuscripts-archives-libraries-v1
Product/test commit: 1ada83ae248552924a4f729439654ad7ff8abfaa
External senior review: NOT PERFORMED
Publication: NOT PERFORMED
Gate G: PLANNED / UNEVALUATED
CIV-47: NOT STARTED
```

The final documentation commit and review ZIP identify the complete local
candidate. Nothing in this record grants senior approval or remote publication.
All historical CIV-45 Initial/Correction 01–08 `CORRECTION REQUIRED` verdicts
remain unchanged.

## Architecture and authority

CIV-46 adds a bounded catalogue and provenance layer to the sole existing
`AgentSimulationSession`. It does not create a second kernel, World, physical
carrier registry, knowledge graph or culture authority.

- PebbleCore remains physical authority for the World and the current globally
  unique sign inscription.
- CIV-45 remains authority for the persistent material written carrier and for
  each accepted reading.
- CIV-41 remains the only generic authority for source claims,
  understandings, beliefs, evidence and epistemic history.
- CIV-42 remains semantic and linguistic authority.
- Pebble's archive adapter observes the required current CIV-45 carriers and
  asks Core to revalidate the complete batch while an opaque candidate session
  is published.
- CIV-46 retains only collection, manuscript, lineage, material-witness,
  retrieval and causal-boundary metadata.

An `AgentArchiveCollection` is a bounded catalogue scope, not an institution.
The names `archive` and `library` do not introduce CIV-47 culture, norms or
organization authority.

## Provenance, retrieval and loss

Each source, facsimile and revision is a distinct CIV-45 artifact. A facsimile
must match its parent proposition and lines; a revision must preserve the
question while changing the asserted proposition. Both append a new
manuscript identity and causal event. Neither rewrites the parent.

The durable material witness contains World, dimension, cell, artifact and
material identities, a content digest, observer and tick. It deliberately
contains neither lines nor proposition content. Retrieval starts from a
derived index selection but must return through CIV-45 `readWriting` with a
fresh physical receipt. CIV-45 then delegates any written claim/belief effect
to CIV-41. Catalogue, search and retrieval themselves do not manufacture
evidence or mutate World truth.

Destroying the catalogue mark removes live search access. Destroying the
selected carrier removes live retrieval access. Historical catalogue metadata
may remain, but it cannot publish a new reading or reconstruct the lost text.

## Derived index and boundedness

The index is an in-memory, non-`Codable` projection rebuilt from bounded
CIV-45 artifacts plus bounded CIV-46 collections/manuscripts. Durable CIV-46
state stores only a revision and source digest used to reject stale indexes.
It never stores postings, lines or asserted proposition values.

Rebuild visits at most the configured artifact/collection/manuscript bounds
and emits at most seven metadata postings per manuscript. Lookup addresses one
posting bucket, scopes it to one collection, returns at most the configured
result limit, and reports zero global-history scans. Caller-controlled query
text and operation identities are prefix-validated before full construction or
hashing.

## Persistence, replay and failure semantics

Checkpoint and replay schema 41 add the archive state and typed operations.
Collection and manuscript IDs are deterministic hashes of stable World and
logical operation identities. A logical operation ID is unique across archive
collections, manuscripts and retrievals. Exact retry returns the accepted
record; divergent reuse is refused.

Every durable transition is built on a copy of the aggregate and published
only after archive, causal, CIV-45, CIV-42 and CIV-41 validation succeeds. The
Pebble adapter performs no World mutation and commits only inside Core's batch
current-authority validation. Restore rejects missing archive state, stale
derived commitments and an archive whose CIV-45 writing authority is disabled.
Causal FIFO compaction refreshes a bounded archive provenance commitment before
eviction and participates in aggregate rollback.

The historical shared-surface changes are limited to what schema 41 requires:

- `AgentCheckpoint` persists/validates archive state and recognizes schema 41.
- `AgentReplay` records and deterministically reapplies the four archive
  operation kinds.
- `AgentCausalLedger` adds typed archive events/payloads; it does not reinterpret
  earlier events.
- causal compaction snapshots and refreshes the archive boundary atomically.
- Gate F blocker 05/08/09 schema sentinels extend the already-strict historical
  policy through supported schema 41 and now reject future schema 42.
- the CIV-45 writing adapter exposes its existing current-material observation
  internally so the CIV-46 batch adapter can reuse the same Core authority.

## Executed evidence

On the exact product/test tree committed as
`1ada83ae248552924a4f729439654ad7ff8abfaa`:

- `scripts/verify-pebblelab-civ46.sh` in release: PASS.
- CIV-41: 3/3 writer, 5/5 reader, 47/47 focused.
- CIV-42: 3/3 writer, 5/5 reader, 56/56 focused.
- CIV-43: 1/1 writer, 3/3 reader, 81/81 focused.
- CIV-44: 2/2 writer, 5/5 reader, 62/62 focused.
- CIV-45: 105/105 focused, plus relevant Core identity, crash,
  stale-authority, snapshot-recovery and lifecycle suites all passing.
- CIV-46: 38/38, covering provenance, copy/revision continuity, checkpoint and
  fresh restoration, loss, rebuild, replay/idempotence, capacity/failure
  atomicity, causal compaction, hostile restore and structural bounds.
- `scripts/verify-pebblelab.sh`: 35/35 steps and 4682/4682 assertions PASS,
  including debug/release builds, golden/shared runtime, deterministic paired
  scenarios and repository hygiene.
- `PEBBLE_REGOLD` was absent; network and fallback paths were not used.

The accepted live campaign used the final creative observer/camera harness in
debug configuration and two deterministic seeds, 46 and 73. For each seed,
the write process and the independent reload/retrieval/loss process ended with
an explicit `status=PASS`, verified cleanup and no residual Pebble process.
Both schema-41 archive checkpoints and post-retrieval checkpoints were emitted.
The four final images (`catalogued.png` and `before-loss.png` for each seed)
were inspected. Seed 73 shows the camera/player alive in normal HUD state; the
previous drowned-camera defect is absent.

The accepted live run preceded two final defensive pure-validation additions:
rejection of disabled CIV-45 authority in a hostile archive checkpoint and
prefix-bounded public search input. Neither changes the valid live flow; both
were exercised afterward by the 38/38 release suite and the full repository
gate. The long live campaign was therefore not repeated solely for those two
negative-path guards.

Rejected intermediate campaigns remain evidence only, never final proof:

- an initial same-reader setup failed the distinct-reader contract;
- a retry attempted two literacy lessons at one tick and was refused;
- one functionally green run had a capture-path separator defect;
- the preceding two-seed run was functionally green but its seed-73 captures
  were rejected because the camera/player was drowning.

## Remaining review boundary

No functional failure is known. External senior review, independent ZIP
inspection and publication have not occurred. The renderer emitted two
pre-existing unused-variable warnings (`lightViewM`, `lightProjM`) during the
repository gate; they are outside CIV-46. Gate G remains unevaluated and CIV-47
remains unstarted.

```text
Status: LOCAL REVIEW CANDIDATE / NOT PUBLISHED
Push attempted: NO
```
