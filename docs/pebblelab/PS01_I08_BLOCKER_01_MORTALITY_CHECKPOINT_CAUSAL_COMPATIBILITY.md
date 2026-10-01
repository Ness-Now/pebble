# PS01 I08 Blocker 01 — Natural extinction/checkpoint causal compatibility

Status: **LOCAL CORRECTION — FOCUSED EVIDENCE PASSED — READY FOR SUPERVISOR REVIEW — NOT PUBLISHED**.
Mission: `INVESTIGATE-AND-RESOLVE-PS01-I08-BLOCKER-01-NATURAL-EXTINCTION-CHECKPOINT-CAUSAL-COMPATIBILITY`.

This is a separate blocker branch from canonical
`79517ab038ff6b33326fd8d38595cb30fe906c8c`, subject
`docs(ps01): record increment 07 publication`, parent
`373b5e3688d25e1e139dd735a76d48e38743c1f8`.
The blocked 15-file I08 implementation is preserved in its original worktree;
this correction neither incorporates that diff nor resumes I08 qualification.
PS01 remains REQUIRED / IN PROGRESS / NOT COMPLETE. CIV-48 remains NOT STARTED
and implementation not authorized. Gate H remains PLANNED.

## Attribution control and exact diagnosis

A separate clean diagnostic worktree started from the exact published baseline:
`/Users/nessnow/.codex/worktrees/ps01-i08-blocker-01/pebble-lab`, branch
`codex/ps01-i08-blocker-01-mortality-checkpoint`. Origin was fetched and the
canonical reference verified unchanged before work. The baseline diagnostic
binary contains only a gated harness and dispatch; no I08 continuation or
shared-authority correction is present.

Using normal 24-founder startup in natural seed 46, ordinary 1 Hz cognition,
one authoritative Core World tick per step, unchanged physical coverage and
the existing checkpoint-save path, all founders genuinely died at World tick
27652 / civilization tick 1380. No death, physical resource, expected result,
empty aggregate or replacement founder was injected. Runtime integrity checks
passed; the existing checkpoint save failed with `mortality causal chain`.

This establishes **PRE-EXISTING SHARED CHECKPOINT COMPATIBILITY BLOCKER,
DISCOVERED BY I08**. It does not indicate a torn World/civilization pair or I08
physical custody handoff failure. The manual save creates a checkpoint, then
the persistence store verifies its temporary bundle through checkpoint
validation/restoration before accepting it. That admission is the failure.

There are exactly two production throws of
`AgentCheckpointError.invalidBound("mortality causal chain")`:

- retained/missing primary-chain event admission;
- the later compound mortality causal predicate.

The first failing record passes retained/missing admission. Its **only false
individual compound condition** is:

```text
exit.causes == expectedExitCauses
```

Actual sequence set: **104, 132053, 132054, 132055, 132058**.
Validator-reconstructed expected set: **132053, 132054, 132055, 132058**.
All event IDs have simulation identity `live-46-8-76--112`.
All 24 records exhibit this same difference. No alternative error-label path
was found; the surrounding controller forwards the checkpoint admission error.

## Causal event forensics

First record: agent `agent_0`, death
`death-agent_0-t1380-0f10e082dc2ce7e0`, death tick **1380**.
Ledger latest sequence **132290**, first retained **124099**, dropped count
**124098**. It retains a contiguous suffix of 8192 events.

| Primary reference | Sequence | Retained kind | Actor / subject |
| --- | --- | --- | --- |
| lethal | 132053 | `lethalHealthDepletion` | agent_0 / agent_0 |
| resources | 132054 | `mortalityResourcesRetired` | agent_0 / agent_0 |
| commitments | 132055 | `mortalityCommitmentsResolved` | agent_0 / agent_0 |
| exit | 132059 | `populationMemberExited` | agent_0 / agent_0 |
| finalized | 132060 | `agentDeathFinalized` | agent_0 / agent_0 |

