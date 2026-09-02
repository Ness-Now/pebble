# CIV-42 — Learned Language Foundations V1

## Published status and baseline

`CIV-42` is **COMPLETE AND PUBLISHED — SENIOR REVIEW APPROVED — REMOTE
VERIFIED**. This publication does not evaluate or acquire Gate G.

```text
repository: Ness-Now/pebble
canonical ref: origin/lab/pebblelab-v1
verified canonical base: 601e3cc75e589539e47a5742c8d7848f9a3e6b59
implementation commit: 900c9adf59e8e0be76c707f6380bfdf576c03899
initial review-candidate documentation: 5ed3459241878c4b8917af77bdcc61691b6704a2
schema-sentinel correction: 595875689e645ba5bc0a057e94b6f58b9d9e0052
senior-review correction 01: 860bd703bc626556c1c2dfba65eeab35781bd48e
senior-review correction 02 / published product HEAD: c116b0780facc297dd3e0839ada505673e656189
final review archive: CIV-42-SENIOR-REVIEW-CORRECTION-02-c116b07.zip
final review archive SHA-256: 4ac1130589c2f369bce6a4fa9213edb2040be84c936ef5e2728077f95ac3751d
publication: COMPLETE — REMOTE VERIFIED
Gate G: PLANNED AND UNEVALUATED
```

Initial senior review found durable semantic-authority and lexical-provenance
blockers. Senior Review Correction 01 bound language state to bounded receipts
but remained blocked because CIV-42 could become the surviving historical
belief authority and mutually fabricated receipts could exploit dropped causal
prefixes. Senior Review Correction 02 moved historical accepted-belief
authority back into CIV-41 and anchored the bounded CIV-41 and CIV-42 proof
sets through exact retained causal boundaries. Re-signed attacks A–G passed,
the canonical 35-stage repository gate passed, independent senior re-review
approved, manual publication completed and the exact remote HEAD was verified.

## Behavioral contract

The V1 model keeps these layers distinct:

```text
CIV-41 proposition and individual belief authority
!= language-independent semantic senses and referent
!= an individual's lexical association and competence
!= optional surface realization
```

`AgentSimulationSession` remains the sole civilization aggregate root. CIV-42
adds no World access, physical mutation path, second cognitive kernel, generic
belief store or language-owned truth. A semantic communication references the
exact accepted CIV-41 proposition and speaker belief revision that authorize
it. It does not create, revise or spread a recipient belief. Lexical competence
alone cannot authorize communication of a proposition the speaker does not
believe.

The deliberately bounded semantic adapter supports the existing CIV-41
natural-resource-presence proposition for one World-cell referent. It carries a
referent-kind, predicate and value sense plus the source proposition identity.
This is not a universal concept graph, ontology, grammar engine or cultural
graph.

## Seed pack and realization

The default reference `AgentLanguagePack` is a five-entry French V1 seed for
the supported senses. Its version, provenance and license are durable data. It
is project-authored under the repository license and incorporates no external
linguistic dataset. A valid empty `und` pack proves that semantic communication
and `NO_RENDERING` do not depend on French data.

The pack is replaceable seed/prior data only. It grants no competence until an
explicit per-agent prior transition creates sparse lexical associations. It is
not cognition, physical truth, cultural truth or gameplay authority.

Deterministic provider-off realization composes an agent's known lexical forms
in stable semantic-role order. For the decisive V1 proposition it realizes:

```text
bois est présent à cellule 2,64,0
```

No provider or model dependency was added. `NO_RENDERING` stores the same
semantic reference with no text, lexical use or accidental exposure. Surface
text is validated as a deterministic projection and is never parsed back into
semantic or epistemic authority.

## Individual learning, bounds and lifecycle

Lexical competence is per agent and event-driven. The decisive learner starts
with no lexical row. A first real rendered exposure creates three `acquiring`
associations; realization still refuses missing competence. A later second
exposure crosses the configured threshold, records the newly learned senses
and enables the learner's deterministic realization. The proof does not insert
the learner's final state directly.

Live defaults bound lexical associations to 4,096 globally and 32 per agent,
and communication history to 4,096 records. Hard configuration ceilings reject
invalid capacities. Exposure counts compact at the learning threshold.
Communication history deterministically evicts oldest tick then stable
identity, with an explicit eviction count. Capacity that cannot be satisfied
fails before publication and leaves exact durable bytes unchanged. A 24-agent
proof creates rows only for the causally participating teacher and learner;
there is no implicit agent-language, agent-agent or concept matrix.

Existing finalized mortality remains the lifecycle owner. Within that existing
transaction CIV-42 removes the departed owner's current lexical competence and
increments a bounded-space retirement count. Orphaned seed and exposure
receipts are removed in the same transition. Retained bounded communications
remain historical semantic records. CIV-42 adds no death detector or parallel
lifecycle.

