# Phase 4.28 - Agent Movement Stack Consolidation Plan

## Scope

Phase 4.28A is documentation-only. It prepares a future PebbleLab
`AgentMovementStack` consolidation layer without implementing that layer,
without adding scenarios, and without changing any behavior.

The purpose is to document the architecture that now exists across movement
intent production, feedback consumption, feedback-aware policy, multi-tick
closed loop, alternate local hints, movement policy consolidation, and bounded
path planning. The plan defines where a future stack adapter may sit, what it
may orchestrate, and which boundaries must remain explicit.

This phase does not touch gameplay, World, PebbleCore, renderer, resources,
registries, save/load, or goldens. It does not modify Swift. It does not add
metrics, events, runners, route following, full-route execution, live
pathfinding, reservation runtime, memory, goals, social behavior,
communication, Python, LLM, RL, or gameplay movement.

## Current Stack Summary

| Phase | Scenario / Artifact | What it proved | Mutation boundary | Status |
| --- | --- | --- | --- | --- |
| 4.21A | `PHASE_4_AGENT_INTENT_PRODUCTION_PLAN.md` | Planned future agent intent production before implementation. | Docs-only, no runtime mutation. | Implemented |
| 4.21B | `agent_intent_production_fixture_smoke` | Deterministic fixture intent proposals and accepted intents. | No World, no movement. | Implemented |
| 4.21C | `agent_intent_production_hardening_smoke` | Duplicate, stale, invalid, wrong-source, and ordering hardening. | No World, no movement. | Implemented |
| 4.21D | `agent_intent_to_tick_fixture_smoke` | Accepted intents can feed tick fixture and same-destination conflict is tick-owned. | No movement application. | Implemented |
| 4.21E | `agent_intent_to_tick_live_readonly_smoke` | Tick layer can read live collision evidence from produced intents. | World read-only at tick, no movement. | Implemented |
| 4.21F | `agent_intent_to_tick_approved_application_smoke` | Tick-approved movements can apply to lab maps only. | Lab maps only, no terrain/World mutation. | Implemented |
| 4.22A | `PHASE_4_FEEDBACK_CONSUMPTION_PLAN.md` | Planned bounded feedback observation before behavior changes. | Docs-only, no runtime mutation. | Implemented |
| 4.22B | `agent_feedback_consumption_fixture_smoke` | Synthetic feedback becomes bounded contexts. | No movement, no collision read, no intent production. | Implemented |
| 4.22C | `agent_feedback_consumption_hardening_smoke` | Duplicate, malformed, max feedback, tick mismatch, all kinds, repeatability. | No World, no movement, no memory/goals. | Implemented |
| 4.22D | `feedback_to_agent_intent_context_fixture_smoke` | Feedback contexts can populate `LabAgentIntentContext.lastFeedback`. | Policy behavior unchanged. | Implemented |
| 4.22E | `feedback_to_agent_intent_context_hardening_smoke` | Feedback-to-context plumbing remains stable across edge cases. | Policy still ignores feedback. | Implemented |
| 4.22F | `PHASE_4_FEEDBACK_AWARE_INTENT_POLICY_PLAN.md` | Planned future feedback-aware policy boundaries. | Docs-only, no runtime mutation. | Implemented |
| 4.23A | `feedback_aware_intent_policy_fixture_smoke` | Opt-in v1 keeps baseline for no feedback/moved/approved and returns noIntent for blocked feedback. | Policy-only, no World/tick/movement. | Implemented |
| 4.23B | `feedback_aware_intent_policy_hardening_smoke` | v1 opt-in, ordering, repeatability, and baseline comparison. | No World/tick/movement. | Implemented |
| 4.23C | `feedback_aware_intent_to_tick_fixture_smoke` | v1 noIntent reduces tick inputs while tick owns remaining conflicts. | Tick fixture only, no movement. | Implemented |
| 4.23D | `feedback_aware_intent_to_tick_live_readonly_smoke` | Tick live read-only evidence remains tick-owned. | World read-only at tick, no movement. | Implemented |
| 4.23E | `feedback_aware_intent_to_tick_approved_application_smoke` | v1 proposals can feed approved lab-map application. | Lab maps only, no terrain/World mutation. | Implemented |
| 4.24A | `PHASE_4_MULTI_TICK_CLOSED_LOOP_PLAN.md` | Planned feedback N to N+1 closed-loop orchestration. | Docs-only, no runtime mutation. | Implemented |
| 4.24B | `multi_tick_closed_loop_fixture_smoke` | Fixed multi-tick loop with previous feedback consumption. | Fixture-only, no World. | Implemented |
| 4.24C | `multi_tick_closed_loop_hardening_smoke` | Missing, duplicate, stale, ordering, repeatability, and leak hardening. | No World/mutation. | Implemented |
| 4.24D | `multi_tick_closed_loop_live_readonly_smoke` | Tick layer reads live collision read-only across ticks. | World read-only at tick, no movement. | Implemented |
| 4.24E | `multi_tick_closed_loop_approved_application_smoke` | Approved moves apply to lab maps across ticks and feedback feeds next tick. | Lab maps only, no terrain/World mutation. | Implemented |
| 4.25A | `PHASE_4_ALTERNATE_LOCAL_HINT_PLAN.md` | Planned deterministic bounded alternate local hints. | Docs-only, no runtime mutation. | Implemented |
| 4.25B | `alternate_local_hint_fixture_smoke` | Opt-in v2 can select bounded local alternates. | Policy/fixture only, no World. | Implemented |
| 4.25C | `alternate_local_hint_hardening_smoke` | Unknown, empty, duplicate, bounds, all blocked kinds, repeatability. | No World/collision/movement. | Implemented |
| 4.25D | `alternate_local_hint_live_readonly_smoke` | Alternate hints feed tick live read-only while policy reads no World. | World read-only at tick, no movement. | Implemented |
| 4.25E | `alternate_local_hint_approved_application_smoke` | Approved alternate first steps apply only to lab maps. | Lab maps only, no terrain/World mutation. | Implemented |
| 4.25F | `alternate_local_hint_multi_tick_replay_smoke` | Alternate local hint replay remains deterministic across ticks. | Lab maps only where approved, no route following. | Implemented |
| 4.26A | `PHASE_4_AGENT_MOVEMENT_POLICY_CONSOLIDATION_PLAN.md` | Planned policy boundary consolidation before new behavior. | Docs-only, no runtime mutation. | Implemented |
| 4.26B | `agent_movement_policy_consolidation_fixture_smoke` | Consolidated policy signatures can wrap v0/v1/v2 without drift. | No World/tick/movement. | Implemented |
| 4.26C | `agent_movement_policy_boundary_hardening_smoke` | Boundary flags remain explicit across policy modes. | No hidden activation. | Implemented |
| 4.26D | `agent_movement_policy_consolidated_replay_regression_smoke` | Consolidated replay digests prove policy/tick/application equivalence. | Lab maps only where approved, no World mutation. | Implemented |
| 4.27A | `PHASE_4_BOUNDED_PATH_PLANNING_PLAN.md` | Planned bounded fixture-first path planning. | Docs-only, no runtime mutation. | Implemented |
| 4.27B | `bounded_path_planning_fixture_smoke` | Fixture-only bounded plans with max steps/nodes and stable digest. | No tick/application/movement. | Implemented |
| 4.27C | `bounded_path_planning_hardening_smoke` | Bounded planner hardening for max steps/nodes, blocks, directions, repeatability. | No tick/application/movement. | Implemented |
| 4.27D | `bounded_path_planning_to_tick_first_step_smoke` | Only selected first step is handed to tick fixture. | No application. | Implemented |
| 4.27E | `bounded_path_planning_approved_application_smoke` | Only approved first steps apply to lab maps. | Lab maps only, no terrain/World mutation. | Implemented |
| 4.27F | `bounded_path_planning_multi_tick_replay_smoke` | Replan each tick, feedback N to N+1, no persistent route commitment. | Lab maps only where approved, no route following. | Implemented |

