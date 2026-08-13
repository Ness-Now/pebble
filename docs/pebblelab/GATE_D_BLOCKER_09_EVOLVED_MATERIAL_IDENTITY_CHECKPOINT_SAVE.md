# Gate D Blocker 09 — Evolved material identity at checkpoint save

## Status and scope

```text
Gate D Evaluation 09: EVALUATED_FAIL_NOT_ACQUIRED — HISTORICAL EVIDENCE
Gate D Blocker 09: BLOCKER_FIX_PUBLISHED
Gate D: EVALUATED_FAIL_NOT_ACQUIRED
Independent Gate D Evaluation 10: NOT_STARTED — NEXT AUTHORIZED ACTION
CIV-34: NOT_STARTED
```

This targeted correction started directly from published baseline
`4ea6fba4b615d72a96087bb98bf5bbca4b560e4b`. It does not incorporate either
Evaluation 09 evidence commit, reevaluate or acquire Gate D, start Evaluation
10, or start `CIV-34`. The published product-fix head is
`ee742afb41fda44c77d8b98f868fbe759934057e`.

## Root cause

Evaluation 09 settled an inherited `iron_pickaxe` with registered identity
damage 0, restored it, and used it normally. The first use removed a real World
block, acquired the real drop and evolved the exact physical tool and current
Material Rights observation from damage 0 to damage 1. The immutable durable
asset reference and historical estate settlement correctly remained damage 0.

The checkpoint custody adapter nevertheless searched PebbleCore for the
registration-time identity and required the current holder observation to equal
that same identity. It therefore refused a coherent current damage-1 tool as a
holder/material/quantity conflict. This contradicted the Material Rights model,
which already permits a validated current identity evolution for the same
canonical item key.

## Durable identity and current observation

The correction preserves three distinct authorities:

- the durable asset reference retains registration identity and history;
- the last verified holder observation identifies the exact current material,
  quantity, holder, fingerprint and observation tick;
- PebbleCore custody is the only physical truth checked at save time.

`AgentMaterialAssetReference` now owns the shared pure predicate for whether a
current identity is permitted by the durable reference. The session validator
and checkpoint adapter use the same predicate instead of maintaining divergent
definitions. Under the existing bounded model, evolution preserves the exact
canonical `itemKey`; this does not permit an arbitrary category match.

The durable asset reference, settlement observation and settlement receipt are
never rewritten by checkpoint save or current tool use.

## Checkpoint custody validation

For an agent-held Material Rights record, restart-safe save now proves in order:

1. the current verified identity is a canonically permitted evolution of the
   durable asset reference;
2. the current holder and quantity are exact;
3. actual PebbleCore custody contains the exact current verified identity;
4. the exact current quantity is available without double reservation;
5. a current custody fingerprint, when required by the existing observation
   boundary, still matches the physical endpoint.

Reservation accounting keys the exact current material identity. Two records
cannot reserve the same physical unit, while independently evolved identities
remain distinct. There is no fallback to the registration identity and no
same-item-key physical substitution.

Checkpoint save remains observational with respect to the World and
civilization session. It publishes only the persistence artifact after all
validation succeeds; refusal publishes no checkpoint or protected handoff.

## Protected-custody round trip

The targeted campaign proves two successive evolution boundaries:

```text
registered damage 0
→ legitimate physical use and current observation damage 1
→ restart-safe checkpoint
→ exact damage-1 protected escrow
→ fresh restore damage 1
→ one post-physical current reconciliation
→ legitimate second physical use and current observation damage 2
→ restart-safe checkpoint
→ exact damage-2 protected escrow
→ fresh restore damage 2
```

Both current identities are encoded in manifest-v2 protected custody evidence,
not reconstructed from Material Rights. The two checkpoint integrity boundaries
are distinct, and neither checkpoint can restore the other checkpoint's stale
tool state.

## Fail-closed cases

The proof refuses each of these cases without session or World mutation and
without checkpoint or handoff publication:

```text
current expected item missing
registration-time identity substituted for current identity
unverified future identity substituted for current identity
wrong holder
wrong quantity
ambiguous duplicate current stack
two records reserving the same current physical unit
```

Unrelated co-mingled material remains unrelated. The correction neither makes
a whole-container fingerprint a durable asset identity nor weakens Blocker 06
asset-scoped authority.

## Restart and historical continuity

Every successful load retains the Blocker 07 ordering:

```text
exact physical restore
→ complete physical checkpoint boundary
→ one current Material Rights reconciliation
→ cross-domain validation
→ atomic publication
```

The Blocker 08 collective placement path restores the representative
multi-probe checkpoint without collision bypass or invented positions. Blocker
05 remains the sole supported authority for restoring non-empty nonpersistent
probe custody; missing, stale or corrupt escrow cannot create material.

Across both uses and restarts, the asset ID, durable registration identity,
beneficiary, ownership and one historical settlement receipt remain unchanged.
The current holder observation alone advances from damage 0 to 1 to 2.

## Validation result

```text
published-baseline damage 0>1 save refusal: reproduced
damage 0>1 checkpoint save: PASS
damage-1 protected custody / fresh restore: exact / PASS
damage 1>2 second physical use and checkpoint save: PASS / PASS
damage-2 protected custody / second fresh restore: exact / PASS
old / future / missing identity: refused / refused / refused
wrong holder / quantity / ambiguity: refused / refused / refused
duplicate current-unit reservation: refused
historical settlement receipts / assets / settlements duplicated: 0 / 0 / 0
physical loss / duplication / synthetic material: 0 / 0 / 0
Observer mutation count: 0
repository shared smoke: 3772 passed, 0 failed
repository verification steps: 35/35
Gate D Blockers 01 through 08: PASS
checkpoint schema / Observer schema: 30 / 7 (unchanged)
golden regeneration: NOT ATTEMPTED
```

## Limits and next action

This correction does not introduce per-unit material UUIDs, broaden legitimate
identity evolution beyond the existing Material Rights rule, repair a stale
current observation during save, create matter from social state, support
abrupt custody loss, or make protected escrow reusable after consumption.

Gate D remains `EVALUATED_FAIL_NOT_ACQUIRED`. Independent Evaluation 09 remains
immutable historical FAIL evidence. The next authorized action is a new
independent Gate D Evaluation 10, which is not started.