## Persistence, replay and causality

Checkpoint schema advances from 36 to 37 only when language state has been
initialized. Schema 37 stores the configuration, pack metadata, sparse lexical
associations, bounded communication history, compaction counters and next
stable ordinal. The senior-review corrections add bounded provenance surfaces
to that unpublished schema in place:

- CIV-41 owns a bounded historical-belief-authority row containing the exact
  canonical proposition and accepted belief revision that authorized a
  communication. CIV-42 retains only the stable CIV-41 authority identity and
  its language-specific semantic projection. Current or departed CIV-41 rows
  are cross-checked whenever retained; compaction never makes CIV-42 the sole
  durable owner asserting that a speaker held the belief;
- the complete bounded set of CIV-41 historical authority rows is committed by
  an exact retained CIV-41 boundary event. The complete bounded set of current
  CIV-42 prior-seed receipts, exposure receipts and retained communications is
  independently committed by an exact retained language boundary event;
- exact prior-seed grant receipts and rendered-exposure receipts justify every
  current association. Exposure competence cites a distinct receipt per
  counted learning exposure plus at most one latest-use receipt. Receipts are
  pruned as soon as no current association cites them.

Restore also validates bounds, canonical pack ordering, association identity
and ownership, deterministic surfaces, exact exposure identities and typed
CIV-41/CIV-42 causal events before publishing the session. Before either exact
boundary event would leave the causal window, the existing pre-eviction path
replaces it with a new exact retained boundary caused by the prior boundary.
There is no dropped-prefix fallback for either committed proof set. Thus a
re-signed checkpoint cannot manufacture a mutually consistent receipt and
competence row, or a language-owned historical belief, merely by citing an
event identity from the compacted causal prefix.

A seed receipt count cannot exceed current association count. Exposure
receipts are explicitly bounded by current associations times the configured
learning threshold plus one latest-use slot; the live maximum is therefore
causal and finite rather than an unbounded history. CIV-41 historical authority
rows are separately bounded by the configured revision limit; referenced rows
remain pinned while unreferenced rows are deterministically evictable.
Communication-history and causal-ledger compaction remain enabled and do not
make surviving current competence self-authorizing.

Published schema-36 checkpoints still decode, validate, restore and re-encode
byte-for-byte without fabricating language state. Schema-37 fresh-process
restart preserves meaningful learned history and re-encodes the exact bytes.

Replay schema 37 records explicit language activation, prior seeding and
semantic communication operations. Replaying the same journal from the same
schema-36 base twice reproduces exact durable state without duplicate lexical
or communication records. Registration-order reversal produces the same
language snapshot.

## Focused evidence

The deterministic focused wrapper is:

```bash
scripts/verify-pebblelab-civ42.sh
```

Both debug and optimized executions pass:

- fresh-process writer: 3/3 assertions;
- separate-process reader: 5/5 assertions;
- main semantic, learning, authority, bounds, replay and lifecycle proof:
  56/56 assertions.

The 56-assertion proof includes fully re-signed schema-37 attacks A through G
for:

- semantic content that no longer corresponds to its cited CIV-41
  proposition, both with retained causal bodies and after causal compaction;
- seeded competence outside the exact prior grant set;
- exposure competence for an association absent from the cited exposure;
- the same lexical fabrication after both communication-history and causal
  event-body compaction;
- a fabricated seed receipt and its matching seeded/known association injected
  together after causal compaction;
- enough fabricated exposure receipts and their matching known association
  injected together after causal and communication-history compaction;
- a fabricated communication, semantic projection and language-side authority
  reference that have no surviving CIV-41-owned historical authority.

Each hostile checkpoint recomputes its durable semantic digest and checkpoint
identity. The legitimate compacted control restores byte-exactly; each forged
variant is refused by the corresponding CIV-41 ownership or exact retained
boundary reachability invariant.

Adjacent optimized owning selectors also pass unchanged:

- CIV-41 structured knowledge: 47/47;
- CIV-41 lifecycle correction: 19/19;
- checkpoint/replay: 49/49;
- mortality/population exit: 93/93;
- Gate F schema-family compatibility: 27/27.

The final canonical `scripts/verify-pebblelab.sh` run passed all 35 stages with
4,396 assertions and exit status 0 at the published product HEAD.

The implementation changes no PebbleCore, Pebble live adapter, World mutation,
rendering or other visible boundary, so a live campaign is not applicable.

## Deliberate V1 limits

CIV-42 does not implement oral belief transmission or distortion, long-distance
carriers, writing, material texts, books, archives, distributed culture,
dialects, from-zero emergent language, a general grammar, a universal concept
graph, embeddings, an LLM provider or new physical mechanics. Those remain
outside this published V1 and, where authorized, belong to CIV-43 and later
phases.
