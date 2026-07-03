# Phase 5.10A — Goal Application Snapshot Mutation Planning

## Purpose

Phase 5.10A defines the contract for mutating a goal on copied/snapshot state
only.

This layer consumes a goal application dry-run decision where:

- `wouldApplyGoalChange=true`;
- `targetGoal` is known;
- `goalBefore` is known;
- `rejectedReasons` is empty;
- `deferredReasons` is empty;
- `dryRun=true`.

It produces a simulated mutation on a copy:

- `snapshotGoalBefore`;
- `snapshotGoalAfter`;
- `snapshotGoalChanged=true`;
- `appliedToSnapshot=true`;
- `appliedToLive=false`;
- `liveAgentMutated=false`.

This phase is planning-only. It adds no Swift runtime, no scenario, no runtime
metrics, no runtime events, no `LabAgent` mutation path, no `agents_basic`
integration, no movement stack call, no World mutation, no terrain mutation,
no mood, no relationships, no communication, no Python, no LLM, no
embeddings, and no RL.

## Starting Point

Phase 5.9B and Phase 5.9C created and hardened the goal application dry-run
layer in `LabGoalApplicationDryRun.swift`.

That layer can already answer whether a controlled goal decision would apply a
goal change. It audits `goalBefore`, `targetGoal`, `goalKnown`,
`goalChanged`, rejected reasons, deferred reasons, and dry-run boundary flags.

It still applies nothing:

- `appliedGoalChange=false`;
- `liveAgentMutated=false`;
- `memoryMutated=false`;
- `movementStackUsed=false`;
- `worldMutated=false`;
- `terrainMutated=false`.

Phase 5.10A prepares the next narrow step: a fixture-only layer that may mutate
a copied/snapshot goal state while proving the live agent goal remains
unchanged.

## Current Goal Dry-Run State

`LabGoalApplicationDryRun.swift` currently owns the goal application dry-run
fixtures.

Current policies are represented by `LabGoalApplicationDryRunPolicy`:

- `dryRun`;
- `mode`;
- `allowGoalApplication`;
- `allowedGoals`;
- `maxGoalChangesPerTick`;
- `requireReason`;
- `requireSnapshotReadOnly`;
- `allowNoopGoal`;
- `allowDeferred`.

Current inputs are represented by `LabGoalApplicationDryRunInput`:

- `tick`;
- `agentId`;
- `snapshotSummary`;
- `currentGoal`;
- `targetGoal`;
- `goalChangeEligible`;
- `controlledDecisionSummary`;
- `snapshotReadOnly`;
- `policy`;
- `reason`.

Current decisions are represented by `LabGoalApplicationDryRunDecision`:

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

Current fixture and hardening reports count policies, inputs, decisions,
eligible inputs, would-apply decisions, no-op goals, rejected applications,
deferred applications, applied goal changes, dry-run status, live/memory/world
boundaries, deterministic order, digest equality, and repeatability failures.

Current limitations:

- no goal is applied to a live `LabAgent`;
- no goal is applied to a copied snapshot yet;
- no selected action is applied;
- no memory is written;
- no movement intent is produced;
- `agents_basic` remains unchanged.

## Problem To Solve

Dry-run proves that a goal change would be allowed. It does not test the
observable effect of changing a goal value.

Problems to solve before implementation:

- dry-run alone does not exercise before/after goal state;
- mutating the true live agent is still too risky;
- the first mutation layer must mutate only a copied state;
- live state must be auditable before and after the copied mutation;
- `appliedToSnapshot` and `appliedToLive` must be separate;
- no-op, rejected, and deferred decisions must stay explicit;
- selected actions, memory writes, and movement stack must stay out of scope;
- `agents_basic` must remain unchanged.

## Snapshot Mutation Contract V0

Input:

- goal application dry-run decision;
- copied mutable goal state;
- original live goal read-only value;
- `targetGoal`;
- `dryRun` forced true;
- mutation mode;
- allowed goals;
- `maxSnapshotMutationsPerTick`;
- reason.

Output:

- snapshot mutation decision;
- `originalLiveGoalBefore`;
- `snapshotGoalBefore`;
- `targetGoal`;
- `snapshotGoalAfter`;
- `snapshotGoalChanged`;
- `appliedToSnapshot`;
- `appliedToLive=false`;
- `liveGoalAfter`;
- `liveAgentMutated=false`;
- rejected reasons;
- deferred reasons;
- deterministic digest.

Important v0 rule: "mutation" in Phase 5.10B means mutation on copied state
only. It must not mutate `LabAgent.currentGoal`, counters, memory, action
state, movement state, World, or terrain.

## Proposed Types For Future Implementation

These types are proposed for Phase 5.10B or later. They are not implemented in
Phase 5.10A.

### `LabGoalSnapshotMutationPolicy`

Suggested fields:

- `dryRun`;
- `mutationMode`;
- `allowSnapshotMutation`;
- `allowedGoals`;
- `maxSnapshotMutationsPerTick`;
- `requireReason`;
- `requireWouldApplyGoalChange`;
- `requireNoRejectedReasons`;
- `requireNoDeferredReasons`;
- `requireLiveUnchanged`.

