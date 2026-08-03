# Gate D Blocker 03 — Cycle-scoped agricultural maturity evidence

## 1. Baseline affected

This targeted product correction starts directly from published product commit
`d0d99f8a1d06cf809b14a68c107f961b58c09674` on
`lab/pebblelab-v1`. Checkpoint schema remains `30`; Observer schema remains
`7`.

The correction does not evaluate or acquire `V4-GATE-D-v1` and does not start
`CIV-34`.

## 2. Independent Evaluation 03 FAIL

Independent Evaluation 03 is immutable historical evidence on commit
`fa63d04b05998b4d7021be313cc6413854b8fd39`. It evaluated the baseline above
and concluded `GATE D FAIL — PRODUCT CORRECTION REQUIRED`. Evaluations 01 and
02 remain immutable FAIL evidence on commits
`9232b65a8a32b2d054fe2e5c7ea80e0dd990d378` and
`d40ca4f8215ff14d904a1fb84aedb7ebd9185082` respectively. None of those
verdict commits is merged or rewritten by this correction.

## 3. Reproduction

The failure boundary was reproduced with one real carrot planted, matured and
harvested, one carrot consumed, two stored, and one replanted in the same
physical cell. The historical cycle-1 mature observation was still fresh while
the cycle-2 crop was physically at stage `0`. A normal `/lab step` selected the
old mature row, called physical maturity verification and failed with
`agricultural maturity observation mismatch`; the civilization tick remained
at `1`.

## 4. Root cause

`reconcileLiveAgriculturalLifecycle` iterated fresh observations until it found
one whose payload said the requested crop was mature. Freshness bounded the age
of a row but did not identify the agricultural cycle. Replanting the same crop
at the same position therefore made a legally retained cycle-1 row appear
eligible for cycle 2.

## 5. Freshness versus cycle identity

Freshness is still required but is no longer used as a proxy for cycle
identity. Historical observations keep their original digests, receipts and
Observer visibility. They remain valid for history, harvest provenance and
renewable evidence, but cannot mature a later cycle.

## 6. Current planting boundary

The durable current-cycle boundary is the exact `.plant` agricultural action
named by `cell.lastWorkEventID`, together with its causal event and independent
World-side physical receipt. The action must name the same plot, cell, actor
and crop, belong to `plot.cycleOrdinal`, occur after the current renewal event
when one exists, and agree with `plot.lastAgricultureEventID` ordering.

`plantedCivilDate` is retained but is not sufficient proof. The plant action's
causal sequence separates operations that share one simulation tick. Its
physical receipt tick, plus the current source and renewal receipts, provides
the lower physical-World-tick boundary.

## 7. Observation selection algorithm

`AgentSimulationSession.currentCycleCropObservation` is the single canonical
selector. For each active actor it first identifies that actor's latest fresh
exact-cell row; it never walks backwards to find a desired mature value. It
then validates exact causal-event and World-receipt linkage, World, storage,
dimension, simulation, crop, position, plant-causal ordering and physical-tick
boundary.

The result is one of `noEligibleObservation`, `currentCycleNonMature`,
`currentCycleMature`, `conflictingCurrentEvidence` or
`invalidCurrentEvidence`. Conflicting and invalid current evidence fail closed.

## 8. Multi-actor ordering

Eligible actor rows are ordered deterministically by physical World tick
descending, simulation tick descending, causal sequence descending,
ecological sequence descending, then observer ID ascending. The actor ID is
only a final stable tie-breaker; tests reverse actor IDs while preserving the
same newest physical evidence. Incompatible rows at the same physical boundary
produce `conflictingCurrentEvidence` rather than choosing the mature row.

## 9. Non-mature semantics

`currentCycleNonMature` is valid physical evidence. Reconciliation does not
call `observeMaturity`, create an agricultural action, emit an error or mutate
the plot. The rest of the normal civilization tick continues. Repeated ticks
continue to select the current stage-0 row instead of the retained cycle-1
mature row.

## 10. Mature fail-closed semantics

Only `currentCycleMature` can reach `observeMaturity`. Pebble still verifies
the real World, exact position and crop, physical stage `7`, source
observation receipt, current plant receipt, plot, cell, actor and cycle. A
current row that claims maturity while the World is at stage `0` still raises
`agricultural maturity observation mismatch` and rolls back exactly.

## 11. Cycle-scoped maturity action identity

Automatic maturity action IDs now have the form
`auto-maturity:<tick>:<plotID>:cycle-<cycleOrdinal>:<cellIndex>`. Two cycles in
the same tick cannot collide, while replay of the same current-cycle physical
proof remains idempotent and publishes one action only.

## 12. Receipts

The selector requires the exact ecological World receipt for the selected row
and the exact physical plant receipt for the current boundary. Auto-maturity
receipts are registered in the candidate tick's World-receipt transaction.
Receipt substitution, wrong World/storage/dimension/content/tick, prior-cycle
receipt reuse and other-cell/plot/crop evidence are refused.

