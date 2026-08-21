# Gate E Evaluation 05 — Local Material Economy

## Verdict

`LOCAL PASS CANDIDATE — SENIOR REVIEW REQUIRED`

This evaluation does not acquire Gate E. It records a fresh, independent local
evaluation of `V4-GATE-E-v1 — Local Material Economy` at the exact published
baseline `9d841cc28dd4a43f70aff6265ead2e25fa6f160c`.

No product correction was made, CIV-38 was not started, currency was not made a
dependency, goldens were not regenerated, and no push was attempted.

## Repository and historical authority

- Repository: `Ness-Now/pebble`
- Canonical branch: `lab/pebblelab-v1`
- Canonical remote SHA verified after `git fetch origin`:
  `9d841cc28dd4a43f70aff6265ead2e25fa6f160c`
- Evaluation branch: `codex/gate-e-evaluation-05`
- Evaluation branch root: the exact canonical SHA above
- Initial worktree: clean
- Evaluation 01 evidence ancestor: NO
- Evaluation 02 evidence ancestor: NO
- Evaluation 03 evidence ancestor: NO
- Evaluation 04 evidence ancestor: NO

The four earlier evaluations retain their immutable historical result:
`FAIL — HISTORICAL IMMUTABLE EVIDENCE`. Blockers 01 through 04 remain
`FIXED + PUBLISHED + REMOTE VERIFIED`. Gate E remains
`PLANNED — NOT ACQUIRED`. CIV-38 remains `OPTIONAL — NOT STARTED`, and currency
remains outside the Gate E dependency set.

## Evaluation design

Evaluation 05 was selected from implementation inspection rather than from a
mechanical replay of Blocker 04. A new same-session selector follows one exact
durable pickaxe through production, barter, physical tool evolution, contract
consideration, return to a former owner, market custody, settlement, and a
second return to a former holder. It composes this path with exact
quantity-bearing needs, future material production, participant availability,
local price history, terminal histories, schema-34 restart and schema-11
read-only observation.

The focused composed trajectory checks that:

1. immutable production origin, durable asset identity, evolved current
   material identity, current economic commitment, current Material Rights and
   current physical authority remain separate;
2. live barter commits both exact legs under one operation, verified exchange
   moves ownership, and terminal barter history releases current authority;
3. an accepted contract commits its concrete consideration asset but does not
   pre-reserve an arbitrary exact asset for a promised future material type;
4. an unrelated market operation cannot use contract-bound consideration, the
   owning contract can continue after restart, and terminal contract history
   does not block later reuse;
5. concrete consideration and fulfillment require current exact custody and
   eligibility, and duplicate fulfillment cannot duplicate state;
6. unavailable participants block market decisions or settlement without
   converting old records into current authority;
7. verified receipts fulfill only matching quantity-bearing needs, including
   an insufficient market receipt that leaves the remaining need active;
8. price history is created only after verified settlement, remains scoped to
   the local oriented commodity pair, and supplies no ownership, custody,
   locality or settlement authority;
9. schema-34 restart derives the same live commitment projection, preserves
   terminal release and retained economic evidence, creates no new physical
   effect, and keeps bounded state within configured limits; and
10. Observer schema 11 leaves tick, causal sequence and digest unchanged.

The composed selector passed 21/21 assertions.

## Fresh runtime campaigns

Five new isolated primary session roots supplied 14 decisive fresh processes
and 43 manually inspected captures:

- production: 2 processes, 6 captures, checkpoint schema 31;
- barter: 2 processes, 6 captures, checkpoint schema 32;
- contracts: 2 processes, 5 captures, checkpoint schema 33;
- markets: 4 processes, 13 decisive captures, checkpoint schema 34; and
- Blocker 04 whole-system commitment composition: 4 processes, 13 captures,
  checkpoint schema 34 and Observer schema 11.

Fresh auxiliary Blocker 01 through 03 campaigns supplied another 8 passing
processes and 33 inspected captures. Blocker 04 is already included in the
primary count. One additional excluded diagnostic process produced 5 inspected
captures while attempting to load a stale checkpoint after a later unsaved
market deposit. The load refused because checkpoint-bound escrow was absent,
physical markets did not initialize, and no economic or physical mutation was
published. This is retained as correct fail-closed diagnostic evidence, not
counted as a decisive passing campaign and not used to inflate the verdict.

Three inherited live wrappers contain assertions whose literal text predates
the published runtime output:

- barter expected an older tool-use phrase, while the trace recorded the exact
  produced tool, `damage=0>1`, `dropsAcquired=1`, and `downstreamUse=PASS`;
- contracts expected an older post-mutation prefix, while the trace recorded
  the protected policy, verified rollback, clean retry and verified
  consideration; and
