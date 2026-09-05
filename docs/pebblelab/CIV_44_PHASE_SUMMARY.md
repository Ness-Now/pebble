# CIV-44 — Compositional and Long-Distance Communication V1

## Review status and baseline

`CIV-44` is **COMPLETE AND PUBLISHED — SENIOR REVIEW APPROVED — REMOTE
VERIFIED** at canonical HEAD
`0c6a6e88ce838266897526a74d067532163cb06f`. It was implemented from exact
canonical baseline
`50d0f73fb9b2a29fd1c3aa80395d20df862a0048` after fetching and verifying
`origin/lab/pebblelab-v1`. The working branch was
`codex/civ-44-compositional-long-distance-communication-v1`; its initial
product/test proof commit is
`6d8a3a99f3c0a80333a3e5f8c97cfd32a44e9ae4`; its initial review-candidate
HEAD was `2c6abeddf547d545148bd879b824d08d4ed3415d`.

Senior review of that candidate returned **CORRECTION REQUIRED** after finding
that CIV-41 terminal-belief compaction could legitimately remove a CIV-43 hop
still referenced by retained terminal CIV-44 history. The executable
reproduction on the uncorrected candidate reported `54 passed, 5 failed` and
also exposed destination-only accepted movement leaving CIV-44 `inTransit`.
Correction 01 composes both cases with the existing authorities and preserves
the original commits without amend or rewrite. Its product/test correction
commit is `8536ae464052d2737f1d34ffde5f08c650613c46`, and its local candidate
HEAD was `6b58f7a7d3ea3be13b51fa79e1b3a9adc64a6e15`.

Senior re-review of Correction 01 returned **CORRECTION 02 REQUIRED** because
its Mortality checkpoint bridge constructed a dictionary from unvalidated
CIV-44 transport IDs. A decodable, re-signed schema-39 checkpoint containing a
duplicate transport ID could therefore trap before the normal CIV-44 identity
guard. Correction 02 proves uniqueness before constructing that dictionary and
returns a controlled checkpoint error for duplicates. Its product/test commit
is `acb6d8399fa021afeb47d9db236ab0a5f3b687c8`; its documentation completed the
final candidate at `0c6a6e88ce838266897526a74d067532163cb06f`.

Final senior re-review approved Correction 02. Manual publication completed,
and `origin/lab/pebblelab-v1` was independently verified exactly at
`0c6a6e88ce838266897526a74d067532163cb06f`. The accepted final review archive
SHA-256 is
`570df1fd45349de684b47a0c30fcb1452137b86d5d40174146126333e6f51683`.
Gate G remains **PLANNED / UNEVALUATED**. CIV-45 is the next eligible and
authorized phase, but is **NOT STARTED**.

## Authority and transition

The V1 path is:

```text
author's accepted CIV-41 belief and CIV-42 semantic content
-> local author-to-carrier CIV-43 pickup
-> immutable transport commitment to that accepted pickup
-> existing generic civilization-activity navigation
-> accepted movement publications from the existing movement authority
-> destination arrival inside the existing local radius
-> explicit local carrier-to-destination CIV-43 handoff
-> destination-attributed CIV-41 acquisition or revision
```

`AgentSimulationSession` remains the sole civilization aggregate root. CIV-41
remains the only generic epistemic authority; CIV-42 remains the semantic,
lexical, Language Pack, and rendering authority; CIV-43 remains the authority
for each local oral hop and any deterministic distortion. Social remains the
local reachability and trust authority. Movement/navigation remains the sole
position-progression authority, Population Scale remains the migration and
residence authority, and Mortality remains the participant-lifecycle authority.
CIV-44 owns only a bounded causal transport record, coordinated terminal
reconciliation, and its reconstruction checks. It creates neither World truth
nor a competing belief, language, movement, migration, compaction, or
global-message authority.

## Content in transit

