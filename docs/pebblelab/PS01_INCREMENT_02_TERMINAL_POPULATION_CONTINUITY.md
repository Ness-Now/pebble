# PS01 Increment 02 — Terminal Population Continuity

Status: **LOCAL REVIEW CANDIDATE**.

PLAYABLE SLICE 01 remains **REQUIRED — IN PROGRESS / NOT COMPLETE**.
CIV-48 remains **NOT STARTED — IMPLEMENTATION NOT AUTHORIZED**. This report
does not authorize Increment 03. The selection review's expected runner-up,
Authoritative Time / Physical Coverage, remains informational only.

## Baseline and scope

- Repository: `Ness-Now/pebble`.
- Canonical branch: `lab/pebblelab-v1`.
- Verified published baseline:
  `7f732c320bb5685bed436868367ce2fb10385953`.
- Baseline tree: `4b7fcdc66fa6c4d13c1ec5bc90fb8325a8bc024c`.
- Baseline parent: `a5bded01dcfc934dc5aed6aab0990fc61ffd30c7`.
- Baseline message: `docs(ps01): record increment 01 publication`.
- Implementation branch:
  `codex/playable-slice-01-increment-02-terminal-population-continuity`.

This increment corrects terminal continuity for a causally simultaneous lethal
cohort inside the already-supported bounded active population. It does not add
food, reproduction, population headroom, time control, culture, Observer
authority, general population scaling, CIV-48, or any other Playable Slice
increment.

## Architecture and authority

The selected design is a **session-owned terminal-cohort barrier**.
`AgentSimulationSession` remains the sole civilization aggregate root and
mortality authority. `Pebble` remains the physical adapter, transaction,
verification, rollback, and publication owner. `PebbleCore` remains World and
physical truth. Observer remains a read-only projection.

At a mortality survival boundary, the session advances survival and
homeostasis to one deterministic tick, orders all newly lethal identities by
`AgentID`, and stages the complete cohort as bounded pending mortality. That
existing pending state is the barrier; no second roster or mortality engine is
introduced. All members retain their original lethal tick even when custody
and finalization are performed in deterministic substeps.

While the barrier exists:

- terminal identities receive no survivor perception;
- terminal identities receive no cognition, goal selection, decision, action,
  work, reproduction, migration, contract, material, care, or guardianship
  authority;
- survivor-only World perception may be recorded at the already-committed
  boundary so survivor physiology and feedback remain aligned;
- dependent-care, childhood, estate, work, migration, family, household, and
  communication cleanup see the complete same-tick terminal identity set;
- physical custody may remain explicitly pending in the session contract.

Two existing passive boundaries must still finish at that committed tick.
Lifecycle stage state is brought to the mortality tick, then guardianship,
dependent-care, and estate custody records made historical by that lifecycle
transition are closed or revalidated. These operations create no replacement,
need, engagement, household movement, work, or social obligation. They are
**PASSIVE BOUNDARY COMPLETION**, not post-mortality participation.

The last pending member's civilization finalization advances only surviving
genetic development to the already-committed tick. Performing this after the
complete cohort prevents finalization order from making a later cohort member
look temporarily alive. The pending transitions disappear through existing
mortality finalization. There is no separately persisted barrier field:
checkpoint state persists the existing, validated pending mortality records and
their original `detectedAtTick`.

In the normal controller, the entire pending cohort is physically reconciled
inside the same candidate controller update. Each probe and its real carried
custody is inspected, transferred or verified empty, recorded, removed, and
verified through existing Pebble owners. The controller publishes the session,
replay recorder, receipt transaction, and physical transaction only after all
members succeed. It cannot publish a half-terminal cohort as complete. A late
failure rolls civilization/replay/custody/probes back to the previous complete
boundary; unverifiable rollback retains the existing hard-failure discipline.
Pebble never chooses who is causally dead.

Direct session tests can persist a supported pending physical state. The normal
controller does not publish such a state across controller updates: success
finishes the cohort atomically, and failure restores the pre-tick boundary.

