# PS01 Increment 06 — Cohort-Safe Bounded Path-Readiness Liveness

Status: **LOCAL CANDIDATE — AWAITING SENIOR REVIEW**.

Local engineering disposition: **P0 0 / P1 0 / blocking P2 0**. This is not a
senior-review verdict, publication record or remote-verification claim.

PLAYABLE SLICE 01 remains **REQUIRED — IN PROGRESS / NOT COMPLETE**.
CIV-48 remains **NOT STARTED — IMPLEMENTATION NOT AUTHORIZED**. Gate H remains
**PLANNED**. Increment 07 is **UNSELECTED**. Renewable Physical Subsistence is
**UNRESOLVED**.

## Review position

- Repository: `Ness-Now/pebble`.
- Canonical branch: `lab/pebblelab-v1`.
- Exact canonical baseline and merge-base:
  `f075cb58e8b34b3035a2a367f1dbae7032bb8591`.
- Local branch: `codex/ps01-increment-06-path-readiness-liveness`.
- Publication: **NO**.
- Push attempted: **NO**.
- Senior review: **PENDING**.

The exact candidate commit, tree, parents, complete patch, raw evidence and
checksums are carried by the external senior-review archive generated from the
clean committed candidate.

## Problem and selected architecture

Increment 05 made passive biology coherent when a civilization candidate had
to roll back, but normal seed 14 still reached civilization tick 22 after
1,200 World ticks because 218 bounded path-readiness failures each aborted the
whole candidate. That behavior preserved physical truth but allowed one
technically indeterminate route to suppress unrelated verified cohort work.

Increment 06 keeps PebbleCore as physical path authority, Pebble as the sole
live sensor/executor/transaction owner, and `AgentSimulationSession` as the
sole civilization aggregate. It adds no pathfinder, scheduler, retry owner or
World revision authority. Instead, Pebble converts a bounded search that can
prove neither path nor absence into one typed, verified stationary result for
that actor. Other actors continue in deterministic agent-ID order and the
cohort publishes only after the existing batch validation and compensation
registration succeed.

## Path-truth contract

| Core result | Physical meaning | Actor result | Cohort publication | Cognition/navigation consequence |
| --- | --- | --- | --- | --- |
| `.path` | Core established a bounded physical route. | The next Core node is attempted through `Entity.move`; movement publishes only after exact position verification. Collision or another post-path physical refusal remains stationary and blocked. | Verified movement and unrelated verified work may publish together. | Successful movement retains existing success feedback; a verified physical refusal retains existing blocked feedback. |
| `.noPath` | Core completed the bounded search and proved no route in the search contract. | Stationary `.blocked`; no movement claim. | The proven negative may publish with unrelated verified work. | Existing blocked memory/navigation behavior remains legitimate. |
| `.nodeBudgetExhausted` | The 600-node bound ended before path or absence was proved. | Stationary `.readinessUnavailable` with the typed reason. | Publishes as a verified stationary actor result; unrelated verified work is not rolled back. | Creates no blocked memory. Direct work defers the same request; routed work consumes existing replan authority. |
| `.coverageLimited` | Search reached the boundary of current physical coverage. | Same stationary typed uncertainty. | Same cohort-safe publication. | Same technical defer/replan behavior; never `noPath`. |
| `.coverageUnavailable` | Required physical coverage was not ready. | Same stationary typed uncertainty. | Same cohort-safe publication. | Same technical defer/replan behavior; never `noPath`. |

The three unavailable classifications are technical policy facts. They do not
assert collision, obstruction, physical impossibility, success or resource
absence, and `AgentFeedbackLoop` writes no movement memory for them.

## Direct uncertainty lifecycle

A direct request gets one bounded Core search per unchanged causal identity.
The identity is:

- action name and requested `dx/dy/dz`;
- target and resource;
- the complete current `AgentGoal` value rather than only goal kind;
- the actor's physical origin, compared separately by the feedback gate; and
- a stable physical-readiness context digest, compared separately.

Action tick is deliberately excluded, so recreating the same policy action on
the next cognition tick does not manufacture a fresh request.

The context digest is derived at the existing Pebble sensor boundary from the
PebbleCore `physicalSimulationCoverage.stableDigest`, the actor's center
column, and the four cardinal neighbor columns. It includes bounded
route-relevant readiness, block, height, clearance, step and dangerous-drop
facts. It deliberately excludes World tick, day time, weather, biome and light
so ordinary time or presentation churn cannot spend another 600-node search.
It is only a retry-key input; PebbleCore remains the authority for the next
search result.

After the first unresolved search, cognition deterministically selects
`wait`, and the session preserves the typed prior outcome across that
`notRequested` publication. The deferral survives checkpoint/restart. The same
request at the same origin and same context remains deferred. A change in the
semantic request, origin, Core coverage digest or included local physical
columns makes a new bounded attempt eligible; its result is still determined
by PebbleCore and may again be unavailable or `.noPath`.