## Conceptual Stack Layers

### AgentSnapshotLayer

Responsibility: capture deterministic per-agent state for the current tick.

Inputs: lab abstract positions, lab physical positions, stable agent ids,
roles, fixture targets, local hints, policy mode, and scenario seed.

Outputs: stable agent snapshots sorted by agent id.

Boundary: does not read World, collision, memory, goals, registries, or live
entities. It does not mutate positions.

Current scenarios proving it: multi-tick closed loop, alternate local hint
multi-tick replay, movement policy consolidated replay, and bounded path
planning multi-tick replay.

Future consolidation risk: snapshots could become implicit memory if they
start carrying prior route state or unbounded history.

### FeedbackLedgerLayer

Responsibility: store emitted feedback by tick and expose only previous-tick
feedback to the next tick.

Inputs: tick/application feedback from tick N, stable agent ids, expected next
tick.

Outputs: feedback observations and feedback contexts for tick N+1.

Boundary: no same-tick consumption, no future consumption, no cross-agent leak,
no memory/goals mutation.

Current scenarios proving it: feedback consumption fixture/hardening,
feedback-to-context fixture/hardening, multi-tick closed loop, alternate local
hint replay, and bounded path planning replay.

Future consolidation risk: feedback may accidentally become durable memory or
may be consumed in the same tick if adapter boundaries blur.

