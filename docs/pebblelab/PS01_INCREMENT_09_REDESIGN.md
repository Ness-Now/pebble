# PS01 Increment 09 — normal demographic continuity redesign

Mission baseline: `71e2245da7074af8464fb578255aa8e5a03c0204`, tree
`a4cc810d0cc58bbdb1a61c89f4d025a480f501e8`, sole parent
`c7de0c870b78fd527287f29362fb7f028fe6cd1d`. Fetched origin and exact
remote branch agree. The four published pre-I09 corrections are dependencies.
The rejected `d0ee80c` worktree was neither edited nor cherry-picked.

## Source and owner audit before architecture selection

| Boundary | Current authority and finding |
| --- | --- |
| Founder activation | `PebbleAgentController+Lifecycle` stages/validates bodies, invokes `AgentFounderSpecification` and `+FounderBootstrap`, then publishes. Normal subsistence is active; lifecycle initializes reproduction disabled. |
| Aggregate | `AgentSimulationSession` is the single value transaction and transition owner. No new kernel is necessary. |
| Settlement/population | `+Population`, `AgentPopulation` own identity, ordinals, resident/in-transit membership and committed admission capacity. Normal profile fixes capacity 30. |
| Lifecycle/reproduction | `+Lifecycle` evaluates bounded sorted pairs, accepts delayed plans, rechecks parents and accepts one site/birth transaction. Legacy pressure and abstract accessible food do not compose native physical meals. |
| Maturity/health/hunger | `AgentPhysiologicalTime`, `+Homeostasis`, lifecycle own World-time biology; reproduction already checks maturity, health, critical hunger. Normal composition additionally requires a currently nourished, physiologically available parent. |
| Kinship | Existing `areUnrelated`, `+Kinship` and birth registration remain the eligibility/parentage owners. No pair is forced. |
| Cooldowns | Lifecycle owns per-parent birth count, last completed tick and shared bounded evaluation/cooldown. Each subsequent normal birth additionally needs newer nourishment receipts. |
| Care | `+DependentCare` owns parent caregiver household, availability, load, assignment/need/childhood bounds and transactional birth registration. Existing Pebble food executor supports exact physical dependent provision. |
| Genetics | `AgentGenetics.inheritedGenotypePreview` uses deterministic keyed contributor/locus selection, then publishes with the birth transaction. No new RNG consumer. |
| Demographic readiness | The missing composition belongs to lifecycle in the session, reading already accepted PhysicalFoodSurvival evidence; it does not belong to Observer or a World census. |
| Ecology/subsistence | Legacy `+LocalEcology` yields/pressure and abstract food remain historical owners. `+WildSubsistence` uses fresh actor-local ecological receipts and accepted acquisition outcomes. Neither is replaced. |
| Live sensing/acquisition | Pebble ecological sensor and wild-subsistence executor validate local mature berry evidence and reuse Core preserving harvest, naturally grown by Core random ticks. |
| Custody/consumption | `PebbleAgentFoodConsumptionExecutor`, Core descriptor and material custody gateway prevalidate/debit/verify/rollback one physical item before publishing the pure outcome. Session retains exact accepted receipt identity, nutrition and need change. |
| Embodiment | `+LifecycleAge.resolvePendingBirthIfDue` scans safe bounded sites, applies the session candidate, creates one Core probe, checks exact occupancy and registers compensation before publication. |
| Checkpoint/session persistence | `AgentCheckpoint`, `AgentReplay`, Pebble persistence and normal World continuation retain owner state and authenticate occupancy/custody. Loading must not initialize a new demographic policy. |
| Schema 44 | World-time physiology with legacy reproductive semantics. Clean restore remains 44 until genuine path-readiness vocabulary is published. |
| Schema 45 | Adds bounded path-readiness liveness; demographic prerequisites remain legacy. Replay capability 45 can coexist with a 44 checkpoint without migrating it. |
| Telemetry | Lifecycle/Observer project state read-only. A physical accessible-food census is unavailable, rather than inferred from absent legacy ecology or converted to zero. |

