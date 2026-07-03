# Phase 5.13A — Agents Basic Goal Integration Planning

## Purpose

Phase 5.13A defines the contract for a controlled integration layer toward
`agents_basic`.

This layer consumes a validated fake-live goal application where:

- `appliedToFakeLive=true`;
- `fakeLiveGoalChanged=true`;
- `appliedToAgentsBasic=0`;
- `agentsBasicTouched=false`;
- `liveRuntimeTouched=false`;
- rejected reasons are empty;
- deferred reasons are empty.

It produces an `agents_basic` integration plan:

- `agentsBasicGoalBefore`;
- `targetGoal`;
- `agentsBasicGoalAfterCandidate`;
- `integrationMode`;
- `agentsBasicApplyEligible`;
- `wouldApplyToAgentsBasic`;
- `appliedToAgentsBasic=false` in Phase 5.13B;
- `agentsBasicTouched=false` in Phase 5.13B;
- `runtimeBehaviorChanged=false`;
- complete audit evidence.

This phase is planning-only. It adds no Swift runtime, no scenario, no runtime
metrics, no runtime events, no `LabAgent` mutation path, no `agents_basic`
integration, no movement stack call, no World mutation, no terrain mutation,
no mood, no relationships, no communication, no Python, no LLM, no embeddings,
and no RL.

## Starting Point

Phase 5.12B and Phase 5.12C created and hardened fake-live goal application in
`LabFakeLiveGoalApplication.swift`.

The current fake-live layer can already apply goal transitions to
scenario-owned fake-live state:

- `appliedToFakeLive` is covered;
- `fakeLiveGoalChanged` is covered;
- fake-live no-op is covered;
- rejected and deferred decisions are covered;
- `appliedToAgentsBasic=0`;
- `agentsBasicTouched=false`;
- `liveRuntimeTouched=false`;
- `memoryMutated=false`;
- `movementStackUsed=false`;
- `worldMutated=false`;
- `terrainMutated=false`;
- hardening covers 29 cases and deterministic digest repeatability.

`agents_basic` remains unchanged. Phase 5.13A prepares only the contract for a
future guarded bridge from fake-live proof to an `agents_basic` candidate.

## Current Fake-Live Goal Application State

`LabFakeLiveGoalApplication.swift` currently owns the fake-live goal
application fixtures.

Current policies are represented by `LabFakeLiveGoalApplicationPolicy`:

- `applyMode`;
- `allowFakeLiveGoalApplication`;
- `allowedGoals`;
- `maxFakeLiveGoalApplicationsPerTick`;
- `requireWouldApplyToLive`;
- `requireNoRejectedReasons`;
- `requireNoDeferredReasons`;
- `requireAgentsBasicUntouched`;
- `requireReason`;
- `allowNoopGoal`;
- `allowDeferred`.

Current inputs are represented by `LabFakeLiveGoalApplicationInput`:

- `tick`;
- `agentId`;
- `fakeLiveGoalBefore`;
- `targetGoal`;
- `liveGoalAfterCandidate`;
- `wouldApplyToLive`;
- `priorAppliedToLive`;
- `priorRejectedReasons`;
- `priorDeferredReasons`;
- `agentsBasicTouchedBefore`;
- `guardedDecisionSummary`;
- `policy`;
- `reason`.

Current decisions are represented by `LabFakeLiveGoalApplicationDecision`:

- `tick`;
- `agentId`;
- `fakeLiveGoalBefore`;
- `targetGoal`;
- `fakeLiveGoalAfter`;
- `fakeLiveGoalChanged`;
- `fakeLiveApplyEligible`;
- `fakeLiveWouldChange`;
- `appliedToFakeLive`;
- `appliedToAgentsBasic`;
- `agentsBasicTouched`;
- `liveRuntimeTouched`;
- `rejectedReasons`;
- `deferredReasons`;
- `applyMode`;
- `success`.

Current reports count policies, inputs, decisions, fake-live eligibility,
would-change decisions, applied-to-fake-live count, fake-live goal changes,
no-ops, rejected applications, deferred applications, applied-to-agents-basic
count, `agentsBasicTouched`, `liveRuntimeTouched`, boundary flags, bounded
shape, deterministic order, digest equality, and repeatability failures.

Current limitations:

- no goal is applied to `agents_basic`;
- no normal runtime agent is mutated;
- no selected action is applied;
- no memory is written;
- no movement intent is produced;
- World and terrain remain untouched.

