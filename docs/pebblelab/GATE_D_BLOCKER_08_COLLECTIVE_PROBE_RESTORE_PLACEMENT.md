# Gate D Blocker 08 — Collective probe restore placement

## Status and scope

```text
Gate D Evaluation 08: EVALUATED_FAIL_NOT_ACQUIRED — HISTORICAL EVIDENCE
Gate D Blocker 08: BLOCKER_FIX_LOCAL_CANDIDATE
Gate D: EVALUATED_FAIL_NOT_ACQUIRED
Independent Gate D Evaluation 09: NOT_STARTED
CIV-34: NOT_STARTED
```

This targeted correction starts directly from published baseline
`02c7778769c8a6d971f4eb8bd73e5a3f7afc8c1e`. It does not incorporate the
Evaluation 08 evidence commit, reevaluate or acquire Gate D, start Evaluation
09, or start `CIV-34`. The local product-fix commit is
`a7f1fd7bf92a6d049d7601945209eb9c98d06058`.

## Root cause

The published loader planned the complete checkpoint probe target correctly,
including reused, repositioned, missing and retired probes. During application,
however, each missing probe was passed back through the ordinary single-probe
creation check. That isolated check observed transaction-owned probes and
checkpoint custody escrow in their transient pre-application positions.

Evaluation 08 therefore reached a collectively valid target layout but
`createProbe(agent_3)` refused `entityCollision`. The failure occurred before
complete physical-boundary acquisition, Material Rights reconciliation or
checkpoint publication. Existing rollback was exact, but every immediate and
fresh-process retry encountered the same false collision.

## Bounded collective authority

PebbleCore now exposes a read-only complete-set placement assessment. It checks
every target against terrain, blocks, fluids, World bounds and collision-
authoritative foreign entities, then checks every target AABB against every
other target AABB. Target-overlap diagnostics are canonical and independent of
input order.

Checkpoint load acquires one unpublished, candidate-scoped placement authority
containing:

- the exact bound `World` identity;
- the complete agent-to-checkpoint-position map;
- only the current probes and custody spill entities owned by that load
  transaction as ignored current-state entity IDs.

The authority is neither stored nor published. Ordinary probe creation cannot
use it. A missing checkpoint probe may use it only when its agent identity,
exact position and World match the acquired target set. `createProbe` still
runs the ordinary PebbleCore placement assessment, with only the bounded
transaction-owned exclusions.

## Save and restore invariants

Checkpoint save now verifies the complete live probe AABB set in addition to
identity and exact position. Restore performs this ordered boundary:

1. decode and validate checkpoint, manifest, World binding and custody proof;
2. stage the candidate civilization state;
3. classify the complete probe plan as reused, repositioned, missing or
   retired;
4. validate the complete target placement set and acquire the bounded
   authority;
5. retire and reposition probes, then create every missing probe using that
   same authority;
6. restore exact checkpoint-bound custody;
7. verify the final active probe set, positions, custody, World identity,
   target AABBs and absence of unexpected probes;
8. acquire the complete physical checkpoint boundary;
9. stage one current Material Rights reconciliation and cross-domain
   validation;
10. publish atomically.

The checkpoint position is exact authority: no nearest-free search, offset or
silent relocation is introduced.

## Collision semantics

Adjacent checkpoint probes with non-intersecting physical AABBs restore. True
target AABB overlap is refused before mutation. A foreign World entity in a
target volume remains an `entityCollision` and causes a fail-closed load with
no relocation or publication.

Transaction-owned entities are excluded only while applying the matching load
candidate. Their old transient positions cannot obstruct the target layout,
but every target remains mutually checked against all other targets. Forward
and reversed missing-probe creation order restore the same exact final set.

## Mixed plan and custody

The decisive proof loads one checkpoint candidate containing simultaneously:

```text
reused_exact = 1
repositioned_verified = 1
restored_missing = 2
retired = 1
```

The saved positions for `agent_1` through `agent_4` are restored exactly, the
dead bootstrap parent remains retired, and two distinct protected custodies are
adopted by their correct probes. There are no duplicate probes, swapped stacks,
physical loss, physical duplication or synthetic material.

## Atomic rollback

A dedicated fault after the first missing-probe creation proves partial
application rollback. All newly created probes are removed; repositioned and
retired probes return to the fresh bootstrap boundary; mapping, positions,
custody, World escrow, session and recorder remain exact; and no reconciliation
run is published. Immediate same-process retry succeeds.

The existing Blocker 07 fault after the post-physical reconciliation candidate
also remains exact. That failed load publishes zero reconciliation runs and
restores escrow. Its immediate retry acquires the complete boundary and commits
exactly one current reconciliation.

## Evaluation 08 decisive continuation

After the corrected fresh succession checkpoint load, the inherited pickaxe is
available on the first normal attempt. The proof records an allowed ownership
verdict, tool damage `0>1`, one real World block removal and acquisition of the
real drop. Historical estate settlement evidence remains retained while the
current destination observation advances.

## Validation result

```text
published-baseline red: reproduced (isolated createProbe entityCollision)
valid adjacent target set: PASS
true target overlap: refused before mutation
foreign World collision: refused before mutation
normal / reversed creation order: PASS / PASS
restored_missing probes in one load: 2
mixed reused / repositioned / restored / retired: 1 / 1 / 2 / 1
partial-creation rollback / immediate retry: exact / PASS
post-reconciliation rollback / immediate retry: exact / PASS
successful-load committed current reconciliation runs: 1
failed-load published reconciliation runs: 0
first inherited use: allowed with real physical mutation
physical loss / duplication / synthetic material / duplicate probes: 0 / 0 / 0 / 0
repository shared smoke: 3768 passed, 0 failed
repository verification steps: 35/35
Gate D Blockers 01, 05 and 07 exact final reruns: PASS
Gate D Blockers 02, 03, 04 and 06 prior same-runtime revalidation: PASS
checkpoint schema / Observer schema: 30 / 7 (unchanged)
golden regeneration: NOT ATTEMPTED
```

## Limits

This correction does not disable collision checks, invent restore positions,
make checkpoint social state physical authority, or relax Blocker 05 escrow.
External World changes that create a real conflict may still make an old
checkpoint fail closed. Unsupported abrupt custody loss remains unsupported.
The proof does not acquire Gate D or authorize Evaluation 09 before senior
review and manual publication of this local candidate.