- the ordinary market wrapper assumed the terminal stall remained empty, while
  normal cognition legitimately deposited a new distinct asset after terminal
  history release.

These are harness-text/fixture-expectation mismatches, not accepted silent
failures. The underlying raw traces were inspected, the dedicated current
Blocker 01 through 04 live regressions all passed, and no verifier or product
source was changed to conceal the mismatches. The dedicated Blocker 03 campaign
saved the post-reentry state before restart and then proved exact withdrawal
and cleanup.

## Validation results

Fresh Evaluation 05 focused selector:

- `gate-e-evaluation-05`: 21 passed, 0 failed

Owning Gate E selectors:

| Selector | Passed | Failed |
|---|---:|---:|
| production | 36 | 0 |
| barter | 56 | 0 |
| contracts | 32 | 0 |
| markets | 31 | 0 |
| material-rights | 23 | 0 |
| candidate-physical-atomicity | 3 | 0 |
| checkpoint-replay | 49 | 0 |
| persistence-reconciliation | 19 | 0 |
| observer | 20 | 0 |
| autonomous-civilization | 36 | 0 |
| **Total** | **305** | **0** |

Dedicated Blocker focused/live results:

| Blocker | Focused | Live |
|---|---:|---|
| 01 | 27/27 | PASS — 2 processes, 9 captures |
| 02 | 33/33 | PASS — 2 processes, 8 captures |
| 03 | 25/25 | PASS — 4 processes, 16 captures |
| 04 | 28/28 | PASS — 4 processes, 13 captures |

The Evaluation 05 selector, owning selectors and Blocker selectors total
439/439 focused assertions. `scripts/verify-pebblelab.sh` separately passed all
35 repository verification steps and 4015/4015 assertions. Its golden policy
remained read-only and refused `PEBBLE_REGOLD`.

## Strongest evidence

The strongest result is the agreement between the 21-assertion composed
same-session trajectory and the four-process Blocker 04 live campaign. The
former carries an exact produced and evolved asset through every economic role
while independently checking origin, identity, rights, ownership, needs,
commitment projection, participant status, price scope, restart and Observer
immutability. The latter demonstrates the decisive physical boundary: an exact
asset committed to one live operation cannot be acquired by an incompatible
operation, the owning operation can continue after restart, terminal history
releases authority, and ordinary reuse subsequently succeeds with exact
conservation and cleanup.

The ordinary production, barter, contract and market campaigns plus the fresh
Blocker 01 through 03 campaigns exercise the surrounding live transaction,
rollback, retry, physical custody, checkpoint and reconciliation paths. Their
combined evidence shows no matter loss, duplication, synthetic material,
duplicate live commitment, deposit, reservation, receipt or settlement,
Observer mutation, or unexpected runtime error.

## Architecture finding

The evaluated behavior preserves the permanent architecture:

- PebbleCore remains physical World truth and persistence;
- Pebble remains the live sensor, executor, verifier, reconciler and rollback
  owner;
- PebbleAgents remains deterministic cognition and bounded civilization state;
- `AgentSimulationSession` remains the unique civilization aggregate;
- Material Rights describes identity, provenance and claims but does not
  replace current physical verification;
- Observer remains read-only; and
- historical economic records explain past events but grant no current
  physical or economic authority.

No second kernel, parallel physical economy or product behavior change was
introduced by this evaluation. The only source changes are an evaluation-only
`pebsmoke` selector and access widening of existing `pebsmoke` fixture helpers
so the new selector can reuse the published test model.

## Final counters and schemas

| Measure | Result |
|---|---:|
| checkpoint schema | 34 (whole-Gate current schema) |
| Observer schema | 11 |
| physical loss | 0 |
| physical duplication | 0 |
| synthetic material | 0 |
| duplicate live commitments | 0 |
| duplicate deposits | 0 |
| duplicate reservations | 0 |
| duplicate receipts | 0 |
| duplicate settlements | 0 |
| Observer mutations | 0 |
| unexpected runtime errors | 0 |

Expected injected transaction faults are retained separately from unexpected
runtime errors. Each decisive campaign conserved physical state. Exact fixture
cleanup was demonstrated by the passing production, barter, contract and
dedicated Blocker campaigns; the ordinary market campaign retained its
legitimate post-terminal reentry asset, and the dedicated Blocker 03 campaign
demonstrated its exact supported withdrawal-and-cleanup path.

## Senior-review boundary

This is local evaluation evidence only. Gate E acquisition requires separate
senior review, evidence publication and explicit program-state canonization.
Evaluation 05 therefore returns `LOCAL PASS CANDIDATE — SENIOR REVIEW REQUIRED`
and makes no claim that Gate E is acquired.