## Problem To Solve

Fake-live application is not `agents_basic` integration.

Problems to solve before implementation:

- `agents_basic` is the current normal runtime scenario;
- connecting it too early can change global behavior and regress existing
  validations;
- a new eligibility layer must sit between fake-live proof and any normal
  runtime candidate;
- `wouldApplyToAgentsBasic` and `appliedToAgentsBasic` must stay separate;
- the first implementation must remain candidate-only;
- action execution, movement, memory writes, World mutation, and terrain
  mutation must be impossible;
- existing `agents_basic` mechanics must remain stable until a later explicitly
  guarded apply phase.

## Agents Basic Goal Integration Contract V0

Input:

- fake-live goal application decision;
- `agents_basic` goal view or proxy;
- `targetGoal`;
- `integrationMode`;
- policy;
- `allowAgentsBasicGoalIntegration`;
- `requireAppliedToFakeLive`;
- `requireFakeLiveGoalChanged`;
- `requireNoRejectedReasons`;
- `requireNoDeferredReasons`;
- `requireAgentsBasicUntouched`;
- `requireLiveRuntimeUntouched`;
- `requireReason`;
- `maxAgentsBasicGoalApplicationsPerTick`.

Output:

- `agents_basic` goal integration decision;
- `agentsBasicGoalBefore`;
- `targetGoal`;
- `agentsBasicGoalAfterCandidate`;
- `agentsBasicGoalWouldChange`;
- `agentsBasicApplyEligible`;
- `wouldApplyToAgentsBasic`;
- `appliedToAgentsBasic`;
- `agentsBasicTouched`;
- `runtimeBehaviorChanged`;
- rejected reasons;
- deferred reasons;
- deterministic digest.

Important v0 rule: Phase 5.13B should produce guarded candidates only.
`appliedToAgentsBasic` must remain false and `agentsBasicTouched` must remain
false.

## Proposed Types For Future Implementation

These types are proposed for Phase 5.13B or later. They are not implemented in
Phase 5.13A.

### `LabAgentsBasicGoalIntegrationPolicy`

Suggested fields:

- `integrationMode`;
- `allowAgentsBasicGoalIntegration`;
- `allowedGoals`;
- `maxAgentsBasicGoalApplicationsPerTick`;
- `requireAppliedToFakeLive`;
- `requireFakeLiveGoalChanged`;
- `requireNoRejectedReasons`;
- `requireNoDeferredReasons`;
- `requireAgentsBasicUntouched`;
- `requireLiveRuntimeUntouched`;
- `requireReason`;
- `requireDedicatedScenario`;
- `dedicatedScenario`;
- `allowNoopGoal`;
- `allowDeferred`.

Purpose: define whether a fake-live goal application can become an
`agents_basic` integration candidate.

### `LabAgentsBasicGoalIntegrationInput`

Suggested fields:

- `tick`;
- `agentId`;
- `agentsBasicGoalBefore`;
- `fakeLiveGoalAfter`;
- `targetGoal`;
- `appliedToFakeLive`;
- `fakeLiveGoalChanged`;
- `appliedToAgentsBasicBefore`;
- `agentsBasicTouchedBefore`;
- `liveRuntimeTouchedBefore`;
- `priorRejectedReasons`;
- `priorDeferredReasons`;
- `fakeLiveDecisionSummary`;
- `policy`;
- `reason`.

Purpose: carry one candidate request derived from a fake-live goal application
decision.

### `LabAgentsBasicGoalIntegrationDecision`

Suggested fields:

- `tick`;
- `agentId`;
- `agentsBasicGoalBefore`;
- `targetGoal`;
- `agentsBasicGoalAfterCandidate`;
- `agentsBasicGoalWouldChange`;
- `agentsBasicApplyEligible`;
- `wouldApplyToAgentsBasic`;
- `appliedToAgentsBasic`;
- `agentsBasicTouched`;
- `runtimeBehaviorChanged`;
- `rejectedReasons`;
- `deferredReasons`;
- `integrationMode`;
- `success`.

Purpose: record the guarded `agents_basic` candidate without mutating the
normal runtime.

### `LabAgentsBasicGoalIntegrationReport`

Suggested fields:

- `scenario`;
- `seed`;
- `agents`;
- `ticks`;
- `policies`;
- `inputs`;
- `decisions`;
- `agentsBasicApplyEligible`;
- `wouldApplyToAgentsBasic`;
- `appliedToAgentsBasic`;
- `agentsBasicGoalWouldChange`;
- `agentsBasicNoops`;
- `rejectedAgentsBasicIntegrations`;
- `deferredAgentsBasicIntegrations`;
- `agentsBasicTouched`;
- `runtimeBehaviorChanged`;
- `memoryMutated`;
- `movementStackUsed`;
- `worldMutated`;
- `terrainMutated`;
- `bounded`;
- `deterministicOrder`;
- `digest`;
- `digestRepeat`;
- `digestsEqual`;
- `repeatabilityFailures`;
- `success`.

Purpose: summarize the candidate-only bridge and prove no normal runtime
behavior changed.

## Agents Basic Integration Modes V0

Modes:

- `agents_basic_goal_integration_audit_only`;
- `agents_basic_goal_integration_guarded_dry_run`;
- `agents_basic_goal_integration_candidate_only`;
- future `agents_basic_goal_apply_guarded`.

For Phase 5.13B, the required recommended mode is:

- `agents_basic_goal_integration_guarded_dry_run`.

Phase 5.13B must not apply to `agents_basic`. It should only produce
`wouldApplyToAgentsBasic` and candidate audit evidence.

## Eligibility Rules V0

`agents_basic` integration can become `wouldApplyToAgentsBasic` only if:

- `appliedToFakeLive=true`;
- `fakeLiveGoalChanged=true`;
- `targetGoal` is known;
- `targetGoal` is in `allowedGoals`;
- `agentsBasicGoalBefore != targetGoal`;
- `appliedToAgentsBasicBefore=false`;
- `agentsBasicTouchedBefore=false`;
- `liveRuntimeTouchedBefore=false`;
- prior rejected reasons are empty;
- prior deferred reasons are empty;
- reason is non-empty;
- policy `allowAgentsBasicGoalIntegration=true`;
- dedicated scenario flag is true;
- `maxAgentsBasicGoalApplicationsPerTick` is respected.

Reject if:

- `appliedToFakeLive=false`;
- `fakeLiveGoalChanged=false` for non-noop;
- `targetGoal` is unknown;
- `targetGoal` is not allowed;
- `agentsBasicGoalBefore` is missing;
- `targetGoal` is missing;
- `appliedToAgentsBasicBefore=true`;
- `agentsBasicTouchedBefore=true`;
- `liveRuntimeTouchedBefore=true`;
- prior rejected reasons are non-empty;
- prior deferred reasons are non-empty;
- reason is missing;
- policy disallows `agents_basic` integration;
- dedicated scenario flag is false;
- max `agents_basic` goal applications are exceeded.

Defer if:

- `integrationMode` is audit-only;
- `agents_basic` state is ambiguous but not invalid;
- policy `allowDeferred=true`.

No-op if:

- `agentsBasicGoalBefore == targetGoal`;
- `allowNoopGoal=true`;
- `appliedToAgentsBasic=false`;
- `agentsBasicTouched=false`.

## Applied Rules V0

For Phase 5.13B:

- `wouldApplyToAgentsBasic` can be true;
- `appliedToAgentsBasic=false` always;
- `agentsBasicTouched=false` always;
- `runtimeBehaviorChanged=false` always;
- `memoryMutated=false`;
- `movementStackUsed=false`;
- `worldMutated=false`;
- `terrainMutated=false`.

Even when `wouldApplyToAgentsBasic=true`, the normal runtime must remain
unchanged.

## Relationship With Fake-Live Goal Application

Agents basic goal integration consumes outputs from
`LabFakeLiveGoalApplication`. It does not replace fake-live application.

The fake-live layer remains responsible for proving the target transition on
scenario-owned fake-live state. The agents-basic integration layer only turns
that proof into a guarded candidate for the normal runtime.

## Relationship With `agents_basic`

`agents_basic` remains unchanged in Phase 5.13B.

No normal runtime agent should be touched. No behavior should change unless a
future guarded apply phase explicitly allows it and proves the change is
isolated, deterministic, and reversible through audit evidence.

## Relationship With Movement Stack

Changing a candidate goal is not movement.

There must be:

- no movement intent;
- no route following;
- no reservation;
- no pathfinding;
- no movement stack call;
- no World mutation.

## Relationship With Memory Writes

Agents basic goal integration planning does not write memory.

