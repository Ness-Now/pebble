# Gate B — Self-Sustaining Local Society

## Candidate evaluation record

Evaluation baseline:
`1191e70afe4757955ca48f992c8517df15455761`
(`Prove specialization without fixed classes`).

Evaluation #1 remains the historical acceptance record:

```text
GATE B CANDIDATE RESULT: FAIL

Automated Integrated Acceptance: FAIL
Playable Passive Observer Slice: FAIL
Real Food-to-Survival Closure: FAIL
Gate R: ACQUIRED
Gate B canonically acquired: NO
```

Local corrective status after `GATE-B-CORR-01`, based on starting HEAD
`515ae22c871292a978bb76da3020d3959632b6ed` and pending senior publication:

```text
GATE B CANDIDATE RESULT: FAIL

Automated Integrated Acceptance: FAIL
Playable Passive Observer Slice: FAIL
Real Food-to-Survival Closure: PASS
Gate R: ACQUIRED
Gate B canonically acquired: NO
```

Local corrective status after `GATE-B-CORR-02`, based on starting HEAD
`1b7c320ec897d5ea9944d3c12e6b7c460954ce23` and pending senior review and
publication:

```text
GATE B CANDIDATE RESULT: FAIL

Automated Integrated Acceptance: NOT RERUN (5/3/2 pending)
Playable Passive Observer Slice: PASS LOCALLY
Real Food-to-Survival Closure: PASS
Livestock Reserve Closure: PASS LOCALLY
Crisis Replacement Orchestration: PASS LOCALLY
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

## Food-to-survival closure at evaluation #1

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

The graph observed by evaluation #1 was therefore:

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

Historical verdict: `B-BLOCKER-FOOD-CLOSURE` was confirmed by evaluation #1.

## GATE-B-CORR-01 local remediation

`GATE-B-CORR-01 — Real Food Consumption and Survival Convergence` is a
non-canonical corrective milestone. It does not advance the current canonical
phase and does not acquire Gate B.

The local correction adds one default-off authority mode and one narrow
adapter over existing owners:

```text
real edible ItemStack in exact actor custody
  -> PebbleCore FoodDef / actor-neutral consumption descriptor
  -> CIV-16 exact-slot debit, verification and verified rollback
  -> validated physical consumption outcome
  -> AgentSimulationSession AgentNeeds.hunger
  -> existing starvation and survival progress