The direct bound is therefore exactly **one bounded physical search per
unchanged causal identity**. It prevents both immediate retry storms and a
technical deferral from becoming permanent false physical knowledge.

## Routed uncertainty lifecycle

Routed work uses the pre-existing navigation configuration and planner. The
default `navigationMaxReplans` is three and the default cooldown is one
navigation tick:

1. an initial route/physical request is attempted;
2. readiness uncertainty preserves the route and marks
   `physicalPathReadinessUnavailable`;
3. after the existing cooldown, navigation may consume replan 1;
4. the same mechanism may consume replans 2 and 3;
5. a further replan request becomes `replanLimitReached` and no search is
   authorized by that navigation work item.

Thus the finite default bound is **initial attempt + at most three replans =
four attempts**. Target/purpose/work lifecycle transitions use existing
navigation authority to create later eligible work. Replan count, last plan
tick, invalidation and failure are durable schema-45 state, so restart grants
no extra attempt.

## Transaction and publication

Readiness uncertainty mutates no physical probe and claims no destination.
Earlier verified movements in the same deterministic batch remain covered by
the existing compensation reservation. The batch validates every outcome,
registers compensation for the actual moved set, and only then returns
publication data. A later validation or registration failure still restores
all earlier physical mutations. An unavailable actor remains in the original
occupancy set, so later actors cannot consume a fictional vacated position.

At the session boundary, `.readinessUnavailable` is accepted only through
`applyVerifiedPhysicalMovements`, must be a zero-delta navigation step, must
match the current action/goal, origin and sensed context, and must carry the
exact typed resolution. Forged or unverified outcomes reject the whole
civilization publication atomically. Mixed-cohort checkpoint and replay are
byte exact.

## Schema 44/45 boundary

Current checkpoint and replay schema is **45**. It durably carries the typed
readiness reason, semantic request identity, physical-readiness context,
navigation failure/invalidation/replan state, and feedback decision factor.

A clean historical schema-44 checkpoint restores and checkpoints again as 44;
loading it does not migrate it. Schema 44 rejects schema-45-only readiness or
navigation vocabulary. Its first successfully validated and published
`.readinessUnavailable` result clears the runtime compatibility marker and
promotes subsequent durable state and replay to 45. Native schema-45
checkpoint/replay round trips exactly. Fresh-process evidence proves that
direct deferral and consumed routed budget survive and that continuous and
restarted continuation are byte identical.

Schema 45 inherits all strict Family and Estate validation used by schemas 26+
and 28+ respectively. Schema 46 is now the first unsupported future schema;
historical schema semantics were not weakened.

## Increment-05 fallback compatibility