Purpose: define whether a dry-run goal decision may be copied into a mutable
snapshot and what safeguards must hold.

### `LabGoalSnapshotMutationInput`

Suggested fields:

- `tick`;
- `agentId`;
- `originalLiveGoal`;
- `snapshotGoalBefore`;
- `targetGoal`;
- `wouldApplyGoalChange`;
- `dryRunDecisionSummary`;
- `policy`;
- `reason`.

Purpose: carry one copied-state mutation request derived from a goal
application dry-run decision.

### `LabGoalSnapshotMutationDecision`

Suggested fields:

- `tick`;
- `agentId`;
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

Purpose: record whether the copied snapshot goal changed and prove the live
goal did not.

### `LabGoalSnapshotMutationReport`

Suggested fields:

- `scenario`;
- `seed`;
- `agents`;
- `ticks`;
- `policies`;
- `inputs`;
- `decisions`;
- `snapshotMutationsAttempted`;
- `snapshotMutationsApplied`;
- `snapshotNoops`;
- `rejectedSnapshotMutations`;
- `deferredSnapshotMutations`;
- `appliedToLiveCount`;
- `liveAgentMutated`;
- `memoryMutated`;
- `movementStackUsed`;
- `worldMutated`;
- `terrainMutated`;
- `dryRun`;
- `bounded`;
- `deterministicOrder`;
- `digest`;
- `digestRepeat`;
- `digestsEqual`;
- `repeatabilityFailures`;
- `success`.

Purpose: summarize the fixture and prove copied mutation did not leak into
live state or side-effect systems.

## Snapshot Mutation Modes V0

Recommended modes:

- `snapshot_goal_mutation_dry_run`;
- `snapshot_goal_mutation_audit`;
- `snapshot_goal_noop_audit`;
- future `snapshot_goal_mutation_apply_to_copy`;
- future `live_goal_mutation_guarded`.

For Phase 5.10B, the required mode should be:

- `snapshot_goal_mutation_dry_run`.

The future names are intentionally explicit. They keep copied-state mutation
separate from any guarded live mutation phase.

## Snapshot Mutation Eligibility Rules V0

Snapshot mutation can be simulated only if:

- `wouldApplyGoalChange=true`;
- `targetGoal` is known;
- `targetGoal` is in `allowedGoals`;
- `snapshotGoalBefore != targetGoal`;
- reason is non-empty;
- `dryRun=true`;
- `allowSnapshotMutation=true`;
- `maxSnapshotMutationsPerTick` is respected;
- dry-run decision has no rejected reasons;
- dry-run decision has no deferred reasons.

Reject if:

- `wouldApplyGoalChange=false`;
- `targetGoal` is unknown;
- `targetGoal` is not allowed;
- `snapshotGoalBefore` is missing;
- `targetGoal` is missing;
- reason is missing;
- `dryRun=false`;
- policy disallows snapshot mutation;
- `maxSnapshotMutationsPerTick` is exceeded;
- dry-run decision has rejected reasons;
- dry-run decision has deferred reasons.

Defer if:

- mutation mode is audit-only;
- snapshot state is ambiguous but not invalid.

No-op if:

- `snapshotGoalBefore == targetGoal`;
- policy allows no-op;
- `appliedToSnapshot=false`;
- `appliedToLive=false`.

## Applied Rules V0

For Phase 5.10B:

- `appliedToSnapshot` can be true only on copied/snapshot state;
- `snapshotGoalChanged=true` only when the copied value changes;
- `appliedToLive=false` always;
- `liveGoalAfter == originalLiveGoalBefore` always;
- `liveAgentMutated=false` always;
- `memoryMutated=false`;
- `movementStackUsed=false`;
- `worldMutated=false`;
- `terrainMutated=false`.

Even when `snapshotGoalChanged=true`, the true live agent goal must remain
unchanged.

## Relationship With Goal Application Dry-Run

Goal snapshot mutation consumes outputs from `LabGoalApplicationDryRun`.

It does not replace the dry-run layer. It specializes only the next step after
`wouldApplyGoalChange=true`: copy the audited target goal into copied state,
then prove the live state was not touched.

Rejected and deferred dry-run decisions should remain rejected or deferred in
the snapshot mutation layer unless a later phase explicitly defines a recovery
path.

## Relationship With agents_basic

`agents_basic` remains unchanged.

Phase 5.10B must use a dedicated scenario. No live behavior change, live goal
change, live action, live memory write, or movement behavior should occur.

## Relationship With Movement Stack

Changing a copied goal is not movement.

The snapshot mutation layer must not produce movement intent, route following,
reservation, pathfinding, full-route execution, or physical movement. It must
not call the movement stack and must not mutate World or terrain.

## Relationship With Memory Writes

Snapshot goal mutation does not write memory.

A future memory audit may observe copied goal transitions, but Phase 5.10B
must not call memory update, append live memory entries, or create a live
transition memory.

## Relationship With Mood / Relations / LLM

Snapshot goal mutation is a narrow copied-state test layer.

