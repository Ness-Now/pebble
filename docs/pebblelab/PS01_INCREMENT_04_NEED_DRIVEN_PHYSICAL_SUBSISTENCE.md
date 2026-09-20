# PS01 Increment 04 — Need-Driven Autonomous Physical Subsistence

Status: **COMPLETE — SENIOR REVIEW APPROVED — PUBLISHED — REMOTE VERIFIED**.

PLAYABLE SLICE 01 remains **REQUIRED — IN PROGRESS / NOT COMPLETE**.
CIV-48 remains **NOT STARTED — IMPLEMENTATION NOT AUTHORIZED**. Increment 05
has not been selected; the next permitted workflow is the separate read-only
`REVIEW-AND-SELECT-PLAYABLE-SLICE-01-INCREMENT-05` mission.

## Published position

- Repository: `Ness-Now/pebble`.
- Canonical branch: `lab/pebblelab-v1`.
- Canonical baseline: `9d4642b03e398999528fd0fdef4adbbd7707bd28`.
- Canonical tree: `3d7e8497a0e575266b949cfeb0b36a657549ea9e`.
- Published commit: `b478fcfd75126fb5ab742916930eb8eb08c5f4f2`.
- Published tree: `2d4ef2716412a4c121fc06e6d292418218cfb009`.
- Published parent: `9d4642b03e398999528fd0fdef4adbbd7707bd28`.
- Implementation branch:
  `codex/ps01-increment-04-need-driven-physical-subsistence`.
- Published commit message: `feat(ps01): add need-driven physical subsistence`.
- Senior review: **PASS — P0 0 / P1 0 / P2 blocking 0**.
- Publication: manual push completed; canonical remote independently verified.

The implementation branch began directly at the canonical baseline. This report
records the senior-review-approved published Increment-04 result; it does not
declare PLAYABLE SLICE 01 complete.

## Selected scope and architecture

Increment 04 activates one need-driven natural food loop: a hungry normal
founder may recognize a freshly observed mature `sweet_berry_bush`, select the
existing wild-gathering activity, physically move, break the exact Core block,
take custody of the resulting real `sweet_berries`, consume one through the
existing physical-food transaction, and receive the validated homeostatic
consequence.

The authority boundary remains unchanged:

- PebbleCore owns block/item registries, edible metadata, loot, World mutation,
  ItemEntities, World randomness, and physical truth.
- Pebble translates one fresh bounded Core observation into neutral evidence,
  drives existing movement/physical gateways, verifies physical results, and
  compensates failed candidates.
- PebbleAgents owns deterministic need, evidence freshness, opportunity state,
  autonomous selection, causal publication, checkpoint/replay, and read-only
  Observer projections. It imports no PebbleCore and knows no raw block/item ID
  or loot table.
- `AgentSimulationSession` remains the sole civilization aggregate root.

No parallel scheduler, material ledger, inventory, food counter, reservation
service, physical pathfinder, or cognitive owner was introduced.

## Natural source and physical qualification

The single food domain is `sweet_berry_bush` at metadata stage 2 or 3.
PebbleCore normal feature generation places bushes at stages `2 + rng.nextInt(2)`.
The Core block definition exposes distinct stage textures and returns no drop
for stages 0/1; stages 2/3 have a guaranteed `sweet_berries` drop with random
quantity 1...3. The item registry defines `sweet_berries` with hunger 2 and
saturation 0.4. No held tool, agriculture, market, production, livestock,
fishing, or hunting bootstrap is required.

The actor-neutral Core qualification reads the same block-drop and food
registries used by canonical break execution. It proves only that the exact
current cell is capable of a guaranteed, simply debit-able edible result. It
does not predict quantity. PebbleAgents receives only canonical material name
and a bounded physical-source fingerprint; actual identity and quantity arrive
after the canonical physical action and ItemEntity verification.

Focused qualification proves stage 0/1 refusal, stage 2/3 eligibility, unrelated
plant refusal, stale fingerprint refusal, expiry refusal, and incomplete scan as
unavailability rather than absence.

## Hunger policy and normal founder composition

The one authoritative live survival configuration supplies:

- hunger increase: 0.05 per cognitive tick;
- hungry threshold: 0.40;
- critical threshold: 0.80;
- hunger recovery threshold: 0.15.

Food acquisition is eligible at the configured hungry threshold. A committed
hunger-recovery goal remains a need only while hunger is above the configured
recovery threshold. There is no second Pebble/PebbleAgents magic threshold.
Focused proof with the same mature source shows no opportunity, berry movement,
break, custody, or consumption before meaningful hunger.

Normal `/lab start founders <count>` composes five candidate-local authorities
before the existing atomic publication boundary: skills dependency, ecological
observation, wild subsistence, physical food, and autonomous activity. No
activation or productive command is needed. The generic arbiter cannot
originate fishing, hunting, agriculture, production, work/professions, markets,
barter, or contracts because their own authorities/inputs remain disabled.
Normal Increment-04 wild-subsistence composition presents only the selected
berry gathering strategy.

Representative bootstrap failures while enabling the extended candidate remove
all staged probes, publish no session, expose no residual authority, leave the
World/cognitive boundary coherent, and permit a clean retry. Historical
non-founder/three-agent startup remains unchanged.

## Ecological evidence and bounds

The production sensor reads only already-loaded, Increment-03-covered World
truth. Live bounds are radius 4, vertical radius 2, at most 512 cells, 4 chunks,
64 entities, 128 results, 1,024 World reads per scan, and 32 scans per cognitive
tick. The normal terrain shape in the measured campaigns visited 205 cells and
205 World reads per founder per scan.

Dynamic edible evidence is fresh for four civilization ticks. Total retained
observations are bounded at 128 and at 16 per observer. Incomplete, pending,
refused, unavailable, stale, and expired evidence cannot be converted into
physical absence or a food opportunity.

Every retained receipt-backed authority has an exact independent World-side
receipt. Receipt reconciliation retains the union required by live observations,
legitimate agricultural references, and saved checkpoints. Old causal events do
not pin redundant receipt bytes after their authority leaves. A bounded derived
cache reuses a decoded receipt only while exact database bytes match; it is not
durable or authoritative.

The checkpoint lifetime proof saved tick 1 with ten qualified berry observations.
Live retention later reached 128 rows while checkpoint authority legitimately
pinned extra rows, raising the World receipt set to 148. Loading restored the
exact saved digest. Deleting the checkpoint released that authority, and by tick
7 reconciliation returned to 128 retained observations and 128 World receipts,
with no stale opportunity or runtime error.

## Opportunity, fairness, and autonomy

Wild-subsistence live configuration retains at most 16 active opportunities,
with a four-tick lifetime and at most eight attempts per tick. Admission is
ordered by causal need/evidence/distance/score; stable AgentID is only the final
deterministic tie-break.

The >16-founder proof admits agents 0...15, reports agent 16 explicitly deferred,
never exceeds 16, releases one slot, and subsequently admits initially excluded
agent 16. Saturation is nonfatal and slots recycle after completion, refusal, or
expiry. Unequal outcomes remain legitimate consequences of need, evidence,
distance, lifetime, contention, and the fixed bound rather than permanent
founder-index entitlement.

The existing autonomous arbiter selects the hunger-motivated `wildGathering`
candidate. Bounded movement uses the existing covered navigation result. No
proof command, scheduler, or direct opportunity injection participates in
normal selection.

## Direct physical action and RNG

PebbleCore owns the scoped direct-action RNG. The substream derives from stable
World physical seed context (World seed, dimension and tick), operation domain,
target X/Y/Z, and a stable attempt identity mixed without Swift `Hasher`.
Player/camera position and collection iteration order are absent. The outer
`gameRng` value is saved before the scope and restored afterward on success,
refusal, or compensated rollback.

The scope encloses canonical break-handler randomness, berry quantity, spawned
ItemEntity velocities, and the injectable World-owned ItemEntity bob phase.
Legacy player block breaking passes no scoped contract and retains its historical
global/nondeterministic semantics. Increment-03 scheduled/covered RNG is
unchanged and remains a separate guarantee.

