# Gate B — Self-Sustaining Local Society

## Re-evaluation #4 — final candidate result

Acceptance baseline:
`ad9322761b2ffa16acad98ac6bafb18cf5317ad2`
(`Prove transactional work continuity past Gate B tick four`). The
HEAD-bound acceptance harness was committed as
`5a0abf17e3b977d96594d34d3eac626a2edb56c0`
(`Execute Gate B re-evaluation four acceptance`).

```text
GATE B RE-EVALUATION #4
CANDIDATE RESULT: FAIL

Gate R: ACQUIRED
Gate B canonically acquired: NO
CIV-26 started: NO
```

All ten fixed seeds were attempted without reroll. Movement was enabled after
bootstrap for every run; no distance-from-home bypass, post-bootstrap
productive command, teleport, reset or system disable was used. The final
source audit nevertheless found a separate hard acceptance-harness failure:
the fixture selects a `plannerID` and two livestock responsible agent IDs,
distributes tools/feed according to those identities, creates the agricultural
plan, establishes a herd with those responsible agents and queues their feed
tasks. Dynamic distance-based selection does not make this role-neutral.
Although the fixture grants no profession, skill history, apprenticeship,
trust, reputation or success, it violates the explicit “bootstrap must not
assign society roles” contract:

```text
B-BLOCKER-ACCEPTANCE-BOOTSTRAP-ROLE-ASSIGNMENT
classification: ACCEPTANCE HARNESS BUG
```

The campaign therefore provides diagnostic evidence but cannot receive
B1–B12 acceptance credit. Independently, every seed encountered the same
product integration failure after 507 or 508 successful cognitive ticks:

```text
B-BLOCKER-MOVEMENT-HOME-BOUNDARY
classification: INTEGRATION BUG
goal: civilizationActivity
action: approach_activity
accepted home boundary: 8
failed physical distance: 9
movement: PebbleCore path plus Entity.move
publication: refused and rolled back
```

| Tier | Seed | Required ticks | Reached | Failure World tick | Result |
| --- | ---: | ---: | ---: | ---: | --- |
| short | 46 | 800 | 509 | 272 | FAIL |
| short | 71 | 800 | 509 | 272 | FAIL |
| short | 113 | 800 | 509 | 262 | FAIL |
| short | 197 | 800 | 509 | 272 | FAIL |
| short | 337 | 800 | 509 | 276 | FAIL |
| medium | 509 | 4,800 | 509 | 266 | FAIL |
| medium | 887 | 4,800 | 508 | 262 | FAIL |
| medium | 1597 | 4,800 | 508 | 267 | FAIL |
| stress | 2593 | 6,400 | 508 | 267 | FAIL |
| stress | 4099 | 6,400 | 509 | 273 | FAIL |

Before the failure, every run retained three living agents, zero eligible-idle
violations and zero abstract camp-stock or generic-resource productive credit.
The runs demonstrated one real till, two real livestock feeds, one fishing
success, six to eight real gathers, seven real physical-food consumptions and
seven cross-family switches. They did not establish a complete agriculture
cycle, livestock product/breeding continuity, dependent-care outcome, guided
own-practice Teaching closure, crisis response or any required horizon.

The seed-509 repeat reproduced the same actor, transition, distance and
cognitive failure tick, but its final semantic digest differed
(`2a31be…` versus `a77ea9…`; World tick 266 versus 268). B11 therefore does
not receive deterministic credit. Seed 887 failed at tick 508 before the
2,400-tick checkpoint boundary. Both stress seeds failed before the
3,200-tick subtractive shocks. Checkpoint and shock results are
`NOT_REACHED`, not described as product successes or failures in isolation.

The rendered seed-46 client ran for 300.007 seconds. Real Player input moved
position and camera while four autonomous decisions and three completions
occurred, with zero direct `setPos` and zero productive command after
`PLAYABLE_SLICE_BOOTSTRAP_COMPLETE`. The society then crossed the same home
boundary at cognitive tick 39. Only 38 cognitive ticks completed successfully;
the final acceptance snapshot contained 32,858 runtime errors. Six captures
were emitted, but visual inspection found only the initial anomalous frame
showing multiple inhabitants; the later named multi-agent, agriculture,
livestock, follow and final captures did not show continuing inhabitants or
multi-domain life. B12 is `FAIL`.