## 13. Restart

No new durable field is required. Schema 30 already preserves cycle ordinal,
current plant action and receipt, `lastWorkEventID`, renewal provenance, causal
ordering and observation receipts. Restore validation now requires a planted
cell's last-work event to be its exact current-cycle plant event while allowing
older mature observations to remain historical. A schema-30 checkpoint saved
with cycle 2 at stage `0` reloads and advances normally.

## 14. Atomicity

Fault injection covers evidence selection, cycle validation, action-ID
creation, physical verification, action publication, cell update, causal
append and final tick validation. Every injected late failure leaves the
published simulation tick unchanged, restores session/agriculture/causal/replay
state, leaves the World crop unchanged and removes every World receipt created
by the failed candidate tick.

## 15. Adversarial tests

The dedicated regression group covers same-actor old-mature/new-non-mature
ordering, both lexical multi-actor directions, same-boundary conflict,
pre-plant evidence, same-tick causal separation, missing current evidence,
later real maturity, receipt substitution, wrong physical tick, wrong crop,
cycle-scoped action IDs, idempotence, multiple cells, schema-30 restart and
non-mutating Observer inspection. Existing fully re-signed checkpoint suites
continue to recompute action, causal, rolling, agriculture, semantic, storage
and manifest digests and reject semantically inconsistent evidence.

## 16. Targeted two-process campaign

The disposable-World runner
[`verify-pebblelab-gate-d-agriculture-cycle-observation-fix.sh`](../../scripts/verify-pebblelab-gate-d-agriculture-cycle-observation-fix.sh)
proved the boundary with World `wmscsurmvlc11`, session
`live-103-14-62--21`, plot `plot-955b8014709cd734` and cell `0`.

Process 1 retained cycle-1 maturity event
`live-103-14-62--21/event-00000000000000000039` and receipt
`eco-81bdee610abb9c38fb6261b4c807bbf28473643f`, replanted cycle 2 through
action `agriculture-live:renewable-cycle2-plant` and causal event
`live-103-14-62--21/event-00000000000000000047`, then selected the new
stage-0 evidence as `currentCycleNonMature`. The normal tick advanced from `1`
to `2` without a maturity action or runtime error.

Process 2 restored the same World/session, advanced normally to tick `4`, grew
the real crop through PebbleCore random ticks to stage `7`, selected current
mature event `live-103-14-62--21/event-00000000000000000094` with receipt
`eco-5dd51ac2d7b2c2a8846b9f4d761f74474f2e33c2`, and published exactly one
`auto-maturity:5:plot-955b8014709cd734:cycle-2:0`. Physical harvest receipt
`agriculture-live:renewable-cycle2-harvest` yielded five carrots. Final
accounting was initial `1`, first planting debit `1`, first harvest `4`, food
debit `1`, stored surplus `2`, second planting debit `1` with first-harvest
provenance, and second harvest `5`.

Across the campaign: World receipts `27`, leaked receipts `0`, duplicate
actions `0`, duplicate receipts `0`, Observer mutations `0`, runtime errors
`0`, external injections after initialization `0`, direct World mutations
after initialization `0`, and cleanup exact. Four fresh captures were opened
individually and inspected at native resolution.

## 17. Regressions

Focused suites passed for agriculture (`66/0`), renewable subsistence
(`19/0`), ecological observation (`68/0`), physical actions (`38/0`), physical
food survival (`50/0`), lifecycle (`80/0`), checkpoint/replay (`49/0`),
persistence/reconciliation (`18/0`), Material Rights (`21/0`), mortality
(`93/0`), estates/inheritance/succession (`84/0`) and Observer (`20/0`):
`606` passed, `0` failed in total. Gate D Blocker 01 position restoration and
Blocker 02 historical ecological-observer runners both remain PASS.

The canonical repository gate result is recorded by the final correction
commit and review package; this report must not be read as an independent Gate
D campaign.

## 18. Limits

This is a bounded selection and reconciliation correction. It does not change
crop growth, force crop stages, add an agriculture engine, shorten historical
retention, relax schema-30 receipts, or claim a general food economy. The
fault-injection and deliberately corrupt fixtures are evaluation-only; the
normal two-process campaign performs no post-initialization state injection.

## 19. Gate D status unchanged

```text
Gate D Blocker 03: FIXED — LOCAL REVIEW CANDIDATE
V4-GATE-D-v1: NOT EVALUATED
next authorized action after publication: V4-GATE-D-v1 — Independent Evaluation 04
CIV-34: NOT STARTED
```

Evaluation 03's former blocker is cleared on the corrected product. Only a new
independent Evaluation 04 after senior review, manual publication and remote
verification may evaluate Gate D.
