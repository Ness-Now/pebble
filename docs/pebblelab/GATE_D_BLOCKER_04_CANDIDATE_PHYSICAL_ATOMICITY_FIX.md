# Gate D Blocker 04 — Candidate physical atomicity

## Status and scope

This document records a targeted product correction based on published
baseline `4b11c93abd36a1a1c61d491df1e5efa6607f6206`.

```text
Gate D Evaluations 01 through 04: historical immutable FAIL
Gate D Blockers 01 through 03: BLOCKER_FIX_PUBLISHED
Gate D Blocker 04: BLOCKER_FIX_LOCAL_CANDIDATE
V4-GATE-D-v1: EVALUATED_FAIL_NOT_ACQUIRED
CIV-34: NOT_STARTED
```

The correction does not change Evaluation 04, acquire Gate D, start Evaluation
05 or start `CIV-34`. No Evaluation 04 commit is merged into the product
history. Its evidence was inspected only as immutable historical context.

## Root cause

Evaluation 04 began with a published session and checkpoint at `20,66,-23`.
Multi-step agricultural navigation then applied at least one successful
PebbleCore movement. A later step collided, the error escaped and the
civilization candidate was abandoned, but the earlier movement survived at
`20,66,-24`. The next `movementBoundary` and checkpoint correctly refused the
physical/session mismatch.

`navigateAgricultureActor` was the immediate path. The product defect was
broader: physical effects owned by a candidate could become observable before
the candidate's session, recorder and receipts were published, without a
shared late-failure compensation boundary.

## Transaction boundaries

`PebbleAgentController` owns one bounded physical-compensation journal and one
World-receipt transaction for each candidate publication boundary. Nested
candidate journals are refused. The journal accepts at most 128 reservations.
An adapter reserves before mutation and registers one one-shot inverse only
after its local mutation and verification succeed.

An adapter that fails locally restores and verifies its own work and registers
no token. A globally abandoned candidate consumes registered tokens once in
reverse mutation order. Child custody/acquisition tokens therefore run before
their parent block/entity inverse. This is the anti-double-rollback rule.

Normal tick publication is ordered as follows:

1. observe the current physical World;
2. mutate and validate candidate copies while physical adapters retain verified
   inverse tokens;
3. perform final session, receipt and physical-boundary validation;
4. commit the staged World-receipt transaction;
5. assign the already-validated session and recorder candidates;
6. consume the physical journal as committed, releasing buffered audiovisual
   effects;
7. publish derived traces and projections.

Steps 4 through 6 are synchronous and non-throwing after final validation.
Candidate receipt rows remain rollback-capable until step 4. The session and
recorder candidates are not externally assigned on any throwing path.

## Senior review correction 01

Senior review found a narrower fail-closed gap between compensation reservation
and journal registration. `PebbleAgentLivestockExecutor.shear` called
`damageItemStack` before rejecting a `nil` result from
`Sheep.shearForLivestock()`. An unavailable product could therefore consume
tool durability or gameplay RNG even though no parent compensation token was
registered. The adapter now rejects the `nil` result before tool wear, custody,
publication or any other candidate mutation.

Successful shearing has a nested boundary: material acquisition registers its
child token before the parent sheep/tool/RNG token is built. A controlled
parent-registration failure now invokes `registerOrCompensate`, which consumes
all synchronous child tokens newer than the parent reservation in reverse
order, then consumes the offered parent token. The restored boundary verifies
the complete sheep state, exact inventory and durability, gameplay RNG,
candidate `ItemEntity` set and material-gateway receipt cache. No token remains
registered after an exact local restore. If any child or parent inverse cannot
prove its result, a consumed diagnostic token remains in the candidate journal
so the enclosing rollback produces `PebbleCandidatePhysicalHardFailure`
instead of treating the reservation gap as clean.

`PebbleCandidatePhysicalTransaction.register` now independently refuses a
token after either `commit()` or `rollback()`. This is a primitive invariant,
not a call-graph assumption.

The general `reserve -> mutate -> validate -> register` audit produced this
result:

| Path | Before/during mutation | Failure after mutation or during `register` | Ownership after success |
| --- | --- | --- | --- |
| Livestock shear | Reservation precedes mutation; unavailable shear returns before tool/RNG mutation; all later local errors restore exact sheep/tool/RNG/entities | Child custody then parent shearing compensate locally through `registerOrCompensate`, or force hard failure | Global candidate journal owns child and parent tokens |
| Livestock feed | Existing `tryFeed` refusal is non-mutating; publication errors restore inventory/love/growth/cause exactly | Existing verified local register-failure rollback remains unchanged | Global candidate journal owns the feed token |
| Material custody | Existing transfer/consume/acquire local rollbacks remain authoritative | Registration refusal now runs the same exact compensation and verifies stacks plus boundary receipt cache; unverifiable restoration forces hard failure | Global candidate journal owns the material token |
| Physical action gateway | Reservation precedes bounded Core mutation and existing validation/rollback | Registration refusal now uses the verified action compensation instead of ignoring a rollback result | Global candidate journal owns the action token |
| Wild fishing and hunting | Existing local rollback restores actor/target, equipment, entities and RNG | Registered acquisition child is consumed before the fishing/hunting parent; partial child-only rollback is impossible | Global candidate journal owns child and parent tokens |
| Wild approach, generic movement and agriculture navigation | Existing complete physical-state snapshots restore every successful local step | Existing verified register-failure rollback remains unchanged | Global candidate journal owns the movement token |
| Birth and mortality | Existing composite local boundaries restore probe identity, World indexes, custody and controller mappings | Existing verified register-failure rollback remains unchanged; mortality suppresses nested material journaling | Global candidate journal owns the lifecycle composite token |
| Renewable fixture | Existing fixture rollback verifies cells, block entity, sky light and inventory | Existing verified register-failure rollback remains unchanged | Global candidate journal owns the fixture token |

The audit therefore found additional registration-failure exposure in material
custody, the physical-action gateway, and the nested fishing/hunting paths.
Those gaps are corrected here. No audited path remains able to continue after
an unverified registration-failure restore; it either restores exactly or
enters the existing observable fail-stop boundary.

On failure, candidate World receipts are removed first and verified absent,
then physical tokens run in reverse order. The published session and recorder
remain the captured originals. A receipt created by an abandoned attempt has a
new attempt ordinal and cannot be recreated or selected by a retry.

## External World progression

`advanceRenewableCropByWorldTicks` temporarily raises `randomTickSpeed`, bounds
the active chunk and calls `World.tick()`. This progression can change much
more than the target crop, including World time, World RNG, scheduled ticks,
lighting, block entities and natural neighbors. It is not compensable candidate
state.

The renewable chronology is therefore:

1. advance the physical World outside any candidate;
2. retain the acquired `physicalWorldTick` and current crop state;
3. open a new candidate journal and receipt transaction;
4. scan the current World and create a fresh observation/receipt;
5. perform the bounded harvest, custody and session operations;
6. validate and publish, or compensate only candidate-owned effects.

If the crop is already mature, retry performs zero additional World ticks. It
rescans the acquired World and creates a distinct receipt. The World RNG is not
restored. The separate PebbleCore gameplay RNG used to calculate candidate
block drops is captured by the physical-action adapter and restored with the
failed candidate, so retry produces the same deterministic harvest rather than
silently consuming candidate randomness.

## Exact movement state

`LabCoreAgentPhysicalState` captures and compares:

- current `x`, `y`, `z` and previous `prevX`, `prevY`, `prevZ`;
- velocity `vx`, `vy`, `vz`;
- `yaw`, `pitch`, `prevYaw`, `prevPitch`;
- `onGround`, `horizontalCollision` and `fallDistance`.

Movement compensation restores these PebbleCore fields directly and verifies
the complete value. It does not call an ordinary inverse movement and does not
use permissive `setPos`. Generic batched movement captures every moved probe
before the first mutation. Agricultural multi-step navigation captures the
actor once before its first successful step. Local late collision restores the
captured state before an error escapes; a later global candidate error invokes
the registered batch inverse.

## Physical mutation inventory

