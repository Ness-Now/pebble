# Phase 5.9A — Goal Application Dry-Run Planning

## Purpose

Phase 5.9A defines the contract for a specialized dry-run layer for applying
a goal change.

This layer consumes a controlled application decision where:

- `goalChangeEligible=true`;
- `computedSelectedGoal` is known;
- `currentGoal` is known;
- `reason` is present.

It produces a goal application dry-run decision:

- `wouldApplyGoalChange=true/false`;
- `appliedGoalChange=false`;
- `liveAgentMutated=false`;
- `goalBefore` and `targetGoal` audited.

This phase is planning-only. It adds no Swift runtime, no scenario, no runtime
metrics, no runtime events, no `LabAgent` mutation path, no `agents_basic`
integration, no movement stack call, no World mutation, no terrain mutation,
no mood, no relationships, no communication, no Python, no LLM, no embeddings,
and no RL.

## Starting Point

Phase 5.8B and Phase 5.8C created and hardened the controlled application
layer. That layer consumes dry-run application plans, applies a policy, and
produces eligibility decisions, controlled decisions, rejected reasons, and
deferred reasons.

The controlled application layer can already say whether a goal change is
eligible, rejected, or deferred. It also keeps all applied flags at zero:

- `appliedGoalChange=false`;
- `appliedAction=false`;
- `appliedMemoryWrite=false`;
- `appliedAnything=false`.

Phase 5.9A prepares a narrower goal application dry-run layer. It does not
apply a goal to an agent. It only defines how Phase 5.9B should audit and
simulate the first future application path.

## Current Controlled Application State

`LabControlledApplication.swift` currently owns the controlled application
fixtures.

Current policies are represented by `LabControlledApplicationPolicy`:

- `dryRun`;
- `applyMode`;
- `allowGoalChange`;
- `allowActionSelection`;
- `allowMemoryWrite`;
- `allowedGoals`;
- `allowedActions`;
- `maxApplicationsPerTick`;
- `maxMemoryWritesPerTick`;
- `requireReason`;
- `requireSnapshotReadOnly`.

Current inputs are represented by `LabControlledApplicationInput`:

- `tick`;
- `agentId`;
- `snapshotSummary`;
- `currentGoal`;
- `computedSelectedGoal`;
- `computedSelectedAction`;
- `proposedMemoryWrites`;
- `wouldChangeGoal`;
- `wouldSelectAction`;
- `wouldWriteMemory`;
- `snapshotReadOnly`;
- `policy`;
- `reason`.

Current eligibilities are represented by `LabControlledApplicationEligibility`:

- `computedSelectedGoal`;
- `computedSelectedAction`;
- `proposedMemoryWrites`;
- `goalChangeEligible`;
- `actionSelectionEligible`;
- `memoryWriteEligible`;
- `eligible`;
- `rejectedReasons`;
- `deferredReasons`;
- `reason`.

Current decisions are represented by `LabControlledApplicationDecision`:

- `eligibility`;
- `appliedGoalChange`;
- `appliedAction`;
- `appliedMemoryWrite`;
- `appliedAnything`;
- `dryRun`;
- `liveAgentMutated`;
- `memoryMutated`;
- `movementStackUsed`;
- `worldMutated`;
- `terrainMutated`;
- `success`.

Current reports count eligible goal changes, eligible actions, eligible memory
writes, rejected applications, deferred applications, applied flags, dry-run
status, boundary flags, bounded output, deterministic order, digest equality,
and repeatability failures.

Current limitations:

- eligibility is not application;
- no selected goal is applied to a live agent;
- no selected action is applied to a live agent;
- no live memory is written;
- no movement intent is produced;
- `agents_basic` remains unchanged.

## Problem To Solve

The controlled application layer proves whether a goal change is eligible. It
does not yet define how goal application itself should be audited.

Problems to solve before implementation:

- eligibility is not application;
- a goal change is less dangerous than a physical action, but still mutates
  agent state;
- the first goal application layer must simulate application before any live
  mutation exists;
- `goalBefore`, `targetGoal`, and `reason` must be audited;
- live mutation must remain impossible in the dry-run layer;
- selected action application remains out of scope;
- memory write application remains out of scope;
- the movement stack remains out of scope;
- `agents_basic` must remain unchanged.

## Goal Application Dry-Run Contract V0

Input:

- controlled application decision;
- live agent snapshot read-only;
- `currentGoal`;
- `targetGoal`;
- allowed goals;
- `goalChangeEligible`;
- `dryRun` forced true;
- reason;
- `maxGoalChangesPerTick`.

Output:

- goal application dry-run decision;
- `goalBefore`;
- `targetGoal`;
- `wouldApplyGoalChange`;
- `appliedGoalChange=false`;
- rejected reasons;
- deferred reasons;
- `liveAgentMutated=false`;
- deterministic digest.

Important v0 rule: `wouldApplyGoalChange=true` is only an audited dry-run
result. It must not mutate a live agent in Phase 5.9B.

## Proposed Types For Future Implementation

These types are proposed for Phase 5.9B or later. They are not implemented in
Phase 5.9A.

### `LabGoalApplicationDryRunPolicy`

Suggested fields:

- `dryRun`;
- `allowGoalApplication`;
- `allowedGoals`;
- `maxGoalChangesPerTick`;
- `requireReason`;
- `requireSnapshotReadOnly`;
- `allowNoopGoal`;
- `allowDeferred`.

Purpose: define the narrow policy for simulating goal application without
mutating an agent.

### `LabGoalApplicationDryRunInput`

Suggested fields:

- `tick`;
- `agentId`;
- `snapshotSummary`;
- `currentGoal`;
- `targetGoal`;
- `goalChangeEligible`;
- `controlledDecisionSummary`;
- `policy`;
- `reason`.

Purpose: carry the audited goal application request from a controlled
application decision into the dry-run goal layer.

### `LabGoalApplicationDryRunDecision`

Suggested fields:

- `tick`;
- `agentId`;
- `goalBefore`;
- `targetGoal`;
- `goalKnown`;
- `goalChanged`;
- `wouldApplyGoalChange`;
- `appliedGoalChange`;
- `rejectedReasons`;
- `deferredReasons`;
- `dryRun`;
- `liveAgentMutated`;
- `success`.

Purpose: record whether a goal change would be applied, why it was rejected or
deferred, and prove that no live mutation occurred.

### `LabGoalApplicationDryRunReport`

Suggested fields:

- `scenario`;
- `seed`;
- `agents`;
- `ticks`;
- `inputs`;
- `decisions`;
- `eligibleInputs`;
- `wouldApplyGoalChanges`;
- `noopGoalChanges`;
- `rejectedGoalApplications`;
- `deferredGoalApplications`;
- `appliedGoalChanges`;
- `dryRun`;
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

Purpose: summarize the fixture-only goal application dry-run contract and its
boundary evidence.

## Goal Application Modes V0

Supported or planned modes:

- `goal_dry_run_only`;
- `goal_eligibility_audit`;
- `goal_noop_audit`;
- future `apply_goal_to_snapshot`;
- future `apply_goal_to_live_agent`.

Recommended Phase 5.9B mode:

- `goal_dry_run_only`.

No mode may modify a real agent in Phase 5.9B.

## Goal Application Eligibility Rules V0

Goal application can be would-applied only if:

- `goalChangeEligible=true`;
- `targetGoal` is known;
- `targetGoal` is in `allowedGoals`;
- `currentGoal != targetGoal`;
- reason is non-empty;
- snapshot is read-only;
- `dryRun=true`;
- `maxGoalChangesPerTick` is respected.

Reject if:

- `targetGoal` is unknown;
- `targetGoal` is not allowed;
- `goalChangeEligible=false`;
- `currentGoal` is missing;
- `targetGoal` is missing;
- reason is missing;
- snapshot is not read-only;
- `dryRun=false`;
- `maxGoalChangesPerTick` is exceeded.

Defer if:

- policy mode is audit-only;
- goal is valid but application is deliberately delayed;
- agent state is ambiguous but not invalid.

No-op if:

- `currentGoal == targetGoal`;
- policy `allowNoopGoal=true`;
- no mutation is needed;
- `appliedGoalChange` remains false.

## Applied Rules V0

For Phase 5.9B:

- `appliedGoalChange=false`;
- `liveAgentMutated=false`;
- `memoryMutated=false`;
- `movementStackUsed=false`;
- `worldMutated=false`;
- `terrainMutated=false`.

Even when `wouldApplyGoalChange=true`, the dry-run layer mutates nothing.

## Relationship With Controlled Application

Goal application dry-run consumes controlled application outputs.

It specializes only the goal-change path:

- reads `goalChangeEligible`;
- reads the computed or target goal;
- reads the current goal;
- reads rejected/deferred context when present;
- produces a narrower goal application dry-run decision.

It does not handle action application. It does not handle memory write
application.

## Relationship With agents_basic

`agents_basic` remains unchanged.

Phase 5.9B must use a dedicated scenario, likely
`goal_application_dry_run_fixture_smoke`. No live behavior change should occur.

## Relationship With Movement Stack

Changing a goal is not movement.

The dry-run goal application layer must not produce:

- movement intent;
- route following;
- reservation;
- pathfinding;
- World mutation.

