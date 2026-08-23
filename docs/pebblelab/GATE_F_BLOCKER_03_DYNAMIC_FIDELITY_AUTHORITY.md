# Gate F Blocker 03 — Dynamic Population Membership and Fidelity Authority

## Status

`V4-GATE-F-v1 Blocker 03: FIXED + PUBLISHED + REMOTE VERIFIED`

The correction was rooted directly at verified canonical baseline
`0407e8290aa98bde154cb98389893bcc577f830e`. Its product, focused-proof and
two-process runtime commit is
`8358811204c35a79a4be202e57a28dfad4fb3e0f`. Senior review approved manual
fast-forward, publication completed at canonical blocker HEAD
`2c6fe63e81b20ee4a37315a6f5ad528a721c2355`, and independent remote
verification passed. The final review archive SHA-256 is
`26c2cfb0326623c276bed2d7c3838394792d7e6f590b2a5aee41ea3cbdeb2a6f`.

- Gate F Evaluation 01: `FAIL — HISTORICAL IMMUTABLE EVIDENCE`
- Gate F Blocker 01: `FIXED + PUBLISHED + REMOTE VERIFIED`
- Gate F Evaluation 02: `FAIL — HISTORICAL IMMUTABLE EVIDENCE`
- Gate F Blocker 02: `FIXED + PUBLISHED + REMOTE VERIFIED`
- Gate F Evaluation 03: `FAIL — HISTORICAL IMMUTABLE EVIDENCE`
- Gate F Blocker 03: `FIXED + PUBLISHED + REMOTE VERIFIED`
- Gate F: `PLANNED — NOT ACQUIRED`
- Gate F Evaluation 04: `NOT PERFORMED`
- CIV-40: `OPTIONAL TOOLING — NOT STARTED`
- CIV-41: `NOT STARTED`

Publication of this correction does not acquire Gate F or start CIV-40 or
CIV-41. The next authorized required action is
`NEW-INDEPENDENT-V4-GATE-F-v1-EVALUATION-04`; Evaluation 04 was not performed
in this reconciliation.

## Git and historical evidence identity

```text
canonical correction baseline: 0407e8290aa98bde154cb98389893bcc577f830e
verified origin/lab/pebblelab-v1 at correction start: 0407e8290aa98bde154cb98389893bcc577f830e
correction branch: codex/gate-f-blocker-03-dynamic-fidelity-authority
product/test/runtime-proof commit: 8358811204c35a79a4be202e57a28dfad4fb3e0f
documentation/evidence commit and published canonical blocker HEAD: 2c6fe63e81b20ee4a37315a6f5ad528a721c2355
senior review: APPROVED FOR MANUAL FAST-FORWARD
manual publication: COMPLETED
independent remote verification: PASS
final review archive SHA-256: 26c2cfb0326623c276bed2d7c3838394792d7e6f590b2a5aee41ea3cbdeb2a6f
```

Evaluation 03 remains immutable historical evidence:

```text
evaluated baseline: 0407e8290aa98bde154cb98389893bcc577f830e
harness commit: 6732b7c1dcb1ec5fc1a01b560d6149d3a04778d5
final evidence HEAD: 9e66af9b0c4ccc9edcfb399fdf287b5a00f25b5d
review ZIP SHA-256: 153dd4acd9829979442c3d45b4de41fee5eb4170750f43cf9ceb2dd2ac6cbb80
deterministic blocker digest: 35b25f446067c4ad5260cc84602bb0597317c6e753d98242cb38bb6d8eb8ac29
verdict: FAIL — HISTORICAL IMMUTABLE EVIDENCE
```

Both Evaluation 03 ancestry checks return exit `1` from
`git merge-base --is-ancestor`. Neither evaluation commit is an ancestor of
this correction branch; no evaluation harness or evidence commit was merged or
cherry-picked.

## Review, publication and remote verification

Senior review approved the product correction and documentation/evidence for
manual fast-forward. Manual publication then completed, establishing
`2c6fe63e81b20ee4a37315a6f5ad528a721c2355` as the published canonical Blocker
03 HEAD. An independent fetch and remote-ref comparison subsequently passed.
The final review archive SHA-256 is
`26c2cfb0326623c276bed2d7c3838394792d7e6f590b2a5aee41ea3cbdeb2a6f`.

These publication facts close Blocker 03 only. Evaluation 03 remains historical
immutable FAIL evidence, Gate F remains planned and not acquired, and
Evaluation 04 remains not performed.

## Historical contradiction and root cause

Evaluation 03 used an ordinary three-founder session with lifecycle,
reproduction and CIV-39 scale enabled. A normal public birth appended the
newborn to session state, the population registry, the settlement projection
and lifecycle authority, but the birth path never composed that new identity
with `AgentPopulationScaleState.fidelityRecords`.

The product therefore created four current population members and only three
current fidelity authorities. In-memory execution could continue because
`fidelity(for:)` defaults to LIVE for a missing record, but schema-35 restore
correctly enforced exact population/fidelity identity-set equality and rejected
the product-created checkpoint with `invalidBound("population scale")`.