Future memory audit of `agents_basic` goal transitions can be planned later,
but Phase 5.13B must not write live memory, mutate memory entries, call memory
update, or create a feedback loop.

## Relationship With Mood / Relations / LLM

Agents basic goal integration is a narrow state transition bridge.

Mood, emotional memory, relationships, trust, communication, community state,
Python, LLM, embeddings, and RL remain out of scope.

## Future Metrics Contract

Metrics prefix:

`agentsBasicGoalIntegration*`

Proposed metrics:

- `agentsBasicGoalIntegrationSuccess`;
- `agentsBasicGoalIntegrationAgents`;
- `agentsBasicGoalIntegrationTicks`;
- `agentsBasicGoalIntegrationPolicies`;
- `agentsBasicGoalIntegrationInputs`;
- `agentsBasicGoalIntegrationDecisions`;
- `agentsBasicGoalIntegrationEligible`;
- `agentsBasicGoalIntegrationWouldApply`;
- `agentsBasicGoalIntegrationApplied`;
- `agentsBasicGoalIntegrationGoalWouldChange`;
- `agentsBasicGoalIntegrationNoops`;
- `agentsBasicGoalIntegrationRejected`;
- `agentsBasicGoalIntegrationDeferred`;
- `agentsBasicGoalIntegrationAgentsBasicTouched`;
- `agentsBasicGoalIntegrationRuntimeBehaviorChanged`;
- `agentsBasicGoalIntegrationMemoryMutated`;
- `agentsBasicGoalIntegrationMovementStackUsed`;
- `agentsBasicGoalIntegrationWorldMutated`;
- `agentsBasicGoalIntegrationTerrainMutated`;
- `agentsBasicGoalIntegrationBounded`;
- `agentsBasicGoalIntegrationDeterministicOrder`;
- `agentsBasicGoalIntegrationDigestsEqual`;
- `agentsBasicGoalIntegrationRepeatabilityFailures`.

## Future Events Contract

Primary future event:

`lab_agents_basic_goal_integration_recorded`

Minimum fields:

- `success`;
- `agentId`;
- `tick`;
- `agentsBasicGoalBefore`;
- `targetGoal`;
- `agentsBasicGoalAfterCandidate`;
- `agentsBasicGoalWouldChange`;
- `agentsBasicApplyEligible`;
- `wouldApplyToAgentsBasic`;
- `appliedToAgentsBasic`;
- `agentsBasicTouched`;
- `runtimeBehaviorChanged`;
- `rejectedReasons`;
- `deferredReasons`;
- `integrationMode`.

Optional summary event:

`lab_agents_basic_goal_integration_summary_recorded`

Fields:

- `success`;
- `agents`;
- `ticks`;
- `inputs`;
- `decisions`;
- `agentsBasicApplyEligible`;
- `wouldApplyToAgentsBasic`;
- `appliedToAgentsBasic`;
- `agentsBasicGoalWouldChange`;
- `noops`;
- `rejected`;
- `deferred`;
- `agentsBasicTouched`;
- `runtimeBehaviorChanged`;
- `bounded`;
- `digestsEqual`;
- `repeatabilityFailures`.

## Future Invariant Contract

Minimum checks for Phase 5.13B:

- scenario name expected;
- seed recorded;
- report success;
- agents expected;
- inputs positive;
- decisions positive;
- agents-basic eligibility covered;
- `wouldApplyToAgentsBasic` covered;
- `agentsBasicGoalWouldChange` covered;
- no-op covered;
- rejected covered;
- deferred covered if implemented;
- `appliedToAgentsBasic` zero;
- `agents_basic` not touched;
- runtime behavior unchanged;
- memory not mutated;
- movement stack not used;
- no World mutation;
- no terrain mutation;
- `agentsBasicGoalBefore` / `targetGoal` /
  `agentsBasicGoalAfterCandidate` audited;
- rejected reasons present;
- deferred reasons present;
- bounded true;
- deterministic order;
- digest repeat equals digest;
- repeatability failures zero;
- report written;
- invariant report written;
- policies written;
- inputs written;
- decisions written;
- digest written;
- metrics written;
- event written.

## Recommended Phase 5.13B

`Phase 5.13B — Agents Basic Goal Integration Guarded Fixture Smoke`

Probable new scenario:

`agents_basic_goal_integration_guarded_fixture_smoke`

