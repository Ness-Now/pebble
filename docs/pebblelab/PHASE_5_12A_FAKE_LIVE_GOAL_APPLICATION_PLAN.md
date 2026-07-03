# Phase 5.12A — Fake-Live Goal Application Planning

## Purpose

Phase 5.12A defines the contract for a fake-live goal application layer.

This layer consumes a guarded live goal application decision where:

- `liveApplyEligible=true`;
- `wouldApplyToLive=true`;
- `appliedToLive=false`;
- `liveAgentMutated=false`;
- `agentsBasicTouched=false`;
- `rejectedReasons` is empty;
- `deferredReasons` is empty.

It produces a controlled mutation on scenario-owned fake-live agent state:

- `fakeLiveGoalBefore`;
- `targetGoal`;
- `fakeLiveGoalAfter`;
- `fakeLiveGoalChanged`;
- `appliedToFakeLive`;
- `appliedToAgentsBasic=false`;
- `agentsBasicTouched=false`;
- `memoryMutated=false`;
- `movementStackUsed=false`;
- `worldMutated=false`;
- `terrainMutated=false`.

This phase is planning-only. It adds no Swift runtime, no scenario, no runtime
metrics, no runtime events, no `LabAgent` mutation path, no `agents_basic`
integration, no movement stack call, no World mutation, no terrain mutation,
no mood, no relationships, no communication, no Python, no LLM, no embeddings,
and no RL.

## Starting Point

Phase 5.11B and Phase 5.11C created and hardened guarded live goal
application candidates in `LabLiveGoalApplication.swift`.

The current guarded layer can already answer whether a validated snapshot
mutation should become a live goal application candidate:

- `liveApplyEligible` is covered;
- `wouldApplyToLive` is covered;
- live goal would-change is covered;
- no-op is covered;
- rejected and deferred decisions are covered;
- `appliedToLive=0`;
- `liveAgentMutated=false`;
- `memoryMutated=false`;
- `movementStackUsed=false`;
- `worldMutated=false`;
- `terrainMutated=false`;
- `agentsBasicTouched=false`;
- hardening covers 32 cases and deterministic digest repeatability.

It still applies nothing. Phase 5.12A prepares the first effective goal
mutation step, but only on scenario-owned fake-live state.

## Current Guarded Live Goal Application State

`LabLiveGoalApplication.swift` currently owns the guarded live goal
application fixtures.

Current policies are represented by `LabLiveGoalApplicationPolicy`:

- `applyMode`;
- `allowLiveGoalApplication`;
- `allowedGoals`;
- `maxLiveGoalApplicationsPerTick`;
- `requireSnapshotMutationApplied`;
- `requireLiveGoalStillMatchesOriginal`;
- `requireNoRejectedReasons`;
- `requireNoDeferredReasons`;
- `requireReason`;
- `requireDedicatedScenario`;
- `dedicatedScenario`;
- `allowNoopGoal`;
- `allowDeferred`.

Current inputs are represented by `LabLiveGoalApplicationInput`:

- `tick`;
- `agentId`;
- `liveGoalBefore`;
- `originalLiveGoalBefore`;
- `snapshotGoalAfter`;
- `targetGoal`;
- `appliedToSnapshot`;
- `snapshotGoalChanged`;
- `priorAppliedToLive`;
- `priorRejectedReasons`;
- `priorDeferredReasons`;
- `snapshotMutationSummary`;
- `policy`;
- `reason`.

Current decisions are represented by `LabLiveGoalApplicationDecision`:

- `tick`;
- `agentId`;
- `liveGoalBefore`;
- `targetGoal`;
- `liveGoalAfterCandidate`;
- `liveGoalWouldChange`;
- `liveApplyEligible`;
- `wouldApplyToLive`;
- `appliedToLive`;
- `liveAgentMutated`;
- `rejectedReasons`;
- `deferredReasons`;
- `applyMode`;
- `success`.

Current reports count policies, inputs, decisions, live eligibility,
would-apply decisions, applied-to-live count, live-goal-would-change
decisions, no-ops, rejected applications, deferred applications, boundary
flags, `agentsBasicTouched`, bounded shape, deterministic order, digest
equality, and repeatability failures.

Current limitations:

- no goal is applied to a true live `LabAgent`;
- no goal is applied to `agents_basic`;
- no selected action is applied;
- no memory is written;
- no movement intent is produced;
- World and terrain remain untouched.

## Problem To Solve

A guarded live candidate still does not test an effective mutation.

Problems to solve before implementation:

- mutating `agents_basic` remains too risky;
- the first effective mutation must target a fake-live agent owned by the
  scenario;
- fake-live state must be visibly distinct from snapshots, copied state, and
  normal runtime agents;