## Architecture decision

Normal founder subsistence initialization prospectively composes lifecycle with
the existing PhysicalFoodSurvival and care owners. Every eligible progenitor
must have an accepted physical meal, remain below the existing hungry threshold,
be healthy and physiologically available, and satisfy existing lifecycle,
membership, kinship, cooldown and care checks. Initial bootstrap hunger zero is
insufficient. A later birth requires newer meals than that parent's last birth.

The nourishment receipt is evidence of a real past debit and present supported
need, not food still in inventory or a forecast of future abundance. This policy
does not require private reserves, unrelated cohort health, a global census or
legacy pressure. It creates no material, does not spend abstract food, and
introduces no second food, ecology or demographic authority. Capacity stays 30.

New accepted plans pin the exact two consumption receipts; bounded food-history
eviction cannot change the selected pair or reroll its accepted evidence. Current
parent physiology and care capacity are rechecked at the existing birth boundary.

Schema 46 explicitly owns this new meaning and provenance. Normal activation and
new-plan evidence are absent from historical 44/45 state. Their encoding,
activation and legacy prerequisites remain unchanged. New semantics masquerading
as historical schemas, missing pinned evidence and removal of the required
physical-food owner refuse. The existing checkpoint/replay owners persist it.

The existing unsupported-future Family/Estate checks used literal 46 when 45
was the newest supported version. I09 retains those checks at unsupported 47,
adds explicit strict-semantics checks for 46, and retains every historical
schema-range assertion. The first full gate's six failures are preserved as
development evidence: the three published failures plus these three stale
future-version expectations. No golden or historical result is rewritten.

## Qualification status

Disposition: **LOCAL_REVIEW_CANDIDATE**, qualified locally for independent
senior review. No publication or completed increment is claimed. PS01 remains REQUIRED / IN PROGRESS / NOT COMPLETE;
CIV-48 and Wave 6 remain unauthorized; Gate H remains planned.

The bounded native campaign is `scripts/verify-pebblelab-ps01-increment-09.sh`.
Seed 14 and 24 ordinary founders reuse the published natural berry environment;
seed 46 is the published natural scarcity control. The campaign stops at the
first native plan/birth, bounded by 12,000 World ticks, without provisioning,
forced pairing, fertility override, terrain changes or scripted births. Unit
DTO fixtures qualify refusal/codec boundaries and are not emergence evidence.
The headless harness gives the disposable World a stable storage ID for exact
cross-process comparisons; generation, physical time, terrain and food remain
the ordinary seed-derived World. The rendered campaign uses ordinary new-World
and autoload entry, with only a render-camera override during capture settling.


## Native positive, scarcity and deterministic qualification

The implementation commit is `9441f8c51ea02bc1d0d441e930a2dc5317e5c50e`.
The save-boundary qualification refinement is
`167f4aa` (`test(pebble): qualify authoritative save-time clock reconciliation`).
The final documentation commit and exact candidate tree are recorded externally
in the review package, avoiding a self-referential commit identity in this file.

The two fresh seed-14 / 24-founder writers reached the same first native birth
at World tick **9692**, civilization tick **1928**. The accepted plan was
`reproduction-plan-00001926-agent_18-agent_9`, created at tick 1926 and due at
1928. Its two exact physical consumption receipts support parents `agent_18`
and `agent_9`; no legacy pressure or foodRaw was supplied. The resulting
`birth-00000001` / `agent_24` has ordinal 24, position `(204,67,-37)`, canonical
parentage, inherited genotype and household-2 care assigned to `agent_18`.
Population is **25/30**, and the session/registry/World body bijection holds.
Physical accounting is **8 acquired = 6 consumed + 2 carried**.

The complete authoritative writer bytes are identical (SHA-256
`98b3cbacc34cae8379e1508bddc1a6db10c5964398414941babb4bdd13e1a5c7`).
Both original fresh readers restored those exact bytes and preserved the birth
through 40 more World ticks. Their successful Save/Continue boundaries were
also byte-identical (SHA-256
`7ebc82ac1e0ca29e004e7e97b46bb01692f887853ecf30fa3f2f49972856da15`).
Two further independent readers of those actual saved boundaries produced
byte-identical state and completed Save/Continue and Save/Exit with zero probes.

