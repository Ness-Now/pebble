# CIV-41 — Structured Knowledge and Belief Graph V1

## Published verdict and baseline

`CIV-41` is **COMPLETE AND PUBLISHED — SENIOR REVIEW APPROVED — REMOTE
VERIFIED** in its bounded V1 contract at canonical product HEAD
`87190af6d7b51b57d600d6f39da4ccda71e3f162`. Independent senior review found
a departed-inhabitant lifecycle blocker in original candidate
`1ce9506824775c1b59eaf5c358f0e8d4edd4eab7`; Senior Review Correction 01 fixed
that blocker without rewriting the reviewed commit. Independent re-review
passed, manual fast-forward publication completed and the exact remote is
verified. The exact implementation baseline was:

```text
repository: Ness-Now/pebble
canonical branch: origin/lab/pebblelab-v1
baseline: 96030494c9bed8e356faae16dbd3c66dc9b4b652
original candidate branch: codex/civ-41-structured-knowledge-belief-graph-v1
original reviewed candidate: 1ce9506824775c1b59eaf5c358f0e8d4edd4eab7
Senior Review Correction 01 / published product HEAD: 87190af6d7b51b57d600d6f39da4ccda71e3f162
senior review verdict after Correction 01: PASS
remote publication: VERIFIED
```

This report intentionally does not self-reference its containing commit.
`CIV-40` remains optional and unstarted. `CIV-42 — Learned Proto-Language V1`
remains unstarted and is the next eligible required phase. Gate G remains
planned; no Gate G evaluation or acquisition was performed.

## Review and publication history

The historical sequence is preserved explicitly:

1. initial CIV-41 candidate `1ce9506824775c1b59eaf5c358f0e8d4edd4eab7`;
2. independent senior review found the departed-cognition lifecycle blocker;
3. Senior Review Correction 01 produced
   `87190af6d7b51b57d600d6f39da4ccda71e3f162`;
4. independent re-review passed;
5. manual fast-forward publication completed;
6. the exact canonical remote was independently verified.

The final candidate review package identities reported to senior review were:

```text
CIV-41-CORRECTION-01-87190af6.zip
reported SHA-256: 0a74f49edc1814b78999f0649b314dd211fb5e141b25a6f66d64f3b811db488c
CIV-41-CORRECTION-01-87190af6-REVIEW_HANDOFF.txt
reported SHA-256: 98d868c11f3c7e2ca7af1881590b12d3ec20ea15effdffe199fae0f0dbb66871
```

Independent senior review fully inspected the plain UTF-8 handoff, including
the complete canonical-to-final Git patch and raw validation outputs. The
binary transport SHA-256 values above are package identities as reported; the
review runtime could not materialize the binary archive and did not
independently recompute those values.

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
- immutable, separately bounded terminal belief evidence for departed owners;
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

Senior Review Correction 01 composes this path with the existing mortality
authority. Only a finalized `agentDeathFinalized` transition terminalizes
cognition. It removes the departed owner from current beliefs, understandings,
recipient claims and revisions, then records a self-contained final account of
each current belief. That account preserves its original structured
proposition, stance, understanding, evidence-or-claim basis and finalized-death
boundary without retaining those live graph rows. Mortality remains the sole
death detector and population-exit owner; CIV-41 adds no lifecycle engine.

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
beliefs, retained provenance, bounded revisions, departed-belief history and
explicit eviction counts.
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

Senior Review Correction 01 does not advance the schema again. The reviewed
schema-36 candidate had not been published, and the new optional history fields
decode its pre-correction shape as empty without fabricating terminal evidence.
A post-death schema-36 checkpoint retains terminal history, dead-source claim
attribution and the absence of dead-owner current cognition across exact
fresh-process re-encoding.

Observer schema advances from 13 to 14 when a CIV-41 graph has been
initialized. Its read-only snapshot exposes proposition/question identity,
evidence authority, claim source/recipient, understanding owner and basis,
current belief stance, revision cause, disagreement, terminal belief evidence
and terminal-history eviction count. An explicitly disabled graph retains and
exposes its durable state without accepting new transitions. Capturing it
changes no graph or causal state.

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
- current beliefs never compact while their owner remains active, and their
  complete understanding/claim/evidence chain is pinned;
- finalized death removes that current authority and converts each final belief
  to one self-contained terminal record; terminal records pin no live graph
  rows;
- terminal records compact oldest finalized-death tick, then stable death and
  belief identity, to at most the configured global belief bound;
- a living recipient's attributed claim may retain a dead source's original
  evidence, but the source identity and evidence authority remain unchanged;
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

Senior Review Correction 01 adds a second focused product scenario. One
directly informed source and one claim-informed recipient each die through the
existing mortality path in separate decisive cases. The proof establishes that
dead-owner current cognition is absent, terminal direct evidence remains
direct only for its historical owner, terminal hearsay remains attributed
hearsay, a living recipient's claim survives its source's death without
promotion, and unrelated living/remote beliefs do not change. When that last
recipient later dies through the same mortality path, the now-unneeded live
source evidence is released while both self-contained terminal accounts remain
correctly attributed. The scenario also proves
exact schema-36 fresh-process restart, repeatable exact-once mortality replay,
read-only Observer 14 projection and 17 real reproduction/knowledge/death
cycles against a 16-row terminal-history bound. The seventeenth terminal row
evicts deterministically while a living founder still acquires a new current
belief; reversing founder registration produces the same knowledge and
mortality snapshots. Its evidence lines begin `CIV41_CORRECTION_DEATH`,
`CIV41_CORRECTION_REPLAY`, `CIV41_CORRECTION_CHURN`,
`CIV41_CORRECTION_RESTART_WRITE` and `CIV41_CORRECTION_RESTART_READ`.

## Validation contract

The focused deterministic command is:

```bash
scripts/verify-pebblelab-civ41.sh
```

Senior Review Correction 01 has its own debug/optimized and two-process
restart wrapper:

```bash
scripts/verify-pebblelab-civ41-correction-01.sh
```

The focused debug and optimized commands each pass 47/47 main assertions plus
3/3 writer and 5/5 separate-process reader assertions. Focused owning selectors
for Senior Review Correction 01 pass 19/19 main assertions plus 3/3 writer and
4/4 separate-process reader assertions in both debug and optimized builds.
Focused owning selectors pass mortality 93/93, checkpoint/replay 49/49,
Observer 20/20 and CIV-39 69/69. Applicable Gate F selectors pass
dynamic fidelity 29/29, Family 27/27, Estate validation 28/28, Estate/Kinship
causality 32/32, terminal-migration admission 20/20 and terminal-household
admission 27/27. The canonical suite retains the existing social-information
coverage. On the published product line the complete aggregate is 4,340/4,340
assertions and the canonical repository gate passes 35/35 steps:

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
- CIV-41 publication does not start CIV-42 or authorize Gate G evaluation.