- before/after fake-live goal values must be audited;
- `appliedToFakeLive` and `appliedToAgentsBasic` must be separate;
- no-op, rejected, and deferred decisions must remain explicit;
- action application, memory writes, movement stack, World mutation, and
  terrain mutation must stay impossible;
- outputs must prove that `agents_basic` remains untouched.

## Fake-Live Goal Application Contract V0

Input:

- guarded live goal application decision;
- fake-live agent goal state;
- `targetGoal`;
- `applyMode`;
- policy;
- `allowFakeLiveGoalApplication`;
- `requireWouldApplyToLive`;
- `requireNoRejectedReasons`;
- `requireNoDeferredReasons`;
- `requireAgentsBasicUntouched`;
- `requireReason`;
- `maxFakeLiveGoalApplicationsPerTick`.

Output:

- fake-live goal application decision;
- `fakeLiveGoalBefore`;
- `targetGoal`;
- `fakeLiveGoalAfter`;
- `fakeLiveGoalChanged`;
- `appliedToFakeLive`;
- `appliedToAgentsBasic=false`;
- `agentsBasicTouched=false`;
- `liveRuntimeTouched=false`;
- `memoryMutated=false`;
- `movementStackUsed=false`;
- `worldMutated=false`;
- `terrainMutated=false`;
- rejected reasons;
- deferred reasons;
- deterministic digest.

Important v0 rule: "apply" in Phase 5.12B may mean applying to a
scenario-owned fake-live value only. It must never mean `agents_basic`,
normal `LabAgent` runtime state, selected action execution, movement, memory
write, World mutation, or terrain mutation.

## Proposed Types For Future Implementation

These types are proposed for Phase 5.12B or later. They are not implemented in
Phase 5.12A.

### `LabFakeLiveGoalApplicationPolicy`

Suggested fields:

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

Purpose: define whether a guarded live goal application candidate may mutate
scenario-owned fake-live goal state.

### `LabFakeLiveGoalApplicationInput`

Suggested fields:

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

Purpose: carry one fake-live goal application request derived from a guarded
live goal application decision.

### `LabFakeLiveGoalApplicationDecision`

Suggested fields:

- `tick`;
- `agentId`;
- `fakeLiveGoalBefore`;
- `targetGoal`;
- `fakeLiveGoalAfter`;
- `fakeLiveGoalChanged`;
- `appliedToFakeLive`;
- `appliedToAgentsBasic`;
- `agentsBasicTouched`;
- `liveRuntimeTouched`;
- `rejectedReasons`;
- `deferredReasons`;
- `applyMode`;
- `success`.

Purpose: record the audited fake-live mutation decision and boundary flags.

### `LabFakeLiveGoalApplicationReport`

Suggested fields:

- `scenario`;
- `seed`;
- `agents`;
- `ticks`;
- `policies`;
- `inputs`;
- `decisions`;
- `fakeLiveApplyEligible`;
- `fakeLiveWouldChange`;
- `appliedToFakeLive`;
- `fakeLiveGoalChanged`;
- `fakeLiveNoops`;
- `rejectedFakeLiveApplications`;
- `deferredFakeLiveApplications`;
- `appliedToAgentsBasic`;
- `agentsBasicTouched`;
- `liveRuntimeTouched`;
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

Purpose: summarize the fake-live application fixture without implying any
normal runtime mutation.

## Fake-Live Application Modes V0

Modes:

- `fake_live_goal_apply`;
- `fake_live_goal_audit_only`;
- `fake_live_goal_candidate_only`;
- future `guarded_agents_basic_goal_apply`.

For Phase 5.12B, the required recommended mode is:

- `fake_live_goal_apply`.

The term `apply` is allowed here only because the state is fake-live and
scenario-owned. It must never mean `agents_basic`.

## Eligibility Rules V0

Fake-live goal application can apply only if:

- `wouldApplyToLive=true`;
- `targetGoal` is known;
- `targetGoal` is in `allowedGoals`;
- `fakeLiveGoalBefore != targetGoal`;
- `priorAppliedToLive=false`;
- prior rejected reasons are empty;
- prior deferred reasons are empty;
- `agentsBasicTouchedBefore=false`;
- reason is non-empty;
- policy `allowFakeLiveGoalApplication=true`;
- `maxFakeLiveGoalApplicationsPerTick` is respected.

Reject if:

- `wouldApplyToLive=false`;
- `targetGoal` is unknown;
- `targetGoal` is not allowed;
- `fakeLiveGoalBefore` is missing;
- `targetGoal` is missing;
- `priorAppliedToLive=true`;
- prior rejected reasons are non-empty;
- prior deferred reasons are non-empty;
- `agentsBasicTouchedBefore=true`;
- reason is missing;
- policy disallows fake-live application;
- max fake-live applications are exceeded.

Defer if:

- `applyMode` is audit-only;
- fake-live state is ambiguous but not invalid;
- policy `allowDeferred=true`.

