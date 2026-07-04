# Phase 5.14A — Agents Basic Goal Apply Planning

## 1. Purpose

Phase 5.14A prepares the first real, guarded goal application into
`agents_basic`. Phase 5.13B and Phase 5.13C proved candidate-only eligibility:
the fixtures can identify when a validated fake-live goal candidate would apply
to an `agents_basic` agent, but they deliberately did not mutate the real
`agents_basic` state.

The next proof must not be another dry run. Phase 5.14B must implement the
opt-in scenario `agents_basic_goal_apply_guarded_fixture_smoke` and must
produce `appliedToAgentsBasic > 0`.

## 2. Starting Point

Phase 5.13C validated
`agents_basic_goal_integration_guarded_hardening_smoke` with this candidate-only
boundary:

- `agentsBasicApplyEligible = 3`;
- `wouldApplyToAgentsBasic = 3`;
- `appliedToAgentsBasic = 0`;
- `agentsBasicGoalWouldChange = 17`;
- `rejected = 16`;
- `deferred = 1`;
- `agentsBasicTouched = false`;
- `runtimeBehaviorChanged = false`;
- `memoryMutated = false`;
- `movementStackUsed = false`;
- `worldMutated = false`;
- `terrainMutated = false`;
- `digest = 701e6b3c6278c27a`.

## 3. Problem To Solve

`would apply` is no longer sufficient evidence. The useful next proof is a real,
bounded mutation of `LabAgent.currentGoal` in an opt-in scenario.

That mutation must be visible in `agents_basic`, but it must be limited to the
`currentGoal` field of targeted agents. Phase 5.14B must not execute actions,
produce movement, call the movement stack, write memory, or mutate `World` or
terrain.

## 4. Strategic Anti-Overengineering Rule

After 5.14A, do not add another candidate-only bridge before the first guarded
apply. Phase 5.14B must implement
`agents_basic_goal_apply_guarded_fixture_smoke` and produce
`appliedToAgentsBasic > 0`.

Phase 5.14C may harden the apply after 5.14B proves the first real bounded
application, but 5.14C must not be used to postpone the initial apply.

## 5. Future 5.14B Scenario Contract

Mandatory scenario name:

- `agents_basic_goal_apply_guarded_fixture_smoke`

Scenario nature:

- runtime fixture;
- strict opt-in;
- deterministic;
- single-purpose;
- no normal `agents_basic` behavior change outside the scenario;
- no action execution;
- no movement stack;
- no World mutation;
- no terrain mutation;
- no memory mutation;
- no selectedAction application;
- no behavior loop multi-pass;
- no route following;
- no pathfinding live.

## 6. Future Apply Ownership

The future implementation should live in `LabAgentsBasicGoalApply.swift` or a
minimal dedicated extension, not as broad new logic in `main.swift`.
`main.swift` should remain only a dispatcher and output writer.

`LabScenarios.swift` may provide or reuse the `agents_basic` agents.
`LabAgent.currentGoal` is the only mutable target field.

Forbidden future apply mutations:

- needs;
- memory;
- position;
- lastAction;
- lastActionEffect;
- lastMovement;
- inventory;
- `World`;
- terrain;
- physical placeholders;
- Core entities.

## 7. Future 5.14B Data Flow

The future 5.14B flow should be:

```text
agents_basic initial state
-> read candidate decisions from guarded integration fixture semantics
-> select eligible decisions
-> locate matching LabAgent by agentId
-> record agentsBasicGoalBefore
-> apply currentGoal = targetGoal for eligible bounded decisions only
-> record agentsBasicGoalAfter
-> count appliedToAgentsBasic
-> count agentsBasicGoalChanged
-> prove no other fields changed
-> emit report/metrics/events/digest
-> fail if any forbidden mutation flag is true
```

## 8. Future 5.14B Proposed Types

Proposed types, not implemented in 5.14A:

- `LabAgentsBasicGoalApplyPolicy`;
- `LabAgentsBasicGoalApplyInput`;
- `LabAgentsBasicGoalApplyDecision`;
- `LabAgentsBasicGoalApplyReport`;
- `LabAgentsBasicGoalApplyInvariantReport`;
- `LabAgentsBasicGoalApplyDigest`;
- `LabAgentsBasicGoalApplyMetrics`.

Minimum `LabAgentsBasicGoalApplyPolicy` fields:

- `applyMode`;
- `allowAgentsBasicGoalApply`;
- `allowedGoals`;
- `maxAgentsBasicGoalApplicationsPerTick`;
- `requireDedicatedScenario`;
- `requireWouldApplyToAgentsBasic`;
- `requireAgentsBasicApplyEligible`;
- `requireNoRejectedReasons`;
- `requireNoDeferredReasons`;
- `requireReason`;
- `allowNoopGoal`;
- `preserveMemory`;
- `preserveMovement`;
- `preserveWorld`;
- `preserveTerrain`.