The movement stack remains out of scope.

## Relationship With Memory Writes

Goal application dry-run does not write memory.

Future memory audit can observe goal transitions later, but Phase 5.9B should
not create a memory write path or call live memory update.

## Relationship With Mood / Relations / LLM

Goal application is a narrow state application layer.

Mood, emotional memory, relationships, trust, communication, community state,
LLM, Python, embeddings, and RL remain out of scope.

## Future Metrics Contract

Prefix:

- `goalApplicationDryRun*`.

Metrics proposed for Phase 5.9B:

- `goalApplicationDryRunSuccess`;
- `goalApplicationDryRunAgents`;
- `goalApplicationDryRunTicks`;
- `goalApplicationDryRunInputs`;
- `goalApplicationDryRunDecisions`;
- `goalApplicationDryRunEligibleInputs`;
- `goalApplicationDryRunWouldApplyGoalChanges`;
- `goalApplicationDryRunNoopGoalChanges`;
- `goalApplicationDryRunRejectedGoalApplications`;
- `goalApplicationDryRunDeferredGoalApplications`;
- `goalApplicationDryRunAppliedGoalChanges`;
- `goalApplicationDryRunDryRun`;
- `goalApplicationDryRunLiveAgentMutated`;
- `goalApplicationDryRunMemoryMutated`;
- `goalApplicationDryRunMovementStackUsed`;
- `goalApplicationDryRunWorldMutated`;
- `goalApplicationDryRunTerrainMutated`;
- `goalApplicationDryRunBounded`;
- `goalApplicationDryRunDeterministicOrder`;
- `goalApplicationDryRunDigestsEqual`;
- `goalApplicationDryRunRepeatabilityFailures`.

## Future Events Contract

Main future event:

- `lab_goal_application_dry_run_recorded`.

Minimum fields:

- `success`;
- `agentId`;
- `tick`;
- `goalBefore`;
- `targetGoal`;
- `goalChangeEligible`;
- `wouldApplyGoalChange`;
- `appliedGoalChange`;
- `rejectedReasons`;
- `deferredReasons`;
- `dryRun`;
- `liveAgentMutated`.

Optional summary event:

- `lab_goal_application_dry_run_summary_recorded`.

Suggested fields:

- `success`;
- `agents`;
- `ticks`;
- `inputs`;
- `decisions`;
- `eligibleInputs`;
- `wouldApplyGoalChanges`;
- `noopGoalChanges`;
- `rejectedGoalApplications`;
- `deferredGoalApplications`;
- `appliedGoalChanges`;
- `dryRun`;
- `bounded`;
- `digestsEqual`;
- `repeatabilityFailures`.

## Future Invariant Contract

Minimum Phase 5.9B checks:

- scenario name expected;
- seed recorded;
- report success;
- agents expected;
- inputs positive;
- decisions positive;
- eligible input covered;
- would apply goal covered;
- noop goal covered;
- rejected goal covered;
- deferred goal covered if implemented;
- unknown target goal rejected;
- missing reason rejected;
- snapshot not read-only rejected;
- dryRun false rejected;
- max goal changes rejected;
- applied goal changes zero;
- live agent not mutated;
- memory not mutated;
- movement stack not used;
- no World mutation;
- no terrain mutation;
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

## Recommended Phase 5.9B

Recommended next phase:

- Phase 5.9B — Goal Application Dry-Run Fixture Smoke.

Likely new scenario:

- `goal_application_dry_run_fixture_smoke`.

Goal: create a fixture that takes controlled decisions that are
goal-eligible, rejected, or deferred and produces goal application dry-run
decisions.

The fixture should:

- create five to seven goal application inputs;
- cover an eligible goal change;
- cover a no-op goal;
- cover rejected unknown goal;
- cover rejected missing reason;
- cover rejected snapshot not read-only;
- cover deferred audit-only if simple;
- keep `appliedGoalChange=0`;
- keep `liveAgentMutated=false`;
- keep `memoryMutated=false`;
- avoid movement stack calls;
- avoid World mutation;
- remain deterministic.

Future outputs:

- `goal_application_dry_run_report.json`;
- `goal_application_dry_run_invariant_report.json`;
- `goal_application_dry_run_policies.json`;
- `goal_application_dry_run_inputs.json`;
- `goal_application_dry_run_decisions.json`;
- `goal_application_dry_run_digest.json`;
- `metrics.json`;
- `events.ndjson`.

## Risks

- confusing `wouldApplyGoalChange` and `appliedGoalChange`;
- changing `currentGoal` too early;
- connecting `agents_basic` too early;
- treating a goal as an action;
- triggering movement because a goal changed;
- writing goal-transition memory too early;
- forgetting no-op coverage;
- forgetting rejected or deferred reasons;
- depending on non-deterministic order;
- growing `main.swift`.