The defect was an authority-composition gap, not a restore-validator defect.
Scale initialization created fidelity records for its initial batch and
scheduled rotation updated existing records, but later lifecycle births and the
legacy/external migration admission path had no shared dynamic-member hook.
Tier allocation logic also lived directly in both initialization and rotation,
making it unsafe for lifecycle code to reproduce independently.

## Shared dynamic fidelity-authority design

`AgentSimulationSession+PopulationScale.swift` now owns one canonical policy
function for complete current membership. It uses population ordinal as the
stable ring order, a stable AgentID tie-break, the current rotation offset, the
configured LIVE and NEAR bounds, and active legacy plus scaled migrations as
LIVE pins. Remaining members fill LIVE, then NEAR, then DORMANT deterministically.

Lifecycle and migration remain the owners of person creation and membership.
They do not select a tier. Before their first causal publication they ask the
scale owner for the exact transition count and validate transition ordinals,
event capacity, current identity equality and pin feasibility. After staging the
new population member, they delegate to the shared scale reconciler. That
reconciler alone:

- computes the complete policy result;
- publishes sorted causal `fidelityTransitioned` events;
- creates exactly one current record for the new identity;
- updates any existing record whose tier must change;
- advances transition counts and ordinals;
- clears stale physical intent on demotion;
- compacts transition history without removing current authority;
- updates the scale and population causal boundary.

The existing public copy-candidate transactions remain the atomic boundary. An
unsupported combined pin set, ordinal exhaustion, causal-capacity failure or
invalid current authority throws before the caller publishes itself. Schema 35
and Observer schema 13 are unchanged, and the strict restore identity-set check
is retained.

## Dynamic membership-path audit

The repository has three supported current-member creation paths while scale
may exist:

1. `initializePopulationScaling` additions: already created fidelity authority;
   it now uses the same canonical policy and recognizes active legacy migration
   pins.
2. Lifecycle birth: now stages membership and delegates immediate fidelity
   reconciliation before final birth publication.
3. Legacy/external `admitMigration`: now delegates the same reconciliation,
   including LIVE pinning for the active incoming migrant.

Mortality remains the sole supported current-member removal transaction. Its
existing scale composition removes the dead identity's current fidelity record,
settlement projection and population membership and terminalizes active
migration exactly once. No second population kernel, fidelity owner, lifecycle
owner or physical path was introduced.

## Birth capacity, causal order and retry

Birth uses the canonical global and committed-settlement capacity authority.
A full population or committed destination now throws the existing
`AgentSessionError.lifecycle(.populationFull)` before any event, lifecycle-plan
terminalization, population ordinal, fidelity transition, state insertion or
registry publication. The pending plan is retained for a legitimate retry.

An accepted scaled birth publishes this causal order:

```text
birth-site validation
  -> populationMemberBorn
  -> one or more fidelityTransitioned events
  -> birthFinalized (linked to social authority and final fidelity event)
```

The historical fixture reaches exactly `4/4`. A later legacy migration is
rejected without mutation. Conversely, if a legacy migrant first consumes the
last committed slot, birth refuses with exact durable bytes, events, population,
lifecycle, scale, fidelity records and ordinals. A real founder death releases
one slot; retry then matches a clean no-refusal execution byte for byte.

## Focused proof

The dedicated selector is:

```text
PEBBLELAB_SMOKE_ONLY=gate-f-blocker-03 .build/debug/pebsmoke
PEBBLELAB_SMOKE_ONLY=gate-f-blocker-03 .build/release/pebsmoke
```

Both builds pass `29/29`. Debug and optimized proof lines are identical:

```text
population=4
fidelity=4
newbornTier=LIVE
checkpointSchema=35
semanticDigest=8e1490b5e0188554e36438cb020ad85edb6e8efdf77e1d6b60f136350dc1eb22
scaleDigest=55117650dea8b89c
```

The matrix proves:

- the historical birth fixture now has population/fidelity identity equality;
- one newborn in state, population, settlement, lifecycle, birth history and
  fidelity authority;
- causal birth-to-fidelity-to-finalization linkage and coherent transition
  record fields;
- LIVE when LIVE capacity is available;
- NEAR when LIVE is full and NEAR is available;
- DORMANT when both configured higher tiers are full;
- equivalent caller order produces identical durable bytes and scale digest;
- bounded transition compaction retains every current fidelity record;
- later scheduled rotation includes the newborn and restores exactly;
- legacy migration creates one LIVE-pinned fidelity record and restores exactly;
- a subsequent birth cannot steal that active incoming LIVE claim;
- an unsupported scaled-plus-legacy pin combination fails closed with exact
  bytes;
- birth consumes the final slot and later migration refuses atomically;
- full-capacity birth refusal preserves bytes and every owning snapshot;
- death releases one slot and retry is byte-identical to a clean path;
- scaled-born mortality removes one current fidelity record and restores
  exactly;
- Observer 13 exposes the newborn and tier without mutation;
- a deliberately corrupted schema-35 checkpoint missing newborn fidelity still
  fails with `invalidBound("population scale")`.

## Two-process runtime proof

