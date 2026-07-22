# Gate B — Self-Sustaining Local Society

## Candidate evaluation record

Evaluation baseline:
`1191e70afe4757955ca48f992c8517df15455761`
(`Prove specialization without fixed classes`).

```text
GATE B CANDIDATE RESULT: FAIL

Automated Integrated Acceptance: FAIL
Playable Passive Observer Slice: FAIL
Real Food-to-Survival Closure: FAIL
Gate R: ACQUIRED
Gate B canonically acquired: NO
```

This is a fail-fast acceptance result, not a new Civilization phase and not a
product implementation. `CIV-00` through `CIV-25` remain completed in their
bounded contracts. Gate B was evaluated and is not acquired. `CIV-26` remains
planned and was not started.

## Definition and evaluation policy

The technical bar used was a bounded local society whose acquired systems
jointly maintain vital needs and responsibilities through real conserved
matter, local information, learning, care, specialization and causal
adaptation. The product bar used was a normal or quasi-normal Pebble launch in
which the player can move and look freely while several inhabitants choose and
chain real activities for several minutes with no per-agent productive command
after bootstrap.

Every B1–B12 pillar is mandatory. One hard blocker is sufficient to fail. The
evaluation therefore audited food closure and normal autonomy before any
multi-seed or live campaign. Once both failed, it ran only a repeated reduced
component matrix. It did not script a false composite society, launch a
command-driven scene as a passive slice, or add product capability to make the
candidate green.

Gate B does not require complete autarky, every tool replacement, workshops,
markets, property law, currency, large settlements, a finished observer UI or
the finished game.

## Food-to-survival closure

### Physical side

- PebbleCore `FoodDef` and `ItemDef.food` are the metadata authority in
  `Sources/PebbleCore/Items/ItemDefs.swift`.
- Sweet berries, raw chicken, cod and salmon are registered foods in
  `Sources/PebbleCore/Items/ItemRegistry.swift`. Raw chicken is edible under
  the real Core rules but carries its configured hunger-effect risk. Wheat is
  an ingredient, not a registered food; the canonical recipe turns wheat into
  bread.
- Fishing, hunting, wild gathering and agriculture create real drops and move
  exact `ItemStack` quantities into real agent custody through the existing
  Pebble executors and CIV-16 gateway.
- The Core eating completion in `Sources/PebbleCore/Systems/Interact.swift`
  calls `Player.feed(food.hunger, food.saturation)`, applies effects and calls
  `Player.consumeHeld(1)`. Its context is Player-specific.
- The CIV-16 custody gateway can exact-debit, verify and roll back a physical
  stack. That operation does not validate food metadata or mutate canonical
  agent survival.

### Civilization side

- `AgentConsumptionIntent` accepts only the generic `.foodRaw` category.
- `AgentSimulationSession.consumeFood` checks and removes one `.foodRaw` from
  `AgentResourceInventory`, then reduces its separate normalized hunger state
  by the fixed `foodNutrition` value.
- Dependent nourishment similarly debits generic inventory or
  `AgentCampStock`.
- Starvation damage and mortality consume this same Civilization hunger state,
  not a physical `ItemStack` or Player hunger/saturation.
- The CIV-16 compatibility projection from real custody is expressly
  read-only and is never written into the session. It maps wheat/hay to
  `.foodRaw` for coarse compatibility and does not make cod, salmon, chicken or
  berries spendable by survival.
- Live agriculture, wild subsistence and livestock deliberately produce zero
  `AgentCampStock` or generic inventory credit. That preserves Gate R but leaves
  the survival boundary open.

The exact current graph is therefore:

```text
real food ItemStack
  -> real custody/container
  -> no canonical agent-eating bridge

abstract foodRaw fixture/coarse ecology
  -> AgentResourceInventory or AgentCampStock
  -> AgentSimulationSession hunger
  -> starvation damage/mortality
```

It is not:

```text
real edible ItemStack
  -> exact physical debit
  -> canonical agent hunger
  -> starvation/survival
```

Verdict: `B-BLOCKER-FOOD-CLOSURE` is confirmed. A chest containing berries or
an agent carrying cod does not satisfy B2.

## Autonomous orchestration matrix

| Domain | Autonomous in normal game | `/lab` required | Proof harness required | Chains next decision | Current trigger and disconnect |
| --- | --- | --- | --- | --- | --- |
| Agriculture | no; plan only | yes | yes | no | The normal tick can create a bounded plot and expose `nextAgriculturalIntent`, but the seam explicitly does not execute farming. `/lab agriculture proof` performs the cycle. |
| Fishing | no | yes | yes | no | Proof setup selects the opportunity; `/lab ... proof fish` calls the real executor. |
| Hunting | no | yes | yes | no | Proof setup selects the opportunity; `/lab ... proof hunt` calls the real executor. |
| Wild gathering | no | yes | yes | no | Proof setup selects the opportunity; `/lab ... proof gather` calls the real executor. |
| Livestock | no | yes | yes | no | Proof commands create the herd/task sequence and call feed, breed, shear, herd and loss transitions. |
| Dependent care | partial after manual activation/bootstrap | yes | no per care action | within care only | Needs, assignment, care goal, bounded travel and interaction are tick-driven. Nourishment still uses abstract food and there is no cross-domain next choice. |
| Teaching/apprenticeship | no | yes | yes | no | The proof manually chooses mentor, apprenticeship, demonstration and later student practice. |
| Work commitments/profiles | no | yes | yes | no | `/lab refresh`, `match` and `record` drive the state; a commitment never becomes normal action input or invokes a domain executor. |