Minimum `LabAgentsBasicGoalApplyInput` fields:

- `tick`;
- `agentId`;
- `agentsBasicGoalBefore`;
- `targetGoal`;
- `agentsBasicGoalAfterCandidate`;
- `agentsBasicApplyEligible`;
- `wouldApplyToAgentsBasic`;
- `priorAppliedToAgentsBasic`;
- `priorRejectedReasons`;
- `priorDeferredReasons`;
- `dedicatedScenario`;
- `policy`;
- `reason`.

Minimum `LabAgentsBasicGoalApplyDecision` fields:

- `tick`;
- `agentId`;
- `agentFound`;
- `agentsBasicGoalBefore`;
- `targetGoal`;
- `agentsBasicGoalAfter`;
- `agentsBasicGoalChanged`;
- `agentsBasicApplyEligible`;
- `wouldApplyToAgentsBasic`;
- `appliedToAgentsBasic`;
- `runtimeBehaviorChanged`;
- `rejectedReasons`;
- `deferredReasons`;
- `applyMode`;
- `success`.

## 9. Future 5.14B Apply Rules

Apply only if:

- `dedicatedScenario = true`;
- policy `allowAgentsBasicGoalApply = true`;
- `agentFound = true`;
- `agentsBasicApplyEligible = true`;
- `wouldApplyToAgentsBasic = true`;
- target goal is known;
- target goal is allowed;
- `agentsBasicGoalBefore != targetGoal`;
- prior rejected reasons are empty;
- prior deferred reasons are empty;
- prior `appliedToAgentsBasic` is false;
- reason is non-empty;
- max applications are not exceeded.

No-op rule:

- if `agentsBasicGoalBefore == targetGoal`, `allowNoopGoal = true` may accept
  the input as an audited no-op;
- `appliedToAgentsBasic = false`;
- `agentsBasicGoalChanged = false`.

Reject if:

- missing agent;
- missing current goal;
- missing target goal;
- unknown target goal;
- target not allowed;
- `wouldApplyToAgentsBasic = false`;
- `agentsBasicApplyEligible = false`;
- prior rejected reasons;
- prior deferred reasons;
- prior applied;
- `dedicatedScenario = false`;
- policy disallows;
- missing reason;
- max applications exceeded;
- no-op disallowed.

## 10. Future 5.14B Required Metrics

Required metric prefix:

- `agentsBasicGoalApply*`

Minimum metrics:

- `agentsBasicGoalApplySuccess`;
- `agentsBasicGoalApplyAgents`;
- `agentsBasicGoalApplyInputs`;
- `agentsBasicGoalApplyDecisions`;
- `agentsBasicGoalApplyEligible`;
- `agentsBasicGoalApplyWouldApply`;
- `agentsBasicGoalApplyApplied`;
- `agentsBasicGoalApplyGoalChanged`;
- `agentsBasicGoalApplyNoops`;
- `agentsBasicGoalApplyRejected`;
- `agentsBasicGoalApplyDeferred`;
- `agentsBasicGoalApplyRuntimeBehaviorChanged`;
- `agentsBasicGoalApplyMemoryMutated`;
- `agentsBasicGoalApplyMovementStackUsed`;
- `agentsBasicGoalApplyWorldMutated`;
- `agentsBasicGoalApplyTerrainMutated`;
- `agentsBasicGoalApplyBounded`;
- `agentsBasicGoalApplyDeterministicOrder`;
- `agentsBasicGoalApplyDigestsEqual`;
- `agentsBasicGoalApplyRepeatabilityFailures`.

## 11. Future 5.14B Required Events

Required aggregate event:

- `lab_agents_basic_goal_apply_recorded`

Minimum fields:

- `success`;
- `agents`;
- `inputs`;
- `decisions`;
- `appliedToAgentsBasic`;
- `agentsBasicGoalChanged`;
- `rejected`;
- `deferred`;
- `runtimeBehaviorChanged`;
- `memoryMutated`;
- `movementStackUsed`;
- `worldMutated`;
- `terrainMutated`;
- `bounded`;
- `deterministicOrder`;
- `digestsEqual`;
- `repeatabilityFailures`.

Optional simple decision event:

- `lab_agents_basic_goal_apply_decision_recorded`

## 12. Future 5.14B Required Outputs

Required `--out` files:

- `agents_basic_goal_apply_report.json`;
- `agents_basic_goal_apply_invariant_report.json`;
- `agents_basic_goal_apply_inputs.json`;
- `agents_basic_goal_apply_decisions.json`;
- `agents_basic_goal_apply_before_after.json`;
- `agents_basic_goal_apply_digest.json`;
- `metrics.json`;
- `events.ndjson`.

## 13. Future 5.14B Success Contract

`runSuccess` may be true only if:

- `report.success = true`;
- `invariantReport.success = true`;
- `inputs > 0`;
- `decisions = inputs`;
- `appliedToAgentsBasic > 0`;
- `agentsBasicGoalChanged > 0`;
- `appliedToAgentsBasic == agentsBasicGoalChanged` for non-noop applied
  decisions;
- `runtimeBehaviorChanged = true`;
- `runtimeBehaviorChangedReason = controlledGoalApplyOnly`, or an equivalent
  explicit audit value;
- `memoryMutated = false`;
- `movementStackUsed = false`;
- `worldMutated = false`;
- `terrainMutated = false`;
- no position changed;
- no needs changed;
- no inventory changed;
- no memory count changed;
- no `lastAction` changed;
- no `lastActionEffect` changed;
- no `lastMovement` changed;
- no physical placeholder moved;
- no Core entity moved;
- `deterministicOrder = true`;
- `digestsEqual = true`;
- `repeatabilityFailures = 0`;
- metrics are present;
- event is present;
- outputs are written.

## 14. Boundary Snapshot Requirements

Phase 5.14B must compare before/after snapshots for every targeted agent.

Allowed mutation:

- `currentGoal` only.

Forbidden mutations:

- position;
- needs;
- health;
- fear;
- homePosition;
- inventory;
- observation;
- nearbyAgents;
- lastAction;
- lastActionEffect;
- lastMovement;
- memory;
- ticksAlive unless the scenario explicitly does not tick agents;
- movement counters;
- action counters;
- `World`;
- terrain;
- physical bridge;
- core entity bridge.

Recommendation: for 5.14B, do not run the normal `agents_basic` tick loop after
applying the goal. The scenario should be a controlled apply fixture, not a
behavior run.

## 15. Relationship With agents_basic

Phase 5.14B may reuse `makeBasicAgents` or construct an `agents_basic`
equivalent fixture state. It must remain opt-in and must not alter the default
`agents_basic` scenario.

Normal `agents_basic` must still pass non-regression after the apply scenario
is added. This apply is not the full cognitive loop. It only proves that a
validated goal candidate can become real agent `currentGoal` state under guard.

## 16. Relationship With Movement Stack

Changing `currentGoal` is not movement.

Forbidden in 5.14B:

- no movement stack call;
- no movement intent;
- no route following;
- no pathfinding live;
- no reservation runtime;
- no dynamic replanning;
- no approved movement application.

## 17. Relationship With Memory

Phase 5.14B must not write memory.

Forbidden:

- no live memory write;
- no memory update call;
- no cognitive memory feedback loop;
- no emotional memory;
- no social memory.

## 18. Relationship With World / Terrain

Phase 5.14B must not mutate `World` or terrain. Prefer no `World` mutation at
all.

If `makeBasicAgents` requires `World` construction for spawn positions, that
setup must be treated as scenario initialization only, not an apply effect. The
report must distinguish setup from apply mutation.

## 19. main.swift Debt Audit

`main.swift` currently acts as a giant scenario router. Do not refactor it
before 5.14B because the priority is first applied `agents_basic` goal evidence.
After 5.14B or 5.14C, schedule a small router cleanup planning phase.

Possible future phase names:

- Phase 5.14D - Roadmap and Scenario Router Debt Audit;
- Phase 5.R1 - PebbleLab Scenario Router Cleanup Planning.

Future cleanup goal:

- inventory scenarios;
- classify worldless and worldful scenarios;
- move scenario dispatch/output writing into smaller helpers;
- avoid a risky broad refactor before behavioral proof.

## 20. Roadmap Warning

`ROADMAP.md` is currently more up to date than
`PHASE_5_COGNITIVE_AGENT_RESYNC_PLAN.md` for Phase 5.13C. Phase 5.14A should
resynchronize `PHASE_5_COGNITIVE_AGENT_RESYNC_PLAN.md` with a short
5.13B/5.13C/5.14A section, without rewriting the whole roadmap.

Do not perform a broad historical rewrite.

## 21. Non-Goals