Mood, emotional memory, relationships, trust, communication, community state,
LLM context, Python, embeddings, and RL remain out of scope.

## Future Metrics Contract

Prefix:

- `goalSnapshotMutation*`

Metrics proposed for Phase 5.10B:

- `goalSnapshotMutationSuccess`;
- `goalSnapshotMutationAgents`;
- `goalSnapshotMutationTicks`;
- `goalSnapshotMutationPolicies`;
- `goalSnapshotMutationInputs`;
- `goalSnapshotMutationDecisions`;
- `goalSnapshotMutationAttempts`;
- `goalSnapshotMutationAppliedToSnapshot`;
- `goalSnapshotMutationSnapshotGoalChanged`;
- `goalSnapshotMutationSnapshotNoops`;
- `goalSnapshotMutationRejected`;
- `goalSnapshotMutationDeferred`;
- `goalSnapshotMutationAppliedToLive`;
- `goalSnapshotMutationDryRun`;
- `goalSnapshotMutationLiveAgentMutated`;
- `goalSnapshotMutationMemoryMutated`;
- `goalSnapshotMutationMovementStackUsed`;
- `goalSnapshotMutationWorldMutated`;
- `goalSnapshotMutationTerrainMutated`;
- `goalSnapshotMutationBounded`;
- `goalSnapshotMutationDeterministicOrder`;
- `goalSnapshotMutationDigestsEqual`;
- `goalSnapshotMutationRepeatabilityFailures`.

## Future Events Contract

Primary future event:

- `lab_goal_snapshot_mutation_recorded`

Minimum fields:

- `success`;
- `agentId`;
- `tick`;
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
- `dryRun`.

Optional summary event:

- `lab_goal_snapshot_mutation_summary_recorded`

Suggested fields:

- `success`;
- `agents`;
- `ticks`;
- `inputs`;
- `decisions`;
- `attempts`;
- `appliedToSnapshot`;
- `snapshotGoalChanged`;
- `snapshotNoops`;
- `rejected`;
- `deferred`;
- `appliedToLive`;
- `dryRun`;
- `bounded`;
- `digestsEqual`;
- `repeatabilityFailures`.

## Future Invariant Contract

Minimum checks for Phase 5.10B:

- scenario name expected;
- seed recorded;
- report success;
- agents expected;
- inputs positive;
- decisions positive;
- snapshot mutation attempted covered;
- applied to snapshot covered;
- snapshot goal changed covered;
- snapshot no-op covered;
- rejected covered;
- deferred covered if implemented;
- applied to live zero;
- live agent not mutated;
- live goal after equals original live goal;
- memory not mutated;
- movement stack not used;
- no World mutation;
- no terrain mutation;
- goal before/after audited;
- target goal audited;
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

## Recommended Phase 5.10B

Recommended next implementation:

`Phase 5.10B — Goal Application Snapshot Mutation Fixture Smoke`

Probable new scenario:

- `goal_application_snapshot_mutation_fixture_smoke`

Objective:

Create a fixture that consumes goal application dry-run decisions, applies a
goal change only to copied/snapshot state, and proves the live goal does not
change.

The fixture should:

- create five to seven snapshot mutation inputs;
- cover `appliedToSnapshot=true`;
- cover `snapshotGoalChanged=true`;
- cover snapshot no-op;
- cover rejected unknown target;
- cover rejected `wouldApplyGoalChange=false`;
- cover rejected dry-run decision with rejected reasons;
- cover audit-only deferred if simple;
- keep `appliedToLive=0`;
- keep `liveAgentMutated=false`;
- keep `memoryMutated=false`;
- avoid movement stack calls;
- avoid World and terrain mutation;
- remain deterministic.

Future outputs:

- `goal_snapshot_mutation_report.json`;
- `goal_snapshot_mutation_invariant_report.json`;
- `goal_snapshot_mutation_policies.json`;
- `goal_snapshot_mutation_inputs.json`;
- `goal_snapshot_mutation_decisions.json`;
- `goal_snapshot_mutation_digest.json`;
- `metrics.json`;
- `events.ndjson`.

## Risks

- confusing snapshot mutation with live mutation;
- changing a true `LabAgent` too early;
- forgetting to compare `liveGoalAfter` with `originalLiveGoalBefore`;
- treating a goal change as an action;
- accidentally triggering movement stack;
- writing a transition memory too early;
- forgetting no-op cases;
- omitting rejected or deferred reasons;
- depending on nondeterministic order;
- growing `main.swift` instead of keeping orchestration thin.

## Explicit Out Of Scope

- no `agents_basic` integration;
- no live agent mutation;
- no live applied goal changes;
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

## Definition Of Done For 5.10A

- Document created.
- Changelog updated.
- Dev journal updated.
- Roadmap updated.
- Cognitive resync plan updated if useful.
- 5.9A goal dry-run plan updated if useful.
- No Swift files changed.
- No runtime behavior changed.
- No scenarios added.
- `swift build` passes if possible.
- `swift build -c release --product Pebble` passes.
- `git diff --check` passes.
- Next phase 5.10B is clearly specified.
