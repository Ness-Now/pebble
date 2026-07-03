# Phase 5.11A — Live Goal Application Planning

## Purpose

Phase 5.11A defines the contract for a guarded live goal application layer.

This layer consumes a validated snapshot mutation where:

- `appliedToSnapshot=true`;
- `snapshotGoalChanged=true`;
- `appliedToLive=false`;
- `liveGoalAfter == originalLiveGoalBefore`;
- `liveAgentMutated=false`.

It produces a strictly guarded live application plan:

- `liveGoalBefore`;
- `targetGoal`;
- `liveGoalAfterCandidate`;
- `applyMode`;
- `liveApplyEligible`;
- `wouldApplyToLive`;
- `appliedToLive=false` in Phase 5.11B unless a later implementation
  explicitly uses a scenario-owned fake-live copy;
- `liveAgentMutated=false` in Phase 5.11B;
- complete audit evidence.

This phase is planning-only. It adds no Swift runtime, no scenario, no runtime
metrics, no runtime events, no `LabAgent` mutation path, no `agents_basic`
integration, no movement stack call, no World mutation, no terrain mutation,
no mood, no relationships, no communication, no Python, no LLM, no embeddings,
and no RL.

## Starting Point

Phase 5.10B and Phase 5.10C created and hardened goal mutation on
copied/snapshot state in `LabGoalSnapshotMutation.swift`.

The snapshot mutation layer proves the expected before/after goal transition
without touching live state:

- copied snapshot goal can change;
- live goal remains unchanged;
- `appliedToLive=false`;
- `liveAgentMutated=false`;
- memory, movement stack, World, and terrain remain untouched.

Phase 5.11A prepares only the contract for a future guarded live goal
application layer. It does not apply a goal to a real `LabAgent`.

## Current Snapshot Mutation State

`LabGoalSnapshotMutation.swift` currently owns the snapshot mutation fixtures.

Current policies are represented by `LabGoalSnapshotMutationPolicy`:

- `dryRun`;
- `mutationMode`;
- `allowSnapshotMutation`;
- `allowedGoals`;
- `maxSnapshotMutationsPerTick`;
- `requireReason`;
- `requireWouldApplyGoalChange`;
- `requireNoRejectedReasons`;
- `requireNoDeferredReasons`;
- `requireLiveUnchanged`;
- `allowNoopGoal`;
- `allowDeferred`.

Current inputs are represented by `LabGoalSnapshotMutationInput`:

- `tick`;
- `agentId`;
- `originalLiveGoal`;
- `snapshotGoalBefore`;
- `targetGoal`;
- `wouldApplyGoalChange`;
- `dryRunRejectedReasons`;
- `dryRunDeferredReasons`;
- `dryRunDecisionSummary`;
- `policy`;
- `reason`.

Current decisions are represented by `LabGoalSnapshotMutationDecision`:

- `originalLiveGoalBefore`;
- `snapshotGoalBefore`;
- `targetGoal`;
- `snapshotGoalAfter`;
- `snapshotGoalChanged`;
- `appliedToSnapshot`;
- `appliedToLive`;
- `liveGoalAfter`;
- `liveAgentMutated`;
- `rejectedReasons`;
- `deferredReasons`;
- `dryRun`;
- `success`.

Current fixture and hardening reports count policies, inputs, decisions,
attempted snapshot mutations, applied-to-snapshot mutations, snapshot goal
changes, no-ops, rejected mutations, deferred mutations, applied-to-live
count, live goal unchanged evidence, boundary flags, deterministic order,
digest equality, and repeatability failures.

Current limitations:

- no goal is applied to a live `LabAgent`;
- no goal is applied to `agents_basic`;
- no selected action is applied;
- no memory is written;
- no movement intent is produced;
- World and terrain remain untouched.

## Problem To Solve

Snapshot mutation is not live application. It proves that a copied goal value
can be changed safely, but it does not define when live goal mutation might be
allowed.

Problems to solve before implementation:

- applying a live goal is a real agent mutation;
- live application must use a dedicated scenario;
- live application must be policy-gated;
- no mode should mutate `agents_basic` in Phase 5.11B;
- dry-run and fake-live states must be distinguished from normal runtime
  live agents;
- `wouldApplyToLive` and `appliedToLive` must be separate;
- action execution, movement, memory writes, World mutation, and terrain
  mutation must be impossible;
- every accepted, rejected, deferred, and no-op decision must be auditable.

## Guarded Live Goal Application Contract V0

Input:

- snapshot mutation decision;
- live agent goal view;
- `targetGoal`;
- `applyMode`;
- live application policy;
- `allowLiveGoalApplication`;
- `requireSnapshotMutationApplied`;
- `requireLiveGoalStillMatchesOriginal`;
- `requireNoRejectedReasons`;
- `requireNoDeferredReasons`;
- `requireReason`;
- `maxLiveGoalApplicationsPerTick`.

Output:

- live goal application candidate;
- `liveGoalBefore`;
- `targetGoal`;
- `liveGoalAfterCandidate`;
- `wouldApplyToLive`;
- `appliedToLive`;
- `liveAgentMutated`;
- rejected reasons;
- deferred reasons;
- audit record;
- deterministic digest.

Important v0 rule: Phase 5.11B should prefer `appliedToLive=false` and
`liveAgentMutated=false`. If a future implementation uses mutable state, it
must be a scenario-owned fake-live copy, not `agents_basic`.

## Proposed Types For Future Implementation

These types are proposed for Phase 5.11B or later. They are not implemented in
Phase 5.11A.

### `LabLiveGoalApplicationPolicy`

Suggested fields:

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
- `allowNoopGoal`;
- `allowDeferred`.

Purpose: define whether a validated snapshot mutation can become a guarded
live goal application candidate.

### `LabLiveGoalApplicationInput`

Suggested fields:

- `tick`;
- `agentId`;
- `liveGoalBefore`;
- `originalLiveGoalBefore`;
- `snapshotGoalAfter`;
- `targetGoal`;
- `snapshotMutationSummary`;
- `appliedToSnapshot`;
- `priorAppliedToLive`;
- `priorRejectedReasons`;
- `priorDeferredReasons`;
- `policy`;
- `reason`.

Purpose: carry the audited live goal application request derived from a
snapshot mutation decision.

### `LabLiveGoalApplicationDecision`

Suggested fields:

- `tick`;
- `agentId`;
- `liveGoalBefore`;
- `targetGoal`;
- `liveGoalAfterCandidate`;
- `liveGoalWouldChange`;
- `wouldApplyToLive`;
- `appliedToLive`;
- `liveAgentMutated`;
- `rejectedReasons`;
- `deferredReasons`;
- `applyMode`;
- `success`.

Purpose: record the guarded live goal application candidate and the final
applied state for the fixture.

### `LabLiveGoalApplicationReport`

Suggested fields:

- `scenario`;
- `seed`;
- `agents`;
- `ticks`;
- `policies`;
- `inputs`;
- `decisions`;
- `liveApplyEligible`;
- `wouldApplyToLive`;
- `appliedToLive`;
- `liveGoalWouldChange`;
- `liveNoops`;
- `rejectedLiveApplications`;
- `deferredLiveApplications`;
- `liveAgentMutated`;
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

Purpose: provide fixture-level evidence that the live goal application
contract is respected.

## Live Goal Application Modes V0

Modes:

- `live_goal_audit_only`;
- `live_goal_guarded_dry_run`;
- `live_goal_candidate_only`;
- future `live_goal_apply_to_dedicated_agent`;
- future `live_goal_apply_to_agents_basic_guarded`.

For Phase 5.11B, the required recommended mode is:

- `live_goal_guarded_dry_run`.

Phase 5.11B must not branch `agents_basic`. If mutable state is needed, it
must be scenario-owned live-like state that cannot affect the normal runtime.

## Eligibility Rules V0

Live goal application can become `wouldApplyToLive=true` only if:

- `appliedToSnapshot=true`;
- `snapshotGoalChanged=true`;
- `targetGoal` is known;
- `targetGoal` is in `allowedGoals`;
- `liveGoalBefore == originalLiveGoalBefore`;
- `targetGoal != liveGoalBefore`;
- prior `appliedToLive=false`;
- prior rejected reasons are empty;
- prior deferred reasons are empty;
- reason is non-empty;
- policy `allowLiveGoalApplication=true`;
- dedicated scenario flag is true;
- `maxLiveGoalApplicationsPerTick` is respected.

Reject if:

- `appliedToSnapshot=false`;
- `snapshotGoalChanged=false` for a non-noop request;
- target goal is unknown;
- target goal is not allowed;
- `liveGoalBefore` does not match `originalLiveGoalBefore`;
- prior `appliedToLive=true`;
- prior rejected reasons are non-empty;
- prior deferred reasons are non-empty;
- reason is missing;
- policy disallows live application;
- dedicated scenario flag is false;
- max live goal applications are exceeded.

Defer if:

- `applyMode` is audit-only;
- live state is ambiguous but not invalid;
- policy `allowDeferred=true`.

No-op if:

- `targetGoal == liveGoalBefore`;
- `allowNoopGoal=true`;
- `appliedToLive=false`;
- `liveAgentMutated=false`.

## Applied Rules V0

Preferred safest rule for Phase 5.11B:

- `appliedToLive=false`;
- `liveAgentMutated=false`.

Alternative only if explicitly implemented as a dedicated mutable fake-live
agent:

- `appliedToLive` can be true only on scenario-owned live-like state;
- never on `agents_basic`;
- the fixture must prove no normal runtime live agent mutation;
- movement, memory, World, and terrain must remain untouched.

Unless the codebase structure makes fake-live application trivial and fully
isolated, Phase 5.11B should choose the safest implementation.

## Relationship With Snapshot Mutation

Live goal application consumes outputs from `LabGoalSnapshotMutation`.

It does not replace snapshot mutation. Snapshot mutation proves copied-state
before/after behavior. Live goal application defines the additional policy and
audit rules that must hold before any live goal transition could be considered.

## Relationship With `agents_basic`

`agents_basic` remains unchanged.

Phase 5.11B must use a dedicated scenario. No live behavior change should
occur in the normal runtime. No `agents_basic` agent should receive a computed
goal from this layer before a later phase explicitly authorizes it.

## Relationship With Movement Stack

Changing a goal is not movement.

The live goal application layer must not produce:

- movement intent;
- route following;
- reservation;
- pathfinding;
- physical placeholder movement;
- Core entity movement;
- World mutation.

## Relationship With Memory Writes

Live goal application planning does not write memory.

A future memory audit may observe live goal transitions, but Phase 5.11B must
not write live memory and must not invoke `LabMemoryUpdate` as an application
side effect.

## Relationship With Mood / Relations / LLM

Live goal application is a narrow guarded state transition layer.

Mood, emotional memory, relationships, trust, communication, community state,
Python, LLM, embeddings, and RL remain out of scope.

## Future Metrics Contract

Metrics prefix:

- `liveGoalApplication*`

Metrics proposed for Phase 5.11B:

- `liveGoalApplicationSuccess`;
- `liveGoalApplicationAgents`;
- `liveGoalApplicationTicks`;
- `liveGoalApplicationPolicies`;
- `liveGoalApplicationInputs`;
- `liveGoalApplicationDecisions`;
- `liveGoalApplicationEligible`;
- `liveGoalApplicationWouldApplyToLive`;
- `liveGoalApplicationAppliedToLive`;
- `liveGoalApplicationLiveGoalWouldChange`;
- `liveGoalApplicationLiveNoops`;
- `liveGoalApplicationRejected`;
- `liveGoalApplicationDeferred`;
- `liveGoalApplicationLiveAgentMutated`;
- `liveGoalApplicationMemoryMutated`;
- `liveGoalApplicationMovementStackUsed`;
- `liveGoalApplicationWorldMutated`;
- `liveGoalApplicationTerrainMutated`;
- `liveGoalApplicationBounded`;
- `liveGoalApplicationDeterministicOrder`;
- `liveGoalApplicationDigestsEqual`;
- `liveGoalApplicationRepeatabilityFailures`.