- no Swift runtime changes;
- no scenario implementation;
- no `agents_basic` runtime apply yet;
- no selected action;
- no movement stack;
- no route following;
- no pathfinding live;
- no World mutation;
- no terrain mutation;
- no memory mutation;
- no mood;
- no relationships;
- no trust;
- no communication;
- no community;
- no Python;
- no LLM;
- no embeddings;
- no RL;
- no renderer/shader/resource changes;
- no registry changes;
- no save/load changes;
- no goldens;
- no `PEBBLE_REGOLD`.

## 22. Definition of Done For 5.14A

- New document `PHASE_5_14A_AGENTS_BASIC_GOAL_APPLY_PLAN.md` created.
- `CHANGELOG.md` updated.
- `DEV_JOURNAL.md` updated with date 2026-07-03 or current local date if
  different.
- `ROADMAP.md` updated:
  - Phase 5.14A marked implemented as docs-only planning.
  - Next recommended step set to Phase 5.14B - Agents Basic Goal Apply Guarded
    Fixture Smoke.
  - Explicitly state 5.14B must produce `appliedToAgentsBasic > 0`.
- `PHASE_5_COGNITIVE_AGENT_RESYNC_PLAN.md` lightly resynced.
- `PHASE_5_13A_AGENTS_BASIC_GOAL_INTEGRATION_PLAN.md` updated with "Next
  Apply Planning" or equivalent section.
- No Swift files changed.
- No runtime scenario added.
- No metrics/events implemented in runtime.
- No renderer/shader/resource/registry/save-load/golden changes.
- `git diff --check` passes.
- `git diff --cached --check` passes.
- Commit created locally.

## Phase 5.14B Implementation Status

Phase 5.14B implemented the planned runtime fixture:

- scenario: `agents_basic_goal_apply_guarded_fixture_smoke`;
- implementation owner: `Sources/PebbleLab/LabAgentsBasicGoalApply.swift`;
- fixture shape: compact worldless `agents_basic`-equivalent state with five
  deterministic `LabAgent` values;
- real applies: `agent_0 idle -> seekSafety`,
  `agent_1 idle -> explore`, and `agent_2 idle -> observeOtherAgent`;
- no-op: `agent_3 explore -> explore`, accepted as audited no-op with
  `appliedToAgentsBasic=false`;
- rejected: `agent_4` unknown target, with `appliedToAgentsBasic=false`;
- result: `appliedToAgentsBasic=3`, `agentsBasicGoalChanged=3`,
  `runtimeBehaviorChanged=true`, and
  `runtimeBehaviorChangedReason=controlledGoalApplyOnly`;
- allowed mutation: `LabAgent.currentGoal` fields only;
- forbidden mutations: memory, movement stack, World, terrain, position, needs,
  inventory, lastAction, lastActionEffect, lastMovement, memory count, counters,
  physical placeholders, and Core entities remain unchanged.

Phase 5.14B is not candidate-only and not dry-run-only. The next recommended
phase is Phase 5.14C - Agents Basic Goal Apply Hardening.

## Phase 5.14C Implementation Status

Phase 5.14C implemented the hardening scenario planned after the first guarded
apply:

- scenario: `agents_basic_goal_apply_hardening_smoke`;
- owner: `Sources/PebbleLab/LabAgentsBasicGoalApply.swift`;
- shape: worldless, opt-in, deterministic hardening fixture;
- coverage: 28 cases, 20 inputs, and 20 decisions;
- real applies: three successful `LabAgent.currentGoal` changes to
  `seekSafety`, `explore`, and `observeOtherAgent`;
- result: `appliedToAgentsBasic=3`, `agentsBasicGoalChanged=3`,
  `agentsBasicGoalNoops=1`, `rejectedAgentsBasicGoalApplies=16`,
  `deferredAgentsBasicGoalApplies=0`;
- runtime audit: `runtimeBehaviorChanged=true` only for controlled goal apply,
  with `runtimeBehaviorChangedReason=controlledGoalApplyOnly`;
- boundaries: rejected decisions and no-op decisions do not mutate snapshots;
  applied decisions mutate only `currentGoal` fields; memory, movement stack,
  World, terrain, position, needs, inventory, lastAction, lastActionEffect,
  lastMovement, memory count, counters, physical placeholders, and Core
  entities remain unchanged;
- outputs: hardening report, invariant report, cases, inputs, decisions,
  before/after, digest, `metrics.json`, and `events.ndjson`;
- events: `lab_agents_basic_goal_apply_hardening_recorded`, decision events,
  and case events.

Phase 5.14C hardens the bounded apply bridge. It is still not the full
cognitive loop and does not call selected actions, movement, memory, pathing,
World mutation, or terrain mutation.

Recommended next step: Phase 5.14D - Roadmap and Scenario Router Debt Audit,
kept as a small docs-only/planning-only inventory of `main.swift` router debt
before any risky broad cleanup.
