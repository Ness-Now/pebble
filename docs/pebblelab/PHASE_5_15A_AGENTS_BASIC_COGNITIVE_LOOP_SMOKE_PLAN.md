# Phase 5.15A — agents_basic Cognitive Loop Smoke Planning

## 1. Purpose

Phase 5.15A prepares the first `agents_basic` scenario where a small cognitive
chain is visible, deterministic, and auditable.

This phase is docs-only. It does not implement a runtime scenario, does not
modify Swift, does not add metrics or events, and does not refactor
`main.swift`.

PebbleLab has now moved beyond simple `wouldApply` evidence. Phase 5.14B
proved a real guarded `LabAgent.currentGoal` apply, and Phase 5.14C hardened
that apply. Phase 5.15A uses that evidence to plan the first bounded
`agents_basic` cognitive-loop smoke.

## 2. Starting Point

Phase 5.14B:

- proved real guarded `currentGoal` apply in
  `agents_basic_goal_apply_guarded_fixture_smoke`;
- produced `appliedToAgentsBasic = 3`;
- produced `agentsBasicGoalChanged = 3`;
- set `runtimeBehaviorChanged = true` only for
  `controlledGoalApplyOnly`;
- allowed only `LabAgent.currentGoal` mutation.

Phase 5.14C:

- hardened the apply path in `agents_basic_goal_apply_hardening_smoke`;
- covered 28 passing cases;
- produced 20 inputs and 20 decisions;
- preserved memory, movement stack, World, terrain, position, needs,
  inventory, lastAction, lastActionEffect, lastMovement, memory count, counters,
  physical placeholders, and Core entities.

Phase 5.14D:

- audited `main.swift` and scenario-router debt;
- found real debt, but no structural blocker for 5.15A;
- recommended Phase 5.15A as the next productive milestone;
- kept routing cleanup as an alternative only if router risk becomes concrete.

The `main.swift` debt is real but not blocking this planning phase or the first
narrow 5.15B smoke.

## 3. Product Goal

The future product milestone is a short scenario where an `agents_basic` or
`agents_basic`-equivalent agent passes through a readable cognitive chain:

- initial state;
- perception or fixture state;
- memory seed or controlled retrieval;
- goal candidate;
- guarded `currentGoal` apply;
- action decision dry-run only;
- optional fixture-only memory update;
- human-readable summary.

The goal is not to create a society. It is not to create general intelligence.
It is to make the cognitive chain readable, testable, bounded, and honest.

## 4. Future Scenario Name

Recommended Phase 5.15B scenario:

- `agents_basic_cognitive_loop_fixture_smoke`

Possible future hardening scenario:

- `agents_basic_cognitive_loop_hardening_smoke`

Do not plan too far ahead. Do not create a ladder of
5.15B-candidate-only -> 5.15C-apply -> 5.15D-hardening. The first runtime
scenario in 5.15B must already traverse a complete, bounded mini cognitive
chain and produce a visible cognitive trace.

## 5. Future 5.15B Scenario Contract

Phase 5.15B must be:

- runtime fixture;
- strict opt-in;
- deterministic;
- worldless or setup-only;
- single-tick or bounded few-tick;
- no normal `agents_basic` behavior change outside the scenario;
- no movement stack;
- no route following;
- no live pathfinding;
- no World mutation;
- no terrain mutation;
- no Core entity mutation;
- no physical placeholder mutation;
- no communication;
- no mood;
- no relationships;
- no trust;
- no LLM, Python, or RL.

Allowed future mutation in 5.15B:

- either no live mutation except a guarded `currentGoal` apply;
- or fixture-local memory update only, clearly separated from live
  `LabAgent.memory`.

Recommendation: 5.15B should use a worldless `agents_basic`-equivalent fixture
first. If it uses `makeBasicAgents`, any World setup must be scenario
initialization only, not part of cognitive mutation.

## 6. Future Cognitive Chain

Future 5.15B flow:

```text
agents_basic-equivalent initial state
-> deterministic perception / fixture observation summary
-> deterministic memory seed or retrieval input
-> goal candidate selection using existing goal-selection semantics
-> guarded apply using 5.14B/5.14C apply semantics
-> action decision dry-run only, not applied
-> optional memory update fixture record only
-> cognitive trace
-> report / invariant report / metrics / events / digest
```