| Mutation category | Physical owner and local boundary | State captured for inverse | Deferred compensation and late-error behavior |
| --- | --- | --- | --- |
| Generic movement | `PebbleAgentMovementExecutor` around one verified batch | Complete `LabCoreAgentPhysicalState` for every moved probe | One batch token; reverse direct restore and full equality verification. Locally failed movement restores before returning and registers nothing. |
| Agricultural navigation | `navigateAgricultureActor` around one multi-step route | Complete actor physical state before the first step | One route token after all steps verify. A late collision restores the whole route locally. |
| Till/place/break | `PebbleAgentPhysicalActionGateway` around PebbleCore rules | Original block cells, entity-ID set, tool/custody state and gameplay RNG | Parent token restores cells/entities/tool/RNG. Sound, particles and vibration remain buffered until commit. Child drop acquisition reverses first. |
| Transfer and storage | `PebbleAgentMaterialCustodyGateway` | Source/destination stacks, boundary receipt cache and transfer identity | One transfer/batch token. Existing gateway rollback remains the local authority. |
| Acquisition and consumption | `PebbleAgentMaterialCustodyGateway` | Exact original `ItemEntity` objects/stacks, actor inventory and boundary receipts | Acquisition recreates original entities after removing candidate custody; consumption restores the debited stack. |
| Construction | Construction executor plus physical-action/material gateways | Candidate executor stays local; every physical placement and custody debit is captured by its owning gateway | No parallel construction inverse. Gateway tokens compensate successful Core operations; candidate executor is discarded with the session. |
| Renewable setup and harvest | Renewable controller plus agriculture, movement, action and material adapters | Bounded fixture cells, block entity, sky light, actor inventory, actor movement and harvest/custody state | Fixture token is reserved before setup; route/action/material tokens compose in mutation order. Natural `World.tick()` growth is explicitly excluded. |
| Fishing and hunting | `PebbleAgentWildSubsistenceExecutor` | Actor/target entity state, complete combat state, inventories, equipment, entity IDs and gameplay RNG | Material acquisition child plus entity/combat parent token. Candidate audiovisual effects are buffered. |
| Livestock feed and shear | `PebbleAgentLivestockExecutor` | Animal state, actor inventory, emitted item entities and gameplay RNG | Material child plus animal/inventory parent token. Locally rejected actions restore and register nothing. |
| Dependent food | Existing physical-food and material gateway path | Debited physical stack and custody boundary | Uses the material gateway token; there is no second food engine or second inverse. |
| Birth | Lifecycle controller plus existing `createProbe` adapter | Created newborn identity, mapping and exact probe reference | Token removes the candidate newborn and verifies all World indexes on later failure. Local creation failure keeps existing bootstrap rollback. |
| Mortality and physical exit | Mortality aggregate transition | Removed probes, mappings, custody/material snapshots, gateways, focus/follow state | One composite mortality token owns the already-atomic local boundary. Child material journaling is suppressed here to avoid double rollback. |
| Migration admission and startup | Population/lifecycle command transactions outside `advanceOneTick` | Staged candidate session/recorder and newly created probe set | Existing bounded local rollback publishes only after full probe verification; it is not claimed by the tick journal. |
| Checkpoint probe create/remove/reposition | Persistence reconciliation outside candidate ticks | Existing checkpoint reconciliation plan and exact rollback state | Existing transactional reconciliation remains the sole owner. Hard-failure guards refuse entry before it can mask a divergence. |
| Ecological/agricultural World receipts | World receipt store transaction | IDs of rows staged by the current candidate | Rows are removed and verified on abort; the transaction commits only at publication. Historical retained rows are never treated as current membership. |
| Recorder and `AgentSimulationSession` | Controller candidate copies | Published value references plus deterministic candidate values | Assignment occurs only after all throwing validation. Failure retains both published values unchanged. |
| `World.tick()` and natural collateral effects | PebbleCore `World` | No candidate snapshot by design | External irreversible progression remains acquired. The retry reobserves it; no general World rollback exists. |

Checkpoint schema 30 and Observer schema 7 remain unchanged. Observer reads the
published session and retained receipts only and receives no mutation or
compensation authority.

## Hard failure

An inverse that throws, collides, cannot match its expected-after boundary or
cannot verify its restored state creates `PebbleCandidatePhysicalHardFailure`.
The diagnostic contains the operation and transaction, mutation, expected and
observed physical states, attempted inverse and error, completed and remaining
tokens, candidate receipt IDs, publication status, physical World tick, World
and session identities, checkpoint identity if any, and agent/probe identities.

The controller retains the published session and recorder, pauses, and refuses
normal step, resume, reset/rebuild/start, renewable operations and all normal
checkpoint operations. It does not adopt the physical divergence or run an
automatic reconciliation. Explicit terminal shutdown can still remove probes
and close the process.