The transport does not copy `AgentLanguageSemanticContent` into a new semantic
store. Its immutable content commitment consists of the retained CIV-43 pickup
transmission and receipt identities, the CIV-41 historical source authority,
the carrier belief identity and exact pickup revision, the origin and carried
semantic digests, and the carried proposition identity. The retained CIV-43
row remains the authoritative semantic reconstruction source; CIV-44's digests
and proposition ID only bind later progression and delivery to that row.

This representation is an embodied messenger's causal commitment, not a
letter, written artifact, book, archive, or independently readable message.
It has no material or World representation and cannot be accessed as prose.
`NO_RENDERING` is a fully supported path. Deterministic compositional rendering
may accompany either local hop, but surface wording is never content,
provenance, arrival, or truth authority.

The carrier may receive a later same-content CIV-41 reaffirmation while
travelling. Delivery accepts that later current revision only when the belief
identity and proposition still match the pickup commitment, and the final
CIV-43 transmitted digest and proposition must still exactly equal the carried
digest and proposition. A carrier revision to different semantic content is
refused atomically with no destination effect. Thus mutable current belief is
not the transport payload and cannot silently rewrite what was picked up.

## Causal transport and locality

Dispatch requires a successful local CIV-43 author-to-carrier hop and a
destination outside both author and carrier direct-social range. Dispatch
creates no destination belief. The carrier receives an ordinary
`.communication` civilization-activity candidate whose target is passed to the
existing generic navigation path. CIV-44 never increments distance on a timer
or private counter: one progress row is added only after an accepted
`AgentMovementOutcome.status == .moved` publication, linked to the existing
`.movement` causal event. Blocked, stationary, missing, rejected, or never
published movement creates no progress and cannot produce arrival.

Arrival is recorded only after accepted position authority places the carrier
and destination within one Manhattan cell. An accepted carrier movement adds a
bounded journey step; an accepted destination movement may satisfy arrival but
does not pretend the carrier travelled. In both cases arrival cites an existing
`.movement` world-outcome event. A stationary outcome or attempted abstract
position rewrite is rejected and creates neither arrival nor delivery. Arrival
alone still creates no destination belief. Delivery is a separate explicit
local CIV-43 carrier-to-destination hop, and its CIV-41 result is accepted only
after the arrival event and exact content checks succeed in the same candidate
transaction.

A direct remote CIV-43 call remains refused by Social locality. A direct CIV-42
semantic-communication call may retain CIV-42/CIV-41 historical source
authority under its published semantics, but creates no CIV-44 transport and
no destination evidence, claim, understanding, belief, or revision. It cannot
mark a transport arrived or delivered. There is therefore no free remote
CIV-44 or epistemic-delivery path.

The carrier's journey changes neither settlement residence nor migration
membership. An active carrier or destination is refused admission to a
settlement migration, and restore rejects active transports whose carrier or
destination is migrating. No settlement-migration event is used as transport
progress.

## Lifecycle, bounds, persistence, and replay

Active carrier death or destination death terminates the transport as failed
inside Mortality's existing aggregate transition and never delivers. Author
death after an accepted pickup does not erase the historical source: the
carrier's live belief and retained CIV-41/CIV-43 authority keep the accepted
message reconstructible without resurrecting the author. Restart retains these
same outcomes.

When CIV-41 later evicts a departed carrier or destination belief under its own
terminal-history bound, CIV-43 remains free to remove the oral hop that depended
exclusively on that belief. Before CIV-43 publishes that removal, CIV-44
deterministically removes only terminal transports referencing the affected
hop, increments its existing eviction counter, and commits the exact remaining
set through its existing provenance boundary in the same aggregate-root
transaction. Active transports are rejected from this path rather than
compacted. Mortality is never refused to preserve CIV-44, and CIV-44 copies no
terminal belief or semantic object.