### IntentContextLayer

Responsibility: build `LabAgentIntentContext` values from snapshots, local
hints, roles, and previous feedback.

Inputs: agent snapshots, feedback contexts, local hints, policy mode.

Outputs: deterministic intent contexts sorted by stable agent id.

Boundary: context construction does not decide movement, read World, read
collision, apply movement, or mutate memory/goals.

Current scenarios proving it: feedback-to-agent-intent context fixture and
hardening, feedback-aware policy fixture and hardening.

Future consolidation risk: context construction may start adapting behavior
instead of preserving policy responsibility.

### MovementPolicyLayer

Responsibility: convert an intent context into a movement proposal according
to an explicit opt-in policy version.

Inputs: intent context, policy mode, previous feedback, local hints.

Outputs: baseline/noIntent/movement proposal plus policy signature.

Boundary: no World/collision reads, no tick arbitration, no application, no
reservation runtime, no memory/goals mutation.

Current scenarios proving it: 4.21 intent production, 4.23 v1, 4.25 v2, and
4.26 policy consolidation.

Future consolidation risk: v3 or future v4 could become globally active or
silently replace v0/v1/v2.

### BoundedPlanningLayer

Responsibility: produce a bounded abstract plan in fixture space and select a
first step.

Inputs: abstract fixture planning context, start, target, maxSteps, maxNodes,
blocked cells, allowed directions, deterministic neighbor order.

Outputs: bounded plan, selected first step, digest, boundary flags.

Boundary: no live World scan, no collision read, no route following, no
persistent route commitment, no full-route execution.

Current scenarios proving it: bounded path planning fixture, hardening,
first-step handoff, approved application, and multi-tick replay.

Future consolidation risk: bounded planning could drift into live pathfinding
or route following if advisory steps are treated as executable state.

### FirstStepHandoffLayer

Responsibility: convert only the selected first step of a current plan into a
movement intent.

Inputs: current tick plan, selected first step, stable agent id.

Outputs: movement intent for tick fixture/live mode, or no handoff.

Boundary: advisory steps are not sent, future route steps are not sent, and no
movement is applied here.

Current scenarios proving it: planning-to-tick first-step handoff, bounded
approved application, bounded multi-tick replay.