Action decision dry-run means:

- propose action name and reason;
- do not set `lastAction`;
- do not call `decideAction`;
- do not call `applyLastActionEffect`;
- do not call `applyAbstractMovement`;
- do not move the agent;
- do not mutate needs, fear, or state;
- do not call the movement stack.

## 7. Future 5.15B Ownership

Future implementation should use a dedicated file:

- `Sources/PebbleLab/LabAgentsBasicCognitiveLoop.swift`

That file should own:

- scenario constants;
- policy;
- input;
- trace steps;
- report;
- invariant report;
- metrics;
- digest;
- event encoders;
- fixture builder.

`main.swift` should only dispatch the fixture and write outputs. Do not place
the cognitive-loop logic in `main.swift`.

## 8. Future Types

Proposed types, not implemented in 5.15A:

- `LabAgentsBasicCognitiveLoopPolicy`;
- `LabAgentsBasicCognitiveLoopInput`;
- `LabAgentsBasicCognitiveLoopAgentSnapshot`;
- `LabAgentsBasicCognitiveLoopPerceptionStep`;
- `LabAgentsBasicCognitiveLoopMemoryStep`;
- `LabAgentsBasicCognitiveLoopGoalCandidateStep`;
- `LabAgentsBasicCognitiveLoopGoalApplyStep`;
- `LabAgentsBasicCognitiveLoopActionDryRunStep`;
- `LabAgentsBasicCognitiveLoopMemoryUpdateStep`;
- `LabAgentsBasicCognitiveLoopTrace`;
- `LabAgentsBasicCognitiveLoopReport`;
- `LabAgentsBasicCognitiveLoopInvariantReport`;
- `LabAgentsBasicCognitiveLoopDigest`;
- `LabAgentsBasicCognitiveLoopMetrics`;
- `LabAgentsBasicCognitiveLoopFixture`.

Minimum policy fields:

- `cognitiveLoopMode`;
- `requireDedicatedScenario`;
- `allowGoalCandidateSelection`;
- `allowGuardedCurrentGoalApply`;
- `allowActionDryRun`;
- `allowFixtureMemoryUpdate`;
- `allowLiveMemoryWrite`;
- `allowMovement`;
- `allowMovementStack`;
- `allowWorldMutation`;
- `allowTerrainMutation`;
- `allowCommunication`;
- `allowMood`;
- `allowRelationships`;
- `allowedGoals`;
- `maxAgents`;
- `maxTicks`;
- `maxGoalApplies`;
- `requireDeterministicOrder`;
- `requireHumanReadableSummary`.

Recommended policy values:

- `allowGoalCandidateSelection = true`;
- `allowGuardedCurrentGoalApply = true`;
- `allowActionDryRun = true`;
- `allowFixtureMemoryUpdate = true` or `false`, but explicit;
- `allowLiveMemoryWrite = false`;
- `allowMovement = false`;
- `allowMovementStack = false`;
- `allowWorldMutation = false`;
- `allowTerrainMutation = false`;
- `allowCommunication = false`;
- `allowMood = false`;
- `allowRelationships = false`.

## 9. Future Trace Requirements

Phase 5.15B must produce a readable trace per agent.

Minimum trace fields:

- `agentId`;
- `initialGoal`;
- `perceptionSummary`;
- `memorySeedSummary`;
- `retrievedMemorySummary`;
- `goalCandidate`;
- `goalCandidateReason`;
- `goalApplyBefore`;
- `goalApplyAfter`;
- `goalApplied`;
- `actionDryRunName`;
- `actionDryRunReason`;
- `memoryUpdateFixtureSummary`;
- `humanReadableSummary`;
- `forbiddenMutations`.

Example human summary:

```text
agent_0 saw low safety in fixture state, retrieved a safety memory, selected
seekSafety, applied currentGoal from idle to seekSafety, proposed
wait/move_abstract as dry-run only, and did not move or write live memory.
```

## 10. Future Outputs

Recommended 5.15B outputs:

- `agents_basic_cognitive_loop_report.json`;
- `agents_basic_cognitive_loop_invariant_report.json`;
- `agents_basic_cognitive_loop_inputs.json`;
- `agents_basic_cognitive_loop_traces.json`;
- `agents_basic_cognitive_loop_before_after.json`;
- `agents_basic_cognitive_loop_digest.json`;
- `agents_basic_cognitive_loop_summary.md`;
- `metrics.json`;
- `events.ndjson`.

`agents_basic_cognitive_loop_summary.md` is important. It should be readable by
a human and explain what the agents did cognitively without claiming more than
the fixture proves.

## 11. Future Metrics

Metric prefix:

- `agentsBasicCognitiveLoop*`

Minimum metrics:

- `agentsBasicCognitiveLoopSuccess`;
- `agentsBasicCognitiveLoopAgents`;
- `agentsBasicCognitiveLoopTicks`;
- `agentsBasicCognitiveLoopInputs`;
- `agentsBasicCognitiveLoopTraces`;
- `agentsBasicCognitiveLoopPerceptionSteps`;
- `agentsBasicCognitiveLoopMemoryRetrievalSteps`;
- `agentsBasicCognitiveLoopGoalCandidates`;
- `agentsBasicCognitiveLoopGoalApplies`;
- `agentsBasicCognitiveLoopActionDryRuns`;
- `agentsBasicCognitiveLoopFixtureMemoryUpdates`;
- `agentsBasicCognitiveLoopLiveMemoryWrites`;
- `agentsBasicCognitiveLoopMovements`;
- `agentsBasicCognitiveLoopMovementStackUsed`;
- `agentsBasicCognitiveLoopWorldMutated`;
- `agentsBasicCognitiveLoopTerrainMutated`;
- `agentsBasicCognitiveLoopCurrentGoalMutated`;
- `agentsBasicCognitiveLoopOnlyAllowedMutations`;
- `agentsBasicCognitiveLoopHumanSummaries`;
- `agentsBasicCognitiveLoopDeterministicOrder`;
- `agentsBasicCognitiveLoopDigestsEqual`;
- `agentsBasicCognitiveLoopRepeatabilityFailures`.

## 12. Future Events

Required future aggregate event:

- `lab_agents_basic_cognitive_loop_recorded`

Recommended trace event:

- `lab_agents_basic_cognitive_loop_trace_recorded`

Minimum aggregate fields:

- `success`;
- `agents`;
- `ticks`;
- `inputs`;
- `traces`;
- `goalCandidates`;
- `goalApplies`;
- `actionDryRuns`;
- `fixtureMemoryUpdates`;
- `liveMemoryWrites`;
- `movements`;
- `movementStackUsed`;
- `worldMutated`;
- `terrainMutated`;
- `currentGoalMutated`;
- `onlyAllowedMutations`;
- `humanSummaries`;
- `deterministicOrder`;
- `digestsEqual`;
- `repeatabilityFailures`.

## 13. Future Invariants

Phase 5.15B `runSuccess` may be true only if:

- `report.success = true`;
- `invariantReport.success = true`;
- `inputs > 0`;
- `traces = inputs`;
- `goalCandidates > 0`;
- `goalApplies > 0`;
- `actionDryRuns > 0`;
- `humanSummaries > 0`;
- `liveMemoryWrites = 0`;
- `movements = 0`;
- `movementStackUsed = false`;
- `worldMutated = false`;
- `terrainMutated = false`;
- `onlyAllowedMutations = true`;
- `currentGoalMutated = true` only through guarded apply;
- no position mutation;
- no needs mutation;
- no inventory mutation;
- no `lastAction` mutation;
- no `lastActionEffect` mutation;
- no `lastMovement` mutation;
- no live memory mutation;
- no counters mutation unless explicitly allowed and documented;
- `deterministicOrder = true`;
- `digestsEqual = true`;
- `repeatabilityFailures = 0`;
- outputs written;
- events written;
- metrics written;
- `summary.md` written.

## 14. Boundary Rules

Forbidden in 5.15B:

- no live movement;
- no movement stack call;
- no route following;
- no live pathfinding;
- no World mutation;
- no terrain mutation;
- no physical placeholder mutation;
- no Core entity mutation;
- no selectedAction application;
- no live memory write unless a later phase explicitly permits it;
- no communication;
- no mood;
- no relationships;
- no trust;
- no LLM;
- no Python;
- no RL;
- no embeddings;
- no full society.