## Mortality configuration

Historical configuration semantics are unchanged:

- `AgentMortalityConfiguration.live.maximumDeathsPerTick == 8`;
- `AgentMortalityConfiguration.embodiedLive.maximumDeathsPerTick == 8`.

The normal founder path selects `embodiedPopulationBounded` from its existing
authoritative `AgentPopulationConfiguration.maximumActivePopulation`. The PS01
normal profile therefore selects 30, matching its unchanged active-population
capacity of 30. Founder range remains `20...30`. No birth/admission headroom or
population rule changed.

The configuration constructor's finite admissible ceiling changes from 8 to
512 so an owner can express the already-bounded population authority. The
population-derived factory enforces the same finite ceiling. This is not a
global default change: historical callers remain at 8, and the normal PS01
product selects 30. No retained-record, compacted-summary, exit-frame,
dependent-care, childhood, household, work, communication, material-exit, or
physical-transaction capacity was raised.

This is not merely an `8 -> 30` constant change. A numerical change alone would
still permit processing order to select another terminal cohort member as a
caregiver, leave historical work or communication evidence invalid, advance
terminal cognition, publish only part of a physical batch, or misalign survivor
development. The barrier and owner-specific cleanup semantics are the product
correction.

## Product integration defects found and corrected

The development campaign preserved the distinction between fixture mistakes
and product defects.

Fixture construction errors, not product bugs:

- a supervision engagement was advanced without the required verification;
  the fixture now uses the existing verified-care operation;
- a replacement caregiver in a separate singleton household was expected to
  be eligible; the fixture now constructs the existing-policy household
  relationship;
- a founder household no-op move was assumed to create evidence; the fixture
  now uses a transition that the existing household authority actually owns.

Real cross-authority product integration defects:

1. **Dependent care.** An active engagement whose caregiver had health zero
   was rejected even while that caregiver was explicitly pending same-boundary
   mortality cleanup. Validation now recognizes only an existing pending
   terminal reference. Selection and replacement still exclude the complete
   terminal cohort, including the case where the otherwise preferred
   replacement is also terminal.
2. **Work/checkpoint.** Mortality correctly ended all commitments, but work
   validation required an ended commitment's worker to remain in the living
   lifecycle roster. Open commitments and active demands still require living
   authority. Historical references require an actual retained or compacted
   death, coherent pre-death ticks, a closed record, and valid terminal work
   provenance. An active commitment to a dead worker and a provenance-free fake
   ended record are both rejected.
3. **Shared communication/checkpoint.** A transport with two terminal
   participants failed once, but its legitimate shared mortality provenance
   was rejected. Cleanup now returns the bounded communication provenance
   boundary. Checkpoint validation requires that exact parented boundary and
   the actual typed failure; an unparented or arbitrary historical failure is
   rejected.
4. **Genetics survivor progression.** The barrier correctly stopped terminal
   cognition but initially left surviving genetics one tick behind. Only
   survivors advance, after the last cohort member finalizes, to the already
   committed lethal tick.
5. **Survivor perception/feedback.** The first barrier discarded all already
   observed World input, leaving survivor physiology ahead of feedback.
   Survivor perception may now be recorded at the boundary. Terminal identities
   remain excluded and no cognition or actions are emitted.
6. **Observer extinction.** The immutable zero-population snapshot was valid,
   but controller presentation required a selected living individual. The
   read-only status now reports `selected=none`, `population=0`, explicit
   bounded death omissions, and `extinction=1`.
7. **Lifecycle stage evidence (closure defect A).** The historical estate suite
   rejected `successor mortality life stage` because mortality returned before
   the existing stage transition completed. The session now completes that
   passive stage boundary before pending publication. Historical estate
   assertions were not changed.
