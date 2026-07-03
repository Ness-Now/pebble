# Phase 5.8A — Live Cognitive Loop Controlled Application Planning

## Purpose

Phase 5.8A defines the v0 contract for a controlled application layer between:

- dry-run application plans;
- eligibility checks;
- controlled application decisions;
- future live application.

The goal is to move from:

```text
computed application plan
-> wouldChangeGoal / wouldSelectAction / wouldWriteMemory
-> applied flags always false
```

to:

```text
computed application plan
-> eligibility checks
-> eligible / rejected / deferred application decision
-> audit report
-> no live mutation yet
```

This phase is planning-only. It adds no Swift runtime, no scenario, no runtime
metrics, no runtime events, no `LabAgent` mutation path, no `agents_basic`
integration, no movement stack call, no World mutation, no terrain mutation,
no mood, no relationships, no communication, no Python, no LLM, no embeddings,
and no RL.

## Starting Point

Phase 5.6B and Phase 5.6C created and hardened the fixture-only cognitive loop
integration:

```text
retrieval
-> goal selection
-> bridge
-> behavior result
-> memory update
```

That chain includes accepted and rejected memory writes, before/after memory
snapshots, no behavior action execution, no memory mutation outside
`LabMemoryUpdate`, no movement stack, and no World or terrain mutation.

Phase 5.7B implemented `live_cognitive_loop_adapter_fixture_smoke`. It created
five live-like adapter agents, five read-only snapshots, five decisions, and
five dry-run application plans. Those plans record `wouldChangeGoal`,
`wouldSelectAction`, and `wouldWriteMemory`, while keeping
`appliedGoalChange=false`, `appliedAction=false`, and
`appliedMemoryWrite=false`.

Phase 5.7C implemented `live_cognitive_loop_adapter_hardening_smoke`. It
expanded coverage to 23 hardening cases, seven read-only snapshots, seven
decisions, and seven application plans. It covers unknown computed goal
sanitization, missing computed action fallback, no-write plans, unchanged
goals, forced `dryRun=true`, all applied flags zero, no live agent mutation,
no memory mutation, no movement stack, no World mutation, and no terrain
mutation.

Phase 5.8A prepares the safety gate that can later decide whether a dry-run
application plan is eligible, rejected, or deferred. It does not apply any
decision.

## Current Adapter State

`LabLiveCognitiveLoopAdapter.swift` currently owns the live adapter dry-run
fixtures.

Current adapter inputs:

- `LabLiveCognitiveLoopAdapterInput`;
- `tick`;
- `agentId`;
- `liveAgentSummary`;
- `currentGoal`;
- `needsSummary`;
- `fear`;
- `health`;
- `memorySummary`;
- `observationSummary`;
- `dryRun`;
- `maxRetrievedMemories`;
- `maxGoalCandidates`;
- `maxMemoryWritesPerTick`;
- `reason`.

Current adapter snapshots:

- `LabLiveCognitiveLoopAdapterSnapshot`;
- `agentType`;
- `positionSummary`;
- `currentGoal`;
- `needsSummary`;
- `fear`;
- `health`;
- `memoryCount`;
- `nearbyAgentCount`;
- `observationAvailable`;
- `snapshotReadOnly`;
- `success`.

Current application plans:

- `LabLiveCognitiveLoopApplicationPlan`;
- `computedSelectedGoal`;
- `computedSelectedAction`;
- `computedBehaviorResult`;
- `proposedMemoryWrites`;
- `wouldChangeGoal`;
- `wouldSelectAction`;
- `wouldWriteMemory`;
- `appliedGoalChange`;
- `appliedAction`;
- `appliedMemoryWrite`;
- `dryRun`;
- `reason`.

Current boundary flags in reports:

- `dryRun=true`;
- `liveAgentMutated=false`;
- `memoryMutated=false`;
- `movementStackUsed=false`;
- `worldMutated=false`;
- `terrainMutated=false`.

Current limitations:

- application plans are computed only;
- no selected goal is applied to a live agent;
- no selected action is applied to a live agent;
- no live memory is written;
- no movement intent is produced;
- `agents_basic` remains unchanged.

## Problem To Solve