A separate native writer saved the accepted plan at World tick **9682**, tick
**1926**, before any birth. A fresh process restored the exact plan and reached
the same complete birth record, newborn agent state, population/lifecycle
member, genotype, kinship and care state at tick 1928. The plan ID, creation
event and pinned meals were not rerolled. The resumed birth occurred at World
tick 9693, one physical tick later than the uninterrupted path. Other ongoing
state differs with restart scheduling; whole future-trajectory equivalence is
not claimed. The accepted reproductive transition and offspring are exact.

The seed-46 scarcity control ran **12,000** normal World ticks after startup,
ending at World tick **12052**, tick **2400**, with reproduction enabled,
capacity 30, 24 residents, **zero acquisitions, consumption, plans and births**.
Its fresh reader continued to World tick 12092 and preserved zero births and
zero physical food. This proves an unmet physical-subsistence control within
the bounded local scenario, not a census claiming that the entire World has no
food. Save/Continue, Save/Exit and exact body membership passed.

## Persistence boundary and qualification corrections

Loading preserves the exact durable state, including schema 46, accepted plans,
births, kinship, genetics, care and physical-consumption provenance. Existing
normal checkpoint capture owns physiological reconciliation to current World
time. A raw running session can lag by a few physical ticks after its last
cognitive step; saving legitimately accepts that elapsed time. The qualification
compares the full saved bytes with the existing owner's monotonic World-time
operation on a read-only value copy, without supplying a prerequisite or birth.

The independent before/after comparison for the final readers changed only
`lastReconciledWorldTick` (9768 -> 9772), `remainderWorldTicks` (116 -> 120) and
`totalElapsedWorldTicks` (9716 -> 9720). Every other authoritative field remained
identical. The new harness's earlier assertion that all raw bytes remain
unchanged across this partial interval failed and is preserved as development
evidence. Its Save/Continue had succeeded; no Core defect or correction was
involved. Final readers resumed the complete actually saved World/checkpoint
bundles without altering World data or manufacturing prerequisites.

Another superseded new-harness run reached a native birth but refused saving:
it renamed the disposable storage ID without installing its World record.
Core correctly refused before checkpoint handoff. The corrected harness uses
the established I08 ordinary exit, Core metadata installation, ordinary load
and 52 real World ticks before founders. Earlier runs are retained as failures,
not qualification PASS. No published persistence dependency was reopened.

Schemas **44 and 45** retain exact historical bytes, disabled normal activation,
legacy ecology/food prerequisites and replay behavior. Physical meals alone do
not reinterpret those prerequisites. Schema **46** explicitly owns the new
activation/evidence meaning, reconstructs the accepted plan through the existing
replay owner, rejects missing pinned evidence, and refuses removal of the
physical-food prerequisite owner atomically. Historical schema payloads cannot
carry the new meaning. Family/Estate strictness and future-version rejection
remain tested.

## Owning regression and canonical results

- Focused command:
  `CFFIXED_USER_HOME=/tmp/pebblelab-i09-redesign-evidence/focused-qualified-home PEBBLELAB_SMOKE_ONLY=ps01-increment-09 .build/release/pebsmoke`.
  **737 passed, 0 failed**, including 19 new boundary checks and existing founder,
  reproduction, population, settlement, kinship, household, dependent-care,
  genetics, physical-food/wild-subsistence, persistence/replay/reconciliation,
  Increment 04/05, temporal/rollback and Core continuation/resident proofs.
- Final canonical command:
  `CFFIXED_USER_HOME=/tmp/pebblelab-i09-redesign-evidence/canonical/clock-home scripts/verify-pebblelab.sh`.
  **FAIL**, stage 5, **6555 passed, 3 failed**, exit 1: zoo bit-identical, combat
  lockstep and eight A* paths node-identical. No new unexplained failure.