All 13 focused selectors passed (`1,225/0`). The canonical gate remained
`35/35` and `3,187 passed, 0 failed`, so Gate R remains acquired and existing
component contracts did not regress. Hard acceptance does not average these
component successes over a systemic integrated failure: B1 through B12 all
remain `FAIL`.

The durable bounded record is
[`GATE_B_REEVALUATION_4_SUMMARY.json`](GATE_B_REEVALUATION_4_SUMMARY.json).
Raw logs, per-seed JSON and captures remain in the dedicated temporary evidence
root printed by `scripts/verify-pebblelab-gate-b.sh`.

Before another campaign, the acceptance fixture must become role-neutral:
compose only the permitted physical opportunities and let product cognition
create plans, responsibilities and tasks. The smallest product correction is a
non-canonical `GATE-B-CORR-05`: reconcile autonomous target/route selection
with the existing home-distance feedback boundary, or causally replan/return
home before crossing it, without disabling movement, widening acceptance,
teleporting or adding a second pathfinder. This evaluation implements neither
correction, does not acquire Gate B and does not start `CIV-26`.

## Post-CORR-04 local remediation record

Starting baseline:
`4d79aea21d77ddbfafd464695ed8a0517164b4ea`
(`Finalize Gate B acceptance harness consistency`).

`GATE-B-CORR-04 — Stable Work Demand Refresh and Transactional Continuity`
remediates `B-BLOCKER-STABLE-WORK-DEMAND-REFRESH` locally. The contract is:

```text
WORK DEMAND LOGICAL IDENTITY != LATEST CAUSAL PROVENANCE
REFRESH != NEW DEMAND
```

Logical identity is the canonical tuple `demandID`, `source`, `sourceKey` and
`domain`. A mismatch in any tuple member remains a fail-closed corruption.
`sourceEventID`, observer/suggested worker, target, tool/resource requirements,
urgency, quantity and cadence are a refreshable projection of the canonical
domain state. `createdAtTick` remains the historical origin; refresh and expiry
ticks may advance.

An unchanged-source heartbeat extends the projection without adding a causal
event. A newer valid source from the same simulation and appropriate domain
updates the same demand and appends the existing `workDemandRefreshed` event.
Stale, future, cross-simulation and wrong-domain references are refused.
Refresh does not increment `totalDemandCount`, replace an attached worker,
create evidence, grant practice, alter profession history or execute physics.
Phase changes whose `sourceKey` changes remain new logical demands.

The published re-evaluation #3 failure was the agricultural plot projection:
after the first real till, the two still-planned cells retained the same
`source/sourceKey/domain/demandID` while the plot's latest valid causal event
advanced. The former exact-`sourceEventID` guard therefore misclassified a
legitimate refresh as identity corruption at tick 4.

The dedicated deterministic selector covers the exact boundary, heartbeat,
newer provenance, phase change, commitment continuity, real outcome/evidence,
expiry/reactivation, v18 checkpoint/replay, input order, causal eviction and
all identity/causal negatives. The bounded Gate-B3 escape probe runs only the
ten historical seeds to 32 ticks plus seed 46 to 800; it is not the unchanged
5/3/2 acceptance campaign and credits no B1–B12 result.

Local evidence at the CORR-04 boundary is `10/10 PASS` at exactly 32 ticks:
every seed crossed tick 4, made 32 autonomous decisions, completed eight Work
reviews with two newer-provenance reconciliations, and reported zero runtime,
identity or stale-provenance errors. Seven seeds retained 22 logical demands
and 13 commitments; seeds 887, 1597 and 2593 retained 21 and 12 respectively.
The targeted seed-46 continuation reached 800 ticks with 200 refresh attempts,
594 heartbeat reconciliations, two meaningful refreshes, 483 new logical
demands, 314 withdrawals, 1,737 commitment-preservation observations, 202
commitments, four real Work evidence records, three profession profiles, 800
decisions, 491 starts, ten completions, six cross-family switches and zero
runtime/manual-productive errors. Its causal ledger remained bounded at 8,192
retained events after 3,908 evictions. This targeted continuation explicitly
does not credit Gate B.

