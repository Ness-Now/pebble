# Phase 5.14D — Roadmap and Scenario Router Debt Audit

## 1. Purpose

Phase 5.14D is a short audit pause after the first real guarded
`agents_basic` goal apply evidence from 5.14B and the hardening evidence from
5.14C.

The purpose is to prevent `main.swift`, scenario routing, and the roadmap docs
from becoming blocking debt before the first visible `agents_basic` cognitive
loop smoke. This phase does not refactor `main.swift`, does not change runtime
behavior, does not add a scenario, and does not create a new abstraction layer.

The intended decision after this audit is simple: proceed to Phase 5.15A -
`agents_basic` Cognitive Loop Smoke Planning, unless this audit identifies a
clear structural blocker. It does not.

## 2. Starting Point

Phase 5.14B produced the first real controlled apply into an
`agents_basic`-equivalent worldless fixture:

- scenario: `agents_basic_goal_apply_guarded_fixture_smoke`;
- `appliedToAgentsBasic = 3`;
- `agentsBasicGoalChanged = 3`;
- `runtimeBehaviorChanged = true`;
- `runtimeBehaviorChangedReason = controlledGoalApplyOnly`.

Phase 5.14C hardened that apply path:

- scenario: `agents_basic_goal_apply_hardening_smoke`;
- 28 cases;
- 28 passed;
- 20 inputs;
- 20 decisions;
- `appliedToAgentsBasic = 3`;
- `agentsBasicGoalChanged = 3`;
- `agentsBasicGoalNoops = 1`;
- `rejectedAgentsBasicGoalApplies = 16`;
- `deferredAgentsBasicGoalApplies = 0`;
- digest `d14fe26adf8e1071`;
- invariant report success true with 75 checks passed and 0 failed.

The important strategic fact is now acquired: `appliedToAgentsBasic > 0`.
The allowed mutation for this milestone is still only `LabAgent.currentGoal`.
No movement stack, memory write, World mutation, or terrain mutation is part of
the apply proof.

## 3. Why This Audit Exists

`main.swift` has become a giant scenario router. The problem is not that the
current code is broken; the problem is that each new fixture currently tends to
touch the same broad routing surface:

- `supportedScenarios` is a long flat list in `LabScenarios.swift`;
- `LabOptions.usage()` repeats that long scenario list for CLI help;
- worldless/worldful behavior is encoded by accumulating many boolean flags;
- tick-loop skipping is another accumulating condition;
- `runSuccess` includes a long chain of optional scenario success gates;
- output writing for reports, invariant reports, digests, metrics, and events
  is centralized and dispersed through `main.swift`;
- metrics dispatch is a long precedence chain that writes `metrics.json`.

Adding Phase 5.15 directly without naming this debt risks making the next
cognitive milestone harder to review. At the same time, a broad refactor now
would be riskier than the debt: 5.15A only needs planning, and the first
runtime-facing 5.15 smoke should stay narrow. The right move is to record the
debt, avoid a rewrite, and keep the next product milestone focused.

## 4. Scope

In scope:

- inventory the routing debt;
- classify existing scenarios by broad families;
- distinguish worldless, worldful, read-only world, mutation candidate,
  movement-stack fixture, and cognitive fixture shapes;
- identify dangerous `main.swift` zones;
- propose a minimal cleanup trajectory;
- recommend the next real milestone, Phase 5.15A.

Out of scope:

- refactor;
- runtime change;
- new scenarios;
- new Swift abstraction;
- runtime metrics or events;
- movement stack changes;
- pathfinding changes;
- memory writes;
- World or terrain mutation;
- LLM, Python, or RL;
- mood, relationships, trust, communication, or social-system runtime.

## 5. Current Scenario Families

The classification below is deliberately practical rather than perfect. Its
goal is to guide future routing decisions, not to rewrite the history of every
phase.