```

- PebbleCore remains the food-metadata and physical-item authority. Simple V1
  agent consumption supports exact carried foods with positive nutrition,
  ordinary one-item debit, no special effects and no remainder/teleport
  behavior. Player retains the full existing food completion path.
- `AgentSimulationSession` remains the only agent survival owner. The explicit
  normalization bridge is `min(1, FoodDef.hunger / 20)` because Core uses a
  20-point hunger scale while `AgentNeeds.hunger` is a normalized deficit.
- The Pebble executor selects a deterministic bounded carried slot, checks the
  Core descriptor, prevalidates the pure outcome, exact-debits real custody,
  verifies the mutation and publishes only the validated outcome. Stale
  custody, publication failure and verification failure leave both truths
  unchanged; rollback must be verified.
- Consumption IDs are unique and bounded; retained outcomes are bounded and
  non-spendable. The abstract conservation ledger is not credited or debited.
- In physical mode, legacy `.foodRaw` consumption is rejected even when a
  large coarse balance exists. No physical item is converted to `.foodRaw`,
  and disabling the mode performs no reverse conversion.
- Checkpoint/replay schema v17 persists only the bounded Civilization state
  and validated outcomes. Real inventory remains owned by PebbleCore and is
  reconciled at the live boundary rather than serialized by PebbleAgents.

The representative matrix proves sweet berries, cod, salmon and bread metadata
plus differentiated nutrition; wheat is not directly edible. Raw chicken,
stews/soups, milk buckets, chorus fruit, golden apples and any food with
effects or non-simple completion semantics are deliberately outside the V1
agent executor and remain Core/Player-only until a later audited extension.

Local verdict: `B-BLOCKER-FOOD-CLOSURE` is `CLOSED / REMEDIATED LOCALLY`,
pending senior publication. CORR-02 subsequently added a separate physical
dependent-care path; the legacy coarse model remains compatible and isolated.

## GATE-B-CORR-02 local remediation

`GATE-B-CORR-02 — Autonomous Agent Activity Orchestration and Playable Observer
Convergence` is a non-canonical corrective milestone. It does not advance the
roadmap, acquire Gate B or start `CIV-26`.

The correction extends the existing cognition loop instead of adding a demo
scheduler. `AgentSimulationSession` deterministically selects at most one
bounded activity per actor from local needs, responsibilities, commitments and
opportunities. The normal cognitive tick still chooses the goal and action;
Pebble translates only the selected typed intent to the already-existing
agriculture, fishing, hunting, gathering and livestock executors. Verified
outcomes return to the session and the next ordinary tick chooses again.

The activity state has explicit selected/traveling/ready/completed/blocked/
stale/interrupted lifecycle, bounded candidates, active intents, recent
records and failure cooldowns. Arbitration is stable by priority band,
urgency, continuity, distance, domain and identifier. Critical survival and
dependent care preempt ordinary work. A blocked prerequisite records evidence
and enters cooldown; idle remains valid. The existing bounded route planner
and the Pebble `findPath` + `Entity.move` adapter remain the sole navigation
path.

The feature is default-off and checkpoint/replay v18 persists only stable
Civilization identities, bounded orchestration state and verified outcomes.
Schemas v1-v17 load with autonomy disabled and empty; no historical activity
is invented. World, Entity, ItemStack, runtime entity IDs and executor objects
are absent from the new durable state.

Dependent care in physical-food mode now selects a supported real food from
the caregiver's custody, uses the Core food descriptor, exact-debits the
physical slot through the existing custody gateway, publishes a monotone
causal outcome and changes only the dependent's canonical hunger. A coarse
`foodRaw` balance cannot nourish a live dependent when real food is absent.
Legacy abstract care remains available only under its explicit authority.

Planting reserve is evaluated against real feed custody before an autonomous
breeding activity is eligible; no feed can be promised twice. Work demands
are refreshed and reviewed in the normal pre-tick bridge, crisis-suspended
commitments admit a deterministic capable replacement, and only a later
verified physical outcome fulfills work. Teaching evidence is derived from a
real source success; observation alone grants no skill and the student's own
later success remains the practice authority.

The rendered passive slice maps stable AgentID hashes to existing villager
models and animation profiles, suppresses cyan debug boxes under the gate,
keeps follow off, and leaves ordinary player movement and mouse look active.
No new asset, skin, registry or physical engine was added.

## Autonomous orchestration matrix

| Domain | Autonomous in normal game | `/lab` required | Proof harness required | Chains next decision | Current trigger and disconnect |
| --- | --- | --- | --- | --- | --- |
| Agriculture | yes when autonomy and agriculture gates are enabled | activation/bootstrap only | focused proof remains | yes | Bounded plans become candidates; till, plant, harvest and storage reuse the existing executor and wait for real Core growth. |
| Fishing | yes | activation/bootstrap only | focused proof remains | yes | Local selected opportunities become cognitive activities and reuse the real bobber/custody executor. |
| Hunting | yes | activation/bootstrap only | focused proof remains | yes | Local prey evidence and real weapon custody gate the existing combat executor. |
| Wild gathering | yes | activation/bootstrap only | focused proof remains | yes | Local renewable evidence reaches canonical break/drop/custody. |
| Livestock | yes for eligible feed, product and herd tasks | activation/bootstrap only | focused proof remains | yes | Managed tasks become responsibilities; real feed reserve and existing executors remain authoritative. |
| Dependent care | yes after explicit feature activation | activation/bootstrap only | focused proof remains | yes | Needs, assignment, preemption, bounded travel and interaction are tick-driven; physical mode exact-debits caregiver food. |
| Teaching/apprenticeship | causal opportunity after real work | activation/bootstrap only | focused proof remains | yes | Demonstration evidence derives from real work; observation grants no skill and own practice remains required. |
| Work commitments/profiles | yes as activity priority/evidence | activation/bootstrap only | focused proof remains | yes | Normal review and replacement feed candidate priority; commitments never mutate the World or lock a profession. |

Under the default-off autonomy gate, first and subsequent productive decisions
are now selected by the normal `AgentSimulationSession` loop. `/lab` remains a
feature/bootstrap and proof surface, not the per-agent productive authority.

The current `/lab demo` is not a Gate B slice. It starts the base agents and
movement but does not activate or orchestrate the acquired productive domains.
Its default follow mode also reapplies player yaw/pitch; normal mouse look is
available only after follow is turned off.

Local corrective verdict: `B-BLOCKER-AUTONOMOUS-PLAYABLE-SLICE` is `CLOSED /
REMEDIATED LOCALLY`; canonical Gate B acceptance still requires the dedicated
5/3/2 campaign, composite restart, human passive review and senior review.

## Player control and visual identity

Pebble's ordinary player movement and mouse-look remain available while the
agent controller updates the same World when follow mode is off. That is a
useful coexistence boundary, but it is not proof of a living society.

`LabCoreAgentEntity` remains unregistered and non-persistent. Under the
CORR-02 gate, stable AgentID hashing selects existing farmer, fisherman,
shepherd, toolsmith, mason or ordinary villager presentation, and the existing
movement limb animation is reused. Cyan debug boxes are suppressed in that
slice. The compact overlay exposes focus, goal/action, commitment and profile;
no new model, texture, skin or animation asset was added.

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
| `dependent-care` | 53 | component pass |
| `skills` | 59 | component pass |
| `teaching` | 41 | component pass |
| `work-professions` | 29 | component pass |
| `physical-food-survival` | 50 | component pass |
| `autonomous-civilization` | 36 | component pass |
| Total | 417 | 417 passed, 0 failed per run |

These checks retain strong evidence for real Core actions, conservation inside
each transaction, causal Teaching, care, bounded histories, descriptive
specialization, deterministic replay and fault handling. They are component
proofs, not integrated Gate B acceptance. Agent-layer fixtures can present an
already verified physical outcome directly, and current live launch modes run
one scripted vertical at a time.

The physical-food component additionally proves 5,001 accepted consumptions,
64 retained recent IDs, 64 retained outcomes, rejection of an ancient
post-eviction duplicate after v17 restore, acceptance of the next monotone
operation, and byte-exact replay from that post-limit checkpoint. Its durable
identity is the canonical causal sequence; there is no lifetime 4,096-meal
ceiling.

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
| B2 Real Food-to-Survival Closure | pass locally, pending publication | Exact physical food debit reaches canonical agent hunger with shadow isolation, idempotence and rollback proof. |
| B3 Multiple Viable Subsistence Strategies | partial | Local orchestration and a three-strategy passive slice pass; the canonical multi-seed adaptation campaign is pending. |
| B4 Agriculture and Managed Surplus Continuity | partial | Autonomous executor chaining and the real cycle pass separately; multi-cycle campaign evidence is pending. |
| B5 Livestock Resource-Bounded Continuity | partial | Real reserve-gated eligibility and executor linkage pass locally; campaign closure is pending. |
| B6 Care Continuity | pass locally | Care preempts work and physical mode exact-debits caregiver food; canonical campaign evidence is pending. |
| B7 Teaching / Own-Practice Learning | partial | Real work now creates causal teaching evidence; integrated campaign observation is pending. |
| B8 Durable Work Specialization | partial | Commitments influence normal candidates and profiles remain causal/non-magical; campaign continuity is pending. |
| B9 Replacement / Crisis Resilience | partial | Normal review and deterministic capable replacement are wired; a canonical live shock campaign is pending. |
| B10 Local Information / No Ghost Stock | partial | Strong observer-local component contracts; no integrated campaign. |
| B11 Determinism / Bounds / Persistence | partial | Per-vertical bounds and byte-exact replay exist; no composite World/session reconcile-and-continue run. |
| B12 Playable Passive Observer Slice | partial | The seed-46 corrective slice passes locally with player control and reused villager identity; human review and canonical campaign remain pending. |

Additional integrated blockers found after the two primary blockers, now
remediated locally by CORR-02:

- `B-BLOCKER-LIVESTOCK-RESERVE-CLOSURE` — physical livestock feed and breeding
  are not causally gated by the real planting reserve and Civilization decision
  in the normal product path.
- `B-BLOCKER-CRISIS-REPLACEMENT-ORCHESTRATION` — physical worker, tool or
  resource loss does not autonomously drive commitment review, replacement and
  an actual replacement action.

The full composite persistence scenario and society-scale acceptance ledger
remain acceptance-infrastructure gaps for Gate B re-evaluation #2. They do not
reopen the local corrective seams or make Gate B acquired.

## Bootstrap, conservation and run metrics

The CORR-02 seed-46 live run emits
`PLAYABLE_SLICE_BOOTSTRAP_COMPLETE tick=0 agents=3 follow=off
productiveCommandsAfter=0`. The bounded bootstrap creates local proof
opportunities and starter tools, then issues no per-agent productive command.
Normal movement, camera and the ordinary cognitive clock remain live.

The run records decisions, candidates, starts, completions, blocks, switches,
completed agents/domains, retained records, evictions and longest idle streak.
Fishing, hunting and wild gathering all publish verified real outcomes in the
same World. The berry path later exact-debits real food into canonical hunger
with `foodRaw`, CampStock and coarse-ecology deltas all zero. The fixture owns
bounded setup/cleanup only; physical actions are selected by cognition.

This is local corrective evidence, not the missing canonical 5/3/2 campaign or
composite persistence acceptance. Exact final counters and capture path belong
to the retained live evidence and mission report.

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

### CORR-01 corrective visual record

The isolated corrective proof is not a passive Gate B slice. It was launched
because CORR-01 changes a real physical boundary and therefore requires its own
visual and trace evidence.

```text
Pebble process launched: YES
real rendered World captured: YES
foreground activation attempted: YES
foreground client visibly observed when environment allowed: YES
capture(s) inspected: YES
real physical food acquisition represented: YES
real food consumption context represented: YES
exact physical debit trace-proven: YES (sweet_berries 1 -> 0)
canonical hunger change trace-proven: YES (0.85 -> 0.75)
abstract food shadow credit observed: NO
final physical state coherent: YES
visual anomaly found: NO
capture paths: retained isolated physical-food-before/acquired/consumed/final PNGs
```

The four 3024×1898 frames show the real forest/water context, bounded fixture,
three expected debug embodiments, visible berry acquisition context and its
absence after consumption. No duplicate agent, duplicate item, ghost berry,
teleport or contradictory final scene was observed. The structured trace also
proves `runtimeErrors=0`, exact fixture/custody cleanup and three probes removed.

### CORR-02 corrective visual record

The `--gate-b-passive` run launches a normal rendered disposable World with
follow off and leaves player movement and mouse look available. After the
bootstrap marker it performs no productive command. Three stable agent
identities reuse villager models and existing limb animation; cyan debug boxes
are absent under the gate. The later capture and structured trace are inspected
for stacking, teleportation, land fishing, ghost items, duplicate animals,
stale overlays and camera hijack. This local slice is corrective evidence only;
it does not replace human review or the canonical Gate B campaign.

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

The evaluator refuses `PEBBLE_REGOLD`, anchors evaluation #1 and the CORR-01
starting baseline, audits both corrective source seams, creates headless
evidence only under a temporary directory, never launches a live command
scheduler and never owns gameplay state. There is no runtime `GateBState`.

## Corrective phases recommended

### 1. Real Food Consumption and Survival Convergence — remediated locally

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

### 2. Autonomous Agent Activity Orchestration and Playable Observer Convergence — remediated locally

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

Dependency order was food closure first, then autonomous orchestration. Both
corrective seams are now locally implemented; the next acceptance activity is
Gate B re-evaluation #2, not `CIV-26`.

## Product question

> Can I launch Pebble normally, enter the World, issue zero per-agent commands
> after bootstrap, walk among the inhabitants for several minutes, and watch a
> small society begin to live, work, learn, care and adapt without me?

```text
YES — locally under the default-off CORR-02 gate; canonical Gate B remains NOT ACQUIRED
```