## Explicit Out Of Scope

- no `agents_basic` integration;
- no live agent mutation;
- no applied goal changes;
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

## Definition Of Done For 5.9A

- Document created.
- Changelog updated.
- Dev journal updated.
- Roadmap updated.
- Cognitive resync plan updated if useful.
- 5.8A controlled application plan updated if useful.
- No Swift files changed.
- No runtime behavior changed.
- No scenarios added.
- `swift build` passes if possible.
- `swift build -c release --product Pebble` passes.
- `git diff --check` passes.
- Next phase 5.9B is clearly specified.

## Phase 5.9B Implementation Status

Phase 5.9B implemented `goal_application_dry_run_fixture_smoke`.

Scenario:

- `goal_application_dry_run_fixture_smoke`.

Policies:

- mode `goal_dry_run_only` for normal dry-run decisions;
- mode `goal_eligibility_audit` for deferred audit-only coverage;
- bounded allowed goals;
- `maxGoalChangesPerTick` coverage;
- explicit dry-run false rejection coverage.

Inputs:

- nine goal application dry-run inputs;
- two eligible goal changes;
- one no-op goal;
- one unknown target goal;
- one missing reason;
- one snapshot-not-read-only case;
- one audit-only deferred case;
- one max-goal-changes rejection;
- one dry-run false rejection.

Decisions:

- two `wouldApplyGoalChange=true` decisions;
- one no-op decision with empty rejected/deferred reasons;
- five rejected decisions;
- one deferred decision;
- all `appliedGoalChange=false`.

Would/applied rules:

- would-apply is allowed only for known, eligible, changed goals with a reason,
  read-only snapshot, dry-run mode, and available goal-change capacity;
- applied goal changes remain zero.

Report:

- `goal_application_dry_run_report.json`.

Invariant:

- `goal_application_dry_run_invariant_report.json`.

Digest:

- `goal_application_dry_run_digest.json`.

Metrics:

- `goalApplicationDryRun*`.

Events:

- `lab_goal_application_dry_run_recorded`;
- optional `lab_goal_application_dry_run_summary_recorded`.

Limitations:

- no live `agents_basic` integration;
- no live agent mutation;
- no applied goal changes;
- no action application;
- no memory write application;
- no movement stack;
- no World or terrain mutation.

Next phase:

- Phase 5.9C — Goal Application Dry-Run Hardening.

## Phase 5.9C Implementation Status

Phase 5.9C implemented `goal_application_dry_run_hardening_smoke`.

Scenario:

- `goal_application_dry_run_hardening_smoke`.

Cases:

- 27 hardening cases;
- baseline compatibility;
- eligible `seekSafety`, `explore`, and `observeOtherAgent`;
- no-op allowed and no-op disallowed;
- unknown and not-allowed target goals;
- missing current goal, missing target goal, and missing reason;
- snapshot-not-read-only, dry-run false, goalChangeEligible false, policy
  denied, and max-goal-changes rejections;
- audit-only deferred;
- rejected/deferred reason presence;
- `goalBefore`/`targetGoal`, `goalKnown`, and `goalChanged` audit;
- applied goal changes zero;
- deterministic order, bounded output, and digest repeatability.

Policies:

- mode `goal_dry_run_only` for normal dry-run decisions;
- mode `goal_eligibility_audit` for deferred coverage;
- bounded allowed goals;
- known-but-not-allowed target goal policy coverage;
- `maxGoalChangesPerTick` rejection coverage;
- dry-run false rejection coverage.

Inputs:

- 16 goal application dry-run inputs in the hardening run.

Decisions:

- three `wouldApplyGoalChange=true` decisions;
- one no-op decision;
- eleven rejected decisions;
- one deferred decision;
- all `appliedGoalChange=false`.

Would/applied rules:

- would-apply is allowed only for known, allowed, eligible, changed goals with
  a reason, read-only snapshot, dry-run mode, and available goal-change
  capacity;
- applied goal changes remain zero.

Report:

- `goal_application_dry_run_hardening_report.json`.

Invariant:

- `goal_application_dry_run_hardening_invariant_report.json`.

Digest:

- `goal_application_dry_run_hardening_digest.json`.

Metrics:

- `goalApplicationDryRunHardening*`.

Events:

- `lab_goal_application_dry_run_hardening_recorded`.

Limitations:

- no live `agents_basic` integration;
- no live agent mutation;
- no applied goal changes;
- no action application;
- no memory write application;
- no movement stack;
- no World or terrain mutation.

Next phase:

- Phase 5.10A — Goal Application Snapshot Mutation Planning.