```text
B-BLOCKER-STABLE-WORK-DEMAND-REFRESH: REMEDIATED LOCALLY
GATE B RE-EVALUATION #3: HISTORICAL FAIL
GATE B CANDIDATE RESULT: FAIL / RE-EVALUATION #4 PENDING
Gate R: ACQUIRED
Gate B canonically acquired: NO
CIV-26 started: NO
```

## Post-CORR-03 local remediation record

Starting baseline:
`768c8da5ccd325ecad06f9654e65b0a738864880`
(`Record Gate B re-evaluation #2 evidence`).

`GATE-B-CORR-03 — Integrated Local Apprenticeship Initiation` closes
`B-BLOCKER-INTEGRATED-TEACHING-INITIATION` locally. The normal bounded
autonomy review in the unique `AgentSimulationSession` now derives relevant
skill domains from current local activity candidates, considers only retained
nearby peers, obtains explicit deterministic student and teacher participation
decisions, then delegates all eligibility and ranking to the existing CIV-20
mentor-selection authority.

The integrated disposable-World proof used no fake skill, practice history,
profession, prestarted apprenticeship or manual initiation. Real foraging
success made `agent_2` practiced; `agent_1` then autonomously entered a local
foraging apprenticeship. A later real mentor success produced an observed
demonstration with zero observation skill, and the student's later own real
success produced normal practice before the existing guided-practice causal
link. Initiation, observation and guided linking created no material or yield
bonus.

```text
B-BLOCKER-INTEGRATED-TEACHING-INITIATION: REMEDIATED LOCALLY
GATE B CANDIDATE RESULT: FAIL / RE-EVALUATION PENDING
Gate R: ACQUIRED
Gate B canonically acquired: NO
Gate B re-evaluation #3 required: YES
CIV-26 started: NO
```

This is a corrective product proof, not Gate B re-evaluation #3. The unchanged
5/3/2 campaign, deterministic repeat, checkpoint/reconciliation campaign,
shocks, composite persistence and final human/senior review were deliberately
not run or credited here.

## Re-evaluation #3 — final candidate result

Product baseline:
`a673b28b14e9d6c97c8d59cca0fbe47b097410a8`
(`Prove integrated Teaching emergence`).

```text
GATE B RE-EVALUATION #3
CANDIDATE RESULT: FAIL

Gate R: ACQUIRED
Gate B canonically acquired: NO
CIV-26 started: NO
```

The acceptance harness armed every required gate, used each World's safe
natural spawn, enabled canonical Core random ticks, created one bounded
three-agent physical opportunity field, and emitted the required
`GATE_B_BOOTSTRAP_COMPLETE` / `PLAYABLE_SLICE_BOOTSTRAP_COMPLETE` end markers
before the corresponding observation window. No
post-bootstrap productive command, reroll, role assignment, material grant or
Teaching seed was used.

All ten fixed seeds were attempted. Every run completed the same initial real
actions — one till, two sheep feeds and one wild gather, with zero ghost
productive delta — then failed at cognitive tick 4:

```text
workCommitment(invalid work state: demand identity changed)
```

The work-demand refresh is transactional, so the refused transition does not
partially publish. It also means the session never advances past tick 4.
Consequently none of the fixed 800/4800/6400 horizons completes; seed 509
cannot establish final-state determinism, seed 887 cannot reach its safe
checkpoint boundary, and neither subtractive stress shock is reached. These
surfaces are recorded as `NOT_EXERCISED`, not falsely described as broken.
B8 and B11 fail directly; every other mandatory hard pillar remains
insufficient for candidate acceptance.

The rendered seed-46 client remains operable for the five-minute wall-clock
observation and accepts normal Player input, but the inhabitants cannot
continue their society after tick 4. B12 therefore fails even though the
client, camera, stable visual identities and zero-command bootstrap still
exist.