No-op if:

- `fakeLiveGoalBefore == targetGoal`;
- `allowNoopGoal=true`;
- `appliedToFakeLive=false`;
- `appliedToAgentsBasic=false`.

## Applied Rules V0

For Phase 5.12B:

- `appliedToFakeLive` can be true;
- `fakeLiveGoalChanged` can be true;
- `appliedToAgentsBasic=false` always;
- `agentsBasicTouched=false` always;
- `liveRuntimeTouched=false` always;
- `memoryMutated=false`;
- `movementStackUsed=false`;
- `worldMutated=false`;
- `terrainMutated=false`.

Even when `appliedToFakeLive=true`, the normal runtime must remain untouched.

## Relationship With Guarded Live Goal Application

Fake-live goal application consumes outputs from `LabLiveGoalApplication`.
It does not replace guarded live application. It is the first phase where a
goal change can be applied, but only on scenario-owned fake-live state.

The guarded layer remains responsible for validating `liveApplyEligible`,
`wouldApplyToLive`, target goal, prior rejected/deferred reasons, policy
gates, and `agentsBasicTouched=false` evidence.

## Relationship With `agents_basic`

`agents_basic` remains unchanged. Phase 5.12B must use a dedicated scenario.
No normal runtime agent should be touched.

The fake-live fixture should include explicit `appliedToAgentsBasic=false`,
`agentsBasicTouched=false`, and `liveRuntimeTouched=false` fields in its
report and invariants.

## Relationship With Movement Stack

Changing a fake-live goal is not movement.

There must be:

- no movement intent;
- no route following;
- no reservation;
- no pathfinding;
- no movement stack call;
- no World mutation.

## Relationship With Memory Writes

Fake-live goal application does not write memory.

Future memory audit may observe fake-live transitions later, but Phase 5.12B
must not write live memory, mutate memory entries, call memory update, or
create a feedback loop.

## Relationship With Mood / Relations / LLM

Fake-live goal application is a narrow scenario-owned state transition layer.

Mood, emotional memory, relationships, trust, communication, community state,
Python, LLM, embeddings, and RL remain out of scope.

## Future Metrics Contract

Metrics prefix:

`fakeLiveGoalApplication*`

Proposed metrics:

- `fakeLiveGoalApplicationSuccess`;
- `fakeLiveGoalApplicationAgents`;
- `fakeLiveGoalApplicationTicks`;
- `fakeLiveGoalApplicationPolicies`;
- `fakeLiveGoalApplicationInputs`;
- `fakeLiveGoalApplicationDecisions`;
- `fakeLiveGoalApplicationEligible`;
- `fakeLiveGoalApplicationWouldChange`;
- `fakeLiveGoalApplicationAppliedToFakeLive`;
- `fakeLiveGoalApplicationGoalChanged`;
- `fakeLiveGoalApplicationNoops`;
- `fakeLiveGoalApplicationRejected`;
- `fakeLiveGoalApplicationDeferred`;
- `fakeLiveGoalApplicationAppliedToAgentsBasic`;
- `fakeLiveGoalApplicationAgentsBasicTouched`;
- `fakeLiveGoalApplicationLiveRuntimeTouched`;
- `fakeLiveGoalApplicationMemoryMutated`;
- `fakeLiveGoalApplicationMovementStackUsed`;
- `fakeLiveGoalApplicationWorldMutated`;
- `fakeLiveGoalApplicationTerrainMutated`;
- `fakeLiveGoalApplicationBounded`;
- `fakeLiveGoalApplicationDeterministicOrder`;
- `fakeLiveGoalApplicationDigestsEqual`;
- `fakeLiveGoalApplicationRepeatabilityFailures`.

## Future Events Contract

Primary future event:

`lab_fake_live_goal_application_recorded`

Minimum fields:

- `success`;
- `agentId`;
- `tick`;
- `fakeLiveGoalBefore`;
- `targetGoal`;
- `fakeLiveGoalAfter`;
- `fakeLiveGoalChanged`;
- `appliedToFakeLive`;
- `appliedToAgentsBasic`;
- `agentsBasicTouched`;
- `liveRuntimeTouched`;
- `rejectedReasons`;
- `deferredReasons`;
- `applyMode`.

Optional summary event:

`lab_fake_live_goal_application_summary_recorded`

Fields:

- `success`;
- `agents`;
- `ticks`;
- `inputs`;
- `decisions`;
- `fakeLiveApplyEligible`;
- `fakeLiveWouldChange`;
- `appliedToFakeLive`;
- `fakeLiveGoalChanged`;
- `noops`;
- `rejected`;
- `deferred`;
- `appliedToAgentsBasic`;
- `agentsBasicTouched`;
- `liveRuntimeTouched`;
- `bounded`;
- `digestsEqual`;
- `repeatabilityFailures`.