## Priority proof contract

The canonical targeted runner is
`scripts/verify-pebblelab-gate-d-candidate-physical-atomicity-fix.sh`.
It proves:

- `candidateShearingUnavailableLeavesPhysicalStateExact`: a non-shearable
  sheep returns `productUnavailable` with exact sheep, tool/durability,
  gameplay RNG, `ItemEntity`, material gateway, session, recorder and World
  receipt state and no registered token;
- `candidateShearingRegistrationFailureCannotLeakParentMutation`: a controlled
  parent registration failure after real shearing and child custody restores
  the child first and parent second, leaves no registered token and publishes
  no candidate state;
- `candidatePhysicalRegisterClosedTransactionRefused`: direct primitive proof
  that both committed and rolled-back transactions reject registration;
- `renewableWorldAdvanceRemainsExternalAfterCandidateFailure`: one external
  growth interval, candidate failure with zero retained receipts, zero-tick
  retry, distinct observation receipt, identical deterministic harvest,
  checkpoint, separate process restart and exact reconciliation;
- `candidateTickFailureAfterVerifiedMovementRestoresAllPhysicalState`: real
  verified movement, late fault, complete before/after trace, reverse
  compensation, unchanged session/recorder, nominal next movement, checkpoint,
  separate process restart and exact reconciliation;
- `candidateCompensationCollisionHardFailsWithoutPublication`: injected
  non-verifiable movement inverse, full hard-failure diagnostic and refusal of
  step, checkpoint, reset, start and resume.

The runner captures rendered screenshots and SHA-256 digests. The canonical
repository gate and the dedicated Blocker 01, 02 and 03 campaigns remain
separate mandatory evidence; a green targeted runner alone does not acquire
Gate D.

## Validation record

The local candidate was validated on 2026-08-09 with the following exact
results:

- focused `candidate-physical-atomicity` pebsmoke selector: 3 passed, 0
  failed;
- 17 directly affected pebsmoke suites: 1,550 passed, 0 failed;
- `scripts/verify-pebblelab.sh`: all 35 canonical repository steps passed,
  including 3,760 golden and shared-runtime checks with 0 failures;
- `scripts/verify-pebblelab-gate-d-position-restore-fix.sh`: Blocker 01
  reproduced and fixed, position mismatches 3 to 0, zero duplication,
  mutation or runtime errors, exact cleanup;
- `scripts/verify-pebblelab-gate-d-ecological-observer-fix.sh`: Blocker 02
  reproduced and fixed, schema 30 retained-death restart, zero duplication,
  mutation or runtime errors, exact cleanup;
- `scripts/verify-pebblelab-gate-d-agriculture-cycle-observation-fix.sh`:
  Blocker 03 reproduced and fixed, all eight late-failure boundaries exact,
  zero receipt leaks, duplicates or Observer mutation, exact cleanup;
- `scripts/verify-pebblelab-gate-d-candidate-physical-atomicity-fix.sh`:
  both shearing atomicity contracts, the closed-transaction primitive proof and
  all three original priority contracts passed across failure, retry,
  checkpoint and fresh-process restart; six rendered captures and their
  SHA-256 manifest were inspected; and
- `scripts/verify-pebblelab-live.sh --dry-run`: passed without launching or
  creating a directory.

The consolidated proof retained its abandoned receipt count at zero, advanced
the mature retry by zero additional World ticks, restored complete movement
state, kept session and recorder publication unchanged on failure, reconciled
the restart exactly, and refused productive continuation after a deliberately
non-verifiable inverse.

## Limits and verdict

There is deliberately no generic snapshot or rollback for `World.tick()`, no
second physical engine and no permissive checkpoint reconciliation. Command
transactions outside candidate ticks retain their existing local ownership;
the journal is not extended across commands or process boundaries. The journal
is bounded to 128 candidate mutations, and capacity failure occurs before the
next physical mutation.

Subject to the recorded full regression and live evidence, the maximum verdict
of this work is:

```text
Gate D Blocker 04: BLOCKER_FIX_LOCAL_CANDIDATE
Gate D: EVALUATED_FAIL_NOT_ACQUIRED
CIV-34: NOT_STARTED
```
