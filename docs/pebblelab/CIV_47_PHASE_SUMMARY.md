# CIV-47 — Distributed Culture, Norms and Ritual Practices V1

## Review status

`CIV-47` is a **LOCAL REVIEW CANDIDATE — NOT PUBLISHED**.

```text
Exact baseline: 70cb245e089987bc829ac138b0988eb3fc825d57
Branch: codex/civ-47-distributed-culture-norms-rituals-v1
Initial product/test commit: ae727382ceaffbf55ee1706ac3a74fe43066c6d4
Final product/test commit: ea9a7484252ac5c75f3880b9b3f14d70fdef06c7
Senior review: NOT PERFORMED
Publication: NOT PUBLISHED
Remote verification: NOT PERFORMED
Gate G: PLANNED / UNEVALUATED / NOT ACQUIRED
```

The candidate does not claim senior approval, publication, remote
verification or Gate G evaluation. Historical failures and corrections from
earlier phases remain unchanged.

## Architecture and authority

CIV-47 extends the sole `AgentSimulationSession` aggregate with bounded,
sparse per-individual cultural state. It introduces no World, settlement,
house, organization or universal-trait culture authority.

- Each participating individual owns a sparse set of current stances and an
  ordered causal history.
- Immutable practice descriptors represent a narrow norm pattern or an
  ordered ritual pattern. A variation names its parent and lineage root and
  never rewrites the parent.
- CIV-43 oral transmissions, CIV-45 readings and CIV-46 retrievals remain the
  carrier authorities when referenced by an exposure. Direct social use
  composes existing locality and settlement membership authority.
- CIV-41 remains the sole generic evidence, claim, understanding, belief and
  belief-revision authority. CIV-42 remains semantic and lexical authority.
- World truth, skill/mastery, recognized rights, identity and organizational
  membership are never inferred from a cultural transition.

An exposure creates or advances only the target individual's cultural stance.
It does not adopt automatically. Deterministic consideration derives adoption
or rejection from that individual's bounded exposure and competing-use
history. Enactment requires adopted participants and exposes local witnesses
without adopting them. Continuity review can cease an inactive or superseded
practice while retaining every admitted historical record.

## Collective projection and boundedness

`culturalPrevalence(in:)` is a non-`Codable`, read-only projection over current
population, household, house or explicit-individual membership. It returns
counts and visit metrics, scans no cultural history, persists no settlement
row and is accepted by no transition API. Calling it is byte-nonmutating.

Configuration bounds individuals, stances per individual, history per
individual, operation receipts, participants and witnesses. There is no
agents-by-practices, agents-by-agents or settlements-by-practices matrix.
Idempotence lookup follows a receipt to one bounded individual history rather
than scanning all cultural history. Admission fails closed at a structural
bound; it does not evict live cultural authority.

Fidelity tiers can change processing cadence, but CIV-47 state is not tiered
away. Causal FIFO compaction refreshes a digest commitment to all bounded
cultural state before its prior boundary leaves retention.

Mortality removes an agent only from active population authority. Its bounded
cultural row remains historical evidence when backed by retained or compacted
mortality identity, is excluded from current settlement prevalence, and
survives checkpoint/restart without resurrecting the agent. Social authority
cannot be disabled underneath an initialized cultural state.

## Persistence, replay and failure semantics

Checkpoint and replay schema 42 persist the individual state, histories,
operation receipts and causal boundary and add typed operations for feature
activation, origin, exposure, consideration, use, variation and continuity.
Schema 38 predecessor state restores byte-exact without invented culture;
schema 42 restores byte-exact; future schema 43 and schema 42 without its
required cultural durable state are refused.

Every cultural transition is built and validated on an aggregate copy and is
published only on success. Same-operation retries return the admitted record;
conflicting retries, duplicate carriers, cross-settlement use and capacity
overflow leave exact pre-operation durable bytes. Replay reproduces exact
durable state and causal history without duplicated adoption, exposure,
variation, use or decline.

## Decisive two-settlement proof

The deterministic campaign creates the main and east settlements through the
existing population-scale authority. One main-settlement founder originates a
structured remembrance ritual. A real CIV-43 oral hop and a witnessed local
enactment expose a second resident without adoption; deterministic
consideration then adopts it. That resident creates a causally linked ritual
variation, demonstrates it twice, and a third resident adopts and uses the
variation. The third resident rejects the root in the presence of the used
competitor, and the second resident later ceases the superseded root. A narrow
scarcity-aid norm is also originated and enacted locally.

The east settlement receives none of those interactions. Its derived
prevalence is empty, while the main projection contains the root, variation
and norm. An attempted cross-settlement witness transition is refused with an
exactly unchanged aggregate. The divergence is therefore an outcome of two
different causal histories, not a settlement label or proof-injected final
state.

## Executed evidence

On final product/test commit `ea9a7484252ac5c75f3880b9b3f14d70fdef06c7`:

- `PEBBLELAB_SMOKE_ONLY=civ-47 .build/debug/pebsmoke`: **42/42 PASS**.
- `scripts/verify-pebblelab-civ47.sh` in release: **PASS**.
- CIV-41: 3/3 writer, 5/5 reader and 47/47 focused.
- CIV-42: 3/3 writer, 5/5 reader and 56/56 focused.
- CIV-43: 1/1 writer, 3/3 reader and 81/81 focused.
- CIV-44: 2/2 writer, 5/5 reader and 62/62 focused.
- CIV-45: 105/105 focused plus its relevant Core persistence corrections.
- CIV-46: 38/38 focused.
- `scripts/verify-pebblelab.sh`: **35/35 steps, 4717/4717 assertions PASS**.
- `PEBBLE_REGOLD` was absent. Provider input and network access were not used.

No GUI/live campaign was run. CIV-47 changes only deterministic
`PebbleAgents` state, causal persistence/replay and headless proof surfaces; it
does not change PebbleCore physical rules, Pebble adapters, renderer, UI or
visible World presentation. The structural two-settlement proof is therefore
the proportionate observable evidence. The repository gate emitted only the
two pre-existing unused-variable warnings in `WorldRenderer.swift`.

Rejected intermediate runs:

- the first new test build used the wrong replay-operation argument label and
  placed `try` incorrectly; compilation was rejected before execution;
- the next fixture used noncanonical founder identifiers and was refused by
  existing population authority before any cultural transition;
- an attempted `--only` CLI selector was not a supported smoke selector; the
  accidentally unfiltered run was interrupted and supplied no accepted result;
- the first mortality-continuity fixture supplied only two founders and was
  refused by existing population authority at 32/33 assertions;
- a defensive review then found and corrected departed-agent historical
  validation, social-dependency teardown and explicit projection-input bounds;
  the final 42/42 debug and release campaigns passed.

```text
Status: LOCAL REVIEW CANDIDATE / NOT PUBLISHED
Senior review approved: NO
Gate G evaluated: NO
Gate G acquired: NO
Push attempted: NO
```