- Exact supplemental stages **6–35 PASS**, exit 0. The review package retains
  the canonical script and transparent extraction: only stage-1–5 calls omitted,
  verified ROOT_DIR substituted, STEP initialized to 5; remaining checks and
  comparisons intact. This is not a full canonical gate PASS.
- Release builds, shell syntax, manifest JSON parse and diff checks passed.
  No golden changed and PEBBLE_REGOLD was never used.

A reused test home exposed ten existing B02/B03 fixture failures: its stable
cancellation World retained a prior required continuation and entry refused
before the test installed callbacks. No Core change was made. Fresh homes
resolved that contamination; both reused-home logs are preserved. The new
campaign refuses a reused focused home. The first full gate's stale future-46
checks and subsequent final results are recorded without rewriting their FAIL.

## Visual Game Smoke Policy V5

The real Metal-rendered Pebble client ran an ordinary seed-14 / 24-founder path,
with no reproduction command, staged pair, actor teleport, food provisioning or
terrain/lighting change. It produced the same native newborn `agent_24` and
parents `agent_18,agent_9`, at civilization tick 1928. Physical accounting was
**7 = 5 + 2** at capture and **9 = 7 + 2** after normal continuation. The slight
acquisition-count difference from the fixed headless startup is not normalized
away; both are legitimate independent normal paths.

The writer completed Save/Continue and Save/Exit. An independent ordinary
autoload restored 25 agents with `foundersCreated=0`, preserved the complete
birth/genotype/kinship/care and meal evidence, continued to World tick **12111**,
and completed Save/Continue and Save/Exit. Both processes verified `probesFinal=0`.
The exact body bijection was checked at the capture boundary.

All three real framebuffer captures were inspected. Terrain, foliage and actors
render coherently; the continuation is naturally darker at night. The camera
is a render-only observer override; capture settling temporarily pauses World
delivery and does not alter Player, actors, food or terrain. After-restore
capture waited for real mesh readiness and occurred later than the exact load
boundary. Rendered stand-ins cannot visually enumerate the exact newborn or
establish parentage; authoritative semantic/body evidence supplies those facts.
Legacy compact-HUD food counters are not the physical readiness authority.

| Capture | World tick | SHA-256 |
| --- | ---: | --- |
| before-save | 9706 | `7a28b926c55829547ac283e8936360128fa5952aeeb88a2e1afd5c84812927a6` |
| after-restore | 10911 | `2b9a03d6132892e0ce77ba4b45bbb49ce06975968817bab50a9cfef7eefb8623` |
| continued | 12111 | `3197d1ef0bb0a739b67d9c7b420e8acf1ed3929933b6749cef14cdb6dad8b136` |

The live executable was built before the headless test harness's storage/clock
assertion refinements. All normal activation, lifecycle, food, persistence,
embodiment and capture runtime sources are identical to the final candidate;
the revised qualification path is inactive in the live campaign. Distinct
binary hashes are preserved rather than claiming one executable identity.

## Scope and limits

No PebbleCore source changed. No second kernel, demographic/ecology/food owner,
physical mechanic, persistence owner or untracked RNG consumer was introduced.
Capacity remains 30. The first legitimate birth occurred below that bound.
Historical characterization and rejected I09 worktrees were not edited.

The candidate qualifies the first normal native birth, its prerequisites,
accepted-plan continuation, body/custody/persistence boundaries and a scarcity
control. It does not prove long-term abundance, sustained population growth,
multiple generations, whole-World future bit identity or behavior above 30.
CIV-48/Wave 6 remain unauthorized, Gate H planned, PS01 incomplete. Publication
and completion remain decisions for a later explicit supervisor review.

The focused external review package preserves exact baseline/candidate identity,
changed-file inventory, full-index patch, source audit/decision, successful and
superseded tests, raw causal/durable evidence, deterministic repeats, schema and
restart evidence, physical accounting, inspected captures/hashes, commands,
final Git state and a SHA-256 manifest. Build caches and redundant binary/data
bulk are excluded. Push attempted: **NO**.