The durable bounded result is
[`GATE_B_REEVALUATION_3_SUMMARY.json`](GATE_B_REEVALUATION_3_SUMMARY.json).
Raw HEAD-bound logs, per-seed JSON, captures, focused results and full-gate
output remain in the dedicated temporary evidence root printed by
`scripts/verify-pebblelab-gate-b.sh`.

The smallest recommended correction is limited to stable work-demand refresh
identity: a refreshed logical demand must handle its newer causal source
deterministically without freezing the entire cognitive tick. This evaluation
does not implement that product fix, create CORR-04, acquire Gate B or start
`CIV-26`.

## Re-evaluation #2 — historical final candidate record

Evaluation starting baseline:
`fc618de61437c4acd63ec0ff41823e6d91b56d0a`
(`Prove continuous playable autonomous society slice`). CORR-01 and CORR-02
are published historical corrections at this baseline. This record evaluates
their assembled result; it does not reopen either correction or start
`CIV-26`.

```text
GATE B RE-EVALUATION #2
CANDIDATE RESULT: FAIL

Gate R: ACQUIRED
Gate B canonically acquired: NO
CIV-26 started: NO
```

The evaluator applied the hard-pillar policy before spending a long 5/3/2
campaign. All six focused regression selectors passed: physical food survival
50/0, autonomous civilization 36/0, livestock 30/0, work/professions 29/0,
dependent care 53/0 and Teaching 41/0, for 239/0. The four published blockers
therefore did not regress at their focused contracts.

The integrated readiness audit then found a hard B7 architecture blocker. The
normal Pebble product path has no caller of
`selectMentorAndStartApprenticeship`. The only Pebble caller is
`PebbleAgentController+TeachingProof.swift`. Autonomous physical execution can
publish a demonstration and guided-practice evidence only after an active
apprenticeship already exists; it cannot create the local Teaching opportunity
that Gate B requires. Starting that apprenticeship from the acceptance harness
would script the result and was refused.

The ten seeds and their horizons were fixed before this audit. None was
rerolled, hidden or credited:

| Tier | Seed | Fixed horizon | Result |
| --- | ---: | ---: | --- |
| short | 46 | 800 ticks | NOT RUN — B7 hard fail before campaign |
| short | 71 | 800 ticks | NOT RUN — B7 hard fail before campaign |
| short | 113 | 800 ticks | NOT RUN — B7 hard fail before campaign |
| short | 197 | 800 ticks | NOT RUN — B7 hard fail before campaign |
| short | 337 | 800 ticks | NOT RUN — B7 hard fail before campaign |
| medium | 509 | 4,800 ticks | NOT RUN — B7 hard fail before campaign |
| medium | 887 | 4,800 ticks | NOT RUN — B7 hard fail before campaign |
| medium | 1597 | 4,800 ticks | NOT RUN — B7 hard fail before campaign |
| stress | 2593 | 6,400 ticks | NOT RUN — B7 hard fail before campaign |
| stress | 4099 | 6,400 ticks | NOT RUN — B7 hard fail before campaign |

Because all required seeds, the society-scale conservation ledger, seed-509
repeat, seed-887 checkpoint/reconciliation and both shocks were not executed,
their corresponding pillars cannot be credited. This is not an average or a
claim that component proofs equal integrated acceptance.