8. **Estate custody availability (closure defect B).** After the stage fix, the
   historical administrator-replacement assertion showed that existing custody
   availability had not been revalidated before the deceased beneficiary left
   lifecycle authority. Existing passive revalidation now runs at the terminal
   boundary; administrator replacement remains mortality cleanup with the full
   cohort excluded. Historical estate assertions were not changed.
9. **Dependent lifecycle closure (canonical-gate defect).** Gate F Blocker 09
   then showed `dependentCare(invalid dependent care state: open assignment)`:
   lifecycle maturation could make an open assignment and guardianship
   historical before the terminal return validated care. A narrow passive
   boundary now ends only lifecycle-invalidated guardianships, assignments,
   needs, and engagements. It never chooses a replacement or creates a new
   obligation. The unchanged Gate F Blocker 09 suite passes 32/32.

## Checkpoint validation boundary

The checkpoint corrections are deliberately asymmetric:

- valid: an ended commitment for a genuinely terminal historical worker with
  coherent tick and typed terminal event;
- invalid: an active commitment for a dead worker;
- invalid: an ended dead-worker record without legitimate terminal provenance;
- valid: mortality exit provenance parented by the one bounded shared
  communication boundary whose parent is the actual typed transport failure;
- invalid: an unparented or arbitrary historical communication failure;
- valid: supported pending physical mortality with coherent current tick,
  identity, physiology, and custody fields;
- invalid: stale/incoherent stage, development, causal, or tick references.

There is no generic rule that historical IDs are acceptable. Every relaxed
reference is constrained by actual mortality history, status, time, and the
owning causal shape. Existing restore validation applies the same rules and
continues to reject re-signed corrupt checkpoints.

## Focused, composed, and regression evidence

The final focused selector on the final source tree passed **85/85**, exit 0:

```sh
PEBBLELAB_SMOKE_ONLY=ps01-increment-02 swift run --skip-build pebsmoke
```

It covers 1, 8, 9, 20, 24, and 30 simultaneous deaths; deterministic identity,
death, causal, and durable-byte ordering; partial mortality; 20/24/30
extinction; pending and finalized checkpoint restore; no resurrection;
mortality evidence compaction after prior history; survivor perception and
genetics; caregiver/guardian cohort exclusion and all-caregivers-terminal;
forward/reverse finalization equivalence; three commitments on one worker;
active settlement migration; one shared communication transport; and the
negative work and communication checkpoint attacks.

The closure-specific reruns on the final tree passed:

| Selector | Passed | Failed |
| --- | ---: | ---: |
| `gate-f-blocker-09` | 32 | 0 |
| `lifecycle` | 80 | 0 |
| `genetics-development` | 46 | 0 |
| `childhood-guardianship` | 62 | 0 |
| `dependent-care` | 55 | 0 |
| `estates-inheritance-succession` | 88 | 0 |

The complete owning matrix passed. Results not affected by the last passive
care closure are preserved from their final owner runs and are also exercised
by the final release smoke gate:

| Selector | Passed | Failed |
| --- | ---: | ---: |
| `mortality` | 93 | 0 |
| `founder-bootstrap` | 65 | 0 |
| `homeostasis-health` | 30 | 0 |
| `physical-food-survival` | 50 | 0 |
| `population-migration` | 66 | 0 |
| `civ-39` | 69 | 0 |
| `kinship` | 79 | 0 |
| `households` | 71 | 0 |
| `unions-family-lineages-houses` | 83 | 0 |
| `work-professions` | 29 | 0 |
| `civ-44` | 62 | 0 |
| `checkpoint-replay` | 49 | 0 |
| `persistence-reconciliation` | 19 | 0 |
| `observer` | 20 | 0 |
| `material-rights` | 23 | 0 |
| `materials` | 35 | 0 |
| `candidate-physical-atomicity` | 3 | 0 |
| `survival-economy` | 403 | 0 |