The first and next productive decisions are therefore chosen by proof commands
or the live harness, except for care and agriculture's non-mutating plan. No
normal `AgentSimulationSession` decision selects the next productive domain,
and no WorkCommitment-to-executor bridge exists.

The current `/lab demo` is not a Gate B slice. It starts the base agents and
movement but does not activate or orchestrate the acquired productive domains.
Its default follow mode also reapplies player yaw/pitch; normal mouse look is
available only after follow is turned off.

Verdict: `B-BLOCKER-AUTONOMOUS-PLAYABLE-SLICE` is confirmed.

## Player control and visual identity

Pebble's ordinary player movement and mouse-look remain available while the
agent controller updates the same World when follow mode is off. That is a
useful coexistence boundary, but it is not proof of a living society.

`LabCoreAgentEntity` is explicitly unregistered, non-persistent and not
normally rendered. With the debug-entity gate, all agents are identical cyan
boxes; the marker does not use AgentID, a name tag, a skin or a deterministic
visual variant. The overlay can expose focus, current goal/action, commitment
and profile, but current bodies are not distinguishable enough to follow one
inhabitant naturally. Existing Player/villager models, skins and animation
profiles are reuse candidates for a later corrective phase; none was connected
by this evaluation.

## Reduced component evidence

The dedicated evaluator builds `pebsmoke` once and runs these existing
selectors twice. The repeated text output must be byte-identical.

| Selector | Checks per run | Result |
| --- | ---: | --- |
| `materials` | 30 | component pass |
| `ecological-observation` | 17 | component pass |
| `agriculture` | 28 | component pass |
| `wild-subsistence` | 44 | component pass |
| `livestock` | 30 | component pass |
| `dependent-care` | 48 | component pass |
| `skills` | 59 | component pass |
| `teaching` | 41 | component pass |
| `work-professions` | 29 | component pass |
| Total | 326 | 326 passed, 0 failed per run |

These checks retain strong evidence for real Core actions, conservation inside
each transaction, causal Teaching, care, bounded histories, descriptive
specialization, deterministic replay and fault handling. They are component
proofs, not integrated Gate B acceptance. Agent-layer fixtures can present an
already verified physical outcome directly, and current live launch modes run
one scripted vertical at a time.

No short, medium or stress acceptance tier was run. No seed was rerolled. The
required 5/3/2 campaign, same-World coexistence, composite persistence boundary
and multi-strategy adaptation remain not run because the two primary hard
blockers make a genuine campaign impossible. Historical seed 46 remains
covered by existing component proofs but was not represented as a Gate B
campaign seed.

## Pillar disposition

| Pillar | Candidate status | Evidence boundary |
| --- | --- | --- |
| B1 Physical Material Truth | partial | Real custody and per-vertical zero-ghost checks exist; no society-scale conservation ledger or composite run exists. |
| B2 Real Food-to-Survival Closure | fail | Physical food and canonical agent survival are separate truths. |
| B3 Multiple Viable Subsistence Strategies | partial | Real strategies exist in separate proofs; no autonomous integrated selection/adaptation. |
| B4 Agriculture and Managed Surplus Continuity | partial | One real cycle and reserve are proved; no autonomous next cycle. |
| B5 Livestock Resource-Bounded Continuity | fail | Core feeding/breeding is real, but a real agriculture reserve and Civilization breeding decision do not gate the live chain end to end. |
| B6 Care Continuity | partial | Care can preempt work and execute after activation; nourishment uses abstract food. |
| B7 Teaching / Own-Practice Learning | partial | Causality is strong; the live chain is proof-command driven. |
| B8 Durable Work Specialization | partial | Profiles are causal, derived and non-magical; the work history is manually sequenced in live proof. |
| B9 Replacement / Crisis Resilience | fail | Direct APIs prove suspension/replacement, but no physical shock autonomously triggers review, selection and a real replacement action. |
| B10 Local Information / No Ghost Stock | partial | Strong observer-local component contracts; no integrated campaign. |
| B11 Determinism / Bounds / Persistence | partial | Per-vertical bounds and byte-exact replay exist; no composite World/session reconcile-and-continue run. |
| B12 Playable Passive Observer Slice | fail | No normal autonomous cross-domain chaining and no adequate visible agent identity. |

Additional integrated blockers found after the two primary blockers:

- `B-BLOCKER-LIVESTOCK-RESERVE-CLOSURE` — physical livestock feed and breeding
  are not causally gated by the real planting reserve and Civilization decision
  in the normal product path.