Two fresh PebbleLab processes run against one explicit output directory:

```text
.build/debug/PebbleLab --seed 603 --ticks 8 \
  --scenario gate_f_blocker_03_birth_exit_smoke --out <fresh-dir>
.build/debug/PebbleLab --seed 603 --ticks 8 \
  --scenario gate_f_blocker_03_birth_restore_smoke --out <same-dir>
```

Process one proves pre-birth population/fidelity equality, performs a normal
public birth, reaches exact capacity `4/4`, observes one DORMANT newborn record
under `LIVE=1` and `NEAR=1`, checks causal order and writes schema 35 immediately
after birth. Independent auxiliary sessions prove exact rejected-birth
atomicity plus no-gap retry, one LIVE-pinned legacy migrant with exact restore,
and scaled-born mortality/removal with exact restore.

Process two is a new OS process. It restores the immediate-birth durable bytes
exactly with one birth and one initial fidelity transition, advances from tick
4 through the meaningful tick-8 rotation boundary, observes the newborn move
from DORMANT to NEAR exactly once, writes schema 35 again and restores the
post-rotation state exactly. Both processes inspect Observer 13 read-only.

```text
processes=2
immediate-birth semantic digest=7eb8ffaf19551946e0b378c8d54febea5b89210e36ba93f11ce82a6fb553d27b
immediate-birth scale digest=4efb123801d4c046
post-rotation semantic digest=b39d14911e330a1f5b661012a52c900e18da179224dff101614d9b4239be18d0
post-rotation scale digest=65d13a6da78e43f8
checkpoint schema=35
Observer schema=13
population/fidelity=4/4
newborn transitions=1 before restart, 2 after scheduled rotation
duplicate inhabitants=0
duplicate durable identities=0
duplicate memberships=0
duplicate births=0
duplicate fidelity records=0
duplicate fidelity transitions=0
duplicate deaths=0
restart duplicate effects=0
Observer mutations=0
physical loss=0
physical duplication=0
synthetic material=0
unexpected runtime errors=0
cleanup=exact PASS
```

This is a validation-only blocker, so no rendered campaign is claimed. The
canonical embodiment and candidate-physical-atomicity regressions retain the
real Pebble/Core mutation, verification and compensation proof. No newborn
economic activity is invented; all existing Gate D and Gate E ownership,
custody, production, contract and market regressions remain passing.

## Validation

| Surface | Result |
| --- | ---: |
| Gate F Blocker 03 debug | 29/29 PASS |
| Gate F Blocker 03 optimized | 29/29 PASS |
| Gate F Blocker 02 debug / optimized | 27/27 each PASS |
| Gate F Blocker 01 debug / optimized | 20/20 each PASS |
| CIV-39 | 69/69 PASS |
| population migration | 66/66 PASS |
| Gate D owning continuity | 544/544 PASS |
| Gate E owning continuity, including E01–E04 | 291/291 PASS |
| migration/embodiment/persistence/Observer/atomicity | 949/949 PASS |
| all listed owning selectors | 1860/1860 PASS |
| canonical repository verification | 35/35 steps; 4133/4133 assertions PASS |

Gate D includes CIV-39, homeostasis/health, lifecycle/reproduction, mortality,
genetics, estates/inheritance/succession, unions/family/lineages/houses and
dependent care. Gate E includes material rights, production, barter, contracts,
markets and Gate E Blockers 01–04. The physical/persistence group includes
population migration, embodiment/Core descent, autonomous civilization,
checkpoint/replay, persistence/reconciliation, Observer and candidate physical
atomicity.

`scripts/verify-pebblelab.sh` passes all 35 steps and all 4,133 assertions. No
golden was regenerated and no test was weakened.

## Changed product and proof surfaces

Product:

- `Sources/PebbleAgents/AgentSimulationSession+PopulationScale.swift`
- `Sources/PebbleAgents/AgentSimulationSession+Lifecycle.swift`
- `Sources/PebbleAgents/AgentSimulationSession+Population.swift`

Focused and runtime proof:

- `Sources/pebsmoke/PebbleAgentsGateFBlocker03Smoke.swift`
- `Sources/pebsmoke/main.swift`
- `Sources/PebbleLab/LabGateFBlocker03DynamicFidelityScenario.swift`
- `Sources/PebbleLab/LabOptions.swift`
- `Sources/PebbleLab/LabScenarios.swift`
- `Sources/PebbleLab/main.swift`

## Limitations and non-claims

- This is published Blocker 03 correction evidence, not Gate F acquisition
  evidence.
- Evaluations 01–03 remain immutable historical FAIL evidence.
- Gate F remains planned and is not acquired.
- Evaluation 04 was not performed; its new independent evaluation is the next
  authorized required action.
- CIV-40 remains optional tooling and is not started; CIV-41 is not started.
- Checkpoint schema remains 35 and Observer schema remains 13.
- No capacity, migration-concurrency or fidelity bound is increased.
- No second civilization authority, physical engine, currency or rendered proof
  is introduced.
- Goldens regenerated: NO.
- Documentation-reconciliation push attempted: NO.
