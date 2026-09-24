# PS01 Increment 05 — Temporal Physiology Coherence

Status: **COMPLETE AND PUBLISHED — PASS — SENIOR REVIEW APPROVED — REMOTE
VERIFIED**.

Technical senior review: **PASS — P0 0 / P1 0 / P2 blocking 0**.

PLAYABLE SLICE 01 remains **REQUIRED — IN PROGRESS / NOT COMPLETE**.
CIV-48 remains **NOT STARTED — IMPLEMENTATION NOT AUTHORIZED**. This report
does not select or authorize Increment 06.

## Review position

- Repository: `Ness-Now/pebble`.
- Canonical branch: `lab/pebblelab-v1`.
- Canonical baseline and parent:
  `1d2c4a92df4e570d56443c4920aae7072637e8f1`.
- Canonical baseline tree:
  `94ec5cc041437fbf821d9d4ccc92ba29f9ce40b1`.
- Published commit: `1614d181668b495d5321f2dfb5627c147b1e64d1`.
- Published tree: `09b5ed6f186e7956883267a9f5d549da4d1e5c76`.
- Published parent: `1d2c4a92df4e570d56443c4920aae7072637e8f1`.
- Published message: `feat(ps01): decouple physiology from cognition time`.
- Accepted senior-review ZIP SHA-256:
  `6cf9ad035b0a35bc436a4e9915a0135fd1180c572b547f17a47d8ab4f11e4a5a`.
- Frozen `Sources` subtree:
  `41f9e7887e466198513cf46ab9c69d1b75e0b75c`.
- Implementation branch:
  `codex/ps01-increment-05-autonomous-renewable-subsistence`.
- Publication: manual user push completed; canonical remote independently
  verified.

This document records the published Increment-05 product and its accepted
evidence. Post-publication reconciliation changes no path under `Sources/`, no
package manifest, script, test, golden, or product behavior.

## Actual increment chronology

1. **Original renewable-subsistence selection.** The initial Increment-05
   direction was renewable physical subsistence, following Increment 04's
   finite natural sweet-berry loop.
2. **Energy-balance architecture finding.** The pre-implementation audit found
   that passive hunger, fatigue, starvation, and demographic age were advanced
   by cognitive ticks. Product physiology therefore varied with cognition Hz,
   path readiness, pause behavior, and catch-up scheduling. Renewable food
   economics could not be made authoritative on that base.
3. **Reselection to Temporal Physiology Coherence.** Increment 05 was narrowed
   to removing cognition frequency as passive biological time authority before
   extending the food supply.
4. **World-time authority design.** Authoritative PebbleCore World ticks became
   the only current passive-biological clock. Pebble reconciles World time at
   the controller boundary, and `AgentSimulationSession` remains the sole
   civilization transition owner.
5. **Schema 44 introduction.** Schema 44 durably records the physiological
   cursor, elapsed World ticks, remainder, applied boundaries, pending
   boundaries, and calibration. Current checkpoints no longer infer their
   schema from whichever historical feature is enabled.
6. **Replay and persistence correction.** Rebase/advance operations became
   explicit replay data. Promotion to schema 44 is transactional; restore and
   replay validate temporal state and retain exact bytes and causal results.
7. **Debug stack-pressure diagnosis and harness-only isolation.** The enlarged
   proof suites exposed debug-build stack pressure rather than recursive
   product execution. Large proof aggregates were separated at real
   `@inline(never)` function boundaries. The session transition remains a
   shallow transactional copy into one in-place implementation.
8. **Historical schema 1–43 compatibility migration.** Existing historical
   fixtures were bound to their real owning schema through one bounded Testing
   SPI. Unmigrated historical checkpoints retain cognitive-time physiology;
   current sessions remain World-time based.
9. **Seed-14 rollback-time biology P1.** Natural execution showed that a
   path-readiness rollback could also discard otherwise eligible elapsed
   biology. The physical/cognitive candidate correctly failed closed, but the
   temporal consequence could not be silently lost.
10. **Compensated temporal-only publication.** After a readiness failure, the
    controller may publish only the already-eligible biological transition.
    It publishes no movement, path, observation, action, or false absence.
    This preserved biological time without claiming that path readiness was
    solved.
11. **Seed-46 ecological membership causal-retention P1.** Long natural
    execution exposed that a still-active resident's original membership
    causal event could leave the bounded ledger while ecological validation
    still required an authoritative active-membership proof.