Resources cause lethal exactly; commitments cause lethal exactly; finalized
causes exit exactly. Primary ordering is strict and correct. No later
mortality-classified event concerning this victim exists. Family, migration,
settlement-migration and communication death causes are absent. The household
death effect is retained at **132058** and is correctly included by both sides.
Lifecycle death effects occur through their existing owner and do not add a
direct cause to the population-exit contract.

Other record references: registration/arrival **3** (evicted), retained current
membership authority **131075**, terminal physiology **132003**, pending
material exit **132027**, verified-empty physical custody resolution **132052**.
Material-exit IDs are empty. These references pass their owning admission.

The unmatched cause **104** exactly equals durable
`dependentCareState.lastCareEventID`. The earlier unmodified non-extinct
capture retains event 104: `childhoodV2Initialized`, origin
`dependentCareTransition`, tick 0, nil actor/subject, zero dependents. Its
absence from the terminal ledger is **legitimate bounded prefix eviction**,
not a hole in the retained suffix or true causal corruption.

The owning death transition calls `applyDependentCareDeath`, which returns the
care state's last boundary even when an adult death creates no new care event.
Mortality deliberately includes that boundary in `populationMemberExited`.
The care owner already admits its exact durable reference when legitimately
evicted, while enforcing simulation identity, bounds, contiguous suffix and
exact retained-event envelopes. The checkpoint mortality reconstruction looked
only at retained exit-cause events, discarded that valid cause, then demanded
exact equality. Producer and ledger preserve their intended contracts; this
reconstruction was inconsistent with legitimate bounded history.

Complete read-only forensics retain every record, primary IDs, retained and
absent event evidence, actual/expected causes, domain causes and each boolean.
Diagnostic JSON and printed reports are evidence only, never simulation input.

## Correction and retained invariants

Checkpoint admission still derives retained care causes as before. Only when
that result is absent may it use the **exact currently durable care boundary**,
and only when that ID is in the exit causes, absent from retained history,
belongs to the same simulation and lies within the recorded discarded prefix.
Existing care validation then verifies the boundary and contiguous-prefix
contract before checkpoint admission can succeed.

No arbitrary missing cause is ignored. Exact exit equality, primary-chain
admission, event kinds, actors, exact causes, strict ordering and no subsequent
mortality remain enforced. No bound is raised, schema changed, transient cache
persisted, second authority introduced or empty-population special case added.
Mortality, care and physical transitions are unchanged. Historical encodings
and schema semantics retain their owning contracts.

The existing checksummed event initializer is exposed solely through the
Testing SPI so adversarial checks rebuild corrupted envelopes with valid
checksums and test semantic refusal instead of an outer checksum mismatch.
It delegates to the same constructor and creates no new transition authority.

## Focused evidence

Baseline natural reproduction: **8 assertions passed; assertion 9 failed**,
exit 1. The raw terminal durable state was captured before save admission.
Initial diagnostic build had a harness-only `GameMode` compile error; corrected
release build passed. Both logs remain preserved.

The small owning regression uses existing pure-session starvation/mortality
transitions with a 128-event ledger, not an injected empty state. It reaches
three deaths at tick 182, latest sequence 1319, first retained 1192, dropped
1191, care boundary 21. The same exit-cause predicate fails.
Before correction the complete focused regression reports **12 passed / 2
failed** (admission and exact restoration). Seven corruption attacks pass.
An earlier diagnostic version checked capture rather than validation and
reported 6/1; its revised explicit-validation version reported 5/2. Those
historical diagnostic outputs are not promoted to acceptance evidence.

The corrected release owning suites pass **375 / 375** assertions:

| `PEBBLELAB_SMOKE_ONLY` | Passed | Failed |
| --- | ---: | ---: |
| `mortality-checkpoint-compaction` | 14 | 0 |
| `mortality` | 93 | 0 |
| `checkpoint-replay` | 49 | 0 |
| `dependent-care` | 55 | 0 |
| `childhood-guardianship` | 62 | 0 |
| `unions-family-lineages-houses` | 83 | 0 |
| `persistence-reconciliation` | 19 | 0 |

