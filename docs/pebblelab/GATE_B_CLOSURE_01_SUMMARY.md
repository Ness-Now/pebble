# GATE-B-CLOSURE-01 — Gate B closure candidate

Date: 2026-07-27

## Status

`GATE-B-CLOSURE-01` is a local **GATE B CLOSURE CANDIDATE**, validated for
review and manual publication.

This record does not declare Gate B published or canonically acquired. It does
not start `CIV-26`. The published remote foundation remains
`780d59d04b0e2b943cde2a9a4b39c9f93496ebe5`; the evaluated local product and
harness HEAD is `a4ed5832db9f4f57e4592be4ba7c26788fc7dd64`.

## Resolved contradiction

The eight agricultural soils observed around tick 400 were physical
crop-compatible surfaces, not eight executable agricultural actions. The
source projection previously classified any tillable or already-farmland cell
as viable, while autonomous candidate generation could only proceed from a
pending bounded plot action with all of its real prerequisites:

- a valid local plot phase and pending cell action;
- a real hoe for tilling;
- the exact real seed quantity for planting;
- a nearby real storage container;
- valid local water, site, and cell constraints for initial planning.

A completed action, missing tool or material, incompatible phase, or absent
plan action now makes the source explicitly and diagnostically unavailable.
The same shared execution-facts contract drives agricultural planning and
productive-source viability, so a compatible surface can no longer be
advertised as actionable when no candidate can follow.

The cross-domain audit found and closed an equivalent mismatch in Wild:
arbitrary observed flora had been projected as viable even though only the
canonical gatherable plant set can produce a gathering candidate. Candidate
generation and source projection now share one gatherable-material policy.
Non-gatherable flora remains observable but is not executable.

## Physical contract

An executable source follows:

```text
locally observed physical source
+ matching material state
+ satisfied tool/resource/business prerequisites
→ viable source
→ cognitive opportunity/candidate
→ bounded arbitration and navigation
→ normal PebbleCore-owned physical attempt
→ verified outcome or bounded failure
```

A source with no executable action is represented as temporarily unavailable,
depleted, or withdrawn with a concrete material reason. A new event identifier
alone cannot renew it. Tool restoration, material restoration, local
redetection, or another relevant physical-state transition can.

At the finite-world horizon, quiescence passes only when all of the following
are simultaneously true:

- zero viable productive sources;
- zero generated executable candidates;
- zero active productive activities;
- zero physically executable Work commitments;
- zero active cooldowns;
- no stable retry storm or logical continuity violation;
- normal survival, waiting, and exploration remain available.

A viable source without a candidate is a hard contradiction, not quiescence.

## Implementation

Three reviewable commits form the closure:

| Commit | Classification | Purpose |
| --- | --- | --- |
| `6f407f60a39f3e76fb64f5b13e8f883bc457c106` | PRODUCT | Align agricultural and fishing source viability with executable physical prerequisites. |
| `76fc37773bbd039cbdc3996a6eaec9efc7aaf7cc` | HARNESS / EVIDENCE | Add exact-horizon finite-world classification, fail-closed evidence parsing, sequential pre-soak, and external material reactivation. |
| `a4ed5832db9f4f57e4592be4ba7c26788fc7dd64` | PRODUCT | Share Wild gatherable-flora policy between candidate generation and source viability. |

No PebbleCore file, checkpoint schema, SaveDB format, pathfinder, cognitive
scheduler, inventory authority, or persistence authority changed.

## Causal evidence

Six new canonical checks were added without replacing an existing check:

- executable agriculture with a pending action and complete prerequisites;
- missing agricultural tool;
- missing agricultural material;
- already-completed agricultural action;
- canonical Wild gatherable policy acceptance;
- rejection of locally observed non-gatherable flora as executable.

Additional fail-closed harness self-tests cover false quiescence, incomplete
horizons, and missing load-bearing fields.

The final canonical gate on the evaluated HEAD is:

```text
baseline local checks = 3264
new checks = 6
removed or replaced = 0
expected = 3270
actual = 3270 passed, 0 failed
repository gate = 35/35
```

## Gate B re-evaluation

The evidence root is:

```text
/tmp/PebbleLab-GateB-Closure01-a4ed5832db9f4f57e4592be4ba7c26788fc7dd64
```

All autonomous pre-soak runs used exact horizons, no reroll, no seed
substitution, no productive manual command, and fail-fast on a genuine
failure.

| Seed | Ticks / snapshot / marker | Classification | Physical completions | Final sources observed / viable / temporary / withdrawn | Exercised domains |
| --- | --- | --- | ---: | --- | --- |
| 46 | `800 / 800 / 800` | `PASS_FINITE_WORLD_EXHAUSTED` | 26 | `128 / 0 / 19 / 109` | Agriculture 6, Livestock 2, Physical survival 9, Wild 18 |
| 71 | `800 / 800 / 800` | `PASS_FINITE_WORLD_EXHAUSTED` | 25 | `128 / 0 / 75 / 53` | Agriculture 6, Livestock 2, Physical survival 9, Wild 17 |
| 887 | `800 / 800 / 800` | `PASS_FINITE_WORLD_EXHAUSTED` | 28 | `128 / 0 / 76 / 52` | Agriculture 6, Livestock 2, Physical survival 9, Wild 20 |

Every seed ended with zero viable sources, candidates, active productive
activities, executable Work commitments, and active cooldowns. Runtime errors,
manual productive commands, and convergence blocking reasons were zero.
Movement remained enabled and the Work bounds remained valid.

## Material reactivation

The separate seed-46 fixture first established
`QUIESCENT_NO_EXECUTABLE_SOURCE` at tick 404. It then introduced one real,
mature berry bush into a verified adjacent World cell through the external
test-fixture boundary. The harness did not create an observation, opportunity,
candidate, activity, or success.

The normal local observation, cognition, navigation, and physical executor
produced an autonomous Wild success at tick 408. The scenario reached exact
tick/snapshot/marker `600 / 600 / 600`, with 27 total physical completions and
one verified success after the material event.

## Gate R and scope

Gate R remains acquired:

- PebbleCore remains the sole physical authority;
- AgentSimulationSession remains the sole cognitive authority;
- there is no second pathfinder, scheduler, inventory, persistence system, or
  livestock simulation;
- there is no teleport, `setPos`, collision bypass, forced success, global
  oracle, automatic resource respawn, or productive manual command;
- deterministic bounds, physical custody, checkpoint v18, and replay remain
  covered by the canonical gate.

## What this Gate B candidate proves

- embodied autonomous observation and action through the normal runtime;
- honest executable-source classification;
- normal physical navigation, inventory, collision, and resource constraints;
- bounded failures without retry storms or silent abandonment;
- correct finite-world exhaustion and quiescence;
- autonomous resumption after a new locally observable material fact;
- multiple autonomous physical outcomes across Agriculture, Livestock, Wild,
  and physical survival.

## What it does not prove

- infinite or autonomous resource renewal;
- permanent productivity through tick 800;
- complete agricultural maturation or repeated crop cycles;
- a self-sufficient livestock economy;
- final economic specialization or a durable complete civilization;
- remote publication or canonical acquisition of Gate B.

## Verdict

```text
GATE B CLOSURE CANDIDATE
VALIDATED FOR REVIEW AND MANUAL PUBLICATION

Gate B published/acquired: NO
CIV-26 started: NO
Push attempted: NO
```