12. **Bounded active-membership authority.** A bounded current-membership
    authority event was added as a projection of the population registry. It
    retains exactly the active set and is refreshed transactionally as
    membership changes. The registry remains the sole population-state
    authority.
13. **Active-to-deceased authority transition.** Mortality now hands authority
    from the active membership projection to the durable deceased record and
    cleanup chain before active evidence may be evicted. No resurrection or
    competing roster was introduced.
14. **Typed fatal-integrity latch.** A normal-session integrity corruption is
    classified separately from transient path/readiness unavailability. It
    latches the exact civilization execution context and prevents scheduler
    retries or temporal fallback.
15. **Senior-review fatal command-gate correction.** Mutating commands,
    including resume/step, are refused after the latch. Read-only observation
    and explicit execution-context termination remain available.
16. **Senior-review schema-44 membership restore invariant.** Restore now
    validates that schema-44 current-membership authority exactly matches the
    population registry and retained causal identities. Historical schemas
    are not retrofitted with that current-only invariant.
17. **Headless normal-product characterization.** A headless harness was added
    after the macOS drawable path proved unsuitable for long unattended
    evidence. It drives the normal controller/product path and records
    deterministic reports; it does not create a second simulation kernel.
18. **PebbleLab historical fixtures schemas 3–10.** The canonical gate found a
    second historical-fixture surface. Settlement Metrics, Local Ecology,
    Mortality, Lifecycle, Kinship, Household, Dependent Care, and Practice
    Skills had defaulted to schema 44. Each was restored to its honest
    predecessor and operation-specific owning schema.
19. **Final evidence campaign.** Natural seeds 14, 46, and 887, performance,
    Increment-03/04 regressions, the 4,866-assertion smoke, and the complete
    35-stage canonical gate passed without regold.
20. **Final blocker analysis.** Technical senior review found no product P0 or
    P1. Documentation/package hygiene was the only remaining local-review
    blocker. Path-readiness liveness and renewable physical subsistence remain
    unselected forward candidates rather than hidden Increment-05 outcomes.

## Current product contract

World time is the sole current passive-biological time authority. Current
checkpoint and replay schema is 44. A cognitive `advanceTick()` without
eligible World time does not advance hunger, fatigue, or biological age, so
these properties are not cognition-Hz-derived.

The accepted live calibration is:

- 24,000 World ticks per day;
- a 1,200-World-tick biological boundary;
- hunger increase 1.0 per World day;
- fatigue increase 1.2 per World day;
- maximum temporal input 9,600 World ticks;
- maximum pending boundaries 8.

Reconciliation accepts only monotonic, bounded World progression. A pause
rebases the World cursor so intentionally paused time is excluded rather than
later granted as catch-up biology. Restore of a historical checkpoint remains
historical until an explicit World-time rebase transactionally migrates its
continuation.

Path-readiness compensation publishes eligible biology only. It cannot publish
a physical action, movement, observation, path conclusion, resource absence,
or other rolled-back cognitive result. A typed fatal integrity failure is a
different class: it latches the session and never uses temporal fallback.

Membership evidence is bounded. The population registry remains the sole state
authority; the retained current-membership event is a validated causal
projection, not a second roster. Mortality performs an explicit
active-to-deceased authority handoff.

Schemas 1–43 preserve their historical cognitive-time physiology and age
semantics while unmigrated. They contain no invented World-time cursor or
schema-44 temporal replay record.

## Acceptance evidence

All results below are final accepted evidence. Pre-correction diagnostic runs
are not acceptance results.

- Canonical gate: **35 / 35 PASS**.
- Optimized smoke inside the canonical gate: **4,866 / 4,866 PASS**.
- Standalone final smoke: **4,866 / 4,866 PASS**, 101.45 seconds.
- Increment 03: **34 / 34 PASS**.
- Increment 04: **33 / 33 PASS**.
- Runtime errors: **0**.
- Catch-up drops: **0**.
- Regold: **NO**.

Natural normal-product characterization:

- Seed 14: 1,200 eligible World ticks, civilization tick 22, 218 path
  readiness failures, 218 legitimate temporal fallbacks, one physiological
  boundary, hunger/fatigue `0.05 / 0.06`, and zero runtime or integrity errors.
- Seed 46: two headless runs were byte-identical. Report SHA-256 begins
  `ba8d017e` and ends `bf3`; semantic digest begins `4f0e6f` and ends `0803c`;
  causal digest begins `0f64c7` and ends `d5d6`. Current-versus-native semantic
  convergence passed, with zero runtime/integrity errors and catch-up drops.
