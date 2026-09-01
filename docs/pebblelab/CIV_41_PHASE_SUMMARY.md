# CIV-41 — Structured Knowledge and Belief Graph V1

## Verdict and baseline

`CIV-41` is implemented in its bounded V1 contract as a **local
implementation/review candidate**. It is not published and has not received
independent senior review. The exact fetched canonical baseline was:

```text
repository: Ness-Now/pebble
canonical branch: origin/lab/pebblelab-v1
baseline: 96030494c9bed8e356faae16dbd3c66dc9b4b652
candidate branch: codex/civ-41-structured-knowledge-belief-graph-v1
remote publication: NO
```

This report intentionally does not self-reference its containing commit.
`CIV-40` remains optional and unstarted. `CIV-42` remains unstarted. Gate G
remains planned; no Gate G evaluation or acquisition was performed.

## Behavioral contract

The durable model preserves these distinct layers:

```text
authoritative physical/civilization evidence
!= attributed source claim
!= individual structured understanding
!= individual current belief
```

PebbleCore remains physical truth. Pebble remains the validated observation,
execution, verification and rollback boundary. Existing civilization domains
retain their canonical facts. CIV-41 adds no global truth table and never
allows an individual belief to mutate World or civilization truth.

The V1 graph supports:

- a typed subject entity, predicate and typed value for one stable structured
  proposition;
- one stable question identity shared by incompatible proposition values;
- direct evidence bound to a validated causal event and its authority kind;
- source claims naming source, recipient, original source evidence and local
  social delivery events;
- owner-specific understandings whose basis is exactly evidence or a source
  claim;
- owner-specific current beliefs and bounded causal revision history;
- deterministic disagreement projection for different current positions on
  the same structured question.

V1 currently instantiates the graph for validated natural resource presence at
a World cell. This is deliberately smaller than a general ontology. It creates
no lexicon, utterance, narrative, tradition, culture, religion, institution,
technology, profession or skill authority.

## Reused owners and transition path

`AgentSimulationSession` remains the sole aggregate root and transition owner.
The implementation extends the existing paths instead of adding a second
cognition or communication kernel:

1. the existing accepted `AgentResourceObservation` and causal perception
   boundary grounds an `AgentSocialFact`;
2. the observer receives direct CIV-41 evidence, understanding and belief;
3. the existing local, directed, radius-bounded social message carries an
   attributed source claim to exactly one eligible recipient;
4. the recipient forms claim-based understanding and an individual belief;
5. the existing validated social-verification observation may produce new
   direct evidence and a causal revision for that recipient only.

The existing no-forwarding rule remains intact. A received claim cannot be
forwarded. There is no long-distance carrier, automatic household/family/
settlement sharing, popularity rule or social convergence rule. Observer is a
read-only projection and never appears as a source.

Every successful evidence, claim, understanding and belief transition has a
distinct typed causal-ledger event. A source claim retains the original direct
evidence identity; source death, disappearance, social-message compaction or
repetition cannot reclassify it as a direct observation.

## Persistence, replay and compatibility

Checkpoint schema advances from 35 to 36 only when a knowledge graph state has
been initialized. Schema 36 stores the bounded graph, configuration, current
beliefs, retained provenance, bounded revisions and explicit eviction counts.
Restore validates identities, graph relationships, owner/question uniqueness,
same-simulation/prior causal boundaries, exact retained causal event kinds and
payload identities, live provenance closure and every global/per-agent bound
before publication. A causal reference outside the retained suffix is accepted
only when it lies in the ledger's deterministic dropped prefix.

The immediately published schema-35 population-scale checkpoint shape still
encodes, decodes, validates, restores and re-encodes exactly. It restores with
no graph and fabricates no evidence, claim, understanding or belief.

Replay schema 36 adds the explicit knowledge-feature transition. Ordinary
knowledge acquisition and revision replay through the existing typed
`advanceTick` and social-verification operations. Replaying the same journal
from the same base reproduces exact durable bytes and record counts; restore
does not append lifecycle or cognitive transitions.

Observer schema advances from 13 to 14 when a CIV-41 graph has been
initialized. Its read-only snapshot exposes proposition/question identity,
evidence authority, claim source/recipient, understanding owner and basis,
current belief stance, revision cause and disagreement. An explicitly disabled
graph retains and exposes its durable state without accepting new transitions.
Capturing it changes no graph or causal state.