The 14 new assertions include non-extinct admission, naturally generated
extinction, legitimate care-prefix eviction, retained primary chains, exact
restoration, and seven checksummed semantic corruption attacks. The attacks
cover an unrelated discarded cause, an extra discarded cause, wrong retained
resource causes, a wrong lethal actor, a missing retained primary event, a
false discarded-prefix claim, and post-finalization mortality activity.

Exact focused invocations (each exited 0):

```sh
CFFIXED_USER_HOME=/tmp/ps01-i08-b01-evidence/focused/home-mortality-checkpoint-compaction PEBBLELAB_SMOKE_ONLY=mortality-checkpoint-compaction /tmp/ps01-i08-b01-evidence/focused/executable/pebsmoke > /tmp/ps01-i08-b01-evidence/focused/mortality-checkpoint-compaction.log 2>&1
CFFIXED_USER_HOME=/tmp/ps01-i08-b01-evidence/focused/home-mortality PEBBLELAB_SMOKE_ONLY=mortality /tmp/ps01-i08-b01-evidence/focused/executable/pebsmoke > /tmp/ps01-i08-b01-evidence/focused/mortality.log 2>&1
CFFIXED_USER_HOME=/tmp/ps01-i08-b01-evidence/focused/home-checkpoint-replay PEBBLELAB_SMOKE_ONLY=checkpoint-replay /tmp/ps01-i08-b01-evidence/focused/executable/pebsmoke > /tmp/ps01-i08-b01-evidence/focused/checkpoint-replay.log 2>&1
CFFIXED_USER_HOME=/tmp/ps01-i08-b01-evidence/focused/home-dependent-care PEBBLELAB_SMOKE_ONLY=dependent-care /tmp/ps01-i08-b01-evidence/focused/executable/pebsmoke > /tmp/ps01-i08-b01-evidence/focused/dependent-care.log 2>&1
CFFIXED_USER_HOME=/tmp/ps01-i08-b01-evidence/focused/home-childhood-guardianship PEBBLELAB_SMOKE_ONLY=childhood-guardianship /tmp/ps01-i08-b01-evidence/focused/executable/pebsmoke > /tmp/ps01-i08-b01-evidence/focused/childhood-guardianship.log 2>&1
CFFIXED_USER_HOME=/tmp/ps01-i08-b01-evidence/focused/home-unions-family-lineages-houses PEBBLELAB_SMOKE_ONLY=unions-family-lineages-houses /tmp/ps01-i08-b01-evidence/focused/executable/pebsmoke > /tmp/ps01-i08-b01-evidence/focused/unions-family-lineages-houses.log 2>&1
CFFIXED_USER_HOME=/tmp/ps01-i08-b01-evidence/focused/home-persistence-reconciliation PEBBLELAB_SMOKE_ONLY=persistence-reconciliation /tmp/ps01-i08-b01-evidence/focused/executable/pebsmoke > /tmp/ps01-i08-b01-evidence/focused/persistence-reconciliation.log 2>&1
```

`swift build -c release` passed for all products. The canonical invocation was:

```sh
CFFIXED_USER_HOME=/tmp/ps01-i08-b01-evidence/canonical-home \
scripts/verify-pebblelab.sh \
> /tmp/ps01-i08-b01-evidence/canonical.log 2>&1
```

Its debug and release build stages passed. Stage 5 full smoke reported
**4920 passed / 3 failed**, exit 1, and therefore stages 6–35 did not execute.
This is not represented as a passing canonical gate. The three failures are
exactly the published historical I07 failures: `zoo: 55 mob types × 200 ticks
bit-identical (3 checkpoints)`, `combat: player + 5 mobs, damage/knockback in
lockstep`, and `8 A* paths node-identical`. The 14-assertion addition accounts
for the increase from the published 4906 passed / 3 failed. No golden changed;
these failures are not attributed to I07 or the blocker correction.