| Pillar | Re-evaluation #2 | Evidence |
| --- | --- | --- |
| B1 Physical Material Truth | FAIL | No society-scale integrated ledger campaign. |
| B2 Real Food-to-Survival Closure | PASS | Published adult/dependent physical-food contracts passed focused regression; the passive World exact-debited real cod and berries with abstract delta zero. |
| B3 Multiple Viable Subsistence Strategies | FAIL | Local passive evidence exists, but the fixed multi-seed campaign was not executed. |
| B4 Agriculture and Managed Surplus Continuity | FAIL | Passive evidence reached till/plant only; random ticks were disabled, so growth, harvest, recovered seed and next cycle were not proved. |
| B5 Livestock Resource-Bounded Continuity | FAIL | The focused reserve contract passed, but campaign continuity and later-surplus eligibility were not proved. |
| B6 Care Continuity | FAIL | Care was not assembled into a medium and stress society run. |
| B7 Teaching / Own-Practice Learning | FAIL | No normal autonomous/local apprenticeship initiation path exists. |
| B8 Durable Work Specialization | FAIL | Work/profiles were not enabled in the passive World and no medium campaign ran. |
| B9 Replacement / Crisis Resilience | FAIL | The designated stress shocks and real replacement outcomes were not run. |
| B10 Local Information / No Omniscience / No Ghost Stock | FAIL | Strong component contracts remain, but no required composite campaign ledger exists. |
| B11 Determinism / Bounds / Persistence Safety | FAIL | Seed 509 repeat and seed 887 reconcile were not run. |
| B12 Playable Passive Observer Slice | FAIL | The live regression passed its narrower CORR-02 assertions, but not the final duration/tracking/integrated-society bar below. |

### Passive-product re-evaluation

The exact live World `PebbleLab-Disposable-GateB-Reevaluation-46` ran 648
simulation ticks at 4 Hz. The interval from the first to last capture was 161
seconds, below the five-minute target. It produced 648 decisions, 14 starts,
11 completed domain activities, one blocked activity, four cross-family
switches, three agents with completions, zero productive commands after
bootstrap, zero eligible-idle violations and zero runtime errors. Completed
families were agriculture 6, livestock 2, wild subsistence 3 and physical
survival 6. Real Player input changed position by 1.736 blocks and changed
yaw/pitch while four decisions and five completions occurred.

This remains useful CORR-02 regression evidence, but is not final Gate B
product evidence. Care, Teaching and work/professions were disabled. Core
random ticks were disabled, so planted crops could not grow or be harvested.
The continuous productive trace for `agent_0` covers till/plant decisions at
ticks 0–12 rather than several minutes. The initial inverted/incomplete terrain
frame recurred; it did not stop input or simulation and was resolved by the
next scheduled capture 33 seconds later, but its exact shorter duration was not
measured.

The smallest corrective recommendation was
`GATE-B-CORR-03 — Integrated Local Apprenticeship Initiation`: derive a bounded
local mentor/student opportunity from real prior practice and local
availability inside the unique `AgentSimulationSession`, without adding a
scheduler or granting skill/profession/output. After that product correction,
the complete unchanged 5/3/2 acceptance, determinism, checkpoint/reconcile and
five-minute passive slice must run. CORR-03 is now remediated locally by the
record above, but is not a Gate B acquisition.

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

Published corrective status after `GATE-B-CORR-01`, based on starting HEAD
`515ae22c871292a978bb76da3020d3959632b6ed`:

```text
GATE B CANDIDATE RESULT: FAIL

Automated Integrated Acceptance: FAIL
Playable Passive Observer Slice: FAIL
Real Food-to-Survival Closure: PASS
Gate R: ACQUIRED
Gate B canonically acquired: NO
```

Published corrective status after `GATE-B-CORR-02`, based on starting HEAD
`1b7c320ec897d5ea9944d3c12e6b7c460954ce23`:

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

Published verdict: `B-BLOCKER-FOOD-CLOSURE` is `CLOSED`. CORR-02 subsequently
added a separate physical dependent-care path; the legacy coarse model remains
compatible and isolated.

## GATE-B-CORR-02 published remediation

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
| Teaching/apprenticeship | no autonomous initiation; evidence chaining only after a pre-existing apprenticeship | initiation exists only in focused proof | required | incomplete | Demonstration evidence derives from real work and observation grants no skill, but the normal product path never creates the apprenticeship. This is the B7 re-evaluation #2 blocker. |
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
corrective seed-46 slice now proves same-World cross-family coexistence, but it
is not a Gate B campaign seed. The required 5/3/2 campaign, composite
persistence boundary and multi-seed adaptation therefore remain not run.

## Pillar disposition

