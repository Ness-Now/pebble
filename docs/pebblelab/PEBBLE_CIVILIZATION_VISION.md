# Pebble Civilization — Vision V4

## Role

This is the durable product vision for Pebble Civilization. It defines the
destination and permanent invariants. It does not define the current Git HEAD,
phase status or next task; those belong to `CURRENT_STATE.md`, the roadmap and
the manifest.

## Product purpose

Pebble Civilization aims to create a small autonomous world of alternative
medieval civilization inside Pebble: a world that can live for generations,
produce unplanned but causally explainable histories, and remain meaningful
whether the player watches, intervenes or leaves.

The target experience is not merely intelligent NPCs, an automated village or
LLM-generated dialogue. The player should be able to return after decades or
centuries of simulated time and discover descendants, migrations, debts,
customs, lost techniques, institutions, conflicts and stories that follow from
events which actually occurred.

The final success criterion is:

> An inhabitant can tell a credible story because the people, material events,
> transmission and consequences behind that story are reconstructible from
> the world’s durable history.

## Simulate causes, not outcomes

The simulation provides constraints, capabilities and consequences. It does
not directly create a kingdom, guild, religion, war or culture because a
threshold was reached.

Different material and social histories may produce:

- clans, communes, guild cities, merchant republics or seigniories;
- settled agriculture, fishing communities, pastoralism, trade or migration;
- cooperation, inequality, schism, collapse or extinction.

No social form is mandatory. Multiple strategies must remain viable, and
failure is an honest possible result.

## Permanent simulation principles

- Information is local, incomplete, delayed, fallible and provenance-bearing.
- There is no collective omniscience or free long-distance communication.
- Material transitions conserve real things.
- Decisions have physical, social and historical consequences.
- Agents may wait, fail, misunderstand, forget, disagree and act
  sub-optimally.
- Deterministic inputs produce deterministic authoritative transitions.
- State and searches are bounded, or have explicit persistence and compaction
  policies.
- Experimental behavior remains gated and default-off until acquired.
- A proof must never inject the outcome it claims to demonstrate.

## Authority boundaries

```text
PebbleCore
= World, blocks, items, entities, physical rules and World persistence

Pebble
= live sensors, adapters, executors, verification and rollback

PebbleAgents
= deterministic cognition, society and civilization

AgentSimulationSession
= sole civilization aggregate root and transition owner

PebbleLab
= deterministic scenarios, reports, long-runs and evaluation

pebsmoke
= invariants, regressions and fault injection
```

`PebbleAgents` never mutates or reads a live `World` directly. Physical
observations and outcomes cross explicit Pebble boundaries. Physical truth
wins over projections. New physical needs reuse Pebble first, then use the
smallest actor-neutral primitive or adapter that preserves ownership.

No second farming, crafting, inventory, combat, animal, redstone, rail,
World-persistence or general physical-pathfinding engine belongs in the
civilization layer.

## Individuals and generations

Inhabitants are limited individuals with needs, aptitudes, development,
relationships, responsibilities, memories and imperfect knowledge. Across a
life they may depend on caregivers, learn, practice, specialize, change roles,
form or leave households, reproduce, age, die and transmit material and
informational legacies.

These concepts remain distinct:

```text
genotype
!= development
!= phenotype
!= education
!= knowledge
!= practical skill
!= culture
!= profession
!= social status
```

No inherited profession, belief, loyalty or skill may be disguised as biology.
Practice, tools, time, teaching and outcomes create mastery. Childhood, care
and environment influence an adult without predetermining one.

## Subsistence and material economy

Survival emerges from competing needs and obligations rather than one global
utility score. Communities may combine gathering, fishing, hunting,
agriculture, livestock, trade, migration, tribute or theft.

Every material domain must reconcile an equation equivalent to:

```text
produced or extracted
= carried
+ contained
+ deposited
+ in transit
+ escrowed
+ built or installed
+ consumed
+ decayed or destroyed
+ explicitly accounted loss
```

Possession, physical custody, recognized ownership, claims and rights of use
are separate. A stolen object still exists. Markets do not create goods.
Buildings require materials. Livestock and books can be physically lost.

Economic development may pass through barter, obligations, contracts,
physical markets and local price memory. Currency is optional: a society may
never adopt it, may use a commodity or may build a local unit of account.
There is no globally omniscient price.

## Knowledge, language and culture

World truth is not the same as what an agent believes or transmits:

```text
WorldTruth
!= SourceClaim
!= AgentUnderstanding
!= AgentBelief
!= SharedTradition
!= Narrative
!= Utterance
```

The generic epistemic authority established by CIV-41 remains the sole generic
owner of the epistemic state it already owns: evidence, attributed source
claims, individual understandings, beliefs, belief revisions and their related
historical epistemic records. It does not own domain capability, recognized
rights or physical truth:

```text
belief that a technique exists
!= practical skill or mastery

belief that someone owns an object
!= recognized ownership
```

Specialized authorities continue to own techniques, skills, capabilities,
rights and World facts. Later phases must compose with CIV-41 rather than add a
second generic belief or knowledge graph.

Knowledge can be observed, taught, practiced, distorted, forgotten, hidden,
stolen, written or rediscovered. Theory never grants practical mastery. These
boundaries also remain distinct:

```text
semantic sense or referent
!= proposition
!= belief
!= lexical form

semantic communication
!= surface realization
```

A universal concept graph does not follow from these distinctions.

A communication may be causally and semantically complete without prose. When
surface realization is useful, all of these paths remain legitimate:

```text
NO_RENDERING
deterministic or compositional surface realization
optional LLM-assisted realization or interpretation
```

