# PS01 Increment 01 — Normal Founder Sandbox Bootstrap

Status: **LOCAL REVIEW CANDIDATE**.
PLAYABLE SLICE 01 is required and not complete. CIV-48 remains **NOT STARTED —
IMPLEMENTATION NOT AUTHORIZED**. This increment establishes initialization;
it does not authorize the subsequent slice increments.

## Exact starting boundary

- Repository: `Ness-Now/pebble`, origin `https://github.com/Ness-Now/pebble.git`.
- Canonical branch: `lab/pebblelab-v1`.
- Fetched canonical HEAD: `196c6f770acc9bb416e04d03f39a7e1191f9329e`.
- Tree: `75665ce8ae0e4b77343151f1d1131d062253a08a`.
- Parent: `79a8926fb6ad7c50ef6682dd5025eca550777479`.
- Message: `docs(roadmap): canonize playable slice 01`.
- Initial local branch: `codex/roadmap-ps01-01`, same HEAD, clean worktree.
- Implementation branch:
  `codex/playable-slice-01-increment-01-normal-bootstrap`.

The preflight read root and target AGENTS, CODEX_START_HERE, CURRENT_STATE,
vision, the PS01 roadmap/manifest contract, development workflow, Visual Game
Smoke Policy V5 and the applicable live runbook. No architectural blocker
requiring a new owner was found.

## Product contract and use

In an ordinary World, `/lab start founders 24` starts the normal profile.
Counts 20 through 30 are accepted; other counts fail explicitly. `/lab start`
retains the historical three-agent profile for focused tooling. An explicit
founder start refuses to replace an active civilization. `/lab reset` reuses
the configured startup profile; it remains an explicit destructive reset of
that session, as before.

The required existing launch gates are `PEBBLELAB_APP_AGENTS=1`,
`PEBBLELAB_APP_PROBES=1`, `PEBBLELAB_DEBUG_ENTITIES=1`,
`PEBBLELAB_APP_AGENTS_POPULATION=1` and
`PEBBLELAB_APP_AGENTS_PERSISTENCE=1`. For the integrated baseline, also enable
`PEBBLELAB_APP_AGENTS_` gates `MOVE`, `OBSERVER`, `LIFECYCLE`, `KINSHIP`,
`HOUSEHOLDS`, `CARE`, `CHILDHOOD`, `FAMILY`, `MORTALITY`, `HOMEOSTASIS` and
`GENETICS`, each with value `1`. `AUTONOMOUS_CIVILIZATION=1` under that same
prefix makes the existing autonomous-civilization commands available and also
selects inhabitant models in WorldRenderer. It is not a rendering-only gate;
founder startup does not execute its passive fixture or enable autonomous
activity authority. Trace/overlay gates
are presentation and diagnostics. Missing domain dependencies fail the whole
candidate through the owning enable operation; they are not silently filled.

No disposable flag, proof command, terrain rewrite, resource fixture or
future schedule is required. New founders have symmetric idle needs, empty
memory and custody, health 100, fear 10 and curiosity 0.2. No practiced skill,
profession, apprenticeship, productive task, social winner, union, house,
parentage or birth plan is supplied. Enabled lifecycle registers mature roots;
households derive singleton memberships from distinct home positions. Family
and childhood authorities initialize without inventing relationships or
childhood exposure. Reproduction remains inactive at this boundary.

## Reused seam and ordering

`PebbleAgentController.start/rebuild` remains the physical orchestrator.
`PebbleNormalFounderProfile` owns the PS01 count range and the population and
household configurations. `AgentFounderSpecification` is a shared finite input
bounded by the supplied population capacity, not persisted population authority.
The shared registry accepts positive contiguous founder IDs within its existing
configured capacity; 20–30 is not a universal civilization law. The normal profile reuses `AgentSimulationSession`, its
population registry and the existing domain enable operations:

1. Validate founder count and required product gates before replacing anything.
2. Resolve all founder positions plus a separate reception point from actual
   World data through `findSafeEntityPlacements`.