Increment-05's `pathReadinessUnavailable -> complete rollback -> eligible
physiology-only publication` machinery remains present and tested. The current
movement executor no longer throws that exception for ordinary
`.nodeBudgetExhausted`, `.coverageLimited` or `.coverageUnavailable`; those
now publish stationary per-agent outcomes, and accepted natural campaigns
therefore recorded zero temporal fallbacks.

No current normal-product path-readiness condition reaches the old exception.
The typed controller catch and physiology-only publisher are retained so a
supported complete-candidate rollback at that seam still cannot lose eligible
World-time biology. Fatal integrity failures remain separate and are never
eligible for temporal fallback.

## Acceptance evidence

All timing below is optimized/release evidence. The first long seed-14 attempt
is diagnostic only: stack sampling showed repeated encoding of a growing
replay journal dominating CPU. The accepted harness records terminal
checkpoint/replay proof instead of serializing that growing journal every
tick. The diagnostic is retained in the review archive and marked **NOT
ACCEPTANCE OR PERFORMANCE EVIDENCE**.

### Focused, persistence and canonical gates

- Final focused Increment-06 gate: **906 / 906 PASS**.
- Fresh-process restart writer: **3 / 3 PASS**.
- Fresh-process restart reader: **6 / 6 PASS**.
- Final proof-maintenance canonical verifier: **35 / 35 PASS**, **4,901 /
  4,901** smoke assertions, 215.64 seconds, no regold. After the source-level
  audit added schema 45 to Gate-F Blocker 05's already-labelled 26–45 strict
  list, the required post-audit canonical rerun also passed **35 / 35** and
  **4,901 / 4,901** in 489.03 seconds; that duration includes the resulting
  optimized `PebbleAgents` rebuild.
- The first canonical run's four proof-maintenance failures are retained. Three
  still named schema 45 as unsupported future state; the fourth expected a new
  session to emit schema 44. Assertions now test unsupported schema 46 and
  native new-session schema 45, while separate proofs continue to protect
  historical schema-44 preservation.

### Seed 14 before/after

Increment 05 baseline: 1,200 World ticks, civilization tick **22**, 218
readiness failures, 218 temporal fallbacks, zero runtime/integrity errors.

Increment 06 final accepted run: 1,200 World ticks, 20 normal founders,
civilization tick **240**, 2,617 physical searches, 2,379 verified movements,
zero proven `.noPath`, 205 `.nodeBudgetExhausted`, zero `.coverageLimited`,
zero `.coverageUnavailable`, 163 mixed readiness-and-movement cohorts, maximum
five World ticks without civilization progress, maximum identical direct
unresolved attempt count one, zero temporal fallbacks, zero runtime/integrity/
fatal errors and zero catch-up drops. `agent_11`, `agent_14` and `agent_5`
encountered uncertainty; the historical `agent_11` condition recurred without
halting its peers. One physiological boundary published with hunger/fatigue
`0.05 / 0.06`.

The optimized repeat matched the semantic digest, causal digest, durable
result, all 2,617 searches, all 205 classifications, defer/replan behavior,
physiology and civilization tick after excluding elapsed wall time. Accepted
run-one harness time was 139.458 seconds (approximately 140.31 seconds external
wall time); repeat external wall time was approximately 139.02 seconds.

### Scarcity/non-fabrication

- Seed 46: civilization tick 240, 3,435 searches, 3,371 verified movements,
  zero path uncertainty, food/resource/harvest/consumption fabrication zero,
  and fallback/error/drop counts zero.
- Seed 887: civilization tick 240, 3,880 searches, 3,747 verified movements,
  zero path uncertainty, food/resource/harvest/consumption fabrication zero,
  and fallback/error/drop counts zero.

### Founder envelope

The accepted optimized controller sampler measured:

| Founders | Median | p95 | Maximum |
| ---: | ---: | ---: | ---: |
| 20 | 85.357 ms | 100.059 ms | 101.950 ms |
| 24 | 111.276 ms | 133.651 ms | 135.903 ms |
| 30 | 153.135 ms | 192.825 ms | 203.506 ms |

All samples reported maximum no-progress interval five World ticks, zero
fallbacks, errors and catch-up drops. The short plateau sampler encountered no
physical path requests; the full seed-14 campaign supplies the complementary
2,617-search cost evidence. Increment-05 medians were 83.463/108.951/147.339
ms and p95s were 99.919/129.969/187.070 ms, but only the like-for-like sampler
fields are compared. No performance equivalence and no support above 30
founders is claimed.

## Camera and real-client visual evidence

Focused Core proof retained near/far/return scheduled, block and entity
equivalence within the published Increment-03 bounded coverage contract. It is
not an arbitrary whole-World invariance claim.

The real Pebble client ran normal seed 14 with 20 founders. Native composited
captures show the scene before uncertainty, after a genuine stationary
`readinessUnavailable`, immediately after moving the camera far with follow
disabled, and later after distant rendering recovered. The later overlay shows
continued civilization progress and a zero-delta readiness result. The
authoritative trace records mixed peer movement, zero runtime errors, exact
conservation, and cleanup of all 20 probes. Camera position remained
presentation input, not readiness or cognition authority.

## Historical proof files changed

- `PebbleAgentsEcologicalObservationSmoke.swift`: new sessions now correctly
  assert native schema 45 while preserving byte-exact continuation.
- `PebbleAgentsGateFBlocker05Smoke.swift`: strict Family compatibility now
  explicitly includes schema 45; schema 46 remains unsupported.
- `PebbleAgentsGateFBlocker08Smoke.swift`: strict Estate compatibility now
  explicitly includes schema 45; schema 46 remains unsupported.
- `PebbleAgentsGateFBlocker09Smoke.swift`: the causal Estate matrix makes the
  same 28–45 strict / 46 unsupported boundary explicit.
- `PebbleIncrement05TemporalPhysiologySmoke.swift`: newly created current
  sessions expect schema 45 while continuing to prove Increment-05 temporal
  remainder, replay and rollback behavior.

No existing substantive validation was skipped or weakened, and no golden was
regenerated.

## Known limits and non-outcomes

- The physical search contract remains bounded at 600 nodes; uncertainty is
  allowed to remain common.
- Direct invalidation is bounded to the existing coverage digest and the
  center/four-cardinal local observation used for a direct step. It is not a
  global World revision or arbitrary distant-route oracle.
- No claim is made above 30 normal founders.
- This increment does not implement renewable food production, demographic
  headroom, a new observer, scheduler, path authority or any Wave-6 CIV.
- Renewable Physical Subsistence remains **UNRESOLVED**.
- Increment 07 remains **UNSELECTED**.

## Local-candidate disposition

- P0: **0**.
- P1: **0**.
- Blocking P2: **0**.
- PS01: **REQUIRED — IN PROGRESS / NOT COMPLETE**.
- CIV-48: **NOT STARTED — IMPLEMENTATION NOT AUTHORIZED**.
- Gate H: **PLANNED**.
- Increment 07: **UNSELECTED**.
- Renewable Physical Subsistence: **UNRESOLVED**.
- Push attempted: **NO**.

The candidate is ready for independent senior review; it is not published or
approved by this document.