Future consolidation risk: a future adapter could send a full route to tick or
auto-apply second steps.

### TickArbitrationLayer

Responsibility: approve or deny one-edge movement intents.

Inputs: tick input, agent positions, movement intents, fixture or live
read-only collision evidence depending scenario.

Outputs: resolutions and structured feedback.

Boundary: tick owns same-destination conflicts and, in live read-only modes,
collision evidence. It does not run pathfinding or route following.

Current scenarios proving it: movement tick fixture/live/approved application,
agent intent to tick, feedback-aware intent to tick, multi-tick closed loop,
alternate local hint, and bounded first-step handoff.

Future consolidation risk: policy or planning adapters may start pre-arbitrating
conflicts or assuming live collision results.

### ApprovedApplicationLayer

Responsibility: apply only tick-approved one-edge movement to lab abstract and
physical position maps.

Inputs: tick resolutions, selected first steps, current lab maps.

Outputs: updated lab maps and application records.

Boundary: no World mutation, no terrain mutation, no Core entity movement, no
physical placeholder movement, and no full-route execution.

Current scenarios proving it: tick approved application, feedback-aware
approved application, multi-tick approved application, alternate approved
application, bounded approved application, bounded replay.

Future consolidation risk: lab-map-only movement could be mistaken for gameplay
movement or live entity movement.

### ReplayRegressionLayer

Responsibility: run fixed deterministic replay loops and compare digests.

Inputs: scenario fixture definitions, tick count, seed, policy/planner mode.

Outputs: replay records, digest, repeat digest, repeatability result.

Boundary: fixed tick count only, no autonomous unbounded loop, no persistent
route state unless a future explicit scenario documents it.

Current scenarios proving it: policy consolidated replay, alternate local hint
multi-tick replay, bounded path planning multi-tick replay.

Future consolidation risk: replay could become a gameplay loop if tick count,
objectives, route commitments, or feedback history become unbounded.

### BoundaryAuditLayer

Responsibility: record and assert forbidden behavior flags.

Inputs: policy/planner/tick/application summaries, reports, invariant checks.

Outputs: boundary reports and invariant reports.

Boundary: audit only; it does not repair behavior or mutate runtime state.

Current scenarios proving it: policy boundary hardening, bounded planning
boundary reports, multi-tick replay invariant reports.

Future consolidation risk: boundary reports may drift from actual behavior if
flags are duplicated without a common schema.

### MetricsEventsReportsLayer

Responsibility: write aggregate JSON reports, metrics, events, digests, and
invariant reports.

Inputs: summaries from all layers.

Outputs: report JSON, invariant JSON, detailed records, metrics JSON,
events.ndjson.

Boundary: one aggregate event per scenario family unless explicitly planned;
no hidden runtime feature activation from reporting.

Current scenarios proving it: every 4.21-4.27 smoke/hardening/replay scenario.

Future consolidation risk: metric/event prefix drift or report schema drift
could hide behavior changes.

## Movement Policy Versions

`v0` is the baseline deterministic one-step local-hint policy. It reads role,
position, and local hints. It does not read feedback, World, collision,
memory, or goals.

`v1` is the feedback-aware filter. It is opt-in. No feedback, `moved`, and
`approvedForMovement` keep baseline behavior. `blockedBy*` feedback becomes
`noIntent`. It does not choose alternates and does not read World/collision.

`v2` is the alternate local hint policy. It is opt-in. No feedback, moved, and
approved feedback keep baseline behavior. Blocked feedback with a known hint
may select a deterministic bounded alternate local hint. Empty or unknown
hints produce no alternate/noIntent. It remains one-edge only.

`v3` is the bounded planning fixture mode. It is opt-in. It can produce a
bounded abstract fixture plan, but only the selected first step may be handed
to tick. Advisory steps are not executable route state.

`v4` is reserved and not implemented. It must not be introduced until the
stack consolidation boundaries are proven and a separate docs-only phase
defines its contract.