Dry-run application plans prove what the cognitive loop would do. They do not
yet define which parts are safe to apply later.

Problems to solve before implementation:

- add an eligibility layer between computed plans and applied decisions;
- separate computed, eligible, rejected, deferred, and applied states;
- treat goal changes, action selection, and memory writes as different risk
  classes;
- reject or defer unsafe plans with explicit reasons;
- prevent silent live agent mutation;
- prevent silent live memory mutation;
- prevent movement intent from leaking through action eligibility;
- keep `agents_basic` unchanged;
- preserve deterministic ordering and digest evidence;
- avoid turning `main.swift` into an application-policy owner.

## Controlled Application Contract V0

Input:

- dry-run application plan;
- live agent snapshot read-only view;
- safety policy;
- allowed application modes;
- `dryRun` / `applyMode`;
- `maxApplicationsPerTick`;
- `allowedGoalChanges`;
- `allowedActions`;
- `allowedMemoryWrites`.

Output:

- eligibility decision;
- `applyGoalChangeAllowed`;
- `applyActionAllowed`;
- `applyMemoryWriteAllowed`;
- rejected reasons;
- deferred reasons;
- controlled application report;
- applied flags all false for Phase 5.8B;
- deterministic digest.

Important v0 rule: Phase 5.8B must remain fixture-only and dry-run-like. Even
if a decision is eligible, it must not be applied to a live agent.

## Proposed Types For Future Implementation

These types are proposed for Phase 5.8B or later. They are not implemented in
Phase 5.8A.

### `LabControlledApplicationPolicy`

Suggested fields:

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

Purpose: define which computed application plan components may become
eligible under a specific fixture policy.

### `LabControlledApplicationInput`

Suggested fields:

- `tick`;
- `agentId`;
- `snapshotSummary`;
- `applicationPlan`;
- `policy`;
- `reason`.

Purpose: bind one read-only snapshot, one application plan, and one policy into
an auditable eligibility request.

### `LabControlledApplicationEligibility`

Suggested fields:

- `tick`;
- `agentId`;
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

Purpose: record what would be allowed by policy without applying it.

### `LabControlledApplicationDecision`

Suggested fields:

- `tick`;
- `agentId`;
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

Purpose: prove that eligibility was evaluated and no live side effect occurred.

### `LabControlledApplicationReport`

Suggested fields:

- `scenario`;
- `seed`;
- `agents`;
- `ticks`;
- `policies`;
- `inputs`;
- `eligibilities`;
- `decisions`;
- `eligibleGoalChanges`;
- `eligibleActions`;
- `eligibleMemoryWrites`;
- `rejectedApplications`;
- `deferredApplications`;
- `appliedGoalChanges`;
- `appliedActions`;
- `appliedMemoryWrites`;
- `appliedAnything`;
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

Purpose: summarize the fixture-only controlled application safety gate.

## Application Modes V0

Allowed mode names:

- `dry_run_only`;
- `eligibility_only`;
- `audit_only`;
- future `apply_goal_only`;
- future `apply_memory_only`;
- future `apply_action_intent_only`.

Recommended mode for Phase 5.8B:

- `eligibility_only`.

No mode should apply anything in Phase 5.8B. Future apply modes should remain
documented but inactive until a dedicated phase explicitly allows them.

## Eligibility Rules V0

Goal change is eligible only if:

- `computedSelectedGoal` is known;
- `wouldChangeGoal=true`;
- policy `allowGoalChange=true`;
- current goal differs from computed goal;
- reason is non-empty;
- snapshot is read-only;
- dry-run or eligibility-only mode is active.

Action selection is eligible only if:

- `computedSelectedAction` is known;
- `wouldSelectAction=true`;
- policy `allowActionSelection=true`;
- action is abstract only;
- no movement intent is produced;
- reason is non-empty.

Memory write is eligible only if:

- `wouldWriteMemory=true`;
- policy `allowMemoryWrite=true`;
- `proposedMemoryWrites > 0`;
- `maxMemoryWritesPerTick` is respected;
- no live memory mutation occurs in v0.

Reject if:

- computed goal is unknown;
- computed action is unknown;
- reason is missing;
- snapshot is not read-only;
- policy disallows the operation;
- `maxApplicationsPerTick` is exceeded;
- `dryRun=false` in a phase that requires dry-run or eligibility-only mode.

Deferred decisions are allowed when:

- a plan is well-formed but policy defers it;
- an operation should wait for a later live-application phase;
- a future dependency such as action-intent ownership is not available yet.

## Applied Rules V0

For Phase 5.8B:

- `appliedGoalChange=false`;
- `appliedAction=false`;
- `appliedMemoryWrite=false`;
- `appliedAnything=false`;
- `liveAgentMutated=false`;
- `memoryMutated=false`;
- `movementStackUsed=false`;
- `worldMutated=false`;
- `terrainMutated=false`.

Even eligible decisions are not applied yet. Eligibility is evidence, not
execution.

## Relationship With Live Adapter

Controlled application consumes application plans from
`LabLiveCognitiveLoopAdapter`.

It does not replace the adapter. It adds a safety gate between:

```text
wouldChangeGoal / wouldSelectAction / wouldWriteMemory
```

and:

```text
appliedGoalChange / appliedAction / appliedMemoryWrite
```

Phase 5.8B should probably use synthetic application plans or outputs shaped
like the 5.7B/5.7C plans. It should not require live `agents_basic` state.

## Relationship With agents_basic

`agents_basic` remains unchanged.

Phase 5.8B must use a dedicated scenario. It must not change normal live
behavior, alter live agent goals/actions/memory, or become a hidden branch in
the existing agent tick path.

## Relationship With Movement Stack

Action eligibility does not mean movement intent.

Out of scope:

- movement stack calls;
- route following;
- reservations;
- pathfinding;
- physical movement;
- Core entity movement;
- placeholder movement;
- World mutation;
- terrain mutation.

If a future action sounds movement-related, Phase 5.8B should still treat it as
an abstract eligibility record only.

## Relationship With Mood / Relations / LLM

Controlled application is a safety gate for future cognition. It may later
protect how memory-informed decisions reach live systems.

Still out of scope:

- mood;
- emotional memory;
- relationships;
- trust;
- communication;
- community state;
- social plans;
- LLM context;
- Python;
- embeddings;
- RL.

## Future Metrics Contract

Prefix:

```text
controlledApplication*
```

Proposed metrics:

- `controlledApplicationSuccess`;
- `controlledApplicationAgents`;
- `controlledApplicationTicks`;
- `controlledApplicationPolicies`;
- `controlledApplicationInputs`;
- `controlledApplicationEligibilities`;
- `controlledApplicationDecisions`;
- `controlledApplicationEligibleGoalChanges`;
- `controlledApplicationEligibleActions`;
- `controlledApplicationEligibleMemoryWrites`;
- `controlledApplicationRejectedApplications`;
- `controlledApplicationDeferredApplications`;
- `controlledApplicationAppliedGoalChanges`;
- `controlledApplicationAppliedActions`;
- `controlledApplicationAppliedMemoryWrites`;
- `controlledApplicationAppliedAnything`;
- `controlledApplicationDryRun`;
- `controlledApplicationLiveAgentMutated`;
- `controlledApplicationMemoryMutated`;
- `controlledApplicationMovementStackUsed`;
- `controlledApplicationWorldMutated`;
- `controlledApplicationTerrainMutated`;
- `controlledApplicationBounded`;
- `controlledApplicationDeterministicOrder`;
- `controlledApplicationDigestsEqual`;
- `controlledApplicationRepeatabilityFailures`.

## Future Events Contract

Primary future event:

```text
lab_controlled_application_recorded
```

Minimum fields:

- `success`;
- `agentId`;
- `tick`;
- `computedSelectedGoal`;
- `computedSelectedAction`;
- `goalChangeEligible`;
- `actionSelectionEligible`;
- `memoryWriteEligible`;
- `eligible`;
- `rejectedReasons`;
- `deferredReasons`;
- `appliedGoalChange`;
- `appliedAction`;
- `appliedMemoryWrite`;
- `appliedAnything`;
- `dryRun`;
- `liveAgentMutated`;
- `movementStackUsed`.

Optional summary event:

```text
lab_controlled_application_summary_recorded
```

Fields:

- `success`;
- `agents`;
- `ticks`;
- `eligibilities`;
- `decisions`;
- `eligibleGoalChanges`;
- `eligibleActions`;
- `eligibleMemoryWrites`;
- `rejectedApplications`;
- `deferredApplications`;
- `appliedGoalChanges`;
- `appliedActions`;
- `appliedMemoryWrites`;
- `appliedAnything`;
- `dryRun`;
- `bounded`;
- `digestsEqual`;
- `repeatabilityFailures`.

## Future Invariant Contract

Minimum checks for Phase 5.8B:

- scenario name expected;
- seed recorded;
- report success;
- agents expected;
- ticks expected;
- policies positive;
- inputs positive;
- eligibilities positive;
- decisions positive;
- eligibility true covered;
- rejection covered;
- deferred covered if implemented;
- goal eligibility covered;
- action eligibility covered;
- memory write eligibility covered;
- applied goal changes zero;
- applied actions zero;
- applied memory writes zero;
- applied anything false;
- dryRun true;
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
- eligibilities written;
- decisions written;
- digest written;
- metrics written;
- event written.

## Recommended Phase 5.8B

Phase 5.8B should implement:

```text
Phase 5.8B — Live Cognitive Loop Controlled Application Fixture Smoke
```

Likely new scenario:

```text
live_cognitive_loop_controlled_application_fixture_smoke
```

Objective:

Create a fixture that takes dry-run application plans, applies an eligibility
policy, produces eligibility decisions, and applies nothing.

The fixture should:

- create 4 to 6 application plans, either synthetic or shaped from the live
  adapter fixture;
- cover goal eligibility;
- cover action eligibility;
- cover memory write eligibility;
- cover policy rejection;
- cover unknown goal rejection;
- cover a no-write plan;
- keep `appliedGoalChange=0`;
- keep `appliedAction=0`;
- keep `appliedMemoryWrite=0`;
- keep `appliedAnything=false`;
- keep `dryRun=true`;
- keep `liveAgentMutated=false`;
- keep `memoryMutated=false`;
- not call movement stack;
- not mutate World;
- remain deterministic.

Future outputs:

- `controlled_application_report.json`;
- `controlled_application_invariant_report.json`;
- `controlled_application_policies.json`;
- `controlled_application_eligibilities.json`;
- `controlled_application_decisions.json`;
- `controlled_application_digest.json`;
- `metrics.json`;
- `events.ndjson`.

## Risks

- confusing eligibility with real application;
- applying goal/action/memory too early;
- branching `agents_basic` too early;
- introducing movement intent through action eligibility;
- hiding live mutation behind copied structs;
- making policies too permissive;
- omitting rejected reasons;
- depending on dictionary or set order;
- growing `main.swift` instead of adding a focused fixture helper.

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

## Definition Of Done For 5.8A

- document created;
- changelog updated;
- dev journal updated;
- roadmap updated;
- cognitive resync plan updated if useful;
- 5.7A live adapter plan updated if useful;
- no Swift files changed;
- no runtime behavior changed;
- no scenarios added;
- `swift build` passes if possible;
- `swift build -c release --product Pebble` passes;
- `git diff --check` passes;
- next phase 5.8B is clearly specified.

## Phase 5.8B Implementation Status

Scenario:

- `live_cognitive_loop_controlled_application_fixture_smoke`.

Policies and inputs:

- creates controlled application policies for eligibility-only, policy-denied,
  and audit-only flows;
- creates dry-run application-plan-shaped inputs covering goal changes, action
  selection, memory writes, no-write plans, unknown values, and missing
  reasons.

Eligibilities:

- covers goal-change eligibility;
- covers action-selection eligibility;
- covers memory-write eligibility;
- covers policy rejection;
- covers unknown goal rejection;
- covers unknown action rejection;
- covers missing reason rejection;
- covers audit-only deferral.

Controlled decisions:

- every decision remains dry-run;
- `appliedGoalChange=false`;
- `appliedAction=false`;
- `appliedMemoryWrite=false`;
- `appliedAnything=false`.

Outputs:

- `controlled_application_report.json`;
- `controlled_application_invariant_report.json`;
- `controlled_application_policies.json`;
- `controlled_application_eligibilities.json`;
- `controlled_application_decisions.json`;
- `controlled_application_digest.json`;
- `metrics.json`;
- `events.ndjson`.

Metrics/events:

- metrics use the `controlledApplication*` prefix;
- the primary event is `lab_controlled_application_recorded`;
- the optional summary event is
  `lab_controlled_application_summary_recorded`.

Boundary flags:

- `dryRun=true`;
- `liveAgentMutated=false`;
- `memoryMutated=false`;
- `movementStackUsed=false`;
- `worldMutated=false`;
- `terrainMutated=false`.

Limitations:

- no live `agents_basic` integration;
- no live agent mutation;
- no applied goal changes;
- no applied actions;
- no applied memory writes;
- no live memory update;
- no movement stack;
- no World or terrain mutation;
- no mood, relationships, communication, community state, Python, LLM,
  embeddings, or RL.

Next phase: Phase 5.8C - Live Cognitive Loop Controlled Application
Hardening.

## Phase 5.8C Implementation Status

Scenario:

- `live_cognitive_loop_controlled_application_hardening_smoke`.

Cases:

- 25 hardening cases;
- baseline compatibility with the Phase 5.8B fixture;
- goal/action/memory-write eligibility;
- policy goal/action/memory rejection;
- unknown goal/action rejection;
- missing reason rejection;
- snapshot-not-read-only rejection;
- max applications and max memory writes rejection;
- dry-run false rejection;
- audit-only deferral;
- no-write and unchanged-goal no-op coverage;
- rejected/deferred reason presence;
- applied flags zero;
- no mutation boundaries;
- deterministic order, bounded output, and digest repeatability.

Policies:

- eligibility-only policies remain dry-run;
- audit-only policies defer decisions;
- negative policies exercise denied goal/action/memory permissions and
  rejected dry-run or snapshot states.

Eligibilities:

- `eligibleGoalChanges=1`;
- `eligibleActions=1`;
- `eligibleMemoryWrites=1`;
- rejected applications and deferred applications are both covered.

Controlled decisions:

- every decision remains audit-only / eligibility-only;
- no decision applies a goal, action, or memory write.

Applied rules:

- `appliedGoalChange=false`;
- `appliedAction=false`;
- `appliedMemoryWrite=false`;
- `appliedAnything=false`.

Outputs:

- `controlled_application_hardening_report.json`;
- `controlled_application_hardening_invariant_report.json`;
- `controlled_application_hardening_cases.json`;
- `controlled_application_hardening_policies.json`;
- `controlled_application_hardening_eligibilities.json`;
- `controlled_application_hardening_decisions.json`;
- `controlled_application_hardening_digest.json`;
- `metrics.json`;
- `events.ndjson`.

Metrics/events:

- metrics use the `controlledApplicationHardening*` prefix;
- the primary event is
  `lab_controlled_application_hardening_recorded`.

Boundary flags:

- `dryRun=true`;
- `liveAgentMutated=false`;
- `memoryMutated=false`;
- `movementStackUsed=false`;
- `worldMutated=false`;
- `terrainMutated=false`.

Limitations:

- no live `agents_basic` integration;
- no live agent mutation;
- no applied goal changes;
- no applied actions;
- no applied memory writes;
- no live memory update;
- no movement stack;
- no World or terrain mutation;
- no mood, relationships, communication, community state, Python, LLM,
  embeddings, or RL.

Next phase: Phase 5.9A - Goal Application Dry-Run Planning.

## Phase 5.9A Planning Link

Phase 5.9A specializes the first future application path after controlled
application: goal application dry-run.

It consumes controlled application decisions where `goalChangeEligible=true`
and defines how Phase 5.9B should audit `goalBefore`, `targetGoal`, reason,
rejected/deferred status, and `wouldApplyGoalChange`, while keeping
`appliedGoalChange=false`, live agents unmutated, memory unmutated, movement
stack unused, World/terrain unmutated, and `agents_basic` unchanged.

Recommended next implementation after this planning layer:

- Phase 5.9B — Goal Application Dry-Run Fixture Smoke.