## Future Invariant Contract

Minimum checks for Phase 5.12B:

- scenario name expected;
- seed recorded;
- report success;
- agents expected;
- inputs positive;
- decisions positive;
- fake-live eligibility covered;
- applied to fake-live covered;
- fake-live goal changed covered;
- no-op covered;
- rejected covered;
- deferred covered if implemented;
- applied to `agents_basic` zero;
- `agents_basic` not touched;
- live runtime not touched;
- memory not mutated;
- movement stack not used;
- no World mutation;
- no terrain mutation;
- `fakeLiveGoalBefore` / `targetGoal` / `fakeLiveGoalAfter` audited;
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

## Recommended Phase 5.12B

`Phase 5.12B — Fake-Live Goal Application Fixture Smoke`

Probable new scenario:

`fake_live_goal_application_fixture_smoke`

Objective: create a fixture that consumes guarded live goal decisions, applies
the goal to fake-live state, and proves that `agents_basic` remains intact.

The fixture should:

- create 6 to 9 fake-live goal inputs;
- cover `appliedToFakeLive=true`;
- cover `fakeLiveGoalChanged=true`;
- cover fake-live no-op;
- cover rejected target unknown / not allowed;
- cover rejected `wouldApplyToLive=false`;
- cover rejected prior rejected/deferred reasons;
- cover rejected `agentsBasicTouchedBefore=true`;
- cover deferred audit-only if simple;
- keep `appliedToAgentsBasic=0`;
- keep `agentsBasicTouched=false`;
- keep `liveRuntimeTouched=false`;
- keep `memoryMutated=false`;
- not call movement stack;
- not mutate World;
- remain deterministic.

Future outputs:

- `fake_live_goal_application_report.json`;
- `fake_live_goal_application_invariant_report.json`;
- `fake_live_goal_application_policies.json`;
- `fake_live_goal_application_inputs.json`;
- `fake_live_goal_application_decisions.json`;
- `fake_live_goal_application_digest.json`;
- `metrics.json`;
- `events.ndjson`.

## Risks

- confusing fake-live state with `agents_basic`;
- mutating a true `LabAgent` too early;
- forgetting `appliedToAgentsBasic=0`;
- triggering movement stack from goal application;
- writing transition memory too early;
- missing rejected or deferred reasons;
- depending on non-deterministic ordering;
- growing `main.swift` instead of keeping orchestration thin.

## Explicit Out Of Scope

- no `agents_basic` integration;
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

## Definition Of Done For 5.12A

- Document created.
- Changelog updated.
- Dev journal updated.
- Roadmap updated.
- Cognitive resync plan updated if useful.
- 5.11A live goal application plan updated if useful.
- No Swift files changed.
- No runtime behavior changed.
- No scenarios added.
- `swift build` passes if possible.
- `swift build -c release --product Pebble` passes.
- `git diff --check` passes.
- Next phase 5.12B is clearly specified.

## Phase 5.12B Implementation Status

Phase 5.12B implemented `fake_live_goal_application_fixture_smoke`.

Scenario:

- `fake_live_goal_application_fixture_smoke`.

Policies:

- default `fake_live_goal_apply`;
- `fake_live_goal_audit_only` deferred mode;
- allowed-goal restriction policy;
- no-op allowed policy;
- max fake-live applications rejection policy.

Inputs:

- 13 fake-live goal application inputs;
- inputs derived from guarded live goal decision-style fields;
- stable order by tick and agent id.

Decisions:

- 13 decisions;
- two `fakeLiveApplyEligible=true`;
- two `appliedToFakeLive=true`;
- two `fakeLiveGoalChanged=true`;
- 11 `fakeLiveWouldChange=true`;
- one fake-live no-op;
- nine rejected fake-live applications;
- one deferred fake-live application;
- `appliedToAgentsBasic=0`.

Fake-live application:

- applies goals only to scenario-owned fake-live values;
- does not apply to `agents_basic`;
- keeps `agentsBasicTouched=false`;
- keeps `liveRuntimeTouched=false`.

Report:

- `fake_live_goal_application_report.json`.

Invariant:

- `fake_live_goal_application_invariant_report.json`;
- 56 checks passed, 0 failed.

Digest:

- `fake_live_goal_application_digest.json`;
- digest `9e0d5a3a700940f9`;
- digest repeat equals digest.

Metrics:

- `fakeLiveGoalApplication*`.

Events:

- `lab_fake_live_goal_application_recorded`;
- optional `lab_fake_live_goal_application_summary_recorded`.

Limitations:

- no `agents_basic` integration;
- no true live runtime mutation;
- no action application;
- no memory write application;
- no movement stack;
- no World or terrain mutation;
- no mood, relationships, LLM, Python, embeddings, or RL.

Next phase:

- Phase 5.12C — Fake-Live Goal Application Hardening.