Deterministic or compositional realization is a normal path even when an LLM
is available. No mandatory intermediate type, template engine, grammar or
catalogue follows from this contract.

The standard initial language path uses language-independent semantic
foundations and a seeded Language Pack, with French as the default/reference
seed. Shared linguistic seed/prior data composes with sparse individual
lexical state, exposure, learning and historical evolution. French is neither
cognition nor epistemic, World or gameplay authority, and it is not a
mandatory architecture dependency. Other seeded languages, mixed populations
and a fully emergent from-zero experimental path remain possible; the latter
is optional rather than a gate prerequisite.

Historical evolution may produce proper names, toponyms, nicknames, slang,
jargon, sociolects, political, religious or technical vocabulary, semantic
drift, borrowings and regional usage. These examples do not mandate a separate
engine or authority for each category.

External linguistic or semantic resources are versioned, provenance-bearing,
licensed and replaceable seeds/priors. Their redistribution must be reviewed
and their use must remain reproducible offline. Such a prior is not a Pebble
World fact, physical affordance, Minecraft/Pebble gameplay mechanic, cultural
meaning or personal association. No external dataset becomes authoritative
merely by being imported.

Long-distance information requires a physical or social carrier. Oral
transmission preserves speaker attribution into the recipient's CIV-41
acquisition or revision; wording never replaces epistemic provenance. A
written artifact is a persistent material information carrier, but its content
is not World truth. It may be false, incomplete, obsolete, propagandistic or
contradictory. Books and archives have authorship, copies, location and
custody; loss can remove durable access without rewriting the underlying
history. Summaries, indexes and other derived projections are never silent
replacements for that history.

Culture is distributed across individuals, interactions, artifacts,
organizations or institutions, and history. Collective trends and prevalence
are derived projections rather than a universal cultural authority. Exposure,
adoption or rejection, use, transmission, variation, competition and decline
may share generic mechanisms when useful without creating a central culture
brain, universal cultural graph or universal trait authority.

Stable entity identity is separate from a socially used label. A self-name,
nickname, hostile label, administrative label and historical name may coexist
without replacing technical identity, organizational authority or real
membership.

Language, culture and social relations remain sparse, bounded, causal and
event-driven; they never imply an all-pairs matrix. `LIVE`, `NEAR` and
`DORMANT` fidelity changes processing cadence and cost, not identity or durable
relevant state.

## Families, organizations and institutions

Biological kinship, affection, union, household, lineage and house are
different relations. Belonging does not imply loyalty.

Organizations use general mechanisms for membership, roles, assets,
obligations, exit, exclusion, split, merge and dissolution. Guilds, councils,
cults, armies and polities arise from histories and needs rather than separate
magic constructors.

Territory, control, ownership, use rights and claims may overlap. Governance,
law, religion, diplomacy and conflict must operate through imperfect
information, material power, obligations and enforceable actions. Political or
religious labels remain descriptive outputs, never causes by themselves.

War is possible but costly in people, food, tools, production, knowledge and
trust. Peace can create real value through safety, trade, learning and shared
infrastructure.

## Technology

Technology is situated knowledge plus material capability. Techniques may be
discovered, practiced, copied, guarded, lost and rediscovered. Production
always uses real Pebble recipes, tools and machines.

Rails, minecarts and redstone are physical properties of this world. Their
infrastructure costs material, expertise and maintenance; it can fail and
disappear. There is no global technology tree that unlocks automatically.

## Player and observation

The player should be able to inspect individuals, relationships, claims,
households, organizations and causal timelines without the UI becoming a
second authority.

As an observer, the player may pause and accelerate time. As an interventionist
god, the player may cause real physical or informational events whose meaning
inhabitants interpret for themselves. As an incarnated actor, the player
obeys ordinary physical constraints and can be injured or die. Omnipotence and
incarnation are separate modes.

## Optional and subordinate LLM

The civilization must remain viable with LLM support disabled.

An optional provider may interpret, verbalize, summarize, negotiate or propose
structured content:

```text
authoritative structured state
-> bounded context
-> optional provider
-> structured proposal
-> deterministic validation
```

Knowledge authorization occurs before retrieval or inference; unavailable
knowledge is not globally retrieved and filtered afterward. An LLM never owns
perception, transactions, cognitive state, material truth or the World and has
no direct authoritative mutation channel. Pebble validates structured
proposals against applicable identifiers, revisions, authorization, rights,
resources, physical feasibility and domain rules.

Providers are replaceable, gated and non-authoritative. When nondeterministic
external inference produces an accepted persistent effect, Pebble captures
that effect and its causal input in replayable form. Historical replay reuses
that capture and never reruns the inference. Provider-off correctness remains
required, and no particular model, runtime, quantization, embedding, vector
database, context size, prompt or hardware is part of the durable architecture.
Natural language is a window onto a coherent history, not a substitute for one.

## Non-goals

Pebble Civilization must not become:

- a scripted village or predetermined feudal progression;
- an LLM facade over a shallow world;
- a second implementation of Minecraft inside `PebbleAgents`;
- an invisible spreadsheet that contradicts the detailed World;
- an omniscient society;
- a world guaranteed to prosper;
- an infinitely detailed simulation everywhere;
- a proof harness that creates the success it measures.

Coarse fidelity, derived projections, fixtures and simplified V1 verticals are
valid when they preserve identity, causality, conservation and reconciliation.

## Final destination

The target is a persistent, multi-generational medieval world in which people
survive, learn, work, exchange, form families and organizations, inherit,
write, believe, negotiate, fight, innovate and die without a prescribed social
outcome. The player can understand why events happened, intervene, leave, and
return generations later to consequences still present in people, objects,
institutions and memories.