## Future Events Contract

Primary future event:

- `lab_live_goal_application_recorded`

Minimum fields:

- `success`;
- `agentId`;
- `tick`;
- `liveGoalBefore`;
- `targetGoal`;
- `liveGoalAfterCandidate`;
- `liveGoalWouldChange`;
- `wouldApplyToLive`;
- `appliedToLive`;
- `liveAgentMutated`;
- `rejectedReasons`;
- `deferredReasons`;
- `applyMode`.

Optional summary event:

- `lab_live_goal_application_summary_recorded`

Summary fields:

- `success`;
- `agents`;
- `ticks`;
- `inputs`;
- `decisions`;
- `liveApplyEligible`;
- `wouldApplyToLive`;
- `appliedToLive`;
- `liveGoalWouldChange`;
- `liveNoops`;
- `rejected`;
- `deferred`;
- `liveAgentMutated`;
- `bounded`;
- `digestsEqual`;
- `repeatabilityFailures`.

## Future Invariant Contract

Minimum checks for Phase 5.11B:

- scenario name expected;
- seed recorded;
- report success;
- agents expected;
- inputs positive;
- decisions positive;
- live eligibility covered;
- `wouldApplyToLive` covered;
- rejected covered;
- deferred covered if implemented;
- no-op covered;
- `appliedToLive` zero unless explicitly fake-live dedicated;
- `agents_basic` unchanged;
- live agent not mutated in normal runtime;
- memory not mutated;
- movement stack not used;
- no World mutation;
- no terrain mutation;
- `liveGoalBefore` / `targetGoal` / `liveGoalAfterCandidate` audited;
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

## Recommended Phase 5.11B

Recommended implementation:

`Phase 5.11B — Live Goal Application Guarded Fixture Smoke`

Likely new scenario:

- `live_goal_application_guarded_fixture_smoke`.

Goal: create a fixture that consumes snapshot mutation decisions, produces
guarded live goal application decisions, and remains isolated from the normal
runtime.

The fixture should:

- create 5 to 8 live goal application inputs;
- cover live eligible;
- cover `wouldApplyToLive`;
- cover no-op;
- cover rejected unknown or not allowed target;
- cover rejected `liveGoalBefore` mismatch;
- cover rejected prior `appliedToLive`;
- cover rejected prior rejected/deferred reasons;
- cover deferred audit-only if simple;
- keep `appliedToLive=0` by default;
- keep `liveAgentMutated=false`;
- keep `memoryMutated=false`;
- not call the movement stack;
- not mutate World;
- remain deterministic.

Future outputs:

- `live_goal_application_report.json`;
- `live_goal_application_invariant_report.json`;
- `live_goal_application_policies.json`;
- `live_goal_application_inputs.json`;
- `live_goal_application_decisions.json`;
- `live_goal_application_digest.json`;
- `metrics.json`;
- `events.ndjson`.

## Risks

- confusing scenario-owned fake-live state with `agents_basic`;
- mutating a real `LabAgent` too early;
- forgetting to prove that `agents_basic` remains unchanged;
- treating a goal change as an action;
- triggering movement stack from a goal transition;
- writing transition memory too early;
- omitting rejected or deferred reasons;
- depending on nondeterministic order;
- growing `main.swift` instead of keeping fixture logic isolated.

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

## Definition Of Done For 5.11A

- Document created.
- Changelog updated.
- Dev journal updated.
- Roadmap updated.
- Cognitive resync plan updated if useful.
- 5.10A snapshot mutation plan updated if useful.
- No Swift files changed.
- No runtime behavior changed.
- No scenarios added.
- `swift build` passes if possible.
- `swift build -c release --product Pebble` passes.
- `git diff --check` passes.
- Next phase 5.11B is clearly specified.

## Phase 5.11B Implementation Status

Phase 5.11B implemented `live_goal_application_guarded_fixture_smoke`.

