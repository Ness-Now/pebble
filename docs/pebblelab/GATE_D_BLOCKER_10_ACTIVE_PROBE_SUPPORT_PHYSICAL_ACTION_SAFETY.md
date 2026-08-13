# Gate D Blocker 10 — Active-probe physical-action safety

## Status

```text
Gate D Evaluation 10:
EVALUATED_FAIL_NOT_ACQUIRED — HISTORICAL EVIDENCE

Gate D Blocker 10:
BLOCKER_FIX_PUBLISHED

Gate D:
EVALUATED_FAIL_NOT_ACQUIRED

Independent Gate D Evaluation 11:
NOT_STARTED

CIV-34:
NOT_STARTED
```

The next authorized action is a new independent V4 Gate D Evaluation 11.
Evaluation 11 is not started. This record does not reevaluate or acquire Gate D.

## Product identity

Published affected baseline:

```text
55e513becac622e2f7f258f10ec406d26865eb6a
```

Published product-fix head:

```text
6ec700640dfe806f32da62fe7d7315c64fdb8f74
```

Senior technical review: **APPROVED**.

Approved review bundle SHA-256:

```text
8508d8d938830a4a0438b49e450d60db286bdf89ba95d530a3f840710e8cccbe
```

Historical Evaluation 10 commits are evidence only and are not ancestors of
this branch:

```text
a39cca48d4bbb33873ed9ba63fbcd7146f772976
154a79a6c34247fe5ad0ca4de33badaab3086f09
```

## Historical first divergence

Evaluation 10 performed a legitimate second use of the inherited pickaxe. The
physical action advanced damage from 1 to 2 and broke the World block at
`20,65,-24`. Active descendant `agent_3` remained at `20,66,-24`, directly
above the removed support. Because Lab probes are intentionally `noGravity`,
no physical fall resolved the state. The next restart-safe checkpoint refused
`agent_3:incompatibleSupport`; immediate retry and two independent fresh
process reproductions refused identically.

The dedicated baseline-red runner reproduced the class directly:

```text
valid active probe above solid support
+ another actor breaks that support
→ physical action succeeded
→ World block removed
→ tool damaged and drop acquired
→ protected probe incompatibleSupport
→ checkpoint publication 0
```

Checkpoint save was correct to refuse. The defect was the earlier product
action boundary.

## Root cause

PebbleCore owns one canonical entity-placement assessment covering support,
body obstruction, fluids and entity collisions. Checkpoint save and restore
already use that authority. The physical-action gateway, however, validated
the target cell and operation outcome without proving that the resulting World
still supported every other active Lab probe.

This was not limited to the inherited-use proof. The same gateway is used by
autonomous wild gathering, agriculture, natural-resource execution,
construction, harvest and other productive callers. The actor could therefore
commit a block mutation underneath another active probe even though the
resulting physical state was not restart-safe.

## Corrected transaction boundary

Before a candidate block mutation, the gateway captures every live
`LabCoreAgentEntity` in deterministic agent/entity order. For each probe it
records exact identity, position, body dimensions and whether its current
placement passes PebbleCore `assessEntityPlacement` while ignoring only the
active probe set itself.

After Core performs the candidate mutation, and before drop acquisition or any
Civilization publication, the gateway rechecks every pre-valid probe with the
same canonical placement primitive. Exact candidate-created item entities may
be ignored only while they belong to that same bounded transaction; normal
World entities remain collision-authoritative.

```text
capture pre-valid active probe boundary
→ Core candidate block mutation
→ canonical post-mutation placement assessment for all captured probes
→ if exact: continue existing verification/publication path
→ if invalid: existing exact compensation and no publication
```

The authority is local to one candidate. Ordinary probe creation receives no
exception. No probe moves, falls, teleports or searches for a new position.
The checkpoint `incompatibleSupport` guard remains unchanged.

## Mutation-family audit

The audit covers all block-mutating gateway families:

- `breakBlock`: removing support beneath another active probe is compensated;
- `tillBlock`: changing valid support into an incompatible support cell is
  compensated;
- `placeBlock`: placing into another probe's body clearance is compensated;
- a target equal to an active probe foot cell continues to refuse before
  mutation as `occupiedTarget`.