All versions must remain explicitly selected. No policy version may replace
another globally. No hidden activation, registry reorder, PebbleCore change, or
gameplay behavior change is allowed.

## Bounded Planning Contract

The 4.27 bounded planning contract is:

- fixture-only planning inputs;
- current `maxSteps <= 4`;
- current `maxNodes <= 32`;
- one-edge steps only;
- same-y steps only;
- deterministic neighbor order and tie-break;
- selected first step only may be handed to tick;
- advisory steps are not sent to tick;
- advisory steps are not applied;
- no persistent route commitment;
- replan each tick from current lab maps;
- no full-route execution;
- no route following;
- no live World scan;
- no live collision read;
- no terrain/World mutation.

Bounded planning produces an inspectable plan. It does not execute movement.
It does not own tick arbitration. It does not own approved application.

## Feedback Contract

The feedback contract is:

- feedback emitted at tick N may be consumed only at tick N+1;
- feedback emitted at tick N must not be consumed in the same tick;
- feedback from a future tick must not be consumed;
- feedback for one agent must not leak to another agent;
- duplicate feedback is handled deterministically;
- unknown or malformed feedback is ignored or rejected deterministically;
- feedback observation does not mutate memory;
- feedback observation does not mutate goals;
- feedback observation does not trigger learning, replanning, reservation, or
  route following.

Feedback is structured context for future policy inputs. It is not durable
agent memory and is not a planner.

## Application Contract

The approved application contract is:

- only tick-approved one-edge first steps may be applied;
- application is lab-map-only;
- abstract and physical lab maps must remain synchronized;
- denied agents are preserved;
- no-path agents are preserved;
- zero-step agents are preserved;
- source mismatch agents are preserved;
- stale intent agents are preserved;
- conflict-denied agents are preserved;
- `displacementsApplied` equals `tickApproved` in approved-application
  scenarios;
- World is not mutated;
- terrain is not mutated;
- Core entities are not moved;
- live physical placeholders are not moved.

Lab-map application is still not gameplay movement.

## Boundary Contract

The following flags must remain false unless a future phase explicitly
dedicates itself to that boundary and documents the exception:

- `worldRead`
- `collisionRead`
- `tickWorldReadOnlyUsed`
- `tickReadCollision`
- `routeFollowingUsed`
- `fullRouteExecutionUsed`
- `persistentRouteCommitmentUsed`
- `advisoryStepsApplied`
- `secondStepAutoApplied`
- `pathfindingLiveUsed`
- `unboundedSearchUsed`
- `dynamicReplanningUsed`
- `reservationRuntimeUsed`
- `memoryUpdated`
- `goalChanged`
- `terrainMutated`
- `worldMutated`
- `coreEntityMoved`
- `physicalPlaceholderMoved`
- `mutationPerformed`

Allowed exceptions:

- `tickUsed` may be true in tick fixture, tick live read-only, and approved
  application scenarios.
- `movementApplied` may be true only when the scenario explicitly applies
  approved movement to lab maps.
- `labPositionMapMutated` may be true only in approved application lab-map-only
  scenarios.

These allowed lab-map mutations must never touch World, terrain, Core
entities, or live physical placeholders.

## Consolidation Risks

- Accidentally turning v3 global.
- Hidden activation of a newer policy mode.
- Route following slipping in before a route-following spec exists.
- Advisory steps being applied.
- Stale feedback leaking into later ticks.
- Same-tick feedback consumption.
- Cross-agent feedback leak.
- Full-route execution.
- World/collision coupling inside policy or planner layers.
- Core entity movement.
- Live physical placeholder movement.
- Metrics inconsistency between family reports.
- Report schema drift across scenario families.
- Deterministic digest instability.
- Performance issues from unbounded search.
- Overfitting fixture names instead of asserting semantic boundaries.