| Family | Examples | World mode | Mutation allowed | Current state | Main risk |
| --- | --- | --- | --- | --- | --- |
| Core smoke / world smoke | `empty`, `chunk_smoke`, `regression_smoke` | worldful or minimal | normal smoke setup only | stable | baseline metrics can hide routing drift |
| Abstract agents | `agent_smoke`, `agents_basic`, `seek_safety_smoke`, `long_run_smoke` | worldful setup with abstract agents | normal abstract agent tick behavior | stable | normal runtime changes can regress broad metrics |
| Physical bridge / Core entity bridge | `physical_placeholder_smoke`, `physical_sync_smoke`, `core_entity_smoke`, `physical_behavior_smoke` | worldful | controlled placeholder/Core bridge mutation | validated | accidental persistence, registry, or entity movement coupling |
| Terrain / collision / pathfinding fixtures | `terrain_scan_smoke`, `terrain_column_scan_smoke`, `terrain_pathfinding_fixture_smoke`, `terrain_collision_live_readonly_smoke` | mixed worldless and read-only world | read-only unless explicitly fixture-only synthetic | validated | mixing read-only evidence with mutation or live movement |
| Movement stack fixtures | `agent_movement_stack_contract_fixture_smoke`, `bounded_path_planning_fixture_smoke`, `multi_agent_movement_tick_hardening_smoke` | mostly worldless | fixture-local value-state mutation only | validated | accidentally calling live movement, reservations, or pathfinding |
| Behavior loop fixtures | `behavior_loop_contract_fixture_smoke`, `behavior_loop_hardening_smoke` | worldless | controlled fixture-local behavior summaries and bounded memory in that layer | validated | confusing fixture memory evidence with live memory writes |
| Memory update/retrieval fixtures | `memory_update_hardening_smoke`, `memory_retrieval_hardening_smoke` | worldless | memory update fixtures write controlled fixture memory; retrieval is read-only | validated | rerunning retrieval/update in live agents without a guard |
| Goal selection fixtures | `goal_selection_from_memory_fixture_smoke`, `goal_selection_from_memory_hardening_smoke` | worldless | selected-goal proposals, not live `agents_basic` mutation | validated | confusing proposals with applied runtime goal state |
| Cognitive loop fixtures | `cognitive_loop_integration_fixture_smoke`, `cognitive_loop_integration_hardening_smoke` | worldless | fixture-local orchestration evidence | validated | becoming a hidden live loop if connected too quickly |
| Live adapter / controlled application | `live_cognitive_loop_adapter_fixture_smoke`, `live_cognitive_loop_controlled_application_fixture_smoke` | worldless live-like fixtures | tightly gated dry-run or controlled fixture application | validated | applying selected actions or memory writes outside the contract |
| Goal application layers | `goal_application_dry_run_fixture_smoke`, `goal_application_snapshot_mutation_fixture_smoke`, `live_goal_application_guarded_fixture_smoke`, `fake_live_goal_application_hardening_smoke` | worldless | staged from dry-run to guarded fake-live mutation | validated | adding another bridge instead of integrating productively |
| `agents_basic` integration | `agents_basic_goal_integration_guarded_fixture_smoke`, `agents_basic_goal_integration_guarded_hardening_smoke` | worldless | candidate-only, no `agents_basic` mutation | validated | returning to candidate-only work after apply was already proven |
| `agents_basic` goal apply | `agents_basic_goal_apply_guarded_fixture_smoke`, `agents_basic_goal_apply_hardening_smoke` | worldless | `LabAgent.currentGoal` only | validated | over-hardening apply instead of moving to cognitive loop planning |
| Future `agents_basic` cognitive loop | future 5.15 smoke | likely worldless or setup-only first | must be explicitly planned | not started | accidentally running full society or normal runtime mutation |

## 6. Worldless / Worldful Routing Audit

The current routing pattern uses many booleans to decide whether `world` is
created or nil. Many fixture scenarios are explicitly worldless and should not
construct `World` at all. Some scenarios need World setup for spawn positions,
chunk readiness, read-only terrain observations, physical placeholders, or Core
entity probes. Other scenarios read generated World evidence but must not
mutate terrain as part of their tested behavior.

The next 5.15 runtime-facing scenario should probably remain worldless or
setup-only at first. The first goal is a visible `agents_basic` cognitive loop
contract, not World interaction.

| Scenario family | World mode | Output mode | Mutation permissions | Risk |
| --- | --- | --- | --- | --- |
| Core/world smoke | worldful or minimal | shared metrics/events | normal setup/tick smoke | broad regression surface |
| Abstract agents | worldful setup | shared agent metrics/events | normal abstract tick mutation | behavior drift in `agents_basic` |
| Physical/Core bridge | worldful | dedicated reports plus shared metrics | controlled bridge mutation | persistence or entity coupling |
| Terrain read-only | worldful read-only | reports/invariants/metrics/events | no terrain mutation | confusing setup chunks with apply effects |
| Synthetic terrain/path fixtures | worldless | dedicated fixture outputs | fixture-local values only | accidentally requiring live World |
| Movement stack fixtures | mostly worldless | dedicated fixture outputs | fixture-local movement state only | accidental live stack application |
| Cognitive fixtures | worldless | dedicated reports/traces/digests | fixture-local cognitive state | hidden live-agent mutation |
| Goal application layers | worldless | dedicated apply outputs | staged, guarded goal mutation only where explicit | repeated bridge layers |
| `agents_basic` apply | worldless | dedicated apply/hardening outputs | `currentGoal` only | over-hardening after proof |
| Future 5.15 | worldless or setup-only first | dedicated cognitive-loop smoke outputs | must be planned | full runtime loop too early |

## 7. main.swift Debt

Observed debt:

- many top-level `let isScenario...` booleans;
- a long `world = nil` condition for worldless fixture scenarios;
- a separate long tick-loop skip condition;
- scenario fixture construction scattered across `main.swift`;
- `runSuccess` gated by a long chain of optional success values;
- output writing for dedicated reports and events centralized in one huge block;
- `metrics.json` selection implemented as a long precedence chain;
- every new scenario requires touching several distant sections;
- it is hard to see which scenarios write which outputs;
- it is hard to guarantee boundary rules by family rather than by individual
  hand-added booleans;
- `LabOptions.usage()` and `supportedScenarios` duplicate the scenario list in
  a way that makes omissions easy.

Do not refactor this before a minimal plan exists. Also do not do a broad
rewrite. The debt is real, but it is not blocking Phase 5.15A planning.

## 8. Minimal Cleanup Path

Only use this path if the router starts blocking useful work. Keep it to two or
three small phases at most.

### Phase 5.R1 — Scenario Inventory and Routing Contract Docs

- docs-only or very light tests;
- finalize scenario family classification;
- define a possible future `ScenarioDescriptor` shape;
- define world mode, output mode, and mutation mode terms;
- do not modify runtime behavior.

### Phase 5.R2 — PebbleLab Scenario Routing Helpers

- small Swift refactor only;
- extract world mode and scenario family helpers;
- keep existing behavior byte-for-byte or report-for-report compatible;
- do not change scenario outputs;
- `swift build`, scenario spot checks, and `pebsmoke` required.

### Phase 5.R3 — Output Writer Helper Consolidation

- only if still necessary after R2;
- consolidate repeated report/invariant/digest/metrics/event writes;
- keep filenames and JSON payloads unchanged;
- no semantic change.

Do not launch R1/R2/R3 automatically. The priority after 5.14D remains 5.15A.

## 9. Next Productive Milestone

Recommended milestone:

Phase 5.15A — `agents_basic` Cognitive Loop Smoke Planning.

Objective: prepare a visible, bounded `agents_basic` cognitive-loop smoke where
one short chain can be audited:

```text
perception/read-only or fixture state
-> retrieval or memory seed
-> goal selection
-> guarded currentGoal apply
-> optional action decision dry-run only
-> memory update fixture only or clearly gated
-> human-readable summary
```

Phase 5.15A should not:

- launch a full society;
- add communication;
- add mood;
- add relationships;
- add live movement stack integration;
- mutate World or terrain;
- connect LLM, Python, or RL.

## 10. Recommended Next Step

Recommended next phase after 5.14D:

Phase 5.15A — `agents_basic` Cognitive Loop Smoke Planning.

Alternative only if router risk becomes too high:

Phase 5.R1 — PebbleLab Scenario Routing Contract Planning.

Do not recommend a new Phase 5.14E goal apply hardening phase. The apply path
has already produced real applied evidence and hardening evidence.

## 11. Anti-Overengineering Rule

Phase 5.14D must not create a new chain of router-planning phases unless a
concrete runtime blocker is found.

The next runtime-facing milestone should be an `agents_basic` cognitive loop
smoke, planned first by Phase 5.15A.

## 12. Definition of Done

- New document
  `PHASE_5_14D_ROADMAP_SCENARIO_ROUTER_DEBT_AUDIT.md` created.
- `ROADMAP.md` updated:
  - 5.14B and 5.14C remain validated;
  - 5.14D docs-only audit added;
  - next recommended milestone is 5.15A.
- `DEV_JOURNAL.md` updated with the current date.
- `CHANGELOG.md` updated.
- `PHASE_5_COGNITIVE_AGENT_RESYNC_PLAN.md` lightly resynchronized.
- `PHASE_5_14A_AGENTS_BASIC_GOAL_APPLY_PLAN.md` updated with 5.14B, 5.14C,
  and 5.14D status.
- No Swift files changed.
- No runtime scenario added.
- No runtime metric or event added.
- No renderer, shader, resource, registry, save/load, or golden changed.
- `git diff --check` passes.
- `git diff --cached --check` passes.
- Local commit created.

## Phase 5.15A Status

Phase 5.15A followed this audit recommendation and created
`PHASE_5_15A_AGENTS_BASIC_COGNITIVE_LOOP_SMOKE_PLAN.md`.

The 5.15A plan keeps router cleanup out of the immediate path. It accepts a
small future `main.swift` addition for 5.15B if necessary, while recommending
that the cognitive-loop implementation itself live in a dedicated future file,
`Sources/PebbleLab/LabAgentsBasicCognitiveLoop.swift`.

No structural router blocker was found. The next expected phase remains Phase
5.15B - `agents_basic` Cognitive Loop Fixture Smoke. Phase 5.R1 should be used
only if adding 5.15B produces concrete router risk that blocks the smoke.

5.15B must be runtime-facing, must not be docs-only, must not be only
candidate-only, and must produce a visible cognitive trace.