Scenario:

- `live_goal_application_guarded_fixture_smoke`.

Policies:

- default `live_goal_guarded_dry_run`;
- `live_goal_audit_only` deferred mode;
- allowed-goal restriction policy;
- dedicated-scenario rejection policy;
- max live goal applications rejection policy;
- no-op allowed policy.

Inputs:

- 14 guarded live goal application inputs;
- inputs derived from validated snapshot mutation-style fields;
- stable order by tick and agent id.

Decisions:

- 14 decisions;
- two `liveApplyEligible=true`;
- two `wouldApplyToLive=true`;
- 12 `liveGoalWouldChange=true`;
- one live no-op;
- 10 rejected live applications;
- one deferred live application;
- `appliedToLive=0`.

Guarded live goal application:

- produces candidates only;
- does not apply to live agents;
- keeps `liveAgentMutated=false`;
- records `agentsBasicTouched=false`.

Report:

- `live_goal_application_report.json`.

Invariant:

- `live_goal_application_invariant_report.json`;
- 57 checks passed, 0 failed.

Digest:

- `live_goal_application_digest.json`;
- digest `4126b7241f1cc167`;
- digest repeat equals digest.

Metrics:

- `liveGoalApplication*`.

Events:

- `lab_live_goal_application_recorded`;
- optional `lab_live_goal_application_summary_recorded`.

Limitations:

- no `agents_basic` integration;
- no live applied goal changes;
- no action application;
- no memory write application;
- no movement stack;
- no World or terrain mutation;
- no mood, relationships, LLM, Python, embeddings, or RL.

Next phase:

- Phase 5.11C — Live Goal Application Guarded Hardening.

## Phase 5.11C Implementation Status

Phase 5.11C implemented `live_goal_application_guarded_hardening_smoke`.

Scenario:

- `live_goal_application_guarded_hardening_smoke`.

Cases:

- 32 hardening cases;
- 5.11B baseline compatibility;
- eligible safety, explore, and observe candidates;
- no-op allowed and no-op disallowed;
- unknown target, target not allowed, missing live goal, missing original live
  goal, missing target, missing reason, live goal mismatch, prior
  applied/rejected/deferred reasons, missing snapshot application, unchanged
  snapshot for non-noop, policy disallow, dedicated scenario false, max live
  applications, and audit-only deferred;
- aggregate checks for rejected/deferred reasons, audit fields,
  `appliedToLive=0`, no mutation boundaries, deterministic order, bounded
  shape, and digest repeatability.

Policies:

- default `live_goal_guarded_dry_run`;
- `live_goal_audit_only` deferred mode;
- no-op allowed policy;
- allowed-goal restriction policy;
- live application disallow policy;
- dedicated-scenario rejection policy;
- max live applications rejection policy.

Inputs:

- 35 inputs including the reused 5.11B baseline inputs;
- stable order by tick and agent id.

Decisions:

- 35 decisions;
- five `liveApplyEligible=true`;
- five `wouldApplyToLive=true`;
- 29 live-goal-would-change decisions;
- two live no-ops;
- 26 rejected live applications;
- two deferred live applications;
- `appliedToLive=0`.

Guarded live goal application:

- produces guarded candidates only;
- does not apply to live agents;
- keeps `liveAgentMutated=false`;
- records `agentsBasicTouched=false`.

Report:

- `live_goal_application_hardening_report.json`.

Invariant:

- `live_goal_application_hardening_invariant_report.json`;
- 95 checks passed, 0 failed.

Digest:

- `live_goal_application_hardening_digest.json`;
- digest `da4f68cecea2990a`;
- digest repeat equals digest.

Metrics:

- `liveGoalApplicationHardening*`.

Events:

- `lab_live_goal_application_hardening_recorded`.

Limitations:

- no `agents_basic` integration;
- no live applied goal changes;
- no action application;
- no memory write application;
- no movement stack;
- no World or terrain mutation;
- no mood, relationships, LLM, Python, embeddings, or RL.

Next phase:

- Phase 5.12A — Fake-Live Goal Application Planning.