Focused Core direct-action digest: `2fd2a58c78641231`. Through the actual Pebble
gateway, camera near, camera far, camera moved away/returned, and deliberately
perturbed outer RNG all produce the same agent-relevant digest:
`4409c39f17ada80f`. Exact cell transition, material, quantity, ItemEntity state,
custody, receipt, and civilization publication match, while outer RNG remains
unchanged.

The physical gateway owns mutation and candidate compensation inside the
World-owned scope. Core owns scope establishment/restoration. Pebble's candidate
transaction records and restores the complete action-owned physical state; it
does not compete with the outer RNG owner.

## Material chain and consumption

The focused product path records:

- mature cell `8579` -> air `0` through canonical block break;
- one real ItemEntity;
- three `sweet_berries` physically dropped and transferred;
- exact agent custody quantity 3;
- one berry selected and physically debited;
- consumed quantity 1, remaining physical custody 2;
- hunger 0.65 -> 0.55;
- abstract `foodRaw` delta 0.

No abstract food is minted, no duplicate stack exists, transferred ItemEntities
are removed from physical source custody, and the consumed item is not retained
in inventory. Quantity leaves the chain only through the authoritative debit.
The cognitive consequence follows only the validated physical-food operation;
Pebble does not directly mutate hunger.

Consumption attacks cover stale inventory fingerprint, removal after prepare,
duplicate intent, insufficient quantity, and publication rejection after debit.
Recoverable failures restore exact physical custody and cognitive state. They
cannot lose an item, reduce hunger without debit, or publish duplicate
consumption.

## Contention, scarcity, and failure boundaries

Two hungry founders may observe the same source without a second reservation
authority. Exact physical revalidation permits at most one mutation, one drop
set, and one custody chain. The later contender receives stale/depleted/refused
causality and no success receipt, ItemEntity, or berry duplication.

Focused scarcity/readiness covers no mature berry, immature-only source,
outside-bound source, stale source, unreachable source, coverage pending,
coverage refused, `.coverageLimited`, `.nodeBudgetExhausted`, full custody, and
capacity saturation. Unavailable/stale/unreachable is never reported as absence.
Continued hunger or starvation is a valid natural scarcity result.

Pre-mutation, mutation, custody, publication, and consumption attacks cover
stale cell, invalid/dead actor, unavailable chunk, out-of-reach target, Core
refusal, unexpected result, missing/mismatched ItemEntity, full destination,
fingerprint mismatch, duplicate acquisition, cognitive rejection, stale debit,
post-debit rejection, and duplicate consumption. Recoverable compensation is
exact. Injected compensation failure trips the existing physical hard-failure
boundary and blocks unsafe continuation; it is never caught and ignored.

The first premature live acquisition attempt is retained as negative readiness
evidence. Hunger and selection existed, but Increment-03 coverage had not yet
reconciled. The candidate rolled back with no source consumption, custody,
hunger improvement, false civilization publication, runtime error, or hard
failure. A later ready retry proceeded normally.

## Persistence and replay

The feature uses existing schema-30 ecological, wild-subsistence, autonomous,
and physical-food durable owners; it does not introduce a broad schema bump.
Optional edible evidence preserves legacy absence, and old checkpoints decode
without inventing evidence. Neutral evidence contributes to canonical digests
only when present.

Direct/restored continuation converges before opportunity, after selection,
after acquisition/custody, and after consumption. Current-source suites pass
checkpoint/replay `49/49`; focused proof shows sequential and batched ecological
publication have identical durable bytes, a batch produces one replay record,
and replay restores every receipt-backed observation exactly. Restored dynamic
evidence keeps the same four-tick freshness and expires/revalidates; it cannot
become immortal.

## Observer

Observer additions are read-only projections of hunger motive, qualified target,
opportunity, movement/refusal, acquisition result, carried berries, consumption,
and hunger consequence. Existing explicit truncation remains in force. Changing
focused/followed agent or camera cannot choose candidates, cache food authority,
feed cognition, or change physical results. Focused Observer immutability and
camera displacement are green.

## Natural product evidence

Canonical seeds 46 and 887 were tried first and are bounded natural scarcity
cases. A deterministic ascending fallback search over `0..<256`, using production
ecological qualification at normal spawn/founder placement, found seed 14 as the
first qualifying seed. The discovery record includes spawn `208,67,-32`, founder
`agent_2` at `206,67,-34`, and a naturally generated stage-2 source at
`205,66,-32`. The search is discovery evidence only and changes no default.

