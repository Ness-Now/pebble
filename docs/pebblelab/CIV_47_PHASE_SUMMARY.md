# CIV-47 — Distributed Culture, Norms and Ritual Practices V1

## Review status

`CIV-47` Senior Review Correction 01 is a **LOCAL REVIEW CANDIDATE — NOT
PUBLISHED**.

```text
Exact baseline: 70cb245e089987bc829ac138b0988eb3fc825d57
Branch: codex/civ-47-distributed-culture-norms-rituals-v1
Initial product/test commit: ae727382ceaffbf55ee1706ac3a74fe43066c6d4
Original reviewed candidate: 27806ac721e8e3570cc31f9e8cac2a001de4d4ca
Original reviewed tree: 2f24e73e6f6ef40f34d017692a84fdf9a24ba6cf
Original senior verdict: CORRECTION REQUIRED
Senior Review Correction 01 product/test commit: 45701f56169218b70f2e698dc0dea67bb1d027c0
Correction 01 senior review: NOT PERFORMED
Publication: NOT PUBLISHED
Remote verification: NOT PERFORMED
Gate G: PLANNED / UNEVALUATED / NOT ACQUIRED
```

The original candidate and review ZIP remain immutable historical
`CORRECTION REQUIRED` evidence. Correction 01 does not claim senior approval,
publication, remote verification or Gate G evaluation.

## Architecture and authority

CIV-47 extends the sole `AgentSimulationSession` aggregate with bounded,
sparse per-individual cultural state. It introduces no World, settlement,
house, organization or universal-trait culture authority.

- Each participating individual owns sparse current stances and an ordered,
  bounded causal history.
- Immutable practice descriptors represent a narrow norm or ordered ritual.
  Variations name a parent and lineage root without rewriting either.
- CIV-41 remains the sole generic epistemic authority; CIV-42 remains semantic
  and lexical authority; CIV-43 remains oral-carrier authority.
- CIV-45 writing and CIV-46 archive/retrieval remain their own material and
  retrieval authorities. Correction 01 fails their cultural exposure paths
  closed because their V1 records do not commit a cultural descriptor.
- World truth, skill/mastery, recognized rights, identity and organizational
  membership are never inferred from a cultural transition.

An exposure changes only the target's cultural state and does not adopt
automatically. Consideration derives adoption or rejection from that
individual's bounded history. Enactment requires adopted participants and
exposes local witnesses without adopting them. Continuity review can cease an
inactive or superseded practice while retaining the admitted history.

## Senior Review Correction 01

Independent review of candidate
`27806ac721e8e3570cc31f9e8cac2a001de4d4ca` returned four P1 findings and no
P0 finding. Product/test commit
`45701f56169218b70f2e698dc0dea67bb1d027c0` addresses them:

1. **Carrier/content binding.** `transmitCulturalPracticeOrally` creates a
   CIV-43 oral hop and a CIV-47 exposure atomically. The oral record carries a
   bounded opaque attachment containing the CIV-47 namespace, practice ID and
   digest of the complete immutable practice descriptor. The culture record
   retains the carrier event, commitment and exact causes. A plain oral `wood`
   proposition cannot expose a remembrance ritual; a real carrier bound to a
   different practice is also refused. CIV-45 and CIV-46 exposure variants
   fail closed until those carrier authorities expose an equivalent immutable
   content commitment.
2. **Participant locality.** Every participant whose identity differs from
   the practitioner is checked directly. Sorting remains deterministic only;
   it grants no authorization. The adversarial proof migrates lexical-smaller
   `agent_0` away from practitioner `agent_1` and obtains an exact atomic
   locality refusal.
3. **Public-input pre-bounds.** Explicit projection IDs, co-participant IDs,
   witness IDs and raw carrier strings are bounded before Set construction,
   sorting, canonicalization or hashing. Encoded schema-42 collection and
   string bounds are checked before the full-state boundary encoding.