Objective: create a fixture that takes fake-live goal decisions and produces
`agents_basic` integration candidates while keeping `agents_basic` unchanged.

The fixture should:

- create 6 to 10 `agents_basic` integration inputs;
- cover `agentsBasicApplyEligible`;
- cover `wouldApplyToAgentsBasic`;
- cover `agentsBasicGoalWouldChange`;
- cover no-op;
- cover rejected target unknown / not allowed;
- cover rejected `appliedToFakeLive=false`;
- cover rejected `fakeLiveGoalChanged=false`;
- cover rejected `agentsBasicTouchedBefore=true`;
- cover rejected `liveRuntimeTouchedBefore=true`;
- cover rejected prior rejected/deferred reasons;
- cover deferred audit-only if simple;
- keep `appliedToAgentsBasic=0`;
- keep `agentsBasicTouched=false`;
- keep `runtimeBehaviorChanged=false`;
- keep `memoryMutated=false`;
- not call movement stack;
- not mutate World;
- remain deterministic.

Future outputs:

- `agents_basic_goal_integration_report.json`;
- `agents_basic_goal_integration_invariant_report.json`;
- `agents_basic_goal_integration_policies.json`;
- `agents_basic_goal_integration_inputs.json`;
- `agents_basic_goal_integration_decisions.json`;
- `agents_basic_goal_integration_digest.json`;
- `metrics.json`;
- `events.ndjson`.

## Risks

- confusing candidate integration with real apply;
- mutating `agents_basic` too early;
- changing normal runtime behavior;
- forgetting `appliedToAgentsBasic=0`;
- triggering movement stack from goal integration;
- writing transition memory too early;
- depending on non-deterministic ordering;
- growing `main.swift` instead of keeping orchestration thin.

## Explicit Out Of Scope

- no `agents_basic` live application;
- no uncontrolled live agent mutation;
- no applied actions;
- no applied memory writes;
- no live memory update;
- no World mutation;
- no movement stack;
- no route following;
- no action intent emission;
- no iterative cognitive loop;
- no mood;
- no emotional memory;
- no relationships;
- no trust;
- no communication;
- no community;
- no construction;
- no mining;
- no Python;
- no LLM;
- no embeddings;
- no RL;
- no save/load changes;
- no renderer changes.

## Definition Of Done For 5.13A

- Document created.
- Changelog updated.
- Dev journal updated.
- Roadmap updated.
- Cognitive resync plan updated if useful.
- 5.12A fake-live goal application plan updated if useful.
- No Swift files changed.
- No runtime behavior changed.
- No scenarios added.
- `swift build` passes if possible.
- `swift build -c release --product Pebble` passes.
- `git diff --check` passes.
- Next phase 5.13B is clearly specified.

## Phase 5.13B Implementation Status

Phase 5.13B implemented the planned guarded fixture:

- scenario: `agents_basic_goal_integration_guarded_fixture_smoke`;
- policies: guarded dry-run, no-op, target allow-list, audit-only, and max
  application rejection;
- inputs: safety/explore candidates, no-op, unknown target, target not allowed,
  missing fake-live application, missing fake-live goal change, prior
  `agents_basic` application, prior `agents_basic` touch, prior runtime touch,
  prior rejected/deferred reasons, audit-only deferred, missing reason, max
  applications, and missing dedicated scenario flag;
- decisions: candidate-only `agentsBasicApplyEligible`,
  `wouldApplyToAgentsBasic`, `agentsBasicGoalWouldChange`, no-op, rejected, and
  deferred coverage;
- candidate-only integration: `wouldApplyToAgentsBasic` can be true, but
  `appliedToAgentsBasic` remains zero;
- boundary flags: `agentsBasicTouched=false`,
  `runtimeBehaviorChanged=false`, `memoryMutated=false`,
  `movementStackUsed=false`, `worldMutated=false`, and
  `terrainMutated=false`;
- report: `agents_basic_goal_integration_report.json`;
- invariant: `agents_basic_goal_integration_invariant_report.json`;
- digest: `agents_basic_goal_integration_digest.json`;
- metrics: `agentsBasicGoalIntegration*`;
- events: `lab_agents_basic_goal_integration_recorded` plus summary event;
- limitations: no `agents_basic` live application, no action application, no
  memory write, no movement stack, no World or terrain mutation;
- next phase: Phase 5.13C - Agents Basic Goal Integration Guarded Hardening.