3. Construct an unpublished session with canonical IDs `agent_0` through
   `agent_(N-1)`; stage all probes through the existing `createProbe` path.
4. Initialize population, lifecycle, kinship, households, survival, care,
   childhood, family, mortality, homeostasis and genetics, where enabled.
5. Validate the complete candidate through the existing checkpoint restore
   validator; check physical indexes, positions, player separation, expected
   probe identities, durable exactness and read-only Observer projection.
6. Publish session, bindings and controller state together, with no remaining
   throwing work.

Population initialization now validates contiguous canonical identities and
configured capacity and derives each ordinal from its canonical ID. Registration keeps the existing lexical identity order; `agent_10` keeps
ordinal 10. The next ordinal is N. The public population operation itself now
uses a private candidate, so late causal errors cannot consume published
registration state. No new population, lifecycle, physical or cognitive owner
was introduced. Observer remains a projection.

All failed staged starts remove the staged probes through the existing World
lifecycle API and verify their absence from both entity indexes. Civilization
candidates are discarded. Unverifiable rollback sets the existing physical
hard-failure latch. Transient Core entity allocation remains monotonic; this
increment does not rewind a global allocator. Exact rollback here means no
candidate session, bindings, custody, terrain mutation or residual probe.

## Bounded placement and capacities

| Boundary | Normal profile | Historical/global policy |
| --- | --- | --- |
| Founder count | 20–30; measured baseline 24 | Three-agent start retained |
| Population capacity | 30 | Default 8 and global ceiling unchanged |
| Placement | N+1 safe cells | Existing World search |
| Horizontal / vertical radius | 12 / 8 | Unchanged |
| Candidate evaluations | At most 12,000 | Unchanged |
| Body | Width 0.6, height 1.8 | Existing probe embodiment |
| Founder / reserved separation | 2 / 2 horizontal blocks | Legacy selected separation stays 1 |
| Egress / maximum drop | At least 1 / at most 1 | Existing Core assessments |
| Household transitions per tick | 30 | Default stays 16; global ceiling unchanged |
| Active households / retained households / memberships | 64 / 256 / 2,048 | Unchanged |
| Causal events | 8,192; no loss during startup accepted | Existing bounded ledger |
| Genetics / homeostasis profiles | 256 / 256 | Unchanged |
| Mortality transitions | Existing limit 8 | Explicitly outside this increment |

No terrain is flattened, planted, cleared or made safe by mutation. Insufficient
safe positions (including reception) cause explicit refusal. Two-block founder
spacing prevents another newly staged founder from occupying a selected
founder's cardinal egress cell. Player and foreign entity collisions remain
Core-owned checks.

Population scaling is not activated by founder startup, including when its
feature gate is available. Thus every initial founder receives ordinary full
cognition. Existing explicit scaling experiments and their tests retain their
semantics; no higher rendered-population guarantee is added.

## Persistence and observation boundary

The existing durable session/checkpoint codec and restore validation are used
without a schema change. No founder input is stored as a second roster. The
restored population, active agent order and expected physical probe IDs must
match exactly. Observer's existing default maximum of 64 exposes every founder;
a smaller configured bound explicitly reports omitted individuals. The live
Observer population label now counts visible plus explicitly omitted people,
instead of incorrectly reporting zero when population scaling is inactive.

This does not implement Save/Continue menu UX, automatic World/civilization
coordination, arbitrary evolved live restart or crash recovery. Existing
checkpoint commands remain responsible for their current World reconciliation
contract. The complete PS01 Save/Continue experience remains a later increment.

## Validation and limits

The first focused run failed with 7 passed / 1 failed. Its exact assertion was
`founder campaign unexpected error: kinship(invalid kinship configuration: state bounds or ordering)`.
The original log remains `runs/ps01-increment01/evidence/focused.log`.
Kinship generated historical people by numeric ordinal, required lexical
AgentID ordering during validation, and sorted only afterward. The narrow
correction moves those existing sorts before validation. AgentID Comparable,
identity spelling, ordinal assignment and the initialization digest expression
remain unchanged. Existing valid historical three-founder ordering is identical.