## 15. Relationship With Existing Phases

Phase 5.15B should reuse existing proof boundaries:

- memory retrieval semantics from memory retrieval fixtures;
- goal selection semantics from goal selection and memory-goal bridge fixtures;
- guarded goal apply from 5.14B and 5.14C;
- action decision as dry-run only, without calling live `decideAction`;
- memory update as fixture-only or omitted in 5.15B if too risky.

Do not duplicate all logic if an existing helper can be reused cleanly. Also do
not branch the live cognitive loop too early. The first smoke should assemble a
small readable chain under guard, not make normal `agents_basic` autonomous.

## 16. Product Definition

A successful cognitive loop smoke is not:

- an autonomous intelligent agent;
- a society;
- a village;
- an LLM;
- a complete planner;
- a social simulation.

A successful cognitive loop smoke is:

- a deterministic trace;
- a readable chain;
- an explained goal decision;
- a guarded `currentGoal` apply;
- an action proposed but not applied;
- a human summary;
- proven boundaries.

## 17. Anti-Overengineering Rule

Do not create another long planning ladder before the first cognitive loop
smoke.

After 5.15A, the next expected phase is Phase 5.15B —
`agents_basic` Cognitive Loop Fixture Smoke.

Phase 5.15B must not be docs-only. It must not be only candidate-only. It must
produce a visible cognitive trace.

## 18. Relationship With Router Debt

Phase 5.14D identified router debt, but found no blocker for 5.15A. Phase
5.15A should not launch a router refactor.

For 5.15B, accept a small `main.swift` addition if necessary. If adding 5.15B
becomes too risky, then consider Phase 5.R1 — but only with concrete evidence
that router risk is blocking the cognitive-loop smoke.

## 19. Definition of Done For 5.15A

- New document
  `PHASE_5_15A_AGENTS_BASIC_COGNITIVE_LOOP_SMOKE_PLAN.md` created.
- `ROADMAP.md` updated:
  - 5.14D validated;
  - 5.15A docs-only planning added;
  - next recommended step is Phase 5.15B —
    `agents_basic` Cognitive Loop Fixture Smoke.
- `DEV_JOURNAL.md` updated with the current date.
- `CHANGELOG.md` updated.
- `PHASE_5_COGNITIVE_AGENT_RESYNC_PLAN.md` lightly updated.
- `PHASE_5_14D_ROADMAP_SCENARIO_ROUTER_DEBT_AUDIT.md` updated with 5.15A
  status.
- No Swift files changed.
- No runtime scenario added.
- No runtime metric or event added.
- No renderer, shader, resource, registry, save/load, or golden changed.
- `git diff --check` passes.
- `git diff --cached --check` passes.
- Local commit created.

## Phase 5.15B Status

Phase 5.15B implemented the planned runtime scenario:

- `agents_basic_cognitive_loop_fixture_smoke`.

It follows the 5.15A contract as a strict opt-in, worldless runtime fixture.
The fixture creates three `agents_basic`-equivalent agents and records one
readable cognitive trace per agent:

- fixture perception;
- fixture memory seed and retrieval summary;
- goal candidate;
- guarded `currentGoal` apply;
- action dry-run only;
- fixture-only memory update;
- human-readable summary.

The first three fixture paths are:

- `agent_0`: safety path, `idle -> seekSafety`;
- `agent_1`: curiosity path, `idle -> explore`;
- `agent_2`: social/observe path, `idle -> observeOtherAgent`.

Phase 5.15B keeps the promised boundaries: no live memory write, no movement,
no movement stack, no selected action application, no live observe, no route
following, no live pathfinding, no World mutation, no terrain mutation, no
physical placeholder or Core entity mutation, no mood, no relationships, no
communication, no Python, no LLM, no embeddings, and no RL.

The only live mutation is guarded `LabAgent.currentGoal`. The reported runtime
behavior change is explicit:

- `runtimeBehaviorChanged = true`;
- `runtimeBehaviorChangedReason = controlledCognitiveGoalApplyOnly`.

Recommended next phase after 5.15B: Phase 5.15C — `agents_basic` Cognitive
Loop Fixture Hardening.