## Bounds and compaction

The live defaults bound each graph-wide propositions, evidence, claims,
understandings, beliefs and revisions collection to 4,096 rows. Per-agent
defaults are 16 evidence, claims, understandings and beliefs and 32 revisions.
Configuration hard limits prevent oversized or zero capacities.

Compaction is deterministic:

- revisions compact oldest tick then stable revision ID;
- noncurrent understandings compact oldest tick then stable identity;
- claims not required by a retained understanding compact oldest first;
- evidence not required by retained understanding, retained claim or an
  unexpired direct social fact compacts oldest first;
- unreferenced propositions compact by stable proposition ID;
- current beliefs never compact, and their complete understanding/claim/
  evidence chain is pinned;
- if current authority cannot fit, the new candidate transition fails before
  publication rather than dropping or reclassifying that authority; focused
  proof compares the entire durable session bytes before and after refusal.

All IDs and snapshot digests use deterministic SHA-256 over canonical typed
content. No dictionary order, registration order, wall clock or randomness is
an identity input. The model stores rows only for agents that actually acquire
information; it creates no agents-by-agents matrix. The durable graph is
independent of execution fidelity, so retaining a belief does not require a
LIVE embodiment.

## Decisive product proof

The focused `pebsmoke` selector starts with only agent identities, positions
and validated observation inputs. It does not deserialize or insert a final
belief. Product transitions produce all decisive state.

The scenario establishes:

- agent A directly observes wood at a cell and locally tells agent B;
- A's understanding is evidence-based while B's is claim-based and attributed
  to A's original evidence;
- remote agent E receives no graph row;
- agent C later directly observes stone at the same cell and locally tells D;
- A/B and C/D retain incompatible accepted beliefs on the same question;
- B is wrong relative to the later validated direct evidence while physical
  conservation, inventories and authoritative state remain unchanged;
- B then checks the cell through the real social-verification path, obtains
  contradictory direct evidence and revises to stone;
- A and E remain unchanged and the disagreement remains valid rather than
  being globally overwritten.

The focused harness proves schema-35 compatibility, exact replay,
registration-order invariance, forced compaction and a 24-agent configuration
in which exactly the causal pair is informed. The wrapper also launches one
process that produces a meaningful schema-36 graph through the real product
path and writes its checkpoint, then a separate process that decodes, validates,
restores and re-encodes the same bytes. Its compact machine-readable evidence
lines begin `CIV41_DECISIVE`, `CIV41_BOUNDS`, `CIV41_SCALE`, `CIV41_RESTART`,
`CIV41_REPLAY`, `CIV41_RESTART_WRITE` and `CIV41_RESTART_READ`.

## Validation contract

The focused deterministic command is:

```bash
scripts/verify-pebblelab-civ41.sh
```

The focused debug and optimized commands each pass 47/47 main assertions plus
3/3 writer and 5/5 separate-process reader assertions. Focused owning selectors
pass checkpoint/replay 49/49, Observer 20/20 and population scaling 69/69; the
schema-36 compatibility updates pass the Gate F Family and Estate selectors
27/27, 28/28 and 32/32. The canonical suite retains the existing
social-information coverage. On this local candidate the complete aggregate is
4,321/4,321 assertions and the canonical repository gate passes 35/35 steps:

```bash
scripts/verify-pebblelab.sh
```

The implementation consumes already validated observations and changes no
live physical adapter or World mutation path. Visual Game Smoke V5 therefore
does not require a manufactured rendered campaign for CIV-41. No golden was
regenerated and `PEBBLE_REGOLD` was not used.

## Explicit non-claims

- CIV-40 was not implemented.
- CIV-42 proto-language, lexicon learning and emergent vocabulary were not
  implemented.
- Oral distortion, multi-hop tradition, long-distance communication, writing,
  archives, culture, religion, institutions, diplomacy and grounded dialogue
  were not implemented.
- Knowing or believing a technique grants no skill, recipe, tool, profession,
  aptitude, development or cultural status.
- No LLM, provider, API or network dependency was added.
- Gate G was not evaluated or acquired.
- This local candidate is not a claim of senior approval or remote
  publication.