The corrected normal seed-46 reproduction passed **12 / 12 assertions**, exit
0. It reached the exact same World tick **27652** / civilization tick **1380**
with zero living agents, zero runtime errors and no fatal-integrity halt.
The existing checkpoint store accepted `natural-terminal`; stored checkpoint
restoration preserved the exact simulation identity and durable bytes, with no
replacement founders. Existing lifecycle cleanup left zero probes.
Normal non-extinct checkpoints passed both before and after causal compaction.

Both the initial and terminal durable state are **byte-identical** between the
baseline failing run and corrected run. The terminal SHA-256 is
`80e92cdcf8878b473210a5a8eda4e91948992265689b89bd0d707000a03b12e3`;
the causal digest is `b5436d9e57367ee1`. This directly isolates an admission
correction without a producer, World, cohort or expected-state change.

Exact natural reproduction commands:

```sh
# Baseline diagnostic release binary, before the shared correction.
bash /tmp/ps01-i08-b01-evidence/run-natural.sh /tmp/ps01-i08-b01-evidence/baseline-natural > /tmp/ps01-i08-b01-evidence/baseline-natural.log 2>&1
# Corrected release binary, built and frozen by the committed diagnostic launcher.
scripts/verify-pebblelab-ps01-i08-blocker-01.sh /tmp/ps01-i08-b01-evidence/corrected-natural > /tmp/ps01-i08-b01-evidence/corrected-natural.log 2>&1
# Read-only reconstruction of the original canonical predicate.
python3 /tmp/ps01-i08-b01-evidence/forensics.py /tmp/ps01-i08-b01-evidence/baseline-natural/state/terminal-state.json /tmp/ps01-i08-b01-evidence/baseline-natural-forensics.json
```

Frozen executable SHA-256 values:

- Baseline diagnostic Pebble:
  `041a1e2403d42bfc005e0748b73be9e0d0ba808217584f4a172da77117616b10`.
- Corrected diagnostic Pebble:
  `df38d068976ef79b1fcb223ba5fe6c0cf570841bf6b0b3dccc6c81334aedd321`.

Evidence root: `/tmp/ps01-i08-b01-evidence`. The delivery archive is separate
from both worktrees at
`/Users/nessnow/Dev/pebble-lab-b01-evidence-20261001`. It preserves failing and
passing logs, raw states, predicate forensics, authority/source hashes, frozen
executables, isolated persistence homes, Git delivery metadata and file hashes.
Earlier harness/SPI compile errors remain recorded as failed diagnostic builds;
they are not accepted runtime evidence. No process was cancelled during the
final natural run; it started after the shared SwiftPM build lock was released.

No full I08 qualification, portal repair or Visual Game Smoke is authorized by
this blocker mission. Portal and visual issues remain separate; existing
Visual-04 evidence does not establish a restore-specific rendering regression
because terrain is already missing before save.
The natural harness uses the existing manual checkpoint command and checkpoint
restoration authority to answer this blocker question. It makes no claim that
ordinary World save/re-entry is qualified; that remains I08 work.

## Remaining limits

The fallback is deliberately limited to an existing durable care reference. It
does not invent historical care provenance when that reference has itself been
superseded or when unknown older exit causes cannot be reconciled. Such cases
retain honest refusal and require their own evidence-driven investigation.
This correction does not establish general long-duration checkpoint admission,
unlimited history, arbitrary historical migration or crash recovery.
I08 remains blocked/unqualified until separate supervisor review and an
explicitly resumed implementation/qualification mission.

The original I08 worktree is unchanged: branch
`codex/ps01-increment-08-normal-continuity`, HEAD
`79517ab038ff6b33326fd8d38595cb30fe906c8c`, nine modified tracked and six
untracked files, no commits. All 15 source hashes and its exact status match
the mission-start snapshot. Its later portal diagnostic source is not
attributed to historical build-17 evidence. The correction has no I08 diff.
Origin was fetched again before delivery and remained at the exact required
baseline. The dedicated local correction commit is identified by delivery Git
metadata rather than a self-referential commit ID in this record.
Push attempted: **NO**.