The second focused run advanced past kinship and failed with 6 passed / 1 failed:
`founder campaign unexpected error: dependentCare(dependent care requires survival)`.
Its log is `focused-02-care-ordering-fail.log`. Survival initialization now
precedes care, as required by the existing care owner; no care rule changed.

The final focused command passed **65/65 assertions**, exit 0:

```sh
PEBBLELAB_SMOKE_ONLY=founder-bootstrap \
PEBBLELAB_FOUNDER_EVIDENCE_DIR=runs/ps01-increment01/evidence/focused-final \
.build/release/pebsmoke
```

It proves 20/24/30 identity and ordinal integrity, canonical ordering, domain
composition, deterministic repeated initialization, exact checkpoint restore,
read-only Observer and explicit truncation, four full cognition ticks for every
founder, duplicate/noncontiguous identity refusal, missing/overlapping placement
refusal, population/household transition/history/causal capacity refusal, all
eleven late authority failures and legacy three-founder population compatibility.
The kernel accepts count 19 within an explicit capacity; the normal product
rejects 19 and 31 before any session is active in each successful live scenario.

After the focused PASS, `swift build -c release --product Pebble` succeeded.
Both `scripts/verify-pebblelab-live.sh --dry-run` and the founder harness dry-run
were inspected before the live campaign:

```sh
python3 scripts/verify-pebblelab-ps01-founders.py --dry-run
python3 scripts/verify-pebblelab-ps01-founders.py \
  --output runs/ps01-increment01/evidence/live-final
```

The campaign passed **18/18 scenarios**. Every process exited 0; every final
boundary is inactive with zero residual probes. The ordinary runs omit both
`PEBBLELAB_DISPOSABLE_WORLD_PROOF` and `PEBBLE_NEWWORLD_NAME`, preserving
ordinary World rules as well as natural terrain. Only explicit injected-fault
runs arm disposable proof guards.

| Scenario | Seed / actual startup anchor | Published agents / probes | Result |
| --- | --- | --- | --- |
| normal-20 | 46 / 8,76,-112 | 20 / 20 | PASS |
| normal-24 | 46 / 8,76,-112 | 24 / 24 | PASS |
| normal-30 | 887 / -64,95,32 | 30 / 30 | PASS |
| unavailable | 12345 / 4096,200,4096 | 0 / 0 | PASS: 0/25 safe cells; 10,625/12,000 evaluations; chunkUnavailable |
| late-probe | 46 | 0 / 0 | PASS: 23 staged probes removed |
| dependency | 46 | 0 / 0 | PASS: households require missing kinship; 24 staged probes removed |
| legacy-three | 46 | 3 / 3 | PASS: historical `/lab start`, clean stop |
| late-population | 46 | 0 / 0 | PASS: 24 staged probes removed |
| late-lifecycle | 46 | 0 / 0 | PASS: 24 staged probes removed |
| late-kinship | 46 | 0 / 0 | PASS: 24 staged probes removed |
| late-household | 46 | 0 / 0 | PASS: 24 staged probes removed |
| late-dependentCare | 46 | 0 / 0 | PASS: 24 staged probes removed |
| late-childhood | 46 | 0 / 0 | PASS: 24 staged probes removed |
| late-family | 46 | 0 / 0 | PASS: 24 staged probes removed |
| late-mortality | 46 | 0 / 0 | PASS: 24 staged probes removed |
| late-homeostasis | 46 | 0 / 0 | PASS: 24 staged probes removed |
| late-genetics | 46 | 0 / 0 | PASS: 24 staged probes removed |
| late-verification | 46 | 0 / 0 | PASS: 24 staged probes removed |

All three normal populations remain scaling-inactive. Their ordinary observed
checkpoints show nine observations and nine goal selections for every founder;
all have runtimeErrors=0 and clean stop removes exactly N probes. Their initial
checkpoint load reuses the exact probe set and retains the semantic digest.
Observer reports population N without durable mutation. No resources or terrain
fixture is present. Per-stage fault logs identify the exact injected owner,
verified physical rollback and no partial session publication. No successful
rollback sets the hard-failure latch.