Mitigation: keep policy modes explicit, keep fixture definitions small, keep
tick counts fixed, keep boundary reports mandatory, compare digests, preserve
existing scenarios, and add consolidation scenarios before adding new behavior.

## Proposed Phase 4.28 Roadmap

### 4.28A - Agent Movement Stack Consolidation Plan

Objective: document the target stack architecture, boundaries, risks, and
future migration path.

Allowed files: PebbleLab documentation only.

Forbidden files: `Sources/`, PebbleCore, renderer, shaders, resources,
registries, save/load, goldens.

Expected scenario name: none.

Expected outputs: this plan, changelog entry, dev journal entry, roadmap entry.

Success contract: docs-only diff, no behavior change, `git diff --check`
passes.

Boundaries: no Swift, no scenario, no runtime metrics/event.

### 4.28B - Stack Contract Fixture Smoke

Objective: introduce a fixture-only stack contract adapter that calls existing
layers without changing their behavior.

Allowed files: PebbleLab Swift and docs for the new scenario only.

Forbidden files: PebbleCore, renderer, resources, registries, save/load,
goldens, route following live.

Expected scenario name: `agent_movement_stack_contract_fixture_smoke`.

Expected outputs:

- `agent_movement_stack_contract_report.json`
- `agent_movement_stack_contract_invariant_report.json`
- `agent_movement_stack_contract_layers.json`
- `agent_movement_stack_contract_signatures.json`
- `metrics.json`
- `events.ndjson`

Success contract: v0/v1/v2/v3 direct signatures match stack-adapter
signatures; no World/collision/tick/application unless explicitly represented
as fixture summaries; no behavior drift.

Boundaries: no hidden policy activation, no movement application, no route
following, no memory/goals, no terrain/World mutation.

### 4.28C - Stack Contract Boundary Hardening

Objective: harden stack boundary flags across policy, planner, handoff, tick,
application, and replay summaries.

Allowed files: PebbleLab Swift and docs for hardening only.

Forbidden files: PebbleCore, renderer, resources, registries, save/load,
goldens.

Expected scenario name: `agent_movement_stack_boundary_hardening_smoke`.

Expected outputs:

- `agent_movement_stack_boundary_hardening_report.json`
- `agent_movement_stack_boundary_hardening_invariant_report.json`
- `agent_movement_stack_boundary_hardening_cases.json`
- `metrics.json`
- `events.ndjson`

Success contract: all forbidden flags remain false except documented lab-map
application/tick fixture allowances; boundary drift is detected.

Boundaries: no new movement behavior, no live pathfinding, no route following,
no World mutation.

### 4.28D - Stack Replay Regression Adapter

Objective: adapt existing replay records into a common stack replay schema and
compare digests without changing replay behavior.

Allowed files: PebbleLab Swift and docs for replay adapter only.

Forbidden files: PebbleCore, renderer, resources, registries, save/load,
goldens.

Expected scenario name: `agent_movement_stack_replay_adapter_smoke`.

Expected outputs:

- `agent_movement_stack_replay_adapter_report.json`
- `agent_movement_stack_replay_adapter_invariant_report.json`
- `agent_movement_stack_replay_adapter_digest.json`
- `metrics.json`
- `events.ndjson`

Success contract: existing replay digests remain stable; adapter digest is
deterministic; no same-tick/future/cross-agent feedback leaks.

Boundaries: fixed tick count, no autonomous loop, no persistent route
commitment, no full-route execution.

### 4.28E - Stack Metrics/Event Compatibility Smoke

Objective: prove consolidated stack summaries can emit compatibility metrics
and one aggregate event without replacing existing family metrics/events.

Allowed files: PebbleLab Swift and docs for compatibility output only.

Forbidden files: PebbleCore, renderer, resources, registries, save/load,
goldens.

Expected scenario name: `agent_movement_stack_metrics_event_compat_smoke`.

Expected outputs:

- `agent_movement_stack_metrics_event_compat_report.json`
- `agent_movement_stack_metrics_event_compat_invariant_report.json`
- `metrics.json`
- `events.ndjson`

Success contract: existing metrics remain available; stack metrics are
aggregate and clearly prefixed; no per-agent event spam; event includes policy
mode and boundary flags.

Boundaries: reporting must not activate features.

### 4.28F - Stack Consolidated Multi-Tick Replay Regression

Objective: run the stack adapter over a bounded multi-tick replay and prove it
matches existing direct bounded replay behavior.

Allowed files: PebbleLab Swift and docs for consolidated replay only.

Forbidden files: PebbleCore, renderer, resources, registries, save/load,
goldens.

Expected scenario name: `agent_movement_stack_consolidated_multi_tick_replay_smoke`.

Expected outputs:

- `agent_movement_stack_consolidated_multi_tick_replay_report.json`
- `agent_movement_stack_consolidated_multi_tick_replay_invariant_report.json`
- `agent_movement_stack_consolidated_multi_tick_replay_digest.json`
- `agent_movement_stack_consolidated_multi_tick_replay_boundary.json`
- `metrics.json`
- `events.ndjson`

Success contract: stack replay digest matches direct replay digest; feedback N
to N+1 holds; lab maps remain synchronized; no hidden policy activation; no
route following/full-route execution.

Boundaries: lab-map-only approved application where explicit, no World/Core
mutation, no physical placeholder movement, no memory/goals, no reservation
runtime.

## Future Route Following Gate

Route following is not introduced by 4.28A. It remains out of scope until a
future 4.29 or later docs-only gate explicitly approves it.

Before route following can be considered:

- stack consolidation must be implemented and validated;
- replay must remain deterministic;
- feedback ledger semantics must remain stable;
- lab abstract/physical maps must remain synchronized;
- no World/Core coupling may appear in policy or planner layers;
- first-step-only handoff must remain proven;
- full-route execution must still be absent;
- a route-following spec must be written as docs-only first;
- explicit user approval must be given for any route-following implementation.

The route-following gate must keep gameplay movement, live entity movement,
terrain mutation, and autonomous behavior separate from PebbleLab fixture
research until those are deliberately planned.

## Acceptance Criteria For 4.28A

- Documentation-only phase.
- New plan file exists.
- Changelog updated.
- Dev journal updated.
- Roadmap updated.
- No `Sources/` changes.
- No behavior changes.
- No new scenario.
- No new runtime metrics.
- No new runtime event.
- No release build required beyond optional sanity because this is docs-only.
- `git diff` shows documentation only.
- `git diff --check` passes.

## Validation Commands

```bash
git status
git diff --stat
git diff --name-only
git diff --check
```

Optional sanity:

```bash
swift build
swift run pebsmoke
```

This phase is docs-only and does not require a release build.

## Definition of Done

- New plan document complete.
- `CHANGELOG.md` updated.
- `DEV_JOURNAL.md` updated.
- `ROADMAP.md` updated.
- `git diff --check` passes.
- `git status` clean after commit.
- Commit message:
  `Document PebbleLab agent movement stack consolidation plan`

## Phase 4.28B Implementation Status

Phase 4.28B added `agent_movement_stack_contract_fixture_smoke`, the first
runtime fixture contract for the conceptual AgentMovementStack.

Validated stack contract:

- all 11 layers are present and enabled;
- layer order is deterministic;
- layer boundaries are clean;
- v0, v1, v2, and v3 are covered as opt-in policy/planning evidence;
- v4 is reserved metadata only with no runtime path;
- no policy is globally activated;
- no hidden activation is detected.

Fixture-only orchestration:

- the contract reuses policy consolidation evidence for v0/v1/v2;
- the contract reuses bounded planning multi-tick replay evidence for v3,
  first-step handoff, tick arbitration, lab-map-only application, feedback
  ledger, replay digest, and boundary audit;
- it does not replace existing scenarios.