A later fresh ordinary seed-14 World supplied acceptance. The environment had no
`PEBBLELAB_DISPOSABLE_WORLD_PROOF`, proof command, fixture, berry placement,
terrain mutation, food grant, physiology override, forced agent movement,
pause, step, speed, or productive command. Only normal founder start and
read-only observation were used.

Current-source sequence:

- civilization tick 1 / World tick 52: fresh bounded observations begin;
- civilization tick 9 / World tick 92: hunger reaches the need threshold and
  fresh evidence can originate opportunities;
- tick 10 / World tick 97: agents 8 and 9 complete autonomous physical gathers;
- tick 11 / World tick 102: agents 8/9 consume real berries; agent 14 physically
  moves from `210,66,-28` to `211,66,-28`;
- tick 12 / World tick 107: agent 14 completes physical gathering;
- tick 13 / World tick 112: agent 14 consumes one berry, hunger 0.65 -> 0.55.

The run recorded three completed `wildGathering` activities, `foodRaw=0`, zero
runtime errors, zero physical hard failures, and no unrelated-domain activity.
Its sufficient positive horizon is tick 13; later natural terminal evidence
records the cohort ending by tick 24 rather than treating idle polling as
acceptance.

Fresh current-source seed-46 scarcity reached ready coverage, produced zero food
candidates/acquisitions/consumptions, zero runtime errors, and zero hard
failures; natural extinction occurred at ticks 23/24 without being engineered.

## Camera evidence

The accepted positive seed-14 run chose a naturally safe surface approximately
512 blocks away, teleported only the player, dwelled remotely, and returned.
Coverage stayed ready for 20 founders/16 covered chunks; normal product behavior
completed three wild gathers and one physical movement while the observer was
remote, with no runtime/catch-up/hard failure. The seed-46 scarcity counterpart
kept ready coverage for 20 founders/12 chunks and fabricated no opportunity,
acquisition, or consumption.

These rendered runs prove observer independence, not whole-World equivalence.
Exact direct-action RNG equivalence is the separate focused four-case proof.

The first camera attempt is retained as **SUPERSEDED — OBSERVER HARNESS
ANOMALY**: the survival player was placed high above unsafe terrain, fell, and
died. Agent simulation stayed active and autonomous acquisition still occurred
remotely with no Pebble hard failure, but that run is not accepted camera
evidence and does not indicate an agent-system defect.

## Canonical normal matrix

All cases used continuous default Play at World 20 Hz/cognition 4 Hz with no
pause, step, speed, productive command, or fixture. The bounded horizon was 24
civilization ticks.

| Founders / seed | Coverage | Food candidates / acquisition / consumption | Population at horizon | Runtime / hard failure |
| --- | --- | --- | --- | --- |
| 20 / 46 | ready, 20 roots / 12 chunks | 0 / 0 / 0 | 20 | 0 / 0 |
| 24 / 46 | ready, 24 roots / 12 chunks | 0 / 0 / 0 | 24 | 0 / 0 |
| 24 / 887 | ready, 24 roots / 9 chunks | 0 / 0 / 0 | 24 | 0 / 0 |
| 30 / 887 | ready, 30 roots / 9 chunks | 0 / 0 / 0 | 30 | 0 / 0 |

These are canonical natural scarcity observations, not a requirement that new
normal campaigns reproduce historical tick-23 extinction. Historical controlled
Increment-02 terminal continuity remains a separate contract.

## Performance root cause and correction

The release sampler times only the real normal `advanceOneTick` path. Startup,
World generation, command parsing, proof validation, trace formatting, terminal
printing, and screenshots are outside the timed interval. Cold samples are
separated from plateau steady state. The sampler changes no authority, bound,
frequency, ordering, or validation and is not required by normal behavior.

Before correction, 30-founder steady state was approximately 444 ms: ecological
batch approximately 251 ms, including approximately 206 ms in 30 separate
whole-session replay/integrity publications and approximately 93 ms repeatedly
decoding receipt validation; the actual World scan was only approximately
3.7 ms.