Representative 24-founder bootstrap/observed and 30-founder observed captures
were inspected. They show actual inhabitants on natural plains/slope and
windswept-hills terrain, consistent with the structured identity and support
checks. The existing follow camera shows a subset of inhabitants; screenshots
are not the evidence for the full roster. Expected active-session refusal text
remains visible in the diagnostic overlay. No initialization visual anomaly was
identified. The natural cow in the seed-887 view is ordinary World fauna, not a
founder fixture. No Pebble process remained after the campaign.

Observer's population label was separately reviewed: the projection takes a
canonical prefix of current session agents and explicitly counts omitted
agents. Thus visible + omitted equals the current population for both scaled
and unscaled sessions. The focused suite checks bounds 64 and 4 for 20/24/30;
existing `observer` checks a truncated 2-of-3 view, and `civ-39` checks a scaled
24-person projection and unchanged durable bytes. No roster/schema was added.

The following owning selectors all passed, exit 0. Each exact command is
`PEBBLELAB_SMOKE_ONLY=<selector> .build/release/pebsmoke`; complete output and
command/accounting records are in `evidence/regressions`.

| Selector | Passed | Failed |
| --- | ---: | ---: |
| `safe-entity-placement` | 18 | 0 |
| `candidate-physical-atomicity` | 3 | 0 |
| `population-migration` | 66 | 0 |
| `lifecycle` | 80 | 0 |
| `kinship` | 79 | 0 |
| `households` | 71 | 0 |
| `dependent-care` | 55 | 0 |
| `childhood-guardianship` | 62 | 0 |
| `unions-family-lineages-houses` | 83 | 0 |
| `mortality` | 93 | 0 |
| `homeostasis-health` | 30 | 0 |
| `genetics-development` | 46 | 0 |
| `observer` | 20 | 0 |
| `checkpoint-replay` | 49 | 0 |
| `persistence-reconciliation` | 19 | 0 |
| `civ-39` | 69 | 0 |
| `autonomous-civilization` | 36 | 0 |
| `bounded-autonomous-navigation` | 26 | 0 |
| `autonomous-interaction-retry-liveness` | 17 | 0 |
| `productive-source-lifecycle` | 22 | 0 |
| `role-neutral-society-bootstrap` | 3 | 0 |

Total: **21 selectors, 947 passed, 0 failed**. `lifecycle` includes age,
maturity and reproduction; `civ-39` includes scaling, scaled mortality,
Observer and persistence. The autonomous suites retain their historical
three-founder fixtures.

Canonical gate: `scripts/verify-pebblelab.sh` passed **35/35 steps**,
**4843/4843 assertions**, exit 0. No regold or golden regeneration was used.
The complete output and deterministic scenario outputs are retained in the
review evidence. Final `git diff --check` and source-freeze hash checks passed.

The complete baseline diff and new files were reviewed for ownership,
transaction ordering, bounds and compatibility. Product code was frozen after
the 18/18 live PASS. Nine product files, three test/proof files and this phase
document are necessary; no unnecessary file was retained. No P0, P1 or P2
finding was identified within Increment 01's bounded contract. This is a local
implementation review, not independent reviewer approval.

Commands, complete output, machine-readable checkpoint/Observer evidence and
fault traces are retained under `runs/ps01-increment01/evidence`. The review ZIP
includes exact candidate Git metadata, complete diff, changed files,
source, relevant contracts and a SHA-256 manifest. Build caches and generated
World databases are excluded.

The existing mortality limit above eight simultaneous lethal transitions is
still a whole-slice blocker. This increment claims no long-duration emergence,
ecological balance, guaranteed survival, Save/Continue product UX, whole-simulation
Pause/Play correction, acceleration, culture/economy activation, later PS01 work
or Wave-6/CIV-48 work.

Push attempted: NO.