4. **Schema-42 causal validation.** Each retained culture record is compared
   with its retained event for kind, origin, actor, subject, tick, payload and
   exact causes. A bounded sparse semantic replay independently reconstructs
   the live-selected cause relations and final stances. Missing old events are
   accepted only behind the existing authenticated compaction frontier.

The hostile suite re-signs and, where necessary, internally reattests altered
checkpoints so the semantic validator—not merely a stale outer digest—refuses
kind, payload, actor, subject, origin, causes, originator relation and carrier
commitment mismatches. A legitimately compacted state still restores exactly.

## Collective projection and boundedness

`culturalPrevalence(in:)` is a non-`Codable`, read-only projection over current
membership. It persists no settlement row and no transition accepts it as
input. Departed identities remain bounded historical culture but are neither
active agents nor current members and are excluded from settlement prevalence.

Configuration bounds individuals, stances, per-individual history, operation
receipts, use participants and witnesses. Idempotence receipts lead to one
bounded individual history. Restore replay visits unique retained cultural
operations and sparse per-individual practice rows; there is no
agents-by-practices, agents-by-agents or settlements-by-practices matrix and no
full culture-history scan per lookup.

Fidelity changes cadence, not durable cultural identity or causality. Causal
FIFO compaction refreshes a digest commitment to the bounded culture state
before a prior boundary leaves retention.

## Persistence, replay and failure semantics

Checkpoint and replay schema 42 persist individual state, histories,
idempotence receipts, carrier commitments and the causal boundary. Published
pre-CIV-47 schema 38 restores without invented culture; schema 42 restores
byte-exact; future schema 43 and schema 42 without required culture state are
refused.

Transitions execute and validate on an aggregate copy and publish only on
success. Same-operation retries are byte-idempotent. Conflicting retries,
duplicate carriers, unrelated carriers, unsupported unbound writing/archive
carriers, remote participants/witnesses and capacity overflow leave exact
pre-operation authoritative bytes. Replay reproduces exact durable state and
causal history without duplicated exposure, adoption, variation, use or
decline.

## Decisive two-settlement proof

The deterministic campaign creates main and east settlements through existing
population authority. Different local interactions propagate, vary, reject
and cease practices in main while east receives none. Derived prevalence then
differs. No settlement label or final culture state is injected, and attempted
cross-settlement propagation is atomically refused.

## Executed evidence

On Correction 01 product/test commit
`45701f56169218b70f2e698dc0dea67bb1d027c0`:

- targeted Debug campaign: **73/73 PASS**;
- `scripts/verify-pebblelab-civ47.sh` Release chain: **PASS**, including
  CIV-41 through CIV-46 and CIV-47 **73/73**;
- `scripts/verify-pebblelab.sh`: **35/35 steps, 4755/4755 assertions PASS**;
- schema-42 exact restart, replay, hostile restore and legitimate compaction
  tests passed;
- provider input, network access and `PEBBLE_REGOLD` were not used.

No GUI/live campaign was run. Correction 01 changes deterministic
`PebbleAgents` state, causal persistence/replay and headless proof only; it
does not change PebbleCore, adapters, renderer, UI or visible World behavior.
The repository gate emitted only the two pre-existing unused-variable warnings
in `WorldRenderer.swift`.

Rejected/intermediate evidence remains distinct:

- the original `27806ac…` candidate and its ZIP retain the authoritative
  `CORRECTION REQUIRED` verdict;
- the original CIV-47 founder fixture with custom identities was refused by
  canonical population authority before any cultural transition;
- Correction 01 compile attempts with invalid Swift guard/`try` syntax were
  rejected before execution;
- early locality-fixture routes with an invalid navigation radius and then a
  stalled/colliding path were rejected and replaced by a real deterministic
  migration;
- the interrupted-session pre-commit Release log completed at 73/73 but lacked
  embedded commit identity, so it is retained only as intermediate evidence;
  normative logs were replayed on the committed SHA above.

```text
Status: LOCAL REVIEW CANDIDATE / NOT PUBLISHED
Senior review approved: NO
Gate G evaluated: NO
Gate G acquired: NO
Push attempted: NO
```