The correction preserves semantics while eliminating repeated work:

1. ordered observation publications share one atomic replay-integrity envelope;
2. retained exact receipt bytes use one bounded derived validation index/cache;
3. batch receipt capacity is preflighted once;
4. confirmed inserted bytes seed the cache only after physical insertion;
5. receipt lifetime follows genuinely retained live/checkpoint authorities.

No authority, observation, freshness, causal event, material result, scan/read,
agent, or validation was removed.

| Founders | Plateau samples | Scans / cells / reads per step | Median | p95 | Max | Catch-up delta |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 20 | 13 | 20 / 4,100 / 4,100 | 107.183 ms | 131.911 ms | 141.240 ms | 0 |
| 24 | 14 | 24 / 4,920 / 4,920 | 128.541 ms | 171.911 ms | 188.002 ms | 0 |
| 30 | 15 | 30 / 6,150 / 6,150 | 169.053 ms | 243.287 ms | 268.070 ms | 0 |

The next-highest 30-founder sample was 232.665 ms. The isolated maximum above
250 ms is accepted as a non-sustained scheduling outlier because median and p95
satisfy the 4 Hz budget and every measured plateau reports zero catch-up-drop
delta, runtime error, and physical hard failure. No claim is made above 30
founders.

## Proof surfaces and regressions

- Final focused Increment-04: **33/33 PASS**.
- Ecological observation owner: **68/68 PASS**.
- Checkpoint/replay owner: **49/49 PASS**.
- Receipt lifetime live proof: **PASS**.
- Touched owner suites: **PASS**, no assertion weakening or regold.
- Increment 03 coverage: **34/34 PASS**.
- Increment 03 checkpoint/camera RNG/path: **21/21 PASS**.
- Increment 03 performance: **6/6 PASS**; 30 roots and 270 theoretical chunks
  remain unchanged, as does zero-agent legacy behavior.
- Increment 02 historical terminal continuity: **85/85 PASS**; exact terminal
  custody, unique mortality receipts, no ghost probes, restore and continuation.
- Final release build: exact `swift build -c release --product Pebble`, exit 0,
  2.40 seconds wall, no warnings.
- Canonical gate: exact `scripts/verify-pebblelab.sh`, **35/35 steps**,
  **4,843/4,843 assertions**, exit 0, regold refused/false.

## Focused disposable proof evidence

`/lab ps01-increment-04-proof` is accepted only when
`PEBBLELAB_DISPOSABLE_WORLD_PROOF=1`. It is unavailable during ordinary product
operation, cannot silently activate normal authorities, and is unnecessary for
normal founder behavior. Its retained subcommands reproduce exact gateway RNG,
physical fault/compensation, contention, seed discovery, performance,
consumption atomicity, and focused founder evidence. Normal product execution
does not call proof implementation; seed search and performance sampling do not
affect normal behavior.

## Minimality and exclusions

The final baseline diff classifies 27 files as REQUIRED PRODUCT, 2 as REQUIRED
TEST / PROOF, 2 as REQUIRED HARNESS, and this file as REQUIRED PHASE
DOCUMENTATION. **UNNECESSARY = 0**. The performance correction is the same
Increment-04 causal contract with less repeated receipt/replay work, not a
general performance framework.

Explicitly excluded are fishing, hunting, agriculture, livestock, production,
professions/work, markets, barter, contracts, generic gathering expansion,
population-cap increase, scan-radius increase, default frequency reduction,
catch-up relaxation, global player RNG replacement, Increment-03 scheduler RNG
changes, an LLM decision owner, Increment 05 selection, and CIV-48
implementation.

## Review disposition

- P0: **0**.
- P1: **0**.
- P2: **0 known**.
- Product state: **PRODUCT FREEZE**.
- Increment 04: **COMPLETE — SENIOR REVIEW APPROVED — PUBLISHED — REMOTE
  VERIFIED**.
- PLAYABLE SLICE 01: **REQUIRED — IN PROGRESS / NOT COMPLETE**.
- CIV-48: **NOT STARTED — IMPLEMENTATION NOT AUTHORIZED**.
- Codex push attempted: **NO**; user-owned manual publication: **COMPLETE**.