| Pillar | Candidate status | Evidence boundary |
| --- | --- | --- |
| B1 Physical Material Truth | partial | Real custody, same-World corrective actions and zero-ghost checks exist; no society-scale conservation ledger or canonical campaign exists. |
| B2 Real Food-to-Survival Closure | pass locally, pending publication | Exact physical food debit reaches canonical agent hunger with shadow isolation, idempotence and rollback proof. |
| B3 Multiple Viable Subsistence Strategies | partial | Local orchestration and a cross-family passive slice pass; the canonical multi-seed adaptation campaign is pending. |
| B4 Agriculture and Managed Surplus Continuity | partial | Autonomous real till/plant chaining passes in the corrective composite; multi-cycle campaign evidence is pending. |
| B5 Livestock Resource-Bounded Continuity | partial | Real reserve-gated eligibility and two physical feed completions pass in the corrective composite; campaign closure is pending. |
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

The hardened product-proof run records decisions, candidates, starts,
completions, blocks, same-family continuations, cross-family switches,
completed agents/families, retained records, evictions and per-agent idle
reasons. Its single seed-46 timeline completed agriculture, livestock, Wild
Subsistence and physical survival across all three agents. Agriculture produced
three real till/plant pairs, both livestock actors fed real sheep, Wild
Subsistence acquired physical food, and the survival path exact-debited that
food into canonical hunger with `foodRaw`, CampStock and coarse-ecology deltas
all zero. Four cross-family transitions were observed. No tick was idle while
an eligible higher-than-idle candidate existed.

The Player input probe used `GameCore.keyDown`/`keyUp` and `mouseDelta`, the
same world-mode API reached by AppKit, and never wrote Player position. During
20 World ticks it changed horizontal position and yaw/pitch while four new
autonomous decisions and five completions occurred. The fixture owns bounded
setup/cleanup only; physical actions remain selected by cognition.

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
are absent under the gate.

```text
Pebble process launched: YES
real rendered World captured: YES
capture(s) inspected: YES (six)
multi-agent life visibly represented: YES
agriculture visibly represented: YES
livestock visibly represented: YES
multiple domain contexts visibly represented: YES
one stable individual traceable across decisions/captures: YES
real Player movement/camera coexistence trace-proven: YES
manual productive commands after bootstrap: 0
autonomous completed activities: 11
completed agents: 3
completed families: 4
cross-family switches: 4
idle while eligible violations: 0
runtime errors: 0
ghost productive credits: 0
cleanup: exact
visual anomaly: one transient malformed first frame; five later frames coherent
captures: gate-b-passive-start/multi-agent/agriculture/livestock/follow-agent/later.png
```

The multi-agent frame shows distinguishable inhabitants with the physical pen,
sheep, field and storage. Subsequent frames show the agricultural and livestock
contexts and changed inhabitant/World state. The first post-bootstrap frame had
a transient inverted/incomplete terrain render; it is retained and reported,
not treated as product evidence. The other five frames rendered normally and
showed no stacking, teleportation, ghost item, duplicate animal, stale overlay
or camera hijack. This local slice is corrective evidence only; it does not
replace human review or the canonical Gate B campaign.

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
- translate selected decisions into existing agriculture, wild and livestock
  executors while retaining the existing care path and post-apprenticeship
  Teaching evidence path;
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
corrective seams are published. Gate B re-evaluation #2 failed on integrated
apprenticeship initiation; the smallest recommended next corrective activity
is CORR-03, not `CIV-26`.

## Product question

> Can I launch Pebble normally, enter the World, issue zero per-agent commands
> after bootstrap, walk among the inhabitants for several minutes, and watch a
> small society begin to live, work, learn, care and adapt without me?

```text
NO

Normal controls, zero productive commands and cross-family physical work are
real in the CORR-02 slice. CORR-03 now proves autonomous local apprenticeship
initiation and its full no-free-skill causal chain. The final candidate still
did not prove integrated care, specialization, agriculture continuity, crisis
recovery or the required multi-seed/persistence campaign. Gate B remains NOT
ACQUIRED pending re-evaluation #3.
```
