# CIV-42 — Learned Language Foundations V1

## Candidate status and baseline

`CIV-42` is a **LOCAL REVIEW CANDIDATE — NOT PUBLISHED**. This document does
not mark the phase complete, rewrite published history, evaluate Gate G or
claim Gate G acquisition.

```text
repository: Ness-Now/pebble
canonical ref: origin/lab/pebblelab-v1
verified canonical base: 601e3cc75e589539e47a5742c8d7848f9a3e6b59
implementation commit: 900c9adf59e8e0be76c707f6380bfdf576c03899
candidate branch: codex/civ-42-learned-language-foundations-v1
publication: NOT ATTEMPTED
Gate G: PLANNED AND UNEVALUATED
```

The report intentionally does not self-reference its containing documentation
commit. Published CIV-41 product and review history remain unchanged.

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
increments a bounded-space retirement count. Retained bounded communications
remain historical semantic records. CIV-42 adds no death detector or parallel
lifecycle.

## Persistence, replay and causality

Checkpoint schema advances from 36 to 37 only when language state has been
initialized. Schema 37 stores the configuration, pack metadata, sparse lexical
associations, bounded communication history, compaction counters and next
stable ordinal. Restore validates bounds, canonical pack ordering, association
identity and ownership, semantic digests, deterministic surfaces, exact
exposure identities, CIV-41 source-belief events and typed CIV-42 causal
events before publishing the session.

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
  44/44 assertions.

Adjacent optimized owning selectors also pass unchanged:

- CIV-41 structured knowledge: 47/47;
- CIV-41 lifecycle correction: 19/19;
- checkpoint/replay: 49/49;
- mortality/population exit: 93/93;
- Gate F schema-family compatibility: 27/27.

The implementation changes no PebbleCore, Pebble live adapter, World mutation,
rendering or other visible boundary, so a live campaign is not applicable.

## Deliberate V1 limits

CIV-42 does not implement oral belief transmission or distortion, long-distance
carriers, writing, material texts, books, archives, distributed culture,
dialects, from-zero emergent language, a general grammar, a universal concept
graph, embeddings, an LLM provider or new physical mechanics. Those remain
outside this candidate and, where authorized, belong to CIV-43 and later
phases.
