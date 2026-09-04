# CIV-43 — Oral Transmission and Distortion V1

## Review status and baseline

`CIV-43` is a **LOCAL REVIEW CANDIDATE — NOT PUBLISHED**. The candidate is
based exactly on published canonical HEAD
`a25167567e636939c39bac502904931323d920a7` from
`origin/lab/pebblelab-v1`. It does not change canonical program progression,
authorize CIV-44, evaluate Gate G, or acquire Gate G.

The initial local candidate is
`2ac189b9da1ece0db7ead0bd60c5ca4e9992ea54`. Senior Review Correction 01 at
`2e232b1c0cfa6455eed48ba2a6d6ccc7220a3cd2` reconciles CIV-41 terminal-belief
compaction with dependent oral history without subordinating mortality.
Senior Review Correction 02 keeps exact current oral authority after the last
hop compacts away, refuses resurrection through a stale formerly authentic
boundary, and refreshes that empty-set authority under causal FIFO pressure.

## Authority and transition

The V1 path is:

```text
speaker's accepted CIV-41 belief revision
-> CIV-41 historical belief authority
-> CIV-42 semantic communication and optional lexical exposure
-> existing direct/social locality authorization
-> deterministic faithful or distorted interpretation
-> recipient-attributed CIV-41 claim, understanding, and belief revision
```

`AgentSimulationSession` remains the sole aggregate root and transition owner.
CIV-41 remains the only generic proposition, understanding, belief, revision,
and historical epistemic authority. CIV-42 remains the semantic, lexical,
Language Pack, exposure, and rendering authority. The existing social subsystem
remains the direct/local reachability owner. CIV-43 stores only the bounded
accepted oral-hop record needed to reconstruct immediate speaker, recipient,
source belief authority, transmitted semantic content, interpreted semantic
content, locality evidence, distortion decision, and the resulting CIV-41
acquisition.

An oral source claim is a distinct CIV-41 provenance route; it does not weaken
the legacy CIV-03 no-forwarding rule. A recipient may speak later only from the
recipient's own then-current accepted CIV-41 belief. Surface text is never
parsed into authority. Lexical learning and epistemic acquisition remain
separate transitions even when one rendered interaction causes both.

## Locality and distortion

Every hop first passes the existing social owner's actor-neutral direct
communication checks: both participants must be current, distinct and
non-migrating; the recipient must be socially available and free of a material
transaction; recipient-to-speaker trust must meet the configured threshold;
and Manhattan distance must be within the configured communication radius.
CIV-43 adds no message bus, carrier, courier, writing, or long-distance path.

After locality is authorized, distance `0...maximumFaithfulDistance` is
faithful. A greater distance still within the social radius triggers the V1
distortion rule. The rule supports only CIV-42's existing bounded
resource-presence values `{absent, wood, stone}`, removes the source value from
the candidates, and selects an alternative from SHA-256 of:

```text
rule version, simulation ID, session seed, tick,
speaker, recipient, source proposition, source semantic digest,
distance, authorized radius, faithful-distance threshold
```

The caller supplies no interpreted value. Identical authoritative inputs yield
the same effect; different legitimate inputs exercise different supported
results. The accepted effect and decision digest are durable replay input.
Replay verifies the recorded effect against the canonical rule and applies it;
it never rerolls. A distorted proposition is only a claim and individual
belief. It changes neither direct CIV-41 observation evidence nor World truth.

## Decisive chain

The focused runtime starts from validated natural-resource observations. Agent
`agent_0` has direct CIV-41 authority for wood at one cell. A distance-one oral
hop to `agent_1` is faithful and creates an attributed CIV-41 acquisition.
`agent_1` then speaks from that new current belief to `agent_2` at distance two,
still inside the social radius. That hop deterministically changes the semantic
proposition and produces a real CIV-41 revision for `agent_2`, whose prior
direct evidence remains unchanged. The second claim names `agent_1`, never
`agent_0`, as its immediate source while upstream authority remains
reconstructible.

## Atomicity, lifecycle, and bounds

The complete hop runs on an `AgentSimulationSession` candidate. CIV-42
communication/exposure, the oral receipt, the CIV-41 claim/understanding/belief
revision, compaction, and all causal records publish together only after every
domain validates. Unknown, dead, self, migrating, unavailable, non-local,
unsupported, unauthoritative, uninitialized, or capacity-refused operations
leave the exact durable digest unchanged. Initialized oral state also prevents
removal of its social, CIV-41, or CIV-42 dependencies.

Live oral history is sparse and capped at 2,048 records, below CIV-42's 4,096
communication cap to preserve one staging slot. Compaction removes the oldest
stable unpinned hop and then retires its superseded CIV-41 claim,
understanding, and revision. A hop required by a current or departed CIV-41
belief is pinned. If all candidates are pinned, the entire prospective
cross-domain transition is refused atomically.