For each compensated action the World cell, tool state, spawned entities,
custody, Material Rights, estate projection, session and recorder remain
exact. The result is independent of active-probe enumeration order.

## Positive physical action

The correction does not prohibit mining generally. A nearby stone block that
does not support, occupy or obstruct a probe is broken through the same
gateway. Core removes the block, damages the pickaxe exactly once, spawns the
drop and the custody gateway acquires it. Every active probe remains
canonically placeable and an immediate restart-safe checkpoint succeeds.

The inherited-use target selector was also corrected to avoid known active
probe support positions. That proof hygiene is not the product correction: the
gateway safety boundary independently refuses an unsafe request from any live
caller.

## Atomicity

The new check occurs inside the existing physical-action transaction. On
failure, the established rollback restores:

```text
World block mutations
spawned ItemEntity objects
tool damage
actor inventory and custody
candidate drops
candidate physical compensation reservation
session and recorder publication
```

The support-destructive proof reports:

```text
worldMutation = 0
toolDamage = 0>0
drops = 0
custody = unchanged
Material Rights = unchanged
estate = unchanged
session = unchanged
recorder = unchanged
physical receipts = 0
protected placement = valid
```

Existing late-fault seams and compensation rules remain unchanged.

## E10 decisive continuation

The targeted campaign independently rebuilds the published estate scenario,
settles the inherited pickaxe to `agent_1` and creates protected custody. It
then proves:

```text
durable registered identity = iron_pickaxe damage 0
current verified identity = damage 1
safe second physical use = damage 1>2
checkpoint C save = restartSafe
graceful checkpoint-bound escrow = exact
fresh process checkpoint C load = exact damage 2
current reconciliation committed by load = exactly 1
continued physical use after load = damage 2>3
settlement receipt = unchanged one
asset ID = unchanged
```

The former destructive target underneath `agent_3` is excluded by the proof
selector, while the product gateway remains the final authority for all
callers.

## Blocker continuity

- Blocker 05 remains strict: protected nonpersistent custody restores only
  from exact checkpoint-bound physical escrow.
- Blocker 06 remains asset-scoped and retains its true late-fault rollback and
  immediate retry.
- Blocker 07 retains physical restore, complete boundary, one staged current
  reconciliation, cross-domain validation and atomic publication ordering.
- Blocker 08 integrated current semantics pass: valid adjacency is accepted,
  true target overlap and a foreign World collision fail before publication,
  exact checkpoint positions and custody restore through the complete
  physical boundary. Its dedicated historical runner remains inconclusive
  because its signed external `SESSION_HOME` fixture is not contained in the
  published baseline; no replacement fixture or false PASS was fabricated.
- Blocker 09 retains durable damage-0 history while exact current damage-1 and
  damage-2 identities save and fresh-restore from PebbleCore custody.

## Validation

Dedicated runner:

```text
scripts/verify-pebblelab-gate-d-active-probe-support-physical-action-fix.sh
```

Targeted smokes passed for physical actions, safe entity placement,
embodiment, checkpoint/replay, persistence reconciliation, material custody,
Material Rights, estates/succession, wild subsistence, agriculture and
candidate physical atomicity.

```text
Blockers 01 through 07: PASS
Blocker 08 dedicated historical runner: INCONCLUSIVE — signed fixture absent
Blocker 08 integrated current semantics: PASS
Blocker 09: PASS
checkpoint schema: 30
Observer schema: 7
physicalLoss: 0
physicalDuplication: 0
syntheticMaterial: 0
duplicateProbes: 0
duplicateAssets: 0
duplicateSettlements: 0
duplicateReceipts: 0
observerMutationCount: 0
repository gate: 35/35, 3772 passed, 0 failed
golden regeneration: NOT ATTEMPTED
```

## Limits

This correction does not add gravity to Lab probes, invent fall mechanics,
relocate probes, relax checkpoint placement, change collision semantics or
claim abrupt-loss custody recovery. It guarantees only that a candidate block
mutation cannot newly invalidate a currently valid active Lab probe and still
commit. Pre-existing invalid probes remain visible to the existing lifecycle
and checkpoint fail-closed boundaries.