- Seed 887: 1,200 World ticks, 240 cognitive ticks, one physiological boundary,
  and zero path, integrity, runtime, or fatal errors.

Release performance:

| Founders | Median | p95 |
| ---: | ---: | ---: |
| 20 | 83.463 ms | 99.919 ms |
| 24 | 108.951 ms | 129.969 ms |
| 30 | 147.339 ms | 187.070 ms |

All reported maxima were below 200 ms. These measurements reported zero
runtime errors and zero catch-up drops.

## Calibration sensitivity

At 20 World ticks per second, 24,000 ticks are 20 minutes and the 1,200-tick
boundary is one minute. Live rates therefore add 0.05 hunger and 0.06 fatigue
per boundary.

At live calibration:

- hungry threshold 0.40: 8 boundaries / 8 minutes;
- critical hunger 0.80: 16 boundaries / 16 minutes;
- full hunger 1.00: 20 boundaries / 20 minutes;
- fatigue threshold 0.65: 11 boundaries / 11 minutes (0.66 accumulated);
- starvation grace: 2 critical boundaries;
- first starvation damage: boundary 18 / 18 minutes;
- ten 10-health damage events: lethal boundary 27 / 27 minutes without food.

Rate sensitivity with the 1,200-tick boundary held constant:

| Rate | Hunger/boundary | Hungry | Critical | Full | Fatigue threshold | Berry offset | Carrot offset | Lethal starvation |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 0.5x | 0.025 | 16 min | 32 min | 40 min | 22 min | 4 min | 6 min | 43 min |
| 1.0x | 0.050 | 8 min | 16 min | 20 min | 11 min | 2 min | 3 min | 27 min |
| 2.0x | 0.100 | 4 min | 8 min | 10 min | 6 min | 1 min | 1.5 min | 19 min |

Boundary sensitivity with aggregate daily rates held constant:

| Boundary | Hunger increment | Hungry threshold | Fatigue threshold | First damage | Lethal starvation |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 600 ticks | 0.025 | 16 boundaries / 8 min | 22 boundaries / 11 min | 17 min | 21.5 min |
| 1,200 ticks | 0.050 | 8 boundaries / 8 min | 11 boundaries / 11 min | 18 min | 27 min |
| 2,400 ticks | 0.100 | 4 boundaries / 8 min | 6 boundaries / 12 min | 20 min | 38 min |

The boundary changes starvation-damage cadence even when aggregate daily rates
are unchanged. The 1,200-tick boundary is therefore product calibration, not
merely an implementation batching interval. Increment 05 made no later retune.

## Berry and carrot read-only recalculation

The accepted recalculation reused canonical Core food and crop definitions. It
did not change them.

- One sweet berry has Core hunger value 2/20, or 0.10 normalized relief. At
  live calibration that offsets two biological boundaries / two minutes.
- One carrot has Core hunger value 3/20, or 0.15 normalized relief. That
  offsets three boundaries / three minutes.
- From the hungry threshold 0.40 to the recovery threshold at or below 0.15,
  three berries or two carrots each provide 0.30 relief and reach 0.10.
- A mature berry bush drops 1...3 berries: 0.10...0.30 relief, equivalent to
  2...6 live minutes. Only the three-berry outcome crosses recovery from
  exactly 0.40.
- A mature carrot crop drops 3...5 carrots. Reserving one for replant leaves
  2...4 edible carrots: 0.30...0.60 relief, equivalent to 6...12 live minutes.
- The already-proven renewable path remains harvest 5, consume 1, store 3,
  replant 1. Its consumed carrot offsets three live minutes.

This analysis does not claim that the normal product has renewable physical
subsistence.

## Historical compatibility and migration ledger

Schemas 1–43 preserve their historical semantics. The sole compatibility API,
`useLegacyCognitivePhysiologyReplayFixture(schemaVersion:)`, is
`@_spi(Testing)`, accepts only supported schemas below 44, and refuses binding
after a World cursor or elapsed World time exists. It is not an environment
switch, public product mode, or arbitrary current-session schema setter.

The canonical gate exposed PebbleLab schemas 3→10 as a second historical
fixture surface beyond the initial pebsmoke sweep:

| Feature | Predecessor | Owner | Final proof |
| --- | ---: | ---: | --- |
| Settlement Metrics | 2 | 3 | A/B/canonical/diff PASS |
| Local Ecology | 3 | 4 | A/B/canonical/diff PASS |
| Mortality | 4 | 5 | A/B/canonical/diff PASS |
| Lifecycle/Reproduction | 4 | 6 | A/B/canonical/diff PASS |
| Durable Kinship | 6 | 7 | A/B/canonical/diff PASS |
| Household Membership | 7 | 8 | A/B/canonical/diff PASS |
| Dependent Care | 8 | 9 | A/B/canonical/diff PASS |
| Practice Skills | 9 | 10 | A/B/canonical/diff PASS |

These were stale fixtures defaulting to schema 44, not current-product
regressions. Their correction used honest predecessors and operation-specific
successful promotion. Failed activation does not promote. No expected schema
was changed, no historical byte check was weakened, no fake World time was
injected, and no golden was regenerated.

Migration totals use one proof source file/suite as the unit. Categories may
overlap where one suite proves current and historical behavior.

- **A — current structural:** 5 proof suites: focused Temporal Physiology,
  Ecological Observation current-v44 paths, Social current-v44 path, Vertical
  current-v44 paths, and Persistence/Replay schema-record structure.
- **B — historical exact:** 62 migrated pre-existing fixture owners: 54
  pebsmoke owners and 8 PebbleLab scenarios. The new focused Temporal
  Physiology suite also owns one schema-1 compatibility fixture, so the final
  proof surface is 63 files with 155 bounded SPI bindings (124 pebsmoke and 31
  PebbleLab).
- **C — semantic invariant:** 1 Runtime suite with 2 assertions: cognitive
  ticking without World time preserves hunger and preserves fatigue.

Registration in `pebsmoke/main.swift` is not counted as a migration.

## Bounded-wait and stack isolation

Increment 05 added 16 loops: one physiological boundary loop bounded by the
durable maximum of 8; three characterization loops, including one state wait
with a hard 60-second deadline; two deterministic credit loops that subtract
20 each iteration; nine ecological proof loops with explicit limits below 128
or 2,048; and one mortality proof loop capped at 16 with a terminal
precondition. External/state waits: 1. Hard-deadlined external/state waits: 1.
Unbounded external waits: 0.

`AgentSimulationSession.advanceTick` makes one shallow transactional copy and
calls one in-place transition; it is not recursive. The controller applies one
replay operation without callback recursion. A 512-step `@inline(never)` proof
kept the stack sentinel address stable while producing exact temporal totals.
The bounded physiological loop processes at most eight pending boundaries.
Debug and release builds, all focused proofs, the full smoke, and the canonical
gate passed.

## Explicit non-outcomes

**Renewable physical subsistence was NOT implemented by Increment 05.**

**Reproduction remains disabled in the normal PS01 product
characterization.** Historical schema fixtures exercise historical
reproduction only as compatibility proof; that is not normal-product
activation.

**PATH-READINESS LIVENESS remains unresolved.**

**PS01 remains REQUIRED — IN PROGRESS / NOT COMPLETE.**

**CIV-48 remains NOT STARTED — IMPLEMENTATION NOT AUTHORIZED.**

Increment 06 is not selected or authorized by this report.

## Unselected forward blocker candidates

These candidates are recorded without ranking or selection.

### PATH-READINESS LIVENESS

Seed 14 reached only civilization tick 22 while 1,200 eligible World ticks
elapsed. It recorded 218 readiness failures and 218 legitimate temporal
fallbacks. Biology remained coherent and published one exact boundary, but
cognitive/action progress can stall while readiness repeatedly fails.

### RENEWABLE PHYSICAL SUBSISTENCE

Increment 04 still relies on finite naturally generated sweet berries.
Increment 05 recalculated berry/carrot energy economics but implemented no
renewable physical food loop. Long-run food continuity therefore still
requires future causal work.

## Local-review disposition

The technical senior review result is **PASS**. Product evidence remains valid
because this repository-history correction changes documentation only and the
frozen `Sources` subtree remains identical.

- P0: **0**.
- P1: **0**.
- P2 blocking: **0**.
- Program surveillance: **PATH-READINESS LIVENESS**.
- Product publication: **REMOTE VERIFIED**.
- Push attempted: **NO**.
- Published: **YES — MANUAL USER PUSH COMPLETED**.

The correct disposition is **COMPLETE AND PUBLISHED — PASS — SENIOR REVIEW
APPROVED — REMOTE VERIFIED**.