- `B-BLOCKER-CRISIS-REPLACEMENT-ORCHESTRATION` — physical worker, tool or
  resource loss does not autonomously drive commitment review, replacement and
  an actual replacement action.

The missing composite scenario and society-scale acceptance ledger are
acceptance-infrastructure gaps. They must be built only after the product can
actually close and orchestrate the chain; they are not evidence that the
isolated contracts are false.

## Bootstrap, conservation and run metrics

No `GATE_B_BOOTSTRAP_COMPLETE` or `PLAYABLE_SLICE_BOOTSTRAP_COMPLETE` marker was
emitted because no credible composite candidate was launched. Consequently:

- post-bootstrap productive injection was not performed;
- manual/debug productive triggers after bootstrap are not applicable, rather
  than falsely reported as zero;
- autonomous decision/action/switch counters were not collected;
- physical food produced/consumed/remaining and society-wide matter balances
  were not fabricated from independent component runs;
- no composite checkpoint, safe-boundary restore or reconciliation occurred;
- no passive follow timeline exists.

The current command-driven live proofs do seed bounded physical fixtures and
clean them up transactionally, but their manual sequencing disqualifies them
from B12.

## Visual evaluation record

```text
Pebble process launched: NO
real rendered World captured: NO
foreground activation attempted: NO
foreground client visibly observed when environment allowed: NO
capture(s) inspected: NO
agriculture visibly represented: NO
livestock visibly represented: NO
multiple real work domains visibly represented: NO
care/Teaching context visibly represented: NOT_APPLICABLE
stress/reallocation visually inspectable: NOT_APPLICABLE
real survival consumption visually/trace proven: NO
normal player movement available during simulation: NO (no Gate B slice launched)
normal camera control available during simulation: NO (no Gate B slice launched)
manual per-agent productive commands after bootstrap: 0 observed (no bootstrap occurred)
autonomous decisions observed: 0
autonomous completed activities observed: 0
multiple agents active without manual orchestration: NO
multiple domains active without manual orchestration: NO
one agent continuously followed: NO
follow duration: 0 minutes
followed agent chained multiple decisions/actions: NO
Teaching/care/specialization naturally observable: NO
agents visually distinguishable enough for V1 observation: NO
demo-only AI/scheduler introduced: NO
final physical state coherent: NO (no Gate B final state captured)
visual anomaly found: NO (no capture existed to inspect)
capture paths: none
```

The app was intentionally not launched after the source audit proved that all
available composite-looking live paths would be command-sequenced. Screenshots
from such a run could not change the Gate B verdict.

## Dedicated command

```bash
scripts/verify-pebblelab-gate-b.sh
```

Normal mode runs the source audit and repeated reduced component matrix, prints
the hard FAIL and exits `2`. Diagnostic mode preserves the FAIL text but exits
`0`:

```bash
scripts/verify-pebblelab-gate-b.sh --report-only
```

The evaluator refuses `PEBBLE_REGOLD`, verifies that product runtime surfaces
still match the evaluated baseline, creates evidence only under a temporary
directory, never launches a live command scheduler and never owns gameplay
state. There is no runtime `GateBState`.

## Corrective phases recommended

### 1. Real Food Consumption and Survival Convergence

Smallest causal scope:

- audit and minimally extract/reuse Core food-use semantics;
- choose and revalidate an exact edible stack from real actor/container
  custody;
- reuse `FoodDef`, including effects and the wheat-to-bread distinction;
- exact physical debit with receipt, idempotence and verified rollback;
- publish the verified result into the existing canonical agent hunger,
  progress, starvation, mortality, care, checkpoint and replay state;
- prevent any simultaneous `.foodRaw` shadow debit or credit;
- preserve coarse/dormant compatibility without treating it as live truth.

Non-scope: a second calories engine, cooking/crafting replacement, a Player
impersonation hack, economy, workshops or CIV-26.

### 2. Autonomous Agent Activity Orchestration and Playable Observer Convergence

Smallest causal scope:

- connect existing needs, local opportunities and commitments to the unique
  `AgentSimulationSession` decision loop;
- translate selected decisions into existing agriculture, wild, livestock,
  care and Teaching executors;
- schedule the next decision after verified outcome, wait or causal blockage;
- close physical seed-reserve/feed decisions and physical crisis/replacement;
- define one bounded normal/quasi-normal bootstrap and an explicit end marker;
- preserve player movement and camera control with follow opt-in;
- reuse existing renderer models/skins/animations for minimal deterministic
  AgentID identity;
- add read-only autonomy counters and only then build the true composite
  acceptance campaign.

Non-scope: a demo scheduler, second cognition kernel, new physical engines,
God Observer, major UI, economy, new profession mechanics or CIV-26.

Dependency order: food closure first, then autonomous orchestration and the
real composite acceptance rerun. The livestock reserve and crisis replacement
blockers belong inside the second causal convergence unless senior review
splits them into smaller milestones.

## Product question

> Can I launch Pebble normally, enter the World, issue zero per-agent commands
> after bootstrap, walk among the inhabitants for several minutes, and watch a
> small society begin to live, work, learn, care and adapt without me?

```text
NO
```