Finalized mortality remains the sole lifecycle owner. A dead participant
cannot send or receive a new hop. CIV-41 moves the departed current belief into
its existing immutable terminal representation, CIV-42 removes current lexical
competence, and CIV-43 may retain the bounded historical hop. Restore validates
that terminal CIV-41 route without recreating a live claim, understanding,
belief, lexical row, or agent. If a later finalized death makes CIV-41 evict
that terminal belief under its own bound, the same aggregate-root transaction
deterministically evicts the dependent oral hop before final cross-domain
validation. CIV-43 copies no terminal belief, and oral history never blocks a
legitimate death merely to preserve reconstruction.

## Schema, replay, and retained authority

Durable oral state advances checkpoint and replay schema to 38. Published
schema 37 retains its exact meaning and byte-exact compatibility. Schema 38
stores configuration, accepted hops, stable ordinal, eviction count, and one
exact oral provenance boundary. Schema 39 is refused.

The boundary digest commits the complete retained oral set and eviction count.
Its exact causal boundary event must remain in the retained ledger suffix.
Before that event would leave the FIFO suffix, a replacement event commits the
same exact set and causally references the previous boundary. Restore
authenticates this independent boundary before cross-domain relationships and
requires it to be the newest retained CIV-43 boundary. An oral domain that has
never carried a hop remains boundary-free. Once oral history exists, legitimate
compaction to zero retained hops publishes an exact empty-set boundary whose
digest also commits the eviction count. The empty boundary causally supersedes
the prior non-empty boundary and is itself refreshed before FIFO eviction.
Restore then checks every retained record against CIV-41 historical authority
and recipient acquisition, CIV-42 communication and semantics, locality
evidence, deterministic distortion, typed causal events, and the record
provenance digest. A dropped-prefix event ID alone is never accepted as oral
proof.

The focused hostile compacted-state proof leaves every authentic oral row and
dependent route unchanged, adds a logically separate forged oral row plus its
own CIV-41 claim, understanding, and revision, recomputes record and oral-set
digests, durable semantic digest, and checkpoint identity, and uses plausible
authority from the dropped causal prefix. Restore rejects it specifically
because the authentic retained boundary event commits the real set. A
legitimate compacted control drops 47 causal events,
retains two of two bounded hops after one oral eviction, restarts byte-exactly,
and permits a living recipient to retransmit its current CIV-41 belief.

A separate terminal-pressure control retains one oral hop while its recipient's
two terminal beliefs remain within CIV-41's capacity. The pressure trajectory
then finalizes another epistemically relevant death, reaches three retained
terminal beliefs after one real terminal eviction, removes the evicted oral
route, increments CIV-43 oral eviction accounting once, keeps mortality
successful, publishes an exact empty-set boundary, drops eight causal events,
restarts byte-exactly, replays without recreating removed history, and repeats
with identical domain and checkpoint digests. A re-signed resurrection attack
then restores the old legitimate terminal belief, its legitimate oral hop, and
its still-exact former boundary while keeping terminal bounds valid. Restore
rejects that otherwise coherent historical graph because the newer retained
empty-set boundary makes the formerly authentic boundary stale. A further
long-running control drops 102 causal events and refreshes the empty boundary
with a causal link to its predecessor.

## Focused evidence

The optimized wrapper is:

```bash
scripts/verify-pebblelab-civ43.sh
```

Its focused proof contains 81 assertions covering faithful acquisition,
immediate-speaker attribution, genuine CIV-41 acquisition and revision, the
`agent_0 -> agent_1 -> agent_2` chain, deterministic distortion variation,
lexical/epistemic separation, unchanged authoritative evidence, order
independence, schema-38 restart, recorded-effect replay, no-reroll tampering,
future-schema refusal, re-signed checkpoint attacks, atomic refusals, real
bounded compaction, the forged dropped-prefix attack, valid post-compaction
retransmission, mortality without cognitive resurrection, coordinated terminal
belief/oral compaction, stale authentic-boundary resurrection refusal,
empty-set boundary refresh, and deterministic multi-death replay.
Separate-process schema-38 writer and reader checks are part of the wrapper.

The implementation changes only deterministic PebbleAgents composition and
headless evidence. It changes no Pebble live adapter, PebbleCore World mechanic,
physical communication behavior, renderer, or visible game path; a live/visual
campaign is not applicable.

## Deliberate V1 limits

CIV-43 supports only the existing CIV-42 resource-presence semantic adapter
and one deterministic distance-conditioned distortion policy. It does not add
compositional discourse, carriers, couriers, relays, writing, literacy, books,
archives, traditions, cultures, dialects, a general grammar, a universal
ontology, organizations, religion, diplomacy, player dialogue, an LLM,
embeddings, or new World mechanics. Those remain out of scope or belong to
later separately authorized phases. Gate G remains **PLANNED / UNEVALUATED**.