First-step-only and feedback:

- only `selectedFirstStep` is handed to tick;
- advisory steps are not sent and not applied;
- feedback emitted at tick N is consumed only at tick N+1;
- same-tick, future, and cross-agent feedback leaks remain zero.

Application and boundaries:

- approved movement applies only to lab abstract/physical maps;
- abstract/physical divergence after application remains zero;
- no World or live collision is read;
- no route following, full-route execution, persistent route commitment, or
  second-step auto-application is used;
- no Core entity or physical placeholder is moved;
- no memory/goals/reservation runtime is used;
- no terrain/World mutation occurs;
- renderer, resources, registries, and goldens are untouched.

Outputs produced:

- `agent_movement_stack_contract_report.json`;
- `agent_movement_stack_contract_invariant_report.json`;
- `agent_movement_stack_contract_layers.json`;
- `agent_movement_stack_contract_policies.json`;
- `agent_movement_stack_contract_replay.json`;
- `agent_movement_stack_contract_boundary.json`;
- `agent_movement_stack_contract_digest.json`;
- `metrics.json`;
- `events.ndjson`.

Limits:

- this is still fixture-only;
- the event uses the existing aggregate `RunEvent` shape while the detailed
  stack-specific data lives in the report and `agentMovementStackContract*`
  metrics;
- route following and full-route execution remain out of scope.

Next step: Phase 4.28C — Stack Contract Boundary Hardening.

## Phase 4.28C Implementation Status

Phase 4.28C added
`agent_movement_stack_contract_boundary_hardening_smoke`, a fixture-only and
audit-only hardening scenario for the stack contract introduced in 4.28B.

Boundary hardening smoke:

- accepts the valid 4.28B baseline stack contract;
- rejects synthetic negative samples;
- treats forbidden behaviors as data for audit, not as runtime behavior to
  execute;
- keeps the runner fixture-only with no World creation.

Negative samples:

- missing, duplicate, out-of-order, disabled, malformed, and dirty layer
  records;
- missing v0/v3 policy records, duplicate policy versions, global activation,
  hidden activation, v4 execution, and v4 not reserved-only;
- same-tick, future, and cross-agent feedback leaks;
- advisory steps sent/applied, second-step auto-application, persistent route
  commitment, full-route execution, and route following;
- World/collision reads, tick World/collision reads, live pathfinding,
  unbounded search, dynamic replanning, reservation runtime, memory/goals,
  terrain/World mutation, Core entity movement, physical placeholder movement,
  renderer/resource/registry/golden touches.

Validation summary:

- cases = 42;
- cases passed = 42;
- cases failed = 0;
- valid baseline accepted = true;
- all negative samples rejected = true;
- expected violations total = 41;
- detected violations total = 41;
- missed violations = 0;
- false positive violations = 0;
- v4 reserved-only enforcement = true;
- no runtime danger executed = true;
- fixture-only audit = true;
- digest repeatability = true;
- baseline stack contract remains green.

Outputs produced:

- `agent_movement_stack_boundary_hardening_report.json`;
- `agent_movement_stack_boundary_hardening_invariant_report.json`;
- `agent_movement_stack_boundary_hardening_cases.json`;
- `agent_movement_stack_boundary_hardening_negative_samples.json`;
- `agent_movement_stack_boundary_hardening_audits.json`;
- `agent_movement_stack_boundary_hardening_boundary.json`;
- `agent_movement_stack_boundary_hardening_digest.json`;
- `metrics.json`;
- `events.ndjson`.

Limits:

- no World or live collision reads are executed;
- no route following, full-route execution, persistent route commitment, or
  second-step auto-application is executed;
- no Core entity or physical placeholder movement is executed;
- no memory/goals/reservation runtime is used;
- no terrain/World mutation occurs;
- renderer, resources, registries, and goldens remain untouched.

Next step: Phase 4.28D — Stack Replay Regression Adapter.