Durable state is bounded by configurable caps for retained transports, journey
steps, transport distance, and the product of retained transports and steps.
Only terminal transports compact for new admission; active authority is never
evicted. The exact retained set and counters are authenticated by a causal
provenance boundary. The boundary refreshes before causal FIFO eviction and
must be the newest retained CIV-44 boundary. A formerly authentic older
boundary cannot resurrect stale in-transit authority.

Checkpoint and replay schema advance from published predecessor 38 to 39.
Schema 38 remains byte-exactly restorable. Schema 39 stores accepted pickup and
delivery effects, bounded progress linked to accepted movement events, terminal
state, counters, and the current provenance boundary. Replay applies the
recorded CIV-43 effects and verifies final digests; it never rerolls them. A
re-signed substituted effect is rejected. Unsupported checkpoint and replay
schema 40 are refused.

Correction 01 adds no durable field and does not advance schema 39. Checkpoint
validation continues to require exact retained transport references. If a
failed terminal transport has been legitimately reconciled away, its retained
population-exit cause is accepted only from the exact causal failure payload,
a newer authentic CIV-44 boundary, and the bounded failed/evicted counters.
This preserves mortality history without accepting an orphaned CIV-41, CIV-42,
CIV-43, or CIV-44 state.

Correction 02 also adds no durable field and does not advance schema 39. Before
the Correction 01 Mortality bridge builds its retained-transport lookup, it
proves that every retained `transportID` is unique. Duplicate IDs now produce a
controlled `AgentCheckpointError.invalidBound`; no record is selected or
discarded arbitrarily. The existing CIV-44 validator, historical failure
matching, counters, boundary, replay, and reconciliation rules are unchanged.

## Focused and canonical evidence

The optimized wrapper is:

```bash
scripts/verify-pebblelab-civ44.sh
```

Its Correction 02 run passed the release build, a fresh-process schema-39
writer (`2/2`), a fresh-process reader (`5/5`), and `62/62` focused assertions.
The assertions cover direct CIV-42/CIV-43 non-delivery, no pre-arrival effect,
blocked and accepted movement, exact pickup commitment, same-content
reaffirmation, different-content refusal, source/author/carrier/destination
reconstruction, no-rendering, unchanged observation truth, restart while in
transit and after delivery, schema-38 compatibility, schema-40 refusal,
recorded-effect replay, hostile replay substitution, deterministic ordering,
terminal-only compaction, coordinated pickup/delivery terminal eviction,
causal FIFO boundary refresh, stale-boundary resurrection, journey-step
failure, accepted destination movement, rejected abstract position rewrite,
author/carrier/destination mortality, byte-exact restore of a valid Mortality
transport checkpoint, and controlled refusal of a re-signed duplicate-ID
checkpoint.

The final canonical command was:

```bash
scripts/verify-pebblelab.sh
```

The Correction 02 run passed all 35 repository steps. Its shared-runtime smoke
suite reported `4539 passed, 0 failed`. Focused CIV-43, CIV-41 Correction 01,
checkpoint/replay, and Mortality regressions passed `81/81`, `19/19`, `49/49`,
and `93/93`, respectively. Goldens were not regenerated.

## Live and visual applicability

This candidate adds deterministic PebbleAgents composition and headless proof.
The only Pebble changes keep `.communication` rejected by the existing live
physical executor and label it exhaustively in passive tracing. No PebbleCore
World mechanic, live adapter, physical executor, renderer, or visible
communication path was added or changed. The candidate therefore makes no live
physical claim, and the live/visual campaign and Visual Game Smoke Policy V5
workflow are not applicable.

## Deliberate V1 limits

V1 provides one embodied carrier and one final recipient, not relay networks,
a postal system, universal discourse engine, general concept graph, or new
pathfinder. It deliberately excludes writing, literacy, letters, books,
manuscripts, archives, libraries, culture, norms, rituals, organizations,
mandatory prose, an LLM provider, and Gate G evaluation. Those require later
separate authorization.