The first debug `survival-economy` diagnostic stopped with shell status 139 /
signal 11 in `___chkstk_darwin` before any assertion failed. The identical
unchanged selector passed 403/403 with the supported 65,520-KiB debug stack and
again in release mode. The final canonical release smoke suite passed, so this
is classified **DEBUG STACK LIMIT — NON-PRODUCT**. Product code and historical
assertions were not changed for it.

Historical estate regression is **88/88** with **NO** historical assertion
changes. The barrier had to preserve the existing estate contract.

## Physical custody and live evidence

The retained final CIV-29 campaign is
`/tmp/pebble-ps01-inc02-civ29-v6`. Its parent-shell numeric exit status was not
retained and is not inferred. The harness writes its final evidence artifact
only after all shell assertions, negative-log checks, restart checks, captures,
cleanup, and residual-process checks succeed. It is therefore classified
**PASS BY RETAINED HARNESS COMPLETION EVIDENCE; numeric parent exit status NOT
RETAINED**.

CIV-29 proves signed pre-death schema-22 custody checkpointing, one tracked
asset, three untracked stacks totaling nine items, six verified-empty actors,
a nine-member same-boundary terminal cohort, rollback after four physical
reconciliations, rollback after probe removal, retry, nine unique receipts,
nine deaths, extinction, byte-exact restore, restart reconciliation, survivor
continuation, stable Observer reads, exact cleanup, no loss/duplication, and
`runtimeErrors=0`. Its ordinary historical one- and two-death custody cases,
stale source, full/unavailable destination, and late failure cases remain.

The final passive lifecycle/care corrections do not require a CIV-29 rerun.
That harness does not enable dependent care, childhood, or estates; all
participants are already mature at the terminal boundary. The changed paths
are therefore unreachable or no-ops, and no Pebble physical owner changed.

The final natural release-binary campaign is retained at
`/tmp/pebble-ps01-inc02-normal-live-v4`:

| Normal World | Result | Terminal / restored tick | Deaths / receipts | Errors |
| --- | --- | --- | --- | --- |
| 20 founders, seed 46 | PASS | 23 / 24 | 20 / 20 | 0 |
| 24 founders, seed 46 | PASS | 23 / 24 | 24 / 24 | 0 |
| 24 founders, seed 887 | PASS | 23 / 24 | 24 / 24 | 0 |
| 30 founders, seed 887 | PASS | 23 / 24 | 30 / 30 | 0 |

All four use ordinary natural Worlds and the normal founder command. They use
no disposable proof flag, food grant, physiology override, staggered founders,
or terrain mutation. Each commits the former tick-23 refusal boundary, reaches
zero population/probes/pending mortality, records one unique death and physical
receipt per founder, saves and restores extinction, advances the restored empty
population to tick 24, and stops without resurrection. Across all successful
runs, `runtimeErrors=0` and `deathsPerTickExceeded=0`.

Representative final captures show natural terrain before terminalization,
explicit Observer extinction with no visible probes, and restored extinction
at tick 24. Structured logs and checkpoints remain authoritative.

## Canonical gate and candidate assessment

The final source tree passed the canonical gate exactly:

```sh
scripts/verify-pebblelab.sh
```

- Steps: **35/35**.
- Release smoke assertions: **4,843 passed / 0 failed**.
- Exit status: **0**.
- Regold: **false**; `PEBBLE_REGOLD` was absent and the gate refuses it.
- Deterministic paired scenario outputs and repository hygiene: PASS.

Local candidate assessment: **P0 0 / P1 0 / P2 0 known**.

## Explicit nonclaims

Increment 02 does not claim authoritative World/civilization Pause, Play, 1x,
or physical coverage; acceleration; food or subsistence; birth/admission
headroom; reproduction activation; agriculture or production startup;
migration initiation; physiological tuning; Save/Continue UX; culture,
knowledge, or language activation; Observer redesign; CIV-48; Increment 03;
or completion/publication of PLAYABLE SLICE 01.

The current no-subsistence normal founder path starving to extinction is a
successful simulation outcome for this increment. Avoiding that outcome is a
separate later product boundary.
